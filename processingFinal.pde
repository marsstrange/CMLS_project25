import oscP5.*;
import netP5.*;

OscP5 oscP5;
PFont font;

ArrayList<Shape> shapes = new ArrayList<Shape>();
String lastCategory = "none";
color lastColor = color(0);

float x = 0, pan = 0, y = 0, freq = 0, pressure = 0, amp = 0;

// Layout constants
final int sideBarWidth = 250;    
final int mainAreaWidth = 750;  
final int scopeWidth = 200;
final int scopeHeight = 100;
final int responseHeight = 100;
final int historyLength = 400;
final int topMargin = 50;
final int graphSpacing = 70;
final color axisColor = color(100);
final int freqLabelInterval = 500; 
final int xLabelOffset = 20;
final int yLabelOffset = 10;
final float individualScopeY = topMargin;
final float individualResponseY = individualScopeY + scopeHeight + graphSpacing;
final float summedScopeY = individualResponseY + responseHeight + graphSpacing;
final float summedResponseY = summedScopeY + scopeHeight + graphSpacing;


ArrayList<Float> summedHistory = new ArrayList<Float>();
float phaseAccumulator = 0.0;
float individualPhase = 0.0;
boolean newShapeAdded = false;

void setup() {
  size(1000, 700);
  background(255);
  
  oscP5 = new OscP5(this, 12000); 
  font = createFont("Arial", 24);
  textFont(font);
  strokeWeight(2);
  smooth();
}

class Shape { 
  String category;
  color col;
  float[][] contour;
  float freq;
  float amp;
  String waveType;
  long creationTime;
  float duration; 

  Shape(String category, color col, float[][] contour, float freq, float amp, String waveType, float duration) {
    this.category = category;
    this.col = col;
    this.contour = contour;
    this.freq = freq;
    this.amp = amp;
    this.waveType = waveType;
    this.creationTime = millis();
    this.duration = duration * 1000;
  }
    
  void draw() {
    stroke(col);
    noFill();
    beginShape();
    for (float[] point : contour) {
      vertex(point[0] * mainAreaWidth, point[1] * height);
    }
    endShape();
    
    if (!category.equals("Line")) {
      float[] first = contour[0];
      float[] last = contour[contour.length-1];
      line(last[0] * mainAreaWidth, last[1] * height, 
           first[0] * mainAreaWidth, first[1] * height);
    }
  }
}

void draw() {
  background(255);
  drawSidebar();
  
  synchronized (shapes) {
    for (Shape s : shapes) {
      s.draw();
    }
  }
  
  drawVisualIndicators();
  drawIndividualOscilloscope();
  drawSummedOscilloscope();
  
  phaseAccumulator += 0.03;
  individualPhase += 0.03;
}

void drawVisualIndicators() {
  drawPanIndicator();
  drawFrequencyIndicator();
}

void drawPanIndicator() {
  float barY = height - 30;
  float cursorX = map(pan, -1, 1, 50, mainAreaWidth-50);
  
  stroke(200);
  line(50, barY, mainAreaWidth-50, barY);
  
  fill(lastColor);
  noStroke();
  ellipse(cursorX, barY, 15, 15);
  
  fill(0);
  textAlign(CENTER, CENTER);
  text("PAN", mainAreaWidth/2, barY - 20);
}

void drawFrequencyIndicator() {
  float barX = 30;
  float freqHeight = height - 200;
  
  float minFreq = 100;
  float maxFreq = 2000;
  float cursorY = map(log(freq/minFreq), 0, log(maxFreq/minFreq), freqHeight, 0);
  cursorY = constrain(cursorY, 0, freqHeight);
  
  stroke(200);
  line(barX, 100, barX, 100 + freqHeight);
  
  fill(lastColor);
  noStroke();
  ellipse(barX, 100 + cursorY, 15, 15);
  
  fill(0);
  textAlign(CENTER, CENTER);
  pushMatrix();
  translate(barX - 15, height/2);
  rotate(-HALF_PI);
  text("FREQUENCY", 0, 0);
  popMatrix();
}

void drawSidebar() {
  fill(240);
  noStroke();
  rect(mainAreaWidth, 0, sideBarWidth, height);
}

