# Facilities for testing Tk applications.
#
#  Copyright (c) 2007, Peter Spjuth  (peter.spjuth@space.se)
#
#  Permission is granted to use this code under the same terms as
#  for the Tcl core code.
#
#----------------------------------------------------------------------
# $Revision: 1.9 $
#----------------------------------------------------------------------

package require Tk
package provide TkTest 0.2

namespace eval tktest {
    namespace eval client {}
    variable client
}

#-----------------------------------------------------------------------------
# Initialise tktest for an application.
# Argument is a string indentifying tested application for send
#-----------------------------------------------------------------------------
proc tktest::init {str} {
    variable client

    set client $str

    # Copy all client procedures to client
    send -- $client {namespace eval tktest::client {}}
    foreach p [info procs ::tktest::client::*] {
        set arglist {}
        foreach arg [info args $p] {
            if {[info default $p $arg value]} {
                lappend arglist [list $arg $value]
            } else {
                lappend arglist [list $arg]
            }
        }
        send -- $client [list proc $p $arglist [info body $p]]
    }
}

#-----------------------------------------------------------------------------
# Client Procedures
#
# Each tktest::client::xxx procedure will be copied to the application under
# test and thus executes in the application's interpreter.
#
# A portal to each is created as tktest::xxx, and is used within test
# sequences.
#-----------------------------------------------------------------------------

#-----------------------------------------------------------------------------
# Helper to parse arguments to a procedure.
# Before calling, the array shall be set up with the allowed options and
# their default values.
# An option that don't take an argument can be done by setting its default
# value to "_flag_". If the option is used, its value becomes "_flag_set".
#-----------------------------------------------------------------------------
proc tktest::client::ParseArgs {arrName arglist} {
    upvar $arrName arr
    set next ""
    foreach arg $arglist {
        # If next is set, this is the value for that option
        if {$next != ""} {
            set arr($next) $arg
            set next ""
        } else {
            set possible [array names arr $arg*]
            if {[llength $possible] == 0} {
                error "Bad option \"$arg\" to [lindex [info level -1] 0]."
            } elseif {[llength $possible] > 1} {
                error "Ambiguous option \"$arg\" to [lindex [info level -1] 0]."
            } else {
                set next [lindex $possible 0]
                if {[string match "_flag_*" $arr($next)]} {
                    set arr($next) _flag_set
                    set next ""
                }
            }
        }
    }
}

#-----------------------------------------------------------------------------
# Locate current toplevel
#-----------------------------------------------------------------------------
proc tktest::client::CurrentTop {} {
    set top [focus]
    if {![winfo exists $top]} {
        set top .
    }
    return [winfo toplevel $top]
}

