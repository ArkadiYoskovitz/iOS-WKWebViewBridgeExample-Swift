function postMessage() {
    var messgeToPost = openGraphValues() //JSON.stringify( openGraphValues() )
    window.webkit.messageHandlers.openGraphClicked.postMessage(messgeToPost);
}

function validOpenGraphTag(tag) {
    
    var property = tag.getAttribute('property')
    
    if (typeof property == "string" && property.includes('og:') ) {
        return true
    }
    return false
}

function openGraphValues() {
    
    var graphTags = {}
    Array.prototype.slice.call(document.head.getElementsByTagName('meta')).filter( validOpenGraphTag ).forEach( function (element) {
        graphTags[ element.getAttribute('property') ] = element.getAttribute('content')
    })
    return graphTags
}
window.onload = function () { postMessage() }
