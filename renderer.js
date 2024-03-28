const { ipcRenderer } = require('electron');
const path = require('path');

const startCaptureBtn = document.getElementById('startCaptureBtn');
const stopCaptureBtn = document.getElementById('stopCaptureBtn');

startCaptureBtn.addEventListener('click', () => {
  const outputFilePath = path.join(__dirname, 'recorded_audio.wav');
  ipcRenderer.send('start-audio-capture', outputFilePath);
  startCaptureBtn.disabled = true;
  stopCaptureBtn.disabled = false;
});

stopCaptureBtn.addEventListener('click', () => {
  ipcRenderer.send('stop-audio-capture');
  startCaptureBtn.disabled = false;
  stopCaptureBtn.disabled = true;
});

ipcRenderer.on('audio-capture-finished', () => {
  console.log('Audio capture finished.');
  startCaptureBtn.disabled = false;
  stopCaptureBtn.disabled = true;
});