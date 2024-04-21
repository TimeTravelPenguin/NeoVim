return {
  enabled = true,
  version = "*",
  languages = {
    python = {
      template = {
        annotation_convention = "numpydoc",
      },
    },
    lua = {
      template = {
        annotation_convention = "emmylua",
      },
    },
    sh = {
      template = {
        annotation_convention = "google_bash",
      },
    },
  },
}
