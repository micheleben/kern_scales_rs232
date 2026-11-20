# KERN FKB 8K0.1A and PCD 2500-2: RS232 notes

Both scales use the same simple KERN protocol.

- Serial: 9600 baud (factory default; also 1200/2400/4800/19200), 8N1, no handshake, 9-pin D-Sub
- Scale pins: 2 = TXD (from scale), 3 = RXD (to scale), 5 = GND. If a straight cable gives nothing, swap 2 and 3 (null modem).
- Menu (hold PRINT until the unit shows, then MODE / SET): set "Pr" to "rE Cr" for remote control. Other modes are Pr PC (send on PRINT key), AU Pr (send automatically when stable) and AU PC (continuous; FKB only).
- Commands are single ASCII characters sent WITHOUT CR/LF:
  - w: weight now (stable or unstable)
  - s: weight once it is stable
  - t: tare (no reply)
- Reply: a fixed-width ASCII line (sign, weight, unit) ending in CR LF. On a fault the line says "Error".
- Pitfalls:
  - The scale is true RS232 (±V levels). An Arduino needs a MAX3232 level shifter; never wire it straight to the Arduino's TTL pins.
  - Clear the input buffer before each query so you don't read a stale value.
  - Unplug the scale from mains before you connect or disconnect the cable.
- Script: src_python/core.py (pyserial). Actions: w / s / t / log / listen.