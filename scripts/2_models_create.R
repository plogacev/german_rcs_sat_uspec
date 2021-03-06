
library(rstan)
library(plyr)
library(dplyr)
library(tidyr)
library(magrittr)
library(brms)
stopifnot(packageVersion("brms") >= '0.10.0')

library(doMC)
doMC::registerDoMC(parallel::detectCores())

source("./models/functions.R")
source("./models/contrasts_priors.R")
source("./models_postprocessing.R")

source("./load_data.R")
subjects = sort(unique(data$subject))

use_data_bernoulli = T

for (subj in subjects)
{
   print(subj)

   if (use_data_bernoulli) {
     cur_data_df <- data %>% subset_data_nocorr(subject == subj)
     sat_bf_cur <- sat_bf
   } else {
     cur_data_df <- data_rc_bysubj_n_yes %>% subset_data_binomial_nocorr(subject == subj)
     sat_bf_cur <- sat_bf_binomial
   }
   fname <- sprintf("subj_%d", subj)

   fit <- brm(sat_bf_cur(
                     dprime = ~ 1 + cGenderMasc * (cLowVsAvg + cHighVsAvg),
                     crit = ~ 1  + cGenderMasc,
                     crit_leftasym =~ 1
                     ),
             prior = c(priors$dprime, priors$crit),
             stanvars = stan_satf_functions, data = cur_data_df$data,
             iter = 4000, warmup = 2000, chains = 4, cores = 4, seed = 1234, init_r = .1
             ,
             file = file.path("../workspace/model_fits/models_singlesubj_uncorr", fname)
             )
}


if (use_data_bernoulli) {
  cur_data_df <- data %>% subset_data_nocorr(T)
  sat_bf_cur <- sat_bf
} else {
  cur_data_df <- data_rc_bysubj_n_yes %>% subset_data_binomial_nocorr(T)
  sat_bf_cur <- sat_bf_binomial
}

formula1 <-
   sat_bf_cur(
      dprime = ~ 1, crit = ~ 1,
      dprime_asymptote = ~ 1 + cLowVsAvg + cHighVsAvg + ( cLowVsAvg + cHighVsAvg + 1|d1|subject),
      dprime_invrate   = ~ 1 + cLowVsAvg + cHighVsAvg + ( cLowVsAvg + cHighVsAvg + 1|d2|subject),
      dprime_intercept = ~ 1 + cLowVsAvg + cHighVsAvg + ( cLowVsAvg + cHighVsAvg + 1|d3|subject),
      crit_leftasym   = ~ 1 + (1|c1|subject),
      crit_rightasym = ~ 1 +  (1|c2|subject),
      crit_invrate   = ~ 1 +  (1|c3|subject),
      crit_intercept = ~ 1 +  (1|c4|subject)
   )

prior1 <- c(priors$dprime, priors$crit,
           priors$dprime_randef_subj, priors$crit_randef_subj,
           set_prior("lkj(2)", class = "cor")
         )

fit1 <- brm(formula1, prior = prior1,
            stanvars = stan_satf_functions, data = cur_data_df$data, 
            iter = 4000, warmup = 1000, chains = 4, cores = 4, seed = 1234, init_r = .1,
            #control = list(metric = "dense_e", adapt_delta = .99),
            file = "../workspace/model_fits/fit_all_uncorr_bysubj_1_4000B",
            sample_file = "../workspace/model_fits/fit_all_uncorr_bysubj_1_4000B"
            )


formula2 <-
   sat_bf_cur(
      dprime = ~ 1, crit = ~ 1,
      dprime_asymptote = ~ 1 + cGenderMasc * (cLowVsAvg + cHighVsAvg) + ( cGenderMasc * (cLowVsAvg + cHighVsAvg) + 1|d1|subject),
      dprime_invrate   = ~ 1 + cGenderMasc * (cLowVsAvg + cHighVsAvg) + ( cGenderMasc * (cLowVsAvg + cHighVsAvg) + 1|d2|subject),
      dprime_intercept = ~ 1 + cGenderMasc * (cLowVsAvg + cHighVsAvg) + ( cGenderMasc * (cLowVsAvg + cHighVsAvg) + 1|d3|subject),
      crit_leftasym   = ~ 1 + (1|c1|subject),
      crit_rightasym = ~ 1 + cGenderMasc + (cGenderMasc + 1|c2|subject),
      crit_invrate   = ~ 1 + cGenderMasc + (cGenderMasc + 1|c3|subject),
      crit_intercept = ~ 1 + cGenderMasc + (cGenderMasc + 1|c4|subject)
   )


