import processing.opengl.*;

String whereami = "You Are Here";
PMatrix2D world = new PMatrix2D();
PVector start;
Font f = new Font();
int linecount =0;

ArrayList buffer_a = new ArrayList();
ArrayList buffer_b = new ArrayList();
ArrayList active_buffer = buffer_a;
ArrayList pending_buffer = buffer_b;

Renderable target;

class AABB implements Serializable {
  float minx,maxx,miny,maxy;

  AABB(PVector p) {
    minx=p.x;
    maxx=p.x;
    miny=p.y;
    maxy=p.y;
  }
  AABB(AABB a) {
    this.minx = a.minx;
    this.maxx = a.maxx;
    this.miny = a.miny;
    this.maxy = a.maxy;
  }

  void Add(PVector p) {
    this.Add(p.x,p.y);
  }
  void Add( float x, float y ) {
    minx = min(minx,x);
    maxx = max(maxx,x);
    miny = min(miny,y);
    maxy = max(maxy,y);
  }  
  void Add( AABB aabb ) {
    this.Add(aabb.minx,aabb.miny);
    this.Add(aabb.maxx,aabb.maxy);
  }

  Boolean IsWithin(float minx, float maxx, float miny, float maxy) {
    return (
      this.minx > minx && this.maxx < maxx && 
      this.miny > miny && this.maxy < maxy
    );
  }
  
  Boolean IsOnScreen() {
    return (
      (
        screenX(minx,miny,0) > 0 && screenX(minx,miny,0) < width &&
        screenY(minx,miny,0) > 0 && screenY(minx,miny,0) < height
      ) || (
        screenX(maxx,miny,0) > 0 && screenX(maxx,miny,0) < width &&
        screenY(maxx,miny,0) > 0 && screenY(maxx,miny,0) < height
      ) || (
        screenX(maxx,maxy,0) > 0 && screenX(maxx,maxy,0) < width &&
        screenY(maxx,maxy,0) > 0 && screenY(maxx,maxy,0) < height
      ) || (
        screenX(minx,maxy,0) > 0 && screenX(minx,maxy,0) < width &&
        screenY(minx,maxy,0) > 0 && screenY(minx,maxy,0) < height
      )
    );
  }
  
  public String toString() {
    return "[ " + minx + ", " + maxx + " : " + miny + ", " + maxy + " ]";
  }
}

class Line {
  PVector[] points = new PVector[0];

  void AddPoint( PVector p ) {
    points = (PVector[]) append(points,p);
  }

  void Render(PVector position, PMatrix2D transform) {
    if(points.length < 2 ) {
      return;
    }
    PVector from = transform.mult(points[0],null);
    from.add(position);
    for(int i=1;i<points.length;++i) {
      PVector to = transform.mult(points[i],null);
      to.add(position);
      AABB aabb = new AABB(from);
      aabb.Add(to);
      if( aabb.IsOnScreen() ) {
        stroke(255);
        line(from.x,from.y,to.x,to.y);
        linecount++;
      }
      from = to;
    }
  }

