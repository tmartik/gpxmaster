import QtQuick 2.0
import QtQuick.Dialogs 1.3
import QtQuick.Layouts 1.15
import QtQuick.Controls 1.4

Dialog {
    visible: false
    title: (dialogData || {}).title || ""
    standardButtons: StandardButton.Save | StandardButton.Cancel

    ColumnLayout {
        anchors.fill: parent

        Text {
            text: (dialogData || {}).text || ""
        }
        TextField {
            id: textField
            Layout.fillWidth: true
            text: (dialogData || {}).value || ""
            onTextChanged: dialogData.value = text
        }
    }
    Component.onCompleted: {
        textField.selectAll()
        Qt.callLater(function() {
            textField.forceActiveFocus()
        })
    }
}
