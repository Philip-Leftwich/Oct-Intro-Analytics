# ============================================================
# Mixed vs Fixed (with group dummies) vs Naive (ignoring groups)
# Power, Type-I error, Bias, RMSE, and CI coverage for beta_trt
# ============================================================

# Packages
suppressPackageStartupMessages({
  library(lme4)        # mixed models
  library(lmerTest)    # Satterthwaite df/p-values for lmer
  library(dplyr)       # summarizing
  library(tidyr)       # tidying summaries
  library(ggplot2)     # optional plots
})

set.seed(12345)

# --------------------------
# Core simulator
# --------------------------
# Simulate clustered outcomes:
# y_ij = beta0 + beta_trt * trt_ij + u_j + e_ij
# u_j ~ N(0, tau^2), e_ij ~ N(0, sigma^2)
# Treatment randomized within clusters with prob p_trt
sim_one <- function(J = 100, beta_trt = 0.30, beta0 = 0,sigma = 1.0, tau = 1.7, p_trt = 0.5, m = 5) {


  m_j <- rpois(J, lambda = m)  # or rnbinom, etc.
  group <- rep(seq_len(J), times = m_j)
  N <- length(group)
  z_j <- rnorm(J)
  u <- rnorm(J, 0, tau)
  p_j <- rep(p_trt, J)
  trt <- rbinom(N, 1, p_j[group])
  x <- rnorm(N)
  eta <- beta0 + beta_trt * trt + (0.7*x)+ u[group]
  y <- eta + rnorm(N, 0, sigma)

  data.frame(y, trt = as.numeric(trt), group = factor(group))
}

# --------------------------
# Fitters that return key stats for the treatment coefficient
# --------------------------
extract_lm <- function(fit, par = "trt") {
  co <- summary(fit)$coef
  if (!(par %in% rownames(co))) return(data.frame(est=NA,se=NA,df=NA,p=NA,low=NA,high=NA))
  est <- co[par, "Estimate"]
  se  <- co[par, "Std. Error"]
  df  <- fit$df.residual
  tval <- est / se
  p <- 2*pt(abs(tval), df = df, lower.tail = FALSE)
  # 95% CI (t-based)
  crit <- qt(0.975, df = df)
  low <- est - crit * se
  high <- est + crit * se
  data.frame(est=est, se=se, df=df, p=p, low=low, high=high)
}

extract_lmer <- function(fit, par = "trt") {
  # lmerTest gives Satterthwaite df and p-values

  co <- summary(fit)$coef
  if (!(par %in% rownames(co))) return(data.frame(est=NA,se=NA,df=NA,p=NA,low=NA,high=NA))
  est <- co[par, "Estimate"]
  se  <- co[par, "Std. Error"]
  df  <- co[par, "df"]
  p   <- co[par, "Pr(>|t|)"]
  # 95% CI using t with Satterthwaite df
  crit <- qt(0.975, df = df)
  low <- est - crit * se
  high <- est + crit * se
  data.frame(est=est, se=se, df=df, p=p, low=low, high=high)
}

# --------------------------
# One replication: fit three models
# --------------------------
fit_three <- function(dat) {
  options(lmerTest.ddf = "Kenward-Roger")
  # Mixed model (random intercept)
  fit_mixed <- lmer(y ~ trt + (1|group), data = dat, REML = TRUE)
  out_mixed <- extract_lmer(fit_mixed, "trt") %>% mutate(model = "Mixed RI")

  # Fixed effects: all groups as dummies
  fit_fe <- lm(y ~ trt + group, data = dat)  # reference-group coding
  out_fe <- extract_lm(fit_fe, "trt") %>% mutate(model = "Fixed FE (dummies)")

  # Naive (ignores groups)
  fit_naive <- lm(y ~ trt, data = dat)
  out_naive <- extract_lm(fit_naive, "trt") %>% mutate(model = "Naive (ignores groups)")

  bind_rows(out_mixed, out_fe, out_naive)
}

# --------------------------
# Monte Carlo driver
# --------------------------
run_sims <- function(nsim = 1000,
                     J = 100, m = 5,
                     beta_trt = 0.30,
                     sigma = 1.0, tau = 1.5,
                     p_trt = 0.5,
                     alpha = 0.05,
                     scenario_name = "Many small clusters (J=100, m=5)") {

  ICC <- tau^2 / (tau^2 + sigma^2)

  res <- replicate(nsim, {
    dat <- sim_one(J = J, m = m, beta_trt = beta_trt, sigma = sigma, tau = tau)
    ans <- fit_three(dat)
    ans$true <- beta_trt
    ans
  }, simplify = FALSE) %>% bind_rows()

  # metrics
  out <- res %>%
    group_by(model) %>%
    summarise(
      nsim = n(),
      power = mean(p < alpha, na.rm = TRUE),                 # if beta_trt != 0, this is power; if == 0, it's type I error
      bias = mean(est - unique(true), na.rm = TRUE),
      rmse = sqrt(mean((est - unique(true))^2, na.rm = TRUE)),
      mean_se = mean(se, na.rm = TRUE),
      mean_df = mean(df, na.rm = TRUE),
      cover_95 = mean(low <= unique(true) & high >= unique(true), na.rm = TRUE)
    ) %>%
    mutate(ICC = ICC, J = J, m = m, N = J*m, scenario = scenario_name, beta_trt = beta_trt)

  list(summary = out, raw = res)
}

