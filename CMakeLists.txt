cmake_minimum_required(VERSION 3.16)
project(ShiftTemplateApp VERSION 0.1 LANGUAGES CXX)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# 6.2 以降であれば動作する構成（qt_standard_project_setup は 6.2 には未搭載）
find_package(Qt6 6.2 COMPONENTS Quick REQUIRED)

qt_add_executable(appShiftTemplate
    main.cpp
)

qt_add_qml_module(appShiftTemplate
    URI ShiftApp
    VERSION 1.0
    QML_FILES
        qml/Main.qml
        qml/pages/LoginPage.qml
        qml/pages/MonthSelectPage.qml
        qml/pages/RosterPage.qml
        qml/pages/StaffDetailPage.qml
        qml/pages/AllAvailabilityPage.qml
        qml/pages/AutoShiftPage.qml
        qml/components/MonthGrid.qml
        qml/components/AvailabilityDialog.qml
        qml/logic/AppState.qml
    RESOURCES
        qml/logic/CalendarUtils.js
)

target_link_libraries(appShiftTemplate
    PRIVATE Qt6::Quick
)
