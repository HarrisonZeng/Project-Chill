"""Second editable room study. Standard Blender bpy; retains v01 outputs.
Run Blender --background --python tools/blender/build_yua_room_v02.py
Uses the v01 construction helpers, stopping before its save/render side effects.
"""
from pathlib import Path
BASE = Path(__file__).with_name('build_yua_room.py')
source = BASE.read_text(encoding='utf-8')
exec(compile(source.split("scene.render.filepath=str(OUT/'yua_room_day.png')")[0], str(BASE), 'exec'))

# Narrow the room rather than making the chair implausibly huge.
for name in ['01 Room shell','02 U desk','05 Window and curtains']:
    for o in C[name].objects:
        o.location.x *= .72
        if o.type == 'MESH':
            for v in o.data.vertices: v.co.x *= .72
        elif o.type == 'CURVE':
            for s in o.data.splines:
                for p in s.bezier_points:
                    p.co.x *= .72; p.handle_left.x *= .72; p.handle_right.x *= .72
for name in ['04 Computer','06 Plants and flowers','07 Desk props']:
    for o in C[name].objects:
        if not o.parent: o.location.x *= .72
# The original curves store world coordinates in their mesh, not their location.
for o in C['07 Desk props'].objects:
    if o.name.startswith('Lamp ivory fabric shade'):
        for v in o.data.vertices: v.co.x -= 2.16*.28
# Shorten the desk returns slightly and retain rounded end grain edges.
for o in C['02 U desk'].objects:
    if 'return' in o.name: o.dimensions.y=2.05; o.location.y=-.19
# Move complete computer assemblies onto the narrower left desk.
bpy.data.objects['MOVE monitor as one object'].location=(-1.48,.12,.898)
bpy.data.objects['MOVE monitor as one object'].rotation_euler.z=math.radians(74)
bpy.data.objects['MOVE keyboard as one object'].location=(-1.45,-.63,.92)
bpy.data.objects['MOVE keyboard as one object'].rotation_euler.z=math.radians(82)
bpy.data.objects['Desk mat'].location=(-1.48,-.66,.90)
bpy.data.objects['Desk mat'].dimensions=(.71,1.12,.012)
bpy.data.objects['Mint mouse'].location=(-1.44,-1.05,.95)
bpy.data.objects['Mouse wheel'].location=(-1.44,-1.03,.983)
# All three front work objects are now on the desktop, with space around them.

# Upholstery: smoothly rounded, tapered forms instead of stacked bevel boxes.
active=C['03 Lavender chair']
for o in list(active.objects): bpy.data.objects.remove(o,do_unlink=True)
pipe=material('Lavender seam piping',(.26,.18,.29),.88)
fabric.node_tree.nodes.get('Principled BSDF').inputs['Sheen Weight'].default_value=.32

def signed(v,p): return math.copysign(abs(v)**p,v)
def cushion(name,loc,half,p=.48,tilt=0):
    verts=[];faces=[];nu=64;nv=32
    for j in range(nv+1):
        lat=-math.pi/2+math.pi*j/nv
        for i in range(nu):
            a=2*math.pi*i/nu
            x=half[0]*signed(math.cos(lat),p)*signed(math.cos(a),p)
            y=half[1]*signed(math.cos(lat),p)*signed(math.sin(a),p)
            z=half[2]*signed(math.sin(lat),p)
            verts.append((x,y,z))
    for j in range(nv):
        for i in range(nu):
            a=j*nu+i;b=j*nu+(i+1)%nu;faces.append((a,b,b+nu,a+nu))
    me=bpy.data.meshes.new(name);me.from_pydata(verts,[],faces);me.update()
    o=bpy.data.objects.new(name,me);active.objects.link(o);o.location=loc;me.materials.append(fabric)
    o.rotation_euler.x=tilt
    for f in me.polygons:f.use_smooth=True
    return o

