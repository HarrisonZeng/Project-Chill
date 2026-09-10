"""Editable Yua room study. Run with Blender --background --python this_file.

The existing game assets are read-only references. All generated objects belong
to a new scene saved under art_source/yua_room. No third-party add-ons required.
"""
import bpy
import math
import random
from pathlib import Path
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'art_source' / 'yua_room'
OUT.mkdir(parents=True, exist_ok=True)
random.seed(21)
bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene
scene.unit_settings.system = 'METRIC'
scene.render.engine = 'CYCLES'
scene.cycles.samples = 48
scene.cycles.use_denoising = True
scene.render.resolution_x = 1600
scene.render.resolution_y = 900
scene.render.resolution_percentage = 100
scene.render.image_settings.file_format = 'PNG'
scene.world = bpy.data.worlds.new('Warm daylight')
scene.world.use_nodes = True
scene.world.node_tree.nodes['Background'].inputs[0].default_value = (.72,.80,.87,1)
scene.world.node_tree.nodes['Background'].inputs[1].default_value = .45
scene.view_settings.view_transform = 'AgX'

def collection(name):
    c = bpy.data.collections.new(name)
    scene.collection.children.link(c)
    return c

C = {n: collection(n) for n in ['01 Room shell','02 U desk','03 Lavender chair',
    '04 Computer','05 Window and curtains','06 Plants and flowers','07 Desk props',
    '08 Lighting and cameras','09 References - hidden']}
active = C['01 Room shell']

def place(o, name, mat=None):
    o.name = name
    for c in list(o.users_collection): c.objects.unlink(o)
    active.objects.link(o)
    if mat: o.data.materials.append(mat)
    return o

def material(name, color, roughness=.5, metal=0):
    m = bpy.data.materials.new(name)
    m.diffuse_color = (*color,1)
    m.use_nodes = True
    p = m.node_tree.nodes.get('Principled BSDF')
    p.inputs['Base Color'].default_value=(*color,1)
    p.inputs['Roughness'].default_value=roughness
    p.inputs['Metallic'].default_value=metal
    return m

def textured(name, a,b, scale, strength=.07):
    m=material(name,a,.65)
    ns=m.node_tree.nodes; links=m.node_tree.links
    coord=ns.new('ShaderNodeTexCoord'); mapping=ns.new('ShaderNodeVectorMath')
    mapping.operation='MULTIPLY'; mapping.inputs[1].default_value=scale
    links.new(coord.outputs['Generated'],mapping.inputs[0])
    noise=ns.new('ShaderNodeTexNoise'); noise.inputs['Scale'].default_value=5
    noise.inputs['Detail'].default_value=3
    links.new(mapping.outputs[0],noise.inputs['Vector'])
    ramp=ns.new('ShaderNodeValToRGB')
    ramp.color_ramp.elements[0].position=.15; ramp.color_ramp.elements[0].color=(*a,1)
    ramp.color_ramp.elements[1].position=.85; ramp.color_ramp.elements[1].color=(*b,1)
    links.new(noise.outputs['Fac'],ramp.inputs[0])
    p=ns.get('Principled BSDF'); links.new(ramp.outputs[0],p.inputs['Base Color'])
    bump=ns.new('ShaderNodeBump'); bump.inputs['Strength'].default_value=strength
    bump.inputs['Distance'].default_value=.015
    links.new(noise.outputs['Fac'],bump.inputs['Height']); links.new(bump.outputs[0],p.inputs['Normal'])
    return m

oak=textured('Honey oak - procedural grain',(.18,.069,.018),(.42,.215,.065),(1,32,5))
floorwood=textured('Floor oak - gentle grain',(.17,.09,.045),(.35,.23,.12),(1,35,3))
fabric=textured('Lavender woven upholstery',(.29,.22,.34),(.47,.38,.51),(65,65,65),.12)
sage=textured('Sage linen curtains',(.19,.26,.12),(.39,.45,.24),(45,3,50),.1)
cream=material('Warm ivory',(.86,.82,.72))
wall=material('Plaster warm white',(.72,.69,.60),.95)
mint=material('Mint enamel',(.34,.59,.49),.34)
matgreen=material('Sage felt desk mat',(.19,.33,.27),.95)
keymat=material('Keyboard soft ivory',(.76,.81,.74),.48)
dark=material('Charcoal',(.035,.05,.044),.6)
brass=material('Aged brass',(.34,.22,.10),.3,.65)
soil=material('Potting soil',(.065,.036,.015),1)
leafmat=material('Leaf green',(.17,.32,.10),.75)
leaflight=material('Leaf tips',(.35,.48,.17),.7)
paper=material('Paper',(.90,.88,.79),.9)
coffee=material('Tea',(.15,.065,.016),.2)
petal=material('Daisy petals',(.94,.93,.80),.5)
yellow=material('Daisy centers',(.9,.50,.07),.7)
pink=material('Book dusty pink',(.54,.29,.30))

