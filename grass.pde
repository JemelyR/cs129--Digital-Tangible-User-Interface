int grass = 1000;
GrassBlade[] blades = new GrassBlade[grass];
void setup() {
size(800, 600);
for (int i = 0; i < grass; i++) {
float x = random(width);
float y = height - random(10, 200);
blades[i] = new GrassBlade(x, y);
}
}
void draw() {
for (int i = 0; i < height; i++) {
float interpolate = map(i, 0, height, 0, 1);
color c = lerpColor(color(130, 200, 230), color(0, 0, 100), interpolate);
stroke(c);
line(0, i, width, i);
}

noStroke();
fill(20, 145, 30);
beginShape();
for (float x = 0; x <= width; x++) {
float noise = noise(x * 0.005, 0) * 95;
float y = height - 160 - noise;
vertex(x, y);
}
vertex(width, height);
vertex(0, height);
endShape(CLOSE);
for (GrassBlade blade : blades) {
blade.update(mouseX, mouseY);
blade.show();
}
}

class GrassBlade {
float x, y;
float height;
float movement;
GrassBlade(float x, float y) {
this.x = x;
this.y = y;
this.height = random(30, 90);
this.movement = random(-0.2, 0.2);
}
void update(float mouseX, float mouseY) {
float angle = atan2(mouseY - y, mouseX - x);
movement = lerp(movement, angle * 0.3, 0.1);
}
void show() {
pushMatrix();
translate(x, y);
rotate(movement);
fill(30, 140, 40);
stroke(0, 100, 0);
strokeWeight(2);
beginShape();
vertex(0, 0);
vertex(-5, -height / 2);
vertex(0, -height);
vertex(5, -height / 2);
endShape(CLOSE);
popMatrix();
}
}
