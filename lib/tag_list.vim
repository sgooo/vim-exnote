

function! g:TagList()
    let self = {}
    " タグリストを開いているバッファ
    let self.tag_list_buffer_name = -1
    let self.callbackfunc = {}
    let self.callbackobj = {}

    " 自分の管理しているバッファまで移動して、自分で閉じる
    function! self.close()
        if self.tag_list_buffer_name >= 0
            " タグリストが開いているバッファのウィンドウ番号
            let s:tag_list_win_name = bufwinnr(self.tag_list_buffer_name)
            " ウィンドウ移動
            exec(s:tag_list_win_name.' wincmd w')
            " 閉じる
            " close
            q!
        endif
    endfunction

    function! self.open(tag_list)
        let l:tag_list = a:tag_list
        vnew
        vertical resize 30
    
        " １行目から追加する
        let l:tag_list_count = 1
        for tag in l:tag_list
            call setline(l:tag_list_count, tag[0]." (".tag[1].")")
            let l:tag_list_count += 1
        endfor
        " タグリストを開いたバッファ番号を保存
        let self.tag_list_buffer_name = bufnr("")

        " ここはsessionがコールバックを受けるような作りにしたい
        " call g:ExnoteEventManager.setEvent(self.TagSearchExt,self)
        call g:ExnoteEventManager.setEvent(self.onEnter,self)
    endfunction

    function! self.onEnter()
        " 選択した行の文字列を取得
        let l:selected_line = getline(".")
        let l:query = split(l:selected_line," ")[0]

        call self.callbackobj.func(l:query)
    endfunction

    function! self.addSelectTagEventListener(func,instance)
        let self.callbackobj = a:instance
        let self.callbackobj.func = a:func
    endfunction

    function! self.isManaging(buffer_name)
        if self.tag_list_buffer_name == a:buffer_name
            return 1
        endif
        return 0
    endfunction

    return self
endfunction

