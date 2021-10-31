#!/usr/bin/env bash

###############################################################################
#                     ANNOTATE (terminal notes command)
###############################################################################

__NAME__="annote"
__VERSION__="1.08"

# variables
c_red="$(tput setaf 196)"
c_cyan="$(tput setaf 44)"
c_light_green_2="$(tput setaf 10)"
c_yellow="$(tput setaf 190)"
c_orange="$(tput setaf 202)"
c_light_blue="$(tput setaf 42)"
c_light_green="$(tput setaf 2)"
c_light_red="$(tput setaf 9)"

b_black="$(tput setab 16)"
b_dark_black="$(tput setab 233)"
b_light_black="$(tput setab 236)"

s_bold="$(tput bold)"
s_dim="$(tput dim)"
s_underline="$(tput smul)"

p_reset="$(tput sgr0)"

config_file="$(realpath ~)/.annote/annote.config"
u_conf_file=""
declare -A kv_conf_var=()
db_loc="$(realpath ~)/.annote/db"
notes_loc="$db_loc/notes"
groups_loc="$db_loc/groups"
tags_loc="$db_loc/tags"
def_group="default"
def_tag="default"
editor="vi"
editor_gui="gedit"
list_delim="  "
list_fmt="<SNO><DELIM><NID><DELIM><TITLE>"
archived="ARCHIVED"

declare -A mutex_ops=()
declare -A mutex_ops_args=()

flag_new_arg4=""            # empty for editor, r -> record script, c -> content, f -> file
flag_modify_arg2=""         # empty for editor, r -> record script, c -> content, f -> file
flag_append_mode="y"        # 'y' --> append, empty to overwrite
flag_gui_editor=""          # 'y' --> use gui editor, empty use cli
flag_disable_warnings=""    # 'y' --> disable warnings, empty to enable
flag_verbose=""             # 'y' --> be verbose, empty no verbose
flag_no_ask=""              # 'y' --> no ask, empty to ask
flag_no_pretty=""           # 'y' --> no pretty, empty to prettify
flag_no_pager=""            # 'y' --> no pager, empty to use pager
flag_nosafe_grpdel=""       # 'y' --> enable nosafe, empty for safe
flag_open_noedit=""         # 'y' --> view only pager, empty to edit
flag_modify_tag_mode=""     # 'o' --> overwrite, 'd' -->delete, 'a' or empty append
flag_search_mode=""         # 't' --> title only, 'n' --> note only, blank to search on both
flag_strict_find=""         # 'y' --> to matches strictly, blank for anywhere search
flag_list_find=""           # 'y' --> to show list of notes not count, blank for count
flag_show_archived=""       # 'y' --> include archived notes into list/find, blank to exclude
flag_debug_mutex_ops=""     # 'y' --> enable mutex multi opts execution, PS: supplying multi opts can creates confusion.

ERR_CONFIG=1
ERR_DATE=2
ERR_MUTEX_OPTS=3
ERR_ARCH=4

