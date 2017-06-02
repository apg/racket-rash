#lang racket/base
(require "../main.rkt")
(require (submod "lang-funcs.rkt" for-module-begin))

(define interactive-return-values (make-hash))
(define (result-n n)
  (hash-ref interactive-return-values n))
(define (return-n n)
  (let ([pline (result-n n)])
    (if (pipeline? pline)
        (pipeline-ret pline)
        pline)))
#|
TODO --
Probably the hash table should only be modifiable via auto-update
when commands are run, and only accessing functions should be in
the repl namespace.

What functions for refering to previous returns would be useful?
Probably there should be something like (return-n-reverse 0)
that gives the previously returned.

Add something that refers to results that are bg pipelines.  There should
be a function to list currently running jobs by their numbers and the command
they are running.

If I add `pipeline-stop` and `pipeline-resume` functions and have interactive
pipelines always run in the background, I can add suspend/background/foreground
to the interactive shell.

bash and friends give jobs numbers as well as their return numbers.
Is that something useful?  I think it probably isn't worth having two
numbering schemes...

|#

(define-namespace-anchor ns-a)
(define repl-namespace (namespace-anchor->namespace ns-a))
(provide repl-namespace)
