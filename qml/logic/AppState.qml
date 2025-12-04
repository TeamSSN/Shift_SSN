pragma Singleton

import QtQuick
import QtQuick.LocalStorage as Sql
import "CalendarUtils.js" as Cal

QtObject {
    id: state

    property bool isAuthenticated: false
    property string userEmail: ""
    property string lastAuthError: ""
    property date selectedMonth: new Date(new Date().getFullYear(), new Date().getMonth() + 1, 1)

    // 初期データはデモ用。ログイン時に DB から読み込まれて上書きされます。
    property var staffEntries: [
        {
            id: 1,
            lastName: "佐藤",
            firstName: "梓",
            name: "佐藤 梓",
            role: "店長",
            status: "partial",
            fixed: [{ weekday: 1, start: "10:00", end: "16:00" }],
            availability: {}
        },
        {
            id: 2,
            lastName: "中村",
            firstName: "蒼",
            name: "中村 蒼",
            role: "大学生",
            status: "notset",
            fixed: [{ weekday: 5, start: "12:00", end: "18:00" }],
            availability: {}
        },
        {
            id: 3,
            lastName: "高橋",
            firstName: "真希",
            name: "高橋 真希",
            role: "パート",
            status: "complete",
            fixed: [],
            availability: {}
        }
    ]

    // DB やローカル識別用
    property bool dbReady: false
    property string accountKey: "local"
    // 新規追加用の連番
    property int nextStaffId: initialMaxId()

    property var autoShiftDraft: ({})

    function combineName(lastName, firstName) {
        const ln = (lastName || "").trim()
        const fn = (firstName || "").trim()
        if (ln && fn)
            return ln + " " + fn
        return ln || fn
    }

    function splitFullName(fullName) {
        const raw = (fullName || "").trim()
        if (raw === "")
            return { lastName: "", firstName: "" }
        const parts = raw.split(/[\s　]+/)
        if (parts.length === 1)
            return { lastName: parts[0], firstName: "" }
        const last = parts.shift()
        return { lastName: last, firstName: parts.join(" ") }
    }

    function normalizeNameParts(lastName, firstName, fallbackFullName) {
        const ln = (lastName || "").trim()
        const fn = (firstName || "").trim()
        if (ln || fn)
            return { lastName: ln, firstName: fn }
        return splitFullName(fallbackFullName)
    }

    function fullName(staff) {
        if (!staff)
            return ""
        return combineName(staff.lastName, staff.firstName)
    }

    function lastNameOnly(staff) {
        if (!staff)
            return ""
        const ln = (staff.lastName || "").trim()
        if (ln !== "")
            return ln
        return splitFullName(fullName(staff)).lastName
    }

    function db() {
        return Sql.LocalStorage.openDatabaseSync("ShiftTemplateApp", "1.0", "Shift template local store", 2 * 1024 * 1024);
    }

    function initDb() {
        const database = db()
        database.transaction(function(tx) {
            tx.executeSql("CREATE TABLE IF NOT EXISTS accounts (email TEXT PRIMARY KEY, password TEXT)");
            tx.executeSql("CREATE TABLE IF NOT EXISTS staff (id INTEGER PRIMARY KEY AUTOINCREMENT, account TEXT, name TEXT, last_name TEXT, first_name TEXT, role TEXT)");
            tx.executeSql("CREATE TABLE IF NOT EXISTS fixed_shift (id INTEGER PRIMARY KEY AUTOINCREMENT, staff_id INTEGER, weekday INTEGER, start TEXT, end TEXT)");
            tx.executeSql("CREATE TABLE IF NOT EXISTS availability (id INTEGER PRIMARY KEY AUTOINCREMENT, staff_id INTEGER, date TEXT, type TEXT, start TEXT, end TEXT)");
            ensureStaffNameColumns(tx)
            migrateStaffNames(tx)
        })
        dbReady = true
    }

    function ensureStaffNameColumns(tx) {
        const rs = tx.executeSql("PRAGMA table_info(staff)")
        let hasLast = false
        let hasFirst = false
        for (let i = 0; i < rs.rows.length; i++) {
            const colName = rs.rows.item(i).name
            if (colName === "last_name")
                hasLast = true
            if (colName === "first_name")
                hasFirst = true
        }
        if (!hasLast)
            tx.executeSql("ALTER TABLE staff ADD COLUMN last_name TEXT")
        if (!hasFirst)
            tx.executeSql("ALTER TABLE staff ADD COLUMN first_name TEXT")
    }

    function migrateStaffNames(tx) {
        const rs = tx.executeSql("SELECT id, name, last_name, first_name FROM staff")
        for (let i = 0; i < rs.rows.length; i++) {
            const row = rs.rows.item(i)
            const normalized = normalizeNameParts(row.last_name, row.first_name, row.name)
            const combined = combineName(normalized.lastName, normalized.firstName)
            const currentLast = (row.last_name || "").trim()
            const currentFirst = (row.first_name || "").trim()
            if (normalized.lastName !== currentLast || normalized.firstName !== currentFirst || row.name !== combined) {
                tx.executeSql("UPDATE staff SET last_name = ?, first_name = ?, name = ? WHERE id = ?",
                              [normalized.lastName, normalized.firstName, combined, row.id])
            }
        }
    }

    function initialMaxId() {
        var max = 0
        staffEntries.forEach(function(s) { if (s.id > max) max = s.id })
        return max + 1
    }

    function computeNextStaffId() {
        // start from in-memory guess
        let candidate = initialMaxId()
        // adjust by DB max if available
        if (dbReady) {
            const database = db()
            database.readTransaction(function(tx) {
                const rs = tx.executeSql("SELECT MAX(id) AS maxId FROM staff")
                if (rs.rows.length === 1 && rs.rows.item(0).maxId !== null) {
                    const dbMax = rs.rows.item(0).maxId
                    if (dbMax + 1 > candidate)
                        candidate = dbMax + 1
                }
            })
        }
        // never go backwards
        if (candidate < nextStaffId)
            candidate = nextStaffId
        return candidate
    }

    function newStaffId() {
        nextStaffId = computeNextStaffId()
        return nextStaffId
    }

    function getStaff(staffId) {
        return staffEntries.find(function(s) { return s.id === staffId }) || null
    }

    function loadStaffFromDb() {
        if (!dbReady) initDb()
        const database = db()
        const rows = []
        database.readTransaction(function(tx) {
            const rs = tx.executeSql("SELECT id, name, last_name, first_name, role FROM staff WHERE account = ?", [accountKey])
            for (let i = 0; i < rs.rows.length; i++) {
                rows.push(rs.rows.item(i))
            }
        })
        const loaded = rows.map(function(r) {
            const names = normalizeNameParts(r.last_name, r.first_name, r.name)
            const displayName = combineName(names.lastName, names.firstName)
            return {
                id: r.id,
                lastName: names.lastName,
                firstName: names.firstName,
                name: displayName,
                role: r.role || "スタッフ",
                status: "notset",
                fixed: [],
                availability: {}
            }
        })
        // 固定シフトを付与
        database.readTransaction(function(tx) {
            loaded.forEach(function(staff) {
                const rs = tx.executeSql("SELECT weekday, start, end FROM fixed_shift WHERE staff_id = ?", [staff.id])
                const fx = []
                for (let i = 0; i < rs.rows.length; i++) {
                    const row = rs.rows.item(i)
                    fx.push({ weekday: row.weekday, start: row.start, end: row.end })
                }
                staff.fixed = fx
            })
        })
        // 取得件数が 0 でも初期データをクリアして空の名簿にする
        staffEntries = refreshStatuses(loaded)
        nextStaffId = computeNextStaffId()
        // 現在の月の出勤可否をロードして固定シフトを反映
        loadAvailabilityForMonth(selectedMonth.getFullYear(), selectedMonth.getMonth())
        applyFixedToSelectedMonth()
    }

    function statusFromAvailability(staff) {
        if (staff.status === "offmonth")
            return "offmonth"
        const year = selectedMonth.getFullYear()
        const month = selectedMonth.getMonth()
        const totalDays = Cal.daysInMonth(year, month)
        let filled = 0
        for (let d = 1; d <= totalDays; d++) {
            const iso = Cal.isoDate(year, month, d)
            if (staff.availability[iso])
                filled++
        }
        if (filled === 0)
            return "notset"
        if (filled >= totalDays)
            return "complete"
        return "partial"
    }

    function refreshStatuses(entries) {
        const withStatus = entries.map(function(s) {
            return Object.assign({}, s, { status: statusFromAvailability(s) })
        })
        return sortStaffEntries(withStatus)
    }

    function rolePriority(role) {
        if (role === "社員") return 0
        if (role === "パート") return 1
        if (role === "アルバイト") return 2
        return 3
    }

    function sortStaffEntries(entries) {
        return entries.slice().sort(function(a, b) {
            const pa = rolePriority(a.role)
            const pb = rolePriority(b.role)
            if (pa !== pb)
                return pa - pb
            // fallback: ID asc for stability
            return a.id - b.id
        })
    }

    function registerAccount(email, password) {
        if (!email || !password) {
            lastAuthError = "メールとパスワードを入力してください"
            return false
        }
        if (!dbReady) initDb()
        const trimmed = email.trim()
        const database = db()
        let exists = false
        database.readTransaction(function(tx) {
            const rs = tx.executeSql("SELECT email FROM accounts WHERE email = ?", [trimmed])
            if (rs.rows.length > 0)
                exists = true
        })
        if (exists) {
            lastAuthError = "すでに登録されています"
            return false
        }
        database.transaction(function(tx) {
            tx.executeSql("INSERT INTO accounts (email, password) VALUES (?, ?)", [trimmed, password])
        })
        lastAuthError = ""
        return true
    }

    function login(email, password) {
        if (!email || !password) {
            lastAuthError = "メールとパスワードを入力してください"
            isAuthenticated = false
            return false
        }
        if (!dbReady) initDb()
        const trimmed = email.trim()
        let ok = false
        const database = db()
        database.readTransaction(function(tx) {
            const rs = tx.executeSql("SELECT password FROM accounts WHERE email = ?", [trimmed])
            if (rs.rows.length === 1) {
                const row = rs.rows.item(0)
                if (row.password === password)
                    ok = true
            }
        })
        if (!ok) {
            lastAuthError = "メールまたはパスワードが違います"
            isAuthenticated = false
            userEmail = ""
            staffEntries = []
            return false
        }
        isAuthenticated = true
        userEmail = trimmed
        accountKey = trimmed
        lastAuthError = ""
        loadStaffFromDb()
        return true
    }

    function logout() {
        isAuthenticated = false
        userEmail = ""
        accountKey = "local"
        staffEntries = []
        autoShiftDraft = {}
    }

    function setMonth(year, monthIndex) {
        selectedMonth = new Date(year, monthIndex, 1)
        loadAvailabilityForMonth(year, monthIndex)
        applyFixedToSelectedMonth()
    }

    function addStaff(lastName, firstName, roleText) {
        const ln = (lastName || "").trim()
        const fn = (firstName || "").trim()
        if (ln === "" && fn === "")
            return
        if (!dbReady) initDb()
        const roleVal = (roleText && roleText.trim() !== "") ? roleText.trim() : "スタッフ"
        const displayName = combineName(ln, fn)
        let newId = newStaffId()
        const database = db()
        database.transaction(function(tx) {
            tx.executeSql("INSERT INTO staff (id, account, name, last_name, first_name, role) VALUES (?, ?, ?, ?, ?, ?)",
                          [newId, accountKey, displayName, ln, fn, roleVal])
        })
        const clone = staffEntries.slice()
        clone.push({
            id: newId,
            lastName: ln,
            firstName: fn,
            name: displayName,
            role: roleVal,
            status: "notset",
            fixed: [],
            availability: {}
        })
        staffEntries = refreshStatuses(clone)
    }

    function deleteStaff(staffId) {
        if (!dbReady) initDb()
        // DB から関連データを削除
        const database = db()
        database.transaction(function(tx) {
            tx.executeSql("DELETE FROM availability WHERE staff_id = ?", [staffId])
            tx.executeSql("DELETE FROM fixed_shift WHERE staff_id = ?", [staffId])
            tx.executeSql("DELETE FROM staff WHERE id = ?", [staffId])
        })
        // メモリから削除
        staffEntries = staffEntries.filter(function(s) { return s.id !== staffId })
        nextStaffId = computeNextStaffId()
    }

    function setFixedShift(staffId, weekday, start, end) {
        if (!dbReady) initDb()
        staffEntries = refreshStatuses(
                    staffEntries.map(function(s) {
                        if (s.id !== staffId)
                            return s
                        let nextFixed = s.fixed.slice()
                        nextFixed = nextFixed.filter(function(f) { return f.weekday !== weekday })
                        if (weekday && start && end) {
                            nextFixed.push({ weekday: weekday, start: start, end: end })
                        }
                        return Object.assign({}, s, { fixed: nextFixed })
                    }))
        // DB 更新（weekday の既存を削除してから追加）
        const database = db()
        database.transaction(function(tx) {
            tx.executeSql("DELETE FROM fixed_shift WHERE staff_id = ? AND weekday = ?", [staffId, weekday])
            if (weekday && start && end) {
                tx.executeSql("INSERT INTO fixed_shift (staff_id, weekday, start, end) VALUES (?, ?, ?, ?)", [staffId, weekday, start, end])
            }
        })
        applyFixedToSelectedMonth()
    }

    function applyFixedToSelectedMonth() {
        const year = selectedMonth.getFullYear()
        const month = selectedMonth.getMonth()
        const totalDays = Cal.daysInMonth(year, month)
        const monthPrefix = Cal.yearMonthPrefix(year, month)
        staffEntries = refreshStatuses(staffEntries.map(function(s) {
            // 既存の固定由来の枠はリセットし、手動入力のみ残す
            const nextAvailability = {}
            Object.keys(s.availability).forEach(function(key) {
                const slot = s.availability[key]
                // 別月 or 手動の設定は残す
                if (!key.startsWith(monthPrefix) || !slot.fixed)
                    nextAvailability[key] = slot
            })
            if (!s.fixed || s.fixed.length === 0)
                return Object.assign({}, s, { availability: nextAvailability })
            for (let d = 1; d <= totalDays; d++) {
                const weekday = Cal.weekday1to7(year, month, d)
                const fixedEntry = s.fixed.find(function(f) { return f.weekday === weekday })
                if (!fixedEntry)
                    continue
                const iso = Cal.isoDate(year, month, d)
                nextAvailability[iso] = { type: "window", start: fixedEntry.start, end: fixedEntry.end, fixed: true }
            }
            return Object.assign({}, s, { availability: nextAvailability })
        }))
    }

    function loadAvailabilityForMonth(year, month) {
        if (!dbReady) initDb()
        const prefix = Cal.yearMonthPrefix(year, month)
        const database = db()
        const rows = []
        database.readTransaction(function(tx) {
            const rs = tx.executeSql(
                        "SELECT a.staff_id as staff_id, a.date as date, a.type as type, a.start as start, a.end as end "
                        + "FROM availability a JOIN staff s ON a.staff_id = s.id "
                        + "WHERE s.account = ? AND a.date LIKE ?",
                        [accountKey, prefix + "%"])
            for (let i = 0; i < rs.rows.length; i++) {
                rows.push(rs.rows.item(i))
            }
        })
        const cleared = staffEntries.map(function(s) {
            const next = {}
            Object.keys(s.availability).forEach(function(key) {
                if (!key.startsWith(prefix))
                    next[key] = s.availability[key]
            })
            return Object.assign({}, s, { availability: next })
        })
        rows.forEach(function(r) {
            const staff = cleared.find(function(s) { return s.id === r.staff_id })
            if (!staff)
                return
            staff.availability[r.date] = { type: r.type, start: r.start, end: r.end }
        })
        staffEntries = refreshStatuses(cleared)
    }

    function updateStaffStatus(staffId, newStatus) {
        staffEntries = staffEntries.map(function(s) {
            if (s.id === staffId)
                return Object.assign({}, s, { status: newStatus })
            return s
        })
    }

    function updateRole(staffId, newRole) {
        staffEntries = refreshStatuses(staffEntries.map(function(s) {
            if (s.id === staffId)
                return Object.assign({}, s, { role: newRole })
            return s
        }))
    }

    function setAvailability(staffId, isoDate, payload) {
        if (!dbReady) initDb()
        staffEntries = refreshStatuses(staffEntries.map(function(s) {
            if (s.id !== staffId)
                return s
            const nextAvailability = Object.assign({}, s.availability)
            if (payload === null) {
                delete nextAvailability[isoDate]
            } else {
                nextAvailability[isoDate] = payload
            }
            return Object.assign({}, s, { availability: nextAvailability })
        }))
        const database = db()
        database.transaction(function(tx) {
            tx.executeSql("DELETE FROM availability WHERE staff_id = ? AND date = ?", [staffId, isoDate])
            if (payload !== null) {
                tx.executeSql("INSERT INTO availability (staff_id, date, type, start, end) VALUES (?, ?, ?, ?, ?)",
                              [staffId, isoDate, payload.type, payload.start || null, payload.end || null])
            }
        })
    }

    function getAvailability(staffId, isoDate) {
        const staff = staffEntries.find(s => s.id === staffId)
        if (!staff)
            return null
        return staff.availability[isoDate] || null
    }

    function copyAvailability(staffId, sourceIso, targetDays) {
        const slot = getAvailability(staffId, sourceIso)
        if (!slot)
            return
        targetDays.forEach(dayIso => setAvailability(staffId, dayIso, slot))
    }

    function aggregateForDay(isoDate) {
        const available = []
        staffEntries.forEach(s => {
            const slot = s.availability[isoDate]
            if (!slot)
                return
            if (slot.type === "off")
                return
            available.push({ staff: s, slot: slot })
        })
        return {
            count: available.length,
            people: available
        }
    }

    function generateDraft(requiredPerDay) {
        const year = selectedMonth.getFullYear()
        const month = selectedMonth.getMonth()
        const days = Cal.daysInMonth(year, month)
        const load = {}
        staffEntries.forEach(s => load[s.id] = 0)
        const draft = {}
        for (let d = 1; d <= days; d++) {
            const iso = Cal.isoDate(year, month, d)
            const people = aggregateForDay(iso).people
            const ranked = people.slice().sort((a, b) => load[a.staff.id] - load[b.staff.id])
            const assigned = ranked.slice(0, requiredPerDay).map(entry => {
                load[entry.staff.id] += 1
                return { name: fullName(entry.staff), window: entry.slot }
            })
            draft[iso] = {
                assigned: assigned,
                missing: Math.max(0, requiredPerDay - assigned.length)
            }
        }
        autoShiftDraft = draft
    }
}
