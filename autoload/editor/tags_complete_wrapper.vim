vim9script

import autoload "editor/tags_complete.vim" as tc

export def TagCompleteWrapper(findstart: number, base: string): any
  return tc.TagComplete(findstart, base)
enddef

defcompile