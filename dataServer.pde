class DataServer {
  private ArrayList<DataStream> allEvents;
  
  public void loadData(String eventDataJSON) {
    allEvents = this.getEventDataFromJSON(loadJSONArray(eventDataJSON));
    println("succesfully loaded");
  }
  
  public ArrayList<DataStream> getEventDataFromJSON(JSONArray values) {
    ArrayList<DataStream> data = new ArrayList<DataStream>();
    for (int i = 0; i < values.size(); i++) {
      println(values.getJSONObject(i));
      data.add(new DataStream(values.getJSONObject(i)));
    }
    return data;
  }
  
  public ArrayList<DataStream> getDataList() {
    return allEvents;
  }
  
}
