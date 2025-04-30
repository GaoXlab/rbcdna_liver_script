# 模型参数
MODEL_PARAMS = {
    'n': 1000,
    'n_pcas': 30,
    'n_feas': 5,
    'n_skip': 0,
    'smote_random_state': 1234,
    'xgb_params': {
        'objective': 'binary:logistic',
        'eval_metric': 'logloss',
        'learning_rate': 0.1,
        'n_estimators': 100,
        'max_depth': 3,
        'subsample': 0.6,
        'min_child_weight': 1,
        'colsample_bytree': 0.8,
        'random_state': 1234,
        'n_jobs': 8
    },
    'lr_params': {
        'class_weight': 'balanced', 
        'C': 1,
        'penalty': 'l2', 
        'solver': 'liblinear'
    }
}
