GITHUB_OWNER <- "amitchaudhary82"
GITHUB_REPO <- "story-sandbox"
GITHUB_API_VERSION <- "2022-11-28"

validate_issue_numbers <- function(issue_numbers) {
  if (!is.numeric(issue_numbers) ||
      length(issue_numbers) == 0L ||
      anyNA(issue_numbers) ||
      any(!is.finite(issue_numbers)) ||
      any(issue_numbers < 1) ||
      any(issue_numbers > .Machine$integer.max) ||
      any(issue_numbers != floor(issue_numbers))) {
    stop("Issue numbers must be one or more positive whole numbers.",
         call. = FALSE)
  }
  if (anyDuplicated(issue_numbers)) {
    stop("An issue number was selected more than once.", call. = FALSE)
  }
  as.integer(issue_numbers)
}

validate_labels <- function(labels, argument_name) {
  if (!is.character(labels) ||
      anyNA(labels) ||
      any(!nzchar(trimws(labels)))) {
    stop(argument_name, " must contain non-empty label names.",
         call. = FALSE)
  }
  if (anyDuplicated(labels)) {
    stop(argument_name, " must not contain duplicate label names.",
         call. = FALSE)
  }
  labels
}

require_non_empty_text <- function(value, argument_name) {
  if (!is.character(value) ||
      length(value) != 1L ||
      is.na(value) ||
      !nzchar(trimws(value))) {
    stop(argument_name, " must be a non-empty piece of text.",
         call. = FALSE)
  }
  value
}

github_token <- local({
  token <- NULL
  function(clear = FALSE) {
    if (clear) {
      token <<- NULL
      return(invisible(NULL))
    }
    if (is.null(token)) {
      if (!requireNamespace("rstudioapi", quietly = TRUE)) {
        stop("Install the rstudioapi package first; see RSTUDIO.md.",
             call. = FALSE)
      }
      token <<- rstudioapi::askForPassword("GitHub personal access token")
      if (is.null(token) || !nzchar(token)) {
        token <<- NULL
        stop("No token was entered; request cancelled.", call. = FALSE)
      }
    }
    token
  }
})

clear_github_token <- function() {
  github_token(clear = TRUE)
  message("The cached token was cleared from this R session.")
  invisible(NULL)
}

github_request <- function(method, path, query = NULL, body = NULL) {
  url <- paste0(
    "https://api.github.com/repos/",
    GITHUB_OWNER, "/", GITHUB_REPO, "/", path
  )

  response <- httr::VERB(
    method = method,
    url = url,
    query = query,
    body = body,
    encode = "json",
    httr::add_headers(
      Authorization = paste("Bearer", github_token()),
      Accept = "application/vnd.github+json",
      `X-GitHub-Api-Version` = GITHUB_API_VERSION
    ),
    httr::timeout(30)
  )
  httr::stop_for_status(response)
  if (httr::status_code(response) == 204L) {
    return(invisible(NULL))
  }
  httr::content(response, as = "parsed", type = "application/json",
                encoding = "UTF-8")
}

fetch_issue_page <- function(state, page) {
  github_request(
    "GET",
    "issues",
    query = list(state = state, per_page = 100, page = page)
  )
}

list_stories <- function(state = "open") {
  state <- match.arg(state, c("open", "closed", "all"))
  issues <- list()
  page <- 1L

  repeat {
    batch <- fetch_issue_page(state, page)
    if (length(batch) == 0L) {
      break
    }
    issues <- c(issues, batch)
    if (length(batch) < 100L) {
      break
    }
    page <- page + 1L
  }

  # GitHub's issues endpoint also returns pull requests; this sandbox lists stories.
  issues <- Filter(function(issue) is.null(issue$pull_request), issues)
  if (length(issues) == 0L) {
    message("No stories found.")
    return(invisible(data.frame()))
  }

  stories <- data.frame(
    number = vapply(issues, function(issue) issue$number, integer(1)),
    title = vapply(issues, function(issue) issue$title, character(1)),
    state = vapply(issues, function(issue) issue$state, character(1)),
    labels = vapply(
      issues,
      function(issue) {
        label_names <- vapply(issue$labels, function(label) label$name,
                              character(1))
        paste(label_names, collapse = ", ")
      },
      character(1)
    ),
    updated_at = vapply(issues, function(issue) issue$updated_at, character(1)),
    stringsAsFactors = FALSE
  )
  print(stories, row.names = FALSE)
  invisible(stories)
}

