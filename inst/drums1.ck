class Drums1 extends PhogenInstrument {
    1 => beat_speed;

    .8 => ins_gain.gain;

    Shakers hhs => JCRev r;
    .025 => r.mix;
    Std.mtof( 76 ) => hhs.freq;

    SinOsc s => ADSR bda;
    80 => s.freq;
    2 => s.gain;
    (1::ms, 10::ms, 0.0, 50::ms ) => bda.set;

    Noise n => ADSR sna => Gain g => dac;
    0.3 => g.gain;
    (0::ms, 25::ms, 0.0, 0::ms) => sna.set;

    [
        [0,0,0,0], //0
        [0,0,0,1], //1
        [0,0,1,0], //2
        [0,0,1,1], //3
        [0,1,0,0], //4
        [0,1,0,1], //5
        [0,1,1,0], //6
        [0,1,1,1], //7
        [1,0,0,0], //8
        [1,0,0,1], //9
        [1,0,1,0], //10
        [1,0,1,1], //11
        [1,1,0,0], //12
        [1,1,0,1], //13
        [1,1,1,0], //14
        [1,1,1,1]  //15
    ] @=> int speed_rhythms[][];

    0 => int hh_weight_choice;
    0 => int sn_weight_choice;
    0 => int bd_weight_choice;
    2 => int max_weight_choice;

    //each index has a weight out of 40
    [
        [10,0,0,0,0,0,0,0,25,0,5,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0,0,40,0,0,0,0,0],
        [0,0,0,0,0,10,0,0,0,0,0,0,0,0,0,30],
        [35,5,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
        [0,1,4,2,1,4,1,0,10,2,9,1,1,0,4,0],
        [3,3,3,3,3,3,3,3,3,3,3,3,3,2,1,1]
    ] @=> int hh_weights[][];
    getTotalWeights(hh_weights) @=> int hh_weights_total[][];

    [
        [30,5,0,0,0,0,0,0,5,0,0,0,0,0,0],
        [30,5,0,0,0,0,0,0,5,0,0,0,0,0,0],
        [10,5,5,5,0,1,2,2,5,5,0,0,0,0,0],
        [3,3,3,3,3,3,3,3,3,3,3,3,3,2,1,1]
    ] @=> int bd_weights[][];
    getTotalWeights(bd_weights) @=> int bd_weights_total[][];

    [
        [30,0,0,0,0,0,0,0,10,0,0,0,0,0,0],
        [30,0,2,0,0,0,0,0,8,0,0,0,0,0,0],
        [20,0,0,0,0,2,0,0,18,0,0,0,0,0,0],
        [20,0,0,0,0,0,0,0,20,0,0,0,0,0,0],
        [3,3,3,3,3,3,3,3,3,3,3,3,3,2,1,1]
    ] @=> int sn_weights[][];
    getTotalWeights(sn_weights) @=> int sn_weights_total[][];

    public void connect( UGen ugen ) {
//        r => ins_gain => ugen;
//        bda => ins_gain => ugen;
//        g => ins_gain => ugen;
        r  => ugen;
        bda => ugen;
        g => ugen;
    }

//    public void flipHhSpeed() {
//        if (hh_speed == 2) {
//            4 => hh_speed;
//        } else {
//            2 => hh_speed;
//        }
//    }
//
//    public void flipBdSpeed() {
//        if (bd_speed == 2) {
//            4 => bd_speed;
//        } else {
//            2 => bd_speed;
//        }
//    }
//
//    public void flipSnSpeed() {
//        if (sn_speed == 2) {
//            4 => sn_speed;
//        } else {
//            2 => sn_speed;
//        }
//    }

    /*
     * The following functions are used to compile the full score
     */
    public void handlePhraseEnd(int phoneme_index) {

    }

    public void handlePhraseStart(int phoneme_index) {

    }

    public void handleMeasureEnd(int phoneme_index) {

    }

    public void handleMeasureStart(int phoneme_index) {
        //hh weight
        if (phoneme_index % 3 == 0) {
            if (hh_weight_choice < max_weight_choice) {
                1 +=> hh_weight_choice;
            }
        }
        if (phoneme_index % 2 == 0) {
            if (hh_weight_choice > 0) {
                1 -=> hh_weight_choice;
            }
        }

        //bd weight
        if (phoneme_index % 2 == 0) {
            if (bd_weight_choice < max_weight_choice) {
                1 +=> bd_weight_choice;
            }
        }
        if (phoneme_index % 3 == 0) {
            if (bd_weight_choice > 0) {
                1 -=> bd_weight_choice;
            }
        }

        //sn weight
        if (phoneme_index % 3 == 0) {
            if (sn_weight_choice < max_weight_choice) {
                1 +=> sn_weight_choice;
            }
        }
        if (phoneme_index % 2 == 0) {
            if (sn_weight_choice > 0) {
                1 -=> sn_weight_choice;
            }
        }
    }

    public void handlePhoneme(int phoneme_index) {
        //hh rhythm index
        hh_weights_total[hh_weight_choice][phoneme_index] => int hh_rhythm_index;

        //bd rhythm index
        bd_weights_total[bd_weight_choice][phoneme_index] => int bd_rhythm_index;

        //sn rhythm index
        sn_weights_total[sn_weight_choice][Global.pho.phoneme_max - phoneme_index] => int sn_rhythm_index;

        1 => int set_beat_speed;
//        if (bd_weight_choice == 2) {
//            2 => set_beat_speed;
//        }

        //these are the arguments that will get passed to the play function
        storeCommand([
            hh_rhythm_index,
            bd_rhythm_index,
            sn_rhythm_index,
            set_beat_speed
        ]);
    }

    /*
     * The following functions are used to play a command from the score
     */
    public void playCommand(int command[]) {
        command[0] => int hh_rhythm_index;
        command[1] => int bd_rhythm_index;
        command[2] => int sn_rhythm_index;
        command[3] => int set_beat_speed;

        set_beat_speed => beat_speed;

        spork ~ playHhRhythm(speed_rhythms[hh_rhythm_index]);
        spork ~ playBdRhythm(speed_rhythms[bd_rhythm_index]);
        spork ~ playSnRhythm(speed_rhythms[sn_rhythm_index]);

    }

    public void playBdRhythm(int rhythm[]) {
        for (0 => int i; i < rhythm.size(); i++ ) {
            if (rhythm[i]) {
                bd();
            }
            Global.pho.tg.beat * beat_speed / 4 => now;
        }
    }

    public void playSnRhythm(int rhythm[]) {
        for (0 => int i; i < rhythm.size(); i++ ) {
            if (rhythm[i]) {
                sn();
            }
            Global.pho.tg.beat * beat_speed / 4 => now;
        }
    }

    public void playHhRhythm(int rhythm[]) {
        for (0 => int i; i < rhythm.size(); i++ ) {
            if (rhythm[i]) {
                hh();
            }
            Global.pho.tg.beat * beat_speed / 4 => now;
        }
    }

    public void hh() {
        1 => hhs.noteOn;
    }

    public void bd() {
        1 => bda.keyOn;
    }

    public void sn() {
        1 => sna.keyOn;
    }
}

Drums1 drm;
drm.connect( dac );
drm.start();