function __cont {
    echo "$(echo "$1" | sed -e "s/${p_reset/[/\\[}/$p_reset$2/g")"
}

function _color {
    echo "$2$(__cont "$1" "$2")$p_reset"
}

function as_red {
    echo "$(_color "$1" "$c_red")"
}

function as_cyan {
    echo "$(_color "$1" "$c_cyan")"
}

function as_yellow {
    echo "$(_color "$1" "$c_yellow")"
}

function as_orange {
    echo "$(_color "$1" "$c_orange")"
}

function as_light_blue {
    echo "$(_color "$1" "$c_light_blue")"
}

function as_light_green {
    echo "$(_color "$1" "$c_light_green")"
}

function as_light_green_2 {
    echo "$(_color "$1" "$c_light_green_2")"
}

function as_light_red {
    echo "$(_color "$1" "$c_light_red")"
}

function on_black {
    echo "$(_color "$1" "$b_black")"
}

function on_light_black {
    echo "$(_color "$1" "$b_light_black")"
}

function on_dark_black {
    echo "$(_color "$1" "$b_dark_black")"
}

function as_bold {
    echo "$(_color "$1" "$s_bold")"
}

function as_dim {
    echo "$(_color "$1" "$s_dim")"
}

function as_underline {
    echo "$(_color "$1" "$s_underline")"
}

function log_error {
    log "$(as_bold "$(as_red 'ERROR')")"  "$*"  >&2
}

function log_info {
    log "$(as_cyan 'INFO')" "$*"
}

function log_warn {
    if [ "x$flag_disable_warnings" != "xy" ]; then
        log "$(as_light_red 'WARN')" "$*"
    fi
}

function log {
    local sym="$(as_bold "$(as_light_blue '*')" )"
    if [ $# -eq 2 ]; then
        sym="$1"
        shift
    fi
    log_plain "[$sym]: $*" 
}

function log_plain {
    echo -e "$*"
}

function log_verbose {
    if [ "x$flag_verbose" = "xy" ]; then
        log "$*"
    fi
}

function log_verbose_info {
    if [ "x$flag_verbose" = "xy" ]; then
        log_info "$*"
    fi
}

function prompt {
    echo "$(log "$(as_cyan "$1")")"
}

function prompt_error {
    echo "$(log "$(as_red "$(as_bold "$1")")")"
}

function __banner__ {
    as_light_green_2 ''
    as_light_green_2 '  █████╗ ███╗   ██╗███╗   ██╗ ██████╗ ████████╗ █████╗ ████████╗███████╗'
    as_light_green_2 ' ██╔══██╗████╗  ██║████╗  ██║██╔═══██╗╚══██╔══╝██╔══██╗╚══██╔══╝██╔════╝'
    as_light_green_2 ' ███████║██╔██╗ ██║██╔██╗ ██║██║   ██║   ██║   ███████║   ██║   █████╗  '
    as_light_green_2 ' ██╔══██║██║╚██╗██║██║╚██╗██║██║   ██║   ██║   ██╔══██║   ██║   ██╔══╝  '
    as_light_green_2 ' ██║  ██║██║ ╚████║██║ ╚████║╚██████╔╝   ██║   ██║  ██║   ██║   ███████╗'
    as_light_green_2 " $(as_underline '╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═══╝ ╚═════╝    ╚═╝   ╚═╝  ╚═╝   ╚═╝   ╚══════╝')"
    log_plain "$(as_orange "                              $__NAME__ (v$__VERSION__)")"
}

function help {
    local idnt_l1="$1"
    local idnt_sc1="$idnt_l1   "
    local idnt_sc2="$idnt_sc1   "
    local idnt_sc3="$idnt_sc2   "
    local fsep_1="\t"
    local fsep_2="$fsep_1\t"
    local fsep_3="$fsep_2\t"
    local fsep_4="$fsep_3\t"

    log_plain "${idnt_l1}$(as_bold " -h")|$(as_bold "--help")${fsep_3}Show help and exit."
    log_plain "${idnt_l1}$(as_bold " --info")${fsep_4}Show information and exit."
    log_plain "${idnt_l1}$(as_bold " -V")|$(as_bold "--version")${fsep_3}Show version and exit."
    log_plain "${idnt_l1}$(as_bold " -v")|$(as_bold "--verbose")${fsep_3}Be verbose."
    log_plain "${idnt_l1}$(as_bold " -D")|$(as_bold "--silent")${fsep_3}Be silent, don't ask questions, use $(as_dim "default") values whenever required."
    log_plain "${idnt_l1}$(as_bold " -q")|$(as_bold "--quite")${fsep_3}Disable warning messages to print."
    log_plain "${idnt_l1}$(as_bold " --strict")${fsep_3}Use strict comparisions, exact matches. Effects $(as_bold "find") action."
    log_plain "${idnt_l1}$(as_bold " --gui")${fsep_4}Use GUI Editor when editing note. Effects $(as_bold "new"), and $(as_bold "modify") actions."
    log_plain "${idnt_l1}$(as_bold " --no-pretty")${fsep_3}Do not prettify output."
    log_plain "${idnt_l1}$(as_bold " --stdout")${fsep_3}Do not use pager, just put everything on $(as_bold "stdout")."
    log_plain "${idnt_l1}$(as_bold " --inc-arch")${fsep_3}Include archived notes, default is to exclude. Effects $(as_bold "list") and $(as_bold "find") actions."
    log_plain "${idnt_l1}$(as_bold " --delim") [$(as_bold "$(as_light_green "delimiter")")]${fsep_2}Use $(as_bold "$(as_light_green "delimiter")") to delimit the list output fields."
    log_plain "${idnt_l1}$(as_bold " --format") [$(as_bold "$(as_light_green "format")")]${fsep_2}Create custom $(as_underline "note listing") format with $(as_dim "$(as_underline "<SNO>")"),$(as_dim "$(as_underline "<NID>")"),$(as_dim "$(as_underline "<TITLE>")"),$(as_dim "$(as_underline "<TAGS>")"),$(as_dim "$(as_underline "<GROUP>")"),$(as_dim "$(as_underline "<DELIM>")")."

    log_plain "${idnt_l1}$(as_bold " -C")|$(as_bold "--config")${fsep_3}Manages config, if specified, then atleast one option has to be supplied."
    log_plain "${idnt_sc1}$(as_bold " -i")|$(as_bold "--import") [$(as_bold "$(as_light_green "file")")]${fsep_2}Import config from $(as_bold "$(as_light_green "file")")."
    log_plain "${idnt_sc1}$(as_bold " -x")|$(as_bold "--export") [$(as_bold "$(as_light_green "file")")]${fsep_2}Export config to $(as_bold "$(as_light_green "file")")."
    log_plain "${idnt_sc1}$(as_bold " -u")|$(as_bold "--use") [$(as_bold "$(as_light_green "file")")]${fsep_2}Use $(as_bold "$(as_light_green "file")") as current instance's config."
    log_plain "${idnt_sc1}$(as_bold " -s")|$(as_bold "--set") [$(as_bold "$(as_light_green "'key=value'")")]${fsep_1}Overrides $(as_bold "$(as_light_green "key")") in current instance, repeat $(as_bold "set") to override more $(as_bold "$(as_light_green "key")")s."
    
    log_plain "${idnt_l1}$(as_bold " -n")|$(as_bold "--new")${fsep_3}Add new Note. If no sub options suplied then this will assume $(as_dim "defaults") or $(as_dim "ask")."
    log_plain "${idnt_sc1}$(as_bold " -t")|$(as_bold "--title") [$(as_bold "$(as_light_green "title")")]${fsep_2}Title of note. (required)"
    log_plain "${idnt_sc1}$(as_bold " -g")|$(as_bold "--group") [$(as_bold "$(as_light_green "group")")]${fsep_2}Group for note (use '$(as_bold ".")' for subgroups). Uses $(as_dim "default") group, if not specified."
    log_plain "${idnt_sc1}$(as_bold " -T")|$(as_bold "--tag") [$(as_bold "$(as_light_green "tags")")]${fsep_2}Tags for note (use '$(as_bold ",")' for multiple tags). Uses $(as_dim "default") tag, if not specified."
    log_plain "${idnt_sc1}$(as_bold " -r")|$(as_bold "--record")${fsep_3}Record terminal activity as note, invokes the $(as_dim "$(as_underline "script")") command."
    log_plain "${idnt_sc1}$(as_bold " -c")|$(as_bold "--content") [$(as_bold "$(as_light_green "content")")]${fsep_1}Use $(as_bold "$(as_light_green "content")") as note's content."
    log_plain "${idnt_sc1}$(as_bold " -f")|$(as_bold "--file") [$(as_bold "$(as_light_green "file")")]${fsep_2}Record $(as_bold "$(as_light_green "file")") as note's content, use '$(as_bold "-")' to record from $(as_bold "stdin")"

    log_plain "${idnt_l1}$(as_bold " -l")|$(as_bold "--list")${fsep_3}List out notes from db. Output controlling options can affects it's output."

    log_plain "${idnt_l1}$(as_bold " -e")|$(as_bold "--erase")|$(as_bold "--delete")"
    log_plain "${idnt_sc1}$(as_bold "--note") [$(as_bold "$(as_light_green "nid")")]${fsep_3}Delete note $(as_bold "$(as_light_green "nid")")(id)."
    log_plain "${idnt_sc1}$(as_bold "--group") [$(as_bold "$(as_light_green "gname")")]${fsep_2}Delete group $(as_bold "$(as_light_green "gname")")(fully qualified name), and assign $(as_dim "default") group to notes."
    log_plain "${idnt_sc1}$(as_bold "--group-nosafe") [$(as_bold "$(as_light_green "gname")")]${fsep_1}Delete group $(as_bold "$(as_light_green "gname")")(fully qualified name), also deletes the notes belongs to it."
    log_plain "${idnt_sc1}$(as_bold "--tag") [$(as_bold "$(as_light_green "tname")")]${fsep_2}Delete tag $(as_bold "$(as_light_green "tname")"), assign $(as_dim "default") tag, if this was only tag to that note."

    log_plain "${idnt_l1}$(as_bold " -o")|$(as_bold "--open") [$(as_bold "$(as_light_green "nid")")]${fsep_2}Open note $(as_bold "$(as_light_green "nid")")(id) in editor."
    log_plain "${idnt_sc1}$(as_bold "--no-edit")${fsep_3}Use pager instead of editor to open."
    
    log_plain "${idnt_l1}$(as_bold " -m")|$(as_bold "--modify")|$(as_bold "--edit") [$(as_bold "$(as_light_green "nid")")]${fsep_1}Edit note $(as_bold "$(as_light_green "nid")")(id), if none from $(as_dim "-r"),$(as_dim "-c"),$(as_dim "-f") are present, then open note with editor."
    log_plain "${idnt_sc1}$(as_bold " -t")|$(as_bold "--title") [$(as_bold "$(as_light_green "title")")]${fsep_2}Modify title of note."
    log_plain "${idnt_sc1}$(as_bold " -g")|$(as_bold "--group") [$(as_bold "$(as_light_green "group")")]${fsep_2}Modify group of note (use '$(as_bold ".")' for subgroups)."
    log_plain "${idnt_sc1}$(as_bold " -T")|$(as_bold "--tag") [$(as_bold "$(as_light_green "tags")")]${fsep_2}Modify tags of note (use '$(as_bold ",")' for multiple tags)."
    log_plain "${idnt_sc2}$(as_bold "--append")${fsep_3}Append new tags. (default)"
    log_plain "${idnt_sc2}$(as_bold "--overwrite")${fsep_2}Overwrite with new tags."
    log_plain "${idnt_sc2}$(as_bold "--delete")${fsep_3}Delete $(as_bold "$(as_light_green "tags")"), if present, and assign $(as_dim "default") tag, if note left with no tags."
    log_plain "${idnt_sc1}$(as_bold " -r")|$(as_bold "--record")${fsep_3}Record terminal activity as note, invokes the $(as_dim "$(as_underline "script")") command."
    log_plain "${idnt_sc1}$(as_bold " -c")|$(as_bold "--content") [$(as_bold "$(as_light_green "content")")]${fsep_1}Use $(as_bold "$(as_light_green "content")") as note's content."
    log_plain "${idnt_sc1}$(as_bold " -f")|$(as_bold "--file") [$(as_bold "$(as_light_green "file")")]${fsep_2}Record $(as_bold "$(as_light_green "file")") as note's content, use '$(as_bold "-")' to record from $(as_bold "stdin")"
    log_plain "${idnt_sc1}$(as_bold " -O")|$(as_bold "--no-append")|$(as_bold "--overwrite")${fsep_1}Do not append to note, and overwrite with new content."

    log_plain "${idnt_l1}$(as_bold " -F")|$(as_bold "--find")|$(as_bold "--search")${fsep_2}Search and list. Output controlling or strict options can affects it's behaviour."
    log_plain "${idnt_sc1}$(as_bold "--tags") [$(as_bold "$(as_light_green "pattern")")]${fsep_2}Search Tags with matching $(as_bold "$(as_light_green "pattern")"), and display number of notes belong to them."
    log_plain "${idnt_sc2}$(as_bold "--list")${fsep_3}Display all notes instead of count of notes."
    log_plain "${idnt_sc1}$(as_bold "--group") [$(as_bold "$(as_light_green "pattern")")]${fsep_2}Search Groups with matching $(as_bold "$(as_light_green "pattern")"), and display number of notes belong to them."
    log_plain "${idnt_sc2}$(as_bold "--list")${fsep_3}Display all notes instead of count of notes."
    log_plain "${idnt_sc1}$(as_bold "--note") [$(as_bold "$(as_light_green "pattern")")]${fsep_2}Search notes title & content for matching $(as_bold "$(as_light_green "pattern")")."
    log_plain "${idnt_sc2}$(as_bold "--title-only")${fsep_2}Limit searching of $(as_bold "$(as_light_green "pattern")") to notes title only."
    log_plain "${idnt_sc2}$(as_bold "--note-only")${fsep_2}Limit searching of $(as_bold "$(as_light_green "pattern")") to notes content only."
    log_plain "${idnt_sc2}$(as_bold "--with-tags") [$(as_bold "$(as_light_green "tags")")]${fsep_1}Filter notes with $(as_bold "$(as_light_green "tags")")."
    log_plain "${idnt_sc2}$(as_bold "--with-group") [$(as_bold "$(as_light_green "group")")]${fsep_1}Filter notes with $(as_bold "$(as_light_green "group")")."
    log_plain "${idnt_sc2}$(as_bold "--created-on") <$(as_bold "$(as_light_green "date")")>${fsep_1}Filter notes with created on $(as_bold "$(as_light_green "date")"). $(as_bold "$(as_light_green "date")") and $(as_dim "sub-options") are mutually exclusive." 
    log_plain "${idnt_sc3}$(as_bold "--before") [$(as_bold "$(as_light_green "date")")]${fsep_1}Filter notes that are created before $(as_bold "$(as_light_green "date")")."
    log_plain "${idnt_sc3}$(as_bold "--after") [$(as_bold "$(as_light_green "date")")]${fsep_2}Filter notes that are created after $(as_bold "$(as_light_green "date")")."
    log_plain "${idnt_sc2}$(as_bold "--last-edit") <$(as_bold "$(as_light_green "date")")>${fsep_1}Filter notes with modified on $(as_bold "$(as_light_green "date")"). $(as_bold "$(as_light_green "date")") and $(as_dim "sub-options") are mutually exclusive." 
    log_plain "${idnt_sc3}$(as_bold "--before") [$(as_bold "$(as_light_green "date")")]${fsep_1}Filter notes that are modified before $(as_bold "$(as_light_green "date")")."
    log_plain "${idnt_sc3}$(as_bold "--after") [$(as_bold "$(as_light_green "date")")]${fsep_2}Filter notes that are modified after $(as_bold "$(as_light_green "date")")."

    log_plain "${idnt_l1}$(as_bold " --archive") [$(as_bold "$(as_light_green "nid")")]${fsep_2}Archive note $(as_bold "$(as_light_green "nid")")(id)."
    log_plain "${idnt_l1}$(as_bold " --unarchive") [$(as_bold "$(as_light_green "nid")")]${fsep_2}Unarchive note $(as_bold "$(as_light_green "nid")")(id)."
    log_plain "${idnt_l1}$(as_bold " --list-archive")${fsep_3}List archived notes."
}

function _info {
    __banner__
    log_plain "\n$(as_bold "[$(as_yellow "NAME")]")"
    log_plain "\t$(as_underline "$(as_bold "Annotate") Terminal based notes managing utility for GNU/Linux OS.")"

    log_plain "\n$(as_bold "[$(as_yellow "SYNOPSIS")]")"
    log_plain "\t$(as_bold "annote") $(as_underline "OPTIONS")"

    log_plain "\n$(as_bold "[$(as_yellow "DESCRIPTION")]")"
    log_plain "\tYou can take note from terminal, or GUI, Capture file into note, or record script or pipe" 
    log_plain "\tcommands output to it to save for later, it can does that."
    log_plain "\t$(as_dim "\"Take notes from wherever, whenever, orcestrate in any way, and it does the thing 'notes' ")"
    log_plain "\t$(as_dim "are supposed to do so, whenever, wherever, however it doen't make any difference.\"")"
    log_plain "\tIt's not an App that works in isolation, it's utility, that works in integration to terminal."

    log_plain "\n$(as_bold "[$(as_yellow "OPTIONS")]")"
    help '\t'

    log_plain "\n$(as_bold "[$(as_yellow "EXIT STATUS")]")"
    log_plain "\t$(as_bold "annote") exits with status $(as_bold "0") as success, greater than $(as_bold "0") if errors occur."
    log_plain "\t$(as_underline "EXIT CODE"): $(as_bold "0") means success."
    log_plain "\t$(as_underline "EXIT CODE"): $(as_bold "$ERR_CONFIG") means 'configuration' related error."
    log_plain "\t$(as_underline "EXIT CODE"): $(as_bold "$ERR_DATE") means 'date' related error."
    log_plain "\t$(as_underline "EXIT CODE"): $(as_bold "$ERR_MUTEX_OPTS") means mutex options provided."
    log_plain "\t$(as_underline "EXIT CODE"): $(as_bold "$ERR_ARCH") means error during archive/unarchive."

    log_plain "\n$(as_bold "[$(as_yellow "AUTHORS")]")"
    log_plain "\tDinesh Saini <https://github.com/dineshsaini/>"

    log_plain "\n$(as_bold "[$(as_yellow "REPORTING BUGS")]")"
    log_plain "\tFor bug reports, use the issue tracker at https://github.com/grayphi/annote/issues"
}

function info {
    if [ "x$flag_no_pager" = "x" ]; then
        _info | less -R
    else
        _info 
    fi
}

function version {
    log_plain "$__NAME__ (v$__VERSION__)"
}

function import_config {
    local imf="$1"
    if [ -f "$imf" ]; then
        mkdir -p "$(dirname "$config_file")"
        touch "$config_file"
        sed -e 's/^\s\+//' -e '/^#/d' -e 's/\s\+$//' -e 's/\s\+=/=/' \
            -e 's/=\s\+/=/' -e '/^$/d' "$imf" >> "$config_file"
        log_info "Done importing conf file"
    else
        log_error "Error while importing"
    fi
}

function export_config {
    local exf="$1"
    sed -e 's/^\s\+//' -e '/^#/d' -e 's/\s\+$//' -e 's/\s\+=/=/' \
        -e 's/=\s\+/=/' -e '/^$/d' "$config_file"  > "$exf"
    log_info "Done exporting conf file"
}

function _set_key {
    local key="$1"
    local value="$2"

    case "$key" in
        "default_group")
            def_group="$value"
            ;;
        "default_tag")
            def_tag="$value"
            ;;
        "db_loc")
            db_loc="$value"
            ;;
        "editor")
            editor="$value"
            ;;
        "gui_editor")
            editor_gui="$value"
            ;;
        "list_delim")
            list_delim="$value"
            ;;
        "list_format")
            list_fmt="$value"
            ;;
        *)
            log_warn "Ignored unknown key: '$key', check config."
            ;;
    esac
}

