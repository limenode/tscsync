# tscsync

Workaround for firmware that leaves the boot CPU's time-stamp counter (TSC)
unsynchronised with the other cores, which makes Linux reject the TSC and fall
back to the slow HPET clocksource.

Written for a Lenovo Legion Slim 5 14APH8 (82Y5, Ryzen 7 7840HS, BIOS MACN24WW).
Full write-up with diagnosis, evidence and reasoning lives in the Obsidian note
`My system GUIDE/TSC clocksource fix (Legion 14APH8).md`; this README is the
short version.

## What it does

`tscsync` measures each core's TSC against the majority (ping-pong, like the
kernel's `check_tsc_warp`) and, with `--apply`, writes `IA32_TSC` (MSR 0x10) on
any out-of-sync core so all agree to within ~100 cycles. `tscsync.service` runs
it as early as systemd allows; the kernel boots with `tsc=reliable` so it keeps
the TSC as clocksource. If the sync fails the unit switches the kernel to HPET.

## Files

| file | purpose |
|---|---|
| `tscsync.c` | the tool (`--measure`, `--apply [--quiet]`) |
| `tscsync.service` | early-boot oneshot unit, with HPET fallback |
| `msr.conf` | `/etc/modules-load.d/` entry so `/dev/cpu/N/msr` exists |
| `install.sh` | backup boot entries, build, install, enable, add `tsc=reliable` |
| `uninstall.sh` | full revert |
| `diag/clk.c` | cost of `clock_gettime` (HPET ≈ 1300 ns, TSC ≈ 20 ns) |
| `diag/monoc.c` | kernel monotonic clock as seen from each core |

## Use

```
sudo sh install.sh      # then reboot
cat /sys/devices/system/clocksource/clocksource0/current_clocksource   # tsc
tscsync --measure                                                       # all rows ~0
journalctl -u tscsync -b                                                # no "FAILED"
sudo sh uninstall.sh    # revert, then reboot
```

Do **not** use `tsc=reliable` without the sync unit: the kernel then trusts a
counter that is seconds off between cores and system time jumps (chrony steps,
"Time jumped backwards", games with negative frame deltas).
