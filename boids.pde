Boid barry;
ArrayList<Boid> boids;
ArrayList<Avoid> avoids;
ArrayList<Transmitter> transmitters;

float globalScale = .61;
float eraseRadius = 30;
String tool = "boids";

// boid control
float maxSpeed;
float friendRadius;
float crowdRadius;
float avoidRadius;
float coheseRadius;
float activation_threshold;


boolean option_friend = true;
boolean option_crowd = true;
boolean option_avoid = true;
boolean option_noise = true;
boolean option_cohese = true;
boolean option_danger = true;

// gui crap
int messageTimer = 0;
String messageText = "";
String endangeredText = "";

void setup () {
  size(1300, 731); //Ratio of 1.7777..7..7
  textSize(16);
  recalculateConstants();
  boids = new ArrayList<Boid>();
  avoids = new ArrayList<Avoid>();
  transmitters = new ArrayList<Transmitter>(); // ziye
  for (int x = 100; x < width - 100; x+= 100) {
    for (int y = 100; y < height - 100; y+= 100) {
      //   boids.add(new Boid(x + random(3), y + random(3)));
      //    boids.add(new Boid(x + random(3), y + random(3)));
    }
  }
  //Uncomment the following to start with an arena
  setupWalls();
}

void recalculateConstants () {
  maxSpeed = 1.6 * globalScale; //Old value 2.1
  activation_threshold= 350 * globalScale; // For transmitters
  friendRadius = 60 * globalScale;
  crowdRadius = (friendRadius / 1.3);
  avoidRadius = 90 * globalScale;
  coheseRadius = friendRadius;
}


void setupWalls() {
  avoids = new ArrayList<Avoid>();
  for (int x = 0; x < width; x+= 17) {
    avoids.add(new Avoid(x, 10));
    avoids.add(new Avoid(x, height - 10));
  }
  
  //for (int x = 600; x <= 900; x+= 13) {
  //  avoids.add(new Avoid(x, 500));
  //  avoids.add(new Avoid(x, 300));
  //}
  //for (int y = 300; y < 500; y+= 13) {
  //  avoids.add(new Avoid(600, y));
  //  avoids.add(new Avoid(900, y));
  //}
  
}

void setupCircle() {
  avoids = new ArrayList<Avoid>();
  for (int x = 0; x < 50; x+= 1) {
    float dir = (x / 50.0) * TWO_PI;
    avoids.add(new Avoid(width * 0.5 + cos(dir) * height*.4, height * 0.5 + sin(dir)*height*.4));
  }
}


void draw () {
  noStroke();
  colorMode(HSB);
  fill(0, 100);
  rect(0, 0, width, height);


  if (tool == "erase") {
    noFill();
    stroke(0, 100, 260);
    rect(mouseX - eraseRadius, mouseY - eraseRadius, eraseRadius * 2, eraseRadius *2);
    if (mousePressed) {
      erase();
    }
  } else if (tool == "avoids") {
    noStroke();
    fill(0, 200, 200);
    ellipse(mouseX, mouseY, 15, 15);
  } else if (tool == "transmitters") {
    noStroke();
    fill(100);
    triangle(mouseX-10, mouseY+10, mouseX, mouseY-10, mouseX+10, mouseY+10);
  }
  int numberEndangered=0;
  for (int i = 0; i <boids.size(); i++) {
    Boid current = boids.get(i);
    current.go();
    current.draw();
    if (current.endangered) numberEndangered ++;
  }
  countEndangered("Number of endangered fish: " + numberEndangered);

  for (int i = 0; i <avoids.size(); i++) {
    Avoid current = avoids.get(i);
    current.go();
    current.draw();
  }

  for (int i = 0; i <transmitters.size(); i++) {
    Transmitter current = transmitters.get(i);
    //current.go();
    current.draw();
  }

  if (messageTimer > 0) {
    messageTimer -= 1;
  }
  drawGUI();
}

