import processing.svg.*;
import processing.pdf.*;

/*
 * When generating high-resolution images, the CONFIG_SCALE_FACTOR
 * is used as the multiplier for the number of pixels. So if you
 * have a 1000x1000 pixel canvas, and you set a scale factor of 5,
 * then you get a 5000x5000 pixel image.
 */
int CONFIG_SCALE_FACTOR = 5;

/* The width and height of your screen canvas in pixels */
int CONFIG_WIDTH_PIXELS = 1000;
int CONFIG_HEIGHT_PIXELS = 1000;

/*
 * Encode a given point (x, y) into the different regions of
 * a clip window as specified by its top-left corner (cx, cy)
 * and it's width and height (cw, ch).
 */
int encode_endpoint(
  float x, float y,
  float clipx, float clipy, float clipw, float cliph)
{
  int code = 0; /* Initialized to being inside clip window */

  /* Calculate the min and max coordinates of clip window */
  float xmin = clipx;
  float xmax = clipx + clipw;
  float ymin = clipy;
  float ymax = clipy + clipw;

  if (x < xmin)       /* to left of clip window */
    code |= (1 << 0);
  else if (x > xmax)  /* to right of clip window */
    code |= (1 << 1);

  if (y < ymin)       /* below clip window */
    code |= (1 << 2);
  else if (y > ymax)  /* above clip window */
    code |= (1 << 3);

  return code;
}

boolean line_clipped(
  float x0, float y0, float x1, float y1,
  float clipx, float clipy, float clipw, float cliph) {

  /* Stores encodings for the two endpoints of our line */
  int e0code, e1code;

  /* Calculate X and Y ranges for our clip window */
  float xmin = clipx;
  float xmax = clipx + clipw;
  float ymin = clipy;
  float ymax = clipy + cliph;

  /* Whether the line should be drawn or not */
  boolean accept = false;

  do {
    /* Get encodings for the two endpoints of our line */
    e0code = encode_endpoint(x0, y0, clipx, clipy, clipw, cliph);
    e1code = encode_endpoint(x1, y1, clipx, clipy, clipw, cliph);

    if (e0code == 0 && e1code == 0) {
      /* If line inside window, accept and break out of loop */
      accept = true;
      break;
    } else if ((e0code & e1code) != 0) {
      /*
       * If the bitwise AND is not 0, it means both points share
       * an outside zone. Leave accept as 'false' and exit loop.
       */
      break;
    } else {
      /* Pick an endpoint that is outside the clip window */
      int code = e0code != 0 ? e0code : e1code;

      float newx = 0, newy = 0;
      
      /*
       * Now figure out the new endpoint that needs to replace
       * the current one. Each of the four cases are handled
       * separately.
       */
      if ((code & (1 << 0)) != 0) {
        /* Endpoint is to the left of clip window */
        newx = xmin;
        newy = ((y1 - y0) / (x1 - x0)) * (newx - x0) + y0;
      } else if ((code & (1 << 1)) != 0) {
        /* Endpoint is to the right of clip window */
        newx = xmax;
        newy = ((y1 - y0) / (x1 - x0)) * (newx - x0) + y0;
      } else if ((code & (1 << 3)) != 0) {
        /* Endpoint is above the clip window */
        newy = ymax;
        newx = ((x1 - x0) / (y1 - y0)) * (newy - y0) + x0;
      } else if ((code & (1 << 2)) != 0) {
        /* Endpoint is below the clip window */
        newy = ymin;
        newx = ((x1 - x0) / (y1 - y0)) * (newy - y0) + x0;
      }
      
      /* Now we replace the old endpoint depending on which we chose */
      if (code == e0code) {
        x0 = newx;
        y0 = newy;
      } else {
        x1 = newx;
        y1 = newy;
      }
    }
  } while (true);

  /* Only draw the line if it was not rejected */
  if (accept)
    line(x0, y0, x1, y1);

  return accept;
}

/*
 * Draw a square with top-left corner at (x, y), and side 'w',
 * filled with clipped lines at an angle 'a' and spaced apart
 * a distance 'step'.
 */
