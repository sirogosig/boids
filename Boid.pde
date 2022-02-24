float tagged_probability=0.1;

char threshold_mode = 't';  //No communication between tags
char swarm_mode = 's';      //Communication between tags
float activated_tags_percentage=0.5;

char mode=threshold_mode; // Set mode HERE

class Boid {
  // main fields
  PVector pos;
  PVector move;
  float shade;
  boolean tagged=false;
  boolean tag_on=false;
  ArrayList<Boid> friends;
  ArrayList<Food> eats;

  // timers
  int thinkTimer = 0;


  Boid (float xx, float yy) {
    move = new PVector(0, 0);
    pos = new PVector(0, 0);
    pos.x = xx;
    pos.y = yy;
    thinkTimer = int(random(10));
    shade = random(255);
    friends = new ArrayList<Boid>();
    eats = new ArrayList<Food>();
    
    float temp=random(1);
    if(temp<tagged_probability) tagged=true;
    tag_on=false;
  }

  void go () {
    increment();
    wrap();
    
    // We update friend array every 5 go's
    if (thinkTimer ==0 ) { 
      // update our friend array (lots of square roots)
      getFriends();
      if(tagged) getTagActivation();
    }
    flock();
    pos.add(move);
    //eat();
  }

  void flock () {
    PVector allign = getAverageDir();
    PVector avoidDir = getAvoidDir(); 
    PVector avoidObjects = getAvoidAvoids();
    PVector noise = new PVector(random(2) - 1, random(2) -1);
    PVector cohese = getCohesion();
    PVector danger = getDanger();

    // Setting up different coefficients:
    allign.mult(1);
    if (!option_friend) allign.mult(0);
    
    avoidDir.mult(1);
    if (!option_crowd) avoidDir.mult(0);
    
    avoidObjects.mult(3);
    if (!option_avoid) avoidObjects.mult(0);

    noise.mult(0.1);
    if (!option_noise) noise.mult(0);

    cohese.mult(2);
    if (!option_cohese) cohese.mult(0);
    
    danger.mult(2);
    if (!option_danger) cohese.mult(0);
    
    stroke(0, 255, 160);

    move.add(allign);
    move.add(avoidDir);
    move.add(avoidObjects);
    move.add(noise);
    move.add(cohese);
    move.add(danger);

    move.limit(maxSpeed);
    
    shade += getAverageColor() * 0.03;
    shade += (random(2) - 1) ;
    shade = (shade + 255) % 255; //max(0, min(255, shade));
  }

  void getFriends () {
    ArrayList<Boid> nearby = new ArrayList<Boid>();
    for (int i =0; i < boids.size(); i++) {
      Boid test = boids.get(i);
      if (test == this) continue;
      if (abs(test.pos.x - this.pos.x) < friendRadius &&
        abs(test.pos.y - this.pos.y) < friendRadius) {
        nearby.add(test);
      }
    }
    friends = nearby;
  }

  float getAverageColor () {
    float total = 0;
    float count = 0;
    for (Boid other : friends) {
      if (other.shade - shade < -128) {
        total += other.shade + 255 - shade;
      } else if (other.shade - shade > 128) {
        total += other.shade - 255 - shade;
      } else {
        total += other.shade - shade; 
      }
      count++;
    }
    if (count == 0) return 0;
    return total / (float) count;
  }
  
  void getTagActivation() {
    if(mode==threshold_mode){
      boolean in_range=false;
      for (Transmitter transmitter : transmitters){
        float d = PVector.dist(pos, transmitter.pos);
        if(d<activation_threshold){
          in_range=true;
        }
      }
      tag_on=in_range;
    }
    
    else{
      boolean closest=false;
      for (Transmitter transmitter : transmitters){
        float my_dist= PVector.dist(pos, transmitter.pos);
        if(my_dist<activation_threshold){
          FloatList distances= new FloatList(); //List of close boids for that transmitter
          for(Boid other : boids){
            if(other==this) continue;
            if(other.tagged){
              float dist = PVector.dist(other.pos, transmitter.pos);
              distances.append(dist);
            }
          }
          distances.sort();
          if(distances.size()>=1){
            if(my_dist<distances.get((int)((distances.size()-1)*activated_tags_percentage))){ // If closer than half other tagged boids
              closest=true;  
            }
          }
          else closest=true;
        }
      }
      tag_on=closest;
    }
  }

