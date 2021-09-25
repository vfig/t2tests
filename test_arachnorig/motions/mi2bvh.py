#!/usr/bin/env python
# ##### BEGIN GPL LICENSE BLOCK #####
#
#  This program is free software; you can redistribute it and/or
#  modify it under the terms of the GNU General Public License
#  as published by the Free Software Foundation; either version 2
#  of the License, or (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software Foundation,
#  Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# ##### END GPL LICENSE BLOCK #####

"""mi2bvh.py mifile calfile mapfile [bvhfile]
   Convert a MI/MC motion to BVH.

"""

__all__ = (
    "read_map",
    "read_cal",
    "write_bvh",
    "cal2bvh",
    "mi2bvh"
)

from struct import unpack
from math import sqrt,sin,cos,asin,acos,atan2,pi, fsum as sum

radians = 180 / pi
two_pi = 2 * pi
epsilon = 0.00001
sqrt2 = sqrt(2)


def scale_v(v, m):
    i,j,k = v
    return (i*m, j*m, k*m)


def r_to_d(r):
    i,j,k = r
    return (i*radians, j*radians, k*radians)


def q_to_m(q):
    w,x,y,z = [c*sqrt2 for c in q]
    da,db,dc = w*x, w*y, w*z
    aa,ab,ac = x*x, x*y, x*z
    bb,bc = y*y, y*z
    cc = z*z
    return ((1.0-bb-cc, dc+ab, ac-db),
            (ab-dc, 1.0-aa-cc, da+bc),
            (db+ac, bc-da, 1.0-aa-bb))


def m_to_v(mx):
    cy = sqrt(mx[0][0]*mx[0][0] + mx[0][1]*mx[0][1])
    if cy < epsilon:
        return (atan2(-mx[2][1], mx[1][1]), atan2(-mx[0][2], cy), 0.0)
    v1 = (atan2(mx[1][2], mx[2][2]),
          atan2(-mx[0][2], cy),
          atan2(mx[0][1], mx[0][0]))
    v2 = (atan2(-mx[1][2], -mx[2][2]),
          atan2(-mx[0][2], -cy),
          atan2(-mx[0][1], -mx[0][0]))
    if sum([abs(c) for c in v1]) > sum([abs(c) for c in v2]):
        return v2
    return v1


def q_to_v(q):
    return m_to_v(q_to_m(q))


def write_quaternion(q):
    # MC rotation is left-handed
    x,y,z = r_to_d(q_to_v(q))
    return "{:.6f} {:.6f} {:.6f}".format(-x,-y,-z)


def write_vector(v):
    if v:
        return "{:.6f} {:.6f} {:.6f}".format(*v)
    return "0.000000 0.000000 0.000000"


creature_types = {
                 0x7FFFF : "Human",
                 0xFFFFF : "HumanWithSword",
                 0x3FFFF : "Droid",
                 0xFF : "SpidBot",
                 0x1FFFFFFF : "Arachnid",
                 0xE : "PlyrArm",
                 0x3FFFFF : "BugBeast",
                 0x1FFFFF : "Crayman",
                 0x7F : "Sweel",
                 0x7 : "Overlord",
                 }

