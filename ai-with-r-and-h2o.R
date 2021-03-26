install.packages("RCurl")
install.packages("rjson")
install.packages("statmod")
install.packages("survival")
install.packages("h2o")

library(h2o)
h2o.init()

# import packages to connect to Athena
library(RJDBC)
#--following R packages are required for the interactive application we build later 
#--steps below might take several minutes to complete install.packages(c("plyr","dplyr","png","RgoogleMaps")) 
library
plyr) 
library(dplyr)
library(png) 
library(RgoogleMaps)

#verify Athena credentials by inspecting results from command below
Sys.getenv()
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


#Note:  Running the preceding query results in the following error: 
#Error in .jcall(rp, "I", "fetch", stride, block): java.sql.SQLException: The requested #fetchSize is more than the allowed value in Athena. Please reduce the fetchSize and try #again. Refer to the Athena documentation for valid fetchSize values.
# Use the dbSendQuery function, reduce the fetch size, and run again
r <- dbSendQuery(con, " SELECT timesignature     FROM sampledb.billboard2")
dftimesignature<- fetch(r, n=-1, block=100)
dbClearResult(r)
table(dftimesignature)
nrow(dftimesignature)

####################
# Define the training data set as all the entries before 2009

r <- dbSendQuery(con, "SELECT * FROM sampledb.billboard2 WHERE year <= 2009")
BillboardTrain <- fetch(r, n=-1, block=100)
dbClearResult(r)
BillboardTrain[1:2,c(1:3,6:10)]
nrow(BillboardTrain)


####################
# Define the test data set as all the entries of the year 2010

BillboardTest <- dbGetQuery(con, "SELECT * FROM sampledb.billboard2 where year = 2010")
BillboardTest[1:2,c(1:3,11:15)]
nrow(BillboardTest)

####################
# Convert training and test datasets into h2o dataframes
train.h2o <- as.h2o(BillboardTrain)
test.h2o <- as.h2o(BillboardTest)

####################
# Create models

# First, define the independent and dependent variables
y.dep <- 39
x.indep <- c(6:38)

# GLM using the numerical variables
modelh1 <- h2o.glm( y = y.dep, x = x.indep, training_frame = train.h2o, family = "binomial")

# Measure performance model 1
h2o.performance(model=modelh1,newdata=test.h2o)

# inspect the coefficients of the variables in the dataset
dfmodelh1 <- as.data.frame(h2o.varimp(modelh1)) 
dfmodelh1

cor(train.h2o$loudness,train.h2o$energy)

#####################################
# Create models 2 and 3, now omiting energy and loudnes because they are correlated

colnames(train.h2o)
y.dep <- 39
x.indep <- c(6:7,9:38)
x.indep
modelh2 <- h2o.glm( y = y.dep, x = x.indep, training_frame = train.h2o, family = "binomial")
h2o.performance(model=modelh2,newdata=test.h2o)
dfmodelh2 <- as.data.frame(h2o.varimp(modelh2))
dfmodelh2
h2o.auc(h2o.performance(modelh2,test.h2o)) 

y.dep <- 39
x.indep <- c(6:12,14:38)
x.indep
modelh3 <- h2o.glm( y = y.dep, x = x.indep, training_frame = train.h2o, family = "binomial")
perfh3<-h2o.performance(model=modelh3,newdata=test.h2o)
perfh3
dfmodelh3 <- as.data.frame(h2o.varimp(modelh3))
dfmodelh3
h2o.sensitivity(perfh3,0.5)
h2o.auc(perfh3)


#####################################
# Build the GMB model

train.h2o$top10=as.factor(train.h2o$top10)
gbm.modelh <- h2o.gbm(y=y.dep, x=x.indep, training_frame = train.h2o, ntrees = 500, max_depth = 4, learn_rate = 0.01, seed = 1122,distribution="multinomial")
perf.gbmh<-h2o.performance(gbm.modelh,test.h2o)
perf.gbmh
h2o.sensitivity(perf.gbmh,0.5)
h2o.auc(perf.gbmh)

#####################################
# Build a deep learning model

system.time(
  dlearning.modelh <- h2o.deeplearning(y = y.dep,
                                       x = x.indep,
                                       training_frame = train.h2o,
                                       epochs = 250,
                                       hidden = c(250,250),
                                       activation = "Rectifier",
                                       seed = 1122,
                                       distribution="AUTO"
  )
)

perf.dl<-h2o.performance(model=dlearning.modelh,newdata=test.h2o)
perf.dl
h2o.sensitivity(perf.dl,0.5)

