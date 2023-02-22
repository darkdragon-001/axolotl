import QtQuick.Controls 2.2
import QtQuick 2.2
import Ubuntu.Components 1.3 as UITK
import QtWebEngine 1.7
import Ubuntu.Components.Popups 1.3 as UITK_Popups
import QtWebSockets 1.0
import QtMultimedia 5.8
import QtQuick.Controls.Suru 2.2
import Ubuntu.Content 1.3

UITK.Page {
  property QtObject request
  property QtObject wsClient
  property var handler
  property var contentType
  property var activeTransfer
  property var selectionType
  property var requestContentHub: false
  property string url
  id: root
  title: "Axolotl"
  WebEngineView {
    id: _webView
    profile: webProfile
    url: "http://localhost:9081/"
    settings.showScrollBars: false
    anchors {
      left: parent.left
      top: parent.top
      right: parent.right
      bottom: Qt.inputMethod.visible? showKeyboard.top: parent.bottom
    }
    onJavaScriptConsoleMessage: {
      var msg = "[Axolotl Web View] [JS] (%1: %2) %3".arg(sourceID).arg(lineNumber).arg(message)
      console.log(msg)
    }
    onLoadingChanged: {
      var msg = "[Axolotl Web View] [JS] url changed %1".arg(url)
      console.log(msg)
      if (url == "https://signalcaptchas.org/registration/generate.html"){
        console.log("[Axolotl Web View] [JS] run interceptor")
        var  interceptor = `
          // override the default onload function
            document.addEventListener('DOMContentLoaded', function () {
                window.renderCallback = function (scheme, sitekey, action, token) {
                    var targetURL = "http://localhost:9080/register?token=" + [scheme, sitekey, action, token].join(".");
                    var link = document.createElement("a");
                    link.href = targetURL;
                    link.innerText = "open axolotl";
                
                    document.body.removeAttribute("class");
                    setTimeout(function () {
                    document.getElementById("container").appendChild(link);
                    }, 2000);
                
                    window.location.href = targetURL;
                };
                function onload() {
                    alert("onload");
                    var action = document.location.href.indexOf("challenge") !== -1 ?
                      "challenge" : "registration";
                    var isDone = false;
                    var sitekey = "6LfBXs0bAAAAAAjkDyyI1Lk5gBAUWfhI_bIyox5W";
                  
                    var widgetId = grecaptcha.enterprise.render("captcha", {
                      sitekey: sitekey,
                      size: "checkbox",
                      theme: getTheme(),
                      callback: function (token) {
                        isDone = true;
                        renderCallback("signal-recaptcha-v2", sitekey, action, token);
                      },
                    });
                  
                    function execute() {
                      if (isDone) {
                        return;
                      }
                  
                      grecaptcha.enterprise.execute(widgetId, { action: action });
                  
                      // Below, we immediately reopen if the user clicks outside the widget. If they
                      //   close it some other way (e.g., by pressing Escape), we force-reopen it
                      //   every second.
                      setTimeout(execute, 1000);
                    }
                  
                    // If the user clicks outside the widget, reCAPTCHA will open it, but we'll
                    //   immediately reopen it. (We use onclick for maximum browser compatibility.)
                    document.body.onclick = function () {
                      if (!isDone) {
                        grecaptcha.enterprise.execute(widgetId, { action: action });
                      }
                    };
                  
                    execute();
                  }
                onload();
            });
        `
        _webView.runJavaScript(interceptor);
    
      }
    }
    onJavaScriptDialogRequested: function(request) {
      request.accepted = true;
      console.log("[axolotl ut] request: ", request.message)
      if(request.message =="desktopLink")
      {
        desktopLinkDialog.request = request; // keep the reference to the request
        desktopLinkDialog.visible = true;
        root.request = request;
      }
      else if(request.message =="refreshContacts")
      {
        root.request = request
        root.requestContentHub = true
        root.contentType = ContentType.Contacts
        root.handler = ContentHandler.Source
        root.selectionType = ContentTransfer.Multiple
      }
      else if(request.message =="photo")
      {
        root.request = request
        root.requestContentHub = true
        root.contentType = ContentType.Pictures
        root.handler = ContentHandler.Source
        root.selectionType = ContentTransfer.Single
      }
      else if(request.message =="video")
      {
        root.request = request
        root.requestContentHub = true
        root.contentType = ContentType.Videos
        root.handler = ContentHandler.Source
        root.selectionType = ContentTransfer.Single
      }
      else if(request.message =="document")
      {
        root.request = request
        root.requestContentHub = true
        root.contentType = ContentType.Documents
        root.handler = ContentHandler.Source
        root.selectionType = ContentTransfer.Single
      }
      else if(request.message =="audio")
      {
        root.request = request
        root.requestContentHub = true
        root.contentType = ContentType.Music
        root.handler = ContentHandler.Source
        root.selectionType = ContentTransfer.Single
      }
      else if(request.message.includes("[oC]"))
      {
        root.request = request
        root.requestContentHub = true
        root.url = request.message.substring(4)
        root.contentType = ContentType.Contacts
        root.handler = ContentHandler.Destination
        root.selectionType = ContentTransfer.Multiple
      }
      else if(request.message.includes("[oP]"))
      {
        root.request = request
        root.requestContentHub = true
        root.url = request.message.substring(4)
        root.contentType = ContentType.Pictures
        root.handler = ContentHandler.Destination
        root.selectionType = ContentTransfer.Single
      }
      else if(request.message.includes("[oV]"))
      {
        root.request = request
        root.requestContentHub = true
        root.url = request.message.substring(4)
        root.contentType = ContentType.Videos
        root.handler = ContentHandler.Destination
        root.selectionType = ContentTransfer.Single
      }
      else if(request.message.includes("[oD]"))
      {
        root.request = request
        root.requestContentHub = true
        root.url = request.message.substring(4)
        root.contentType = ContentType.Documents
        root.handler = ContentHandler.Destination
        root.selectionType = ContentTransfer.Single
      }
      else if(request.message.toLowerCase().includes("call"))
      {
        root.request = request
        var callUrl = request.message.substring(4)
        Qt.openUrlExternally("tel: ///"+callUrl);
        request.dialogAccept();

      }
      else if(request.message.toLowerCase().includes("http"))
      {
        Qt.openUrlExternally(request.message);
        request.dialogAccept();
      }
      else if(request.message =="paste")
      {
        request.dialogAccept(UITK.Clipboard.data.text ? UITK.Clipboard.data.text: "");
      }
      else {
        simpleDialog.request = request;
        simpleDialog.visible = true;
        root.request = request;
      }
      onFeaturePermissionRequested: {
        grantFeaturePermission(securityOrigin, feature, true);
      }
    }
    Connections {
      onFeaturePermissionRequested: {
        console.log("grantFeaturePermission", feature)
        _webView.grantFeaturePermission(securityOrigin, feature, true);
      }
    }

    WebEngineProfile {
      id: webProfile
    }
  }
  ContentPeerPicker {
    id: peerPicker
    anchors {
      fill: parent;
    }
    visible: root.requestContentHub
    contentType: root.contentType //ContentType.Pictures
    handler: root.handler //ContentHandler.Source
    // selectionType: root.selectionType
    onPeerSelected: {
      root.activeTransfer = peer.request()
      if(handler === ContentHandler.Source )
      {
        peer.selectionType = root.selectionType
        _webView.forceActiveFocus();
      }
      else {
        root.activeTransfer.stateChanged.connect(function() {
        if (root.activeTransfer.state === ContentTransfer.InProgress)
        {
          console.log("In progress", root.url);
          root.activeTransfer.items = [ resultComponent.createObject(parent, {"url": root.url}) ];
          root.activeTransfer.state = ContentTransfer.Charged;
          requestContentHub=false;
          request.dialogAccept();
          _webView.forceActiveFocus();
        }
      })
    }
  }
  onCancelPressed: {
    _webView.forceActiveFocus();
    request.dialogAccept("canceld");
    requestContentHub=false
  }
}

Connections {
  target: root.activeTransfer
  onStateChanged: {
    if(handler === ContentHandler.Source )
    {
      if (root.activeTransfer.state === ContentTransfer.Charged)
        requestContentHub=false
        if (root.activeTransfer.items.length > 0)
        {
          request.dialogAccept(root.activeTransfer.items[0].url);
        }
      }
    }
  }
  UITK_Popups.Dialog {
  id: desktopLinkDialog
  property QtObject request
  title: "Add signal desktop"
  text: "Scan QR-Code with Tagger from open store and paste the received code here"
  TextField {
    id: desktopId
    height: units.gu(10)
    anchors {
      left: parent.left
      right: parent.right
      topMargin: units.gu(0.1)
    }
    onPressAndHold: {
      desktopId.forceActiveFocus();
      desktopId.text = UITK.Clipboard.data.text ? UITK.Clipboard.data.text: "";
    }
    placeholderText: i18n.tr("tsdevice: /?uuid=...")
  }
  UITK.Button {
    text: "Paste"
    onClicked: {
      desktopId.text = UITK.Clipboard.data.text ? UITK.Clipboard.data.text: "";
    }
  }
  UITK.Button {
    text: "Cancel"
    onClicked: {
      UITK_Popups.PopupUtils.close(desktopLinkDialog)
      request.dialogAccept()
    }
  }
  UITK.Button {
    text: "Add"
    color: UITK.UbuntuColors.green
    onClicked: {
      request.dialogAccept(desktopId.text)
      UITK_Popups.PopupUtils.close(desktopLinkDialog)
    }
  }
}
UITK_Popups.Dialog {
id: simpleDialog
property QtObject request
title: "alert"
text: request.message
UITK.Button {
  text: "Cancel"
  onClicked: {
    UITK_Popups.PopupUtils.close(simpleDialog)
    request.dialogCancel()
  }
}
}
Connections {
  id: keyboard
  target: Qt.inputMethod
}
Item {
  id: showKeyboard
  height: keyboard.target.visible ? keyboard.target.keyboardRectangle.height / (units.gridUnit / 8): 0
  width: parent.width
  visible: Qt.inputMethod.visible
  anchors {
    // bottomMargin: (UbuntuApplication.inputMethod.visible) ? -height: 0
    // onBottomMarginChanged: hidden = (anchors.bottomMargin == -height ? true: hidden)
    left: parent.left
    right: parent.right
    bottom: parent.bottom
    // Behavior on bottomMargin {
    //   NumberAnimation {
    //     duration: UbuntuAnimation.FastDuration
    //     easing: UbuntuAnimation.StandardEasing
    //   }
    // }
  }
  Rectangle {
    color: "white"
    anchors.fill: parent
  }
}
Component.onCompleted: {
  webProfile.clearHttpCache();
}
Component {
  id: resultComponent
  ContentItem { }
}
}
