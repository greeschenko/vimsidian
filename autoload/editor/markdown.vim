vim9script

import autoload "editor/checkbox.vim" as checkbox
import autoload "editor/list.vim" as list
import autoload "editor/visual.vim" as visual

# ----------------------------
# Public API (re-export)
# ----------------------------

# checkbox
export def ToggleCheckbox()
  checkbox.ToggleCheckbox()
enddef

export def ToggleCheckboxVisual()
  checkbox.ToggleCheckboxVisual()
enddef

export def MakeCheckbox()
  checkbox.MakeCheckbox()
enddef

# list
export def ContinueList(): string
  return list.ContinueList()
enddef

# visual formatting
export def ToggleBold()
  visual.ToggleBold()
enddef

export def ToggleItalic()
  visual.ToggleItalic()
enddef

export def ToggleCode()
  visual.ToggleCode()
enddef

export def ToggleCodeBlock()
  visual.ToggleCodeBlock()
enddef

export def ToggleHeading(level: number)
  visual.ToggleHeading(level)
enddef

export def ToggleQuote()
  visual.ToggleQuote()
enddef

export def ToggleList()
  visual.ToggleList()
enddef
