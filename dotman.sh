#!/bin/bash

source src/module.sh
source src/menu.sh
source src/common.sh

#path to the scripts directory
readonly SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"

#actions to perform if a module is dirty
#returns 1 if module should be skipped
action_dirty() {
  local action="$1"
  local dirty_files_name="$2[@]"
  local dirty_files=("${!dirty_files_name}")

    case "$1" in
      "quit")
        com_log "quitting"
        exit 0
        ;;
      "skip")
        com_log "skipping"
        return 1
        ;;
      "overwrite")
        module_create_dir
        module_link
        ;;
      "backup")
        local backup_path="/tmp/backup"

        for file in "${dirty_files[@]}"; do
          #ignore links
          if [ -L "$file" ]; then
            continue
          fi
          mkdir -p "$backup_path${file%/*}"
          cp "$file" "$backup_path$file"
        done
        module_create_dir
        module_link
        ;;
      "info")
        menu_dirty_info dirty_files

        menu_dirty "$module"
        local action="${result[0]}"
        action_dirty "$action" "$2"
        ;;
    esac
}

#scan directory for modules
module_scan .
modules=("${result[@]}")

#let user select modules
menu_select modules
selection=(${result[@]})

for module in "${selection[@]}"; do
  module_path="$SCRIPTPATH/$module"
  com_log "executing module: $module of selection: $selection"

  module_init "$module" "$module_path"

  module_check
  dirty_files=("${result[@]}")
  if [ "${#result[@]}" -gt 0 ]; then
    com_log "dirty module: $module"

    menu_dirty "$module"
    action="${result[0]}"
    action_dirty "$action" dirty_files
    #continue with next module if skipped
    if [ $? -eq 1 ]; then
      continue
    fi
  else
    module_create_dir
    module_link
  fi

  module_unload
done
