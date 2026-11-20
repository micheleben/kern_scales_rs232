#!/usr/bin/env python3
"""
Read KERN FKB_A (e.g. FKB 8K0.1A) and KERN PCD (e.g. PCD 2500-2) balances over RS232.

Scale setup (do this once on each balance, via the PRINT-key menu):
  - "Pr"   -> set to "rE Cr"  (remote control mode)
  - "bAUd" -> 9600 (factory default)
Serial: 9600 baud, 8 data bits, no parity, 1 stop bit, no handshake.

Remote commands (single ASCII char, sent WITHOUT CR/LF):
  w -> send current weight (stable or unstable)
  s -> send weight once it is stable
  t -> tare (no reply)

Install:  pip install pyserial
Examples:
  python src_python/core.py COM3 w                # Windows, one reading
  python src_python/core.py /dev/ttyUSB0 s        # Linux, one stable reading
  python src_python/core.py /dev/ttyUSB0 t        # tare
  python src_python/core.py COM3 log --interval 1 --csv weights.csv
  python src_python/core.py COM3 listen           # just print whatever the scale sends
                                                  # (use with PRINT key or AU PC continuous mode)
"""
import argparse
import csv
import re
import sys
import time
from datetime import datetime

import serial  # pyserial

LINE_RE = re.compile(r"([-+]?)\s*(\d+(?:\.\d+)?)\s*([A-Za-z%]+)?")


def open_port(port, baud):
    return serial.Serial(
        port=port,
        baudrate=baud,
        bytesize=serial.EIGHTBITS,
        parity=serial.PARITY_NONE,
        stopbits=serial.STOPBITS_ONE,
        timeout=2,          # seconds to wait for a reply line
        xonxoff=False, rtscts=False, dsrdtr=False,
    )


def parse(line):
    """'  -   123.4 g' -> (-123.4, 'g'); returns (None, None) on 'Error' or garbage."""
    if "Err" in line:
        return None, None
    m = LINE_RE.search(line)
    if not m:
        return None, None
    sign, num, unit = m.groups()
    # the minus sign may be separated from the digits by blanks
    value = float(num) * (-1 if "-" in line.split(num)[0] else 1)
    return value, unit or ""


def query(ser, cmd, timeout=2.0):
    """Send a single-letter command (no CR/LF) and return the reply line."""
    ser.reset_input_buffer()          # drop stale bytes so we don't read an old value
    ser.write(cmd.encode("ascii"))
    if cmd == "t":
        return ""
    ser.timeout = timeout
    raw = ser.readline()              # replies end with CR LF
    return raw.decode("ascii", errors="replace").strip()


def main():
    ap = argparse.ArgumentParser(description="KERN FKB/PCD RS232 reader")
    ap.add_argument("port", help="COM3 on Windows, /dev/ttyUSB0 on Linux")
    ap.add_argument("action", choices=["w", "s", "t", "log", "listen"])
    ap.add_argument("--baud", type=int, default=9600)
    ap.add_argument("--interval", type=float, default=1.0, help="seconds between readings (log)")
    ap.add_argument("--csv", help="append readings to this CSV file (log)")
    args = ap.parse_args()

    with open_port(args.port, args.baud) as ser:
        time.sleep(0.2)  # let the port settle

        if args.action in ("w", "s", "t"):
            # 's' only answers when stable, so allow longer
            reply = query(ser, args.action, timeout=10 if args.action == "s" else 2)
            if args.action == "t":
                print("Tare sent.")
                return
            if not reply:
                sys.exit("No reply. Check: Pr = rE Cr, baud rate, cable (try swapping pins 2/3).")
            value, unit = parse(reply)
            print(f"raw: {reply!r}  ->  {value} {unit}")

        elif args.action == "log":
            writer, f = None, None
            if args.csv:
                f = open(args.csv, "a", newline="")
                writer = csv.writer(f)
            try:
                while True:
                    reply = query(ser, "w")
                    value, unit = parse(reply)
                    ts = datetime.now().isoformat(timespec="seconds")
                    print(f"{ts}  {value} {unit}   raw={reply!r}")
                    if writer:
                        writer.writerow([ts, value, unit, reply]); f.flush()
                    time.sleep(args.interval)
            except KeyboardInterrupt:
                pass
            finally:
                if f:
                    f.close()

        elif args.action == "listen":
            print("Listening (Ctrl+C to stop)...")
            try:
                while True:
                    line = ser.readline().decode("ascii", errors="replace").strip()
                    if line:
                        print(f"{datetime.now():%H:%M:%S}  {line!r}  ->  {parse(line)}")
            except KeyboardInterrupt:
                pass


if __name__ == "__main__":
    main()