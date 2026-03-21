;;; init.el --- Emacs configuration -*- lexical-binding: t; -*-

;;; Code:

(add-to-list 'load-path (expand-file-name "lisp" user-emacs-directory))
(setq custom-file (expand-file-name ".custom.el" user-emacs-directory))

(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)

(require 'use-package)
(require 'use-package-chords)
(setq use-package-always-defer t)
(setq use-package-always-ensure t)
(key-chord-mode 1)

(use-package diminish
  :demand t)


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
  :demand t
  :config
  (add-to-list 'page-break-lines-modes 'emacs-news-view-mode)
  (global-page-break-lines-mode))

(column-number-mode)
(setq-default display-line-numbers-width 3)
(setq display-line-numbers-global-modes '(not vterm-mode Info-mode dired-mode))
(global-display-line-numbers-mode)
(dolist (hook '(Info-mode-hook dired-mode-hook))
  (add-hook hook (lambda () (display-line-numbers-mode -1))))
(setf (alist-get 'continuation fringe-indicator-alist) '(nil nil))
(line-number-mode)
(size-indication-mode)

(use-package modus-themes
  :demand t
  :config
  (modus-themes-load-theme 'modus-operandi-tinted))

(set-face-attribute 'default nil :family "Input Mono Narrow" :height 140)


;;; Env

(use-package exec-path-from-shell
  :demand t
  :config
  (dolist (var '("EDITOR" "VISUAL"))
    (add-to-list 'exec-path-from-shell-variables var))
  (exec-path-from-shell-initialize))


;;; Completion: Vertico (UI) + fzf (matching) + Consult (commands)

(use-package recentf
  :demand t
  :config
  (recentf-mode))

(use-package nt-fzf-complete
  :ensure nil
  :demand t
  :config
  (setq completion-styles '(fzf basic)))

(use-package vertico
  :demand t
  :config
  (setq vertico-buffer-display-action
	'(display-buffer-in-side-window (side . bottom) (window-height . 0.4)))
  (vertico-buffer-mode)
  (vertico-mode))

(use-package consult
  :bind (("C-x b" . consult-buffer)
         ("C-x 4 b" . consult-buffer-other-window)
         ("C-c b" . consult-buffer)
         ("C-c l" . consult-line))
  :config
  (setq consult-preview-key nil))

(use-package nt-files
  :ensure nil
  :bind ("C-c f" . nt/find-file))


;;; Evil

(use-package evil
  :demand t
  :init
  (setq evil-want-keybinding nil)
  (setq evil-want-C-u-scroll t)
  (setq evil-want-C-i-jump t)
  :config
  (evil-mode 1))

(use-package evil-escape
  :after evil
  :demand t
  :diminish
  :config
  (setq evil-escape-key-sequence "jk")
  (evil-escape-mode 1))

(use-package evil-surround
  :after evil
  :demand t
  :config
  (global-evil-surround-mode 1))

(use-package evil-collection
  :after evil
  :demand t
  :diminish evil-collection-unimpaired-mode
  :config
  (defun nt/disable-evil-escape-in-magit ()
    (setq-local evil-escape-inhibit t))
  (add-hook 'magit-mode-hook #'nt/disable-evil-escape-in-magit)
  (evil-collection-init))

(defun nt/vterm-evil-insert (&rest _)
  (when (derived-mode-p 'vterm-mode)
    (evil-insert-state)))
(dolist (cmd '(evil-window-left evil-window-right evil-window-up evil-window-down
               evil-window-next evil-window-prev other-window
               switch-to-buffer consult-buffer consult-buffer-other-window))
  (advice-add cmd :after #'nt/vterm-evil-insert))


;;; Tree-sitter

(use-package treesit-auto
  :demand t
  :config
  (treesit-auto-add-to-auto-mode-alist 'all)
  (global-treesit-auto-mode))


;;; Projects

(use-package projectile
  :diminish
  :bind-keymap ("C-c p" . projectile-command-map)
  :config
  (setq projectile-project-search-path '("~/Developer/"))
  (projectile-mode))

(use-package nt-projectile
  :ensure nil
  :chords ("gp" . nt/projectile-switch-project))


;;; Dired

(setq ls-lisp-use-insert-directory-program nil)
(setq ls-lisp-dirs-first t)
(setq ls-lisp-verbosity nil)
(setq dired-listing-switches "-alB")
(add-hook 'dired-mode-hook #'dired-omit-mode)

(use-package dired-gitignore
  :after dired
  :config
  (dired-gitignore-global-mode))


;;; Keys

(evil-define-key 'normal 'global
  "-" #'dired-jump
  (kbd "C-p") #'consult-buffer
  (kbd "C-f") #'nt/find-file)

(autoload 'nt/revert-buffer "nt-revert")
(global-set-key (kbd "s-u") #'nt/revert-buffer)

(use-package which-key
  :defer 5
  :diminish
  :config
  (which-key-mode))


;;; Git
(use-package git-gutter
  :diminish
  :init
  (global-git-gutter-mode t)
  (setq git-gutter:added-sign "+"
	git-gutter:modified-sign "~"
	git-gutter:deleted-sign "-"
	git-gutter:hide-gutter t)
  (evil-define-key 'normal 'global
    "]c" #'git-gutter:next-hunk
    "[c" #'git-gutter:previous-hunk))

(use-package magit-section
  :init
  (setq magit-section-visibility-indicators
	'(("…" . t) ("…" . t))))

(use-package magit)

(autoload 'nt/magit-status "nt-magit")
(global-set-key (kbd "C-x g") #'nt/magit-status)
(global-set-key (kbd "C-c g") #'nt/magit-status)


;;; Claude

(use-package vterm
  :hook (vterm-mode . (lambda ()
                        (display-line-numbers-mode -1)
                        (setq-local truncate-lines t)
                        (setq-local fringe-indicator-alist
                                    '((truncation nil nil)))
                        (set-window-fringes nil 0 0)
                        (page-break-lines-mode -1)))
  :bind (:map vterm-mode-map
              ("M-:" . eval-expression)))

(use-package claude-code
  :vc (:url "https://github.com/stevemolitor/claude-code.el" :rev :newest)
  :bind-keymap ("C-c c" . claude-code-command-map)
  :diminish
  :config
  (setq claude-code-terminal-backend 'vterm)
  (claude-code-mode))

;;; init.el ends here
