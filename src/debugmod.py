from dataclasses import dataclass
from pathlib import Path
from typing import Any, ClassVar

from lib.filesystem import ExtFs
from lib.modules import Module, ModuleRequirements


@dataclass
class DebugMod(Module):
    # Class constants
    SELINUX_RULES: ClassVar[list[str]] = [
        'allow adbd adbd process setcurrent',
        'allow adbd su process dyntransition',
        'allow su * * *',
        'allow init overlayfs_file dir relabelfrom',
        'allow init overlayfs_file dir mounton',
        'allow init overlayfs_file dir write',
        'allow init overlayfs_file file append',
        'allow init system_block_device blk_file write',
        'allow fsck system_block_device blk_file ioctl',
        'allow fsck system_block_device blk_file read',
        'allow fsck system_block_device blk_file write',
        'allow fsck system_block_device blk_file getattr',
        'allow fsck system_block_device blk_file lock',
        'allow fsck system_block_device blk_file append',
        'allow fsck system_block_device blk_file map',
        'allow fsck system_block_device blk_file open',
        'allow fsck system_block_device blk_file watch',
        'allow fsck system_block_device blk_file watch_reads',
    ]

    SYSTEM_PROPS: ClassVar[dict[str, str]] = {
        'ro.debuggable': '1',
        'ro.adb.secure': '0',
        'persist.service.adb.enable': '1',
        'persist.service.debuggable': '1',
        'persist.sys.usb.config': 'mtp,adb',
    }

    def requirements(self) -> ModuleRequirements:
        return ModuleRequirements(
            boot_images=set(),
            ext_images={'system', 'vendor'},
            selinux_patching=True,
        )

    def inject(self, boot_fs: dict[str, Any], ext_fs: dict[str, ExtFs],
               selinux_policies: list[Path]) -> None:
        # Inject SELinux rules
        for policy in selinux_policies:
            with open(policy, 'ab') as f:
                for rule in self.SELINUX_RULES:
                    f.write(f'{rule}\n'.encode('utf-8'))

        # Inject system properties
        system_prop_file = ext_fs['system'].tree / 'system' / 'build.prop'
        vendor_prop_file = ext_fs['vendor'].tree / 'build.prop'

        for prop_file in [system_prop_file, vendor_prop_file]:
            if not prop_file.exists():
                continue

            current_props = prop_file.read_text()
            with open(prop_file, 'a') as f:
                f.write('\n# Added by DebugMod\n')
                for key, value in self.SYSTEM_PROPS.items():
                    f.write(f'{key}={value}\n')