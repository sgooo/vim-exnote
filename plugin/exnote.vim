scriptencoding utf-8

if exists('g:ex_note')
    finish
endif
let g:ex_note = 1

let s:save_cpo = &cpo
set cpo&vim

" vim script

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

let &cpo = s:save_cpo
unlet s:save_cpo

