

function! g:ExnoteSession(id)
    let self = {}
    let self.master_document = {}
    let self.tag_list = {}
    let self.id = -1

    function! self.ExnoteSession(id)
        let self.master_document = g:MasterDocument()
        let self.tag_list = g:TagList(a:id)
        let self.id = a:id
        call self.tag_list.addSelectTagEventListener(self.selectTag,self)
    endfunction

    function! self.selectTag(selected_tag)
        call self.tagSearch(a:selected_tag)
    endfunction

    " 自分の管理しているバッファか
    " 基本的にmaster_documentかtaglistか
    function! self.isManaging(buffer_name)
        if self.tag_list.isManaging(a:buffer_name) || self.master_document.isManaging(a:buffer_name)
            return 1
        endif
        return 0
    endfunction

    function! self.isManagingMaster(buffer_name)
        if self.master_document.isManaging(a:buffer_name) == 1
            return 1
        endif
        return 0
    endfunction

    function! self.toggleTagList()
        " すでに開いているとき
        if self.tag_list.isOpen() == 1
            " タグリストを閉じる
            call self.closeTagList()
            return
        endif
        " タグリストを開く
        call self.openTagList()
    endfunction

    " タグリストを閉じる
    function! self.closeTagList()
        call self.tag_list.close()
    endfunction

    " タグリストを開く
    function! self.openTagList()
        let l:tags =  self.master_document.getTagsInDocument()
        call self.tag_list.open(l:tags)
    endfunction

    function! self.tagSearch(query)
        let l:tags = self.master_document.tagSearch(a:query)
        " 新しいタブを開いて、マッチした文字を挿入する
        tabnew
        call setline(".", l:tags)
    endfunction
    
    call self.ExnoteSession(a:id)
    return self
endfunction
