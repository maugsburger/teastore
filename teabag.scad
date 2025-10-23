include <openscad-screw-holes/screw_holes.scad> // https://github.com/nomike/openscad-screw-holes


/* [Global Options] */
// Main body thickness in mm
Shell_Thickness = 1.5; // 0.25

// Lay all parts flat onto bed
Print_Flat = false;

// Top Cover Type
Top_Cover="M"; // [N:None, L:Lid, M:MountingPlate ]
// Back Plate Type
Back_Plate="L"; // [N:None, L:Lid, M:MountingPlate ]

/* [Teabags] */
// Number of Teabags (<50) or absolute inner Height
Bag_Space = 120;
// Teabag Width
Bag_Width = 66;
// Teabag Length
Bag_Length = 77;
// Teabag Heigth
Bag_Height = 7;
// Wiggleroom per Side
Bag_Wiggle = 0.5;  // .25
// Compensation Ramp
Bag_Ramp = 20;

/* [Opening] */
// Full Width Opening Size in Teabags
Opening_Pullout = 1.2; // .1
// Total Opening Height in Teabags
Opening_Height_Teabags = 3; // .1
// Opening Height in mm (used if not null)
Opening_Height_Absolute = 0;
// Chamfer radius inside opening
Opening_Chamfer = 5;

/* [Labelholder] */
// Inner Width for the Label (0 for full width)
Label_Width = 0;
// Inner Height for the Label (0 for up to top)
Label_Height = 67;
// Inner Thickness for the Label
Label_Thickness = 1;
// Lip over the label
Label_Lip = 2.5; // .5
// Wall thickness for the Holder
Label_Shell = 1;

/* [Dovetails] */
// Height+Width of the Dovetail
Dovetail_Size = 3;
// Dovetail Corner Fillet
Dovetail_Fillet = 0.25; // 0.05
// Clearance, Substracted in Lid/Mounting Plate
Dovetail_Clearance = 0.15; // 0.05
// Create Dovetail on Top?
Dovetail_Top = true;
// Create Dovetail on the Back?
Dovetail_Back = true;

/* [Screw Mounting Plate] */
// Screw Head Diameter
ScrewHead_Diameter = 9; // 0.1
// Screw Head complete Height
ScrewHead_Height = 3.5; // 0.1
// Angle of the screw heads countersinking part
ScrewHead_Angle  = 180;
// Thread size, defining the hole diameter
ScrewThread = 5; // [ 0:M1.6, 1:M2, 2:M2.5, 3:M3, 4:M3.5, 5:M4, 6:M5 ]
// Extra Height of the Mounting Plate with Screwholes
ScrewPlateExtra = Dovetail_Size;


/* [Hidden] */
// quality
$fa = .2;
$fs = .1;
eps = 0.001;
// Calculations
screwhead = [ScrewHead_Diameter, ScrewHead_Height, ScrewHead_Angle];

// shell overall
sh_inner_x = Bag_Width + 2* Bag_Wiggle;
sh_inner_y = Bag_Length + 2* Bag_Wiggle;
sh_inner_z = Bag_Space < 50 ? Bag_Height * Bag_Space : Bag_Space;
sh_outer_x = sh_inner_x + 2* Shell_Thickness;
sh_outer_y = sh_inner_y + 2* Shell_Thickness; 
sh_outer_z = sh_inner_z + Shell_Thickness; // bottom layer with opening

echo("inner dimensions (front): W x D x H", sh_inner_x, sh_inner_y, sh_inner_z);
echo("outer dimensions (only base shell): W x D x H", sh_outer_x, sh_outer_y, sh_outer_z + Shell_Thickness);

// Shell pullout
sho_total_height =  Opening_Height_Absolute > 0  ?  Opening_Height_Absolute :  Opening_Height_Teabags * Bag_Height;

// Pullout part opening height 
sho_fullwidth_height = Opening_Pullout * Bag_Height;
// Offset for diagonal part above pullout part
sho_diagonal_height = sho_total_height - sho_fullwidth_height;

// helper modules 
module prism(l, w, h) {
    polyhedron(// pt      0        1        2        3        4        5
               points=[[0,0,0], [0,w,h], [l,w,h], [l,0,0], [0,w,0], [l,w,0]],
               // top sloping face (A)
               faces=[[0,1,2,3],
               // vertical rectangular face (B)
               [2,1,4,5],
               // bottom face (C)
               [0,3,5,4],
               // rear triangular face (D)
               [0,4,1],
               // front triangular face (E)
               [3,2,5]]
               );}




// Basic Shell holding the bags, without top and bottom
module shell_base() {
    linear_extrude(sh_inner_z, convexity = 2)
    difference() {
    square([sh_outer_x, sh_outer_y]);
    translate([Shell_Thickness, Shell_Thickness, 0]) 
    square([sh_inner_x, sh_inner_y]);
    }
}

