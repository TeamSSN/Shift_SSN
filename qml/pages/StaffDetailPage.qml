import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ShiftApp 1.0
import "../components" as Components
import "../logic/CalendarUtils.js" as Cal

Page {
    id: page
    property var staffId: -1
    signal done()

    title: "個人設定"

    property var staff: ({ name: "不明", role: "スタッフ", fixed: [], availability: {} })
    property string lastEditedIso: ""
    property string editingIso: ""
    property int daysInMonth: Cal.daysInMonth(AppState.selectedMonth.getFullYear(), AppState.selectedMonth.getMonth())
    property var copySelection: []
    property int fixedWeekday: 1
    property string fixedStart: "10:00"
    property string fixedEnd: "18:00"
    property var weekdayNames: ["", "月", "火", "水", "木", "金", "土", "日"]
    property var roleOptions: ["社員", "パート", "アルバイト"]
    property var roleModel: roleOptions
    property bool copyMode: false
    property string copySourceIso: ""
    property var copyTargetsIso: []

    function refreshStaff() {
        const found = AppState.getStaff(staffId)
        if (found)
            staff = found
        else
            staff = { name: "不明", role: "スタッフ", fixed: [], availability: {} }
        if (staff.fixed.length > 0) {
            fixedWeekday = staff.fixed[0].weekday
            fixedStart = staff.fixed[0].start
            fixedEnd = staff.fixed[0].end
        }
        // 役割がプリセット外なら追加
        roleModel = roleOptions
        if (staff.role && roleOptions.indexOf(staff.role) === -1)
            roleModel = roleOptions.concat([staff.role])
        if (roleBox)
            roleBox.currentIndex = Math.max(0, roleModel.indexOf(staff.role || roleOptions[0]))
    }

    Component.onCompleted: refreshStaff()
    onStaffIdChanged: refreshStaff()
    Connections {
        target: AppState
        function onStaffEntriesChanged() { refreshStaff() }
    }

    Components.AvailabilityDialog {
        id: editor
        isoDate: editingIso
        daysInMonth: daysInMonth
        year: AppState.selectedMonth.getFullYear()
        month: AppState.selectedMonth.getMonth()
        existing: AppState.getAvailability(staffId, editingIso)
        onCopyModeRequested: function(enabled, sourceIso) {
            copyMode = enabled
            if (enabled) {
                copySourceIso = sourceIso
                copyTargetsIso = []
            } else {
                copySourceIso = ""
                copyTargetsIso = []
            }
        }
        onConfirmed: function(payload, keepCopyMode) {
            AppState.setAvailability(staffId, editingIso, payload)
            lastEditedIso = editingIso
            if (keepCopyMode) {
                if (copyTargetsIso.length > 0) {
                    AppState.copyAvailability(staffId, copySourceIso || editingIso, copyTargetsIso)
                }
            }
            copyMode = false
            copySourceIso = ""
            copyTargetsIso = []
        }
    }

    Dialog {
        id: copyDialog
        modal: true
        title: "コピー先を選択（同月内）"
        standardButtons: Dialog.Ok | Dialog.Cancel
        onAccepted: {
            if (lastEditedIso === "")
                return
            const targets = copySelection.map(function(day) {
                return Cal.isoDate(AppState.selectedMonth.getFullYear(), AppState.selectedMonth.getMonth(), day)
            })
            AppState.copyAvailability(staffId, lastEditedIso, targets)
        }
        contentItem: Flickable {
            contentWidth: parent ? parent.width : 360
            contentHeight: contentItem.childrenRect.height
            clip: true
            ColumnLayout {
                width: contentWidth
                spacing: 6
                Repeater {
                    model: daysInMonth
                    delegate: CheckBox {
                        required property int modelData
                        text: modelData + "日"
                        checked: copySelection.indexOf(modelData) !== -1
                        onToggled: {
                            const idx = copySelection.indexOf(modelData)
                            if (checked && idx === -1) {
                                copySelection = copySelection.concat([modelData])
                            } else if (!checked && idx !== -1) {
                                const next = copySelection.slice()
                                next.splice(idx, 1)
                                copySelection = next
                            }
                        }
                    }
                }
            }
        }
    }

    Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: contentColumn.implicitHeight + 20
        clip: true

        ColumnLayout {
            id: contentColumn
            width: parent.width
            anchors.margins: 14
            spacing: 14

            RowLayout {
                spacing: 8
                Button { text: "戻る"; onClicked: done(); font.bold: true }
                Label { text: staff.name; font.pixelSize: 22; font.bold: true }
                Label { text: staff.role; color: "#666" }
            }

            Rectangle {
                color: "#ffffff"
                radius: 10
                border.color: "#d9e1ec"
                Layout.fillWidth: true
                Layout.preferredHeight: contentRow.implicitHeight + 20
                RowLayout {
                    id: contentRow
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 16
                    ColumnLayout {
                        spacing: 8
                        Label { text: "固定シフト (曜日ごとに1枠まで。複数曜日可)" }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 6
                            Repeater {
                                model: staff.fixed
                                delegate: Rectangle {
                                    color: "#e8f0fe"
                                    radius: 8
                                    border.color: "#c3d2fa"
                                    Layout.fillWidth: true
                                    height: 34
                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 8
                                        spacing: 8
                                        Label {
                                        text: `${weekdayNames[modelData.weekday] || "?"}  ${modelData.start} - ${modelData.end}`
                                            color: "#1a237e"
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }
                                        ToolButton {
                                            text: "×"
                                            onClicked: AppState.setFixedShift(staffId, modelData.weekday, "", "")
                                        }
                                    }
                                }
                            }
                            Rectangle {
                                height: 1
                                color: "#e0e5eb"
                                Layout.fillWidth: true
                                visible: staff.fixed.length > 0
                            }
                            RowLayout {
                                spacing: 6
                                Label { text: "曜日" }
                                ComboBox {
                                    id: weekdayBox
                                    model: [
                                        { label: "月", value: 1 },
                                        { label: "火", value: 2 },
                                        { label: "水", value: 3 },
                                        { label: "木", value: 4 },
                                        { label: "金", value: 5 },
                                        { label: "土", value: 6 },
                                        { label: "日", value: 7 }
                                    ]
                                    textRole: "label"
                                    valueRole: "value"
                                    currentIndex: model.findIndex(function(entry) { return entry.value === fixedWeekday })
                                    onActivated: function(idx) { fixedWeekday = model[idx].value }
                                    width: 80
                                }
                                Label { text: "開始" }
                                TextField {
                                    text: fixedStart
                                    onTextChanged: fixedStart = text
                                    width: 80
                                    placeholderText: "hh:mm"
                                }
                                Label { text: "終了" }
                                TextField {
                                    text: fixedEnd
                                    onTextChanged: fixedEnd = text
                                    width: 80
                                    placeholderText: "hh:mm"
                                }
                                Button {
                                    text: "追加/上書き"
                                    onClicked: AppState.setFixedShift(staffId, fixedWeekday, fixedStart, fixedEnd)
                                }
                            }
                        }
                    }
                    Item { Layout.fillWidth: true }
                }
            }

            Label {
                text: "日付をタップして出勤可否を設定（1日1枠）。固定シフトは自動反映。"
                color: "#666"
            }

            Components.MonthGrid {
                id: grid
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.topMargin: 12
                year: AppState.selectedMonth.getFullYear()
                month: AppState.selectedMonth.getMonth()
                badgeProvider: function(iso) {
                    const slot = AppState.getAvailability(staffId, iso)
                    if (!slot) return ""
                    if (slot.type === "off") return "×"
                    if (slot.type === "available") return "○"
                    if (slot.type === "window") return `${slot.start}-${slot.end}`
                    if (slot.type === "free") return "F"
                    return ""
                }
                colorProvider: function(iso) {
                    const slot = AppState.getAvailability(staffId, iso)
                    var base = "#ffffff"
                    if (slot) {
                        if (slot.type === "off") base = "#ffe6e6"
                        else if (slot.type === "available") base = "#e8f5e9"
                        else if (slot.type === "window") base = "#e3f2fd"
                        else if (slot.type === "free") base = "#fff3e0"
                    }
                    if (copyMode) {
                        if (iso === copySourceIso)
                            return "#d1c4e9"
                        if (copyTargetsIso.indexOf(iso) !== -1)
                            return "#ede7f6"
                    }
                    return base
                }
                onDaySelected: (iso, day) => {
                    if (copyMode) {
                        const slot = AppState.getAvailability(staffId, iso)
                        if (!copySourceIso) {
                            if (!slot) return
                            copySourceIso = iso
                        } else {
                            if (iso === copySourceIso) return
                            const idx = copyTargetsIso.indexOf(iso)
                            if (idx === -1)
                                copyTargetsIso = copyTargetsIso.concat([iso])
                            else {
                                const next = copyTargetsIso.slice()
                                next.splice(idx, 1)
                                copyTargetsIso = next
                            }
                        }
                    } else {
                        editingIso = iso
                        editor.open()
                    }
                }
            }
        }
    }
}
