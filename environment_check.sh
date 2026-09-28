echo -e "\n\033[0;31mUptime:\033[1;33m"
uptime
echo -e "\n\033[0;31mTop:\033[1;33m"
top -bn1 | head -20
echo -e "\n\033[0;31mCPU-power:\033[1;33m"
cpupower frequency-info
