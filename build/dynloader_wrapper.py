#!/usr/bin/env python3

import sys
import os
import stat
from elftools.elf.elffile import ELFFile
from elftools.elf.segments import InterpSegment

installdir = sys.argv[1]

# generate shell wrappers for dynamically linked ELF to run them with embedded dynamic linker
for root, dirs, files in os.walk(installdir):
    for file in files:
        filepath = os.path.join(root, file)
        try:
            with open(filepath, 'rb') as filed:
                try:
                    e = ELFFile(filed)
                    if e.header.e_type == 'ET_EXEC':
                        is_dynamic_elf = False
                        for s in e.iter_segments():
                            if isinstance(s, InterpSegment):  # This ELF is a dynamically linked one
                                dynamic_linker_path = s.get_interp_name()
                                is_dynamic_elf = True
                                break
                        if is_dynamic_elf:
                            del e
                            filed.close()
                            wrapped_path = os.path.join(root, file + '_wrapped')
                            os.rename(filepath, wrapped_path)
                            target_path = wrapped_path.replace(installdir, '')
                            filed = open(filepath, 'w+')
                            filed.write("""#!/bin/sh
export ROOTFS_RO=$SNAP
export ROOTFS_RW=$SNAP_DATA
export LD_LIBRARY_PATH=$SNAP/usr/lib:$SNAP/lib:$LD_LIBRARY_PATH
exec \"$SNAP/""" + dynamic_linker_path.decode('ascii') + '\" \"$SNAP/' + target_path + '\" \"$@\"\n')
                            filed.close()
                            st = os.stat(filepath)
                            os.chmod(filepath, st.st_mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)
                            is_dynamic_elf = False
                except Exception as e:
                    pass
        except FileNotFoundError as e:
            pass