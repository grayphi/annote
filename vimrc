" load global configuration
source /etc/vimrc

" highlighting comments for annote notes
" comments defination: <start>@<number|range>!<space><string>
"   empty: <>
"   space: < >
"   integer: <[0-9]+>
"   string: <.*>
"   start: (<empty>|<##>)
"   number: (<integer>|<integer.number>)
"   range: (<number-number>|<number-*>)
"
highlight cmnts ctermfg=DarkGrey
match cmnts /^\s*\(##\)\?@[0-9.*-]*! .*/

" highlights for sub heading and back references
" subheading defination: #@<number> <string>
"   integer: <[0-9]+>
"   string: <.*>
"   number: (<integer.number>)
"
" numeral back reference defination: @{<number>}
"   integer: <[0-9]+>
"   number: (<integer>|<integer.number>)
"
" string back reference defination: @[<string>]
"   string: <[^]]*>
"
highlight subheads ctermfg=DarkGreen
2match subheads /\(^\s*#@[0-9]\+[0-9.]*[0-9]\+ .*\|@{[0-9.]\+}\|@\[[^]]\+\]\|@[(][^)]\+[)]\)/

