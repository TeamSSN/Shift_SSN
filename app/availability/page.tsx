"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { useShift } from "../context/ShiftContext";
import { format, startOfMonth, endOfMonth, eachDayOfInterval, getDay } from "date-fns";
import { ja } from "date-fns/locale";
import { ChevronLeft, X } from "lucide-react";
import { cn } from "@/lib/utils";

export default function AllAvailabilityPage() {
  const router = useRouter();
  const { staffList, selectedMonth } = useShift();
  const [selectedDate, setSelectedDate] = useState<Date | null>(null);

  const monthStart = startOfMonth(selectedMonth);
  const monthEnd = endOfMonth(selectedMonth);
  const days = eachDayOfInterval({ start: monthStart, end: monthEnd });
  const startDayOfWeek = getDay(monthStart);
  const paddingDays = Array(startDayOfWeek).fill(null);

  const getAvailabilityForDate = (date: Date) => {
    const dateStr = format(date, "yyyy-MM-dd");
    return staffList.filter(staff => {
      const slot = staff.availability[dateStr];
      return slot && slot.type !== "off";
    }).map(staff => ({
      staff,
      slot: staff.availability[dateStr]
    }));
  };

  const handleDayClick = (date: Date) => {
    setSelectedDate(date);
  };

  const selectedDateAvailability = selectedDate ? getAvailabilityForDate(selectedDate) : [];

  return (
    <div className="min-h-screen bg-slate-50 pb-20">
      <header className="bg-white shadow-sm sticky top-0 z-10">
        <div className="max-w-4xl mx-auto px-4 h-16 flex items-center space-x-4">
          <button onClick={() => router.back()} className="p-2 hover:bg-slate-100 rounded-full">
            <ChevronLeft className="w-6 h-6 text-slate-600" />
          </button>
          <div>
            <h1 className="text-lg font-bold text-slate-900">全員の出勤可能状況</h1>
            <p className="text-xs text-slate-500">{format(selectedMonth, "yyyy年 M月")}</p>
          </div>
        </div>
      </header>

      <main className="max-w-4xl mx-auto px-4 py-6">
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
            const available = getAvailabilityForDate(date);
            const count = available.length;
            
            return (
              <div
                key={date.toString()}
                onClick={() => handleDayClick(date)}
                className="aspect-[4/5] bg-white border rounded-md p-1 cursor-pointer hover:border-blue-400 transition-colors flex flex-col items-center justify-start overflow-hidden"
              >
                <span className={cn("text-sm font-medium", getDay(date) === 0 ? "text-red-500" : getDay(date) === 6 ? "text-blue-500" : "text-slate-700")}>
                  {format(date, "d")}
                </span>
                
                <div className="mt-1 flex-1 w-full px-1 overflow-y-auto no-scrollbar">
                  {count > 0 ? (
                    <div className="flex flex-col gap-1">
                        {available.map(({staff, slot}) => (
                            <div key={staff.id} className={cn(
                              "text-[10px] rounded px-1 py-0.5 flex items-center justify-between gap-1",
                              slot?.type === "free" ? "bg-green-100 text-green-800" : "bg-blue-100 text-blue-800"
                            )}>
                                <span className="truncate font-medium">{staff.lastName}</span>
                                <span className="shrink-0 text-[9px] font-mono opacity-90">
                                  {slot?.type === "free" ? "Free" : `${slot?.start}~${slot?.end}`}
                                </span>
                            </div>
                        ))}
                    </div>
                  ) : (
                    <div className="h-full flex items-center justify-center">
                        <span className="text-slate-200 text-xl">-</span>
                    </div>
                  )}
                </div>
              </div>
            );
          })}
        </div>
      </main>

      {/* Detail Modal */}
      {selectedDate && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-xl w-full max-w-md shadow-2xl overflow-hidden max-h-[80vh] flex flex-col">
            <div className="bg-slate-50 px-6 py-4 border-b flex justify-between items-center shrink-0">
              <h3 className="font-bold text-lg text-slate-800">
                {format(selectedDate, "M月d日 (E)", { locale: ja })} の出勤可能者
              </h3>
              <button onClick={() => setSelectedDate(null)} className="text-slate-400 hover:text-slate-600">
                <X className="w-5 h-5" />
              </button>
            </div>
            
            <div className="p-0 overflow-y-auto flex-1">
              {selectedDateAvailability.length > 0 ? (
                <ul className="divide-y divide-slate-100">
                  {selectedDateAvailability.map(({ staff, slot }) => (
                    <li key={staff.id} className="p-4 flex justify-between items-center">
                      <div>
                        <div className="font-bold text-slate-800">{staff.name}</div>
                        <div className="text-xs text-slate-500">{staff.role}</div>
                      </div>
                      <div className="text-right">
                        {slot.type === "free" ? (
                          <span className="inline-block px-2 py-1 bg-green-100 text-green-700 text-xs font-bold rounded">Free</span>
                        ) : (
                          <span className="font-mono text-blue-700 font-medium">
                            {slot.start} - {slot.end}
                          </span>
                        )}
                        {slot.fixed && <span className="ml-2 text-[10px] bg-amber-100 text-amber-700 px-1 rounded">固定</span>}
                      </div>
                    </li>
                  ))}
                </ul>
              ) : (
                <div className="p-8 text-center text-slate-500">
                  出勤可能なスタッフはいません
                </div>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
