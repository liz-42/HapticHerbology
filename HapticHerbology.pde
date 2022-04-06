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
 
/* Library imports *****************************************************************************************************/ 
import processing.serial.*;
import static java.util.concurrent.TimeUnit.*;
import java.util.concurrent.*;
/* End library imports *************************************************************************************************/  

/* Scheduler definition ************************************************************************************************/ 
private ScheduledExecutorService scheduler      = Executors.newScheduledThreadPool(1);
/* End scheduler definition ********************************************************************************************/ 

/* Device block definitions ********************************************************************************************/
Board             haplyBoard;
Device            widgetOne;
Mechanisms        pantograph;

byte              widgetOneID                         = 5;
int               CW                                  = 0;
int               CCW                                 = 1;
boolean           renderingForce                     = false;
/* End device block definition *****************************************************************************************/

/* Framerate definition ************************************************************************************************/
long              baseFrameRate                       = 180;
/* End framerate definition ********************************************************************************************/ 

/* Elements definition *************************************************************************************************/

/* Screen and world setup parameters */
float             pixelsPerMeter                      = 4000.0;
float             radsPerDegree                       = 0.01745;

/* Pantagraph link parameters in meters */
float             l                                   = 0.07;
float             L                                   = 0.09;

/* End effector radius in meters */
float             rEE                                 = 0.003;

// End effector raduis for visuals
float             rEE_vis                             = 0.003;

/* Virtual wall parameter  */
float             kWall                               = 100;
float             hWall                               = 0.015;
float             hWall2                              = 0.005;
PVector           fWall                               = new PVector(0, 0);
PVector           penWall                             = new PVector(0, 0);
// For grey lines
PVector           penWallGrey                         = new PVector(0, 0);

// For right image
ArrayList<Integer[]> allLinePositions = new ArrayList<Integer[]>();
// For left image
ArrayList<Integer[]> allLinePositions_left = new ArrayList<Integer[]>();
ArrayList<Integer[]> allLinePositions_left_grey = new ArrayList<Integer[]>();

// For horizontal lines
ArrayList<Integer[]> allHorLinePositions = new ArrayList<Integer[]>();

/* Generic data for a 2DOF device */
/* Joint space */
PVector           angles                              = new PVector(0, 0);
PVector           torques                             = new PVector(0, 0);

/* Task space */
PVector           posEE                               = new PVector(0, 0);
PVector           fEE                                 = new PVector(0, 0);

/* Device graphical position */
PVector           deviceOrigin                        = new PVector(0, 0);

/* Graphical elements */
PShape pGraph, joint, endEffector, endEffector_1, endEffector_2, endEffector_3, endEffector_4;

// All lines
ArrayList<PShape> allLines = new ArrayList<PShape>();

// Lines for left image
ArrayList<PShape> allLines_left = new ArrayList<PShape>();
ArrayList<PShape> allLines_left_grey = new ArrayList<PShape>();

// Horizontal lines
ArrayList<PShape> allHorLines = new ArrayList<PShape>();              

PImage render_image;
int render_image_margin_x = 475;
int render_image_margin_y = 100;

int top_margin_images = 300;
PImage image_1;
int left_margin_image_1 = 20;
PImage image_2;
int left_margin_image_2 = 40;
PImage image_3;
int left_margin_image_3 = 60;
PImage image_4;
int left_margin_image_4 = 80;

PShape[] right_image_lines = {};

// File names for all the different trees
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

// Arrays for different facts
String[] aspect_facts = {"aspect_facts 1", "aspect_facts 2"};
String[] chestnut_facts = {"chestnut_facts 1", "chestnut_facts 2"};
String[] cedar_facts = {"cedar_facts 1", "cedar_facts 2"};
String[] oak_facts = {"oak_facts 1", "oak_facts 2"};

IntList combinations = new IntList();

// Array to switch between images with arrow keys
String[] all_images = oak_trees;
int cur_image = 0;
int default_width = 0;
int default_height = 0; 

// State to control which set of trees should be rendered
String tree_state = "oak";

// Rendering forces technique
int force_render_technique = 1;

SimulationThread st = new SimulationThread();
boolean changed_state = false;
int time_with_forces = 0;

// States for testing
String state = "regular";
boolean show_lines = false;

boolean is_experiment_active = false;
boolean game_over = false;
float theta; // For tree
float intro_tree_timer = 0;
boolean intro_tree_direction = true;

PFont font;

/* End elements definition *********************************************************************************************/ 

