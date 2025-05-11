from flask import Flask, jsonify
import psutil
import platform
from datetime import datetime

app = Flask(__name__)

def get_system_info():
    # CPU
    cpu_usage = psutil.cpu_percent(interval=1)
    cpu_count = psutil.cpu_count(logical=False)
    cpu_count_logical = psutil.cpu_count(logical=True)

    # Memory
    mem = psutil.virtual_memory()
    swap = psutil.swap_memory()

    # Disk
    disks = []
    for partition in psutil.disk_partitions():
        usage = psutil.disk_usage(partition.mountpoint)
        disks.append({
            "device": partition.device,
            "mountpoint": partition.mountpoint,
            "total": usage.total,
            "used": usage.used,
            "free": usage.free,
            "percent": usage.percent
        })

    # Network
    net = psutil.net_io_counters()
    net_ifaces = {}
    for interface, stats in psutil.net_if_stats().items():
        net_ifaces[interface] = {
            "isup": stats.isup,
            "speed": stats.speed
        }

    # System
    boot_time = datetime.fromtimestamp(psutil.boot_time()).isoformat()
    system_info = {
        "system": platform.system(),
        "release": platform.release(),
        "machine": platform.machine(),
        "boot_time": boot_time
    }

    return {
        "cpu": {
            "physical_cores": cpu_count,
            "logical_cores": cpu_count_logical,
            "usage_percent": cpu_usage
        },
        "memory": {
            "total": mem.total,
            "available": mem.available,
            "used": mem.used,
            "percent": mem.percent,
            "swap_total": swap.total,
            "swap_used": swap.used,
            "swap_free": swap.free
        },
        "disks": disks,
        "network": {
            "bytes_sent": net.bytes_sent,
            "bytes_recv": net.bytes_recv,
            "interfaces": net_ifaces
        },
        "system_info": system_info
    }

@app.route('/monitoring', methods=['GET'])
def monitoring():
    try:
        system_data = get_system_info()
        return jsonify(system_data)
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