creature_joints = {
                0x7FFFF : ('LToe',
                           'RToe',
                           'LAnkle',
                           'RAnkle',
                           'LKnee',
                           'RKnee',
                           'LHip',
                           'RHip',
                           'Butt',
                           'Neck',
                           'LShldr',
                           'RShldr',
                           'LElbow',
                           'RElbow',
                           'LWrist',
                           'RWrist',
                           'LFinger',
                           'RFinger',
                           'Abdomen',
                           'Head'),
                0xFFFFF : ('LToe',
                           'RToe',
                           'LAnkle',
                           'RAnkle',
                           'LKnee',
                           'RKnee',
                           'LHip',
                           'RHip',
                           'Butt',
                           'Neck',
                           'LShldr',
                           'RShldr',
                           'LElbow',
                           'RElbow',
                           'LWrist',
                           'RWrist',
                           'LFinger',
                           'RFinger',
                           'Abdomen',
                           'Head'),
                0x3FFFF : ('LToe',
                           'RToe',
                           'LAnkle',
                           'RAnkle',
                           'LKnee',
                           'RKnee',
                           'LHip',
                           'RHip',
                           'Butt',
                           'Abdomen',
                           'Neck',
                           'LShldr',
                           'RShldr',
                           'LElbow',
                           'RElbow',
                           'LWrist',
                           'RWrist',
                           'Head'),
                0xFF : ('base',
                        'LMand','LMElbow',
                        'RMand','RMElbow',
                        'R1Shldr','R1Elbow','R1Wrist',
                        'R2Shldr','R2Elbow','R2Wrist',
                        'R3Shldr','R3Elbow','R3Wrist',
                        'R4Shldr','R4Elbow','R4Wrist',
                        'L1Shldr','L1Elbow','L1Wrist',
                        'L2Shldr','L2Elbow','L2Wrist',
                        'L3Shldr','L3Elbow','L3Wrist',
                        'L4Shldr','L4Elbow','L4Wrist',
                        'R1Finger','R2Finger','R3Finger','R4Finger',
                        'L1Finger','L2Finger','L3Finger','L4Finger',
                        'LTip','RTip',
                        'Sac'),
                0x1FFFFFFF : ('base',
                              'LMand','LMElbow',
                              'RMand','RMElbow',
                              'R1Shldr','R1Elbow','R1Wrist',
                              'R2Shldr','R2Elbow','R2Wrist',
                              'R3Shldr','R3Elbow','R3Wrist',
                              'R4Shldr','R4Elbow','R4Wrist',
                              'L1Shldr','L1Elbow','L1Wrist',
                              'L2Shldr','L2Elbow','L2Wrist',
                              'L3Shldr','L3Elbow','L3Wrist',
                              'L4Shldr','L4Elbow','L4Wrist',
                              'R1Finger','R2Finger','R3Finger','R4Finger',
                              'L1Finger','L2Finger','L3Finger','L4Finger',
                              'LTip','RTip'),
                0xE : ('butt',
                       'RShldr',
                       'RElbow',
                       'RWrist',
                       'RFinger'),
                0x3FFFFF : ('LToe',
                            'RToe',
                            'LAnkle',
                            'RAnkle',
                            'LKnee',
                            'RKnee',
                            'LHip',
                            'RHip',
                            'Butt',
                            'Neck',
                            'LShldr',
                            'RShldr',
                            'LElbow',
                            'RElbow',
                            'LWrist',
                            'RWrist',
                            'LFinger',
                            'RFinger',
                            'Abdomen',
                            'Head',
                            'LClaw',
                            'RClaw'),
                0x1FFFFF : ('LToe',
                            'RToe',
                            'LAnkle',
                            'RAnkle',
                            'LKnee',
                            'RKnee',
                            'LHip',
                            'RHip',
                            'Butt',
                            'Neck',
                            'LShldr',
                            'RShldr',
                            'LElbow',
                            'RElbow',
                            'TPincher',
                            'RWrist',
                            'TTip',
                            'RFinger',
                            'Abdomen',
                            'Head',
                            'BPincher',
                            'BTip'),
                0x7F : ('base',
                        'Back',
                        'Shoulder',
                        'Neck',
                        'Head',
                        'Tail',
                        'Tip'),
                0x7 : ('base',
                       'TUp','TMid','TBot','TTip',
                       'FUp','FUMid','FMid','FBMid','FBot','FTip',
                       'L2Up','L2UMid','L2Mid','L2BMid','L2Bot','L2Tip',
                       'L1Up','L1UMid','L1Mid','L1BMid','L1Bot','L1Tip',
                       'R2Up','R2UMid','R2Mid','R2BMid','R2Bot','R2Tip',
                       'R1Up','R1UMid','R1Mid','R1BMid','R1Bot','R1Tip',
                       'Head',
                       'Sac'),
                }

# Filled automatically from creature_joints
creature_maps = {}

class JointDict(dict):
    def __getitem__(self, key):
        try:
            return dict.__getitem__(self, key)
        except KeyError:
            return 'joint#'+str(key)


