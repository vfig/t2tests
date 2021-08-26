#include <stdbool.h>
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>

typedef int8_t i8;
typedef uint8_t u8;
typedef int16_t i16;
typedef uint16_t u16;
typedef int32_t i32;
typedef uint32_t u32;
typedef int64_t i64;
typedef uint64_t u64;

typedef struct float3 {
    float x,y,z;
} float3;
#define float3(x,y,z) ((struct float3){x,y,z})

typedef struct float3x3 {
    float m00,m01,m02;
    float m10,m11,m12;
    float m20,m21,m22;
} float3x3;
#define float3x3(m00,m01,m02,m10,m11,m12,m20,m21,m22) \
    ((struct float3x3){m00,m01,m02,m10,m11,m12,m20,m21,m22})

void die(const char *message) {
    fprintf(stderr, "%s", message);
    exit(99);
}

struct EUV {
    float u, v;
};

struct EPoint {
    float x, y, z;
};

struct EPart {
    u32 flags;
    char visibility;
    u32 id;
    u32 mat_id;
    struct EPoint vertex;
};

struct EPartMapping {
    u32 id;
    struct EUV uv[3];
};

struct EMaterial {
    u32 id;
    char *name;
    char *shading;
    char *texture;
    u32 unk1;
    char *unk2;
    u32 unk3;
};

struct EModel {
    const char *name;
    u32 materials_count;
    struct EMaterial materials[2];
    u32 points_count;
    struct EPoint points[85];
    u32 parts_count;
    struct EPart parts[139];
    u32 part_mappings_count;
    struct EPartMapping part_mappings[139];
};

struct EFile {
    u32 models_count;
    struct EModel models[1];
};

