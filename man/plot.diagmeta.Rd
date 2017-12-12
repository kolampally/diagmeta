\name{plot.diagmeta}
\alias{plot.diagmeta}
%- Also NEED an '\alias' for EACH other topic documented here.
\title{Plot for meta-analysis of diagnostic accuracy studies with the multiple cutoffs
}
\description{
Draws a plot for meta-analysis of diagnostic accuracy studies with the multiple cutoffs
}
\usage{
plot.diagmeta(x, which = c("survival", "youden", "roc", "sroc"), xlab = "threshold", ci = FALSE,
              ciSens = FALSE, ciSpec = FALSE, mark.optcut = FALSE, mark.cutpoints = FALSE,
              points = TRUE, lines = FALSE, rlines = TRUE, line.optcut = TRUE,
              col.points =  "rainbow",cex = 1, pch.points = 16, cex.marks = 0.7 * cex,
              lwd = 1, lwd.optcut = 2 * lwd, shading = "none", xlim = NULL, ...)
}
%- maybe also 'usage' for other objects documented here.
\arguments{
  \item{x}{An object of class \code{diagmeta}}
  \item{which}{A character vector indicating the type of plot, either \code{"reg"} or\code{"cdf"} or \code{"survival"} or \code{"Youden"} or \code{"ROC"} or \code{"SROC"} or \code{"density"}}
  \item{xlab}{An x axis label}
  \item{ci}{A logical indicating whether confidence intervals should be plotted for \code{"cdf"}, \code{"survival"} and \code{"Youden"}}
  \item{ciSens}{A logical indicating whether confidence intervals should be plotted for sensitivity, given the specificity in \code{"SROC"} plot}
  \item{ciSpec}{A logical indicating whether confidence intervals should be plotted for specificity, given the sensitivity in \code{"SROC"} plot}
  \item{mark.optcut}{
{A logical indicating whether the optimal cutoff should be marked on \code{"SROC"} plot}
}
  \item{mark.cutpoints}{
{A logical indicating whether the given cutoffs should be marked on \code{"SROC"} plot}
}
  \item{points}{A logical indicating whether points should be plotted on \code{"ROC"} plot}
  \item{lines}{A logical indicating polygonal lines connecting points belonging to the same study should be printed in plots \code{"reg"}, \code{"cdf"}, \code{"survival"} and \code{"Youden"}}
  \item{rlines}{A logical indicating whether regression lines or curves should be plotted for plots \code{"reg"}, \code{"cdf"}, \code{"survival"} and \code{"Youden"}}

  \item{line.optcut}{A logical indicating whether a vertical line should be plotted at optimal cutoff line}
  \item{col.points}{A character vector indicating color, either \code{"rainbow"} or \code{"topo"} or \code{"heat"} or \code{"terrain"} or \code{"cm"} or \code{"gray"} or \code{"black"}}

  \item{cex}{
The magnification to be used for plotting text and symbols.
}
  \item{pch.points}{
Plot symbol(s) for points
}
  \item{cex.marks}{
Magnification(s) to be used for marking cutoffs
}
  \item{lwd}{Line width}
  \item{lwd.optcut}{Line width of optimal cutoff
%%     ~~Describe \code{lwd.optcut} here~~
}
  \item{shading}{A character indicating shading and hatching confidence region in \code{"SROC"} plot, either \code{"none"} or \code{"shade"} or \code{"hatch"}}
  \item{xlim}{
 	A character or numerical vector indicating the minimum and maximum value for the horizontal axes.
}
  \item{\dots}{
Additional graphical arguments
}
}
\details{
to write
}

\references{
%% ~put references to the literature/web site here ~
}
\author{
%%  ~~who you are~~
}
\note{
%%  ~~further notes~~
}

%% ~Make other sections like Warning with \section{Warning }{....} ~

\seealso{
\code{\link{diagmeta}}
}
\examples{
feno <- read.csv2("FENO_MultipleCO_basic.csv",
                  as.is = TRUE)
str(feno)

results.f <- diagmeta(TP, FP, TN, FN, cutoff, study,
                data = feno, log.cutoff = TRUE,  model = "DIDS", distr = "l")
results.f$optcut
##
xlab <- "FeNO [ppb]"


#Regression plot with confidence intervals
plot.diagmeta(results.f, which="reg", xlab=xlab, lines = FALSE, ci = TRUE)

#cumulative distribution plot with optimal cutoff line and confidence intervals
plot(results.f, which="cdf", xlab=xlab, line.optcut = TRUE, ci= TRUE)

#survival plot with optimal cutoff line and confidence intervals
plot(results.f, which="survival", xlab=xlab, line.optcut = TRUE, ci = TRUE)

#youden plot with optimal cutoff line and confidence intervals
plot(results.f, which="youden", xlab=xlab, lines = TRUE, line.optcut = TRUE, ci = TRUE)
plot(results.f, which="ROC", lines = TRUE)
plot(results.f, which="SROC", ciSens = TRUE, ciSpec = TRUE, mark.optcut = TRUE, shading = "hatch")

}
% Add one or more standard keywords, see file 'KEYWORDS' in the
% R documentation directory.
\keyword{ ~kwd1 }% use one of  RShowDoc("KEYWORDS")
\keyword{ ~kwd2 }% __ONLY ONE__ keyword per line
