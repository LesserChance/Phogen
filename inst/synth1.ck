class Synth1 extends PhogenInstrument {
    1 => beat_speed;
    1 => int divide_beat_speed;

    0 => int weight_choice;

    [0, 2, 4, 5] @=> int maj[]; //major scale

    Phasor s;
    ADSR e;
    LPF lp;

    400 => int lp_freq;
    1 => int sweep_direction;
    1 => int sweep_amount;
    1::ms => dur sweep_duration;
    50 => int sweep_sample_length;

    200 => int s_freq;

    32 => int base_note;

    lp_freq => lp.freq;
    Std.mtof(base_note) $ int => s.freq;
    .9 => s.gain;

    1.5 => ins_gain.gain;
//    0 => ins_gain.gain;
    0 => int from_gain;

    e.set( 10::ms, 8::ms, .5, 500::ms );

    [
        [0,20,10,0,10,0,0,0,0,0,0],
        [0,5,35,0,0,0,0,0,0,0,0]
    ] @=> int beat_speed_weights[][];
    getTotalWeights(beat_speed_weights) @=> int beat_speed_weights_total[][];

    [
        [20,0,0,0,20,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0,40,0]
    ] @=> int sweep_amount_weights[][];
    getTotalWeights(sweep_amount_weights) @=> int sweep_amount_weights_total[][];

    [
        [30,0,0,0,0,10,0,0,0,0,0],
        [40,0,0,0,0,0,0,0,0,0,0]
    ] @=> int sweep_duration_weights[][];
    getTotalWeights(sweep_duration_weights) @=> int sweep_duration_weights_total[][];

    [
        [0,0,0,30,0,10,0,0,0,0],
        [0,35,5,0,0,0,0,0,0,0]
    ] @=> int note_length_weights[][];
    getTotalWeights(note_length_weights) @=> int note_length_weights_total[][];

    //used for phrase saving
    sweep_amount => int set_sweep_amount;
    1 => int set_sweep_duration;

    public void connect( UGen ugen ) {
//        s => e => lp => ins_gain => ugen;
        s => e => lp => ugen;
    }

    /*
     * The following functions are used to compile the full score
     */
    public void handlePhraseEnd(int phoneme_index) {

    }

    public void handlePhraseStart(int phoneme_index) {
        sweep_amount_weights_total[weight_choice][phoneme_index] + 1 => set_sweep_amount;
        sweep_duration_weights_total[weight_choice][phoneme_index] + 1 => set_sweep_duration;
        beat_speed_weights_total[weight_choice][phoneme_index] => divide_beat_speed;
    }

    public void handleMeasureEnd(int phoneme_index) {

    }

    public void handleMeasureStart(int phoneme_index) {

    }

    public void handlePhoneme(int phoneme_index) {
        //make sure I can store a command
        if (canStoreCommand()) {
            Global.pho.generatePRN(0, maj.size() - 1, phoneme_index) => int note;
            maj[note] + base_note => int interpolate_to;

            note_length_weights_total[weight_choice][phoneme_index] => int note_length;

            if (note_length > phrase_commands_left) {
                phrase_commands_left => note_length;
            }

            Global.pho.generatePRN(0, 5, phoneme_index) => int fade_out;

            //these are the arguments that will get passed to the play function
            storeCommand([
                interpolate_to,
                divide_beat_speed,
                set_sweep_amount,
                set_sweep_duration,
                fade_out
            ]);

            //insert empty commands for the note length
            for (1 => int i; i < note_length; i++ ) {
                storeCommand(int empty[0]);
            }
        }
    }

    public void prepPhrase(int command[]) {
        if (command.size() > 0) {
            //beat speed
            command[1] => int set_divide_beat_speed;
            (1 $ float / set_divide_beat_speed) => float set_new_beat_speed;
            setBeatSpeed(set_new_beat_speed);

            //sweep
            command[2] => int set_sweep_amount;
            command[3] => int set_sweep_duration;

            set_sweep_amount => sweep_amount;
            set_sweep_duration * 1::ms => sweep_duration;


            command[4] => int fade_out;
            if (fade_out == 0) {
                spork ~ gainDown(.01);
            } else {
                spork ~ gainUp(.01);
            }
        }
    }

    public void fast() {
        1 => weight_choice;
    }

    public void slow() {
        0 => weight_choice;
    }

    /*
     * The following functions are used to play a command from the score
     */
    public void playCommand(int command[]) {
        if (command.size() > 0) {
            command[0] => int interpolate_to;


            100 => lp_freq;
            spork ~ sweep(4000);

            spork ~ playNote(interpolate_to);
        }

    }

    public void playNote(int interpolate_to) {
        s_freq $ int => int from_freq;
        Std.mtof(interpolate_to) $ int => s_freq;


        e.keyOn();
        spork ~ interpolate(from_freq, s_freq, sweep_sample_length);
        (Global.pho.tg.beat * (beat_speed) / 2) => now; //attack for half a beat
        e.keyOff();
    }

    fun void interpolate(int from, int to, int len) {
        from => int freq;
        to - from => int dist;
        dist / len => int inc_freq;

        0 => int count;
        while (count < len) {
            inc_freq +=> freq;
            freq => s.freq;
            1::ms => now;
            1 +=> count;
        }
    }

    fun void sweep(int to_max) {
        while (lp_freq < to_max) {
            lp_freq => lp.freq;
            sweep_duration => now;
            sweep_amount * sweep_direction +=> lp_freq;
        }
    }

    fun void gainDown(float step_size) {
//        <<< "gain down" >>>;
//        from_gain => float set_gain;
//        while (set_gain > 0) {
//            set_gain => ins_gain.gain;
//            step_size -=> set_gain;
//            10::ms => now;
//        }
//        0 => from_gain;
    }

    fun void gainUp(float step_size) {
//        <<< "gain up" >>>;
//        from_gain => float set_gain;
//        while (set_gain < 1) {
//            set_gain => ins_gain.gain;
//            step_size +=> set_gain;
//            10::ms => now;
//        }
//        1 => from_gain;
    }
}

Synth1 synth;
synth.connect(dac);
synth.start();