static struct EFile E_DATA={
    .models_count=1,
    .models={{
        .name="Combine",
        .materials_count=2,
        .materials={
            { .id=1,.name="Material1",.shading="PHONG",.texture="cstar2.gif",.unk1=0,.unk2="TRANSP",.unk3=0 },
            { .id=2,.name="Material2",.shading="PHONG",.texture="cstar1.gif",.unk1=0,.unk2="TRANSP",.unk3=0 },
        },
        .points_count=85,
        .points={
            { -0.014887,0.180975,0.063819 },
            { 0.181086,0.014777,0.063530 },
            { 0.290177,0.342054,0.064102 },
            { -0.342164,0.290066,0.064008 },
            { -0.181085,-0.014999,0.063478 },
            { -0.290177,-0.342275,0.062905 },
            { 0.014888,-0.181196,0.063188 },
            { 0.342165,-0.290287,0.062999 },
            { 0.290177,0.342264,-0.056405 },
            { -0.014887,0.181185,-0.056688 },
            { 0.181086,0.014988,-0.056977 },
            { -0.181085,-0.014788,-0.057030 },
            { -0.342164,0.290276,-0.056497 },
            { 0.014888,-0.180986,-0.057319 },
            { -0.290177,-0.342065,-0.057602 },
            { 0.342165,-0.290077,-0.057508 },
            { -0.142936,0.143281,0.088983 },
            { 0.143437,0.142782,0.088983 },
            { 0.000873,0.499844,0.089606 },
            { -0.499999,0.000718,0.088734 },
            { -0.143437,-0.143091,0.088483 },
            { -0.000873,-0.500153,0.087861 },
            { 0.142936,-0.143591,0.088483 },
            { 0.499999,-0.001027,0.088734 },
            { 0.000874,0.500153,-0.087861 },
            { 0.143437,0.143091,-0.088483 },
            { -0.142935,0.143591,-0.088483 },
            { -0.143435,-0.142781,-0.088983 },
            { -0.499999,0.001028,-0.088734 },
            { 0.142937,-0.143281,-0.088983 },
            { -0.000873,-0.499843,-0.089606 },
            { 0.499999,-0.000718,-0.088734 },
            { -0.032010,0.418313,0.089463 },
            { -0.032010,0.418622,-0.088003 },
            { 0.243486,-0.103445,0.088554 },
            { 0.243487,-0.103135,-0.088913 },
            { 0.069738,0.225658,0.063898 },
            { 0.069738,0.225869,-0.056609 },
            { 0.225770,-0.069848,0.063383 },
            { 0.225770,-0.069637,-0.057124 },
            { -0.103290,-0.243640,0.088308 },
            { -0.103289,-0.243330,-0.089159 },
            { -0.243485,0.103135,0.088912 },
            { -0.243486,0.103445,-0.088554 },
            { -0.069737,-0.225670,-0.057398 },
            { -0.069737,-0.225880,0.063109 },
            { -0.195660,0.012603,0.063526 },
            { -0.114376,0.214138,0.063877 },
            { -0.114376,0.214347,-0.056630 },
            { -0.195659,0.012812,-0.056981 },
            { -0.142936,0.143325,0.063753 },
            { -0.243485,0.103179,0.063683 },
            { -0.243485,0.103390,-0.056823 },
            { -0.142936,0.143536,-0.056753 },
            { -0.214248,-0.114531,0.088533 },
            { -0.214248,-0.114221,-0.088934 },
            { -0.143436,-0.143047,0.063254 },
            { -0.214248,-0.114487,0.063304 },
            { -0.103290,-0.243596,0.063078 },
            { -0.214248,-0.114276,-0.057203 },
            { -0.105367,-0.158190,-0.057280 },
            { -0.103290,-0.243386,-0.057429 },
            { -0.143436,-0.142836,-0.057253 },
            { 0.114377,-0.214402,0.088360 },
            { 0.114377,-0.214093,-0.089107 },
            { 0.243486,-0.103401,0.063324 },
            { 0.033284,-0.187328,0.063177 },
            { 0.033284,-0.187118,-0.057330 },
            { 0.243487,-0.103190,-0.057183 },
            { 0.142937,-0.143547,0.063254 },
            { 0.114377,-0.214358,0.063130 },
            { 0.114377,-0.214148,-0.057377 },
            { 0.142937,-0.143336,-0.057253 },
            { 0.214249,0.114222,0.088933 },
            { 0.214249,0.114531,-0.088533 },
            { 0.103290,0.243331,0.089158 },
            { 0.103291,0.243640,-0.088308 },
            { 0.103290,0.243375,0.063929 },
            { 0.187218,0.033172,0.063563 },
            { 0.187218,0.033382,-0.056944 },
            { 0.103291,0.243585,-0.056578 },
            { 0.143437,0.142826,0.063754 },
            { 0.214249,0.114266,0.063704 },
            { 0.214249,0.114476,-0.056803 },
            { 0.143437,0.143036,-0.056753 },
        },
        .parts_count=139,
        .parts={
            { .flags=4,.visibility='N',.id=0,.mat_id=1,.vertex={32,17,18} },
            { .flags=4,.visibility='N',.id=1,.mat_id=1,.vertex={16,17,32} },
            { .flags=4,.visibility='N',.id=2,.mat_id=1,.vertex={54,16,19} },
            { .flags=4,.visibility='N',.id=3,.mat_id=1,.vertex={20,16,54} },
            { .flags=4,.visibility='N',.id=4,.mat_id=1,.vertex={63,20,21} },
            { .flags=4,.visibility='N',.id=5,.mat_id=1,.vertex={22,20,63} },
            { .flags=4,.visibility='N',.id=6,.mat_id=1,.vertex={34,17,22} },
            { .flags=4,.visibility='N',.id=7,.mat_id=1,.vertex={23,17,34} },
            { .flags=4,.visibility='N',.id=8,.mat_id=1,.vertex={22,16,20} },
            { .flags=4,.visibility='N',.id=9,.mat_id=1,.vertex={16,22,17} },
            { .flags=4,.visibility='N',.id=10,.mat_id=1,.vertex={33,25,26} },
            { .flags=4,.visibility='N',.id=11,.mat_id=1,.vertex={24,25,33} },
            { .flags=4,.visibility='N',.id=12,.mat_id=1,.vertex={55,26,27} },
            { .flags=4,.visibility='N',.id=13,.mat_id=1,.vertex={28,26,55} },
            { .flags=4,.visibility='N',.id=14,.mat_id=1,.vertex={64,27,29} },
            { .flags=4,.visibility='N',.id=15,.mat_id=1,.vertex={30,27,64} },
            { .flags=4,.visibility='N',.id=16,.mat_id=1,.vertex={35,25,31} },
            { .flags=4,.visibility='N',.id=17,.mat_id=1,.vertex={29,25,35} },
            { .flags=4,.visibility='N',.id=18,.mat_id=1,.vertex={26,29,27} },
            { .flags=4,.visibility='N',.id=19,.mat_id=1,.vertex={29,26,25} },
            { .flags=4,.visibility='N',.id=20,.mat_id=0,.vertex={36,9,0} },
            { .flags=4,.visibility='N',.id=21,.mat_id=0,.vertex={37,9,36} },
            { .flags=4,.visibility='N',.id=22,.mat_id=0,.vertex={15,1,7} },
            { .flags=4,.visibility='N',.id=23,.mat_id=0,.vertex={10,1,15} },
            { .flags=4,.visibility='N',.id=24,.mat_id=0,.vertex={39,13,10} },
            { .flags=4,.visibility='N',.id=25,.mat_id=0,.vertex={6,38,1} },
            { .flags=4,.visibility='N',.id=26,.mat_id=0,.vertex={45,13,6} },
            { .flags=4,.visibility='N',.id=27,.mat_id=0,.vertex={13,14,44} },
            { .flags=4,.visibility='N',.id=28,.mat_id=0,.vertex={14,45,5} },
            { .flags=4,.visibility='N',.id=29,.mat_id=0,.vertex={13,45,14} },
            { .flags=4,.visibility='N',.id=30,.mat_id=0,.vertex={4,45,6} },
            { .flags=4,.visibility='N',.id=31,.mat_id=0,.vertex={60,13,44} },
            { .flags=4,.visibility='N',.id=32,.mat_id=0,.vertex={11,13,60} },
            { .flags=4,.visibility='N',.id=33,.mat_id=0,.vertex={12,11,4} },
            { .flags=4,.visibility='N',.id=34,.mat_id=0,.vertex={12,4,3} },
            { .flags=4,.visibility='N',.id=35,.mat_id=0,.vertex={48,0,9} },
            { .flags=4,.visibility='N',.id=36,.mat_id=0,.vertex={47,0,48} },
            { .flags=4,.visibility='N',.id=37,.mat_id=0,.vertex={1,36,0} },
            { .flags=4,.visibility='N',.id=38,.mat_id=0,.vertex={47,4,0} },
            { .flags=4,.visibility='N',.id=39,.mat_id=0,.vertex={46,4,47} },
            { .flags=4,.visibility='N',.id=40,.mat_id=0,.vertex={37,10,9} },
            { .flags=4,.visibility='N',.id=41,.mat_id=0,.vertex={53,11,49} },
            { .flags=4,.visibility='N',.id=42,.mat_id=0,.vertex={11,48,9} },
            { .flags=4,.visibility='N',.id=43,.mat_id=0,.vertex={53,48,11} },
            { .flags=4,.visibility='N',.id=44,.mat_id=1,.vertex={50,33,26} },
            { .flags=4,.visibility='N',.id=45,.mat_id=1,.vertex={33,16,32} },
            { .flags=4,.visibility='N',.id=46,.mat_id=1,.vertex={50,16,33} },
            { .flags=4,.visibility='N',.id=47,.mat_id=0,.vertex={47,12,3} },
            { .flags=4,.visibility='N',.id=48,.mat_id=0,.vertex={48,12,47} },
            { .flags=4,.visibility='N',.id=49,.mat_id=0,.vertex={46,47,3} },
            { .flags=4,.visibility='N',.id=50,.mat_id=0,.vertex={52,53,49} },
            { .flags=4,.visibility='N',.id=51,.mat_id=1,.vertex={51,26,43} },
            { .flags=4,.visibility='N',.id=52,.mat_id=1,.vertex={50,26,51} },
            { .flags=4,.visibility='N',.id=53,.mat_id=0,.vertex={53,12,48} },
            { .flags=4,.visibility='N',.id=54,.mat_id=0,.vertex={52,12,53} },
            { .flags=4,.visibility='N',.id=55,.mat_id=1,.vertex={50,42,16} },
            { .flags=4,.visibility='N',.id=56,.mat_id=1,.vertex={51,42,50} },
            { .flags=4,.visibility='N',.id=57,.mat_id=1,.vertex={51,19,42} },
            { .flags=4,.visibility='N',.id=58,.mat_id=1,.vertex={19,43,28} },
            { .flags=4,.visibility='N',.id=59,.mat_id=1,.vertex={51,43,19} },
            { .flags=4,.visibility='N',.id=60,.mat_id=0,.vertex={11,5,4} },
            { .flags=4,.visibility='N',.id=61,.mat_id=0,.vertex={14,5,11} },
            { .flags=4,.visibility='N',.id=62,.mat_id=0,.vertex={45,4,5} },
            { .flags=4,.visibility='N',.id=63,.mat_id=0,.vertex={60,59,11} },
            { .flags=4,.visibility='N',.id=64,.mat_id=1,.vertex={62,55,27} },
            { .flags=4,.visibility='N',.id=65,.mat_id=1,.vertex={55,56,57} },
            { .flags=4,.visibility='N',.id=66,.mat_id=1,.vertex={62,56,55} },
            { .flags=4,.visibility='N',.id=67,.mat_id=1,.vertex={62,58,56} },
            { .flags=4,.visibility='N',.id=68,.mat_id=1,.vertex={61,58,62} },
            { .flags=4,.visibility='N',.id=69,.mat_id=0,.vertex={59,44,14} },
            { .flags=4,.visibility='N',.id=70,.mat_id=0,.vertex={60,44,59} },
            { .flags=4,.visibility='N',.id=71,.mat_id=1,.vertex={61,27,41} },
            { .flags=4,.visibility='N',.id=72,.mat_id=1,.vertex={62,27,61} },
            { .flags=4,.visibility='N',.id=73,.mat_id=1,.vertex={57,20,54} },
            { .flags=4,.visibility='N',.id=74,.mat_id=1,.vertex={56,20,57} },
            { .flags=4,.visibility='N',.id=75,.mat_id=1,.vertex={56,40,20} },
            { .flags=4,.visibility='N',.id=76,.mat_id=1,.vertex={58,40,56} },
            { .flags=4,.visibility='N',.id=77,.mat_id=1,.vertex={57,28,55} },
            { .flags=4,.visibility='N',.id=78,.mat_id=1,.vertex={28,54,19} },
            { .flags=4,.visibility='N',.id=79,.mat_id=1,.vertex={57,54,28} },
            { .flags=4,.visibility='N',.id=80,.mat_id=1,.vertex={61,40,58} },
            { .flags=4,.visibility='N',.id=81,.mat_id=1,.vertex={40,30,21} },
            { .flags=4,.visibility='N',.id=82,.mat_id=1,.vertex={30,61,41} },
            { .flags=4,.visibility='N',.id=83,.mat_id=1,.vertex={40,61,30} },
            { .flags=4,.visibility='N',.id=84,.mat_id=0,.vertex={71,13,67} },
            { .flags=4,.visibility='N',.id=85,.mat_id=0,.vertex={6,13,71} },
            { .flags=4,.visibility='N',.id=86,.mat_id=0,.vertex={6,7,66} },
            { .flags=4,.visibility='N',.id=87,.mat_id=0,.vertex={7,71,15} },
            { .flags=4,.visibility='N',.id=88,.mat_id=0,.vertex={6,71,7} },
            { .flags=4,.visibility='N',.id=89,.mat_id=0,.vertex={66,38,6} },
            { .flags=4,.visibility='N',.id=90,.mat_id=0,.vertex={65,38,66} },
            { .flags=4,.visibility='N',.id=91,.mat_id=0,.vertex={72,39,68} },
            { .flags=4,.visibility='N',.id=92,.mat_id=0,.vertex={39,67,13} },
            { .flags=4,.visibility='N',.id=93,.mat_id=0,.vertex={72,67,39} },
            { .flags=4,.visibility='N',.id=94,.mat_id=1,.vertex={69,34,22} },
            { .flags=4,.visibility='N',.id=95,.mat_id=1,.vertex={34,29,35} },
            { .flags=4,.visibility='N',.id=96,.mat_id=1,.vertex={69,29,34} },
            { .flags=4,.visibility='N',.id=97,.mat_id=0,.vertex={65,66,7} },
            { .flags=4,.visibility='N',.id=98,.mat_id=0,.vertex={72,71,67} },
            { .flags=4,.visibility='N',.id=99,.mat_id=1,.vertex={69,64,29} },
            { .flags=4,.visibility='N',.id=100,.mat_id=1,.vertex={70,64,69} },
            { .flags=4,.visibility='N',.id=101,.mat_id=0,.vertex={71,68,15} },
            { .flags=4,.visibility='N',.id=102,.mat_id=0,.vertex={72,68,71} },
            { .flags=4,.visibility='N',.id=103,.mat_id=1,.vertex={70,22,63} },
            { .flags=4,.visibility='N',.id=104,.mat_id=1,.vertex={69,22,70} },
            { .flags=4,.visibility='N',.id=105,.mat_id=1,.vertex={70,30,64} },
            { .flags=4,.visibility='N',.id=106,.mat_id=1,.vertex={30,63,21} },
            { .flags=4,.visibility='N',.id=107,.mat_id=1,.vertex={70,63,30} },
            { .flags=4,.visibility='N',.id=108,.mat_id=1,.vertex={33,18,24} },
            { .flags=4,.visibility='N',.id=109,.mat_id=1,.vertex={32,18,33} },
            { .flags=4,.visibility='N',.id=110,.mat_id=1,.vertex={34,31,23} },
            { .flags=4,.visibility='N',.id=111,.mat_id=1,.vertex={35,31,34} },
            { .flags=4,.visibility='N',.id=112,.mat_id=0,.vertex={10,2,1} },
            { .flags=4,.visibility='N',.id=113,.mat_id=0,.vertex={8,2,10} },
            { .flags=4,.visibility='N',.id=114,.mat_id=0,.vertex={80,2,8} },
            { .flags=4,.visibility='N',.id=115,.mat_id=0,.vertex={2,36,77} },
            { .flags=4,.visibility='N',.id=116,.mat_id=0,.vertex={36,80,37} },
            { .flags=4,.visibility='N',.id=117,.mat_id=0,.vertex={2,80,36} },
            { .flags=4,.visibility='N',.id=118,.mat_id=0,.vertex={78,36,1} },
            { .flags=4,.visibility='N',.id=119,.mat_id=0,.vertex={77,36,78} },
            { .flags=4,.visibility='N',.id=120,.mat_id=0,.vertex={84,37,80} },
            { .flags=4,.visibility='N',.id=121,.mat_id=0,.vertex={37,79,10} },
            { .flags=4,.visibility='N',.id=122,.mat_id=0,.vertex={84,79,37} },
            { .flags=4,.visibility='N',.id=123,.mat_id=1,.vertex={81,75,17} },
            { .flags=4,.visibility='N',.id=124,.mat_id=1,.vertex={75,25,76} },
            { .flags=4,.visibility='N',.id=125,.mat_id=1,.vertex={81,25,75} },
            { .flags=4,.visibility='N',.id=126,.mat_id=0,.vertex={77,78,2} },
            { .flags=4,.visibility='N',.id=127,.mat_id=0,.vertex={84,83,79} },
            { .flags=4,.visibility='N',.id=128,.mat_id=1,.vertex={81,74,25} },
            { .flags=4,.visibility='N',.id=129,.mat_id=1,.vertex={82,74,81} },
            { .flags=4,.visibility='N',.id=130,.mat_id=0,.vertex={83,80,8} },
            { .flags=4,.visibility='N',.id=131,.mat_id=0,.vertex={84,80,83} },
            { .flags=4,.visibility='N',.id=132,.mat_id=1,.vertex={82,17,73} },
            { .flags=4,.visibility='N',.id=133,.mat_id=1,.vertex={81,17,82} },
            { .flags=4,.visibility='N',.id=134,.mat_id=1,.vertex={75,24,18} },
            { .flags=4,.visibility='N',.id=135,.mat_id=1,.vertex={76,24,75} },
            { .flags=4,.visibility='N',.id=136,.mat_id=1,.vertex={82,31,74} },
            { .flags=4,.visibility='N',.id=137,.mat_id=1,.vertex={31,73,23} },
            { .flags=4,.visibility='N',.id=138,.mat_id=1,.vertex={82,73,31} },
        },
        .part_mappings_count=139,
        .part_mappings={
            { .id=0,.uv={{0.533115f,-0.080801f},{0.342083f,-0.334835f},{0.500000f,-0.005495f}} },
            { .id=1,.uv={{0.644823f,-0.334835f},{0.342083f,-0.334835f},{0.533115f,-0.080801f}} },
            { .id=2,.uv={{0.712748f,-0.614751f},{0.644823f,-0.334835f},{0.993453f,-0.500000f}} },
            { .id=3,.uv={{0.643187f,-0.643187f},{0.644823f,-0.334835f},{0.712748f,-0.614751f}} },
            { .id=4,.uv={{0.385249f,-0.712957f},{0.643187f,-0.643187f},{0.500000f,-0.994506f}} },
            { .id=5,.uv={{0.356813f,-0.643187f},{0.643187f,-0.643187f},{0.385249f,-0.712957f}} },
            { .id=6,.uv={{0.258177f,-0.602865f},{0.342083f,-0.334835f},{0.356813f,-0.643187f}} },
            { .id=7,.uv={{0.006547f,-0.500000f},{0.342083f,-0.334835f},{0.258177f,-0.602865f}} },
            { .id=8,.uv={{0.356813f,-0.643187f},{0.644823f,-0.334835f},{0.643187f,-0.643187f}} },
            { .id=9,.uv={{0.644823f,-0.334835f},{0.356813f,-0.643187f},{0.342083f,-0.334835f}} },
            { .id=10,.uv={{0.533115f,-0.080383f},{0.356813f,-0.333004f},{0.644823f,-0.333004f}} },
            { .id=11,.uv={{0.500000f,-0.005495f},{0.356813f,-0.333004f},{0.533115f,-0.080383f}} },
            { .id=12,.uv={{0.712749f,-0.614751f},{0.644823f,-0.333004f},{0.643187f,-0.643187f}} },
            { .id=13,.uv={{0.993453f,-0.500000f},{0.644823f,-0.333004f},{0.712749f,-0.614751f}} },
            { .id=14,.uv={{0.385250f,-0.713322f},{0.643187f,-0.643187f},{0.356813f,-0.643187f}} },
            { .id=15,.uv={{0.500000f,-0.996337f},{0.643187f,-0.643187f},{0.385250f,-0.713322f}} },
            { .id=16,.uv={{0.258178f,-0.602865f},{0.356813f,-0.333004f},{0.006547f,-0.500000f}} },
            { .id=17,.uv={{0.356813f,-0.643187f},{0.356813f,-0.333004f},{0.258178f,-0.602865f}} },
            { .id=18,.uv={{0.644823f,-0.333004f},{0.356813f,-0.643187f},{0.643187f,-0.643187f}} },
            { .id=19,.uv={{0.356813f,-0.643187f},{0.644823f,-0.333004f},{0.356813f,-0.333004f}} },
            { .id=20,.uv={{0.468430f,-0.888040f},{0.566264f,-0.455714f},{0.566264f,-0.887949f}} },
            { .id=21,.uv={{0.468430f,-0.455297f},{0.566264f,-0.455714f},{0.468430f,-0.888040f}} },
            { .id=22,.uv={{0.225859f,-0.492674f},{0.538483f,-0.909927f},{0.216039f,-0.902930f}} },
            { .id=23,.uv={{0.545029f,-0.492344f},{0.538483f,-0.909927f},{0.225859f,-0.492674f}} },
            { .id=24,.uv={{0.259195f,-0.388593f},{0.356813f,-0.643187f},{0.356813f,-0.345824f}} },
            { .id=25,.uv={{0.356813f,-0.643187f},{0.259195f,-0.389916f},{0.356813f,-0.347656f}} },
            { .id=26,.uv={{0.624120f,-0.853411f},{0.522116f,-0.489340f},{0.517206f,-0.851978f}} },
            { .id=27,.uv={{0.522116f,-0.489340f},{0.907529f,-0.492674f},{0.629030f,-0.490265f}} },
            { .id=28,.uv={{0.907529f,-0.492674f},{0.624120f,-0.853411f},{0.902619f,-0.857143f}} },
            { .id=29,.uv={{0.522116f,-0.489340f},{0.624120f,-0.853411f},{0.907529f,-0.492674f}} },
            { .id=30,.uv={{0.643187f,-0.643187f},{0.396533f,-0.740644f},{0.356813f,-0.643187f}} },
            { .id=31,.uv={{0.475460f,-0.709113f},{0.356813f,-0.643187f},{0.396533f,-0.740136f}} },
            { .id=32,.uv={{0.643187f,-0.643187f},{0.356813f,-0.643187f},{0.475460f,-0.709113f}} },
            { .id=33,.uv={{0.911620f,-0.430403f},{0.530257f,-0.430732f},{0.525347f,-0.765897f}} },
            { .id=34,.uv={{0.911620f,-0.432234f},{0.525347f,-0.767729f},{0.913257f,-0.769231f}} },
            { .id=35,.uv={{0.682691f,-0.455257f},{0.566264f,-0.887949f},{0.566264f,-0.455714f}} },
            { .id=36,.uv={{0.681697f,-0.888049f},{0.566264f,-0.887949f},{0.682691f,-0.455257f}} },
            { .id=37,.uv={{0.356813f,-0.347656f},{0.603467f,-0.253248f},{0.643187f,-0.347656f}} },
            { .id=38,.uv={{0.748669f,-0.393410f},{0.643187f,-0.643187f},{0.643187f,-0.347656f}} },
            { .id=39,.uv={{0.674582f,-0.630066f},{0.643187f,-0.643187f},{0.748669f,-0.393410f}} },
            { .id=40,.uv={{0.603467f,-0.252940f},{0.356813f,-0.345824f},{0.643187f,-0.345824f}} },
            { .id=41,.uv={{0.722637f,-0.475735f},{0.643187f,-0.643187f},{0.674581f,-0.630067f}} },
            { .id=42,.uv={{0.643187f,-0.643187f},{0.748669f,-0.392135f},{0.643187f,-0.345824f}} },
            { .id=43,.uv={{0.722637f,-0.475735f},{0.748669f,-0.392135f},{0.643187f,-0.643187f}} },
            { .id=44,.uv={{0.711693f,-0.054401f},{0.376395f,-0.317193f},{0.710290f,-0.318352f}} },
            { .id=45,.uv={{0.376395f,-0.317193f},{0.711926f,-0.010659f},{0.376768f,-0.010914f}} },
            { .id=46,.uv={{0.711693f,-0.054401f},{0.711926f,-0.010659f},{0.376395f,-0.317193f}} },
            { .id=47,.uv={{0.681697f,-0.888049f},{0.949263f,-0.454212f},{0.945990f,-0.888278f}} },
            { .id=48,.uv={{0.682691f,-0.455257f},{0.949263f,-0.454212f},{0.681697f,-0.888049f}} },
            { .id=49,.uv={{0.674582f,-0.630066f},{0.748669f,-0.393410f},{0.990180f,-0.498168f}} },
            { .id=50,.uv={{0.777607f,-0.587009f},{0.722637f,-0.475735f},{0.674581f,-0.630067f}} },
            { .id=51,.uv={{0.657148f,-0.475858f},{0.540077f,-0.917253f},{0.657149f,-0.917346f}} },
            { .id=52,.uv={{0.540077f,-0.475765f},{0.540077f,-0.917253f},{0.657148f,-0.475858f}} },
            { .id=53,.uv={{0.722637f,-0.475735f},{0.990180f,-0.498168f},{0.748669f,-0.392135f}} },
            { .id=54,.uv={{0.777607f,-0.587009f},{0.990180f,-0.498168f},{0.722637f,-0.475735f}} },
            { .id=55,.uv={{0.540077f,-0.475765f},{0.657147f,-0.402694f},{0.540077f,-0.402601f}} },
            { .id=56,.uv={{0.657148f,-0.475858f},{0.657147f,-0.402694f},{0.540077f,-0.475765f}} },
            { .id=57,.uv={{0.657148f,-0.475858f},{0.955810f,-0.402930f},{0.657147f,-0.402694f}} },
            { .id=58,.uv={{0.955810f,-0.402930f},{0.657149f,-0.917346f},{0.955810f,-0.917582f}} },
            { .id=59,.uv={{0.657148f,-0.475858f},{0.657149f,-0.917346f},{0.955810f,-0.402930f}} },
            { .id=60,.uv={{0.530257f,-0.430732f},{0.123568f,-0.778388f},{0.525347f,-0.765897f}} },
            { .id=61,.uv={{0.128478f,-0.430403f},{0.123568f,-0.778388f},{0.530257f,-0.430732f}} },
            { .id=62,.uv={{0.396533f,-0.740644f},{0.643187f,-0.643187f},{0.500000f,-0.994506f}} },
            { .id=63,.uv={{0.475460f,-0.709113f},{0.599660f,-0.749427f},{0.643187f,-0.643187f}} },
            { .id=64,.uv={{0.494250f,-0.555827f},{0.565112f,-0.479754f},{0.494250f,-0.480183f}} },
            { .id=65,.uv={{0.565112f,-0.479754f},{0.494250f,-0.843113f},{0.565111f,-0.843308f}} },
            { .id=66,.uv={{0.494250f,-0.555827f},{0.494250f,-0.843113f},{0.565112f,-0.479754f}} },
            { .id=67,.uv={{0.494250f,-0.555827f},{0.393092f,-0.842946f},{0.494250f,-0.843113f}} },
            { .id=68,.uv={{0.393091f,-0.555310f},{0.393092f,-0.842946f},{0.494250f,-0.555827f}} },
            { .id=69,.uv={{0.599660f,-0.749427f},{0.396533f,-0.740136f},{0.500000f,-0.992674f}} },
            { .id=70,.uv={{0.475460f,-0.709113f},{0.396533f,-0.740136f},{0.599660f,-0.749427f}} },
            { .id=71,.uv={{0.393091f,-0.555310f},{0.494250f,-0.480183f},{0.393091f,-0.479574f}} },
            { .id=72,.uv={{0.494250f,-0.555827f},{0.494250f,-0.480183f},{0.393091f,-0.555310f}} },
            { .id=73,.uv={{0.565111f,-0.843308f},{0.494250f,-0.903260f},{0.565111f,-0.903558f}} },
            { .id=74,.uv={{0.494250f,-0.843113f},{0.494250f,-0.903260f},{0.565111f,-0.843308f}} },
            { .id=75,.uv={{0.494250f,-0.843113f},{0.393092f,-0.903167f},{0.494250f,-0.903260f}} },
            { .id=76,.uv={{0.393092f,-0.842946f},{0.393092f,-0.903167f},{0.494250f,-0.843113f}} },
            { .id=77,.uv={{0.565111f,-0.843308f},{0.851064f,-0.478022f},{0.565112f,-0.479754f}} },
            { .id=78,.uv={{0.851064f,-0.478022f},{0.565111f,-0.903558f},{0.851064f,-0.904762f}} },
            { .id=79,.uv={{0.565111f,-0.843308f},{0.565111f,-0.903558f},{0.851064f,-0.478022f}} },
            { .id=80,.uv={{0.393091f,-0.555310f},{0.393092f,-0.903167f},{0.393092f,-0.842946f}} },
            { .id=81,.uv={{0.393092f,-0.903167f},{0.135025f,-0.478022f},{0.135025f,-0.902930f}} },
            { .id=82,.uv={{0.135025f,-0.478022f},{0.393091f,-0.555310f},{0.393091f,-0.479574f}} },
            { .id=83,.uv={{0.393092f,-0.903167f},{0.393091f,-0.555310f},{0.135025f,-0.478022f}} },
            { .id=84,.uv={{0.400215f,-0.489797f},{0.522116f,-0.489340f},{0.499577f,-0.489424f}} },
            { .id=85,.uv={{0.517206f,-0.851978f},{0.522116f,-0.489340f},{0.400215f,-0.489797f}} },
            { .id=86,.uv={{0.517206f,-0.851978f},{0.121113f,-0.853480f},{0.494943f,-0.852062f}} },
            { .id=87,.uv={{0.121113f,-0.853480f},{0.400215f,-0.489797f},{0.121113f,-0.490842f}} },
            { .id=88,.uv={{0.517206f,-0.851978f},{0.400215f,-0.489797f},{0.121113f,-0.853480f}} },
            { .id=89,.uv={{0.337033f,-0.635139f},{0.259195f,-0.389916f},{0.356813f,-0.643187f}} },
            { .id=90,.uv={{0.220491f,-0.406672f},{0.259195f,-0.389916f},{0.337033f,-0.635139f}} },
            { .id=91,.uv={{0.276238f,-0.515372f},{0.259195f,-0.388593f},{0.220490f,-0.405550f}} },
            { .id=92,.uv={{0.259195f,-0.388593f},{0.337034f,-0.635139f},{0.356813f,-0.643187f}} },
            { .id=93,.uv={{0.276238f,-0.515372f},{0.337034f,-0.635139f},{0.259195f,-0.388593f}} },
            { .id=94,.uv={{0.535442f,-0.881826f},{0.416294f,-0.939797f},{0.535209f,-0.939890f}} },
            { .id=95,.uv={{0.416294f,-0.939797f},{0.536846f,-0.531465f},{0.417471f,-0.530856f}} },
            { .id=96,.uv={{0.535442f,-0.881826f},{0.536846f,-0.531465f},{0.416294f,-0.939797f}} },
            { .id=97,.uv={{0.220491f,-0.406672f},{0.337033f,-0.635139f},{0.004910f,-0.500000f}} },
            { .id=98,.uv={{0.276238f,-0.515372f},{0.249838f,-0.599660f},{0.337034f,-0.635139f}} },
            { .id=99,.uv={{0.535442f,-0.881826f},{0.613388f,-0.531763f},{0.536846f,-0.531465f}} },
            { .id=100,.uv={{0.612262f,-0.881812f},{0.613388f,-0.531763f},{0.535442f,-0.881826f}} },
            { .id=101,.uv={{0.249838f,-0.599660f},{0.220490f,-0.405550f},{0.004910f,-0.500000f}} },
            { .id=102,.uv={{0.276238f,-0.515372f},{0.220490f,-0.405550f},{0.249838f,-0.599660f}} },
            { .id=103,.uv={{0.612262f,-0.881812f},{0.535209f,-0.939890f},{0.612075f,-0.939824f}} },
            { .id=104,.uv={{0.535442f,-0.881826f},{0.535209f,-0.939890f},{0.612262f,-0.881812f}} },
            { .id=105,.uv={{0.612262f,-0.881812f},{0.922259f,-0.532967f},{0.613388f,-0.531763f}} },
            { .id=106,.uv={{0.922259f,-0.532967f},{0.612075f,-0.939824f},{0.922259f,-0.939560f}} },
            { .id=107,.uv={{0.612262f,-0.881812f},{0.612075f,-0.939824f},{0.922259f,-0.532967f}} },
            { .id=108,.uv={{0.376395f,-0.317193f},{0.277414f,-0.010989f},{0.277414f,-0.316850f}} },
            { .id=109,.uv={{0.376768f,-0.010914f},{0.277414f,-0.010989f},{0.376395f,-0.317193f}} },
            { .id=110,.uv={{0.416294f,-0.939797f},{0.112930f,-0.529304f},{0.112930f,-0.939560f}} },
            { .id=111,.uv={{0.417471f,-0.530856f},{0.112930f,-0.529304f},{0.416294f,-0.939797f}} },
            { .id=112,.uv={{0.545029f,-0.492344f},{0.855156f,-0.906593f},{0.538483f,-0.909927f}} },
            { .id=113,.uv={{0.853519f,-0.494506f},{0.855156f,-0.906593f},{0.545029f,-0.492344f}} },
            { .id=114,.uv={{0.429641f,-0.455132f},{0.213584f,-0.888278f},{0.213584f,-0.454212f}} },
            { .id=115,.uv={{0.213584f,-0.888278f},{0.468430f,-0.888040f},{0.429641f,-0.888076f}} },
            { .id=116,.uv={{0.468430f,-0.888040f},{0.429641f,-0.455132f},{0.468430f,-0.455297f}} },
            { .id=117,.uv={{0.213584f,-0.888278f},{0.429641f,-0.455132f},{0.468430f,-0.888040f}} },
            { .id=118,.uv={{0.364861f,-0.328528f},{0.603467f,-0.253248f},{0.356813f,-0.347656f}} },
            { .id=119,.uv={{0.587718f,-0.215817f},{0.603467f,-0.253248f},{0.364861f,-0.328528f}} },
            { .id=120,.uv={{0.481116f,-0.269158f},{0.603467f,-0.252940f},{0.587718f,-0.216114f}} },
            { .id=121,.uv={{0.603467f,-0.252940f},{0.364861f,-0.327005f},{0.356813f,-0.345824f}} },
            { .id=122,.uv={{0.481116f,-0.269158f},{0.364861f,-0.327005f},{0.603467f,-0.252940f}} },
            { .id=123,.uv={{0.327353f,-0.048647f},{0.438651f,-0.004742f},{0.327353f,-0.005165f}} },
            { .id=124,.uv={{0.438651f,-0.004742f},{0.327353f,-0.311026f},{0.438651f,-0.310603f}} },
            { .id=125,.uv={{0.327353f,-0.048647f},{0.327353f,-0.311026f},{0.438651f,-0.004742f}} },
            { .id=126,.uv={{0.587718f,-0.215817f},{0.364861f,-0.328528f},{0.500000f,-0.007326f}} },
            { .id=127,.uv={{0.481116f,-0.269158f},{0.400340f,-0.244038f},{0.364861f,-0.327005f}} },
            { .id=128,.uv={{0.479563f,-0.597999f},{0.406426f,-0.981057f},{0.479563f,-0.981355f}} },
            { .id=129,.uv={{0.406147f,-0.598013f},{0.406426f,-0.981057f},{0.479563f,-0.597999f}} },
            { .id=130,.uv={{0.400340f,-0.244038f},{0.587718f,-0.216114f},{0.500000f,-0.010989f}} },
            { .id=131,.uv={{0.481116f,-0.269158f},{0.587718f,-0.216114f},{0.400340f,-0.244038f}} },
            { .id=132,.uv={{0.406147f,-0.598013f},{0.479563f,-0.534469f},{0.406100f,-0.534535f}} },
            { .id=133,.uv={{0.479563f,-0.597999f},{0.479563f,-0.534469f},{0.406147f,-0.598013f}} },
            { .id=134,.uv={{0.438651f,-0.004742f},{0.722586f,-0.309524f},{0.722586f,-0.003663f}} },
            { .id=135,.uv={{0.438651f,-0.310603f},{0.722586f,-0.309524f},{0.438651f,-0.004742f}} },
            { .id=136,.uv={{0.406147f,-0.598013f},{0.111293f,-0.979853f},{0.406426f,-0.981057f}} },
            { .id=137,.uv={{0.111293f,-0.979853f},{0.406100f,-0.534535f},{0.109656f,-0.534799f}} },
            { .id=138,.uv={{0.406147f,-0.598013f},{0.406100f,-0.534535f},{0.111293f,-0.979853f}} },
        },
    }},
};

