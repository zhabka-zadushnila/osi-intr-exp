echo -e "\n\033[0;31mUname output:\033[1;33m"
uname -a
echo -e "\n\033[0;31mLSCPU:\033[1;33m"
lscpu
lscpu -e
echo -e "\n\033[0;31mCache sizes:\033[1;33m"
cat /proc/cpuinfo | grep -i cache
echo -e "\n\033[0;31mRAM:\033[1;33m"
free -h
echo -e "\n\033[0;31mDisk info:\033[1;33m"
sudo lshw -class disk -class memory -short
echo -e "\n\033[0;31msmartctl:\033[1;33m"
sudo smartctl -a /dev/nvme1
echo -e "\n\033[0;31mDisk Rotation:\033[1;33m"
cat /sys/block/nvme1n1/queue/rotational
echo -e "\n\033[0;31mnproc:\033[1;33m"
nproc
echo -e "\n\033[0;31mnumactl:\033[1;33m"
numactl --hardware
