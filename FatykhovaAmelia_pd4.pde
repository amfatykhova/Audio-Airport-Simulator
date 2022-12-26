// IMPORTS
import beads.*;
import controlP5.*;
import java.util.ArrayList;
import java.util.*;
import org.jaudiolibs.beads.*;
import processing.event.MouseEvent;

// PROJECT VARIABLES ///////////////////////////////////////////////////////////////////
PowerSpectrum ps;
ControlP5 p5;

color mouseColor = color(255, 204, 0);
color fore = color(255, 255, 255);
color back = color(0,0,0);

ControlTimer timer;
Timer bagTimer;
RadioButton selectMode;
RadioButton directionKey;
RadioButton lineTime;
RadioButton bagButtons;
RadioButton soundKey;
DropdownList chooseDestination;
Slider volumeSlider;

double currentDirection = -1.0;

String currentDestination = "...";

Vector<Integer> destinationPosition;

String nextBeacon;
float bagDistance;
String northFlag = "...";
String southFlag = "...";
String clearFlag = "...";
String preCheckFlag = "...";
int currentMode;
float longestDistance = -1;
String navStatus = "...";

// sound variables
SamplePlayer bagSound;
SamplePlayer lineSound;
SamplePlayer navSoundNorth;
SamplePlayer navSoundSouth;
SamplePlayer navSoundEast;
SamplePlayer navSoundWest;
SamplePlayer arrivalSound;
Gain masterGain;
Glide volumeGlide;
Glide bagBeepRateGlide;
Glide lineSpeedGlide;
Glide navSpeedGlide;

boolean playNorth = false;
boolean playSouth = false;
boolean playClear = false;
boolean playPreCheck = false;
boolean playBagSounds = false;

int northTime = -1;
int southTime = -1;
int clearTime = -1;
int preCheckTime = -1;

boolean northwards = false;
boolean southwards = false;
boolean eastwards = false;
boolean westwards = false;

boolean startNavSim = false;

boolean navMode = false;
boolean lineMode = false;
boolean bagMode = false;

// default currentPosition vector is fake 
Vector <Integer> currentPosition = new Vector<Integer>() {{
  add(-100000);
  add(-100000);
}};


// JSON DATA
String navigationEvents = "aiportNav_Destinations.json";
String securityLineEvents = "airportNav_SecurityLine.json";
String bagEvents = "bagsNew.json";

// DATASTRUCTURES
ArrayList<DataStream> navData;
ArrayList<DataStream> lineData;
ArrayList<DataStream> bagData;
DataStream currentLine;
DataStream currentBagPosition;
float currentBagDistance = -1.0;

DataServer server1;
DataServer server2;
DataServer server3;

///////////////////////////////////////////////////////////////////////////////