// Pullout opening for basic shell
module shell_opening() {
    offset(r=Opening_Chamfer)  offset(delta=-Opening_Chamfer)
    //offset(delta=2, chamfer=true) 
    polygon([
        [0,-Opening_Chamfer-Shell_Thickness],
        [0,0],
        [0,sho_fullwidth_height],
        [sho_diagonal_height,
            sho_fullwidth_height + sho_diagonal_height],
        [sh_inner_x-sho_diagonal_height,
            sho_fullwidth_height + sho_diagonal_height],
        [sh_inner_x,sho_fullwidth_height],
        [sh_inner_x,0],
        [sh_inner_x,-Opening_Chamfer-Shell_Thickness]
    ]);
    
}

module shell_bottom() {
    chamfer = 1;
    radius=12;

    prism_offset = Bag_Ramp / sh_outer_y * Shell_Thickness;

    difference() {

        union() {
            cube([sh_outer_x, sh_outer_y, Shell_Thickness+eps]);
            translate([0,0,prism_offset])
            prism(sh_outer_x, sh_outer_y, Bag_Ramp);
        };

        translate([Shell_Thickness,chamfer,-1])
        linear_extrude(h=sh_inner_z) {
            // lower part / wide opening
            offset(r=chamfer) offset(delta=-chamfer)
            polygon([
                [0, -2*chamfer],
                [0, 0],
                [sh_inner_x/2-radius, sh_inner_x/2-radius],
                [sh_inner_x/2+radius, sh_inner_x/2-radius],
                [sh_inner_x, 0],
                [sh_inner_x, -2*chamfer]
            ]);
            
            // rounding in top
            difference() {
            offset(r=radius) offset(delta=-radius)
            polygon([
                [0, -2*radius],
                [0, 0],
                [sh_inner_x/2, sh_inner_x/2],
                [sh_inner_x, 0],
                [sh_inner_x, -2*radius]
            ]);
            polygon([
                [0, -2*radius-1],
                [0, 0],
                [sh_inner_x, 0],
                [sh_inner_x, -2*radius-1]
            ]);
            }
        }
    }
}

// create top part with dovetails. parameters:
// extra: increase dovetail length
// inner: create inner dovetails to sit on, below surface
// angled: rounded back corner for vertical dovetail
// offset: increase base size by offset for tolerances
// upperextra: increase the dovetail and cube on top outwards with a rectangle this wide
module shell_dovetail(extra=0, inner=false, angled=false, offset=0, upperextra=0) {
    
    // angled piece on front
    //translate([-upperextra,0,-eps])
    //cube([sh_outer_x+2*upperextra,Shell_Thickness,Dovetail_Size+offset]);
    
    chamfer_reduction = 0.2; // no pointy edge!
    chamfer_size = min(Shell_Thickness, Dovetail_Size)-chamfer_reduction;
    
    
    translate([sh_outer_x+upperextra,0,0])
    rotate([0,270,0])
    linear_extrude(h=sh_outer_x+2*upperextra) {
        polygon([
            [0,0], [0,Shell_Thickness], 
            [0,Shell_Thickness+chamfer_size+offset/2],
            [Dovetail_Size+offset,Shell_Thickness],
            [Dovetail_Size+offset,0]
        ]);
        
        if (inner) {
            color("red")
            polygon([
                [0,0],
                [0,Shell_Thickness+chamfer_size],
                [-chamfer_size+offset,Shell_Thickness],
                [-chamfer_size+offset,0]
            ]);
        }
    };
    
    // dovetails on side
    dovetail_base = Shell_Thickness; // base the dovetail sits on, doesnt change width
    dovetail_len = sh_outer_y - 2*eps;
    dovetail_height = Dovetail_Size-eps;
    
    translate([0,eps,eps]){
        // upper dovetails
        translate([dovetail_base,0,0])
        dovetail(
            height=dovetail_height, depth=dovetail_len+extra,
            extra=dovetail_base+upperextra, fillet=Dovetail_Fillet, 
            angle=angled, offset=offset);
        
        translate([sh_outer_x-dovetail_base,0,0])
        mirror([1,0,0])
        dovetail(
            height=dovetail_height, depth=dovetail_len+extra, 
            extra=dovetail_base+upperextra, fillet=Dovetail_Fillet, 
            angle=angled, offset=offset);
        
        if (inner) {
        // lower holding dovetails
        translate([Shell_Thickness,-eps,-Dovetail_Size])
        dovetail(
            height=Dovetail_Size, depth=dovetail_len, 
            extra=eps);
        
        translate([sh_outer_x-Shell_Thickness,-eps,-Dovetail_Size])
        mirror([1,0,0])
        dovetail(
            height=Dovetail_Size, depth=dovetail_len, 
            extra=eps);
        }
    }
}

