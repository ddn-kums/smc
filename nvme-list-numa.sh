#!/bin/bash

# Script to list all NVMe devices with their NUMA nodes and driver bindings
# Shows both vfio-pci bound devices and kernel nvme driver bound devices

echo "=== NVMe Device NUMA Mapping ==="
echo
echo "Format: PCI_Address | NUMA_Node | Driver | Vendor:Device | Model | NVMe_Name"
echo "--------------------------------------------------------------------------------"

# Find all NVMe controllers using direct sysfs enumeration
for pci_dev in /sys/bus/pci/devices/*; do
    if [ -f "$pci_dev/class" ]; then
        class=$(cat "$pci_dev/class" 2>/dev/null)
        if [ "$class" = "0x010802" ]; then
            bdf=$(basename "$pci_dev")

            # Get basic PCI info
            driver=$(grep DRIVER /sys/bus/pci/devices/$bdf/uevent 2>/dev/null | awk -F"=" '{print $2}')
            numa=$(cat /sys/bus/pci/devices/$bdf/numa_node 2>/dev/null || echo "unknown")
            vendor=$(cat /sys/bus/pci/devices/$bdf/vendor 2>/dev/null)
            device=$(cat /sys/bus/pci/devices/$bdf/device 2>/dev/null)

            # Get model information
            model="unknown"
            if [ "$driver" = "nvme" ] && [ -d "/sys/bus/pci/devices/$bdf/nvme" ]; then
                # For nvme driver, get model from nvme device
                nvme_dev=$(ls /sys/bus/pci/devices/$bdf/nvme 2>/dev/null | head -1)
                if [ -n "$nvme_dev" ]; then
                    model=$(cat /sys/bus/pci/devices/$bdf/nvme/$nvme_dev/model 2>/dev/null | xargs || echo "unknown")
                fi
            elif [ "$driver" = "vfio-pci" ]; then
                # For vfio-pci, try to get model from modalias or use vendor:device
                modalias=$(cat /sys/bus/pci/devices/$bdf/modalias 2>/dev/null || echo "")
                if [ -n "$modalias" ]; then
                    model="vfio-bound"
                else
                    model="vfio-bound"
                fi
            fi

            # Try to find corresponding nvme device name if bound to nvme driver
            nvme_name=""
            if [ "$driver" = "nvme" ] && [ -d "/sys/bus/pci/devices/$bdf/nvme" ]; then
                nvme_name=$(ls /sys/bus/pci/devices/$bdf/nvme 2>/dev/null | head -1)
                if [ -n "$nvme_name" ]; then
                    nvme_name="($nvme_name)"
                fi
            elif [ "$driver" = "vfio-pci" ]; then
                nvme_name="(vfio-bound)"
            elif [ -z "$driver" ]; then
                nvme_name="(no-driver)"
            fi

            # Format output
            printf "%-15s | %-9s | %-10s | %s:%s | %-20s | %s\n" \
                "$bdf" \
                "$numa" \
                "${driver:-none}" \
                "${vendor:-unknown}" \
                "${device:-unknown}" \
                "${model}" \
                "$nvme_name"
        fi
    fi
done

echo
echo "=== NUMA Summary ==="
echo

# Count devices per NUMA node
declare -A numa_counts
declare -A vfio_counts
declare -A nvme_counts

for pci_dev in /sys/bus/pci/devices/*; do
    if [ -f "$pci_dev/class" ]; then
        class=$(cat "$pci_dev/class" 2>/dev/null)
        if [ "$class" = "0x010802" ]; then
            bdf=$(basename "$pci_dev")
            driver=$(grep DRIVER /sys/bus/pci/devices/$bdf/uevent 2>/dev/null | awk -F"=" '{print $2}')
            numa=$(cat /sys/bus/pci/devices/$bdf/numa_node 2>/dev/null || echo "unknown")

            # Count total devices per NUMA
            numa_counts[$numa]=$((${numa_counts[$numa]} + 1))

            # Count by driver type
            if [ "$driver" = "vfio-pci" ]; then
                vfio_counts[$numa]=$((${vfio_counts[$numa]} + 1))
            elif [ "$driver" = "nvme" ]; then
                nvme_counts[$numa]=$((${nvme_counts[$numa]} + 1))
            fi
        fi
    fi
done

echo "NUMA Node | Total | vfio-pci | nvme driver"
echo "----------|-------|----------|------------"
for numa in $(echo "${!numa_counts[@]}" | tr ' ' '\n' | sort -n); do
    printf "%-9s | %-5s | %-8s | %-11s\n" \
        "$numa" \
        "${numa_counts[$numa]}" \
        "${vfio_counts[$numa]:-0}" \
        "${nvme_counts[$numa]:-0}"
done

echo
echo "=== NUMA Topology ==="
echo
lscpu | grep "NUMA node"
