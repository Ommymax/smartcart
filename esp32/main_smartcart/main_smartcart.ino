/*
 SMART SHOPPING CART - RIGHT / MAIN ESP32
 ESP-NOW + UART + L298N + 3 ultrasonic + GPS + Render telemetry
 Arduino-ESP32 Core 3.3.x

 Required Arduino library:
 - TinyGPSPlus
*/

#include <WiFi.h>
#include <esp_now.h>
#include <HTTPClient.h>
#include <WiFiClientSecure.h>
#include <TinyGPSPlus.h>

#define RED_LED 2
#define GREEN_LED 4
#define FRONT_ECHO 12
#define FRONT_TRIG 13
#define LEFT_TRIG 14
#define UART_RX 16
#define UART_TX 17
#define IN1 18
#define IN2 19
#define IN3 21
#define IN4 22
#define GPS_TX 23
#define RIGHT_ECHO 25
#define RIGHT_TRIG 26
#define LEFT_ECHO 27
#define ENA 32
#define ENB 33
#define GPS_RX 34
#define BATTERY_ADC_PIN 35

// ESP32 supports 2.4GHz Wi-Fi only. Do not use a 5GHz SSID.
const char* WIFI_SSID = "YOUR_2_4GHZ_WIFI_NAME";
const char* WIFI_PASSWORD = "YOUR_WIFI_PASSWORD";

#define EXPECTED_TAG_ID 1001
#define CART_ID "SMART_CART_001"

const char* RENDER_URL = "https://smartcart-backend-bgt4.onrender.com/api/cart/telemetry";
const char* COMMAND_URL = "https://smartcart-backend-bgt4.onrender.com/api/carts/" CART_ID "/command/latest";
const char* API_TOKEN = "YOUR_RENDER_ESP32_API_TOKEN";

const unsigned long TAG_TIMEOUT_MS = 300;
const unsigned long LEFT_TIMEOUT_MS = 400;
const unsigned long STATUS_INTERVAL_MS = 500;
const unsigned long TELEMETRY_INTERVAL_MS = 5000;
const unsigned long COMMAND_POLL_INTERVAL_MS = 350;
const unsigned long BLINK_INTERVAL_MS = 250;
const unsigned long ECHO_TIMEOUT_US = 9000;
const unsigned long GPS_STALE_MS = 10000;

const int FRONT_STOP_CM = 25;
const int SIDE_STOP_CM = 15;
const int FRONT_SLOW_CM = 45;
const int SIDE_SLOW_CM = 25;

const int RSSI_STOP = -43;
const int RSSI_CRAWL = -50;
const int RSSI_SLOW = -58;
const int RSSI_MEDIUM = -68;
const int DIRECTION_DEAD_ZONE = 4;

const int SPEED_CRAWL = 50;
const int SPEED_SLOW = 70;
const int SPEED_MEDIUM = 90;
const int SPEED_NORMAL = 110;
const int TURN_INNER_SPEED = 35;
const int TURN_OUTER_SPEED = 80;

const float DIVIDER_R1 = 100000.0f;
const float DIVIDER_R2 = 27000.0f;
const float BATTERY_FULL_V = 12.60f;
const float BATTERY_EMPTY_V = 9.60f;
const float BATTERY_CALIBRATION = 1.00f;

struct TagPacket {
  uint16_t tagID;
  uint32_t counter;
};

TinyGPSPlus gps;
HardwareSerial GPS_SERIAL(1);

volatile int rawRightRSSI = -100;
volatile uint32_t packetCounter = 0;
volatile unsigned long lastRightPacketMs = 0;
volatile bool rightEverReceived = false;

int rawLeftRSSI = -100;
bool leftNodeReportedConnected = false;
unsigned long lastLeftDataMs = 0;
String uartBuffer;

float filteredLeftRSSI = -100.0f;
float filteredRightRSSI = -100.0f;

long frontDistance = 999;
long leftDistance = 999;
long rightDistance = 999;

bool frontSensorActive = false;
bool leftSensorActive = false;
bool rightSensorActive = false;
bool tagConnected = false;
bool leftConnected = false;
bool radioConnected = false;

bool gpsAvailable = false;
double gpsLatitude = 0.0;
double gpsLongitude = 0.0;
unsigned long lastGpsUpdateMs = 0;

unsigned long lastBlinkMs = 0;
unsigned long lastStatusMs = 0;
bool greenState = false;

