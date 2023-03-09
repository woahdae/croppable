import Cropper from 'cropperjs';

function isTurbolinksEnabled() {
  try {
    return Turbolinks.supported;
  } catch(_) {
    return false;
  }
}

if(isTurbolinksEnabled()) {
  document.addEventListener('turbo:load', start)
} else {
  document.addEventListener('DOMContentLoaded', start)
}

function start() {
  const dropAreas  = document.getElementsByClassName('croppable-droparea');

  Array.from(dropAreas).forEach((dropArea) => {
    const wrapper = dropArea.closest(".croppable-wrapper");
    const input   = wrapper.querySelector(".croppable-input");

    input.addEventListener('change', (event) => {
      const file  = input.files[0];

      const image = document.createElement('img');
      image.src = URL.createObjectURL(file);

      updateImageDisplay(image, wrapper, true, input)
    });

    dropArea.onclick = () => input.click()

    dropArea.addEventListener("dragover", (event)=>{
      event.preventDefault();
      dropArea.classList.add("active");
    });

    dropArea.addEventListener("dragleave", ()=>{
      dropArea.classList.remove("active");
    });

    dropArea.addEventListener("drop", (event)=>{
      event.preventDefault();

      const file  = event.dataTransfer.files[0];

      if (file.type.match(/image.*/)) {
        input.files = event.dataTransfer.files;

        const image = document.createElement('img');
        image.src = URL.createObjectURL(file);

        updateImageDisplay(image, wrapper, true, input)
      }

      dropArea.classList.remove("active");
    });
  });

  const images = document.getElementsByClassName('croppable-image');

  Array.from(images).forEach((image) => {
    const wrapper = image.closest(".croppable-wrapper");

    updateImageDisplay(image, wrapper, false, false)
  });
}

function updateImageDisplay(image, wrapper, isNewImage, input) {
  const controls    = wrapper.querySelector(".croppable-controls");
  const container   = wrapper.querySelector(".croppable-container");
  const centerBtn   = wrapper.querySelector(".croppable-center");
  const fitBtn      = wrapper.querySelector(".croppable-fit");
  const deleteBtn   = wrapper.querySelector(".croppable-delete");
  const bgColorBtn  = wrapper.querySelector(".croppable-bgcolor");
  const xInput      = wrapper.querySelector(".croppable-x");
  const yInput      = wrapper.querySelector(".croppable-y");
  const scaleInput  = wrapper.querySelector(".croppable-scale");
  const deleteInput = wrapper.querySelector(".croppable-input-delete");
  const dropArea    = wrapper.querySelector(".croppable-droparea");
  const width       = wrapper.dataset.width;
  const height      = wrapper.dataset.height;

  dropArea.classList.add("inactive");
  container.classList.add("active");
  deleteInput.checked = false;

  cleanContainer()

  const cropper = new Cropper(image, {container, template: template(width, height)});

  const cropperImage  = cropper.getCropperImage();
  const cropperCanvas = cropper.getCropperCanvas();

  controls.style.display = "flex";

  var saveTransform = false;

  cropperImage.$ready(() => {
    if (xInput.value != "" && !isNewImage) {
      var waitForTranform = null;

      // Turbolinks hack to actually apply initial transformation
      if(isTurbolinksEnabled) {
        waitForTranform = 10;
      } else {
        waitForTranform = 0;
      }

      setTimeout(() => {
        cropperImage.$setTransform(+scaleInput.value, 0, 0, +scaleInput.value, +xInput.value, +yInput.value);

        saveTransform = true;
      }, waitForTranform)
    } else {
      const matrix     = cropperImage.$getTransform();
      xInput.value     = matrix[4];
      yInput.value     = matrix[5];
      scaleInput.value = matrix[0];

      saveTransform = true;
    }
  })

  cropperImage.addEventListener('transform', (event) => {
    if(saveTransform) {
      const matrix = event.detail.matrix;
      xInput.value     = matrix[4];
      yInput.value     = matrix[5];
      scaleInput.value = matrix[0];
    }
  });

  cropperCanvas.style.backgroundColor = bgColorBtn.value;

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

  deleteBtn.addEventListener("click", (event) => {
    event.preventDefault();

    deleteInput.checked = true;

    if (input) { input.value = ""; }

    cleanContainer()

    dropArea.classList.remove("inactive");
    container.classList.remove("active");

    controls.style.display = "none";
  })

  function cleanContainer() {
    while(container.firstChild) {
      container.removeChild(container.lastChild);
    }
  }
}

function template(width, height) {
  return `
<cropper-canvas style="height: ${height}px; width: ${width}px;">
  <cropper-image slottable></cropper-image>
  <cropper-handle action="move" plain></cropper-handle>
</cropper-canvas>
  `
}
