let s:commands_cache = ['section', 'subsection', 'newcommand', 'textbf', 'texttt', 'emph', 'textit']
let s:environments_cache = ['enumerate', 'itemize', 'table', 'tabular', 'center']
let s:packages = ['inputenc', 'tikz', 'pgfplots', 'amsmath', 'geometry']
let s:cmd_pat = '\\\([^a-zA-Z]\|[a-zA-Z]\+\)\([.*]\)*\({.*}\)*'
let s:complete_dict = {
\   'begin': {-> s:environments_cache}, 
\   'end': {-> s:environments_cache}, 
\   'usepackage': {-> s:packages}}
let g:texCompleteEnvCallbacks = []


function ParseBuff()
    for line in getline(1, '$')
        let l:pos = 0
        while l:pos >= 0
            let [l:cmd, _, l:pos] = matchstrpos(line, s:cmd_pat, l:pos)
            let l:args = map(split(l:cmd, '{')[1:], 'v:val[:-1]')
            if len(l:cmd[1:]) > 0 && match(s:commands_cache, l:cmd[1:stridx(l:cmd, '{') - 1]) < 0
                if l:cmd =~ '{'
                    let s:commands_cache += [l:cmd[1:stridx(l:cmd, '{') - 1]]
                else
                    let s:commands_cache += [l:cmd[1:]]
                endif
            endif
            if l:cmd =~ "begin" && len(l:args) > 0
                let s:environments_cache += [l:args[0][:-2]]
            endif
        endwhile
    endfor
endfunction


function s:getCmd()
    return getline('.')[strridx(getline('.'), '\', col('.') - 1):col('.') - 2]
endfunction

function ComplComm(findstart, base)
    let l:bufline = getline('.')
    let l:inbufcmd = s:getCmd()
    if a:findstart
        for cmd in keys(s:complete_dict)
            if match(l:inbufcmd, '{') < 0
                continue
            endif
            let l:matchpos = matchend(l:bufline, '^\\' . cmd . '\(\[.*\]\)*{', strridx(l:bufline, '\', col('.') - 2))
            if l:matchpos > 0
                return l:matchpos
            endif
        endfor
        return strridx(getline('.'), '\', col('.') - 2) + 1
    endif

    for cmd in keys(s:complete_dict)
        if l:inbufcmd =~ '^\\' . cmd . '\(\[.*\]\)*{'
            let l:inbufcmd = s:getCmd()
            return s:complete_dict[cmd]()
        endif
    endfor
    let l:pref = a:base[strridx(a:base, '\', col('.')) + 1] 
    return filter(s:commands_cache, 'v:val =~ "^' . l:pref . '"')
endfunction


function CompleteEnv()
    if !has_key(v:completed_item, 'word') || len(v:completed_item['word']) == 0
        return
    endif
    let l:cmd = s:getCmd()
    if l:cmd ==# '\begin{' . v:completed_item['word']
        call setline('.', getline('.') . '}')
        call append('.', [repeat(' ', indent('.') + &tabstop), 
\                         repeat(' ', indent('.')) . '\end{' . v:completed_item['word'] . '}'])
        call setpos('.', [0, line('.') + 1, col('$'), 0])
        for Callback in g:texCompleteEnvCallbacks
            call Callback()
        endfor
    endif

endfunction

command! GetCmd echo s:getCmd()
command! Latex :!latexmk -pdf %
command! DumpCache echo s:commands_cache
au BufRead,InsertLeave *.tex call ParseBuff()
au CompleteDone *.tex call CompleteEnv()
imap \ \<C-X><C-O><C-P>
imap { {<C-X><C-O><C-P>
imap @. \cdot
call ParseBuff()
set omnifunc=ComplComm
source _autoitem.vim