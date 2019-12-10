#include <QApplication>
#include <QQmlApplicationEngine>
// #include <QMetaType>
// #include <QMetaObject>
#include <QDebug>

int main (int argc, char * argv[])
{
    // Here can be registered QML singleton types
    // qmlRegisterSingletonType(QUrl("qrc:/SingletonUrl.qml")
    //         , "SingletonUri"
    //         , VERSION_MAJOR
    //         , VERSION_MINOR
    //         , "SignletonName");

    // Here can be registered QML types
    // qmlRegisterType<QmlType>("Qml.Type.Uri"
    //         , VERSION_MAJOR
    //         , VERSION_MINOR
    //         , "QmlTypeName");

    // Call before initialization of QApplication
    QApplication::setAttribute(Qt::AA_EnableHighDpiScaling);

    QApplication app(argc, argv);
    app.setQuitOnLastWindowClosed(true);

    QQmlApplicationEngine engine;

    QObject::connect(& engine, & QQmlApplicationEngine::quit, [] {
        qDebug() << "Finishing application ...";
        qApp->quit();
    });

    // Here can be imported paths
    // engine.addImportPath(":/path");

    engine.load(QUrl{"qrc:/main.qml"});

    return app.exec();
}