void setup(){
 size(800,650);

 ac = new AudioContext();
 p5 = new ControlP5(this); // holds UI controls
 
 timer = new ControlTimer();
 // PROJECT UI ELEMENTS START
 
 server1 = new DataServer();
 server1.loadData(navigationEvents);
 navData = server1.getDataList();
 println("number of nav events: " + navData.size());
 
 
 server2 = new DataServer();
 server2.loadData(securityLineEvents);
 lineData = server2.getDataList();
 println("number of line events: " + lineData.size());
 
 //println(mouseX);
 server3 = new DataServer();
 server3.loadData(bagEvents);
 bagData = server3.getDataList();
 println("number of bag events: " + bagData.size());
 
 
 bagSound = getSamplePlayer("bagBeep.wav");
 bagSound.pause(true);
 lineSound = getSamplePlayer("securityLine.wav");
 lineSound.pause(true);
 
 navSoundNorth = getSamplePlayer("navNorth.wav");
 navSoundNorth.pause(true);
 
 navSoundSouth = getSamplePlayer("navSouth.wav");
 navSoundSouth.pause(true);
 
 navSoundEast = getSamplePlayer("navEast.wav");
 navSoundEast.pause(true);
 
 navSoundWest = getSamplePlayer("navWest.wav");
 navSoundWest.pause(true);
 
 arrivalSound = getSamplePlayer("arrivalBloop.wav");
 arrivalSound.pause(true);
 
 // make bag sounds and line sound loop 
 bagSound.setLoopType(SamplePlayer.LoopType.LOOP_FORWARDS);
 lineSound.setLoopType(SamplePlayer.LoopType.LOOP_FORWARDS);
 
 navSoundNorth.setLoopType(SamplePlayer.LoopType.LOOP_FORWARDS);
 navSoundSouth.setLoopType(SamplePlayer.LoopType.LOOP_FORWARDS);
 navSoundEast.setLoopType(SamplePlayer.LoopType.LOOP_FORWARDS);
 navSoundWest.setLoopType(SamplePlayer.LoopType.LOOP_FORWARDS);
 
 // set up a master gain object
 volumeGlide = new Glide(ac, 0.75, 500);
 masterGain = new Gain(ac, 2, volumeGlide);

 bagBeepRateGlide = new Glide(ac,  1, 500);
 bagSound.setRate(bagBeepRateGlide);
 
 lineSpeedGlide = new Glide(ac, 1, 500);
 lineSound.setRate(lineSpeedGlide);
 
 navSpeedGlide = new Glide(ac, 1, 500);
 navSoundNorth.setRate(navSpeedGlide);
 navSoundSouth.setRate(navSpeedGlide);
 navSoundEast.setRate(navSpeedGlide);
 navSoundWest.setRate(navSpeedGlide);
 
 
 masterGain.addInput(bagSound);
 masterGain.addInput(lineSound);

 masterGain.addInput(navSoundNorth);
 masterGain.addInput(navSoundSouth);
 masterGain.addInput(navSoundWest);
 masterGain.addInput(navSoundEast);
 
 masterGain.addInput(arrivalSound);
 
 ac.out.addInput(masterGain);
 
 //////////////////////////////////////////////////////////

 chooseDestination = p5.addDropdownList("chooseDestination")
   .setPosition(515, 100)
   .setSize(100, 400)
   .addItem("T1", 0)
   .addItem("T2", 1)
   .addItem("T3", 2)
   .addItem("T4", 3)
   .addItem("South Security", 4)
   .addItem("North Security", 5)
   .addItem("Ride Share", 6)
   .addItem("Starbucks", 7)
   .addItem("McDonald's", 8)
   .addItem("Train Station", 9)
   .addItem("Brookstone", 10)
   .addItem("Wendy's", 11)
   .addItem("Bathroom", 12)
   .addItem("BaggageClaim", 13);
   
 selectMode = p5.addRadioButton("selectMode")
   .setPosition(10, 510)
   .setSize(45, 25)
   .setItemsPerRow(1)
   .setSpacingColumn(80)
   .setSpacingRow(20)
   .addItem("Navigation", 0)
   .addItem("Security Time", 1)
   .addItem("Bag Location", 2);
   
 volumeSlider = p5.addSlider("volumeSlider")
    .setPosition(150, 510)
    .setSize(25, 100)
    .setRange(0, 100.0)
    .setValue(50)
    .setLabel("Master Volume Slider"); 
    
 directionKey = p5.addRadioButton("directionKey")
   .setPosition(650, 100)
   .setSize(45, 15)
   .setItemsPerRow(1)
   .setSpacingColumn(80)
   .setSpacingRow(10)
   .addItem("Start Nav Sim", 0)
   .addItem("Reset Nav Sim", 1);
   
 soundKey = p5.addRadioButton("soundKey")
   .setPosition(650, 200)
   .setSize(30, 10)
   .setItemsPerRow(1)
   .setSpacingColumn(80)
   .setSpacingRow(10)
   .addItem("North", 0)
   .addItem("South", 1)
   .addItem("East", 2)
   .addItem("West", 3);
    
 lineTime = p5.addRadioButton("lineTime")
    .setPosition(30, 405)
    .setSize(45, 25)
    .setItemsPerRow(4)
    .setSpacingColumn(125)
    .addItem("Play North", 0)
    .addItem("Play South", 1)
    .addItem("Play Clear", 2)
    .addItem("Play PreCheck", 3)
    .addItem("Pause North", 4)
    .addItem("Plause South", 5)
    .addItem("Plause Clear", 6)
    .addItem("Pause PreCheck", 7);
    
 bagButtons = p5.addRadioButton("bagButtons")
    .setPosition(280, 560)
    .setSize(45, 25)
    .setItemsPerRow(2)
    .setSpacingColumn(120)
    .addItem("Play Bag Location Sounds", 0)
    .addItem("Pause Bag Location Sounds", 1);
   
 ac.start();
}

