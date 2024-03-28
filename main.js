const { app, BrowserWindow, ipcMain } = require('electron');
const path = require('path');
const { spawn } = require('child_process');

let mainWindow;
let swiftExecutable;

function createWindow() {
  mainWindow = new BrowserWindow({
    width: 800,
    height: 600,
    webPreferences: {
      nodeIntegration: true,
      contextIsolation: false,
    },
  });

  mainWindow.loadFile('index.html');
}

app.whenReady().then(() => {
  createWindow();
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') {
    app.quit();
  }
});

app.on('activate', () => {
  if (BrowserWindow.getAllWindows().length === 0) {
    createWindow();
  }
});

ipcMain.on('start-audio-capture', (event, outputFilePath) => {
  try {
    swiftExecutable = spawn('./AudioCapture', [outputFilePath], { stdio: ['inherit', 'pipe', 'inherit'] });
    console.log("Spawned process:", swiftExecutable);

    swiftExecutable.stdout.on('data', data => {
      console.log(`Swift executable output: ${data}`);
    });

    if (swiftExecutable.stderr) {
      swiftExecutable.stderr.on('data', data => {
        console.error(`Swift executable error: ${data}`);
      });
    } else {
      console.warn("stderr is null. Swift executable may not produce error output.");
    }

    swiftExecutable.on('close', code => {
      console.log(`Swift executable exited with code ${code}`);
      event.reply('audio-capture-finished');
    });

    swiftExecutable.on('error', error => {
      console.error(`Failed to start Swift executable: ${error}`);
    });
  } catch (error) {
    console.error(`Error starting audio capture: ${error}`);
  }
});



ipcMain.on('stop-audio-capture', () => {
  if (swiftExecutable) {
    swiftExecutable.kill();
  }
});