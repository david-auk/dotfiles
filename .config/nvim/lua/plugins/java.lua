return {
  {
    "mfussenegger/nvim-jdtls",

    opts = {
      settings = {
        java = {
          configuration = {
            updateBuildConfiguration = "automatic",
          },

          completion = {
            importOrder = {
              "java",
              "javax",
              "org",
              "com",
              "io",
              "nl",
            },
          },
        },
      },
    },
  },
}
