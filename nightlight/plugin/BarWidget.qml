import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "local.solar-nightlight"
  property bool enabled: true
  property int temperature: 6500
  property int nightTemperature: 4000
  property int fadeMinutes: 30
  property string scheduleMode: "solar"
  property int startMinutes: 1200
  property int endMinutes: 420
  property string locationMode: "timezone"
  property real latitude: 0
  property real longitude: 0
  property string timezone: ""
  property string sunrise: "--:--"
  property string sunset: "--:--"
  property bool popupOpen: false

  function refresh() { if (!statusProcess.running) statusProcess.running = true }
  function run(args) {
    controlProcess.command = [Quickshell.env("HOME") + "/.local/bin/omarchy-solar-nightlight"].concat(args)
    controlProcess.running = true
  }
  function close() { popupOpen = false }
  function clock(minutes) {
    var hour = Math.floor(minutes / 60)
    var minute = minutes % 60
    return String(hour).padStart(2, "0") + ":" + String(minute).padStart(2, "0")
  }

  implicitWidth: button.implicitWidth
  implicitHeight: barSize

  BarIconButton {
    id: button
    anchors.centerIn: parent
    bar: root.bar
    active: root.enabled
    text: "󰔎"
    dimmed: !root.enabled
    tooltipText: root.enabled
      ? "Night light on · " + root.temperature + "K · sunset " + root.sunset
      : "Night light off"

    MouseArea {
      anchors.fill: parent
      hoverEnabled: true
      acceptedButtons: Qt.LeftButton | Qt.RightButton
      cursorShape: Qt.PointingHandCursor
      onClicked: function(mouse) {
        if (mouse.button === Qt.RightButton) root.popupOpen = !root.popupOpen
        else root.run(["--toggle"])
      }
      onEntered: if (root.bar) root.bar.showTooltip(button, button.tooltipText)
      onExited: if (root.bar) root.bar.hideTooltip(button)
    }
  }

  PopupCard {
    anchorItem: root
    bar: root.bar
    owner: root
    open: root.popupOpen
    contentWidth: fittedContentWidth(Style.space(320))
    contentHeight: fittedContentHeight(panel.implicitHeight)

    Column {
      id: panel
      anchors.fill: parent
      spacing: Style.space(12)

      Text {
        text: "Solar Night Light"
        color: root.bar.foreground
        font.family: root.bar.fontFamily
        font.pixelSize: Style.font.subtitle
        font.bold: true
      }

      Toggle {
        width: parent.width
        label: "Enabled"
        description: root.enabled ? "Following sunrise and sunset" : "Stays off until you turn it on"
        checked: root.enabled
        onClicked: root.run(["--toggle"])
      }

      Toggle {
        width: parent.width
        label: "Automatic schedule"
        description: root.scheduleMode === "solar" ? "Sunset to sunrise" : "Using custom times"
        checked: root.scheduleMode === "solar"
        onClicked: root.run(["--schedule-mode", root.scheduleMode === "solar" ? "custom" : "solar"])
      }

      Column {
        width: parent.width
        spacing: Style.space(6)
        visible: root.scheduleMode === "custom"
        Text { text: "Turn on  " + root.clock(root.startMinutes); color: root.bar.foreground; font.family: root.bar.fontFamily }
        PanelSlider {
          width: parent.width; bar: root.bar; minimum: 0; maximum: 1439; step: 15; integer: true; value: root.startMinutes
          onReleased: function(value) { root.run(["--start-minutes", String(Math.round(value / 15) * 15)]) }
        }
        Text { text: "Turn off  " + root.clock(root.endMinutes); color: root.bar.foreground; font.family: root.bar.fontFamily }
        PanelSlider {
          width: parent.width; bar: root.bar; minimum: 0; maximum: 1439; step: 15; integer: true; value: root.endMinutes
          onReleased: function(value) { root.run(["--end-minutes", String(Math.round(value / 15) * 15)]) }
        }
      }

      Text {
        text: root.timezone + "  ·  " + root.sunrise + " → " + root.sunset
        color: Qt.darker(root.bar.foreground, 1.35)
        font.family: root.bar.fontFamily
        font.pixelSize: Style.font.caption
      }

      Toggle {
        width: parent.width
        label: "Automatic location"
        description: root.locationMode === "timezone" ? "From the system timezone" : "Using manual coordinates"
        checked: root.locationMode === "timezone"
        onClicked: {
          if (root.locationMode === "manual") root.run(["--location-mode", "timezone"])
          else {
            latitudeField.text = String(root.latitude)
            longitudeField.text = String(root.longitude)
            root.locationMode = "manual"
          }
        }
      }

      Row {
        width: parent.width
        spacing: Style.space(6)
        visible: root.locationMode === "manual"
        TextField { id: latitudeField; width: (parent.width - Style.space(6)) / 2; placeholderText: "Latitude"; foreground: root.bar.foreground }
        TextField { id: longitudeField; width: (parent.width - Style.space(6)) / 2; placeholderText: "Longitude"; foreground: root.bar.foreground }
      }
      Button {
        visible: root.locationMode === "manual"
        width: parent.width
        text: "Apply manual location"
        bordered: true
        onClicked: root.run(["--location-mode", "manual", "--latitude", latitudeField.text, "--longitude", longitudeField.text])
      }

      Text { text: "Night warmth  " + root.nightTemperature + "K"; color: root.bar.foreground; font.family: root.bar.fontFamily }
      PanelSlider {
        width: parent.width
        bar: root.bar
        minimum: 2500
        maximum: 5000
        step: 100
        integer: true
        value: root.nightTemperature
        onReleased: function(value) { root.run(["--night-temperature", String(Math.round(value / 100) * 100)]) }
      }

      Text { text: "Sunrise/sunset fade  " + root.fadeMinutes + " min"; color: root.bar.foreground; font.family: root.bar.fontFamily }
      PanelSlider {
        width: parent.width
        bar: root.bar
        minimum: 5
        maximum: 120
        step: 5
        integer: true
        value: root.fadeMinutes
        onReleased: function(value) { root.run(["--fade-minutes", String(Math.round(value / 5) * 5)]) }
      }
    }
  }

  Process {
    id: statusProcess
    command: [Quickshell.env("HOME") + "/.local/bin/omarchy-solar-nightlight", "--status"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        try {
          var state = JSON.parse(text)
          root.enabled = state.enabled === true
          root.temperature = Number(state.temperature || state.scheduled_temperature || 6500)
          root.nightTemperature = Number(state.night_temperature || 4000)
          root.fadeMinutes = Number(state.fade_minutes || 30)
          root.scheduleMode = String(state.schedule_mode || "solar")
          root.startMinutes = Number(state.start_minutes || 1200)
          root.endMinutes = Number(state.end_minutes || 420)
          root.locationMode = String(state.location_mode || "timezone")
          root.latitude = Number(state.latitude || 0)
          root.longitude = Number(state.longitude || 0)
          root.timezone = String(state.timezone || "")
          root.sunrise = String(state.sunrise || "--:--")
          root.sunset = String(state.sunset || "--:--")
        } catch (error) {}
      }
    }
  }

  Process { id: controlProcess; onExited: refresh() }
  Timer { interval: 5000; repeat: true; running: true; triggeredOnStart: true; onTriggered: root.refresh() }
}
