;;; nt-fzf-complete.el --- FZF-backed completion style -*- lexical-binding: t; -*-

;;; Commentary:
;; Completion style that uses the real fzf binary's --filter mode.
;; Works with completing-read, so it integrates with Vertico and any
;; command that uses the standard completion API (M-x, C-x b, etc.).

;;; Code:

(defcustom nt/fzf-complete-executable (executable-find "fzf")
  "Path to the fzf executable."
  :type 'string
  :group 'minibuffer)

(defvar nt/fzf-complete--cache nil
  "Cache: (CACHE-KEY TABLE . INPUT-STRING).")

(defun nt/fzf-complete--prepare (candidates)
  "Return (TABLE . INPUT-STRING) for CANDIDATES, caching across calls."
  (let ((cache-key (cons (length candidates) (car candidates))))
    (if (and nt/fzf-complete--cache
             (equal (car nt/fzf-complete--cache) cache-key))
        (cdr nt/fzf-complete--cache)
      (let ((table (make-hash-table :test #'equal :size (length candidates)))
            (input (mapconcat #'substring-no-properties candidates "\n")))
        (dolist (c candidates)
          (let ((key (substring-no-properties c)))
            (unless (gethash key table)
              (puthash key c table))))
        (let ((entry (cons table input)))
          (setq nt/fzf-complete--cache (cons cache-key entry))
          entry)))))

(defun nt/fzf-complete--clear-cache ()
  "Clear the candidate cache."
  (setq nt/fzf-complete--cache nil))

(add-hook 'minibuffer-exit-hook #'nt/fzf-complete--clear-cache)

(defun nt/fzf-complete--filter (pattern candidates)
  "Filter CANDIDATES with fzf --filter using PATTERN.
Returns a list sorted by fzf's ranking.
Text properties on CANDIDATES are preserved."
  (if (string-empty-p pattern)
      (copy-sequence candidates)
    (let* ((prepared (nt/fzf-complete--prepare candidates))
           (table (car prepared))
           (input (cdr prepared)))
      (with-temp-buffer
        (insert input)
        (let ((exit-code
               (call-process-region (point-min) (point-max)
                                    nt/fzf-complete-executable
                                    t t nil "--filter" pattern)))
          (when (memq exit-code '(0 1))
            (mapcar (lambda (s) (or (gethash s table) s))
                    (split-string (buffer-string) "\n" t))))))))

(defun nt/fzf-complete-try-completion (string table pred point)
  "FZF try-completion style function.
Signals whether matches exist; does not narrow the input since
fuzzy matches have no meaningful common prefix."
  (when nt/fzf-complete-executable
    (let* ((beforepoint (substring string 0 point))
           (afterpoint (substring string point))
           (bounds (completion-boundaries beforepoint table pred afterpoint))
           (prefix (substring beforepoint 0 (car bounds)))
           (pattern (substring beforepoint (car bounds)))
           (all (all-completions prefix table pred)))
      (when all
        (let ((filtered (nt/fzf-complete--filter pattern all)))
          (cond
           ((null filtered) nil)
           ((and (= (length filtered) 1)
                 (string= (car filtered) pattern))
            t)
           (t (cons string point))))))))

(defun nt/fzf-complete--highlight (pattern candidate)
  "Return a copy of CANDIDATE with matched characters highlighted.
Uses smart case: case-insensitive unless PATTERN contains uppercase."
  (let* ((cand (copy-sequence candidate))
         (case-sensitive (let ((case-fold-search nil))
                           (string-match-p "[[:upper:]]" pattern)))
         (pos 0))
    (dotimes (i (length pattern))
      (let ((pchar (aref pattern i)))
        (while (and (< pos (length cand))
                    (not (if case-sensitive
                             (eq (aref cand pos) pchar)
                           (eq (downcase (aref cand pos))
                               (downcase pchar)))))
          (setq pos (1+ pos)))
        (when (< pos (length cand))
          (add-face-text-property pos (1+ pos)
                                  'completions-common-part nil cand)
          (setq pos (1+ pos)))))
    cand))

(defun nt/fzf-complete-all-completions (string table pred point)
  "FZF all-completions style function.
Filters and ranks candidates using fzf --filter."
  (when nt/fzf-complete-executable
    (let* ((beforepoint (substring string 0 point))
           (afterpoint (substring string point))
           (bounds (completion-boundaries beforepoint table pred afterpoint))
           (prefix (substring beforepoint 0 (car bounds)))
           (pattern (substring beforepoint (car bounds)))
           (all (all-completions prefix table pred)))
      (when all
        (let ((filtered (nt/fzf-complete--filter pattern all)))
          (when filtered
            (when (> (length pattern) 0)
              (setq filtered (mapcar (lambda (c)
                                       (nt/fzf-complete--highlight pattern c))
                                     filtered)))
            (setcdr (last filtered) (length prefix))
            filtered))))))

(add-to-list 'completion-styles-alist
             '(fzf nt/fzf-complete-try-completion
               nt/fzf-complete-all-completions
               "FZF-backed fuzzy completion."))

(provide 'nt-fzf-complete)
;;; nt-fzf-complete.el ends here
