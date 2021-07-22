#script "Test stuff"
#target photoshop
#strict on

function Log(message) {
    $.writeln(message);
}

var l = activeDocument.activeLayer;
var b = l.bounds; // left, top, right, bottom?
Log("::   bounds: " + b[0] + ", " + b[1] + ", " + b[2] + ", " + b[3]);
var sel = activeDocument.selection;
sel.deselect();
// EXTEND, INTERSECT, DIMINISH
var x0 = b[0].as("px");
var y0 = b[1].as("px");
var x1 = b[2].as("px");
var y1 = b[3].as("px");
var coords = [ [x0,y0], [x0,y1], [x1,y1], [x1,y0] ];
Log(coords);
sel.select(coords, SelectionType.REPLACE, 0, false);
//Result: 90,77,368,237