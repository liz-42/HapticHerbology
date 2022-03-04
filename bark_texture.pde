/**
 **********************************************************************************************************************
 * @file       bark_texture.pde
 * @author     Elizabeth Reid, modified from hello wall by Steve Ding, Colin Gallacher
 * @version    V3.0.0
 * @date       03-Febuary-2022
 * @brief      Maze example adapted from Hello Wall
 **********************************************************************************************************************
 * @attention
 *
 *
 **********************************************************************************************************************
 */
 
  /* library imports *****************************************************************************************************/ 
import processing.serial.*;
import static java.util.concurrent.TimeUnit.*;
import java.util.concurrent.*;
/* end library imports *************************************************************************************************/  


/* scheduler definition ************************************************************************************************/ 
private final ScheduledExecutorService scheduler      = Executors.newScheduledThreadPool(1);
/* end scheduler definition ********************************************************************************************/ 



/* device block definitions ********************************************************************************************/
Board             haplyBoard;
Device            widgetOne;
Mechanisms        pantograph;

byte              widgetOneID                         = 5;
int               CW                                  = 0;
int               CCW                                 = 1;
boolean           renderingForce                     = false;
/* end device block definition *****************************************************************************************/



/* framerate definition ************************************************************************************************/
long              baseFrameRate                       = 120;
/* end framerate definition ********************************************************************************************/ 



/* elements definition *************************************************************************************************/

/* Screen and world setup parameters */
float             pixelsPerMeter                      = 4000.0;
float             radsPerDegree                       = 0.01745;

/* pantagraph link parameters in meters */
float             l                                   = 0.07;
float             L                                   = 0.09;


/* end effector radius in meters */
float             rEE                                 = 0.003;

/* virtual wall parameter  */
float             kWall                               = 100;
float             hWall                               = 0.015;
float             hWall2                              = 0.005;
PVector           fWall                               = new PVector(0, 0);
PVector           penWall                             = new PVector(0, 0);