fit2 <- brm(formula2, prior = prior1,
                stanvars = stan_satf_functions, data = cur_data_df$data, 
                iter = 4000, warmup = 1000, chains = 4, cores = 4, seed = 1234, init_r = .1,
                #control = list(metric = "dense_e", adapt_delta = .99),
                file = "../workspace/model_fits/fit_all_uncorr_bysubj_2_4000",
                sample_file = "../workspace/model_fits/fit_all_uncorr_bysubj_2_4000"
                )

fit2_prior <- brm(formula2, prior = prior1,
            stanvars = stan_satf_functions, data = cur_data_df$data[1:2,], 
            sample_prior = "only",
            iter = 2000, warmup = 1000, chains = 4, cores = 4, seed = 1234, init_r = .1,
            #control = list(metric = "dense_e", adapt_delta = .99),
            file = "../workspace/model_fits/fit_all_uncorr_bysubj_2_prior"
            )

# ##################################################################################################
# ##################################################################################################
# ##################################################################################################
# 
# 
# formula1B <- sat_bf(dprime = ~ 1, crit = ~ 1,
#                    dprime_asymptote = ~ 1 + cGenderMasc * (cLowVsAvg + cHighVsAvg) + ( 1|d1|item), 
#                    dprime_invrate   = ~ 1 + cGenderMasc * (cLowVsAvg + cHighVsAvg) + ( 1|d2|item),
#                    dprime_intercept = ~ 1 + cGenderMasc * (cLowVsAvg + cHighVsAvg) + ( 1|d3|item),
#                    crit_leftasym   = ~ 1 + (1|c1|item),
#                    crit_rightasym = ~ 1 + cGenderMasc + (1|c2|item),
#                    crit_invrate   = ~ 1 + cGenderMasc + (1|c3|item),
#                    crit_intercept = ~ 1 + cGenderMasc + (1|c4|item)
#                    )
# prior1B <- c(priors$dprime, priors$crit,
#              #priors$dprime_randef_subj, priors$crit_randef_subj,
#              priors$dprime_randef_item, priors$crit_randef_item
#              #,
#              #set_prior("lkj(2)", class = "cor")
#              )
# 
# fit1B <- brm(formula1B, prior = prior1B,
#             stanvars = stan_satf_functions, data = cur_data_df$data, 
#             iter = 2000, warmup = 1000, chains = 4, cores = 4, seed = 1234, init_r = .1,
#             #control = list(metric = "dense_e", adapt_delta = .99),
#             file = "../workspace/model_fits/fit_all_uncorr_byitem1",
#             sample_file = "../workspace/model_fits/fit_all_uncorr_byitem1"
#             )
# 
# ##################################################################################################
# ##################################################################################################
# ##################################################################################################
# 
# 
# 
# formula1C <- sat_bf(dprime = ~ 1, crit = ~ 1,
#                     dprime_asymptote = ~ 1 + cGenderMasc * (cLowVsAvg + cHighVsAvg) + ( 1|ds1|subject) + ( 1|di1|item), 
#                     dprime_invrate   = ~ 1 + cGenderMasc * (cLowVsAvg + cHighVsAvg) + ( 1|ds2|subject) + ( 1|di2|item),
#                     dprime_intercept = ~ 1 + cGenderMasc * (cLowVsAvg + cHighVsAvg) + ( 1|ds3|subject) + ( 1|di3|item),
#                     crit_leftasym   = ~ 1 + (1|cs1|subject) + (1|ci1|item),
#                     crit_rightasym = ~ 1 + cGenderMasc + (1|cs2|subject) + (1|ci2|item),
#                     crit_invrate   = ~ 1 + cGenderMasc + (1|cs3|subject) + (1|ci3|item),
#                     crit_intercept = ~ 1 + cGenderMasc + (1|cs4|subject) + (1|ci4|item)
#                     )
# prior1C <- c(priors$dprime, priors$crit,
#              priors$dprime_randef_subj, priors$crit_randef_subj,
#              priors$dprime_randef_item, priors$crit_randef_item
#              #set_prior("lkj(2)", class = "cor")
#             )
# 
# fit1C <- brm(formula1C, prior = prior1C,
#              stanvars = stan_satf_functions, data = cur_data_df$data, 
#              iter = 2000, warmup = 1000, chains = 4, cores = 4, seed = 1234, init_r = .1,
#              #control = list(metric = "dense_e", adapt_delta = .99),
#              file = "../workspace/model_fits/fit_all_uncorr_byitem_bysubj1",
#              sample_file = "../workspace/model_fits/fit_all_uncorr_byitem_bysubj1"
#             )
# 
# ##################################################################################################
# ##################################################################################################
# ##################################################################################################
# 
# 
# formula2A <- sat_bf(dprime = ~ 1, crit = ~ 1,
#                     dprime_asymptote = ~ 1 + cGenderMasc * (cLowVsAvg + cHighVsAvg) +
#                                             ( cGenderMasc * (cLowVsAvg + cHighVsAvg) + 1|ds1|subject) +
#                                             (1|di1|item), 
#                     dprime_invrate   = ~ 1 + cGenderMasc * (cLowVsAvg + cHighVsAvg) +
#                                             ( cGenderMasc * (cLowVsAvg + cHighVsAvg) + 1|ds2|subject) +
#                                             (1|di2|item),
#                     dprime_intercept = ~ 1 + cGenderMasc * (cLowVsAvg + cHighVsAvg) +
#                                             ( cGenderMasc * (cLowVsAvg + cHighVsAvg) + 1|ds3|subject) +
#                                             (1|di3|item),
#                     crit_leftasym  = ~ 1 + (1|cs1|subject),
#                     crit_rightasym = ~ 1 + cGenderMasc + (cGenderMasc + 1|cs2|subject),
#                     crit_invrate   = ~ 1 + cGenderMasc + (cGenderMasc + 1|cs3|subject),
#                     crit_intercept = ~ 1 + cGenderMasc + (cGenderMasc + 1|cs4|subject)
#                   )
# 
# prior2A <- c(priors$dprime, priors$crit,
#             priors$dprime_randef_subj, priors$crit_randef_subj,
#             priors$dprime_randef_item, #priors$crit_randef_item,
#             set_prior("lkj(2)", class = "cor")
#             )
# 
# # fit2A_prior <- brm(formula2A, prior = prior2A,
# #                   stanvars = stan_satf_functions, data = cur_data_df$data[1:2,], 
# #                   sample_prior = "only",
# #                   iter = 2000, warmup = 1000, chains = 4, cores = 4, seed = 1234, init_r = .1,
# #                   #control = list(metric = "dense_e", adapt_delta = .99),
# #                   file = "../workspace/models/fit_all_uncorr_bysubj2A_prior"
# #                   )
# 
# fit2A <- brm(formula2A, prior = prior2A,
#             stanvars = stan_satf_functions, data = cur_data_df$data, 
#             iter = 2000, warmup = 1000, chains = 4, cores = 4, seed = 1234, init_r = .1,
#             #control = list(adapt_delta = .95, max_treedepth = 20), # metric = "dense_e", 
#             file = "../workspace/models/fit_all_uncorr_bysubj2A",
#             sample_file = "../workspace/models/fit_all_uncorr_bysubj2A"
#             )

