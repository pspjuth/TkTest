#!/bin/sh
# Inspired by sak.tcl from tcllib distribution
# -*- tcl -*- \
exec tclsh "$0" ${1+"$@"}

proc get_input {f} {return [read [set if [open $f r]]][close $if]}
proc write_out {f text} {
    catch {file delete -force $f}
    puts -nonewline [set of [open $f w]] $text
    close $of
}

package require doctools
foreach {format ext} {nroff n html html} {
    ::doctools::new dt -format $format -module tktest -file doc/tktest.man
    write_out doc/tktest.$ext [dt format [get_input doc/tktest.man]]
    dt destroy
}
