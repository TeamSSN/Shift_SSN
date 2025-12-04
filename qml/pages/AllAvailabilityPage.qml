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
    property var selectedAgg: ({ count: 0, people: [] })

    Popup {
        id: detailPopup
        modal: true
        focus: true
        anchors.centerIn: parent
        width: Math.min(parent ? parent.width - 60 : 640, 640)
        height: Math.min(parent ? parent.height - 40 : 700, 700)
        background: Rectangle {
            color: "#ffffff"
            radius: 14
            border.color: "#d9e1ec"
        }
        contentItem: ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Label {
                    text: selectedIso === "" ? "選択日なし" : `${selectedIso} の出勤可能者`
                    font.pixelSize: 18
                    font.bold: true
                }
                Item { Layout.fillWidth: true }
                Button {
                    text: "閉じる"
                    flat: true
                    onClicked: detailPopup.close()
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 72
                radius: 10
                color: "#f5f8fb"
                border.color: "#e3ebf3"
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 6
                    RowLayout {
                        spacing: 10
                        Label {
                            text: `人数: ${selectedAgg.count} 人`
                            font.bold: true
                            color: "#0d47a1"
                        }
                        Item { Layout.fillWidth: true }
                    }
                    RowLayout {
                        spacing: 12
                        Label {
                            text: "社員: " + selectedPeople.filter(function(p){ return p.staff.role === "社員" }).length
                            color: "#d32f2f"
                        }
                        Label {
                            text: "パート: " + selectedPeople.filter(function(p){ return p.staff.role === "パート" }).length
                            color: "#2e7d32"
                        }
                        Label {
                            text: "アルバイト: " + selectedPeople.filter(function(p){ return p.staff.role === "アルバイト" }).length
                            color: "#000000"
                        }
                        Item { Layout.fillWidth: true }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 10
                color: "#ffffff"
                border.color: "#e0e5eb"
                clip: true
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 10
                    Label {
                        visible: selectedPeople.length === 0
                        text: "この日に出勤可能なスタッフはいません"
                        color: "#607d8b"
                        Layout.alignment: Qt.AlignHCenter
                    }
                    ListView {
                        visible: selectedPeople.length > 0
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        model: selectedPeople
                        delegate: Rectangle {
                            width: ListView.view.width
                            height: 58
                            color: roleBandColor(modelData.staff.role, index)
                            border.color: "#eef2f7"
                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 10
                                property color roleColor: modelData.staff.role === "社員" ? "#d32f2f" : (modelData.staff.role === "パート" ? "#2e7d32" : "#000000")
                                Rectangle {
                                    width: 6
                                    height: 26
                                    radius: 3
                                    color: roleColor
                                }
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2
                                    Label {
                                        text: AppState.fullName(modelData.staff)
                                        color: "#1b2638"
                                        font.bold: true
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                    Label {
                                        text: modelData.staff.role
                                        color: roleColor
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                }
                                Label {
                                    text: modelData.slot.type === "window"
                                          ? `${modelData.slot.start}-${modelData.slot.end}`
                                          : (modelData.slot.type === "available" ? "終日" : (modelData.slot.type === "free" ? "F" : ""))
                                    color: "#455a64"
                                    horizontalAlignment: Text.AlignRight
                                    Layout.alignment: Qt.AlignVCenter
                                    Layout.preferredWidth: 100
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    function roleBandColor(role, idx) {
        if (role === "社員") return idx % 2 === 0 ? "#fff4f4" : "#ffe9e9"
        if (role === "パート") return idx % 2 === 0 ? "#f2fff4" : "#e6ffeb"
        if (role === "アルバイト") return idx % 2 === 0 ? "#f7f7f7" : "#ededed"
        return idx % 2 === 0 ? "#f9fbfd" : "#ffffff"
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
            Label { text: "表示月: " + AppState.selectedMonth.getFullYear() + "年" + (AppState.selectedMonth.getMonth() + 1) + "月"; color: "#607d8b" }
            Label { text: "タップで詳細表示"; color: "#607d8b" }
        }

        Components.MonthGrid {
            Layout.fillWidth: true
            Layout.fillHeight: true
            badgeProvider: function(iso) {
                const agg = AppState.aggregateForDay(iso)
                if (!agg.count) return ""
                const mapped = agg.people.map(function(p) {
                    const label = AppState.lastNameOnly(p.staff) || AppState.fullName(p.staff)
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
                const sorted = agg.people.slice().sort(function(a, b) {
                    const pa = AppState.rolePriority(a.staff.role)
                    const pb = AppState.rolePriority(b.staff.role)
                    if (pa !== pb) return pa - pb
                    return AppState.fullName(a.staff).localeCompare(AppState.fullName(b.staff))
                })
                selectedIso = iso
                selectedPeople = sorted
                selectedAgg = { count: agg.count, people: sorted }
                detailPopup.open()
            }
        }
    }
}
