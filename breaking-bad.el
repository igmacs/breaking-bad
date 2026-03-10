;;; breaking-bad.el --- Incremental adoption of modal editing in Emacs

;;; Commentary:

;; More information is available in the README.md file.

;;; Code:

(defvar bb-normal-map (make-sparse-keymap)
  "Keymap for my normal state.")

(define-minor-mode bb-normal-mode
  "My modal normal state."
  :init-value nil
  :lighter " N"
  :keymap bb-normal-map
  (if bb-normal-mode
      (bb-insert-mode -1)))

(defvar bb-excluded-modes nil)

(defun bb--maybe-activate ()
  (unless (or (minibufferp)
              (member major-mode bb-excluded-modes))
    (bb-normal-mode 1)))

(define-globalized-minor-mode bb-global-mode
  bb-normal-mode
  bb--maybe-activate)


(defun bb-normal-key-undefined (&rest args)
  (interactive)
  (funcall #'undefined))

(defun bb-normal-key-variable (key)
  (intern (concat "bb-normal-binding-for-" key)))

(defun bb-self-insert-remap ()
  (interactive)
  (let* ((keys (this-command-keys-vector)) ; full key sequence as a vector
         (key (key-description keys))
         (key-variable (bb-normal-key-variable key))
         (key-function (eval key-variable))
         (arg current-prefix-arg)
         (original-remap (command-remapping 'self-insert-command nil (delq bb-normal-map (current-active-maps)))))
    (if key-function
        (if arg
            (apply key-function (list arg))
          (apply key-function nil))
      (if original-remap
          (cl-letf (((symbol-function #'self-insert-command) #' bb-normal-key-undefined))
            (call-interactively original-remap))
        (funcall #'undefined)))))


(keymap-set bb-normal-map "<remap> <self-insert-command>" #'bb-self-insert-remap)


(dolist (key (mapcar (lambda (ch) (key-description (vector ch)))
                     (number-sequence 32 126)))
         (let ((key-variable (bb-normal-key-variable key)))
           (set key-variable nil)))


(defun bb-set-normal-key (key binding &optional forbid)
  (set (bb-normal-key-variable key) binding)
  (when (and forbid (symbolp binding))
    (keymap-set bb-normal-map
                (format "<remap> <%s>" (symbol-name binding))
                (lambda () (interactive) (message "Use normal mode binding!!!")))))

(bb-set-normal-key "i" #'bb-insert-mode)
(bb-set-normal-key "h" #'backward-char)
(bb-set-normal-key "j" #'next-line)
(bb-set-normal-key "k" #'previous-line)
(bb-set-normal-key "l" #'forward-char)

(defun bb-set-normal-key-local (key binding)
  (let ((key-var (bb-normal-key-variable key)))
    (make-local-variable key-var)
    (set key-var binding)))



;;; insert-mode

(defvar bb-insert-map (make-sparse-keymap)
  "Keymap for my insert state.")

(defun bb-exit-insert-mode-when-not-inserting ()
  (unless (member this-command (list #'self-insert-command
                                     #'bb-self-insert-remap ;; This is the command that usually enables insert-mode
                                 ))
    (bb-normal-mode 1)))

(define-minor-mode bb-insert-mode
  "My modal insert state."
  :init-value nil
  :lighter " N"
  :keymap bb-insert-map
  (if bb-insert-mode
      (progn
        (bb-normal-mode -1)
        (add-hook 'post-command-hook #'bb-exit-insert-mode-when-not-inserting nil t))
    (remove-hook 'post-command-hook #'bb-exit-insert-mode-when-not-inserting t)))

(define-key bb-insert-map (kbd "C-g")
            (lambda () (interactive) (bb-insert-mode -1) (bb-normal-mode 1)))




(provide 'breaking-bad)

;;; breaking-bad.el ends here
