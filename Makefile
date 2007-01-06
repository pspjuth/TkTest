#----------------------------------------------------------------------
# Make file for TkTest
#----------------------------------------------------------------------
# $Revision: 1.1 $
#----------------------------------------------------------------------

VERSION = 01
NAGELFAR = /home/peter/src/nagelfar/nagelfar.tcl

all:

#----------------------------------------------------------------
# Testing
#----------------------------------------------------------------

check:
	$(NAGELFAR) -strictappend src/tktest.tcl

test:
	@./tests/all.tcl $(TESTFLAGS)


#----------------------------------------------------------------
# Coverage
#----------------------------------------------------------------

# Source files for code coverage
SRCFILES = src/tktest.tcl
IFILES   = $(SRCFILES:.tcl=.tcl_i)
LOGFILES = $(SRCFILES:.tcl=.tcl_log)
MFILES   = $(SRCFILES:.tcl=.tcl_m)

# Instrument source file for code coverage
%.tcl_i: %.tcl
	@$(NAGELFAR) -instrument $<

# Target to prepare for code coverage run. Makes sure log file is clear.
instrument: $(IFILES)
	@rm -f $(LOGFILES)

# Top file for coverage run
nagelfar_dummy.tcl: $(IFILES)
	@rm -f nagelfar_dummy.tcl
	@touch nagelfar_dummy.tcl
	@for i in $(SRCFILES) ; do echo "source $$i" >> nagelfar_dummy.tcl ; done

# Top file for coverage run
nagelfar.tcl_i: nagelfar_dummy.tcl_i
	@cp -f nagelfar_dummy.tcl_i nagelfar.tcl_i

# Run tests to create log file.
testcover $(LOGFILES): nagelfar.tcl_i
	@./tests/all.tcl $(TESTFLAGS)

# Create markup file for better view of result
%.tcl_m: %.tcl_log 
	@$(NAGELFAR) -markup $*.tcl

# View code coverage result
icheck: $(MFILES)
	@for i in $(SRCFILES) ; do eskil -noparse $$i $${i}_m & done

# Remove code coverage files
clean:
	@rm -f $(LOGFILES) $(IFILES) $(MFILES) nagelfar.tcl_* nagelfar_dummy*