String movement = "stopped";
String stopReason = "startup";
String remoteCommand = "none";
bool manualControl = false;
int remoteSpeed = SPEED_MEDIUM;
unsigned long remoteCommandUntilMs = 0;

portMUX_TYPE mux = portMUX_INITIALIZER_UNLOCKED;

void onDataReceived(const esp_now_recv_info_t* info, const uint8_t* data, int len) {
  if (len != sizeof(TagPacket)) return;

  TagPacket p;
  memcpy(&p, data, sizeof(p));
  if (p.tagID != EXPECTED_TAG_ID) return;

  rawRightRSSI = (info && info->rx_ctrl) ? info->rx_ctrl->rssi : -100;
  packetCounter = p.counter;
  lastRightPacketMs = millis();
  rightEverReceived = true;
}

float smoothRSSI(float oldValue, int newValue) {
  const float alpha = 0.35f;
  if (oldValue <= -99.0f) return newValue;
  return alpha * newValue + (1.0f - alpha) * oldValue;
}

void setMovement(const String& value, const String& reason = "") {
  portENTER_CRITICAL(&mux);
  movement = value;
  if (reason.length()) stopReason = reason;
  portEXIT_CRITICAL(&mux);
}

String extractJsonString(const String& json, const String& key, const String& fallback) {
  String marker = "\"" + key + "\":\"";
  int start = json.indexOf(marker);
  if (start < 0) return fallback;
  start += marker.length();
  int end = json.indexOf("\"", start);
  if (end < 0) return fallback;
  return json.substring(start, end);
}

int extractJsonInt(const String& json, const String& key, int fallback) {
  String marker = "\"" + key + "\":";
  int start = json.indexOf(marker);
  if (start < 0) return fallback;
  start += marker.length();
  while (start < json.length() && json[start] == ' ') start++;
  int end = start;
  while (end < json.length() && (isDigit(json[end]) || json[end] == '-')) end++;
  if (end <= start) return fallback;
  return json.substring(start, end).toInt();
}

void readGPS() {
  while (GPS_SERIAL.available()) {
    gps.encode(GPS_SERIAL.read());
  }

  if (gps.location.isValid() && gps.location.age() < 5000) {
    gpsAvailable = true;
    gpsLatitude = gps.location.lat();
    gpsLongitude = gps.location.lng();
    lastGpsUpdateMs = millis();
  } else if (millis() - lastGpsUpdateMs > GPS_STALE_MS) {
    gpsAvailable = false;
  }
}

void readLeftUART() {
  while (Serial2.available()) {
    char c = Serial2.read();

    if (c == '\n') {
      uartBuffer.trim();

      if (uartBuffer.startsWith("L:")) {
        int comma = uartBuffer.indexOf(',');

        if (comma > 2) {
          int rssi = uartBuffer.substring(2, comma).toInt();
          int connected = uartBuffer.substring(comma + 1).toInt();

          if (rssi >= -120 && rssi <= 0) {
            rawLeftRSSI = rssi;
            leftNodeReportedConnected = (connected == 1);
            lastLeftDataMs = millis();

            if (leftNodeReportedConnected) {
              filteredLeftRSSI = smoothRSSI(filteredLeftRSSI, rawLeftRSSI);
            }
          }
        }
      }

      uartBuffer = "";
    } else if (c != '\r') {
      if (uartBuffer.length() < 40) uartBuffer += c;
      else uartBuffer = "";
    }
  }
}

long readDistanceCM(int trig, int echo, bool& active) {
  digitalWrite(trig, LOW);
  delayMicroseconds(2);
  digitalWrite(trig, HIGH);
  delayMicroseconds(10);
  digitalWrite(trig, LOW);

  unsigned long duration = pulseIn(echo, HIGH, ECHO_TIMEOUT_US);
  if (duration == 0) {
    active = false;
    return 999;
  }

  long distance = (long)(duration * 0.0343f / 2.0f);
  active = (distance >= 2 && distance <= 400);
  return active ? distance : 999;
}

void setMotorSpeed(int leftSpeed, int rightSpeed) {
  ledcWrite(ENA, constrain(leftSpeed, 0, 255));
  ledcWrite(ENB, constrain(rightSpeed, 0, 255));
}

void normalStop(const String& reason) {
  ledcWrite(ENA, 0);
  ledcWrite(ENB, 0);
  digitalWrite(IN1, LOW);
  digitalWrite(IN2, LOW);
  digitalWrite(IN3, LOW);
  digitalWrite(IN4, LOW);
  setMovement("stopped", reason);
}

