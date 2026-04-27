vim9script

import autoload 'ui/graph/domain/graph_state.vim' as domain
import autoload 'ui/graph/infrastructure/window.vim' as window

export def ToggleGraphPanel()
  if window.GetWindowId() != -1
    window.CloseWindow()
  else
    window.OpenWindow()
  endif
enddef

export def OpenGraphPanel()
  window.OpenWindow()
enddef

export def CloseGraphPanel()
  window.CloseWindow()
enddef

export def UpdateGraph()
  if window.GetWindowId() == -1
    return
  endif
  domain.LoadFromCurrentNote()
  window.Render()
enddef

defcompile