/* Setup section *******************************************************************************************************/
void setup() {
  /* Put setup code here, run once: */
  
  /* Screen size definition */
  size(1232, 750);
  
  printArray(PFont.list());
  font = createFont("Georgia", 32, true);
  textFont(font);

  /* Device setup */
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
    
  /* Visual elements setup */
  background(125);
  deviceOrigin.add(width/2, 0);
  
  /* Create pantagraph graphics */
  create_pantagraph();

  // Get default height and width to use for all images
  PImage temp = loadImage(original_image);
  
  default_width = temp.width;
  default_height = temp.height;
  
  init_combinations();

  /* Setup framerate speed */
  frameRate(baseFrameRate);
  
  /* Setup simulation thread to run at 1kHz */ 
  scheduler.scheduleAtFixedRate(st, 1, 1, MILLISECONDS);
}
/* end setup section ***************************************************************************************************/

/* draw section ********************************************************************************************************/
void draw() {
  // Things displayed when experiment is going
  if (is_experiment_active) {
    /* Put graphical code here, runs repeatedly at defined framerate in setup, else default at 60fps: */
    if (renderingForce == false) {
      update_animation(angles.x*radsPerDegree, angles.y*radsPerDegree, posEE.x, posEE.y);
    }

    if (changed_state && time_with_forces == 0) {
      scheduler.shutdown();
      st = new SimulationThread();
      scheduler = Executors.newScheduledThreadPool(1);
      scheduler.scheduleAtFixedRate(st, 1, 1, MILLISECONDS);
      changed_state = false;

      println("force reset");
    }
  }
  // Things displayed when experiment is not 'going'
  else {
    // Intro
    if (!game_over) {
      update_intro();
    } 
    // Conclusion
    else {
      update_conclusion();
    }
  }
}
/* end draw section ****************************************************************************************************/

