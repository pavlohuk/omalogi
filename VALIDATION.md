# MVP validation

Spanish original: [VALIDATION.es.md](VALIDATION.es.md).

Date: 2026-09-29. Status: installed; physical controls, restoration and desktop actions checked; validation sign-off pending. This document separates observed results from pending steps.

## Observed machine

- Omarchy 4.0.4-1, Hyprland 0.56.2-2, Quickshell 0.3.1-1.
- Solaar 1.1.20-2 and Rust 1.98.1.
- MX Master **3S**, HID++ 4.5, serial `[omitted]`, Bolt USB `046d:C548`.
- DPI: 200–8000, steps of 50. Previous state: 1000 DPI, Ratcheted, SmartShift 10, wheel inversion/resolution/diversion off; default buttons.

## Completed checks

- Rust release build and contract tests: 6 passed.
- Python tests: 6 passed. They cover selective preservation, rollback after persisting a failed value, several applies, software mode, free spin with saved threshold, and recovery from a transient read at startup.
- Clippy on all targets with warnings as errors: passed.
- Manifest validation with `omarchy plugin validate .`: passed.
- Local installation and plugin enablement through official commands: completed.
- `omalogi-solaar.service`: started; `graphical-session.target` was active.
- The first physical apply detected a derived SmartShift 1 read in Freespinning. Rollback recovered the previous settings (later read: SmartShift 10). The implementation now verifies the threshold with Ratcheted before selecting Freespinning.
- An explicit recovery completed a pending record with the message "Original state restored and verified". The panel now protects closing during an operation, and file updates take the same lock.
- Diagnostic physical apply completed: 1200 DPI, vertical inversion/resolution on, horizontal inversion on, Freespinning and saved SmartShift threshold 12; eleven diagnostic assignments. The CLI verified the hardware and service startup. Evidence: `artifacts/hardware-apply.json`.
- Eleven physical events with source `solaar` and a successful result: five gestures, back/forward, vertical up/down and horizontal left/right. `scripts/validate-hardware.py verify` returned `missing: []`; evidence `artifacts/hardware-after.json`.
- The user confirmed turning the mouse off and on and retesting a gesture and a wheel rotation. Later reads kept DPI and diversions. A scroll-mode change was observed during the interaction; an isolated service restart after selecting Freespinning did **not** reproduce it (`artifacts/probe-scroll.json`). It is not attributed to a persistence failure without evidence.
- Full restoration compared with the previous state: 1000 DPI, Ratcheted, SmartShift 10, wheel inversion/resolution/diversion off and original buttons. `scripts/validate-hardware.py restore` returned `restoration_verified: true`; evidence `artifacts/hardware-restored.json`.
- Before the panel redesign: independent visual review of the five tabs in a native 855×1408 window. The reviewer asked for two fixes; their second pass rated both as resolved: secondary-text contrast (about 5.1:1) and draft preservation with explicit discard. The second verdict covers those fixes; it does not certify interactions that were not exercised.

## Pending physical evidence

- Startup in a real new session (physical reconnection of the mouse is already confirmed). The user chose to do this check later; the full goal remains pending that evidence.

The panel test saved "Omarchy menu" for the click, and the apply finished with `applied: true`, `pending: false` and the service active. The user reported that Apps did not open; the observed profile still assigned Menu and there was no new physical event in the log. A manual run of the Menu action returned success, marked `source: manual`; it does not replace checking the physical click, nor does it confirm selecting Apps from the panel.

After restarting Solaar to get a temporary trace, clicks and gestures were recorded with the Menu and workspace-switch actions. The trace was removed and the normal service restored. The user then confirmed that the click opened Menu and the right gesture switched workspace; the log contains both actions with `source: solaar` and `ok: true`. This confirms physical execution of the profile saved from the panel. The restart resolved the observed symptom; no proven cause or permanent fix is claimed from that result alone. The normal profile was applied afterwards (`artifacts/hardware-normal.json`).

The user confirmed that the click with the freshly applied normal profile opened Apps. The service log showed `gesture.click → apps`, `gesture.up → menu` and `gesture.right → workspace.next`, all with source `solaar` and a successful result. The earlier failure did not reproduce in this later apply. The final profile keeps 1000 DPI, Ratcheted/SmartShift 10, default wheels and side buttons, and the five initial gestures defined in the scope.

The last status query of this session returned `applied: true`, `pending: false` and `daemon: true`; `systemctl --user is-enabled omalogi-solaar.service` returned `enabled`. Enablement and the verified restarts do not replace startup in a new session.

