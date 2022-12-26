import java.util.*;

enum EventType {
  NavPoints,
  LocateBag,
  SecurityLine,
}

enum PointName {
  T1,
  T2,
  T3,
  T4,
  SouthSecurity,
  NorthSecurity,
  BaggageClaim,
  RideShare,
  Starbucks,
  McDonalds,
  Bathroom,
  TrainStation,
  Brookstone,
  Wendys,
  none
}

enum SecurityTimeFlag {
  // fast (under 15 min), medium (15 - 30 min), slow (over 30 min) (String)
  slow,
  fast,
  medium,
  none
}

enum Line {
  north,
  south,
  clear,
  preCheck,
  none
}

class DataStream {
  int timestamp; // done
  EventType event; // done
  PointName pointName; // done
  Vector<Integer> position;
  float distance;
  Line line;
  SecurityTimeFlag flag; // done
  int waitTime;
  
  public DataStream(JSONObject json) {
    // all event types contain a timestamp
    this.timestamp = json.getInt("timestamp");
    
    String eventType = json.getString("event");
    
    try {
      this.event = EventType.valueOf(eventType);
    }
    catch (IllegalArgumentException e) {
      throw new RuntimeException(eventType + " is not a valid value for enum EventType.");
    }
    
    if (json.isNull("pointName")) {
      this.pointName = PointName.valueOf("none");
    } else {
      String pointType = json.getString("pointName");
      try {
        this.pointName = PointName.valueOf(pointType);
      }
      catch (IllegalArgumentException e) {
        throw new RuntimeException(pointType + " is not a valid value for enum Destination.");
      }
    }
    
    if (json.isNull("flag")) {
      this.flag = SecurityTimeFlag.valueOf("none");
    } else {
      String flagType = json.getString("flag");
      try {
        this.flag = SecurityTimeFlag.valueOf(flagType);
      }
      catch (IllegalArgumentException e) {
        throw new RuntimeException(flagType + " is not a valid value for enum SecurityTimeFlag.");
      }
    }
    
    if (json.isNull("position")) {
      Vector<Integer> v = new Vector<Integer>();
      v.add(-100000);
      v.add(-100000);
      this.position = v;
    } else {
      JSONObject vector = json.getJSONObject("position");
      Integer xCoordinate = (Integer) vector.getInt("X");
      Integer yCoordinate = (Integer) vector.getInt("Y");
      Vector<Integer> v = new Vector<Integer>();
      v.add(xCoordinate);
      v.add(yCoordinate);
      this.position = v;
    }
    
    if (json.isNull("line")) {
      this.line = Line.valueOf("none");
    } else {
      String lineType = json.getString("line");
      try {
        this.line = Line.valueOf(lineType);
      }
      catch (IllegalArgumentException e) {
        throw new RuntimeException(lineType + " is not a valid value for enum Line.");
      }
    }
    
    if (json.isNull("distance")) {
      this.distance= -1.0;
    } else {
      this.distance = json.getFloat("distance");
    }
    
    if (json.isNull("waitTime")) {
      this.waitTime = -1;
    } else {
      this.waitTime = json.getInt("waitTime");
    } 
  }
  
  public int getTimestamp() {
    return timestamp;
  }
  public EventType getEvent() {
    return event;
  }
  public PointName getPoint() {
    return pointName;
  }
  public float getDistance() {
    return distance;
  }
  public int getWaitTime() {
    return waitTime;
  }
  public SecurityTimeFlag getFlag() {
    return flag;
  }
  public Line getLine() {
    return line;
  }
  public Vector getPosition() {
    return position;
  }
  
  
  public String toString() {
    String output = getEvent().toString() + ": ";
    output += "(timestamp: " + getTimestamp() + ") ";
    output += "(pointName: " + getPoint().toString() + ") ";
    output += "(position: " + getPosition().toString() + ") ";
    output += "(line: " + getLine().toString() + ") ";
    output += "(flag: " + getFlag().toString() + ") ";
    output += "(waitTime: " + getWaitTime() + ") ";
    output += "(distance: " + getDistance() + ") ";
    return output;
  }
}
