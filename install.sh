echo "\n *** Running Installer  *** \n"

DIRECTORY="$HOME/.dotfiles"

if [ -d "$DIRECTORY" ]; then
    echo ".dotfiles already exits"
    echo "remove it for installtion"s
    exit
fi

mkdir $DIRECTORY
cd $DIRECTORY
git init
git remote add origin  https://github.com/joey00072/dotfiles
git pull origin master



if [ -f "$HOME/.vimrc" ]; then
    echo "vimrc already exits"
    echo "moving ~/.vimrc to ~/.vimrc_old"
    mv $HOME/.vimrc $HOME/.vimrc_old
fi

ln -s $HOME/.dotfiles/.vimrc $HOME/.vimrc

curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

vim +'PlugInstall --sync' +qa


echo "\n *** DONE *** \n"
