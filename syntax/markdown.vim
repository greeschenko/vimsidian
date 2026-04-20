vim9script

syntax region WikiLink start=/\[\[/ end=/\]\]/ contains=WikiLinkOpen,WikiLinkClose,WikiLinkText keepend

syntax match WikiLinkOpen /\[\[/ contained
syntax match WikiLinkClose /\]\]/ contained
syntax match WikiLinkText /[^[\]]\+/ contained

syntax match Tag /#[a-zA-Z0-9_-]\+/

highlight default link WikiLinkOpen Comment
highlight default link WikiLinkClose Comment
highlight default link WikiLinkText Statement
highlight default link Tag Identifier

