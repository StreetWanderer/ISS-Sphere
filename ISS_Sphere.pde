/* OpenProcessing Tweak of *@*http://www.openprocessing.org/sketch/41142*@* */
/* !do not delete the line above, required for linking your tweak if you upload again */
/**
 *
 * <p>
 * <span style="color: orange;">Orange</span> represent Montreal.
 * <span style="color: green;">Green</span> is the ISS
 * </p>
 * <p>
 *  The ISS position is recalculated every second but expect it to only move every minute or so.
 * </p>
 * <p>Code at : <a href="https://github.com/StreetWanderer/ISS-Sphere">https://github.com/StreetWanderer/ISS-Sphere</a></p>
 */
 // import processing.opengl.*;
 
float R = 20;
 
float rotationX = 0;
float rotationY = 0;
float velocityX = 0;
float velocityY = 0;
//float pushBack = 445;
//float pushBack = 415;
float pushBack = 485 - 2*R;
 
float phi = (sqrt(5)+1)/2 - 1; // golden ratio
float ga = phi*2*PI;           // golden angle
 
//int kMaxPoints = 90;
 
int nbrPoints = 200;

String[] tleData = {"1 25544U 98067A   15036.75479648  .00017495  00000-0  26839-3 0  9992", "2 25544  51.6473  20.3663 0005703 331.6319  87.1479 15.54376832927580"};

float time = millis();

//boolean addPoints = false;
//SpherePoint[] pts = new SpherePoint[kMaxPoints];
SpherePoint[] pts = new SpherePoint[nbrPoints];

Geolocation currentPos = new Geolocation(45.5, -73.6, 240, "Montreal");
//Geolocation equator = new Geolocation(0, 73.6, 156, "Equateur");
//Geolocation pole = new Geolocation(-89, 0, 255, "South Pole");
//Geolocation npole = new Geolocation(90, 0, 100, "Nort Pole");

Geolocation issPosition = new Geolocation(0, 0, 50, "ISS");
SpherePoint issPoint;
 
// To add: Give each point a heading and velocity, adjust based on distance/heading to nearby points.
//
class SpherePoint {
  float  lat,lon, hue;
  SpherePoint(float lat, float lon)
  {
    this.lat = lat;
    this.lon = lon;
    this.hue = -1;
    //console.log(lat, lon);
  }
};
 


class Geolocation {
  float lat, lon, hue;
  String  name;
  Geolocation(float lat, float lon, float hue, String name)
  {
    this.lat = lat;
    this.lon = lon;
    this.hue = hue;
    this.name = name;
  }
}



 
void initSphere()
{
  for (int i = 1; i <= min(nbrPoints,pts.length); ++i) {
    float lon = ga*i;
    lon /= 2*PI; lon -= floor(lon); lon *= 2*PI;
    if (lon > PI)  lon -= 2*PI;
 
    // Convert dome height (which is proportional to surface area) to latitude
    float lat = asin(-1 + 2*i/(float)nbrPoints);
 
    pts[i] = new SpherePoint(lat, lon);
  }
}
 
void setup()
{
   //size(700, 700, P3D); 
  size(600, 600, P3D); 
  //R = .8 * height/2;
   
  initSphere();
   
  //colorMode(HSB, 1);
  colorMode(RGB, 255);
  background(0);
 
  getClosestPoint(currentPos).hue = currentPos.hue;
  renderISS();
  console.log("initDone");
 
}
 
void draw()
{   
  /*
  if (addPoints) {
    nbrPoints += 1;
    nbrPoints = min(nbrPoints, kMaxPoints);
    initSphere();
  }
  */
 
  background(0);           
  smooth();
 
  renderGlobe();
 
  rotationX += velocityX;
  rotationY += velocityY;
  velocityX *= 0.95;
  velocityY *= 0.95;
   
  // Implements mouse control (interaction will be inverse when sphere is  upside down)
  if(mousePressed){
    velocityX += (mouseY-pmouseY) * 0.01;
    velocityY -= (mouseX-pmouseX) * 0.01;
  }
  
  time = millis();
  
  if(time % 1000 == 0) //every 1000ms re-calculate ISS position 
  {
    renderISS();
  }
  
}
 
 
void renderGlobe()
{
  pushMatrix();
  translate(width/2.0, height/2.0, pushBack);
   
  float xRot = radians(-rotationX);
  float yRot = radians(270 - rotationY - millis()*.003);
  
  rotateX( xRot ); 
  rotateY( yRot );
  
 
  strokeWeight(20);
   
  float elapsed = millis()*.001;
  float secs = floor(elapsed);
   
  for (int i = 1; i <= min(nbrPoints,pts.length); ++i)
  {
      float lat = pts[i].lat;
      float lon = pts[i].lon;
 
      pushMatrix();
      rotateY( lon);
      rotateZ( -lat);
      float lum = (cos(pts[i].lon+PI*.33+yRot)+1)/2;
      //console.log(lum);
      if(pts[i].hue != -1)
      {
        //stroke(pts[i].hue, .68, .85);
        stroke(pts[i].hue, 104, 0);
      }
      else
      {
        //stroke(.1, .68*lum, .85+lum);
        stroke(255*lum,255*lum,255*lum);
      }
       
      point(R,0,0);
       
      popMatrix();
  }
 
  popMatrix();
   
}