void emergencyStop(const String& reason) {
  digitalWrite(IN1, HIGH);
  digitalWrite(IN2, HIGH);
  digitalWrite(IN3, HIGH);
  digitalWrite(IN4, HIGH);
  ledcWrite(ENA, 255);
  ledcWrite(ENB, 255);
  setMovement("emergency_stop", reason);
}

void moveForward(int speedValue) {
  digitalWrite(IN1, HIGH);
  digitalWrite(IN2, LOW);
  digitalWrite(IN3, HIGH);
  digitalWrite(IN4, LOW);
  setMotorSpeed(speedValue, speedValue);
  setMovement("moving_forward");
}

void turnLeft(int speedValue) {
  digitalWrite(IN1, HIGH);
  digitalWrite(IN2, LOW);
  digitalWrite(IN3, HIGH);
  digitalWrite(IN4, LOW);
  setMotorSpeed(min(TURN_INNER_SPEED, speedValue), min(TURN_OUTER_SPEED, speedValue));
  setMovement("turning_left");
}

void turnRight(int speedValue) {
  digitalWrite(IN1, HIGH);
  digitalWrite(IN2, LOW);
  digitalWrite(IN3, HIGH);
  digitalWrite(IN4, LOW);
  setMotorSpeed(min(TURN_OUTER_SPEED, speedValue), min(TURN_INNER_SPEED, speedValue));
  setMovement("turning_right");
}

void updateConnections() {
  unsigned long now = millis();
  tagConnected = rightEverReceived && (now - lastRightPacketMs <= TAG_TIMEOUT_MS);
  leftConnected = leftNodeReportedConnected && (now - lastLeftDataMs <= LEFT_TIMEOUT_MS);
  radioConnected = tagConnected && leftConnected;

  if (tagConnected) filteredRightRSSI = smoothRSSI(filteredRightRSSI, rawRightRSSI);
  else filteredRightRSSI = -100;

  if (!leftConnected) filteredLeftRSSI = -100;
}

void updateGreenLED() {
  if (radioConnected) {
    digitalWrite(GREEN_LED, HIGH);
    return;
  }

  if (millis() - lastBlinkMs >= BLINK_INTERVAL_MS) {
    lastBlinkMs = millis();
    greenState = !greenState;
    digitalWrite(GREEN_LED, greenState);
  }
}

int speedFromRSSI(int averageRSSI) {
  if (averageRSSI >= RSSI_STOP) return 0;
  if (averageRSSI >= RSSI_CRAWL) return SPEED_CRAWL;
  if (averageRSSI >= RSSI_SLOW) return SPEED_SLOW;
  if (averageRSSI >= RSSI_MEDIUM) return SPEED_MEDIUM;
  return SPEED_NORMAL;
}

int limitSpeedForObstacle(int requested) {
  int result = requested;
  if (frontDistance < FRONT_SLOW_CM) result = min(result, SPEED_CRAWL);
  if (leftDistance < SIDE_SLOW_CM || rightDistance < SIDE_SLOW_CM) result = min(result, SPEED_SLOW);
  return result;
}

bool handleObstacleSafety() {
  if (!frontSensorActive) {
    emergencyStop("front_sensor_inactive");
    return true;
  }

  if (frontDistance < FRONT_STOP_CM) {
    emergencyStop("front_obstacle");
    return true;
  }

  if (leftSensorActive && rightSensorActive && leftDistance < SIDE_STOP_CM && rightDistance < SIDE_STOP_CM) {
    emergencyStop("both_sides_blocked");
    return true;
  }

  if (leftSensorActive && leftDistance < SIDE_STOP_CM) {
    if (rightSensorActive && rightDistance > SIDE_SLOW_CM) turnRight(SPEED_CRAWL);
    else emergencyStop("left_obstacle");
    return true;
  }

  if (rightSensorActive && rightDistance < SIDE_STOP_CM) {
    if (leftSensorActive && leftDistance > SIDE_SLOW_CM) turnLeft(SPEED_CRAWL);
    else emergencyStop("right_obstacle");
    return true;
  }

  return false;
}

