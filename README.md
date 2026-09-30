# flashlight

_TODO: one-line description._ High-power LED flashlight: STM32 controller, TPS61088 boost driver, USB-PD power input and LED board, with a machined body. Development boards for each subsystem plus an integrated v1.1 board.

## Status

| Area | Status |
|---|---|
| Mechanical | In progress (body + head CAD) |
| Electrical | In progress (dev boards routed; full-v1-1 schematic only) |
| Firmware | In progress (STM32) |
| Docs | Proposal + final report |

## What's here

| Folder | Contents |
|---|---|
| `docs/` | Datasheets, reports, photos — `reports` |
| `mechanical/` | CAD (native + exports), CAM — `cad` |
| `electrical/` | KiCad board projects, circuit sims — `flashlight-boost-dev`, `flashlight-boost-dev-2`, `flashlight-full-v1-1`, `flashlight-hardware`, `flashlight-led`, `flashlight-power-input-dev`, `flashlight-stm32-dev` |
| `firmware/` | MCU firmware projects — `flashlight-firmware-stm32` |
| `analysis/` | MATLAB / Python models and data — `sim` |
| `admin/` | Budget, receipts (git-ignored) — `BCN-IAD.pdf`, `FILE_3389.pdf` |

See [docs/STRUCTURE.md](docs/STRUCTURE.md) for the layout conventions.

## Build / run

_TODO: tools + versions, and the steps to rebuild or reproduce._

## Results

_TODO: what worked, measurements, photos._