def cube(name,loc,size,mat,bevel=.02,rotation=None):
    bpy.ops.mesh.primitive_cube_add(size=1,location=loc)
    o=place(bpy.context.object,name,mat); o.dimensions=size
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    if bevel:
        mod=o.modifiers.new('Soft finished edges','BEVEL'); mod.width=bevel; mod.segments=3
        mod=o.modifiers.new('Weighted corner normals','WEIGHTED_NORMAL')
    if rotation: o.rotation_euler=rotation
    return o

def sphere(name,loc,size,mat):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=24,ring_count=12,location=loc)
    o=place(bpy.context.object,name,mat); o.scale=size
    for p in o.data.polygons:p.use_smooth=True
    return o

def cylinder(name,loc,r,depth,mat,vertices=48,r2=None):
    bpy.ops.mesh.primitive_cone_add(vertices=vertices,radius1=r,radius2=r if r2 is None else r2,depth=depth,location=loc)
    o=place(bpy.context.object,name,mat)
    mod=o.modifiers.new('Rounded rims','BEVEL');mod.width=.008;mod.segments=3
    o.modifiers.new('Weighted normals','WEIGHTED_NORMAL')
    for p in o.data.polygons:p.use_smooth=True
    return o

def rod(name,start,end,r,mat):
    d=Vector(end)-Vector(start)
    o=cylinder(name,(Vector(start)+Vector(end))/2,r,d.length,mat,16)
    o.rotation_euler=d.to_track_quat('Z','Y').to_euler()
    return o

def curve(name,points,r,mat):
    data=bpy.data.curves.new(name,'CURVE');data.dimensions='3D';data.bevel_depth=r;data.bevel_resolution=3
    s=data.splines.new('BEZIER');s.bezier_points.add(len(points)-1)
    for p,co in zip(s.bezier_points,points):p.co=co;p.handle_left_type='AUTO';p.handle_right_type='AUTO'
    o=bpy.data.objects.new(name,data);active.objects.link(o);data.materials.append(mat);return o

def torus(name,loc,major,minor,mat,rot=None):
    bpy.ops.mesh.primitive_torus_add(major_segments=48,minor_segments=12,location=loc,major_radius=major,minor_radius=minor)
    o=place(bpy.context.object,name,mat)
    if rot:o.rotation_euler=rot
    for p in o.data.polygons:p.use_smooth=True
    return o

def parent_group(name,objects,location,angle=0):
    p=bpy.data.objects.new(name,None);active.objects.link(p)
    for o in objects:o.parent=p
    p.location=location;p.rotation_euler[2]=angle;return p

# Actual room geometry, open on the camera side for a readable cutaway.
for row in range(19):
    for col in range(8):
        x=-4.8+col*1.28+(row%2)*.64
        # continuous floor extends beyond camera framing
        cube('Floor plank %02d-%02d'%(row,col),(x,-4.6+row*.37,-.045),(1.277,.368,.09),floorwood,.001)
cube('Back wall below window',(0,1.94,.48),(14,.16,.96),wall)
cube('Back wall above window',(0,1.94,3.5),(5.9,.16,.50),wall)
cube('Left window pier',(-4.53,1.94,2.12),(3.96,.16,2.35),wall)
cube('Right wall for botanical prints',(2.12,1.94,2.12),(1.35,.16,2.35),wall)
cube('Back skirting',(0,1.80,.095),(5.75,.035,.16),cream,.008)

