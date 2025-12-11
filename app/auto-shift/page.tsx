"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { useShift } from "../context/ShiftContext";
import { format, startOfMonth, endOfMonth, eachDayOfInterval, getDay } from "date-fns";
import { ChevronLeft, Download } from "lucide-react";
import { cn } from "@/lib/utils";

export default function AutoShiftPage() {
  const router = useRouter();
  const { selectedMonth, generateDraft } = useShift();
  const [requiredPerDay, setRequiredPerDay] = useState(3);
  const [draft, setDraft] = useState<Record<string, any> | null>(null);

  const handleGenerate = () => {
    const result = generateDraft(requiredPerDay);
    setDraft(result);
  };

  const monthStart = startOfMonth(selectedMonth);
  const monthEnd = endOfMonth(selectedMonth);
  const days = eachDayOfInterval({ start: monthStart, end: monthEnd });
  const startDayOfWeek = getDay(monthStart);
  const paddingDays = Array(startDayOfWeek).fill(null);

  return (
    <div className="min-h-screen bg-slate-50 pb-20">
      <header className="bg-white shadow-sm sticky top-0 z-10">
        <div className="max-w-4xl mx-auto px-4 h-16 flex items-center space-x-4">
          <button onClick={() => router.back()} className="p-2 hover:bg-slate-100 rounded-full">
            <ChevronLeft className="w-6 h-6 text-slate-600" />
          </button>
          <div>
            <h1 className="text-lg font-bold text-slate-900">シフト自動生成 (ベータ)</h1>
            <p className="text-xs text-slate-500">{format(selectedMonth, "yyyy年 M月")}</p>
          </div>
        </div>
      </header>

      <main className="max-w-4xl mx-auto px-4 py-6">
        {!draft ? (
          <div className="bg-white p-8 rounded-lg shadow-md text-center">
            <h2 className="text-xl font-bold text-slate-800 mb-4">生成設定</h2>
            <div className="flex items-center justify-center space-x-4 mb-8">
              <label className="font-medium text-slate-700">1日あたりの必要人数:</label>
              <input
                type="number"
                min="1"
                value={requiredPerDay}
                onChange={(e) => setRequiredPerDay(Number(e.target.value))}
                className="border rounded-md p-2 w-20 text-center text-lg"
              />
            </div>
            <button
              onClick={handleGenerate}
              className="bg-blue-600 text-white px-8 py-3 rounded-full text-lg font-bold shadow-lg hover:bg-blue-700 transition-colors"
            >
              シフト案を作成
            </button>
          </div>
        ) : (
          <>
            <div className="flex justify-between items-center mb-4">
              <button 
                onClick={() => setDraft(null)}
                className="text-sm text-blue-600 hover:underline"
              >
                設定に戻る
              </button>
              <button className="flex items-center space-x-2 text-slate-600 hover:text-slate-900">
                <Download className="w-4 h-4" />
                <span>CSV出力 (未実装)</span>
              </button>
            </div>

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
                const dayData = draft[dateStr];
                const assigned = dayData?.assigned || [];
                const missing = dayData?.missing || 0;
                
                return (
                  <div
                    key={dateStr}
                    className="min-h-[120px] bg-white border rounded-md p-1 flex flex-col"
                  >
                    <div className="flex justify-between items-start">
                      <span className={cn("text-sm font-medium", getDay(date) === 0 ? "text-red-500" : getDay(date) === 6 ? "text-blue-500" : "text-slate-700")}>
                        {format(date, "d")}
                      </span>
                      {missing > 0 && (
                        <span className="text-[10px] bg-red-100 text-red-600 px-1 rounded font-bold">
                          不足 {missing}
                        </span>
                      )}
                    </div>
                    
                    <div className="mt-1 space-y-1 overflow-y-auto flex-1">
                      {assigned.map((a: any, idx: number) => (
                        <div key={idx} className="text-[10px] bg-blue-50 text-blue-800 px-1 py-0.5 rounded truncate">
                          {a.name}
                        </div>
                      ))}
                    </div>
                  </div>
                );
              })}
            </div>
          </>
        )}
      </main>
    </div>
  );
}
