function daysInMonth(year, month) {
    // UTC の正午を基準にし、DST 影響を排除
    return new Date(Date.UTC(year, month + 1, 0, 12)).getUTCDate();
}

function firstDayOfWeek(year, month) {
    return new Date(Date.UTC(year, month, 1, 12)).getUTCDay(); // 0 = Sunday
}

function isoDate(year, month, day) {
    const mm = (month + 1).toString().padStart(2, "0");
    const dd = day.toString().padStart(2, "0");
    return `${year}-${mm}-${dd}`;
}

function weekday1to7(year, month, day) {
    const wd0 = new Date(Date.UTC(year, month, day, 12)).getUTCDay(); // 0=Sun
    return wd0 === 0 ? 7 : wd0; // 1=Mon ... 7=Sun
}

function yearMonthPrefix(year, month) {
    return `${year}-${(month + 1).toString().padStart(2, "0")}-`
}

function buildCalendarDays(year, month) {
    const total = daysInMonth(year, month);
    const offset = firstDayOfWeek(year, month);
    const days = [];
    for (let i = 0; i < offset; i++) {
        days.push(null);
    }
    for (let d = 1; d <= total; d++) {
        days.push({ day: d, iso: isoDate(year, month, d) });
    }
    return days;
}
