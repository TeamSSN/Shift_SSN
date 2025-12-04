import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ShiftApp 1.0

Page {
    id: page
    signal proceed()
    signal back()
    title: "対象月の選択"

    property int yearValue: AppState.selectedMonth.getFullYear()
    property int monthValue: AppState.selectedMonth.getMonth() + 1

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 12
        width: Math.min(parent.width, 520)

        Label {
            text: "翌月分のシフトテンプレートを作成します"
            font.pixelSize: 20
            Layout.alignment: Qt.AlignHCenter
        }

        Rectangle {
            color: "#ffffff"
            radius: 10
            border.color: "#d9e1ec"
            Layout.fillWidth: true
            Layout.preferredHeight: 180
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12
                RowLayout {
                    spacing: 12
                    Label { text: "年" }
                    SpinBox {
                        id: yearBox
                        from: 2023
                        to: 2030
                        value: yearValue
                        onValueChanged: yearValue = value
                    }
                    Label { text: "月" }
                    ComboBox {
                        id: monthBox
                        model: [1,2,3,4,5,6,7,8,9,10,11,12]
                        currentIndex: monthValue - 1
                        onActivated: function(idx) { monthValue = model[idx] }
                        width: 100
                    }
                }
                Rectangle { height: 1; color: "#e0e5eb"; Layout.fillWidth: true }
                ColumnLayout {
                    spacing: 4
                    Label { text: "選択中: " + yearValue + "年" + monthValue + "月"; font.bold: true }
                    Label { text: "フロー: 名簿 → 個人設定 → 全体確認 → 自動生成"; color: "#607d8b" }
                    Label { text: "固定シフトは曜日ごとに自動反映"; color: "#607d8b" }
                }
            }
        }

        RowLayout {
            spacing: 12
            Button {
                text: "戻る"
                onClicked: back()
                font.bold: true
            }
            Button {
                text: "名簿へ進む"
                Layout.fillWidth: true
                font.bold: true
                onClicked: {
                    AppState.setMonth(yearValue, monthValue - 1)
                    proceed()
                }
            }
        }
    }
}