// create a single dovetail with 90°/45°/45°
// height, length: base dimensions of triangular part
// extra: extend to negative x by this amount with a rectangular part
// fillet: create fillet of this size on inner edge, reduces steep inner angle
// angle: angle bottom end
// offset: increase outer size for clearance
module dovetail(height, depth, extra=0, fillet=0, angle=false, offset=0 ) {
    length = depth + ( angle==true ? height : 0 );
    difference() {
        translate([eps,length+eps,0])
        rotate([90,0,0])
        linear_extrude(h=length-eps) 

        // dovetail and chamfer part
        offset(delta=offset)
        union() {
            polygon([
                [-extra,0],
                [-extra,height],
                [0,height],
                [height/4,height],
                [height/4,height/4],
                [fillet+offset*2,fillet+offset*2], // make bottom part angle more shallow
                [fillet+offset*2,0],
                [0,0],
            ]);
            offset(r=fillet) offset(delta=-fillet)
            polygon([
                [0,height],
                [height,height],
                [0,0],
            ]);
        }
    
        // rounding and chamfer at bottom for vertical dovetail
        if (angle) {
            color("orange")
            translate([0,0,-height/2])
            linear_extrude(h=2*height)
            translate([0,length-height+eps,0])
            offset(r=-1) offset(delta=+1)
            polygon([
                [0-extra,height+eps],
                [height-fillet-.1,height+eps],
                [height-fillet-.1,-2],
                [height*2+eps,-2],
                
            ]);
            translate([-height,length-height+eps,height+eps])
            rotate([0,90,0])
            linear_extrude(h=2*height)
            color("green")
            polygon([
                [0,height+eps],
                [height+eps,height+eps],
                [0,0],
            ]);
        }
    }
}


module lid() {
    dovetailplate();
}

module mountingplate() {
    dovetailplate(screw=true, extrathick=ScrewPlateExtra);
}

module dovetailplate(screw=false, extrathick=0) {
    tolerance_width = 0.1; // extra x dimension / make "too wide"
    tolerance_depth = 0.1; // y dimension when on top
    tolerance_height = 0.1; // z dimension when on top
    lid_extra = Dovetail_Back == true ? Dovetail_Size : 0;
    lid_y = sh_outer_y + lid_extra - tolerance_depth;
    lid_heigth = Dovetail_Size + extrathick;
        
    difference() { 
        // base cube 
        translate([-tolerance_width/2,
            tolerance_depth/2,
            tolerance_height/2])
        cube([sh_outer_x + tolerance_width, 
            lid_y, 
            lid_heigth-tolerance_height]);

        // different length depending on enabled back-holder 
        // TODO make global calculation
        shell_dovetail(extra=lid_extra, offset=Dovetail_Clearance,
            upperextra=Shell_Thickness*2);
            
        
        if (screw) {
            translate([sh_outer_x-sh_outer_x/4, 20, 0])
                #screw_hole(screwhead, ScrewThread, lid_heigth, 0);
            
            translate([0+sh_outer_x/4, 20, 0])
                #screw_hole(screwhead, ScrewThread, lid_heigth, 0);
                
            translate([sh_outer_x/2, sh_inner_y-15, 0])
                #screw_hole(screwhead, ScrewThread, lid_heigth, 0);
        }
    }
}



module labelholder() {
    label_height = Label_Height > 0 ? Label_Height : 
        sh_outer_z - sho_total_height - Shell_Thickness + Label_Thickness;

    label_width =  Label_Width > 0 ? Label_Width : 
        sh_outer_x - 2* Label_Shell;

    total_thickness = Label_Thickness + Label_Shell;
    sidecube_width = (sh_outer_x - label_width ) / 2;
    chamfer_diag = sqrt(2*sidecube_width^2);

    echo("Label dimensions:", label_width, label_height, Label_Thickness);
    
