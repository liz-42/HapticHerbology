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
long              baseFrameRate                       = 180;
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
// for grey lines
PVector           penWallGrey                         = new PVector(0, 0);

// for right image
ArrayList<Integer[]> allLinePositions = new ArrayList<Integer[]>();
// for left image
ArrayList<Integer[]> allLinePositions_left = new ArrayList<Integer[]>();
ArrayList<Integer[]> allLinePositions_left_grey = new ArrayList<Integer[]>();

// for horizontal lines
ArrayList<Integer[]> allHorLinePositions = new ArrayList<Integer[]>();
                              
                              
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

//Float[][] allHorLinePositions = {posHorLine1, posHorLine2, posHorLine3, posHorLine4, posHorLine5, posHorLine6, posHorLine7, posHorLine8,
//                                 posHorLine9, posHorLine10, posHorLine11};


/* generic data for a 2DOF device */
/* joint space */
PVector           angles                              = new PVector(0, 0);
PVector           torques                             = new PVector(0, 0);

/* task space */
PVector           posEE                               = new PVector(0, 0);
PVector           fEE                                 = new PVector(0, 0); 

PVector posCursor = new PVector(-1,-1);
PVector newPos = new PVector(0,0);

/* device graphical position */
PVector           deviceOrigin                        = new PVector(0, 0);

/* World boundaries reference */
final int         worldPixelWidth                     = 650; //1000;
final int         worldPixelHeight                    = 584; //650;


/* graphical elements */
PShape pGraph, joint, endEffector;


// all lines
ArrayList<PShape> allLines = new ArrayList<PShape>();

// lines for left image
ArrayList<PShape> allLines_left = new ArrayList<PShape>();
ArrayList<PShape> allLines_left_grey = new ArrayList<PShape>();

// horizontal lines
ArrayList<PShape> allHorLines = new ArrayList<PShape>();


                     

// horizontal lines
//PShape horLine1, horLine2, horLine3, horLine4, horLine5, horLine6, horLine7, horLine8, horLine9, horLine10, horLine11;

//PShape[] allHorLines = {horLine1, horLine2, horLine3, horLine4, horLine5, horLine6, horLine7, horLine8, horLine9, horLine10, horLine11};

// background and other image
PImage bark_template;
PImage bark_detailed;
PImage bark_BAW;
PImage bark_GREY;

PImage temp_image;
PImage left_image;
int left_image_margin_x = 20;
int left_image_margin_y = 80;

PImage right_image;
int right_image_margin_x = left_image_margin_x + 40;
int right_image_margin_y = left_image_margin_y;

// colour versions
PImage left_image_colour;
PImage right_image_colour;


PShape[] right_image_lines = {};


int screen_width = 650;
int screen_height = 584;
// states for testing
//String state = "lines";
String state = "simple_image";
String renderTechnique = "";

float[][] kernel = {{ -1, -1, -1}, 
                    { -1,  9, -1}, 
                    { -1, -1, -1}};

                    
float v = 1.0 / 9.0;
float[][] kernel_blur = {{ v, v, v }, 
                         { v, v, v }, 
                         { v, v, v }};
/* end elements definition *********************************************************************************************/ 



