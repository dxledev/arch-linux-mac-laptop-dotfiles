; extends

((at_rule
  (at_keyword) @_directive
  (keyword_query) @constant)
  (#eq? @_directive "@apply")
  (#set! priority 125))