cushion('Chair tailored lower shell',(0,.055,.405),(.48,.43,.13),.45)
cushion('Chair crowned seat',(0,-.03,.535),(.405,.385,.105),.47)
b=cushion('Chair rounded enveloping back',(0,.375,.925),(.49,.115,.49),.58,-.12)
# Top of back slightly narrower; bottom forms a shallow wrap around the sitter.
for v in b.data.vertices:
    v.co.x *= 1-.10*(v.co.z/.49)
    v.co.y -= .075*(abs(v.co.x)/.49)**2
for side in [-1,1]:
    verts=[];faces=[];rings=32;n=32
    for j in range(rings+1):
        t=j/rings;y=-.36+t*.77
        top=.77+.35*t*t;bottom=.40+.025*t
        cap=max(.01,math.sin(math.pi*t))**.22
        for i in range(n):
            a=2*math.pi*i/n
            x=side*(.443+.025*math.sin(t*math.pi))+.094*signed(math.cos(a),.55)*cap
            z=(top+bottom)/2+(top-bottom)/2*signed(math.sin(a),.55)*cap
            verts.append((x,y,z))
    for j in range(rings):
        for i in range(n):
            a=j*n+i;bb=j*n+(i+1)%n;faces.append((a,bb,bb+n,a+n))
    faces.append(tuple(reversed(range(n))));faces.append(tuple(rings*n+i for i in range(n)))
    me=bpy.data.meshes.new('Sculpted arm');me.from_pydata(verts,[],faces);me.update()
    o=bpy.data.objects.new('Chair flowing arm left' if side<0 else 'Chair flowing arm right',me);active.objects.link(o);me.materials.append(fabric)
    for f in me.polygons:f.use_smooth=True
    curve('Chair arm tailored seam',[(side*.46,-.33,.67),(side*.52,-.24,.74),(side*.53,.05,.81),(side*.52,.29,.98),(side*.45,.39,1.10)],.0035,pipe)
for x in [-.32,.32]:
    for y in [-.25,.30]:
        ob=cylinder('Chair splayed tapered oak foot',(x*1.07,y,.205),.023,.35,oak,r2=.041)
        ob.rotation_euler=(.10 if y<0 else -.10,-x*.25,0)
curve('Seat cushion stitched perimeter',[(-.35,-.36,.55),(0,-.398,.55),(.35,-.36,.55),(.408,-.10,.55),(.36,.28,.55),(0,.34,.55),(-.36,.28,.55),(-.408,-.10,.55),(-.35,-.36,.55)],.003,pipe)
curve('Back outer piping',[(-.44,.28,.71),(-.46,.29,1.12),(-.33,.28,1.36),(0,.29,1.41),(.33,.28,1.36),(.46,.29,1.12),(.44,.28,.71)],.0035,pipe)
pillow=cushion('Chair soft loose lumbar pillow',(.015,.18,.79),(.275,.09,.225),.60,-.20)
pillow.rotation_euler.y=.12;pillow.rotation_euler.z=-.08
for x in [-.14,.14]: sphere('Back fabric covered button',(x,.246,1.14),(.014,.009,.014),pipe)
parent_group('MOVE chair as one object',list(active.objects),(.12,-.02,0),math.radians(-16))

# More natural leaves: pointed curved blades with a raised central vein.
active=C['06 Plants and flowers']
for o in list(active.objects):
    if any(o.name.startswith(n) for n in ['Front succulent','Back fern','Wall-side plant']):bpy.data.objects.remove(o,do_unlink=True)
leafdeep=material('Foliage deep olive',(.075,.17,.036),.7)

