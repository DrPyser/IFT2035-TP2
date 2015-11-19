#! /usr/bin/gsi -:dR

;;; Fichier : tp2.scm

;;; Ce programme est une version incomplete du TP2.  Vous devez uniquement
;;; changer et ajouter du code dans la premi�re section.

;;;----------------------------------------------------------------------------

;;; Vous devez modifier cette section.  La fonction "traiter" doit
;;; �tre d�finie, et vous pouvez ajouter des d�finitions de fonction
;;; afin de bien d�composer le traitement � faire en petites
;;; fonctions.  Il faut vous limiter au sous-ensemble *fonctionnel* de
;;; Scheme dans votre codage (donc n'utilisez pas set!, set-car!,
;;; begin, etc).

;;; La fonction traiter re�oit en param�tre une liste de caract�res
;;; contenant la requ�te lue et le dictionnaire des variables sous
;;; forme d'une liste d'association.  La fonction retourne
;;; une paire contenant la liste de caract�res qui sera imprim�e comme
;;; r�sultat de l'expression entr�e et le nouveau dictionnaire.  Vos
;;; fonctions ne doivent pas faire d'affichage car c'est la fonction
;;; "repl" qui se charge de cela.

;(load "/usr/lib64/gambit-c/syntax-case.scm")

;;State monad
(define st-return
  (lambda (x)
    (lambda (s)
      (cons x s))))

(define get
  (lambda (s)
    (cons s s)))

