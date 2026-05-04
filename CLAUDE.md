# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

MISO2 is an embedded IoT framework written in Zig for microcontroller development, currently supporting the FRDM MCX E247 Ethernet Board (Cortex M4 with FPU/DSP, 2MB Flash, 256kB SRAM) with future support planned for Bosch XDK110. The project implements HTTP and MQTT 3.11 protocol support for embedded networking applications.

## Build System

This project uses a hybrid build approach with Zig as the primary build system and Python/uv for toolchain management.

### Building the Project

**Standard build:**
```bash
uv run python -mziglang build
```

**Run the executable:**
```bash
zig build run
```

**Run with arguments:**
```bash
zig build run -- arg1 arg2
```

### Testing

**Run all tests (runs both module and executable tests in parallel):**
```bash
zig build test
```

**Run with fuzz testing:**
```bash
zig build test --fuzz
```

The test suite includes:
- Module tests (from `src/root.zig`)
- Executable tests (from `src/main.zig`)
- Fuzz testing support for data structure validation

### Development Environment

**Python environment setup (required for Zig toolchain access):**
```bash
uv sync
```

Python 3.11+ is required. The project uses `uv` for Python package management and runs Zig through the Python ziglang module.

## Architecture

### Module Structure

The project follows Zig's standard module pattern:

- **`src/root.zig`**: Library module entry point (`miso2` module)
  - Exposes reusable functions for embedding in other projects
  - Contains core business logic

- **`src/main.zig`**: Executable entry point
  - CLI/application layer that imports and uses the `miso2` module
  - Handles command-line arguments and I/O operations

### External Dependencies

The project uses git submodules for external libraries located in `external/`:

- **CMSIS_6**: ARM Cortex Microcontroller Software Interface Standard
- **CMSIS-RTX**: RTOS implementation for ARM Cortex-M
- **lwIP**: Lightweight TCP/IP stack for embedded systems
- **picohttpparser**: Fast HTTP parser library
- **mcux-devices-mcx**: NXP MCX device support libraries

These are managed as submodules and must be initialized:
```bash
git submodule update --init --recursive
```

### Board Support

Board-specific configurations are in `board/frdmmcxe247/`. When adding support for new boards, create a similar directory structure.

### C Source Integration

The `csrc/` directory is designated for C source files that integrate with the Zig build system. This allows interfacing with the C-based external libraries.

## Zig Build System Details

The `build.zig` file defines:

- **Target configuration**: Supports cross-compilation for embedded targets
- **Optimization modes**: Debug, ReleaseSafe, ReleaseFast, ReleaseSmall
- **Module system**: Exports `miso2` module for use by consumers
- **Test infrastructure**: Parallel test execution for both module and executable tests

Build outputs go to `zig-out/` by default (can be overridden with `--prefix` or `-p`).

## Zig Version Requirements

- Minimum Zig version: **0.16.0**
- Currently using: **0.16.0**

The project relies on Zig 0.16.0+ features including the new `std.Build` API and module system.
