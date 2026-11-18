# Bluetooth keyboard on a Linux + Windows dual boot (one profile)

Tested with a Kinesis mWave, BlueZ 5.87, Arch Linux.

## Why it breaks

- Both OSes use the same adapter, so the keyboard sees one host address.
- A bond is a key shared by (keyboard address, host address). Each pairing makes a new random key.
- Only the OS that paired last holds the key the keyboard expects. The other OS loops:
  connect → reads fail (`Request attribute has encountered an unlikely error`) → disconnect → repeat.
- Keyboard profiles don't help: same host address, so a reset of either profile can wipe the shared key.

Fix: pair both OSes, then copy Windows' key into Linux so all three sides hold the same key.

## Addresses

| What | Linux form | Windows registry form |
|---|---|---|
| Adapter (`<A>`) | `14:75:5B:5A:82:F9` | `14755b5a82f9` |
| Keyboard (`<K>`) | `DA:29:E2:A4:D8:82` | `da29e2a4d882` |

Find them with `bluetoothctl show` and `bluetoothctl devices`.

## Steps

1. **Keyboard:** pick one profile. `Fn` → hold `F12` 3 s until the LED flashes fast.
2. **Linux:** pair. This creates the bond file you will edit.
   ```
   bluetoothctl remove <K>
   bluetoothctl scan on            # Ctrl-C once the keyboard shows up
   bluetoothctl pair <K>
   bluetoothctl trust <K>
   ```
3. **Windows:** remove the old keyboard entry. Clear the same profile again (`Fn` → hold `F12`) and pair.
   Windows must be the **last** pairing.
4. **Windows:** shut down fully (Shift + Shut down). With hibernate or Fast Startup on, the NTFS mount is refused or stale.
5. **Linux:** export Windows' key (read-only mount; the registry is never written).
   ```
   sudo pacman -S chntpw
   sudo mkdir -p /mnt/win
   sudo mount -t ntfs3 -o ro /dev/<windows-partition> /mnt/win
   sudo reged -x /mnt/win/Windows/System32/config/SYSTEM \
       'HKEY_LOCAL_MACHINE\SYSTEM' \
       'ControlSet001\Services\BTHPORT\Parameters\Keys\<A, registry form>' /root/bt.reg
   sudo less /root/bt.reg          # section ending in \<K, registry form>
   ```
6. **Convert** the values:

   | Windows | Linux `[LongTermKey]` | Rule |
   |---|---|---|
   | `LTK` = `hex:aa,bb,…` | `Key=` | drop commas, uppercase, same byte order |
   | `KeyLength` = `dword:00000010` | `EncSize=` | hex → decimal (`16`) |
   | `EDIV` = `dword:0000xxxx` | `EDiv=` | hex → decimal |
   | `ERand` = `hex(b):b0,…,b7` | `Rand=` | **reverse bytes**, hex → decimal |

   Secure Connections pairing usually gives `EDIV = 0` and `ERand = 0`.
   ```
   echo aa,bb,... | tr -d , | tr a-f A-F                    # Key
   printf '%d\n' 0x0000xxxx                                 # EDiv
   python3 -c 'import sys; print(int.from_bytes(bytes.fromhex(sys.argv[1].replace(",", "")), "little"))' b0,b1,b2,b3,b4,b5,b6,b7   # Rand
   ```
7. **Linux:** edit the bond with the daemon stopped (otherwise bluetoothd overwrites it).
   ```
   sudo systemctl stop bluetooth
   cd /var/lib/bluetooth/<A>/<K>
   sudo cp -a info info.bak
   SUDO_EDITOR=nvim sudoedit info
   ```
   - Replace `Key`, `EncSize`, `EDiv`, `Rand` under `[LongTermKey]`.
   - If `[PeripheralLongTermKey]` or `[SlaveLongTermKey]` exists, set the same `Key` there too.
   - Leave `[IdentityResolvingKey]` alone for a keyboard with a static address (as the mWave has).
8. **Clean up and start:**
   ```
   sudo umount /mnt/win
   sudo shred -u /root/bt.reg
   sudo systemctl start bluetooth
   ```
9. **Verify:** `bluetoothctl info <K>` shows `Connected: yes`, and `grep mWave /proc/bus/input/devices` lists the keyboard.

## Commands only

Values for this machine filled in. Works in fish and bash.

**1. Keyboard:** `Fn` → hold `F12` 3 s, wait for the fast flash.