// PROJECT EVENT HANDLERS
void volumeSlider(float value) {
  println("Volume slider moved: ", value);
  volumeGlide.setValue(value/100.0);
}

void selectMode(int value) {
  if (value == 0) {
    playBagSounds = false;
    // navigation mode
    navMode = true;
    bagMode = false;
    lineMode = false;
    selectMode.activate(0);
    currentMode = 0;
    // deactivate buttons from other modes
    lineTime.deactivateAll();
    bagButtons.deactivateAll();
    // reset the global timer to simulate navigation mode
    timer.reset();
    // timer.start();
    bagSound.pause(true);
    lineSound.pause(true);
    preCheckFlag = "...";
    preCheckTime = -1;
    northFlag = "...";
    northTime = -1;
    southFlag = "...";
    southTime = -1;
    clearFlag = "...";
    clearTime = -1;
    currentBagDistance = -1;
  } else if (value == 1) {
    // security mode
    playBagSounds = false;
    lineMode = true;
    navMode = false;
    bagMode = false;
    selectMode.activate(1);
    currentMode = 1;
    // deactivate buttons from other modes
    directionKey.deactivateAll();
    bagButtons.deactivateAll();
    // reset the global timer to simulate navigation mode
    timer.reset();
    navSoundNorth.pause(true);
    navSoundSouth.pause(true);
    navSoundEast.pause(true);
    navSoundWest.pause(true);
    bagSound.pause(true);
     currentDirection = -1.0;
      currentPosition = new Vector<Integer>() {{
        add(-100000);
        add(-100000);
      }};
      longestDistance = -1; // reset longest distance
      currentDestination = "...";
      navStatus = "...";
      currentBagDistance = -1;
  } else if (value == 2) {
    // bag mode
    bagMode = true;
    navMode = false;
    lineMode = false;
    selectMode.activate(2);
    currentMode = 2;
    // deactivate buttons from other modes
    directionKey.deactivateAll();
    lineTime.deactivateAll();
    // reset the global timer to simulate navigation mode
    timer.reset();
    navSoundNorth.pause(true);
    navSoundSouth.pause(true);
    navSoundEast.pause(true);
    navSoundWest.pause(true);
    lineSound.pause(true);
    preCheckFlag = "...";
    preCheckTime = -1;
    northFlag = "...";
    northTime = -1;
    southFlag = "...";
    southTime = -1;
    clearFlag = "...";
    clearTime = -1;
     currentDirection = -1.0;
      currentPosition = new Vector<Integer>() {{
        add(-100000);
        add(-100000);
      }};
      longestDistance = -1; // reset longest distance
      currentDestination = "...";
      navStatus = "...";
  }
}


void directionKey(int value) {
  if (navMode) {
    if (value == 0) {
      // play
      navSoundNorth.pause(true);
      navSoundSouth.pause(true);
      navSoundEast.pause(true);
      navSoundWest.pause(true);
      startNavSim = true;
      directionKey.activate(0);
    } else if (value == 1) {
      // pause
      startNavSim = false;
      directionKey.activate(1);
      currentDirection = -1.0;
      currentPosition = new Vector<Integer>() {{
        add(-100000);
        add(-100000);
      }};
      longestDistance = -1; // reset longest distance
      currentDestination = "...";
      navStatus = "...";
      navSoundNorth.pause(true);
      navSoundSouth.pause(true);
      navSoundEast.pause(true);
      navSoundWest.pause(true);
    }
  }
}

