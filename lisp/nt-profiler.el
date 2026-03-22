;;; nt-profiler.el --- Profiler utilities -*- lexical-binding: t; -*-

(defun nt/profiler--format-entry (fn)
  "Format a single backtrace entry FN as a safe frame name.
Replaces spaces and semicolons so flamegraph.pl can parse the line."
  (let ((name (cond
               ((symbolp fn) (symbol-name fn))
               ((compiled-function-p fn) "[compiled]")
               ((and (listp fn) (eq (car fn) 'lambda)) "[lambda]")
               ((and (listp fn) (eq (car fn) 'closure)) "[closure]")
               (t (replace-regexp-in-string "[ \t\n]+" "_" (format "%s" fn))))))
    (replace-regexp-in-string "[; ]" "_" name)))

(defun nt/profiler-export-folded-stacks (filename)
  "Export the current CPU profile as folded stacks to FILENAME.
The output is compatible with Brendan Gregg's flamegraph.pl and inferno."
  (interactive "FExport folded stacks to: ")
  (let ((profile (profiler-cpu-profile)))
    (unless profile
      (error "No CPU profile data available.  Run profiler-start first"))
    (let ((log (profiler-profile-log profile)))
      (with-temp-file filename
        (maphash
         (lambda (backtrace count)
           (when (> count 0)
             (let ((stack (seq-filter #'identity (append backtrace nil))))
               (when stack
                 ;; backtrace is leaf-first; flamegraph wants root-first
                 (insert (mapconcat #'nt/profiler--format-entry
                                    (nreverse stack) ";")
                         " "
                         (number-to-string count)
                         "\n")))))
         log)))
    (message "Wrote folded stacks to %s" filename)))

(provide 'nt-profiler)
;;; nt-profiler.el ends here
