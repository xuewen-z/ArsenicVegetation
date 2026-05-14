# 加载必要的包
library(piecewiseSEM)
library(nlme)
library(lm.beta)
library(lme4)
library(caret)
library(ggplot2)
library(reshape2)

# 载入数据
data <- read.csv("G:/59_SiteSEMinput/SEMRInData.csv")
colnames(data) <- c('GPPmax','WUE','CUE','LAI','PFT','CO2','SM','RSDS','VPD','Elev','O3','Latitude','Longitude','As',
                    'PET','Prec','AI','Temp','AET','Alpha','TWI','CEC','Clay__top_','Clay__sub_','SOC','PH',
                    'silt__top_','silt__sub_','sand__top_','sand__sub_','SWC')
# 标准化数据，排除分类变量和地理坐标
numeric_cols <- setdiff(colnames(data), c("PFT", "Latitude", "Longitude"))
data_scaled <- data
data_scaled[numeric_cols] <- scale(data[numeric_cols])

# 环境变量的组合 (PCA)
climate_pca <- prcomp(data_scaled[, c("Prec","VPD","AI","Temp","O3")], scale. = TRUE)
# 土壤变量的组合 (PCA)
soil_pca <- prcomp(data_scaled[, c("CEC", "SM", "SOC","PH")], scale. = TRUE)

data_scaled$climate <- climate_pca$x[, 1]
data_scaled$soil <- soil_pca$x[, 1]


# 总样本数
total_samples <- 44692     

# 计算抽样比例 p
p <- total_samples / nrow(data_scaled)

# 使用 createDataPartition 进行分层抽样
set.seed(2024)  # 设置种子以保证可重复性
train_indices <- createDataPartition(data_scaled$PFT, p = p, list = FALSE)

# 获取抽样后的数据
sampled_data_caret <- data_scaled[train_indices, ]


# 检查抽样结果
cat("Total sampled:", nrow(sampled_data_caret), "\n")
table(sampled_data_caret$PFT)


# 混合效应模型列表
Salt.list <- list(
  lme(As ~ climate, random = ~ 1 |Elev, na.action = na.omit, data = sampled_data_caret),
  lme(soil ~ As + climate, random = ~ 1 |Elev, na.action = na.omit, data = sampled_data_caret),
  lme(GPPmax ~ soil + climate + As , random = ~ 1 |Elev, na.action = na.omit, data = sampled_data_caret),
  lme(CUE ~ GPPmax + soil + climate + As , random = ~ 1 |Elev, na.action = na.omit, data = sampled_data_caret),
  lme(WUE ~ GPPmax + soil + climate + As , random = ~ 1 |Elev, na.action = na.omit, data = sampled_data_caret),
  lme(LAI ~ As + WUE + GPPmax + soil + climate, random = ~ 1 |Elev, na.action = na.omit, data = sampled_data_caret),
  CUE %~~% WUE
  
)


# 构建 SEM
Salt.psem <- as.psem(Salt.list)

# 检查 SEM 结果
suppressWarnings(summary(Salt.psem, .progressBar = FALSE))


# 获取标准化路径系数
sem.effects <- coefs(Salt.psem, standardize = "scale")  # 使用 scale 标准化
print(sem.effects)


# 创建路径系数表（Std.Estimate）
paths <- list(
  As_to_soil = -0.0628,
  As_to_GPP = -0.0071,
  As_to_CUE =  0.0390,
  As_to_WUE = -0.0041,
  As_to_LAI = -0.0105,
  
  climate_to_As = 0.0666,
  climate_to_soil = 0.2294,
  climate_to_CUE = -0.2205,
  climate_to_WUE = -0.3089,
  climate_to_GPP = -0.5033,
  climate_to_LAI = 0.4336,
  
  soil_to_CUE = -0.0943,
  soil_to_WUE = 0.1786,
  soil_to_GPP = 0.3973,
  soil_to_LAI = 0.2165,
  
  GPP_to_CUE = 0.4940,
  GPP_to_LAI = -0.1409,
  GPP_to_WUE = 0.6422,
  WUE_to_LAI = 1.0033
)

# ====== 自定义函数：计算总效应 ======
# 计算总效应函数
compute_total_effect <- function(direct, indirects) {
  indirect_total <- sum(unlist(indirects))
  total <- direct + indirect_total
  return(data.frame(Direct = direct, Indirect = indirect_total, Total = total))
}

