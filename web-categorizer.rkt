#lang racket/base
(require racket/file
         racket/list
         racket/string
         racket/system
         racket/format
         racket/contract)

;;; purpose

; to categorize a web page based on its text, using llama.cpp and a 7B or 13B open source model

;;; consts

(define ROOT_PATH                "/Users/dextersantucci/Projects/Cpp/llama.cpp/")
(define MODEL_NAME               "Wizard-Vicuna-13B-Uncensored.ggmlv3.q4_0.bin")
(define PROMPT_PATH              "prompts/web-text-url.txt")

(define COMMAND_LINE_PREFIX      " ") ; -ins
(define COMMAND_LINE_SETTINGS    " --threads 4 --temp 0")
(define COMMAND_LINE_MODEL       " --model ")
(define COMMAND_LINE_PROMPT      " --prompt ")

;; gathers the main binary's full path

;; returns a command line to run the categorization
;; model filepath i.e.: ./models/13B/ggml-vicuna-13b-4bit.bin
(define/contract (make-command-line main-filepath model-filepath prompt)
  (non-empty-string? non-empty-string? non-empty-string? . -> . non-empty-string?)
  (~a main-filepath
      COMMAND_LINE_PREFIX
      COMMAND_LINE_SETTINGS
      COMMAND_LINE_MODEL  model-filepath
      COMMAND_LINE_PROMPT prompt))

;; categorize a web text, given the text and its URL
(define/contract (categorize url web-text)
  (non-empty-string? non-empty-string? . -> . string?)
  (define prompt
    (string-append "\"Categorize the following text using a single word. Here is the text: "
                   web-text
                   " Category: \""))
  (define command-line
    (make-command-line main-filepath model-filepath prompt))
  ;(displayln (~a "Running command line: " command-line))
  (define-values (output err)
    (system->ports command-line))
  ; separate prompt from answer, return answer
  (define prompt-parts (string-split output "Category: "))
  (string-append url ": " (string-replace (last prompt-parts)
                                         "\n" "")))

;; redirect output and error ports to string, returning both as values
(define (system->ports command)
  (let ((out (open-output-string))
        (err (open-output-string)))
    (parameterize ((current-output-port out)
                   (current-error-port err))
      (system command)
      (values (get-output-string out)
              (get-output-string err)))))
; unit test
;(define-values (output err)
;  (system->ports "notepad.exe"))

;; returns the URL and Web text contained in a custom prompt fole
;; returns two values. (define-values (url web-text) (get-web-test-and-url prompt-filepath))
(define (get-web-test-and-url prompt-filepath)
  (define lines
    (file->lines prompt-filepath))
  (values (car lines)
          (string-join (cdr lines) "\n")))

;;; main

(define main-filepath
  (~a ROOT_PATH "main"))

(define prompt-filepath
  (~a ROOT_PATH PROMPT_PATH))

(define model-filepath
  (~a ROOT_PATH "models/13B/" MODEL_NAME))

; extract url and web text
(define-values (url web-text)
  (get-web-test-and-url prompt-filepath))

; categorize!
(categorize url web-text)


; EOF
