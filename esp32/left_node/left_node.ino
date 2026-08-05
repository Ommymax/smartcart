/*
 SMART CART LEFT ESP32 NODE
 Receives the customer tag by ESP-NOW and sends left-side signal to MAIN ESP32 by UART.

 Wiring:
 LEFT ESP32 GPIO17 TX2 -> MAIN ESP32 GPIO16 RX2
 LEFT ESP32 GND        -> MAIN ESP32 GND
*/

#include <WiFi.h>
#include <esp_now.h>
#include <esp_wifi.h>

#define RED_LED 2
#define GREEN_LED 4
#define UART_RX 16
#define UART_TX 17

#define EXPECTED_TAG_ID 1001
#define FALLBACK_WIFI_CHANNEL 1

const char* MAIN_WIFI_SSID = "YOUR_MAIN_CART_WIFI_NAME";

const unsigned long TAG_TIMEOUT_MS = 350;
const unsigned long UART_INTERVAL_MS = 50;
const unsigned long CHANNEL_CHECK_INTERVAL_MS = 10000;
const unsigned long MAIN_UART_BAUD = 115200;

struct __attribute__((packed)) TagPacket {
  uint16_t tagID;
  uint32_t counter;
};

volatile int latestRSSI = -100;
volatile uint32_t latestCounter = 0;
volatile unsigned long lastPacketMs = 0;
volatile bool everReceived = false;

unsigned long lastUartMs = 0;
unsigned long lastChannelCheckMs = 0;
bool greenState = false;
uint8_t radioChannel = FALLBACK_WIFI_CHANNEL;

uint8_t findMainChannel() {
  int count = WiFi.scanNetworks(false, true);
  for (int i = 0; i < count; i++) {
    if (WiFi.SSID(i) == MAIN_WIFI_SSID) {
      uint8_t channel = WiFi.channel(i);
      WiFi.scanDelete();
      return channel;
    }
  }
  WiFi.scanDelete();
  return FALLBACK_WIFI_CHANNEL;
}

void applyRadioChannel(uint8_t channel) {
  if (channel < 1 || channel > 13) return;
  esp_wifi_set_channel(channel, WIFI_SECOND_CHAN_NONE);
  radioChannel = channel;
}

void onDataReceived(const esp_now_recv_info_t* info, const uint8_t* data, int len) {
  if (len != (int)sizeof(TagPacket)) return;

  TagPacket packet;
  memcpy(&packet, data, sizeof(packet));
  if (packet.tagID != EXPECTED_TAG_ID) return;

  latestRSSI = (info && info->rx_ctrl) ? info->rx_ctrl->rssi : -100;
  latestCounter = packet.counter;
  lastPacketMs = millis();
  everReceived = true;
}

void fatal(const char* message) {
  Serial.print("E:");
  Serial.println(message);
  while (true) {
    digitalWrite(GREEN_LED, !digitalRead(GREEN_LED));
    delay(100);
  }
}

void setup() {
  Serial.begin(115200);
  Serial2.begin(MAIN_UART_BAUD, SERIAL_8N1, UART_RX, UART_TX);

  pinMode(RED_LED, OUTPUT);
  pinMode(GREEN_LED, OUTPUT);
  digitalWrite(RED_LED, HIGH);

  WiFi.persistent(false);
  WiFi.mode(WIFI_STA);
  WiFi.setSleep(false);
  WiFi.disconnect(false, true);
  delay(100);

  radioChannel = findMainChannel();
  applyRadioChannel(radioChannel);

  Serial.println();
  Serial.println("SMART CART LEFT ESP32 STARTING...");
  Serial.print("LEFT MAC: ");
  Serial.println(WiFi.macAddress());
  Serial.print("ESP-NOW channel: ");
  Serial.println(radioChannel);

  if (esp_now_init() != ESP_OK) fatal("ESP-NOW init failed");
  if (esp_now_register_recv_cb(onDataReceived) != ESP_OK) fatal("ESP-NOW callback failed");

  Serial.println("LEFT ESP32 READY");
}

void loop() {
  unsigned long now = millis();
  bool connected = everReceived && now - lastPacketMs <= TAG_TIMEOUT_MS;

  if (!connected && now - lastChannelCheckMs >= CHANNEL_CHECK_INTERVAL_MS) {
    lastChannelCheckMs = now;
    uint8_t detectedChannel = findMainChannel();
    applyRadioChannel(detectedChannel);
  }

  if (now - lastUartMs >= UART_INTERVAL_MS) {
    lastUartMs = now;
    int rssi = connected ? constrain(latestRSSI, -110, -1) : -100;
    Serial2.printf("L:%d,%d\n", rssi, connected ? 1 : 0);
    Serial.printf("leftTag=%s rssi=%d packets=%lu channel=%u\n",
                  connected ? "CONNECTED" : "NOT_CONNECTED",
                  rssi,
                  (unsigned long)latestCounter,
                  radioChannel);
  }

  if (connected) {
    digitalWrite(GREEN_LED, HIGH);
    delay(10);
  } else {
    greenState = !greenState;
    digitalWrite(GREEN_LED, greenState);
    delay(50);
  }
}
