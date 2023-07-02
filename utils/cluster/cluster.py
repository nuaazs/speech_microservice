
import sys
sys.path.append("/home/zhaosheng/asr_damo_websocket/online/speaker-diraization")

from utils.encoder import similarity as sim

import cfg
import os
import torch
import torchaudio
from itertools import combinations
import numpy as np
from utils.oss import upload_file

def find_optimal_subset(file_emb, similarity_threshold,spkid, save_wav_path=None):
    embeddings = file_emb['embedding']
    lengths = file_emb['length']
    files = list(embeddings.keys())
    # sort files by filesize (descending)
    files.sort(key=lambda x: os.path.getsize(x), reverse=True)
    files= files[:cfg.MAX_WAV_NUMBER]
    # 计算所有可能的子集，并按照长度降序排序
    subsets = []
    for r in range(1, len(files) + 1):
        subsets.extend(combinations(files, r))
    subsets.sort(key=len, reverse=True)
    subsets=subsets
    
    # 逐个检查子集，找到第一个满足条件的最优解
    for subset in subsets:
        subset_embeddings = [embeddings[file] for file in subset]
        
        # 计算所有子集中的余弦相似度最小值
        min_similarity = 1.0
        similarity_list = []
        for vec1, vec2 in combinations(subset_embeddings, 2):
            similarity = sim(torch.tensor(vec1), torch.tensor(vec2))
            similarity_list.append(similarity)
            if similarity < min_similarity:
                min_similarity = similarity
        mean_similarity = np.mean(similarity_list)
        # 检查余弦相似度是否满足条件
        if mean_similarity >= similarity_threshold or len(subset) == 1:
            selected_files = list(subset)
            total_duration = sum(lengths[file] for file in selected_files)
            # 保存音频
            if save_wav_path is not None:
                os.makedirs(save_wav_path, exist_ok=True)
                selected_files = sorted(selected_files, key=lambda x: x.split("/")[-1].replace(".wav","").split("_")[0])
                selected_times = [(_data.split("/")[-1].replace(".wav","").split("_")[0],_data.split("/")[-1].replace(".wav","").split("_")[1]) for _data in selected_files]
                audio_data = np.concatenate([torchaudio.load(file)[0] for file in selected_files], axis=-1)
                torchaudio.save(os.path.join(save_wav_path,f"{spkid}_selected.wav"), torch.from_numpy(audio_data),sample_rate=16000)
                url = upload_file("raw",os.path.join(save_wav_path,f"{spkid}_selected.wav"),f"{spkid}_selected.wav")
            return selected_files, total_duration,url,os.path.join(save_wav_path,f"{spkid}_selected.wav"),selected_times
    return [], 0,"","",[]

# if __name__ =='__main__':
    # find_optimal_subset(file_emb, similarity_threshold, save_wav_path=None)