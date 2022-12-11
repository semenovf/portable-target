#include <QGuiApplication>
#include <QQmlApplicationEngine>

int main (int argc, char * argv[])
{
    QGuiApplication::setAttribute(Qt::AA_EnableHighDpiScaling);

    QGuiApplication app(argc, argv);
    app.setQuitOnLastWindowClosed(true);

    QQmlApplicationEngine engine;

    QObject::connect(& engine, & QQmlApplicationEngine::quit, [] {
        qApp->quit();
    });

    engine.load(QUrl{"qrc:/main.qml"});

    return app.exec();
}


