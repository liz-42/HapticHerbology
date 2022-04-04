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
final int         worldPixelWidth                     = 650;
final int         worldPixelHeight                    = 584;


/* graphical elements */
PShape pGraph, joint, endEffector;

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

int default_image_width;
int default_image_height;
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

public class HHBlock {
  public int start_x;
  public int start_y;
  public int height;
  public int width;
  public color c;

  private PShape shape;

  public HHBlock(int startX, int startY, int w,  int h, color c) {
    start_x = startX;
    start_y = startY;
    width = w;
    height = h;
    this.c = c;

    shape = createShape(RECT, right_image_margin_x + start_x, right_image_margin_y + start_y, width, height);
    shape.setFill(c);
    shape.setStroke(false);
    // shape(shape);
  }

  public void show(){
    shape(shape);
  }

  public void hide(){
    shape.setStroke(color(255));
    shape(shape);
  }
}

ArrayList<HHBlock> blocks = new ArrayList<HHBlock>();

public int getBlockIndexAtCoord(int x, int y){
  for (int i = 0; i < blocks.size(); ++i) {
    HHBlock block = blocks.get(i);

    if(block.start_x == x && block.start_y == y){
      return i;
    }
  }

  return -1;
}

public int getBlockIndexBelowCoords(int x, int y) {
  int index_1 = getBlockIndexAtCoord(x,y);
  if(index_1 == -1) return -1;
  HHBlock a = blocks.get(index_1);

  int index_2 = getBlockIndexAtCoord(a.start_x, a.start_y + a.height);
  if(index_2 == -1) return -1;
  HHBlock b = blocks.get(index_2);

  if(a.height == b.height)
    return index_2;

  return -1;
}

public int getBlockIndexNextToCoords(int x, int y) {
  int index_1 = getBlockIndexAtCoord(x, y);
  if(index_1 == -1) return -1;
  HHBlock a = blocks.get(index_1);

  int index_2 = getBlockIndexAtCoord(a.start_x + a.width, a.start_y);
  if(index_2 == -1) return -1;
  HHBlock b = blocks.get(index_2);

  if(a.width == b.width)
    return index_2;

  return -1;
}

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
  
  haplyBoard          = new Board(this, "COM7", 0);
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
  
  // /* create pantagraph graphics */
  create_pantagraph();

  // load images
  left_image = loadImage("oak_bark.jpg");
  // left_image.filter(THRESHOLD);
  // right_image = loadImage("oak_bark.jpg");
  // right_image.filter(THRESHOLD);

  default_image_width = left_image.width;
  default_image_height = left_image.height;

  process_image("oak_bark.jpg");

  // // Read image vertically
  // // Create blocks accordingly
  // // right_image_lines = [];
  // int black = 0;
  // int startJ = 0;
  // int blocks = 0;
  
  // for (int i = 0; i < right_image.width; i++) {
  //   println("line", i);
  //   for (int j = 0; j < right_image.height; j++) {
  //     float pixel = red(right_image.pixels[i + j * right_image.width]);

  //     if(pixel < 10){
  //       if(black == 0){
  //         startJ = j;
  //       }
  //       black++;
  //     }
  //     if(pixel >= 5 || j == right_image.height-1){
  //       if(black >= 10){
  //         blocks++;
  //         PShape temp = createShape(LINE, right_image_margin_x + i, right_image_margin_y + startJ, right_image_margin_x + i, right_image_margin_y + j - 1);
  //         temp.setStroke(color(0,0,150));
  //         shape(temp);
  //       }
  //         black = 0;
  //     }
    
  //   }
  //   black = 0;
    // blocks   = 0;
  // }
  // println("lines :", lines);


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
    update_animation(angles.x*radsPerDegree, angles.y*radsPerDegree, posEE.x, posEE.y);
  }

  // Equivalent to MouseMoved()
  // if(renderingForce){
  //   newPos = new PVector(mouseX - left_image_margin_x, mouseY - left_image_margin_y);
    
  //   if(newPos.x != posCursor.x || newPos.y != posCursor.y){
  //     // Inside left image
  //     if(newPos.x >= 0 && newPos.x < left_image.width && newPos.y >= 0 && newPos.y < left_image.height){
  //       // println("Mouse loc", mouseX, mouseY);

  //       float loc = newPos.x + newPos.y * left_image.width;
  //       float r = red(left_image.pixels[int(loc)]);
  //       float g = green(left_image.pixels[int(loc)]);
  //       float b = blue(left_image.pixels[int(loc)]);

  //       // println("loc: ", loc, " rgb:", r,g,b);
  //     }
  //     posCursor = newPos;
  //   }
  // }
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

      // float[][] line_endeffector_offsets = new float[allLinePositions.length][4];
      
      // for (int i=0; i < allLinePositions.length; i++) {
      //   // x1 offset
      //   line_endeffector_offsets[i][0] = allLinePositions[i][0] - posEE.x;
      //   // y1 offset
      //   line_endeffector_offsets[i][1] = allLinePositions[i][1] - posEE.y; 
      //   // x2 offset
      //   line_endeffector_offsets[i][2] = allLinePositions[i][2] - posEE.x;
      //   // y2 offset
      //   line_endeffector_offsets[i][3] = allLinePositions[i][3] - posEE.y; 
      // }
      
      // PVector[] lineForces = new PVector[allLinePositions.length];
      // for (int i=0; i < line_endeffector_offsets.length; i++) {
      //   lineForces[i] = calculate_line_force(line_endeffector_offsets[i], penWall);
      // }
      
      // ensure only one vertical line can enact force upon the end effector at once
      // for (int i=0; i < lineForces.length; i++) {
      //   if (lineForces[i].x != 0 || lineForces[i].y != 0) {
      //     fWall.add(lineForces[i]);
      //     break;
      //   }
      // }
      
      // horizontal lines
      // penWall.set(0, 10);
      
      // float[][] hor_line_endeffector_offsets = new float[allHorLinePositions.length][4];
      
      // for (int i=0; i < allHorLinePositions.length; i++) {
      //   // x1 offset
      //   hor_line_endeffector_offsets[i][0] = allHorLinePositions[i][0] - posEE.x;
      //   // y1 offset
      //   hor_line_endeffector_offsets[i][1] = allHorLinePositions[i][1] - posEE.y; 
      //   // x2 offset
      //   hor_line_endeffector_offsets[i][2] = allHorLinePositions[i][2] - posEE.x;
      //   // y2 offset
      //   hor_line_endeffector_offsets[i][3] = allHorLinePositions[i][3] - posEE.y; 
      // }
      
      // PVector[] horLineForces = new PVector[allHorLinePositions.length];
      // for (int i=0; i < hor_line_endeffector_offsets.length; i++) {
      //   horLineForces[i] = calculate_line_force(hor_line_endeffector_offsets[i], penWall);
      // }
      
      // ensure horizontal force is off when crossing vertical lines
      // for (int i=0; i < horLineForces.length; i++) {
      //   if (fWall.x == 0) {
      //     fWall.add(horLineForces[i]);
      //   }
      // }
      
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

