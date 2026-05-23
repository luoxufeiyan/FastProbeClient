# FastProbe Client

A lightweight, high-performance system monitoring client written in Go. It gathers host information, real-time resource utilization, and network traffic metrics, and periodically reports them to a **FastProbe Server**.

---

## Features

- **Lightweight & Efficient**: Single compiled binary written in Go (Go 1.21+), with extremely low memory and CPU overhead.
- **Comprehensive System Metrics**:
  - **Operating System**: OS distribution name and kernel version.
  - **Uptime**: System boot uptime in seconds.
  - **CPU**: Real-time overall CPU usage percentage.
  - **Memory & Swap**: Physical memory and swap space capacity and usage.
  - **Disk**: Capacity and utilization of the primary partition (`/` on Linux/macOS, `C:` on Windows).
  - **Network**: Current Rx/Tx bandwidth rates (bytes/sec) and cumulative Rx/Tx data since boot.
  - **IP & IP Stack**: Primary IP address and stack detection (`ipv4`, `ipv6`, or `dual` stack).
- **Dynamic Configuration**: Adjusts reporting frequency dynamically based on the server-defined interval (`report_interval`).
- **Production-Ready Service**: Includes an installer script to run as a supervised `systemd` service on Linux.

---

## API & Communication Protocol

The client communicates with the FastProbe Server's `/report` endpoint using standard JSON payloads over HTTP/HTTPS.

### Authentication

All requests sent by the client must include the node's secret token in the request headers:

- **Header Name**: `X-Node-Secret`
- **Header Value**: The secret token assigned to the client node in the FastProbe Admin Dashboard.

### Request Payload Format (POST `/report`)

```json
{
  "os": "Ubuntu 22.04 LTS",
  "kernel_version": "5.15.0-89-generic",
  "uptime": 86400,
  "cpu": 15.3,
  "mem_total": 4294967296,
  "mem_used": 1073741824,
  "swap_total": 2147483648,
  "swap_used": 536870912,
  "disk_total": 85899345920,
  "disk_used": 21474836480,
  "net_rx": 10240,
  "net_tx": 5120,
  "net_total_rx": 10737418240,
  "net_total_tx": 5368709120,
  "ip": "198.51.100.23",
  "ip_stack": "ipv4"
}
```

### Server Response Payload

Upon successful processing (`200 OK`), the server returns a JSON payload directing the client's next report timing:

```json
{
  "report_interval": 10
}
```

- **`report_interval`**: The interval (in seconds) the client will sleep before performing the next system metrics scan and reporting. Defaults to `30` seconds if not specified or when errors occur.

---

## Configuration

The client requires a simple configuration file in JSON format. By default, it looks for the file at:
`/etc/fastprobe-client/config.json`

### Configuration Structure

```json
{
  "url": "https://your-fastprobe-server.com/report",
  "token": "your_node_secret_token_here"
}
```

- **`url`**: The absolute URL of the FastProbe Server's report endpoint.
- **`token`**: The secret token configured for this node.

You can specify a custom path to the configuration file using the `-config` CLI flag:
```bash
./fastprobe-client -config /path/to/your/config.json
```

---

## Installation

### Method 1: Automatic Installation (Linux)

For Linux systems, you can install the client using the installation script. This script automatically detects the host architecture, downloads the latest binary, prompts for configuration details, and registers a systemd background service.

Run the installer with root privileges:

```bash
sudo ./install.sh
```

During installation, the script will:
1. Detect system architecture (e.g., `amd64`, `arm64`).
2. Download the compiled binary to `/usr/local/bin/fastprobe-client`.
3. Ask you for the **FastProbe Server URL** and **Node Token**.
4. Save the configuration to `/etc/fastprobe-client/config.json`.
5. Create, enable, and start a systemd service named `fastprobe-client`.

To check the service status:
```bash
systemctl status fastprobe-client
```

### Method 2: Build & Run from Source

#### Prerequisites
- Go 1.21 or later installed on the system.

#### Build Instructions
Clone the repository, navigate to the client directory, and compile:

```bash
go build -o fastprobe-client main.go
```

#### Run Instructions
1. Create a `config.json` file.
2. Launch the compiled binary:
   ```bash
   ./fastprobe-client -config config.json
   ```

---

## Cross-Compilation

To compile the FastProbe client for various operating systems and architectures from your development machine:

**Linux (AMD64)**
```bash
GOOS=linux GOARCH=amd64 go build -o fastprobe-client-linux-amd64 main.go
```

**Linux (ARM64)**
```bash
GOOS=linux GOARCH=arm64 go build -o fastprobe-client-linux-arm64 main.go
```

**Windows (AMD64)**
```bash
GOOS=windows GOARCH=amd64 go build -o fastprobe-client.exe main.go
```

**macOS (AMD64)**
```bash
GOOS=darwin GOARCH=amd64 go build -o fastprobe-client-darwin-amd64 main.go
```

---

## License

This project is licensed under the MIT License. See the parent repository for more information.
