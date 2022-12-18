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

"""bvh2mi.py bvhfile mapfile crettype mifile
   Convert a BVH to MI/MC motion.

"""

__all__ = (
    "read_map",
    "read_bvh",
    "write_mi",
    "write_mc",
    "bvh2mi"
)

from struct import pack
from math import sin,cos,pi

degrees = pi / 180


def d_to_r(r):
    i,j,k = r
    return (i*degrees, j*degrees, k*degrees)


def v_to_q(v):
    si,sj,sk = [sin(0.5*c) for c in v]
    ci,cj,ck = [cos(0.5*c) for c in v]
    ss,sc = si*sk, si*ck
    cc,cs = ci*ck, ci*sk
    return (cj*cc + sj*ss,
            cj*sc - sj*cs,
            cj*ss + sj*cc,
            cj*cs - sj*sc)


def read_quaternion(v):
    x,y,z = d_to_r(v)
    return v_to_q([-x,-y,-z])


creature_types = {
                 "human" : 0x7FFFF,
                 "humanwithsword" : 0xFFFFF,
                 "droid" : 0x3FFFF,
                 "spidbot" : 0xFF,
                 "arachnid" : 0x1FFFFFFF,
                 "plyrarm" : 0xE,
                 "bugbeast" : 0x3FFFFF,
                 "crayman" : 0x1FFFFF,
                 "sweel" : 0x7F,
                 "overlord" : 0x7,
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
            return dict.__getitem__(self, str(key).lower())
        except KeyError:
            val = max(list(dict.values(self)) + [0])
            dict.__setitem__(self, str(key).lower(), val)
            return val


def builtin_map(cretname):
    try:
        cret = creature_types[cretname.lower()]
    except KeyError:
        return JointDict(), 0
    try:
        return creature_maps[cret], cret
    except KeyError:
        pass
    try:
        joints = creature_joints[cret]
        map = JointDict([(name.lower(),joint) for joint,name in enumerate(joints)])
        creature_maps[cret] = map
        return map, cret
    except KeyError:
        return JointDict(), cret


def read_map(file):
    """
    Load a joint mapping file.
    """
    map = JointDict([(name.lower(),int(joint)) for name,joint in
                                               (line.split() for line in file)])
    return map


import re

HIERARCHY = 'HIERARCHY'
ROOT = re.compile(r'^(ROOT) (.+)$', re.I)
JOINT = re.compile(r'^(JOINT) (.+)$', re.I)
ENDSITE = 'END SITE'
OFFSET = re.compile(r'^(OFFSET) ([0-9. -]+)$', re.I)
CHANNELS = re.compile(r'^(CHANNELS) (\d+ [A-Za-z ]+)$', re.I)
MOTION = 'MOTION'
FRAMES = re.compile(r'^(FRAMES): (\d+)$', re.I)
FRAMETIME = re.compile(r'^(FRAME TIME): ([0-9.]+)$', re.I)


class ParseError(Exception):

    __slots__ = ("args","str","line","column")

    def __init__(self, str, line = 0, column = 0):
        self.str = str
        self.line = line
        self.column = column
        self.args = (str,line,column)

    def __str__(self):
        if self.line and self.column:
            return "{0.line}:{0.column}: {0.str}".format(self)
        elif self.line:
            return "{0.line}: {0.str}".format(self)
        else:
            return "{0.str}".format(self)

    def __repr__(self):
        return "ParseError"+repr(self.args)


def read_bvh(bvh):

    hier = {}
    channels = []
    joint = None
    level = 1
    curline = 0
    lines = (l.strip() for l in bvh)

    def clean(str):
        return re.sub(r'\s+', '_', str.strip())

    def expect(token):
        nonlocal curline, lines
        tok = next(lines)
        while tok == "":
            tok = next(lines)
        curline += 1
        if isinstance(token, (set,tuple,list)):
            for t in token:
                if isinstance(t, str):
                    if tok.upper() == t:
                        return (tok,None)
                else:
                    found = t.match(tok)
                    if found:
                        return found.groups()
            raise ParseError("syntax error", curline)
        if isinstance(token, str):
            if tok.upper() != token:
                raise ParseError("syntax error", curline)
            return (tok,None)
        else:
            found = token.match(tok)
            if not found:
                raise ParseError("syntax error", curline)
            return found.groups()


    def do_push(name, *args):
        nonlocal hier, joint, level
        expect('{')
        name = clean(name)
        joint['JOINTS'].append(name)
        joint = {'PARENT':joint['NAME'], 'NAME':name, 'JOINTS':[]}
        hier[name] = joint
        level += 1

    def do_pop(*args):
        nonlocal joint, level
        joint = hier[joint['PARENT']] if joint['PARENT'] else None
        level -= 1

    def do_offset(*args):
        nonlocal joint
        try:
            offset = tuple((float(c) for c in args[0:3]))
        except ValueError:
            raise ParseError("syntax error", curline)
        joint['OFFSET'] = offset

    def do_channels(*args):
        nonlocal joint, channels
        try:
            numchannels = int(args[0])
        except ValueError:
            raise ParseError("syntax error", curline)
        for i in range(1, numchannels+1, 3):
            channeltype = args[i][1:]
            if args[i+1][1:] != channeltype or args[i+2][1:] != channeltype:
                raise ParseError("syntax error", curline)
            order = args[i][0] + args[i+1][0] + args[i+2][0]
            if 'X' not in order or 'Y' not in order or 'Z' not in order:
                raise ParseError("syntax error", curline)
            if channeltype == 'rotation':
                joint['ROTATION'] = order
                channels.append((False, joint['NAME'], order))
            elif channeltype == 'position':
                joint['LOCATION'] = order
                channels.append((True, joint['NAME'], order))
            else:
                channels.append((None, None, None))

    def do_leaf(*args):
        # BVH doesn't save the identity of leaves
        # Just ignore it
        expect('{')
        expect(OFFSET)
        expect('}')


    State = {
            'OFFSET':do_offset,
            'CHANNELS':do_channels,
            'JOINT':do_push,
            'End Site':do_leaf,
            '}':do_pop
            }
    expect(HIERARCHY)
    name = expect((ROOT,JOINT))[1]
    expect('{')
    name = clean(name)
    joint = {'PARENT':None, 'NAME':name, 'JOINTS':[]}
    hier[name] = joint
    while level > 0:
        token,args = expect((OFFSET, CHANNELS, JOINT, ENDSITE, '}'))
        if args is not None:
            args = args.split()
        else:
            args = []
        try:
            State[token](*args)
        except TypeError:
            raise ParseError("syntax error", curline)

    expect(MOTION)
    numframes = int(expect(FRAMES)[1])
    fps = int(round(1.0 / float(expect(FRAMETIME)[1]), 3))

    return {'JOINTS':hier, 'FRAMES':numframes, 'FPS':fps}, channels


def write_mi(mi, info, joints):
    map = list(set([c[1] for c in joints if c]))
    map.sort()
    mi.write(pack('<4xlfl4x12s64x', info['CRET'], info['FRAMES'], info['FPS'], info['NAME'].encode('ascii')))
    mi.write(pack('<l12x', len(map)+1))
    pad = mi.write(pack('<3l', 1, joints[0][1], 0))
    for ix,co in enumerate(map, 1):
        pad += mi.write(pack('<3l', 0, co, ix))
        ix += 1
    mi.write(b'\0' * (16 - pad%16))


def write_mc(mc, location, joints):
    numjoints = len(joints)+1
    numframes = len(location) // 3
    start = (numjoints + 1) * 4
    start += 16 - start%16
    offsets = [start, start + numframes*12]
    for i in range(1, numjoints-1):
        offsets.append(offsets[i] + numframes*16)
    mc.write(pack('<L', numjoints))
    for pos in offsets:
        mc.write(pack('<L', pos))
    mc.seek(start, 0)
    for f in location:
        mc.write(pack('<f', f))
    for j in joints:
        for f in j:
            mc.write(pack('<f', f))


def reorder(co, order):
    return (co[order.index('X')], co[order.index('Y')], co[order.index('Z')])


def bvh2mi(bvhfile, jointmap, mifile, miname, crettype):
    bvh = open(bvhfile, 'r', encoding='ascii')
    info, channels = read_bvh(bvh)
    if not channels[0][0]:
        ParseError("incompatible components")
    translated = [(True, jointmap[channels[0][1]], channels[0][2])]
    translated.extend(((False,jointmap[c],o) if c and not t else None for t,c,o in channels[1:]))
    position = []
    joints = [None for x in range(max(jointmap.values())+1)]
    for c in translated:
        if c:
            joints[c[1]] = []
    frames = (l.split() for l in bvh)
    try:
        for x in range(info['FRAMES']):
            values = (float(v) for v in next(frames))
            components = zip(values,values,values)
            for map,co in zip(translated, components):
                if map:
                    if map[0]:
                        position.extend(reorder(co,map[2]))
                    else:
                        joints[map[1]].extend(read_quaternion(reorder(co,map[2])))
    except ValueError:
        raise ParseError("syntax error")
    except StopIteration:
        raise ParseError("unexpected end-of-file")
    info['NAME'] = miname
    info['CRET'] = crettype
    write_mi(open(mifile+'.mi', 'wb'), info, translated)
    write_mc(open(mifile+'_.mc', 'wb'), position, [f for f in joints if f])


if __name__=='__main__':
    import sys
    import os

    def usage():
        sys.stdout("usage: {} Input.BVH Input.MAP CreatureType Output".format(os.path.basename(sys.argv[0])))
        sys.exit()

    if len(sys.argv) < 4:
        usage()
    bvhfile, mapfile, mifile = sys.argv[1:4]
    if os.path.splitext(mapfile)[1].lower() == '.map':
        if len(sys.argv) < 5:
            usage()
        crettype,mifile = mifile,sys.argv[4]
        jointmap = read_map(open(mapfile, 'r', encoding='ascii'))
        crettype = int(crettype,16)
    else:
        jointmap,crettype = builtin_map(mapfile)
        if not jointmap:
            sys.stderr("unknown creature type: "+mapfile+"\n")
            sys.exit()
    mifile = os.path.splitext(mifile)[0]
    bvh2mi(bvhfile, jointmap, mifile, os.path.basename(mifile), crettype)

