dist_noinst_DATA = Reprof.pm.mk $(srcdir)/*.pm

SUBDIRS = Reprof

all-local: Reprof.pm

Reprof.pm : Reprof.pm.mk
	sed -e 's|__bindir__|$(bindir)|g;s|__datadir__|$(datadir)|g;s|__docdir__|$(docdir)|g;s|__pkgdatadir__|$(pkgdatadir)|g;s|__PREFIX__|$(prefix)|g;s|__sysconfdir__|$(sysconfdir)|g;s|__VERSION__|$(VERSION)|g;' "$<" > "$@"

clean-local:
	rm -f Reprof.pm
