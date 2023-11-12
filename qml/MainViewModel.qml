import QtQuick 2.0
import QtPositioning 5.15

Item {
    property var documents: []

    property var mapProviders: []
    property var recent: []
    property var bookmarks: []

    // Map file settings
    property int maxRecents: 10
    property int routeFilterMinDistance: 10
    property bool useImperialUnits: false

    function addMapProvider(mapName, mapUrl, cacheName, referer) {
        mapProviders.push({
                      name: mapName,
                      url: mapUrl,
                      cacheName: cacheName,
                      referer: referer
                  })
        mapProvidersChanged()
    }

    function createDocument() {
        documents.push({
                           file: {
                               fullpath: "",
                               name: "New file",
                               type: "gpx"
                           },
                           tracks: [],
                           waypoints: []
                       })
        documentsChanged()
    }

    function openDocument(url) {
        var path = url

        if(documents.filter(d => d.file.fullpath === path).length > 0) {
            // The file is already open
            return
        }

        var ext = path.split('.').pop()

        switch(ext.toLowerCase()) {
            case 'gpx':
                openFileFromUrl(path)
            break
            case 'kml':
                openFile(path, function(content) {
                    var json = Utility.parseKml(content)
                    handleGpx(json, path)
                })
            break
            case 'json':
                openFile(path, function(content) {
                    var gpx = JSON.parse(content)

                    gpx.file = {
                        name: path.split("/").pop(),
                        fullpath: path,
                        type: 'json'
                    }

                    documents.push(gpx)
                    documentsChanged()
                })
            break
        }

        // Save to recents list
        saveToRecents(path)
    }

    function saveToRecents(path) {
        var name = path.split('/').pop()
        var exists = recent.filter(r => {
                                       return r.name === name
                                   }).length > 0

        if(!exists) {
            var r = {
                name: name,
                url: path
            }
            recent.splice(0, 0, r)      // Put to top of the list
            if(recent.length > maxRecents) {
                // Remove oldest entry
                recent.pop()
            }

            recentChanged()
        }
    }

    function openFileFromUrl(path) {            // TODO: remove
        openFile(path, function(content) {
            var json = Utility.parseGpx(content)
            handleGpx(json, path)
        })
    }

    function handleGpx(json, path) {
        var gpx = JSON.parse(json)
        console.log('GPX OPENED!')

        gpx.file = {
            name: path.split("/").pop(),
            fullpath: path,
            type: 'gpx'            // TODO: use GPX type
        }

        // Filter tracks
        var tracks = []

        for(var t of gpx.tracks) {
            var segments = []
            for(var s of t.segments) {
                var segment = pri.filterCoordinates(s)  // TODO: move to away from here!
                segments.push(segment)
            }
            t.segments = segments
            tracks.push(t)
        }

        gpx.tracks = tracks

        documents.push(gpx)
        documentsChanged()
    }

    function openFile(path, callback) {
        var xhr = new XMLHttpRequest
        xhr.open("GET", path)
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                var response = xhr.responseText
                callback(response)
            }
        }
        xhr.send()
    }

    function saveDocumentAs(documentIndex, path) {
        var d = documents[documentsView.selectedIndex]

        d.file.fullpath = path
        d.file.name = path.split('/').pop()

        pri.saveDocument(path, d)

        d.file.modified = null
        documentsChanged()
    }

    function saveDocument(documentIndex) {
        var d = documents[documentsView.selectedIndex]

        var path = d.file.fullpath
        pri.saveDocument(path, d)

        d.file.modified = null
        documentsChanged()
    }

    function removeDocument(index) {
        documents.splice(index, 1)
        documentsChanged()
    }

    function addBookmark(name, lat, lon, zoomLevel) {
        bookmarks.push({
                           name: name,
                           lat: lat,
                           lon: lon,
                           zoomLevel: zoomLevel
                       })
        bookmarksChanged()
    }

    function getAllDistanceMarkers() {
        var result = []

        for(var gpx of documents) {
            for(var track of gpx.tracks) {
                for(var s of track.segments) {
                    result = result.concat(getPathMarkers(s))
                }
            }
        }

        return result
    }

    function getPathMarkers(path) {
        var result = []

        var lastCoordinate
        var intervalDistance = 0
        var totalDistance = 0

        for(var c of path) {
            var coordinate = QtPositioning.coordinate(c.lat, c.lon)
            if(!lastCoordinate) {
                lastCoordinate = coordinate
                continue
            }

            var dist = lastCoordinate.distanceTo(coordinate)
            totalDistance += dist
            intervalDistance += dist
            if(useImperialUnits ? intervalDistance > style.imperialUnitFactor * 1000 : intervalDistance > 1000) {
                intervalDistance = 0
                result.push({
                                lat: c.lat,
                                lon: c.lon,
                                distance: totalDistance
                            })
            }

            lastCoordinate = coordinate
        }

        if(lastCoordinate) {
            result.push({
                            lat: lastCoordinate.latitude,
                            lon: lastCoordinate.longitude,
                            distance: totalDistance,
                            final: true
                        })
        }

        return result
    }

    function createNewTrack(document) {
        var trackNo = document.tracks.length + 1
        var t = pri.createTrack(qsTr("Track %1").arg(trackNo))
        document.tracks.push(t)
        document.file.modified = new Date()
        documentsChanged()
    }

    function insertPoint(documentIndex, trackIndex, segmentIndex, lat, lon) {
        var d = documents[documentIndex]
        var t = d.tracks[trackIndex]
        var segment = t.segments[segmentIndex]

        segment.push(pri.createPoint(lat, lon))

        d.file.modified = new Date()
        documentsChanged()
    }

    function removePoint(documentIndex, trackIndex, segmentIndex, index) {
        var d = documents[documentIndex]
        var t = d.tracks[trackIndex]
        var segment = t.segments[segmentIndex]
        segment.splice(index, 1)

        d.file.modified = new Date()
        documentsChanged()
    }

    function renameTrack(documentIndex, trackIndex, name) {
        var d = documents[documentIndex]
        var t = d.tracks[trackIndex]
        t.name = name
        d.file.modified = new Date()
        documentsChanged()
    }

    function deleteSegment(documentIndex, trackIndex, segmentIndex) {
        documents[documentIndex].tracks[trackIndex].segments.splice(segmentIndex, 1)
        documents[documentIndex].file.modified = new Date()
        documentsChanged()
    }

    function deleteTrack(documentIndex, trackIndex) {
        documents[documentIndex].tracks.splice(trackIndex, 1)
        documents[documentIndex].file.modified = new Date()
        documentsChanged()
    }

    function addSegment(documentIndex, trackIndex) {
        var s = []
        documents[documentIndex].tracks[trackIndex].segments.push(s)
        documents[documentIndex].file.modified = new Date()
        documentsChanged()
    }

    function splitSegment(track, segment, index) {
        var copy = JSON.parse(JSON.stringify(segment))    // Take deep-copy

        segment.splice(index + 1, segment.length - index - 1)   // Remove everything after 'index' (leave a common coordinate)

        copy.splice(0, index)   // Remove everything before 'index'

        track.segments.push(copy)
        documentsChanged()
    }

    function compressSegment(documentIndex, trackIndex, segmentIndex, minDistance) {
        var segment = documents[documentIndex].tracks[trackIndex].segments[segmentIndex]

        var c1 = QtPositioning.coordinate(segment[0].lat, segment[0].lon)
        for(var i = 1; segment.length > 1 && i < segment.length - 1;) {         // Ignore the last point
            var c2 = QtPositioning.coordinate(segment[i].lat, segment[i].lon)
            if(c1.distanceTo(c2) < minDistance) {
                segment.splice(i, 1)
            } else {
                c1 = c2
                i++
            }
        }

        // TODO: update modified timestamp here!
        documentsChanged()
    }

    function reverseSegment(documentIndex, trackIndex, segmentIndex) {
        var segment = documents[documentIndex].tracks[trackIndex].segments[segmentIndex]
        segment.reverse()

        var document = documents[documentIndex]
        document.file.modified = new Date()
        documentsChanged()
    }

    function cutSegment(documentIndex, trackIndex, segmentIndex) {
        var document = documents[documentIndex]
        var segment = document.tracks[trackIndex].segments[segmentIndex]

        Clipboard.setText(JSON.stringify(segment))						// Copy to clipboard

        document.tracks[trackIndex].segments.splice(segmentIndex, 1)	// Remove from the document

        document.file.modified = new Date()
        documentsChanged()
    }

    function copySegment(documentIndex, trackIndex, segmentIndex) {
        var document = documents[documentIndex]
        var segment = document.tracks[trackIndex].segments[segmentIndex]

        Clipboard.setText(JSON.stringify(segment))						// Copy to clipboard
    }

    function pasteSegment(documentIndex, trackIndex, segmentIndex) {
        var document = documents[documentIndex]
        var segment = document.tracks[trackIndex].segments[segmentIndex]

        var coordinates = JSON.parse(Clipboard.getText())
        segment.push.apply(segment, coordinates)    // Append to the given segment

        document.file.modified = new Date()
        documentsChanged()
    }

    function movePoint(documentIndex, trackIndex, segmentIndex, index, lat, lon) {
        var segment = documents[documentIndex].tracks[trackIndex].segments[segmentIndex]
        var c = segment[index]
        c.lat = lat
        c.lon = lon

        var document = documents[documentIndex]
        document.file.modified = new Date()
        documentsChanged()
    }

    function addWaypoint(document, name, lat, lon, comment) {
        var waypoints = document.waypoints || []
        document.waypoints = waypoints

        document.waypoints.push({
                             name: name,
                             lat: lat,
                             lon: lon,
                             cmt: comment,
                         })
        document.file.modified = new Date()
        documentsChanged()
    }

    function replaceWaypoint(document, waypointIndex, name, comment) {
        var place = document.waypoints[waypointIndex]
        place.name = name
        place.cmt = comment

        document.file.modified = new Date()
        documentsChanged()
    }

    function moveToNewTrack(documentIndex, trackIndex, segmentIndex) {
        var removedSegments = documents[documentIndex].tracks[trackIndex].segments.splice(segmentIndex, 1)

        var trackNo = documents[documentIndex].tracks.length + 1
        var t = pri.createTrack("Track %1".arg(trackNo))
        t.segments = removedSegments

        documents[documentIndex].tracks.push(t)
        documents[documentIndex].file.modified = new Date()
        documentsChanged()
    }

	// Private functions
    QtObject {
        id: pri

        function createTrack(name) {
            return {
                name: name,
                segments: []
            }
        }

        function createPoint(lat, lon) {
            return {
                lat: lat,
                lon: lon
            }
        }

        function saveDocument(path, doc) {
            var savedata = JSON.parse(JSON.stringify(doc))  // Take a deep-copy
            delete savedata['file']
            if(path.endsWith('.json')) {
                Utility.saveTextToFile(path, JSON.stringify(savedata, null, 4))
            } else if(path.endsWith('.gpx')) {
                var xml = GpxWriter.write(savedata)
                Utility.saveTextToFile(path, xml)
            }
        }

        // Remove coordinates, which are too close to each other.
        function filterCoordinates(coordinates) {
            var result = []
            var lastCoordinate

            for(var c of coordinates) {
                var coordinate = QtPositioning.coordinate(c.lat, c.lon)
                if(result.length === 0) {
                    result.push(c)
                    lastCoordinate = coordinate
                    continue
                }

                var dist = lastCoordinate.distanceTo(coordinate)

                if(dist >= routeFilterMinDistance) {
                    result.push(c)
                    lastCoordinate = coordinate
                }
            }

            return result
        }
    }
}
