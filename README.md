# flask-api-monitoring
This repository offers a simple API for monitoring the server.

## Install
Copy files into folder and type `bash monitoring.sh install-systemd`.

The script will automatically create a virtual environment, install libraries, and run the systemd-service.

If you copy the code or move the file from DOS, you need to run:
```bash
# Install package to convert CRLF to LF
sudo apt-get install dos2unix -y

# Conversion
dos2unix monitoring.sh

# File execution rights
chmod +x monitoring.sh
```
This is necessary to reformat the file into a suitable Unix format.

## Usage
The API will be available by:
`http://{your_server_ip}:5000/monitoring`