void followCustomer() {
  if (!radioConnected) {
    normalStop("radio_not_connected");
    return;
  }

  int leftRSSI = round(filteredLeftRSSI);
  int rightRSSI = round(filteredRightRSSI);
  int averageRSSI = (leftRSSI + rightRSSI) / 2;

  if (averageRSSI >= RSSI_STOP) {
    emergencyStop("customer_too_close");
    return;
  }

  int speedValue = limitSpeedForObstacle(speedFromRSSI(averageRSSI));
  int difference = leftRSSI - rightRSSI;

  if (abs(difference) <= DIRECTION_DEAD_ZONE) {
    moveForward(speedValue);
  } else if (difference > DIRECTION_DEAD_ZONE) {
    if (leftSensorActive && leftDistance > SIDE_STOP_CM) turnLeft(speedValue);
    else normalStop("left_path_unsafe");
  } else {
    if (rightSensorActive && rightDistance > SIDE_STOP_CM) turnRight(speedValue);
    else normalStop("right_path_unsafe");
  }
}

void setRemoteCommand(const String& command, int speedValue, int durationMs) {
  portENTER_CRITICAL(&mux);
  remoteCommand = command;
  remoteSpeed = constrain(speedValue, 0, 255);
  remoteCommandUntilMs = millis() + durationMs;

  if (command == "auto") {
    manualControl = false;
    stopReason = "auto_follow";
  } else {
    manualControl = true;
    stopReason = "app_remote";
  }
  portEXIT_CRITICAL(&mux);

  Serial.printf("Remote command=%s speed=%d duration=%dms\n", command.c_str(), remoteSpeed, durationMs);
}

void handleManualControl() {
  if (!manualControl) return;

  if (millis() > remoteCommandUntilMs) {
    normalStop("remote_timeout");
    return;
  }

  int speedValue = constrain(remoteSpeed, SPEED_CRAWL, SPEED_NORMAL);

  if (remoteCommand == "forward") {
    if (!frontSensorActive || frontDistance < FRONT_STOP_CM) emergencyStop("front_obstacle_remote");
    else moveForward(limitSpeedForObstacle(speedValue));
  } else if (remoteCommand == "left") {
    if (leftSensorActive && leftDistance <= SIDE_STOP_CM) normalStop("left_path_unsafe_remote");
    else turnLeft(speedValue);
  } else if (remoteCommand == "right") {
    if (rightSensorActive && rightDistance <= SIDE_STOP_CM) normalStop("right_path_unsafe_remote");
    else turnRight(speedValue);
  } else if (remoteCommand == "stop") {
    normalStop("app_stop");
  } else if (remoteCommand == "emergency_stop") {
    emergencyStop("app_emergency_stop");
  } else if (remoteCommand == "auto") {
    manualControl = false;
  } else {
    normalStop("manual_idle");
  }
}

float readBatteryVoltage() {
  uint32_t totalMv = 0;
  for (int i = 0; i < 16; i++) totalMv += analogReadMilliVolts(BATTERY_ADC_PIN);

  float pinVoltage = (totalMv / 16.0f) / 1000.0f;
  float divider = (DIVIDER_R1 + DIVIDER_R2) / DIVIDER_R2;
  return pinVoltage * divider * BATTERY_CALIBRATION;
}

int batteryPercentage(float voltage) {
  float p = (voltage - BATTERY_EMPTY_V) * 100.0f / (BATTERY_FULL_V - BATTERY_EMPTY_V);
  return constrain((int)round(p), 0, 100);
}

String buildJson() {
  float batteryVoltage = readBatteryVoltage();
  int batteryPct = batteryPercentage(batteryVoltage);

  String json = "{";
  json += "\"cartId\":\"" CART_ID "\",";
  json += "\"powerStatus\":\"on\",";
  json += "\"motionStatus\":\"" + movement + "\",";
  json += "\"stopReason\":\"" + stopReason + "\",";
  json += "\"batteryVoltage\":" + String(batteryVoltage, 2) + ",";
  json += "\"batteryPercentage\":" + String(batteryPct) + ",";
  json += "\"radioConnected\":" + String(radioConnected ? "true" : "false") + ",";
  json += "\"internetConnected\":" + String(WiFi.status() == WL_CONNECTED ? "true" : "false") + ",";
  json += "\"ultrasonic\":{";
  json += "\"front\":{\"active\":" + String(frontSensorActive ? "true" : "false") + ",\"distanceCm\":" + String(frontDistance) + "},";
  json += "\"left\":{\"active\":" + String(leftSensorActive ? "true" : "false") + ",\"distanceCm\":" + String(leftDistance) + "},";
  json += "\"right\":{\"active\":" + String(rightSensorActive ? "true" : "false") + ",\"distanceCm\":" + String(rightDistance) + "}";
  json += "},";
  json += "\"rssi\":{\"left\":" + String(filteredLeftRSSI, 1) + ",\"right\":" + String(filteredRightRSSI, 1) + "},";
  json += "\"location\":{";
  json += "\"available\":" + String(gpsAvailable ? "true" : "false") + ",";
  json += "\"source\":\"gps\",";
  json += "\"latitude\":" + String(gpsAvailable ? String(gpsLatitude, 6) : "null") + ",";
  json += "\"longitude\":" + String(gpsAvailable ? String(gpsLongitude, 6) : "null");
  json += "},";
  json += "\"uptimeMs\":" + String(millis());
  json += "}";
  return json;
}

