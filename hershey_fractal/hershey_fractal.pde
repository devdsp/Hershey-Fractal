/*
Copyright 2011 Adam Thomas
Released under GPLv2
*/

import processing.opengl.*;

String whereami = "You Are Here";
Font f = new Font();

class Line {
  PVector[] points = new PVector[0];

  void AddPoint( PVector p ) {
    points = (PVector[]) append(points,p);
  }
  
  void Render() {
    PVector h = new PVector(
      screenX(0,7,0) - screenX(0,-7,0),
      screenY(0,7,0) - screenY(0,-7,0)
    );
    if( h.mag() > 10 ) {
      this.Recurse();
    } else {
      
      PVector from = null;
      for(PVector p : points) {
        if(from != null) {
          line(from.x,from.y,p.x,p.y);
        }
        from = new PVector(p.x,p.y);
      }
    }
  }
  
  void Recurse() {
    PVector from = null;
    CharacterIterator it = new StringCharacterIterator(whereami);
    char ch=it.first();
    for(PVector p : points) {
      if(from != null) {
        pushMatrix();
        translate(from.x,from.y);
        {
          float s = 10;
          PVector foo = new PVector(p.x,p.y);
          foo.sub(from);
          float theta = foo.heading2D();
          float len = foo.mag()*s;
          pushMatrix();
          rotate(theta);
          scale(1/s);
          while (len > 0) {
            Glyph g = f.glyphs[ch-32];
            g.Render();
            translate(g.maxx-g.minx, 0);
            ch=it.next();
            if(ch == CharacterIterator.DONE) {
              g = f.glyphs[' '-32];
              translate(g.maxx-g.minx,0);
              len -= g.maxx-g.minx;
              ch = it.first();
            }
            len -= g.maxx-g.minx;
          }
          popMatrix();
        }
        popMatrix();
      }
      from = new PVector(p.x,p.y);
    }
  }
}

class Glyph {
  int minx,maxx;
  Line[] lines = new Line[0];

  Glyph(int _minx, int _maxx) {
    minx = _minx;
    maxx = _maxx;
  }

  void AddLine( Line l ) {
    lines = (Line[]) append(lines, l);
  }
  
  boolean OnScreen() {
    for(Line l : lines ) {
      for(PVector p : l.points ) {
        float x = screenX(p.x,p.y);
        float y = screenY(p.x,p.y);
        if(x > 0 && x < width && y > 0 && y < height) {
          return true;
        }
      }
    }
    return false; 
  }
  
  void Render() {
    if(!OnScreen()) {
      return;
    }
    for (Line l : lines) {
      l.Render();
    }
  }
  
  void Recurse() {
    for (Line l : lines) {
      l.Recurse();
    }
  }
}

class Font {
  Glyph[] glyphs = new Glyph[0];
  void AddGlyph( Glyph g ) {
    glyphs = (Glyph[]) append(glyphs,g);
  }
}

int HersheyLen(String s) {
  StringCharacterIterator it = new StringCharacterIterator(s);
  int len=0;
  for(char ch = it.first();ch != CharacterIterator.DONE;ch = it.next()) {
    len += f.glyphs[ch-32].maxx - f.glyphs[ch-32].minx;
  } 
  return len;
}

void setup() {
  size(screen.width, screen.height, OPENGL);
  
  strokeWeight(2);
  
  BufferedReader reader;
  byte font_data[] = loadBytes("rowmans.1.jhf");

  for(int i=0; i < font_data.length;i++) {

    while(i < font_data.length && font_data[i] == '\n') {
      Glyph g = new Glyph(0,0);
      f.AddGlyph(g);  
      i++;
    }

    if( i < font_data.length -1 && font_data[i+1] != '\n' ) {

      byte minx = font_data[i++];
      byte maxx = font_data[i++];

      Glyph g = new Glyph(minx-'R',maxx-'R');
      f.AddGlyph(g);
      Line l = new Line();
      g.AddLine(l);

      while(font_data[i] != '\n') {
        byte x = font_data[i++];
        byte y = font_data[i++];
        if(x==' ' && y == 'R') {
          l = new Line();
          g.AddLine(l);
        } 
        else {
          x-='R';
          y-='R';
          l.AddPoint(new PVector(x,y));
        }
      }
    }
  }
}



float m = 0;
float s=1;
void draw() {
  float dt = (millis() - m)/1000;
  m = millis();
  background(0,0,0);
  stroke(255);
  translate(width/2,height/2);
  
  scale(s);
  s*=1+dt/4;
  translate(-HersheyLen(whereami)/2, 0);
  
  CharacterIterator it = new StringCharacterIterator(whereami);

  for (char ch=it.first(); ch != CharacterIterator.DONE; ch=it.next()) {
    Glyph g = f.glyphs[ch-32];
    g.Render();
    translate(g.maxx-g.minx, 0);
  }
}