function _conf_file {
    local cfile="$1"
    local line=""
    cfile="$(echo "$cfile" | sed -e 's/^\s\+//' -e 's/\s\+$//')"
    if [ -n "$cfile" ] && [ -f "$cfile" ]; then
        while IFS= read -r line; do
            local key="$(echo "$line" | cut -d= -f1 | sed -e 's/\s\+$//')"
            local value="$(echo "$line" | cut -d= -f2- | sed -e 's/^\s\+//')"
            _set_key "$key" "$value"
        done < <(sed -e 's/^\s\+//' -e '/^#/d' -e 's/\s\+$//' \
            -e '/^$/d' "$cfile")
    fi
}   

function _load_sys_conf {
    _conf_file "$config_file"
}

function _load_user_conf {
    if [ -n "$u_conf_file" ] && [ -r "$u_conf_file" ]; then
        _conf_file "$u_conf_file"
    fi
}

function store_kv_pair {
    local kv="$1"
    local kv="$(echo "$kv" | sed -e 's/^\s\+//' -e 's/\s\+$//')"
    local k="$(echo "$kv" | cut -d= -f1 | sed -e 's/\s\+$//')"
    local v="$(echo "$kv" | cut -d= -f2- | sed -e 's/^\s\+//')"
    if [ -n "$k" ]; then
        kv_conf_var["$k"]="$v"
    fi
}

