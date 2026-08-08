# i18n-backend-icu

[`i18n-protocol`](https://github.com/egao1980/i18n-protocol) backend over **ICU4C** via [`cl-stack-icu`](https://github.com/egao1980/cl-stack-icu) (includes MF2 shim).

## Capabilities

`:locale` `:message` `:plural` `:catalog`

```lisp
(asdf:load-system "i18n-backend-icu")
(format-message "Hello {$name}!" '(("name" . "Ada")) :locale "en")
(plural-category 1 :locale "en")  ; => :one
(let ((cat (load-catalog nil :locale "en")))
  (catalog-get cat "Version"))
```

## License

MIT