void drawIndividualOscilloscope() {
  float xPos = mainAreaWidth + (sideBarWidth - scopeWidth)/2; 
  
  fill(255);
  stroke(200);
  rect(xPos, individualScopeY, scopeWidth, scopeHeight);
  
  fill(0);
  textAlign(CENTER, CENTER);
  textSize(16);
  text("Current Waveform", xPos + scopeWidth/2, individualScopeY - 20);
  
  stroke(axisColor);
  line(xPos, individualScopeY + scopeHeight/2, xPos + scopeWidth, individualScopeY + scopeHeight/2);
  line(xPos, individualScopeY, xPos, individualScopeY + scopeHeight);
  
  fill(0);
  textSize(12);
  textAlign(CENTER, CENTER);
  text("Time", xPos + scopeWidth/2, individualScopeY + scopeHeight + xLabelOffset-10);

  pushMatrix();
  translate(xPos - yLabelOffset, individualScopeY + scopeHeight/2);
  rotate(-HALF_PI);
  text("Amplitude", 0, 0);
  popMatrix();
  
  if (!shapes.isEmpty()) {
    Shape latest = shapes.get(shapes.size()-1);
    ArrayList<Float> wavePoints = new ArrayList<Float>();
    int resolution = scopeWidth;
    float cycles = 2.0;

    for (int i = 0; i < resolution; i++) {
      float t = map(i, 0, resolution-1, individualPhase, individualPhase + cycles * TWO_PI);
      float value = calculateWaveValue(t, latest.freq, latest.waveType);
      wavePoints.add(value);
    }

    stroke(latest.col);
    strokeWeight(2);
    noFill();
    beginShape();
    for (int i = 0; i < wavePoints.size(); i++) {
      float xp = xPos + i;
      float yp = individualScopeY + scopeHeight/2 + wavePoints.get(i) * scopeHeight/3;
      vertex(xp, yp);
    }
    endShape();
  }
  

  drawFrequencyResponse(xPos, individualResponseY, getLatestShape());
}

void drawSummedOscilloscope() {
  float xPos = mainAreaWidth + (sideBarWidth - scopeWidth)/2;

  fill(255);
  stroke(200);
  rect(xPos, summedScopeY, scopeWidth, scopeHeight);
  
  fill(0);
  textAlign(CENTER, CENTER);
  textSize(16);
  text("Summed Waveforms", xPos + scopeWidth/2, summedScopeY - 20);
  
  stroke(axisColor);
  line(xPos, summedScopeY + scopeHeight/2, xPos + scopeWidth, summedScopeY + scopeHeight/2);
  line(xPos, summedScopeY, xPos, summedScopeY + scopeHeight);
  
  fill(0);
  textSize(12);
  textAlign(CENTER, CENTER);
  text("Time", xPos + scopeWidth/2, summedScopeY + scopeHeight + xLabelOffset - 10);

  pushMatrix();
  translate(xPos - yLabelOffset, summedScopeY + scopeHeight/2);
  rotate(-HALF_PI);
  text("Amplitude", 0, 0);
  popMatrix();

  if (!shapes.isEmpty()) {
    synchronized (shapes) {
      shapes.removeIf(s -> (millis() - s.creationTime) > s.duration);
    }

    float sum = 0;
    synchronized (shapes) {
      for (Shape s : shapes) {
        sum += calculateWaveValue(phaseAccumulator, s.freq, s.waveType) * s.amp;
      }
    }
    
    summedHistory.add(sum);
    while(summedHistory.size() > historyLength) {
      summedHistory.remove(0);
    }
    
    float maxAmplitude = 0.001;
    for (Float val : summedHistory) {
      maxAmplitude = max(maxAmplitude, abs(val));
    }
    float normalization = scopeHeight/(3 * maxAmplitude);

    stroke(lastColor);
    strokeWeight(2);
    noFill();
    beginShape();
    for (int i = 0; i < summedHistory.size(); i++) {
      float xp = xPos + map(i, 0, historyLength-1, 0, scopeWidth);
      float yp = summedScopeY + scopeHeight/2 + summedHistory.get(i) * normalization;
      vertex(xp, yp);
    }
    endShape();
  }

  drawSummedFrequencyResponse(xPos, summedResponseY);
}

void drawFrequencyResponse(float xPos, float yPos, Shape shape) {
  fill(255);
  stroke(200);
  rect(xPos, yPos, scopeWidth, responseHeight);
  
  stroke(axisColor);
  line(xPos, yPos + responseHeight, xPos + scopeWidth, yPos + responseHeight);
  line(xPos, yPos, xPos, yPos + responseHeight);
  
  fill(100);
  textSize(10);
  textAlign(CENTER, TOP);
  for(int freq = 0; freq <= 1760; freq += freqLabelInterval) {
    float xLabel = map(freq, 0, 1760, xPos, xPos + scopeWidth);
    text(str(freq) + "Hz", xLabel, yPos + responseHeight + 2);
  }
  
  fill(0);
  textAlign(CENTER, CENTER);
  textSize(16);
  text("Frequency Response", xPos + scopeWidth/2, yPos - 20);
  
  fill(0);
  textSize(12);
  textAlign(CENTER, CENTER);
  text("Frequency (Hz)", xPos + scopeWidth/2, yPos + responseHeight + xLabelOffset);

  pushMatrix();
  translate(xPos - yLabelOffset, yPos + responseHeight/2);
  rotate(-HALF_PI);
  text("Amplitude", 0, 0);
  popMatrix();

  if (shape != null) {
    float fundamentalFreq = shape.freq;
    float fundamentalAmp = shape.amp;
    
    stroke(shape.col);
    fill(shape.col);
    float xPosFreq = map(fundamentalFreq, 0, 1760, xPos, xPos + scopeWidth);
    float h = map(fundamentalAmp, 0, fundamentalAmp, 0, responseHeight);
    rect(xPosFreq - 1, yPos + responseHeight - h, 2, h);
  }
}

