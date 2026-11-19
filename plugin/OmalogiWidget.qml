import QtQuick
import Quickshell
import Quickshell.Io
import qs.Ui
import qs.Commons

Panel {
    id: root
    property var shell: null
    property var manifest: null
    moduleName: "omalogi.mouse"
    manageIpc: false
    implicitWidth: button.implicitWidth
    implicitHeight: button.implicitHeight
    // The persistent panel owns the process; hiding only releases the popup input layer.
    function close() { controller.hide() }
    // First connected MX Master's battery, or null while unknown or asleep. The panel shows
    // it; the bar stays an icon and a notification speaks up only when the level is low.
    property var battery: null
    readonly property int lowLevel: 10
    property bool lowNotified: false
    function batteryText() {
        if (!battery) return ""
        var state = battery.charging ? " · charging" : battery.full ? " · full" : ""
        return (battery.approximate ? "about " : "") + battery.level + "%" + state
    }
    function checkLow() {
        if (!battery) return
        // Re-arm only clearly above the threshold, so a level wavering at 9–10% notifies once.
        if (battery.charging || battery.level >= lowLevel + 5) { lowNotified = false; return }
        if (battery.level >= lowLevel || lowNotified) return
        lowNotified = true
        notify.command = ["notify-send", "-u", "critical", "-a", "Omalogi", "-i", "input-mouse",
            battery.name + " battery low", battery.level + "% left. Charge the mouse soon."]
        notify.running = true
    }
    Process { id: notify }
    BarIconButton {
        id: button
        bar: root.bar
        text: "󰍽"
        tooltipText: "Omalogi · configure MX Master"
        onPressed: function(button) { if (button === Qt.LeftButton) root.toggle() }
    }
    // One HID++ battery request per poll; the CLI skips while a transaction owns the mouse.
    Process {
        id: batteryPoll
        command: [Quickshell.env("HOME") + "/.local/bin/omalogi", "battery"]
        stdout: StdioCollector { id: batteryOut; waitForEnd: true }
        onExited: {
            try {
                var result = JSON.parse(batteryOut.text)
                if (!result.ok || result.busy) throw new Error("not read")
                root.battery = result.batteries.length ? result.batteries[0] : null
                root.checkLow()
            } catch (e) {
                // A transaction or a waking mouse: keep the last level and try again soon.
                batteryRetry.restart()
            }
        }
    }
    function pollBattery() { if (!batteryPoll.running) batteryPoll.running = true }
    Timer {
        interval: 5 * 60 * 1000; repeat: true; running: true; triggeredOnStart: true
        onTriggered: root.pollBattery()
    }
    Timer { id: batteryRetry; interval: 30 * 1000; onTriggered: root.pollBattery() }
    OmalogiPanel { id: panel; ownerWidget: root; anchorItem: button; bar: root.bar }
    // Monitor-scoped UI navigation and geometry for local diagnostics/captures.
    IpcHandler {
        enabled: root.opened
        target: "omalogi.mouse." + (panel.screen ? panel.screen.name : "unknown")
        function view(name: string): void { if (name === "Mouse" || name === "Extras") panel.page = name }
        function geometry(): string {
            return JSON.stringify({screen:panel.screen ? panel.screen.name : "",x:panel.cardOrigin.x,y:panel.cardOrigin.y,width:panel.contentWidth,height:panel.contentHeight,page:panel.page,dirty:panel.dirty,busy:panel.busy})
        }
    }
}
