# My dotfiles

This directory contains the dotfiles for my system

## Requirements

Ensure you have the following installed on your system

### Git (Linux)

```cmd
pacman -S git
```

### Stow (Linux)

```cmd
pacman -S stow
```

### Git (Mac)

```cmd
brew install git
```

### Stow (Mac)

```cmd
brew install stow
```

## Installation

First, check out the dotfiles repo in your $HOME directory using git

```cmd
git clone git@github.com:david-auk/dotfiles.git
cd dotfiles
```

Then use GNU stow to create symlinks

```cmd
stow .
```