active=C['02 U desk']
TOP=.84
cube('Desk - back span',(0,1.28,TOP),(5.3,.90,.105),oak,.04)
cube('Desk - left return',(-2.10,-.29,TOP),(1.1,2.25,.105),oak,.04)
cube('Desk - right return',(2.10,-.29,TOP),(1.1,2.25,.105),oak,.04)
for x,y in [(-2.45,-1.23),(-1.74,-1.23),(2.45,-1.23),(1.74,-1.23),(-2.4,1.50),(2.4,1.50)]:
    cube('Desk square oak leg',(x,y,.40),(.085,.085,.8),oak,.012)
for x in [-2.1,2.1]:cube('Desk apron',(x,-.24,.74),(.09,2.10,.17),oak)

active=C['05 Window and curtains']
for x in [-2.53,-1.20,.13,1.47]:cube('Window vertical frame',(x,1.77,2.12),(.075,.13,2.29),cream,.01)
for z in [1.0,3.23]:cube('Window horizontal frame',(-.53,1.77,z),(4.10,.16,.08),cream,.01)
cube('Deep window sill',(-.53,1.69,.99),(4.25,.42,.075),cream,.02)
rod('Curtain brass rail',(-2.8,1.57,3.34),(1.75,1.57,3.34),.025,brass)

def curtain(name,xcenter,width,mat,front=1.55):
    verts=[];faces=[];nu=48;nv=20
    for j in range(nv+1):
        v=j/nv;z=1.01+v*2.22
        gather=1-.40*math.exp(-((v-.39)/.16)**2)
        for i in range(nu+1):
            u=i/nu
            x=xcenter+(u-.5)*width*gather
            y=front+.055*math.cos(u*math.pi*12)+.035*math.sin(v*math.pi)
            verts.append((x,y,z+.018*math.cos(u*math.pi*12)*(1-v)))
    for j in range(nv):
        for i in range(nu):
            a=j*(nu+1)+i;faces.append((a,a+1,a+nu+2,a+nu+1))
    me=bpy.data.meshes.new(name);me.from_pydata(verts,[],faces);me.update()
    o=bpy.data.objects.new(name,me);active.objects.link(o);me.materials.append(mat)
    for p in me.polygons:p.use_smooth=True
    sol=o.modifiers.new('Fabric thickness','SOLIDIFY');sol.thickness=.003
    return o

curtain('Sage curtain left',-2.39,.56,sage)
curtain('Sage curtain right',1.34,.56,sage)
for x in [-2.39,1.34]:cube('Curtain tieback',(x,1.49,1.88),(.36,.045,.085),sage,.018)
sheer=material('Ivory sheer linen',(.91,.91,.83),.9)
curtain('Ivory inner curtain left',-1.97,.31,sheer,1.67)
curtain('Ivory inner curtain right',.91,.31,sheer,1.67)

# Existing outside artwork is a packed, replaceable backdrop; not claimed as 3D.
backdrop=ROOT/'assets/art/backgrounds/view_city_day.png'
m=material('Outside - replaceable painted city',(.8,.85,.8))
ns=m.node_tree.nodes;ns.clear();out=ns.new('ShaderNodeOutputMaterial');em=ns.new('ShaderNodeEmission');tex=ns.new('ShaderNodeTexImage')
tex.image=bpy.data.images.load(str(backdrop));tex.image.pack();em.inputs['Strength'].default_value=.8
m.node_tree.links.new(tex.outputs['Color'],em.inputs['Color']);m.node_tree.links.new(em.outputs[0],out.inputs[0])
me=bpy.data.meshes.new('Backdrop quad');me.from_pydata([(-3,2.04,.78),(2,2.04,.78),(2,2.04,3.55),(-3,2.04,3.55)],[],[(0,1,2,3)])
me.uv_layers.new()
for loop,uv in zip(me.uv_layers.active.data,[(0,0),(1,0),(1,1),(0,1)]):loop.uv=uv
o=bpy.data.objects.new('Outside city - 2D backdrop',me);active.objects.link(o);me.materials.append(m)

active=C['03 Lavender chair']
cube('Chair seat cushion',(0,.0,.51),(.89,.78,.24),fabric,.14)
cube('Chair upholstered base',(0,.07,.40),(.97,.86,.19),fabric,.13)
cube('Chair curved back cushion',(0,.42,.88),(.92,.22,.84),fabric,.16,(-.10,0,0))
for x in [-.48,.48]:
    cube('Chair padded arm',(x,.04,.72),(.21,.76,.28),fabric,.095)
    cube('Chair upholstered side',(x,.09,.57),(.18,.72,.37),fabric,.075)
