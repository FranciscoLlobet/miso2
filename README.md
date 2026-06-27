# MISO2

Miso2 Zig

Current Support: 

- FRDM MCX E247 Ethernet Board
- Bosch XDK110 (future)

Protocols: 

- NTP
- HTTP
- MQTT 3.11

## Build 

### 0.a

Get and install [uv](https://docs.astral.sh/uv/)

### 0.b Build Picolibc

```bash
./scripts/build-picolibc.sh
 ```

### 1.0 Build embedded firmware

Build using zig

```bash
zig build
```

Build using `uv`

```bash
uv run python-zig build
 ```
