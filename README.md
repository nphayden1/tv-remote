#tv-remote
Provides a user interface for a computer to run freetube

To Install 
Run:

echo "deb [trusted=yes] https://raw.githubusercontent.com/nphayden1/tv-remote/main/ ./" | sudo tee /etc/apt/sources.list.d/tv-remote.list


sudo apt update && sudo apt install tv-remote


systemctl --user daemon-reload


systemctl --user restart tv-remote.service
