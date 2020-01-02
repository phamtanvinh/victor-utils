#!/bin/bash

usage="Usage: bash $(basename "$0") [OPTIONS]...
This script will use sqlite3 to parse cbb file into csv file.
File format: [file_base_name]-[pattern].[ext] => Ex: data-0000.cbb
Ex run auto:
bash $(basename "$0") \\
    --src_dir='/path/to/source' \\
    --dest_dir='/path/to/dest' \\
    --start_date=20190325 \\
    --game_list='GN ZS' \\
    --end_date=20190327
Ex run direct:
bash $(basename "$0") \\
    --src_dir=/path/to/[dir or file]\\
    --dest_dir='/path/to/directory'
[OPTIONS]:
    --src_dir       data source input. Default: ./
    --dest_dir      data destination output. Default: ./stage
    --start_date    format YYYYMMDD
    --end_date      format YYYYMMDD
    --game_list     list of game code
    --help          show description
Flow structure:
    => Config default
    => Get options and validate parameters
    => Validate config
    => Pre-process to prepair local variables, functions...
    => Main process for looping and calling function
Author: vinhpt"

base_dir=$(dirname "$(readlink -f "$0")")
debug=0
rpad=20
br=$(printf '%0.s=' {1..40})

debug(){
    [[ $debug -eq 1 ]] && printf "$@"
}

# [CONFIG]: setting befor starting process
# File format: data-0000.cbb => [file_base_name]-[pattern].[ext]
# debug "%-${rpad}s %s\n" "[CONFIG]:" "Setting befor starting process"
src_dir="$base_dir"
dest_dir=
file_base_name="data"
file_ext="cbb"
table_list=( 'cbb_msg' 'cbb_meta')
game_list=( 'GN' 'ZS' )
is_direct=

date_format='%Y%m%d' # ex: 20190327
today=$(date "+$date_format")
start_date=$today
end_date=$today

# [OPTIONS]: opts config
# debug "%-${rpad}s %s\n" "[OPTIONS]:" "Options config"
opts=
longopts="work_dir:,src_dir:,dest_dir:,start_date:,end_date:,game_list:,direct,debug,help"
! parsed=$(getopt --option=$opts --longoptions=$longopts --name "$0" -- "$@")
eval set -- "$parsed"

while true; do
    case "$1" in
        --help)
            shift 1 && echo "$usage" && exit 0 ;;
        --work_dir)
            [[ ! -d "$2" ]] && echo "Error: $2 doesn't exist" && exit 3
            work_dir="$2"
            shift 2 ;;
        --src_dir)
            ! [[ -d "$2" || -f "$2" ]] && echo "Error: $2 doesn't exist" && exit 3
            src_dir=$(readlink -f "$2")
            shift 2 ;;
        --dest_dir)
            [[ ! -d "$2" ]] && echo "Error: $2 doesn't exist" && exit 3
            dest_dir=$(readlink -f "$2")
            shift 2 ;;
        --start_date)
            [[ "$2" -le 0 ]] && echo "Error: $2 must be positive number. Ex: 20190325" && exit 3
            start_date="$2"
            shift 2 ;; 
        --end_date)
            [[ "$2" -le 0 ]] && echo "Error: $2 must be positive number. Ex: 20190325" && exit 3
            end_date="$2"
            shift 2 ;; 
        --game_list)
            game_list=( "$2" )
            shift 2 ;;
        --direct)
            is_direct=1
            shift 1 ;;
        --debug)
            debug=1 
            shift 1 ;;
        --)
            shift && break ;;
        *)
            exit 3 ;;
    esac
done

# [VALIDATION]: get some source and quick check validation
debug "%-${rpad}s %s\n" "[VALIDATION]:" "Quick check"
date_delta=$(( ($(date -d "$end_date" +%s) - $(date -d "$start_date" +%s))/(60*60*24) )) 
[[ ! "$date_delta" -ge 0 ]] && echo "Error date input." && exit 3   # check input validation
[[ -z "$dest_dir" ]] && dest_dir="$base_dir/stage"

# Config Info
debug "$br\n"
debug "Config Info\n"
debug "$br\n"
debug "src_dir:\t$src_dir\n" 
debug "dest_dir:\t$dest_dir\n"
debug "game_list:\t$game_list\n"
debug "start_date:\t$start_date\n"
debug "end_date:\t$end_date\n"
debug "is_direct:\t$is_direct\n"
debug "$br\n"

# [PRE-PROCESS]: get local variable and generate source
debug "%-${rpad}s %s\n" "[PRE-PROCESS]:" "Initialize..."
l_file_list=
l_file_name=
l_src_file=
l_dest_file=
l_date=
l_game=

get_src_dir(){
    debug "Run:\tget_src_dir\n"
    [[ "$is_direct" -eq 1 ]] && _source_dir="$src_dir" || _source_dir="$src_dir/$l_game/$l_date" # check if load directly or not
    l_file_list="$_source_dir/$file_base_name*.$file_ext" 
    [[ -f "$_source_dir" ]] && l_file_list="$_source_dir" # If source is file
    debug "$l_file_list\n"
}

get_dest_file(){
    debug "Run:\tget_dest_file\n"
    [[ "$is_direct" -eq 1 ]] && _dir_name=$dest_dir ||  _dir_name="$dest_dir/$l_game/$l_date"
    mkdir -p "$_dir_name"
    l_dest_file="$_dir_name/${l_file_name%%.*}-$i_table.csv"
}

parse_cbb(){
    debug "Run:\tparse_cbb\n"
    for i_table in ${table_list[@]}; do
        _sql="select * from $i_table;"
        get_dest_file
        debug "Save:\t$l_dest_file\n"
        sqlite3 -csv -header "$l_src_file" "$_sql" > "$l_dest_file"
    done
}

loop_src(){
    debug "Run:\tloop_src\n"
    OLDIFS=$IFS && IFS=$'\t'
    get_src_dir
    for i_file in $l_file_list; do
        [[ ! -f $i_file ]] && echo "Error: $i_file not found." && continue
        l_file_name=$(basename "$i_file")
        l_src_file="$i_file"
        debug "Get:\t$l_src_file\n"
        parse_cbb
    done
    IFS=$OLDIFS
}

# [MAIN-PROCESS]
debug "%-${rpad}s %s\n" "[MAIN-PROCESS]:" "Run"
main(){
    if [[ "$is_direct" -eq 1 ]]; then
        loop_src
    else
        for i_game in ${game_list[@]}; do
            l_game=$i_game
            for i_date in $(seq 0 $date_delta); do
                l_date=$(date -d "$start_date +$i_date days" "+$date_format")
                debug "$br\n Game $l_game\tDate $l_date\n$br\n"
                loop_src
            done
        done
    fi && printf "$br\nDone.\n"
}

# Run
main