function _set_keys_conf {
    if [[ ${#kv_conf_var[@]} -ge 1 ]]; then
        for i in "${!kv_conf_var[@]}"; do
            _set_key "$i" "${kv_conf_var["$i"]}"
        done
    fi
}

function initialize_conf {
    _load_sys_conf
    _load_user_conf
    _set_keys_conf
    notes_loc="$db_loc/notes"
    groups_loc="$db_loc/groups"
    tags_loc="$db_loc/tags"
    mkdir -p "$db_loc"
    mkdir -p "$notes_loc"
    mkdir -p "$groups_loc"
    mkdir -p "$tags_loc"
}

function note_exists {
    local nid="$1"
    local f="$(ls "$notes_loc" | grep "^$nid$" | wc -l)"
    if [[ "$f" -gt 0 ]]; then
        echo "true"
    else
        echo "false"
    fi
}

function tag_exists {
    local tname="$1"
    local c="$(ls "$tags_loc" | grep "^$tname$" | wc -l)"
    if [[ "$c" -gt 0 ]]; then
        echo "true"
    else
        echo "false"
    fi
}

function group_exists {
    local gname="$1"
    local retval="false"
    if [ -n "$gname" ]; then
        if [ -d "$groups_loc/$(echo "$gname" | sed 's/\./\//g')" ]; then
            retval="true"
        fi
    fi
    echo "$retval"
}

function get_group {
    local group="$1"
    group="$(echo "$group" | sed -e 's/\s\+/ /g' -e 's/[^A-Za-z0-9._ ]//g' \
        -e 's/\.\+/./g' -e 's/^ //' -e 's/ $//' -e 's/ \././g' \
        -e 's/\. /./g' -e 's/ /_/g' -e 's/^\.//' -e 's/\.$//' )"
    if [ -z "$group" ]; then
        group="$def_group"
    fi
    echo "$group"
}

function get_tags {
    local tags="$1"
    tags="$(echo "$tags" | sed -e 's/\s\+/ /g' -e 's/[^A-Za-z0-9,_ ]//g' \
        -e 's/,\+/,/g' -e 's/^ //' -e 's/ $//' -e 's/ ,/,/g' -e 's/, /,/g' \
        -e 's/ /_/g' -e 's/^,//' -e 's/,$//' )"
    if [ -z "$tags" ]; then
        tags="$def_tag"
    fi
    echo "$tags"
}

function get_group_loc {
    local group="$1"
    local gl="$groups_loc/$(echo "$group" | sed 's/\./\//g')"
    mkdir -p "$gl"
    echo "$gl"
}

function get_tag_loc {
    local tag="$1"
    local tl="$tags_loc/$tag"
    mkdir -p "$tl"
    echo "$tl"
}

function _gen_note_id {
    local nid="n$(date '+%s')"
    while [ -d "$notes_loc/$nid" ]; do
        sleep "0.4s"
        nid="$(_gen_note_id)"
    done
    echo "$nid"
}

function _create_note {
    local nid="$(_gen_note_id)"
    local nloc="$notes_loc/$nid"
    mkdir "$nloc"
    touch "$nloc/$nid.title"
    touch "$nloc/$nid.note"
    touch "$nloc/$nid.group"
    touch "$nloc/$nid.tags"
    touch "$nloc/$nid.metadata"
    echo "Created On: $(date --date="@${nid#n}")" > "$nloc/$nid.metadata"
    echo "$nid"
}

function _new_note {
    local title="$1"
    local group="$2"
    local tags="$3"
    local nid="$(_create_note)"
    local nloc="$notes_loc/$nid"
    echo "$title" > "$nloc/$nid.title" 
    local gl="$(get_group_loc "$group")"
    echo "$group" > "$nloc/$nid.group"
    echo "$nid" >> "$gl/notes.lnk"
    local tag=""
    while IFS= read -d, -r tag ; do
        # useless check, but let it be,in case read takes last ignored empty
        if ! [ -z "$tag" ]; then
            local tl="$(get_tag_loc "$tag")"
            echo "$tag" >> "$nloc/$nid.tags"
            echo "$nid" >> "$tl/notes.lnk"
        fi
    done < <(echo "$tags,")
    echo "Modified On: $(date)" >> "$nloc/$nid.metadata"
    echo "$nid"
}

function get_note {
    local nid="$1"
    echo "$notes_loc/$nid/$nid.note"
}

function get_note_title {
    local nid="$1"
    local tf="$notes_loc/$nid/$nid.title"
    if [ -f "$tf" ]; then
        echo "$(cat "$tf")"
    fi
}

function set_note_title {
    local nid="$1"
    local t_new="$2"
    local tf="$notes_loc/$nid/$nid.title"
    if [ -f "$tf" ]; then
        echo "$t_new" > "$tf"
    fi
}

function get_note_tags {
    local nid="$1"
    local tf="$notes_loc/$nid/$nid.tags"
    if [ -f "$tf" ]; then
        echo "$(cat "$tf" | tr '\n' ',' | sed 's/,$//')"
    fi
}

function get_note_group {
    local nid="$1"
    local gf="$notes_loc/$nid/$nid.group"
    if [ -f "$gf" ]; then
        echo "$(cat "$gf")"
    fi
}

function change_note_group {
    local nid="$1"
    local g_new="$(get_group "$2")"
    local g_old="$(get_note_group "$nid")"
    
    if [ "x$g_new" != "x$g_old" ]; then
        local ngf="$notes_loc/$nid/$nid.group"
        local gl="$(get_group_loc "$g_old")"
        local gf="$gl/notes.lnk"
        sed -i -e "/^$nid$/d" "$gf"
        gl="$(get_group_loc "$g_new")"
        gf="$gl/notes.lnk"
        echo "$nid" >> "$gf"
        echo "$g_new" > "$ngf"
    fi
}

function update_metadata {
    local nid="$1"
    local key="$2"
    local value="$3"
    local mfile="$notes_loc/$nid/$nid.metadata"
    sed -i -e "/^$key:.*$/d" "$mfile"
    echo "$key: $value" >> "$mfile"
}

function get_metadata {
    local nid="$1"
    local key="$2"
    local value=""
    if $(note_exists "$nid"); then
        local mfile="$notes_loc/$nid/$nid.metadata"
        value="$(cat "$mfile" | grep "^$key: " | sed -e "s/^$key: //" )"
    fi
    echo "$value"
}

function add_note {
    local title="$1"
    local group="$2"
    local tags="$3"
    local note="$4"
    title="$(echo "$title" | sed -e 's/\s\+/ /g' -e 's/^ //' -e 's/ $//')"
    group="$(echo "$group" | sed -e 's/\s\+/ /g' -e 's/^ //' -e 's/ $//')"
    tags="$(echo "$tags" | sed -e 's/\s\+/ /g' -e 's/^ //' -e 's/ $//')"
    if [ -z "$title" ]; then
        read -r -p "$(prompt "Enter title for note:") " title
        while [ -z "$title" ]; do
            read -r -p "$(prompt_error \
                "Enter title for note (can't be empty):") " title
        done
    fi
    if [ "x$flag_no_ask" = "x" ] && [ -z "$group" ]; then
        read -r -p "$(prompt \
            "Enter group (use '.' for subgroups) (enter to skip):") " group
    fi
    if [ "x$flag_no_ask" = "x" ] && [ -z "$tags" ]; then
        read -r -p "$(prompt \
            "Enter tags (',' seperated) (enter to skip):") " tags
    fi
    group="$(get_group "$group")"
    tags="$(get_tags "$tags")"
    local nid="$(_new_note "$title" "$group" "$tags")"
    local nf="$(get_note "$nid")"
    case "$flag_new_arg4" in
        "r")
            log_info "Press 'Ctrl + D' when exit recording to note."
            script -q "$nf"
            ;;
        "c")
            echo "$note" > "$nf"
            ;;
        "f")
            if [ "x$note" = "x-" ]; then
                while IFS= read -r line; do
                    echo "$line" >> "$nf"
                done
            else
                if [ -n "$note" ] && [ -r "$note" ]; then
                    cat "$note" > "$nf"
                fi
            fi
            ;;
        "")
            if [ "x$flag_gui_editor" = "xy" ]; then
                $editor_gui "$nf"
            else
                $editor "$nf"
            fi
            ;;
    esac
    update_metadata "$nid" "Modified On" "$(date)" 
}

function _list_prettify_fg {
    local c="$1"
    local txt="$2"
    local bold="$3"
    if [ "x$flag_no_pretty" != "xy" ]; then
        if [ $(( $c % 2 )) -eq 0 ]; then
            txt="$(as_cyan "$txt")"
        else
            txt="$(as_light_green_2 "$txt")"
        fi
        if [ "x$bold" = "xy" ]; then
            txt="$(as_bold "$txt")"
        fi
    fi
    echo "$txt"
}

function _list_prettify_bg {
    local c="$1"
    local txt="$2"
    if [ "x$flag_no_pretty" != "xy" ]; then
        if [ $(( $c % 2 )) -eq 0 ]; then
            txt="$(on_light_black "$txt")"
        else
            txt="$(on_dark_black "$txt")"
        fi
    fi
    echo "$txt"
}

function make_header {
    local sno="S.No."
    local nid="ID"
    local ngrp="GROUP"
    local ntitle="TITLE"
    local ntags="TAGS"
    local fmt="$(echo "$list_fmt" | sed "s/<DELIM>/$list_delim/g")"
    for i in {1..5}; do
       if [[ "$fmt" =~ \<SNO\> ]]; then
           sno="$(_list_prettify_fg "$i" "$sno" "y")"
           fmt="$(echo "$fmt" | sed -e "s/<SNO>/$sno/g" )"
       elif [[ "$fmt" =~ \<NID\> ]]; then
           nid="$(_list_prettify_fg "$i" "$nid" "y")"
           fmt="$(echo "$fmt" | sed -e "s/<NID>/$nid/g" )"
       elif [[ "$fmt" =~ \<GROUP\> ]]; then
           ngrp="$(_list_prettify_fg "$i" "$ngrp" "y")"
           fmt="$(echo "$fmt" | sed -e "s/<GROUP>/$ngrp/g" )"
       elif [[ "$fmt" =~ \<TAGS\> ]]; then
           ntags="$(_list_prettify_fg "$i" "$ntags" "y")"
           fmt="$(echo "$fmt" | sed -e "s/<TAGS>/$ntags/g" )"
       elif [[ "$fmt" =~ \<TITLE\> ]]; then
           ntitle="$(_list_prettify_fg "$i" "$ntitle" "y")"
           fmt="$(echo "$fmt" | sed -e "s/<TITLE>/$ntitle/g" )"
       fi
    done
    echo -e "$fmt"
}

function _list_note {
    local sno="$1"
    local nid="$2"
    local ngrp="$(get_note_group "$nid")"
    local ntitle="$(get_note_title "$nid")"
    local ntags="$(get_note_tags "$nid")"
    local fmt="$(echo "$list_fmt" | sed "s/<DELIM>/$list_delim/g")"
    for i in {1..5}; do
       if [[ "$fmt" =~ \<SNO\> ]]; then
           sno="$(_list_prettify_fg "$i" "$sno" "y")"
           fmt="$(echo "$fmt" | sed -e "s/<SNO>/$sno/g" )"
       elif [[ "$fmt" =~ \<NID\> ]]; then
           nid="$(_list_prettify_fg "$i" "$nid")"
           fmt="$(echo "$fmt" | sed -e "s/<NID>/$nid/g" )"
       elif [[ "$fmt" =~ \<GROUP\> ]]; then
           ngrp="$(_list_prettify_fg "$i" "$ngrp")"
           fmt="$(echo "$fmt" | sed -e "s/<GROUP>/$ngrp/g" )"
       elif [[ "$fmt" =~ \<TAGS\> ]]; then
           ntags="$(_list_prettify_fg "$i" "$ntags")"
           fmt="$(echo "$fmt" | sed -e "s/<TAGS>/$ntags/g" )"
       elif [[ "$fmt" =~ \<TITLE\> ]]; then
           ntitle="$(_list_prettify_fg "$i" "$ntitle")"
           ntitle="$(echo "$ntitle" | sed 's/\//\\\//g')"
           ntitle="$(echo "$ntitle" | sed 's/&/\\&/g')"
           fmt="$(echo "$fmt" | sed -e "s/<TITLE>/$ntitle/g" )"
       fi
    done
    echo -e "$fmt"
}

function get_all_notes {
    echo "$(ls "$notes_loc" | sort | tr '\n' ',' | sed 's/,$//')"
}

function _list_notes {
    local nids="$1"
    local c=0
    local l=""
    on_black "$(make_header)"
    if [ -n "$nids" ]; then
        for n in `echo "$nids" | tr ',' '\n'`; do
            if [[ "x$flag_show_archived" = "x" ]] && $(is_archived "$n"); then
                continue;
            fi
            c="$(( ++c ))"
            l="$(_list_note "$c" "$n")"

            _list_prettify_bg "$c" "$l"
        done
    else
        for n in `echo "$(get_all_notes)" | tr ',' '\n'`; do
            if [[ "x$flag_show_archived" = "x" ]] && $(is_archived "$n"); then
                continue;
            fi
            c="$(( ++c ))"
            l="$(_list_note "$c" "$n")"

            _list_prettify_bg "$c" "$l"
        done
    fi
}

function list_notes {
        if [ "x$flag_no_pager" = "xy" ]; then
            _list_notes "$1"
        else
            _list_notes "$1" | less -R
        fi
}

function build_header {
    local fmt=""
    local c=0
    while [[ $# -gt 0 ]]; do
        local arg="$1"
        shift
        arg="$(_list_prettify_fg "$c" "$arg" "y")"
        fmt="$fmt$arg$list_delim"
        c="$(( ++c ))"
    done
    echo -e "$(on_black "$fmt")"
}

function build_row {
    local row_n="$1"
    shift
    local c=0;
    local fmt=""
    fmt="$(_list_prettify_fg "$c" "$row_n" "y")$list_delim"
    while [[ $# -gt 0 ]]; do
        local t="$1"
        shift
        c="$(( ++c ))"
        t="$(_list_prettify_fg "$c" "$t")"
        fmt="$fmt$t$list_delim"
    done
    _list_prettify_bg "$row_n" "$fmt"
}

function list_groups {
    local groups="$1"
    local gl="$db_loc/groups"
    local sgl="$(echo "$gl" | sed 's/\//\\\//g')"
    if [ -z "$groups" ]; then
        groups="$(find "$gl" -type f -name 'notes.lnk' -print | sed \
            -e "s/^$sgl\///" -e 's/\//./g' -e 's/\.notes\.lnk$//' | \
            tr '\n' ',' | sed 's/,$//')"
    else
        local rgs=""
        for g in `echo "$groups" | tr ',' '\n'`; do
            if $(group_exists "$g" ); then
                rgs="$rgs,$g"
            fi
        done
        groups="$(echo "$rgs" | sed 's/^,//')"
    fi
    local c=0;
    if [ "x$flag_list_find" = "xy" ]; then
        build_header "S.No." "Group" "Note ID" "Note Title"
    else
        build_header "S.No." "Group" "Total Notes"
    fi
    for g in `echo "$groups" | tr ',' '\n'`; do
        local gf="$(get_group_loc "$g")/notes.lnk"
        if [ "x$flag_list_find" = "xy" ]; then
            if [ -f "$gf" ]; then
                for n in `cat "$gf"`; do
                    local msg="$(get_note_title "$n")"
                    build_row $((++c)) "$g" "$n" "$msg"
                done
            fi
        else
            local tn=""
            if [ -f "$gf" ]; then
                tn="$(cat "$gf" | wc -l)"
            else
                tn="0"
            fi
            local msg=" Contain $tn Note(s)."
            build_row $((++c)) "$g" "$msg"
        fi
    done
}

function list_tags {
    local tags="$1"
    local tl="$db_loc/tags"
    local stl="$(echo "$tl" | sed 's/\//\\\//g')"
    if [ -z "$tags" ]; then
        tags="$(find "$tl" -type f -name 'notes.lnk' -print | sed \
            -e "s/^$stl\///" -e 's/\//./g' -e 's/\.notes\.lnk$//' | \
            tr '\n' ',' | sed 's/,$//')"
    else
        local rts=""
        for t in `echo "$tags" | tr ',' '\n'`; do
            if $(tag_exists "$t" ); then
                rts="$rts,$t"
            fi
        done
        tags="$(echo "$rts" | sed 's/^,//')"
    fi
    local c=0;
    if [ "x$flag_list_find" = "xy" ]; then
        build_header "S.No." "Tags" "Note ID" "Note Title"
    else
        build_header "S.No." "Tags" "Total Notes"
    fi
    for t in `echo "$tags" | tr ',' '\n'`; do
        local tf="$(get_tag_loc "$t")/notes.lnk"
        if [ "x$flag_list_find" = "xy" ]; then
            if [ -f "$tf" ]; then
                for n in `cat "$tf"`; do
                    local msg="$(get_note_title "$n")"
                    build_row $((++c)) "$t" "$n" "$msg"
                done
            fi
        else
            local tn=""
            if [ -f "$tf" ]; then
                tn="$(cat "$tf" | wc -l)"
            else
                tn="0"
            fi
            local msg=" Contain $tn Note(s)."
            build_row $((++c)) "$t" "$msg"
        fi
    done
}

function open_note {
    local nid="$1"
    nid="$(echo "$nid" | sed -e 's/^\s\+//' -e 's/\s\+$//')"
    if [ -n "$nid" ] && $(note_exists "$nid"); then
        local nf="$(get_note "$nid")"
        if [ -f "$nf" ]; then
            if [ "x$flag_no_pager" = "xy" ]; then
                cat "$nf"
            elif [ "x$flag_open_noedit" = "xy" ]; then
                less "$nf"
            else
                if [ "x$flag_gui_editor" = "xy" ]; then
                    $editor_gui "$nf"
                else
                    $editor "$nf"
                fi
            fi
        fi
    fi
}

function modify_title {
    local nid="$1"
    local t_new="$2"
    nid="$(echo "$nid" | sed -e 's/^\s\+//' -e 's/\s\+$//')"
    t_new="$(echo "$t_new" | sed -e 's/^\s\+//' -e 's/\s\+$//')"
    if [ -n "$nid" ] && $(note_exists "$nid"); then
        if [ -n "$t_new" ]; then
            set_note_title "$nid" "$t_new"
        else
            local t_old="$(get_note_title "$nid")"
            log_info "Current title: "$(as_bold "$t_old")""
            read -r -p "$(prompt "Enter new title for note:") " t_new
            while [ -z "$t_new" ]; do
                read -r -p "$(prompt_error \
                    "Enter new title for note (can't be empty):") " t_new
            done
            set_note_title "$nid" "$t_new"
        fi
    fi
}

function modify_note {
    local nid="$1"
    local note="$2"
    nid="$(echo "$nid" | sed -e 's/^\s\+//' -e 's/\s\+$//')"
    note="$(echo "$note" | sed -e 's/^\s\+//' -e 's/\s\+$//')"
    if [ -n "$nid" ] && $(note_exists "$nid"); then
        local nf="$(get_note "$nid")"
        if [ "x$flag_append_mode" != "xy" ]; then
            echo -n "" > "$nf"
        fi
        case "$flag_modify_arg2" in
            "r")
                log_info "Press 'Ctrl + D' when exit recording to note."
                script -q -a "$nf"
                ;;
            "c")
                echo "$note" >> "$nf"
                ;;
            "f")
                if [ "x$note" = "x-" ]; then
                    while IFS= read -r line; do
                        echo "$line" >> "$nf"
                    done
                else
                    if [ -n "$note" ] && [ -r "$note" ]; then
                        cat "$note" >> "$nf"
                    fi
                fi
                ;;
            "")
                if [ "x$flag_gui_editor" = "xy" ]; then
                    $editor_gui "$nf"
                else
                    $editor "$nf"
                fi
                ;;
        esac
        update_metadata "$nid" "Modified On" "$(date)"
    fi
}

