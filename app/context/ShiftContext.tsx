"use client";

import React, { createContext, useContext, useState, useEffect, ReactNode } from "react";
import { addMonths, format, getDaysInMonth, startOfMonth, isSameDay, parseISO } from "date-fns";

// Types
export type Role = "社員" | "パート" | "アルバイト";
export type Status = "complete" | "partial" | "notset" | "offmonth";

export interface FixedShift {
  weekday: number; // 1 (Mon) - 7 (Sun)
  start: string;
  end: string;
}

export interface AvailabilitySlot {
  type: "window" | "off" | "free";
  start?: string;
  end?: string;
  fixed?: boolean;
}

export interface Staff {
  id: number;
  lastName: string;
  firstName: string;
  name: string;
  role: Role;
  status: Status;
  fixed: FixedShift[];
  availability: Record<string, AvailabilitySlot>; // key: YYYY-MM-DD
}

interface ShiftContextType {
  isAuthenticated: boolean;
  userEmail: string;
  selectedMonth: Date;
  staffList: Staff[];
  login: (email: string) => void;
  logout: () => void;
  setMonth: (date: Date) => void;
  addStaff: (lastName: string, firstName: string, role: Role) => void;
  updateStaff: (staff: Staff) => void;
  deleteStaff: (id: number) => void;
  getStaff: (id: number) => Staff | undefined;
  setFixedShift: (staffId: number, weekday: number, start: string, end: string) => void;
  removeFixedShift: (staffId: number, weekday: number) => void;
  setAvailability: (staffId: number, date: string, slot: AvailabilitySlot | null) => void;
  copyAvailability: (staffId: number, sourceDate: string, targetDates: string[]) => void;
  generateDraft: (requiredPerDay: number) => Record<string, any>;
}

const ShiftContext = createContext<ShiftContextType | undefined>(undefined);

// Initial Mock Data
const INITIAL_STAFF: Staff[] = [
  {
    id: 1,
    lastName: "佐藤",
    firstName: "梓",
    name: "佐藤 梓",
    role: "社員",
    status: "partial",
    fixed: [{ weekday: 1, start: "10:00", end: "16:00" }],
    availability: {},
  },
  {
    id: 2,
    lastName: "中村",
    firstName: "蒼",
    name: "中村 蒼",
    role: "アルバイト", // Mapped from "大学生" in QML to Role type
    status: "notset",
    fixed: [{ weekday: 5, start: "12:00", end: "18:00" }],
    availability: {},
  },
  {
    id: 3,
    lastName: "高橋",
    firstName: "真希",
    name: "高橋 真希",
    role: "パート",
    status: "complete",
    fixed: [],
    availability: {},
  },
];

const rolePriority = (role: Role): number => {
  switch (role) {
    case "社員": return 1;
    case "パート": return 2;
    case "アルバイト": return 3;
    default: return 4;
  }
};

const sortStaffList = (list: Staff[]) => {
  return [...list].sort((a, b) => {
    const pA = rolePriority(a.role);
    const pB = rolePriority(b.role);
    if (pA !== pB) return pA - pB;
    return a.id - b.id;
  });
};

