#include <Arduino.h>
#include <Wire.h>                 // Must include Wire library for I2C
#include "SparkFun_MMA8452Q.h"    // Click here to get the library: http://librarymanager/All#SparkFun_MMA8452Q
#include <stdio.h>
#include <STM32LowPower.h>
#include <rtc.h>

const PinMap PinMap_I2C_SDA[] = {
  {PB_7,  I2C1, STM_PIN_DATA(STM_MODE_AF_OD, GPIO_NOPULL, GPIO_AF4_I2C1)}, // RADIO_RF_CBT_HF
  {NC,    NP,   0}
};

const PinMap PinMap_I2C_SCL[] = {
  {PB_6,  I2C1, STM_PIN_DATA(STM_MODE_AF_OD, GPIO_NOPULL, GPIO_AF4_I2C1)}, // RADIO_RF_CRX_RX
  {NC,    NP,   0}
};

MMA8452Q accel;                   // create instance of the MMA8452 class
STM32RTC &rtc = STM32RTC::getInstance();

volatile bool transientDetected = false;  // ISR flag
unsigned long lastShakeTime = 0;
bool on = false;
unsigned long switchedOnT = -1;

void configureTransientDetection() {
  accel.standby();

  accel.writeRegister(TRANSIENT_CFG, 0b00010110); // X/Y axes, latch enabled
  accel.writeRegister(TRANSIENT_THS, 12);       // 127=8g, 0=0.063g
  accel.writeRegister(TRANSIENT_COUNT, 25);     // COUNT * 20ms 
  accel.writeRegister(CTRL_REG4, 0x20);           // Enable transient interrupt
  accel.writeRegister(CTRL_REG5, 0x20);           // Route to INT1

  accel.active();
}

void onTransientInterrupt() {
  transientDetected = true;
}

unsigned long rtcSeconds() {
  return (rtc.getHours() * 3600UL +
          rtc.getMinutes() * 60UL +
          rtc.getSeconds()) * 1000UL;
}

void setup() {
  pinMode(PB9, OUTPUT);
  Serial.begin(9600);

  Wire.setSDA(PB_7);
  Wire.setSCL(PB_6);
  Wire.begin();

  if (accel.begin(Wire, 0x1C) == false) {
    Serial.println("Not Connected. Please check connections and read the hookup guide.");
    while (1) {
      Serial.println("Not Connected...");
      digitalWriteFast(PB_9, 1);
      delay(1000);
      digitalWriteFast(PB_9, 0);
      delay(1000);
    }
  }
  configureTransientDetection();
  LowPower.attachInterruptWakeup(PA0, onTransientInterrupt, FALLING, SLEEP_MODE);

  rtc.setClockSource(STM32RTC::LSI_CLOCK); // or LSE_CLOCK if you have a crystal
  rtc.begin();           
  rtc.setHours(0);
  rtc.setMinutes(0);
  rtc.setSeconds(0);

  byte intSource = accel.readRegister(INT_SOURCE);
  byte src = accel.readRegister(TRANSIENT_SRC); // Clear the interrupt
  Serial.println("Setup complete.\n");
}

void loop() {
  LowPower.deepSleep();
  delay(20);

  if (transientDetected) { 
    Serial.println("Interrtupt\n");
    transientDetected = false;
    
    unsigned long now = rtcSeconds();
    byte intSource = accel.readRegister(INT_SOURCE);
    byte src = accel.readRegister(TRANSIENT_SRC); // Clear the interrupt

    if (now == lastShakeTime && now != switchedOnT) {
      switchedOnT = now;
      Serial.println("LED!\n");
      on = !on;
      if (on) {
        digitalWriteFast(PB_9, 1);
      }
      else {
        digitalWriteFast(PB_9, 0);
      }
    }

    lastShakeTime = now;
  }
}