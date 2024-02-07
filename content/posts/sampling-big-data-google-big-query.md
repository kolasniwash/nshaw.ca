+++
title = "Creating datasets from big data with google big query"
date = 2019-10-01
+++

When starting out in machine learning one of the first things we learn is how to split data into training and test sets. And how important it is that this is done in a repeatable way. At first this seems straightforward. You use functions like train_test_split from sklearn and like magic have train and test datasets.

Moving further in my machine learning journey we realize it isn't always that simple. Typical datasets in examples are in the 50k rows range. But what If the dataset was much larger? Like 10x or 100x larger? Datasets can get so huge that you aren't able to hold them in the memory of your computer.

If you've worked with SQL you might know how we often only work with a subset of the whole dataset. By selecting only the rows and columns we need from a larger source. This post describes a clean and structured way to do this for a very large dataset. The concepts presented here are from the Launching into Machine Learning course by Google Cloud on Coursera. Part of the Machine Learning with TensorFlow on Google Cloud Platform Specialization.

# Classic way to set up training and test datasets
Using train_test_split is the ubiquitous method machine learning practitioners use to segment a dataset. For datasets sized less than about 100k rows most computers can hold the whole dataset in their memory and run something like the following.  

```python
from sklearn.model_selection import train_test_split
X_train, X_test, y_train, y_test = train_test_split(x, y, test_size = 0.2, random_state = 0)
```
_SciKit learn method to create train and test datasets_

It's a clean and simple way to get an 80/20 split on the dataset x with target dataset y. And when we set the random_state field we always produce the same subsets of data in each of the train and test buckets.

A variation on this method is to split the dataset into training, validation, and test. This technique is seen in deep learning where cross validation methods are computationally intensive and can be costly. To do this we first split the training and test then the training into training and validation.

```python
from sklearn.model_selection import train_test_split

#split the dataset into training and test
X_train, X_test, y_train, y_test = train_test_split(x, y, test_size = 0.2, random_state = 0)

#split the training dataset into training and validation
X_train, X_val, y_train, y_val = train_test_split(X_train, y_train, test_size=0.25, random_state=0)
```
_SciKit learn method to create train, validate, and test datasets_

This is a simple quick solution if you have enough data to spare. I.e. A 100k row dataset would leave you with datasets of 60k training, 20k validation, and 20k test. 

However it's probably not a good solution if your data absolutely massive like the 92M rows in the [Chicago Taxi Trips](https://www.kaggle.com/chicago/chicago-taxi-trips-bq) dataset on Kaggle. Working with this size of data the above method won't work for the average user. 

# Method for selecting a data subset
The general approach to working with big data sets is to first develop a model on a smaller subset of the data, like the 100k size explained above. How can we select this data from the larger dataset?

First, we will assume the dataset is hosted in structured database. This could be a private company database or more likely a cloud hosted service like Google Big Query (GBQ) or Amazon Redshift. We can use SQL to query the data and select a subset. But what's a reasonable way to do this? Let’s look at some options.

For the following examples we'll use the [NYC TLC Trips public dataset from google](https://console.cloud.google.com/marketplace/details/city-of-new-york/nyc-tlc-trips?filter=solution-type:dataset&q=NY&id=e4902dee-0577-42a0-ac7c-436c04ea50b6). A dataset of about 1.9M rows that is available to the public in the google big query sandbox.

## Query the data as a single block
We might consider selecting 100k of our larger dataset based on pickup_datetime, selecting only data within certain dates, or by location, only selecting a certain area. This is a valid approach if the subset you select is representative of the actual data you plan to use to make predictions. I.e. if you only plan to make predictions on taxi rides in Brooklyn you might be able to sample rides that begin and end in Brooklyn and arrive at a small enough sample. 

```sql
SELECT *
FROM `bigquery-public-data.new_york_taxi_trips.tlc_green_trips_2015`
WHERE pickup_latitude >= 40.768297 
      AND pickup_latitude <= 40.806139
      AND pickup_longitude <= -73.958011 
      AND pickup_longitude >=-73.994169
      AND dropoff_latitude >= 40.768297 
      AND dropoff_latitude <= 40.806139
      AND dropoff_longitude <= -73.958011 
      AND dropoff_longitude >=-73.994169 
```
_Query that returns taxi rides that start and terminate in New York's Upper West Side. Approx 88k rows._

For any other application however, this method introduces obvious bias into the data. Our sample would likely not have the same representative distribution as the original. It would only be useful for highly specific cases. How can we run a model that makes predictions for fare_amount if we train on one neighbourhood and test on another?

## Query data with a random function
Like in the SciKit Learn example above we could use a RAND() call in the SQL query to select rows as a random sample. This would allow us to generate a sample dataset with the same distribution as the original.

