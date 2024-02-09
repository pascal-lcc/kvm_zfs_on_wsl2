#!/bin/bash
set -xe

# Root trap
if [[ "$EUID" -ne 0 ]]; then echo "Please run as root"; exit; fi

# Import variables
source ./vars.sh

# Install pre-requisites

export DEBIAN_FRONTEND=noninteractive
apt-get update && \
apt-get upgrade -y && \
apt-get install -y tzdata && \
apt-get install -y \
  alien \
  autoconf \
  automake \
  bc \
  binutils \
  bison \
  build-essential \
  curl \
  dkms \
  fakeroot \
  flex \
  gawk \
  libaio-dev \
  libattr1-dev \
  libblkid-dev \
  libelf-dev \
  libffi-dev \
  libssl-dev \
  libtool \
  libudev-dev \
  python3 \
  python3-cffi \
  python3-dev \
  python3-setuptools \
  uuid-dev \
  wget \
  zlib1g-dev


# Create temp build dir (delete it first if we find it already exists)
DIR="`pwd`/build"
WSL="$DIR/WSL2-Linux-Kernel-linux-msft-wsl"


if [[ -d $DIR ]]; then rm -rf $DIR; fi
mkdir $DIR


if [[ ! -f "$DIR/linux-msft-wsl.tar.gz" ]]; then
  wget https://github.com/microsoft/WSL2-Linux-Kernel/archive/refs/tags/linux-msft-wsl-${KERNELVER}.tar.gz -O "$DIR/linux-msft-wsl.tar.gz"
  tar -xvf "$DIR/linux-msft-wsl.tar.gz" -C $DIR
  mv $DIR/WSL2-Linux-Kernel-linux-msft-wsl-${KERNELVER} $WSL
fi;

cp "$WSL/Microsoft/config-wsl" "$WSL/.config"

sed -i 's/^CONFIG_LOCALVERSION=.*/CONFIG_LOCALVERSION="-${KERNELNAME}"/g' $WSL/.config

sed -i 's/# CONFIG_KVM_GUEST is not set/CONFIG_KVM_GUEST=y/g' $WSL/.config

sed -i 's/# CONFIG_ARCH_CPUIDLE_HALTPOLL is not set/CONFIG_ARCH_CPUIDLE_HALTPOLL=y/g' $WSL/.config

sed -i 's/# CONFIG_HYPERV_IOMMU is not set/CONFIG_HYPERV_IOMMU=y/g' $WSL/.config

sed -i '/^# CONFIG_PARAVIRT_TIME_ACCOUNTING is not set/a CONFIG_PARAVIRT_CLOCK=y' $WSL/.config

sed -i '/^# CONFIG_CPU_IDLE_GOV_TEO is not set/a CONFIG_CPU_IDLE_GOV_HALTPOLL=y' $WSL/.config

sed -i '/^CONFIG_CPU_IDLE_GOV_HALTPOLL=y/a CONFIG_HALTPOLL_CPUIDLE=y' $WSL/.config

sed -i 's/CONFIG_HAVE_ARCH_KCSAN=y/CONFIG_HAVE_ARCH_KCSAN=n/g' $WSL/.config

sed -i '/^CONFIG_HAVE_ARCH_KCSAN=n/a CONFIG_KCSAN=n' $WSL/.config

# Enter the kernel directory
cd $WSL
# Update our .config file by accepting the defaults for any new kernel
# config options added to the kernel since the Microsoft config was
# generated.


make olddefconfig
make prepare

wget https://github.com/openzfs/zfs/releases/download/zfs-${ZFSVER}/zfs-${ZFSVER}.tar.gz -O $DIR/zfs.tar.gz
tar -xvf $DIR/zfs.tar.gz -C $DIR
mv $DIR/zfs-${ZFSVER} $DIR/zfs


cd $DIR/zfs
./autogen.sh

./configure --prefix=/ --libdir=/lib --includedir=/usr/include --datarootdir=/usr/share --enable-linux-builtin=yes --with-linux=$WSL --with-linux-obj=$WSL
./copy-builtin $WSL



cd $DIR/zfs
make -s -j$(nproc)
make install


# Make sure that we're going to build ZFS support when we build our kernel
sed -i '/.*CONFIG_ZFS.*/d' $WSL/.config
echo "CONFIG_ZFS=y" >>  $WSL/.config

# Return to the kernel directory
cd $WSL

# Build our kernel and install the modules into /lib/modules!
echo "Y" | make -j$(nproc)
make modules_install



# Copy our kernel to C:\ZFSonWSL\bzImage
# (We don't save it as bzImage in case we overwrite the kernel we're actually running
# so after the build process is done, the user will need to shutdown WSL and then rename
# the bzImage-new kernel to bzImage)
mkdir -p /mnt/c/KVM-ZFS-WSL
cp -fv $WSL/arch/x86/boot/bzImage /mnt/c/KVM-ZFS-WSL/bzImage-new
# Tar up the build directories for the kernel and for ZFS
# Mostly useful for our GitLab CI process but might help with redistribution
cd $DIR
#tar -czf linux-${KERNELVER}-${KERNELNAME}.tgz /usr/src/linux-${KERNELVER}-${KERNELNAME}
#tar -czf zfs-${ZFSVER}-for-${KERNELVER}-${KERNELNAME}.tgz /usr/src/zfs-${ZFSVER}-for-linux-${KERNELVER}-${KERNELNAME}

exit