#-----------------------------------------------------------------------------
# Locate a widget
# Return its name
#-----------------------------------------------------------------------------
proc tktest::client::widget {args} {
    set top [CurrentTop]

    set argv(-class) ""
    set argv(-text) ""
    set argv(-pos) ""
    set argv(-eval) ""
    ParseArgs argv $args

    # Traverse windows
    set candidates {}
    set todo [winfo children $top]
    lappend todo $top
    while {[llength $todo] > 0} {
        set doing $todo
        set todo {}
        foreach w $doing {
            # Exclude invisible windows
            if {![winfo ismapped $w]} {
                continue
            }
            # Don't traverse to another toplevel
            if {[winfo toplevel $w] ne $w} {
                # Add children
                eval lappend todo [winfo children $w]
            }
            # Filter on class
            if {$argv(-class) ne ""} {
                if {![string match -nocase $argv(-class) [winfo class $w]]} {
                    continue
                }
            }
            # Filter on name
            if {$argv(-text) ne ""} {
                if {![catch {$w cget -text} text]} {
                    if {![string match -nocase $argv(-text) $text]} {
                        continue
                    }
                } else {
                    # Skip those without -text
                    continue
                }
            }
            lappend candidates $w
        }
    }
    if {[llength $candidates] == 0} {
        return -code error "Widget not found"
    }
    if {[llength $candidates] == 1} {
        set w [lindex $candidates 0]
    } else {
        if {$argv(-pos) eq ""} {
            return -code error "Ambiguous widget '$candidates'"
        }
        # Check pos with lindex to allow end style indexing.
        if {[lindex $candidates $argv(-pos)] eq ""} {
            return -code error "Position out of range"
        }
        # Sort on coordinates
        set tosort {}
        foreach w $candidates {
            set x [winfo rootx $w]
            set y [winfo rooty $w]
            lappend tosort [list $w $x $y]
        }
        set tosort [lsort -integer -index 1 $tosort]
        set tosort [lsort -integer -index 2 $tosort]
        set w [lindex $tosort $argv(-pos) 0]
    }
    if {$argv(-eval) ne ""} {
        return [uplevel \#0 $w $argv(-eval)]
    }
    return $w
}

#-----------------------------------------------------------------------------
# Run a command in client
#-----------------------------------------------------------------------------
proc tktest::client::cmd {args} {
    return [uplevel \#0 $args]
}

#-----------------------------------------------------------------------------
# Press a button
#-----------------------------------------------------------------------------
proc tktest::client::press {name {pos {}}} {
    widget -text $name -pos $pos -eval invoke
}

#-----------------------------------------------------------------------------
# Find coordinates for a widget
# Any extra arguments are called as a subcommand on the widget
# to ask for a coord or bounding box.
# Returns a list of x/y, relative to the widget's toplevel.
#-----------------------------------------------------------------------------
proc tktest::client::coord {w args} {
    set x [expr {[winfo rootx $w] - [winfo rootx [winfo toplevel $w]]}]
    set y [expr {[winfo rooty $w] - [winfo rooty [winfo toplevel $w]]}]
    set width [winfo width $w]
    set height [winfo height $w]

    if {[llength $args] > 0} {
        set bbox [eval \$w $args]
        if {[llength $bbox] == 2} {
            return $bbox
        }
        foreach {rx ry width height} $bbox break
        incr x $rx
        incr y $ry
    }

    set mx [expr {$x + $width / 2}]
    set my [expr {$y + $height / 2}]
    return [list $mx $my]
}

#-----------------------------------------------------------------------------
# Invoke a menu
# Each argument is a glob pattern describing a menu element's label.
# All entries but the last should be cascades.
#-----------------------------------------------------------------------------
proc tktest::client::menu {args} {
    set top [CurrentTop]
    if {[winfo class $top] eq "Menu"} {
        set menu $top
    } else {
        set menu [$top cget -menu]
    }

    set notlast [llength $args]
    foreach arg $args {
        incr notlast -1
        set endindex [$menu index end]
        for {set index 0} {$index <= $endindex} {incr index} {
            if {[catch {$menu entrycget $index -label} label]} continue
            if {[string match -nocase $arg $label]} {
                break
            }
        }
        if {$index <= $endindex} {
            if {$notlast} {
                set menu [$menu entrycget $index -menu]
            } else {
                $menu invoke $index
            }
        } else {
            return -code error "Menu not found $arg in $menu"
        }
    }
}

#-----------------------------------------------------------------------------
# Mouse click on a coordinate.
# BUtton may be a number or left/right.
# Coordinates can be either a list or two arguments.
#-----------------------------------------------------------------------------
proc tktest::client::mouse {but x {y {}}} {
    set top [CurrentTop]
    if {$but eq "left"} {
        set but 1
    } elseif {$but eq "right"} {
        set but 3
    }
    if {$y eq "" && [llength $x] > 1} {
        foreach {x y} $x break
    }
    set rootx [expr {[winfo rootx $top] + $x}]
    set rooty [expr {[winfo rooty $top] + $y}]
    set w [winfo containing $rootx $rooty]
    
    set wx [expr {$rootx - [winfo rootx $w]}]
    set wy [expr {$rooty - [winfo rooty $w]}]

    event generate $w <ButtonPress-$but> -x $wx -y $wy -rootx $rootx -rooty $rooty
    event generate $w <ButtonRelease-$but> -x $wx -y $wy -rootx $rootx -rooty $rooty
}

#-----------------------------------------------------------------------------
# Send a key event
#-----------------------------------------------------------------------------
proc tktest::client::key {sym {mod {}}} {
    set top [CurrentTop]

    if {$mod eq ""} {
        event generate $top <Key-$sym>
    } else {
        event generate $top <$mod-Key-$sym>
    }
}

#-----------------------------------------------------------------------------
# Send a string as key events
#-----------------------------------------------------------------------------
proc tktest::client::keys {string} {
    set top [CurrentTop]
    foreach char [split $string ""] {
        # TODO: what set of chars should this work for?
        set char [string map {
            " " space
            \n  Return
            +   plus
            -   minus
        } $char]

        event generate $top <Key-$char>
    }
}

#-----------------------------------------------------------------------------
# Initialize mirroring procedures
# Create local procs that mirror client procs
#-----------------------------------------------------------------------------

foreach p [info procs tktest::client::*] {
    set tail [namespace tail $p]
    ##nagelfar ignore Non constant argument to proc
    proc tktest::$tail {args} [string map "%tail% $tail" {
        variable client
        if {[lindex $args 0] eq "-async"} {
            send -async -- $client tktest::client::%tail% [lrange $args 1 end]
        } else {
            send -- $client tktest::client::%tail% $args
        }
    }]
}

#-----------------------------------------------------------------------------
# Helpers to combine common tasks
#-----------------------------------------------------------------------------

# Perform a command and wait for a focus change in the application.
# This is used for buttons or menus that create a dialog or other
# new window.
proc tktest::waitFocus {cmd args} {
    set f [tktest::cmd focus]
    eval \$cmd -async $args
    update
    after 250
    for {set t 0} {$t < 20} {incr t} {
        set newf [tktest::cmd focus]
        update
        after 100
        if {$newf ne $f} break
    }
    if {$newf eq $f} {
        return -code error "Timeout in waitFocus"
    }
    return
}

# Invoke a context menu at a coordinate
proc tktest::contextMenu {coord args} {
    tktest::mouse right $coord
    eval tktest::menu $args
    tktest::key Escape
}