def blade(name,start,end,width,ma):
    a=Vector(start);b=Vector(end);d=b-a
    across=d.cross(Vector((0,0,1)))
    if across.length<.001: across=Vector((1,0,0))
    across.normalize();verts=[];faces=[]
    for j in range(9):
        t=j/8;c=a+d*t+Vector((0,0,.025*math.sin(math.pi*t)))
        w=width*math.sin(math.pi*t)**.7
        for k in [-1,0,1]:verts.append(tuple(c+across*w*k+Vector((0,0,-abs(k)*.014*math.sin(math.pi*t)))))
    for j in range(8):
        for k in range(2):n=j*3+k;faces.append((n,n+1,n+4,n+3))
    me=bpy.data.meshes.new(name);me.from_pydata(verts,[],faces);me.update()
    o=bpy.data.objects.new(name,me);active.objects.link(o);me.materials.append(ma)
    for f in me.polygons:f.use_smooth=True
    o.modifiers.new('Leaf thickness','SOLIDIFY').thickness=.001
    curve(name+' central vein',[a,(a+b)/2+Vector((0,0,.026)),b],.0008,leaflight)
    return o

def lathe(name,xy,profile,ma):
    verts=[];faces=[];n=64
    for r,z in profile:
        for i in range(n):t=i*2*math.pi/n;verts.append((xy[0]+r*math.cos(t),xy[1]+r*math.sin(t),z))
    for j in range(len(profile)-1):
        for i in range(n):a=j*n+i;b=j*n+(i+1)%n;faces.append((a,b,b+n,a+n))
    me=bpy.data.meshes.new(name);me.from_pydata(verts,[],faces);me.update()
    o=bpy.data.objects.new(name,me);active.objects.link(o);me.materials.append(ma)
    for f in me.polygons:f.use_smooth=True
    return o

def pot(name,x,y,z,s=1):
    lathe(name+' shaped ceramic',(x,y),[(0,z),(.072*s,z),(.077*s,z+.015*s),(.090*s,z+.13*s),(.092*s,z+.15*s),(.082*s,z+.15*s),(.078*s,z+.135*s)],cream)
    cylinder(name+' soil',(x,y,z+.133*s),.078*s,.006,soil)
    for i in range(9):
        t=i*2.4;st=(x,y,z+.14*s);end=(x+math.cos(t)*.13*s,y+math.sin(t)*.13*s,z+(.20+.10*(i%3))*s)
        rod(name+' stalk',st,end,.002*s,leafdeep)
        blade(name+' leaf',end,(end[0]+math.cos(t)*.08*s,end[1]+math.sin(t)*.08*s,end[2]+.035*s),.043*s,leafmat if i%2 else leafdeep)
    torus(name+' pot lip',(x,y,z+.147*s),.087*s,.005*s,cream)
pot('Front pothos',-1.73,-1.14,.90,.85)
pot('Sill plant',.46,1.39,.90,.85)
pot('Desk plant',1.91,1.27,.90,.85)
# Trailing plant and shallow wall shelf give the right side a lived-in silhouette.
active=C['07 Desk props']
cube('Botanical display shelf',(1.60,1.62,2.76),(.96,.38,.045),oak,.01)
for x in [1.25,1.97]:rod('Shelf brass support',(x,1.78,2.49),(x,1.48,2.73),.009,brass)
active=C['06 Plants and flowers'];pot('Shelf pothos',1.30,1.57,2.79,.85)
for k in range(3):
    pts=[(1.30+k*.04,1.53,2.91),(1.27+k*.04,1.37,2.77),(1.22+k*.07,1.34,2.55),(1.24+k*.07,1.35,2.31-k*.09)]
    curve('Hanging vine',pts,.003,leafdeep)
    for j in range(6):
        z=2.76-j*.073-k*.026;x=1.23+k*.07
        side=-1 if j%2 else 1
        blade('Trailing heart leaf',(x,1.34,z),(x+side*.075,1.28,z-.065),.038,leafmat if j%2 else leafdeep)

active=C['07 Desk props']
# Refine the lamp with a turned brass profile and a finely pleated shade.
for o in list(active.objects):
    if o.name.startswith(('Lamp stem','Lamp base','Lamp ivory fabric shade')):bpy.data.objects.remove(o,do_unlink=True)
