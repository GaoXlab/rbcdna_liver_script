library(optparse)
library(dplyr)
library(patchwork)
library(cowplot)
library(reshape2)
library(stringr)
library(ggpubr)
# library(ggbiplot)
library(pheatmap)
library(ggplot2)
# library(factoextra)
library(RColorBrewer)
# library(scatterplot3d)
library(RCurl)#同时引入later包，需要打开X11
library(bitops)
library(later)

fun_anova <- function(grp1_data,grp2_data,pvalue.threshold){
      p = NULL
      p_adj = NULL
      group_data <- cbind(grp1_data,grp2_data)
      group_data <- na.omit(group_data)#删除有NA的行
      # group_data <- group_data[apply(group_data,1,sum)!=0,]
      group_label <- as.factor(c(rep("grp1_data",length(colnames(grp1_data))),rep("grp2_data",length(colnames(grp2_data)))))
      for(i in 1:dim(group_data)[1]) { 
        group_data_i <- as.numeric(c(group_data[i,colnames(grp1_data)],group_data[i,colnames(grp2_data)]))
        group_i <- data.frame(group_data_i,group_label)
        levels(group_i$group_label)
        res.aov <- aov(group_data_i ~ group_label,data=group_i)
        res.aov.summary <- summary(res.aov)
        res.tukey <- TukeyHSD(res.aov)# performing multiple pairwise-comparison between the means of groups
        p <- c(p,as.numeric(unlist(res.aov.summary)[9])) 
        p_adj <- c(p_adj,as.numeric(unlist(res.tukey)[4]))
      }
      names(p) <- rownames(group_data)
      names(p_adj) <- rownames(group_data)
      group_data.p.res <- as.data.frame(cbind(group_data,p,p_adj))
      colnames(group_data.p.res)[(dim(group_data.p.res)[2]-1):dim(group_data.p.res)[2]] <- c("one_wayAnova.pvalue","one_wayAnova.p_adj")
      return(group_data.p.res)
}

FindFeatures <- function(grp1_data,grp2_data,test.use,lg2fc.threshold,pvalue.threshold,Pseudocount,title){
  # grp1_data=D_samples_Control
  # grp2_data=D_samples_Disease
  test_p_result <- c()
  control_versus_treat_selected_regions_intersect <- c()
  grp1_data <- as.data.frame(grp1_data)
  grp2_data <- as.data.frame(grp2_data)
  if(test.use=="anova"){
    test_p_result <- fun_anova(grp1_data,grp2_data,pvalue.threshold)
  }
  avg_lg2FC <- (log2((apply(grp2_data,1,mean)+Pseudocount)/(apply(grp1_data,1,mean)+Pseudocount)))
  med_lg2FC <- (log2((apply(grp2_data,1,median)+Pseudocount)/(apply(grp1_data,1,median)+Pseudocount)))
  grp2vgrp1 <- as.data.frame(cbind(test_p_result,avg_lg2FC,med_lg2FC))
  ####################################
  # sign the significant regions
  ####################################
  pvalue = grp2vgrp1[,(dim(grp2vgrp1)[2]-3)]
  padj = grp2vgrp1[,(dim(grp2vgrp1)[2]-2)]
  avg.lg2fc = grp2vgrp1[,(dim(grp2vgrp1)[2]-1)]
  median.lg2fc = grp2vgrp1[,(dim(grp2vgrp1)[2])]

  grp2vgrp1$Significant.pvalue.avg_lg2FC <- ifelse(pvalue<=pvalue.threshold&avg.lg2fc>lg2fc.threshold, "upsig", "nosig")
  grp2vgrp1[pvalue<=pvalue.threshold&avg.lg2fc<(-lg2fc.threshold),"Significant.pvalue.avg_lg2FC"]="downsig"
  print(table(grp2vgrp1$"Significant.pvalue.avg_lg2FC"))
  grp2vgrp1$Significant.padj.avg_lg2FC <- ifelse(padj<=pvalue.threshold&avg.lg2fc>lg2fc.threshold, "upsig", "nosig")
  grp2vgrp1[which(padj<=pvalue.threshold&avg.lg2fc<(-lg2fc.threshold)),"Significant.padj.avg_lg2FC"]="downsig"
  print(table(grp2vgrp1$"Significant.pvalue.avg_lg2FC"))
  grp2vgrp1$Significant.pvalue.med_lg2FC <- ifelse(pvalue<=pvalue.threshold&median.lg2fc>lg2fc.threshold, "upsig", "nosig")
  grp2vgrp1[which(pvalue<=pvalue.threshold&median.lg2fc<(-lg2fc.threshold)),"Significant.pvalue.med_lg2FC"]="downsig"
  print(table(grp2vgrp1$"Significant.pvalue.med_lg2FC"))
  grp2vgrp1$Significant.padj.med_lg2FC <- ifelse(padj<=pvalue.threshold&median.lg2fc>lg2fc.threshold, "upsig", "nosig")
  grp2vgrp1[which(padj<=pvalue.threshold&median.lg2fc<(-lg2fc.threshold)),"Significant.padj.med_lg2FC"]="downsig"
  print(table(grp2vgrp1$"Significant.pvalue.med_lg2FC"))
  ####################################
  # Output1:
  ####################################
  write.table(grp2vgrp1,str_c(title,"DataMatrix_SignedFindMarkers.log"),sep="\t")
  ####################################
  # Output2:
  ####################################
  sig_up=grp2vgrp1[grp2vgrp1$Significant.padj.avg_lg2FC=='upsig',]
  sig_down=grp2vgrp1[grp2vgrp1$Significant.padj.avg_lg2FC=='downsig',]
  data_rownames_conapc=c(rownames(sig_up),rownames(sig_down))
  table(grp2vgrp1[data_rownames_conapc,]$Significant.padj.avg_lg2FC)
  select_features=data_rownames_conapc
  write.table(grp2vgrp1[data_rownames_conapc,],str_c("DataMatrix_SignedFindMarkers_allsigregions.log"),sep="\t")

  sig_up=tail(rownames(sig_up[order(sig_up$avg_lg2FC),]),20)
  sig_down=head(rownames(sig_down[order(sig_down$avg_lg2FC),]),20)
  data_rownames_conapc=c(sig_up,sig_down)
  table(grp2vgrp1[data_rownames_conapc,]$Significant.padj.avg_lg2FC)
  select_features=data_rownames_conapc
  write.table(grp2vgrp1[data_rownames_conapc,],str_c("DataMatrix_SignedFindMarkers_40regions.log"),sep="\t")

  return(grp2vgrp1)

}