function modify_group {
    local nid="$1"
    local g_new="$2"
    nid="$(echo "$nid" | sed -e 's/^\s\+//' -e 's/\s\+$//')"
    g_new="$(echo "$g_new" | sed -e 's/^\s\+//' -e 's/\s\+$//')"
    if [ -n "$nid" ] && $(note_exists "$nid"); then
        if [ -n "$g_new" ]; then
            change_note_group "$nid" "$g_new"
        else
            local g_old="$(get_note_group "$nid")"
            log_info "Current group: "$(as_bold "$g_old")""
            read -r -p "$(prompt \
                "Enter group (use '.' for subgroups) (enter to skip):") " g_new
            change_note_group "$nid" "$g_new"
        fi
    fi
}

function _add_note_tag {
    local nid="$1"
    local tag="$2"
    local ntf="$notes_loc/$nid/$nid.tags"
    local tnf="$(get_tag_loc "$tag")/notes.lnk"
    echo "$nid" >> "$tnf"
    echo "$tag" >> "$ntf"
}

function add_note_tags {
    local nid="$1"
    local n_tags="$2"
    n_tags="$(get_tags "$n_tags")"
    n_tags="$(echo ",$n_tags," | sed -e "s/,$def_tag,//g" -e 's/,,/,/g' \
        -e 's/^,//' -e 's/,$//')"
    if [ -n "$n_tags" ]; then
        _delete_note_tag "$nid" "$def_tag"
        for t in `echo "$n_tags" | tr ',' '\n'`; do
            _add_note_tag "$nid" "$t"
        done
    fi
}

function _delete_note_tag {
    local nid="$1"
    local tag="$2"
    local ntf="$notes_loc/$nid/$nid.tags"
    local tnf="$(get_tag_loc "$tag")/notes.lnk"
    sed -i -e "/^$nid$/d" "$tnf"
    sed -i -e "/^$tag$/d" "$ntf"
}

function delete_note_tags {
    local nid="$1"
    local d_tags="$2"
    d_tags="$(get_tags "$d_tags")"
    d_tags="$(echo ",$d_tags," | sed -e "s/,$def_tag,//g" -e 's/,,/,/g' \
        -e 's/^,//' -e 's/,$//')"
    if [ -n "$d_tags" ]; then
        for t in `echo "$d_tags" | tr ',' '\n'`; do
            _delete_note_tag "$nid" "$t"
        done
    fi
    local nt="$(get_note_tags "$nid")" 
    if [ -z "$nt" ]; then
        _add_note_tag "$nid" "$def_tag"
    fi
}

function change_note_tags {
    local nid="$1"
    local t_new="$2"
    local t_old="$(get_note_tags "$nid")"
    t_new="$(get_tags "$t_new")"
    t_old="$(echo "$t_old" | tr ',' '\n' | sort -u | tr '\n' ',' |\
        sed 's/,$//')"
    t_new="$(echo "$t_new" | tr ',' '\n' | sort -u | tr '\n' ',' | \
        sed 's/,$//')"
    local a_tags=""
    local d_tags=""
    local c_tags=""
    for t in `echo "$t_new" | tr ',' '\n'`; do
        if [[ ",$t_old," =~ ,$t, ]]; then
            c_tags="$c_tags,$t"
            t_old="$(echo ",$t_old," | sed -e "s/,$t,/,/" -e 's/^,//' \
                -e 's/,$//')"
        else
            a_tags="$a_tags,$t"
        fi
    done
    d_tags="$t_old"
    case $flag_modify_tag_mode in
        "a"|"")
            add_note_tags "$nid" "$a_tags"
            ;;
        "o")
            delete_note_tags "$nid" "$d_tags"
            add_note_tags "$nid" "$a_tags"
            ;;
        "d")
            delete_note_tags "$nid" "$c_tags"
            ;;
    esac
}

function modify_tags {
    local nid="$1"
    local t_new="$2"
    nid="$(echo "$nid" | sed -e 's/^\s\+//' -e 's/\s\+$//')"
    t_new="$(echo "$t_new" | sed -e 's/^\s\+//' -e 's/\s\+$//')"
    if [ -n "$nid" ] && $(note_exists "$nid"); then
        if [ -n "$t_new" ]; then
            change_note_tags "$nid" "$t_new"
        else
            local t_old="$(get_note_tags "$nid")"
            log_info "Current tags: "$(as_bold "$t_old")""
            read -r -p "$(prompt \
                "Enter tags (',' seperated) (enter to skip):") " t_new
            change_note_tags "$nid" "$t_new"
        fi
    fi
}

function delete_note {
    local nid="$1"
    nid="$(echo "$nid" | sed -e 's/^\s\+//' -e 's/\s\+$//')"
    if [ -n "$nid" ] && $(note_exists "$nid"); then
        local nl="$notes_loc/$nid"
        delete_note_tags "$nid" "$(get_note_tags "$nid")"
        change_note_group "$nid" 
        local gl="$(get_group_loc "$def_group")"
        local tl="$(get_tag_loc "$def_tag")"
        local gf="$gl/notes.lnk"
        local tf="$tl/notes.lnk"
        sed -i -e "/^$nid$/d" "$gf"
        sed -i -e "/^$nid$/d" "$tf"
        rm -rf "$nl"
    fi
}

function delete_tag {
    local tag="$1"
    tag="$(echo "$tag" | sed -e 's/^\s\+//' -e 's/\s\+$//')"
    if [ -n "$tag" ] && $(tag_exists "$tag"); then
        local tf="$(get_tag_loc "$tag")"
        local tnf="$tf/notes.lnk"
        for nid in `cat "$tnf"`; do
            delete_note_tags "$nid" "$tag"
        done
        rm -rf "$tf"
    fi
}

function get_subgroups {
    local grp="$1"
    local sgrps=""
    if $(group_exists "$grp"); then
        local gl="$(get_group_loc "$grp")"
        local gsl="$(echo "$groups_loc" | sed 's/\//\\\//g')"
        sgrps="$(find "$gl" -mindepth 1 -type d | sed -e "s/^$gsl\///" \
            -e 's/\//./g' | tr '\n' ',' | sed 's/,$//')"
    fi
    echo "$sgrps"
}

function delete_group {
    local fqgn="$1"
    fqgn="$(echo "$fqgn" | sed -e 's/^\s\+//' -e 's/\s\+$//')"
    if [ -n "$fqgn" ] && $(group_exists "$fqgn"); then
        local sgrps="$(get_subgroups "$fqgn")"
        for cg in `echo "$sgrps,$fqgn" | tr ',' '\n'`; do
            local gl="$(get_group_loc "$cg")"
            local nf="$gl/notes.lnk"
            if [ -f "$nf" ]; then 
                for nid in `cat "$nf"`; do
                    if [ "x$flag_nosafe_grpdel" = "xy" ]; then
                        delete_note "$nid"
                    else
                        change_note_group "$nid" 
                    fi
                done
            fi
        done
        rm -rf "$(get_group_loc "$fqgn")"
    fi
}