void create_pantagraph(){
  float rEEAni = pixelsPerMeter * (rEE/2);
  
  // fill(127,0,0);
  endEffector = createShape(ELLIPSE, deviceOrigin.x, deviceOrigin.y, 2*rEEAni, 2*rEEAni);
  // endEffector.setStroke(color(0));
  // strokeWeight(5);
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
  background(125);

  xE = pixelsPerMeter * xE;
  yE = pixelsPerMeter * yE;
  
  // Print images
  image(left_image, left_image_margin_x, left_image_margin_y);
  image(right_image, right_image_margin_x, right_image_margin_y);

  for (HHBlock block : blocks) {
    block.show();
  }

  // if (state == "lines") {
  //   //for(int i=0; i < allLines.length; i++) {
  //   //  shape(allLines[i]);
  //   //}
  // }
  // else if (state == "simple_image") {
  //   //image(bark_template, 350, 150);
  //   // background(bark_template);
  // }
  // else if (state == "detailed_image") {
  //   // background(bark_detailed);
  //   //image(bark_detailed, 350, 150);
  // } else if (state == "blackandwhite"){
  //   // background(bark_BAW);
  // } else if (state == "greyscale"){
  //   // background(bark_GREY);
  // }
  
  textSize(48);
  text("Image #1", left_image_margin_x, left_image_margin_y * 2 / 3);
  text("Image #2", right_image_margin_x, right_image_margin_y * 2 / 3);

  textSize(24);
  text("This image tracks position", left_image_margin_x, left_image_margin_y + left_image.height + 40);
  text("This image has pre-lines", right_image_margin_x, right_image_margin_y + right_image.height + 40);


  translate(xE, yE);
  shape(endEffector);
}