    difference(){
        union() {
            %color("orange") translate([-label_width/2,total_thickness,0]) 
            cube([label_width, label_height, Label_Thickness]);
            
            translate([0,total_thickness,Label_Thickness])
                linear_extrude(h=Label_Shell)
            
            intersection() {
                translate([-label_width/2-eps,0,0]) 
                square([label_width+2*eps, label_height]);
            
                offset(r=-2*Label_Lip) offset(delta=+2*Label_Lip)
                offset(r=Label_Lip) offset(delta=-Label_Lip)
                polygon([
                    [0,Label_Lip],
                    [label_width/2-Label_Lip,Label_Lip], 
                    [label_width/2-Label_Lip,label_height],
                    [label_width/2+2*Label_Lip,label_height],
                    [label_width/2+2*Label_Lip,-2*Label_Lip],
                    [-label_width/2-2*Label_Lip,-2*Label_Lip],
                    [-label_width/2-2*Label_Lip,label_height],
                    [-label_width/2+Label_Lip,label_height],
                    [-label_width/2+Label_Lip,Label_Lip], 
                ]);
            }
            
            
            
            translate([label_width/2,total_thickness,0]) 
            cube([sidecube_width, label_height, total_thickness ]);
            
            translate([-label_width/2-sidecube_width,total_thickness,0]) 
            cube([sidecube_width, label_height, total_thickness ]);
        
            translate([-sh_outer_x/2,0,0]) 
            prism(sh_outer_x, total_thickness, total_thickness);
        }

        translate([-sh_outer_x/2-chamfer_diag/10,0,total_thickness-chamfer_diag/2.5 ])
        rotate([0,45,0])
        translate([-sidecube_width,0,0])
        cube([sidecube_width, label_height+total_thickness, sidecube_width ]);
        
        translate([sh_outer_x/2+chamfer_diag/10,0,total_thickness-chamfer_diag/2.5 ])
        rotate([0,45,0])
        translate([-sidecube_width,0,0])
        cube([sidecube_width, label_height+total_thickness, sidecube_width ]);
    }
    
}

module shell_assembled() {
    translate([0,0,Shell_Thickness])
    difference() {
        //color("green", 0.2) 
        shell_base();
            rotate([90,0,0]) 
            translate([Shell_Thickness,0,-1.5*Shell_Thickness])
            linear_extrude(height = 2*Shell_Thickness)
            shell_opening();
    }
    shell_bottom();
    if (Dovetail_Top) {
        translate([0,0,sh_outer_z])
        if (Dovetail_Back) {
            shell_dovetail(extra=Dovetail_Size, true);
        } else {
            shell_dovetail(0, true);
        }
    }
    if (Dovetail_Back) {
        translate([0,sh_outer_y,sh_outer_z])
        rotate([270,0,0])
        // back is always longer, so it matches top no matter what
        shell_dovetail(extra=Dovetail_Size, angled=true);
    }
    translate([sh_outer_x/2,0,sho_total_height+Shell_Thickness])
    rotate([90,0,0])
    labelholder();
}

module print_shell_assembled() {
    shell_assembled();
}

module print_topcover() {
    translate_topcover = 
        Print_Flat==false? [0,0,sh_outer_z] : [sh_outer_x+2,0,0];
    rotate_mountingplate_print = 
        Print_Flat==false ? [0,0,0] : [0,180,0];
    translate_mountingplate_print = 
        Print_Flat==false ? [0,0,0] : [sh_outer_x,0,Dovetail_Size*2];
    
    translate(translate_topcover) {
        color("darkred")
        if ( Top_Cover=="L" ) {
            lid();
        } else if ( Top_Cover=="M" ) {
            translate(translate_mountingplate_print) 
            rotate(rotate_mountingplate_print) 
            mountingplate();
        }
    }
}

module print_backplate() {
    translate_backplate = 
        Print_Flat==false ? [0,sh_outer_y,sh_outer_z] : [2*(sh_outer_x+2),0,0];
    rotate_backplate = 
        Print_Flat==false ? [270,0,0] : [0,0,0];
    rotate_mountingplate_print = 
        Print_Flat==false ? [0,0,0] : [0,180,0];
    
     translate(translate_backplate) rotate(rotate_backplate)  {
        color("maroon")
        if ( Back_Plate=="L" ) {
             lid();
        } else if ( Back_Plate=="M" ) {
            rotate(rotate_mountingplate_print) 
            mountingplate();
        }
    }
}

previewDebug = true;

if ($preview && previewDebug ) {
    translate(v = [sh_outer_x + 10, 0 , 0])
    difference() {
        group() {
            print_shell_assembled();
            print_topcover();
            print_backplate();
        }
        translate([0,sh_inner_y/2,sh_inner_z/2])
        cube([sh_inner_x,2*sh_outer_y, 2*sh_outer_z],center=true);
    };

    translate([-(sh_outer_x+10),0,0]) color("pink") 
        mountingplate();

    translate( [-10 ,sh_outer_y+10,Dovetail_Size*2]) 
        rotate([0,180,0]) color("pink")
        mountingplate();
        
    translate([-(sh_outer_x*2+20),0,0])
        color("purple") lid();

    mountingplate();
        
} else {
    // can't use module here when we want seperate objects / lazy union
    print_shell_assembled();
    print_topcover();
    print_backplate();
}

