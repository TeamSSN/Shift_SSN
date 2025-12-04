# Shift Template Qt Prototype

Qt Quick 製のシフトテンプレート試作アプリです。名簿管理、個人設定（出勤可否/固定シフト）、全員出勤可視化、自動割当て(簡易)を含みます。

## セットアップ

1. 依存パッケージ（Ubuntu 22.04 例）  
   ```
   sudo apt update
   sudo apt install -y \
     qt6-base-dev qt6-declarative-dev \
     qml6-module-qtquick qml6-module-qtquick-controls \
     qml6-module-qtquick-layouts qml6-module-qtquick-localstorage \
     qml6-module-qtquick-window
   ```
2. ビルド  
   ```
   cmake -S . -B build
   cmake --build build
   ```
3. 実行  
   ```
   ./build/appShiftTemplate
   ```

### Windows の場合

1. Qt 6.2 以上をインストール（MSVC か MinGW いずれかで統一）。Qt Maintenance Tool などで `Qt Quick` / `Qt Quick Controls` / `Qt Quick Layouts` / `Qt Quick Local Storage` を含むモジュールを選択します。
2. CMake のジェネレーターを環境に合わせて指定してビルド  
   - MSVC 例:  
     ```
     cmake -S . -B build -G "NMake Makefiles" -DCMAKE_BUILD_TYPE=Release
     cmake --build build
     ```
   - MinGW 例:  
     ```
     cmake -S . -B build -G "MinGW Makefiles" -DCMAKE_BUILD_TYPE=Release
     cmake --build build
     ```
3. 実行  
   ```
   build\\appShiftTemplate.exe
   ```
   ※ Qt の bin フォルダが PATH に入っていない場合は、`Qt\\6.x.x\\mingw_64\\bin` などを PATH に追加してください。

## ログインとデータ保存

- ローカルSQLite (Qt Quick LocalStorage) に保存。パス: `~/.local/share/appShiftTemplate/QML/OfflineStorage/Databases/`
- アカウント: メール＋パスワード。未登録ならログイン不可。新規登録ボタンで作成。
- アカウントごとにスタッフ/固定シフト/出勤可否を分離保存。

## 主な操作

- 名簿: 姓・名・役割(社員/パート/アルバイト)で追加。右側の「個人設定」「削除」ボタンで操作。
- 個人設定: 日付クリックで出勤可否/時間帯を編集。複数日コピーはダイアログから開始し、カレンダーでコピー先を選択→完了。
- 全員出勤可視化: カレンダーに姓のみ表示（役割色: 社員=赤, パート=緑, アルバイト=黒）。タップで詳細。
- 自動割当て: 必要人数を指定して簡易ドラフトを生成。

## 開発メモ

- Qt 6.2+ で動作確認。`QtQuick.LocalStorage` を利用。
- ビルドに失敗する場合は Qt6 の CMake パスや QML モジュールの有無を再確認してください。***
