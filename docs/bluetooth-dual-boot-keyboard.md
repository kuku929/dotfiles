# Bluetooth keyboard on a Linux + Windows dual boot (one profile)


**1. Keyboard:** `Fn` → hold `F12` 3 s, wait for the fast flash.


Let KBD_MAC = DA:29:E2:A4:D8:82 ( the keyboard's MAC address )
Let PC_MAC = 14:75:5B:5A:82:F9 ( the computer's MAC address )

**2. Linux: pair**
```
bluetoothctl remove KBD_MAC
bluetoothctl --timeout 15 scan on
bluetoothctl pair KBD_MAC
bluetoothctl trust KBD_MAC
```

**3–4. Windows:** remove the mWave in Settings → Bluetooth, `Fn` → hold `F12`, pair, then Shift + Shut down.

**5. Linux: export Windows' key**
```
sudo pacman -S chntpw
sudo mkdir -p /mnt/win
sudo mount -t ntfs3 -o ro /dev/nvme0n1p3 /mnt/win
sudo reged -x /mnt/win/Windows/System32/config/SYSTEM 'HKEY_LOCAL_MACHINE\SYSTEM' 'ControlSet001\Services\BTHPORT\Parameters\Keys\PC_MAC' /root/bt.reg
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
sudo cp -a /var/lib/bluetooth/PC_MAC/KBD_MAC/info /var/lib/bluetooth/PC_MAC/KBD_MAC/info.bak
env SUDO_EDITOR=nvim sudoedit /var/lib/bluetooth/PC_MAC/KBD_MAC/info
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
bluetoothctl info KBD_MAC | grep -E 'Paired|Trusted|Connected'
grep mWave /proc/bus/input/devices
```

**Recovery**
```
bluetoothctl power off; bluetoothctl power on
bluetoothctl block KBD_MAC
bluetoothctl unblock KBD_MAC
sudo cp -a /var/lib/bluetooth/PC_MAC/KBD_MAC/info.bak /var/lib/bluetooth/PC_MAC/KBD_MAC/info
```
- Power cycle: when a connect or pair hangs with no error.
- `block` / `unblock`: stop or resume a reconnect loop.
- Last line: restore the backup if the edit is bad. Stop bluetooth first.
