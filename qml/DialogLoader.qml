import QtQuick 2.15

Loader {
    id: loader

    property var dialogData
    property var callback

    onLoaded: item.open()

    function show(dialogComponent, params, acceptCallback) {
        sourceComponent = null
        dialogData = null

        dialogData = params
        sourceComponent = dialogComponent
        callback = acceptCallback
    }

    function close() {
        sourceComponent = null
        dialogData = null
    }

    Connections {
        target: loader.item

        function onAccepted() {
            if(callback) {
                callback(dialogData)
            }
        }
    }
}
