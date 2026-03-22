;;; nt-projectile.el --- Projectile extensions  -*- lexical-binding: t; -*-

;;; Code:

(require 'projectile)

(defvar nt/projectile-saved-thing nil
  "Property list of saved thing for projects.
Keys are project roots (strings), so use `lax-plist-put' and
`lax-plist-get'.")

(defun nt/projectile-open-project-buffer ()
  "Open an empty buffer named after the project in the project root."
  (let* ((root (projectile-project-root))
         (name (projectile-project-name))
         (buf (get-buffer-create (format "*%s*" name))))
    (switch-to-buffer buf)
    (setq default-directory root)))

(defvar nt/projectile-switch-fallback #'nt/projectile-open-project-buffer)

;;;###autoload
(defun nt/projectile-switch-project (&optional arg)
  "Switch to a project, restoring saved context if available.
Automatically saves window configuration before switching.
With prefix argument ARG, prompt for what to save instead."
  (interactive "P")
  (when (projectile-project-p)
    (if arg
        (call-interactively #'nt/projectile-save-thing)
      (nt/projectile-save-thing ?w)))
  (let ((projectile-switch-project-action #'nt/projectile-maybe-restore-thing))
    (projectile-switch-project)))

(defun nt/projectile-save-thing (thing)
  "Save thing for current project.

Thing is a character representing
-  . point marker
- (b)uffer
- (f)ile
- (w)indow configuration
- (d)elete saved thing"
  (interactive (list
                (let ((letters '(?. ?b ?f ?w ?d)))
                  (read-char-choice (concat "Save [" letters "]: ")
                                    letters))))
  (let ((value (cl-case thing
                 (?. (point-marker))
                 (?b (current-buffer))
                 (?f (buffer-file-name))
                 (?w (current-window-configuration))
                 (?d nil))))
    (setq nt/projectile-saved-thing
          (lax-plist-put nt/projectile-saved-thing
                         (projectile-project-root)
                         (cons thing value)))))

(defun nt/projectile-restore-thing ()
  "Restore saved thing for current project.
Return nil if there is no thing saved."
  (interactive)
  (when-let ((thing-value (lax-plist-get nt/projectile-saved-thing
                                          (projectile-project-root)))
             (thing (car thing-value))
             (value (cdr thing-value)))
    (cl-case thing
      (?. (switch-to-buffer
           (or (marker-buffer value)
               (user-error "Buffer no longer exists")))
          (goto-char value))
      (?b (if (buffer-live-p value)
              (switch-to-buffer value)
            (user-error "Buffer no longer exists")))
      (?f (find-file value))
      (?w (set-window-configuration value)))
    t))

(defun nt/projectile-maybe-restore-thing ()
  "Try to restore thing for current project.
If nothing saved, call `nt/projectile-switch-fallback'."
  (or (nt/projectile-restore-thing)
      (funcall nt/projectile-switch-fallback)))

(provide 'nt-projectile)
;;; nt-projectile.el ends here
