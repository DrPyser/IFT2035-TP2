Fonctionnement du programme {#fonctionnement-du-programme .unnumbered}
===========================

Le programme sépare les lignes en jetons (liste de caractères) en
utilisant les espaces comme délimiteur. Il traverse la liste de jeton et
traite celui-ci selon le premier caractère. Une liste, utilisée comme
pile, emmagasine les nombres au fur et à mesure que les calculs sont
effectués.

Lorsqu’une opération a lieu, on récupère les deux derniers éléments de
la pile, on effectue l’opération et on replace le résultat sur la pile.

Une copie du dictionnaire est utilisé pour gérer les assignations. Lors
d’une assignation, on modifie ce dictionnaire. S’il n’y a pas d’erreur,
c’est ce dictionnaire qui sera utilisée pour les prochaines lignes.
Sinon, on garde l’ancien dictionnaire.

Lors de l’appel d’une variable, on ne fait que récupérer la valeur
associée à la variable.

Les erreurs sont gérées par des continuations, qui les attrapent dès
leur apparition dans le processus de traitement. Celles-ci prennent un
message d’erreur en paramètre et le retourne comme valeur à afficher,
interrompant le traitement.

Résolution des problèmes de programmation {#résolution-des-problèmes-de-programmation .unnumbered}
=========================================

Analyse syntaxique {#analyse-syntaxique .unnumbered}
------------------

D’abord, si la ligne est vide, la fonction “traiter” retourne une liste
vide (pour ne rien afficher) et le dictionnaire sans modification.
Sinon, le programme sépare la ligne en une liste de chaines de
caractères en utilisant les espaces comme délimiteurs.

Cette liste est ensuite envoyé à la fonction “traiter-jetons” qui
parcourt chaque jeton et les traite, en faisant des suppositions selon
le premier caractère du jeton :

-   Si le caractère est un chiffre, alors on est en train de traiter un
    nombre. On vérifie donc si tous les caractères du jeton sont des
    chiffres. ;

-   Si le caractère est une lettre, alors on est en train de traiter une
    variable. On vérifie donc si le jeton n’est que d’un caractère et si
    la variable a déjà été initialisée ;

-   Si le caractère est un =, alors on est en train de traiter une
    affectation. On vérifie donc si le jeton contient 2 caractères, si
    le deuxième est une lettre et si la pile utilisée pour les calculs
    contient un élément ;

-   Si le caractère est un +, un - ou un \*, alors on est en train de
    traiter une opération. On vérifie donc si la pile contient
    suffisamment d’éléments pour effectuer l’opération ;

-   Si le caractère est un retour à la ligne ou la fin du fichier, alors
    on a aucune action à effectuer ;

-   Sinon, le jeton est forcément invalide.

Calcul de l’expression {#calcul-de-lexpression .unnumbered}
----------------------

La fonction “traiter-jetons” reçoit une pile en paramètre pour effectuer
les calculs. En assumant que la ligne a une syntaxe valide, on a le
comportement suivant :

-   Pour un nombre, on convertit la chaine en nombre et on l’ajoute à la
    pile

-   Pour une variable, on ajoute la valeur à la pile.

-   Pour une affectation, on supprime d’abord le couple clef-valeur du
    dictionnaire si la variable a déjà été assignée, puis on ajoute le
    nouveau couple clef-valeur dans celui-ci.

-   Pour une opération, on détermine quelle fonction utiliser, récupère
    le nombre d’arguments nécessaires de la pile, applique la fonction
    sur les arguments et ajoute le résultat à la pile.

Affectation aux variables {#affectation-aux-variables .unnumbered}
-------------------------

L’affectation aux variables se fait à l’aide du dictionnaire qui est
passé en entrée à la fonction “traiter”. Elle contient des paires
clef-valeur, où la clef est la variable et la valeur est le nombre qui a
été affecté à celle-ci.

Un dictionnaire temporaire vide est envoyé à “traiter-jetons” qui
contient les valeurs assignées dans la ligne. Lors d’une assignation,
les clefs-valeurs sont ajoutées à ce dictionnaire.

Les continuations qui traitent les erreurs reçoivent le dictionnaire de
variables et le dictionnaire temporaire en paramètre. S’il n’y a pas
d’erreur, on insère toutes les clefs-valeurs du dictionnaire temporaire
au dictionnaire de variables.

Affichage des résultats et des erreurs {#affichage-des-résultats-et-des-erreurs .unnumbered}
--------------------------------------

La fonction “traiter-jetons” reçoit une continuation en paramètre qui
s’occupe de l’affichage, qui est aussi passée à “traiter-jeton”. Cette
continuation vérifie si une erreur a eu lieu et affiche le message en
conséquent. Sinon, elle affiche le seul et dernier élément sur la pile.

Gestion des erreurs {#gestion-des-erreurs .unnumbered}
-------------------

La gestion des erreurs passe par une continuation qui prend en
paramètres le message d’erreur, la pile de nombres et le dictionnaire.

S’il n’y a pas d’erreur, la continuation est appelée à la fin du
traitement avec un message d’erreur initialisé à faux.

S’il y a une erreur, la continuation est appelée avec le message
d’erreur initialisée à la description de l’erreur.

Ainsi, la continuation affiche le message d’erreur si celui-ci n’est pas
à faux. Sinon, il affiche le résultat correct.

Notons que le programme continue d’exécuter les lignes subséquentes même
s’il y a une erreur.

Comparaison avec le TP1 {#comparaison-avec-le-tp1 .unnumbered}
=======================

Le programme en Scheme prend un peu moins de 300 lignes de codes, alors
que le programme en C en a pris un peu moins de 700. En général, le
programme a été beaucoup plus simple à implémenter en Scheme qu’en C.

D’abord, les nombres à précision arbitraire sont déjà présents dans le
langage. Il n’était donc pas nécessaire de créer une nouvelle structure
pour les représenter ni de créer des fonctions spécifiques pour
effectuer les opérations sur ceux-ci.

De plus, les listes de Scheme peuvent être facilement utilisées comme
pile, où “cons” permet de pousser une valeur dans la pile et “car” et
“cdr” de récupérer un élément de la pile. En C, il a fallu utiliser une
liste chainée comme pile.

Il n’était aussi pas nécessaire de gérer la mémoire. Sans ces trois
difficultés, le programme C aurait aussi moins de 300 lignes.
