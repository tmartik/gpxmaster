import QtQuick 2.15
import QtQuick.Controls 1.4

Menu {
    property int coordinateIndex: -1

    signal split(var index)
    signal remove(var index)

    MenuItem {
        text: "Split segment"
        onTriggered: split(coordinateIndex)
    }
    MenuItem {
        text: "Delete coordinate"
        onTriggered: remove(coordinateIndex)
    }

    function showMenu(index) {
        coordinateIndex = index
        popup()
    }
}
