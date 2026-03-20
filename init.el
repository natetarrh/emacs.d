;;; init.el --- Emacs configuration -*- lexical-binding: t; -*-

;;; Code:

(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)

(require 'use-package)
(setq use-package-always-defer t)

(use-package diminish
  :ensure t
  :demand t)

(add-to-list 'load-path (expand-file-name "lisp" user-emacs-directory))

(setq custom-file (expand-file-name ".custom.el" user-emacs-directory))

(desktop-save-mode 1)


;;; Performance

(setq read-process-output-max (* 1024 1024))
(setq jit-lock-defer-time 0.05)

(defun nt/gc-disable ()
  (setq gc-cons-threshold most-positive-fixnum))

(defun nt/gc-enable ()
  (setq gc-cons-threshold 800000))

(add-hook 'minibuffer-setup-hook #'nt/gc-disable)
(add-hook 'minibuffer-exit-hook #'nt/gc-enable)


;;; Appearance

(setq inhibit-splash-screen t
      initial-scratch-message nil)

(blink-cursor-mode -1)
(menu-bar-mode -1)
(scroll-bar-mode -1)
(tool-bar-mode -1)

(use-package page-break-lines
  :ensure t
  :demand t
  :config
  (global-page-break-lines-mode))

(column-number-mode)
(setq-default display-line-numbers-width 3)
(global-display-line-numbers-mode)
(setf (alist-get 'continuation fringe-indicator-alist) '(nil nil))
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

(use-package recentf
  :demand t
  :config
  (recentf-mode))

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
         ("C-x 4 b" . consult-buffer-other-window)
         ("C-c b" . consult-buffer)
         ("C-c l" . consult-line))
  :config
  (setq consult-preview-key nil))

(use-package nt-files
  :bind ("C-c f" . nt/find-file))


;;; Keys

(global-set-key (kbd "s-u") #'revert-buffer-quick)
(windmove-default-keybindings)

(use-package which-key
  :ensure t
  :defer 5
  :diminish
  :config
  (which-key-mode))


;;; Git

(use-package magit-section
  :ensure t
  :init
  (setq magit-section-visibility-indicators
        '((?• . ?◦) ("…" . t))))

(use-package magit
  :ensure t)


;;; Claude

(use-package vterm
  :ensure t
  :hook (vterm-mode . (lambda ()
                        (display-line-numbers-mode -1)
                        (set-window-fringes nil 0 0)
                        (page-break-lines-mode -1))))

(use-package claude-code
  :ensure t
  :vc (:url "https://github.com/stevemolitor/claude-code.el" :rev :newest)
  :bind-keymap ("C-c c" . claude-code-command-map)
  :diminish claude-code-mode
  :config
  (setq claude-code-terminal-backend 'vterm)
  (setq claude-code-display-window-fn
        (lambda (buffer)
          (pop-to-buffer buffer '((display-buffer-in-direction)
                                  (direction . right)
                                  (window-width . 0.5)))))
  (claude-code-mode))

;;; init.el ends here
