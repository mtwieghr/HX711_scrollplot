


/**
 ******************************************************************************
 * File Name          : LDC1614_example
 * Description        : Example program for LDC16xx_lib
 ******************************************************************************
 * 
 * Copyright (c) 2018 CNR-STIIMA DASM Group
 * All rights reserved. 
 * 
 * Redistribution and use in source and binary forms, with or without modification, 
 * are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 * 3. The name of the author may not be used to endorse or promote products
 *    derived from this software without specific prior written permission. 
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED 
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF 
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT 
 * SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, 
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT 
 * OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING 
 * IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY 
 * OF SUCH DAMAGE.
 *
 * Credits go to Jeremi Wójcicki (and the current maintainers) of this software.
 *
 **/



#define sensor_NSLAVES 1
#define sensor_NCH     2

//sensor_data_t sensor_data[sensor_NSLAVES];
//sensor_cal_t sensor_cal[sensor_NSLAVES];
//uint16_t *status_ptr;



#define MSG_LENGTH 128
char msg_tx[MSG_LENGTH];
char msg_rx[MSG_LENGTH];

// an ISR control flag for pending sensor data
volatile bool drdy = 0;

// interrupt service routine - when sensor conversion is complete
// this code should be light not to block the main loop for too long
void onDataReady(){
  drdy = true;
}

#define SAMPLES_PER_PRINT 1

//#define SERIAL_VERBOSE 1

int meascnt=0;
int calcnt[sensor_NSLAVES];
#define NCAL 16
bool calcomplete[sensor_NSLAVES];
bool calready=false;

// the HX711 board applies Vbias=4.1V to the load cell when Vcc=5V
// for a load cell with rated sensitivity of 1mV/V full scale
// the full scale output voltage will be Vbias*sensitivity

#define Vbias 4.1               //bias voltage to load cell
#define LC_capacity_kg 20.0     //load cell rated capacity
#define LC_sensitivity 0.001    //sensitivity in V/V
#define ADC_vin_FSR 0.04        //for gain = 128, input range is +/-20mV
#define ADC_vin_FSR 0.08        //for gain = 64, input range is +/-40mV
#define ADC_vin_FSR 0.16        //for gain = 32, input range is +/-80mV
#define ADC_raw_FSR (2^24-1)    //full scale range of the ADC output code


#include "HX711.h"

#define NAVG 1

// HX711.DOUT  - pin #A1
// HX711.PD_SCK - pin #A0

//HX711 scale(A1, A0);    // parameter "gain" is ommited; the default value 128 is used by the library
//(data, clk)
HX711 scale[2]={HX711(5, 2),HX711(6,4)};    // parameter "gain" is ommited; the default value 128 is used by the library
//HX711 scale[2]={HX711(3, 2),HX711(5,2)};    // parameter "gain" is ommited; the default value 128 is used by the library

  int chidx=0;