(define (put ss)
  (lambda (s)
    (cons '() ss)))

(define (run st s)
  (st s))

(define (st-bind st f)
  (lambda (s)
    (let* ((a (run st s))
	   (x (car a))
	   (stt (cdr a)))
      (run (f x) stt))))

(define (modify f)
  (lambda (s)
    (cons '() (f s))))

(define (gets f)
  (lambda (s)
    (cons (f s) s)))
;;-------------------------------------------------------------------------

;;;Fonctions utilitaires

(define foldl
  (lambda (f base lst)
    (if (null? lst)
	base
	(foldl f (f base (car lst)) (cdr lst)))))

;;Convertit un caract�re repr�sentant un chiffre en l'integer correspondant
(define char->int
  (lambda (char)
    (case char
      [(#\0) 0]
      [(#\1) 1]
      [(#\2) 2]
      [(#\3) 3]
      [(#\4) 4]
      [(#\5) 5]
      [(#\6) 6]
      [(#\7) 7]
      [(#\8) 8]
      [(#\9) 9])))

(define del-assoc
  (lambda (key lst)
    (if (null? lst)
	lst
	(if (eqv? (caar lst) key)
	    (cdr lst)
	    (cons (car lst) (del-assoc key (cdr lst)))))))

(define ensure-assoc
  (lambda (lst key value)
    (cons (cons key value) (del-assoc key lst))))
    
;;Accumule les �l�ments de 'lst' tant qu'ils satisfassent le pr�dicat 'p'.
;;Au premier �l�ment ne satisfaisant pas 'p', ou si la fin de la liste est atteinte,
;;une liste contenant une liste des �l�ments accumul�s ainsi que le reste de 'lst' est retourn�.
;;ex: (span odd? '(1 3 5 6 7 8 9)) => ((1 3 5) (6 7 8 9))
(define span
  (lambda (p lst)
    (let helper ((accum '())
		 (rest lst))
      (if (null? rest)
	  (list (reverse accum) rest)
	  (if (p (car rest))
	      (helper (cons (car rest) accum) (cdr rest))
	      (list (reverse accum) rest))))))

;;Convertit une liste de charact�re repr�sentant des chiffres en le nombre correspondant � la lecture de gauche � droite
;;ex:(chars->number '(#\1 #\2 #\3)) => 123
(define chars->number
  (lambda (lst)
    (foldl (lambda (acc x)
	     (+ (* 10 acc) (char->int x)))
	   0
	   lst)))

(define (split p lst)
  (if (null? lst)
      '()
      (if (p (car lst))
	  (split p (cdr lst))
	  (let ((tmp (span (lambda (x) (not (p x))) lst)))
	    (cons (car tmp) (split p (cadr tmp)))))))

(define (take n lst)
  (if (null? lst)
      '()
      (if (<= n 0)
	  '()
	  (cons (car lst) (take (- n 1) (cdr lst))))))

(define (drop n lst)
  (if (null? lst)
      '()
      (if (<= n 0)
	  lst
	  (drop (- n 1) (cdr lst)))))

(define take-while
  (lambda (p lst)
    (let helper ((lst lst)
		 (cont (lambda (x) x)))
      (if (p (car lst))
	  (helper (cdr lst) (lambda (x) (cons (car lst) x)))
	  (cont '())))))

(define (split-at n lst)
  (let helper ((taken '())
	       (rest lst)
	       (n n))
    (if (or (<= n 0) (null? rest))
	(list (reverse taken) rest)
	(helper (cons (car rest) taken) (cdr rest) (- n 1)))))
				  
(define number->list
  (lambda (number)
    (if (number? number)
	(string->list (number->string number))
	'())))

(define every
  (lambda (p lst)
    (or (null? lst)
	(if (p (car lst))
	    (every p (cdr lst))
	    #f))))

(define operator?
  (lambda (char)
    (member char (list #\+ #\- #\* #\/))))

;;Une macro pour destructurer une liste

;(define-syntax let+
 ; (syntax-rules ()
  ;  [(_ pattern lst f ...) (apply (lambda pattern f ...) lst)]))

(define operator->procedure
  (lambda (char)
    (case char
      ((#\+) (list + 2))
      ((#\*) (list * 2))
      ((#\-) (list - 2))
      ((#\/) (list / 2)))))      

;;----------------------------------------------------------------------------
;;Fonction pour traiter un jeton, en retournant � la continuation une pile et un dictionnaire potentiellement modifi�
;;(et potentiellement un message d'erreur)
(define traiter-jeton
  (lambda (jeton pile dict cont)
    (cond ((char-numeric? (car jeton)) (if (every char-numeric? jeton)
					   (cont #f (cons (chars->number jeton) pile) dict)
					   (cont (string-append "*** Erreur: jeton invalide: " (list->string jeton) " ***\n")
						 pile dict)))
	  ((char-alphabetic? (car jeton)) (if (= (length jeton) 1)
					      (let ((binding (assoc (car jeton) dict)))
						(if binding
						    (cont #f (cons (cdr binding) pile) dict)
						    (cont (string-append "*** Erreur: variable non-d�finie: " (string (car jeton)) " ***\n")
							  pile
							  dict)))
						(cont (string-append "*** Erreur: jeton invalide: " (list->string jeton) " ***\n")
						      pile dict)))
	  ((char=? (car jeton) #\=) (if (= (length jeton) 2)
					(if (char-alphabetic? (cadr jeton))
					    (if (> (length pile) 0)
						(cont #f pile (ensure-assoc dict (cadr jeton) (car pile)))
						(cont "*** Erreur: argument manquant pour l'op�ration d'assignation ***\n"
						      pile dict))
					    (cont "*** Erreur: jeton invalide - une variable doit �tre un charact�re alphabetic ***\n"
						  pile dict))
					(cont (string-append "*** Erreur: jeton invalide: " (list->string jeton) " ***\n")
					      pile dict)))
	  ((operator? (car jeton)) (apply (lambda (proc narg)
					    (if (>= (length pile) narg)
						(cont #f (cons (apply proc (take narg pile)) (drop narg pile)) dict)
						(cont (string-append "*** Erreur: nombre d'arguments insuffisant pour l'op�rateur "
								     (string (car jeton)) " ***\n") pile dict)))
						      (operator->procedure (car jeton))))
	  (else (cont "What the fuck is that?\n" pile dict)))))
						   

;;Traite l'ensemble des jeton. La continuation peut retourner � n'importe quel �tape du traitement dans le cas d'une erreur
(define traiter-jetons
  (lambda (jetons pile dict cont)
    (if (null? jetons)
	(cont #f pile dict)
	(traiter-jeton (car jetons) pile dict 
			(lambda (erreur pile dict)
			  (if erreur
			      (cons (string->list erreur) dict)
			      (traiter-jetons (cdr jetons) pile dict cont)))))))

(define traiter
  (lambda (expr dict)
    (if (null? expr)
	(cons '() dict)
	(let ((tokens (split char-whitespace? expr)))
;	  (display tokens)
	  (traiter-jetons tokens '() dict (lambda (erreur pile dict)
					(if erreur
					    (cons (string->list erreur) dict)
					    (cond ((null? pile) (cons '() dict))
						  ((> (length pile) 1) (cons (string->list "*** Erreur: valeur(s) inutilis�e(s) ***") dict))
						  (else (cons (number->list (car pile)) dict))))))))))

;;;----------------------------------------------------------------------------



					
;;; Ne pas modifier cette section.

(define repl
  (lambda (dict)
    (print "? ")
    (let ((ligne (read-line)))
      (if (string? ligne)
          (let ((r (traiter-ligne ligne dict)))
            (for-each write-char (car r))
;	    (display (cadr r))
            (repl (cdr r)))))))

(define traiter-ligne
  (lambda (ligne dict)
    (traiter (string->list ligne) dict)))

(define main
  (lambda ()
    (repl '()))) ;; dictionnaire initial est vide
    
;;;----------------------------------------------------------------------------