Float[] posLine1 = {0.0, 0.05, 0.0, 0.07};
Float[] posLine2 = {-0.001, 0.038, -0.001, 0.05};
Float[] posLine3 = {0.015, 0.05, 0.015, 0.07};
Float[] posLine4 = {0.018, 0.045, 0.018, 0.06};
Float[] posLine5 = {0.019, 0.038, 0.019, 0.042};
Float[] posLine6 = {0.008, 0.038, 0.008, 0.06};
Float[] posLine7 = {-0.01, 0.038, -0.01, 0.06};
Float[] posLine8 = {-0.008, 0.06, -0.008, 0.08};
Float[] posLine9 = {0.026, 0.038, 0.026, 0.045};
Float[] posLine10 = {0.028, 0.045, 0.028, 0.055};
Float[] posLine11 = {0.03, 0.055, 0.03, 0.07};
Float[] posLine12 = {0.032, 0.07, 0.032, 0.1};
Float[] posLine13 = {0.03, 0.1, 0.03, 0.105};
Float[] posLine14 = {0.028, 0.105, 0.028, 0.12};
Float[] posLine15 = {0.026, 0.117, 0.026, 0.143};
Float[] posLine16 = {0.032, 0.13, 0.032, 0.143};
Float[] posLine17 = {0.032, 0.038, 0.032, 0.043};
Float[] posLine18 = {-0.015, 0.038, -0.015, 0.043};
Float[] posLine19 = {-0.018, 0.038, -0.018, 0.07};
Float[] posLine20 = {-0.019, 0.07, -0.019, 0.083};
Float[] posLine21 = {-0.018, 0.083, -0.018, 0.095};
Float[] posLine22 = {-0.017, 0.095, -0.017, 0.108};
Float[] posLine23 = {-0.019, 0.108, -0.019, 0.12};
Float[] posLine24 = {-0.018, 0.12, -0.018, 0.135};
Float[] posLine25 = {-0.017, 0.135, -0.017, 0.138};
Float[] posLine26 = {-0.016, 0.138, -0.016, 0.14};
Float[] posLine27 = {-0.015, 0.14, -0.015, 0.143};
Float[] posLine28 = {-0.014, 0.14, -0.014, 0.143};
Float[] posLine29 = {-0.023, 0.038, -0.023, 0.055};
Float[] posLine30 = {-0.023, 0.07, -0.023, 0.077};
Float[] posLine31 = {-0.024, 0.077, -0.024, 0.0955};
Float[] posLine32 = {-0.026, 0.0955, -0.026, 0.1};
Float[] posLine33 = {-0.027, 0.1, -0.027, 0.11};
Float[] posLine34 = {-0.029, 0.135, -0.029, 0.14};
Float[] posLine35 = {-0.028, 0.14, -0.028, 0.143};
Float[] posLine36 = {-0.027, 0.141, -0.027, 0.143};
Float[] posLine37 = {-0.025, 0.122, -0.025, 0.143};
Float[] posLine38 = {-0.024, 0.11, -0.024, 0.122};
Float[] posLine39 = {-0.013, 0.108, -0.013, 0.12};
Float[] posLine40 = {-0.013, 0.08, -0.013, 0.09};
Float[] posLine41 = {-0.01, 0.075, -0.01, 0.083};
Float[] posLine42 = {-0.008, 0.083, -0.008, 0.143};
Float[] posLine43 = {-0.007, 0.1, -0.007, 0.133};
Float[] posLine44 = {-0.007, 0.139, -0.007, 0.143};
Float[] posLine45 = {-0.006, 0.12, -0.006, 0.133};
Float[] posLine46 = {-0.005, 0.13, -0.005, 0.136};
Float[] posLine47 = {-0.007, 0.053, -0.007, 0.058};
Float[] posLine48 = {-0.018, 0.12, -0.018, 0.135};
Float[] posLine49 = {-0.03, 0.038, -0.03, 0.095};
Float[] posLine50 = {-0.028, 0.047, -0.028, 0.055};
Float[] posLine51 = {-0.026, 0.055, -0.026, 0.07};
Float[] posLine52 = {-0.023, 0.098, -0.023, 0.108};
Float[] posLine53 = {-0.032, 0.096, -0.032, 0.125};
Float[] posLine54 = {-0.035, 0.125, -0.035, 0.143};
Float[] posLine55 = {-0.036, 0.038, -0.036, 0.09};
Float[] posLine56 = {-0.035, 0.09, -0.035, 0.1};
Float[] posLine57 = {-0.036, 0.1, -0.036, 0.115};
Float[] posLine58 = {0.013, 0.038, 0.013, 0.042};
Float[] posLine59 = {0.012, 0.065, 0.012, 0.07};
Float[] posLine60 = {0.011, 0.071, 0.011, 0.077};
Float[] posLine61 = {0.012, 0.077, 0.012, 0.086};
Float[] posLine62 = {0.011, 0.086, 0.011, 0.102};
Float[] posLine63 = {0.013, 0.09, 0.013, 0.1205};
Float[] posLine64 = {0.015, 0.1205, 0.015, 0.125};
Float[] posLine65 = {0.016, 0.125, 0.016, 0.135};
Float[] posLine66 = {0.02, 0.137, 0.02, 0.143};
Float[] posLine67 = {0.018, 0.14, 0.018, 0.143};
Float[] posLine68 = {0.018, 0.13, 0.018, 0.134};
Float[] posLine69 = {0.02, 0.065, 0.02, 0.12};
Float[] posLine70 = {0.022, 0.097, 0.022, 0.115};
Float[] posLine71 = {0.022, 0.065, 0.022, 0.07};
Float[] posLine72 = {0.024, 0.055, 0.024, 0.065};
Float[] posLine73 = {0.026, 0.065, 0.026, 0.082};
Float[] posLine74 = {0.025, 0.082, 0.025, 0.086};
Float[] posLine75 = {0.026, 0.086, 0.026, 0.105};
Float[] posLine76 = {0.01, 0.127, 0.01, 0.134};
Float[] posLine77 = {0.009, 0.134, 0.009, 0.143};
Float[] posLine78 = {0.003, 0.07, 0.003, 0.1};
Float[] posLine79 = {0.002, 0.095, 0.002, 0.117};
Float[] posLine80 = {0.004, 0.103, 0.004, 0.117};
Float[] posLine81 = {0.0, 0.092, 0.0, 0.105};
Float[] posLine82 = {-0.002, 0.086, -0.002, 0.092};
Float[] posLine83 = {-0.003, 0.082, -0.003, 0.086};
Float[] posLine84 = {0.005, 0.118, 0.005, 0.125};
Float[] posLine85 = {0.004, 0.125, 0.004, 0.13};
Float[] posLine86 = {0.002, 0.131, 0.002, 0.14};
Float[] posLine87 = {0.003, 0.14, 0.003, 0.143};
Float[] posLine88 = {0.005, 0.065, 0.005, 0.07};
Float[] posLine89 = {0.006, 0.06, 0.006, 0.065};



