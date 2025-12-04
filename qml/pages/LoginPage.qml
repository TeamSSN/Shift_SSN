import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ShiftApp 1.0

Page {
    id: page
    signal loginSucceeded(string email)

    title: "ログイン"

    property string infoText: ""

    Rectangle {
        anchors.centerIn: parent
        width: 420
        height: 320
        radius: 12
        color: "#ffffff"
        border.color: "#d9e1ec"
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 24
            spacing: 14

            Label {
                text: "シフトテンプレート生成"
                font.pixelSize: 22
                font.bold: true
                Layout.alignment: Qt.AlignHCenter
            }
            Label {
                text: "管理者ログイン"
                color: "#607d8b"
                Layout.alignment: Qt.AlignHCenter
            }

            TextField {
                id: emailField
                placeholderText: "メールアドレス"
                text: "manager@example.com"
                Layout.preferredWidth: 320
            }

            TextField {
                id: passwordField
                placeholderText: "パスワード"
                echoMode: TextInput.Password
                Layout.preferredWidth: 320
            }

            Label {
                text: infoText
                color: infoText.indexOf("成功") !== -1 ? "green" : "red"
                Layout.alignment: Qt.AlignHCenter
            }

            RowLayout {
                spacing: 8
                Layout.alignment: Qt.AlignHCenter
                Button {
                    text: "ログイン"
                    Layout.preferredWidth: 120
                    onClicked: {
                        if (AppState.login(emailField.text, passwordField.text)) {
                            infoText = ""
                            loginSucceeded(emailField.text)
                        } else {
                            infoText = AppState.lastAuthError || "ログインに失敗しました"
                        }
                    }
                }
                Button {
                    text: "新規登録"
                    flat: true
                    onClicked: {
                        if (AppState.registerAccount(emailField.text, passwordField.text)) {
                            infoText = "登録に成功しました。ログインしてください。"
                        } else {
                            infoText = AppState.lastAuthError || "登録に失敗しました"
                        }
                    }
                }
                Button {
                    text: "パスワードリセット"
                    flat: true
                    enabled: false
                }
            }
        }
    }
}
