public class PhogenInstrument {
    Gain ins_gain;
    0 => int debug_score;

    //The compiled score
    int score[0][0];
    int repeat_phoneme_score[0][0];

    //used for phrase composition
    int current_phoneme;
    int next_phoneme;
    int phrase_commands_used;
    int phrase_commands_left;
    int measures_passed;
    int loop_index;
    int repeat_counts[];

    1 => float beat_speed;

    fun void setBeatSpeed(float set_beat_speed) {
        set_beat_speed => beat_speed;
    }

    fun void connect( UGen ugen ) {

    }

    fun void start() {
        Global.instrument_ready.broadcast();

        Global.compose => now;
        compose();

        Global.play => now;
        prep();

        while (true) {
            Global.play => now;
            play(Global.pho.current_phrase_play_from, Global.pho.current_phrase_size);
        }
    }

    fun void ready() {
        Global.instrument_ready.broadcast();
    }

    /*
     * The following functions are used for the weighting system
     */
    //all weighted arrays should total 40
    fun int[][] getTotalWeights(int weights[][]) {
        int ret_val[0][0];
        for (0 => int i; i < weights.size(); i++ ) {
            int weight_choice_index[0];
            for (0 => int j; j < weights[i].size(); j++ ) {
                for (0 => int k; k < weights[i][j]; k++ ) {
                    weight_choice_index << j;
                }
            }
            ret_val << weight_choice_index;
        }

        return ret_val;
    }

    /*
     * The following functions are used to compile the full score
     */
    fun void compose() {
        ready();

        Global.compose_phrase => now;

        if (Global.pho.attr[0]) {
            slow();
        } else if (Global.pho.attr[1]) {
            fast();
        }

        //initialize shit based on phrase details
        0 => phrase_commands_used;
        Global.pho.phrase_score.size() => phrase_commands_left;
        handlePhraseStart(Global.pho.phrase_score[0]);
        handleMeasureStart(Global.pho.phrase_score[0]);

        0 => loop_index;
        Global.pho.phrase_loops[loop_index] @=> repeat_counts;
        prepareLoops();

        for (0=>int i; i < Global.pho.phrase_score.size(); i++) {
            Global.pho.phrase_score[i] => current_phoneme;
            if (i != Global.pho.phrase_score.size() - 1) {
                Global.pho.phrase_score[i+1] => next_phoneme;
            } else {
                -1 => next_phoneme;
            }
            handlePhoneme(current_phoneme);
        }
        ready();
        if (debug_score){ <<< "++++++++++++ PHRASE END ++++++++++++" >>>; }

        //if there is more to compose, wait for it
        if (!Global.pho.last_phrase) {
            compose();
        } else {
            handlePhraseEnd(current_phoneme);
            ready();
        }
    }

    public void handlePhraseEnd(int phoneme_index) {

    }

    public void handlePhraseStart(int phoneme_index) {

    }

    public void handleMeasureEnd(int phoneme_index) {

    }

    public void handleMeasureStart(int phoneme_index) {

    }

    public void handlePhoneme(int phoneme_index) {

    }

    public void loopMeasures(int measure_count, int loop_count) {
        if (repeat_phoneme_score.size() > 0) {
            for (0=>int i; i < loop_count; i++) {
                if (debug_score){ <<< "++++++++++++ LOOP " + (i + 1) + " ++++++++++++" >>>; }
                for (0=>int j; j < repeat_phoneme_score.size(); j++) {
                    if (debug_score){ outputCommand("rpt", repeat_phoneme_score[j]); }
                    addCommandToScore(repeat_phoneme_score[j]);
                }
            }
        }

        prepareLoops();
    }

    public void prepareLoops() {
        0 => measures_passed;
        int empty[0][0] @=> repeat_phoneme_score;
    }

    public void storeCommand(int command[]) {
        repeat_phoneme_score << command;
        if (debug_score){ outputCommand("str", command); }
        addCommandToScore(command);
    }

    private void addCommandToScore(int command[]) {
        score << command;
        1 -=> phrase_commands_left;
        1 +=> phrase_commands_used;

        if (phrase_commands_used % Global.pho.beat_count == 0) {
            //ending a measure
            handleMeasureEnd(current_phoneme);

            if (debug_score){ <<< "++++++++++++ MEASURE END ++++++++++++" >>>; }
            1 +=> measures_passed;
            if (measures_passed == repeat_counts[0]) {

                if (debug_score){ <<< "++++++++++++ LOOP START (" + repeat_counts[0] + "/" + repeat_counts[1] + ")++++++++++++" >>>; }
                loopMeasures(repeat_counts[0], repeat_counts[1] - 1);
                if (debug_score){ <<< "++++++++++++ LOOP END ++++++++++++" >>>; }

                if (Global.pho.phrase_loops.size() > (loop_index + 1)) {
                    1 +=> loop_index;
                    Global.pho.phrase_loops[loop_index] @=> repeat_counts;
                }
            }


            //starting a measure
            if (next_phoneme > -1) {
                handleMeasureStart(current_phoneme);
            }
        }
    }

    public int canStoreCommand() {
        return (phrase_commands_left > 0);
    }

    public void outputCommand(string prefix, int command[]) {
        "" => string output_string;
        for (command.size() - 1=>int i; i >= 0; i--) {
            ":" + command[i] + output_string => output_string;
        }
        <<< prefix + output_string >>>;
    }

    /*
     * The following functions are used to prep an instrument for a specific time
     */
    public void prep() {
        ready();
    }

    public void prepPhrase(int command[]) {

    }

    /*
     * The following functions are used to switch tracks
     */
    public void fast() {

    }

    public void slow() {

    }

    /*
     * The following functions are used to play a command from the score
     */
    public void play(int play_from, int play_size) {
        prepPhrase(score[play_from]);
        1 => int at_measure;

        for (0=>int i; i < play_size; i++) {
            playCommand(score[play_from + i]);
            Global.pho.tg.beat * beat_speed => now;
        }

        ready();
    }

    public void playCommand(int command[]) {

    }
}