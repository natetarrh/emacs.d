;;; init.el --- Emacs configuration -*- lexical-binding: t; -*-

;;; Code:

(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)

(require 'use-package)
(setq use-package-always-defer t)

(add-to-list 'load-path (expand-file-name "lisp" user-emacs-directory))

(setq custom-file (expand-file-name ".custom.el" user-emacs-directory))

(desktop-save-mode 1)


;;; Performance

(setq read-process-output-max (* 1024 1024))
(setq gc-cons-threshold (* 20 1024 1024))

;; Typing latency tweaks
(setq jit-lock-defer-time 0.05)
(setq bidi-paragraph-direction 'left-to-right)
(setq auto-window-vscroll nil)
(setq inhibit-compacting-font-caches t)


;;; Appearance

(setq inhibit-splash-screen t
      initial-scratch-message nil)

(blink-cursor-mode -1)
(menu-bar-mode -1)
(scroll-bar-mode -1)
(tool-bar-mode -1)

(column-number-mode)
(line-number-mode)
(size-indication-mode)

(use-package modus-themes
  :demand t
  :config
  (modus-themes-load-theme 'modus-operandi-tinted))

(set-face-attribute 'default nil :family "Input Mono Narrow" :height 140)


;;; Environment

(use-package exec-path-from-shell
  :ensure t
  :demand t
  :config
  (exec-path-from-shell-initialize))


;;; Completion: Vertico (UI) + fzf (matching) + Consult (commands)

(use-package fzf-complete
  :demand t
  :config
  (setq completion-styles '(fzf basic)))

(use-package vertico
  :ensure t
  :demand t
  :config
  (vertico-mode))

(use-package consult
  :ensure t
  :bind (("C-x b" . consult-buffer)
         ("C-c b" . consult-buffer)
         ("C-c s" . consult-ripgrep)
         ("C-c l" . consult-line))
  :config
  (setq consult-preview-key nil))

(use-package nt-files
  :bind ("C-c f" . nt/find-file))


;;; Keys

(global-set-key (kbd "s-u") #'revert-buffer-quick)

(use-package which-key
  :ensure t
  :defer 5
  :diminish
  :config
  (which-key-mode))


;;; Git

(use-package magit-section
  :init
  (setq magit-section-visibility-indicators nil))

(use-package magit)

;; This is intentionally not loaded.
(setq custom-file (expand-file-name ".custom.el" user-emacs-directory))

;;; init.el ends here
