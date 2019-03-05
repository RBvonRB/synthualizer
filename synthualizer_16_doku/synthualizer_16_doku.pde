import oscP5.*; //<>// //<>//
import netP5.*;
import ddf.minim.*;
import ddf.minim.ugens.*; 
import ddf.minim.effects.*; 
import com.hamoid.*;

VideoExport videoExport;
boolean recording = false;

Minim       minim;
AudioOutput out;
AudioOutput outMetr;
Oscil       wave;
Oscil       wave2;
Oscil       metronome;
BandPass    filt1;
BandPass    filt2;

PGraphics pg1;
PGraphics pg2;
PGraphics pg3;
PGraphics pg4;

float freq1;
float freq2;
int thresh = 8;
String tonGeschl = "maj";
String oktave = "2";
String[][] songName = {{"kids", "min"}, {"canon", "maj"}, {"sandstorm", "min"}, {"new1", "min"}};
String[] pitch = {"C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"};
String[] waveForm = {"Sinus", "Saw", "Square"};
String noteName1, noteName2;
int startPt = 0; //starting point in rel. to C, 0=C, 1=C#, 2=D...
int fps = 25;
float tempMin = 60;
float tempMax = 130;
int arp1No = 8;
float amp = 0.5;
float ampMax = 0.6;
boolean arp = false;
boolean metr = false;
boolean trig1 = false;
boolean trig2 = false;
boolean sustain = false;
boolean live = true;
boolean info = true;
boolean bassStep = false;
boolean bandOn;
int oct=1;
float rectSz = 40;
float rectRot = 0;
float rectPos;
int padVal1 = 1;
int padVal2 = 1;
int noteVal1;
int noteVal2;
int waveNo = 3;
int stepCntSeq = 1;
int step64 = 1;
int step32 = 1;
int step16 = 1;
int step8 = 1;
int step4 = 1;
int cnt64;
int cnt32;
int cnt16;
int cnt8;
int cnt4;
int trigXY1, ptrigXY1;
int muteStep;

int recCnt = 1;

int songNo;

float[] freqs = new float[12];
float[] notes = new float[thresh];
int[] steps = new int[thresh];
float[][] sequence = new float[32][2];
int subTri = 6;
float[] rotSpdSin = new float [thresh];
//x+y of smaller triangles  [top/bottom][triangle][point][x/y]
float[][][][] coordTri = new float [2][subTri][3][2];

float[] sinYrect = new float [thresh];
float[] posYrect = new float [thresh];
float[] heightYrect = new float [thresh];
float[] sinYsaw = new float [thresh];
float[] posYsaw = new float [thresh];

color clrSnd;
color colMaj;
color colMin;
float hue;
float sat;
float bright;

int[] arp1 = new int[arp1No];
int arpCnt = 0;
int stepCnt = 0;


void setup() {
  background(0);
  //size(960, 540);
  fullScreen();
  frameRate(fps);
  background(0);
  rectMode(CENTER);
  colorMode(HSB, 360, 100, 100);
  pg1 = createGraphics(290, 360);
  pg2 = createGraphics(290, 360);
  pg3 = createGraphics(290, 360);
  pg4 = createGraphics(290, 360);
  imageMode (CORNERS);


  colMaj = color(0, 70, 89);
  colMin = color(197, 69, 81);


  /* start oscP5, listening for incoming messages at port 8000 */
  oscP5 = new OscP5(this, 8000);




  minim = new Minim(this);
  // use the getLineOut method of the Minim object to get an AudioOutput object
  out = minim.getLineOut();
  outMetr = minim.getLineOut();


  filt1 = new BandPass(440, 20, out.sampleRate());
  filt2 = new BandPass(440, 20, out.sampleRate());


  // create a sine wave Oscil, set to 440 Hz, at 0.5 amplitude
  wave = new Oscil( 440, 0.5f, Waves.SINE );
  wave2 = new Oscil( 440, 0.5f, Waves.SINE );
  metronome = new Oscil( 1200, 1f, Waves.SAW );


  wave.patch(filt1).patch( out );
  wave2.patch(filt2).patch( out );
  metronome.patch( outMetr );

  bandOn = true;

  for (int i=0; i<thresh; i++) {
    float randValSin = random(-1, -.4);
    if (i%2==0) randValSin = abs(randValSin);
    rotSpdSin[i] = randValSin;
  }

  videoExport = new VideoExport(this, "screenCap" + recCnt + ".mp4");
  videoExport.startMovie();
}