Float[][] allLinePositions = {posLine1, posLine2, posLine3, posLine4, posLine5, posLine6, posLine7, posLine8, posLine9, posLine10, posLine11,
                              posLine12, posLine13, posLine14, posLine15, posLine16, posLine17, posLine18, posLine19, posLine20, posLine21,
                              posLine22, posLine23, posLine24, posLine25, posLine26, posLine27, posLine28, posLine29, posLine30, posLine31,
                              posLine32, posLine33, posLine34, posLine35, posLine36, posLine37, posLine38, posLine39, posLine40, posLine41,
                              posLine42, posLine43, posLine44, posLine45, posLine46, posLine47, posLine48, posLine49, posLine50, posLine51,
                              posLine52, posLine53, posLine54, posLine55, posLine56, posLine57, posLine58, posLine59, posLine60, posLine61,
                              posLine62, posLine63, posLine64, posLine65, posLine66, posLine67, posLine68, posLine69, posLine70, posLine71,
                              posLine72, posLine73, posLine74, posLine75, posLine76, posLine77, posLine78, posLine79, posLine80, posLine81,
                              posLine82, posLine83, posLine84, posLine85, posLine86, posLine87, posLine88, posLine89};
                              
                              
// horizontal lines for up and down texture
Float[] posHorLine1 = {-0.037, 0.04, 0.033, 0.04};
Float[] posHorLine2 = {-0.037, 0.05, 0.033, 0.05};
Float[] posHorLine3 = {-0.037, 0.06, 0.033, 0.06};
Float[] posHorLine4 = {-0.037, 0.07, 0.033, 0.07};
Float[] posHorLine5 = {-0.037, 0.08, 0.033, 0.08};
Float[] posHorLine6 = {-0.037, 0.09, 0.033, 0.09};
Float[] posHorLine7 = {-0.037, 0.1, 0.033, 0.1};
Float[] posHorLine8 = {-0.037, 0.11, 0.033, 0.11};
Float[] posHorLine9 = {-0.037, 0.12, 0.033, 0.12};
Float[] posHorLine10 = {-0.037, 0.13, 0.033, 0.13};
Float[] posHorLine11 = {-0.037, 0.14, 0.033, 0.14};

Float[][] allHorLinePositions = {posHorLine1, posHorLine2, posHorLine3, posHorLine4, posHorLine5, posHorLine6, posHorLine7, posHorLine8,
                                 posHorLine9, posHorLine10, posHorLine11};




/* generic data for a 2DOF device */
/* joint space */
PVector           angles                              = new PVector(0, 0);
PVector           torques                             = new PVector(0, 0);

