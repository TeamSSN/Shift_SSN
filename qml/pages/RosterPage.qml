import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ShiftApp 1.0

Page {
    id: page
    signal openStaff(int staffId)
    signal openAllAvailability()
    signal openAutoShift()
    signal back()

    title: "名簿と固定シフト"

    property var statusLabels: ({
        "complete": "✔ 完了",
        "partial": "▲ 部分設定",
        "notset": "○ 未設定",
        "offmonth": "✖ 長期休み"
    })

    property var statusColors: ({
        "complete": "#4caf50",
        "partial": "#ff9800",
        "notset": "#9e9e9e",
        "offmonth": "#e91e63"
    })

    property var weekdayNames: ["", "月", "火", "水", "木", "金", "土", "日"]

    function weekdayLabel(n) {
        return weekdayNames[n] || `週${n}`
    }

    property int yearValue: (new Date()).getFullYear()
    property int monthValue: AppState.selectedMonth.getMonth() + 1

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        RowLayout {
            spacing: 8
            Button { text: "ログアウト"; onClicked: back(); font.bold: true }
            Button { text: "全員の出勤可視化"; onClicked: openAllAvailability(); font.bold: true }
            Button { text: "自動シフト生成 (β)"; onClicked: openAutoShift(); font.bold: true }
            Item { Layout.fillWidth: true }
            RowLayout {
                spacing: 6
                Rectangle { width: 14; height: 14; radius: 3; color: statusColors["complete"] }
                Label { text: "完了" }
                Rectangle { width: 14; height: 14; radius: 3; color: statusColors["partial"] }
                Label { text: "部分" }
                Rectangle { width: 14; height: 14; radius: 3; color: statusColors["notset"] }
                Label { text: "未設定" }
            }
        }

        Rectangle {
            color: "#ffffff"
            radius: 10
            border.color: "#d9e1ec"
            Layout.fillWidth: true
            Layout.preferredHeight: 64
            RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 8
                Label { text: "対象月"; Layout.alignment: Qt.AlignVCenter }
                Label { text: yearValue + "年"; Layout.alignment: Qt.AlignVCenter }
                RowLayout {
                    spacing: 4
                    Layout.alignment: Qt.AlignVCenter
                    ComboBox {
                        id: monthBox
                        model: [1,2,3,4,5,6,7,8,9,10,11,12]
                        currentIndex: monthValue - 1
                        onActivated: function(idx) {
                            monthValue = model[idx]
                            AppState.setMonth(yearValue, monthValue - 1)
                        }
                        Layout.preferredWidth: 70
                    }
                    Label { text: "月"; Layout.alignment: Qt.AlignVCenter }
                }
                Label { text: "表示中: " + yearValue + "年" + monthValue + "月"; color: "#607d8b"; Layout.alignment: Qt.AlignVCenter }
            }
        }

        Rectangle {
            color: "#ffffff"
            radius: 10
            border.color: "#d9e1ec"
            Layout.fillWidth: true
            Layout.preferredHeight: 88
            RowLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 10
                Label { text: "姓"; width: 24; horizontalAlignment: Text.AlignRight }
                TextField {
                    id: newLast
                    placeholderText: "山田"
                    Layout.preferredWidth: 160
                    onAccepted: addButton.clicked()
                }
                Label { text: "名"; width: 24; horizontalAlignment: Text.AlignRight }
                TextField {
                    id: newFirst
                    placeholderText: "太郎"
                    Layout.preferredWidth: 160
                    onAccepted: addButton.clicked()
                }
                Label { text: "役職"; width: 32; horizontalAlignment: Text.AlignRight }
                ComboBox {
                    id: newRole
                    model: ["社員", "パート", "アルバイト"]
                    Layout.preferredWidth: 140
                }
                Button {
                    id: addButton
                    text: "追加"
                    onClicked: {
                        AppState.addStaff(newLast.text, newFirst.text, newRole.currentText)
                        newLast.text = ""
                        newFirst.text = ""
                        newRole.currentIndex = 0
                    }
                }
            }
        }

        ListView {
            id: list
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: AppState.staffEntries
            clip: true
            delegate: Rectangle {
                color: "#ffffff"
                height: 110
                width: list.width
                radius: 10
                border.color: "#dfe6ef"
                anchors.margins: 4
                property color roleColor: modelData.role === "社員" ? "#d32f2f" : (modelData.role === "パート" ? "#2e7d32" : "#000000")
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 12
                    Rectangle {
                        width: 6
                        height: 80
                        radius: 3
                        color: statusColors[modelData.status] || "#ccc"
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        Label { text: AppState.fullName(modelData); font.pixelSize: 18; font.bold: true; color: roleColor }
                        Label { text: "役割: " + modelData.role; color: "#607d8b" }
                        Label {
                            text: "固定: " + (modelData.fixed.length > 0 ? modelData.fixed.map(f => `${weekdayLabel(f.weekday)} ${f.start}-${f.end}`).join(", ") : "なし")
                            color: "#455a64"
                        }
                    }
                    Item { Layout.fillWidth: true }
                    ColumnLayout {
                        spacing: 6
                        Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                        RowLayout {
                            spacing: 6
                            Button {
                                text: "削除"
                                onClicked: AppState.deleteStaff(modelData.id)
                            }
                            Button {
                                text: "個人設定"
                                onClicked: openStaff(modelData.id)
                            }
                        }
                    }
                }
            }
        }
    }
}