const u32 MD_MAGIC = *((u32*)"LGMD");

#pragma pack(push,1)
// FIXME: remove these member name comments
struct MDFile {
    u32 magic;  //id
    u32 version; //ver
    u8 name[8];   // not null-terminated! //name
    float bsphere_radius; //radius
    float max_poly_radius; //max_pgon_radius
    float3 bbox_max; //bmax
    float3 bbox_min; //bmin
    float3 origin;  //pcen
    u16 poly_count; //pgons
    u16 vert_count; //verts
    u16 param_count; //parms;
    u8 mat_count; //mats
    u8 vcall_count; //vcals
    u8 vhot_count; //vhots
    u8 model_count; //subobjs
    u32 model_offset;
    u32 mat_offset;
    u32 uv_offset;
    u32 vhot_offset;
    u32 point_offset;
    u32 light_offset;
    u32 normal_offset;
    u32 poly_offset;
    u32 node_offset;
    u32 model_size; // zero on disk, calculated during load.
};

enum MDJointType {
    MD_JOINT_FIXED=0,
    MD_JOINT_ROTATING=1,
    MD_JOINT_TRANSLATING=2,
};

struct MDTransform {
    float3x3 a; // 3D affine transformation
    float3 t; // translation
};

struct MDModel {
    u8 name[8]; // not null-terminated!
    u8 joint_type; // MDJointType.
    i32 param;
    float joint_value_min;
    float joint_value_max;
    struct MDTransform transform;
    i16 child_index; // -1 if no children.
    i16 next_index; // -1 if last sibling.
    u16 vhot_index;
    u16 vhot_count;
    u16 point_index;
    u16 point_count;
    u16 light_index;
    u16 light_count;
    u16 normal_index;
    u16 normal_count;
    u16 node_index;
    u16 node_count;
};

