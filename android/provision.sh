source /vagrant/build.sh

install_dependencies
install_jdk1_6

echo "export PATH=$PATH:/vagrant/build.sh" >> /home/vagrant/.bashrc
