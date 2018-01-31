#!/bin/bash

source common.sh

#initialized during load
_module_name=""
_module_path=""
#contains (localrelativedir globaltarget)
_module_target=()

#scans <dir> for modules
#returns list of modules
module_scan() {
  result=()
  local modules=()
  for i in $1/*
  do
    if [ -d "$i" ]; then
      modules+=(${i#"$1/"})
    fi
  done
  result=(${modules[@]})
}

#loads module (works like a FSM)
module_init() {
  com_log "###########################################"
  com_log "# module initing target"
  com_log "###########################################"

  _module_name=$1
  _module_path=$2

  com_log "name: $_module_name"
  com_log "path: $_module_path"

  #add new modules to load here
  _module_target+=("$_module_path/home" "$HOME")
  _module_target+=("$_module_path/root" "/")
}

module_unload() {
  com_log "unloading module"
}

#return if error (e.g. file already exists)
#returns 1 if module dirty / result contains list of dirty files
module_check() {
  result=()
  #mark true if module is dirty (files exist, e.g. override/backup/etc)
  local module_dirty=false

  com_log "###########################################"
  com_log "# module checking target"
  com_log "###########################################"

  for ((i=0; i<${#_module_target[@]}; i+=2))
  do
    #check if potential target exists (means if e.g. /home /root etc are in the modules folder)
    if [ -d "${_module_target[i]}" ]; then

      #load current state
      local cur_source=${_module_target[i]}
      local cur_target=${_module_target[i+1]}

      local files=()
      files=($(find $cur_source  -type f))

      com_log "source: $cur_source"
      com_log "target: $cur_target"

      for file in "${files[@]}"
      do
        local rel_file="${file#$cur_source}"

        com_log "file: $file"
        #relative path to file
        com_log "$rel_file"

        com_log "target-file: $cur_target$rel_file"
        
        #check if file already exists (and ignore already correctly linked files)
        if [ -f "$cur_target$rel_file" ] && [ "$(readlink $cur_target$rel_file)" != "$file" ]; then
          module_dirty=true
          result+=("$cur_target$rel_file")
        fi

      done

    fi
  done
  if [ "$module_dirty" = true ]; then
    return 1
  fi
  return 0
}

#replicates directory structure of <module> 
module_create_dir() {
  for ((i=0; i<${#_module_target[@]}; i+=2))
  do
    local cur_source="${_module_target[i]}"
    local cur_target="${_module_target[i+1]}"

    #if current source exists
    if [ -d "$cur_source" ]; then
      local directories=($(find $cur_source -type d))
      local files=($(find $cur_source -type f))

      #create all relative module dirs
      for dir in "${directories[@]}"; do
        if [ ! -d "$cur_target${dir#$cur_source}" ]; then
          mkdir -p $cur_target${dir#$cur_source}
        fi
      done
    fi
  done

}

module_link() {
  for ((i=0; i<${#_module_target[@]}; i+=2))
  do
    local cur_source=${_module_target[i]}
    local cur_target=${_module_target[i+1]}

    if [ -d "$cur_source" ]; then
      local files=($(find $cur_source -type f))
      for file in "${files[@]}"; do
        local file_target=$cur_target${file#$cur_source}
        #remove existing files
        if [ -f "$file_target" ]; then
          rm "$file_target"
        fi
        #link files
        ln -fns "$file" "$file_target"
      done
    fi
  done
}

