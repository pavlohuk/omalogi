# Omalogi

Spanish version: [USAGE.es.md](USAGE.es.md).

Local MVP for configuring a Logitech MX Master connected through Bolt or Bluetooth: DPI, gesture button, side buttons and both scroll wheels. A Rust CLI, a QML panel in the Omarchy shell, and an external Solaar for HID++ and events.

Validated hardware compatibility is the **MX Master 3S connected through Bolt**. Settings are limited to the selected device; the configuration of other devices is preserved.

**Bluetooth:** pair and connect the mouse from the Omarchy Bluetooth panel; Omalogi detects it when its panel opens and the header shows `Bluetooth`. Over Bluetooth, Solaar does not report a serial number, so the mouse is identified by its Unit ID. If Solaar reports the same value as the serial over Bolt (as it does on the observed 3S), the profile follows the mouse when the connection changes. This path is experimental: it was tested on the same mouse (detection, gestures, wheels, DPI, apply, restore and reconnection), but one early test ended with the mouse leaving its Bluetooth channel. The likely cause is now avoided, but not proven; see [VALIDATION.md](../VALIDATION.md).

## Install

Follow [README.md](../README.md) to install from Omarchy Plugins or from source. The installer resolves Solaar, installs the binary and sets up the user service. The prebuilt release does not require Rust.

The rename migrates profiles, backups, Omalogi's own rules and the widget from the previous local installation. It stops if an operation is pending or if unrelated files exist at the target paths.

## Use

The widget opens a floating panel anchored to the bar, with two views. **Mouse** brings together the vector drawing of the device, DPI, gestures, side buttons and actions for both wheels. **Extras** contains inversion, resolution, ratchet, SmartShift and mouse tests.

Settings are saved and applied automatically after a 450 ms pause. The slider shows the value while you drag it and starts applying when you release it. Rapid changes are grouped; if you edit while the previous change is being verified, the latest value is kept for the next operation. The status distinguishes "Saving…", "Applying…" and "Profile active".

Escape, clicking outside, or the bar widget close the panel, even while applying. The operation and any queued changes continue in the background; closing releases the popup's input layer. Reopening keeps the pending value. There are no Refresh, Close, Save or Apply buttons. **Restore original**, in Extras, returns to the state before the first apply. If an operation fails, the desired value is kept and **Retry changes** appears; an incomplete recovery asks you to Restore. Nothing is retried indefinitely.

- **DPI:** the values exposed by the sensor; on this 3S, 200–8000 in steps of 50.
- **Gestures:** click without moving, plus four directions by holding the button, moving the mouse and releasing. All five are assigned when you customize; "No action" lets you disable one.
- **Buttons:** "Default behavior" keeps back and forward. They can also change DPI, volume, workspaces, playback, or open panels.
- **Wheels:** inversion, resolution, ratchet and SmartShift depending on capabilities. Rotation actions are optional and replace that wheel's normal scrolling in both directions. Choosing "Normal scrolling" in either direction returns both directions to normal behavior. When you customize one direction, the other becomes "No action" if it was still normal; you can assign it another action.
- **Tests:** records physical events with source `solaar`; a manual run is marked `manual` and does not count as a hardware test. The temporary logging mode replaces the actions of all controls until you reassign them or restore.

Initial profile: click opens apps; up opens the menu; down shows the scratchpad; left/right switch workspace. Side buttons and wheels keep their normal behavior.

## CLI

Every operation responds with JSON, including errors (exit code 1).

```bash
omalogi status
omalogi doctor
omalogi config
omalogi config --stdin < profile.json
omalogi apply --stdin < profile.json
omalogi apply
omalogi events
omalogi trigger gesture.click --manual
omalogi restore
```

The profile is a version 1 document. `config` returns an object with a `config` field: extract that field before using it as input, for example `omalogi config | jq .config > profile.json`.

## Persistence and restoration

The service starts with `graphical-session.target` and stops with the session. Solaar reapplies the settings when the device reconnects. The managed configuration stops ignoring the corresponding vertical controls; restoration recovers their original flags.

The backup and the operation log live in `~/.config/omalogi/`. Omalogi's own rules are added at the top of `~/.config/solaar/rules.yaml` between markers; the rest of the file is preserved verbatim. Solaar persistence is changed per device and per key, keeping other devices and settings. The "Mouse Gestures" software mode is preserved, which a physical read alone cannot distinguish from "Diverted".

The CLI validates before writing, stops its own service during the transaction, checks the physical reads of the modified settings, and recovers the previous state if anything fails. An interrupted operation leaves a pending record: run **Restore** before applying again. Keep the mouse connected during apply/restore. If you have another Solaar instance open outside the service, close it so it does not overwrite persistence.

If the profile is active but a gesture adds no events in the Extras tests, check the service log and try `systemctl --user restart omalogi-solaar.service`. During validation, stalled event capture was observed and recovered this way; a later apply worked normally. The cause is not proven. Avoid running parallel HID++ queries against the same device.

```bash
systemctl --user status omalogi-solaar.service
journalctl --user -u omalogi-solaar.service --no-pager
bash scripts/uninstall.sh
```

Uninstalling first restores the mouse and then removes Omalogi's own files. It keeps Solaar, backups and logs; if it cannot restore, it stops so it does not remove the recovery tool.

## Verify

```bash
cargo test --locked --offline
cargo clippy --locked --offline --all-targets -- -D warnings
python3 -m unittest discover -s tests -p 'test_*.py'
omarchy plugin validate .
python3 scripts/test-panel.py
```

`test-panel.py` runs the real QML widget in an isolated Quickshell instance with a slow simulated CLI: grouping, queueing, closing while applying, reopening, error and retry. It does not write to hardware.

The Python transaction tests use `target/debug/omalogi`, produced by `cargo test`. They cover a write failure after persisting an attempted value, several applies in a row, software-mode restoration, and preservation of foreign rules.

Real-hardware validation is recorded in [VALIDATION.md](../VALIDATION.md). The `scripts/validate-hardware.py` scripts prepare and verify a local test; wheel rotations, gestures, reconnection and a new session require physical interaction. Simulated tests do not certify those steps.

## MVP limits

Only this machine and mouse are validated; universal support for other models or versions is not promised. Solaar remains a dependency, and writing and verification still depend on HID++ queries. With an active profile, DPI and inversions read, write and verify only the modified settings over a single Solaar connection; actions that keep the current capture mode only update the rules. Mode changes, ratchet/SmartShift and the first apply use the full transaction. Every path keeps the backup, pending record and rollback; real timing depends on the device. Available actions are predefined and invoked without a shell; arbitrary commands and a native HID++ daemon are left for a later version.

Sources and decisions: [scope](../MVP_SCOPE.md) (Spanish), [Omarchy](../research/omarchy-integration.md), [Solaar contract](../research/device-controls.md), [future HID++ path](../research/hidpp-native-path.md).
