#!/bin/bash

SERVICE_NAME="monitoring_api"
PORT=5000
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$SCRIPT_DIR/venv"
API_SCRIPT="app.py"
LOG_FILE="$SCRIPT_DIR/monitoring.log"
PID_FILE="$SCRIPT_DIR/monitoring.pid"
SYSTEMD_DIR="/etc/systemd/system"
USER=$(whoami)

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

create_venv() {
    echo -e "${YELLOW}Creating a virtual environment...${NC}"
    
    if ! dpkg -l | grep -q python3-venv; then
        echo -e "${YELLOW}Installing python3-venv...${NC}"
        apt-get install -y python3-venv
    fi
    
    if [ ! -d "$VENV_DIR" ]; then
        python3 -m venv "$VENV_DIR"
        echo -e "${GREEN}The virtual environment was created in ${VENV_DIR}${NC}"
    fi
}

install_dependencies() {
    echo -e "${YELLOW}Installing dependencies...${NC}"
    "$VENV_DIR/bin/pip" install -q flask psutil
}

start_service() {
    echo -e "${YELLOW}Launching the monitoring service...${NC}"
    nohup "$VENV_DIR/bin/python" "$SCRIPT_DIR/$API_SCRIPT" > "$LOG_FILE" 2>&1 &
    echo $! > "$PID_FILE"
    sleep 2
    check_status
}

stop_service() {
    if [ -f "$PID_FILE" ]; then
        echo -e "${YELLOW}Stopping the service...${NC}"
        kill -9 $(cat "$PID_FILE") >/dev/null 2>&1
        rm -f "$PID_FILE"
        echo -e "${GREEN}The service has been stopped${NC}"
    fi
}

check_status() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p "$PID" > /dev/null; then
            echo -e "${GREEN}The service is working [PID: $PID]${NC}"
            echo -e "Адрес: ${YELLOW}http://localhost:$PORT/monitoring${NC}"
            return 0
        else
            echo -e "${RED}The service is not running (broken PID file)${NC}"
            return 1
        fi
    else
        echo -e "${RED}The service is not running${NC}"
        return 1
    fi
}

create_systemd_service() {
    echo -e "${YELLOW}Creating a systemd service...${NC}"
    
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}Error: Root permissions are required!${NC}"
        echo -e "Run with sudo: ${YELLOW}sudo $0 install-systemd${NC}"
        exit 1
    fi

    SERVICE_FILE="${SYSTEMD_DIR}/${SERVICE_NAME}.service"
    
    if [ -f "$SERVICE_FILE" ]; then
        echo -e "${RED}The service already exists!${NC}"
        read -p "Overwrite? (y/N): " answer
        [[ ! "$answer" =~ ^[Yy]$ ]] && exit 0
    fi

    cat > "$SERVICE_FILE" << EOF
[Unit]
Description=Monitoring API Service
After=network.target

[Service]
User=$USER
WorkingDirectory=$SCRIPT_DIR
ExecStart=$VENV_DIR/bin/python $SCRIPT_DIR/$API_SCRIPT
ExecStop=/bin/kill -INT \$MAINPID
Restart=always
RestartSec=5
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=$SERVICE_NAME

[Install]
WantedBy=multi-user.target
EOF

    echo -e "${GREEN}The service has been created: ${SERVICE_FILE}${NC}"
    
    systemctl daemon-reload
    systemctl enable "$SERVICE_NAME"
    systemctl start "$SERVICE_NAME"
    
    echo -e "\n${GREEN}The service has been successfully installed!${NC}"
    echo -e "Usage: systemctl [status|start|stop|restart] $SERVICE_NAME"
}

case "$1" in
    start)
        create_venv
        install_dependencies
        start_service
        ;;
    install-systemd)
        create_systemd_service
        ;;
    stop)
        stop_service
        ;;
    restart)
        stop_service
        start_service
        ;;
    status)
        check_status
        ;;
    *)
        echo -e "${YELLOW}Using: $0 [command]${NC}"
        echo -e "Commands:"
        echo -e "  ${GREEN}start${NC}          - Start service"
        echo -e "  ${GREEN}install-systemd${NC} - Install as systemd service"
        echo -e "  ${GREEN}stop${NC}           - Stop service"
        echo -e "  ${GREEN}restart${NC}        - Restart service"
        echo -e "  ${GREEN}status${NC}         - Show status"
        exit 1
esac

exit 0
