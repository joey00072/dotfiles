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

curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

echo "\n *** DONE *** \n"