void soundKey(int value) {
  if (navMode) {
    if (value == 0) {
      navSpeedGlide.setValue(1);
      soundKey.activate(0);
      navSoundNorth.pause(true);
      navSoundSouth.pause(true);
      navSoundEast.pause(true);
      navSoundWest.pause(true);
      navSoundSouth.start(0);
    } else if (value == 1) {
      navSpeedGlide.setValue(1);
      soundKey.activate(1);
      navSoundNorth.pause(true);
      navSoundSouth.pause(true);
      navSoundEast.pause(true);
      navSoundWest.pause(true);
      navSoundNorth.start(0);
    } else if (value == 2) {
      navSpeedGlide.setValue(1);
      soundKey.activate(2);
      navSoundNorth.pause(true);
      navSoundSouth.pause(true);
      navSoundEast.pause(true);
      navSoundWest.pause(true);
      navSoundEast.start(0);
    } else if (value == 3) {
      navSpeedGlide.setValue(1);
      soundKey.activate(3);
      navSoundNorth.pause(true);
      navSoundSouth.pause(true);
      navSoundEast.pause(true);
      navSoundWest.pause(true);
      navSoundWest.start(0);
    }
  }
}

void chooseDestination(int value) {
  if (navMode) {
    if (value == 0) {
      //T1
      currentDestination = "T1";
      longestDistance = -1; // reset longest distance
      println(currentDestination);
      for (int i = 0; i < navData.size(); i++) {
        String navName = navData.get(i).getPoint().toString();
        if (navName == currentDestination) {
          destinationPosition = navData.get(i).getPosition();
          println("destination position for " + currentDestination + " is: " + destinationPosition);
        }
      }
      
    } else if (value == 1) {
      //T2
      currentDestination = "T2";
      longestDistance = -1; // reset longest distance
      println(currentDestination);
      for (int i = 0; i < navData.size(); i++) {
        String navName = navData.get(i).getPoint().toString();
        if (navName == currentDestination) {
          destinationPosition = navData.get(i).getPosition();
          println("destination position for " + currentDestination + " is: " + destinationPosition);
        }
      }
      
    }  else if (value == 2) {
      //T3
      currentDestination = "T3";
      longestDistance = -1; // reset longest distance
      println(currentDestination);
      for (int i = 0; i < navData.size(); i++) {
        String navName = navData.get(i).getPoint().toString();
        if (navName == currentDestination) {
          destinationPosition = navData.get(i).getPosition();
          println("destination position for " + currentDestination + " is: " + destinationPosition);
        }
      }
      
    }  else if (value == 3) {
      //T4
      currentDestination = "T4";
      longestDistance = -1; // reset longest distance
      println(currentDestination);
      for (int i = 0; i < navData.size(); i++) {
        String navName = navData.get(i).getPoint().toString();
        if (navName == currentDestination) {
          destinationPosition = navData.get(i).getPosition();
          println("destination position for " + currentDestination + " is: " + destinationPosition);
        }
      }
      
    }  else if (value == 4) {
      //South Security
      currentDestination = "SouthSecurity";
      longestDistance = -1; // reset longest distance
      println(currentDestination);
      for (int i = 0; i < navData.size(); i++) {
        String navName = navData.get(i).getPoint().toString();
        if (navName == currentDestination) {
          destinationPosition = navData.get(i).getPosition();
          println("destination position for " + currentDestination + " is: " + destinationPosition);
        }
      }
      
    }  else if (value == 5) {
      //North Security
      currentDestination = "NorthSecurity";
      longestDistance = -1; // reset longest distance
      println(currentDestination);
      for (int i = 0; i < navData.size(); i++) {
        String navName = navData.get(i).getPoint().toString();
        if (navName == currentDestination) {
          destinationPosition = navData.get(i).getPosition();
          println("destination position for " + currentDestination + " is: " + destinationPosition);
        }
      }
      
    }  else if (value == 6) {
      //Ride Share
      currentDestination = "RideShare";
      longestDistance = -1; // reset longest distance
      println(currentDestination);
      for (int i = 0; i < navData.size(); i++) {
        String navName = navData.get(i).getPoint().toString();
        if (navName == currentDestination) {
          destinationPosition = navData.get(i).getPosition();
          println("destination position for " + currentDestination + " is: " + destinationPosition);
        }
      }
      
    }  else if (value == 7) {
      // Starbucks
      currentDestination = "Starbucks";
      longestDistance = -1; // reset longest distance
      println(currentDestination);
      for (int i = 0; i < navData.size(); i++) {
        String navName = navData.get(i).getPoint().toString();
        if (navName == currentDestination) {
          destinationPosition = navData.get(i).getPosition();
          println("destination position for " + currentDestination + " is: " + destinationPosition);
        }
      }
      
    }  else if (value == 8) {
      // McDonald's
      currentDestination = "McDonalds";
      longestDistance = -1; // reset longest distance
      println(currentDestination);
      for (int i = 0; i < navData.size(); i++) {
        String navName = navData.get(i).getPoint().toString();
        if (navName == currentDestination) {
          destinationPosition = navData.get(i).getPosition();
          println("destination position for " + currentDestination + " is: " + destinationPosition);
        }
      }
      
    }  else if (value == 9) {
      // train station
      currentDestination = "TrainStation";
      longestDistance = -1; // reset longest distance
      println(currentDestination);
      for (int i = 0; i < navData.size(); i++) {
        String navName = navData.get(i).getPoint().toString();
        if (navName == currentDestination) {
          destinationPosition = navData.get(i).getPosition();
          println("destination position for " + currentDestination + " is: " + destinationPosition);
        }
      }
      
    }  else if (value == 10) {
      // brookstone
      currentDestination = "Brookstone";
      longestDistance = -1; // reset longest distance
      println(currentDestination);
      for (int i = 0; i < navData.size(); i++) {
        String navName = navData.get(i).getPoint().toString();
        if (navName == currentDestination) {
          destinationPosition = navData.get(i).getPosition();
          println("destination position for " + currentDestination + " is: " + destinationPosition);
        }
      }
      
    }  else if (value == 11) {
      // Wendy's
      currentDestination = "Wendys";
      longestDistance = -1; // reset longest distance
      println(currentDestination);
      for (int i = 0; i < navData.size(); i++) {
        String navName = navData.get(i).getPoint().toString();
        if (navName == currentDestination) {
          destinationPosition = navData.get(i).getPosition();
          println("destination position for " + currentDestination + " is: " + destinationPosition);
        }
      }
      
    }  else if (value == 12) {
      // bathroom
      currentDestination = "Bathroom";
      longestDistance = -1; // reset longest distance
      println(currentDestination);
      for (int i = 0; i < navData.size(); i++) {
        String navName = navData.get(i).getPoint().toString();
        if (navName == currentDestination) {
          destinationPosition = navData.get(i).getPosition();
          println("destination position for " + currentDestination + " is: " + destinationPosition);
        }
      }
      
    } else if (value == 13) {
      // baggaegclaim
      currentDestination = "BaggageClaim";
      longestDistance = -1; // reset longest distance
      println(currentDestination);
      for (int i = 0; i < navData.size(); i++) {
        String navName = navData.get(i).getPoint().toString();
        if (navName == currentDestination) {
          destinationPosition = navData.get(i).getPosition();
          println("destination position for " + currentDestination + " is: " + destinationPosition);
        }
      }
      
    }
  }
}

