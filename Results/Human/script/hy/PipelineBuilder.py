from typing import Dict, Any

from imblearn.pipeline import Pipeline as ImbPipeline
from sklearn.linear_model import LogisticRegression
from sklearn.pipeline import Pipeline
from xgboost import XGBClassifier

from .Estimator import *


class PipelineBuilder:
    def __init__(self, config: Dict[str, Any] = None):
        self._parent_builder = None
        self.config = config
        self.steps = []
        self._has_classifier = False  # 标记是否已添加classifier
        self._sub_pipelines = []  # 用于存储子pipeline(用于ensemble模型)

    def add_pca_feature_combiner(self) -> 'PipelineBuilder':
        """添加特征组合步骤"""
        self.steps.append((
            'pca_feature_combiner',
            PCABasedFeatureCombiner(self.config['n_pcas'], self.config['n_feas'], self.config['n_skip'])
        ))
        return self

    def add_classifier(self, classifier) -> 'PipelineBuilder':
        """添加分类器"""
        if self._has_classifier:
            raise ValueError("Classifier already added to pipeline. Only one classifier is allowed.")

        self.steps.append(('classifier', classifier))
        self._has_classifier = True
        return self
    # ================== 集成模型相关方法 ==================
    def start_sub_pipeline(self, name: str) -> 'PipelineBuilder':
        """开始一个新的子pipeline"""
        sub_builder = PipelineBuilder(self.config)
        sub_builder._parent_builder = self  # 设置父builder
        self._sub_pipelines.append({
            'name': name,
            'builder': sub_builder
        })
        return sub_builder

    def end_sub_pipeline(self) -> 'PipelineBuilder':
        """结束当前子pipeline并返回父builder"""
        if not self._sub_pipelines:
            return self._parent_builder if self._parent_builder else self
        return self._parent_builder  # 总是返回父builder

    def add_mean_classifier(self) -> 'PipelineBuilder':
        """添加均值分类器"""
        if not self._sub_pipelines:
            raise ValueError("No sub-pipelines defined for mean classifier")

        # 构建所有子pipeline
        sub_pipes = []
        for sub in self._sub_pipelines:
            sub_pipe = sub['builder'].build()
            sub_pipes.append(sub_pipe)

        self.steps.append((
            'ensemble',
            MeanClassifier(
                sub_pipes
            )
        ))
        self._has_classifier = True
        return self

    def build(self) -> Pipeline:
        return ImbPipeline(self.steps)

    def add_xgb_classifier(self) -> 'PipelineBuilder':
        """添加XGBoost分类器，如果xgb_params不存在则使用空字典"""
        xgb_params = self.config.get('xgb_params', {})
        return self.add_classifier(XGBClassifier(**xgb_params))

    def add_lr_classifier(self) -> 'PipelineBuilder':
        """添加逻辑回归分类器，如果lr_params不存在则使用空字典"""
        lr_params = self.config.get('lr_params', {})
        return self.add_classifier(LogisticRegression(**lr_params))