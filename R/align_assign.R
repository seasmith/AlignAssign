
captureArea <- function() {
  capture <- rstudioapi::getActiveDocumentContext()

  range_start <- capture$selection[[1L]]$range$start[[1L]]
  range_end   <- capture$selection[[1L]]$range$end[[1L]]

  capture_contents        <- capture$contents[range_start:range_end]
  names(capture_contents) <- range_start:range_end
  capture_contents        <- capture_contents
  return(capture_contents)
}


findr <- function(find, where) {

  found  <- grep(find, where)
  regex_positions <- regexec(find, where)
  regex_positions <- regex_positions[found]

  assignment_positions <- sapply(regex_positions, `[[`, 1L)
  doc_lines            <- as.integer(names(where))
  max.pos              <- which.max(assignment_positions)

  furthest_row         <- doc_lines[found[max.pos]]
  furthest_column      <- max(assignment_positions)


  rows_to_align    <- doc_lines[found[-max.pos]]
  columns_to_align <- assignment_positions[-max.pos]

  positions_list <- Map(c, rows_to_align, columns_to_align)

  insertText_num  <- furthest_column - columns_to_align
  insertText_list <- vapply(insertText_num,
                            function(x) paste0(rep(" ", x), collapse = ""),
                            character(1))

  rstudioapi::insertText(positions_list, insertText_list)
}

#' Align a highlighted region's assignment operators.
#'
#' @return
#' Aligns the single caret operators (\code{<-}) with a highlighted region.
#' @export
alignr <- function() {
  area <- captureArea()
  findr("<-", area)
}
