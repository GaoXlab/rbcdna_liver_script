import argparse
import os
from datetime import datetime

from hy.data_loader import load_sample_info, load_separate_cohorts
from hy.tab_files import aggregate_tab_file
from joblib import Parallel, delayed
from sklearn.model_selection import train_test_split

def get_location(location):
    if location == "WORKING_DIR":
        return args.working_dir
    elif location == "MODEL_DATA":
        return os.path.join(args.working_dir, "modelData")
    elif location == "SCRIPT":
        return os.path.join(args.working_dir, "script")
    elif location == "REPORT":
        return os.path.join(args.working_dir, "results/3_FeatureReduction")
    else:
        return os.path.join(args.working_dir, "results")

def process_task(task_id):
    # 动态生成文件路径（例如 train_1.tab, train_2.tab, ...）
    tab_file = os.path.join(get_location("WORKING_DIR"), f"train.tab")
    blacklist_file = os.path.join(get_location("SCRIPT"), "blacklist.bed")

    # 调用目标函数
    return aggregate_tab_file(tab_file, task_id, blacklist_file)

def main(args):
    # p100 to p70 and p30
    sample_info = load_sample_info(get_location("MODEL_DATA"), args.exp_name)
    p70_ids_path = os.path.join(get_location("MODEL_DATA") + f"/{args.exp_name}.trn.ids.txt")
    # always generate p70_ids_path
    if True:
        print(f"generating {args.exp_name}.ids.txt")
        p100 = load_separate_cohorts(get_location("MODEL_DATA"), args.exp_name, "p100")
        p70, p30, y_p70, y_p30 = train_test_split(sample_info.loc[p100.index],
                     sample_info.loc[p100.index]['target'],
                     test_size=0.3,
                     stratify=sample_info.loc[p100.index]['target'],
                     random_state=1234)
        p70.to_csv(p70_ids_path, sep=',', index=True, header=False, columns=[])
        p30.to_csv(get_location("MODEL_DATA") + f"/{args.exp_name}.test.ids.txt", sep=',', index=True, header=False, columns=[])

        p70[p70['target'] == 0].index.to_series().to_csv(get_location("MODEL_DATA") + f"/{args.exp_name}.neg.ids.txt", index=False, header=False)
        p70[p70['target'] == 1].index.to_series().to_csv(get_location("MODEL_DATA") + f"/{args.exp_name}.pos.ids.txt", index=False, header=False)

    script_dir = get_location("SCRIPT")
    model_data_dir = get_location("MODEL_DATA")
    # run $SCRIPT_DIR/make_tab.sh $MODEL_DATA_DIR/"${TYPE}_trn_ids.txt" manu_2502hcc_trim_q30_gcc_10k_cpm train.tab
    # 这里是为了生成train.tab文件
    os.system(f"bash {script_dir}/make_tab.sh {model_data_dir}/{args.exp_name}.trn.ids.txt manu_2502hcc_trim_q30_gcc_10k_cpm train.tab")
    # 并行处理 1-100 的任务
    Parallel(n_jobs=-1)(  # n_jobs=-1 使用所有可用CPU核心
        delayed(process_task)(i) for i in range(1, 101)  # 生成1到100的任务ID
    )

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("exp_name", help="实验名称 (如 gc hcc)")
    parser.add_argument('working_dir', help='工作目录')
    args = parser.parse_args()

    start_time = datetime.now()
    main(args)
    end_time = datetime.now()
    elapsed_time = end_time - start_time

    print(f"程序运行时间: {elapsed_time}")