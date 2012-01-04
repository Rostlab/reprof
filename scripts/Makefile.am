dist_bin_SCRIPTS = reprof
man1_MANS = reprof.1

reprof.1: reprof
	pod2man -c 'User Commands' -r "$(VERSION)" -name $(shell echo "$(basename $@)" | tr '[:lower:]' '[:upper:]') $< > $@

install-exec-hook:
	sed -i -e 's|__bindir__|$(bindir)|g;s|__datadir__|$(datadir)|g;s|__docdir__|$(docdir)|g;s|__pkgdatadir__|$(pkgdatadir)|g;s|__PREFIX__|$(prefix)|g;s|__sysconfdir__|$(sysconfdir)|g;s|__VERSION__|$(VERSION)|g;' "$(DESTDIR)$(bindir)/reprof"

install-data-hook:
	sed -i -e 's|__bindir__|$(bindir)|g;s|__datadir__|$(datadir)|g;s|__docdir__|$(docdir)|g;s|__pkgdatadir__|$(pkgdatadir)|g;s|__PREFIX__|$(prefix)|g;s|__sysconfdir__|$(sysconfdir)|g;s|__VERSION__|$(VERSION)|g;' "$(DESTDIR)$(man1dir)/reprof.1"

clean-local:
	rm -f reprof.1
