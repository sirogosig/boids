class Transmitter {
  PVector pos;
  
  Transmitter(float xx, float yy) {
    pos = new PVector(xx,yy);
  }
  
  void go () {
  }
  
  void draw () {
    fill(15, 200, 200);
    triangle(pos.x-10, pos.y+10, pos.x, pos.y-10, pos.x+10, pos.y+10);
    noFill();
    stroke(0,0,100);
    circle(pos.x,pos.y,2*activation_threshold);
  }
}