for x in [-.33,.33]:
    for y in [-.25,.34]:rod('Chair tapered wooden leg',(x*1.18,y*1.1,.035),(x,y,.42),.037,oak)
cube('Chair lumbar pillow',(.03,.26,.72),(.52,.16,.39),fabric,.085,(-.19,.09,-.09))

parent_group('MOVE chair as one object',list(active.objects),(0,0,0),math.radians(-18))

active=C['04 Computer']
objs=[]
objs.append(cube('Monitor mint frame',(0,0,.49),(1.01,.065,.66),mint,.045))
screenmat=material('Screen soft lavender',(.55,.53,.65),.8)
p=screenmat.node_tree.nodes.get('Principled BSDF');p.inputs['Emission Color'].default_value=(.5,.48,.62,1);p.inputs['Emission Strength'].default_value=.25
objs.append(cube('Monitor screen',(0,-.036,.50),(.91,.009,.55),screenmat,.018))
objs.append(cube('Monitor stand',(0,.04,.11),(.12,.10,.21),mint,.02))
objs.append(cube('Monitor foot',(0,-.005,.012),(.44,.27,.027),mint,.03))
ui=material('Screen app warm white',(.73,.74,.73),.9)
objs.append(cube('Screen app document',(.07,-.043,.50),(.66,.003,.44),ui,.003))
for i in range(7):
    objs.append(cube('Screen paragraph %d'%i,(.045,-.046,.66-i*.045),(.44 if i%3 else .32,.002,.009),screenmat,.001))
for i in range(5):
    objs.append(sphere('Screen sidebar dot',(-.36,-.045,.67-i*.07),(.015,.003,.015),mint))
parent_group('MOVE monitor as one object',objs,(-2.02,-.04,.898),math.radians(57))
cube('Desk mat',(-2.04,-.74,.90),(.94,1.05,.012),matgreen,.045)
objs=[cube('Keyboard body',(0,0,0),(.71,.25,.022),mint,.024)]
for row in range(5):
    for col in range(14):
        if row==0 and 4<=col<=8:continue
        objs.append(cube('Key %02d %02d'%(row,col),(-.32+col*.049,-.098+row*.044,.02),(.043,.037,.012),keymat,.004))
objs.append(cube('Space bar',(-.01,-.098,.02),(.24,.037,.012),keymat,.004))
parent_group('MOVE keyboard as one object',objs,(-1.99,-.68,.92),math.radians(72))
mouse=sphere('Mint mouse',(-2.04,-1.1,.95),(.075,.12,.035),mint)
cube('Mouse wheel',(-2.04,-1.08,.98),(.01,.035,.008),cream,.003)
curve('Monitor power cable',[(-2.15,.20,.90),(-2.40,.12,.90),(-2.54,-.12,.9),(-2.51,-.40,.90)],.008,mint)

active=C['07 Desk props']
# Lamp with an open tapered shade.
lx,ly=2.16,1.25
cylinder('Lamp base',(lx,ly,.925),.145,.05,brass)
rod('Lamp stem',(lx,ly,.95),(lx,ly,1.44),.027,brass)
torus('Lamp stem collar',(lx,ly,1.18),.055,.017,brass)
verts=[];faces=[]
for z,r in [(1.39,.25),(1.77,.14)]:
    for i in range(64):a=2*math.pi*i/64;verts.append((lx+r*math.cos(a),ly+r*math.sin(a),z))
for i in range(64):j=(i+1)%64;faces.append((i,j,64+j,64+i))
me=bpy.data.meshes.new('Shade linen mesh');me.from_pydata(verts,[],faces)
o=bpy.data.objects.new('Lamp ivory fabric shade',me);active.objects.link(o);me.materials.append(cream)
o.modifiers.new('Shade fabric thickness','SOLIDIFY').thickness=.006
torus('Shade lower piping',(lx,ly,1.39),.25,.007,cream)
torus('Shade upper piping',(lx,ly,1.77),.14,.006,cream)