# As → LAI 间接路径
as_indirect <- list(
  paths$As_to_soil * paths$soil_to_LAI,
  paths$As_to_soil * paths$soil_to_GPP * paths$GPP_to_LAI,
  paths$As_to_soil * paths$soil_to_GPP * paths$GPP_to_WUE * paths$WUE_to_LAI,
  paths$As_to_soil * paths$soil_to_WUE * paths$WUE_to_LAI,
  paths$As_to_GPP * paths$GPP_to_LAI,
  paths$As_to_GPP * paths$GPP_to_WUE * paths$WUE_to_LAI,
  paths$As_to_WUE * paths$WUE_to_LAI
)
As_LAI <- compute_total_effect(paths$As_to_LAI, as_indirect)

# Climate → LAI 间接路径
climate_indirect <- list(
  paths$climate_to_As * paths$As_to_LAI,
  paths$climate_to_As * paths$As_to_soil * paths$soil_to_LAI,
  paths$climate_to_As * paths$As_to_soil * paths$soil_to_WUE * paths$WUE_to_LAI,
  paths$climate_to_As * paths$As_to_soil * paths$soil_to_GPP * paths$GPP_to_LAI,
  paths$climate_to_As * paths$As_to_soil * paths$soil_to_GPP * paths$GPP_to_WUE * paths$WUE_to_LAI,
  paths$climate_to_As * paths$As_to_WUE * paths$WUE_to_LAI,
  paths$climate_to_As * paths$As_to_GPP * paths$GPP_to_LAI,
  paths$climate_to_As * paths$As_to_GPP * paths$GPP_to_WUE * paths$WUE_to_LAI,
  
  paths$climate_to_soil * paths$soil_to_LAI,
  paths$climate_to_soil * paths$soil_to_WUE * paths$WUE_to_LAI,
  paths$climate_to_soil * paths$soil_to_GPP * paths$GPP_to_WUE * paths$WUE_to_LAI,
  paths$climate_to_soil * paths$soil_to_GPP * paths$GPP_to_LAI,
  
  paths$climate_to_WUE * paths$WUE_to_LAI,
  paths$climate_to_GPP * paths$GPP_to_LAI,
  paths$climate_to_GPP * paths$GPP_to_WUE * paths$WUE_to_LAI
)
Climate_LAI <- compute_total_effect(paths$climate_to_LAI, climate_indirect)

# Soil → LAI 间接路径
soil_indirect <- list(
  paths$soil_to_WUE * paths$WUE_to_LAI,
  paths$soil_to_GPP * paths$GPP_to_LAI,
  paths$soil_to_GPP * paths$GPP_to_WUE * paths$WUE_to_LAI
  
)
Soil_LAI <- compute_total_effect(paths$soil_to_LAI, soil_indirect)



# 合并结果
result <- rbind(
  As = As_LAI,
  Climate = Climate_LAI,
  Soil = Soil_LAI
)


result$Source <- rownames(result)
result <- result[order(-abs(result$Total)), ]
print(result)





# 输入已计算好的结果（保留1位有效数字）
result <- data.frame(
  Source = c("Climate", "As", "Soil"),
  Direct = signif(c(0.4336, -0.0105, 0.2165), 2),
  Indirect = signif(c(-0.43034, -0.04509763, 0.37919785), 2)
)
result$Total <- result$Direct + result$Indirect

# 计算相对重要性（基于 Total 的绝对值）
total_sum <- sum(abs(result$Total))
result_long <- reshape2::melt(result, id.vars = "Source", variable.name = "Type", value.name = "Effect")
result_long$RelImportance <- 100 * result_long$Effect / total_sum

# ✅ 手动修正 As 的 Total 为 -9
result_long$RelImportance[result_long$Source == "As" & result_long$Type == "Total"] <- -9


# 点横坐标偏移
offsets <- c(Direct = -0.25, Indirect = 0, Total = 0.25)
result_long$xpos <- as.numeric(factor(result_long$Source, levels = c("Climate", "As", "Soil"))) +
  offsets[result_long$Type]

# 颜色设定（As = 红色，其它为自然风格色系）
color_map <- c(
  "Climate" = "#A6CEE3",   
  "As" = "#F4A6B7",        
  "Soil" = "#FDBF6F"     
)

# 形状设定
shape_map <- c("Direct" = 23, "Indirect" = 22, "Total" = 21)  # 

