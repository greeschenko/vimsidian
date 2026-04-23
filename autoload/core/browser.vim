vim9script

export def OpenInNewWindow(url: string)
    var cmd = GetBrowserCommand()
    if empty(cmd)
        var fallback = GetFallbackCommand()
        system(fallback .. ' ' .. fnameescape(url) .. ' &')
        return
    endif
    system(cmd .. ' ' .. fnameescape(url) .. ' &')
enddef

def GetBrowserCommand(): string
    if has('macunix')
        return GetMacCommand()
    elseif has('win32')
        return GetWindowsCommand()
    elseif has('unix')
        return GetLinuxCommand()
    endif
    return ''
enddef

def GetFallbackCommand(): string
    if has('macunix')
        return 'open'
    elseif has('win32')
        return 'start'
    endif
    return 'xdg-open'
enddef

def GetLinuxCommand(): string
    if executable('firefox')
        return 'firefox --new-window'
    elseif executable('google-chrome')
        return 'google-chrome --new-window'
    elseif executable('chrome')
        return 'chrome --new-window'
    elseif executable('chromium')
        return 'chromium --new-window'
    elseif executable('chromium-browser')
        return 'chromium-browser --new-window'
    endif
    return ''
enddef

def GetMacCommand(): string
    if executable('Firefox')
        return 'open -a Firefox --args --new-window'
    elseif executable('Google Chrome')
        return 'open -a "Google Chrome" --args --new-window'
    elseif executable('Chromium')
        return 'open -a Chromium --args --new-window'
    endif
    return ''
enddef

def GetWindowsCommand(): string
    if executable('firefox')
        return 'start firefox -new-window'
    elseif executable('chrome')
        return 'start chrome --new-window'
    endif
    return ''
enddef

defcompile