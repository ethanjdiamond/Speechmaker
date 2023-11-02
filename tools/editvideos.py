import os
import moviepy.editor as mp
import moviepy.video.fx.all as vfx
from watson_developer_cloud import SpeechToTextV1

VIDEOS_FILEPATH = "videos/"

for folder in os.listdir(VIDEOS_FILEPATH):
    if folder.startswith("."):
        continue
    for video in os.listdir(VIDEOS_FILEPATH + folder):
        if video.startswith("."):
            continue
        clip = mp.VideoFileClip(VIDEOS_FILEPATH + folder + "/" + video)
        if clip.duration < 0.3:
            os.remove(VIDEOS_FILEPATH + folder + "/" + video)
            print("Deleted " + VIDEOS_FILEPATH + folder + "/" + video)
        else:
            clip = clip.resize(width=720, height=720)
            clip.write_videofile(
                VIDEOS_FILEPATH + folder + "/" + video,
                codec="libx264",
                audio_codec="aac",
                temp_audiofile="temp-audio.m4a",
                remove_temp=True,
                verbose=False,
            )
            print("Resized " + VIDEOS_FILEPATH + folder + "/" + video)