function find_tags {
    local tpat="$(echo "$1" | sed -e 's/^\s\+//' -e 's/\s\+$//')"
    local tags=""
    local stl="$(echo "$tags_loc" | sed 's/\//\\\//g')"
    local apat="*"
    if [ "x$flag_strict_find" = "xy" ]; then
        apat=""
    fi
    if [ -n "$tpat" ]; then
        tags="$(find "$tags_loc"  -mindepth 1 -maxdepth 1 -type d \
            -name "$apat$tpat$apat" -print | sed -e "s/^$stl\///" \
            -e 's/\/$//' | tr '\n' ',' | sed 's/,$//')"
    fi
    if [ -n "$tags" ]; then
        list_tags "$tags"
    else
        log_info "no tags found"
    fi
}

function find_groups {
    local gpat="$(echo "$1" | sed -e 's/^\s\+//' -e 's/\s\+$//')"
    local groups=""
    local sgl="$(echo "$groups_loc" | sed 's/\//\\\//g')"
    if [ "x$flag_strict_find" != "xy" ]; then
        gpat="*$(echo "$gpat" | sed 's/\./*.*/g')*"
    fi
    gpat="$(echo "$gpat" | sed 's/\./\//g')"
    if [ -n "$gpat" ]; then
        groups="$(find "$groups_loc"  -mindepth 1 -type d \
            -path "$groups_loc/$gpat" -print | sed -e "s/^$sgl\///" \
            -e 's/\/$//' -e 's/\//./g' | tr '\n' ',' | sed 's/,$//')"
    fi
    if [ -n "$groups" ]; then
        list_groups "$groups"
    else
        log_info "no group found"
    fi
}

function find_notes {
    local stxt="$1"
    local find_with_tags="$2"           # comma seperated tags
    local find_with_group="$3"          # fqgn
    local find_created_on="$4"          # range seperated with comma
    local find_modified="$5"            # range seperated with comma
    local notes=""
    local snl="$(echo "$notes_loc" | sed 's/\//\\\//g')"
    stxt="$(echo "$stxt" | sed -e 's/^\s\+//' -e 's/\s\+$//')"
    find_with_tags="$(echo "$find_with_tags" | sed -e 's/^\s\+//' \
        -e 's/\s\+$//')"
    find_with_group="$(echo "$find_with_group" | sed -e 's/^\s\+//' \
        -e 's/\s\+$//')"
    find_created_on="$(echo "$find_created_on" | sed -e 's/^\s\+//' \
        -e 's/\s\+$//')"
    find_modified="$(echo "$find_modified" | sed -e 's/^\s\+//' \
        -e 's/\s\+$//')"
    if [ -n "$stxt" ] && [ "x$flag_search_mode" = "xt" ]; then
        notes="$(find "$notes_loc" -type f -iname "*.title" -exec grep \
            -ilFe "$stxt" {} \; | sed -e "s/^$snl\///" | cut -d/ -f1 | \
            sort -u | tr '\n' ',' | sed 's/,$//')"
    elif [ -n "$stxt" ] && [ "x$flag_search_mode" = "xn" ]; then
        notes="$(find "$notes_loc" -type f -iname "*.note" -exec grep \
            -ilFe "$stxt" {} \; | sed -e "s/^$snl\///" | cut -d/ -f1 | \
            sort -u | tr '\n' ',' | sed 's/,$//')"
    elif [ -n "$stxt" ]; then
        notes="$(find "$notes_loc" -type f \( -iname "*.note" -o \
            -iname "*.title" \) -exec grep -ilFe "$stxt" {} \; | sed \
            -e "s/^$snl\///" |cut -d/ -f1 | sort -u | tr '\n' ',' | \
            sed 's/,$//')"
    fi
    if [ -n "$find_with_group" ] && [ -n "$notes" ]; then
        if [ "x$flag_strict_find" = "xy" ]; then
            if $(group_exists "$find_with_group"); then
                for n in `echo "$notes" | tr ',' '\n'`; do
                    local g="$(get_note_group "$n")"
                    if [ "x$g" != "x$find_with_group" ]; then
                        notes="$(echo ",$notes," | sed -e "s/,$n,/,/" \
                            -e 's/^,//' -e 's/,$//')"
                    fi
                done
            else
                notes=""
            fi
        else
            for n in `echo "$notes" | tr ',' '\n'`; do
                local g="$(get_note_group "$n")"
                local p="$(echo "$find_with_group" | sed 's/\./*.*/g')"
                if [[ "$(echo "$g" | grep -i "$p" | wc -l)" -eq 0 ]]; then
                    notes="$(echo ",$notes," | sed -e "s/,$n,/,/" \
                        -e 's/^,//' -e 's/,$//')"
                fi
            done
        fi
    fi
    if [ -n "$find_with_tags" ] && [ -n "$notes" ]; then
        if [ "x$flag_strict_find" = "xy" ]; then
            for t in `echo "$find_with_tags" | tr ',' '\n'`; do
                t="$(echo "$t" | sed -e 's/^\s\+//' -e 's/\s\+$//')"
                if $(tag_exists "$t"); then
                    for n in `echo "$notes" | tr ',' '\n'`; do
                        local nt="$(get_note_tags "$n")"
                        if [[ "$(echo ",$nt," | grep ",$t," | wc -l)" \
                            -eq 0 ]]; then
                            notes="$(echo ",$notes," | sed -e "s/,$n,/,/" \
                                -e 's/^,//' -e 's/,$//')"
                        fi
                    done
                else
                    notes=""
                    break
                fi
            done
        else
            for n in `echo "$notes" | tr ',' '\n'`; do
                local nt="$(get_note_tags "$n")"
                local f=""
                for t in `echo "$find_with_tags" | tr ',' '\n'`; do
                    t="$(echo "$t" | sed -e 's/^\s\+//' -e 's/\s\+$//')"
                    if [[ "$(echo ",$nt," | grep -i ",.*$t.*," | wc -l)"  \
                        -gt 0 ]]; then
                        f="y"
                        break
                    fi
                done
                if [ -z "$f" ]; then
                    notes="$(echo ",$notes," | sed -e "s/,$n,/,/" \
                        -e 's/^,//' -e 's/,$//')"
                fi
            done
        fi
    fi
    if [ -n "$find_created_on" ] && [ -n "$notes" ]; then
        local after="$(echo "$find_created_on" | cut -d, -f1)"
        local before="$(echo "$find_created_on" | cut -d, -f2)"
        if [ -n "$after" ] && [ -n "$notes" ]; then
            for n in `echo "$notes" | tr ',' '\n'`; do
                local d="$(get_metadata "$n" 'Created On')"
                d="$(date --date="$d" "+%s")"
                if [[ "$d" -lt "$after" ]]; then
                    notes="$(echo ",$notes," | sed -e "s/,$n,/,/" \
                        -e 's/^,//' -e 's/,$//')"
                fi
            done
        fi
        if [ -n "$before" ] && [ -n "$notes" ]; then
            for n in `echo "$notes" | tr ',' '\n'`; do
                local d="$(get_metadata "$n" 'Created On')"
                d="$(date --date="$d" "+%s")"
                if [[ "$d" -gt "$before" ]]; then
                    notes="$(echo ",$notes," | sed -e "s/,$n,/,/" \
                        -e 's/^,//' -e 's/,$//')"
                fi
            done
        fi
    fi
    if [ -n "$find_modified" ] && [ -n "$notes" ]; then
        local after="$(echo "$find_modified" | cut -d, -f1)"
        local before="$(echo "$find_modified" | cut -d, -f2)"
        if [ -n "$after" ] && [ -n "$notes" ]; then
            for n in `echo "$notes" | tr ',' '\n'`; do
                local d="$(get_metadata "$n" 'Modified On')"
                d="$(date --date="$d" "+%s")"
                if [[ "$d" -lt "$after" ]]; then
                    notes="$(echo ",$notes," | sed -e "s/,$n,/,/" \
                        -e 's/^,//' -e 's/,$//')"
                fi
            done
        fi
        if [ -n "$before" ] && [ -n "$notes" ]; then
            for n in `echo "$notes" | tr ',' '\n'`; do
                local d="$(get_metadata "$n" 'Modified On')"
                d="$(date --date="$d" "+%s")"
                if [[ "$d" -gt "$before" ]]; then
                    notes="$(echo ",$notes," | sed -e "s/,$n,/,/" \
                        -e 's/^,//' -e 's/,$//')"
                fi
            done
        fi
    fi
    if [ -n "$notes" ]; then
        list_notes "$notes"
    fi
}

function is_archived {
    local nid="$1"
    local flag="false"
    nid="$(echo "$nid" | sed -e 's/^\s\+//' -e 's/\s\+$//')"
    if [ -n "$nid" ] && $(note_exists "$nid"); then
        local tags="$(get_note_tags "$nid")"
        local regex=",$archived,"
        if [[ ",$tags," =~ $regex ]]; then
            flag="true"
        fi
    fi
    echo "$flag"
}

function archive_note {
    local nid="$1"
    nid="$(echo "$nid" | sed -e 's/^\s\+//' -e 's/\s\+$//')"
    if [ -n "$nid" ] && $(note_exists "$nid"); then
        if ! $(is_archived "$nid"); then
            add_note_tags "$nid" "$archived"
        fi
    else
        log_error "Invalid note id ('$nid') provided."
        exit $ERR_ARCH
    fi
}

function unarchive_note {
    local nid="$1"
    nid="$(echo "$nid" | sed -e 's/^\s\+//' -e 's/\s\+$//')"
    if [ -n "$nid" ] && $(note_exists "$nid"); then
        if $(is_archived "$nid"); then
            delete_note_tags "$nid" "$archived"
        fi
    else
        log_error "Invalid note id ('$nid') provided."
        exit $ERR_ARCH
    fi
}

function list_archive {
    local v_old="$flag_list_find"
    flag_list_find="y"
    list_tags "$archived"
    flag_list_find="$v_old"
}

