;;; flymake-markdownlint.el --- Markdown linter with markdownlint  -*- lexical-binding: t; -*-

;; Copyright (C) 2021 Martin Kjær Jørgensen (shaohme) <mkj@gotu.dk>
;;
;; Author: Martin Kjær Jørgensen <mkj@gotu.dk>
;; Created: 15 December 2021
;; Version: 0.1.0
;; Package-Requires: ((emacs "26.1"))
;; URL: https://github.com/shaohme/flymake-markdownlint
;;; Commentary:

;; This package adds Markdown syntax checker using markdownlint-cli.
;; Make sure 'markdownlint-cli' binary is on your path.
;; Installation instructions https://github.com/DavidAnson/markdownlint

;; SPDX-License-Identifier: GPL-3.0-or-later

;; flymake-markdownlint is free software; you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; flymake-markdownlint is distributed in the hope that it will be useful, but WITHOUT
;; ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
;; or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public
;; License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with flymake-markdownlint.  If not, see http://www.gnu.org/licenses.

;;; Code:

(require 'flymake)

(defgroup flymake-markdownlint nil
  "Markdownlint backend for Flymake."
  :prefix "flymake-markdownlint-"
  :group 'tools)

(defcustom flymake-markdownlint-path
  (executable-find "markdownlint")
  "The path to the `markdownlint' executable."
  :type 'string)

(defvar-local flymake-markdownlint--proc nil)

(defun flymake-markdownlint (report-fn &rest _args)
  "Flymake backend for markdownlint report using REPORT-FN."
  (unless (and flymake-markdownlint-path
               (file-executable-p flymake-markdownlint-path))
    (error "Could not find markdownlint executable"))

  (when (process-live-p flymake-markdownlint--proc)
    (kill-process flymake-markdownlint--proc)
    (setq flymake-markdownlint--proc nil))

  (let ((source (current-buffer)))
    (save-restriction
      (widen)
      (setq
       flymake-markdownlint--proc
       (make-process
        :name "flymake-markdownlint" :noquery t :connection-type 'pipe
        :buffer (generate-new-buffer " *flymake-markdownlint*")
        :command (list flymake-markdownlint-path "-s" "-j")
        :sentinel
        (lambda (proc _event)
          (when (eq 'exit (process-status proc))
            (unwind-protect
                (if (with-current-buffer source (eq proc flymake-markdownlint--proc))
                    (with-current-buffer (process-buffer proc)
                      (goto-char (point-min))
                      (let ((diags)
                            (map-vec (json-parse-buffer)))
                        (if (not (vectorp map-vec))
                            (error (format "json-parser-buffer returned unexpected type, %s" (type-of map-vec))))
                        (let ((len (length map-vec))
                              (i 0))
                          (while (< i len)
                            (let* ((map (aref map-vec i))
                                   (lineNum (gethash "lineNumber" map))
                                   (ruleNames (gethash "ruleNames" map))
                                   (ruleDesc (gethash "ruleDescription" map))
                                   (errRange (gethash "errorRange" map))
                                   (error-type (if (eq errRange :null) :warning :error))
                                   (region (flymake-diag-region source lineNum)))
                              ;; expect `region' to only have 2 values (start . end)
                              (push (flymake-make-diagnostic source
                                                             (car region)
                                                             (cdr region)
                                                             error-type
                                                             (format "%s: %s" (aref ruleNames 0) ruleDesc)) diags)
                              (setq i (+ i 1)))))
                        (funcall report-fn (reverse diags))))
                  (flymake-log :warning "Canceling obsolete check %s"
                               proc))
              (kill-buffer (process-buffer proc)))))))
      (process-send-region flymake-markdownlint--proc (point-min) (point-max))
      (process-send-eof flymake-markdownlint--proc))))

;;;###autoload
(defun flymake-markdownlint-setup ()
  "Enable markdownlint flymake backend."
  (add-hook 'flymake-diagnostic-functions #'flymake-markdownlint nil t))

(provide 'flymake-markdownlint)
;;; flymake-markdownlint.el ends here
