dist_bin_SCRIPTS = reprof
dist_noinst_SCRIPTS = reprof.pl
man_MANS = reprof.1

reprof: reprof.pl
	sed -e 's|__bindir__|$(bindir)|g;s|__datadir__|$(datadir)|g;s|__docdir__|$(docdir)|g;s|__pkgdatadir__|$(pkgdatadir)|g;s|__PREFIX__|$(prefix)|g;s|__sysconfdir__|$(sysconfdir)|g;s|__VERSION__|$(VERSION)|g;' $< > $@

reprof.1: reprof.pl
	sed -e 's|__bindir__|$(bindir)|g;s|__datadir__|$(datadir)|g;s|__docdir__|$(docdir)|g;s|__pkgdatadir__|$(pkgdatadir)|g;s|__PREFIX__|$(prefix)|g;s|__sysconfdir__|$(sysconfdir)|g;s|__VERSION__|$(VERSION)|g;' $< | \
	pod2man -c 'User Commands' -r "$(VERSION)" -name $(shell echo "$(basename $@)" | tr '[:lower:]' '[:upper:]') > $@

clean-local:
	rm -f reprof reprof.1
