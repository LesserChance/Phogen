import sys
import re
import string

f = open('Dictionary/sphinxdict/cmudict.0.7a_SPHINX_40')
lines = f.readlines()
f.close()

word_trie = dict();
end = "|"
word_trie[end] = "";

for line in lines:
    word, phonemes = line.split('\t', 1)

    current_trie = word_trie
    for letter in word:
        if letter in current_trie:
            current_trie = current_trie[letter]
        else:
            current_trie[letter] = dict()
            current_trie = current_trie[letter]

    #we now have all letters, add the end signal and set it
    current_trie[end] = phonemes.replace("\n","")

def get_phoneme(word):
    current_trie = word_trie
    for letter in word:
        if letter in current_trie:                                              
            current_trie = current_trie[letter]                                 
        else:                                                                   
            return False

    if (end in current_trie):
        return current_trie[end]
    else:
        return ""

def phonemeize_text(text):
    ret_val = ""
    words = text.split(' ')
    for word in words:
        phoneme = get_phoneme(word.upper())
        if phoneme:
            phoneme_pieces = phoneme.split(' ')
            #uncomment for words in list (when using connotation)
            #ret_val = ret_val + "[" + word.upper() + "]\n"
            for piece in phoneme_pieces:
                ret_val = ret_val + piece + "\n"
    
    return ret_val

#NEED TO NOT STRIP OUT APOSTROPHES
phonemeize = sys.argv[1].translate(string.maketrans("",""), string.punctuation);
print phonemeize_text(phonemeize);
