import QtQuick 2.15
import QtQuick.Dialogs 1.3

Dialog {
    id: dialog
    property alias mapProvider: mapProviderView.mapProvider

    title: qsTr("Add a map server")
    standardButtons: StandardButton.Save | StandardButton.Cancel
    visible: false

    MapProviderView {
        id: mapProviderView
        anchors.fill: parent
    }
}
