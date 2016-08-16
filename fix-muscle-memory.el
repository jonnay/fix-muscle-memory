;;; fix-spell-memory.el --- Simple hack into ispell to fix (muscle) memory problems
 
;; Copyright (C) 2012 Jonathan Arkell

;; Author: Jonathan Arkell <jonnay@jonnay.net>
;; Created: 5 Oct 2012
;; Keywords: erc bitlbee bot
;; Version 0.1

;; This file is not part of GNU Emacs.
;; Released under the GPL v3.0

;;; Commentary:
;; ,   
;; ,   When spell correcting, this package forces you to fix your mixtakes
;; ,   three times to re-write your muscle memory into typing it correctly.
;; , 
;; , * Motivation
;; , 
;; ,   I used to type 'necessary' wrong... ALL THE TIME.  I misspelled it so
;; ,   often that it became part of my muscle memory.  It is one of *THOSE*
;; ,   words for me.  There are others, that by muscle or brain memory,
;; ,   are "burned in" as a particular pattern.
;; ,  
;; ,   This is an attempt to break that pattern, by forcing you to re-type
;; ,   your misspelled words 3 times.  This should help overcome any broken
;; ,   muscle and brain memory.
;; , 
;; , * Usage
;; , 
;; ,   - Step 1 :: Require this file
;; ,   - Step 2 :: Use M-$ to check the spelling of your misspelled word
;; ,   - Step 3 :: follow the directions of the prompt
;; ,   
;; ,   If you want, you can customize the 
;; ,   `fix-muscle-memory-load-problem-words' variable, and that will 
;; ,   force you to fix the typos when you make them, rather than at 
;; ,   spell-check time.
;; , 
;; ,   This works by adding the words to the global abbrev table, and
;; ,   modifying the `abbrev-expand-function'.  If you do any jiggery-pokery
;; ,   there, you'll need to be aware.
;; , 
;; , * Changelog
;; , 
;; ,   - v 0.1 :: First Version.
;; ,   - v 0.2 :: 
;; ,     - Minor documentation fix. 
;; ,   - v 0.3 ::
;; ,     - Fix bug when using Ispell.
;; ,   - v 0.3.1 ::
;; ,     - Gave it it's own repository (finally).
;; ,     - Added abbrev hook.
;; ,     - properly manage the response back from `ispell-command-loop'.
;; ,     - Added cute emoji.  I couldn't help myself.

;;; Code:

(defun fix-muscle-memory-load-problem-words (sym values)
  "Remove existing problem words and re-set them.
`VALUES' is a list of word pairs.  
`SYM' is just there for customize."
  ; remove the old abbrevs
  (when (boundp 'fix-muscle-memory-problem-words)
    (dolist (word-pair fix-muscle-memory-problem-words)
      (define-abbrev global-abbrev-table (car word-pair) nil)))
  ; set the new 
  (dolist (word-pair values)
          (define-abbrev global-abbrev-table 
            (car word-pair)
            (cdr word-pair)
            nil
            '(:system t)))
  (setq fix-muscle-memory-problem-words values))

(defcustom fix-muscle-memory-problem-words 
  '()
  "A list of problematic words that should be immediately fixed.
This is a lit of cons cells, with the car being the typo and the
cdr the fix.

If you edit this outside of customize, you will need to use
`fix-muscle-memory-load-problem-words' function instead. "
  :type '(repeat (cons string string))
  :set 'fix-muscle-memory-load-problem-words)

(defun fix-muscle-memory-correct-user-with-the-ruler (the-problem the-solution)
  "The user correction function.

This function helps fix a bug in the user by making them type out
`THE-SOLUTION' in response to when `THE-PROBLEM' is seen."
  (beep)
  (let* ((required-corrections 3)
         (attempts 0))
    (while (< attempts required-corrections)
      (when (< attempts -6) (error "Too many failed attempts! 😿"))
      (setq attempts 
            (+ attempts (if (string= (read-string
                                      (format "Bad User *whack*.🙇📏 Please fix '%s' with '%s' (%d/%d): "
                                              the-problem
                                              the-solution
                                              attempts
                                              required-corrections))
                                  the-solution)
                         1
                       (progn (beep) -1)))))))

(defun fix-muscle-memory-in-ispell (orig-fn miss guess word start end)
  "Advice function to run after an ispell word has been selected"
  (let ((return-value (funcall orig-fn miss guess word start end)))
    (when (stringp return-value)
      (fix-muscle-memory-correct-user-with-the-ruler miss return-value))
    return-value))

(advice-add 'ispell-command-loop :around #'fix-muscle-memory-in-ispell)

(defun fix-muscle-memory-expand-abbrev ()
  (let* ((abbrev (abbrev--default-expand))
         (word (assoc (symbol-name abbrev) fix-muscle-memory-problem-words)))
    (when (and abbrev word)
      (fix-muscle-memory-correct-user-with-the-ruler (car word) (cdr word)))
    abbrev))

(setq abbrev-expand-function #'fix-muscle-memory-expand-abbrev)  

(provide 'emagician-fix-spell-memory)

;;; emagician-fix-spell-memory ends here
