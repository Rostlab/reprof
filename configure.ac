AC_INIT([reprof], [1.0], [hoenigschmid@rostlab.org])
AM_INIT_AUTOMAKE([-Wall -Werror foreign])
AC_CONFIG_FILES([
                 Makefile
                 scripts/Makefile
                 share/Makefile
                 perl/Makefile
                 perl/Build.PL
                 ])
AC_SUBST(INSTALL_BASE_ARG)

if test "x$prefix" != "x/usr"; then
    INSTALL_BASE_ARG=install_base=$prefix
fi

AC_OUTPUT