void drawSummedFrequencyResponse(float xPos, float yPos) {
    fill(255);
    stroke(200);
    rect(xPos, yPos, scopeWidth, responseHeight);
    
    stroke(axisColor);
    line(xPos, yPos + responseHeight, xPos + scopeWidth, yPos + responseHeight);
    line(xPos, yPos, xPos, yPos + responseHeight);
    
    fill(0);
    textAlign(CENTER, CENTER);
    textSize(16);
    text("Summed Frequency Response", xPos + scopeWidth/2, yPos - 20);

    fill(100);
    textSize(10);
    textAlign(CENTER, TOP);
    for(int freq = 0; freq <= 1760; freq += freqLabelInterval) {
    float xLabel = map(freq, 0, 1760, xPos, xPos + scopeWidth);
    text(str(freq) + "Hz", xLabel, yPos + responseHeight + 2);
  }
  
  fill(0);
  textSize(12);
  textAlign(CENTER, CENTER);
  text("Frequency (Hz)", xPos + scopeWidth/2, yPos + responseHeight + xLabelOffset);

  pushMatrix();
  translate(xPos - yLabelOffset, yPos + responseHeight/2);
  rotate(-HALF_PI);
  text("Amplitude", 0, 0);
  popMatrix();

    if (!shapes.isEmpty()) {
      float[] bins = new float[353];
      float maxAmp = 0;
      
    synchronized (shapes) {
      for (Shape s : shapes) {
        float freq = s.freq;
        float amp = s.amp;
        int bin = (int)(freq/5);
        if (bin >= 0 && bin < bins.length) {
          bins[bin] += amp;
          maxAmp = max(maxAmp, bins[bin]);
        }
        
      }
    }

    stroke(lastColor);
    fill(lastColor);
    for (int i=0; i<bins.length; i++) {
      if(bins[i] > 0) {
        float freqCenter = i * 5 + 2.5;
        float xPosBin = map(freqCenter, 0, 1760, xPos, xPos + scopeWidth);
        float h = map(bins[i], 0, maxAmp, 0, responseHeight);
        rect(xPosBin - 1, yPos + responseHeight - h, 2, h);
      }
    }
  }
}

Shape getLatestShape() {
  return shapes.isEmpty() ? null : shapes.get(shapes.size()-1);
}


float calculateWaveValue(float t, float freq, String waveType) {
  float phase = t * (freq/100.0);
  switch(waveType) {
    case "Sine": return sin(phase);
    case "Square": return (sin(phase) > 0) ? 1.0 : -1.0;
    case "Triangle": return (2/PI) * asin(sin(phase));
    case "Sawtooth": return (phase % TWO_PI)/PI - 1.0;
    default: return sin(phase);
  }
}

String getWaveform(String category) {
  String lowerCat = category.toLowerCase();
  if (category.contains("triangle")) return "Triangle";
  if (category.contains("rect") || lowerCat.contains("square")) return "Square";
  if (category.contains("line")) return "Sawtooth";
  return "Sine";
}

void oscEvent(OscMessage msg) {
  if (msg.checkAddrPattern("/clearVisuals")) {
    synchronized (shapes) {
      shapes.clear();
      summedHistory.clear();
    }
  }
  if (msg.checkAddrPattern("/shapeContour")) {
    try {
      if (msg.arguments().length < 11) return;
      
      int numPoints = msg.get(10).intValue(); 
      if (numPoints < 0 || numPoints > 1000) return;
      
      int requiredArgs = 11 + (2 * numPoints);
      if (msg.arguments().length < requiredArgs) return;

      String category = msg.get(0).stringValue();
      x = msg.get(1).floatValue();
      y = msg.get(2).floatValue();
      float r = msg.get(5).floatValue();
      float g = msg.get(6).floatValue();
      float b = msg.get(7).floatValue();
      pressure = msg.get(8).floatValue();
      float total_length = msg.get(9).floatValue();
      float duration = total_length * 0.02;

      float[][] contour = new float[numPoints][2];
      int argIndex = 11;
      for (int i = 0; i < numPoints; i++) {
        contour[i][0] = msg.get(argIndex++).floatValue();
        contour[i][1] = msg.get(argIndex++).floatValue();
      }
      
      lastCategory = category.toLowerCase();
      lastColor = color(r * 255, g * 255, b * 255);
      String currentWaveType = getWaveform(category);
      
      float minFreq = 100;
      float maxFreq = 1760;
      freq = exp(log(minFreq) + (log(maxFreq) - log(minFreq)) * (1 - y));
      pan = x * 2 - 1;
      amp = pressure;

      synchronized (shapes) {
        shapes.add(new Shape(category, lastColor, contour, freq, amp, currentWaveType, duration));
        if (shapes.size() > 50) shapes.remove(0);
        newShapeAdded = true;
      }

    } catch (Exception e) {
      println("OSC Error: " + e);
    }
  }
  else if (msg.checkAddrPattern("/undo")) {
    synchronized (shapes) {
      if (!shapes.isEmpty()) shapes.remove(shapes.size()-1);
    }
  }
}
