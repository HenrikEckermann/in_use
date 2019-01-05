# since I am used to dplyr for data manipulation I think it might be good to
# have a fast way to to switch between dataframe/tibble to phyloseq so that 
# I can use dplyr etc. also here. A requirement for phyloseq object creation is
# that rownames are sample names that match the sample names in the otu table. 
# Similarly, tax_table rownames need to match otu names of the otu table.

library(phyloseq)
library(dplyr)
library(glue)

# creates list of dfs
to_dfs <- function(pseq, level = "species", rtc_name = "sample_id") {
  # otu df
  otu <- as.data.frame(otu_table(pseq)) %>% rownames_to_column(level)
  sdata <- as_data_frame(sample_data(pseq)) %>% rownames_to_column(rtc_name)
  taxt <- as.data.frame(tax_table(pseq)) %>% rownames_to_column(level)
  return(list(otu = otu, sdata = sdata, taxt = taxt))
}

# transforms list of dfs to pseq
to_pseq <- function(
    list_of_dfs, 
    level = "species", 
    rtc_name = "sample_id",
    taxa_are_rows = TRUE) {
      # otu df
      otu <- list_of_dfs$otu %>% 
        column_to_rownames(level) %>% 
        otu_table(taxa_are_rows = taxa_are_rows)
        
      sdata <- list_of_dfs$sdata %>% 
        column_to_rownames(rtc_name) %>% 
        sample_data()
        
      taxt <- 
      list_of_dfs$taxt %>% 
        column_to_rownames(level) %>% 
        as.matrix() %>%
        tax_table()
        
      pseq <- phyloseq(otu, sdata, taxt)
      return(pseq)
}


sd_to_df <- function(pseq, rtc_name = "sample_id") {
    sample_data(pseq) %>%
    as_data_frame() %>%
    rownames_to_column(rtc_name)    
}

df_to_sd <- function(sdata, ctr_name = "sample_id") {
  sdata %>% 
    column_to_rownames(ctr_name) %>%
    sample_data()
}


otu_to_df <- function(pseq, level = "species", transpose = TRUE) {
    otu <- 
      otu_table(pseq) %>%
      as.data.frame() %>%
      rownames_to_column(level) 
    if (transpose) {
      otu <- 
        otu %>%
        gather(sample_id, value, -species) %>%
        spread(species, value)
    }   
    otu
}

df_to_otu <- function(otu, level = "species", taxa_are_rows = TRUE) {
  otu %>% 
    column_to_rownames(level) %>%
    otu_table(taxa_are_rows = taxa_are_rows)
}




# biplot function 
biplot <- function(
  pseq_clr, 
  scaling_factor = 10, 
  color = NULL, 
  text = FALSE, 
  split_by = FALSE, 
  facet = FALSE, 
  connect_series = FALSE, 
  subject_id = "subject_id", 
  filter_samples = FALSE) {
    
    
    # PCA
    pcx <- pseq_clr %>% 
        otu_to_df() %>%
        column_to_rownames("sample_id") %>%
        prcomp()
    
    # extract loadings
    pcx_rot <- 
        pcx$rotation %>%
            as.tibble() %>%
            mutate_all(function(x) x * scaling_factor) %>%
            add_column(taxa = rownames(pcx$rotation))
                       
    # combine first 4 PCs with metadata
    princomps <- pcx$x %>% as.data.frame() %>%
        rownames_to_column("sample_id") %>%
        select(PC1, PC2, PC3, PC4, sample_id)
    data <- pseq_clr %>% 
                sd_to_df() %>% 
                left_join(princomps, by = "sample_id") 
    
    # apply filtering
    if (filter_samples != FALSE) data <- data %>% filter(sample_id %in% filter_samples)
                       


    # how much variance do pcs explain?
    pc1 <- round(pcx$sdev[1]^2/sum(pcx$sdev^2),3)
    pc2 <- round(pcx$sdev[2]^2/sum(pcx$sdev^2),3)
    pc3 <- round(pcx$sdev[3]^2/sum(pcx$sdev^2),3)
    pc4 <- round(pcx$sdev[4]^2/sum(pcx$sdev^2),3)

    # if connecting by time, data must be arranged accordingly
    if (connect_series != FALSE) data <- data %>% arrange_(connect_series)
                       
    # avoid errors due to wrong class
    if (length(color > 0)) data[[color]] <-  as.factor(data[[color]])
                       
    # define plottting function 
    create_plot <- function(data, pc = 1, pc1, pc2, title = "") {
        data %>%        
        ggplot(aes_string(glue("PC{pc}"), glue("PC{pc+1}"), label = "sample_id", color = color)) +
            geom_text(data = pcx_rot, aes_string(glue("PC{pc}"), glue("PC{pc+1}"), label = "taxa"), color = "#999999", size = 3, alpha = 0.4) +
            xlab(glue("PC{pc}: [{pc1*100}%]")) +  ylab(glue("PC{pc+1}: [{pc2*100}%]")) +
            scale_y_continuous(sec.axis = ~./scaling_factor) +
            scale_x_continuous(sec.axis = ~./scaling_factor) +
            scale_color_manual(values = c("#fc8d62", "#8da0cb", "#66c2a5",'#1f78b4','#33a02c','#e31a1c')) +
            ggtitle(title) +
            theme_bw()  
    }

    
    # split by (to produce bigger plots than possible just by facet_wrap or to use in addition as grouping possibility)
    if (split_by != FALSE) {
        data <- data %>% group_by_(split_by) %>% nest()
        pc_plots_1 <- map2(data[[2]], data[[1]], ~create_plot(data = .x, title = .y, pc = 1, pc1, pc2))
        pc_plots_2 <- map2(data[[2]], data[[1]], ~create_plot(data = .x, title = .y, pc = 3, pc3, pc4))
        pc_plots <- append(pc_plots_1, pc_plots_2)
    } else {
        # plots
        p12 <- create_plot(data = data, pc = 1, pc1, pc2)
        p34 <- create_plot(data = data, pc = 2, pc3, pc4)
        pc_plots <- list(p12, p34)  
    }
                       

                       
    # apply optionals 
    # text 
    if (text) {
        pc_plots <- map(pc_plots, ~.x + geom_text(size = 3))
    }else{
        pc_plots <- map(pc_plots, ~.x + geom_point())
    }
                    
    # path 
    if (connect_series != FALSE) pc_plots <- map(pc_plots, ~.x + geom_path(aes(group = as.factor(subject_id)), arrow = arrow(length = unit(0.35,"cm"), ends = "last"), alpha = 0.3, size = 0.8))
                       
    # facetting 
    if (facet != FALSE) pc_plots <- map(pc_plots, ~.x + facet_wrap(as.formula(glue(".~{facet}"))))  
                       
    pc_plots
}
