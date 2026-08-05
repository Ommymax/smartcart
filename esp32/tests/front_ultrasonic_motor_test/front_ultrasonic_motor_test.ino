/*
  SmartCart front ultrasonic + motor driver test

  Use this sketch only for bench testing.
  It does not connect to Wi-Fi, Render, GPS, or ESP-NOW.

  Serial commands:
    m = run a short motor test
    s = stop motors
*/

#define FRONT_ECHO 12
#define FRONT_TRIG 13

#define IN1 18
#define IN2 19
#define IN3 21
#define IN4 22
#define ENA 32
#define ENB 33

const unsigned long ECHO_TIMEOUT_US = 30000;
const int SAFE_STOP_CM = 25;
const int TEST_SPEED = 90;

unsigned long lastReadMs = 0;

long readFrontDistanceCm(bool& active, unsigned long& echoUs) {
  digitalWrite(FRONT_TRIG, LOW);
  delayMicroseconds(2);
  digitalWrite(FRONT_TRIG, HIGH);
  delayMicroseconds(10);
  digitalWrite(FRONT_TRIG, LOW);

  echoUs = pulseIn(FRONT_ECHO, HIGH, ECHO_TIMEOUT_US);
  if (echoUs == 0) {
    active = false;
    return 999;
  }

  long distance = (long)(echoUs * 0.0343f / 2.0f);
  active = distance >= 2 && distance <= 400;
  return active ? distance : 999;
}

void setMotorSpeed(int leftSpeed, int rightSpeed) {
  ledcWrite(ENA, constrain(leftSpeed, 0, 255));
  ledcWrite(ENB, constrain(rightSpeed, 0, 255));
}

void stopMotors() {
  setMotorSpeed(0, 0);
  digitalWrite(IN1, LOW);
  digitalWrite(IN2, LOW);
  digitalWrite(IN3, LOW);
  digitalWrite(IN4, LOW);
}

void forward(int speedValue) {
  digitalWrite(IN1, HIGH);
  digitalWrite(IN2, LOW);
  digitalWrite(IN3, HIGH);
  digitalWrite(IN4, LOW);
  setMotorSpeed(speedValue, speedValue);
}

void reverse(int speedValue) {
  digitalWrite(IN1, LOW);
  digitalWrite(IN2, HIGH);
  digitalWrite(IN3, LOW);
  digitalWrite(IN4, HIGH);
  setMotorSpeed(speedValue, speedValue);
}

void runMotorTest() {
  bool active = false;
  unsigned long echoUs = 0;
  long distance = readFrontDistanceCm(active, echoUs);

  Serial.println();
  Serial.println("Motor test requested");
  Serial.printf("Front sensor: %ld cm / %lu us / %s\n", distance, echoUs, active ? "ACTIVE" : "INACTIVE");

  if (!active) {
    Serial.println("Motor test cancelled: front ultrasonic has no echo.");
    return;
  }

  if (distance < SAFE_STOP_CM) {
    Serial.println("Motor test cancelled: obstacle too close.");
    return;
  }

  Serial.println("Forward 2 seconds");
  forward(TEST_SPEED);
  delay(2000);
  stopMotors();
  delay(800);

  Serial.println("Reverse 2 seconds");
  reverse(TEST_SPEED);
  delay(2000);
  stopMotors();

  Serial.println("Motor test complete");
}

void setup() {
  Serial.begin(115200);
  delay(1000);

  pinMode(FRONT_TRIG, OUTPUT);
  pinMode(FRONT_ECHO, INPUT);

  pinMode(IN1, OUTPUT);
  pinMode(IN2, OUTPUT);
  pinMode(IN3, OUTPUT);
  pinMode(IN4, OUTPUT);

  if (!ledcAttach(ENA, 1000, 8) || !ledcAttach(ENB, 1000, 8)) {
    Serial.println("PWM setup failed. Check ESP32 Arduino core version.");
    while (true) delay(1000);
  }

  stopMotors();

  Serial.println();
  Serial.println("SmartCart front ultrasonic + motor test ready");
  Serial.println("Pins: FRONT_TRIG=13 FRONT_ECHO=12 IN1=18 IN2=19 IN3=21 IN4=22 ENA=32 ENB=33");
  Serial.println("Type m + Enter to run motor test. Type s + Enter to stop.");
}

void loop() {
  if (Serial.available()) {
    char command = Serial.read();
    if (command == 'm' || command == 'M') runMotorTest();
    if (command == 's' || command == 'S') {
      stopMotors();
      Serial.println("Motors stopped");
    }
  }

  if (millis() - lastReadMs >= 500) {
    lastReadMs = millis();
    bool active = false;
    unsigned long echoUs = 0;
    long distance = readFrontDistanceCm(active, echoUs);

    Serial.printf(
      "front=%ldcm echo=%luus status=%s\n",
      distance,
      echoUs,
      active ? "ACTIVE" : "INACTIVE"
    );
  }
}
