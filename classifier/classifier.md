
# Text Analysis #

We have 3 csv files, one for each category we gathered (Wikipedia, Trip advisor blogs, BBC Articles).

Reading the data using Pandas library:


```python
import pandas as pd       
wiki = pd.read_csv("../gather/wikipediaSummaries.csv", header=0, delimiter="\t", quoting=3, encoding="ISO-8859-1")
bbc = pd.read_csv("../gather/bbcArticls.csv", header=0, delimiter="\t", quoting=3, encoding="ISO-8859-1")
trip = pd.read_csv("../gather/tripAdvisorBlogPosts.csv", header=0, delimiter="\t", quoting=3, encoding="ISO-8859-1")
```

Adding classes for each category:


```python
wiki['class'] = 1
bbc['class'] = 2
trip['class'] = 3
```


```python
wiki = wiki.iloc[:, 1:]
bbc = bbc.iloc[:, 1:]
trip = trip.iloc[:, 1:]
```

merging the 3 files into one train set:


```python
frames = [wiki, bbc, trip]
train = pd.concat(frames, ignore_index=True)
```

Now we'll iterate over the data set and process the texts.

The proccessing includes: removing non-letters chars, convert to lower case and removing stop words.


```python
import re
from nltk.corpus import stopwords
```


```python
train.shape[0]
```




    142




```python
for i in range(train.shape[0]):
    letters_only = re.sub("[^a-zA-Z]", " ", train.iloc[i, 0])
    words = letters_only.lower().split()
    stops = set(stopwords.words("english"))
    meaningful_words = [w for w in words if not w in stops]
    train.iloc[i, 0] = " ".join(meaningful_words)
```

## Creating data structure ##

Let's create data structure from the texts:


```python
from sklearn.feature_extraction.text import CountVectorizer
vectorizer = CountVectorizer(analyzer = "word", tokenizer = None, preprocessor = None, stop_words = None, max_features = 5000)
```


```python
train_data_features = vectorizer.fit_transform(train.iloc[:, 0])
train_data_features = train_data_features.toarray()
```

sample of the words in the data:


```python
vocab = vectorizer.get_feature_names()
print(vocab[0:50])
```

    ['abandoned', 'abbey', 'abbreviated', 'abi', 'abilities', 'ability', 'able', 'abound', 'absence', 'absent', 'absolutely', 'abstract', 'abstracted', 'abstraction', 'abstractions', 'abuse', 'academics', 'accept', 'acceptance', 'accepted', 'accepting', 'accepts', 'access', 'accessed', 'accesses', 'accessible', 'accessing', 'accessor', 'accessors', 'accidentally', 'accio', 'acclaimed', 'accommodations', 'accomplished', 'according', 'accordingly', 'account', 'accused', 'achieve', 'achieved', 'acm', 'acquired', 'acquiring', 'acquisition', 'acre', 'acres', 'across', 'act', 'acting', 'action']
    

## Training Model ##

We'll use RandomForest to train our model.


```python
from sklearn.ensemble import RandomForestClassifier
import numpy as np
```

Splitting the train data into train and test sets:


```python
msk = np.random.rand(len(train)) < 0.8
# train set:
train_x = train_data_features[msk]
train_y = train.loc[msk,"class"]
# test set:
test_x = train_data_features[~msk]
test_y = train.loc[~msk,"class"]
```


```python
randomForest = RandomForestClassifier(n_estimators = 100) # Initializing the model
model = randomForest.fit(train_x, train_y) # Training ...
model.score(test_x,test_y) # Evaluate the model
```




    0.9487179487179487