JSON artifacts from the real operations are stored in `artifacts/hardware-*.json`. Tests with the simulated backend do not satisfy the pending steps.


## Panel redesign

- `omalogi.mouse` works as a widget with a `Panel`/`KeyboardPanel` anchored to the bar. Mouse and Extras were captured on the real desktop at 920×690; evidence `.impeccable/review/{mouse,extras}.png` and their JSON geometries. The Hyprland client list contains no tiled Omalogi window.
- Mouse shows DPI, five gestures, two side buttons and four wheel actions around the vector diagram at the same time. Extras contains inversions, resolution, ratchet, SmartShift and diagnostics.
- The drawing follows the top-down photo of the MX Master 3S the user provided later: wide body, thumb rest, straight wheel and separated top buttons. Interactive points and connectors were updated to that outline.
- Installation updated, manifest validation passed, and no Omalogi QML errors in the shell log.
- Final independent visual review: `ship`, with no material fixes. It approved both captures and the drawing's match with the photo. Drawing interactions and draft preservation were reviewed in code; that review does not claim them as tested. An automated Tab/arrow walk did not produce a draft, so it does not certify editing or discarding on reopen.
- This review changes the interface and layout; it does not repeat or replace the earlier physical tests or the pending new-session test.


## Automatic apply and lock fix

- The isolated test of the native widget reproduced the blocked close twice: with a simulated apply in progress, `OmalogiWidget.close()` left `opened: true`. Removing the close guard hid the panel layer (`closed: true`) while the process kept running. That is the path used by `KeyboardPanel`'s outside close.
- `scripts/test-panel.py` tests change grouping, latest value queued, close/reopen during an apply, background completion, and failure without a retry loop. It uses native QML and a slow simulated CLI, not physical input.
- The user confirmed on the installed version that they can use the mouse/keyboard outside the panel and that settings apply automatically. They then reported slowness; the update path was investigated and fixed.
- Measurement of the previous path: reapplying the same profile took 12.104 s; the three full Solaar queries took 3.617, 3.869 and 3.986 s. With incremental updates, the same operation took 0.429 s and did not query HID.
- Real DPI change 1300 → 1350 → 1300, keeping the user's assignments: both operations were physically verified and took 2.637 and 2.739 s. Evidence `artifacts/fast-apply-timing.json`. These are CLI times; the UI adds a 450 ms grouping pause and may have an earlier setting queued.
- With an active profile, DPI and inversions use the adapter for the installed Solaar library over one connection: previous values, validation, write without internal persistence, read-back and rollback. Rust persists selectively after verifying. An adapter crash leaves the pending record and requires Restore. Actions with the same capture mode update rules without physical queries; changing ratchet/SmartShift, capture modes or applying for the first time keeps the full transaction.
- The visual review rated its only fix as resolved: documentation of the automatic flow and of closing. That verdict does not certify every physical path of the new adapter.

## Preparing Omalogi for distribution — 2026-09-29

The project was renamed to Omalogi, with the `omalogi` CLI, the `omalogi.mouse` plugin, configuration in `~/.config/omalogi/` and the `omalogi-solaar.service` service. The names used above follow the current naming; the historical physical tests were done before the rename. The code keeps references to the old name only for migration and recovery.

- Single manifest at the root, author and version `0.1.0-beta.1` shared with Cargo and Cargo.lock; official Omarchy validation and metadata check passed.
- Seven Rust contracts and 28 Python tests passed. Nine new tests cover installation, reinstallation, unrelated files, native Git checkout, migration, pending operation, conflicting configuration directories, rollback on write failure, and uninstall restrictions.
- Rust formatting and Clippy passed with no warnings. The isolated native QML test passed grouping, queueing, close/reopen, background completion and error/retry. Running it requires a graphical session; an attempt inside the sandbox could not open Wayland and is not counted as a product result.
- Real migration through the source installer: the profile and original snapshot were kept; Omalogi's own rules changed markers and executable path. The old service was removed and `omalogi-solaar.service` ended up active and enabled. The follow-up query returned `ok: true`, `applied: true`, `pending: false`, `daemon: true`. The shell discovered the plugin named Omalogi with `enabled: true`.
- Local distribution archive generated and checksum verified with the machine's GNU binary. The public release uses a separate musl build in GitHub Actions; that workflow was pending when preparation closed; its result is recorded below.
- Public preview of the native components generated with simulated device data and an opaque background; the real serial and local logs are not included.

