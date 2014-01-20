class Keyboard1 extends PhogenInstrument {
    1 => beat_speed;

    //minor scales
    [0, 2, 3, 5, 7, 8, 10] @=> int min[]; //minor mode
    [0, 2, 3, 5, 7, 8, 11] @=> int har[]; //harmonic minor
    [0, 2, 3, 5, 7, 9, 11] @=> int asc[]; //ascending melodic minor
    [0, 1, 3, 5, 7, 8, 10] @=> int nea[]; //make 2nd degree neapolitain

    //other church modes
    [0, 2, 4, 5, 7, 9, 11] @=> int maj[]; //major scale
    [0, 2, 4, 5, 7, 8, 10] @=> int mixo[]; //church mixolydian
    [0, 2, 3, 5, 7, 9, 10] @=> int dor[]; //church dorian
    [0, 2, 4, 6, 7, 9, 11] @=> int lyd[]; //church lydian

    [0, 2, 4, 7, 9] @=> int pent[]; //major pentatonic
    [0, 1, 4, 5, 7, 8, 10] @=> int jewish[]; //phrygian dominant, jewish scale
    [0, 2, 3, 6, 7, 8, 11] @=> int gypsy[]; //hungarian or gypsy
    [0, 1, 4, 5, 7, 8, 11] @=> int arabic[]; //arabic scale
    [0, 2, 4, 6, 8, 10] @=> int whole_tone[]; //the whole tone scale
    [0, 2, 3, 5, 6, 8, 9, 11] @=> int dim[]; //diminished scale

    [
        [0,20,0,0,10,0,10,0,0,0,0],
        [0,10,0,0,30,0,0,0,0,0,0]
    ] @=> int note_length_weights[][];
    getTotalWeights(note_length_weights) @=> int note_length_weights_total[][];

    0 => int note_weight_choice;
    1 => int max_weight_choice;

    400 => int min_decay_rate;
    500 => int max_decay_rate;
    400 => int decay_rate;
    500 => int set_decay_rate;

    .1 => float reverb_mix;
    .5 => float reverb_gain;
    36 => int base_note;
    36 => int top_note;
    4  => int note_inc;
    36 => int start_base_note;

    //cycle through each pulse on use for less overdrive
    0 => int use_pulse;
    3 => int pulses;

    Impulse pulse_gen[pulses];      // pulse generator
    LPF str[pulses];                // low pass filter

    JCRev r;

    r.mix(.01);
    r.gain(.6);

    maj @=> int scale[];

    for(int i; i < pulses; i++) {
       2.5 => str[i].gain;
       pulse_gen[i] => str[i] => r;
       str[i].Q(decay_rate); // set string decay rate
    }


    public void connect( UGen ugen ) {
        r => ins_gain => ugen;
    }

    /*
     * The following functions are used to compile the full score
     */
    public void handlePhraseEnd(int phoneme_index) {

    }

    public void handlePhraseStart(int phoneme_index) {
        if (phoneme_index % 2 == 0) {
            if (note_weight_choice < max_weight_choice) {
                1 +=> note_weight_choice;
            }
        }
        if (phoneme_index % 4 == 0) {
            if (note_weight_choice > 0) {
                1 -=> note_weight_choice;
            }
        }
    }

    public void handleMeasureEnd(int phoneme_index) {

    }

    public void handleMeasureStart(int phoneme_index) {
        //set decay rate
        if (phoneme_index % 10 == 0) {
            if (base_note < top_note) {
                note_inc +=> base_note;
            }
        }
        if (phoneme_index % 5 == 0) {
            min @=> scale;
        }
        if (phoneme_index % 4 == 0) {
            maj @=> scale;
            start_base_note => base_note;
        }
    }

    public void handlePhoneme(int phoneme_index) {
        //make sure I can store a command
        if (canStoreCommand()) {
            phoneme_index % this.scale.size() => int note_index;
            this.scale[note_index] => int note;

            note_length_weights_total[note_weight_choice][phoneme_index] => int note_length;

            if (note_length > phrase_commands_left) {
                phrase_commands_left => note_length;
            }

            (50 * (note_length - 1)) + decay_rate => set_decay_rate;

            //these are the arguments that will get passed to the play function
            storeCommand([
                use_pulse,
                note,
                set_decay_rate,
                base_note,
                note_length
            ]);

            //insert empty commands for the note length
            for (1 => int i; i < note_length; i++ ) {
                storeCommand(int empty[0]);
            }

            1 +=> use_pulse;
            if (use_pulse % pulses == 0) {
                0 => use_pulse;
            }
        }
    }

    /*
     * The following functions are used to play a command from the score
     */
    public void playCommand(int command[]) {
        if (command.size() > 0) {
            command[0] => int pluck;
            command[1] => int note;
            command[2] => int set_decay;
            command[3] => int base_note;
            command[4] => int note_length;

            for(int i; i < pulses; i++) {
               str[i].Q(set_decay); // set string decay rate
            }

            spork ~ playKeys(pluck, note, base_note);
        }

    }

    public void playKeys(int pluck, int note, int base_note) {
        5 => pulse_gen[pluck].next; // pick the string
        Std.mtof(note + base_note) => str[pluck].freq; // set string note
        (Global.pho.tg.beat * beat_speed / 2) => now; //play for half a beat
    }
}

Keyboard1 keys;
keys.connect(dac);
keys.start();