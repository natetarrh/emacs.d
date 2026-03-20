;;; nt-revert.el --- Revert buffer helpers -*- lexical-binding: t; -*-

;;; Code:

;;;###autoload
(defun nt/revert-buffer ()
  "Revert buffer, skipping confirmation when content matches the file on disk."
  (interactive)
  (let ((noconfirm (or (not (buffer-modified-p))
                       (not (verify-visited-file-modtime (current-buffer))))))
    (revert-buffer t noconfirm)))

(provide 'nt-revert)
;;; nt-revert.el ends here
