export VAGRANT_MACHINE=1 
echo "export VAGRANT_MACHINE=1" >> .bashrc # we set this environment variable so that we put the webrtc code in a shared directory where the host machine can see the files and modify them
apt-get update
source /vagrant/build.sh

install_dependencies

echo "source /vagrant/build.sh" >> /home/vagrant/.bashrc
