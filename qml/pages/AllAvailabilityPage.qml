import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ShiftApp 1.0
import "../components" as Components

Page {
    id: page
    signal back()
    title: "全員の出勤可能一覧"

    property string selectedIso: ""
    property var selectedPeople: []

    Dialog {
        id: detailDialog
        title: selectedIso + " の出勤可能者"
        modal: true
        standardButtons: Dialog.Ok
        contentItem: ListView {
            model: selectedPeople
            delegate: Item {
                width: 320
                height: 40
                property color roleColor: modelData.staff.role === "社員" ? "#d32f2f" : (modelData.staff.role === "パート" ? "#2e7d32" : "#000000")
                RowLayout {
                    anchors.fill: parent
                    Label { text: modelData.staff.name; Layout.fillWidth: true; color: roleColor }
                    Label { text: modelData.staff.role; color: roleColor; width: 70 }
                    Label {
                        text: modelData.slot.type === "window"
                              ? `${modelData.slot.start}-${modelData.slot.end}`
                              : (modelData.slot.type === "available" ? "終日" : (modelData.slot.type === "free" ? "F" : ""))
                        color: "#555"
                    }
                }
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        RowLayout {
            spacing: 8
            Button { text: "戻る"; onClicked: back() }
            Label { text: "姓のみ表示（役職色: 社員=赤, パート=緑, アルバイト=黒）"; color: "#555" }
            Item { Layout.fillWidth: true }
            Label { text: "タップで詳細表示"; color: "#607d8b" }
        }

        Components.MonthGrid {
            Layout.fillWidth: true
            Layout.fillHeight: true
            badgeProvider: function(iso) {
                const agg = AppState.aggregateForDay(iso)
                if (!agg.count) return ""
                const mapped = agg.people.map(function(p) {
                    const parts = p.staff.name.split(/[\\s　]+/)
                    const label = parts[0]
                    let color = "#000000"
                    if (p.staff.role === "社員") color = "#d32f2f"
                    else if (p.staff.role === "パート") color = "#2e7d32"
                    return `<span style="color:${color}">${label}</span>`
                })
                const maxShow = 4
                let arr = mapped
                if (mapped.length > maxShow) {
                    arr = mapped.slice(0, maxShow).concat([`<span style="color:#607d8b">+${mapped.length - maxShow}</span>`])
                }
                return arr.join(" ")
            }
            colorProvider: function(iso) {
                const agg = AppState.aggregateForDay(iso)
                if (!agg.count) return "#ffffff"
                return "#eef7ff"
            }
            onDaySelected: (iso, day) => {
                const agg = AppState.aggregateForDay(iso)
                selectedIso = iso
                selectedPeople = agg.people
                detailDialog.open()
            }
        }
    }
}
