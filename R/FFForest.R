#' Creates a forest of fast and frugal decision trees
#'
#' @param formula formula. A formula specifying a binary criterion as a function of multiple variables
#' @param data dataframe. A dataframe containing variables in formula
#' @param max.levels integer. Maximum number of levels considered for the trees.
#' @param sim integer. Number of simulations to perform.
#' @param train.p numeric. What percentage of the data to use for training in simulations.
#' @param rank.method string. How to rank cues during tree construction. "m" (for marginal) means that cues will only be ranked once with the entire training dataset. "c" (conditional) means that cues will be ranked after each level in the tree with the remaining unclassified training exemplars. This also means that the same cue can be used multiple times in the trees. Note that the "c" method will take (much) longer and may be prone to overfitting.
#' @param hr.weight numeric. How much weight to give to maximizing hits versus minimizing false alarms (between 0 and 1)
#' @param verbose logical. Should progress reports be printed?
#' @param do.lr,do.cart,do.rf logical. Should regression, cart, and/or random forests be calculated for comparison?
#' @param cpus integer. Number of cpus to use (any value larger than 1 will initiate parallel calculations in snowfall)
#' @importFrom stats median formula
#' @importFrom graphics text points segments plot
#' @return A dataframe containing best thresholds and marginal classification statistics for each cue
#' @export
#' @examples
#'
#' train.5m <- FFForest(formula = diagnosis ~.,
#'                      data = breastcancer,
#'                      train.p = .5,
#'                      sim = 5,
#'                      rank.method = "m",
#'                      cpus = 1)
#'
#'
#'
FFForest <- function(formula = NULL,
                     data = NULL,
                     max.levels = 5,
                     sim = 10,
                     train.p = .5,
                     rank.method = "m",
                     hr.weight = .5,
                     verbose = TRUE,
                     cpus = 1,
                     do.lr = TRUE,
                     do.cart = TRUE,
                     do.rf = TRUE
) {

simulations <- data.frame(
  sim = 1:sim,
  cues = rep(NA, sim),
  thresholds = rep(NA, sim)
)

# getsim.fun does one training split and returns tree statistics
getsim.fun <- function(i) {

result.i <- FFTrees::FFTrees(formula = formula,
                              data = data,
                              data.test = NULL,
                              train.p = train.p,
                              max.levels = max.levels,
                              rank.method = rank.method,
                              hr.weight = hr.weight,
                              object = NULL,
                              do.cart = do.cart,
                              do.lr = do.lr,
                              do.rf = do.rf)

decisions.i <- predict(result.i, data)

tree.stats.i <- result.i$tree.stats
comp.stats.i <- c()

if(do.lr) {
lr.stats.i <- result.i$lr$stats
names(lr.stats.i) <- paste0("lr.", names(lr.stats.i))
comp.stats.i <- c(comp.stats.i, lr.stats.i)
}

if(do.cart) {
  cart.stats.i <- result.i$cart$stats
  names(cart.stats.i) <- paste0("cart.", names(cart.stats.i))
  comp.stats.i <- c(comp.stats.i, cart.stats.i)
  }

if(do.rf) {
  rf.stats.i <- result.i$rf$stats
  names(rf.stats.i) <- paste0("rf.", names(rf.stats.i))
  comp.stats.i <- c(comp.stats.i, rf.stats.i)
}

comp.stats.i <- unlist(comp.stats.i)

return(list("trees" = tree.stats.i,
            "decisions" = decisions.i,
            "competitors" = comp.stats.i
            ))

}

if(cpus == 1) {

  result.ls <- lapply(1:nrow(simulations), FUN = function(x) {

    if(verbose) {print(paste0(x, " of ", nrow(simulations)))}
    return(getsim.fun(x))

    })

}

if(cpus > 1) {

  suppressMessages(snowfall::sfInit(parallel = TRUE, cpus = cpus))
  snowfall::sfExport("simulations")
  snowfall::sfLibrary(FFTrees)
  snowfall::sfExport("formula")
  snowfall::sfExport("data")
  snowfall::sfExport("max.levels")
  snowfall::sfExport("train.p")
  snowfall::sfExport("do.lr")
  snowfall::sfExport("do.rf")
  snowfall::sfExport("do.cart")
  snowfall::sfExport("max.levels")
  snowfall::sfExport("rank.method")
  snowfall::sfExport("hr.weight")

  result.ls <- snowfall::sfClusterApplySR(1:nrow(simulations), fun = getsim.fun, perUpdate = 1)
  suppressMessages(snowfall::sfStop())

  }

# Append final results to simulations

best.tree.v <- sapply(1:length(result.ls), FUN = function(x) {

  best.tree.i <- which(result.ls[[x]]$trees$train$v == max(result.ls[[x]]$trees$train$v))

  if(length(best.tree.i) > 1) {best.tree.i <- sample(best.tree.i, 1)}

  return(best.tree.i)

})

sapply(1:length(result.ls), FUN = function(x) {length(result.ls[[x]]$decisions)})

decisions <- matrix(unlist(lapply(1:length(result.ls), FUN = function(x) {

  return(result.ls[[x]]$decisions)

})), nrow = nrow(data), ncol = sim)

simulations$cues <- sapply(1:length(result.ls),
                             FUN = function(x) {result.ls[[x]]$trees$train$cues[best.tree.v[x]]})

simulations$thresholds <- sapply(1:length(result.ls),
                             FUN = function(x) {result.ls[[x]]$trees$train$thresholds[best.tree.v[x]]})

simulations$hr.train <- sapply(1:length(result.ls),
                                FUN = function(x) {result.ls[[x]]$trees$train$hr[best.tree.v[x]]})

simulations$far.train <- sapply(1:length(result.ls),
                                 FUN = function(x) {result.ls[[x]]$trees$train$far[best.tree.v[x]]})

simulations$v.train <- sapply(1:length(result.ls),
                              FUN = function(x) {result.ls[[x]]$trees$train$v[best.tree.v[x]]})

simulations$dprime.train <- qnorm(simulations$hr.train) - qnorm(simulations$far.train)


simulations$hr.test <- sapply(1:length(result.ls),
                               FUN = function(x) {result.ls[[x]]$trees$test$hr[best.tree.v[x]]})

simulations$far.test <- sapply(1:length(result.ls),
                                FUN = function(x) {result.ls[[x]]$trees$test$far[best.tree.v[x]]})

simulations$v.test <- sapply(1:length(result.ls),
                             FUN = function(x) {result.ls[[x]]$trees$test$v[best.tree.v[x]]})

simulations$dprime.test <- qnorm(simulations$hr.test) - qnorm(simulations$far.test)

# Get overall cue frequencies
frequencies <- table(unlist(strsplit(simulations$cues, ";")))

# Get connections from simulation
{
## get unique values

unique.cues <- unique(unlist(strsplit(simulations$cues, ";")))

connections <- expand.grid("cue1" = unique.cues,
                        "cue2" = unique.cues,
                        stringsAsFactors = FALSE)

for(i in 1:nrow(connections)) {

  N <- sum(sapply(1:length(simulations$cues), FUN = function(x) {

    connections[i, 1] %in% unlist(strsplit(simulations$cues[x], ";")) &
    connections[i, 2] %in% unlist(strsplit(simulations$cues[x], ";"))

  }))

  connections$N[i] <- N

}
}

# Get competition results
competitors <- as.data.frame(t(sapply(1:length(result.ls), FUN = function(x) {result.ls[[x]]$competitors})))

if(do.lr) {

  lr.sim <- competitors[,grepl("lr", names(competitors))]
  names(lr.sim) <- gsub("lr.", replacement = "", x = names(lr.sim))

} else {lr.sim <- NULL}

if(do.cart) {

  cart.sim <- competitors[,grepl("cart", names(competitors))]
  names(cart.sim) <- gsub("cart.", replacement = "", x = names(cart.sim))

} else {cart.sim <- NULL}


if(do.rf) {

  rf.sim <- competitors[,grepl("rf", names(competitors))]
  names(rf.sim) <- gsub("rf.", replacement = "", x = names(rf.sim))

} else {rf.sim <- NULL}

# Summarise output

output <-list("tree.sim" = simulations,
              "decisions" = decisions,
              "frequencies" = frequencies,
              "connections" = connections,
              "lr.sim" = lr.sim,
              "cart.sim" = cart.sim,
              "rf.sim" = rf.sim)

class(output) <- "FFForest"

return(output)

}
