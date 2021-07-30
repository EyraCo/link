// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import "../css/app.css";

import "alpine-magic-helpers/dist/component";
import Alpine from "alpinejs";
import { decode } from "blurhash";


window.blurHash = () => {
  return {
    show: true,
    showBlurHash() {
      return this.show !== false;
    },
    hideBlurHash() {
      this.show = false;
    },
    render() {
      const canvas = this.$el.getElementsByTagName("canvas")[0];
      if (canvas.dataset.rendered) {
        return;
      }
      const blurhash = canvas.dataset.blurhash;
      const width = parseInt(canvas.getAttribute("width"), 10);
      const height = parseInt(canvas.getAttribute("height"), 10);
      const pixels = decode(blurhash, width, height);
      const ctx = canvas.getContext("2d");
      const imageData = ctx.createImageData(width, height);
      imageData.data.set(pixels);
      ctx.putImageData(imageData, 0, 0);
      canvas.dataset.rendered = true;
    },
  };
};
