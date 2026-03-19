;;; fzf-complete.el --- FZF-backed completion style -*- lexical-binding: t; -*-

;;; Commentary:
;; Completion style that uses the real fzf binary's --filter mode.
;; Works with completing-read, so it integrates with Vertico and any
;; command that uses the standard completion API (M-x, C-x b, etc.).

;;; Code:

(defcustom fzf-complete-executable (executable-find "fzf")
  "Path to the fzf executable."
  :type 'string
  :group 'minibuffer)

(defun fzf-complete--filter (pattern candidates)
  "Filter CANDIDATES with fzf --filter using PATTERN.
Returns a list sorted by fzf's ranking.
Text properties on CANDIDATES are preserved."
  (if (string-empty-p pattern)
      (copy-sequence candidates)
    ;; Build a lookup from plain text back to original propertized candidate.
    (let ((table (make-hash-table :test #'equal :size (length candidates))))
      (dolist (c candidates)
        (let ((key (substring-no-properties c)))
          (unless (gethash key table)
            (puthash key c table))))
      (with-temp-buffer
        (insert (mapconcat #'substring-no-properties candidates "\n"))
        (let ((exit-code
               (call-process-region (point-min) (point-max)
                                    fzf-complete-executable
                                    t t nil "--filter" pattern)))
          (when (memq exit-code '(0 1))
            (mapcar (lambda (s) (or (gethash s table) s))
                    (split-string (buffer-string) "\n" t))))))))

(defun fzf-complete-try-completion (string table pred point)
  "FZF try-completion style function.
Signals whether matches exist; does not narrow the input since
fuzzy matches have no meaningful common prefix."
  (when fzf-complete-executable
    (let* ((beforepoint (substring string 0 point))
           (afterpoint (substring string point))
           (bounds (completion-boundaries beforepoint table pred afterpoint))
           (prefix (substring beforepoint 0 (car bounds)))
           (pattern (substring beforepoint (car bounds)))
           (all (all-completions prefix table pred)))
      (when all
        (let ((filtered (fzf-complete--filter pattern all)))
          (cond
           ((null filtered) nil)
           ((and (= (length filtered) 1)
                 (string= (car filtered) pattern))
            t)
           (t (cons string point))))))))

(defun fzf-complete--highlight (pattern candidate)
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

(defun fzf-complete-all-completions (string table pred point)
  "FZF all-completions style function.
Filters and ranks candidates using fzf --filter."
  (when fzf-complete-executable
    (let* ((beforepoint (substring string 0 point))
           (afterpoint (substring string point))
           (bounds (completion-boundaries beforepoint table pred afterpoint))
           (prefix (substring beforepoint 0 (car bounds)))
           (pattern (substring beforepoint (car bounds)))
           (all (all-completions prefix table pred)))
      (when all
        (let ((filtered (fzf-complete--filter pattern all)))
          (when filtered
            (when (> (length pattern) 0)
              (setq filtered (mapcar (lambda (c)
                                       (fzf-complete--highlight pattern c))
                                     filtered)))
            (setcdr (last filtered) (length prefix))
            filtered))))))

(add-to-list 'completion-styles-alist
             '(fzf fzf-complete-try-completion
               fzf-complete-all-completions
               "FZF-backed fuzzy completion."))

(provide 'fzf-complete)
;;; fzf-complete.el ends here
