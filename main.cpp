#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QUrl>
#include <QQmlEngine>

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    // AppState を明示的にシングルトン登録（qt_add_qml_module では qmldir の singleton が付与されない環境向け）
    qmlRegisterSingletonType(QUrl(u"qrc:/ShiftApp/qml/logic/AppState.qml"_qs),
                             "ShiftApp", 1, 0, "AppState");

    QQmlApplicationEngine engine;
    // Qt 6.2 の qt_add_qml_module で生成されるリソースパスは qrc:/ShiftApp/qml/
    const QUrl url(u"qrc:/ShiftApp/qml/Main.qml"_qs);
    QObject::connect(
        &engine, &QQmlApplicationEngine::objectCreated,
        &app, [url](QObject *obj, const QUrl &objUrl) {
            if (!obj && url == objUrl)
                QCoreApplication::exit(-1);
        },
        Qt::QueuedConnection);
    engine.load(url);

    return app.exec();
}
