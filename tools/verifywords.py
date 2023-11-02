# RERUN THE VIDEO FILE AGAINST WATSON TO CONFIRM IT'S CORRECT
print("VERIFYING WORD: " + word)
word_subclip.audio.write_audiofile(TMP_WAV_NAME, verbose=False)
with open(
    os.path.join(os.path.dirname(__file__), TMP_WAV_NAME), "rb"
) as tmp_audio_file:
    tmp_data = speech_to_text.recognize(tmp_audio_file, content_type="audio/wav")
    if len(tmp_data["results"]) > 0:
        tmp_word = tmp_data["results"][0]["alternatives"][0]["transcript"].strip()
        print("COMPARING WORDS: " + tmp_word + "|" + word)
