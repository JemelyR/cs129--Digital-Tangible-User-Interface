import processing.serial.*;
import ddf.minim.*;

Serial myPort;
String incomingData = "";

// Minim setup
Minim minim;
AudioInput input;
AudioRecorder recorder;
AudioPlayer[] sounds;
String audioFileName = "recorded_audio.wav";
boolean isRecording = false;
boolean isPlayingRecorded = false;
int lastFSRValue = 0;
float circleRadius = 20;
boolean pulseGrowing = true;

// NFC setup
boolean[] isPlaying;
String[] rfidTags = {
  "19.230.91.245",
  "147.106.52.250",
  "205.249.171.45",
  "63.163.20.2",
  "115.161.152.244",
  "115.113.99.250",
  "99.108.240.246",
  "147.217.57.250"
};

void setup() {
  size(600, 400);
  
  // initialize serial connection
  myPort = new Serial(this, "COM5", 115200);
  myPort.bufferUntil('\n');
  
  // initialize Minim
  minim = new Minim(this);
  input = minim.getLineIn(Minim.MONO, 1024);
  createNewRecorder();

  // initialize NFC sounds
  sounds = new AudioPlayer[rfidTags.length];
  isPlaying = new boolean[rfidTags.length];
  sounds[0] = minim.loadFile(audioFileName); // recorded sound net audio (initially empty)
  sounds[0].setGain(2);
  sounds[1] = minim.loadFile("sonido-de-lluvia-rain-sound-132614.mp3");
  sounds[2] = minim.loadFile("cheerful-chirping-of-birds_nature-sound-201697.mp3");
  sounds[3] = minim.loadFile("wolf-howl-6310.mp3");
  sounds[4] = minim.loadFile("wind-in-trees-117477.mp3");
  sounds[5] = minim.loadFile("owl-hooting-223549.mp3");
  sounds[6] = minim.loadFile("wind-chimes-60654.mp3");
  sounds[7] = minim.loadFile("chime_song_mellow_chill_short2-62649.mp3");
}

void draw() {
  background(200);

  // display recording status and FSR value
  textSize(24);
  textAlign(CENTER, CENTER);
  fill(0);
  text("FSR Value: " + lastFSRValue, width / 2, 50);

  if (isRecording) {
    // animate the recording indicator
    if (pulseGrowing) {
      circleRadius += 0.5;
      if (circleRadius >= 30) pulseGrowing = false;
    } else {
      circleRadius -= 0.5;
      if (circleRadius <= 20) pulseGrowing = true;
    }

    // draw red pulsing circle
    fill(255, 0, 0);
    noStroke();
    ellipse(width / 2, height / 2, circleRadius * 2, circleRadius * 2);

    fill(255);
    text("Recording...", width / 2, height - 50);
  } else {
    // draw static gray circle when not recording
    fill(100);
    noStroke();
    ellipse(width / 2, height / 2, 40, 40);

    fill(0);
    text("Not Recording", width / 2, height - 50);
  }
}

void serialEvent(Serial myPort) {
  try {
    String rawData = myPort.readStringUntil('\n');
    if (rawData != null) {
      rawData = trim(rawData);

      if (rawData.startsWith("FSR:")) {
        lastFSRValue = int(rawData.substring(4));
        handleFSRValue(lastFSRValue);
      }

      if (rawData.startsWith("TAG:")) {
        String tagId = rawData.substring(4);
        handleTag(tagId);
      }
    }
  } catch (Exception e) {
    println("Error reading serial data: " + e.getMessage());
  }
}

void handleFSRValue(int fsrValue) {
  boolean shouldRecord = (fsrValue <= 300);
  if (shouldRecord && !isRecording) {
    startRecording();
  } else if (!shouldRecord && isRecording) {
    stopRecording();
  }
}

void startRecording() {
  createNewRecorder(); // ensure a fresh recorder instance
  recorder.beginRecord();
  println("Recording started...");
  isRecording = true;
}

void stopRecording() {
  isRecording = false;
  recorder.endRecord();
  recorder.save();
  println("Recording stopped and saved as " + audioFileName);
  reloadRecordedAudio();
}

void handleTag(String tagId) {
  for (int i = 0; i < rfidTags.length; i++) {
    if (tagId.equals(rfidTags[i])) {
      if (i == 0) { // play recorded audio for tag 0
        if (!isPlayingRecorded) {
          sounds[0].rewind();
          sounds[0].loop();
          isPlayingRecorded = true;
        } else {
          sounds[0].pause();
          isPlayingRecorded = false;
        }
      } else if (!isPlaying[i]) {
        sounds[i].rewind();
        sounds[i].loop();
        isPlaying[i] = true;
      } else {
        sounds[i].pause();  // pause the sound if already playing
        isPlaying[i] = false;
      }
      break;
    }
  }
}

void createNewRecorder() {
  if (recorder != null && recorder.isRecording()) {
    recorder.endRecord();
  }
  recorder = minim.createRecorder(input, audioFileName, true);
}

void reloadRecordedAudio() {
  sounds[0].close(); // close current instance of the recorded audio
  sounds[0] = minim.loadFile(audioFileName); // reload the updated file
  sounds[0].setGain(6);
  if (isPlayingRecorded) {
    sounds[0].rewind();
    sounds[0].loop(); // ensure new recording loops if tag is still active
  }
}

void keyPressed() {
  if (key == 'p' || key == 'P') {
    if (!isPlayingRecorded) {
      sounds[0].rewind();
      sounds[0].loop(); // loop the recorded audio
      isPlayingRecorded = true;
    } else {
      sounds[0].pause();
      isPlayingRecorded = false;
    }
  }
}

void stop() {
  if (recorder.isRecording()) {
    recorder.endRecord();
    recorder.save();
    println("Recording stopped and saved as " + audioFileName);
  }
  minim.stop();
  super.stop();
}
