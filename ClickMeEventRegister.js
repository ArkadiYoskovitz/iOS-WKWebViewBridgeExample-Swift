function postMessage() {
    var messgeToPost = {
        //'ButtonId':'mobile_share_fb'
        'ButtonId':'clickMeButton'
    };
    window.webkit.messageHandlers.buttonClicked.postMessage(messgeToPost);
}

var button = document.getElementById("clickMeButton");
//var button = document.getElementById("tsbb");
//var button = document.getElementByClass("mobile_share_fb")
button.addEventListener("click", postMessage ,false);
