scriptencoding utf-8

if exists('g:ex_note')
    finish
endif
let g:ex_note = 1

let s:save_cpo = &cpo
set cpo&vim

" vim script

function! Q(query)
    return '\[' . a:query . '\]'
endfunction


function! MatchLine(line, query)
    " * [xx,xx]にマッチさせる
    let s:tag_space = matchstr(a:line, '\* \[.*\]', 0)
    " [or, query ]or,にマッチさせる
    let s:query = '[\[\,]'. a:query . '[\]\,]'
    let s:matched_str = matchstr(s:tag_space, s:query)
    let s:is_matched = ( s:matched_str != '' )
    return s:is_matched
endfunction

" query 検索するタグ文字列
function! Exnote(query)
    " 開いているファイルの行数を調べる
    let line_count = line("$")
    " 全行をリストに入れる
    let s:lines = getline(1,line_count)
    
    " マッチした行を入れるためのリスト
    let s:list = []
    let s:add_flag = 0

    " 全行を調べる
    for s:line in s:lines
    
        " 行がマッチしたか
        let s:is_matched = MatchLine(s:line, a:query)

        " マッチしてたらフラグを上げる
        if s:is_matched
            let s:add_flag = 1
        endif
    
        " フラグが上がってたら追加
        " フラグは次に空白列が来るまで上がっている
        if s:add_flag == 1
            call add(s:list, s:line)
        endif
    
        " 空白列が来たらフラグをさげる
        if s:line == ''
            let s:add_flag = 0
        endif
    endfor
    
    " 新しいタブを開いて、マッチした文字を挿入する
    tabnew
    call setline(".", s:list)
endfunction

command! -nargs=1 Exnote call Exnote(<args>)

let &cpo = s:save_cpo
unlet s:save_cpo