lx=2.16*.72
lathe('Lamp turned brass base',(lx,ly),[(0,.903),(.145,.903),(.15,.92),(.12,.94),(.075,.95),(.055,.97),(.044,1.00),(.04,1.04),(.029,1.08),(.032,1.12),(.055,1.15),(.055,1.18),(.029,1.20),(.025,1.41)],brass)
verts=[];faces=[];n=128
for z,r in [(1.39,.25),(1.40,.252),(1.75,.142),(1.77,.14)]:
    for i in range(n):
        t=2*math.pi*i/n;rr=r+(.003 if i%2 else -.003);verts.append((lx+rr*math.cos(t),ly+rr*math.sin(t),z))
for j in range(3):
    for i in range(n):a=j*n+i;b=j*n+(i+1)%n;faces.append((a,b,b+n,a+n))
me=bpy.data.meshes.new('Pleated shade');me.from_pydata(verts,[],faces);me.update()
o=bpy.data.objects.new('Lamp tailored pleated linen shade',me);active.objects.link(o);me.materials.append(cream);o.modifiers.new('Linen thickness','SOLIDIFY').thickness=.004
# Ceramic botanical motifs on mug and planter, and a spoon on the saucer.
cx=1.95*.72
for j in range(3):
    xx=cx-.03+j*.027
    curve('Cup painted sprig',[(xx,cy-.080,.956),(xx+.008,cy-.089,1.03)],.0017,leafmat)
    for k in range(3):sphere('Cup painted leaf',(xx+(-.008 if k%2 else .012),cy-.090,.974+k*.018),(.010,.0015,.005),leafmat)
rod('Teaspoon handle',(cx+.08,cy-.10,.925),(cx+.18,cy-.16,.925),.004,brass)
sphere('Teaspoon bowl',(cx+.065,cy-.092,.924),(.022,.012,.004),brass)
# Writing pad lines and spiral binding; props remain separate and editable.
nx=1.88*.72
for j in range(8):cube('Notebook faint ruled line',(nx, .84+j*.022,.938),(.33,.001,.0005),sage,0,(0,0,-.12))
for j in range(12):torus('Notebook binding ring',(nx-.196,.79+j*.022,.94),.009,.0015,brass,(0,math.pi/2,0))
# A little oak drawer box below the wall prints.
cube('Stationery chest',(1.91,1.60,1.045),(.34,.29,.30),oak,.009)
for j in range(2):
    cube('Stationery drawer front',(1.91,1.446,.976+j*.14),(.31,.026,.12),oak,.007)
    sphere('Drawer brass knob',(1.91,1.425,.976+j*.14),(.015,.012,.012),brass)
# Fix books that previously extended off the desktop.
for o in active.objects:
    if o.name.startswith('Book'):o.location.x-=.09
# Desk mat stitching, inset well inside the rounded edge.
curve('Desk mat sewn border',[(-1.80,-1.16,.908),(-1.80,-.15,.908),(-1.16,-.15,.908),(-1.16,-1.16,.908),(-1.80,-1.16,.908)],.0018,cream)
# Dino gains a tail, felt spikes, nostrils and embroidery.
dx=-.40*.72
sphere('Dino curved tail',(dx,1.44,.99),(.07,.15,.045),plush)
for x in [-.032,.032]:sphere('Dino nostril',(dx+x,1.169,1.278),(.004,.004,.005),dark)
curve('Dino embroidered smile',[(dx-.040,1.172,1.246),(dx,1.162,1.238),(dx+.040,1.172,1.246)],.0018,dark)
for i in range(5):sphere('Dino crown felt spike',(dx-.085+i*.042,1.315,1.385+math.sin(i*math.pi/4)*.02),(.018,.018,.028),belly)
# Ground plush and timer on simple round wood coasters.
for xx in [dx,-.91*.72]:cylinder('Keepsake oak coaster',(xx,1.30,.907),.15,.017,oak)

