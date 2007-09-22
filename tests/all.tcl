#!/bin/sh
#----------------------------------------------------------------------
# $Revision: 1.3 $
#----------------------------------------------------------------------
# the next line restarts using tclsh \
exec tclsh "$0" "$@"

set thisScript [file normalize [file join [pwd] [info script]]]
set thisDir    [file dirname $thisScript]

package require tcltest
namespace import tcltest::*
tcltest::configure -verbose "body error" -singleproc 1
#tcltest::configure -file gui*
#tcltest::configure -match tktest-6*

lappend ::auto_path [file join $thisDir]/..
package require TkTest

if {$argc > 0} {
    eval tcltest::configure $argv
}

tcltest::testsDirectory $thisDir
tcltest::runAllTests

cleanupTestFile
