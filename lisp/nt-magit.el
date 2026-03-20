;;; nt-magit.el --- Magit extensions -*- lexical-binding: t; -*-

;;; Code:

;;;###autoload
(defun nt/magit-status ()
  "Open magit-status in the current window from vterm, other window otherwise."
  (interactive)
  (let* ((action (if (derived-mode-p 'vterm-mode)
                     '(display-buffer-same-window)
                   '((display-buffer-use-some-window)
                     (inhibit-same-window . t))))
         (magit-display-buffer-function
          (lambda (buffer)
            (display-buffer buffer action))))
    (magit-status)))

(provide 'nt-magit)
;;; nt-magit.el ends here