  PVector getAverageDir () {
    PVector sum = new PVector(0, 0);
    int count = 0;

    for (Boid other : friends) {
      float d = PVector.dist(pos, other.pos);
      // If the distance is greater than 0 and less than an arbitrary amount (0 when you are yourself)
      if ((d > 0) && (d < friendRadius)) {
        PVector copy = other.move.copy();
        copy.normalize();
        copy.div(d); 
        sum.add(copy);
        count++;
      }
      if (count > 0) {
        //sum.div((float)count);
      }
    }
    return sum;
  }

  PVector getAvoidDir() {
    PVector steer = new PVector(0, 0);
    int count = 0;

    for (Boid other : friends) {
      float d = PVector.dist(pos, other.pos);
      // If the distance is greater than 0 and less than an arbitrary amount (0 when you are yourself)
      if ((d > 0) && (d < crowdRadius)) {
        // Calculate vector pointing away from neighbor
        PVector diff = PVector.sub(pos, other.pos);
        diff.normalize();
        diff.div(d);        // Weight by distance
        steer.add(diff);
        count++;            // Keep track of how many
      }
    }
    if (count > 0) {
      //steer.div((float) count);
    }
    return steer;
  }

  PVector getAvoidAvoids() {
    PVector steer = new PVector(0, 0);
    int count = 0;

    for (Avoid avoid : avoids) {
      float d = PVector.dist(pos, avoid.pos);
      // If the distance is greater than 0 and less than an arbitrary amount (0 when you are yourself)
      if (d < avoidRadius){
        // Calculate vector pointing away from avoid
        PVector diff = PVector.sub(pos, avoid.pos);
        diff.normalize();
        diff.div(d);        // Weight by distance
        steer.add(diff);
        count++;            // Keep track of how many
      }
    }
    return steer;
  }
  
  PVector getCohesion () {
   float neighbordist = 50;
    PVector sum = new PVector(0, 0);   // Start with empty vector to accumulate all locations
    int count = 0;
    for (Boid other : friends) {
      float d = PVector.dist(pos, other.pos);
      if ((d > 0) && (d < coheseRadius)) {
        sum.add(other.pos); // Add location
        count++;
      }
    }
    if (count > 0) {
      sum.div(count);
      
      PVector desired = PVector.sub(sum, pos);  
      return desired.setMag(0.05);
    } 
    else {
      return new PVector(0, 0);
    }
  }
  
  PVector getDanger() {
    PVector steer = new PVector(0, 0);
    for (Boid other : friends) {
      if(other.tagged && other.tag_on){
        float d = PVector.dist(pos, other.pos);
        if ((d > 0)) {
          PVector diff = PVector.sub(pos, other.pos);
          diff.normalize();
          diff.div(d);
          steer.add(diff);
        }   
      }
    }
    return steer;
  }

  void draw () {
    for (int i = 0; i < friends.size(); i++) {
      Boid f = friends.get(i);
      if(this.tagged && f.tagged){
        stroke(90);
        line(this.pos.x, this.pos.y, f.pos.x, f.pos.y);
      }
    }
    
    noStroke();
    fill(shade, 90, 200);
    pushMatrix();
    translate(pos.x, pos.y);
    rotate(move.heading());
    beginShape();
    vertex(15 * globalScale, 0);
    vertex(-7* globalScale, 7* globalScale);
    vertex(-7* globalScale, -7* globalScale);
    endShape(CLOSE);
    if(tagged){
      if(tag_on){
        fill(0, 200, 200);
        circle(0,0,5);
      }
      else{
        fill(0, 0, 50);
        circle(0,0,5);  
      }
    }
    popMatrix();
  }

  // update all those timers!
  void increment () {
    thinkTimer = (thinkTimer + 1) % 5; // The thinkTimer is between 0 and 4
  }

  // Ensures the fishes go around the arena
  void wrap () {
    pos.x = (pos.x + width) % width;
    pos.y = (pos.y + height) % height;
  }
  
  //void eat() {
  //  for (Food f : eats) {
  //    foods.remove(f);
  //  }
  //  eats = new ArrayList<Food>();
  //}
}