def builtin_map(cret):
    try:
        return creature_maps[cret]
    except KeyError:
        pass
    try:
        joints = creature_joints[cret]
        map = JointDict(enumerate(joints))
        creature_maps[cret] = map
        return map
    except KeyError:
        return JointDict()


def read_map(file):
    """
    Load a joint mapping file.
    """
    map = JointDict()
    # Some maps (Burrick) have more than one name per joint.
    for name,joint in (line.split() for line in file):
        map.setdefault(int(joint), name)
    return map


def read_cal(cal):
    """
    Load a calibration file.
    """

    joints = {}
    torsos = []

    def read_torso():
        joint,parent,numfixedjoints = unpack('<3l', cal.read(12))
        fixedjoints = list(unpack('<16l', cal.read(64))[:numfixedjoints])
        locations = [unpack('<3f', cal.read(12)) for x in range(16)][:numfixedjoints]
        if joint not in joints:
            joints[joint] = {'OFFSET':(0.0,0.0,0.0), 'PARENT':-1, 'FIXED':[]}
        joints[joint].setdefault('FIXED',[]).extend(fixedjoints)
        for j,loc in zip(fixedjoints, locations):
            if j not in joints:
                joints[j] = {}
            joints[j]['OFFSET'] = loc
            joints[j]['PARENT'] = joint
        torsos.append(joint)

    def read_limb():
        torso,numsegments,joint = unpack('<l4xlH', cal.read(14))
        segments = list(unpack('<16H', cal.read(32))[:numsegments])
        locations = [unpack('<3f', cal.read(12)) for x in range(16)][:numsegments]
        lengths = list(unpack('<16f', cal.read(64))[:numsegments])
        if joint not in joints:
            joints[joint] = {'OFFSET':(0.0,0.0,0.0), 'JOINTS':[]}
        for j,loc, len in zip(segments, locations, lengths):
            joints[joint].setdefault('JOINTS',[]).append(j)
            if j not in joints:
                joints[j] = {}
            joints[j]['OFFSET'] = scale_v(loc, len)
            joints[j]['PARENT'] = joint
            joint = j

    numtorsos,numlimbs = unpack('<4x2l', cal.read(12))
    for n in range(numtorsos):
        read_torso()
    for n in range(numlimbs):
        read_limb()
    calibrate = unpack('<f', cal.read(4))[0]
    return torsos, joints, calibrate


def read_mi(mi):
    """
    Load a MI motion info header.
    """
    cret,numframes,fps = unpack('<4xlfl4x', mi.read(20))
    numframes = int(numframes)
    # Trim null and trailing garbage (if any)
    raw_name = mi.read(12)
    if 0 in raw_name:
      raw_name = raw_name[:raw_name.index(0)]
    motname = raw_name.decode('ascii')
    if motname.find('\0') != -1:
        motname = motname[:motname.find('\0')]
    mi.seek(64, 1)
    numjoints,numflags = unpack('<l4xl4x', mi.read(16))
    joints = [None for x in range(numjoints)]
    for j in range(numjoints):
        trans_or_rot,jnum,jindex = unpack('<3l', mi.read(12))
        istrans = trans_or_rot == 1
        joints[jindex] = (istrans,jnum)
    flags = {}
    for f in range(numflags):
        frame,flag = unpack('<lL', mi.read(8))
        flags[frame] = flags.get(frame, 0) | flag
    return {'FRAMES':numframes,
            'FPS':fps,
            'CRET':cret,
            'NAME':motname,
            'JOINTS':joints,
            'FLAGS':flags}


def read_mc(mc, minfo):
    """
    Load the frames from a MC file.
    """
    numjoints = unpack('<L', mc.read(4))[0]
    if numjoints != len(minfo['JOINTS']):
        raise RuntimeError("MC/MI joints mismatch")
    offsets = unpack('<'+str(numjoints)+'L', mc.read(4*numjoints))
    frames = [{} for f in range(minfo['FRAMES'])]
    for ji,pos in zip(minfo['JOINTS'],offsets):
        mc.seek(pos, 0)
        form, size = ('<3f',12) if ji[0] else ('<4f',16)
        for fr in frames:
            fr[ji] = unpack(form, mc.read(size))
    return frames


