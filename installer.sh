echo "deb http://http.kali.org/kali kali-rolling main non-free contrib" | sudo tee /etc/apt/sources.list.d/kali.list
wget -q -O - https://archive.kali.org/archive-key.asc | sudo apt-key add -

sudo apt update
sudo apt upgrade
sudo apt install golang-go
sudo apt-get install httpx-toolkit

go install github.com/lc/gau/v2/cmd/gau@latest

go install github.com/tomnomnom/gf@latest

cd ~/
git clone https://github.com/s0md3v/uro/
cd uro
python3 setup.py sdist
cd dist
pip3 install *
cd ~/
sudo mv ~/.local/bin/uro /usr/bin/

go install github.com/KathanP19/Gxss@latest

go install github.com/hahwul/dalfox/v2@latest

git clone https://github.com/gotr00t0day/spyhunt
pip3 install -r ~/tools/spyhunt/requirements.txt
sudo python3 spyhunt/install.py
