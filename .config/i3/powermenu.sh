#!/bin/bash

options="Lock\nSuspend\nHibernate\nReboot\nShutdown\nLogout"

selected=$(echo -e "$options" | rofi -dmenu -p "Power Menu" -lines 6 -width 15 -location 0)

case "$selected" in
    Lock)
        i3lock
        ;;
    Suspend)
        systemctl suspend
        ;;
    Hibernate)
        systemctl hibernate
        ;;
    Reboot)
        systemctl reboot
        ;;
    Shutdown)
        systemctl poweroff
        ;;
    Logout)
        i3-msg exit
        ;;
esac
