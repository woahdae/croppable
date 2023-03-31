export default [
  {
    input: "app/javascript/croppable/index.js",
    output: [
      {
        file: "app/assets/javascripts/croppable.js",
        format: "umd",
        name: "Croppable",
        globals: {
          'cropperjs': 'Cropper'
        }
      },
      {
        file: "app/assets/javascripts/croppable.esm.js",
        format: "es",
      }
    ],
    external: ['cropperjs']
  }
]
