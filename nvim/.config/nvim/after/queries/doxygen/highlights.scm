; extends

((tag
  (tag_name) @_return
  (description) @comment.documentation.return)
 (#any-of? @_return "@return" "\\return" "@returns" "\\returns")
 (#doxygen-first-token! @comment.documentation.return)
 (#set! priority 110))

; A return without an earlier block tag remains part of the brief description.
((brief_description
  (tag_name) @_return
  (brief_text) @comment.documentation.return)
 (#any-of? @_return "@return" "\\return" "@returns" "\\returns")
 (#doxygen-first-token! @comment.documentation.return)
 (#set! priority 110))
