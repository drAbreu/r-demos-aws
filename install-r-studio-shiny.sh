#install R
sudo amazon-linux-extras install R4
#install RStudio-Server 
# If this would not worl, make sure to visit https://rstudio.com/products/rstudio/download-server/redhat-centos/ for the latest versions of R studio
wget https://download2.rstudio.org/server/centos7/x86_64/rstudio-server-rhel-1.4.1106-x86_64.rpm
sudo yum install -y --nogpgcheck rstudio-server-rhel-1.4.1106-x86_64.rpm

useradd rstudio 
# add your favourite password in here. For the demo, we will use rstudio
echo rstudio:rstudio | chpasswd

# remove the conf file, cant be used in free Rstudio version
sudo rm -rf /etc/rstudio/rserver.conf 
sudo rstudio-server stop
sudo rstudio-server start
#configure java, choose 1 as your selection option for java 8 configuration 
sudo /usr/sbin/alternatives --config java 
#run command below to add Java support to R 
sudo R CMD javareconf 
#following libraries are required for the interactive application we build later 
sudo yum install -y libpng-devel 
sudo yum install -y libjpeg-turbo-devel

# Edit your .Renviron file so that you can connect to your ATHENA service
# Fill the file with
# ATHENA_USER=< AWS_ACCESS_KEY_ID >
# ATHENA_PASSWORD=< AWS_SECRET_ACCESS_KEY>
# The values can be found in the user you created in IAM. See previous steps of the tutorial for that
sudo vim /home/rstudio/.Renviron