# Material direction: warm wood, cooler lavender shadows, controlled highlights.
for ma in [oak,floorwood]:
    p=ma.node_tree.nodes.get('Principled BSDF');p.inputs['Roughness'].default_value=.36
    p.inputs['Coat Weight'].default_value=.16;p.inputs['Coat Roughness'].default_value=.3
wall.node_tree.nodes.get('Principled BSDF').inputs['Base Color'].default_value=(.59,.56,.46,1)
# Existing backdrop must not obstruct actual window light rays.
bpy.data.objects['Outside city - 2D backdrop'].visible_shadow=False
active=C['08 Lighting and cameras']
for o in list(active.objects):
    if o.type=='LIGHT':bpy.data.objects.remove(o,do_unlink=True)
scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.65,.75,1,1)
scene.world.node_tree.nodes['Background'].inputs[1].default_value=.22
area('Window soft daylight',(-1.0,1.05,3.3),(0,-.2,.6),350,(1,.87,.66),2.0)
area('Cool room bounce',(.4,-3,2.7),(0,.3,1),95,(.72,.82,1),3)
area('Lamp warm pool',(lx,ly,1.41),(lx,ly,.9),9,(1,.63,.28),.18)
ld=bpy.data.lights.new('Afternoon sun through window','SUN');ld.energy=1.5;ld.angle=math.radians(7);ld.color=(1,.82,.60)
ob=bpy.data.objects.new(ld.name,ld);active.objects.link(ob);ob.rotation_euler=Vector((-.70,-1,-1.0)).to_track_quat('-Z','Y').to_euler()
scene.view_settings.exposure=-.2
# Fix render-review issues: close right wall and keep the cable on the desk.
rw=bpy.data.objects['Right wall for botanical prints'];rw.location.x=2.54;rw.dimensions.x=3.0
rail=bpy.data.objects['Curtain brass rail'];rail.scale.z*=.72
for objname in ['Monitor power cable','Desk mat sewn border']:
    bpy.data.objects.remove(bpy.data.objects[objname],do_unlink=True)
active=C['04 Computer']
curve('Monitor cable resting on desktop',[(-1.62,.26,.910),(-1.79,.18,.910),(-1.81,-.12,.910),(-1.82,-.42,.910)],.005,mint)
active=C['07 Desk props']
pts=[(-1.78,-1.12,.908),(-1.78,-.19,.908),(-1.75,-.16,.908),(-1.21,-.16,.908),(-1.18,-.19,.908),(-1.18,-1.12,.908),(-1.21,-1.15,.908),(-1.75,-1.15,.908),(-1.78,-1.12,.908)]
seam=curve('Desk mat inset stitched border',pts,.0014,cream)
for bp in seam.data.splines[0].bezier_points:bp.handle_left_type='VECTOR';bp.handle_right_type='VECTOR'
# Glass vase has actual inner and outer walls, exposing the flower stems.
active=C['06 Plants and flowers']
bpy.data.objects.remove(bpy.data.objects['Daisy vase'],do_unlink=True)
glass=material('Celadon glass vase',(.72,.87,.71),.12)
gp=glass.node_tree.nodes.get('Principled BSDF');gp.inputs['Transmission Weight'].default_value=.88;gp.inputs['IOR'].default_value=1.45
lathe('Daisy shaped glass vase',(-1.33*.72,1.35),[(0,.90),(.063,.90),(.081,.92),(.074,1.02),(.052,1.105),(.055,1.13),(.050,1.135),(.047,1.11),(.068,1.02),(.074,.925),(0,.915)],glass)
active=C['08 Lighting and cameras']