/* task space */
PVector           posEE                               = new PVector(0, 0);
PVector           fEE                                 = new PVector(0, 0); 

/* device graphical position */
PVector           deviceOrigin                        = new PVector(0, 0);

/* World boundaries reference */
final int         worldPixelWidth                     = 1000;
final int         worldPixelHeight                    = 650;


/* graphical elements */
PShape pGraph, joint, endEffector;
PShape line1, line2, line3, line4, line5, line6, line7, line8, line9, line10, line11, line12, line13, line14, line15, line16;
PShape line17, line18, line19, line20, line21, line22, line23, line24, line25, line26, line27, line28, line29, line30, line31;
PShape line32, line33, line34, line35, line36, line37, line38, line39, line40, line41, line42, line43, line44, line45, line46;
PShape line47, line48, line49, line50, line51, line52, line53, line54, line55, line56, line57, line58, line59, line60, line61;
PShape line62, line63, line64, line65, line66, line67, line68, line69, line70, line71, line72, line73, line74, line75, line76;
PShape line77, line78, line79, line80, line81, line82, line83, line84, line85, line86, line87, line88, line89;


// all lines
PShape[] allLines = {line1, line2, line3, line4, line5, line6, line7, line8, line9, line10, line11, line12, line13, line14, line15, line16,
                     line17, line18, line19, line20, line21, line22, line23, line24, line25, line26, line27, line28, line29, line30, line31,
                     line32, line33, line34, line35, line36, line37, line38, line39, line40, line41, line42, line43, line44, line45, line46,
                     line47, line48, line49, line50, line51, line52, line53, line54, line55, line56, line57, line58, line59, line60, line61,
                     line62, line63, line64, line65, line66, line67, line68, line69, line70, line71, line72, line73, line74, line75, line76,
                     line77, line78, line79, line80, line81, line82, line83, line84, line85, line86, line87, line88, line89};
                     

// horizontal lines
PShape horLine1, horLine2, horLine3, horLine4, horLine5, horLine6, horLine7, horLine8, horLine9, horLine10, horLine11;

PShape[] allHorLines = {horLine1, horLine2, horLine3, horLine4, horLine5, horLine6, horLine7, horLine8, horLine9, horLine10, horLine11};

// background and other image
PImage bark_template;
PImage bark_detailed;


// states for testing
String state = "lines";


/* end elements definition *********************************************************************************************/ 



/* setup section *******************************************************************************************************/
void setup(){
  /* put setup code here, run once: */
  
  /* screen size definition */
  size(1000, 650);
  
  /* device setup */
  
  /**  
   * The board declaration needs to be changed depending on which USB serial port the Haply board is connected.
   * In the base example, a connection is setup to the first detected serial device, this parameter can be changed
   * to explicitly state the serial port will look like the following for different OS:
   *
   *      windows:      haplyBoard = new Board(this, "COM10", 0);
   *      linux:        haplyBoard = new Board(this, "/dev/ttyUSB0", 0);
   *      mac:          haplyBoard = new Board(this, "/dev/cu.usbmodem1411", 0);
   */ 
  haplyBoard          = new Board(this, "COM4", 0);
  widgetOne           = new Device(widgetOneID, haplyBoard);
  pantograph          = new Pantograph();
  
  widgetOne.set_mechanism(pantograph);
  
  widgetOne.add_actuator(1, CCW, 2);
  widgetOne.add_actuator(2, CW, 1);

  widgetOne.add_encoder(1, CCW, 241, 10752, 2);
  widgetOne.add_encoder(2, CW, -61, 10752, 1);
  
  widgetOne.device_set_parameters();
    
  
  /* visual elements setup */
  background(0);
  deviceOrigin.add(worldPixelWidth/2, 0);
  
  /* create pantagraph graphics */
  create_pantagraph();
  
  /* create wall graphics */
  create_line_graphics(allLines, allLinePositions);
  
  // create line graphics for horizontal lines
  create_hor_line_graphics(allHorLines, allHorLinePositions);
  
  
  /* setup framerate speed */
  frameRate(baseFrameRate);
  
  // load images
  bark_template = loadImage("oak_bark_black_and_white.jpg");
  bark_detailed = loadImage("oak_bark.jpg");
  
  
  /* setup simulation thread to run at 1kHz */ 
  SimulationThread st = new SimulationThread();
  scheduler.scheduleAtFixedRate(st, 1, 1, MILLISECONDS);
  
}
/* end setup section ***************************************************************************************************/