# Cup and saucer, notebook, handheld.
cx,cy=1.95,.31
cylinder('Tea saucer',(cx,cy,.908),.145,.015,cream)
cylinder('Tea cup',(cx,cy,.995),.081,.15,cream,r2=.095)
torus('Cup lip',(cx,cy,1.071),.090,.007,cream)
cylinder('Tea surface',(cx,cy,1.069),.083,.004,coffee)
torus('Cup handle',(cx+.103,cy,1.005),.05,.011,cream,(math.pi/2,0,0))
cube('Notebook sage cover',(1.88,.92,.908),(.43,.29,.023),mint,.008,(0,0,-.12))
cube('Notebook pages',(1.88,.92,.925),(.415,.277,.023),paper,.004,(0,0,-.12))
rod('Green pen',(1.78,.90,.944),(2.01,.87,.944),.009,mint)
cube('Handheld console',(2.18,-.24,.93),(.50,.22,.057),mint,.034,(0,0,-.10))
cube('Handheld display',(2.18,-.24,.962),(.32,.19,.006),dark,.01,(0,0,-.10))
for x in [1.99,2.37]:cylinder('Console thumb stick',(x,-.24,.969),.019,.012,dark,24)

# Books against the back wall.
for i,(h,ma) in enumerate([(.28,pink),(.37,sage),(.32,cream),(.40,mint)]):
    cube('Book spine %d'%i,(2.52+i*.06,1.52,.90+h/2),(.047,.19,h),ma,.006,(0,-.08 if i==0 else 0,0))
    cube('Book spine title %d'%i,(2.52+i*.06,1.418,.98+h/2),(.025,.004,.06),paper,.001)

active=C['06 Plants and flowers']
def plant(name,x,y,z,scale=1):
    cylinder(name+' ceramic pot',(x,y,z+.075*scale),.075*scale,.15*scale,cream,r2=.10*scale)
    cylinder(name+' soil',(x,y,z+.145*scale),.085*scale,.008,soil)
    for i in range(9):
        a=i*2.4;h=(.16+random.random()*.17)*scale
        start=(x,y,z+.14*scale);end=(x+math.cos(a)*.10*scale,y+math.sin(a)*.10*scale,z+.14*scale+h)
        rod(name+' stem',start,end,.003*scale,leafmat)
        ob=sphere(name+' leaf',end,(.037*scale,.018*scale,.082*scale),leafmat if i%2 else leaflight)
        ob.rotation_euler=(.6*math.sin(a),.6*math.cos(a),a)
plant('Front succulent',-2.36,-1.17,.91,.75)
plant('Back fern',.64,1.39,.91,.8)
plant('Wall-side plant',2.64,1.20,.91,.9)
# Daisy bouquet.
vase=material('Celadon vase',(.57,.71,.57),.26)
cylinder('Daisy vase',(-1.33,1.35,1.015),.078,.23,vase,r2=.061)
for i in range(9):
    a=i*2.4;x=-1.33+math.cos(a)*random.uniform(.05,.20);y=1.35+math.sin(a)*.12;z=1.36+random.random()*.22
    rod('Daisy stem',(-1.33,1.35,1.1),(x,y,z),.004,leafmat)
    sphere('Daisy golden center',(x,y,z),(.023,.023,.02),yellow)
    for k in range(8):
        t=k*math.pi/4;ob=sphere('Daisy petal',(x+math.cos(t)*.038,y+math.sin(t)*.038,z-.003),(.030,.014,.008),petal);ob.rotation_euler[2]=t

active=C['07 Desk props']
# Small analog timer, face angled toward camera.
objs=[cube('Clock ivory body',(0,0,.12),(.26,.095,.26),cream,.035)]
ob=cylinder('Clock green dial',(0,-.055,.12),.094,.008,matgreen);ob.rotation_euler[0]=math.pi/2;objs.append(ob)
for i in range(12):
    t=i*math.pi/6
    objs.append(sphere('Clock hour dot',(math.sin(t)*.077,-.065,.12+math.cos(t)*.077),(.004,.003,.004),cream))
objs.append(rod('Clock minute hand',(0,-.070,.12),(.012,-.070,.179),.003,cream))
objs.append(rod('Clock hour hand',(0,-.072,.12),(-.035,-.072,.12),.004,cream))
parent_group('MOVE clock',objs,(-.91,1.30,.90),.10)
# Original simple dinosaur plush proxy, independent editable pieces.
plush=material('Dinosaur soft sage',(.36,.56,.37),.95)
belly=material('Dinosaur pale belly',(.74,.76,.48),.95)
sphere('Dino body',(-.40,1.33,1.08),(.13,.105,.18),plush)
sphere('Dino head',(-.40,1.31,1.29),(.13,.10,.11),plush)
sphere('Dino muzzle',(-.40,1.23,1.265),(.11,.07,.055),plush)
sphere('Dino belly',(-.40,1.232,1.07),(.087,.022,.11),belly)
for dx in [-.075,.075]:
    sphere('Dino eye',(-.40+dx,1.223,1.315),(.009,.007,.012),dark)
    sphere('Dino foot',(-.40+dx,1.24,.942),(.065,.085,.04),plush)
    sphere('Dino arm',(-.40+dx*1.7,1.28,1.10),(.047,.04,.077),plush)
