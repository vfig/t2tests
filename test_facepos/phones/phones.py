import json, math

with open("sg11101a.json") as f:
    data = json.load(f)

def to_ticks(s):
    return int(round(s*16.0))

CUE_POSES = {
    'A': '0',
    'B': '2',
    'C': '4',
    'D': '5',
    'E': '3',
    'F': '1',
    'G': '2',
    'H': '5',
    'X': '0',
    }
def to_pose(cue):
    return CUE_POSES[cue]

length = to_ticks(math.ceil(data['metadata']['duration']))
poses = [(to_ticks(c['start']), to_pose(c['value']))
    for c in data['mouthCues']]
print(length)
print(poses[0])

pose_frames = []
null_pose = CUE_POSES['A']
last_pose = null_pose
tick = 0
for (pose_tick, pose) in poses:
    while tick<pose_tick:
        pose_frames.append(last_pose)
        tick += 1
    last_pose = pose
while tick<length:
    pose_frames.append(null_pose)
    tick += 1
pose_str = "".join(pose_frames)
print(pose_str)
