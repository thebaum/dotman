#!/bin/bash


#generate and show menu of <items>
#returns: selected items
menu_select() {
  result=()
  local data_name="$1[@]"
  local data=("${!data_name}")

  dialog_args=(--stdout --clear --checklist select 0 40 0)
  
  for it in "${data[@]}"; do
    dialog_args+=("$it" "$it" off)
  done
  
  result+=$(dialog ${dialog_args[@]})
}

menu_dirty_info() {
  local dirty_files_name="$1[@]"
  local dirty_files=("${!dirty_files_name}")

  #string builder
  local dialog_files_list=""
  for file in "${dirty_files[@]}"; do
    dialog_files_list+="$file\n"
  done

  info=$(dialog --stdout --clear --colors --title "dirty files: " --msgbox "$dialog_files_list" 10 20)
}

menu_dirty() {
  result=()
  local module_name=$1
  local action=$(dialog --stdout --clear --colors --menu "[Module: \Zb\Z1$module_name\Zn] Some files already exist, actions:" 15 40 20 \
    0 quit \
    1 skip \
    2 overwrite \
    3 backup \
    4 info)

  case "$action" in
    0)
      result+=("quit")
      ;;
    1)
      result+=("skip")
      ;;
    2)
      result+=("overwrite")
      ;;
    3)
      result+=("backup")
      ;;
    4)
      result+=("info")
      ;;
  esac
}
