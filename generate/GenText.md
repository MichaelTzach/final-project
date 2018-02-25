
# Text Generation
You can find the full code in the "TextGen.py" file.
Here we will review the most significet parts of the code

## Data preperetion
In the "preprocess" function we first read the sequences.


```python
    x = pd.read_csv(path).as_matrix()
    data = ''.join(x[:, 1])
```

Then we are creating the dictionary to index the chars to numeric and vise versa


```python
    unique_chars = sorted(list(set(data)))
    dict_size = len(unique_chars)+1
    char_indices = dict((c, i) for i, c in enumerate(unique_chars))
    indices_char = dict((i, c) for i, c in enumerate(unique_chars))
```

Next we prepering the data, the data will be a sequences of 10 chars and the output should be those 10 chars shipted by 1


```python
   for i in range(0, len(data)-10, 10):
        temp = data[i:i+10]
        tempy = data[i+1:i+11]
        sequences.append([char_indices[a] for a in temp])
        y_sequences.append([char_indices[a] for a in tempy])
    y_sequences = np.array([to_categorical(a, num_classes=dict_size) for a in np.array(y_sequences)])
```

Then we split the data to 80%-20% (train-test) 

## The Model
For the model we used Embedding layer as the first layer to convert the input array to a dense vectors.
Then we use an LSTM (Long-Short-Term-Memory) layer, it's a variant of RNN with an addition of 'memory cell'.
Afterwards a dropout layer to be more generalized.
And finally an output layer with the size of the vocabulary.
The models were trained with batch size of 1000 and with 100 epochs.
Our optimizer is 'ADAM' an improvment of the gradient descent by using a changing learning rate.


```python
    model = Sequential()
    model.add(Embedding(dict_size, 42, input_length=10))
    model.add(LSTM(int(dict_size*2), return_sequences=True))
    model.add(Dropout(0.2))
    model.add(TimeDistributed(Dense(dict_size, activation='softmax')))
    model.summary()
    model.compile(optimizer='adam', loss='categorical_crossentropy', metrics=['accuracy'])
```

We tried a deeper network but probably because of our litle resources we couldn't train it enough and our accuracy was very low, arround 35% with lot of epochs.


```python
    model = Sequential()
    model.add(Embedding(dict_size, 42, input_length=10))
    model.add(LSTM(75, return_sequences=True))
    model.add(Dense(40, activation='relu'))
    model.add(Dense(75, activation='relu'))
    model.add(TimeDistributed(Dense(dict_size, activation='softmax')))
    model.summary()
    model.compile(optimizer='adam', loss='mse', metrics=['accuracy'])
```

## Model evaluetion
We used the test set from that we preperd earlier to check the model accuracy.
It is easy to see that we got much higher accuracy with the bigger datasets.

|          | Wiki  | BBC   | TripAdvisor |   
|----------|-------|-------|-------------|
| Accuracy | 0.543 | 0.357 | 0.450       |   
| Loss     | 1.594 | 2.22  | 1.939       |   
   

## Generating Text
For the text generation we first give the sequance 'When mecha' as the initial input, from testing with a random seed we got bad results. Then added the first char predicted to the text, afterwards we took the last 10 chars of the constructed sequance and used them as the input.

Here we are giving the seed and translating it to input form.


```python
inp = 'When mecha'
idxs = [char_indices[c] for c in inp]
arr = np.array(idxs)[np.newaxis, :]
```

Gathering the prediction output


```python
p = model.predict(arr)[0]
```

For a non-monotonic generation we are randomly choosing one of the most probable indx from the output and adding that char to the total output  


```python
char = chars[np.where(p[-1] == random.choice(p_sorted[-3:]))[0][0]]
out += char
```

Finally write each sequance to a file.


```python
file = open('{}_gen.csv'.format(path), 'aw')
file.write('{}, {}\n'.format(i, ''.join(out)))
file.close()
```

## Discussion

We trained a model for each type using sequances of 10 chars.
Our results weren't meaningfull but surprisingly mostly combined from a real words.
The results are satisfying for the amount of training time (100 epochs) and for the thin model we used.
Of course a more deeper and more training time will generate better results.
