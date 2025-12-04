import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ShiftApp 1.0
import QtQuick.Controls.Material

ApplicationWindow {
    id: window
    visible: true
    width: 1280
    height: 800
    title: "シフトテンプレート生成（Qt プロトタイプ）"
    color: "#f2f4f8"

    // 簡易テーマ
    property color primary: "#1e88e5"
    property color surface: "#ffffff"
    property color muted: "#607d8b"
    property color divider: "#e0e5eb"
    Material.theme: Material.Light
    Material.primary: "#1565c0"
    Material.accent: "#1976d2"
    palette {
        buttonText: "#0d47a1"
        brightText: "#0d47a1"
        text: "#0d47a1"
    }

    header: ToolBar {
        RowLayout {
            anchors.fill: parent
            spacing: 12
            Label {
                text: "シフトテンプレート"
                font.pixelSize: 18
                font.bold: true
                color: "#0d47a1"
                Layout.alignment: Qt.AlignVCenter
            }
            Label {
                text: `対象月：${AppState.selectedMonth.getFullYear()}年${AppState.selectedMonth.getMonth() + 1}月`
                Layout.alignment: Qt.AlignVCenter
            }
            Label {
                text: "v0.1 試作"
                color: "#888"
                Layout.alignment: Qt.AlignVCenter
            }
            Item { Layout.fillWidth: true }
            Rectangle {
                color: AppState.isAuthenticated ? "#e3f2fd" : "#ffecb3"
                radius: 14
                border.color: window.divider
                Layout.preferredHeight: 32
                Layout.preferredWidth: 240
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 6
                    Label {
                        text: AppState.isAuthenticated ? `ログイン中：${AppState.userEmail}` : "未ログイン"
                        color: "#0d47a1"
                    }
                }
            }
        }
    }

    StackView {
        id: stack
        anchors.fill: parent
        initialItem: loginPage
    }

    // 明示的な Component を保持し、StackView に null が渡らないようにする
    Component {
        id: loginPage
        LoginPage {
            onLoginSucceeded: function(email) {
                AppState.login(email)
                stack.push(rosterPage)
            }
        }
    }

    Component {
        id: monthSelectPage
        MonthSelectPage {
            onProceed: function() { stack.push(rosterPage) }
            onBack: function() { stack.pop() }
        }
    }

    Component {
        id: rosterPage
        RosterPage {
            onOpenStaff: function(staffId) { stack.push(staffDetailPage, { staffId: staffId }) }
            onOpenAllAvailability: function() { stack.push(allAvailabilityPage) }
            onOpenAutoShift: function() { stack.push(autoShiftPage) }
            onBack: function() { stack.pop() }
        }
    }

    Component {
        id: staffDetailPage
        StaffDetailPage {
            onDone: function() { stack.pop() }
        }
    }

    Component {
        id: allAvailabilityPage
        AllAvailabilityPage {
            onBack: function() { stack.pop() }
        }
    }

    Component {
        id: autoShiftPage
        AutoShiftPage {
            onBack: function() { stack.pop() }
        }
    }
}
