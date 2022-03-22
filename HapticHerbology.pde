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


ArrayList<Integer[]> allLinePositions = new ArrayList<Integer[]>();
                              
                              
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
  right_image_margin_x += left_image.width;

  image(left_image, left_image_margin_x, left_image_margin_y);
  image(right_image, right_image_margin_x, right_image_margin_y);

  left_image.loadPixels();
  // temp_image.loadPixels();
  right_image.loadPixels();

  textSize(48);
  text("Image #1", left_image_margin_x, left_image_margin_y * 2 / 3);
  text("Image #2", right_image_margin_x, right_image_margin_y * 2 / 3);

  textSize(24);
  text("This image tracks position", left_image_margin_x, left_image_margin_y + left_image.height + 40);
  text("This image has pre-lines", right_image_margin_x, right_image_margin_y + right_image.height + 40);
  
  // for (int y = 1; y < left_image.height-1; y++) { // Skip top and bottom edges
  //   for (int x = 1; x < left_image.width-1; x++) { // Skip left and right edges
  //     float sum = 0; // Kernel sum for this pixel
  //     for (int ky = -1; ky <= 1; ky++) {
  //       for (int kx = -1; kx <= 1; kx++) {
  //         // Calculate the adjacent pixel for this kernel point
  //         int pos = (y + ky)*left_image.width + (x + kx);
  //         // Image is grayscale, red/green/blue are identical
  //         float val = red(left_image.pixels[pos]);
  //         // Multiply adjacent pixels based on the kernel values
  //         sum += kernel[ky+1][kx+1] * val;
  //       }
  //     }
  //     // For this pixel in the new image, set the gray value
  //     // based on the sum from the kernel
  //     temp_image.pixels[y*left_image.width + x] = color(sum, sum, sum);
  //   }
  // }


  // for (int y = 1; y < temp_image.height-1; y++) {   // Skip top and bottom edges
  //     for (int x = 1; x < temp_image.width-1; x++) {  // Skip left and right edges
  //       float sum = 0; // Kernel sum for this pixel
  //       for (int ky = -1; ky <= 1; ky++) {
  //         for (int kx = -1; kx <= 1; kx++) {
  //           // Calculate the adjacent pixel for this kernel point
  //           int pos = (y + ky)*temp_image.width + (x + kx);
  //           // Image is grayscale, red/green/blue are identical
  //           float val = red(temp_image.pixels[pos]);
  //           // Multiply adjacent pixels based on the kernel values
  //           sum += kernel_blur[ky+1][kx+1] * val;
  //         }
  //       }
  //       // For this pixel in the new image, set the gray value
  //       // based on the sum from the kernel
  //       right_image.pixels[y*temp_image.width + x] = color(sum);
  //     }
  //   }

  // right_image.updatePixels();
  // image(right_image, right_image_margin_x, right_image_margin_y);

  // Read image vertically
  // Create lines accordingly
  // right_image_lines = [];
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


  // noStroke();
  
  // fill(0,0,255);
  // beginShape();
  // // Create lines in the right_image
  // for (int i = 0; i < right_image.width; ++i) {
  //   for (int j = 0; j < right_image.height; ++j) {
  //     int loc = i + j * right_image.width;
  //     float r = red(right_image.pixels[loc]);
  //     float g = green(right_image.pixels[loc]);
  //     float b = blue(right_image.pixels[loc]);

  //     if ((r + g + b) / 3 < 1) {
  //       vertex(i + right_image_margin_x, j + right_image_margin_y);
  //     }
  //   }
  // }
  // endShape(CLOSE);

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

  // Equivalent to MouseMoved()
  if(renderingForce){
    newPos = new PVector(mouseX - left_image_margin_x, mouseY - left_image_margin_y);
    
    if(newPos.x != posCursor.x || newPos.y != posCursor.y){
      // Inside left image
      if(newPos.x >= 0 && newPos.x < left_image.width && newPos.y >= 0 && newPos.y < left_image.height){
        // println("Mouse loc", mouseX, mouseY);

        float loc = newPos.x + newPos.y * left_image.width;
        float r = red(left_image.pixels[int(loc)]);
        float g = green(left_image.pixels[int(loc)]);
        float b = blue(left_image.pixels[int(loc)]);

        // println("loc: ", loc, " rgb:", r,g,b);
      }
      posCursor = newPos;
    }
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

      penWall.set(1/(height_offset + force_offset), 0);
      
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
      
      //float[][] hor_line_endeffector_offsets = new float[allHorLinePositions.length][4];
      
      //for (int i=0; i < allHorLinePositions.length; i++) {
      //  // x1 offset
      //  hor_line_endeffector_offsets[i][0] = allHorLinePositions[i][0] - posEE.x;
      //  // y1 offset
      //  hor_line_endeffector_offsets[i][1] = allHorLinePositions[i][1] - posEE.y; 
      //  // x2 offset
      //  hor_line_endeffector_offsets[i][2] = allHorLinePositions[i][2] - posEE.x;
      //  // y2 offset
      //  hor_line_endeffector_offsets[i][3] = allHorLinePositions[i][3] - posEE.y; 
      //}
      
      
      //PVector[] horLineForces = new PVector[allHorLinePositions.length];
      //for (int i=0; i < hor_line_endeffector_offsets.length; i++) {
      //  horLineForces[i] = calculate_line_force(hor_line_endeffector_offsets[i], penWall);
      //}
      
      //// ensure horizontal force is off when crossing vertical lines
      //for (int i=0; i < horLineForces.length; i++) {
      //  if (fWall.x == 0) {
      //    fWall.add(horLineForces[i]);
      //  }
      //}
      
      
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

PVector calculate_line_force(float[] offsets, PVector pen_wall) {
  PVector force = new PVector(0,0);
  //println(offsets);
  Float[] test = {offsets[0] - Math.round(offsets[0]), offsets[1] - Math.round(offsets[1]), offsets[2] - Math.round(offsets[2]), offsets[3] - Math.round(offsets[3])}; 
  //println(test);
  if (offsets[0] < 49 && offsets[1] < 6 && offsets[2] > 33 && offsets[3] > -6) {
    //println("yes");
    // make sure the force is applied outward from the wall, whatever side we're on
    float wallForce = -hWall; 
    if (offsets[2] < 40) {
      wallForce = hWall;
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
  }
  else if (state == "simple_image") {
    //image(bark_template, 350, 150);
    // background(bark_template);
  }
  else if (state == "detailed_image") {
    // background(bark_detailed);
    //image(bark_detailed, 350, 150);
  } else if (state == "blackandwhite"){
    // background(bark_BAW);
  } else if (state == "greyscale"){
    // background(bark_GREY);
  }
  
  
    //for(int i=0; i < allHorLines.length; i++) {
    //  shape(allHorLines[i]);
    //}
   
    
    
  // draw background images 
  image(left_image, left_image_margin_x, left_image_margin_y);
  image(right_image, right_image_margin_x, right_image_margin_y);

  //left_image.loadPixels();
  //// temp_image.loadPixels();
  //right_image.loadPixels();

  textSize(48);
  text("Image #1", left_image_margin_x, left_image_margin_y * 2 / 3);
  text("Image #2", right_image_margin_x, right_image_margin_y * 2 / 3);

  textSize(24);
  text("This image tracks position", left_image_margin_x, left_image_margin_y + left_image.height + 40);
  text("This image has pre-lines", right_image_margin_x, right_image_margin_y + right_image.height + 40);
  
  
  // show the auto generated lines
  //for(int i=0; i < allLines.size(); i++) {
  //    shape(allLines.get(i));
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




 
