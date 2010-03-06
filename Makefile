#----------------------------------------------------------------------
# Make file for TkTest
#----------------------------------------------------------------------
# $Revision: 1.6 $
#----------------------------------------------------------------------

VERSION = 02
NAGELFAR = nagelfar

all: doc


#----------------------------------------------------------------
# Documentation
#----------------------------------------------------------------

doc : doc/tktest.html doc/tktest.n

doc/tktest.html doc/tktest.n : doc/tktest.man mkdoc.tcl
	mkdoc.tcl


#----------------------------------------------------------------
# Testing
#----------------------------------------------------------------

check:
	$(NAGELFAR) -strictappend src/tktest.tcl

test: ccclean
	@./tests/all.tcl $(TESTFLAGS)


#----------------------------------------------------------------
# Coverage
#----------------------------------------------------------------

# Source files for code coverage
SRCFILES = src/tktest.tcl
IFILES   = $(SRCFILES:.tcl=.tcl_i) tests/all.tcl_i
LOGFILES = $(SRCFILES:.tcl=.tcl_log)
MFILES   = $(SRCFILES:.tcl=.tcl_m)

# Instrument source file for code coverage
%.tcl_i: %.tcl
	@$(NAGELFAR) -instrument $<

# Target to prepare for code coverage run. Makes sure log file is clear.
instrument: $(IFILES)
	@rm -f $(LOGFILES)

# Run tests to create log file.
testcover $(LOGFILES): $(IFILES) tests/tktest.test
	@./tests/all.tcl_i $(TESTFLAGS)

# Create markup file for better view of result
%.tcl_m: %.tcl_log 
	@$(NAGELFAR) -markup $*.tcl

# View code coverage result
icheck: $(MFILES)
	@for i in $(SRCFILES) ; do eskil -noparse $$i $${i}_m & done

# Remove code coverage files
ccclean:
	@rm -f $(LOGFILES) $(IFILES) $(MFILES)

#----------------------------------------------------------------
# Release management
#----------------------------------------------------------------

release: doc
	tar -zcf tktest$(VERSION).tar.gz $(SRCFILES) pkgIndex.tcl \
		doc/tktest.html doc/tktest.n doc/tktest.man