void setup() {

  //Serial.begin(115200);
  Serial.begin(1000000);
  Serial.println("HX711 Demo");
  
  Serial.println("Before setting up the scale:");
  chidx=0;
  sprintf(msg_tx,"CH%i Raw=%li",chidx,scale[chidx].read()); Serial.println(msg_tx);
  chidx=1;
  sprintf(msg_tx,"CH%i Raw=%li ",chidx,scale[chidx].read()); Serial.println(msg_tx);

  Serial.println("read average: \t\t");
  chidx=0;
  sprintf(msg_tx,"CH%i Raw=%li ",chidx,scale[chidx].read_average(NAVG)); Serial.println(msg_tx);
  chidx=1;
  sprintf(msg_tx,"CH%i Raw=%li ",chidx,scale[chidx].read_average(NAVG)); Serial.println(msg_tx);

  // print the average of 5 readings from the ADC minus the tare weight (not set yet)
  Serial.println("get value: \t\t");
  chidx=0;
  sprintf(msg_tx,"CH%i Raw=%li ",chidx,scale[chidx].get_value(NAVG)); Serial.println(msg_tx);
  chidx=1;
  sprintf(msg_tx,"CH%i Raw=%li ",chidx,scale[chidx].get_value(NAVG)); Serial.println(msg_tx);



  //Serial.print("get units: \t\t");
  //Serial.println(scale[chidx].get_units(5), 1);  // print the average of 5 readings from the ADC minus tare weight (not set) divided 
            // by the SCALE parameter (not set yet)  
  chidx=0;
  scale[chidx].set_scale(2280.f);                      // this value is obtained by calibrating the scale with known weights; see the README for details
  scale[chidx].tare();               // reset the scale to 0
  sprintf(msg_tx,"CH%i offset=%li ",chidx,scale[chidx].get_offset()); Serial.println(msg_tx);
  
  chidx=1;
  scale[chidx].set_scale(2280.f);                      // this value is obtained by calibrating the scale with known weights; see the README for details
  scale[chidx].tare();               // reset the scale to 0
  sprintf(msg_tx,"CH%i offset=%li ",chidx,scale[chidx].get_offset()); Serial.println(msg_tx);

  Serial.println(" ");
  Serial.println("***************************");
  Serial.println("After setting up the scale:");
  Serial.println("***************************");
  Serial.println(" ");

  chidx=0;
  sprintf(msg_tx,"CH%i Raw=%li ",chidx,scale[chidx].read()); Serial.println(msg_tx);
  chidx=1;
  sprintf(msg_tx,"CH%i Raw=%li ",chidx,scale[chidx].read()); Serial.println(msg_tx);

  Serial.println("read average: \t\t");
  chidx=0;
  sprintf(msg_tx,"CH%i Raw=%li ",chidx,scale[chidx].read_average(NAVG)); Serial.println(msg_tx);
  chidx=1;
  sprintf(msg_tx,"CH%i Raw=%li ",chidx,scale[chidx].read_average(NAVG)); Serial.println(msg_tx);

  // print the average of 5 readings from the ADC minus the tare weight (not set yet)
  Serial.println("get value: \t\t");
  chidx=0;
  sprintf(msg_tx,"CH%i Raw=%li ",chidx,scale[chidx].get_value(NAVG)); Serial.println(msg_tx);
  chidx=1;
  sprintf(msg_tx,"CH%i Raw=%li ",chidx,scale[chidx].get_value(NAVG)); Serial.println(msg_tx);

  Serial.println("manual offset correction: \t\t");
  chidx=0;
  sprintf(msg_tx,"CH%i Raw=%li ",chidx,scale[chidx].read_average(NAVG)-scale[chidx].get_offset()); Serial.println(msg_tx);
  chidx=1;
  sprintf(msg_tx,"CH%i Raw=%li ",chidx,scale[chidx].read_average(NAVG)-scale[chidx].get_offset()); Serial.println(msg_tx);


  Serial.println("Readings:");
  Serial.println("CAL DONE");

  calready=false;
}
//int chidx;
long temp[sensor_NCH];
long temp_diff;
// main loop
void loop() {
  //delay(20);
  
  dump_sensor_data();
  //Serial.write(0x1B);
  //sprintf(msg_tx,"diff Raw=%li ",1000); Serial.println(msg_tx);
}


//char *dtostrf(double val, signed char width, unsigned char prec, char *s)
//void dump_ldc_data(LDC16xx *ldc, uint8_t slaveidx)
char fstr1[16];

void dump_sensor_data(void)
{
//  Serial.write(0x0C);
  //Serial.write(0x1B);
  fstr1[16];
  chidx=0;
  temp[sensor_NCH];
  //sprintf(msg_tx,"LDC%i:\n",slaveidx+1); Serial.print(msg_tx);
  for(chidx = 0; chidx < sensor_NCH; chidx++) {
    delay(20);
    temp[chidx]=scale[chidx].read_average(NAVG);
    sprintf(msg_tx,"CH%i Raw=%li ",chidx,temp[chidx]-scale[chidx].get_offset()); Serial.println(msg_tx);
  }
  temp_diff = (temp[0]-scale[0].get_offset()) - (temp[1]-scale[1].get_offset());
  sprintf(msg_tx,"diff Raw=%li ",temp_diff); Serial.println(msg_tx);
}