def write_bvh(bvh, torsos, joints, jointmap):
    """
    Write the BVH bone info for a set of torsos and joints.

    The order of components and fixed positions of the bones are returned.
    The component list gives a number of components and which joint they
    belong to. A 6-component element refers to translation and rotation. A
    3-component element is just rotation. Components are given in XYZ order
    for both translation and rotation.

    When writing a list of components, the translation vector for everything
    other than the root should be the associated offset returned by this
    function.

    :arg bvh: The output file object.
    :type bvh: IOBase
    :arg torsos: List of the torso bones from read_cal.
    :type torsos: list of ints
    :arg joints: A collection of joint bones from read_cal.
    :type joints: dict
    :arg jointmap: Dictionary of joint names.
    :type jointmap: dict
    :return: (components, offsets)
    :rtype: list of tuples, and list of triples
    """

    components = []
    offsets = []

    def bvh_offset(joint, tab, co=True):
        origin = joint['OFFSET']
        if co:
            offsets.append(origin)
        bvh.write(tab+"OFFSET {}\n".format(write_vector(origin)))

    def bvh_segment(joint, tab, haschild=True):
        bvh_offset(joint, tab, haschild)
        if haschild:
            bvh.write(tab+"CHANNELS 3 Xrotation Yrotation Zrotation\n")
            for j in joint['JOINTS']:
                bvh_joint(j, tab)


    def bvh_joint(jnum, tab):
        joint = joints[jnum]
        if 'JOINTS' in joint:
            components.append((3, jnum))
            bvh.write(tab+"JOINT "+jointmap[jnum]+"\n")
            bvh.write(tab+"{\n")
            bvh_segment(joint, tab+"\t")
        else:
            bvh.write(tab+"End Site\n")
            bvh.write(tab+"{\n")
            bvh_segment(joint, tab+"\t", False)
        bvh.write(tab+"}\n")

    def bvh_fixed(jnum, root, tab):
        joint = joints[jnum]
        numfixed = len(joint['FIXED']) if 'FIXED' in joint else 0
        numjoints = len(joint['JOINTS']) if 'JOINTS' in joint else 0
        if numfixed + numjoints != 0:
            bvh.write(tab+root+" "+jointmap[jnum]+"\n")
            bvh.write(tab+"{\n")
            itab = tab+"\t"
            bvh_offset(joint, itab)
            if numfixed != 0:
                components.append((6, jnum))
                bvh.write(itab+"CHANNELS 6 Xposition Yposition Zposition Xrotation Yrotation Zrotation\n")
                for j in joint['FIXED']:
                    bvh_fixed(j, "JOINT", itab)
            else:
                components.append((3, jnum))
                bvh.write(itab+"CHANNELS 3 Xrotation Yrotation Zrotation\n")
            if numjoints != 0:
                for j in joint['JOINTS']:
                    bvh_joint(j, itab)
            bvh.write(tab+"}\n")

    bvh.write("HIERARCHY\n")
    seen = set()
    for torso in torsos:
        if torso not in seen:
            seen.add(torso)
            joint = joints[torso]
            if joint['PARENT'] == -1:
                bvh_fixed(torso, "ROOT", "")
    return components, offsets


def cal2bvh(calname, jointmap, bvh):
    """
    Read a calibration file and write the bone structure in BVH format.

    :arg calname: The input file name.
    :type calname: string
    :arg jointmap: Dictionary of joint names.
    :type jointmap: dict
    :arg bvh: The output file name or object.
    :type bvh: string or IOBase
    """
    with open(calname, 'rb') as cal:
        torsos, joints, calibrate = read_cal(cal)
    if isinstance(bvh, str):
        bvh = open(bvh, 'w', encoding='ascii', buffering=1)
    write_bvh(bvh, torsos, joints, jointmap)
    bvh.write("MOTION\nFrames: 0\nFrame Time: 0.033333\n")