export function ShiftProvider({ children }: { children: ReactNode }) {
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [userEmail, setUserEmail] = useState("");
  const [selectedMonth, setSelectedMonth] = useState<Date>(addMonths(startOfMonth(new Date()), 1));
  const [staffList, setStaffList] = useState<Staff[]>(sortStaffList(INITIAL_STAFF));

  // Helper to calculate status based on availability
  const calculateStatus = (staff: Staff, month: Date): Status => {
    if (staff.status === "offmonth") return "offmonth";
    
    const daysInMonth = getDaysInMonth(month);
    let filled = 0;
    const monthPrefix = format(month, "yyyy-MM");

    for (let d = 1; d <= daysInMonth; d++) {
      const dateStr = `${monthPrefix}-${String(d).padStart(2, "0")}`;
      if (staff.availability[dateStr]) {
        filled++;
      }
    }

    if (filled === 0) return "notset";
    if (filled >= daysInMonth) return "complete";
    return "partial";
  };

  const refreshStatuses = (list: Staff[], month: Date) => {
    return list.map((s) => ({
      ...s,
      status: calculateStatus(s, month),
    }));
  };

  // Apply fixed shifts to the selected month
  const applyFixedToMonth = (list: Staff[], month: Date) => {
    const daysInMonth = getDaysInMonth(month);
    const monthPrefix = format(month, "yyyy-MM");

    return list.map((staff) => {
      const newAvailability = { ...staff.availability };
      
      // Remove existing fixed entries for this month to re-apply
      Object.keys(newAvailability).forEach((key) => {
        if (key.startsWith(monthPrefix) && newAvailability[key].fixed) {
          delete newAvailability[key];
        }
      });

      if (staff.fixed.length > 0) {
        for (let d = 1; d <= daysInMonth; d++) {
          const date = new Date(month.getFullYear(), month.getMonth(), d);
          const dateStr = format(date, "yyyy-MM-dd");
          // date-fns getDay: 0 (Sun) - 6 (Sat). We use 1 (Mon) - 7 (Sun)
          let weekday = date.getDay();
          if (weekday === 0) weekday = 7;

          const fixedEntry = staff.fixed.find((f) => f.weekday === weekday);
          
          // Only apply if not already set manually (manual override logic from QML)
          // QML logic: "別月 or 手動の設定は残す" -> "Existing manual settings remain"
          // But here we deleted fixed entries. So if there is an entry left, it's manual.
          if (fixedEntry && !newAvailability[dateStr]) {
            newAvailability[dateStr] = {
              type: "window",
              start: fixedEntry.start,
              end: fixedEntry.end,
              fixed: true,
            };
          }
        }
      }
      return { ...staff, availability: newAvailability };
    });
  };

  // Effect to re-apply fixed shifts when month changes
  useEffect(() => {
    setStaffList((prev) => {
      const withFixed = applyFixedToMonth(prev, selectedMonth);
      return refreshStatuses(withFixed, selectedMonth);
    });
  }, [selectedMonth]);

  const login = (email: string) => {
    setIsAuthenticated(true);
    setUserEmail(email);
  };

  const logout = () => {
    setIsAuthenticated(false);
    setUserEmail("");
  };

  const setMonth = (date: Date) => {
    setSelectedMonth(startOfMonth(date));
  };

  const addStaff = (lastName: string, firstName: string, role: Role) => {
    const newId = Math.max(...staffList.map((s) => s.id), 0) + 1;
    const newStaff: Staff = {
      id: newId,
      lastName,
      firstName,
      name: `${lastName} ${firstName}`,
      role,
      status: "notset",
      fixed: [],
      availability: {},
    };
    setStaffList((prev) => sortStaffList(refreshStatuses([...prev, newStaff], selectedMonth)));
  };

  const updateStaff = (updatedStaff: Staff) => {
    setStaffList((prev) =>
      sortStaffList(refreshStatuses(
        prev.map((s) => (s.id === updatedStaff.id ? updatedStaff : s)),
        selectedMonth
      ))
    );
  };

  const deleteStaff = (id: number) => {
    setStaffList((prev) => prev.filter((s) => s.id !== id));
  };

  const getStaff = (id: number) => staffList.find((s) => s.id === id);

  const setFixedShift = (staffId: number, weekday: number, start: string, end: string) => {
    setStaffList((prev) => {
      const updatedList = prev.map((s) => {
        if (s.id !== staffId) return s;
        const newFixed = s.fixed.filter((f) => f.weekday !== weekday);
        newFixed.push({ weekday, start, end });
        return { ...s, fixed: newFixed };
      });
      const withFixed = applyFixedToMonth(updatedList, selectedMonth);
      return refreshStatuses(withFixed, selectedMonth);
    });
  };

  const removeFixedShift = (staffId: number, weekday: number) => {
    setStaffList((prev) => {
      const updatedList = prev.map((s) => {
        if (s.id !== staffId) return s;
        return { ...s, fixed: s.fixed.filter((f) => f.weekday !== weekday) };
      });
      const withFixed = applyFixedToMonth(updatedList, selectedMonth);
      return refreshStatuses(withFixed, selectedMonth);
    });
  };

  const setAvailability = (staffId: number, date: string, slot: AvailabilitySlot | null) => {
    setStaffList((prev) => {
      const updatedList = prev.map((s) => {
        if (s.id !== staffId) return s;
        const newAvailability = { ...s.availability };
        if (slot === null) {
          delete newAvailability[date];
        } else {
          newAvailability[date] = slot;
        }
        return { ...s, availability: newAvailability };
      });
      return refreshStatuses(updatedList, selectedMonth);
    });
  };

  const copyAvailability = (staffId: number, sourceDate: string, targetDates: string[]) => {
    setStaffList((prev) => {
      const staff = prev.find((s) => s.id === staffId);
      if (!staff) return prev;
      const slot = staff.availability[sourceDate];
      if (!slot) return prev;

      const updatedList = prev.map((s) => {
        if (s.id !== staffId) return s;
        const newAvailability = { ...s.availability };
        targetDates.forEach((targetDate) => {
          newAvailability[targetDate] = slot;
        });
        return { ...s, availability: newAvailability };
      });
      return refreshStatuses(updatedList, selectedMonth);
    });
  };

  const generateDraft = (requiredPerDay: number) => {
    // Simplified draft generation
    const daysInMonth = getDaysInMonth(selectedMonth);
    const monthPrefix = format(selectedMonth, "yyyy-MM");
    const draft: Record<string, any> = {};
    const load: Record<number, number> = {};
    staffList.forEach(s => load[s.id] = 0);

    for (let d = 1; d <= daysInMonth; d++) {
      const dateStr = `${monthPrefix}-${String(d).padStart(2, "0")}`;
      const availablePeople = staffList.filter(s => {
        const slot = s.availability[dateStr];
        return slot && slot.type !== "off";
      });

      // Sort by load (least shifts first)
      availablePeople.sort((a, b) => load[a.id] - load[b.id]);

      const assigned = availablePeople.slice(0, requiredPerDay).map(s => {
        load[s.id]++;
        return { name: s.name, window: s.availability[dateStr] };
      });

      draft[dateStr] = {
        assigned,
        missing: Math.max(0, requiredPerDay - assigned.length)
      };
    }
    return draft;
  };

  return (
    <ShiftContext.Provider
      value={{
        isAuthenticated,
        userEmail,
        selectedMonth,
        staffList,
        login,
        logout,
        setMonth,
        addStaff,
        updateStaff,
        deleteStaff,
        getStaff,
        setFixedShift,
        removeFixedShift,
        setAvailability,
        copyAvailability,
        generateDraft,
      }}
    >
      {children}
    </ShiftContext.Provider>
  );
}

export function useShift() {
  const context = useContext(ShiftContext);
  if (context === undefined) {
    throw new Error("useShift must be used within a ShiftProvider");
  }
  return context;
}
