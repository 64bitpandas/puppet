#!/bin/sh
ssh="/usr/bin/ssh -o ConnectTimeout=2 -o BatchMode=yes -n -T ssh"
notify_send="/usr/bin/notify-send --expire-time=30000 --icon=/opt/share/xsession/backgrounds/ocf_logo_borderless.png"

# display staff in lab
lab_staff=$(curl -s http://stats/staff.cgi)

if [ -n "$lab_staff" ]; then
    $notify_send "OCF volunteer staff in lab:
$lab_staff"
fi

$notify_send "Fall 2014 Hours
R.R.R. Week: 11am-9pm (starting 12/8)
Finals Week: 9am-9pm (starting 12/15)
Friday, Dec. 19: 9am-noon"

# report printing quota
while true; do
  balance="`$ssh /opt/ocf/bin/paper | grep pages`"
  if [ -n "$balance" ] && ( [ -z "$old_balance" ] || [ "$balance" != "$old_balance" ] ); then
    $notify_send "$balance
(as of `date '+%I:%M%P'`)"
    old_balance=$balance
  fi
  sleep 60;
done