/* setup section *******************************************************************************************************/
void setup(){
  /* put setup code here, run once: */
  
  /* screen size definition */
  size(650, 584);
  
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
  background(125);
  deviceOrigin.add(worldPixelWidth/2, 0);
  
   /* create pantagraph graphics */
   create_pantagraph();
  
   /* create wall graphics */
   //create_line_graphics(allLines, allLinePositions);
  
   // create line graphics for horizontal lines
   //create_hor_line_graphics(allHorLines, allHorLinePositions);

  // load images
  // bark_template = loadImage("oak_bark_black_and_white.jpg");
  // bark_detailed = loadImage("oak_bark.jpg");
  // bark_template = loadImage("oak_bark_black_and_white.jpg");
  left_image = loadImage("oak_bark.jpg");
  left_image.filter(THRESHOLD);
  right_image = loadImage("oak_bark.jpg");
  right_image.filter(THRESHOLD);
  // temp_image = createImage(left_image.width, left_image.height, RGB);
  // right_image = createImage(left_image.width, left_image.height, RGB);
  
  // colour version - left image
  left_image_colour = loadImage("oak_bark.jpg");
  
  // original images
  right_image_margin_x += left_image.width;

  image(left_image, left_image_margin_x, left_image_margin_y);
  image(right_image, right_image_margin_x, right_image_margin_y);
  
  // colour version - right image
  right_image_colour = loadImage("oak_bark.jpg");

  left_image.loadPixels();
  // temp_image.loadPixels();
  right_image.loadPixels();

  textSize(48);
  text("Image #1", left_image_margin_x, left_image_margin_y * 2 / 3);
  text("Image #2", right_image_margin_x, right_image_margin_y * 2 / 3);

  textSize(24);
  text("This image tracks position", left_image_margin_x, left_image_margin_y + left_image.height + 40);
  text("This image has pre-lines", right_image_margin_x, right_image_margin_y + right_image.height + 40);
  

  // Read image vertically
  // Create lines accordingly
  // right image
  int black = 0;
  int startJ = 0;
  int lines = 0;
  
  for (int i = 0; i < right_image.width; i++) {
    //println("line", i);
    for (int j = 0; j < right_image.height; j++) {
      float pixel = red(right_image.pixels[i + j * right_image.width]);

      if(pixel < 10){
        if(black == 0){
          startJ = j;
        }
        black++;
      }
      if(pixel >= 5 || j == right_image.height-1){
        if(black >= 10){
          lines++;
          Integer[] curLinePos = {right_image_margin_x + i, right_image_margin_y + startJ, right_image_margin_x + i, right_image_margin_y + j - 1};
          PShape temp = createShape(LINE, right_image_margin_x + i, right_image_margin_y + startJ, right_image_margin_x + i, right_image_margin_y + j - 1);
          //println(curLinePos);
          temp.setStroke(color(0,0,150));
          
          // add to list
          allLinePositions.add(curLinePos);
          allLines.add(temp);
          //shape(temp);
        }
          black = 0;
      }
    
    }
    //println("lines :", lines);
    black = 0;
    lines = 0;
   }
   
   // left image
   black = 0;
   startJ = 0;
   lines = 0;
  
   for (int i = 0; i < left_image.width; i++) {
     //println("line", i);
     for (int j = 0; j < left_image.height; j++) {
       float pixel = red(left_image.pixels[i + j * left_image.width]);

       if(pixel < 10){
         if(black == 0){
           startJ = j;
         }
         black++;
       }
       if(pixel >= 5 || j == left_image.height-1){
         
         if ((black >= 3) && (black < 10)){
           lines++;
           Integer[] curLinePos = {left_image_margin_x + i, left_image_margin_y + startJ, left_image_margin_x + i, left_image_margin_y + j - 1};
           PShape temp = createShape(LINE, left_image_margin_x + i, left_image_margin_y + startJ, left_image_margin_x + i, left_image_margin_y + j - 1);
           //println(curLinePos);
           temp.setStroke(color(0,150,150));
          
           // add to list
           allLinePositions_left_grey.add(curLinePos);
           allLines_left_grey.add(temp);
         }
         else if(black >= 10){
           lines++;
           Integer[] curLinePos = {left_image_margin_x + i, left_image_margin_y + startJ, left_image_margin_x + i, left_image_margin_y + j - 1};
           PShape temp = createShape(LINE, left_image_margin_x + i, left_image_margin_y + startJ, left_image_margin_x + i, left_image_margin_y + j - 1);
           //println(curLinePos);
           temp.setStroke(color(0,0,150));
          
           // add to list
           allLinePositions_left.add(curLinePos);
           allLines_left.add(temp);
           //shape(temp);
         }
           black = 0;
       }
    
     }
     //println("lines :", lines);
     black = 0;
     lines = 0;
   }
   
   // create horizontal lines for right image
   for (int j = 0; j < left_image.height; j=j+20) {
     Integer[] curLinePos = {right_image_margin_x, right_image_margin_y + j, right_image_margin_x + right_image.width, right_image_margin_y + j};
     PShape temp = createShape(LINE, right_image_margin_x, right_image_margin_y + j, right_image_margin_x + right_image.width, right_image_margin_y + j);
     //println(curLinePos);
     temp.setStroke(color(0,0,150));
          
     // add to list
     allHorLinePositions.add(curLinePos);
     allHorLines.add(temp);
   }
   
   
   
   
   // for testing 
    //ArrayList<PShape> tempList = new ArrayList<PShape>();
    //tempList.add(allLines.get(0));
    //tempList.add(allLines.get(200));
    //tempList.add(allLines.get(400));
    
    //allLines = tempList;
    
    
    //ArrayList<Integer[]> tempList2 = new ArrayList<Integer[]>();
    //tempList2.add(allLinePositions.get(0));
    //tempList2.add(allLinePositions.get(200));
    //tempList2.add(allLinePositions.get(400));
    //allLinePositions = tempList2;
    
    //println(allLinePositions.get(0));


  /* setup framerate speed */
  frameRate(baseFrameRate);
  
  /* setup simulation thread to run at 1kHz */ 
  SimulationThread st = new SimulationThread();
  scheduler.scheduleAtFixedRate(st, 1, 1, MILLISECONDS);
  
}
/* end setup section ***************************************************************************************************/

