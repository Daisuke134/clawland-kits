// Greenhouse Pro controller enclosure
// Weather-sheltered electronics box with relay sidecar and vent slots.

$fn = 48;

outer_x = 160;
outer_y = 110;
outer_z = 58;
wall = 3;
lid_overlap = 8;
standoff_h = 8;

module shell() {
  difference() {
    cube([outer_x, outer_y, outer_z], center = false);
    translate([wall, wall, wall]) cube([outer_x - 2 * wall, outer_y - 2 * wall, outer_z - wall], center = false);
  }
}

module vent_row(y_pos) {
  for (x = [18 : 18 : outer_x - 18]) {
    translate([x, y_pos, outer_z - 18]) rotate([90, 0, 0]) cylinder(h = wall + 2, r = 3);
  }
}

module cable_gland_holes() {
  translate([24, outer_y + 0.1, 18]) rotate([90, 0, 0]) cylinder(h = wall + 1, r = 6);
  translate([52, outer_y + 0.1, 18]) rotate([90, 0, 0]) cylinder(h = wall + 1, r = 6);
  translate([80, outer_y + 0.1, 18]) rotate([90, 0, 0]) cylinder(h = wall + 1, r = 6);
  translate([108, outer_y + 0.1, 18]) rotate([90, 0, 0]) cylinder(h = wall + 1, r = 6);
}

module board_standoffs() {
  for (pt = [[26, 20], [26, 82], [118, 20], [118, 82]]) {
    translate([pt[0], pt[1], wall]) cylinder(h = standoff_h, r = 3);
    translate([pt[0], pt[1], wall + standoff_h - 1]) cylinder(h = 4, r = 1.4);
  }
}

module relay_shelf() {
  translate([outer_x - 48, 12, wall]) cube([32, 78, 3], center = false);
}

module lid() {
  difference() {
    translate([0, 0, 0]) cube([outer_x, outer_y, wall + 6], center = false);
    translate([lid_overlap, lid_overlap, wall]) cube([outer_x - 2 * lid_overlap, outer_y - 2 * lid_overlap, 8], center = false);
    for (pt = [[12, 12], [12, outer_y - 12], [outer_x - 12, 12], [outer_x - 12, outer_y - 12]]) {
      translate([pt[0], pt[1], -0.1]) cylinder(h = wall + 7, r = 2);
    }
  }
}

difference() {
  shell();
  vent_row(-0.5);
  vent_row(outer_y - wall + 0.5);
  cable_gland_holes();
}

board_standoffs();
relay_shelf();

translate([outer_x + 20, 0, 0]) lid();
