#include <SoftwareSerial.h>
#include <PN532_SWHSU.h>
#include <PN532.h>

// NFC setup & handling
SoftwareSerial SWSerial(3, 2);
PN532_SWHSU pn532swhsu(SWSerial);
PN532 nfc(pn532swhsu);

String tagId = "None";
String lastTagId = "None";
byte nuidPICC[4];
unsigned long lastDetectedTime = 0;
unsigned long debounceDelay = 1000;

const int fsrPin = A0;
const int led = 11;
int fsrValue = 0;

void setup() {
  Serial.begin(9600);  
  Serial.println("Initializing...");

  // NFC setup
  nfc.begin();
  uint32_t versiondata = nfc.getFirmwareVersion();
  if (!versiondata) {
    while (1); // don't proceed if NFC module is not detected
  }
  nfc.SAMConfig();

  // FSR setup
  pinMode(led, OUTPUT);
  digitalWrite(led, HIGH);
}

void loop() {
  // continuous FSR reading and LED control
  fsrValue = analogRead(fsrPin);
  if (fsrValue <= 300) {
    digitalWrite(led, HIGH);
  } else {
    digitalWrite(led, LOW);
  }

  // send FSR value to Serial for processing
  Serial.print("FSR:");
  Serial.println(fsrValue);

  readNFC();

  // send NFC tag data to Serial for processing only when it changes
  if (tagId != lastTagId) {
    Serial.print("TAG:");
    Serial.println(tagId);
    lastTagId = tagId;
  }

  delay(50); // small delay to manage serial communication
}

void readNFC() {
  boolean success;
  // array of unpopulated IDs
  uint8_t uid[] = { 0, 0, 0, 0, 0, 0, 0 }; 
  uint8_t uidLength;      
  success = nfc.readPassiveTargetID(PN532_MIFARE_ISO14443A, &uid[0], &uidLength);

  if (success) {
    for (uint8_t i = 0; i < uidLength; i++) {
      nuidPICC[i] = uid[i];
    }
    String newTagId = tagToString(nuidPICC);
    if (newTagId != tagId && millis() - lastDetectedTime >= debounceDelay) {
      tagId = newTagId;
      lastDetectedTime = millis(); // update last detected time
    }
  } else {
    // reset to "None" if no tag has been detected for the debounce delay
    if (tagId != "None" && millis() - lastDetectedTime >= debounceDelay) {
      tagId = "None";
    }
  }
}

String tagToString(byte id[4]) {
  String tagId = "";
  for (byte i = 0; i < 4; i++) {
    if (i < 3) tagId += String(id[i]) + ".";
    else tagId += String(id[i]);
  }
  return tagId;
}