void draw_square(float x, float y, float w, float step, float a)
{
  float xstart = x + random(w);
  float ystart = y + random(w);

  float slope = tan(a);
  float c = ystart - slope * xstart;

  boolean downAccept = true;
  boolean upAccept = true;
  
  int i = 0;
  
  //for (int i = 0; i < w / step; i++) {
  while (downAccept || upAccept) {
    float x0 = x - w/2;
    float y0 = slope * x0 + c + (float)i * step / cos(a);
    float x1 = x + w + w/2;
    float y1 = slope * x1 + c + (float)i * step / cos(a);;
    upAccept = line_clipped(x0, y0, x1, y1, x, y, w, w);
    
    x0 = x - w/2;
    y0 = slope * x0 + c - (float)i * step / cos(a);
    x1 = x + w + w/2;
    y1 = slope * x1 + c - (float)i * step / cos(a);
    downAccept = line_clipped(x0, y0, x1, y1, x, y, w, w);
    
    i++;
  }
}

PImage img;

void render() {
  /* Write your drawing code here */
  int CELL_SIZE = 25;
  
  smooth();
  stroke(0);
  strokeWeight(2);
  background(255);
  
  /* Uncomment for image-based line spacing */
  //img = loadImage("test.jpg");
  //img.filter(GRAY);
  
  for (int i = 0; i < (width / CELL_SIZE) + 1; i++) {
    for (int j = 0; j < (height / CELL_SIZE) + 1; j++) {
      /* 1. Noise-based angle */
      //float noise_scale = 0.005;
      //float angle = noise((i * CELL_SIZE + CELL_SIZE/2) * noise_scale, (j * CELL_SIZE + CELL_SIZE/2) * noise_scale) * 360;
      /* 2. Random angle */
      float angle = random(180);
      
      /* 1. Image-based spacing. Remember to uncomment image initialization above */
      //float spacing = map(red(img.get((i * CELL_SIZE + CELL_SIZE/2), (j * CELL_SIZE + CELL_SIZE/2))), 0, 255, 1, 4);
      /* 2. Random spacing in a given range */
      float spacing = random(2, 15);
      /* 3. Y-axis-based spacing */
      //float spacing = map(j, 0, (height/CELL_SIZE) + 1, 15, 2);
      
      draw_square(i*CELL_SIZE, j*CELL_SIZE, CELL_SIZE, spacing, radians(angle));
    }
  }
}



/*
 * =========================================================
 * Ignore everything below this line! Just press '?' while
 * your sketch is running to get a list of available options
 * to export your sketch into various formats.
 * =========================================================
 */

int seed;

void settings() {
  size(CONFIG_WIDTH_PIXELS, CONFIG_HEIGHT_PIXELS);
}

void setup() {
  seed = millis();
  seededRender();
}

void draw() {
}

void seededRender() {
  randomSeed(seed);
  noiseSeed(seed);
  render();
}

void keyPressed() {
  switch(key) {
    case 'l':
      saveLowRes();
      break;
    case 'h':
      saveHighRes(CONFIG_SCALE_FACTOR);
      break;
    case 'p':
      savePDF();
      break;
    case 's':
      saveSVG();
      break;
    case 'n':
      seed = millis();
      seededRender();
      break;
    case '?':
      println("Keyboard shortcuts:");
      println("  n: Generate a new seeded image");
      println("  l: Save low-resolution image");
      println("  h: Save high-resolution image");
      println("  p: Save PDF version");
      println("  s: Save SVG version");
  }
}

void saveLowRes() {
  println("Saving low-resolution image...");
  save(seed + "-lowres.png");
  println("Finished");
}

void saveHighRes(int scaleFactor) {
  PGraphics hires = createGraphics(
                        width * scaleFactor,
                        height * scaleFactor,
                        JAVA2D);
  println("Saving high-resolution image...");
  beginRecord(hires);
  hires.scale(scaleFactor);
  seededRender();
  endRecord();
  hires.save(seed + "-highres.png");
  println("Finished");
}

void savePDF() {
  println("Saving PDF image...");
  beginRecord(PDF, seed + "-vector.pdf");
  seededRender();
  endRecord();
  println("Finished");
}

void saveSVG() {
  println("Saving SVG image...");
  beginRecord(SVG, seed + "-vector.svg"); 
  seededRender();
  endRecord();
  println("Finished");
}