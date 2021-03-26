#--following R packages are required for connecting R with Athena
install.packages("rJava")
install.packages("RJDBC")
library(rJava)
library(RJDBC)

#--following R packages are required for the interactive application we build later
#--steps below might take several minutes to complete
install.packages(c("plyr","dplyr","png","RgoogleMaps"))
library(plyr)
library(dplyr)
library(png)
library(RgoogleMaps)

#verify Athena credentials by inspecting results from command below
Sys.getenv()
#set up URL to download Athena JDBC driver
# You can find the URL of the driver in http://docs.aws.amazon.com/athena/latest/ug/connect-with-jdbc.html
URL <- 'https://s3.amazonaws.com/athena-downloads/drivers/JDBC/AthenaJDBC_1.1.0/AthenaJDBC41-1.1.0.jar' 
fil <- basename(URL)
#download the file into current working directory
if (!file.exists(fil)) download.file(URL, fil)
#verify that the file has been downloaded successfully
fil
list.files()
#set up driver connection to JDBC
drv <- JDBC(driverClass="com.amazonaws.athena.jdbc.AthenaDriver", fil, identifier.quote="'")
#connect to Athena using the driver, S3 working directory and credentials for Athena 
#replace ‘athenauser’ below with prefix you have set up for your S3 bucket
con <- jdbcConnection <- dbConnect(drv, 'jdbc:awsathena://athena.us-east-1.amazonaws.com:443/',
                                   s3_staging_dir="s3://r-tutorial-for-aws",
                                   user=Sys.getenv("ATHENA_USER"),
                                   password=Sys.getenv("ATHENA_PASSWORD"))
#in case of error or warning from step above ensure rJava and RJDBC packages have #been loaded 
#also ensure you have Java 8 running and configured for R as outlined earlier

# get a list of all tables currently in Athena 
dbListTables(con)
# run a sample query
dfelb=dbGetQuery(con, "SELECT * FROM sampledb.elb_logs limit 10")
head(dfelb,2)
