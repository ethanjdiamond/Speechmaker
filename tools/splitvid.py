import json
import os
import random
import string
import os
import math
import moviepy.editor as mp
import moviepy.video.fx.all as vfx
from watson_developer_cloud import SpeechToTextV1

# SETUP
WATSON_USERNAME = os["WATSON_USERNAME"]
WATSON_PASSWORD = os["WATSON_PASSWORD"]

BASE_FILEPATH = "source/"
MP3_NAME = BASE_FILEPATH + "temp.mp3"
WAV_NAME = BASE_FILEPATH + "temp.wav"
JSON_NAME = BASE_FILEPATH + "temp.json"

VIDEOS_FILEPATH = "videos/"

SPLIT_LENGTH = 60

speech_to_text = SpeechToTextV1(
    username=WATSON_USERNAME, password=WATSON_PASSWORD, x_watson_learning_opt_out=False
)

if not os.path.exists(VIDEOS_FILEPATH):
    os.makedirs(VIDEOS_FILEPATH)

# FOR EACH CLIP

for filename in os.listdir(BASE_FILEPATH):
    try:
        # MAKE CLIP SQUARE
        print("STARTING " + filename)
        full_clip = mp.VideoFileClip(BASE_FILEPATH + filename)

        print("MAKE CLIP SQUARE")
        square_offset = (full_clip.w - full_clip.h) / 2
        clip = full_clip.fx(
            vfx.crop,
            x1=square_offset,
            y1=0,
            x2=square_offset + full_clip.h,
            y2=full_clip.h,
        )

        # BREAK INTO PIECES
        clip_count = int(math.ceil(clip.duration / SPLIT_LENGTH))
        for clip_index in range(0, clip_count):
            try:
                # GET WAV FROM VIDEO
                print(
                    "STARTING SUBCLIP "
                    + str(clip_index + 1)
                    + " OF "
                    + str(clip_count)
                    + " FOR "
                    + filename
                )
                print("CONVERTING FILE TO WAV")
                subclip_start_time = clip_index * (clip.duration / clip_count)
                subclip_end_time = (clip_index + 1) * (clip.duration / clip_count)
                subclip = clip.subclip(subclip_start_time, subclip_end_time)
                subclip.audio.write_audiofile(WAV_NAME, verbose=False)

                # SEND WAV TO TEXT TO SPEECH AND WRITE TO FILE
                print("SENDING TO WATSON")
                with open(
                    os.path.join(os.path.dirname(__file__), WAV_NAME), "rb"
                ) as audio_file:
                    text = speech_to_text.recognize(
                        audio_file,
                        content_type="audio/wav",
                        timestamps=True,
                        continuous=True,
                    )
                    dumped_json = json.dumps(text, indent=2)

                    the_file = open(JSON_NAME, "w+")
                    the_file.write(dumped_json)
                    the_file.close()

                # CUT UP THE VIDEO
                print("CUTTING UP THE VIDEO")
                the_file = open(JSON_NAME, "r+")
                data = json.load(the_file)
                for result in data["results"]:
                    for timestamp in result["alternatives"][0]["timestamps"]:
                        try:
                            word = timestamp[0]
                            word_start_time = float(timestamp[1])
                            word_end_time = float(timestamp[2])
                            clip_name = "".join(
                                random.choice(string.ascii_uppercase + string.digits)
                                for _ in range(5)
                            )  # random 5 char alphanum

                            word_folder = os.path.join(VIDEOS_FILEPATH, word)
                            word_subclip_output_path = os.path.join(
                                word_folder, clip_name + ".mp4"
                            )
                            word_subclip = subclip.subclip(
                                word_start_time, word_end_time
                            )

                            if word_subclip.duration < 0.3:
                                continue

                            word_subclip.resize(width=720, height=720)

                            # WRITE IT OUT
                            print("WRITING")
                            if not os.path.exists(word_folder):
                                os.makedirs(word_folder)
                            word_subclip.write_videofile(
                                word_subclip_output_path,
                                codec="libx264",
                                audio_codec="aac",
                                temp_audiofile="temp-audio.m4a",
                                remove_temp=True,
                                verbose=False,
                            )
                        except Exception as e:
                            print("ERROR: " + str(e))
            except Exception as e:
                print("CLIP ERROR: " + str(e))
    except Exception as e:
        print("FULL VIDEO ERROR " + str(e))