public void setPlaybackRateBag() {
  bagBeepRateGlide.setValue((42 - currentBagDistance)/8);
}

void bagButtons(int value) {
  if (bagMode) {
    if (value == 0) {
      playBagSounds = true;
      bagButtons.activate(0);
      timer.reset();
      getBagData();
      bagSound.start(0);
    } else if (value == 1) {
      playBagSounds = false;
      println("bag sounds stopped");
      bagButtons.activate(1);
      currentBagDistance = -1;
      bagSound.pause(true);
    }
  }
}

public void setPlaybackRateLine(float val) {
  lineSpeedGlide.setValue(Math.abs(50 - val)/12);
}

void lineTime(int value) {
  if (lineMode) {
    if (value == 0) {
      // play north
      lineTime.activate(0);
      playNorth = true;
      playSouth = false;
      playClear = false;
      playPreCheck = false;
      println("playNorth: ", playNorth);
      getLineData("north");
      lineSound.start(0);
      northFlag = currentLine.getFlag().toString();
      northTime = currentLine.getWaitTime();
      
    } else if (value == 1) {
      // play south
      lineTime.activate(1);
      playSouth = true;
      playNorth = false;
      playClear = false;
      playPreCheck = false;
      println("playSouth: ", playSouth);
      getLineData("south");
      lineSound.start(0);
      southFlag = currentLine.getFlag().toString();
      southTime = currentLine.getWaitTime();
      
    } else if (value == 2) {
      // play clear
      lineTime.activate(2);
      playClear = true;
      playNorth = false;
      playSouth = false;
      playPreCheck = false;
      println("playClear: ", playClear);
      getLineData("clear");
      lineSound.start(0);
      clearFlag = currentLine.getFlag().toString();
      clearTime = currentLine.getWaitTime();
      
    } else if (value == 3) {
      // play precheck
      lineTime.activate(3);
      playPreCheck = true;
      playNorth = false;
      playSouth = false;
      playClear = false;
      println("playPreCheck: ", playPreCheck);
      getLineData("preCheck");
      lineSound.start(0);
      preCheckFlag = currentLine.getFlag().toString();
      preCheckTime = currentLine.getWaitTime();
      
    } else if (value == 4) {
      // pause north
      lineSound.pause(true);
      lineTime.activate(4);
      playNorth = false;
      println("playNorth: ", playNorth);
      northFlag = "...";
      northTime = -1;
      
    } else if (value == 5) {
      // pause south
      lineSound.pause(true);
      lineTime.activate(5);
      playSouth = false;
      println("playSouth: ", playSouth);
      southFlag = "...";
      southTime = -1;
      
    } else if (value == 6) {
      // pause clear
      lineSound.pause(true);
      lineTime.activate(6);
      playClear = false;
      println("playClear: ", playClear);
      clearFlag = "...";
      clearTime = -1;
      
    } else if (value == 7) {
      // pause pre-check
      lineSound.pause(true);
      lineTime.activate(7);
      playPreCheck = false;
      println("playPreCheck: ", playPreCheck);
      preCheckFlag = "...";
      preCheckTime = -1;
    }
  }
}