/* simulation section **************************************************************************************************/
class SimulationThread implements Runnable {
  public void run() {
    /* put haptic simulation code here, runs repeatedly at 1kHz as defined in setup */
    if (!is_experiment_active)
      return;


    renderingForce = true;
    
    time_with_forces++;
    
    if(haplyBoard.data_available()) {
      /* GET END-EFFECTOR STATE (TASK SPACE) */
      widgetOne.device_read_data();
    
      angles.set(widgetOne.get_device_angles()); 
      posEE.set(widgetOne.get_device_position(angles.array()));
      posEE.set(device_to_graphics(posEE)); 
      
      /* haptic wall force calculation */
      fWall.set(0, 0);
      
      // change force offsets for main vertical lines depending on tree type
      //println(posEE.x, posEE.y);
      if (tree_state == "oak") {
        float force_offset = 0.005 + abs(posEE.x) * 1.5; // To account for weakness when the end effector is perpendicular to the motors
        if (( posEE.x > 0.02) || (posEE.x < -0.02)) {
          force_offset = force_offset + 0.01;
        } else if ((( posEE.x < 0.02) && (posEE.x > -0.02)) && posEE.y < 0.05){
          force_offset = force_offset + 0.005;
        } else if ((( posEE.x < 0.02) && (posEE.x > -0.02)) && posEE.y >= 0.05){
          force_offset = force_offset + 0.02;
        }
        float height_offset = (posEE.y + rEE)/1.75; // To account for the difference in force close and far from the motors
      
        // Adjustments to height offset
        if (posEE.y < 0.03) {
          height_offset = height_offset + 0.05;
        }

        penWall.set(1/(height_offset + force_offset), 0);
      }
      else if (tree_state == "cedar") {
        float force_offset = 0.005 + abs(posEE.x) * 1.5; // To account for weakness when the end effector is perpendicular to the motors
        if (( posEE.x > 0.02) || (posEE.x < -0.02)) {
          force_offset = force_offset + 0.01;
        } else if ((( posEE.x < 0.02) && (posEE.x > -0.02)) && posEE.y < 0.05){
          force_offset = force_offset + 0.005;
        } else if ((( posEE.x < 0.02) && (posEE.x > -0.02)) && posEE.y >= 0.05){
          force_offset = force_offset + 0.02;
        }
        float height_offset = (posEE.y + rEE)/1.75; // To account for the difference in force close and far from the motors
      
        // Adjustments to height offset
        if (posEE.y < 0.03) {
          height_offset = height_offset + 0.05;
        }

        penWall.set(1/((height_offset + force_offset)*1.25), 0);
      }
      else if (tree_state == "chestnut") {
        float force_offset = 0.005 + abs(posEE.x) * 1.5; // To account for weakness when the end effector is perpendicular to the motors
        if (( posEE.x > 0.02) || (posEE.x < -0.02)) {
          force_offset = force_offset + 0.03;
        } else if ((( posEE.x < 0.02) && (posEE.x > -0.02)) && posEE.y < 0.05){
          force_offset = force_offset + 0.04;
        } else if ((( posEE.x < 0.02) && (posEE.x > -0.02)) && posEE.y >= 0.05){
          force_offset = force_offset + 0.04;
        }
        float height_offset = (posEE.y + rEE)/1.75; // To account for the difference in force close and far from the motors
      
        // Adjustments to height offset
        if (posEE.y < 0.03) {
          height_offset = height_offset + 0.05;
        }

        penWall.set(0, 1/(height_offset + force_offset) * 1.1);
      }
      else { // Aspen
        float force_offset = 0.005 + abs(posEE.x)*1.5; // To account for weakness when the end effector is perpendicular to the motors
        if (( posEE.x > 0.02) || (posEE.x < -0.02)) {
          force_offset = force_offset + 0.01;
        } else if ((( posEE.x < 0.02) && (posEE.x > -0.02)) && posEE.y < 0.05){
          force_offset = force_offset + 0.005;
        } else if ((( posEE.x < 0.02) && (posEE.x > -0.02)) && posEE.y >= 0.05){
          force_offset = force_offset + 0.02;
        }
        float height_offset = (posEE.y + rEE)/1.75; // To account for the difference in force close and far from the motors
      
        // Adjustments to height offset
        if (posEE.y < 0.03) {
          height_offset = height_offset + 0.05;
        }

        penWall.set(0, 1/((height_offset + force_offset)*2));
      }

      switch (force_render_technique) {
        case 1: // 
          float[][] line_endeffector_offsets = new float[allLinePositions.size()][4];
        
          for (int i = 0; i < allLinePositions.size(); i++) {
            // x1 offset
            line_endeffector_offsets[i][0] = allLinePositions.get(i)[0] - (posEE.x * 4000.0 + render_image.width);
            // y1 offset
            line_endeffector_offsets[i][1] = allLinePositions.get(i)[1] - (posEE.y * 4000.0); 
            // x2 offset
            line_endeffector_offsets[i][2] = allLinePositions.get(i)[2] - (posEE.x * 4000.0 + render_image.width);
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
            
          // Change force offset for horizontal lines depending on tree type
          if (tree_state == "oak") {
            penWall.set(0, 10);
          } else if (tree_state == "cedar") {
            penWall.set(0, 5);
          } else if (tree_state == "chestnut") {
            penWall.set(5, 0);
            if ((( posEE.x < 0.02) && (posEE.x > -0.02))){
              penWall.set(1, 0);
            }
          } else { // Aspen
            penWall.set(5, 0);
          }
        
          float[][] hor_line_endeffector_offsets = new float[allHorLinePositions.size()][4];
          
          for (int i=0; i < allHorLinePositions.size(); i++) {
            // x1 offset
            hor_line_endeffector_offsets[i][0] = allHorLinePositions.get(i)[0] - (posEE.x*4000.0 + render_image.width);
            // y1 offset
            hor_line_endeffector_offsets[i][1] = allHorLinePositions.get(i)[1] - (posEE.y*4000.0); 
            // x2 offset
            hor_line_endeffector_offsets[i][2] = allHorLinePositions.get(i)[2] - (posEE.x*4000.0 + render_image.width);
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
            float height_offset_grey = (posEE.y + rEE)/1.0; // to account for the difference in force close and far from the motors
        
            // adjustments to height offset
            if (posEE.y < 0.03) {
              height_offset_grey = height_offset_grey + 0.05;
            }

            penWallGrey.set(0, 1/((height_offset_grey + force_offset_grey)*4));
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
            float height_offset_grey = (posEE.y + rEE)/1.0; // to account for the difference in force close and far from the motors
        
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
            line_endeffector_offsets_left[i][0] = allLinePositions_left.get(i)[0] - (posEE.x*4000.0 + render_image.width);
            // y1 offset
            line_endeffector_offsets_left[i][1] = allLinePositions_left.get(i)[1] - (posEE.y*4000.0); 
            // x2 offset
            line_endeffector_offsets_left[i][2] = allLinePositions_left.get(i)[2] - (posEE.x*4000.0 + render_image.width);
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
            line_endeffector_offsets_left_grey[i][0] = allLinePositions_left_grey.get(i)[0] - (posEE.x*4000.0 + render_image.width);
            // y1 offset
            line_endeffector_offsets_left_grey[i][1] = allLinePositions_left_grey.get(i)[1] - (posEE.y*4000.0); 
            // x2 offset
            line_endeffector_offsets_left_grey[i][2] = allLinePositions_left_grey.get(i)[2] - (posEE.x*4000.0 + render_image.width);
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
void init_combinations() {
  combinations = new IntList();
  int count_render_techniques = 3;
  int count_types_trees = 4;
  int count_images_per_tree_type = 4;

  for (int i = 1; i <= count_render_techniques; ++i) {
    for (int j = 1; j < count_types_trees; ++j) {
      for (int k = 1; k < count_images_per_tree_type; ++k) {
        combinations.append(i * 1000 + j * 100 + k);
      }
    }
  }
}

void start_experiment() {
  
  // Calculates image lines and placement
  process_image(all_images[0]);
}

void process_image(String image) {
  // Variable to make sure the line forces are actually rendered in the right spot
  int force_centering = 290;
  
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
  render_image = loadImage(image);
  updateImages();

  // Resize if needed
  if (render_image.width != default_width || render_image.height != default_height) {
    render_image.resize(default_width, default_height);
  }
  
  // Original images
  render_image.loadPixels();
  render_image.filter(THRESHOLD);
  
  // If the average is higher than 125, then the image likely contains more small black lines
  int threshold = 10;
  int threshold_grey = 3; // For the smaller lines

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
  
  for (int i = 0; i < render_image.width; i++) {
    for (int j = 0; j < render_image.height; j++) {
      float pixel = red(render_image.pixels[i + j * render_image.width]);

      // If pixel is black
      if(pixel < 10) {
        if(black == 0) {
          startJ = j;
        }
        black++;
      }

      // If pixel is not black
      if (pixel >= 5 || j == render_image.height - 1) {
        if ((black >= threshold_grey) && (black < threshold)) {
          Integer[] curLinePos = {render_image_margin_x + i - force_centering, render_image_margin_y + startJ, render_image_margin_x + i - force_centering, render_image_margin_y + j - 1};
          PShape temp = createShape(LINE, render_image_margin_x + i, render_image_margin_y + startJ, render_image_margin_x + i, render_image_margin_y + j - 1);
          //println(curLinePos);
          temp.setStroke(color(0,150,150));
        
          // add to list
          allLinePositions_left_grey.add(curLinePos);
          allLines_left_grey.add(temp);
        }
        else if (black >= threshold) {
          Integer[] curLinePos = {render_image_margin_x + i - force_centering, render_image_margin_y + startJ, render_image_margin_x + i - force_centering, render_image_margin_y + j - 1};
          PShape temp = createShape(LINE, render_image_margin_x + i, render_image_margin_y + startJ, render_image_margin_x + i, render_image_margin_y + j - 1);
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
    for (int j = 0; j < render_image.height; j=j+20) {
      Integer[] curLinePos = {render_image_margin_x - force_centering, render_image_margin_y + j, render_image_margin_x + render_image.width - force_centering, render_image_margin_y + j};
      PShape temp = createShape(LINE, render_image_margin_x, render_image_margin_y + j, render_image_margin_x + render_image.width, render_image_margin_y + j);
      //println(curLinePos);
      temp.setStroke(color(0,0,150));
        
      // add to list
      allHorLinePositions.add(curLinePos);
      allHorLines.add(temp);
    }
  }
  else {
    for (int j = 0; j < render_image.width; j=j+20) {
      Integer[] curLinePos = {render_image_margin_x + j - force_centering, render_image_margin_y, render_image_margin_x + j - force_centering, render_image_margin_y + render_image.height};
      PShape temp = createShape(LINE, render_image_margin_x + j, render_image_margin_y, render_image_margin_x + j, render_image_margin_y + render_image.height);
      //println(curLinePos);
      temp.setStroke(color(0,0,150));
        
      // add to list
      allHorLinePositions.add(curLinePos);
      allHorLines.add(temp);
    }
  }
}

void create_pantagraph() {
  float rEEAni = pixelsPerMeter * (rEE_vis/2);
  
  endEffector = createShape(ELLIPSE, deviceOrigin.x, deviceOrigin.y, 2*rEEAni, 2*rEEAni);
  endEffector.setFill(color(255, 255, 0));
  endEffector_1 = createShape(ELLIPSE, deviceOrigin.x - 283 * 1.5 - left_margin_image_1 * 1.5, deviceOrigin.y + 200, 2*rEEAni, 2*rEEAni);
  endEffector_2 = createShape(ELLIPSE, deviceOrigin.x - 283 * 0.5 - left_margin_image_1 * 0.5, deviceOrigin.y + 200, 2*rEEAni, 2*rEEAni);
  endEffector_3 = createShape(ELLIPSE, deviceOrigin.x + 283 * 0.5 + left_margin_image_1 * 0.5, deviceOrigin.y + 200, 2*rEEAni, 2*rEEAni);
  endEffector_4 = createShape(ELLIPSE, deviceOrigin.x + 283 * 1.5 + left_margin_image_1 * 1.5, deviceOrigin.y + 200, 2*rEEAni, 2*rEEAni);
  strokeWeight(1);
}

PVector calculate_line_force(float[] offsets, PVector pen_wall, int direction) {
  PVector force = new PVector(0,0);
  //println(offsets);
  //Float[] test = {offsets[0] - Math.round(offsets[0]), offsets[1] - Math.round(offsets[1]), offsets[2] - Math.round(offsets[2]), offsets[3] - Math.round(offsets[3])}; 
  //println(offsets[0], offsets[1], offsets[2], offsets[3]);
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

void updateImages() {
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
}

void update_animation(float th1, float th2, float xE, float yE) {
  background(10);
  xE = pixelsPerMeter * xE;
  yE = pixelsPerMeter * yE;
  
  switch (state) {
    case "regular": 
      break;
    case "baw":
      image_1.filter(THRESHOLD);
      image_2.filter(THRESHOLD);
      image_3.filter(THRESHOLD);
      image_4.filter(THRESHOLD);
      break;
    case "grey":
      image_1.filter(GRAY);
      image_2.filter(GRAY);
      image_3.filter(GRAY);
      image_4.filter(GRAY);
      break;
  }

  // Show 4 images
  image(image_1, left_margin_image_1, top_margin_images);
  left_margin_image_2 = image_1.width + left_margin_image_1 * 2;
  image(image_2, left_margin_image_2, top_margin_images);
  left_margin_image_3 = image_1.width * 2+ left_margin_image_1 * 3;
  image(image_3, left_margin_image_3, top_margin_images);
  left_margin_image_4 = image_1.width * 3 + left_margin_image_1 * 4;
  image(image_4, left_margin_image_4, top_margin_images);

  // Title
  textAlign(LEFT, TOP);
  textSize(20);
  text("Haptic Herbology", 5, 5);

  // Instructions
  textAlign(CENTER, CENTER);
  textSize(30);
  text("Which image do you think is being represented right now?", width / 2, height / 10);
  text("Press the number on the keyboard that corresponds to the image.", width / 2, height / 10 + 35);

  // 'Random' fact


  // Image titles
  textAlign(LEFT, TOP);
  textSize(30);
  int top_margin_text = top_margin_images - 50;
  text("Oak (1)", left_margin_image_1 + 100, top_margin_text);
  text("Cedar (2)", left_margin_image_2 + 90, top_margin_text);
  text("Chestnut (3)", left_margin_image_3 + 60, top_margin_text);
  text("Aspen (4)", left_margin_image_4 + 80, top_margin_text);
  

  // Debugging lines
  if(show_lines){
    image(render_image, render_image_margin_x, render_image_margin_y);

    switch (force_render_technique) {
      case 1:
        for(int i=0; i < allLines.size(); i++) {
          shape(allLines.get(i));
        }
        for(int i=0; i < allHorLines.size(); i++) {
          shape(allHorLines.get(i));
        }
        break;
      case 2:
        for(int i=0; i < allLines_left.size(); i++) {
          shape(allLines_left.get(i));
        }
        for(int i=0; i < allLines_left_grey.size(); i++) {
          shape(allLines_left_grey.get(i));
        }
        for(int i=0; i < allHorLines.size(); i++) {
          shape(allHorLines.get(i));
        }
        break;
      case 3:
        break;
    }
  }
  
  translate(xE, yE);

  // For debugging
  if(show_lines) 
    shape(endEffector); // Actual end-effector location

  // End effector on each images
  shape(endEffector_1); // EE on Oak
  shape(endEffector_2); // EE on Cedar
  shape(endEffector_3); // EE on Chestnut
  shape(endEffector_4); // EE on Aspen
}

void update_intro() {
  println("Update_intro ", intro_tree_timer);
  background(0);

  intro_tree_timer += (intro_tree_direction? 0.1 : -0.1);
  
  if(intro_tree_timer >= 100)
    intro_tree_direction = false;
  
  if(intro_tree_timer <= 0)
    intro_tree_direction = true;

  textAlign(CENTER, CENTER);
  text("Welcome to this Haptic Herbology informal pre-testing!", width/2, height/5);
  textSize(26);
  text("Press `Enter` to begin.", width/2, height/3);

  drawTree();
}

void update_conclusion() {

}

PVector device_to_graphics(PVector deviceFrame) {
  return deviceFrame.set(-deviceFrame.x, deviceFrame.y);
}

PVector graphics_to_device(PVector graphicsFrame) {
  return graphicsFrame.set(-graphicsFrame.x, graphicsFrame.y);
}

void participantSelection(int selected_image) {
  println("Participant has selected image ", selected_image);



}

// Change state when any key pressed
void keyPressed() {
  println("keyPressed", keyCode);

  if (keyCode == 10) { // Enter key
    is_experiment_active = !is_experiment_active;
  }
  // Nothing else should work until the experiment is started.
  if (!is_experiment_active)
    return;

  // Participant pick
  else if (keyCode == '1') {
    participantSelection(1);
  } else if (keyCode == '2') {
    participantSelection(2);
  } else if (keyCode == '3') {
    participantSelection(3);
  } else if (keyCode == '4') {
    participantSelection(4);
  }

  // Toggle rendering techniques
  else if (keyCode == 38) { // Up
    if(force_render_technique == 3) 
      force_render_technique = 0;
    force_render_technique++;
  } else if (keyCode == 40) { // Down
    if(force_render_technique == 1) 
      force_render_technique = 4;
    force_render_technique--;
  }


  // Toggle image color
  else if (keyCode == 32) { // Space bar
    if(state == "regular") state = "baw";
    else if(state == "baw") state = "grey";
    else if(state == "grey") state = "regular";

    updateImages();
  }

  // Toggle PLines
  else if(keyCode == 80){ // p
    show_lines = !show_lines;
  }

  // Toggle which type of tree is rendered
  else if (keyCode == 79) { // o
    tree_state = "oak";
    all_images = oak_trees;
    process_image(all_images[cur_image]);
    time_with_forces = 0;
    changed_state = true;
  }
  else if (keyCode == 67) { // c
    tree_state = "cedar";
    all_images = cedar_trees;
    process_image(all_images[cur_image]);
    time_with_forces = 0;
    changed_state = true;
  }
  else if (keyCode == 72) { // h
    tree_state = "chestnut";
    all_images = chestnut_trees;
    process_image(all_images[cur_image]);
    time_with_forces = 0;
    changed_state = true;
  }
  else if (keyCode == 65) { // a
    tree_state = "aspen";
    all_images = aspen_trees;
    process_image(all_images[cur_image]);
    time_with_forces = 0;
    changed_state = true;
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

  println("force_render_technique: ", force_render_technique);
  println("state: ", state);
  println("tree_state: ", tree_state);
  println("cur_image: ", cur_image);
}
/* end helper functions section ****************************************************************************************/


void drawTree() {
  stroke(255);
  // Let's pick an angle 0 to 90 degrees based on the mouse position
  float a = (intro_tree_timer / (float) 100) * 45f;
  // Convert it to radians
  theta = radians(a);
  // Start the tree from the bottom of the screen
  translate(width/2,height);
  // Draw a line 120 pixels
  line(0,0,0,-120);
  // Move to the end of that line
  translate(0,-120);
  // Start the recursive branching!
  branch(120);
}

void branch(float h) {
  // Each branch will be 2/3rds the size of the previous one
  h *= 0.66;
  
  // All recursive functions must have an exit condition!!!!
  // Here, ours is when the length of the branch is 2 pixels or less
  if (h > 2) {
    pushMatrix();    // Save the current state of transformation (i.e. where are we now)
    rotate(theta);   // Rotate by theta
    line(0, 0, 0, -h);  // Draw the branch
    translate(0, -h); // Move to the end of the branch
    branch(h);       // Ok, now call myself to draw two new branches!!
    popMatrix();     // Whenever we get back here, we "pop" in order to restore the previous matrix state
    
    // Repeat the same thing, only branch off to the "left" this time!
    pushMatrix();
    rotate(-theta);
    line(0, 0, 0, -h);
    translate(0, -h);
    branch(h);
    popMatrix();
  }
}
