import Cropper from 'cropperjs';

const input = document.querySelector('.croppable-input');

if (input) {
  input.addEventListener('change', updateImageDisplay);
}

function updateImageDisplay(event) {
  const input      = event.target;
  const wrapper    = input.closest(".croppable-wrapper");
  const controls   = wrapper.querySelector(".croppable-controls");
  const container  = wrapper.querySelector(".croppable-container");
  const centerBtn  = wrapper.querySelector(".croppable-center");
  const fitBtn     = wrapper.querySelector(".croppable-fit");
  const bgColorBtn = wrapper.querySelector(".croppable-bgcolor");
  const xInput     = wrapper.querySelector(".croppable-x");
  const yInput     = wrapper.querySelector(".croppable-y");
  const scaleInput = wrapper.querySelector(".croppable-scale");

  const width      = input.dataset.width;
  const height     = input.dataset.height;

  const file  = input.files[0];
  const image = document.createElement('img');

  image.src = URL.createObjectURL(file);

  const cropper = new Cropper(image, {container, template: template(width, height)});

  const cropperImage  = cropper.getCropperImage();
  const cropperCanvas = cropper.getCropperCanvas();

  controls.style.display = "flex";

  const matrix     = cropperImage.$getTransform();
  xInput.value     = matrix[4];
  yInput.value     = matrix[5];
  scaleInput.value = matrix[0];

  cropperCanvas.style.backgroundColor = bgColorBtn.value;

  cropperImage.addEventListener('transform', (event) => {
    const matrix = event.detail.matrix;

    xInput.value     = matrix[4];
    yInput.value     = matrix[5];
    scaleInput.value = matrix[0];
  });

  bgColorBtn.addEventListener("change", (event) => {
    event.preventDefault();
    cropperCanvas.style.backgroundColor = event.target.value;
  })

  centerBtn.addEventListener("click", (event) => {
    event.preventDefault();
    cropperImage.$center('cover')
  })

  fitBtn.addEventListener("click", (event) => {
    event.preventDefault();
    cropperImage.$center('contain')
  })
}

function template(width, height) {
  return `
<cropper-canvas style="height: ${height}px; width: ${width}px;">
  <cropper-image slottable></cropper-image>
  <cropper-handle action="move" plain></cropper-handle>
</cropper-canvas>
  `
}
