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

// end effector raduis for visuals
float             rEE_vis                             = 0.003;

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
final int         worldPixelWidth                     = 1232;
final int         worldPixelHeight                    = 650;

/* graphical elements */
PShape pGraph, joint, endEffector, endEffector_1, endEffector_2, endEffector_3, endEffector_4;

// all lines
ArrayList<PShape> allLines = new ArrayList<PShape>();

// lines for left image
ArrayList<PShape> allLines_left = new ArrayList<PShape>();
ArrayList<PShape> allLines_left_grey = new ArrayList<PShape>();

// horizontal lines
ArrayList<PShape> allHorLines = new ArrayList<PShape>();              

PImage left_image;
int left_image_margin_x = 20;
int left_image_margin_y = 80;

int top_margin_images = 80;
PImage image_1;
int left_margin_image_1 = 20;
PImage image_2;
int left_margin_image_2 = 40;
PImage image_3;
int left_margin_image_3 = 60;
PImage image_4;
int left_margin_image_4 = 80;

// colour versions
PImage left_image_colour;
// PImage right_image_colour;

PShape[] right_image_lines = {};

int screen_width = 1232;
int screen_height = 650;
// states for testing
String state = "simple_image";
String renderTechnique = "";

float[][] kernel = {{ -1, -1, -1}, 
                    { -1,  9, -1}, 
                    { -1, -1, -1}};

float v = 1.0 / 9.0;
float[][] kernel_blur = {{ v, v, v }, 
                         { v, v, v }, 
                         { v, v, v }};

// file names for all the different trees
String original_image = "oak_bark.jpg";

String aspen_1 = "aspen_1.jpg";
String aspen_2 = "aspen_2.jpg";
String aspen_3 = "aspen_3.jpg";
String aspen_4 = "aspen_4.jpg";

String horse_chestnut_1 = "horse_chestnut_1.jpg";
String horse_chestnut_2 = "horse_chestnut_2.jpg";
String horse_chestnut_3 = "horse_chestnut_3.jpg";
String horse_chestnut_4 = "horse_chestnut_4.jpg";

String cedar_1 = "cedar_1.jpg";
String cedar_2 = "cedar_2.jpg";
String cedar_3 = "cedar_3.jpg";
String cedar_4 = "cedar_4.jpg";

String oak_1 = "oak_bark.jpg";
String oak_2 = "wet_and_flat.jpg";
String oak_3 = "typical_bark.jpg";
String oak_4 = "large_ridges.jpg";

// Arrays for different tree types
String[] aspen_trees = {aspen_1, aspen_2, aspen_3, aspen_4};
String[] chestnut_trees = {horse_chestnut_1, horse_chestnut_2, horse_chestnut_3, horse_chestnut_4};
String[] cedar_trees = {cedar_1, cedar_2, cedar_3, cedar_4};
String[] oak_trees = {oak_1, oak_2, oak_3, oak_4};

// Array to switch between images with arrow keys
String[] all_images = oak_trees;
int cur_image = 0;
int default_width = 0;
int default_height = 0; 

// State to control which set of trees should be rendered
String tree_state = "oak";

// Rendering forces technique
int force_render_technique = 1;

/* end elements definition *********************************************************************************************/ 

/* setup section *******************************************************************************************************/
void setup() {
  /* put setup code here, run once: */
  
  /* screen size definition */
  size(1232, 650);
  
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
  
  /* create pantagraph graphics */
  create_pantagraph();

  // get default height and width to use for all images
  PImage temp = loadImage(original_image);
  
  default_width = temp.width;
  default_height = temp.height;
  
  // calculates image lines and placement
  process_image(all_images[0]);

  /* setup framerate speed */
  frameRate(baseFrameRate);
  
  /* setup simulation thread to run at 1kHz */ 
  SimulationThread st = new SimulationThread();
  scheduler.scheduleAtFixedRate(st, 1, 1, MILLISECONDS);
}
/* end setup section ***************************************************************************************************/

