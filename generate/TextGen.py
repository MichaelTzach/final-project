from keras.models import Sequential, load_model
import random
from keras.layers import LSTM, Embedding, Dense, TimeDistributed, Dropout
import pandas as pd
from keras.utils import to_categorical
import numpy as np
import os

def preprocess(path):
    # read file
    x = pd.read_csv(path, delimiter='\t').as_matrix()
    seq_size = x.shape[0]
    data = ''.join(x[:, 1])
    del x

    # create dict
    unique_chars = sorted(list(set(data)))
    dict_size = len(unique_chars)+1
    char_indices = dict((c, i) for i, c in enumerate(unique_chars))
    indices_char = dict((i, c) for i, c in enumerate(unique_chars))

    # create sequences size 10
    sequences = list()
    y_sequences = list()
    for i in range(0, len(data)-10, 10):
        temp = data[i:i+10]
        tempy = data[i+1:i+11]
        sequences.append([char_indices[a] for a in temp])
        y_sequences.append([char_indices[a] for a in tempy])
    y_sequences = np.array([to_categorical(a, num_classes=dict_size) for a in np.array(y_sequences)])

    # train-test split
    sequences = np.array(sequences)
    y_sequences = np.array(y_sequences)
    n_seqs = sequences.shape[0]
    n_train = int(round(n_seqs*0.8))
    print n_train
    x_train, x_test = sequences[:n_train], sequences[n_train:]
    y_train, y_test = y_sequences[:n_train], y_sequences[n_train:]

    return x_train, y_train, x_test, y_test, indices_char, char_indices, unique_chars, seq_size


def train_model(X, Y, dict_size, name):
    model = Sequential()
    model.add(Embedding(dict_size, 42, input_length=10))
    model.add(LSTM(int(dict_size*2), return_sequences=True))
    model.add(Dropout(0.2))
    model.add(TimeDistributed(Dense(dict_size, activation='softmax')))
    model.summary()
    model.compile(optimizer='adam', loss='categorical_crossentropy', metrics=['accuracy'])
    model.fit(X, Y, batch_size=1000, epochs=100)
    model.save('{}.h5'.format(name))
    return model


def generate_text(model, char_indices, chars, seq_size, path):
    inp = 'When mecha'
    print char_indices
    for i in range(0, int(seq_size*.3)):
        print i
        out = inp
        idxs = [char_indices[c] for c in inp]
        for k in range(0, 200):
            arr = np.array(idxs)[np.newaxis, :]
            p = model.predict(arr)[0]
            p_sorted = sorted(p[-1])
            char = chars[np.where(p[-1] == random.choice(p_sorted[-3:]))[0][0]]
            out += char
            idxs = [char_indices[c] for c in out[-10:]]
        inp = out[-10:]
        file = open('{}_gen.csv'.format(path), 'aw')
        file.write('{}, {}\n'.format(i, ''.join(out)))
        file.close()


def main():
    paths = {"/home/remote/PycharmProjects/finalProject/wikipediaSummaries.csv", 'bbcArticls.csv', 'tripAdvisorBlogPosts.csv'}
    for path in paths:
        name = os.path.basename(path).split('.')[0]
        print name
        print "preprocess"
        x_train, y_train, x_test, y_test, indices_char, char_indices, chars, seq_size = preprocess(path)
        print "train"
        model = train_model(x_train, y_train, len(indices_char)+1, name)
        print model.evaluate(x_test, y_test)
        generate_text(model, char_indices, chars, seq_size, name)


if __name__ == '__main__':
    main()