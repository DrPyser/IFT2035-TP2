#! /usr/bin/env gsi -:dR

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
  (lambda (key assoc)
    (if (null? assoc)
	assoc
	(if (eqv? (caar assoc) key)
	    (cdr assoc)
	    (cons (car assoc) (del-assoc (cdr assoc)))))))

(define ensure-assoc
  (lambda (lst key value)
    (cons (cons key value) (del-assoc key lst))))
    
;;Accumule les �l�ments de 'lst' tant qu'ils satisfassent le pr�dicat 'p'.
;;Au premier �l�ment ne satisfaisant pas 'p', ou si la fin de la liste est atteinte,
;;une liste contenant une liste des �l�ments accumul�s ainsi que le reste de 'lst' est retourn�.
;;ex: (span odd? '(1 3 5 6 7 8 9)) => ((1 3 5) (6 7 8 9))
(define span
  (lambda (p lst)
    (define (helper accum rest)
      (if (null? rest)
	  (list (reverse accum) rest)
	  (if (p (car rest))
	      (helper (cons (car rest) accum) (cdr rest))
	      (list (reverse accum) rest))))
    (helper '() lst)))	

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

(define space?
  (lambda (char)
    (char=? char #\ )))

(define traiter-jeton)


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

(define (split-at n lst)
  (let helper ((taken '())
	       (rest lst)
	       (n n))
    (if (or (<= n 0) (null? rest))
	(list (reverse taken) rest)
	(helper (cons (car rest) taken) (cdr rest) (- n 1)))))

(define compute
  (lambda (dict stack nargs operator)
    (if (>= (length stack) nargs)
	(let ((tmp (split-at nargs stack)))
	  (list #f (cons (apply operator (car tmp)) (cadr tmp)) dict))
	(list "*** Erreur: Nombre d'argument insuffisant." stack dict))))

(define traiter-liste
  (lambda (acc token)
    (let* ((error (car acc))
	   (stk (cadr acc)) 
	   (dict (caddr acc))
	   (top (if (null? stk) #f (car stk))))
      (if error
	  acc
	  (cond ((number? token) (list #f (cons token stk) dict))
		((char? token) (let ((value (assoc token dict)))
				 (if value
				     (list nil (cons value stk) dict)
				     (list "*** Erreur: variable non-d�finie ***" stk dict))))
		((symbol? token) (case token
				   [(+) (compute stk + 2)]
				   [(-) (compute stk - 2)]
				   [(*) (compute stk * 2)]))		  
		((string? token) (list token stk dict))
		((list? token) (case (car token)
				 [(=) (if (null? stk)
					  (list "*** Erreur: argument manquant pour l'affectation ***" stk dict)
					  (list #f stk (ensure-assoc dict (cadr token) (car stk))))]))
		(t (list "what the fuck is that?" stk dict)))))))
				  
(define number->list
  (lambda (number)
    (if (number? number)
	(string->list (number->string number))
	'())))
				    
(define traiter
  (lambda (expr dict)
    (if (null? expr)
	(list '() dict)
	(let* ((results (foldl traiter-liste (list #f '() dict) (map traiter-jeton (split space? expr))))
	       (erreur (car results))
	       (stk (cadr results))
	       (dict (caddr results)))
	  (cond (erreur (list (string->list erreur) dict))
		((null? stk) (list '() dict))
		((> (length stk) 1) (cons (string->list "*** Erreur: valeur(s) inutilis�e(s) ***") dict))
		(else (list (number->list (car stk)) dict)))))))

;;;----------------------------------------------------------------------------



					
;;; Ne pas modifier cette section.

(define repl
  (lambda (dict)
    (print "? ")
    (let ((ligne (read-line)))
      (if (string? ligne)
          (let ((r (traiter-ligne ligne dict)))
            (for-each write-char (car r))
            (repl (cdr r)))))))

(define traiter-ligne
  (lambda (ligne dict)
    (traiter (string->list ligne) dict)))

(define main
  (lambda ()
    (repl '()))) ;; dictionnaire initial est vide
    
;;;----------------------------------------------------------------------------
