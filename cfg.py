TEMP_PATH = "/tmp"
SR = 16000

NNVAD_DEVICE = "cuda:0"
ENCODE_CAMP_DEVICE = "cuda:0"
ENCODE_ECAPATDNN_DEVICE = "cuda:0"
GENDER_DEVICE = "cuda:0"
LANGUAGE_DEVICE = "cuda:0"
PUNC_PYTHON_DEVICE = "gpu:1"
ASR_PYTHON_DEVICE = "gpu:1"

ENCODE_MODEL_LIST = ["ECAPATDNN", "CAMPP"]
BLACK_TH = {"ECAPATDNN": 0.78, "CAMPP": 0.78}
EMBEDDING_LEN = {"ECAPATDNN": 192, "CAMPP": 512}

MYSQL = {
    "host": "192.168.3.169",
    "port": 3306,
    "db": "si",
    "username": "zhaosheng",
    "passwd": "Nt3380518",
}

REDIS = {
    "host": "127.0.0.1",
    "port": 6379,
    "register_db": 1,
    "test_db": 2,
    "password": "",
}

MINIO = {
    "host": "192.168.3.169",
    "port": 9000,
    "access_key": "zhaosheng",
    "secret_key": "zhaosheng",
    "test_save_days": 30,
    "register_save_days": -1,
    "register_raw_bucket": "register_raw",
    "register_preprocess_bucket": "register_preprocess",
    "test_raw_bucket": "test_raw",
    "test_preprocess_bucket": "test_preprocess",
    "pool_raw_bucket": "pool_raw",
    "pool_preprocess_bucket": "pool_preprocess",
    "black_raw_bucket": "black_raw",
    "black_preprocess_bucket": "black_preprocess",
    "white_raw_bucket": "white_raw",
    "white_preprocess_bucket": "white_preprocess",
    "zs": b"zhaoshengzhaoshengnuaazs",
}
BUCKETS = ["raw", "preprocess", "preprocessed", "testing", "sep","vad"]