import os
import shutil

VIDEOS_FILEPATH = "videos/"
BATCH_PREFIX = "batch_"
BATCH_SIZE = 100

batch_number = 1
current_folder = ""


def createNewBatchFolder():
    global batch_number
    global current_folder

    current_folder = VIDEOS_FILEPATH + BATCH_PREFIX + str(batch_number)
    os.makedirs(current_folder)
    batch_number += 1


createNewBatchFolder()
current_count = 0
for folder in os.listdir(VIDEOS_FILEPATH):
    if folder.startswith("."):
        continue
    if folder.startswith(BATCH_PREFIX):
        continue

    if current_count > BATCH_SIZE:
        current_count = 0
        createNewBatchFolder()

    shutil.move(VIDEOS_FILEPATH + folder, current_folder)
    current_count += 1