// modify currentLine
void getLineData(String lineName) {
  if (timer.minute() < 1) {
    // timestamp 100
    for (int i = 0; i < lineData.size(); i++) {
      if (lineData.get(i).getTimestamp() == 100 && lineData.get(i).getLine().toString().equals(lineName)){
        currentLine  = lineData.get(i);
        setPlaybackRateLine(currentLine.getWaitTime());
        println(currentLine);
      }
    }
  } else if (timer.minute() > 1 && timer.minute() < 2) {
    // timestamp 60000
    for (int i = 0; i < lineData.size(); i++) {
      if (lineData.get(i).getTimestamp() == 60000 && lineData.get(i).getLine().toString().equals(lineName)){
        currentLine  = lineData.get(i);
        setPlaybackRateLine(currentLine.getWaitTime());
        println(currentLine);
      }
    }
  } else if (timer.minute() > 2 && timer.minute() < 3) {
    // timestamp 120000
    for (int i = 0; i < lineData.size(); i++) {
      if (lineData.get(i).getTimestamp() == 120000 && lineData.get(i).getLine().toString().equals(lineName)){
        currentLine = lineData.get(i);
        setPlaybackRateLine(currentLine.getWaitTime());
        println(currentLine);
      }
    }
  } else if (timer.minute() > 3 && timer.minute() < 4) {
    // timestamp 180000
    for (int i = 0; i < lineData.size(); i++) {
      if (lineData.get(i).getTimestamp() == 180000 && lineData.get(i).getLine().toString().equals(lineName)){
        currentLine = lineData.get(i);
        setPlaybackRateLine(currentLine.getWaitTime());
        println(currentLine);
      }
    }
  } else if (timer.minute() > 4 && timer.minute() < 5) {
    // timestamp 240000
    for (int i = 0; i < lineData.size(); i++) {
      if (lineData.get(i).getTimestamp() == 240000 && lineData.get(i).getLine().toString().equals(lineName)){
        currentLine = lineData.get(i);
        setPlaybackRateLine(currentLine.getWaitTime());
        println(currentLine);
      }
    }
  } else if (timer.minute() > 5 && timer.minute() < 6) {
    // timer 300000
    for (int i = 0; i < lineData.size(); i++) {
      if (lineData.get(i).getTimestamp() == 300000 && lineData.get(i).getLine().toString().equals(lineName)){
        currentLine = lineData.get(i);
        setPlaybackRateLine(currentLine.getWaitTime());
        println(currentLine);
      }
    }
  } else if (timer.minute() > 6 && timer.minute() < 7) {
    // timer 360000
    for (int i = 0; i < lineData.size(); i++) {
      if (lineData.get(i).getTimestamp() == 360000 && lineData.get(i).getLine().toString().equals(lineName)){
        currentLine = lineData.get(i);
        setPlaybackRateLine(currentLine.getWaitTime());
        println(currentLine);
      }
    }
  }
}

