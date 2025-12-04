import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

Dialog {
    id: dialog
    property string isoDate: ""
    property var existing: null
    property int daysInMonth: 31
    property int year: 2024
    property int month: 0
    signal confirmed(var payload, bool keepCopyMode)
    signal copyModeRequested(bool enabled, string sourceIso)

    // カレンダー操作を阻害しないよう非モーダル
    modal: false
    standardButtons: Dialog.NoButton
    title: "出勤可否を編集"
    width: 440
    height: 540
    closePolicy: Popup.NoAutoClose
    z: 3000
    // 画面中央付近に出す（埋もれ防止）
    x: dialog.Window.window ? (dialog.Window.window.width - width) / 2 : 40
    y: dialog.Window.window ? Math.max(20, (dialog.Window.window.height - height) / 2) : 40

    property string selection: existing && existing.type ? existing.type : "available"
    property string startValue: existing && existing.start ? existing.start : "09:00"
    property string endValue: existing && existing.end ? existing.end : "17:00"
    property bool startCopySelection: false

    Rectangle {
        anchors.fill: parent
        color: "#ffffff"
        radius: 10
        border.color: "#d9e1ec"
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 18

            Label { text: isoDate; font.bold: true; font.pixelSize: 18 }

            Rectangle {
                color: "#f7f9fc"
                radius: 8
                border.color: "#d9e1ec"
                Layout.fillWidth: true
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 10
                    ButtonGroup { id: typeGroup }
                    RadioButton {
                        text: "出勤不可 (×)"
                        checked: selection === "off"
                        onClicked: selection = "off"
                        ButtonGroup.group: typeGroup
                    }
                    RadioButton {
                        text: "出勤可能 (○)"
                        checked: selection === "available"
                        onClicked: selection = "available"
                        ButtonGroup.group: typeGroup
                    }
                    RadioButton {
                        text: "時間帯指定"
                        checked: selection === "window"
                        onClicked: selection = "window"
                        ButtonGroup.group: typeGroup
                    }
                    RowLayout {
                        spacing: 10
                        Label { text: "開始" }
                        TextField {
                            text: startValue
                            onTextChanged: startValue = text
                            Layout.preferredWidth: 140
                        }
                        Label { text: "終了" }
                        TextField {
                            text: endValue
                            onTextChanged: endValue = text
                            Layout.preferredWidth: 140
                        }
                    }
                    RadioButton {
                        text: "F（フリー）"
                        checked: selection === "free"
                        onClicked: selection = "free"
                        ButtonGroup.group: typeGroup
                    }
                }
            }

            Item { Layout.fillHeight: true }

            RowLayout {
                spacing: 14
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 10
                Button {
                    text: "キャンセル"
                    Layout.preferredWidth: 110
                    onClicked: {
                        startCopySelection = false
                        copyModeRequested(false, "")
                        dialog.close()
                    }
                }
                Button {
                    text: startCopySelection ? "コピー先終了" : "複数日コピー"
                    Layout.preferredWidth: 130
                    checkable: true
                    checked: startCopySelection
                    onClicked: {
                        startCopySelection = !startCopySelection
                        copyModeRequested(startCopySelection, isoDate)
                    }
                }
                Button {
                    text: "完了"
                    Layout.preferredWidth: 110
                    highlighted: true
                    onClicked: {
                        let payload = null
                        if (selection === "off") {
                            payload = { type: "off" }
                        } else if (selection === "available") {
                            payload = { type: "available" }
                        } else if (selection === "window") {
                            payload = { type: "window", start: startValue, end: endValue }
                        } else if (selection === "free") {
                            payload = { type: "free" }
                        }
                        confirmed(payload, startCopySelection)
                        startCopySelection = false
                        copyModeRequested(false, "")
                        dialog.close()
                    }
                }
            }
        }
    }
}
