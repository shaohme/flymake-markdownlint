# flymake-markdownlint

A Flymake backend for validating Markdown files for Emacs (26+), using
[markdownlint](https://github.com/DavidAnson/markdownlint)

## Installation

`flymake-markdownlint` is not available on MELPA, so you have to add
it using your `load-path` manually.

## Usage

Add the following to your `.emacs` files for Emacs to load the backend
when visiting a Markdown file

```elisp
(require 'flymake-markdownlint)

(add-hook 'markdown-mode-hook 'flymake-markdownlint-setup)
```

Remember to enable `flymake-mode` as well, preferably after.

## License

Distributed under the GNU General Public License, version 3.