# ##################################################################################################
# ##################################################################################################
# ##################################################################################################
# 
# formula2B <- sat_bf(dprime = ~ 1, crit = ~ 1,
#                     dprime_asymptote = ~ 1 + cGenderMasc * (cLowVsAvg + cHighVsAvg) +
#                                           ( cGenderMasc * (cLowVsAvg + cHighVsAvg) + 1|ds1|subject), 
#                     dprime_invrate   = ~ 1 + cGenderMasc * (cLowVsAvg + cHighVsAvg) +
#                                           ( cGenderMasc * (cLowVsAvg + cHighVsAvg) + 1|ds2|subject),
#                     dprime_intercept = ~ 1 + cGenderMasc * (cLowVsAvg + cHighVsAvg) +
#                                           ( cGenderMasc * (cLowVsAvg + cHighVsAvg) + 1|ds3|subject),
#                     crit_leftasym   = ~ 1 + (1|cs1|subject) + (1|ci1|item),
#                     crit_rightasym = ~ 1 + cGenderMasc + (cGenderMasc + 1|cs2|subject) + (1|ci2|item),
#                     crit_invrate   = ~ 1 + cGenderMasc + (cGenderMasc + 1|cs3|subject) + (1|ci3|item),
#                     crit_intercept = ~ 1 + cGenderMasc + (cGenderMasc + 1|cs4|subject) + (1|ci4|item)
#                     )
# 
# prior2B <- c(priors$dprime, priors$crit,
#              priors$dprime_randef_subj, priors$crit_randef_subj,
#              priors$dprime_randef_item, priors$crit_randef_item,
#              set_prior("lkj(2)", class = "cor")
#              )
# 
# # fit2B_prior <- brm(formula2B, prior = prior2B,
# #                   stanvars = stan_satf_functions, data = cur_data_df$data[1:2,], 
# #                   sample_prior = "only",
# #                   iter = 2000, warmup = 1000, chains = 4, cores = 4, seed = 1234, init_r = .1,
# #                   #control = list(metric = "dense_e", adapt_delta = .99),
# #                   file = "../workspace/models/fit_all_uncorr_bysubj2A_prior"
# #                   )
# 
# fit2B <- brm(formula2B, prior = prior2B,
#              stanvars = stan_satf_functions, data = cur_data_df$data, 
#              iter = 2000, warmup = 1000, chains = 4, cores = 4, seed = 1234, init_r = .1,
#              #control = list(adapt_delta = .95, max_treedepth = 20), # metric = "dense_e", 
#              file = "../workspace/models/fit_all_uncorr_bysubj2B",
#              sample_file = "../workspace/models/fit_all_uncorr_bysubj2B"
#              )
# 
# ##################################################################################################
# ##################################################################################################
# ##################################################################################################
# 
# 
# fit2 <- brm(sat_bf(dprime = ~ 1, crit = ~ 1,
#                    dprime_asymptote = ~ 1 + cGenderMasc * (cLowVsAvg + cHighVsAvg) +
#                                            ( cGenderMasc * (cLowVsAvg + cHighVsAvg) + 1|ds1|subject) +
#                                            ( cGenderMasc * (cLowVsAvg + cHighVsAvg) + 1|di1|item), 
#                    dprime_invrate   = ~ 1 + cGenderMasc * (cLowVsAvg + cHighVsAvg) +
#                                            ( cGenderMasc * (cLowVsAvg + cHighVsAvg) + 1|ds2|subject) +
#                                            ( cGenderMasc * (cLowVsAvg + cHighVsAvg) + 1|di2|item),
#                    dprime_intercept = ~ 1 + cGenderMasc * (cLowVsAvg + cHighVsAvg) +
#                                            ( cGenderMasc * (cLowVsAvg + cHighVsAvg) + 1|ds3|subject) +
#                                            ( cGenderMasc * (cLowVsAvg + cHighVsAvg) + 1|di3|item),
#                    crit_leftasym   = ~ 1 + (1|cs1|subject) + (1|ci1|item),
#                    crit_rightasym = ~ 1 + cGenderMasc + (cGenderMasc + 1|cs2|subject) + (cGenderMasc + 1|ci2|item),
#                    crit_invrate   = ~ 1 + cGenderMasc + (cGenderMasc + 1|cs3|subject) + (cGenderMasc + 1|ci3|item),
#                    crit_intercept = ~ 1 + cGenderMasc + (cGenderMasc + 1|cs4|subject) + (cGenderMasc + 1|ci4|item)
#                    ),
#                     prior = c(priors$dprime, priors$crit,
#                               priors$dprime_randef_subj, priors$crit_randef_subj,
#                               priors$dprime_randef_item, priors$crit_randef_item,
#                               set_prior("lkj(2)", class = "cor")
#                     ),
#                     stanvars = stan_satf_functions, data = cur_data_df$data, 
#                     iter = 2000, chains = 4, cores = 4, seed = 1234, init_r = .1,
#                     #control = list(metric = "dense_e", adapt_delta = .99),
#                     file = "../workspace/models/fit_all_uncorr_bysubj2",
#                     sample_file = "../workspace/models/fit_all_uncorr_bysubj2"
#                     )
# 
# 
# 
# 
# ###############################################
# ###############################################
# ###############################################
# 
# # fit_prior <-
# #    brm(sat_bf(dprime = ~ 1 + cGenderMasc * (cLowVsAvg + cHighVsAvg) + 
# #                  ( cGenderMasc * (cLowVsAvg + cHighVsAvg) + 1|1|subject),
# #               crit = ~ 1 + cGenderMasc + (cGenderMasc + 1|2|subject),
# #               dprime_asymptote = ~ (1|3|item)
# #    ),
# #    prior = c(priors$dprime, priors$crit,
# #              priors$dprime_randef_subj, priors$crit_randef_subj,
# #              set_prior(nlpar = "dprimeAsymptote", prior = "student_t(50, 0, .25)", class = "sd", group = "item"),
# #              set_prior("lkj(2)", class = "cor")
# #    ),
# #    sample_prior = "only",
# #    stanvars = stan_satf_functions, data = cur_data_df$data[1:2,], 
# #    iter = 2000, chains = 4, cores = 4, seed = 12345#,
# #    #control = list(adapt_delta = 0.999, stepsize = 0.001) #init_r = .1
# #    )
# 
# 
# #
# fit0 <- brm(sat_bf(dprime = ~ 1 + (cLowVsAvg + cHighVsAvg),
#                    crit = ~ 1
#                   ),
#                   prior = c(priors$dprime, priors$crit),
#                   stanvars = stan_satf_functions, data = cur_data_df$data, 
#                   iter = 2000, chains = 4, cores = 4, seed = 1234, init_r = .1,
#                   file = "./workspace_test/fit_all_uncorr_bysubj0"
#                   )
# 
# 
# # x <- posterior_samples(fit0,
# #        c("dprimeAsymptote_Intercept",
# #          "dprimeInvrate_Intercept",
# #          "dprimeIntercept_Intercept",
# #          "critLeftAsym_Intercept",
# #          "critRightAsym_Intercept",
# #          "critInvrate_Intercept",
# #          "critIntercept_Intercept") )
# # 
# # pairs(x)
# 
# # x %>% #subset(d < 0.3 & d > -0.5 ) %>% #subset(x1 < 0.2 & x1 > 0) %>%
# #   .[,c("b_critLeftAsym_Intercept",
# #        "b_critRightAsym_Intercept",
# #        "b_critInvrate_Intercept",
# #        "b_critIntercept_Intercept"
# #   )] %>%
# #   pairs()
# # 
# # 
# # ###
# # 
# # expose_functions(fit0)
# # 
# # fn <- function(time, zero_crit_unconstrained, zero_crit_std_unconstrained, 
# #                             right_asymptote, invrate_unconstrained)
# # {
# #   sapply(time, function(time)
# #   criterion_fn(time, zero_crit_unconstrained, 
# #                zero_crit_std_unconstrained, 
# #                right_asymptote, 
# #                invrate_unconstrained))
# # }
# # 
# # 
# # p <- ggplot(data = data.frame(x=-5:5, y=-5:5), aes(x))
# # 
# # z3 <- subset(x, round(b_critZeroTCritStd_Intercept,1) == -3 ) %>% .[1,]
# # z2 <- subset(x, round(b_critZeroTCritStd_Intercept,1) == -2 ) %>% .[1,]
# # z1 <- subset(x, round(b_critZeroTCritStd_Intercept,1) == -1 ) %>% .[1,]
# # 
# # p <- p + stat_function(fun = function(time) { with(z1, fn(time, zero_crit_unconstrained=b_critZeroTCrit_Intercept, 
# #                                                       zero_crit_std_unconstrained=b_critZeroTCritStd_Intercept, 
# #                                                       right_asymptote=b_critRightAsym_Intercept, 
# #                                                       invrate_unconstrained=b_critInvrate_Intercept)) } )
# # p <- p + stat_function(fun = function(time) { with(z2, fn(time, zero_crit_unconstrained=b_critZeroTCrit_Intercept, 
# #                                                      zero_crit_std_unconstrained=b_critZeroTCritStd_Intercept, 
# #                                                      right_asymptote=b_critRightAsym_Intercept, 
# #                                                      invrate_unconstrained=b_critInvrate_Intercept)) },
# #                        color = "red")
# # p <- p + stat_function(fun = function(time) { with(z3, fn(time, zero_crit_unconstrained=b_critZeroTCrit_Intercept, 
# #                                                           zero_crit_std_unconstrained=b_critZeroTCritStd_Intercept, 
# #                                                           right_asymptote=b_critRightAsym_Intercept, 
# #                                                           invrate_unconstrained=b_critInvrate_Intercept)) },
# #                        color = "blue")
# # 
# # p + scale_x_continuous(limits = c(-0.5, 5))
# # 
# # p + stat_function(fun = function(x) x)
# # 
# # p + stat_function(fun = function(.x) .5*exp(-abs(.x)))
# # 
# 
