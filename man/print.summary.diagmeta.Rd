\name{print.summary.diagmeta}
\alias{print.summary.diagmeta}
%- Also NEED an '\alias' for EACH other topic documented here.
\title{
Print and summary method for objects of class diagmeta
}
\description{
Print and summary method for objects of class \code{\link{diagmeta}}
}
\usage{
print.summary.diagmeta(x, ...)
}
\arguments{
  \item{x}{An object of class \code{\link{diagmeta}}}
  \item{...}{additional arguments}
}

\seealso{
\code{\link{diagmeta}}
}
\examples{
## Not run

## Fenomeda data

feno <- read.csv2("FENO_MultipleCO_basic.csv",
                  as.is = TRUE)
data <- feno
results.f <- diagmeta(TP, FP, TN, FN, cutoff, study,
                data = feno, log.cutoff = TRUE,  model = "DIDS", distr = "l")

print.summary.diagmeta(results.f)

}
