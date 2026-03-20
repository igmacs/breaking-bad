# Breaking Bad

This is yet another modal editing package for Emacs. The motivation
behind it is that I want to start using modal editing, ideally with
Vim bindings, but switching all at once is too overwhelming. Instead,
I'm writing my own package to be able to transition step by step and
learn a bit about Emacs internals along the way. If the package is
useful for someone else, all the better.

## Modal editing advantages I want to replicate

I don't know yet the full power of modal editing, but these are the
features/advantages that I want to replicate

- Different key bindings depending of context or mode. In particular,
  free a lot of key bindings when you are not inserting text

- Consistent bindings for verbs, targets and modifiers. So you are
  able to perform NxM actions with N+M bindings

- Vim bindings, which seem to me that are more widespread outside
  Emacs than Emacs bindings

## Other features specific to this package

- I want to be able to assign different commands to the same binding
  in different major modes

## Adoption levels

I would like to have some variable that indicated the level of
adoption and enable or disable a number of features depending on it,
but that still requires some though. For now, adoption levels will
just correspond to progress and commits in this repository.

### Level 1

The goal of this level is to just get used to having separate normal
and insert modes.

This level introduces a minor mode for normal-mode, which can be
enabled globally, and which remaps `self-insert-command` to a command
that calls the function in the variable `bb-normal-binding-for-<key>`,
which by default is just doing nothing. This tries to play nicely with
already exisiting remaps like `org-self-insert-command`: if the
default is not overriden this package will allow that remap to do its
thing, and only interfere when it actually tries to self insert. In
this level, no command is actually assigned by default to any key,
except the one for entering insert mode.

This level also introduces the minor mode for insert-mode, which will
be enabled for the current buffer when pressing `i` in
normal-mode. This mode is just normal Emacs behaviour, except
- `C-g` exits it and enters normal-mode again
- Some commands or combinations of commands will result in immediately
  changing to normal mode again, to avoid the user to just be always
  in insert mode to have usual Emacs behavior

## Comparison with other packages

### Evil mode

This is the most famous package for Vim emulation, and the one I will
try to use as inspiration for this package, as this package name
suggests. The idea is that after completing this project, I should be
able to just start using evil-mode instead of this package.