/* draw section ********************************************************************************************************/
void draw(){
  /* put graphical code here, runs repeatedly at defined framerate in setup, else default at 60fps: */
  if (renderingForce == false){
    // background(152,190,100);
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
      
      
      //println(posEE.x, posEE.y);
      
      float force_offset = 0.005 + abs(posEE.x)*1.5; // to account for weakness when the end effector is perpendicular to the motors
      //if ((posEE.x < -0.006 || (posEE.x > 0.012 && posEE.x < 0.02))) {
      //  force_offset = 0.02;
      //}
      if (( posEE.x > 0.02) || (posEE.x < -0.02)) {
        force_offset = force_offset + 0.01;
      }
      else if ((( posEE.x < 0.02) && (posEE.x > -0.02)) && posEE.y < 0.05){
        force_offset = force_offset + 0.005;
      }
      else if ((( posEE.x < 0.02) && (posEE.x > -0.02)) && posEE.y >= 0.05){
        force_offset = force_offset + 0.02;
      }
      float height_offset = (posEE.y + rEE)/1.75; // to account for the difference in force close and far from the motors
      
      // adjustments to height offset
      if (posEE.y < 0.03) {
        height_offset = height_offset + 0.05;
      }

      penWall.set(1/(height_offset + force_offset), 0);
      
      
      // no need to calculate everything at once - it introduces lag
      
      if (posEE.x > 0) { // right image
      
      
        float[][] line_endeffector_offsets = new float[allLinePositions.size()][4];
      
        for (int i=0; i < allLinePositions.size(); i++) {
          // x1 offset
          line_endeffector_offsets[i][0] = allLinePositions.get(i)[0] - (posEE.x*4000.0 + right_image.width);
          // y1 offset
          line_endeffector_offsets[i][1] = allLinePositions.get(i)[1] - (posEE.y*4000.0); 
          // x2 offset
          line_endeffector_offsets[i][2] = allLinePositions.get(i)[2] - (posEE.x*4000.0 + right_image.width);
          // y2 offset
          line_endeffector_offsets[i][3] = allLinePositions.get(i)[3] - (posEE.y*4000.0); 
        }
      
      
      
      
        PVector[] lineForces = new PVector[allLinePositions.size()];
        for (int i=0; i < line_endeffector_offsets.length; i++) {
          lineForces[i] = calculate_line_force(line_endeffector_offsets[i], penWall, 1);
        }
      
      
        // ensure only one vertical line can enact force upon the end effector at once
        for (int i=0; i < lineForces.length; i++) {
          if (lineForces[i].x != 0 || lineForces[i].y != 0) {
            fWall.add(lineForces[i]);
            break;
          }
        }
      }
      else { // left image
      
      
        // force offsets for grey lines
        float force_offset_grey = 0.005 + abs(posEE.x)*1.5; // to account for weakness when the end effector is perpendicular to the motors
        if (( posEE.x > 0.02) || (posEE.x < -0.02)) {
          force_offset_grey = force_offset_grey + 0.01;
        }
        else if ((( posEE.x < 0.02) && (posEE.x > -0.02)) && posEE.y < 0.05){
          force_offset_grey = force_offset_grey + 0.02;
        }
        else if ((( posEE.x < 0.02) && (posEE.x > -0.02)) && posEE.y >= 0.05){
          force_offset_grey = force_offset_grey + 0.03;
        }
        float height_offset_grey = (posEE.y + rEE)/1.75; // to account for the difference in force close and far from the motors
      
        // adjustments to height offset
        if (posEE.y < 0.03) {
          height_offset_grey = height_offset_grey + 0.05;
        }

        penWallGrey.set(0, 1/((height_offset_grey + force_offset_grey)*3));
      
        float[][] line_endeffector_offsets_left = new float[allLinePositions_left.size()][4];
      
        for (int i=0; i < allLinePositions_left.size(); i++) {
          // x1 offset
          line_endeffector_offsets_left[i][0] = allLinePositions_left.get(i)[0] - (posEE.x*4000.0 + left_image.width);
          // y1 offset
          line_endeffector_offsets_left[i][1] = allLinePositions_left.get(i)[1] - (posEE.y*4000.0); 
          // x2 offset
          line_endeffector_offsets_left[i][2] = allLinePositions_left.get(i)[2] - (posEE.x*4000.0 + left_image.width);
          // y2 offset
          line_endeffector_offsets_left[i][3] = allLinePositions_left.get(i)[3] - (posEE.y*4000.0); 
        }
      
      
      
      
        PVector[] lineForces_left = new PVector[allLinePositions_left.size()];
        for (int i=0; i < line_endeffector_offsets_left.length; i++) {
          lineForces_left[i] = calculate_line_force(line_endeffector_offsets_left[i], penWall, -1);
        }
      
      
        // ensure only one vertical line can enact force upon the end effector at once
        for (int i=0; i < lineForces_left.length; i++) {
          if (lineForces_left[i].x != 0 || lineForces_left[i].y != 0) {
            fWall.add(lineForces_left[i]);
            break;
          }
        }
        
        
        float[][] line_endeffector_offsets_left_grey = new float[allLinePositions_left_grey.size()][4];
      
        for (int i=0; i < allLinePositions_left_grey.size(); i++) {
          // x1 offset
          line_endeffector_offsets_left_grey[i][0] = allLinePositions_left_grey.get(i)[0] - (posEE.x*4000.0 + left_image.width);
          // y1 offset
          line_endeffector_offsets_left_grey[i][1] = allLinePositions_left_grey.get(i)[1] - (posEE.y*4000.0); 
          // x2 offset
          line_endeffector_offsets_left_grey[i][2] = allLinePositions_left_grey.get(i)[2] - (posEE.x*4000.0 + left_image.width);
          // y2 offset
          line_endeffector_offsets_left_grey[i][3] = allLinePositions_left_grey.get(i)[3] - (posEE.y*4000.0); 
        }
      
      
      
      
        PVector[] lineForces_left_grey = new PVector[allLinePositions_left_grey.size()];
        for (int i=0; i < line_endeffector_offsets_left_grey.length; i++) {
          lineForces_left_grey[i] = calculate_line_force(line_endeffector_offsets_left_grey[i], penWallGrey, 1);
        }
      
      
        // ensure only one vertical line can enact force upon the end effector at once
        for (int i=0; i < lineForces_left_grey.length; i++) {
          if ((lineForces_left_grey[i].x != 0 || lineForces_left_grey[i].y != 0)) {
            fWall.add(lineForces_left_grey[i]);
            break;
          }
        }
      
      }
      
      // horizontal lines
      penWall.set(0, 10);
      
      float[][] hor_line_endeffector_offsets = new float[allHorLinePositions.size()][4];
      
      for (int i=0; i < allHorLinePositions.size(); i++) {
        // x1 offset
        hor_line_endeffector_offsets[i][0] = allHorLinePositions.get(i)[0] - (posEE.x*4000.0 + right_image.width);
        // y1 offset
        hor_line_endeffector_offsets[i][1] = allHorLinePositions.get(i)[1] - (posEE.y*4000.0); 
        // x2 offset
        hor_line_endeffector_offsets[i][2] = allHorLinePositions.get(i)[2] - (posEE.x*4000.0 + left_image.width);
        // y2 offset
        hor_line_endeffector_offsets[i][3] = allHorLinePositions.get(i)[3] - (posEE.y*4000.0); 
      }
      
      
      PVector[] horLineForces = new PVector[allHorLinePositions.size()];
      for (int i=0; i < hor_line_endeffector_offsets.length; i++) {
        horLineForces[i] = calculate_line_force(hor_line_endeffector_offsets[i], penWall, 1);
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

PVector colour_force(int direction) {
  PVector force = new PVector(0,0);
  if(haplyBoard.data_available()){
      /* GET END-EFFECTOR STATE (TASK SPACE) */
      widgetOne.device_read_data();
    
      angles.set(widgetOne.get_device_angles()); 
      posEE.set(widgetOne.get_device_position(angles.array()));
      posEE.set(device_to_graphics(posEE)); 
      
      
      /* haptic wall force calculation */
      fWall.set(0, 0);
      
      
      float force_offset = 0.005 + posEE.x*1.8; // to account for weakness when the end effector is perpendicular to the motors
      //if ((posEE.x < -0.006 || (posEE.x > 0.012 && posEE.x < 0.02))) {
      //  force_offset = 0.02;
      //}
      if (( posEE.x < 0.02)) {
        force_offset = force_offset + 0.01;
      }
      float height_offset = (posEE.y + rEE)/1.75; // to account for the difference in force close and far from the motors
      
      // adjustments to height offset
      if (posEE.y < 0.03) {
        height_offset = height_offset + 0.05;
      }

      penWall.set(direction * 1/(height_offset + force_offset), 0);
      
      force.add(penWall.mult(hWall/3));
      
      //println(force);
      
  }
  return force;
  
}



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

void create_lines_from_image(){
  println("Create Lines From Image");
  // bark_detailed = loadImage("oak_bark.jpg");
  // bark_template = loadImage("oak_bark_black_and_white.jpg");
  // bark_BAW = loadImage("oak_bark.jpg");
  // bark_GREY = loadImage("oak_bark.jpg");
  // bark_BAW.filter(THRESHOLD);
  // bark_GREY.filter(GRAY);
  int white = 0;
  int black = 0;
  float threshold = 255/2;
  bark_BAW.loadPixels();
  for (int i = 0; i < bark_BAW.height; ++i) {
    for (int j = 0; j < bark_BAW.width; ++j) {
      int loc = j + i * bark_BAW.width;
      float r = red(bark_BAW.pixels[loc]);
      float g = green(bark_BAW.pixels[loc]);
      float b = blue(bark_BAW.pixels[loc]);

      if((r+g+b)/3 >= threshold){
        white++;
      } else {
        black++;
      }
      
    }
  }

  println("White pixels: ", white);
  println("Black pixels: ", black);
}

void create_pantagraph(){
  float rEEAni = pixelsPerMeter * (rEE/2);
  
  fill(127,0,0);
  endEffector = createShape(ELLIPSE, deviceOrigin.x, deviceOrigin.y, 2*rEEAni, 2*rEEAni);
  endEffector.setStroke(color(0));
  strokeWeight(5);
  
}

PVector calculate_line_force(float[] offsets, PVector pen_wall, int direction) {
  PVector force = new PVector(0,0);
  //println(offsets);
  Float[] test = {offsets[0] - Math.round(offsets[0]), offsets[1] - Math.round(offsets[1]), offsets[2] - Math.round(offsets[2]), offsets[3] - Math.round(offsets[3])}; 
  //println(test);
  if (offsets[0] < 49 && offsets[1] < 6 && offsets[2] > 33 && offsets[3] > -6) {
    //println("yes");
    // make sure the force is applied inward towards the wall, whatever side we're on
    float wallForce = -hWall * direction; 
    if (offsets[2] < 40) {
      wallForce = hWall * direction;
    }
      force = force.add(pen_wall.mult(wallForce));
  }
  //else {
  //  println(offsets);
  //}
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
  //background(152,190,100);
  background(125);

  xE = pixelsPerMeter * xE;
  yE = pixelsPerMeter * yE;
  
  if (state == "lines") {
    //for(int i=0; i < allLines.length; i++) {
    //  shape(allLines[i]);
    //}
    image(left_image, left_image_margin_x, left_image_margin_y);
    image(right_image, right_image_margin_x, right_image_margin_y);
  }
  else if (state == "simple_image") {
    //image(bark_template, 350, 150);
    // background(bark_template);
    image(left_image, left_image_margin_x, left_image_margin_y);
    image(right_image, right_image_margin_x, right_image_margin_y);
  }
  else if (state == "detailed_image") {
    // background(bark_detailed);
    //image(bark_detailed, 350, 150);
    image(right_image_colour, right_image_margin_x, right_image_margin_y);
    image(left_image_colour, left_image_margin_x, left_image_margin_y);
  } else if (state == "blackandwhite"){
    // background(bark_BAW);
  } else if (state == "greyscale"){
    // background(bark_GREY);
  }
  
  
    for(int i=0; i < allHorLines.size(); i++) {
      shape(allHorLines.get(i));
    }
   
    
    
  // draw background images 
  //image(left_image, left_image_margin_x, left_image_margin_y);
  //image(right_image, right_image_margin_x, right_image_margin_y);

  //left_image.loadPixels();
  //// temp_image.loadPixels();
  //right_image.loadPixels();

  textSize(48);
  text("Image #1", left_image_margin_x, left_image_margin_y * 2 / 3);
  text("Image #2", right_image_margin_x, right_image_margin_y * 2 / 3);

  textSize(20);
  text("This image has a gradient", left_image_margin_x, left_image_margin_y + left_image.height + 40);
  text("This image has simple lines", right_image_margin_x, right_image_margin_y + right_image.height + 40);
  
  
  // show the auto generated lines
  for(int i=0; i < allLines.size(); i++) {
      shape(allLines.get(i));
  }
  for(int i=0; i < allLines_left.size(); i++) {
      shape(allLines_left.get(i));
  }
  for(int i=0; i < allLines_left_grey.size(); i++) {
      shape(allLines_left_grey.get(i));
  }
  
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
  println("keyPressed", keyCode);
  if (keyCode == '1') {
    //state = "lines";
  }
  else if (keyCode == '2') {
    state = "simple_image";
  }
  else if (keyCode == '3') {
    state = "detailed_image";
  } else if(keyCode == 'b' || keyCode == 'B'){
    state = "blackandwhite";
  } else if(keyCode == 'g' || keyCode == 'G'){
    state = "greyscale";
  }
}

// void mouseClicked(){
//   println("Mouse clicked", mouseX, mouseY);
  
//   int loc = mouseY + mouseX * bark_BAW.width;
//   float r = red(bark_BAW.pixels[loc]);
//   float g = green(bark_BAW.pixels[loc]);
//   float b = blue(bark_BAW.pixels[loc]);

//   println("loc: ", loc, " rgb:", r,g,b);
  
// }

// void mouseMoved(){
//   if(renderingForce){
//     println("Mouse loc", mouseX, mouseY);

//     int loc = mouseY + mouseX * bark_BAW.width;
//     float r = red(bark_BAW.pixels[loc]);
//     float g = green(bark_BAW.pixels[loc]);
//     float b = blue(bark_BAW.pixels[loc]);

//     println("loc: ", loc, " rgb:", r,g,b);
//   }
// }

/* end helper functions section ****************************************************************************************/




 
