#!/usr/bin/env tclsh
#
# Simple GUI application to run tests on
#
package require Tk
tk appname TkTestTest

frame .fl -width 100 -height 200
pack .fl -side top -anchor w

listbox .lb -listvariable LB
pack .lb -in .fl -fill both -expand 1
pack propagate .fl 0
set LB {aa bb cc dd ee}

frame .f1
pack .f1 -side top -anchor w

button .b1 -text Apa -command "set But Apa"
button .b2 -text Bepa -command "set But Bepa"
button .b3 -text Cepa -command "set But Cepa"
button .b4 -text Depa -command "set But Depa"
checkbutton .b5 -text Cb1 -variable Cbut1
checkbutton .b6 -text Cb2 -variable Cbut2

label .l1 -textvariable But
label .l2 -textvariable Cbut1
label .l3 -textvariable Cbut2

entry .e -width 10 -textvariable But
text  .t -width 10 -height 10 

grid .b1 .b2 -sticky nw  -in .f1
grid .b3 .b4 -sticky nw  -in .f1
grid .b5 .b6 -sticky nw  -in .f1
grid .l1 -   -sticky nw  -in .f1
grid .l2 -   -sticky nw  -in .f1
grid .l3 -   -sticky nw  -in .f1
grid .e  -   -sticky nwe -in .f1
grid .t  -   -sticky nwe -in .f1

menu .m
. configure -menu .m

.m add cascade -label "File" -menu .m.f
menu .m.f
.m.f add command -label "Exit"

.m add cascade -label "Edit" -menu .m.e
menu .m.e
.m.e add command -label "Copy" -command "set But Copy"
.m.e add command -label "Paste" -command "set But Paste"

proc popup {x y X Y} {
    destroy .popup
    menu .popup -tearoff 0

    .popup add command -label "Miffo" -command "set But Miffo"
    .popup add command -label "Maffo" -command "set But Maffo"

    tk_popup .popup $X $Y
}

bind .l2 <Button-3> "popup %x %y %X %Y"