# Final framing review: floor coverage and seamless plaster joins.
active=C['01 Room shell']
cube('Continuous floor under planks',(0,0,-.102),(24,24,.025),floorwood,0)
for ob in active.objects:
    if ob.type=='MESH' and wall in list(ob.data.materials):
        for mod in list(ob.modifiers):ob.modifiers.remove(mod)
# Extend the window left so the composition is backed by daylight, not blank wall.
for ob in C['05 Window and curtains'].objects:
    ob.location.x=1.15+(ob.location.x-1.15)*1.18
    if ob.type=='MESH':
        if ob.name=='Curtain brass rail':ob.scale.z*=1.18
        else:
            for vert in ob.data.vertices:vert.co.x*=1.18
bpy.data.objects['Left window pier'].location.x-=.54
active=C['08 Lighting and cameras']
# A continuous wall surface avoids coplanar seams between the original blocks.
active=C['01 Room shell']
for ob in list(active.objects):
    if ob.type=='MESH' and wall in list(ob.data.materials):bpy.data.objects.remove(ob,do_unlink=True)
verts=[(-12,1.86,0),(12,1.86,0),(12,1.86,5),(-12,1.86,5),(-2.39,1.86,.97),(1.05,1.86,.97),(1.05,1.86,3.25),(-2.39,1.86,3.25)]
me=bpy.data.meshes.new('Continuous plaster around opening');me.from_pydata(verts,[],[(0,1,5,4),(1,2,6,5),(7,6,2,3),(0,4,7,3)]);me.update()
ob=bpy.data.objects.new('Seamless wall with real window opening',me);active.objects.link(ob);me.materials.append(wall)
mod=ob.modifiers.new('Wall thickness','SOLIDIFY');mod.thickness=.16;mod.offset=-1
bpy.data.objects['Continuous floor under planks'].location.z=-.014
active=C['08 Lighting and cameras']
# Selected framing: gentle three-quarter desk view with a central seated subject zone.
cam.name='CAM 01 - selected call composition';cam.data.name=cam.name
cam.location=(1.50,-6.35,3.35);target=Vector((0,.48,1.28))
cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.lens=45
cam.data.dof.use_dof=False
# Optional second camera documents the room without changing the chosen default.
data=bpy.data.cameras.new('CAM 02 - wider room inspection');wide=bpy.data.objects.new(data.name,data);active.objects.link(wide)
wide.location=(2.6,-6.8,3.6);wide.rotation_euler=(Vector((0,.45,1.35))-wide.location).to_track_quat('-Z','Y').to_euler();data.lens=45
anchor=bpy.data.objects.new('YUA seated eye target - guide only',None);active.objects.link(anchor);anchor.location=(.12,-.06,1.36);anchor.empty_display_type='SPHERE';anchor.empty_display_size=.06;anchor.hide_render=True
scene.camera=cam
scene.cycles.samples=64
scene.render.resolution_x=1600;scene.render.resolution_y=900
scene['README']='Room v02: narrower desk; tailored chair; refined foliage, lamp and desk details. Selected CAM 01. No character or game changes. See README_v02.md.'
bpy.data.texts['START HERE'].clear();bpy.data.texts['START HERE'].write('YUA ROOM v02\n\nSelected view: CAM 01 - selected call composition. Numpad 0 to view; F12 to render.\nThe room is still a 3D art study, not a finished anime background. No character included.\nOriginal v01 files are retained. Rebuilding v02 overwrites v02 outputs only.\nSee art_source/yua_room/README_v02.md.\n')
for screen in bpy.data.screens:
    for a in screen.areas:
        if a.type=='VIEW_3D':
            a.spaces.active.region_3d.view_perspective='CAMERA'
            a.spaces.active.shading.type='MATERIAL'
bpy.ops.object.select_all(action='DESELECT')
scene.render.filepath=str(OUT/'yua_room_v02_day.png')
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'yua_room_v02.blend'))
bpy.ops.render.render(write_still=True)
print('YUA_ROOM_V02_COMPLETE',len(scene.objects),'objects')


