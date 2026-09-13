# MacMem: CPU & GPU Memory Monitor

A native macOS application written in **Swift** and **SwiftUI** that measures, analyzes, and visualizes **CPU (host RAM)** and **GPU (graphics memory)** in real-time.

MacMem provides deep visibility into Apple Silicon's Unified Memory Architecture (UMA).

![MacMem screenshot](/Images/MacMem_Screenshot.png)

---

## Key Features

- **Independent CPU & GPU Telemetry**: CPU metrics reflect strictly CPU-bound workloads, while GPU metrics reflect graphics/compute buffers (Metal buffers, LLMs, displays).
- **Dedicated Total System Memory Section**: Prominent dashboard widget displaying the combined system memory consumption.
- **Apple Silicon Unified Memory Visibility**: Explains and visualizes how CPU and GPU share the unified physical RAM pool without bus transfers.
- **Activity Monitor Breakdown**: Computes App Memory, Wired Memory, Compressed Memory, and Cached Files from Mach kernel primitives.
- **GPU Core & Memory Utilization**: Live tracking of GPU Allocated Memory, In-Use Active Memory, Metal Recommended Working Set Budget, and GPU Core Utilization (Device %, 3D Renderer %, 2D Tiler %).
- **Virtual Swap & Memory Pressure**: Inspects macOS VM pressure levels (Normal, Warning, Critical) and swap memory usage (Total, Used, Free).
- **Interactive Swift Charts**: Real-time historical timeline charting memory trajectories in gigabytes or percentage over time, showing Total System Used, CPU-Only, and GPU-Only curves.
- **Snapshot Export**: Export timestamped memory telemetry snapshots to formatted JSON or copy to the clipboard.
- **Native macOS Experience**: Polished SwiftUI interface with sidebar navigation, gauges, progress rings, dark/light mode support, and keyboard shortcuts.

---

## Project Structure

```
macmem/
├── Package.swift                  # Manifest declaring targets & macOS 14+ platform
├── Sources/
│   ├── MacMemKit/                 # Core telemetry engine (independent & reusable)
│   │   ├── Models/
│   │   │   ├── ByteFormatter.swift       # Byte formatting (B, KB, MB, GB, TB, %)
│   │   │   ├── SystemMemoryOverview.swift # Memory partition (CPU + GPU = Total)
│   │   │   ├── CPUMemoryInfo.swift       # CPU metrics, reconciliation, swap, pressure
│   │   │   ├── GPUMemoryInfo.swift       # GPU metrics, working set, utilization, clients
│   │   │   └── MemorySample.swift        # Time-series samples and JSON snapshot export
│   │   ├── Readers/
│   │   │   ├── CPUMemoryReader.swift     # Mach kernel (host_statistics64) & sysctl reader
│   │   │   ├── GPUMemoryReader.swift     # IOKit IOAccelerator & Metal device reader
│   │   │   └── MockMemoryReaders.swift   # Test doubles for unit testing & previews
│   │   └── Services/
│   │       └── MemoryMonitorService.swift # Polling engine, history ring buffer, snapshot exporter
│   └── macmem/                    # Native macOS SwiftUI Application
│       ├── MacMemApp.swift               # Application lifecycle, windowing, and menu commands
│       ├── ViewModels/
│       │   └── DashboardViewModel.swift  # Observable UI state adapter
│       └── Views/
│           ├── ContentView.swift         # Sidebar navigation and toolbar controls
│           ├── OverviewView.swift        # Combined CPU vs GPU memory distribution & balance
│           ├── CPUMemoryView.swift       # Dedicated CPU memory gauges, breakdown, and swap
│           ├── GPUMemoryView.swift       # Dedicated GPU memory gauges, utilization, and hardware
│           ├── HistoryChartView.swift    # Swift Charts time-series timeline (GB & %)
│           └── Components/
│               ├── MetricCardView.swift  # Visual card component with icons & badges
│               └── GaugeRingView.swift   # Circular progress gauge ring with gradients
├── Tests/
│   └── MacMemTests/
│       ├── ByteFormatterTests.swift      # Formatting and unit conversion tests
│       ├── SystemMemoryOverviewTests.swift # Partition mathematics & percentage additive tests
│       ├── CPUMemoryInfoTests.swift      # CPU calculations, reconciliation, and pressure
│       ├── GPUMemoryInfoTests.swift      # GPU calculations, working set ratios, and fallbacks
│       ├── CPUMemoryReaderTests.swift    # Mach host statistics verification & mock tests
│       ├── GPUMemoryReaderTests.swift    # Metal & IOKit accelerator verification & mock tests
│       └── MemoryMonitorServiceTests.swift # Polling, history buffer capping, and JSON export tests
├── Scripts/
│   └── build_app.sh              # Build script packaging a standalone macOS MacMem.app bundle
└── README.md                     # Documentation
```

