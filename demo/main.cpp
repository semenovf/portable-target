#include <QApplication>
#include <QQmlApplicationEngine>

int main (int argc, char * argv[])
{
    QApplication::setAttribute(Qt::AA_EnableHighDpiScaling);

    QApplication app(argc, argv);
    app.setQuitOnLastWindowClosed(true);

    QQmlApplicationEngine engine;

    QObject::connect(& engine, & QQmlApplicationEngine::quit, [] {
        qApp->quit();
    });

    engine.load(QUrl{"qrc:/main.qml"});

    return app.exec();
}


