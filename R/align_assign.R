capture <- function() {
  # Get context
  rstudioapi::getActiveDocumentContext()
}

captureArea <- function(capture) {
  # Find range
  range_start <- capture$selection[[1L]]$range$start[[1L]]
  range_end   <- capture$selection[[1L]]$range$end[[1L]]

  # Dump contents and use highlighted lines as names.
  contents        <- capture$contents[range_start:range_end]
  names(contents) <- range_start:range_end
  return(contents)
}

findRegEx <- function(find, where) {

  # Find matches, extract positions, find furthest <-, get rows/cols to align.
  matched.rows <- grep(find, where)
  positions <- regexec(find, where)
  positions <- positions[matched.rows]

  lines.highlighted <- as.integer(names(where))
  matched.cols      <- sapply(positions, `[[`, 1L)
  which.max.col     <- which.max(matched.cols)

  furthest_row    <- lines.highlighted[matched.rows[which.max.col]]
  furthest_column <- max(matched.cols)

  return(list(matched.rows      = matched.rows,
              matched.cols      = matched.cols,
              lines.highlighted = lines.highlighted,
              which.max.col     = which.max.col,
              furthest_column   = furthest_column))
}

assembleInsert <-function(info) {
  # Unload variables
  matched.rows      <- info$matched.rows
  matched.cols      <- info$matched.cols
  lines.highlighted <- info$lines.highlighted
  which.max.col     <- info$which.max.col
  furthest_column   <- info$furthest_column

  # Find the rows to align and the current column position of each regEx match.
  rows_to_align    <- lines.highlighted[matched.rows[-which.max.col]]
  columns_to_align <- matched.cols[-which.max.col]

  # Set location for spaces to be inserted.
  location <- Map(c, rows_to_align, columns_to_align)

  # Find and set the number of spaces to insert on each line.
  text_num <- furthest_column - columns_to_align
  text     <- vapply(text_num,
                     function(x) paste0(rep(" ", x), collapse = ""),
                     character(1))

  return(list(location = location, text = text))
}

insertr <- function(list) {
  rstudioapi::insertText(list[["location"]], list[["text"]])
}

#' Align a highlighted region's assignment operators.
#'
#' @param rgx_op Regex for assignment operator
#' @return
#' Aligns the given or guessed operator within a highlighted region.
#' @export
alignAssign <- function(rgx_op = NULL) {
  capture <- capture()
  area    <- captureArea(capture)
  if (is.null(rgx_op)) rgx_op <- guess_operator(area)
  loc     <- findRegEx(rgx_op, area)
  insertList <- assembleInsert(loc)
  insertr(insertList)
}

#' Align a highlighted region's assignment operators.
#'
#' @return Aligns the equal sign assignment operators (\code{=}) within a
#' highlighted region.
#' @export
alignAssignEqual <- function() {
  alignAssign("=")
}

#' Align a highlighted region's assignment operators.
#'
#' @return Aligns the single caret operators (\code{<-}) within a
#' highlighted region.
#' @export
alignAssignArrow <- function() {
  alignAssign("<-")
}

guess_operator <- function(area = captureArea(capture())) {
  area <- strsplit(area, "\n")
  counts <- list(
    "=" = vapply(gregexpr("=", area, fixed = TRUE), function(x) length(x[x > 0]), integer(1)),
    "<-" = vapply(gregexpr("<-", area, fixed = TRUE), function(x) length(x[x > 0]), integer(1))
  )
  # Does one appear in all? (keep)
  all_ones <- vapply(lapply(counts, function(x) x == 1), all, logical(1))
  if (sum(all_ones) == 1) return(names(all_ones)[all_ones])

  # Does only one appear at all? (keep)
  nones <- vapply(lapply(counts, function(x) x == 0), all, logical(1))
  if (sum(nones) == 1) {
    return(names(counts)[!nones])
  } else if (sum(nones) == 2) {
    stop("Neither `=` or `<-` are used in the selected lines")
  }

  # if not in all or none then are either duplicated on a line? (discard)
  mult_in_lines <- vapply(lapply(counts, function(x) x > 1), sum, integer(1))
  if (sum(mult_in_lines) == 1) return(names(counts)[!mult_in_lines])

  # fall back to max count
  some_ones <- vapply(lapply(counts, function(x) x == 1), sum, integer(1))
  all_same <- length(unique(counts)) == 1
  if (!all_same) {
    return(names(which.max(some_ones)))
  } else {
    warning("Couldn't guess the operator for alignment, trying ` <- `")
    return("<-")
  }
}

alignCursor <- function() {
  context <- rstudioapi::getActiveDocumentContext()

  cursors <- lapply(context$selection, function(x) {
    rbind(x$range$start, x$range$end)
  })

  if (length(cursors) < 2) {
    message("Nothing to align, did you place multiple cursors in the document?")
    return()
  }

  x <- as.data.frame(do.call("rbind", cursors))
  x <- unique(x)
  x <- x[order(x$row), ]

  # used to keep track of added space if multiple cursors per line
  added_spaces <- data.frame(row = unique(x$row), nt = 0L)

  x$group <- sequence(rle(x$row)$lengths)
  x <- split(x, x$group)
  for (xg in x) {
    xg            <- merge(xg, added_spaces, by = "row")
    xg$column     <- xg$column + xg$nt
    xg$n          <- max(xg$column) - xg$column
    added_spaces  <- update_spaces(added_spaces, xg)
    spaces_to_add <- make_space(xg$n)
    locs          <- Map(c, xg$row, xg$column)
    rstudioapi::insertText(locs, spaces_to_add, id = context$id)
  }
}

make_space <- function(n) {
  vapply(n, function(nn) strrep(' ', nn), " ")
}

update_spaces <- function(a, x) {
  a <- merge(a, x[, c("row", "n")], by = "row")
  a$nt <- a$nt + x$n
  a[, c("row", "nt")]
}
