"use client";

import { useRouter } from "next/navigation";
import { useShift } from "../context/ShiftContext";
import { addMonths, format, subMonths } from "date-fns";
import { ChevronLeft, ChevronRight } from "lucide-react";

export default function MonthSelectPage() {
  const { selectedMonth, setMonth } = useShift();
  const router = useRouter();

  const handlePrev = () => setMonth(subMonths(selectedMonth, 1));
  const handleNext = () => setMonth(addMonths(selectedMonth, 1));
  const handleProceed = () => router.push("/roster");

  return (
    <div className="min-h-screen bg-slate-50 flex flex-col items-center pt-20">
      <h1 className="text-2xl font-bold text-blue-900 mb-8">作成する月を選択</h1>
      
      <div className="bg-white p-8 rounded-xl shadow-lg flex items-center space-x-8 mb-12">
        <button onClick={handlePrev} className="p-2 hover:bg-slate-100 rounded-full">
          <ChevronLeft className="w-8 h-8 text-slate-600" />
        </button>
        <div className="text-4xl font-bold text-slate-800 w-64 text-center">
          {format(selectedMonth, "yyyy年 M月")}
        </div>
        <button onClick={handleNext} className="p-2 hover:bg-slate-100 rounded-full">
          <ChevronRight className="w-8 h-8 text-slate-600" />
        </button>
      </div>

      <button
        onClick={handleProceed}
        className="bg-blue-600 text-white px-8 py-3 rounded-full text-lg font-semibold shadow-md hover:bg-blue-700 transition-colors"
      >
        この月で作成する
      </button>
    </div>
  );
}
