scriptencoding utf-8

if exists('g:ex_note')
    finish
endif
let g:ex_note = 1

let s:save_cpo = &cpo
set cpo&vim

" vim script

" let g:exnote_root_path= expand('%:p:h')
let g:exnote_root_path= expand('<sfile>:p:h') 
runtime lib/tag_list.vim
runtime lib/master_document.vim
runtime lib/exnote_session.vim

let g:ExnoteEventManager = {}
let g:ExnoteEventManager.listener_list = []

function! g:ExnoteEventManager.unbind(func,object)
    let l:current_buffer = bufnr("")
    let l:tmp_list = []
    for l:listener in g:ExnoteEventManager.listener_list
        if l:listener.buffer_name == l:current_buffer
            " echom "unbind buffer: " . l:listener.buffer_name
        else
            call add(l:tmp_list,l:listener)
        endif
    endfor
    let g:ExnoteEventManager.listener_list = l:tmp_list
endfunction
function! g:ExnoteEventManager.bind(func,object,id)
    let l:current_buffer = bufnr("")
    let l:listener = {}
    let l:listener.object = a:object
    let l:listener.object.func = a:func
    let l:listener.buffer_name = l:current_buffer
    let l:listener.id = a:id
    call add(g:ExnoteEventManager.listener_list, l:listener)
    nnoremap <silent> <buffer> <cr> :call g:ExnoteEventManager.gofunc()  <cr>
endfunction
function! g:ExnoteEventManager.gofunc()
    let l:current_buffer = bufnr("")
    for l:listener in g:ExnoteEventManager.listener_list
        if l:listener.buffer_name == l:current_buffer
            call l:listener.object.func()
        endif
    endfor
endfunction


function! s:Exnote()
    let self = {}
    let self.name = "exnote"
    let self.exnote_sessions = []
    
    function! self.getSession()
        " ここで開いたバッファがマスター文書クラスで管理しているか調べる
        " マスター文書クラスのリストを全部舐めて、バッファ番号が一致するか調べる
        " 現在のバッファ番号を取得する
        let l:current_buffer = bufnr("")

        let l:is_exnote_session_managed = 0
        let l:exnote_session = {}

        for exnote_session in self.exnote_sessions
            if exnote_session.isManaging(l:current_buffer)
                let l:is_exnote_session_managed = 1
                let l:exnote_session = exnote_session
                " bug-fix
                break
            endif
        endfor
        " まだ管理してなかったら管理対象に追加する
        if l:is_exnote_session_managed == 0
            let l:exnote_session = g:ExnoteSession(len(self.exnote_sessions))
            call add(self.exnote_sessions,l:exnote_session)
        endif

        " この時点でExnoteを呼び出した文書を管理しているexnote_sessionインスタンスが存在する
        return l:exnote_session
    endfunction
    
    " タグリスト開閉のトグル
    function! self.toggleTagList()
        
        let l:exnote_session = self.getSession()
        
        " exnote_sessionにタグリストをトグルさせる
        call l:exnote_session.toggleTagList()

    endfunction

    function! self.tagSearch(query)
        let l:exnote_session = self.getSession()
        call l:exnote_session.tagSearch(a:query)
    endfunction

    " 管理対象だったバッファが閉じられたら、sessionリストから削除する
    function! self.deleteBuffer()
        let l:current_buffer = self.focus_buffer
        let l:is_exnote_session_managed = 0
        let l:exnote_session = {}

        let l:tmp_list = []
        " echom "session size: " . len(self.exnote_sessions)
        " echom "curent_buffer: " . l:current_buffer
        for exnote_session in self.exnote_sessions
            if exnote_session.isManagingMaster(l:current_buffer) == 1
                " echom "管理してる" .  exnote_session.id . "が閉じられた"
            else
                call add(l:tmp_list,exnote_session)
            endif
        endfor
        let self.exnote_sessions = l:tmp_list
    endfunction

    " バッファが閉じられるタイミングでバッファ番号を取得手段がないので、
    " バッファに移動した時点でバッファ番号を保存しておく
    function! self.enterBuffer()
        let self.focus_buffer = bufnr("")
    endfunction


    return self
endfunction

let s:exnote = s:Exnote()

augroup del_buffer
    autocmd!
    autocmd BufDelete * call s:exnote.deleteBuffer()
augroup END

augroup ent_buffer
    autocmd!
    autocmd BufEnter * call s:exnote.enterBuffer()
augroup END

command! -nargs=1 ExnoteTagSearch call s:exnote.tagSearch(<args>)
command! -nargs=0 ExnoteTagList call s:exnote.toggleTagList(<args>)

" http://d.hatena.ne.jp/yk5656/20131215/1387098750
function! s:BufInfo()
  echo "\n----- バッファに関する情報 -----"
  echo "bufnr('%')=" . bufnr('%') . "	// 現在のバッファ番号"
  echo "bufnr('$')=" . bufnr('$') . "	// 最後のバッファ番号"
  echo "bufnr('#')=" . bufnr('#') . "	// 直前のバッファ番号？（仕様がよくわからない）"
  for i in range(1, bufnr('$'))
    echo  "bufexists(" . i . ")=".bufexists(i)
    echon " buflisted(" . i . ")=".buflisted(i)
    echon " bufloaded(" . i . ")=".bufloaded(i)
    echon " bufname(" . i . ")=".bufname(i)
  endfor
  echo "// bufexists(n)=バッファnが存在するか"
  echo "// buflisted(n)=バッファnがリストにあるか"
  echo "// bufloaded(n)=バッファnがロード済みか"
  echo "// bufname(n)=バッファnの名前"

  echo "\n----- ウィンドウに関する情報 -----"
  echo "winnr()="    . winnr()    . "	// 現在のウィンドウ番号"
  echo "winnr('$')=" . winnr('$') . "	// 最後のウィンドウ番号"
  echo "winnr('#')=" . winnr('#') . "	// 直前のウィンドウ番号？（仕様がよくわからない）"
  for i in range(1, winnr('$'))
    echo "winbufnr(" . i . ")=".winbufnr(i) . "	// ウィンドウ" . i . "に関連付くバッファ番号"
  endfor

  echo "\n----- タブページに関する情報 -----"
  echo "tabpagenr()="    . tabpagenr()    . '	// 現在のタブページ番号'
  echo "tabpagenr('$')=" . tabpagenr('$') . '	// 最後のタブページ番号'
  for i in range(1, tabpagenr('$'))
    echo 'tabpagebuflist(' . i . ')='
    echon tabpagebuflist(i)
    echon "	// タブページ" . i . "に関連づくバッファ番号のリスト"
  endfor
  for i in range(1, tabpagenr('$'))
    echo  'tabpagewinnr(' . i . ')=' . tabpagewinnr(i)
    echon " tabpagewinnr(" . i . ", '$')=" . tabpagewinnr(i, '$')
    echon " tabpagewinnr(" . i . ", '#')=" . tabpagewinnr(i, '#')
  endfor
  echo "// tabpagewinnr(n)     =タブページnの現在のウィンドウ番号"
  echo "// tabpagewinnr(n, '$')=タブページnの最後のウィンドウ番号"
  echo "// tabpagewinnr(n, '#')=タブページnの直前のウィンドウ番号？（仕様がよくわからない）"

endfunction
command! -nargs=0 BufInfo call s:BufInfo()


let &cpo = s:save_cpo
unlet s:save_cpo