enum MDMaterialType {
    MD_MATERIAL_TEXTURE=0,
    MD_MATERIAL_COLOR=1,
};

struct MDMaterial {
    u8 name[16]; // not null-terminated!
    u8 mat_type;
    u8 slot;
    union {
        // mat_type=MD_MATERIAL_TEXTURE:
        u32 texture_handle;
        // mat_type=MD_MATERIAL_COLOR:
        u32 color; // 0xAARRGGBB
    };
    union {
        // mat_type=MD_MATERIAL_TEXTURE:
        float uv_scale;
        // mat_type=MD_MATERIAL_COLOR:
        u32 palette_index;
    };
};
#pragma pack(pop)

void dump_mdfile(struct MDFile *m) {
    printf("magic: %.*s\n", sizeof(m->magic), (char *)&m->magic);
    printf("version: %lu\n", m->version);
    printf("name: %.*s\n", sizeof(m->name), m->name);
    printf("bsphere_radius: %f\n", m->bsphere_radius);
    printf("max_poly_radius: %f\n", m->max_poly_radius);
    printf("bbox_max: %f,%f,%f\n", m->bbox_max.x, m->bbox_max.y, m->bbox_max.z);
    printf("bbox_min: %f,%f,%f\n", m->bbox_min.x, m->bbox_min.y, m->bbox_min.z);
    printf("origin: %f,%f,%f\n", m->origin.x, m->origin.y, m->origin.z);
    printf("poly_count: %u\n", m->poly_count);
    printf("vert_count: %u\n", m->vert_count);
    printf("param_count: %u\n", m->param_count);
    printf("mat_count: %u\n", m->mat_count);
    printf("vcall_count: %u\n", m->vcall_count);
    printf("vhot_count: %u\n", m->vhot_count);
    printf("model_count: %u\n", m->model_count);
    printf("model_offset: 0x%lx\n", m->model_offset);
    printf("mat_offset: 0x%lx\n", m->mat_offset);
    printf("uv_offset: 0x%lx\n", m->uv_offset);
    printf("vhot_offset: 0x%lx\n", m->vhot_offset);
    printf("point_offset: 0x%lx\n", m->point_offset);
    printf("light_offset: 0x%lx\n", m->light_offset);
    printf("normal_offset: 0x%lx\n", m->normal_offset);
    printf("poly_offset: 0x%lx\n", m->poly_offset);
    printf("node_offset: 0x%lx\n", m->node_offset);
    printf("model_size: %lu\n", m->model_size);
    printf("\n");
}

