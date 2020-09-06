import QtQuick 2.1 // import QtQuick 2.5
import QtQuick.Controls 1.4
import QtQuick.Window 2.2 //2.13
import Qt.labs.platform 1.0 //1.1

// ApplicationWindow {
Window {
    id: appWindow
    visible: true
    width: Screen.width
    height: Screen.height
    title: qsTr("File Dialog")

    color: "#343434";

    Rectangle {
        anchors.fill: parent
        color: "transparent"

        Button {
            text: "Open File Dialog ..."
            anchors.centerIn: parent

            onClicked: {
                fileDialog.open()
            }
        }
    }

    FileDialog {
        id: fileDialog
        folder: StandardPaths.writableLocation(StandardPaths.DocumentsLocation)
    }
}
