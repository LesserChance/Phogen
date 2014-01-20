// global reference to the Phogen using Global.pho
public class Global {
    static Phogen @ pho;
    static Event @ compose;
    static Event @ compose_phrase;
    static Event @ play;
    static Event @ instrument_ready;
}

//init global references
Phogen p @=> Global.pho;
Event com @=> Global.compose;
Event com_phrase @=> Global.compose_phrase;
Event pla @=> Global.play;
Event ins @=> Global.instrument_ready;

//init the phogen
me.arg(0) => string use_file;
me.arg(1) => string file_text;

string instrument_list[0];
for (2 => int i; i < me.args(); i++) {
    instrument_list << me.arg(i);
}

2 => int beat_count;     //number of beats in a measure
4 => int measure_count;  //number of measures in a phrase

Global.pho.init(use_file, file_text, instrument_list, beat_count, measure_count);

class Phogen {

    TimeGrid tg;
    int bpm;
    int beat_count;
    int measure_count;
    int phrase_size;
    int max_offset;

    string filename;

    string phoneme_list[0];
    int phoneme_score[0];
    int instrument_shreds[0];


    [
        1,  //slow
        0   //fast
    ] @=> int attr[];

    int current_phrase_size;
    int current_phrase_play_from;
    int phrase_sizes[0];
    int phrase_score[];
    int phrase_loops[][];

    int last_phrase;

    //Keep track of all assignable phonemes 0 - 39
    [
        "AA","AE","AH","AO","AW","AY","B","CH","D",
        "DH","EH","ER","EY","F","G","HH","IH","IY","JH","K","L","M","N","NG",
        "OW","OY","P","R","S","SH","T","TH","UH","UW","V","W","Y","Z","ZH","SIL"
    ] @=> string phonemes[];

    phonemes.size() - 1 => int phoneme_max;


    public void init(string use_file, string file_text, string instrument_list[], int beat_count, int measure_count) {

        setBeatCount(beat_count, measure_count);

        file_text => this.filename;
        if (use_file == "true") {
            <<< "READING FROM " + file_text >>>;
            calculate(file_text);
            <<< "DONE" >>>;
        } else {
            <<< "GENERATING PHONEMES" >>>;
            Std.system("python Dictionary/mk_phoneme.py \"" + file_text + "\" > temp.pho");
            calculate("temp.pho");
            <<< "DONE" >>>;
        }

        int empty[this.phrase_size] @=> this.phrase_score;
        phoneme_score.size() => this.max_offset;

        //determine bpm params (100 - 160)
        getScore(0, max_offset) % 60 => int bpm_score;
        100 + bpm_score => this.bpm;
        setBeatCount(4,4);

        for (0 => int i; i < instrument_list.size(); i++) {
            <<< "ADD " + instrument_list[i] >>>;
            instrument_shreds << Machine.add(instrument_list[i]);
            <<< instrument_shreds >>>;
            Global.instrument_ready => now;
        }

        //need to wait until all instruments are ready to play
        1::ms => now;
        compose();

        1::ms => now;
        play();
    }

    fun void setBeatCount(int set_beat_count, int set_measure_count) {
        set_beat_count => this.beat_count;
        set_measure_count => this.measure_count;
        tg.set(1::minute/bpm, set_beat_count, set_measure_count);

        set_beat_count * set_measure_count => this.phrase_size;
    }

    fun int getIndex(string phoneme) {
        for (0=>int i; i <= phoneme_max; i++) {
            if (phonemes[i] == phoneme) {
                return i;
            }
        }
    }

    fun void calculate(string filename) {
        FileIO fio;
        fio.open(filename, FileIO.READ);

        while (fio.more()) {
            fio.readLine() => string str;
            if (str != "") {
                phoneme_list << str;
                phoneme_score << getIndex(str);
            }
        }
    }

    fun int getScore(int start_index, int end_index) {
        0 => int score_total;

        for (start_index => int i; i <= end_index; i++) {
            if (i < max_offset) {
                phoneme_score[i] +=> score_total;
            }
        }

        return score_total;
    }