void keyPressed () {
  if (key == 'b') {
    tool = "boids";
    message("Add boids");
  } else if (key == 'o') {
    tool = "avoids";
    message("Place obstacles");
  } else if (key == 'e') {
    tool = "erase";
    message("Eraser");
  } else if (key == 't') {
    tool = "transmitters";
    message("Add transmitter");
  } else if (key == '-') {
    message("Decreased scale");
    globalScale *= 0.8;
  } else if (key == '=') {
    message("Increased Scale");
    globalScale /= 0.8;
  } else if (key == '1') {
    option_friend = option_friend ? false : true;
    message("Turned friend allignment " + on(option_friend));
  } else if (key == '2') {
    option_crowd = option_crowd ? false : true;
    message("Turned crowding avoidance " + on(option_crowd));
  } else if (key == '3') {
    option_avoid = option_avoid ? false : true;
    message("Turned obstacle avoidance " + on(option_avoid));
  } else if (key == '4') {
    option_cohese = option_cohese ? false : true;
    message("Turned cohesion " + on(option_cohese));
  } else if (key == '5') {
    option_noise = option_noise ? false : true;
    message("Turned noise " + on(option_noise));
  } else if (key == ',') {
    setupWalls();
  } else if (key == '.') {
    setupCircle();
  }
  recalculateConstants();
}

void drawGUI() {
  if (messageTimer > 0) {
    fill((min(30, messageTimer) / 30.0) * 255.0);

    text(messageText, 10, height - 25);
  }
  fill(255.0);
  text(endangeredText, 1080, height - 25);
  text("Total boids: " + boids.size(), 950, height - 25);
  text("Tagged fish percentage: " + (int)(100*tagged_probability) + "%", 730, height - 25);
  text("Tag activation percentage: " + (int)(100*activated_tags_percentage) + "%", 500, height-25);
}

String s(int count) {
  return (count != 1) ? "s" : "";
}

String on(boolean in) {
  return in ? "on" : "off";
}

void mousePressed () {
  switch (tool) {
  case "boids":
    int number_tags=int(10*tagged_probability);
    int[] tags_distribution = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
    while(number_tags>0){
      int index=0;
      do {
        index=int(random(10));
      }while(tags_distribution[index]==1);
      tags_distribution[index]=1;
      number_tags--;
    }
    for(int i=0; i<10; i++){
      boolean tagged=false;
      if(tags_distribution[i]==1) tagged=true;
      
      boids.add(new Boid(mouseX, mouseY+2*i,tagged));
    }
    break;
  case "avoids":
    avoids.add(new Avoid(mouseX, mouseY));
    break;
  case "transmitters": 
    transmitters.add(new Transmitter(mouseX, mouseY));
    break;
  }
}

void erase () {
  for (int i = boids.size()-1; i > -1; i--) {
    Boid b = boids.get(i);
    if (abs(b.pos.x - mouseX) < eraseRadius && abs(b.pos.y - mouseY) < eraseRadius) {
      boids.remove(i);
    }
  }
  
  for (int i = avoids.size()-1; i > -1; i--) {
    Avoid b = avoids.get(i);
    if (abs(b.pos.x - mouseX) < eraseRadius && abs(b.pos.y - mouseY) < eraseRadius) {
      avoids.remove(i);
    }
  }
  
  for (int i = transmitters.size()-1; i > -1; i--) {
    Transmitter trans = transmitters.get(i);
    if (abs(trans.pos.x - mouseX) < eraseRadius && abs(trans.pos.y - mouseY) < eraseRadius) {
      transmitters.remove(i);
    }
  }
  
}

void drawText (String s, float x, float y) {
  fill(0);
  text(s, x, y);
  fill(200);
  text(s, x-1, y-1);
}


void message (String in) {
  messageText = in;
  messageTimer = (int) frameRate * 3;
}

void countEndangered (String in) {
  endangeredText = in;
}
