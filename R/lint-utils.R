stripComments <- function(content) {
  gsub("#.*", "", content, perl = TRUE)
}

hasAbsolutePaths <- function(content) {
  regex <- c(
    "[\'\"]\\s*[a-zA-Z]:", ## windows-style absolute paths
    "[\'\"]\\s*\\\\\\\\", ## windows UNC paths
    "[\'\"]\\s*/(?!/)(.*?)/(.*?)", ## unix-style absolute paths
    "[\'\"]\\s*~/", ## path to home directory
    "\\[(.*?)\\]\\(\\s*[a-zA-Z]:", ## windows-style markdown references [Some image](C:/...)
    "\\[(.*?)\\]\\(\\s*/", ## unix-style markdown references [Some image](/Users/...)
    NULL ## so we don't worry about commas above
  )
  results <- as.logical(Reduce(`+`, lapply(regex, function(rex) {
    grepl(rex, content, perl = TRUE)
  })))
}

noMatch <- function(x) {
  identical(attr(x, "match.length"), -1L)
}

badRelativePaths <- function(content, project, path) {
  
  ## Figure out how deeply the path of the file is nested
  ## (it is relative to the project root)
  slashMatches <- gregexpr("/", path)
  nestLevel <- if (noMatch(slashMatches)) 0 else length(slashMatches[[1]])
  
  ## Identify occurrences of "../"
  regexResults <- gregexpr("../", content, fixed = TRUE)
  
  ## Figure out sequential runs of `../`
  runs <- lapply(regexResults, function(x) {
    if (noMatch(x)) return(NULL)
    rle <- rle(as.integer(x) - seq(0, by = 3, length.out = length(x)))
    rle$lengths
  })
  
  badPaths <- vapply(runs, function(x) {
    any(x > nestLevel)
  }, logical(1))
  
  badPaths
}

enumerate <- function(X, FUN, ...) {
  FUN <- match.fun(FUN)
  result <- vector("list", length(X))
  for (i in seq_along(X)) {
    result[[i]] <- FUN(X[[i]], i, ...)
  }
  names(result) <- names(X)
  result
}

makeLinterMessage <- function(header, content, lines) {
  c(
    paste0(header, ":"),
    paste(lines, ": ", content[lines], sep = ""),
    "\n"
  )
}

hasLint <- function(x) {
  any(unlist(lapply(x, function(x) {
    lapply(x, function(x) {
      length(x$indices) > 0
    })
  })))
}

isRCodeFile <- function(path) {
  grepl("\\.[rR]$|\\.[rR]md$|\\.[rR]nw$", path)
}