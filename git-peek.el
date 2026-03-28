;;; git-peek.el --- Extract a file from a past git commit -*- lexical-binding: t -*-

;;; Commentary:

;; Extract a specific file from a past git commit and save to ~/Dropbox/backup/tmp/
;; Preview updates in real-time as cursor moves in ivy commit list.
;; Requires: ivy

;;; Code:

(declare-function ivy-read "ivy")
(declare-function ivy-state-current "ivy")
(defvar ivy-last)

(defvar git-peek-preview-height 0.8
  "Height ratio of preview window (0.0-1.0).
Adjust to your preference.
1.0 = full screen (minus minibuffer).
0.8 = 80%, default, good for dired/general use.
0.5 = 50%, good for side-by-side comparison with current file.")

(defvar git-peek--root nil "Git root directory for current session.")
(defvar git-peek--file nil "Selected file for current session.")
(defvar git-peek--active nil "Non-nil while commit selection ivy is active.")

(defun git-peek--do-preview ()
  "Preview the commit at current ivy cursor position."
  (when git-peek--active
    (let* ((commit (ivy-state-current ivy-last))
           (hash (car (split-string commit " ")))
           (content (shell-command-to-string
                     (format "git -C %s show %s:%s"
                             git-peek--root
                             hash
                             git-peek--file))))
      (with-current-buffer (get-buffer-create "*git-preview*")
        (erase-buffer)
        (insert content)
        (goto-char (point-min)))
      (display-buffer "*git-preview*"
                      `((display-buffer-in-side-window)
                        (side . top)
                        (window-height . ,git-peek-preview-height))))))

(advice-add 'ivy-next-line     :after (lambda (&rest _) (git-peek--do-preview)))
(advice-add 'ivy-previous-line :after (lambda (&rest _) (git-peek--do-preview)))

;;;###autoload
(defun git-peek ()
  "Extract files from past commits and save in ~/Dropbox/backup/tmp/.
Preview updates in real-time as cursor moves.  RET to save."
  (interactive)
  (let* ((root (or (locate-dominating-file default-directory ".git")
                   (error "Git repository not found")))
         (files
          (split-string
           (shell-command-to-string
            (format "git -C %s ls-files" root)) "\n" t))
         (file (ivy-read "Select File: " files))
         (commits
          (split-string
           (shell-command-to-string
            (format "git -C %s log --oneline -- %s" root file)) "\n" t)))
    (setq git-peek--root root)
    (setq git-peek--file file)
    (setq git-peek--active t)
    (git-peek--do-preview)
    (ivy-read "Select Commit: " commits
	      :action
	      (lambda (commit)
		(setq git-peek--active nil)
		(let* ((hash (car (split-string commit " ")))
		       (date (string-trim
			      (shell-command-to-string
			       (concat "git -C " root
				       " show -s --format=%cd --date=format:%Y%m%d "
				       hash))))
		       (dest-dir (expand-file-name "~/Dropbox/backup/tmp/"))
		       (dest (concat dest-dir date "_" (file-name-nondirectory file))))
		  (unless (file-directory-p dest-dir)
		    (make-directory dest-dir t))
		  (shell-command
		   (format "git -C %s show %s:%s > %s" root hash file dest))
		  (when (get-buffer "*git-preview*")
		    (kill-buffer "*git-preview*"))
		  (dired dest-dir)
		  (message "Saved: %s" dest))))))

(provide 'git-peek)
;;; git-peek.el ends here