# --------------------------
# Run scenarios
# --------------------------
nsim <- 30  # reduce to 200 if you need it snappy

# Scenario A: Many small clusters (mixed model should shine vs FE on power)
A <- run_sims(nsim = nsim, J = 100, m = 10,
              beta_trt = 0.2, sigma = .7, tau = .3,
              scenario_name = "Many small clusters, low variation")

# Scenario B: Fewer larger clusters (gap narrows)
B <- run_sims(nsim = nsim, J = 25, m = 40,
              beta_trt = 0.2, sigma = .7, tau = .3,
              scenario_name = "Fewer larger clusters, low variation")

C <- run_sims(nsim = nsim, J = 100, m = 10,
              beta_trt = 0.2, sigma = .7, tau = .8,
              scenario_name = "Many small clusters, high variation")

# Scenario B: Fewer larger clusters (gap narrows)
D <- run_sims(nsim = nsim, J = 25, m = 40,
              beta_trt = 0.2, sigma = .7, tau = .8,
              scenario_name = "Fewer larger clusters, high variation")

# Scenario C: Type-I error audit (beta_trt = 0)
E <- run_sims(nsim = nsim, J = 25, m = 20,
              beta_trt = 0, sigma = .7, tau = 1,
              scenario_name = "Type-I error")

# # --------------------------
# # Combine and print summaries
# # --------------------------
 summary_all <- bind_rows(A$summary, B$summary, C$summary, D$summary, E$summary)
# print(summary_all)
#
# # --------------------------
# # Optional: quick plots
# # --------------------------
 # Power (or type-I when beta=0)
 ggplot(filter(summary_all, scenario != "Type-I error"),
        aes(x = model, y = power)) +
   geom_col() +
   facet_wrap(~ scenario, ncol = 2) +
   coord_cartesian(ylim = c(0,1)) +
   labs(title="Power by model and scenario", x = NULL, y = "Power (alpha=0.05)") +
   theme_bw() + theme(legend.position = "none")+
   geom_label(aes(label= round(power,2)))+
  coord_flip()
#
# # # Coverage
#  ggplot(summary_all, aes(x = model, y = cover_95, fill = model)) +
#    geom_col() +
#    facet_wrap(~ scenario, ncol = 1) +
#    coord_cartesian(ylim = c(0,1)) +
#    geom_hline(yintercept = 0.95, linetype = 2) +
# #  labs(title="95% CI Coverage", x = NULL, y = "Coverage") +
#    theme_bw() + theme(legend.position = "none")
# #
# # # RMSE
#  ggplot(summary_all, aes(x = model, y = rmse, fill = model)) +
#    geom_col() +
#   facet_wrap(~ scenario, ncol = 1) +
#    labs(title="RMSE of treatment effect estimate", x = NULL, y = "RMSE") +
#    theme_bw() + theme(legend.position = "none")



###

summary_raw <- bind_rows(
  A$raw %>% mutate(scenario = "Many small clusters, low variation"),
  B$raw %>% mutate(scenario = "Fewer larger clusters, low variation"),
  C$raw %>% mutate(scenario = "Many small clusters, high variation"),
  D$raw %>% mutate(scenario = "Fewer larger clusters, high variation"),
  E$raw %>% mutate(scenario = "Type-I error")
)

ggplot(summary_raw, aes(x = est,  y =model, fill = model))+
  geom_density_ridges(alpha = .4)+
  facet_wrap(~scenario)


ggplot(summary_raw, aes(x = se, y = model, fill = model)) +
  ggridges::geom_density_ridges(alpha = 0.5, scale = 1.1, rel_min_height = 0.01, color = "grey30") +
  facet_wrap(~ scenario, scales = "free_x") +
  labs(
    title = "Distribution of Standard Errors Across Models",
    x = "Estimated SE for β_trt",
    y = NULL
  ) +
  theme_bw(base_size = 12) +
  theme(
    legend.position = "none",
    strip.text = element_text(size = 11, face = "bold"),
    axis.text.y = element_text(size = 10),
    axis.text.x = element_text(size = 9),
    panel.grid.minor = element_blank()
  )

ggplot(summary_all, aes(x = rmse, y = model, fill = model)) +
  ggridges::geom_density_ridges(alpha = 0.5, scale = 1.1, rel_min_height = 0.01, color = "grey30") +
  facet_wrap(~ scenario, scales = "free_x") +
  labs(
    title = "Distribution of Standard Errors Across Models",
    x = "Estimated SE for β_trt",
    y = NULL
  ) +
  theme_bw(base_size = 12) +
  theme(
    legend.position = "none",
    strip.text = element_text(size = 11, face = "bold"),
    axis.text.y = element_text(size = 10),
    axis.text.x = element_text(size = 9),
    panel.grid.minor = element_blank()
  )
