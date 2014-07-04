source /vagrant/build.sh

install_dependencies
install_jdk1_6

echo "source /vagrant/build.sh" >> /home/vagrant/.bashrc
echo "export JAVA_HOME=$JAVA_HOME" >> /home/vagrant/.bashrc
