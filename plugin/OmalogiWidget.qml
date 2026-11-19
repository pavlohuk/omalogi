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
    // First connected MX Master's battery, or null while unknown or asleep.
    property var battery: null
    readonly property bool batteryLow: !!battery && battery.level <= 15 && !battery.charging
    function batteryText() {
        if (!battery) return ""
        var state = battery.charging ? " · charging" : battery.full ? " · full" : ""
        return " · " + (battery.approximate ? "about " : "") + battery.level + "%" + state
    }
    BarIconButton {
        id: button
        bar: root.bar
        text: "󰍽"
        labelText: root.battery && !vertical ? root.battery.level + "%" : ""
        slotSize: Style.bar.iconSlot * (labelText !== "" ? 2 : 1)
        foreground: root.batteryLow && root.bar ? root.bar.urgent : (root.bar ? root.bar.barForeground : Color.foreground)
        tooltipText: (root.battery ? root.battery.name : "Omalogi") + root.batteryText() + " · configure"
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
                if (result.ok && !result.busy) root.battery = result.batteries.length ? result.batteries[0] : null
            } catch (e) { root.battery = null }
        }
    }
    Timer {
        interval: 5 * 60 * 1000; repeat: true; running: true; triggeredOnStart: true
        onTriggered: if (!batteryPoll.running) batteryPoll.running = true
    }
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
