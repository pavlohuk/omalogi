# OMALOGI_SOLAAR_BATTERY: battery of each connected MX Master, as one JSON line.
# Reads only: one ping and one battery request per mouse. A bar widget polls it, so it
# must stay far cheaper than `solaar show`, which reads every feature of every device.
import json

from logitech_receiver.common import BatteryLevelApproximation, BatteryStatus
from solaar import cli

CHARGING = {BatteryStatus.RECHARGING, BatteryStatus.ALMOST_FULL, BatteryStatus.SLOW_RECHARGE}


def paired(receiver):
    # As `solaar show`: stop after the paired count rather than probing every slot.
    count = receiver.count()
    for dev in receiver:
        if not count:
            break
        yield dev
        count -= 1


def mice():
    for item in cli._receivers_and_devices():
        yield from [item] if item.isDevice else paired(item)


def report(dev):
    if not (dev.name or "").startswith("MX Master") or not dev.ping():
        return None
    battery = dev.battery()
    if battery is None or battery.level is None:
        return None
    return {
        # The same identity `omalogi status` uses: serial through a receiver, unit ID direct.
        "id": dev.serial or str(dev.unitId),
        "name": dev.name,
        "transport": dev.receiver.name.removesuffix(" Receiver") if dev.receiver
        else "Bluetooth" if dev.bluetooth else "USB",
        "level": int(battery.level),
        # Some mice report only a coarse band (empty, critical, low, good, full).
        "approximate": isinstance(battery.level, BatteryLevelApproximation),
        "charging": battery.status in CHARGING,
        "full": battery.status == BatteryStatus.FULL,
    }


batteries = []
for dev in mice():
    try:
        entry = report(dev)
    except Exception:
        # An asleep or vanishing mouse must not hide the others.
        continue
    if entry:
        batteries.append(entry)
print(json.dumps(batteries))