/* draw section ********************************************************************************************************/
void draw() {
  /* put graphical code here, runs repeatedly at defined framerate in setup, else default at 60fps: */
  update_animation(angles.x*radsPerDegree, angles.y*radsPerDegree, posEE.x, posEE.y);
}
/* end draw section ****************************************************************************************************/

/* simulation section **************************************************************************************************/
class SimulationThread implements Runnable {
  public void run() {
    /* put haptic simulation code here, runs repeatedly at 1kHz as defined in setup */
    
    renderingForce = true;
    
    if(haplyBoard.data_available()) {
      /* GET END-EFFECTOR STATE (TASK SPACE) */
      widgetOne.device_read_data();
    
      angles.set(widgetOne.get_device_angles()); 
      posEE.set(widgetOne.get_device_position(angles.array()));
      posEE.set(device_to_graphics(posEE)); 
      
      /* haptic wall force calculation */
      fWall.set(0, 0);
      
      // change force offsets for main vertical lines depending on tree type
      if (tree_state == "oak") {
        float force_offset = 0.005 + abs(posEE.x)*1.5; // to account for weakness when the end effector is perpendicular to the motors
        if (( posEE.x > 0.02) || (posEE.x < -0.02)) {
          force_offset = force_offset + 0.01;
        } else if ((( posEE.x < 0.02) && (posEE.x > -0.02)) && posEE.y < 0.05){
          force_offset = force_offset + 0.005;
        } else if ((( posEE.x < 0.02) && (posEE.x > -0.02)) && posEE.y >= 0.05){
          force_offset = force_offset + 0.02;
        }
        float height_offset = (posEE.y + rEE)/1.75; // to account for the difference in force close and far from the motors
      
        // adjustments to height offset
        if (posEE.y < 0.03) {
          height_offset = height_offset + 0.05;
        }

        penWall.set(1/(height_offset + force_offset), 0);
      }
      else if (tree_state == "cedar") {
        float force_offset = 0.005 + abs(posEE.x)*1.5; // to account for weakness when the end effector is perpendicular to the motors
        if (( posEE.x > 0.02) || (posEE.x < -0.02)) {
          force_offset = force_offset + 0.01;
        } else if ((( posEE.x < 0.02) && (posEE.x > -0.02)) && posEE.y < 0.05){
          force_offset = force_offset + 0.005;
        } else if ((( posEE.x < 0.02) && (posEE.x > -0.02)) && posEE.y >= 0.05){
          force_offset = force_offset + 0.02;
        }
        float height_offset = (posEE.y + rEE)/1.75; // to account for the difference in force close and far from the motors
      
        // adjustments to height offset
        if (posEE.y < 0.03) {
          height_offset = height_offset + 0.05;
        }

        penWall.set(1/((height_offset + force_offset)*1.25), 0);
      }
      else if (tree_state == "chestnut") {
        float force_offset = 0.005 + abs(posEE.x)*1.5; // to account for weakness when the end effector is perpendicular to the motors
        if (( posEE.x > 0.02) || (posEE.x < -0.02)) {
          force_offset = force_offset + 0.03;
        } else if ((( posEE.x < 0.02) && (posEE.x > -0.02)) && posEE.y < 0.05){
          force_offset = force_offset + 0.04;
        } else if ((( posEE.x < 0.02) && (posEE.x > -0.02)) && posEE.y >= 0.05){
          force_offset = force_offset + 0.04;
        }
        float height_offset = (posEE.y + rEE)/1.75; // to account for the difference in force close and far from the motors
      
        // adjustments to height offset
        if (posEE.y < 0.03) {
          height_offset = height_offset + 0.05;
        }

        penWall.set(0, 1/(height_offset + force_offset));
      }
      else { // Aspen
        float force_offset = 0.005 + abs(posEE.x)*1.5; // to account for weakness when the end effector is perpendicular to the motors
        if (( posEE.x > 0.02) || (posEE.x < -0.02)) {
          force_offset = force_offset + 0.01;
        } else if ((( posEE.x < 0.02) && (posEE.x > -0.02)) && posEE.y < 0.05){
          force_offset = force_offset + 0.005;
        } else if ((( posEE.x < 0.02) && (posEE.x > -0.02)) && posEE.y >= 0.05){
          force_offset = force_offset + 0.02;
        }
        float height_offset = (posEE.y + rEE)/1.75; // to account for the difference in force close and far from the motors
      
        // adjustments to height offset
        if (posEE.y < 0.03) {
          height_offset = height_offset + 0.05;
        }

        penWall.set(0, 1/((height_offset + force_offset)*1.5));
      }

      switch (force_render_technique) {
        case 1: // 
          float[][] line_endeffector_offsets = new float[allLinePositions.size()][4];
        
          for (int i = 0; i < allLinePositions.size(); i++) {
            // x1 offset
            line_endeffector_offsets[i][0] = allLinePositions.get(i)[0] - (posEE.x * 4000.0 + left_image.width);
            // y1 offset
            line_endeffector_offsets[i][1] = allLinePositions.get(i)[1] - (posEE.y * 4000.0); 
            // x2 offset
            line_endeffector_offsets[i][2] = allLinePositions.get(i)[2] - (posEE.x * 4000.0 + left_image.width);
            // y2 offset
            line_endeffector_offsets[i][3] = allLinePositions.get(i)[3] - (posEE.y * 4000.0); 
          }
        
          PVector[] lineForces = new PVector[allLinePositions.size()];
          for (int i=0; i < line_endeffector_offsets.length; i++) {
            // change force orientation depending on tree type
            lineForces[i] = calculate_line_force(line_endeffector_offsets[i], penWall, 1); // 1 applies inward line force
          }
          // ensure only one vertical line can enact force upon the end effector at once
          for (int i=0; i < lineForces.length; i++) {
            if (lineForces[i].x != 0 || lineForces[i].y != 0) {
              fWall.add(lineForces[i]);
              break;
            }
          }
            
          // change force offset for horizontal lines depending on tree type
          if (tree_state == "oak") {
            penWall.set(0, 10);
          }
          else if (tree_state == "cedar") {
            penWall.set(0, 5);
          }
          else if (tree_state == "chestnut") {
            penWall.set(5, 0);
            if ((( posEE.x < 0.02) && (posEE.x > -0.02))){
              penWall.set(1, 0);
            }
          }
          else {
            penWall.set(5, 0);
          }
        
          float[][] hor_line_endeffector_offsets = new float[allHorLinePositions.size()][4];
          
          for (int i=0; i < allHorLinePositions.size(); i++) {
            // x1 offset
            hor_line_endeffector_offsets[i][0] = allHorLinePositions.get(i)[0] - (posEE.x*4000.0 + left_image.width);
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
          
          // Ensure horizontal force is off when crossing vertical lines
          for (int i=0; i < horLineForces.length; i++) {
            if (fWall.x == 0) {
              fWall.add(horLineForces[i]);
            }
          }
          break;
        
        case 2: // 
          // change force offsets for grey lines depending on tree type
          if (tree_state == "oak") {
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
          }
          else if (tree_state == "cedar") {
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
          }
          else if (tree_state == "chestnut") {
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

            penWallGrey.set(1/((height_offset_grey + force_offset_grey)*3), 0);
          }
          else {
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

            penWallGrey.set(1/((height_offset_grey + force_offset_grey)*2), 0);
          }
          
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
            lineForces_left[i] = calculate_line_force(line_endeffector_offsets_left[i], penWall, -1); // -1 applies outward line force
          }
        
          //boolean size_change = false;
          // ensure only one vertical line can enact force upon the end effector at once
          for (int i=0; i < lineForces_left.length; i++) {
            if (lineForces_left[i].x != 0 || lineForces_left[i].y != 0) {
              fWall.add(lineForces_left[i]);
              //// change size of end effector
              //rEE_vis = 0.002;
              //create_pantagraph();
              //size_change = true;
              break;
            }
          }
          //// reset size if not in any lines
          //if (!size_change && rEE_vis != 0.003) {
          //  rEE_vis = 0.003;
          //  create_pantagraph();
          //}
          
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
          break;

        case 3:

          break;
      }
      
      fEE = (fWall.copy()).mult(-1);
      fEE.set(graphics_to_device(fEE));
      /* End haptic wall force calculation */
    }
    
    torques.set(widgetOne.set_device_torques(fEE.array()));
    widgetOne.device_write_torques();
  
    renderingForce = false;
  }
}
/* End simulation section **********************************************************************************************/


