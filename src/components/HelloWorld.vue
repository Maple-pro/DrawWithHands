<template>
  <div class="hello">
    <div class="container">
      <video class="input_video"></video>
      <div class="canvas-container">
        <canvas class="output_canvas" width="1280px" height="720px" />
        <canvas class="permanent_canvas" width="1280px" height="720px" />
      </div>

      <div class="loading">
        <div class="spinner"></div>
        <div class="message">
          Loading
        </div>
      </div>
    </div>
    <div class="control-panel" />
    <div class="control-btns">
      <form>
        <input type="radio" v-model="showHands" value="show">显示手掌
        <input type="radio" v-model="showHands" value="noshow">不显示手掌
      </form>
      <button v-on:click="help" class="control-btn">Help</button>
      <button v-on:click="clearImage" class="clear-btn control-btn">Clear</button>
      <button v-on:click="exportImage" class="export-btn control-btn">Export</button>
      <div class="notice-text">
        Press Ctrl to draw.
      </div>
    </div>
  </div>
</template>

<script>
import DeviceDetector from 'device-detector-js';
// import { FPS, ControlPanel, controlsElement } from '@mediapipe/control_utils';
import * as ControlUtils from '@mediapipe/control_utils';
import * as DrawingUtils from '@mediapipe/drawing_utils';
import * as CameraUtils from '@mediapipe/camera_utils';
import * as HandsUtils from '@mediapipe/hands';
import download from 'downloadjs';

