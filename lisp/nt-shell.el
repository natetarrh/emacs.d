;;; nt-shell.el --- Terminal extensions -*- lexical-binding: t; -*-

;;; Code:

(require 'vterm)

;;;###autoload
(defun nt/zsh-vterm (&optional directory name)
  "Open a vterm buffer in DIRECTORY.

If a terminal for DIRECTORY already exists, switch to that
buffer.  If the current buffer is already a terminal for
DIRECTORY, create an additional terminal.

By default, DIRECTORY is `default-directory'.

With a \\[universal-argument] prefix argument, set DIRECTORY to
the home directory.

With a 0 prefix argument, select from existing terminal
directories.

With any other prefix argument, prompt for directory.

If NAME is non-nil, use *NAME* for the buffer name instead of
*zsh: DIRECTORY*."
  (interactive (nt/zsh-vterm--args))
  (let* ((dir (abbreviate-file-name (expand-file-name directory)))
         (name (or name (concat "zsh: " dir)))
         (full-name (concat "*" name "*"))
         (default-directory dir)
         (existing (get-buffer full-name)))
    (if (and existing
             (not (string= (nt/zsh-vterm-directory) dir)))
        (pop-to-buffer-same-window existing)
      (vterm (if existing
                 (generate-new-buffer-name full-name)
               full-name)))))

;;;###autoload
(defun nt/zsh-toggle-vterm-project (&optional other-window)
  "Toggle a vterm buffer for the current project root.
Falls back to `default-directory' if not in a project.
With OTHER-WINDOW prefix, display in other window."
  (interactive "P")
  (let* ((pr (project-current))
         (dir (if pr
                  (project-root pr)
                default-directory)))
    (if (string= (buffer-name)
                 (concat "*zsh: " (abbreviate-file-name
                                   (expand-file-name dir)) "*"))
        (bury-buffer)
      (let ((display-buffer-overriding-action
             (and other-window '(nil (inhibit-same-window . t)))))
        (nt/zsh-vterm dir)))))

;;;###autoload
(defun nt/zsh-vterm-other-window (&optional directory)
  "Open a vterm buffer in DIRECTORY in another window."
  (interactive (nt/zsh-vterm--args))
  (let ((display-buffer-overriding-action
         '(nil (inhibit-same-window . t))))
    (nt/zsh-vterm directory)))

(defun nt/zsh-vterm--args ()
  (list (cond
         ((not current-prefix-arg)
          default-directory)
         ((= (prefix-numeric-value current-prefix-arg) 4)
          "~/")
         ((= (prefix-numeric-value current-prefix-arg) 0)
          (let ((dirs (nt/zsh-vterm-current-directories)))
            (cl-case (length dirs)
              (0 (user-error "No ZSH vterm buffers found"))
              (1 (car dirs))
              (t (completing-read "Directory: " dirs
                                  nil nil nil nil (car dirs))))))
         (t
          (read-directory-name "Directory: ")))))

(defun nt/zsh-vterm-directory (&optional buffer)
  "Return directory name for ZSH vterm in BUFFER.
BUFFER defaults to current buffer."
  (with-current-buffer (or buffer (current-buffer))
    (let ((bname (buffer-name)))
      (and (derived-mode-p 'vterm-mode)
           (string-match "^\\*zsh: \\(.*\\)\\*\\(<[0-9]+>\\)*$" bname)
           (match-string 1 bname)))))

(defun nt/zsh-vterm-current-directories ()
  (delete-dups
   (delq nil (mapcar #'nt/zsh-vterm-directory (buffer-list)))))

(provide 'nt-shell)
;;; nt-shell.el ends here
