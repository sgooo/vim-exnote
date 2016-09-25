

function! g:ExnoteSession()
    let self = {}
    " タグリストを開いているかフラグ
    let self.is_exnote_tag_list_open = 0
    let self.master_document = {}
    let self.tag_list = {}

    function! self.ExnoteSession()
        echom "exnotesession construct"
        let self.master_document = g:MasterDocument()
        let self.tag_list = g:TagList()
        call self.tag_list.addSelectTagEventListener(self.selectTag,self)
    endfunction

    function! self.selectTag(selected_tag)
        echom "コールバック"
        call self.TagSearchExt(a:selected_tag)
    endfunction

    " 自分の管理しているバッファか
    " 基本的にmaster_documentかtaglistか
    function! self.isManaging(buffer_name)
        if self.tag_list.isManaging(a:buffer_name) || self.master_document.isManaging(a:buffer_name)
            return 1
        endif
        return 0
    endfunction

    function! self.toggleTagList()
        " すでに開いているとき
        if self.is_exnote_tag_list_open == 1
            " タグリストを閉じる
            call self.closeTagList()
            " タグリストを開いているフラグを落とす
            let self.is_exnote_tag_list_open = 0
            return
        endif
        " タグリストを開く
        call self.openTagList()
        " タグリストを開いているフラグを立てる
        let self.is_exnote_tag_list_open = 1
    endfunction

    " タグリストを閉じる
    function! self.closeTagList()
        call self.tag_list.close()
    endfunction

    " タグリストを開く
    function! self.openTagList()
        let l:tags =  self.master_document.getTagsInDocument()
        " 本文を開いているバッファ番号を保存
        
        let self.body_buffer_name = bufnr("")
        call self.tag_list.open(l:tags)
    endfunction

    
    function! self.TagSearchExt(query)
        echom "TagSearchExt"
        let l:query = a:query
        let s:body_win_name = bufwinnr(self.body_buffer_name)
        " ウィンドウ移動
        exec(s:body_win_name.' wincmd w')
    
        call self.master_document.tagSearch(l:query)
    endfunction

    function! self.tagSearch(query)
        call self.master_document.tagSearch(a:query)
    endfunction
    
    call self.ExnoteSession()
    return self
endfunction
