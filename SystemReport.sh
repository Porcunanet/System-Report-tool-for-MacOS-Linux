#!/bin/bash

# System Report Script for Linux and macOS
# Usage: ./system_report.sh [output_file]

OUTPUT_FILE="${1:-system_report_$(date +%Y%m%d_%H%M%S).txt}"

# Detect OS
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macOS"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "Linux"
    else
        echo "Unknown"
    fi
}

OS=$(detect_os)

# Print header
print_header() {
    echo "========================================"
    echo "$1"
    echo "========================================"
}

# Generate report
generate_report() {
    print_header "SYSTEM REPORT - $(date)"
    echo "Operating System: $OS"
    echo ""

    # System Information
    print_header "SYSTEM INFORMATION"
    if [[ "$OS" == "macOS" ]]; then
        system_profiler SPSoftwareDataType SPHardwareDataType 2>/dev/null | head -30
    else
        echo "Hostname: $(hostname)"
        echo "Kernel: $(uname -r)"
        echo "Architecture: $(uname -m)"
        [ -f /etc/os-release ] && cat /etc/os-release
    fi
    echo ""

    # Uptime
    print_header "UPTIME"
    uptime
    echo ""

    # CPU Information
    print_header "CPU INFORMATION"
    if [[ "$OS" == "macOS" ]]; then
        sysctl -n machdep.cpu.brand_string
        echo "CPU Cores: $(sysctl -n hw.ncpu)"
    else
        lscpu 2>/dev/null || cat /proc/cpuinfo | grep "model name" | head -1
        echo "CPU Cores: $(nproc 2>/dev/null || grep -c processor /proc/cpuinfo)"
    fi
    echo ""

    # Memory Information
    print_header "MEMORY INFORMATION"
    if [[ "$OS" == "macOS" ]]; then
        echo "Total Memory: $(($(sysctl -n hw.memsize) / 1024 / 1024 / 1024)) GB"
        vm_stat | head -10
    else
        free -h 2>/dev/null || cat /proc/meminfo | head -3
    fi
    echo ""

    # Disk Usage
    print_header "DISK USAGE"
    df -h | grep -E '^/dev/|Filesystem'
    echo ""

    # Network Information
    print_header "NETWORK INTERFACES"
    if [[ "$OS" == "macOS" ]]; then
        ifconfig | grep -E '^[a-z]|inet '
    else
        ip addr 2>/dev/null || ifconfig | grep -E '^[a-z]|inet '
    fi
    echo ""

    # Running Processes (Top 10 by CPU)
    print_header "TOP 10 PROCESSES BY CPU"
    ps aux | sort -rk 3,3 | head -11
    echo ""

    # Running Processes (Top 10 by Memory)
    print_header "TOP 10 PROCESSES BY MEMORY"
    ps aux | sort -rk 4,4 | head -11
    echo ""

    # Logged in Users
    print_header "LOGGED IN USERS"
    who
    echo ""

    # Last Logins
    print_header "RECENT LOGINS"
    last | head -10
    echo ""

    # System Load
    print_header "SYSTEM LOAD AVERAGE"
    if [[ "$OS" == "macOS" ]]; then
        sysctl vm.loadavg
    else
        cat /proc/loadavg
    fi
    echo ""

    # Port Listening
    print_header "LISTENING PORTS"
    if [[ "$OS" == "macOS" ]]; then
        netstat -an | grep LISTEN | head -20
    else
        ss -tuln 2>/dev/null | head -20 || netstat -tuln | head -20
    fi
    echo ""

    print_header "REPORT COMPLETE"
    echo "Report generated at: $(date)"
}

# Main execution
echo "Generating system report for $OS..."
generate_report | tee "$OUTPUT_FILE"
echo ""
echo "Report saved to: $OUTPUT_FILE"