function push_op {
    local pos="$(echo "${!mutex_ops[@]}" | tr ' ' '\n' | sort -n | tail -n1)"
    if [ "x$pos" = "x" ]; then
        pos="-1"
    fi
    pos="$(( ++pos ))"
    mutex_ops["$pos"]="$1"
}

function push_op_args {
    local pos="$(echo "${!mutex_ops_args[@]}" | tr ' ' '\n' | sort -n | tail -n1)"
    if [ "x$pos" = "x" ]; then
        pos="-1"
    fi
    pos="$(( ++pos ))"
    mutex_ops_args[$pos]="$1"
}

function pop_op {
    v_pop_op=""
    local pos="$(echo "${!mutex_ops[@]}" | tr ' ' '\n' | sort -n | head -n1)"
    if [ "x$pos" != "x" ]; then
        v_pop_op="${mutex_ops[$pos]}"
        unset mutex_ops["$pos"]
    fi
}

function pop_op_args {
    v_pop_op_args=""
    local pos="$(echo "${!mutex_ops_args[@]}" | tr ' ' '\n' | sort -n | \
        head -n1)"
    if [ "x$pos" != "x" ]; then
        v_pop_op_args="${mutex_ops_args[$pos]}"
        unset mutex_ops_args["$pos"]
    fi
}

function parse_date {
    local cdate=""
    cdate="$(date --date="$1" "+%s" 2>/dev/null)"
    if [ -z "$cdate" ]; then
        log_error "Invalid date: '$1'"
    fi
    echo "$cdate"
}

function _parse_args_config {
    local n1="$#"
    local eflag=0
    local oflag=0
    while [[ $# -ne 0 && $eflag -eq 0 ]]; do
        local sarg1="$1"
        case "$sarg1" in 
        "-i"|"--import")
            oflag=1
            local sarg2="$2"
            shift 2
            import_config "$sarg2"
            exit 0
            ;;
        "-x"|"--export")
            oflag=1
            local sarg2="$2"
            shift 2
            export_config "$sarg2"
            exit 0
            ;;
        "-u"|"--use")
            oflag=1
            local sarg2="$2"
            shift 2
            u_conf_file="$sarg2"
            ;;
        "-s"|"--set")
            oflag=1
            local sarg2="$2"
            shift 2
            store_kv_pair "$sarg2"
            ;;
        *)
            if [[ $oflag -ne 1 ]]; then
                log_error "No '--config' options found, check help for details."
                exit $ERR_CONFIG
            fi
            eflag=1
            ;;
        esac
    done
    local n2="$#"
    shift_n="$((n1-n2))"
}

function _parse_args_new {
    local n1="$#"
    local eflag=0
    local title=""
    local group=""
    local tags=""
    local note=""
    while [[ $# -ne 0 && $eflag -eq 0 ]]; do
        local sarg1="$1"
        case "$sarg1" in 
            "-t"|"--title")
                title="$2"
                shift 2
                ;;
            "-g"|"--group")
                group="$2"
                shift 2
                ;;
            "-T"|"--tags")
                tags="$2"
                shift 2
                ;;
            "-r"|"--record")
                flag_new_arg4="r"
                shift
                ;;
            "-c"|"--content")
                flag_new_arg4="c"
                note="$2"
                shift 2
                ;;
            "-f"|"--file")
                flag_new_arg4="f"
                note="$2"
                shift 2
                ;;
            *)
                eflag=1
                ;;
        esac
    done
    push_op "new"
    push_op_args "$title"
    push_op_args "$group"
    push_op_args "$tags"
    push_op_args "$note"
    local n2="$#"
    shift_n="$((n1-n2))"
}

function _parse_args_list {
    local n1="$#"
    local eflag=0
    while [[ $# -ne 0 && $eflag -eq 0 ]]; do
        local sarg1="$1"
        case "$sarg1" in
            "--stdout")
                flag_no_pager="y"
                shift
                ;;
            "--no-pretty")
                flag_no_pretty="y"
                shift
                ;;
            *)
                eflag=1
                ;;
        esac
    done
    push_op "list"
    local n2="$#"
    shift_n="$((n1-n2))"
}

function _parse_args_delete {
    local n1="$#"
    local eflag=0
    local nid=""
    local group=""
    local tag=""
    while [[ $# -ne 0 && $eflag -eq 0 ]]; do
        local sarg1="$1"
        case "$sarg1" in 
            "--note")
                nid="$2"
                shift 2
                push_op "delete_n"
                push_op_args "$nid"
                ;;
            "--group")
                group="$2"
                shift 2
                push_op "delete_g"
                push_op_args "$group"
                ;;
            "--group-nosafe")
                flag_nosafe_grpdel="y"
                group="$2"
                shift 2
                push_op "delete_g_ns"
                push_op_args "$group"
                ;;
            "--tag")
                tag="$2"
                shift 2
                push_op "delete_t"
                push_op_args "$tag"
                ;;
            *)
                eflag=1
                ;;
        esac
    done
    local n2="$#"
    shift_n="$((n1-n2))"
}

function _parse_args_modify {
    local n1="$#"
    local eflag=0
    local nflag=0
    local nid=""
    local title=""
    local group=""
    local tags=""
    local note=""
    local flag_t=""
    local flag_g=""
    local flag_T=""
    while [[ $# -ne 0 && $eflag -eq 0 ]]; do
        local sarg="$1"
        case "$sarg" in 
            "-t"|"--title")
                flag_t="y"
                title="$2"
                shift 2
                ;;
            "-g"|"--group")
                flag_g="y"
                group="$2"
                shift 2
                ;;
            "-T"|"--tags")
                shift
                flag_T="y"
                local tflag=0
                local flag2=0
                while [[ $# -ne 0 && $flag2 -eq 0 ]]; do
                    local sarg1="$1"
                    case "$sarg1" in
                        "--append")
                            shift
                            flag_modify_tag_mode="a"
                            ;;
                        "--overwrite")
                            shift
                            flag_modify_tag_mode="o"
                            ;;
                        "--delete")
                            shift
                            flag_modify_tag_mode="d"
                            ;;
                        *)
                            if [[ $tflag -eq 0 ]]; then
                                tflag=1
                                tags="$sarg1"
                                shift
                            else
                                flag2=1
                            fi
                            ;;
                    esac
                done
                ;;
            "-r"|"--record")
                flag_modify_arg2="r"
                shift
                ;;
            "-c"|"--content")
                flag_modify_arg2="c"
                note="$2"
                shift 2
                ;;
            "-f"|"--file")
                flag_modify_arg2="f"
                note="$2"
                shift 2
                ;;
            "-O"|"--no-append"|"--overwrite")
                flag_append_mode=""
                shift
                ;;
            *)
                if [[ $nflag -eq 0 ]]; then
                    nid="$sarg"
                    shift
                    nflag=1
                else
                    eflag=1
                fi
                ;;
        esac
    done
    if [ "x$flag_t" = "xy" ]; then
        push_op "modify_t"
        push_op_args "$nid"
        push_op_args "$title"
    fi
    if [ "x$flag_g" = "xy" ]; then
        push_op "modify_g"
        push_op_args "$nid"
        push_op_args "$group"
    fi
    if [ "x$flag_T" = "xy" ]; then
        push_op "modify_T"
        push_op_args "$nid"
        push_op_args "$tags"
    fi  
    if [ "x$flag_t" = "x" ] && [ "x$flag_g" = "x" ] && \
        [ "x$flag_T" = "x" ]; then
        push_op "modify_n"
        push_op_args "$nid"
        push_op_args "$note"
    fi
    local n2="$#"
    shift_n="$((n1-n2))"
}

function _parse_args_open {
    local n1="$#"
    local eflag=0
    local nid=""
    local nflag=0
    while [[ $# -ne 0 && $eflag -eq 0 ]]; do
        local sarg1="$1"
        case "$sarg1" in 
            "--no-edit")
                flag_open_noedit="y"
                shift
                ;;
            *)
                if [[ $nflag -eq 0 ]]; then
                    nid="$sarg1"
                    nflag=1
                    shift
                else
                    eflag=1
                fi
                ;;
        esac
    done
    push_op "open"
    push_op_args "$nid"
    local n2="$#"
    shift_n="$((n1-n2))"
}

