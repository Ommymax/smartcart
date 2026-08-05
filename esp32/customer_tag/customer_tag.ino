/*
 SMART SHOPPING CART - CUSTOMER TAG ESP32
 Broadcasts a small ESP-NOW packet so the cart can follow by RSSI.
*/

#include <WiFi.h>
#include <esp_now.h>
#include <esp_wifi.h>

#define STATUS_LED 2
#define TAG_BUTTON 0

#define TAG_ID 1001

// Must match the channel used by MAIN ESP32 and LEFT NODE.
const uint8_t WIFI_CHANNEL = 6;
const unsigned long SEND_INTERVAL_MS = 50;

uint8_t broadcastAddress[] = {0xff, 0xff, 0xff, 0xff, 0xff, 0xff};
uint32_t counter = 0;
unsigned long lastSendMs = 0;
bool ledState = false;

struct TagPacket {
  uint16_t tagID;
  uint32_t counter;
};

void onDataSent(const uint8_t*, esp_now_send_status_t status) {
  if (status == ESP_NOW_SEND_SUCCESS) {
    ledState = !ledState;
    digitalWrite(STATUS_LED, ledState);
  }
}

void setup() {
  Serial.begin(115200);
  pinMode(STATUS_LED, OUTPUT);
  pinMode(TAG_BUTTON, INPUT_PULLUP);

  WiFi.mode(WIFI_STA);
  WiFi.disconnect();
  esp_wifi_set_channel(WIFI_CHANNEL, WIFI_SECOND_CHAN_NONE);

  Serial.println();
  Serial.println("SMART CART CUSTOMER TAG STARTING...");
  Serial.print("TAG MAC: ");
  Serial.println(WiFi.macAddress());
  Serial.print("ESP-NOW channel: ");
  Serial.println(WIFI_CHANNEL);

  if (esp_now_init() != ESP_OK) {
    Serial.println("ESP-NOW init failed");
    while (true) delay(100);
  }

  esp_now_register_send_cb(onDataSent);

  esp_now_peer_info_t peerInfo = {};
  memcpy(peerInfo.peer_addr, broadcastAddress, 6);
  peerInfo.channel = WIFI_CHANNEL;
  peerInfo.encrypt = false;

  if (esp_now_add_peer(&peerInfo) != ESP_OK) {
    Serial.println("Failed to add broadcast peer");
    while (true) delay(100);
  }

  Serial.println("TAG READY");
}

void loop() {
  if (millis() - lastSendMs >= SEND_INTERVAL_MS) {
    lastSendMs = millis();

    TagPacket packet;
    packet.tagID = TAG_ID;
    packet.counter = counter++;

    esp_err_t result = esp_now_send(broadcastAddress, (uint8_t*)&packet, sizeof(packet));
    Serial.printf("tagSend=%s counter=%lu\n", result == ESP_OK ? "OK" : "FAILED", counter);
  }

  delay(5);
}
