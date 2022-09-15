#!/usr/bin/env bash

if [[ $(/usr/bin/id -u) -ne 0 ]]; then
    echo "Not running as root"
    exit
fi


##Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
C_OFF='\033[0m'        # Reset Color


## Get script directory
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

## Get logged user
USER="$SUDO_USER"

########################## Programs ##################################

## Add repositories
echo -e "${YELLOW}Adding repositories...${C_OFF}"
add-apt-repository universe -y
add-apt-repository ppa:mozillateam/ppa -y
add-apt-repository ppa:danielrichter2007/grub-customizer -y

## Visual Studio Code ##
wget -q https://packages.microsoft.com/keys/microsoft.asc -O- | apt-key add -
add-apt-repository "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" -y

## Firefox ##
# Add priority to Firefox deb/apt version
touch /etc/apt/preferences.d/mozillateanppa
echo -e "Package: firefox*\nPin: release o=LP-PPA-mozillateam\nPin-Priority: 1001" | tee /etc/apt/preferences.d/mozillateanppa

## Update repositories
echo -e "${YELLOW}Updating repositories...${C_OFF}"
apt update > /dev/null 2>&1


## Programs to be removed
REMOVE_APT=(
    yelp*
    gnome-logs
    seahorse
    gnome-contacts
    geary
    gnome-weather
    ibus-mozc
    mozc-utils-gui
    gucharmap
    simple-scan
    popsicle
    popsicle-gtk
    totem*
    lm-sensors*
    xfburn
    xsane*
    hv3
    exfalso
    parole
    quodlibet
    xterm
    redshift*
    drawing
    hexchat*
    thunderbird*
    transmission*
    transmission-gtk*
    transmission-common*
    webapp-manager
    celluloid
    hypnotix
    rhythmbox*
    librhythmbox-core10*
    rhythmbox-data
    mintbackup
    mintreport
    aisleriot
    gnome-mahjongg
    gnome-mines
    quadrapassel
    gnome-sudoku
    pitivi
    gnome-sound-recorder
    remmina*
)

## Programs to be installed with apt
PROGRAMS_APT=(
	## System 
	ffmpeg
	net-tools
	ufw
    software-properties-common
    apt-transport-https
    sassc
	dbus-x11

	## CLI
	htop
	neofetch
    curl
    wget

	## Fonts
	fonts-firacode

	## Gnome
	chrome-gnome-shell
	dconf-editor
	gnome-shell-extensions
    gnome-shell-extension-manager
	gnome-tweaks

	## Apps
	code
	firefox
	vlc
	virtualbox
    grub-customizer
    gparted
)

## Remove bloatware
echo -e "${BLUE}Removing bloatware...${C_OFF}"
for program_name in ${REMOVE_APT[@]}; do
	if dpkg -l | grep -q $program_name; then # If program is installed
		echo -e "${YELLOW}	[REMOVING] - $program_name ${C_OFF}"

		apt remove "$program_name" -y -q
	fi
done
echo -e "${GREEN}Bloatware removed${C_OFF}"

## Install programs with apt
echo -e "${BLUE}Installing programs with apt...${C_OFF}"
for program_name in ${PROGRAMS_APT[@]}; do
	if ! dpkg -l | grep -q $program_name; then # If program is not installed
		echo -e "${YELLOW}	[INSTALLING] - $program_name ${C_OFF}"

		apt install "$program_name" -y -q
	fi
done

# Just in case
apt install -y --fix-broken --install-recommends

## Remove junk and update
echo -e "${YELLOW}Updating, upgrading and cleaning system...${C_OFF}"
apt update && apt dist-upgrade -y
apt autoclean
apt autoremove -y

## Checklist
echo -e "\nInstalled APT's:"
for program_name in ${PROGRAMS_APT[@]}; do
	if dpkg -l | grep -q $program_name; then 
		echo -e "	${GREEN}[INSTALLED] - $program_name ${C_OFF}"
	else
		echo -e "	${RED}[NOT INSTALLED] - $program_name ${C_OFF}"
	fi
done

echo
echo "############################################"
echo -e "${GREEN}System and Programs - Done${C_OFF}"
echo "############################################"