/* draw section ********************************************************************************************************/
void draw(){
  /* put graphical code here, runs repeatedly at defined framerate in setup, else default at 60fps: */
  if(renderingForce == false){
    background(152,190,100);
    update_animation(angles.x*radsPerDegree, angles.y*radsPerDegree, posEE.x, posEE.y);
  }
}
/* end draw section ****************************************************************************************************/



/* simulation section **************************************************************************************************/
class SimulationThread implements Runnable{
  
  public void run(){
    /* put haptic simulation code here, runs repeatedly at 1kHz as defined in setup */
    
    renderingForce = true;
    
    if(haplyBoard.data_available()){
      /* GET END-EFFECTOR STATE (TASK SPACE) */
      widgetOne.device_read_data();
    
      angles.set(widgetOne.get_device_angles()); 
      posEE.set(widgetOne.get_device_position(angles.array()));
      posEE.set(device_to_graphics(posEE)); 
      
      
      /* haptic wall force calculation */
      fWall.set(0, 0);
      
      
      float force_offset = 0; // to account for weakness when the end effector is perpendicular to the motors
      if ((posEE.x < -0.006 || posEE.x > 0.012) && posEE.y < 0.1) {
        force_offset = 0.02;
      }
      float height_offset = (posEE.y + rEE); // to account for the difference in force close and far from the motors

      penWall.set(1/(height_offset + force_offset), 0);
      
      float[][] line_endeffector_offsets = new float[allLinePositions.length][4];
      
      for (int i=0; i < allLinePositions.length; i++) {
        // x1 offset
        line_endeffector_offsets[i][0] = allLinePositions[i][0] - posEE.x;
        // y1 offset
        line_endeffector_offsets[i][1] = allLinePositions[i][1] - posEE.y; 
        // x2 offset
        line_endeffector_offsets[i][2] = allLinePositions[i][2] - posEE.x;
        // y2 offset
        line_endeffector_offsets[i][3] = allLinePositions[i][3] - posEE.y; 
      }
      
      
      PVector[] lineForces = new PVector[allLinePositions.length];
      for (int i=0; i < line_endeffector_offsets.length; i++) {
        lineForces[i] = calculate_line_force(line_endeffector_offsets[i], penWall);
      }
      
      
      // ensure only one vertical line can enact force upon the end effector at once
      for (int i=0; i < lineForces.length; i++) {
        if (lineForces[i].x != 0 || lineForces[i].y != 0) {
          fWall.add(lineForces[i]);
          break;
        }
      }
      
      // horizontal lines
      penWall.set(0, 10);
      
      float[][] hor_line_endeffector_offsets = new float[allHorLinePositions.length][4];
      
      for (int i=0; i < allHorLinePositions.length; i++) {
        // x1 offset
        hor_line_endeffector_offsets[i][0] = allHorLinePositions[i][0] - posEE.x;
        // y1 offset
        hor_line_endeffector_offsets[i][1] = allHorLinePositions[i][1] - posEE.y; 
        // x2 offset
        hor_line_endeffector_offsets[i][2] = allHorLinePositions[i][2] - posEE.x;
        // y2 offset
        hor_line_endeffector_offsets[i][3] = allHorLinePositions[i][3] - posEE.y; 
      }
      
      
      PVector[] horLineForces = new PVector[allHorLinePositions.length];
      for (int i=0; i < hor_line_endeffector_offsets.length; i++) {
        horLineForces[i] = calculate_line_force(hor_line_endeffector_offsets[i], penWall);
      }
      
      // ensure horizontal force is off when crossing vertical lines
      for (int i=0; i < horLineForces.length; i++) {
        if (fWall.x == 0) {
          fWall.add(horLineForces[i]);
        }
      }
      
      
      fEE = (fWall.copy()).mult(-1);
      fEE.set(graphics_to_device(fEE));
      /* end haptic wall force calculation */
    }
    
    
    torques.set(widgetOne.set_device_torques(fEE.array()));
    widgetOne.device_write_torques();
  
  
    renderingForce = false;
  }
}
/* end simulation section **********************************************************************************************/


