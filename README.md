# kern_scales_rs232

Notes and Python code for talking to **KERN balances over RS232**.

Tested models / targets:

| Model            | Family | Notes                                  |
|------------------|--------|----------------------------------------|
| KERN FKB 8K0.1A  | FKB_A  | supports continuous output (`AU PC`)   |
| KERN PCD 2500-2  | PCD    |                                        |

Both use the same simple KERN single-character protocol. See
[dev_docs/protocol.md](dev_docs/protocol.md) for the details: wiring, menu settings, commands and pitfalls.

## Protocol in brief

- Serial: **9600 baud, 8N1, no handshake**, 9-pin D-Sub (pin 2 = TXD, 3 = RXD, 5 = GND)
- On the scale, set the menu item `Pr` to `rE Cr` (remote control)
- Commands are single ASCII characters, sent **without** CR/LF:

| Cmd | Meaning                               | Reply            |
|-----|---------------------------------------|------------------|
| `w` | current weight (stable or not)        | ASCII line, CRLF |
| `s` | weight once stable                    | ASCII line, CRLF |
| `t` | tare                                  | none             |

## Repository layout

```
.
├── dev_docs/
│   └── protocol.md      # RS232 notes for the supported scales
├── src_python/
│   └── core.py          # pyserial command-line reader
├── .env-example         # template for .env (VIRTUAL_ENV path)
├── requirements.txt     # Python dependencies (pyserial)
├── run.ps1              # Windows launcher: uses the venv from .env
└── run.sh               # Linux/macOS/Git Bash launcher: same
```

## Setup

The Python interpreter comes from a virtual environment. Its path is set by the
`VIRTUAL_ENV` variable in a local `.env` file, which git ignores. The venv can live anywhere,
for example a shared folder outside the repo.

1. Create your `.env` from the template:

   ```powershell
   copy .env-example .env      # Windows
   ```
   ```bash
   cp .env-example .env        # Linux / macOS
   ```

2. Edit `.env` and point `VIRTUAL_ENV` to the venv folder. An absolute path is best; a
   relative path is resolved from the repo root:

   ```
   VIRTUAL_ENV = C:/Users/you/venvs/kern_scales
   ```

3. Create the venv if it does not exist yet, and install the dependencies:

   ```powershell
   .\run.ps1 setup
   ```
   ```bash
   ./run.sh setup
   ```

   If PowerShell blocks the script, run
   `powershell -ExecutionPolicy Bypass -File .\run.ps1 setup` instead.

Every other argument to `run.ps1` / `run.sh` goes straight to the venv's `python`.
With no arguments, the scripts print which interpreter they are using.

**VS Code:** run *Python: Select Interpreter* and pick `<VIRTUAL_ENV>/Scripts/python.exe`
on Windows, or `<VIRTUAL_ENV>/bin/python` on Linux/macOS.

## Usage

```powershell
# Windows
.\run.ps1 src_python\core.py COM3 w                         # one reading
.\run.ps1 src_python\core.py COM3 s                         # one stable reading
.\run.ps1 src_python\core.py COM3 t                         # tare
.\run.ps1 src_python\core.py COM3 log --interval 1 --csv weights.csv
.\run.ps1 src_python\core.py COM3 listen                    # print whatever the scale sends
```

```bash
# Linux
./run.sh src_python/core.py /dev/ttyUSB0 w
```

Options: `--baud` (default 9600), `--interval` in seconds (for `log`), and `--csv FILE`, which appends
readings to a CSV file (for `log`).

On Linux, add your user to the `dialout` group to get access to `/dev/ttyUSB*`.

## Troubleshooting

- **No reply:** check that `Pr` is set to `rE Cr`, that the baud rate matches, and try swapping
  pins 2 and 3 (null-modem cable).
- **Stale values:** the code clears the input buffer before every query. Do the same in your
  own code.
- **Microcontrollers:** the scale uses true RS232 voltage levels. Put a MAX3232 level shifter
  between it and an Arduino or other TTL device.
- Unplug the scale from mains before you connect or disconnect the serial cable.