def mi2bvh(miname, calname, jointmap, bvh):
    """
    Read MI/MC mocap data and convert it to BVH format.

    :arg miname: The name of the MI file, including the ".mi" extension.
    :type minime: string
    :arg calname: The calibration file that defines the skeleton.
    :type calname: string
    :arg jointmap: Dictionary of joint names.
    :type jointmap: dict
    :arg bvh: The output file name or object.
    :type bvh: string or IOBase
    """
    from os.path import splitext
    mcname = splitext(miname)[0] + "_.mc"
    with open(miname, 'rb') as mi:
        info = read_mi(mi)
    with open(mcname, 'rb') as mc:
        frames = read_mc(mc, info)
    with open(calname, 'rb') as cal:
        torsos, joints, calibrate = read_cal(cal)
    if jointmap is None:
        jointmap = builtin_map(info['CRET'])
    if isinstance(bvh, str):
        bvh = open(bvh, 'w', encoding='ascii', buffering=1)
    components, offsets = write_bvh(bvh, torsos, joints, jointmap)
    bvh.write("MOTION\nFrames: {}\nFrame Time: {:.6f}\n".format(info['FRAMES'], 1/info['FPS']))
    for fr in frames:
        for co, off in zip(components, offsets):
            if co[0] == 6:
                ji = (True, co[1])
                if ji in fr:
                    bvh.write(write_vector(fr[ji]) + " ")
                else:
                    bvh.write(write_vector(off) + " ")
            ji = (False, co[1])
            if ji in fr:
                quat = fr[(False, co[1])]
                bvh.write(write_quaternion(quat) + " ")
            else:
                bvh.write(write_vector(None) + " ")
        bvh.write("\n")


if __name__ == '__main__':
    import sys
    import os

    def usage():
        sys.stdout.write("""
usage: {0} model.CAL model.MAP [output.BVH]
       {0} motion.MI model.CAL [model.MAP] [output.BVH]
Reads the MI/MC with CAL and MAP, or a CAL with MAP and write to the BVH file.
Writes to standard output if no BVH file is specified. If the motion file is
omitted, a model hierarchy alone is written.

Motion data is stored in two files. The name of the MC file is inferred from
the MI file name. A motion name of FOO.MI will be associated with FOO_.MC.
The .MI extension may also be omitted and it will be added automatically.

The MAP file is (sometimes) optional when a motion file is being read.
Mappings for standard creature types are built-in. Unusual or custom joint
names will need a MAP file. A MAP file is always needed when reading a
CAL file alone.
""".format(os.path.basename(sys.argv[0])))
        sys.exit()

    if len(sys.argv) < 1:
        usage()
    mifile = sys.argv[1]
    argtype = os.path.splitext(mifile)[1].lower()
    if argtype == '':
        argtype = '.mi'
        mifile = mifile + '.mi'
    if argtype == '.cal':
        calfile = mifile
        mapfile = None
        jointmap = None
        if len(sys.argv) > 3:
            mapfile,bvhfile = sys.argv[2:4]
        elif len(sys.argv) == 3:
            bvhfile = sys.argv[2]
            if os.path.splitext(bvhfile)[1].lower() == '.map':
                mapfile,bvhfile = bvhfile,sys.stdout
        else:
            bvhfile = sys.stdout
        if mapfile is not None:
            jointmap = read_map(open(mapfile, 'r', encoding='ascii'))
        else:
            jointmap = builtin_map(None)
        cal2bvh(calfile, jointmap, bvhfile)
    elif argtype == '.mi':
        if len(sys.argv) < 2:
            usage()
        calfile = sys.argv[2]
        mapfile = None
        jointmap = None
        if len(sys.argv) > 4:
            mapfile,bvhfile = sys.argv[3:5]
        elif len(sys.argv) == 4:
            bvhfile = sys.argv[3]
            if os.path.splitext(bvhfile)[1].lower() == '.map':
                mapfile,bvhfile = bvhfile,sys.stdout
        else:
            bvhfile = sys.stdout
        if mapfile is not None:
            jointmap = read_map(open(mapfile, 'r', encoding='ascii'))
        mi2bvh(mifile, calfile, jointmap, bvhfile)
    else:
        usage()