void draw() {

  noCursor();
  blendMode(BLEND);

  if (tonGeschl == "maj") {
    steps[0] = 0;
    steps[1] = 2;
    steps[2] = 4;
    steps[3] = 5;
    steps[4] = 7;
    steps[5] = 9;
    steps[6] = 11;
    steps[7] = 12;
    hue = hue(colMaj);
    sat = saturation(colMaj);
    bright = brightness(colMaj);
  } else if (tonGeschl == "min") {
    steps[0] = 0;
    steps[1] = 2;
    steps[2] = 3;
    steps[3] = 5;
    steps[4] = 7;
    steps[5] = 8;
    steps[6] = 10;
    steps[7] = 12;
    hue = hue(colMin);
    sat = saturation(colMin);
    bright = brightness(colMin);
  }

  if (xyPadStrip[1]==1) {
    if (tonGeschl=="maj") {
      sat = map(xPad, 0, 1, saturation(colMaj), 0);
      bright = map(yPad, 0, 1, 100, brightness(colMaj));
    } else if (tonGeschl=="min") {
      sat = map(xPad, 0, 1, saturation(colMin), 0);
      bright = map(yPad, 0, 1, 100, brightness(colMin));
    }
  } else {
    if (tonGeschl=="maj") {
      sat = saturation(colMaj);
      bright = brightness(colMaj);
    } else if (tonGeschl=="min") {
      sat = saturation(colMin);
      bright = brightness(colMin);
    }
  }

  clrSnd = color(hue, sat, bright);

  background (clrSnd);


  int[] notePad1 = subset(square4, 1, thresh);
  int[] notePad2 = subset(square4, thresh+1, thresh);
  int[] songPad = subset(square8[1], 1, songs.length);

  //square8[spalte][zeile];
  if (arrSum(songPad)>0) {
    live=false;
    for (int j=0; j<=songs.length; j++) {
      if (square8[1][j] ==1) {
        songNo=j-1;
      }
    }
  } else {
    live=true;
  }

  if (sliderStrip[1] ==1) info = true;
  else info = false;
  if (sliderStrip[2] ==1) metr = true;
  else metr = false;

  if (arrSum(notePad1)>0) trig1 = true;
  else trig1 = false;
  if (arrSum(notePad2)>0) trig2 = true;
  else trig2 = false;

  amp = map(fader[1], 0, 1, 0, ampMax);


  if (square4strip[3]>0 || live == false) {
    sustain = true;
  } else {
    sustain =false;
  }


  if (sustain==false) {
    if (trig1 == false) wave.setAmplitude( 0 );
    else wave.setAmplitude( amp );
    if (trig2 == false) wave2.setAmplitude( 0 );
    else wave2.setAmplitude( amp );
  } else {
    wave.setAmplitude( amp );
    wave2.setAmplitude( amp );
  }

  muteStep=4;
  if (square4strip[4]==1) {
    if (cnt32%muteStep==0) {
      wave2.setAmplitude( 0 );
    }
  }

  if (metr) {
    if (cnt32%16==0) {
      metronome.setAmplitude( .1 );
    } else {
      metronome.setAmplitude( 0 );
    }
  } else {
    metronome.setAmplitude( 0 );
  }

  if (square4strip[2]==1) {
    bassStep=true;
  } else {
    bassStep=false;
  }

  if (square4strip[1] == 1) 
    arp = true;
  else if (square4strip[1] == 0)
    arp = false;

  int oktaveInt = constrain(floor(map(fader[3], 0, 1, 2, 6)), 2, 5);
  oktave = str(oktaveInt);


  //----------------------------FILTER----------------------------

  trigXY1 = 1-xyPadStrip[1];
  if (trigXY1!=ptrigXY1) {
    bandSwapper();
    ptrigXY1 = trigXY1;
  }

  float passBand = map(xPad, 0, 1, 200, 1600);
  filt1.setFreq(passBand);
  filt2.setFreq(passBand);
  float bandWidth = map(yPad, 0, 1, 200, 500);
  filt1.setBandWidth(bandWidth);
  filt2.setBandWidth(bandWidth);


  for (int i=0; i<freqs.length; i++) {
    freqs[i] = Frequency.ofPitch(pitch[i] + oktave ).asHz();
  }

  if (live) {
    if (sliderStrip[4]>0) {
      tonGeschl = "maj";
    } else {
      tonGeschl = "min";
    }
  } else {
    tonGeschl = songName[songNo][1];
  }

  startPt = floor(map(fader[4], 0, 1, 0, 11));
  if (startPt<0) startPt = 0;

  float bpm = map(fader[5], 0, 1, tempMin, tempMax);
  oct = 1;

  //println(wave.getLastValues()[0]);
  //println(wave2.getLastValues()[0]);
  //---------------------------------TIMER---------------------------

  float bpf = bpm/(60*fps);


  cnt64 = floor(frameCount*(bpf*32));
  cnt32 = floor(cnt64/2);
  cnt16 = floor(cnt32/4);
  cnt8 = floor(cnt32/8);
  cnt4 = floor(cnt32/16);

  step32 = (cnt32%32)+1;
  step16 = (cnt16%16)+1;
  step8 = (cnt8%8)+1;
  step4  = (cnt4%4)+1;


  arpCnt = cnt16%arp1.length;

  stepCntSeq = cnt8%songs[songNo].length;


  //---------------------------------ARPEGGIO---------------------------


  for (int i = 0; i<arp1.length; i++) {
    if (arp==false) {
      arp1[i] = 0;
    } else {
      arp1[0] = 0;
      arp1[1] = 1;
      arp1[2] = 2;
      arp1[3] = 3;
      arp1[4] = 2;
      arp1[5] = 0;
      arp1[6] = 2;
      arp1[7] = 1;
    }
  }

  //---------------------------------NOTE-GENERATOR---------------------------

  for (int j = 0; j<notes.length; j++) {
    if (startPt+steps[j]<freqs.length) {
      notes[j]=freqs[startPt+steps[j]];
    } else {
      notes[j]=freqs[startPt+steps[j]-12]*2;
    }
  }


  if (live) {
    for (int i=0; i<square4.length; i++) {
      if (square4[i]>0) {
        if (i<=thresh) {
          padVal1 = i;
        } else {
          padVal2 = i-thresh;
        }
      }
    }
  } else {
    padVal1 = songs[songNo][stepCntSeq][0];
    padVal2 = songs[songNo][stepCntSeq][1];
  }


  if (padVal1>thresh) {
    padVal1 -= thresh-1;
  }
  if (padVal2>thresh) {
    padVal2 -= thresh-1;
    oct += 1;
  }


  freq1 = notes[padVal1-1];
  freq2 = notes[padVal2-1]*pow(2, oct)*pow(2, arp1[arpCnt]);


  noteVal1 = startPt+(steps[padVal1-1]);
  noteVal1 = startPt+(steps[padVal1-1]);

  noteVal2 = startPt+(steps[padVal2-1]);

  if (noteVal1<pitch.length) {
    noteName1 = pitch[noteVal1];
  } else {
    noteName1 = pitch[noteVal1 - pitch.length];
  }

  if (noteVal2<pitch.length) {
    noteName2 = pitch[noteVal2];
  } else {
    noteName2 = pitch[noteVal2 - pitch.length];
  }


  wave.setFrequency( freq1 );
  wave2.setFrequency( freq2 );

  waveNo = constrain(floor(map(fader[2], 0, 1, 1, 4)), 1, 3);

  if (waveNo == 1) {
    wave.setWaveform( Waves.SINE );
    wave2.setWaveform( Waves.SINE );
  } else if (waveNo == 2) {
    wave.setWaveform( Waves.SAW );
    wave2.setWaveform( Waves.SAW );
  } else if (waveNo == 3) {
    wave.setWaveform( Waves.SQUARE );
    wave2.setWaveform( Waves.SQUARE );
  }

  //-------------------------AUDIOVIZ----------------------------

  float strkW = map(amp, 0, ampMax, 3, 6);
  color fillBlk = color(0, 0, 0);
  color strkBlk = color(0, 0, 0);


  strokeWeight(strkW);
  stroke(strkBlk);
  strokeJoin(ROUND);

  //fill(clrSnd);





  //------------------------------------sine------------------------------------
  if (waveNo == 1) {
    float crcSz = 60;
    float distInner = 1.7*crcSz;
    float speedAll = map(fader[5], 0, 1, .005, .02);

    pushMatrix();
    translate(width/2, height/2);
    fill(clrSnd);


    stroke(strkBlk);
    ellipse(0, 0, padVal1*2*distInner, padVal1*2*distInner);


    for (int j=0; j<thresh; j++) {
      rotate(frameCount*speedAll*rotSpdSin[j]);
      for (int i=0; i<thresh; i++) {


        //bass
        if (j==padVal1-1 && i==j) {
          fill(fillBlk);
          stroke(strkBlk);
        } else {
          noFill();
          noStroke();
        }

        //melodie
        if (j==padVal2-1) {
          if (arp) {
            int rand = floor(random(thresh));
            if (rand==i) {
              stroke(strkBlk);
              //  strokeWeight(strkW);
            } else {
              noStroke();
            }
          } else {
            //    strokeWeight(strkW);
            stroke(strkBlk);
          }
        } else {
          if (i==j) {
            //    strokeWeight(strkW);
            stroke(strkBlk);
          } else {
            noStroke();
          }
        }
        pushMatrix();
        rotate(radians(360*i/thresh));        
        ellipse(0, -distInner*(j+1), crcSz, crcSz);
        popMatrix();
      }
    }

    popMatrix();
  } 
  //------------------------------------saw------------------------------------
  else if (waveNo == 2) {


    float margin = 30;
    float triWdth = (width-margin)/4;
    float speedWiggleSaw = map(fader[5], 0, 1, .05, .1);

    float yWiggle = map(sin(frameCount*speedWiggleSaw), -1, 1, 0, 80);
    float x1top = margin;
    float x2top = triWdth-margin;
    float x3top = margin;
    float y1top = margin;
    float y2top = margin;
    float y3top = height-margin-yWiggle;
    float x1bot = triWdth-margin;
    float x2bot = margin;
    float x3bot = triWdth-margin;
    float y1bot = height-margin;
    float y2bot = height-margin;
    float y3bot = margin+yWiggle;


    float midXtop = (x1top+x2top+x3top)/3;
    float midYtop = (y1top+y2top+y3top)/3;
    float midXbot = (x1bot+x2bot+x3bot)/3;
    float midYbot = (y1bot+y2bot+y3bot)/3;





    for (int i=0; i<subTri; i++) {
      float interpol = i*(1.0/subTri);
      coordTri[0][i][0][0] = lerp(x1top, midXtop, interpol);
      coordTri[0][i][0][1] = lerp(y1top, midYtop, interpol);
      coordTri[0][i][1][0] = lerp(x2top, midXtop, interpol);
      coordTri[0][i][1][1] = lerp(y2top, midYtop, interpol);
      coordTri[0][i][2][0] = lerp(x3top, midXtop, interpol);
      coordTri[0][i][2][1] = lerp(y3top, midYtop, interpol);
      coordTri[1][i][0][0] = lerp(x1bot, midXbot, interpol);
      coordTri[1][i][0][1] = lerp(y1bot, midYbot, interpol);
      coordTri[1][i][1][0] = lerp(x2bot, midXbot, interpol);
      coordTri[1][i][1][1] = lerp(y2bot, midYbot, interpol);
      coordTri[1][i][2][0] = lerp(x3bot, midXbot, interpol);
      coordTri[1][i][2][1] = lerp(y3bot, midYbot, interpol);
    }

    for (int i=0; i<thresh; i++) {

      if (padVal1!=padVal2) {
        if (padVal1-1==i) {
          fill(fillBlk);
        } else {
          noFill();
        }
      } else {
        noFill();
      }

      if (i%2==0) {
        //draw top triangles
        stroke(strkBlk);
        pushMatrix();
        translate(triWdth*(i/2), 0);
        triangle(x1top, y1top, x2top, y2top, x3top, y3top);

        //draw sub triangles
        if (padVal2-1==i) {
          for (int l=0; l<subTri; l++) {
            if (arp) {
              int randSub = floor(random(subTri));
              if (padVal2!=padVal1) {
                if (randSub==l) {
                  stroke(strkBlk);
                } else {
                  noStroke();
                }
              } else {
                if (randSub==l) {
                  stroke(strkBlk);
                  fill(fillBlk);
                } else {
                  noStroke();
                  noFill();
                }
              }
            } else {
              stroke (strkBlk);
              if (padVal2==padVal1) {
                if (l%2==0) {
                  fill(fillBlk);
                } else {
                  fill(clrSnd);
                }
              }
            }
            beginShape();
            vertex(coordTri[0][l][0][0], coordTri[0][l][0][1]);
            vertex(coordTri[0][l][1][0], coordTri[0][l][1][1]);
            vertex(coordTri[0][l][2][0], coordTri[0][l][2][1]);
            vertex(coordTri[0][l][0][0], coordTri[0][l][0][1]);
            endShape();
          }
        }

        popMatrix();
      } else {
        //draw bottom triangles
        stroke(strkBlk);
        pushMatrix();
        translate(triWdth*(i/2)+margin, 0);
        triangle(x1bot, y1bot, x2bot, y2bot, x3bot, y3bot);

        //draw sub triangles
        if (padVal2-1==i) {
          for (int l=0; l<subTri; l++) {
            if (arp) {
              int randSub = floor(random(subTri));
              if (padVal2!=padVal1) {
                if (randSub==l) {
                  stroke(strkBlk);
                } else {
                  noStroke();
                }
              } else {
                if (randSub==l) {
                  stroke(strkBlk);
                  fill(fillBlk);
                } else {
                  noStroke();
                  noFill();
                }
              }
            } else {
              stroke (strkBlk);
              if (padVal2==padVal1) {
                if (l%2==0) {
                  fill(fillBlk);
                } else {
                  fill(clrSnd);
                }
              }
            }
            beginShape();
            vertex(coordTri[1][l][0][0], coordTri[1][l][0][1]);
            vertex(coordTri[1][l][1][0], coordTri[1][l][1][1]);
            vertex(coordTri[1][l][2][0], coordTri[1][l][2][1]);
            vertex(coordTri[1][l][0][0], coordTri[1][l][0][1]);
            endShape();
          }
        }

        popMatrix();
      }
    }
  }
  //------------------------------------square------------------------------------
  else if (waveNo == 3) {

    float sqWidth = width*.06; 
    float margin = 90; 
    float speedWiggle = map(fader[5], 0, 1, .05, .2); 
    float wiggleAmp = 50; 
    float heightAmp = 2; 
    int clones = 6; 

    float distX = (width-2*margin)/(thresh-1); 
    float posX; 

    for (int i=0; i<posYrect.length; i++) { 
      sinYrect[i] = sin(frameCount*speedWiggle+i); 
      //posYrect[i] = map(sinYrect[i], -1, 1, -wiggleAmp, wiggleAmp);
      posYrect[i] = 0; 
      heightYrect[i] = map(sinYrect[i], -1, 1, 1, 2);
    }

    float distClones = sqWidth*2; 


    pushMatrix(); 
    translate(0, height/2); 
    for (int i=0; i<thresh; i++) {

      stroke(strkBlk); 
      strokeWeight(strkW); 
      posX = margin+i*distX; 
      if (i==padVal1-1) fill(fillBlk); 
      else fill(clrSnd); 
      rect(posX, posYrect[i], sqWidth, sqWidth*heightYrect[i]); 
      if (i==padVal2-1) {
        noFill(); 
        for (int j=-clones; j<clones; j++) {
          if (arp) {
            int rand = floor(random(-clones, clones)); 
            if (rand==j || j==0) {
              stroke(strkBlk); 
              strokeWeight(strkW);
            } else {
              noStroke();
            }
          }
          rect(posX, posYrect[i]+j*(distClones*heightYrect[i]*.6), sqWidth, sqWidth*heightYrect[i]);
        }
      }
    }
    popMatrix();
  }



  //------------------------------------info------------------------------------
  if (info) {
    //WAVE
    blendMode(DIFFERENCE); 
    noFill(); 
    stroke(0, 0, 100); 
    strokeWeight(5); 
    float waveAmp = 200; 
    pushMatrix(); 
    translate(0, height/2); 
    for (int i = 0; i < out.bufferSize() - 1; i++) {
      int iMapped = floor(map(i, 0, out.bufferSize(), 0, width)); 
      line( iMapped, - out.left.get(i)*waveAmp, iMapped+1, - out.left.get(i+1)*waveAmp );
    }
    popMatrix(); 


    blendMode(BLEND); 
    noStroke(); 
    fill(0, 0, 0); 
    rect(0, 0, 360, 360); 
    textSize(14); 
    fill(0, 0, 100); 
    text(nf(bpm, 3, 2) + " bpm"
      + "\n" + "key: " + pitch[startPt]+ tonGeschl
      + "\n" + "note1: " + noteName1+ oktave + " note2: " + noteName2 + oktave
      //+ "\n" + "noteVal1: " + noteVal1
      //  + "\n" + "oct: " + oct
      //+ "\n" + "passBand: " + nf(passBand, 5, 1) + " bandWidth: " + nf(bandWidth, 5, 1)
      + "\n" + "waveform: " + waveForm[waveNo-1]
      + "\n" + "viertel: " + step4
      + "\n" + "filter: " + bandOn
      //+ "\n" + "achtel: " + step8
      //+ "\n" + "sechszehntel: " + step16
      //+ "\n" + "zweinddreissigstel: " + step32
      //  + "\n" + "stepCntSeq: " + stepCntSeq
      // + "\n" + "arp: " + arp  
      + "\n" + "live: " + live 
      , 15, 20);
  }




  //-------------------------interface----------------------


  if (sliderNeedsRedraw == true) redrawSliders(); 
  if (square4NeedsRedraw == true) redrawSquare4(); 
  if (xyPadNeedsRedraw == true) redrawxyPad(); // only redraw the screen if we need to
  if (square8NeedsRedraw == true) redrawSquare8(); // only redraw the screen if we need to

  if (info) {
    float sc = .7; 
    float dist = pg1.width*sc; 
    image(pg1, 0, height, pg1.width*sc, height-pg1.height*sc); 
    image(pg2, dist*1, height, dist*1+pg1.width*sc, height-pg1.height*sc); 
    image(pg3, dist*2, height, dist*2+pg1.width*sc, height-pg1.height*sc); 
    image(pg4, dist*3, height, dist*3+pg1.width*sc, height-pg1.height*sc);
  }

  if (recording) {
    videoExport.saveFrame();
  }
}

float arrSum(int[] arr) {
  float sum = arr[0]; 
  for (int i = 1; i < arr.length; i++) {
    sum +=arr[i];
  }
  return sum;
}



void bandSwapper() {
  if (bandOn) {
    wave.unpatch(filt1); 
    wave2.unpatch(filt2); 
    wave.patch(out); 
    wave2.patch(out); 
    bandOn = false;
  } else {
    wave.unpatch(out); 
    wave2.unpatch(out); 
    wave.patch(filt1); 
    wave2.patch(filt2); 
    bandOn = true;
  }
}

void keyPressed() {
  if (key == 'r' || key == 'R') {
    recording = !recording;
    println("Recording is " + (recording ? "ON" : "OFF"));
  }
  if (key == 'q') {
    videoExport.endMovie();
    recCnt ++;
    //   exit();
  }
}
