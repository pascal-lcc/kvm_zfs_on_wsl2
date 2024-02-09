Source
    https://github.com/alexhaydock/zfs-on-wsl/
    https://boxofcables.dev/kvm-optimized-custom-kernel-wsl2-2022/



(ZFS-on-WSL + kvm) run proxmox ve on wsl2


./build_wsl_kernel.sh

wsl --shutdown



Edit the .wslconfig file in your home directory to point to the downloaded kernel:

[wsl2]
kernel=C:\\KVM-ZFS-WSL\\bzImage
localhostForwarding=true
swap=0



