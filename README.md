# dotfiles
collection of my dotfile

### prerequisite
First install 
- curl vim git zsh
- go nodejs (optional)

```bash
# mac 
brew install git vim curl zsh

# ubuntu
sudo apt install git vim curl zsh

```

## Installation

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/joey00072/dotfiles/master/install.sh)"
```

### change defalut shell to zsh

```bash
chsh -s $(which zsh)
```

#### zsh theme 
defalut theme would be robbyrussell <br />
powerlevel10k/powerlevel10k is installed but not activated 
to change theme just edit ~/.zshrc <br/>
`ZSH_THEME="powerlevel10k/powerlevel10k"`