function _parse_args_find {
    local n1="$#"
    local eflag=0
    while [[ $# -ne 0 && $eflag -eq 0 ]]; do
        local sarg="$1"
        case "$sarg" in 
            "--tags")
                shift
                local tflag=0
                local flag=0
                local tag_pat=""
                while [[ $# -ne 0 && $flag -eq 0 ]]; do
                    local sarg1="$1"
                    case "$sarg1" in
                        "--list")
                            flag_list_find="y"
                            shift
                            ;;
                        *)
                            if [[ $tflag -eq 0 ]]; then
                                tflag=1
                                tag_pat="$sarg1"
                                shift
                            else
                                flag=1
                            fi
                            ;;
                    esac
                done
                push_op "find_t"
                push_op_args "$tag_pat"
                ;;
            "--group")
                shift
                local gflag=0
                local flag=0
                local group_pat=""

                while [[ $# -ne 0 && $flag -eq 0 ]]; do
                    local sarg1="$1"
                    case "$sarg1" in
                        "--list")
                            flag_list_find="y"
                            shift
                            ;;
                        *)
                            if [[ $gflag -eq 0 ]]; then
                                gflag=1
                                group_pat="$sarg1"
                                shift
                            else
                                flag=1
                            fi
                            ;;
                    esac
                done
                push_op "find_g"
                push_op_args "$group_pat"
                ;;
            "--note")
                shift
                local nflag=0
                local flag=0
                local note_str=""
                local find_with_tags=""
                local find_with_group=""
                local find_created_on=""
                local find_modified=""
                while [[ $# -ne 0 && $flag -eq 0 ]]; do
                    local sarg1="$1"
                    case "$sarg1" in
                        "--title-only")
                            flag_search_mode="t"
                            shift
                            ;;
                        "--note-only")
                            flag_search_mode="n"
                            shift
                            ;;
                        "--with-tags")
                            find_with_tags="$2"
                            shift 2
                            ;;
                        "--with-group")
                            find_with_group="$2"
                            shift 2
                            ;;
                        "--created-on")
                            shift
                            local flag2=0
                            local bdate=""
                            local adate=""
                            local cdate=""
                            local dflag=0
                            while [[ $# -ne 0 && $flag2 -eq 0 ]]; do
                                local sarg2="$1"
                                case "$sarg2" in
                                    "--before")
                                        if [[ $dflag -eq 1 ]]; then
                                            log_error '"--before" option can not be used with already supplied date, check help.'
                                            exit $ERR_DATE 
                                        fi
                                        bdate="$2"
                                        shift 2
                                        bdate="$(parse_date "$bdate")"
                                        if [ -z "$bdate" ]; then
                                            log_error "Enter valid '--before' date, check help for details."
                                            exit $ERR_DATE
                                        fi
                                        ;;
                                    "--after")
                                        if [[ $dflag -eq 1 ]]; then
                                            log_error '"--after" option can not be used with already supplied date, check help.'
                                            exit  $ERR_DATE
                                        fi
                                        adate="$2"
                                        shift 2
                                        adate="$(parse_date "$adate")"
                                        if [ -z "$adate" ]; then
                                            log_error "Enter valid '--after' date, check help for details."
                                            exit $ERR_DATE
                                        fi
                                        ;;
                                    *)
                                        if [[ -z "$adate"  && -z "$bdate" ]] && [[ $dflag -eq 0 ]]; then
                                            shift
                                            dflag=1
                                            cdate="$sarg2"
                                            cdate="$(parse_date "$cdate")"
                                            if [ -z "$cdate" ]; then
                                                log_error "Enter valid '--created-on' date, check help for details."
                                                exit $ERR_DATE
                                            else
                                                bdate="$cdate"
                                                adate="$cdate"
                                            fi
                                        else
                                            flag2=1
                                        fi
                                        ;;
                                esac
                            done
                            find_created_on="$adate,$bdate"
                            ;;
                        "--last-edit")
                            shift
                            local flag2=0
                            local bdate=""
                            local adate=""
                            local cdate=""
                            local dflag=0
                            while [[ $# -ne 0 && $flag2 -eq 0 ]]; do
                                local sarg2="$1"
                                case "$sarg2" in
                                    "--before")
                                        if [[ $dflag -eq 1 ]]; then
                                            log_error '"--before" option can not be used with already supplied date, check help.'
                                            exit $ERR_DATE 
                                        fi
                                        bdate="$2"
                                        shift 2
                                        bdate="$(parse_date "$bdate")"
                                        if [ -z "$bdate" ]; then
                                            log_error "Enter valid '--before' date, check help for details."
                                            exit $ERR_DATE
                                        fi
                                        ;;
                                    "--after")
                                        if [[ $dflag -eq 1 ]]; then
                                            log_error '"--after" option can not be used with already supplied date, check help.'
                                            exit  $ERR_DATE
                                        fi
                                        adate="$2"
                                        shift 2
                                        adate="$(parse_date "$adate")"
                                        if [ -z "$adate" ]; then
                                            log_error "Enter valid '--after' date, check help for details."
                                            exit $ERR_DATE
                                        fi
                                        ;;
                                    *)
                                        if [[ -z "$adate"  && -z "$bdate" ]] && [[ $dflag -eq 0 ]]; then
                                            shift
                                            dflag=1
                                            cdate="$sarg2"
                                            cdate="$(parse_date "$cdate")"
                                            if [ -z "$cdate" ]; then
                                                log_error "Enter valid '--created-on' date, check help for details."
                                                exit $ERR_DATE
                                            else
                                                bdate="$cdate"
                                                adate="$cdate"
                                            fi
                                        else
                                            flag2=1
                                        fi
                                        ;;
                                esac
                            done
                            find_modified="$adate,$bdate"
                            ;;
                        *)
                            if [[ $nflag -eq 0 ]]; then
                                nflag=1
                                note_str="$sarg1"
                                shift
                            else
                                flag=1
                            fi
                            ;;
                    esac
                done
                push_op "find_n"
                push_op_args "$note_str"
                push_op_args "$find_with_tags"
                push_op_args "$find_with_group"
                push_op_args "$find_created_on"
                push_op_args "$find_modified"
                ;;
            *)
                eflag=1
                ;;
        esac
    done
    local n2="$#"
    shift_n="$((n1-n2))"
}

function parse_args {
    local shift_n=0
    while [ $# -gt 0 ]; do
        local arg="$1"
        shift
        case "$arg" in
            "--info")
                info
                exit 0
                ;;
            "-h"|"--help")
                help
                exit 0
                ;;
            "-V"|"--version")
                version
                exit 0
                ;;
            "-v"|"--verbose")
                flag_verbose="y"
                ;;
            "-D"|"--silent")
                flag_no_ask="y"
                ;;
            "-q"|"--quite")
                flag_disable_warnings="y"
                ;;
            "--strict")
                flag_strict_find="y"
                ;;
            "--gui")
                flag_gui_editor="y"
                ;;
            "--no-pretty")
                flag_no_pretty="y"
                ;;
            "--stdout")
                flag_no_pager="y"
                ;;
            "--inc-arch")
                flag_show_archived="y"
                ;;
            "--delim")
                list_delim="$1"
                shift 
                ;;
            "--format")
                list_fmt="$1"
                shift 
                ;;
            "-C"|"--config")
                _parse_args_config "$@"
                shift $shift_n
                ;;
            "-n"|"--new")
                _parse_args_new "$@"
                shift $shift_n
                ;;
            "-l"|"--list")
                _parse_args_list "$@"
                shift $shift_n
                ;;
            "-e"|"--erase"|"--delete")
                _parse_args_delete "$@"
                shift $shift_n
                ;;
            "-o"|"--open")
                _parse_args_open "$@"
                shift $shift_n
                ;;
            "-F"|"--find"|"--search")
                _parse_args_find "$@"
                shift $shift_n
                ;;
            "-m"|"--modify"|"--edit")
                _parse_args_modify "$@"
                shift $shift_n
                ;;
            "--archive")
                local nid="$1"
                shift
                push_op "arch"
                push_op_args "$nid"
                ;;
            "--unarchive")
                local nid="$1"
                shift
                push_op "un_arch"
                push_op_args "$nid"
                ;;
            "--list-archive")
                push_op "list_arch"
                ;;
            *)
                log_error "Unknow option '$arg', check help for details."
                exit 0;
                ;;
        esac
    done
}

function do_actions {
    if [[ ${#mutex_ops[@]} -gt 1 ]] && [ "x$flag_debug_mutex_ops" = "x" ]; then
        log_error "Multiple actions defined, only one can be specified at a time. Check help for details."
        exit $ERR_MUTEX_OPTS
    elif [[ ${#mutex_ops[@]} -eq 0 ]]; then
        log_error "No actions defined. Check help for details."
        exit 0
    fi
    while [[ ${#mutex_ops[@]} -ne 0 ]]; do
        local v_pop_op=""
        pop_op
        case "$v_pop_op" in
            "new")
                local v_pop_op_args=""
                local title=""
                local group=""
                local tags=""
                local note=""
                pop_op_args
                title="$v_pop_op_args"
                pop_op_args
                group="$v_pop_op_args"
                pop_op_args
                tags="$v_pop_op_args"
                pop_op_args
                note="$v_pop_op_args"
                add_note "$title" "$group" "$tags" "$note"
                ;;
            "list")
                list_notes
                ;;
            "delete_n")
                local v_pop_op_args=""
                pop_op_args
                delete_note "$v_pop_op_args"
                ;;
            "delete_g")
                local v_pop_op_args=""
                pop_op_args
                delete_group "$v_pop_op_args"
                ;;
            "delete_g_ns")
                local v_pop_op_args=""
                pop_op_args
                delete_group "$v_pop_op_args"
                ;;
            "delete_t")
                local v_pop_op_args=""
                pop_op_args
                delete_tag "$v_pop_op_args"
                ;;
            "open")
                local v_pop_op_args=""
                pop_op_args
                open_note "$v_pop_op_args"
                ;;
            "find_t")
                local v_pop_op_args=""
                pop_op_args
                find_tags "$v_pop_op_args"
                ;;
            "find_g")
                local v_pop_op_args=""
                pop_op_args
                find_groups "$v_pop_op_args"
                ;;
            "find_n")
                local note_str=""
                local find_with_tags=""
                local find_with_group=""
                local find_created_on=""
                local find_modified=""
                local v_pop_op_args=""
                pop_op_args
                note_str="$v_pop_op_args"
                pop_op_args
                find_with_tags="$v_pop_op_args"
                pop_op_args
                find_with_group="$v_pop_op_args"
                pop_op_args
                find_created_on="$v_pop_op_args"
                pop_op_args
                find_modified="$v_pop_op_args"
                find_notes "$note_str" "$find_with_tags" "$find_with_group" "$find_created_on" "$find_modified"
                ;;
            "modify_t")
                local nid=""
                local title=""
                local v_pop_op_args=""
                pop_op_args
                nid="$v_pop_op_args"
                pop_op_args
                title="$v_pop_op_args"
                modify_title "$nid" "$title"
                ;;
            "modify_g")
                local nid=""
                local group=""
                local v_pop_op_args=""
                pop_op_args
                nid="$v_pop_op_args"
                pop_op_args
                group="$v_pop_op_args"
                modify_group "$nid" "$group"
                ;;
            "modify_T")
                local nid=""
                local tags=""
                local v_pop_op_args=""
                pop_op_args
                nid="$v_pop_op_args"
                pop_op_args
                tags="$v_pop_op_args"
                modify_tags "$nid" "$tags"
                ;;
            "modify_n")
                local nid=""
                local note=""
                local v_pop_op_args=""
                pop_op_args
                nid="$v_pop_op_args"
                pop_op_args
                note="$v_pop_op_args"
                modify_note "$nid" "$note"
                ;;
            "arch")
                local nid=""
                local v_pop_op_args=""
                pop_op_args
                nid="$v_pop_op_args"
                archive_note "$nid"
                ;;
            "un_arch")
                local nid=""
                local v_pop_op_args=""
                pop_op_args
                nid="$v_pop_op_args"
                unarchive_note "$nid"
                ;;
            "list_arch")
                list_archive
                ;;
            *)
                log_error "No such action ('$v_pop_op') defined."
                exit 0
                ;;
        esac
    done
}

parse_args "$@"
initialize_conf
do_actions