export default {
  name: 'HelloWorld',
  data () {
    return {
      fpsControl: new ControlUtils.FPS(),
      videoElement: null,
      canvasElement: null,
      permanentCanvasElement: null,
      controlsElement: null,
      canvasCtx: null,
      permanentCtx: null,
      lines: [],
      isCtrlPressed: false,

      // control-btns
      showHands: 'show',
    }
  },
  methods: {
    testSupport(supportedDevices) {
      const deviceDetector = new DeviceDetector();
      const detectedDevice = deviceDetector.parse(navigator.userAgent);
      let isSupported = false;
      for (const device of supportedDevices) {
        if (device.client !== undefined) {
          const re = new RegExp(`^${device.client}$`);
          if (!re.test(detectedDevice.client.name)) {
            continue;
          }
        }
        if (device.os !== undefined) {
          const re = new RegExp(`^${device.os}$`);
          if (!re.test(detectedDevice.os.name)) {
            continue;
          }
        }
        isSupported = true;
        break;
      }
      if (!isSupported) {
        alert(`This demo, running on ${detectedDevice.client.name}/${detectedDevice.os.name}, ` +
          `is not well supported at this time, continue at your own risk.`);
      }
    },
    onResults(results) {
      // 判断这一帧是否与上一帧所画的为连续的，如果不是，则新增line
      let flag = false;

      // Hide the spinner.
      document.body.classList.add('loaded');
      // Update the frame rate.
      this.fpsControl.tick();
      // Draw the overlays.
      this.canvasCtx.save();
      this.canvasCtx.clearRect(0, 0, this.canvasElement.width, this.canvasElement.height);
      this.canvasCtx.drawImage(results.image, 0, 0, this.canvasElement.width, this.canvasElement.height);
      if (this.permanentCanvasElement.width !== this.canvasElement.width) {
        this.permanentCanvasElement.width = this.canvasElement.width;
        this.permanentCanvasElement.height = this.canvasElement.height;
        this.drawPath();
      }

      if (results.multiHandLandmarks && results.multiHandedness) {
        for (let index = 0; index < results.multiHandLandmarks.length; index++) {
          const classification = results.multiHandedness[index];
          const isRightHand = classification.label === 'Right';
          const landmarks = results.multiHandLandmarks[index];

          // Draw hands
          if (this.showHands === 'show') {
            DrawingUtils.drawConnectors(this.canvasCtx, landmarks, HandsUtils.HAND_CONNECTIONS, {
              color: isRightHand ?  '#00FF00' : '#FF0000'
            });
            DrawingUtils.drawLandmarks(this.canvasCtx, landmarks, {
              color: isRightHand ? '#00FF00' : '#FF0000',
              fillColor: isRightHand ? '#FF0000' : '#00FF00',
              radius: (x) => {
                return DrawingUtils.lerp(x.from.z, -0.15, .1, 10, 1);
              }
            });
          }
          

          // 绘制右手 8 号点路径
          if (isRightHand && this.isCtrlPressed) {
            // 与上一帧为同一条线
            flag = true;

            if (!this.lines.length) {
              this.lines.push([]);
            }
            const eightLandmark = results.multiHandLandmarks[index][8];
            this.lines[this.lines.length - 1].push({
              x: eightLandmark.x,
              y: eightLandmark.y,
            });

            this.drawPath();
          }
        }
        
      }
      this.canvasCtx.restore();

      // 当前帧与上一帧所画的不为同一条线
      if (!flag && this.lines[this.lines.length - 1] && this.lines[this.lines.length - 1].length) {
        this.lines.push([]);
      }
    },
    drawPath() {
      const permanentCanvasWidth = this.permanentCanvasElement.width;
      const permanentCanvasHeight = this.permanentCanvasElement.height;
      const width = this.canvasElement.width;
      const height = this.canvasElement.height;

      this.permanentCtx.beginPath();
      this.permanentCtx.clearRect(0, 0, permanentCanvasWidth, permanentCanvasHeight);

      this.lines.forEach(line => {
        const points = line;
        if (points.length > 1) {
          points.forEach((point, i) => {
            i === 0 
              ? this.permanentCtx.moveTo(point.x * width, point.y * height)
              : this.permanentCtx.lineTo(point.x * width, point.y * height); 
          });
          this.permanentCtx.strokeStyle = "blue";
          this.permanentCtx.lineWidth = 5;
        }
      })
      this.permanentCtx.stroke();
      this.permanentCtx.closePath();
    },
    onkeydown(event) {
      const e = event || window.event || arguments.callee.caller.arguments[0];
      if (e) {
        this.isCtrlPressed = e.ctrlKey;
      }
    },
    onkeyup(event) {
      const e = event || window.event || arguments.callee.caller.arguments[0];
      if (e) {
        this.isCtrlPressed = e.ctrlKey;
      }
    },
    exportImage() {
      const MIME_TYPE = "image/png";
      const imgURL = this.permanentCanvasElement.toDataURL(MIME_TYPE);

      download(imgURL, `rawWithHands-${Date.now()}`, MIME_TYPE);
    },
    clearImage() {
      this.lines.length = 0;
      this.drawPath();
    },
    help() {
      this.$alert('<ol><li>在浏览器中输入 chrome://flags/#unsafely-treat-insecure-origin-as-secure</li><li>定位到的“Insecure origins treated as secure”区域的文本框中输入 http://maples31.com:3000</li><li>将右侧 Disabled 改为 Enabled</li><li>点击下方的 Relaunch</li><li>再次访问</li></ol>', '加载不出摄像头', {
        dangerouslyUseHTMLString: true
      });
    }
  },
  created: function() {
    document.onkeydown = this.onkeydown.bind(this);

    document.onkeyup = this.onkeyup.bind(this);
  },
  mounted: function() {
    this.testSupport([{ client: 'Chrome' }]);

    // Our input frames will come from here.
    this.videoElement = document.getElementsByClassName('input_video')[0];
    this.canvasElement = document.getElementsByClassName('output_canvas')[0];
    this.permanentCanvasElement = document.getElementsByClassName('permanent_canvas')[0];
    this.controlsElement = document.getElementsByClassName('control-panel')[0];
    if (this.canvasElement) {
      this.canvasCtx = this.canvasElement.getContext('2d');
    }
    if (this.permanentCanvasElement) {
      this.permanentCtx = this.permanentCanvasElement.getContext('2d');
    }

    // Optimization: Turn off animated spinner after its hiding animation is done.
    const spinner = document.querySelector('.loading');
    spinner.ontransitionend = () => {
      spinner.style.display = 'none';
    };

    const hands = new HandsUtils.Hands({
      locateFile: (file) => {
        return `https://cdn.jsdelivr.net/npm/@mediapipe/hands@0.4.1646424915/${file}`;
      }
    });
    hands.onResults(this.onResults);

    // Present a control panel through which the user can manipulate the solution
    // options.
    new ControlUtils.ControlPanel(this.controlsElement, {
      selfieMode: true,
      maxNumHands: 2,
      modelComplexity: 1,
      minDetectionConfidence: 0.5,
      minTrackingConfidence: 0.5
    })
    .add([
      new ControlUtils.StaticText({ title: 'Draw With Hands' }),
      this.fpsControl,
      new ControlUtils.Toggle({ title: 'Selfie Mode', field: 'selfieMode' }),
      new ControlUtils.SourcePicker({
        onSourceChanged: () => {
          hands.reset();
        },
        onFrame: async (input, size) => {
          const aspect = size.height / size.width;
          let width, height;
          if (window.innerWidth > window.innerHeight) {
            height = window.innerHeight;
            width = height / aspect;
          }
          else {
            width = window.innerWidth;
            height = width * aspect;
          }
          this.canvasElement.width = width;
          this.canvasElement.height = height;
          // if (this.permanentCanvasElement.width !== width) {
          //   this.permanentCanvasElement.width = width;
          //   this.permanentCanvasElement.height = height;
          // }
          await hands.send({ image: input });
        },
        examples: {
          videos: [],
          images: [],
        }
      }),
      new ControlUtils.Slider({
        title: 'Max Number of Hands',
        field: 'maxNumHands',
        range: [1, 4],
        step: 1
      }),
      new ControlUtils.Slider({
        title: 'Min Detection Confidence',
        field: 'minDetectionConfidence',
        range: [0, 1],
        step: 0.01
      }),
      new ControlUtils.Slider({
        title: 'Min Tracking Confidence',
        field: 'minTrackingConfidence',
        range: [0, 1],
        step: 0.01
      }),
    ])
    .on(x => {
      const options = x;
      this.videoElement.classList.toggle('selfie', options.selfieMode);
      hands.setOptions(options);
    });
  }
}
</script>

