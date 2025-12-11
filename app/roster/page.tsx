"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { useShift, Staff, Role } from "../context/ShiftContext";
import { CheckCircle, AlertTriangle, Circle, XCircle, Plus, Trash2, User } from "lucide-react";
import { cn } from "@/lib/utils";

export default function RosterPage() {
  const { staffList, addStaff, deleteStaff, logout } = useShift();
  const router = useRouter();
  const [isAddModalOpen, setIsAddModalOpen] = useState(false);

  // Add Staff Form State
  const [lastName, setLastName] = useState("");
  const [firstName, setFirstName] = useState("");
  const [role, setRole] = useState<Role>("アルバイト");

  const handleAddStaff = () => {
    if (lastName && firstName) {
      addStaff(lastName, firstName, role);
      setIsAddModalOpen(false);
      setLastName("");
      setFirstName("");
    }
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case "complete": return <CheckCircle className="w-5 h-5 text-green-500" />;
      case "partial": return <AlertTriangle className="w-5 h-5 text-amber-500" />;
      case "offmonth": return <XCircle className="w-5 h-5 text-gray-400" />;
      default: return <Circle className="w-5 h-5 text-slate-300" />;
    }
  };

  const getStatusText = (status: string) => {
    switch (status) {
      case "complete": return "完了";
      case "partial": return "設定漏れ";
      case "offmonth": return "長期休み";
      default: return "未設定";
    }
  };

  const getWeekdayLabel = (weekday: number) => {
    const labels = ["", "月", "火", "水", "木", "金", "土", "日"];
    return labels[weekday] || "";
  };

  const getRoleColor = (role: Role) => {
    switch (role) {
      case "社員": return "bg-rose-100 text-rose-600";
      case "パート": return "bg-amber-100 text-amber-600";
      case "アルバイト": return "bg-emerald-100 text-emerald-600";
      default: return "bg-slate-100 text-slate-600";
    }
  };

  return (
    <div className="min-h-screen bg-slate-50 pb-20">
      {/* Header */}
      <header className="bg-white shadow-sm sticky top-0 z-10">
        <div className="max-w-4xl mx-auto px-4 h-16 flex items-center justify-between">
          <h1 className="text-xl font-bold text-blue-900">名簿管理</h1>
          <button onClick={() => { logout(); router.push("/"); }} className="text-sm text-slate-500 hover:text-slate-800">
            ログアウト
          </button>
        </div>
      </header>

      <main className="max-w-4xl mx-auto px-4 py-8">
        <div className="flex justify-between items-center mb-6">
          <h2 className="text-lg font-semibold text-slate-700">スタッフ一覧</h2>
          <button
            onClick={() => setIsAddModalOpen(true)}
            className="flex items-center space-x-2 bg-blue-600 text-white px-4 py-2 rounded-md hover:bg-blue-700 transition-colors"
          >
            <Plus className="w-4 h-4" />
            <span>スタッフ追加</span>
          </button>
        </div>

        <div className="bg-white rounded-lg shadow overflow-hidden">
          <ul className="divide-y divide-slate-100">
            {staffList.map((staff) => (
              <li key={staff.id} className="hover:bg-slate-50 transition-colors">
                <div className="flex items-center p-4">
                  <div 
                    className="flex-1 flex items-center cursor-pointer"
                    onClick={() => router.push(`/staff/${staff.id}`)}
                  >
                    <div className={cn("w-10 h-10 rounded-full flex items-center justify-center mr-4", getRoleColor(staff.role))}>
                      <User className="w-5 h-5" />
                    </div>
                    <div>
                      <div className="font-medium text-slate-900">{staff.name}</div>
                      <div className="text-sm text-slate-500">{staff.role}</div>
                      {staff.fixed.length > 0 && (
                        <div className="mt-1 flex flex-wrap gap-1">
                          {staff.fixed.sort((a, b) => a.weekday - b.weekday).map((f, idx) => (
                            <span key={idx} className="inline-flex items-center px-1.5 py-0.5 rounded text-[10px] font-medium bg-slate-100 text-slate-600 border border-slate-200">
                              {getWeekdayLabel(f.weekday)}: {f.start}-{f.end}
                            </span>
                          ))}
                        </div>
                      )}
                    </div>
                  </div>
                  
                  <div className="flex items-center space-x-6">
                    <div className="flex items-center space-x-2 w-24">
                      {getStatusIcon(staff.status)}
                      <span className={cn("text-sm", {
                        "text-green-600": staff.status === "complete",
                        "text-amber-600": staff.status === "partial",
                        "text-gray-500": staff.status === "offmonth" || staff.status === "notset"
                      })}>
                        {getStatusText(staff.status)}
                      </span>
                    </div>
                    <button 
                      onClick={() => deleteStaff(staff.id)}
                      className="p-2 text-slate-400 hover:text-red-500 transition-colors"
                    >
                      <Trash2 className="w-5 h-5" />
                    </button>
                  </div>
                </div>
              </li>
            ))}
          </ul>
        </div>

        <div className="mt-8 flex justify-end space-x-4">
          <button
            onClick={() => router.push("/availability")}
            className="px-6 py-3 bg-white border border-slate-300 text-slate-700 rounded-lg hover:bg-slate-50 font-medium"
          >
            全員の状況を確認
          </button>
          <button
            onClick={() => router.push("/auto-shift")}
            className="px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 font-medium shadow-md"
          >
            シフト自動生成へ
          </button>
        </div>
      </main>

      {/* Add Staff Modal */}
      {isAddModalOpen && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-6 w-full max-w-md shadow-xl">
            <h3 className="text-lg font-bold mb-4">スタッフ追加</h3>
            <div className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700">姓</label>
                  <input
                    type="text"
                    value={lastName}
                    onChange={(e) => setLastName(e.target.value)}
                    className="mt-1 block w-full border border-gray-300 rounded-md p-2"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700">名</label>
                  <input
                    type="text"
                    value={firstName}
                    onChange={(e) => setFirstName(e.target.value)}
                    className="mt-1 block w-full border border-gray-300 rounded-md p-2"
                  />
                </div>
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700">役割</label>
                <select
                  value={role}
                  onChange={(e) => setRole(e.target.value as Role)}
                  className="mt-1 block w-full border border-gray-300 rounded-md p-2"
                >
                  <option value="社員">社員</option>
                  <option value="パート">パート</option>
                  <option value="アルバイト">アルバイト</option>
                </select>
              </div>
              <div className="flex justify-end space-x-3 mt-6">
                <button
                  onClick={() => setIsAddModalOpen(false)}
                  className="px-4 py-2 text-slate-600 hover:bg-slate-100 rounded-md"
                >
                  キャンセル
                </button>
                <button
                  onClick={handleAddStaff}
                  className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700"
                >
                  追加
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
