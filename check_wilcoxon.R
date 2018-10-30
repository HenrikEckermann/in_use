# this function is copied from an older version of the microbiome package
# (https://github.com/microbiome/microbiome)
check_wilcoxon <- function (dat, G1, G2, p.adjust.method = "BH", sort = FALSE, paired = FALSE){
      
      samples <- colnames(dat)
      levels <- rownames(dat)
      M <- matrix(data = NA, length(levels), 1)
      rownames(M) <- levels
      for (i in 1:length(levels)) {
          lvl <- levels[i]
          l.g1 <- dat[lvl, G1]
          l.g2 <- dat[lvl, G2]
          p <- wilcox.test(as.numeric(l.g1), pas.numeric(l.g2), paired = paired)$p.value
          M[i, 1] <- p
      }
      if (!is.null(p.adjust.method)) {
          cor.p <- p.adjust(M, method = p.adjust.method)
          names(cor.p) <- rownames(M)
      }
      else {
          cor.p <- as.vector(M)
          names(cor.p) <- rownames(M)
      }
      if (sort) {
          cor.p <- sort(cor.p)
      }
      cor.p
}





levelmap <- function (phylotypes = NULL, level.from, level.to, phylogeny.info){
  if (level.from == level.to) {
    df <- list()
    df[[level.to]] <- factor(phylotypes)
    df <- as.data.frame(df)
    return(df)
  }
  if (level.from == "level 0") {
      level.from <- "L0"
  }
  if (level.from == "level 1") {
      level.from <- "L1"
  }
  if (level.from == "level 2") {
      level.from <- "L2"
  }
  if (level.from == "oligo") {
      level.from <- "oligoID"
  }
  if (level.to == "level 0") {
      level.to <- "L0"
  }
  if (level.to == "level 1") {
      level.to <- "L1"
  }
  if (level.to == "level 2") {
      level.to <- "L2"
  }
  if (level.to == "oligo") {
      level.to <- "oligoID"
  }
  phylogeny.info <- polish.phylogeny.info(phylogeny.info)
  if (is.null(phylotypes)) {
      phylotypes <- as.character(unique(phylogeny.info[[level.from]]))
  }
  if (level.from == "species" && level.to %in% c("L0", "L1",
      "L2")) {
      sl <- species2levels(phylotypes, phylogeny.info)[, level.to]
  }
  if (level.from == "oligoID" && level.to %in% c("L0", "L1",
      "L2", "species")) {
      sl <- oligoTOhigher(phylotypes, phylogeny.info, level.to = level.to)
  }
  if (level.from == "L2" && level.to == "L1") {
      sl <- level2TOlevel1(phylotypes, phylogeny.info)[, 2]
  }
  if (level.from == "L2" && level.to == "L0") {
      sl <- level2TOlevel0(phylotypes, phylogeny.info)[, 2]
  }
  if (level.from == "L1" && level.to == "L0") {
      sl <- level1TOlevel0(phylotypes, phylogeny.info)[, 2]
  }
  if (level.from == "L1" && level.to == "L2") {
      sl <- list()
      for (pt in phylotypes) {
          sl[[pt]] <- as.character(unique(phylogeny.info[phylogeny.info[["L1"]] == pt, "L2"]))
      }
  }
  if (level.from == "L1" && level.to == "L0") {
      sl <- list()
      for (pt in phylotypes) {
          sl[[pt]] <- as.character(unique(phylogeny.info[phylogeny.info[["L1"]] == pt, "L0"]))
      }
  }
  if (level.from == "L0" && level.to %in% c("L1", "L2")) {
      sl <- list()
      for (pt in phylotypes) {
          sl[[pt]] <- as.character(unique(phylogeny.info[phylogeny.info[[level.from]] == pt, level.to]))
      }
  }
  if (level.from %in% c("L0", "L1", "L2") && level.to == "species") {
      sl <- list()
      for (pt in phylotypes) {
          sl[[pt]] <- as.character(unique(phylogeny.info[phylogeny.info[[level.from]] == pt, level.to]))
      }
  }
  if (level.from %in% c("L0", "L1", "L2", "species") && level.to ==
      "oligoID") {
      sl <- list()
      for (pt in phylotypes) {
          sl[[pt]] <- as.character(unique(phylogeny.info[phylogeny.info[[level.from]] == pt, level.to]))
      }
  }
  sl
}
