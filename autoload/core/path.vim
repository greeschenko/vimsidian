vim9script

import autoload 'core/vault.vim'

# ----------------------------
# Slug
# ----------------------------

def Transliterate(text: string): string
  var map = {
    'а': 'a', 'б': 'b', 'в': 'v', 'г': 'h', 'ґ': 'g',
    'д': 'd', 'е': 'e', 'є': 'ie', 'ж': 'zh', 'з': 'z',
    'и': 'y', 'і': 'i', 'ї': 'i', 'й': 'i',
    'к': 'k', 'л': 'l', 'м': 'm', 'н': 'n',
    'о': 'o', 'п': 'p', 'р': 'r', 'с': 's',
    'т': 't', 'у': 'u', 'ф': 'f', 'х': 'kh',
    'ц': 'ts', 'ч': 'ch', 'ш': 'sh', 'щ': 'shch',
    'ь': '', 'ю': 'iu', 'я': 'ia'
  }

  var result = ''
  for ch in split(tolower(text), '\zs')
    result ..= get(map, ch, ch)
  endfor

  return result
enddef

def Slugify(title: string): string
  var slug = Transliterate(title)

  slug = substitute(slug, '\s\+', '-', 'g')
  slug = substitute(slug, '[^a-z0-9_-]', '', 'g')
  slug = substitute(slug, '-\+', '-', 'g')
  slug = substitute(slug, '^-', '', '')
  slug = substitute(slug, '-$', '', '')

  if empty(slug)
    slug = strftime('%Y%m%d%H%M%S')
  endif

  return slug
enddef

export def SlugifyPath(path: string): string
  var parts = split(path, '/')
  var result = []

  for i in range(len(parts))
    if i == len(parts) - 1
      add(result, Slugify(parts[i]))
    else
      add(result, parts[i])
    endif
  endfor

  return join(result, '/')
enddef

# ----------------------------
# Note identity
# ----------------------------

export def GetNoteId(path: string): string
  var rel = substitute(path, '^' .. vault.GetDataPath() .. '/', '', '')
  return substitute(rel, '\.md$', '', '')
enddef

export def NormalizeNotePath(path: string): string
  return GetNoteId(path)
enddef

# ----------------------------
# Resolve
# ----------------------------

export def ResolveLink(link: string): string
  var slug = SlugifyPath(link)
  return vault.GetDataPath() .. '/' .. slug .. '.md'
enddef

defcompile
