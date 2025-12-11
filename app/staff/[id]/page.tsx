"use client";

import { useState, useEffect } from "react";
import { useParams, useRouter } from "next/navigation";
import { useShift, AvailabilitySlot } from "../../context/ShiftContext";
import { format, startOfMonth, endOfMonth, eachDayOfInterval, isSameMonth, getDay, isSameDay } from "date-fns";
import { ja } from "date-fns/locale";
import { ChevronLeft, Clock, X, Check, Copy, Calendar } from "lucide-react";
import { cn } from "@/lib/utils";

export default function StaffDetailPage() {
  const { id } = useParams();
  const router = useRouter();
  const { getStaff, selectedMonth, setAvailability, copyAvailability, setFixedShift, removeFixedShift } = useShift();
  
  const staffId = Number(id);
  const staff = getStaff(staffId);

  const [selectedDate, setSelectedDate] = useState<Date | null>(null);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [isFixedModalOpen, setIsFixedModalOpen] = useState(false);
  
  // Copy Mode State
  const [isCopyMode, setIsCopyMode] = useState(false);
  const [copySourceDate, setCopySourceDate] = useState<Date | null>(null);
  const [selectedTargetDates, setSelectedTargetDates] = useState<Set<string>>(new Set());

  // Modal State
  const [modalType, setModalType] = useState<"window" | "off" | "free">("window");
  const [startTime, setStartTime] = useState("10:00");
  const [endTime, setEndTime] = useState("19:00");

  // Fixed Shift State (for the modal or separate view)
  // For simplicity, I'll add a "Fixed Shift" section in the modal if the day matches a weekday?
  // Or maybe a separate "Fixed Shift Settings" button.
  // The requirements say: "固定シフトは画面表示時に自動反映" (Fixed shifts are automatically reflected).
  // "日付を押すとモーダルが開き...固定シフトの確認と編集が可能" (Click date -> modal -> check/edit fixed shift).
  // Actually, fixed shifts are usually set per weekday, not per date.
  // But let's stick to the daily availability setting first.

  if (!staff) {
    return <div className="p-8">Staff not found</div>;
  }

  const monthStart = startOfMonth(selectedMonth);
  const monthEnd = endOfMonth(selectedMonth);
  const days = eachDayOfInterval({ start: monthStart, end: monthEnd });

  // Pad start of month
  const startDayOfWeek = getDay(monthStart); // 0 (Sun) - 6 (Sat)
  // We want Monday start? QML usually does Monday start.
  // Let's assume Sunday start for standard calendar, or Monday if preferred.
  // Let's do Sunday start for simplicity with date-fns default.
  const paddingDays = Array(startDayOfWeek).fill(null);

  const handleDayClick = (date: Date) => {
    const dateStr = format(date, "yyyy-MM-dd");

    if (isCopyMode) {
      // Toggle selection
      const newSet = new Set(selectedTargetDates);
      if (newSet.has(dateStr)) {
        newSet.delete(dateStr);
      } else {
        newSet.add(dateStr);
      }
      setSelectedTargetDates(newSet);
      return;
    }

    setSelectedDate(date);
    const currentSlot = staff.availability[dateStr];
    
    if (currentSlot) {
      setModalType(currentSlot.type);
      if (currentSlot.start) setStartTime(currentSlot.start);
      if (currentSlot.end) setEndTime(currentSlot.end);
    } else {
      setModalType("window");
      // Default times
    }
    setIsModalOpen(true);
  };

  const handleSave = () => {
    if (selectedDate) {
      const dateStr = format(selectedDate, "yyyy-MM-dd");
      if (modalType === "off") {
        setAvailability(staffId, dateStr, { type: "off" });
      } else if (modalType === "free") {
        setAvailability(staffId, dateStr, { type: "free" });
      } else {
        setAvailability(staffId, dateStr, { type: "window", start: startTime, end: endTime });
      }
      setIsModalOpen(false);
    }
  };

  const handleClear = () => {
    if (selectedDate) {
      const dateStr = format(selectedDate, "yyyy-MM-dd");
      setAvailability(staffId, dateStr, null);
      setIsModalOpen(false);
    }
  };

  const startCopyMode = () => {
    if (selectedDate) {
      setCopySourceDate(selectedDate);
      setIsCopyMode(true);
      setIsModalOpen(false);
      setSelectedTargetDates(new Set());
    }
  };

  const executeCopy = () => {
    if (copySourceDate && selectedTargetDates.size > 0) {
      const sourceDateStr = format(copySourceDate, "yyyy-MM-dd");
      copyAvailability(staffId, sourceDateStr, Array.from(selectedTargetDates));
      cancelCopyMode();
    }
  };

  const cancelCopyMode = () => {
    setIsCopyMode(false);
    setCopySourceDate(null);
    setSelectedTargetDates(new Set());
  };

  return (
    <div className="min-h-screen bg-slate-50 pb-20">
      <header className="bg-white shadow-sm sticky top-0 z-10">
        <div className="max-w-4xl mx-auto px-4 h-16 flex items-center justify-between">
          <div className="flex items-center space-x-4">
            <button onClick={() => router.back()} className="p-2 hover:bg-slate-100 rounded-full">
              <ChevronLeft className="w-6 h-6 text-slate-600" />
            </button>
            <div>
              <h1 className="text-lg font-bold text-slate-900">{staff.name}</h1>
              <p className="text-xs text-slate-500">{format(selectedMonth, "yyyy年 M月")}</p>
            </div>
          </div>
          {isCopyMode ? (
            <div className="flex items-center space-x-2">
              <button 
                onClick={cancelCopyMode}
                className="px-3 py-1 text-sm text-slate-600 hover:bg-slate-100 rounded"
              >
                キャンセル
              </button>
              <button 
                onClick={executeCopy}
                disabled={selectedTargetDates.size === 0}
                className="px-3 py-1 text-sm bg-blue-600 text-white rounded hover:bg-blue-700 disabled:opacity-50"
              >
                貼り付け ({selectedTargetDates.size})
              </button>
            </div>
          ) : (
            <button
              onClick={() => setIsFixedModalOpen(true)}
              className="flex items-center space-x-1 px-3 py-2 bg-white border border-slate-300 rounded-md text-sm font-medium text-slate-700 hover:bg-slate-50"
            >
              <Calendar className="w-4 h-4" />
              <span>固定シフト</span>
            </button>
          )}
        </div>
      </header>

      {isCopyMode && copySourceDate && (
        <div className="bg-blue-50 border-b border-blue-100 p-2 text-center text-sm text-blue-800">
          <span className="font-bold">{format(copySourceDate, "M/d")}</span> の設定をコピー中。貼り付け先を選択してください。
        </div>
      )}

      <main className="max-w-4xl mx-auto px-4 py-6">
        {/* Calendar Grid */}
        <div className="grid grid-cols-7 gap-1 mb-2">
          {["日", "月", "火", "水", "木", "金", "土"].map((d, i) => (
            <div key={i} className={cn("text-center text-sm font-medium py-2", i === 0 ? "text-red-500" : i === 6 ? "text-blue-500" : "text-slate-500")}>
              {d}
            </div>
          ))}
        </div>
        
        <div className="grid grid-cols-7 gap-1">
          {paddingDays.map((_, i) => <div key={`pad-${i}`} />)}
          {days.map((date) => {
            const dateStr = format(date, "yyyy-MM-dd");
            const slot = staff.availability[dateStr];
            const isFixed = slot?.fixed;
            const isSelectedTarget = selectedTargetDates.has(dateStr);
            const isSource = copySourceDate && isSameDay(date, copySourceDate);
            
            return (
              <div
                key={dateStr}
                onClick={() => handleDayClick(date)}
                className={cn(
                  "aspect-[4/5] bg-white border rounded-md p-1 cursor-pointer transition-colors relative flex flex-col items-center justify-start",
                  slot?.type === "off" && "bg-slate-100",
                  slot?.type === "free" && "bg-green-50",
                  slot?.type === "window" && "bg-blue-50",
                  isCopyMode && !isSelectedTarget && !isSource && "opacity-50 hover:opacity-100",
                  isSelectedTarget && "ring-2 ring-blue-500 z-10",
                  isSource && "ring-2 ring-amber-500 z-10",
                  !isCopyMode && "hover:border-blue-400"
                )}
              >
                <span className={cn("text-sm font-medium", getDay(date) === 0 ? "text-red-500" : getDay(date) === 6 ? "text-blue-500" : "text-slate-700")}>
                  {format(date, "d")}
                </span>
                
                <div className="mt-1 flex-1 flex flex-col items-center justify-center w-full">
                  {slot ? (
                    <>
                      {slot.type === "off" && <X className="w-6 h-6 text-slate-400" />}
                      {slot.type === "free" && <div className="text-xs font-bold text-green-600">Free</div>}
                      {slot.type === "window" && (
                        <div className="text-[10px] text-blue-700 font-medium text-center leading-tight">
                          {slot.start}<br/>|<br/>{slot.end}
                        </div>
                      )}
                      {isFixed && (
                        <div className="absolute top-1 right-1 w-1.5 h-1.5 bg-amber-400 rounded-full" title="固定シフト" />
                      )}
                    </>
                  ) : (
                    <span className="text-slate-200 text-xl">-</span>
                  )}
                </div>
              </div>
            );
          })}
        </div>
      </main>

      {/* Edit Modal */}
      {isModalOpen && selectedDate && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-xl w-full max-w-sm shadow-2xl overflow-hidden">
            <div className="bg-slate-50 px-6 py-4 border-b flex justify-between items-center">
              <h3 className="font-bold text-lg text-slate-800">
                {format(selectedDate, "M月d日 (E)", { locale: ja })}
              </h3>
              <button onClick={() => setIsModalOpen(false)} className="text-slate-400 hover:text-slate-600">
                <X className="w-5 h-5" />
              </button>
            </div>
            
            <div className="p-6 space-y-6">
              <div className="grid grid-cols-3 gap-3">
                <button
                  onClick={() => setModalType("off")}
                  className={cn("p-3 rounded-lg border-2 flex flex-col items-center space-y-2 transition-all", 
                    modalType === "off" ? "border-red-500 bg-red-50 text-red-700" : "border-slate-200 hover:border-slate-300 text-slate-600")}
                >
                  <X className="w-6 h-6" />
                  <span className="text-xs font-bold">不可</span>
                </button>
                <button
                  onClick={() => setModalType("window")}
                  className={cn("p-3 rounded-lg border-2 flex flex-col items-center space-y-2 transition-all", 
                    modalType === "window" ? "border-blue-500 bg-blue-50 text-blue-700" : "border-slate-200 hover:border-slate-300 text-slate-600")}
                >
                  <Clock className="w-6 h-6" />
                  <span className="text-xs font-bold">時間指定</span>
                </button>
                <button
                  onClick={() => setModalType("free")}
                  className={cn("p-3 rounded-lg border-2 flex flex-col items-center space-y-2 transition-all", 
                    modalType === "free" ? "border-green-500 bg-green-50 text-green-700" : "border-slate-200 hover:border-slate-300 text-slate-600")}
                >
                  <Check className="w-6 h-6" />
                  <span className="text-xs font-bold">フリー</span>
                </button>
              </div>

              {modalType === "window" && (
                <div className="flex items-center justify-center space-x-4 bg-slate-50 p-4 rounded-lg">
                  <input
                    type="time"
                    value={startTime}
                    min="06:00"
                    max="23:00"
                    step="900"
                    onChange={(e) => setStartTime(e.target.value)}
                    className="border rounded p-2 text-lg font-mono text-slate-900 bg-white"
                  />
                  <span className="text-slate-400">~</span>
                  <input
                    type="time"
                    value={endTime}
                    min="06:00"
                    max="23:00"
                    step="900"
                    onChange={(e) => setEndTime(e.target.value)}
                    className="border rounded p-2 text-lg font-mono text-slate-900 bg-white"
                  />
                </div>
              )}

              <div className="flex space-x-3 pt-2">
                <button
                  onClick={handleClear}
                  className="flex-1 py-3 border border-slate-300 text-slate-600 rounded-lg font-medium hover:bg-slate-50"
                >
                  未設定に戻す
                </button>
                <button
                  onClick={handleSave}
                  className="flex-1 py-3 bg-blue-600 text-white rounded-lg font-bold hover:bg-blue-700 shadow-md"
                >
                  決定
                </button>
              </div>

              <div className="pt-2 border-t border-slate-100">
                <button
                  onClick={startCopyMode}
                  className="w-full flex items-center justify-center space-x-2 py-2 text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"
                >
                  <Copy className="w-4 h-4" />
                  <span className="text-sm font-medium">この設定を他の日にコピー</span>
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
      {/* Fixed Shift Modal */}
      {isFixedModalOpen && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-xl w-full max-w-md shadow-2xl overflow-hidden max-h-[80vh] flex flex-col">
            <div className="bg-slate-50 px-6 py-4 border-b flex justify-between items-center shrink-0">
              <h3 className="font-bold text-lg text-slate-800">固定シフト設定</h3>
              <button onClick={() => setIsFixedModalOpen(false)} className="text-slate-400 hover:text-slate-600">
                <X className="w-5 h-5" />
              </button>
            </div>
            <div className="p-6 overflow-y-auto">
              <p className="text-sm text-slate-500 mb-6">
                曜日ごとの固定シフトを設定します。設定はすべての月に自動的に反映されます。
              </p>
              <div className="space-y-4">
                {[
                  { id: 1, label: "月" },
                  { id: 2, label: "火" },
                  { id: 3, label: "水" },
                  { id: 4, label: "木" },
                  { id: 5, label: "金" },
                  { id: 6, label: "土" },
                  { id: 7, label: "日" },
                ].map((day) => {
                  const fixedEntry = staff.fixed.find((f) => f.weekday === day.id);
                  const isEnabled = !!fixedEntry;

                  return (
                    <div key={day.id} className="flex items-center justify-between p-3 border rounded-lg bg-slate-50">
                      <div className="flex items-center space-x-4">
                        <div className={cn(
                          "w-8 h-8 rounded-full flex items-center justify-center font-bold text-sm",
                          day.id === 7 ? "bg-red-100 text-red-600" : day.id === 6 ? "bg-blue-100 text-blue-600" : "bg-slate-200 text-slate-600"
                        )}>
                          {day.label}
                        </div>
                        <label className="relative inline-flex items-center cursor-pointer">
                          <input 
                            type="checkbox" 
                            className="sr-only peer"
                            checked={isEnabled}
                            onChange={(e) => {
                              if (e.target.checked) {
                                setFixedShift(staffId, day.id, "10:00", "19:00");
                              } else {
                                removeFixedShift(staffId, day.id);
                              }
                            }}
                          />
                          <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
                        </label>
                      </div>

                      {isEnabled ? (
                        <div className="flex items-center space-x-2">
                          <input
                            type="time"
                            value={fixedEntry.start}
                            min="06:00"
                            max="23:00"
                            step="900"
                            onChange={(e) => setFixedShift(staffId, day.id, e.target.value, fixedEntry.end)}
                            className="border rounded px-1 py-1 text-sm w-20 text-center text-slate-900 bg-white"
                          />
                          <span className="text-slate-400">-</span>
                          <input
                            type="time"
                            value={fixedEntry.end}
                            min="06:00"
                            max="23:00"
                            step="900"
                            onChange={(e) => setFixedShift(staffId, day.id, fixedEntry.start, e.target.value)}
                            className="border rounded px-1 py-1 text-sm w-20 text-center text-slate-900 bg-white"
                          />
                        </div>
                      ) : (
                        <span className="text-sm text-slate-400 px-4">設定なし</span>
                      )}
                    </div>
                  );
                })}
              </div>
            </div>
            <div className="p-4 border-t bg-slate-50 flex justify-end">
              <button onClick={() => setIsFixedModalOpen(false)} className="px-6 py-2 bg-blue-600 text-white rounded-lg font-bold hover:bg-blue-700">
                完了
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
