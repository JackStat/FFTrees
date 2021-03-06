% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/rfpred_function.R
\name{rf.pred}
\alias{rf.pred}
\title{Calculates predictions from Random Forests using the randomForest package}
\usage{
rf.pred(formula, data.train, data.test = NULL, rf.model = NULL)
}
\arguments{
\item{formula}{a formula}

\item{data.train}{dataframe. A training dataset}

\item{data.test}{dataframe. A testing dataset}

\item{rf.model}{An optional existing random forests model}
}
\description{
Calculates predictions from Random Forests using the randomForest package
}
\examples{

# Fit rf for the mushrooms dataset

mushrooms.rf <- rf.pred(formula = poisonous ~.,
                            data.train = mushrooms)



}