# 绘图
p <- ggplot(result_long, aes(x = xpos, y = RelImportance)) +
  geom_hline(yintercept = 0, linetype = "solid", color = "gray30", size = 0.5) +
  geom_segment(aes(xend = xpos, yend = 0, color = Source), size = 3.5) +
  geom_point(aes(shape = Type, fill = Source, color = Source), size = 20, stroke = 0) +
  geom_text(aes(label = round(RelImportance), group = Type),
            color = "black", size = 12, vjust = 0.5) +
  scale_shape_manual(values = shape_map) +
  scale_fill_manual(values = color_map, guide = "none") +
  scale_color_manual(values = color_map, guide = "none") +
  guides(
    shape = guide_legend(
      override.aes = list(size = 12)  # ✅ 设置图例中形状大小
    )
  ) +
  scale_x_continuous(breaks = 1:3, labels = c("climate", "As","edaphic")) +
  labs(
    x = NULL, y = "relative importance (%)",
    shape = " "
  ) +
  theme_minimal(base_size = 14) +
  theme(
    panel.background = element_blank(),
    plot.background = element_blank(),
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    panel.border = element_blank(),
    axis.text.x = element_blank(),
    axis.line.y = element_line(),
    axis.ticks.y = element_line(color = "black", size = 0.5),
    legend.position = c(0.4, 0.9),
    legend.direction = "horizontal",
    legend.text = element_text(size = 28),
    axis.text.y = element_text(size = 30),
    axis.title.y = element_text(size = 30),  # ✅ 设置 y 轴标题字体大小
  )


# 显示图形
print(p)

ggsave("LAI_Effect_Transparent.png", plot = p,
       width = 10, height = 6, dpi = 300, bg = "transparent")



# 设置保存路径
png("FigS19_PCAvariance.png", width = 1800, height = 1200, res = 300)

# 设置图形参数：一行两图
par(mfrow = c(1, 2),            # 1行2列
    mar = c(4, 4, 2, 1),        # 边距
    oma = c(1, 1, 2, 1),        # 外边距，用于放a、b标签
    family = "sans")       # 设置字体为 Helvetica


# 自定义颜色和点样式
line_col <- "grey20"
point_col <- "black"
point_type <- 20



######附录图19

# --- 图1：Climate PCA ---
plot(cumsum(climate_pca$sdev^2 / sum(climate_pca$sdev^2)), type = "b",
     xlab = "climatic principal component", ylab = "cumulative variance explained",
     col = line_col, pch = point_type,
     lwd = 2, cex = 1.1,
     xaxt = "n")  # 关闭自动x轴刻度
axis(side = 1, at = 1:5, labels = 1:5)  # 自定义x轴为整数
mtext("a", side = 3, line = 0.5, adj = -0.1, cex = 1.5, font = 2)

# --- 图2：Soil PCA ---
plot(cumsum(soil_pca$sdev^2 / sum(soil_pca$sdev^2)), type = "b",
     xlab = "edaphic principal component", ylab = "cumulative variance explained",
     col = line_col, pch = point_type,
     lwd = 2, cex = 1.1,
     xaxt = "n")  # 同样关闭自动x轴刻度
axis(side = 1, at = 1:4, labels = 1:4)  # 设置整数刻度
mtext("b", side = 3, line = 0.5, adj = -0.1, cex = 1.5, font = 2)

# 关闭图形设备
dev.off()


# 其他的分析

# 绘制气候 PCA 负载图
barplot(climate_pca$rotation[, 1], las = 2, col = "steelblue",
        main = "Climate Variables Loading on PC1",
        xlab = "Climate Variables", ylab = "Loadings")

# 绘制土壤 PCA 负载图
barplot(soil_pca$rotation[, 1], las = 2, col = "forestgreen",
        main = "Soil Variables Loading on PC1",
        xlab = "Soil Variables", ylab = "Loadings")





# 主成分的解释方差比例
explained_variance_climate <- summary(climate_pca)$importance[2, ] # 提取每个主成分的解释方差比例
explained_variance_soil <- summary(soil_pca)$importance[2, ]

# 计算解释方差比例的权重
w1 <- explained_variance_soil[1] / sum(explained_variance_soil[1:2])
w2 <- explained_variance_soil[2] / sum(explained_variance_soil[1:2])

# 提取 PC1 和 PC2 的值
soil_PC1 <- soil_pca$x[, 1]  # 第一主成分得分
soil_PC2 <- soil_pca$x[, 2]  # 第二主成分得分

# 加权合并 PC1 和 PC2
soil_combined <- w1 * soil_PC1 + w2 * soil_PC2
data_scaled$soil <- soil_combined

