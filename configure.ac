AC_INIT([reprof], [1.0], [hoenigschmid@rostlab.org])
AM_INIT_AUTOMAKE([-Wall -Werror foreign])
AC_CONFIG_FILES([
                 Makefile
                 Build.PL
                 lib/Makefile
                 lib/RG/Makefile
                 lib/RG/Reprof/Makefile
                 scripts/Makefile
                 share/Makefile
                 ])
AC_SUBST(INSTALL_BASE_ARG)

if test "x$prefix" != "x/usr"; then
    INSTALL_BASE_ARG=install_base=$prefix
fi

AC_OUTPUT
