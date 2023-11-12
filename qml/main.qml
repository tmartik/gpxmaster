import QtQuick 2.15
import QtQuick.Controls 1.4
import QtQuick.Dialogs 1.3
import QtQuick.Layouts 1.15
import QtLocation 5.15
import QtPositioning 5.15

import Qt.labs.platform 1.1 as Platform
import Qt.labs.settings 1.0

import "view"
import "menu"
import "dialog"


ApplicationWindow {
    id: appWindow

    // Style
    property Style style: Style {}

    // Application state
    width: 640
    height: 480
    visibility: ApplicationWindow.Maximized
    title: qsTr("GPX Master")

    property MainViewModel mainViewModel: MainViewModel {
        id: mainViewModel
        useImperialUnits: appMenu.useImperialUnits
    }
    property var mapView

    menuBar: AppMenu {
        id: appMenu
        property var currentDocument: mainViewModel.documents[documentsView.selection[0]]

        appVisibility: appWindow.visibility
        documentModified: currentDocument > '' && currentDocument.file.modified > '' && currentDocument.file.fullpath > ''
        documentSelected: documentsView.selectedIndex >= 0
        mapsAvailable: mainViewModel.mapProviders.length > 0
        recent: mainViewModel.recent
        bookmarks: mainViewModel.bookmarks

        // File
        onNewFile: mainViewModel.createDocument()
        onOpenFile: {
            if(url) {
                mainViewModel.openDocument(url)
                showLeftPanel = true
            } else {
                openFileDialog.open()
            }
        }
        onSaveFile: mainViewModel.saveDocument(documentsView.selectedIndex)
        onSaveAsFile: saveFileDialog.open()

        // Map
        onAddMap: dialogLoader.show(mapAddDialogComponent, {})
        onSelectMap: {
            dialogLoader.show(mapSelectionDialogComponent, {
                                  selectedIndex: 0
                              })
        }
        onManageMaps: dialogLoader.show(mapManagementDialogComponent)
        onEditSettings: {}  // TODO: show settings dialog
        onOfflineChanged: HttpServer.setFlightMode(offline)

        // View
        onFullScreenChanged: {
            if(fullScreen) {
                showFullScreen()
            } else {
                showMaximized()
            }
        }

        // Bookmark
        onAddBookmark: {
            dialogLoader.show(textEditDialogComponent, {
                                  title: qsTr("Add bookmark"),
                                  text: qsTr("Type bookmark name:"),
                                  value: qsTr("New bookmark"),
                                  coordinate: mapLoader.item.center
                              }, function(dialogData) {
                                  mainViewModel.addBookmark(dialogData.value, dialogData.coordinate.latitude, dialogData.coordinate.longitude, mapLoader.item.zoomLevel)
                              })
        }
        onBookmarkSelected: mapLoader.item.gotoCoordinate(bookmark.lat, bookmark.lon, bookmark.zoomLevel || 16)
    }

    MapContextMenu {
        id: contextMenu
        documentSelected: documentsView.selectedIndex >= 0
        segmentSelected: documentsView.selection.length === 4 && documentsView.selection[1] === 0   // A segment selected
        onAddWaypoint: {
            dialogLoader.show(wptEditDialogComponent, {
                                  wpt: {
                                      name: '',
                                      cmt: '',
                                      latitude: coordinate.latitude,
                                      longitude: coordinate.longitude
                                  }
                              })
        }
        onAddTrackPoint: mainViewModel.insertPoint(documentsView.selection[0], documentsView.selection[2], documentsView.selection[3], lat, lon)
    }

    SegmentContextMenu {
        id: dotContextMenu
        onSplit: {
            var d = mainViewModel.documents[documentsView.selection[0]]
            var t = d.tracks[documentsView.selection[2]]
            mainViewModel.splitSegment(t, getSelectedSegment(), index)
        }
        onRemove: mainViewModel.removePoint(documentsView.selection[0], documentsView.selection[2], documentsView.selection[3], index)
    }



    function getSelectedSegment() {
        if(documentsView.selection.length === 4 && documentsView.selection[1] === 0) {
            var d = mainViewModel.documents[documentsView.selection[0]]
            var t = d.tracks[documentsView.selection[2]]
            return t.segments[documentsView.selection[3]]
        } else {
            return null
        }
    }

    Component.onCompleted: {
        Qt.callLater(function() {
            HttpServer.setCacheFolder(Utility.pwd() + "/tilecache")
            HttpServer.setFlightMode(true)
        })

        if(mainViewModel.mapProviders.length > 0) {
            Qt.callLater(function() {
                mapLoader.sourceComponent = mapViewComponent
                HttpServer.setURL(mainViewModel.mapProviders[0].url, mainViewModel.mapProviders[0].cacheName, mainViewModel.mapProviders[0].referer)
                mapView.clearData()
            })
        }
    }

    Shortcut {
        sequence: "ESC"
        onActivated: showMinimized()
    }

    property var distanceMarkers: appMenu.showDistanceMarkers ? mainViewModel.getAllDistanceMarkers() : []

    Connections {
        target: mainViewModel

        function onDocumentsChanged() {
            // Populate map
            console.log('POPULATING MAP...')
            console.time('populate')

            mapView.resetLayers()
            mainViewModel.documents.forEach(d => {
                              // Handle only tracks for now
                              d.tracks.forEach(t => {
                                                   mapView.addRouteLayer(t.name, t.segments.map(s => {
                                                                                            var path = s.map(c => {
                                                                                                             return {
                                                                                                                 latitude: c.lat,
                                                                                                                 longitude: c.lon
                                                                                                             }
                                                                                                         })
                                                                                            return {
                                                                                                path: path
                                                                                            }
                                                                                        }), {
                                                                     color: 'black'
                                                                 })
                                               })
                          })

            // Add place layers
            for(var d of mainViewModel.documents) {
                mapView.addPlaceLayer(d.file.name, d.waypoints)
            }

            console.timeEnd('populate')
        }
    }

    SplitView {
        anchors.fill: parent
        orientation: Qt.Horizontal

        // Route panel
        DocumentsView {
            id: documentsView
            Layout.minimumWidth: 64
            Layout.maximumWidth: parent.width / 2
            width: 256
            visible: appMenu.showLeftPanel
            model: mainViewModel.documents
            onFitToview: {
                // Center map to seleted segment
                var s = mainViewModel.documents[documentIndex].tracks[trackIndex].segments[segmentIndex]
                var geoshape = getSegmentExtent(s)
                mapView.fitViewportToGeoShape(geoshape, mapView.width / 20)     // TODO: margins

            }
            onNewTrack: mainViewModel.createNewTrack(mainViewModel.documents[documentIndex])
            onNewSegment: mainViewModel.addSegment(documentIndex, trackIndex)
            onDeleteTrack: mainViewModel.deleteTrack(documentIndex, trackIndex)
            onDeleteSegment: mainViewModel.deleteSegment(documentIndex, trackIndex, segmentIndex)
            onRenameTrack: {
                dialogLoader.show(textEditDialogComponent, {
                                      title: qsTr("Rename"),
                                      text: qsTr("Rename track:"),
                                      value: mainViewModel.documents[documentIndex].tracks[trackIndex].name
                                  }, function(data) {
                                      // on accepted
                                      mainViewModel.renameTrack(documentIndex, trackIndex, data.value)
                                  })
            }
            onMoveToNewTrack: mainViewModel.moveToNewTrack(documentIndex, trackIndex, segmentIndex)
            onCompress: {
                dialogLoader.show(textEditDialogComponent, {
                                      title: qsTr("Compress"),
                                      text: qsTr("Minimum distance between track points (m):"),
                                      value: 100
                                  }, function(data) {
                                      // on accepted
                                      mainViewModel.compressSegment(documentIndex, trackIndex, segmentIndex, parseInt(data.value))
                                  })
            }
            onReverse: mainViewModel.reverseSegment(documentIndex, trackIndex, segmentIndex)
            onCut: mainViewModel.cutSegment(documentIndex, trackIndex, segmentIndex)
            onCopy: mainViewModel.copySegment(documentIndex, trackIndex, segmentIndex)
            onPaste: mainViewModel.pasteSegment(documentIndex, trackIndex, segmentIndex)
            onRemoveDocument: mainViewModel.removeDocument(index)
            onSelectionChanged: {
                if(selection.length === 4) {
                    // A segment was selected
                    var trackIndex = 0      // Convert selected index to map layer index    // TODO: convert to reduce() ?
                    for(var index in mainViewModel.documents) {
                        var d = mainViewModel.documents[index]
                        if(parseInt(index) === selection[0]) {
                            break
                        }
                        trackIndex += d.tracks.length
                    }

                    mapView.selectedPath = selection[3]
                    mapView.selectedTrack = trackIndex + selection[2]
                } else if(selection.length === 3) {
                    if(selection[1] === 2) {
                        // A waypoint was selected
                        var waypointIndex = selection[2]
                        var waypoint = mainViewModel.documents[selection[0]].waypoints[selection[2]]
                        mapLoader.item.gotoCoordinate(waypoint.lat, waypoint.lon, 16)
                    }
                }
            }
        }

        // The map
        Loader {
            id: mapLoader
            sourceComponent: mapViewComponent
            focus: true
        }
    }

    function getSegmentExtent(segment) {
        var topLeft = QtPositioning.coordinate(segment[0].lat, segment[0].lon)
        var bottomRight = QtPositioning.coordinate(topLeft.latitude, topLeft.longitude)

        segment.forEach(c => {
                      topLeft.latitude = Math.max(topLeft.latitude, c.lat)
                      topLeft.longitude = Math.min(topLeft.longitude, c.lon)
                      bottomRight.latitude = Math.min(bottomRight.latitude, c.lat)
                      bottomRight.longitude = Math.max(bottomRight.longitude, c.lon)
                  })

        return QtPositioning.rectangle(topLeft, bottomRight)
    }

    ActionBar {
        id: toolActionBar
        anchors.top: parent.top
        anchors.margins: style.margin
        anchors.horizontalCenter: parent.horizontalCenter
        vertical: false
        actions: [
            {
                title: "Ins.\nWpt.",
                action: function() {

                }
            },
            {
                name: "del_wpt",
                title: "Del",
                action: function() {
                }
            },
            {
                name: "move_wpt",
                title: "Drag",
                action: function() {
                }
            },
        ]

        function isSelected(name) {
            return selectedAction === actions.map(a => a.name).indexOf(name)
        }
    }

    ActionBar {
        id: mapActionBar
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: style.margin
        vertical: true
        widthFactor: 5
        actions: mainViewModel.mapProviders.map((m, index) => {
                                               return {
                                                   title: m.name,
                                                   action: function() {
                                                       selectMap(index)
                                                   }
                                               }
                                           })
    }


    Platform.FileDialog {
        id: openFileDialog
        title: "Open file"
        nameFilters: [ "All supported files (*.gpx *.json *.kml)", "GPX files (*.gpx)", "KML files (*.kml)", "JSON files (*.json)", "All files (*)" ]
        onAccepted: {
            console.log("You chose: " + openFileDialog.fileUrls)
            mainViewModel.openDocument(openFileDialog.files[0])
            showLeftPanel = true
        }
    }


    Platform.FileDialog {
        id: saveFileDialog
        title: "Save file as"
        fileMode: Platform.FileDialog.SaveFile
        nameFilters: [ "GPX files (*.gpx)", "JSON files (*.json)" ]
        onAccepted: mainViewModel.saveDocumentAs(documentsView.selectedIndex, saveFileDialog.files[0])
    }

    Component {
        id: mapViewComponent
        MapView {
            id: mapView
            property int zoom: Math.floor(zoomLevel)
            appStyle: appWindow.style
            useImperialUnits: appMenu.useImperialUnits
            Layout.minimumWidth: 32
            focus: true
            selectedLayerName: mainViewModel.documents[documentsView.selectedIndex].file.name         // TODO: does not work!
            selection: documentsView.selection
            zoomLevel: 5
            center {
                latitude: 56
                longitude: 8
            }
            dragEnabled: toolActionBar.isSelected("move_wpt")
            markersModel: distanceMarkers.filter(function(dm, index) {
                return zoom >= 13 ? true : zoom >= 11 ? index % 2 !== 0 || dm.final === true: dm.final === true
            })
            dotModel: getSelectedSegment() || []
            onDropped: {
                if(mainViewModel.documents.length > 0 && content && documentsView.selectedIndex >= 0) {
                    var d = mainViewModel.documents[documentsView.selectedIndex]
                    mainViewModel.addWaypoint(d, name, coordinate.latitude, coordinate.longitude, content)
                }
            }
            onOpenFile: mainViewModel.openFileFromUrl(url)
            onWptClicked: {
                dialogLoader.show(wptEditDialogComponent, {
                                      documentIndex: -1,        // TODO: !
                                      placeIndex: index,
                                      wpt: wpt
                                  })
            }
            onLeftClick: {      // Map left click
                if(toolActionBar.isSelected("add_wpt")) {
                    mainViewModel.insertPoint(documentsView.selection[0], documentsView.selection[2], documentsView.selection[3], coordinate.latitude, coordinate.longitude)
                }
            }
            onRightClick: {     // Map right click
                contextMenu.showMenu(coordinate)
            }
            onPointLeftClicked: {   // Dot left click
                if(toolActionBar.isSelected("del_wpt")) {
                    mainViewModel.removePoint(documentsView.selection[0], documentsView.selection[2], documentsView.selection[3], index)
                }
            }
            onPointRightClicked: dotContextMenu.showMenu(index)
            onKeyPressed: {
                if(key === Qt.Key_Delete && selectedDotIndex >= 0) {
                    mainViewModel.removePoint(documentsView.selection[0], documentsView.selection[2], documentsView.selection[3], selectedDotIndex)
                }
            }
            onKeyReleased: {
                if(key === Qt.Key_Insert) {
                    mainViewModel.insertPoint(documentsView.selection[0], documentsView.selection[2], documentsView.selection[3], coordinate.latitude, coordinate.longitude)
                }
            }
            onMoved: mainViewModel.movePoint(documentsView.selection[0], documentsView.selection[2], documentsView.selection[3], index, coordinate.latitude, coordinate.longitude)
            Component.onCompleted: appWindow.mapView = this     // TODO: not really needed; use loader.item
        }
    }

    DialogLoader {
        id: dialogLoader
    }

    Component {
        id: mapAddDialogComponent
        MapAddDialog {
            onAccepted: {
                mainViewModel.addMapProvider(mapName, mapUrl, cacheName, referer)
                dialogLoader.close()            // TODO: is this really needed ?

                selectMap(mainViewModel.mapProviders.length - 1)
            }
            onRejected: dialogLoader.close()    // TODO: is this really needed ?
        }
    }

    Component {
        id: mapSelectionDialogComponent
        MapSelectionDialog {
            model: mainViewModel.mapProviders
            onAccepted: {
                dialogLoader.close()                // TODO: is this really needed ?
                selectMap(selectedIndex)
            }
            onRejected: dialogLoader.close()        // TODO: is this really needed ?
        }
    }

    function selectMap(index) {
        // Save coordinate and zoom level
        var lat = appWindow.mapView.center.latitude
        var lon = appWindow.mapView.center.longitude
        var z = appWindow.mapView.zoomLevel

        mapLoader.sourceComponent = null

        var m = mainViewModel.mapProviders[index]
        HttpServer.setURL(m.url, m.cacheName, m.referer)
        mapView.clearData()

        mapLoader.sourceComponent = mapViewComponent

        // Restore coordinate and zoom level
        appWindow.mapView.center.latitude = lat
        appWindow.mapView.center.longitude = lon
        appWindow.mapView.zoomLevel = z

        // Refresh map layers
        mainViewModel.documentsChanged()
    }

    Component {
        id: mapManagementDialogComponent
        MapManagementDialog {
            model: mainViewModel.mapProviders
        }
    }

    Component {
        id: wptEditDialogComponent
        WptEditDialog {
            editable: documentsView.selectedIndex >= 0
            onAccepted: {
                var d = mainViewModel.documents[documentsView.selectedIndex]

                if(dialogData.placeIndex >= 0) {
                    mainViewModel.replaceWaypoint(d, dialogData.placeIndex, name, cmt)
                } else {
                    mainViewModel.addWaypoint(d, name, dialogData.wpt.latitude, dialogData.wpt.longitude, cmt)
                }

                dialogLoader.close()                // TODO: is this really needed ?
            }
            onRejected: dialogLoader.close()        // TODO: is this really needed ?
            Component.onCompleted: open()           // TODO: is this really needed ?
        }
    }

    Component {
        id: textEditDialogComponent
        TextQueryDialog {}
    }

    Settings {
        id: settings
        fileName: 'gpx-master.ini'
        property alias mapProviders: mainViewModel.mapProviders
        property alias bookmarks: mainViewModel.bookmarks
        property alias recent: mainViewModel.recent
    }
}