// bag data stream handler
void getBagData() {
  if (playBagSounds) {
      Timer loopTimer = new Timer(); 
      TimerTask timerTask = new TimerTask() {
        public void run() {
          if (playBagSounds == false) {
            loopTimer.cancel();
            return;
          }
          for (int i = 0; i < bagData.size(); i++) {
            if (bagData.get(i).getTimestamp() == timer.second()) {
              currentBagPosition = bagData.get(i);
              currentBagDistance = currentBagPosition.getDistance();
              println("Position at " + timer.second() + " is " + currentBagDistance);
              setPlaybackRateBag();
            }
          }
        }
      };
    loopTimer.scheduleAtFixedRate(timerTask, 0, 1000);
  } else {
    return;
  }
}


public void directionSoundPlayer(double angle) {
  if ((angle > 345 && angle < 360) || (angle >= 0 && angle < 15)) {
    navSoundNorth.start();
  } else if (angle > 75 && angle < 105) {
    navSoundEast.start();
  } else if (angle > 165 && angle < 195) {
    navSoundSouth.start();
  } else if (angle > 255 && angle < 285) {
    navSoundWest.start();
  } else if (angle >= 15 && angle <= 75) {
    navSoundNorth.start();
    navSoundEast.start();
  } else if (angle >= 105 && angle <= 165) {
    navSoundSouth.start();
    navSoundEast.start();
  } else if (angle >= 195 && angle <= 255) {
    navSoundSouth.start();
    navSoundWest.start();
  } else if (angle >= 285 && angle <= 345) {
    navSoundNorth.start();
    navSoundWest.start();
  }

}

public void setNavPlayRate(float distance) {
 // 0.5 to 2
 // longestDistance --> max distance the player has been from the destination
 // distance --> the current distance that the player is from the destination
  float percent = 100 - ((distance / longestDistance) * 100);
  float value = ((percent * 1.5)/100) + 0.5;
  navSpeedGlide.setValue(value);
  println("song rate: ", value);
  
  if (distance < 10) {
    navStatus = "arrived";
    arrivalSound.start(0);
    navSoundNorth.pause(true);
    navSoundSouth.pause(true);
    navSoundEast.pause(true);
    navSoundWest.pause(true);
    println("YOU HAVE ARRIVED AT YOUR DESTINATION: " + currentDestination);
  }
}


void mousePressed() {
  // x value: 15 to 465
 // y value: 50 to 250
 // centerX: 240, center y: 150 
  if (mouseX > 15 && mouseX < 465 && mouseY > 50 && mouseY < 250 && !currentDestination.equals("...") && startNavSim == true) {
     println("mouse was clicked: (x: " + mouseX + ", y: " + mouseY + ")");
     currentPosition = new Vector<Integer>();
     currentPosition.add(mouseX);
     currentPosition.add(mouseY);
     double angle = calculateAngle(currentPosition, destinationPosition);
     currentDirection = angle;
     float distance = calculateDistance(currentPosition, destinationPosition);
     println("current position: ", currentPosition);
     println("destination position: ", destinationPosition);
     println("angle: ", angle);
     println("distance: ", distance); 
     navStatus = "travelling to destination";
     navSoundNorth.pause(true);
     navSoundSouth.pause(true);
     navSoundWest.pause(true);
     navSoundEast.pause(true);
     directionSoundPlayer(angle);
     setNavPlayRate(distance);
  } 
}