/* helper functions section, place helper functions here ***************************************************************/

void create_line_graphics(PShape[] shapes, Float[][] positions) {
  for(int i=0; i < shapes.length; i++) {
    shapes[i] = create_wall(positions[i][0], positions[i][1], positions[i][2], positions[i][3]); 
    shapes[i].setStroke(color(150,0,0));
  }
}

void create_hor_line_graphics(PShape[] shapes, Float[][] positions) {
  for(int i=0; i < shapes.length; i++) {
    shapes[i] = create_wall(positions[i][0], positions[i][1], positions[i][2], positions[i][3]); 
    shapes[i].setStroke(color(0,0,150));
  }
}


void create_pantagraph(){
  float rEEAni = pixelsPerMeter * (rEE/2);
  
  fill(127,0,0);
  endEffector = createShape(ELLIPSE, deviceOrigin.x, deviceOrigin.y, 2*rEEAni, 2*rEEAni);
  endEffector.setStroke(color(0));
  strokeWeight(5);
  
}


PVector calculate_line_force(float[] offsets, PVector pen_wall) {
  PVector force = new PVector(0,0);
  if (offsets[0] < 0.002 && offsets[1] < 0.002 && offsets[2] > -0.002 && offsets[3] > -0.002) {
    // make sure the force is applied outward from the wall, whatever side we're on
    float wallForce = hWall; 
    if (offsets[2] < -0.001) {
      wallForce = -hWall;
    }
      force = force.add(pen_wall.mult(wallForce));
  }
  return force;
}


PShape create_wall(float x1, float y1, float x2, float y2){
  x1 = pixelsPerMeter * x1;
  y1 = pixelsPerMeter * y1;
  x2 = pixelsPerMeter * x2;
  y2 = pixelsPerMeter * y2;
  
  return createShape(LINE, deviceOrigin.x + x1, deviceOrigin.y + y1, deviceOrigin.x + x2, deviceOrigin.y+y2);
}


void update_animation(float th1, float th2, float xE, float yE){
  background(152,190,100);

  xE = pixelsPerMeter * xE;
  yE = pixelsPerMeter * yE;
  
  if (state == "lines") {
    for(int i=0; i < allLines.length; i++) {
      shape(allLines[i]);
    }
  }
  else if (state == "simple_image") {
    image(bark_template, 350, 150);
  }
  else if (state == "detailed_image") {
    image(bark_detailed, 350, 150);
  }
  
  
    //for(int i=0; i < allHorLines.length; i++) {
    //  shape(allHorLines[i]);
    //}
  
    translate(xE, yE);
    shape(endEffector);
}


PVector device_to_graphics(PVector deviceFrame){
  return deviceFrame.set(-deviceFrame.x, deviceFrame.y);
}


PVector graphics_to_device(PVector graphicsFrame){
  return graphicsFrame.set(-graphicsFrame.x, graphicsFrame.y);
}


// change state when any key pressed
void keyPressed() {
  if (keyCode == '1') {
    state = "lines";
  }
  else if (keyCode == '2') {
    state = "simple_image";
  }
  else if (keyCode == '3') {
    state = "detailed_image";
  }
}


/* end helper functions section ****************************************************************************************/




 
