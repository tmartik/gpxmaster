import QtQuick 2.15
import QtQuick.Controls 1.4

MenuBar {
    // File manu signals
    signal newFile()
    signal openFile(var url)
    signal saveFile()
    signal saveAsFile()

    // Map menu signals
    signal addMap()
    signal selectMap()
    signal manageMaps()
    signal editSettings()

    // Bookmark signals
    signal addBookmark()
    signal bookmarkSelected(var bookmark)

    // Input properties
    property var recent: []
    property var bookmarks: []
    property bool documentModified: false
    property bool documentSelected: false
    property bool mapsAvailable: false
    property int appVisibility: 0

    // Output properties
    property bool fullScreen: false
    property bool offline: true
    property bool useImperialUnits: false
    property bool showLeftPanel: false
    property bool showDistanceMarkers: false

     Menu {
         title: qsTr("File")
         MenuItem {
             text: "&New..."
             shortcut: StandardKey.New
             onTriggered: newFile()
         }
         MenuItem {
             text: "&Open..."
             shortcut: StandardKey.Open
             onTriggered: openFile(null)
         }
         Menu {
             id: recentMenu
             title: "Recent"
             enabled: recent.length > 0
             Instantiator {
                model: recent
                MenuItem {
                   text: modelData.name || "invalid entry!"
                   onTriggered: openFile(modelData.url)
                }

                onObjectAdded: recentMenu.insertItem(index, object)
                onObjectRemoved: recentMenu.removeItem(object.url)
            }
         }
         MenuItem {
             text: "Save"
             shortcut: StandardKey.Save
             enabled: documentModified
             onTriggered: saveFile()
         }
         MenuItem {
             text: "Save as..."
             enabled: documentSelected
             onTriggered: saveAsFile()
         }
     }
     Menu {
         title: qsTr("Map")
         MenuItem {
             text: "Add..."
             onTriggered: addMap()
         }
         MenuItem {
             text: "Select..."
             enabled: mapsAvailable
             onTriggered: selectMap()
         }
         MenuItem {
             text: "Manage..."
             enabled: mapsAvailable
             onTriggered: manageMaps()
         }
         MenuSeparator {}
         MenuItem {
             text: "Settings..."
             onTriggered: editSettings()
         }
         MenuSeparator {}
         MenuItem {
             text: "Online"
             enabled: mapsAvailable
             checkable: true
             onTriggered: offline = !checked
         }
     }
     Menu {
         title: qsTr("View")
         MenuItem {
             text: "Full screen"
             checkable: true
             shortcut: "F11"
             onTriggered: fullScreen = appVisibility !== 5
         }
         MenuItem {
             text: "Imperial units"
             checkable: true
             checked: useImperialUnits
             onTriggered: useImperialUnits = !useImperialUnits
         }
         MenuItem {
             text: "Left panel"
             checkable: true
             checked: showLeftPanel
             onTriggered: showLeftPanel = !showLeftPanel
         }
         MenuItem {
             text: useImperialUnits ? qsTr("Show milestones") : qsTr("Show kilometric points")
             checkable: true
             checked: showDistanceMarkers
             onTriggered: showDistanceMarkers = !showDistanceMarkers
         }
     }
     Menu {
         id: bookmarksMenu
         title: qsTr("Bookmarks")
         MenuItem {
             shortcut: "Ctrl+D"
             text: "Add..."
             onTriggered: addBookmark()
         }
         MenuSeparator {}
         MenuItem {
             text: "Manage..."
             // TODO:
         }
         MenuSeparator { }

         Instantiator {
            model: bookmarks
            MenuItem {
               text: modelData.name
               onTriggered: bookmarkSelected(modelData)

            }

            onObjectAdded: bookmarksMenu.insertItem(index, object)
            onObjectRemoved: bookmarksMenu.removeItem(object)
        }
     }
     Menu {
         title: qsTr("Help")
         MenuItem {
             text: "About"
             onTriggered: {
                 // TODO:
                console.log("PORT: " + HttpServer.getPortNumber())
             }
         }
     }
 }