selected_stories <- function(issue_numbers) {
  issue_numbers <- validate_issue_numbers(issue_numbers)
  stories <- list_stories(state = "all")
  selected <- stories[stories$number %in% issue_numbers, , drop = FALSE]

  missing_numbers <- setdiff(issue_numbers, selected$number)
  if (length(missing_numbers) > 0L) {
    stop(
      "These issue numbers were not found in the repository: ",
      paste(missing_numbers, collapse = ", "),
      call. = FALSE
    )
  }
  selected[match(issue_numbers, selected$number), , drop = FALSE]
}

confirm_write <- function(action, stories, confirmation = "YES") {
  cat("\n", action, "\n", sep = "")
  print(stories[, c("number", "title", "state"), drop = FALSE],
        row.names = FALSE)
  answer <- readline(
    paste0("Type ", confirmation, " to continue (anything else cancels): ")
  )
  if (!identical(answer, confirmation)) {
    message("Cancelled; no changes were made.")
    return(FALSE)
  }
  TRUE
}

update_labels <- function(issue_numbers, add = character(), remove = character()) {
  issue_numbers <- validate_issue_numbers(issue_numbers)
  add <- validate_labels(add, "add")
  remove <- validate_labels(remove, "remove")
  if (length(add) == 0L && length(remove) == 0L) {
    stop("Provide at least one label to add or remove.", call. = FALSE)
  }
  overlap <- intersect(add, remove)
  if (length(overlap) > 0L) {
    stop("A label cannot be added and removed in the same request: ",
         paste(overlap, collapse = ", "), call. = FALSE)
  }

  stories <- selected_stories(issue_numbers)
  cat("\nLabels to add: ",
      if (length(add) == 0L) "(none)" else paste(add, collapse = ", "),
      "\nLabels to remove: ",
      if (length(remove) == 0L) "(none)" else paste(remove, collapse = ", "),
      "\n", sep = "")
  if (!confirm_write("Update labels on these stories?", stories)) {
    return(invisible(FALSE))
  }

  for (number in issue_numbers) {
    if (length(add) > 0L) {
      github_request(
        "POST",
        paste0("issues/", number, "/labels"),
        body = list(labels = unname(as.list(add)))
      )
    }
    for (label in remove) {
      github_request(
        "DELETE",
        paste0("issues/", number, "/labels/", URLencode(label, reserved = FALSE))
      )
    }
    message("Updated labels on issue #", number, ".")
  }
  invisible(TRUE)
}

post_story_comment <- function(issue_numbers, comment) {
  issue_numbers <- validate_issue_numbers(issue_numbers)
  comment <- require_non_empty_text(comment, "comment")
  stories <- selected_stories(issue_numbers)
  cat("\nComment to be posted:\n", comment, "\n", sep = "")
  if (!confirm_write("Post this comment on these stories?", stories)) {
    return(invisible(FALSE))
  }

  for (number in issue_numbers) {
    github_request(
      "POST",
      paste0("issues/", number, "/comments"),
      body = list(body = comment)
    )
    message("Posted comment on issue #", number, ".")
  }
  invisible(TRUE)
}

close_after_cab_approval <- function(issue_numbers, cab_reference, comment) {
  issue_numbers <- validate_issue_numbers(issue_numbers)
  cab_reference <- require_non_empty_text(cab_reference, "cab_reference")
  comment <- require_non_empty_text(comment, "comment")
  stories <- selected_stories(issue_numbers)

  if (any(stories$state != "open")) {
    stop("All selected stories must be open before they can be closed.",
         call. = FALSE)
  }

  approval_comment <- paste0(
    "CAB approval recorded (reference: ", cab_reference, ").\n\n",
    comment
  )
  cat("\nApproval comment to be posted before closing:\n")
  cat(approval_comment, "\n")
  if (!confirm_write(
    "Record CAB approval and close these stories?",
    stories,
    confirmation = "CLOSE"
  )) {
    return(invisible(FALSE))
  }

  for (number in issue_numbers) {
    github_request(
      "POST",
      paste0("issues/", number, "/comments"),
      body = list(body = approval_comment)
    )
    github_request(
      "PATCH",
      paste0("issues/", number),
      body = list(state = "closed", state_reason = "completed")
    )
    message("Recorded CAB approval and closed issue #", number, ".")
  }
  invisible(TRUE)
}
