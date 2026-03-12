;;; breaking-bad.el --- Incremental adoption of modal editing in Emacs -*- lexical-binding: t; -*-

;;; Commentary:

;; More information is available in the README.md file.

;;; Code:

(defvar bb-normal-map (make-sparse-keymap)
  "Keymap for modal editing normal mode.")

(define-minor-mode bb-normal-mode
  "Modal editing normal mode."
  :init-value nil
  :lighter " N"
  :keymap bb-normal-map
  (if bb-normal-mode
      (bb-insert-mode -1)))

(defvar bb-excluded-modes nil)

(defun bb--maybe-activate ()
  "Activate normal mode in the current buffer if appropriate."
  (unless (or (minibufferp)
              (member major-mode bb-excluded-modes))
    (bb-normal-mode 1)))

(define-globalized-minor-mode bb-global-mode
  bb-normal-mode
  bb--maybe-activate)


(defun bb--normal-key-undefined (&rest _args)
  "Like `undefined` but receiving any number of args."
  (interactive)
  (funcall #'undefined))

(defun bb--normal-key-variable (key)
  "Return the symbol used to store the normal mode binding for KEY.
KEY is a key description string (e.g., \"a\" or \"SPC\")."
  (intern (concat "bb-normal-binding-for-" key)))

(defun bb--self-insert-undefined-in-buffer (buffer)
  "Return a `self-insert-command` wrapper used to disable self-inserting.
In the given BUFFER it will be disabled, and elsewhere it will work as
intended."
  (let ((orig (symbol-function #'self-insert-command)))
    (lambda (&rest args)
      (interactive)
      (if (eq buffer (current-buffer))
          (apply #'bb--normal-key-undefined args)
        (call-interactively orig)))))

(defun bb--self-insert-remap ()
  "Handle a self-insert key press in normal mode.
Looks up the pressed key in the normal mode binding variables.  If a binding
is found it is called; otherwise, any active remap of `self-insert-command'
outside `bb-normal-map' is honoured, but self-insertion in the current buffer
is suppressed.  Falls back to `undefined' when no binding exists."
  (interactive)
  (let* ((keys (this-command-keys-vector)) ; full key sequence as a vector
         (key (key-description keys))
         (key-variable (bb--normal-key-variable key))
         (key-function (eval key-variable))
         (arg current-prefix-arg)
         (original-remap (command-remapping 'self-insert-command nil (delq bb-normal-map (current-active-maps)))))
    (if key-function
        (if arg
            (apply key-function (list arg))
          (apply key-function nil))
      (if original-remap
          (cl-letf (((symbol-function #'self-insert-command) (bb--self-insert-undefined-in-buffer (current-buffer))))
            (call-interactively original-remap))
        (funcall #'undefined)))))


(keymap-set bb-normal-map "<remap> <self-insert-command>" #'bb--self-insert-remap)


(dolist (key (mapcar (lambda (ch) (key-description (vector ch)))
                     (number-sequence 32 126)))
         (let ((key-variable (bb--normal-key-variable key)))
           (set key-variable nil)))


(defun bb-set-normal-key (key binding &optional forbid)
  "Bind KEY to BINDING in normal mode.
KEY is a key description string.  BINDING is the command to call.
When FORBID is non-nil and BINDING is a symbol, also install a remap so that
invoking BINDING via its original key sequence shows a reminder to use the
normal mode binding instead."
  (set (bb--normal-key-variable key) binding)
  (when (and forbid (symbolp binding))
    (keymap-set bb-normal-map
                (format "<remap> <%s>" (symbol-name binding))
                (lambda () (interactive) (message "Use normal mode binding!!!")))))

(bb-set-normal-key "i" #'bb-insert-mode)
;; (bb-set-normal-key "h" #'backward-char)
;; (bb-set-normal-key "j" #'next-line)
;; (bb-set-normal-key "k" #'previous-line)
;; (bb-set-normal-key "l" #'forward-char)

(defun bb-set-normal-key-local (key binding)
  "Bind KEY to BINDING in normal mode, buffer-locally.
Like `bb-set-normal-key' but makes the binding variable buffer-local so it
only affects the current buffer."
  (let ((key-var (bb--normal-key-variable key)))
    (make-local-variable key-var)
    (set key-var binding)))



;;; insert-mode

(defvar bb-insert-map (make-sparse-keymap)
  "Keymap for my insert state.")

(defvar-local bb--change-tick-counter 0)
(defvar-local bb--point-tracker nil)

(defun bb--exit-insert-mode-when-not-inserting ()
  "Switch back to normal mode after a command that did not insert text.
Runs on `post-command-hook' while insert mode is active.  If the buffer
modification tick did not change and the command was not the one that
activates insert mode, `bb-normal-mode' is re-enabled."
  (let ((last-tick-counter bb--change-tick-counter)
        (new-tick-counter (setq-local bb--change-tick-counter (buffer-chars-modified-tick)))
        (last-point bb--point-tracker)
        (new-point (setq-local bb--point-tracker (point))))
    (unless (eq this-command #'bb--self-insert-remap) ;; This is the command that usually enables insert-mode
      (when (and (eq last-tick-counter new-tick-counter)
                 (eq last-point new-point))
        (bb-normal-mode 1)))))

(define-minor-mode bb-insert-mode
  "My modal insert state."
  :init-value nil
  :lighter " N"
  :keymap bb-insert-map
  (if bb-insert-mode
      (progn
        (bb-normal-mode -1)
        (add-hook 'post-command-hook #'bb--exit-insert-mode-when-not-inserting nil t))
    (remove-hook 'post-command-hook #'bb--exit-insert-mode-when-not-inserting t)))

(define-key bb-insert-map (kbd "C-g")
            (lambda () (interactive) (bb-insert-mode -1) (bb-normal-mode 1)))




(provide 'breaking-bad)

;;; breaking-bad.el ends here
