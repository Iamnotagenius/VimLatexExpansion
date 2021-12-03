let s:begin = '\\begin{\(enumerate\|itemize\)}'
let s:end = '\\end{\(enumerate\|itemize\)}'

function s:onEnvInsert()
    if v:completed_item['word'] !~ '\(enumerate\|itemize\)'
        return
    endif
	call setline('.', getline('.') . '\item ')
    call setpos('.', [0, line('.'), col('$'), 0])
    inoremap <CR> <CR>\item 
endfunction

function s:detectItemEnv()
    call setline('$', mapcheck('<CR>', 'i'))
    let l:balance = 0
    for line in map(range(line('.'), 1, -1), {_, val -> getline(val)})
        if line =~ s:begin
            let l:balance += 1
        elseif line =~ s:end
            let l:balance -= 1
        endif
    endfor

    if l:balance <= 0 
        if len(mapcheck('<CR>', 'i')) > 0
            iunmap <CR>
        endif
    else
        inoremap <CR> <CR>\item 
    endif
endfunction

au CursorMoved,CursorMovedI *.tex call s:detectItemEnv()
let g:texCompleteEnvCallbacks += [function('s:onEnvInsert')]