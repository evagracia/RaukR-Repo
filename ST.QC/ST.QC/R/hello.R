#' ST-package
#' conversion of tsv files and alignment matrix to data frame with filtered data and HTGC nomenclature
#' 
#' 
#' 
#' @export
ST.QC <- function(){
library(magrittr)
library(dplyr)
library(ggplot2)
library(devtools)
library(usethis)
library(roxygen2)
library(knitr)
library(rmarkdown)
library(reshape2)
library(Rcpp)
library(data.table)
library(Matrix)
library(gridExtra)


#load data
tsv_file <- "/Users/evagracia/AZKManuscript/tsv files/190415_Kidney_EXP1_NHK1_D2_stdata.tsv"
alignment_file <- "/Users/evagracia/AZKManuscript/selection files/spot_data-selection-EXP1_NHK1_D2.tsv"

# Read the tsv file, make a data frame and transpose it

S1 <- t(data.frame(fread(input = tsv_file, sep = "\t", header = T), row.names = 1))

# Reading the alignment_file
S1_alignment <- read.table(file = alignment_file, header = T, stringsAsFactors = F)


#set the rownames of the alignment tables to the x, y coordinates separated by "x" so that they match the column names of the expression datasets.

rownames(S1_alignment) <- paste(S1_alignment$x, S1_alignment$y, sep = "x")





# Now we use the function subset_data in our expression matrix
S1_subset <- subset_data(S1, S1_alignment)

# We read the conversion file from Ensembl names to gene_names

# convert and sort by gene type in descending order

sorted_data <- sort(table(ensids[rownames(S1_subset), ]$gene_type), decreasing = T)
print(sorted_data)
# Create data.frame with gene counts, gene id and biotype


d <- data.frame(S1_subset, count = rowSums(S1_subset), 
                  gene = rownames(S1_subset), 
                  biotype = ensids[rownames(S1_subset), ]$gene_type)
d %>%
  group_by(biotype) %>%
  summarize(content = sum(count)) %>%
  arrange(-content) %>%
  head(n = 10)

# Excluding biotypes
accepted_genes <- ensids$gene_id[ensids$gene_type %in% c("protein_coding", "lincRNA", "IG_C_gene")]
# Conversion to HGNC
rownames(S1_subset) <- ensids[rownames(S1_subset), ]$gene_name
(S1_subset)[1:5,1:5]
# We remove mitochondrial genes and MALAT1 ( hosekeeping)
remove_genes_S1 <- c(grep(pattern = "^MTRNR", value = T, x = rownames(S1_subset)), "MALAT1")
S1_subset <- S1_subset[!rownames(S1_subset) %in% remove_genes_S1, ]
}
Histo_unique()

#'Histogram function
#'Histograms of unique transcripts and genes 
#'@export
# We make a df. Unique genes per spot. Unique transcripts per spot
Histo_unique <- function(){
S1_df <- as.data.frame(S1_subset)
unique.genes <- apply(S1_df, 2, function(x) sum(x > 0))
unique.transcripts <- colSums(S1_df)

gg <- data.frame(unique.genes, unique.transcripts)
gg <- add_rownames(gg, var = "Spot")

a <- ggplot(gg, aes (x = unique.genes))+
  geom_histogram(bins = 100, color = "blue")

b <- ggplot(gg, aes (x = unique.transcripts))+
  geom_histogram(bins = 100, color = "red")
grid.arrange(a,b)
}

#' subset the expression datasetsusing the spots under tissue
#'removes ambiguous, non-expressed genes and prints general stats
#'
#'
#'
#'
#'@export
subset_data <- function(data, alignment) {
  # Subset expression dataset using intersect
  data_subset <- data[, intersect(colnames(data), rownames(alignment))]
  
  # Make sure that genes with 0 expression are removed
  data_subset <- data_subset[rowSums(data_subset) > 0, ]
  
  # Remove ambiguous genes
  remove_genes <- grep(pattern = "ambiguous", x = rownames(data_subset), value = T)
  data_subset <- data_subset[!rownames(data_subset) %in% remove_genes, ]
  
  # Print some messages
  cat("Number of genes in raw dataset: ", nrow(data), "\n")
  cat("Number of genes in subset dataset: ", nrow(data_subset), "\n")
  cat("Number of spots in raw dataset: ", ncol(data), "\n")
  cat("Number of spots in subset dataset: ", ncol(data_subset), "\n\n")
  return(data_subset)
}
