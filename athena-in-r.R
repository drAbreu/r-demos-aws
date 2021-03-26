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
con <- jdbcConnection <- dbConnect(drv, 'jdbc:awsathena://athena.eu-central-1.amazonaws.com:443/',
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


# You can try a query of a public data set from Amazon. Conccretely from the Billboard dataset
####

# Generate the query to get a table out of the billyboard numbers

dbSendQuery(con, 
            "
            CREATE EXTERNAL TABLE IF NOT EXISTS sampledb.billboard2 (
            year int,
            songtitle string,
            artistname string,
            songID string,
            artistID string,
            timesignature int,
            timesignature_confidence double,
            loudness double,
            tempo double,
            tempo_confidence double,
            key int,
            key_confidence double,
            energy double,
            pitch double,
            timbre_0_min double,
            timbre_0_max double,
            timbre_1_min double,
            timbre_1_max double,
            timbre_2_min double,
            timbre_2_max double,
            timbre_3_min double,
            timbre_3_max double,
            timbre_4_min double,
            timbre_4_max double,
            timbre_5_min double,
            timbre_5_max double,
            timbre_6_min double,
            timbre_6_max double,
            timbre_7_min double,
            timbre_7_max double,
            timbre_8_min double,
            timbre_8_max double,
            timbre_9_min double,
            timbre_9_max double,
            timbre_10_min double,
            timbre_10_max double,
            timbre_11_min double,
            timbre_11_max double,
            Top10 int)
            ROW FORMAT DELIMITED
            FIELDS TERMINATED BY ','
            STORED AS TEXTFILE
            LOCATION 's3://aws-bigdata-blog/artifacts/predict-billboard/data'
            ;
            "
)

# Check that the table was created
dfg<-dbGetQuery(con,"SELECT * FROM sampledb.billboard2 LIMIT 30")
dfg

# Check that you can make easy fast wqueries
# Top hits by Janet Jackson
dbGetQuery(con, " SELECT songtitle,artistname,top10   FROM sampledb.billboard2 WHERE lower(artistname) =     'janet jackson' AND top10 = 1")

# Songs in the data set specifically from 2010
dbGetQuery(con, " SELECT count(*)   FROM sampledb.billboard2 WHERE year = 2010")
