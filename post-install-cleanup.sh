#!/bin/bash
# add the install to the packagelist
grep -qxF "$SPACK_INSTALL_ARGS" state/packagelist.txt || echo $SPACK_INSTALL_ARGS >> state/packagelist.txt
echo
echo "removing implicit modules from Lmod"
./hide-implicit-mods.py
echo
echo "regenerating Lmod spider cache using hard-coded modulepath. This may change someday!"
/modules/lmod/lmod/lmod/libexec/update_lmod_system_cache_files -d /modules/lmod/cache $HARD_MODULEPATH