    fun void compose() {
        //tell everyone composition is starting
        Global.compose.broadcast();
        wait();

        0 => int start_offset;

        while (start_offset < max_offset) {
            //song attributes
            for (0 => int j; j < attr.size(); j++) {
                0 => attr[j];
            }

            1 => attr[generatePRN(0, attr.size() - 1, phoneme_score[start_offset])];

            //determine measure_count 2-5
            phoneme_score[start_offset] % 4 => int measure_shift;

            //Determine phrase size
            setBeatCount(this.beat_count, 5 - measure_shift);

            phrase_sizes << this.phrase_size;

            //Determine if this is the last phrase of the song
            if ((start_offset + this.phrase_size) >= max_offset) {
                1 => last_phrase;
            } else {
                0 => last_phrase;
            }

            //Begin phrase composition
            int empty[this.phrase_size] @=> phrase_score;
            0 => int phoneme_phrase_total;
            for (0 => int i; i < phrase_size; i++) {
                start_offset + i => int phoneme_index;
                if (phoneme_index < max_offset) {
                    phoneme_score[phoneme_index] @=> phrase_score[i];
                    phoneme_score[phoneme_index] +=> phoneme_phrase_total;
                }
            }

            getMeasureLoops(phoneme_phrase_total, 3) @=> phrase_loops;

//            <<< "Phrase Data" >>>;
//            <<< "bpm: " + this.bpm >>>;
//            <<< "beat_count:" + beat_count >>>;
//            <<< "measure_count:" + measure_count >>>;
//            <<< "phrase_size:" + phrase_size >>>;
//            <<< "-----------" >>>;

            //tell each instrument to compose a phrase
            Global.compose_phrase.broadcast();
            wait();

            phrase_size +=> start_offset;
        }
    }

    fun void play() {
        tg.sync();

        //prep instruments
        Global.play.broadcast();
        wait();

        //begin playing
        0 => int phrase_play_from;
        for (0 => int i; i < phrase_sizes.size(); i++) {
            phrase_sizes[i] => this.current_phrase_size;
            phrase_play_from => this.current_phrase_play_from;

            Global.play.broadcast();
            wait();

            phrase_play_from + this.current_phrase_size => phrase_play_from;
        }

        1::second => now;
        end();
    }

    fun void end() {
        for (instrument_shreds.size() - 1 => int i; i >=0 ; i--) {
            Machine.remove(instrument_shreds[i]);
        }
        1::second => now;
    }

    fun void wait() {
        Global.instrument_ready => now;
    }


    /*
     * The following functions are used for determining repetition to generate a phrase
     */
    fun int[][] getMeasureLoops(int phoneme_total_score, int min_loop_count) {
        int empty[0][0] @=> int ret_val[][];

        measure_count => int measures_to_fill;
        while (measures_to_fill > 0) {
            getMeasureLoopPiece(measures_to_fill, phoneme_total_score, min_loop_count) @=> int ret_val_piece[];
            measures_to_fill - (ret_val_piece[0] * ret_val_piece[1]) => measures_to_fill;

            ret_val << ret_val_piece;

            //generate new pseudo random numbers
            1 +=> phoneme_total_score;
        }

        return ret_val;
    }

    fun int[] getMeasureLoopPiece(int measures_to_fill, int phoneme_total_score, int min_loop_count) {
        int ret_val[2];

        //Determine loop count
        if (measures_to_fill < min_loop_count) {
            measures_to_fill => min_loop_count;
        }
//        Math.floor(measures_to_fill / 2) $ int => int max_loop_count;
        measures_to_fill => int max_loop_count;
        if (max_loop_count == 0) {
            1 => max_loop_count;
        }

        generatePRN(min_loop_count, max_loop_count, phoneme_total_score) => int set_loop_count;
//        2 => int set_loop_count;

        //Determine measure count
        Math.floor(measures_to_fill / set_loop_count) $ int => int max_measure_count;
        generatePRN(1, max_measure_count, phoneme_total_score) => int set_measure_count;

        //1 in 5 change of flipping measure/loop
        if (generatePRN(0, 4, phoneme_total_score - 1) > 0) {
            set_measure_count => ret_val[0];
            set_loop_count => ret_val[1];
        } else {
            set_measure_count => ret_val[1];
            set_loop_count => ret_val[0];
        }

        return ret_val;
    }

    fun int generatePRN(int min, int max, int seed) {
        Math.srandom(seed);
        return Math.random2(min, max);
    }
}



