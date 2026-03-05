syntax enable
set tabstop=4
set shiftwidth=4
set expandtab
set cursorline
set cursorcolumn
hi CursorLine cterm=underline
hi CursorColumn cterm=underline

" show trailing white spaces
highlight WhitespaceEOL ctermbg=red guibg=red
match WhitespaceEOL /\s\+$/