  AABB GetAABB(PVector position, PMatrix2D transform) {
    AABB aabb = new AABB(position);
    for(int i=0;i<points.length;++i) {
      PVector tmp = transform.mult(points[i], null);
      tmp.add(position);
      aabb.Add(tmp);
    }
    return aabb;
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

  void Render(Renderable parent, PVector position, PMatrix2D transform) {
    
    if(GetAABB(position,transform).IsOnScreen()) {
      
      if(transform.mult(new PVector(0,1),null).mag() < 1) {
        for(int i=0;i<lines.length;++i) {
          lines[i].Render(position,transform);
        }
        pending_buffer.add(parent);
        
      } else {  
        ArrayList children = new ArrayList();
        for(int i=0;i<lines.length;++i) {
          CharacterIterator it = new StringCharacterIterator(whereami);    
          
          if( lines[i].points.length < 2 ) {
            continue;
          }
          
          PVector from = transform.mult(lines[i].points[0],null);
          from.add(position);
          
          for(int j=1;j<lines[i].points.length;++j) {
          
            PVector to = transform.mult(lines[i].points[j],null);
            to.add(position);
                        
            PMatrix2D next_transform = new PMatrix2D(transform);
            next_transform.scale(0.1);        
            next_transform.rotate(
              atan2(
                lines[i].points[j].y-lines[i].points[j-1].y,
                lines[i].points[j].x-lines[i].points[j-1].x
              )
            );
            
            PushString(it, from, to, next_transform, children);
            from = to;
          }
        }
        if( target == parent ) {
          target = (Renderable) children.get((int)random(0,children.size()-1));
        }
      }
    } else {
      if(target == parent) {
        target = null;
      }
    }
  }

  AABB GetAABB(PVector position, PMatrix2D transform) {
    AABB aabb = new AABB(position);
    for(int i=0;i<lines.length;++i) {
      aabb.Add(lines[i].GetAABB(position,transform));
    }
    return aabb;
  }
}

class Renderable {
  Glyph g;
  PVector position;
  PMatrix2D transform;
  void Render() {
    g.Render(this, position,transform);
  }
}


class Font {
  Glyph[] glyphs = new Glyph[0];
  void AddGlyph( Glyph g ) {
    glyphs = (Glyph[]) append(glyphs,g);
  }
}

void PushString(CharacterIterator it, PVector start, PVector end, PMatrix2D transform, ArrayList siblings) {
  PVector offset = new PVector(start.x, start.y);
  char ch = it.current();

  while( PVector.dist(start,end) > PVector.dist(start,offset) ) {
    
    Renderable r = new Renderable();
    r.g = f.glyphs[ch-32];
    r.position = new PVector(offset.x, offset.y);
    r.transform = new PMatrix2D(transform);
    pending_buffer.add(r);
    siblings.add(r);
    
    offset.add(transform.mult(new PVector(r.g.maxx-r.g.minx,0),null));
    
    if( (ch = it.next()) == CharacterIterator.DONE ) {
      offset.add(transform.mult(new PVector(f.glyphs[0].maxx-f.glyphs[0].minx,0),null));
      ch = it.first();
    }
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


void SeedBuffer(String s) {
  StringCharacterIterator it = new StringCharacterIterator(s);
  PVector position = new PVector(HersheyLen(s)/-2,0);
  for(char ch = it.first(); ch != CharacterIterator.DONE;ch = it.next()) {
    Renderable r = new Renderable();
    r.g = f.glyphs[ch-32];
    r.position = new PVector(position.x, position.y);
    r.transform = new PMatrix2D();
    active_buffer.add(r);
    position.add(new PVector(f.glyphs[0].maxx-f.glyphs[0].minx,0));
  }
}

void setup() {
  size(800, 450, OPENGL);
  background(102);

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
  SeedBuffer(whereami);
}

boolean pause = false;

void keyPressed(){
  if( key == ' ' ) {pause = !pause;}
}


void draw() {
  background(102);
  stroke(255);
  
  translate(width/2,height/2);
  pending_buffer = new ArrayList();
    
  while( target == null || target.g == f.glyphs[0] ) {
    target = (Renderable) active_buffer.get((int)random(0,active_buffer.size()-1));
  }
  
  PMatrix2D transformer = new PMatrix2D();
  transformer.scale(1.01);
  
  PVector right = target.transform.mult(new PVector(1,0),null);
  
  float theta = -right.heading2D();
  if( theta != 0 ) {
    transformer.rotate(theta*0.01);
  }

  // TODO: re-write the frustrum culling so that it can happen outside the render pass
  
  for (int i = 0; i < active_buffer.size(); i++) {
    Renderable r = (Renderable) active_buffer.get(i);
    if( !pause ) {
      r.position.x -= target.position.x*0.05;
      r.position.y -= target.position.y*0.05;
      
      r.position = transformer.mult(r.position,null);
      r.transform.apply(transformer);
    }
  }
  
  for (int i = 0; i < active_buffer.size(); i++) {
    Renderable r = (Renderable) active_buffer.get(i);
    r.Render();
  }
    
  active_buffer = new ArrayList(pending_buffer);
  pending_buffer = new ArrayList();
  
  //println( "Glyph Count: "+active_buffer.size()+". Lines Drawn: "+linecount);
  linecount = 0;
  
  if( active_buffer.size() == 0 ) {
    exit();
  }
}