for z in [1.12,1.20,1.28]:sphere('Dino back spike',(-.40,1.432,z),(.025,.035,.03),belly)

# Botanical wall prints, actual geometry and simplified leaf artwork.
for i,(x,z,w,h) in enumerate([(1.97,2.26,.39,.53),(2.49,2.17,.34,.43),(2.17,2.94,.49,.35)]):
    cube('Botanical frame %d'%i,(x,1.815,z),(w,.055,h),oak,.012)
    cube('Botanical paper %d'%i,(x,1.781,z),(w-.035,.008,h-.035),paper,.001)
    rod('Print drawn stem',(x,1.773,z-h*.30),(x+.02,1.773,z+h*.3),.003,leafmat)
    for j in range(5):
        side=1 if j%2 else -1
        ob=sphere('Print leaf',(x+side*.045,1.769,z-h*.2+j*h*.1),(.040,.002,.020),leafmat);ob.rotation_euler[1]=side*.5

active=C['08 Lighting and cameras']
def area(name,loc,target,power,color,size):
    data=bpy.data.lights.new(name,'AREA');data.energy=power;data.color=color;data.shape='DISK';data.size=size
    o=bpy.data.objects.new(name,data);active.objects.link(o);o.location=loc;o.rotation_euler=(Vector(target)-o.location).to_track_quat('-Z','Y').to_euler();return o
area('Daylight - broad window',(-1.7,1.1,4.3),(0,-.3,.4),650,(1,.90,.74),3.4)
area('Soft camera fill',(1.5,-3.5,3.8),(0,.4,1),250,(.79,.86,1),4)
area('Warm lamp glow',(lx,ly,1.40),(lx,ly,.85),12,(1,.66,.32),.3)
data=bpy.data.cameras.new('Camera - reference composition');cam=bpy.data.objects.new('Camera - reference composition',data);active.objects.link(cam)
cam.location=(3.1,-6.5,3.75);target=Vector((-.05,.42,1.49));cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler()
data.type='PERSP';data.lens=47;scene.camera=cam
data.dof.use_dof=False

active=C['09 References - hidden']
ref=bpy.data.objects.new('REFERENCE room_master - original image',None);active.objects.link(ref);ref.empty_display_type='IMAGE';ref.data=bpy.data.images.load(str(ROOT/'assets/art/backgrounds/room_master.png'));ref.data.pack();ref.hide_render=True;ref.hide_viewport=True
active.hide_render=True;active.hide_viewport=True
scene['README']='Yua room v01: editable geometry, procedural materials, packed outside illustration. Units metres. Camera is a proposed match, not a measured reconstruction. No Yua character model included. See README.md.'
scene['reference']='assets/art/backgrounds/room_master.png'
text=bpy.data.texts.new('START HERE')
text.write('YUA ROOM - editable first study\n\nNumpad 0: game camera. Z > Material Preview: materials. F12: render.\nCollections separate furniture, props, lighting and room. Monitor and keyboard have MOVE parent empties.\nWindow city is the existing packed 2D artwork; every interior item is geometry.\nOriginal game assets are untouched. Full notes in art_source/yua_room/README.md.\n')
for screen in bpy.data.screens:
    for a in screen.areas:
        if a.type=='VIEW_3D':
            a.spaces.active.region_3d.view_perspective='CAMERA'
            a.spaces.active.shading.type='MATERIAL'
            a.spaces.active.overlay.show_overlays=False
bpy.ops.object.select_all(action='DESELECT')
scene.render.filepath=str(OUT/'yua_room_day.png')
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'yua_room_v01.blend'))
bpy.ops.render.render(write_still=True)
print('YUA_ROOM_COMPLETE',len(scene.objects),'objects',str(OUT/'yua_room_v01.blend'))
