;;; dsv.scm -- Tests for DSV parser.

;; Copyright (C) 2014, 2015 Artyom V. Poptsov <poptsov.artyom@gmail.com>
;;
;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; The program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with the program.  If not, see <http://www.gnu.org/licenses/>.

(use-modules (srfi srfi-64)
             (srfi srfi-26)
             (dsv))

(test-begin "dsv")


;;; dsv->scm

(test-equal "dsv->scm: three fields"
  '(("a" "b" "c"))
  (call-with-input-string "a:b:c\n"
    (cut dsv->scm <>)))

(test-equal "dsv->scm: two fields with an escaped colon"
  '(("a:b" "c"))
  (call-with-input-string "a\\:b:c\n"
    (cut dsv->scm <>)))

(test-equal "dsv->scm: two fields with an escaped comma"
  '(("a,b" "c"))
  (call-with-input-string "a\\,b,c\n"
    (cut dsv->scm <> #\,)))

(test-equal "dsv->scm: two fields, check order"
  '(("1") ("2"))
  (call-with-input-string
      "1\n2\n"
    (cut dsv->scm <>)))

(test-equal "dsv-string->scm: three fields, separated by a colon 1"
  '(("a" "b" "c"))
  (dsv-string->scm "a:b:c\n"))

(test-equal "dsv-string->scm: three fields, separated by a colon 2"
  '(("a" "b" ""))
  (dsv-string->scm "a:b:\n"))

(test-equal "dsv-string->scm: three fields, separated by a comma"
  '(("a" "b" "c"))
  (dsv-string->scm "a:b:c\n"))

;; Handling of commented lines
(test-assert "dsv->scm, comment prefix"
  (and (equal? '(("a" "b" "c"))
               (call-with-input-string
                "# this is a comment\na:b:c\n"
                 (cut dsv->scm <>)))
       (equal? '(("a" "b" "c"))
               (call-with-input-string
                "; this is a comment\na:b:c\n"
                (cut dsv->scm <> #:comment-prefix ";")))
       (equal? '(("# this is a comment"))
               (call-with-input-string
                "# this is a comment"
                (cut dsv->scm <> #:comment-prefix 'none)))))

(test-assert "dsv-string->scm, nonprintable characters"
  (equal? '(("\f" "a\nb" "\r" "\t" "\v"))
          (dsv-string->scm "\\f:a\\nb:\\r:\\t:\\v\n")))

(test-assert "dsv-string->scm, backslash unescaping"
  (equal? '(("a\\b"))
          (dsv-string->scm "a\\\\b\n")))

(test-assert "dsv-string->scm, record continuation"
    (equal? '(("a b" "c")) (dsv-string->scm "a \\\nb:c\n")))


;;; scm->dsv

(test-assert "scm->dsv"
  (and (string=? "a:b:c\n"
                 (call-with-output-string
                  (cut scm->dsv '(("a" "b" "c")) <>)))
       (string=? "a:b:c\nd:e:f\n"
                 (call-with-output-string
                  (cut scm->dsv '(("a" "b" "c") ("d" "e" "f")) <>)))))

(test-assert "scm->dsv-string"
  (and (equal? "a:b:c\n" (scm->dsv-string '(("a" "b" "c"))))
       (equal? "a,b,\n"  (scm->dsv-string '(("a" "b" "")) #\,))
       (equal? "a:b:\n"  (scm->dsv-string '(("a" "b" ""))))))

(test-assert "scm->dsv, nonprintable characters"
  (equal? "\\f:a\\nb:\\r:\\t:\\v\n"
          (scm->dsv-string '(("\f" "a\nb" "\r" "\t" "\v")))))

(test-assert "scm->dsv, backslash escaping"
  (equal? "a\\\\b\n"
          (scm->dsv-string '(("a\\b")))))


;;; guess-delimiter

(test-assert "guess-delimiter"
  (and (equal? #\,     (guess-delimiter "a,b,c"))
       (equal? #\:     (guess-delimiter "a:b:c"))
       (equal? #\tab   (guess-delimiter "a	b	c"))
       (equal? #\space (guess-delimiter "a b c"))
       (equal? #\:     (guess-delimiter "a,b:c:d:e"))
       (equal? #\,     (guess-delimiter "a,b,c,d:e"))
       (equal? #f      (guess-delimiter "a,b:c"))))

(test-end "dsv")

(exit (= (test-runner-fail-count (test-runner-current)) 0))

;;; dsv.scm ends here.