**2. Linux: pair**
```
bluetoothctl remove DA:29:E2:A4:D8:82
bluetoothctl --timeout 15 scan on
bluetoothctl pair DA:29:E2:A4:D8:82
bluetoothctl trust DA:29:E2:A4:D8:82
```

**3–4. Windows:** remove the mWave in Settings → Bluetooth, `Fn` → hold `F12`, pair, then Shift + Shut down.

**5. Linux: export Windows' key**
```
sudo pacman -S chntpw
sudo mkdir -p /mnt/win
sudo mount -t ntfs3 -o ro /dev/nvme0n1p3 /mnt/win
sudo reged -x /mnt/win/Windows/System32/config/SYSTEM 'HKEY_LOCAL_MACHINE\SYSTEM' 'ControlSet001\Services\BTHPORT\Parameters\Keys\14755b5a82f9' /root/bt.reg
sudo less /root/bt.reg
```
In `less`, find the section ending `\da29e2a4d882` and note `LTK`, `KeyLength`, `EDIV`, `ERand`.

**6. Convert** (replace the placeholders with your values)
```
echo aa,bb,cc,... | tr -d , | tr a-f A-F
printf '%d\n' 0x00000010
printf '%d\n' 0x0000xxxx
python3 -c 'import sys; print(int.from_bytes(bytes.fromhex(sys.argv[1].replace(",", "")), "little"))' b0,b1,b2,b3,b4,b5,b6,b7
```
In order: `Key` (from `LTK`), `EncSize` (from `KeyLength`), `EDiv` (from `EDIV`), `Rand` (from `ERand`; the python line does the byte reversal).

**7. Linux: write the key**
```
sudo systemctl stop bluetooth
sudo cp -a /var/lib/bluetooth/14:75:5B:5A:82:F9/DA:29:E2:A4:D8:82/info /var/lib/bluetooth/14:75:5B:5A:82:F9/DA:29:E2:A4:D8:82/info.bak
env SUDO_EDITOR=nvim sudoedit /var/lib/bluetooth/14:75:5B:5A:82:F9/DA:29:E2:A4:D8:82/info
```
Under `[LongTermKey]`, set `Key=`, `EncSize=`, `EDiv=`, `Rand=`. If `[PeripheralLongTermKey]` or `[SlaveLongTermKey]` exists, set the same `Key=` there. Save with `:wq`.

**8. Clean up and start**
```
sudo umount /mnt/win
sudo shred -u /root/bt.reg
sudo rfkill unblock bluetooth
sudo systemctl start bluetooth
```

**9. Verify**
```
bluetoothctl info DA:29:E2:A4:D8:82 | grep -E 'Paired|Trusted|Connected'
grep mWave /proc/bus/input/devices
```

**Recovery**
```
bluetoothctl power off; bluetoothctl power on
bluetoothctl block DA:29:E2:A4:D8:82
bluetoothctl unblock DA:29:E2:A4:D8:82
sudo cp -a /var/lib/bluetooth/14:75:5B:5A:82:F9/DA:29:E2:A4:D8:82/info.bak /var/lib/bluetooth/14:75:5B:5A:82:F9/DA:29:E2:A4:D8:82/info
```
- Power cycle: when a connect or pair hangs with no error.
- `block` / `unblock`: stop or resume a reconnect loop.
- Last line: restore the backup if the edit is bad. Stop bluetooth first.

## Rules afterwards

- Same profile (switch position) in both OSes.
- Don't re-pair in either OS and don't reset **any** profile. If you do, repeat steps 3–8.
- A firmware update may wipe bonds too. Repeat steps 1–8 after one.
- Use the other profile only for a different machine.
- The LTK is a secret. Don't paste it anywhere.

## Troubleshooting

| Symptom | Fix |
|---|---|
| connect/pair hangs, no error | `bluetoothctl power off; bluetoothctl power on`, retry |
| reconnect loop | stop it: `bluetoothctl block <K>`; undo: `bluetoothctl unblock <K>` |
| `AuthenticationFailed` on pair | keyboard not in pairing mode: `Fn` → hold `F12` 3 s |
| no `<K>` subkey in the registry | Windows paired under another address; list the subkeys of `<A>` |
| `sudo nano: command not found` | use `SUDO_EDITOR=nvim sudoedit <file>` |
| still loops after the copy | restore `info.bak`; check the `Rand` byte order and the switch position |
