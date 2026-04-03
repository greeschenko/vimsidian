vim9script

syntax region WikiLink start=/\[\[/ end=/\]\]/ contains=WikiLinkOpen,WikiLinkClose,WikiLinkText keepend

syntax match WikiLinkOpen /\[\[/ contained
syntax match WikiLinkClose /\]\]/ contained
syntax match WikiLinkText /[^[\]]\+/ contained

highlight default link WikiLinkOpen Comment
highlight default link WikiLinkClose Comment
highlight default link WikiLinkText Statement

