#lang racket/base

(require
 "main.rkt"
 (submod "private/lang-funcs.rkt" for-module-begin)
 "private/repl-namespace.rkt"
 "private/read-funcs.rkt"
 "private/option-app.rkt"
 "private/rashrc-lib.rkt"

 basedir
 racket/exn

 (for-syntax syntax/parse
             racket/base))


(define (rash-repl last-ret-val n)
  (option-app (current-prompt-function)
              #:last-return-value last-ret-val
              #:last-return-index n)
  (flush-output (current-output-port))
  (flush-output (current-error-port))
  (let* ([next-input (with-handlers ([exn? (λ (e) (eprintf "~a~n" e)
                                              #`(%%rash-racket-line (void)))])
                       (rash-read-syntax #f (current-input-port)))]
         [exit? (if (equal? next-input eof) (exit) #f)])
    (let* ([ret-val-list
            (call-with-values
             (λ () (with-handlers ([(λ (e) #t) (λ (e) e)])
                     (eval-syntax (parameterize ([current-namespace repl-namespace])
                                    (namespace-syntax-introduce #`(rash-line-parse
                                                                   ((current-input-port)
                                                                    (current-output-port)
                                                                    (current-error-port))
                                                                   #,next-input))))))
             list)]
           [ret-val (if (equal? (length ret-val-list)
                                1)
                        (car ret-val-list)
                        ret-val-list)]
           [new-n (add1 n)])
      (hash-set! (eval 'interactive-return-values repl-namespace)
                 new-n
                 ret-val)
      ;; Sleep just long enough to give any filter ports (eg a highlighted stderr)
      ;; to be able to output before the next prompt.
      (sleep 0.01)
      (rash-repl ret-val new-n))))

(define (eval-rashrc.rkt rcfile)
  (eval-syntax (parameterize ([current-namespace repl-namespace])
                 (namespace-syntax-introduce
                  (datum->syntax #f `(require (file ,(path->string rcfile))))))))
(define (eval-rashrc rcfile)
  (eval-syntax (parameterize ([current-namespace repl-namespace])
                 (namespace-syntax-introduce
                  #`(rash-line-parse
                     ((current-input-port)
                      (current-output-port)
                      (current-error-port))
                     #,@(rash-read-syntax-all (object-name rcfile)
                                              (open-input-file rcfile)))))))

(for ([rcfile (list-config-files #:program "rash" "rashrc.rkt")])
  (with-handlers ([(λ _ #t) (λ (ex)
                              (eprintf "error in rc file ~a: ~a"
                                       rcfile (exn->string ex)))])
    (eval-rashrc.rkt rcfile)))
(for ([rcfile (list-config-files #:program "rash" "rashrc")])
  (with-handlers ([(λ _ #t) (λ (ex)
                              (eprintf "error in rc file ~a: ~a"
                                       rcfile (exn->string ex)))])
    (eval-rashrc rcfile)))

(rash-repl (void) 0)

(printf "and now exiting for some reason~n")
