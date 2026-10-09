set nocompatible
filetype plugin indent on
syntax enable

" encoding
set encoding=utf-8
set fileencodings=utf-8,big5,gbk,latin1

" indentation
set tabstop=4
set shiftwidth=4
set softtabstop=4
set expandtab
set autoindent
set smartindent

" ui
set number
set ruler
set showcmd
set wildmenu
set scrolloff=5
set laststatus=2
set mouse=a
set backspace=indent,eol,start
set cursorline
set cursorcolumn
hi CursorLine cterm=underline
hi CursorColumn cterm=underline

" search
set incsearch
set hlsearch
set ignorecase
set smartcase
" clear search highlight with <Esc><Esc>
nnoremap <silent> <Esc><Esc> :nohlsearch<CR>

" behavior
set hidden
set autoread
set splitright
set splitbelow
set updatetime=300
set ttimeoutlen=0

" persistent undo, stored outside project dirs
if has('persistent_undo')
    let s:undodir = expand('~/.vim/undo')
    if !isdirectory(s:undodir)
        call mkdir(s:undodir, 'p', 0700)
    endif
    let &undodir = s:undodir
    set undofile
endif

" restore last cursor position when reopening a file
augroup RestoreCursor
    autocmd!
    autocmd BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g`\"" | endif
augroup END

" show trailing white spaces (matchadd applies to every window, unlike :match)
highlight WhitespaceEOL ctermbg=red guibg=red
augroup TrailingWhitespace
    autocmd!
    autocmd ColorScheme * highlight WhitespaceEOL ctermbg=red guibg=red
    autocmd BufWinEnter,WinEnter * if !exists('w:ws_match') | let w:ws_match = matchadd('WhitespaceEOL', '\s\+$') | endif
augroup END