/* Helper functions section, place helper functions here ***************************************************************/

void process_image(String image) {
  // Reset line arrays 
  allLinePositions = new ArrayList<Integer[]>();

  // For left image
  allLinePositions_left = new ArrayList<Integer[]>();
  allLinePositions_left_grey = new ArrayList<Integer[]>();

  // For horizontal lines
  allHorLinePositions = new ArrayList<Integer[]>();
  allLines = new ArrayList<PShape>();

  // Lines for left image
  allLines_left = new ArrayList<PShape>();
  allLines_left_grey = new ArrayList<PShape>();

  // Horizontal lines
  allHorLines = new ArrayList<PShape>();

  // Load images
  left_image = loadImage(image);
  left_image_colour = loadImage(image);
  image_1 = loadImage(oak_trees[cur_image]);
  image_2 = loadImage(cedar_trees[cur_image]);
  image_3 = loadImage(chestnut_trees[cur_image]);
  image_4 = loadImage(aspen_trees[cur_image]);

  image_1.resize(default_width, default_height);
  image_2.resize(default_width, default_height);
  image_3.resize(default_width, default_height);
  image_4.resize(default_width, default_height);

  println("w: ", image_1.width);
  println("h: ", image_1.height);

  // Resize if needed
  if (left_image.width != default_width || left_image.height != default_height) {
    left_image.resize(default_width, default_height);
    left_image_colour.resize(default_width, default_height);
  }
  
  // Original images
  left_image.loadPixels();
  
  float sum = 0;
  float count = 0;

   
  // If the average is higher than 125, then the image likely contains more small black lines
  int threshold = 10;
  int threshold_grey = 3; // For the smaller lines

  left_image.filter(THRESHOLD);
  
  // Lower the threshold for aspen trees
  if (tree_state == "aspen") {
    threshold = 2;
    threshold_grey = 1;
  }
  // Lower the threshold for chestnut trees
  if (tree_state == "chestnut") {
    threshold = 5;
    threshold_grey = 2;
  }

  // Read image vertically
  // Create lines accordingly
  int black = 0;
  int startJ = 0;
  
  for (int i = 0; i < left_image.width; i++) {
    for (int j = 0; j < left_image.height; j++) {
      float pixel = red(left_image.pixels[i + j * left_image.width]);

      // If pixel is black
      if(pixel < 10) {
        if(black == 0) {
          startJ = j;
        }
        black++;
      }

      // If pixel is not black
      if (pixel >= 5 || j == left_image.height - 1) {
        if ((black >= threshold_grey) && (black < threshold)) {
          Integer[] curLinePos = {left_image_margin_x + i, left_image_margin_y + startJ, left_image_margin_x + i, left_image_margin_y + j - 1};
          PShape temp = createShape(LINE, left_image_margin_x + i, left_image_margin_y + startJ, left_image_margin_x + i, left_image_margin_y + j - 1);
          //println(curLinePos);
          temp.setStroke(color(0,150,150));
        
          // add to list
          allLinePositions_left_grey.add(curLinePos);
          allLines_left_grey.add(temp);
        }
        else if (black >= threshold) {
          Integer[] curLinePos = {left_image_margin_x + i, left_image_margin_y + startJ, left_image_margin_x + i, left_image_margin_y + j - 1};
          PShape temp = createShape(LINE, left_image_margin_x + i, left_image_margin_y + startJ, left_image_margin_x + i, left_image_margin_y + j - 1);
          temp.setStroke(color(0,0,150));
        
          // add to list
          allLinePositions_left.add(curLinePos);
          allLines_left.add(temp);

          
          allLinePositions.add(curLinePos);
          allLines.add(temp);
        }
          black = 0;
      }
    }
  }
  
  // Create horizontal lines for right image depending on tree type - vertical otherwise
  if (tree_state == "oak" || tree_state == "cedar") {
    for (int j = 0; j < left_image.height; j=j+20) {
      Integer[] curLinePos = {left_image_margin_x, left_image_margin_y + j, left_image_margin_x + left_image.width, left_image_margin_y + j};
      PShape temp = createShape(LINE, left_image_margin_x, left_image_margin_y + j, left_image_margin_x + left_image.width, left_image_margin_y + j);
      //println(curLinePos);
      temp.setStroke(color(0,0,150));
        
      // add to list
      allHorLinePositions.add(curLinePos);
      allHorLines.add(temp);
    }
  }
  else {
    for (int j = 0; j < left_image.width; j=j+20) {
      Integer[] curLinePos = {left_image_margin_x + j, left_image_margin_y, left_image_margin_x + j, left_image_margin_y + left_image.height};
      PShape temp = createShape(LINE, left_image_margin_x + j, left_image_margin_y, left_image_margin_x + j, left_image_margin_y + left_image.height);
      //println(curLinePos);
      temp.setStroke(color(0,0,150));
        
      // add to list
      allHorLinePositions.add(curLinePos);
      allHorLines.add(temp);
    }
  }
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

void create_pantagraph() {
  float rEEAni = pixelsPerMeter * (rEE_vis/2);
  
  endEffector = createShape(ELLIPSE, deviceOrigin.x, deviceOrigin.y, 2*rEEAni, 2*rEEAni);
  endEffector_1 = createShape(ELLIPSE, deviceOrigin.x - 283 * 1.5 - left_margin_image_1 * 1.5, deviceOrigin.y, 2*rEEAni, 2*rEEAni);
  endEffector_2 = createShape(ELLIPSE, deviceOrigin.x - 283 * 0.5 - left_margin_image_1 * 0.5, deviceOrigin.y, 2*rEEAni, 2*rEEAni);
  endEffector_3 = createShape(ELLIPSE, deviceOrigin.x + 283 * 0.5 + left_margin_image_1 * 0.5, deviceOrigin.y, 2*rEEAni, 2*rEEAni);
  endEffector_4 = createShape(ELLIPSE, deviceOrigin.x + 283 * 1.5 + left_margin_image_1 * 1.5, deviceOrigin.y, 2*rEEAni, 2*rEEAni);
  //endEffector.setStroke(color(0));
  strokeWeight(1);
  
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

PShape create_wall(float x1, float y1, float x2, float y2) {
  x1 = pixelsPerMeter * x1;
  y1 = pixelsPerMeter * y1;
  x2 = pixelsPerMeter * x2;
  y2 = pixelsPerMeter * y2;
  
  return createShape(LINE, deviceOrigin.x + x1, deviceOrigin.y + y1, deviceOrigin.x + x2, deviceOrigin.y+y2);
}

void update_animation(float th1, float th2, float xE, float yE) {
  background(125);
  xE = pixelsPerMeter * xE;
  yE = pixelsPerMeter * yE;
  
  // Show 4 images
  image(image_1, left_margin_image_1, top_margin_images);
  left_margin_image_2 = image_1.width + left_image_margin_x * 2;
  image(image_2, left_margin_image_2, top_margin_images);
  left_margin_image_3 = image_1.width * 2+ left_image_margin_x * 3;
  image(image_3, left_margin_image_3, top_margin_images);
  left_margin_image_4 = image_1.width * 3 + left_image_margin_x * 4;
  image(image_4, left_margin_image_4, top_margin_images);


  if (state == "lines") {
    image(left_image, left_image_margin_x, left_image_margin_y);
    // image(right_image, right_image_margin_x, right_image_margin_y);
    for(int i=0; i < allLines.size(); i++) {
        shape(allLines.get(i));
    }
    for(int i=0; i < allLines_left.size(); i++) {
        shape(allLines_left.get(i));
    }
    for(int i=0; i < allLines_left_grey.size(); i++) {
        shape(allLines_left_grey.get(i));
    }
    for(int i=0; i < allHorLines.size(); i++) {
      shape(allHorLines.get(i));
    }
  }
  else if (state == "simple_image") {
    image(left_image, left_image_margin_x, left_image_margin_y);
  }
  else if (state == "detailed_image") {
    image(left_image_colour, left_image_margin_x, left_image_margin_y);
  }

  textSize(48);
  text("Haptic Herbology", screen_width / 2 - 150, 40);
  textSize(30);
  int top_margin_text = top_margin_images + image_1.height + 30;
  text("Oak", left_margin_image_1 + 100, top_margin_text);
  text("Cedar", left_margin_image_2 + 100, top_margin_text);
  text("Chestnut", left_margin_image_3 + 100, top_margin_text);
  text("Aspen", left_margin_image_4 + 100, top_margin_text);
  
  // textSize(48);
  // text("Image #1", left_image_margin_x, left_image_margin_y * 2 / 3);
  // text("Image #2", right_image_margin_x, right_image_margin_y * 2 / 3);

  //  textSize(20);
  //  text("This image has a gradient", left_image_margin_x, left_image_margin_y + left_image.height + 40);
  //  text("This image has simple lines", right_image_margin_x, right_image_margin_y + right_image.height + 40);
  
  
  // show the auto generated lines
  // for(int i=0; i < allLines.size(); i++) {
  //    shape(allLines.get(i));
  // }
  // for(int i=0; i < allLines_left.size(); i++) {
  //    shape(allLines_left.get(i));
  // }
  // for(int i=0; i < allLines_left_grey.size(); i++) {
  //    shape(allLines_left_grey.get(i));
  // }
  
  translate(xE, yE);
  shape(endEffector_1);
  shape(endEffector_2);
  shape(endEffector_3);
  shape(endEffector_4);
}

PVector device_to_graphics(PVector deviceFrame) {
  return deviceFrame.set(-deviceFrame.x, deviceFrame.y);
}

PVector graphics_to_device(PVector graphicsFrame) {
  return graphicsFrame.set(-graphicsFrame.x, graphicsFrame.y);
}

// change state when any key pressed
void keyPressed() {
  println("keyPressed", keyCode);

  if (keyCode == '1'){
    force_render_technique = 1;
  } else if (keyCode == '2'){
    force_render_technique = 2;
  } else if (keyCode == '3'){
    force_render_technique = 3;
  }

  else if (keyCode == 32) { // Space bar
    if(state == "lines") state = "simple_image";
    else if(state == "simple_image") state = "detailed_image";
    else if(state == "detailed_image") state = "lines";
  }

  // Toggle which type of tree is rendered
  else if (keyCode == 79) { // o
    tree_state = "oak";
    all_images = oak_trees;
    process_image(all_images[cur_image]);
  }
  else if (keyCode == 67) { // c
    tree_state = "cedar";
    all_images = cedar_trees;
    process_image(all_images[cur_image]);
  }
  else if (keyCode == 72) { // h
    tree_state = "chestnut";
    all_images = chestnut_trees;
    process_image(all_images[cur_image]);
  }
  else if (keyCode == 65) { // a
    tree_state = "aspen";
    all_images = aspen_trees;
    process_image(all_images[cur_image]);
  }

  // Change images using Right and left arrow keys
  else if (keyCode == 39) {
    if(cur_image < (all_images.length - 1)) {
      cur_image = cur_image + 1;
    }
    else {
      cur_image = 0;
    }
    process_image(all_images[cur_image]);
  }
  else if (keyCode == 37) {
    if(cur_image > 0) {
      cur_image = cur_image - 1;
    }
    else {
      cur_image = all_images.length - 1;
    }
    process_image(all_images[cur_image]);
  }

  println(cur_image, all_images.length);
}
/* end helper functions section ****************************************************************************************/