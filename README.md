<h1>Description</h1>
An Experiment with chuck used to autogenerate music base on phonemes. I had lofty goals of affecting the music based on the connotation of the words used, but never actually got there.

This was never fully finished, but all of the main pieces are in place to add new instruments and autogenerate some music.

<h1>Usage</h1>
<h2>Playing music</h2>

[instrument_list] is a colon separated list of instrument files i.e. inst/drums1.ck:inst/keyboard1.ck

Generating Phonemes on the fly:
`chuck tg.ck phogen.ck:false:"your text here":[instrument list] inst/phogen_instrument.ck --caution-to-the-wind`

From a phoneme file:
`chuck tg.ck phogen.ck:true:"Dictionary/phonemes/test.pho":[instrument list] inst/phogen_instrument.ck`

To record to a wav file, add this to the command
rec.ck:[filename].wav

<h2>Generating phonemes</h2>
`python Dictionary/mk_phoneme.py "your text here" >> phonemes/[filename].pho`

<h1>Examples</h1>
Sample2.wav was generated using the first twenty or so lines of "The Chaos" by G. Nolst Trenite.

The phoneme file is phonemes/sample2.pho

The instruments used were drums1 and keyboard1

So you can regenerate this audio by running the following command
`chuck tg.ck phogen.ck:true:"phonemes/sample2.pho":inst/drums1.ck:inst/keyboard1.ck inst/phogen_instrument.ck rec.ck:new_sample.wav`