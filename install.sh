echo "\n *** Running Installer  *** \n"

DIRECTORY="$HOME/.dotfiles"
OHMYZSH="$HOME/.oh-my-zsh"

if [ -d "$DIRECTORY" ]; then
    echo ".dotfiles already exits"
    echo "remove it for installtion"s
    exit
fi

if [ ! -d $OHMYZSH ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

mkdir $DIRECTORY
cd $DIRECTORY
git init
git remote add origin  https://github.com/joey00072/dotfiles
git pull origin master


# nvim installation
if [ -f "$HOME/.config/nvim" ]; then
    echo "nvim already exits"
    echo "moving ~/.config/nvim/ to ~/.config/nvim_old"
    mv $HOME/.config/nvim $HOME/.config/nvim_old
fi

ln -s $HOME/.dotfiles/nvim $HOME/.config/nvim

echo "NVIM Installed"



# zshrc installation
if [ -f "$HOME/.zshrc" ]; then
    echo "zshrc already exits"
    echo "moving ~/.zshrc to ~/.zshrc_old"
    mv $HOME/.zshrc $HOME/.zshrc_old
fi

ln -s $HOME/.dotfiles/.zshrc $HOME/.zshrc


# zsh autosuggestions
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

# power level10k installation
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
# zshrc installation
if [ -f "$HOME/.p10k.zsh" ]; then
    echo "p10k already exits"
    echo "moving ~/.p10k.zsh to ~/.p10k.zsh_old"
    mv $HOME/.zshrc $HOME/.zshrc_old
fi

# vim installation
if [ -f "$HOME/.vimrc" ]; then
    echo "vimrc already exits"
    echo "moving ~/.vimrc to ~/.vimrc_old"
    mv $HOME/.vimrc $HOME/.vimrc_old
fi

ln -s $HOME/.dotfiles/.vimrc $HOME/.vimrc

curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

vim +'PlugInstall --sync' +qa



echo "\n *** DONE *** \n"