```sql
SELECT COUNT(*)
FROM (
  SELECT RAND() as split_feature,
         pickup_datetime,
         dropoff_datetime
  FROM `bigquery-public-data.new_york_taxi_trips.tlc_green_trips_2015`
)
WHERE split_feature < 0.01
```
_Adapted from the [google cloud training-data-analist repo](https://github.com/nicholasjhana/training-data-analyst/blob/master/courses/machine_learning/deepdive/02_generalization/repeatable_splitting.ipynb)_

In the above query we generate a random number with RAND() in the split_feature column. We then only select 1% of all rows with the WHERE split_features < 0.01 which returns 192,389 rows. This is a reasonable dataset to work with for model development. From here we could download the dataset as a csv and work with it on our machine, using sklearn to do the train and test split for us.

The downside to this model however is that we could not run this query again and regenerate the same data. Why not? Because the RAND() function will always generate different real number values per row. Unlike the sklearn implementation, SQL does not have a random_state feature that lets us fix the random intervals being generated. 

So this method is not robust enough for a end-to-end production pipeline.

## Query using a MOD operator 
A more robust solution, and one I learned from the [Launching into Machine Learning](https://www.coursera.org/learn/launching-machine-learning?) Coursera course, is to transform a column in the dataset with a hash function and then filter it with a MOD operator. This method has the benefit of always being repeatable and therefore selecting the same data when the query is run multiple times.

Lets take a look at what this looks like in SQL.

```sql
SELECT MOD(ABS(FARM_FINGERPRINT(CAST(pickup_datetime as string))), 1500) as hash_value, 
       *
FROM `bigquery-public-data.new_york_taxi_trips.tlc_green_trips_2015`
WHERE MOD(ABS(FARM_FINGERPRINT(CAST(pickup_datetime as string))), 1500) < 8
```
_Query using a hash to select 'random' row values. Returns approx 100k rows. Adapted from the [google cloud training-data-analist repo](https://github.com/nicholasjhana/training-data-analyst/blob/master/courses/machine_learning/deepdive/02_generalization/repeatable_splitting.ipynb)_

{% raw %}
<img src="http://nicholasjhana.github.io/assets/images/gbq-mod-query-result.png" alt="" class="full">{% endraw %}

### How is this query working?

1. The query uses the [```FARM_FINGERPRINT()```](https://cloud.google.com/bigquery/docs/reference/standard-sql/hash_functions) function to transform a string, in this case the datetime of pickup, into a hash value.
2. On the hash value we apply the MOD operator returning the remainder by the value by which we wish to reduce the dataset, in this case 1500.
3. In the WHERE clause we select reminders from 0 to 7 as our sample. We could choose any values

We can calculate how many rows we expect to be returned by different values in the MOD function: (19233765 rows / 1500) * 8 segments ~ 102k

### Evaluating the MOD method
Using the method described above is robust and simple. There are several clear advantages.
- You always return the same subsegment of data (unless the underlying dataset changes i.e. more data is added)
- Returns a subsample of data of the same distribution as the original dataset.
- It may be integrated into an end-to-end machine learning pipeline

On the other hand, there are some drawbacks.
- Converting a column into a hash means that column is no longer useable in the selected machine learning model. Doing so would be a source of bias. Consider that if you use dates all matching YYYY-MM-DD will have the same hash.
- The distribution of the subset is as good as the distribution of the hashed column. If the hashed column has only a few values (i.e. named locations) then your subset will reflect this bias. Good choices for columns to hash on are dates, unique user id, etc. Consider what the distribution of the hashing column is in relation to the whole dataset. If it appears uniform with a wide range of values, probably you'll be ok.

# How to use a GBQ query and sample directly into a cloud hosted jupyter notebook
In this last section we'll look at accessing Google Big Query and running one of the above queries directly from Jypter. This is a great solution if you are working on a virtual machine in the cloud. You're able to clone your stored script in github, run the query and have your data accessible without having to store and track cvs files. 

```python
#import gbq library
from google.cloud import bigquery

query = """
SELECT MOD(ABS(FARM_FINGERPRINT(CAST(pickup_datetime as string))), 1500) as hash_value, 
       *
FROM `bigquery-public-data.new_york_taxi_trips.tlc_green_trips_2015`
WHERE MOD(ABS(FARM_FINGERPRINT(CAST(pickup_datetime as string))), 1500) < 8

#run query and return as dataframe
subsample_dataset = bigquery.Client().query(query).to_dataframe()
subsample_dataset.head()
```
_Example executing GBQ query from a cloud hosted Jupyter Notebook. Adapted from the [google cloud training-data-analist repo](https://github.com/nicholasjhana/training-data-analyst/blob/master/courses/machine_learning/deepdive/02_generalization/repeatable_splitting.ipynb)_

The above code uses the bigquery client library and works if executing from a [google cloud hosted Jupyter Notebook](https://cloud.google.com/ai-platform/notebooks/docs/create-new) (AI Platform > Notebooks > New Instance > Python3 Notebook). The benefit of working in a cloud notebook is that you won't have to waste time getting setup with an SSH connection or Oauth client access. 

# Summary
We saw an introductory on how to transition from datasets of the size manageable by a single machine to big data - so much data you can't handle it on your machine alone. Using SQL as a preprocessing step to create a subsegment of your dataset is a practical step in reducing your data to something you can build a model prototype. Combining SQL with python in a cloud hosted notebook makes loading and managing your dataset simple and reduces errors from managing multiple csv files.


