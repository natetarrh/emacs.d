;;; nt-files.el --- File-related commands -*- lexical-binding: t; -*-

;;; Code:

(declare-function project-root "project")

;;;###autoload
(defun nt/find-file ()
  "Find file in project using rg --files, filtered by fzf via completing-read."
  (interactive)
  (let* ((default-directory
          (or (when-let* ((proj (project-current))
                          (root (project-root proj)))
                root)
              default-directory))
         (files (split-string
                 (shell-command-to-string "rg --files --hidden --glob '!.git'")
                 "\n" t))
         (selected (completing-read "Find file: " files nil t)))
    (find-file selected)))

(provide 'nt-files)
;;; nt-files.el ends here
