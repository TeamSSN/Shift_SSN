import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ShiftApp 1.0
import "../logic/CalendarUtils.js" as Cal

Page {
    id: page
    signal back()
    title: "自動シフト生成 (β)"

    property int requiredPerDay: 2
    property int daysInMonth: Cal.daysInMonth(AppState.selectedMonth.getFullYear(), AppState.selectedMonth.getMonth())

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        RowLayout {
            spacing: 8
            Button { text: "戻る"; onClicked: back() }
            Label { text: "固定シフト優先 → 時間帯一致 → 均等割り当て（簡易版）"; color: "#607d8b" }
        }

        Rectangle {
            color: "#f5f5f5"
            radius: 6
            border.color: "#e0e0e0"
            Layout.fillWidth: true
            Layout.preferredHeight: 80
            RowLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 12
                Label { text: "日別必要人数" }
                SpinBox {
                    id: requiredBox
                    from: 1
                    to: 8
                    value: requiredPerDay
                    onValueChanged: requiredPerDay = value
                }
                Button {
                    text: "生成"
                    onClicked: AppState.generateDraft(requiredPerDay)
                }
                Label {
                    text: "出勤可データがない日が多い場合は割り当て不足として表示されます"
                    color: "#555"
                }
            }
        }

        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: daysInMonth
            clip: true
            delegate: Rectangle {
                width: parent ? parent.width : 400
                height: 64
                color: index % 2 === 0 ? "#ffffff" : "#fafafa"
                border.color: "#e0e0e0"
                readonly property int day: index + 1
                readonly property string iso: Cal.isoDate(AppState.selectedMonth.getFullYear(), AppState.selectedMonth.getMonth(), day)
                readonly property var draft: AppState.autoShiftDraft[iso] || { assigned: [], missing: requiredPerDay }
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 8
                    Label { text: iso; width: 110 }
                    Label {
                        text: draft.assigned.length > 0 ? draft.assigned.map(a => a.name + annotateSlot(a.window)).join(", ") : "割り当てなし"
                        Layout.fillWidth: true
                        wrapMode: Text.Wrap
                    }
                    Label {
                        text: draft.missing > 0 ? `不足: ${draft.missing}` : "充足"
                        color: draft.missing > 0 ? "#e53935" : "#4caf50"
                        width: 80
                    }
                }

                function annotateSlot(window) {
                    if (!window) return ""
                    if (window.type === "window") return ` (${window.start}-${window.end})`
                    if (window.type === "available") return " (終日)"
                    if (window.type === "free") return " (F)"
                    return ""
                }
            }
        }
    }
}
