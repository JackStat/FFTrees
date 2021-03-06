% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/growFFTrees_function.R
\name{grow.FFTrees}
\alias{grow.FFTrees}
\title{Grows fast and frugal trees}
\usage{
grow.FFTrees(formula, data, rank.method = "m", hr.weight = 0.5,
  max.levels = 4, stopping.rule = "exemplars", stopping.par = 0.1,
  verbose = F, ...)
}
\arguments{
\item{formula}{formula. A formula}

\item{data}{dataframe. A dataset}

\item{rank.method}{character. A string indicating how to rank cues during tree construction. "m" (for marginal) means that cues will only be ranked once with the entire training dataset. "c" (conditional) means that cues will be ranked after each level in the tree with the remaining unclassified training exemplars.}

\item{hr.weight}{numeric. A value between 0 and 1 indicating how much weight to give to maximizing hit rates versus minimizing false alarm rates. Used for selecting cue thresholds and ranking cues in the tree.}

\item{max.levels}{integer. The maximum number of levels in the tree(s)}

\item{stopping.rule}{character. A string indicating the method to stop growing trees. "levels" means the tree grows until a certain level. "exemplars" means the tree grows until a certain number of unclassified exemplars remain. "statdelta" means the tree grows until the change in the tree.criterion statistic is less than a specified level.}

\item{stopping.par}{numeric. A number indicating the parameter for the stopping rule. For stopping.rule == "levels", this is the number of levels. For stopping rule == "exemplars", this is the smallest percentage of examplars allowed in the last level.}

\item{verbose}{logical.  Should tree growing progress be displayed?}

\item{...}{Currently ignored}
}
\value{
A list of length 4. tree.definitions contains definitions of the tree(s). tree.stats contains classification statistics for the tree(s). levelout shows which level in the tree(s) each exemplar is classified. Finally, decision shows the classification decision for each tree for each exemplar
}
\description{
Grows fast and frugal trees
}
\examples{

 titanic.trees <- grow.FFTrees(formula = survived ~.,
                                   data = titanic)

# Tree definitions are stored in tree.definitions

titanic.trees$tree.definitions

# Tree classification statistics are in tree.stats

titanic.trees$tree.stats

# The level at which each exemplar is classified for each tree is in levelout

titanic.trees$levelout

# The decision for each exemplar for each tree is in decision

titanic.trees$decision



}