transformat <- function(df){ # fig5
  D_samples <- as.data.frame(df)
  D_samples_1 <- c()
  for(i in colnames(D_samples)){
        D_samples_1 <- cbind(D_samples_1, as.numeric(as.character(as.matrix(D_samples[, i]))))
  }
  D_samples_1 <- as.data.frame(D_samples_1)
  colnames(D_samples_1) <- colnames(D_samples); rownames(D_samples_1) <- rownames(D_samples)
  return(D_samples_1)
}

pheatmap_f_g2 <- function(groups_label, grp1_data, grp2_data, pic_name){
    pdf(pic_name,width=8,height=8)
    
    sample_group_a=unlist(strsplit(groups_label,"_"))[1]
    sample_group_b=unlist(strsplit(groups_label,"_"))[2]
    # diff types numbers
    print(str_c("GroupA-sample:",dim(grp1_data)[2],";  GroupB-sample:",dim(grp2_data)[2]))
    # diff types numbers
    hmMat21 <- cbind(grp1_data, grp2_data)
    hmMat21 <- apply(hmMat21,2,as.numeric); dim(hmMat21)
    hmMat21 <- as.data.frame(hmMat21)
    rownames(hmMat21) = rownames(grp1_data)
    aka2 = data.frame(SampleType = factor(c(rep(str_c(sample_group_a," :",dim(grp1_data)[2]),dim(grp1_data)[2]),
                                            rep(str_c(sample_group_b," :",dim(grp2_data)[2]),dim(grp2_data)[2]))))
    rownames(aka2)<- colnames(hmMat21)
    aka3 = list(SampleType = c(GroupA ="#deebf7",GroupB="#fc9272"))
    names(aka3$SampleType) <- c(str_c(sample_group_a," :",dim(grp1_data)[2]),str_c(sample_group_b," :",dim(grp2_data)[2]))
    dista <- c('correlation', 'euclidean', 'maximum', 'manhattan', 'canberra','binary', 'minkowski')#'euclidean'
    # for(i in 1:length(dista)){
      i=1
      bk <- c(seq(-1.5,-0.1,by=0.01),seq(0,1.5,by=0.01))
      print(str_c("height:",225/dim(hmMat21)[2]))
      print(str_c("width:",300/dim(hmMat21)[1]))
      # aa=pheatmap(hmMat21,scale="row",cluster_rows =T,cluster_cols = T,annotation_col = aka2,color = c(colorRampPalette(colors = c("#084594","#08519c","white"))(length(bk)/2),
      #             colorRampPalette(colors = c("white","#cb181d","firebrick3"))(length(bk)/2)),legend_breaks=c(-1.5,-1,-0.5,0,0.5,1,1.5),main=dista[i],
      #             legend_labels=c('-1.5','-1','-0.5','0','0.5','1','1.5'),breaks=bk, annotation_colors = aka3[1],annotation_legend = TRUE,
      #             annotation_names_row=F,treeheight_row=20, treeheight_col=20,cellheight =225/dim(hmMat21)[1],cellwidth =300/dim(hmMat21)[2],
      #             clustering_distance_cols =dista[i],clustering_distance_row =dista[i], fontsize=10,show_rownames=F,show_colnames=T,fontsize_col=5,cex.lab=1)
      # aa
      aa=pheatmap(hmMat21,scale="row",cluster_rows =T,cluster_cols = T,annotation_col = aka2,color = c(colorRampPalette(colors = c("#084594","#08519c","white"))(length(bk)/2),
                  colorRampPalette(colors = c("white","#cb181d","firebrick3"))(length(bk)/2)),#legend_breaks=c(-1.5,-1,-0.5,0,0.5,1,1.5), 
                  legend_labels=F,breaks=bk, annotation_colors = aka3[1],annotation_legend = F,annotation_names_col=F,familyfont="Arial",
                  annotation_names_row=F,treeheight_row=20, treeheight_col=40,cellheight =225/dim(hmMat21)[1],cellwidth =300/dim(hmMat21)[2],clustering_distance_cols =dista[i],clustering_distance_row =dista[i], fontsize=20,show_rownames=F,show_colnames=F,fontsize_col=5,cex.lab=1)
      aa
    # }
    dev.off()
    return(hmMat21[aa$tree_row$order, aa$tree_col$order])
}
