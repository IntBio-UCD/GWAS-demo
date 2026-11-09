# gwas_helpers.R
# Reading ANGSD results and plotting them. Needs tidyverse.

suppressPackageStartupMessages(library(tidyverse))

# Read an ANGSD .lrt0.gz file. Sites ANGSD skipped (LRT = -999) are dropped.
# logp is -log10(p) from a 1-df chi-square, computed on the log scale.
read_lrt <- function(file) {
  read_tsv(file, show_col_types = FALSE, progress = FALSE) %>%
    filter(!is.na(LRT), LRT >= 0) %>%
    transmute(chr = as.character(Chromosome), pos = Position, freq = Frequency, LRT,
              logp = -pchisq(LRT, df = 1, lower.tail = FALSE, log.p = TRUE) / log(10))
}

# Genomic inflation: median LRT over its expected median under no association.
lambda_gc <- function(d) median(d$LRT) / qchisq(0.5, df = 1)

# Bonferroni threshold on the -log10(p) scale
bonferroni <- function(n_tests, alpha = 0.05) -log10(alpha / n_tests)

# Chromosome lengths and offsets from the .fai, for the Manhattan x axis
chr_layout <- function(fai, chrs) {
  read_tsv(fai, col_names = c("chr", "len", "off", "lb", "lw"), col_types = "cdddd", show_col_types = FALSE) %>%
    filter(chr %in% chrs) %>%
    arrange(factor(chr, levels = str_sort(chr, numeric = TRUE))) %>%
    mutate(offset = cumsum(lag(len, default = 0)), mid = offset + len / 2, idx = row_number())
}

# Manhattan plot. Weak sites are thinned for drawing only (one per 50 kb x 0.02 cell below logp = 2).
plot_manhattan <- function(d, lay, title = NULL) {
  n <- nrow(d)
  hi <- filter(d, logp >= 2)
  lo <- d %>% filter(logp < 2) %>% mutate(xb = pos %/% 5e4, yb = round(logp / 0.02)) %>%
    distinct(chr, xb, yb, .keep_all = TRUE) %>% select(-xb, -yb)
  bind_rows(hi, lo) %>%
    inner_join(select(lay, chr, offset, idx), by = "chr") %>%
    mutate(x = pos + offset) %>%
    ggplot(aes(x, logp, colour = factor(idx %% 2))) +
    geom_point(size = 0.6, alpha = 0.7) +
    scale_colour_manual(values = c("#0F5A82", "#56B4E9"), guide = "none") +
    geom_hline(yintercept = bonferroni(n), colour = "red", linetype = "dashed") +
    scale_x_continuous(breaks = lay$mid, labels = lay$chr, expand = c(0.01, 0)) +
    labs(x = "Chromosome", y = expression(-log[10](italic(p))), title = title) +
    theme_classic(base_size = 13) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))
}

# QQ plot for a named list of runs, with lambda in the legend and a 95% band.
plot_qq <- function(runs) {
  qq <- function(d) {
    n <- nrow(d)
    tibble(obs = sort(d$logp, decreasing = TRUE)) %>%
      mutate(i = row_number(), exp = -log10((i - 0.5) / n),
             lo = -log10(qbeta(0.975, i, n - i + 1)), hi = -log10(qbeta(0.025, i, n - i + 1))) %>%
      filter(obs >= 2 | row_number() %% 20 == 0)       # draw every 20th point below logp = 2
  }
  tabs <- imap(runs, ~ qq(.x) %>% mutate(run = sprintf("%s (lambda = %.2f)", .y, lambda_gc(.x))))
  ggplot() +
    geom_ribbon(data = tabs[[1]], aes(exp, ymin = lo, ymax = hi), fill = "grey85") +
    geom_abline(slope = 1, intercept = 0) +
    geom_point(data = bind_rows(tabs), aes(exp, obs, colour = run), size = 0.8) +
    labs(x = expression(Expected~-log[10](italic(p))), y = expression(Observed~-log[10](italic(p))), colour = NULL) +
    coord_equal() +
    theme_classic(base_size = 13) +
    theme(legend.position = "bottom", legend.direction = "vertical")
}