############################ Extensions ##################################

## Make sure the directory for storing the user's shell extension exists.
sudo -u $USER mkdir -p /home/$USER/.local/share/gnome-shell/extensions/

## Move the shell extension to the correct directory.
sudo -u $USER cp $SCRIPT_DIR/extensions/extensions.tar.xz /home/$USER/.local/share/gnome-shell/extensions/
cd /home/$USER/.local/share/gnome-shell/extensions/
sudo -u $USER tar -xvf extensions.tar.xz
rm -rf extensions.tar.xz
cd $SCRIPT_DIR




############################ Fonts #######################################

## Make sure the directory for storing the fonts exists.
sudo -u $USER mkdir -p /home/$USER/.local/share/fonts

## Copy fonts to the correct directory.
sudo -u $USER cp -R ./fonts/* /home/$USER/.local/share/fonts

############################ Theme #######################################

## Set dark mode
gsettings set org.gnome.shell.ubuntu color-scheme prefer-dark

## WhiteSur Theme
echo -e "${Yellow}Please initialize firefox to install Monterey theme${Color_Off}"
read -p "Press any key to continue" -n1 -s
echo
killall -9 firefox > /dev/null 2>&1

echo -e "Installing WhiteSur Theme..."
sudo -u $USER git clone -q https://github.com/vinceliuice/WhiteSur-gtk-theme.git
cd WhiteSur-gtk-theme
./install.sh -l -i ubuntu -m
./tweaks.sh -f monterey -g -b $SCRIPT_DIR/images/background.jpg -s
sleep 3
cd $SCRIPT_DIR

## WhiteSur Icons
echo -e "Installing WhiteSur Icons..."
sudo -u $USER git clone -q https://github.com/vinceliuice/WhiteSur-icon-theme.git 
cd WhiteSur-icon-theme
./install.sh 
cd $SCRIPT_DIR

## Load all settings
sudo -u $USER dconf load / < dconf-settings.ini

## Set background
sudo -u $USER cp ./images/background.jpg /home/$USER/ 
sudo -u $USER gsettings set org.gnome.desktop.background picture-uri-dark file:///home/$USER/background.jpg;

echo
echo "############################################"
echo -e "${GREEN}Theme - Done${C_OFF}"
echo "############################################"
echo -e "Changes will be applied after restarting the computer"



############################ ZSH #########################################

## Install zsh
echo -e "${YELLOW}Installing zsh...${C_OFF}"
apt install zsh -y

## Install oh-my-zsh
sudo -u $USER wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh
sh install.sh --unattended
cd $SCRIPT_DIR

## Install Powerlevel10k
echo -e "Installing Powerlevel10k..."
sudo -u $USER git clone --quiet --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$home/.oh-my-zsh/custom}/themes/powerlevel10k 
echo 'source /home/$USER/.oh-my-zsh/custom/themes/powerlevel10k/powerlevel10k.zsh-theme' >>/home/$USER/.zshrc

## Install zsh-autosuggestions
sudo -u $USER git clone https://github.com/zsh-users/zsh-autosuggestions /home/$USER/.oh-my-zsh/custom/plugins/zsh-autosuggestions

## Install zsh-syntax-highlighting
sudo -u $USER git clone https://github.com/zsh-users/zsh-syntax-highlighting.git /home/$USER/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting

## Move dotfiles to correct directory
echo -e "${YELLOW}Moving dotfiles to correct directory...${C_OFF}"
cp -R $SCRIPT_DIR/dotfiles/dotfiles.tar.xz /home/$USER/
# Unzip tar.xz file
cd /home/$USER/
tar -xvf dotfiles.tar.xz
rm dotfiles.tar.xz
cd $SCRIPT_DIR

## Change shell to zsh
echo -e "${YELLOW}Changing shell to zsh...${C_OFF}"
chsh -s /bin/zsh

## Check if the shell change was successful
if [ $? -ne 0 ]; then
    echo "chsh command unsuccessful. Change your default shell manually."
else
    echo "Shell successfully changed to zsh."
fi

echo -e "${GREEN}Done! Changes will be applied after reboot${C_OFF}"
