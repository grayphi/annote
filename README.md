# NAME

Annotate Terminal based notes managing utility for GNU/Linux OS.

# SYNOPSIS
	annote OPTIONS

# DESCRIPTION
 You can take note from terminal, or GUI, Capture file into note, or record script or pipe commands output to it to save for later, it can does that. 
`Take notes from wherever, whenever, orcestrate in any way, and it does the thing 'notes' are supposed to do so, whenever, wherever, however it doen't make any difference.`
 It's not an App that works in isolation, it's utility, that works in integration to terminal.

# OPTIONS
	-h|--help			Show help and exit.
	--info				Show information and exit.
	-V|--version			Show version and exit.
	-v|--verbose			Be verbose.
	-S|--silent			Be silent, don't ask questions, use default values whenever required.
	-q|--quite			Disable warning messages to print.
	--strict			Use strict comparisions, exact matches. Effects find action.
	--gui				Use GUI Editor when editing note. Effects new, and modify actions.
	--no-pretty			Do not prettify output.
	--no-header			Do not display header in the output.
	-z|-0				Seperate record(s) by NULL character, instead of NEWLINE(default).
	--stdout			Do not use pager, just put everything on stdout.
	--inc-arch			Include archived notes, default is to exclude. Effects list and find actions.
	--delim [delimiter]		Use delimiter to delimit the list output fields.
	--format [format]		Create custom note listing format with <SNO>,<NID>,<TITLE>,<TAGS>,<GROUP>,<DELIM>.
	--sort-as [sf]			Use sort flag (sf) to sort the notes listing. sf can be: 'L|l', 'O|o', 'F|f',
	         			'M|m'. As Latest on the top, Oldest on the top, random as they're Found(default),
	         			last Modified on the top.
	-C|--config			Manages config, if specified, then atleast one option has to be supplied.
	   -i|--import [file]		Import config from file.
	   -x|--export [file]		Export config to file.
	   -u|--use [file]		Use file as current instance's config.
	   -s|--set ['key=value']	Overrides key in current instance, repeat set to override more keys.
	-D|--db [dbl_key]		Use db 'dbl_key' from config file as current instance's db location.
	-n|--new			Add new Note. If no sub options suplied then this will assume defaults or ask.
	   -t|--title [title]		Title of note. (required)
	   -g|--group [group]		Group for note (use '.' for subgroups). Uses default group, if not specified.
	   -T|--tags [tags]		Tags for note (use ',' for multiple tags). Uses default tag, if not specified.
	   -r|--record			Record terminal activity as note, invokes the script command.
	   -c|--content [content]	Use content as note's content.
	   -f|--file [file]		Record file as note's content, use '-' to record from stdin
	-l|--list <dbs>			List out notes from db. Output controlling options can affects it's output.
	         			If 'dbs' is supplied, then --list will only display available db(s).
	-e|--erase|--delete
	   --note [nid]			Delete note nid(id).
	   --group [gname]		Delete group gname(fully qualified name), and assign default group to notes.
	   --group-nosafe [gname]	Delete group gname(fully qualified name), also deletes the notes belongs to it.
	   --tag [tname]		Delete tag tname, assign default tag, if this was only tag to that note.
	-o|--open [nid]			Open note nid(id) in Pager.
	   --edit			Use Editor instead of Pager to open.
	   --with [cmd]			Use command cmd to open note's file(n_file). By default, n_file will be appended
	         			at the end of cmd, but if n_file needs to be supplied in between, then use '{}'
	         			in the cmd and n_file will replace all occurences of {}.
	-m|--modify|--edit [nid]	Edit note nid(id), if none from -r,-c,-f are present, then open note with editor.
	   -t|--title [title]		Modify title of note.
	   -g|--group [group]		Modify group of note (use '.' for subgroups).
	   -T|--tag [tags]		Modify tags of note (use ',' for multiple tags).
	      --append			Append new tags. (default)
	      --overwrite		Overwrite with new tags.
	      --delete			Delete tags, if present, and assign default tag, if note left with no tags.
	   -r|--record			Record terminal activity as note, invokes the script command.
	   -c|--content [content]	Use content as note's content.
	   -f|--file [file]		Record file as note's content, use '-' to record from stdin
	   -O|--no-append|--overwrite	Do not append to note, and overwrite with new content.
	-F|--find|--search		Search and list. Output controlling or strict options can affects it's behaviour.
	   --tags [pattern]		Search Tags with matching pattern, and display number of notes belong to them.
	      --list			Display all notes instead of count of notes.
	   --group [pattern]		Search Groups with matching pattern, and display number of notes belong to them.
	      --list			Display all notes instead of count of notes.
	   --note [pattern]		Search notes title & content for matching pattern.
	      --title-only		Limit searching of pattern to notes title only.
	      --note-only		Limit searching of pattern to notes content only.
	      --with-tags [tags]	Filter notes with tags.
	      --with-group [group]	Filter notes with group.
	      --created-on <date>	Filter notes with created on date. date and sub-options are mutually exclusive.
	         --before [date]	Filter notes that are created before date.
	         --after [date]		Filter notes that are created after date.
	      --last-edit <date>	Filter notes with modified on date. date and sub-options are mutually exclusive.
	         --before [date]	Filter notes that are modified before date.
	         --after [date]		Filter notes that are modified after date.
	--archive [nid]			Archive note nid(id).
	--unarchive [nid]		Unarchive note nid(id).
	--list-archive			List archived notes.




# How to install
1. Clone the repo.
2. Edit `annote.config` file.
3. Run `install.sh` script
4. To install at different location, run `install.sh <INSTALL/LOC>`.
5. Done, verify by typing `$ annote --info`.