void renderISS()
{
  initSatellite(tleData[0], tleData[1]);
  if(issPoint != null)
    issPoint.hue = -1;
    
  issPoint = getClosestPoint(issPosition);
  issPoint.hue = issPosition.hue;
  console.log(issPosition);
}
 
/*
void mouseClicked()
{
  //addPoints = !addPoints;
  
  SpherePoint currentPoint = getClosestPoint(currentPos);
  SpherePoint equatorPoint = getClosestPoint(equator);
  SpherePoint polePoint = getClosestPoint(pole);
  
  getClosestPoint(npole).hue = npole.hue;
  
  currentPoint.hue = currentPos.hue;
  equatorPoint.hue = equator.hue;
  polePoint.hue = pole.hue;
  
}
*/

SpherePoint getClosestPoint(Geolocation pos)
{
  int min = MAX_INT; 
  int index = 0;
  
  float[] distances = {};
  
  var mappedLat = map(pos.lat, -90, 90, -3.1, 3.1);
  var mappedLon = map(pos.lon, -180, 180, -3.1, 3.1);
  
  
  
  for(var i=1; i < pts.length; i++)
  {
    //float dist = calculateDistance(pts[i].lat, pts[i].lon, mappedLat, mappedLon);
    float dist = calculateDistance(pts[i].lat, pts[i].lon, radians(pos.lat), radians(pos.lon));
    //append(distances, dist);
    
    if(dist < min) { 
      min = dist; 
      index = i; 
    }
  }
  
  //console.log(index);  
  return pts[index];
  
  
}

//Calculate distance on a globe between 2 coordinates. MUST BE IN RADIANS!
void calculateDistance (float lat1, float lon1, float lat2, float lon2)
{
  //var R = 6371; // km
  //var R = 40;

  float phi1 = lat1; //issPosition.latitude.toRadians();
  float phi2 = lat2; //currentPosition.coords.latitude.toRadians();
  float deltaPhi = lat2 - lat1;
  float deltaLambda = lon2 - lon1;

  float a = sin(deltaPhi/2) * sin(deltaPhi/2) + cos(phi1) * cos(phi2) * sin(deltaLambda/2) * sin(deltaLambda/2);
  float c = 2 * atan2(Math.sqrt(a), sqrt(1-a));

  float d = R * c;
  
  return d;
}

function initSatellite(String tle_line_1, String tle_line_2){

  var now = new Date();
  
  var satrec = satellite.twoline2satrec(tle_line_1, tle_line_2);
  

  var position_and_velocity = satellite.propagate (satrec,
                                                now.getUTCFullYear(), 
                                                now.getUTCMonth() + 1, // Note, this function requires months in range 1-12. 
                                                now.getUTCDate(),
                                                now.getUTCHours(), 
                                                now.getUTCMinutes(), 
                                                now.getUTCSeconds());
  var position_eci = position_and_velocity["position"];
  var gmst = satellite.gstime_from_date (now.getUTCFullYear(), 
                                       now.getUTCMonth() + 1, // Note, this function requires months in range 1-12. 
                                       now.getUTCDate(),
                                       now.getUTCHours(), 
                                       now.getUTCMinutes(), 
                                       now.getUTCSeconds());


  var position_gd = satellite.eci_to_geodetic (position_eci, gmst);
  
  issPosition.lat = degrees(position_gd["latitude"]);
  issPosition.lon = degrees(position_gd["longitude"]);

  //issPosition = {longitude: position_gd["longitude"].toDegrees(), latitude:position_gd["latitude"].toDegrees(), altitude: position_gd["height"], timestamp:now.getTime()};

  //calculateDistance();
}

