# since I am used to dplyr for data manipulation I think it might be good to
# have a fast way to to switch between dataframe/tibble to phyloseq so that 
# I can use dplyr etc. also here. A requirement for phyloseq object creation is
# that rownames are sample names that match the sample names in the otu table. 
# Similarly, tax_table rownames need to match otu names of the otu table.

library(phyloseq)
library(dplyr)

# creates list of dfs
to_dfs <- function(pseq, level = "species", rtc_name = "sample_id") {
  # otu df
  otu <- as.data.frame(otu_table(pseq)) %>% rownames_to_column(level)
  sdata <- as.data.frame(sample_data(pseq)) %>% rownames_to_column(rtc_name)
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
    as.data.frame() %>%
    rownames_to_column(rtc_name)    
}

df_to_sd <- function(sdata, ctr_name = "sample_id") {
  sdata %>% 
    column_to_rownames(ctr_name) %>%
    sample_data()
}


otu_to_df <- function(pseq, level = "species") {
    otu_table(pseq) %>%
    as.data.frame() %>%
    rownames_to_column(level)    
}

df_to_otu <- function(otu, level = "species", taxa_are_rows = TRUE) {
  otu %>% 
    column_to_rownames(level) %>%
    otu_table(taxa_are_rows = taxa_are_rows)
}
