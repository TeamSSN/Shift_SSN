import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ShiftApp 1.0
import "../logic/CalendarUtils.js" as Cal

Item {
    id: root
    property int year: AppState.selectedMonth.getFullYear()
    property int month: AppState.selectedMonth.getMonth() // 0-based
    property var badgeProvider: null // function(iso) -> string
    property var colorProvider: null // function(iso) -> color string
    signal daySelected(string iso, int day)

    property var days: []
    // グリッドと曜日ヘッダーの幅を一致させる
    property real cellWidth: (width - (grid.columnSpacing * (grid.columns - 1))) / grid.columns

    implicitWidth: 820
    implicitHeight: 560

    function refresh() {
        days = Cal.buildCalendarDays(year, month)
    }

    Component.onCompleted: refresh()
    onYearChanged: refresh()
    onMonthChanged: refresh()

    ColumnLayout {
        anchors.fill: parent
        spacing: 6

        Rectangle {
            radius: 8
            color: "#ffffff"
            border.color: "#d9e1ec"
            Layout.fillWidth: true
            Layout.preferredHeight: 48
            GridLayout {
                anchors.fill: parent
                anchors.margins: 10
                columns: 7
                columnSpacing: grid.columnSpacing
                rowSpacing: 0
                Repeater {
                    model: ["日", "月", "火", "水", "木", "金", "土"]
                    delegate: Label {
                        text: modelData
                        font.bold: true
                        color: index === 0 ? "#d32f2f" : (index === 6 ? "#1565c0" : "#111")
                        Layout.preferredWidth: root.cellWidth
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }
        }

        GridLayout {
            id: grid
            Layout.fillWidth: true
            Layout.fillHeight: true
            columns: 7
            rowSpacing: 6
            columnSpacing: 6

            Repeater {
                model: days
                delegate: Rectangle {
                    required property var modelData
                    readonly property bool isEmpty: modelData === null
                    readonly property var badgeVal: badgeProvider ? badgeProvider(modelData && modelData.iso) : ""
                    color: isEmpty ? "#f8f8f8" : (colorProvider ? colorProvider(modelData.iso) || "#ffffff" : "#ffffff")
                    implicitWidth: root.cellWidth
                    implicitHeight: 90
                    radius: 8
                    border.color: "#d9e1ec"
                    border.width: isEmpty ? 0 : 1
                    opacity: isEmpty ? 0.4 : 1

                    MouseArea {
                        anchors.fill: parent
                        enabled: !isEmpty
                        onClicked: root.daySelected(modelData.iso, modelData.day)
                    }

                    Column {
                        anchors.fill: parent
                        anchors.margins: 6
                        spacing: 4
                        Label {
                            text: isEmpty ? "" : modelData.day
                            font.bold: true
                        }
                        Text {
                            visible: !isEmpty && badgeVal && String(badgeVal).length > 0
                            text: !isEmpty ? (badgeVal || "") : ""
                            textFormat: Text.RichText
                            color: "#333"
                            wrapMode: Text.NoWrap
                            elide: Text.ElideRight
                            font.pixelSize: 12
                            maximumLineCount: 1
                            horizontalAlignment: Text.AlignLeft
                        }
                    }
                }
            }
        }
    }
}