<style>
@keyframes spin {
  0% {
    transform: rotate(0deg);
  }
  100% {
    transform: rotate(360deg);
  }
}

.hello {
  bottom: 0;
  font-family: "Titillium Web", sans-serif;
  color: white;
  left: 0;
  margin: 0;
  position: absolute;
  right: 0;
  top: 0;
  transform-origin: 0px 0px;
  overflow: hidden;
}

.container {
  position: absolute;
  background-color: #596e73;
  width: 100%;
  max-height: 100%;
}

.input_video {
  display: none;
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
}
.input_video.selfie {
  transform: scale(-1, 1);
}

.input_image {
  position: absolute;
}

.canvas-container {
  /* display: flex; */
  height: 100vh;
  width: 100%;
  /* justify-content: center;
  align-items: center;
  position: relative; */
}

.output_canvas {
  max-width: 100%;
  display: block;
  position: absolute;
  left: 0;
  top: 0;
  right: 0;
  bottom: 0;
  margin: auto;
  /* border: thick solid red; */
  z-index: 1;
}

.permanent_canvas {
  max-width: 100%;
  display: block;
  position: absolute;
  left: 0;
  right: 0;
  top: 0;
  bottom: 0;
  margin: auto;
  /* border: thin solid #000000; */
  z-index: 2;
}

.control-panel {
  position: absolute;
  left: 10px;
  top: 10px;
}

.control-btns {
  position: absolute;
  right: 30px;
  top: 30px;
  display: flex;
  flex-direction: column;
  align-items: center;
}

.control-btns .control-btn {
  display: inline-block;
  width: 80%;
  height: 30px;
  margin-top: 20px;
  cursor: pointer;
  background: #fff;
  border: 1px solid #dcdfe6;
  color: #606266;
  box-sizing: border-box;
  font-weight: 500;
  font-size: 14px;
  border-radius: 4px;
}

.control-btns .notice-text {
  margin-top: 20px;
}

.loading {
  display: flex;
  position: absolute;
  top: 0;
  right: 0;
  bottom: 0;
  left: 0;
  align-items: center;
  backface-visibility: hidden;
  justify-content: center;
  opacity: 1;
  transition: opacity 1s;
}
.loading .message {
  font-size: x-large;
}
.loading .spinner {
  position: absolute;
  width: 120px;
  height: 120px;
  animation: spin 1s linear infinite;
  border: 32px solid #bebebe;
  border-top: 32px solid #3498db;
  border-radius: 50%;
}

.loaded .loading {
  opacity: 0;
}
</style>