void connectWiFi() {
  if (WiFi.status() == WL_CONNECTED) return;

  Serial.println("Connecting to Wi-Fi...");
  Serial.print("SSID: ");
  Serial.println(WIFI_SSID);

  WiFi.disconnect(false);
  WiFi.mode(WIFI_STA);
  WiFi.setSleep(false);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

  unsigned long start = millis();
  while (WiFi.status() != WL_CONNECTED && millis() - start < 12000) {
    delay(250);
    Serial.print(".");
  }
  Serial.println();

  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("Wi-Fi CONNECTED");
    Serial.print("IP Address: ");
    Serial.println(WiFi.localIP());
    Serial.print("Wi-Fi Channel: ");
    Serial.println(WiFi.channel());
  } else {
    Serial.print("Wi-Fi FAILED. Status code: ");
    Serial.println(WiFi.status());
    Serial.println("Use 2.4GHz Wi-Fi, correct password, and keep router/hotspot near the ESP32.");
  }
}

void postTelemetry() {
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("Telemetry skipped: Wi-Fi offline");
    return;
  }

  WiFiClientSecure client;
  client.setInsecure();

  HTTPClient http;
  http.setTimeout(8000);

  if (!http.begin(client, RENDER_URL)) {
    Serial.println("HTTP begin failed");
    return;
  }

  http.addHeader("Content-Type", "application/json");
  http.addHeader("X-API-Token", API_TOKEN);

  String payload = buildJson();
  Serial.println("Posting telemetry...");
  Serial.println(payload);

  int code = http.POST(payload);
  Serial.print("Telemetry HTTP=");
  Serial.println(code);

  if (code > 0) {
    Serial.print("Server response: ");
    Serial.println(http.getString());
  } else {
    Serial.print("HTTP error: ");
    Serial.println(http.errorToString(code));
  }

  http.end();
}

void pollRemoteCommand() {
  if (WiFi.status() != WL_CONNECTED) return;

  WiFiClientSecure client;
  client.setInsecure();

  HTTPClient http;
  http.setTimeout(3000);

  if (!http.begin(client, COMMAND_URL)) {
    Serial.println("Command HTTP begin failed");
    return;
  }

  http.addHeader("X-API-Token", API_TOKEN);

  int code = http.GET();
  if (code != 200) {
    Serial.print("Command HTTP=");
    Serial.println(code);
    http.end();
    return;
  }

  String response = http.getString();
  http.end();

  String command = extractJsonString(response, "command", "none");
  if (command == "none") return;

  int speedValue = extractJsonInt(response, "speed", SPEED_MEDIUM);
  int durationMs = extractJsonInt(response, "durationMs", 700);
  setRemoteCommand(command, speedValue, durationMs);
}

void telemetryTask(void*) {
  unsigned long lastPost = 0;

  for (;;) {
    if (WiFi.status() != WL_CONNECTED) connectWiFi();

    if (millis() - lastPost >= TELEMETRY_INTERVAL_MS) {
      lastPost = millis();
      postTelemetry();
    }

    vTaskDelay(pdMS_TO_TICKS(200));
  }
}

void commandTask(void*) {
  unsigned long lastPoll = 0;

  for (;;) {
    if (WiFi.status() == WL_CONNECTED && millis() - lastPoll >= COMMAND_POLL_INTERVAL_MS) {
      lastPoll = millis();
      pollRemoteCommand();
    }

    vTaskDelay(pdMS_TO_TICKS(50));
  }
}