void dump_mdmodel(struct MDModel *m) {
    const char *joint_type_names[] = {
        "MD_JOINT_FIXED",
        "MD_JOINT_ROTATING",
        "MD_JOINT_TRANSLATING",
    };
    printf("name: %.*s\n", sizeof(m->name), m->name);
    printf("joint_type: %s\n", joint_type_names[m->joint_type]);
    printf("param: %ld\n", m->param);
    printf("joint_value_min: %f\n", m->joint_value_min);
    printf("joint_value_max: %f\n", m->joint_value_max);
    printf("transform: %f %f %f\n"
           "           %f %f %f\n"
           "           %f %f %f\n"
           "           %f,%f,%f\n",
           m->transform.a.m00, m->transform.a.m01, m->transform.a.m02,
           m->transform.a.m10, m->transform.a.m11, m->transform.a.m22,
           m->transform.a.m20, m->transform.a.m21, m->transform.a.m22,
           m->transform.t.x, m->transform.t.y, m->transform.t.z);
    printf("child_index: %d\n", m->child_index);
    printf("next_index: %d\n", m->next_index);
    printf("vhot_index: %u\n", m->vhot_index);
    printf("vhot_count: %u\n", m->vhot_count);
    printf("point_index: %u\n", m->point_index);
    printf("point_count: %u\n", m->point_count);
    printf("light_index: %u\n", m->light_index);
    printf("light_count: %u\n", m->light_count);
    printf("normal_index: %u\n", m->normal_index);
    printf("normal_count: %u\n", m->normal_count);
    printf("node_index: %u\n", m->node_index);
    printf("node_count: %u\n", m->node_count);
    printf("\n");
}