public float calculateDistance(Vector<Integer> current, Vector<Integer> destination) {
  float distance = sqrt((destination.get(1) - current.get(1)) * (destination.get(1) - current.get(1)) + (destination.get(0) - current.get(0)) * (destination.get(0) - current.get(0)));
  if (distance > longestDistance) {
    longestDistance = distance;
  }
  return distance;
}

public static double calculateAngle(Vector<Integer> current, Vector<Integer> destination) {
    double theta = Math.atan2(destination.get(1) - current.get(1), destination.get(0) - current.get(0));
    theta += Math.PI/2.0;
    double angle = Math.toDegrees(theta);
    if (angle < 0) {
        angle += 360;
    }
    return angle;
}

color hover = color(0, 230, 150);

void draw() {

 background(back);
 stroke(fore);
 
 

 
   fill(color(0, 280, 120));
   // simulation start position
   rect(165, 225, 6, 6);
   
    // gates
   fill(color(0, 230, 150));
   
   
   rect(25, 70, 4, 4);
   text("T1", 32, 75);
   
   rect(100, 70, 4, 4);
   text("T2", 107, 75);
   
   rect(175, 70, 4, 4);
   text("T3", 182, 75);
   
   rect(250, 70, 4, 4);
   text("T4", 257, 75);
   
   rect(350, 70, 4, 4);
   text("Starbucks", 357, 75);
   
   rect(25, 115, 4, 4);
   text("MCDonald's", 32, 120);
   
   rect(370, 150, 4, 4);
   text("Train Station", 377, 155);
   
   rect(155, 140, 4, 4);
   text("Brookstone", 162, 145);
   
   rect(280, 140, 4, 4);
   text("Wendy's", 287, 145);
   
   rect(400, 225, 4, 4);
   text("Ride share", 407, 230);
   
   rect(250, 180, 4, 4);
   text("Bathroom", 257, 185);
   
   rect(30, 225, 4, 4);
   text("Baggage claim", 37, 230);
   
   rect(100, 200, 4, 4);
   text("South Security", 107, 205);
   
   rect(365, 200, 4, 4);
   text("North Security", 372, 205);
 

 fill(mouseColor);
 ellipse(mouseX, mouseY, 8, 8);
 

// MAP BOUNDARY BOX:
 fill (10, 10, 10, 10);
 rect (15, 50, 450, 200);
 // x value: 15 to 465
 // y value: 50 to 250
 
 
 fill (0, 32, 0, 32);
 rect (5, 480, 240, 150);
 
 // actually make real variables:
 
 fill(255);
 text("Select Mode Menu: ", 80, 500);
 text("Terminal T Map: ", 185, 40);
 text("Directional Tone Key", 580, 80);
  text("NAVIGATION MENU", 585, 60);
 text("Current Destination: " + currentDestination, 15, 280);
 text("Current Position: " + currentPosition, 15, 300);
 text("Direction to Travel: " + currentDirection, 15, 320);
 text("Status: " + navStatus, 250, 280);
 
 text("LINE MENU", 280, 345);
 text("NORTH LINE", 30, 365);
 text("SOUTH LINE", 200, 365);
 text("CLEAR LINE", 370, 365);
 text("PRE-CHECK LINE", 540, 365);
 text("North Flag: " + northFlag, 30, 380);
 text("South Flag: " + southFlag, 200, 380);
 text("Clear Flag: " + clearFlag, 370, 380);
 text("PreCheck Flag: " + preCheckFlag, 540, 380);
 
  text("North Wait: " + northTime + " min", 30, 395);
 text("South Wait: " + southTime + " min", 200, 395);
 text("Clear Wait: " + clearTime + " min", 370, 395);
 text("PreCheck Wait: " + preCheckTime + " min", 540, 395);
 
 text("Bag Distance: " + currentBagDistance, 625, 575);
 text("BAG MENU", 465, 530);
 
 text("Timer: " + timer.toString(), 2, 10);
 text("Mouse: (x: " + mouseX + ", y: " + mouseY + ")", 2, 30);
}
