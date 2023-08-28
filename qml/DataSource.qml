import QtQuick 2.15

Item {
    property string host

    function sendRequest(method, path, body, callback) {
        // Create the XMLHttpRequest object
        var xhr = new XMLHttpRequest

        // Listen to the readyStateChanged signal
        xhr.onreadystatechange = function() {
          // If the state changed to DONE, we can parse the response
          if (xhr.readyState === XMLHttpRequest.DONE) {

            // Parse the responseText string to JSON format
            var responseJSON = JSON.parse(xhr.responseText)
            if(xhr.status === 200) {
                var r = responseJSON
                console.log('RESPONSE: ' + r)
                callback(responseJSON)
            } else {
                console.log('RESPONSE ERROR CODE: ' + xhr.status + ' - ' + r)
            }
          }
        }

        var url = host + (path || '/')

        // Define the target of your request
        console.log(method + ' ' + url)
        xhr.open((method || 'GET'), url)
        // Execute the request
        xhr.send(body)
    }
}
