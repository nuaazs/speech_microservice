import os
import subprocess

def get_sub_wav(wav_file_path, save_folder, timelist, smooth_threshold, min_duration):
    total_number = 0
    for i in range(len(timelist)-1):
        if timelist[i+1][0] - timelist[i][1] < smooth_threshold:
            timelist[i+1][0] = timelist[i][0]
            timelist[i][1] = timelist[i+1][1]
    timelist = list(set([tuple(t) for t in timelist]))
    timelist = [_item for _item in timelist if _item[1] - _item[0] >= min_duration]
    for item in timelist:
        start = item[0] / 1000
        stop = item[1] / 1000
        if stop - start < min_duration:
            continue
        filename = f"{start:.2f}_{stop:.2f}.wav"
        save_path = os.path.join(save_folder, filename)
        cmd = f"ffmpeg -i {wav_file_path} -ss {start} -to {stop} -y {save_path} > /dev/null 2>&1"
        subprocess.call(cmd, shell=True)
        total_number = total_number + 1
    file_list = [os.path.join(save_folder, _file) for _file in os.listdir(save_folder) if _file.endswith(".wav")]
    return file_list