void printStatus() {
  if (millis() - lastStatusMs < STATUS_INTERVAL_MS) return;
  lastStatusMs = millis();

  String ip = WiFi.status() == WL_CONNECTED ? WiFi.localIP().toString() : "0.0.0.0";

  Serial.printf(
    "tag=%s leftNode=%s radio=%s leftRSSI=%.1f rightRSSI=%.1f "
    "front=%ld(%s) leftD=%ld(%s) rightD=%ld(%s) "
    "motion=%s reason=%s mode=%s cmd=%s wifi=%s ip=%s gps=%s lat=%.6f lng=%.6f packets=%lu\n",
    tagConnected ? "CONNECTED" : "NOT_CONNECTED",
    leftConnected ? "CONNECTED" : "NOT_CONNECTED",
    radioConnected ? "CONNECTED" : "SEARCHING",
    filteredLeftRSSI,
    filteredRightRSSI,
    frontDistance,
    frontSensorActive ? "ACTIVE" : "INACTIVE",
    leftDistance,
    leftSensorActive ? "ACTIVE" : "INACTIVE",
    rightDistance,
    rightSensorActive ? "ACTIVE" : "INACTIVE",
    movement.c_str(),
    stopReason.c_str(),
    manualControl ? "REMOTE" : "AUTO",
    remoteCommand.c_str(),
    WiFi.status() == WL_CONNECTED ? "ONLINE" : "OFFLINE",
    ip.c_str(),
    gpsAvailable ? "READY" : "WAITING",
    gpsLatitude,
    gpsLongitude,
    packetCounter
  );
}

void fatal(const char* msg) {
  Serial.println(msg);

  while (true) {
    emergencyStop("fatal_error");
    digitalWrite(GREEN_LED, !digitalRead(GREEN_LED));
    delay(100);
  }
}

void setup() {
  Serial.begin(115200);
  delay(1000);

  Serial.println();
  Serial.println("SMART CART MAIN ESP32 STARTING...");

  Serial2.begin(115200, SERIAL_8N1, UART_RX, UART_TX);
  GPS_SERIAL.begin(9600, SERIAL_8N1, GPS_RX, GPS_TX);

  pinMode(RED_LED, OUTPUT);
  pinMode(GREEN_LED, OUTPUT);
  pinMode(FRONT_TRIG, OUTPUT);
  pinMode(FRONT_ECHO, INPUT);
  pinMode(LEFT_TRIG, OUTPUT);
  pinMode(LEFT_ECHO, INPUT);
  pinMode(RIGHT_TRIG, OUTPUT);
  pinMode(RIGHT_ECHO, INPUT);
  pinMode(IN1, OUTPUT);
  pinMode(IN2, OUTPUT);
  pinMode(IN3, OUTPUT);
  pinMode(IN4, OUTPUT);
  pinMode(BATTERY_ADC_PIN, INPUT);

  analogReadResolution(12);
  analogSetPinAttenuation(BATTERY_ADC_PIN, ADC_11db);

  if (!ledcAttach(ENA, 1000, 8) || !ledcAttach(ENB, 1000, 8)) fatal("PWM setup failed");

  digitalWrite(RED_LED, HIGH);
  normalStop("startup");

  connectWiFi();

  Serial.print("MAIN MAC: ");
  Serial.println(WiFi.macAddress());
  Serial.print("Current Wi-Fi channel: ");
  Serial.println(WiFi.channel());

  if (esp_now_init() != ESP_OK) fatal("ESP-NOW init failed");
  if (esp_now_register_recv_cb(onDataReceived) != ESP_OK) fatal("ESP-NOW callback failed");

  xTaskCreatePinnedToCore(telemetryTask, "Telemetry", 10000, nullptr, 1, nullptr, 0);
  xTaskCreatePinnedToCore(commandTask, "Commands", 8000, nullptr, 1, nullptr, 0);

  Serial.println("MAIN READY");
}

void loop() {
  readGPS();
  readLeftUART();
  updateConnections();
  updateGreenLED();

  frontDistance = readDistanceCM(FRONT_TRIG, FRONT_ECHO, frontSensorActive);

  if (!frontSensorActive || frontDistance < FRONT_STOP_CM) {
    emergencyStop(!frontSensorActive ? "front_sensor_inactive" : "front_obstacle");
    printStatus();
    return;
  }

  leftDistance = readDistanceCM(LEFT_TRIG, LEFT_ECHO, leftSensorActive);
  rightDistance = readDistanceCM(RIGHT_TRIG, RIGHT_ECHO, rightSensorActive);

  if (handleObstacleSafety()) {
    printStatus();
    return;
  }

  if (manualControl) handleManualControl();
  else followCustomer();
  printStatus();
}