This preparation does not certify a new session, an installation on another machine, the remote workflow, or additional physical tests of gestures and wheels after the migration. Publishing steps are in [docs/PUBLISHING.md](docs/PUBLISHING.md).

## Publishing on GitHub — 2026-09-29

- Code on `main` and tag `v0.1.0-beta.1` published. The beta is available on [GitHub Releases](https://github.com/AlejandroFloresArroyo/omalogi/releases/tag/v0.1.0-beta.1).
- GitHub Actions passed [Checks on main](https://github.com/AlejandroFloresArroyo/omalogi/actions/runs/36650398640), [Checks on the tag](https://github.com/AlejandroFloresArroyo/omalogi/actions/runs/36650399307) and [Release](https://github.com/AlejandroFloresArroyo/omalogi/actions/runs/36650399296).
- The release's Linux x86_64 musl binary was downloaded and verified locally: correct version, no ELF interpreter, archive limited to the executable and license, correct checksum, and a match with the digests of the assets uploaded to GitHub.
- Twelve transaction tests passed using that binary and simulated Solaar processes. Nothing was written to hardware.
- After publishing, the archive and its checksum were downloaded without authentication from the same URLs the installer uses; verification passed.

Publishing on GitHub is not admission to the Omarchy Plugins catalog. The real new graphical session and installation on a second clean environment remain pending.

## Bluetooth support — 2026-10-01

Status: implemented and covered by simulated tests. A first physical test confirmed detection, gestures, DPI and restoration over Bluetooth and ended with an **incident with no proven cause**. After adding a wait at service startup and at reconnection, the following tests repeated that sequence without incident and covered a full apply, all eleven controls and reconnection. The likely cause is identified but not proven; Bluetooth remains experimental. This section describes what was checked before pairing the mouse over Bluetooth.

Facts checked by reading the installed Solaar 1.1.20 (`/usr/lib/python3.14/site-packages`):

- A direct device has no pairing record: `Device.serial` returns an empty string (`logitech_receiver/device.py`, `_serial = pairing_info["serial"] if pairing_info else None`). `solaar show` prints it as a header without a slot number, with an empty `Serial number:` and a `Unit ID:` (`solaar/cli/show.py`, `_print_device`).
- `solaar config <device>` matches serial, codename, kind and name (`solaar/cli/__init__.py`, `_find_device`); the Unit ID selects nothing. Rules (`Device:`) and persistence (`_modelId` + `_unitId`) do accept it.
- Solaar's udev rule grants access to Logitech Bluetooth `hidraw` (`KERNELS == "0005:046D:*"` in `42-logitech-unify-permissions.rules`).

Completed checks:

- 10 Rust contracts and 57 Python tests passed. Transactions (apply, restore, rollback, incremental path, interrupted operation) run twice: with the simulated backend as Bolt and as Bluetooth. The simulated Bluetooth backend rejects selection by Unit ID when `solaar config` is invoked without the adapter, just like real Solaar.
- `tests/test_solaar_cli.py` runs the adapter's six cases against Solaar 1.1.20's real `_find_device` with simulated devices, plus a reference copy of its rules for environments without Solaar.
- Mutation check: removing Unit ID identification, accepting the Unit ID nested in features, removing the `transport` default in saved states, skipping the adapter, or removing its Unit ID match makes at least one test fail in each case.
- Real Bolt, read-only: the output of `solaar config <serial>` and of the adapter were identical except for the final `# transport: Bolt` line (53 and 54 lines). `omalogi status` with the new binary returned `ok: true`, `transport: Bolt`, 11 settings, 5 buttons, `applied: true`, `pending: false`, `daemon: true`.
- `scripts/test-panel.py` passed with the real QML, including the `Bluetooth · TEST1234 · Connected` header with a simulated CLI.

### Physical Bluetooth test — 2026-10-01, 22:15–22:23

The user paired the MX Master 3S over Bluetooth; the Bolt pairing stayed on the receiver. Build installed from this branch (`8550aaa`) with `scripts/install.sh --from-source`. The active profile had been applied days earlier over Bolt.

Observed:

- Kernel, 22:15:45: `BLUETOOTH HID v0.06 Mouse [Logitech MX Master 3S]`, `hidraw11`, `HID++ 4.5 device connected`. The udev rule granted the user access (ACL present on the node).
- `solaar show` printed the mouse as a header without a slot, with an empty `Serial number:` and `Unit ID:` at device level, and the Bolt pairing as `Device is offline.`: the same shape as the fixtures.
- Stock `solaar config <Unit ID>` failed with `no online device found matching`; the previously installed binary failed the same way. The adapter returned the settings and `# transport: Bluetooth`; `omalogi status` with the new binary returned `ok: true`, `transport: Bluetooth`, 11 settings.
- The identifier of the profile applied over Bolt matched the Unit ID over Bluetooth. Solaar used the same persistence entry (the file had two entries: this mouse and another device).
- Gestures over Bluetooth with source `solaar` and `ok: true`: all five at 22:16:20–22 with the existing rules, and six more at 22:18:52–57, after two service restarts.
- Incremental DPI 1300 → 1350 → 1300 over Bluetooth: 0.97 s and 0.89 s, each with a correct read-back and `applied: true`, `pending: false`, `daemon: true`.
- `omalogi restore` over Bluetooth, from a snapshot taken over Bolt: 11.4 s, "restored and verified" according to the CLI's own check.

Incident:

- Restoration started the service at 22:19:13.5 and `omalogi status` was launched immediately, which is also what the panel does after restoring. The service logged invalid reads from 22:19:14.66 (`AttributeError` reading the battery) and 14 errors in 17 s; the three earlier starts in the session logged none.
- 22:19:15.99: `bluetoothd` logged `Write output report failed`. The `hidraw11` node disappeared and the mouse then responded over Bolt. `status` returned "The mouse is not responding" during the switch.
- Over Bolt, the next read showed `scroll-ratchet: Freespinning` even though the restoration had just verified `Ratcheted`.
- Solaar left settings unrelated to a mouse in its persistence (`headset-*`, `analog-button-tuning_*`, `crown-smooth`, `logivoice-nr-state`), `_NAME: BL`, and a second entry for the same Unit ID with `dpi` and `divert-keys` marked as absent. The backup from before the test already contained one key of that kind (`logivoice-ng-state`), of unknown date.

Cause: **not proven**. Hypothesis: the freshly started service and the CLI queried HID++ at the same time on the same Bluetooth `hidraw` node, and each process interpreted the other's responses; a misdirected write would explain the channel and scroll-mode change. It is not ruled out that the channel was switched by hand with Easy-Switch. No attempt was made to reproduce it.

Recovery:

- Profile reapplied over Bolt through the adapter: full transaction, 26.9 s, verified (1300 DPI, Ratcheted, SmartShift 10, gesture button diverted). This also covers writing over Bolt with the adapter, which previously had only read coverage. `rules.yaml` was byte-for-byte identical to the pre-test file.
- That reapply took the Freespinning state as its baseline. With the service stopped, `~/.config/solaar/config.yaml` and `~/.config/omalogi/state.json` were restored from the backup taken before the test, whose profile and values match those applied. Final state: `transport: Bolt`, `applied: true`, `pending: false`, `daemon: true`, original baseline, no new errors in the service log.
- Time for one read over Bolt, three pairs: stock Solaar 2.57/2.20/2.21 s; adapter 2.19/2.22/2.21 s.

### Wait at service startup and second test — 2026-10-01, 23:18–23:33

Passive measurement (reading the Logitech `hidraw` nodes, sending nothing), three service restarts with no CLI queries, with the mouse on Bluetooth since 23:18:02:

- The mouse's Bluetooth node: 121 HID++ responses per restart, the first 0.36–0.47 s after start and the last at 2.55–2.88 s, with no gaps longer than 0.5 s.
- Another Logitech mouse through a Lightspeed receiver: 202–208 responses, up to 2.96–3.10 s. Bolt receiver node: 9.
- The incident happened 2.46 s after a start, inside that window and with an overlapping CLI query. This is consistent with the cross-read hypothesis; it does not prove it.

Change: before any HID++ query, the CLI asks systemd how long the service has been active and waits until 6 s have passed. Transactions stop the service and do not wait. Tests: 11 Rust contracts and 60 Python tests; three of them check that no query reaches the mouse during the first 3 s, with and without a saved profile, and that a settled service adds no delay. Mutation check: removing the wait in `config`, removing it in discovery, ignoring the service's age, or waiting with the service stopped makes a test fail in each case.

With build `2b653a4` installed and the mouse on Bluetooth:

- The incident sequence, five times in a row: `restore`, immediate `status`, `apply` of the profile, immediate `status`. The ten immediate queries took 7.4–8.7 s (wait included) and returned `transport: Bluetooth` with the expected values (1000 DPI and normal gesture button after restoring; 1300 DPI and diverted after applying). Zero errors in the service log, a single Solaar entry for the mouse, no new or lost keys.
- Ten full transactions over Bluetooth in those cycles: `restore` 10.6–11.6 s and `apply` 10.2–11.1 s, all verified by the CLI.
- Diagnostic profile (eleven events, both wheels and side buttons diverted) applied and verified in 11.3 s. Physical events from the user with source `solaar` and `ok: true`: `gesture.click` (3), `gesture.right` (2), `wheel.up` (10), `wheel.down` (27), `thumb.left` (1), `thumb.right` (1).
- No `button.back`, `button.forward`, `gesture.up`, `gesture.down` or `gesture.left` were recorded in that 150 s window. The user said afterwards that they did not see the prompt and did not press them. The three gestures were recorded over Bluetooth in the first test; the side buttons were tested in the third.
- Reconnection: the Bluetooth node was absent for 2.5 s and returned at 23:31:59. The system did not log the reason, and there is no record of the user turning the mouse off. After reconnecting, `wheel.down` was recorded with source `solaar`: Solaar restored the wheel diversion. 10 s were waited after the reconnection before the next CLI query.
- Close: user profile reapplied and verified over Bluetooth; `applied: true`, `pending: false`, `daemon: true`; zero service errors during the whole window.

### Wait after reconnecting and third test — 2026-10-01, 23:37–23:50

Mechanism: Solaar 1.1.20 uses a fixed HID++ software identifier (`SOLAAR_SOFTWARE_ID = 0x0B` in `logitech_receiver/base.py`; `_get_next_sw_id` always returns it). The service and any CLI process using its library send with the same identifier, so on a shared node neither can tell its responses from the other's. In the captures, responses with identifier 1 (15, up to 0.55 s) belong to the kernel driver and those with identifier 11 (122) to Solaar. This explains how cross-reads happen; it does not prove they caused the channel switch.

Passive measurement of seven reconnections triggered with `bluetoothctl disconnect` and `connect`, with the service active and no CLI queries:

- In six, 137 HID++ responses from 0.02–0.07 s to 2.54–2.94 s after the node appeared.
- In one, 174 responses with a second burst between 4.44 and 5.25 s. That capture did not classify traffic, so it is unknown who originated it.
- The modification time of `/dev/hidrawN` matched the kernel's connection time and did not change during six minutes of use.

Change: the 6 s wait now counts from whichever happened last, the service start or the appearance of the most recent Logitech Bluetooth node. With the service stopped, it does not wait. Tests: 13 Rust contracts and 60 Python tests. Mutation check: ignoring the reconnection, counting Bluetooth nodes from other vendors, counting Logitech USB nodes, taking the oldest node, or ignoring the service state makes a test fail in each case. The call that passes the real `/sys/class/hidraw` and `/dev` paths has no automated test; the following measurement covers it.

With build `93e7e3a` installed and the mouse on Bluetooth:

- Three reconnections with `omalogi status` launched 0.0 s after the node appeared: the response arrived 8.44–8.65 s after connection, `ok: true`, `transport: Bluetooth`, 1300 DPI, gesture button diverted. Zero service errors, the mouse stayed on Bluetooth and the Solaar entry did not change.
- In a fourth, the mouse did not reconnect within 60 s and no query was launched; it later reconnected on its own.
- Side buttons diverted to diagnostics (full transaction, 9.2 s): `button.back` (1) and `button.forward` (2) with source `solaar` and `ok: true` within 5 s. This gives physical Bluetooth evidence for all eleven events.
- Close: user profile reapplied and verified over Bluetooth; `applied: true`, `pending: false`, `daemon: true`; zero service errors.

Pending:

- The cause of the incident remains unproven. It was not deliberately reproduced without the wait: 1 incident in 3 immediate queries without it, 0 in 13 with it (10 after service start, 3 after reconnection).
- The margin is narrow in the worst observed case: HID++ traffic up to 5.25 s on a reconnection, against a 6 s wait.
- Reconnection through a receiver: the node persists, so the wait only covers service startup there.
- Reconnection after a long suspend of the mouse or the computer.
- Profile continuity between Bolt and Bluetooth on other models. It depends on the serial reported over Bolt matching the Unit ID; it matches on the observed 3S.