void process_image(String image){
  right_image_margin_x = left_image_margin_x + 40;
  right_image_margin_y = left_image_margin_y;

  blocks = new ArrayList<HHBlock>();

  left_image = loadImage(image);
  left_image.filter(THRESHOLD);
  right_image = loadImage(image);
  right_image.filter(THRESHOLD);

  // resize if needed
  if (left_image.width != default_image_width || left_image.height != default_image_height) {
    left_image.resize(default_image_width, default_image_height);
    right_image.resize(default_image_width, default_image_height);
  }

  right_image_margin_x += left_image.width;

  image(left_image, left_image_margin_x, left_image_margin_y);
  image(right_image, right_image_margin_x, right_image_margin_y);
  textSize(48);
  text("Image #1", left_image_margin_x, left_image_margin_y * 2 / 3);
  text("Image #2", right_image_margin_x, right_image_margin_y * 2 / 3);
  textSize(24);
  text("This image tracks position", left_image_margin_x, left_image_margin_y + left_image.height + 40);
  text("This image has pre-lines", right_image_margin_x, right_image_margin_y + right_image.height + 40);

  left_image.loadPixels();
  right_image.loadPixels();
  
  /* Start by cleaning the image */
  for (int y = 1; y < left_image.height-1; y++) { // Skip top and bottom edges
    for (int x = 1; x < left_image.width-1; x++) { // Skip left and right edges
      float majority = 0; // Kernel sum for this pixel
      for (int ky = -1; ky <= 1; ky++) {
        for (int kx = -1; kx <= 1; kx++) {
          int pos = (y + ky) * left_image.width + (x + kx);
          float val = red(left_image.pixels[pos]);

          majority += (val == 0 ? -1 : 1);
        }
      }
      
      int c = majority >= 0 ? 255 : 0;
      right_image.pixels[y*left_image.width + x] = color(c);
    }
  }

  right_image.updatePixels();
  // image(right_image, right_image_margin_x, right_image_margin_y);


  for (int i = 0; i < right_image.height; i++) {
    for (int j = 0; j < right_image.width; j++) {
      float pixel_1 = red(right_image.pixels[j + i * right_image.width]);
      if(pixel_1 == 0){
        blocks.add(new HHBlock(j, i, 1, 1, color(100)));
      }    
    }
  }

  // HHBlock temp = new HHBlock(5,5,5,5,color(0,255,0));

  println("Groups before iterations:", blocks.size());

  // 6 iterations just cause it plateaus for this image after 6.
  for(int iterations = 0; iterations < 1; iterations++){
    println("Iteration ", iterations);
    // Go horizontal
    for (int i = 0; i < right_image.height; i++) {
      for (int j = 0; j < right_image.width - pow(2,iterations) / 2; j += pow(2,iterations) * 2) {
        int index_1 = getBlockIndexAtCoord(j, i);
        int index_2 = getBlockIndexNextToCoords(j, i);
        // println("a - i,j", i, j);
        // println("i1, i2", index_1, index_2);

        if(index_1 == -1 || index_2 == -1){
          continue;
        }

        // println("b - i,j", i, j);
        HHBlock block_1 = blocks.get(index_1);
        HHBlock block_2 = blocks.get(index_2);
        // println("newBlock", j, i, block_1.width * 2, block_1.height);
        blocks.add(new HHBlock(j, i, block_1.width * 2, block_1.height, color(random(254) + 1, random(254) + 1, random(254) + 1)));

        blocks.remove(index_1);
        blocks.remove(index_2 - 1); // -1 because it's an arraylist, so remove index1 before shifts all the index values
      }
    }

    println("Groups after horizontal:", blocks.size());

    // Go vertical
    for (int i = 0; i < right_image.width; i++) {
      for (int j = 0; j < right_image.height - pow(2,iterations - 1); j += pow(2,iterations + 1)) {
        int index_1 = getBlockIndexAtCoord(i, j);
        int index_2 = getBlockIndexBelowCoords(i, j);

        if(index_1 == -1 || index_2 == -1)
          continue;

        HHBlock block_1 = blocks.get(index_1);
        HHBlock block_2 = blocks.get(index_2);

        // println("newBlock", j, i, block_1.width * 2, block_1.height);
        blocks.add(new HHBlock(i, j, block_1.width, block_1.height * 2, color(random(254) + 1, random(254) + 1, random(254) + 1)));
        
        blocks.remove(index_1);
        blocks.remove(index_2 - 1);
      }
    }
    println("Groups after vertical:", blocks.size());
  }
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
  // if (keyCode == '1') {
  //   //state = "lines";
  // }
  // else if (keyCode == '2') {
  //   state = "simple_image";
  // }
  // else if (keyCode == '3') {
  //   state = "detailed_image";
  // } else if(keyCode == 'b' || keyCode == 'B'){
  //   state = "blackandwhite";
  // } else if(keyCode == 'g' || keyCode == 'G'){
  //   state = "greyscale";
  // }
}

/* end helper functions section ****************************************************************************************/