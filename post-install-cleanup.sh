#!/bin/bash
# despite that this modulepath only includes x86_64,
# it seems to update the cache for other microarches as well
HARD_MODULEPATH="/modules/spack/share/spack/modules/linux-ubuntu20.04-x86_64:/modules/modulefiles"

# add the install to the packagelist
grep -qxF "$SPACK_INSTALL_ARGS" state/packagelist.txt || echo $SPACK_INSTALL_ARGS >> state/packagelist.txt
echo
echo "removing implicit modules from Lmod"
./hide-implicit-mods.py
echo
echo "regenerating Lmod spider cache using hard-coded modulepath. This may change someday!"
/modules/lmod/lmod/lmod/libexec/update_lmod_system_cache_files -d /modules/lmod/cache $HARD_MODULEPATH