---

## Requirements

- **Operating System**: macOS 14.0 (Sonoma) or macOS 15.0 (Sequoia) or newer.
- **Architecture**: Apple Silicon (M1, M2, M3, M4 series).
- **Toolchain**: Swift 6.0+ / Xcode 16.0+ Command Line Tools.

---

## How to Build

### 1. Debug Build
```bash
swift build
```

### 2. Release Build
```bash
swift build -c release
```

### 3. Build Standalone macOS App Bundle (`MacMem.app`)
```bash
./Scripts/build_app.sh
```
This compiles the release binary and packages it into `dist/MacMem.app`.

---

## How to Run

### Method A: Run via Swift Package Manager
```bash
swift run macmem
```

### Method B: Launch the App Bundle
```bash
open dist/MacMem.app
```
Or double-click `dist/MacMem.app` in Finder.

---

## How to Run the Tests

To execute the automated test suite:
```bash
swift test
```

---

## Application Navigation

### 1. Overview Screen
- **Total System Memory Card**: Large gauge ring showing Total System Memory Used %, accompanied by the additive partition badges: `CPU Only % + GPU Only % = Total System Used %` and `Free RAM %`.
- **Physical RAM Allocation Distribution Bar**: Stacked bar displaying CPU Memory (Blue), GPU Memory (Indigo), and Free Memory (Green) summing to 100% of RAM.
- **Side-by-Side Cards**: Simultaneous gauge rings for CPU-only share and GPU-only share.
- **Subsystem Comparison Matrix**: Side-by-side tabular comparison of memory used, % of physical RAM, active footprint, and pressure/utilization.

### 2. CPU Memory Screen
- **CPU Exclusive Utilization Gauge**: Large progress ring displaying CPU-only memory usage and memory pressure indicator.
- **Granular Category Cards**: App Memory, Wired Memory, Compressed Memory, Cached Files, Free Memory, and Total RAM.
- **Virtual Swap Space**: Swap memory progress bar showing Used, Free, and Total swap.
- **Kernel VM Paging**: Cumulative counters for Page-Ins and Page-Outs.

### 3. GPU Memory Screen
- **GPU Exclusive Utilization Gauge**: Large progress ring displaying GPU-only memory percentage of total system RAM.
- **Budget & Working Set Cards**: Allocated GPU Memory, In-Use Active Memory, Metal Working Set Limit, Available Headroom, Process GPU Footprint, and Active GPU Clients.
- **GPU Core Utilization**: Dedicated progress bars for **Overall Device Utilization %**, **3D Renderer Engine %**, and **2D Tiler Accelerator %**.

### 4. Trends & Charts Screen
- **Swift Charts Timeline**: Chart plotting historical telemetry for Total System Used (Purple line/area), CPU Only (Blue line), GPU Only (Indigo line), and GPU In-Use (Pink dashed line).
- **Display Modes**: Toggle between **Gigabytes (GB)** and **Percentage (%)**.
- **Analytics Grid**: Automatically computes Peak System Memory, Peak CPU, Peak GPU, and Average System Memory used.

### 5. Keyboard Shortcuts
- **Pause / Resume**: `Command + P`
- **Refresh Now**: `Command + R`
- **Clear History**: `Command + K`
- **Copy Snapshot JSON**: `Command + Shift + C`
- **Save Snapshot to File**: `Command + S`

---

Developed for macOS Apple Silicon.