void dump_mdmaterial(struct MDMaterial *m) {
    const char *mat_type_names[] = {
        "MD_MATERIAL_TEXTURE",
        "MD_MATERIAL_COLOR",
    };
    printf("name: %.*s\n", sizeof(m->name), m->name);
    printf("mat_type: %s\n", mat_type_names[m->mat_type]);
    printf("slot: %u\n", m->slot);
    if (m->mat_type==MD_MATERIAL_TEXTURE) {
        printf("texture_handle: %lu\n", m->texture_handle);
        printf("uv_scale: %f\n", m->uv_scale);
    } else {
        printf("color: %u %u %u %u (rgba)\n",
            ((m->color>>16)&0xff), ((m->color>>8)&0xff),
            (m->color&0xff), ((m->color>>24)&0xff) );
        printf("palette_index: %lu\n", m->palette_index);
    }
    printf("\n");
}

void read_model(const char *filename) {
    struct MDFile mdfile = {0};
    struct MDModel mdmodel = {0};
    struct MDMaterial mdmat = {0};
    FILE *f = fopen(filename, "rb");
    if (!f) die("cannot open file!");
    // TODO: actually deal with file errors, lol
    fread(&mdfile, sizeof(mdfile), 1, f);
    dump_mdfile(&mdfile);
    fseek(f, mdfile.model_offset, SEEK_SET);
    for (int i=0; i<(int)mdfile.model_count; ++i) {
        fread(&mdmodel, sizeof(mdmodel), 1, f);
        printf("Model %d:\n", i);
        dump_mdmodel(&mdmodel);
    }
    fseek(f, mdfile.mat_offset, SEEK_SET);
    for (int i=0; i<(int)mdfile.mat_count; ++i) {
        fread(&mdmat, sizeof(mdmat), 1, f);
        printf("Material %d:\n", i);
        dump_mdmaterial(&mdmat);
    }
    fclose(f);


}

void convert_to_bin(struct EFile *efile) {
    printf("%04lx\n", MD_MAGIC);
    die("not implemented!\n");
}

int main(int arc, char **argv) {
    read_model("compass2.bin");
    //convert_to_bin(&E_DATA);
    return 0;
}
