// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract RandomRate is Ownable {
    using Strings for string;
    uint16 private constant NFT_TYPE = 0; //Kingdom
    uint16 private constant KINGDOM = 1; //Kingdom
    uint16 private constant TRANING_CAMP = 2; //Training Camp
    uint16 private constant GEAR = 3; //Battle Gear
    uint16 private constant DRO = 4; //Battle DRO
    uint16 private constant SUITE = 5; //Battle Suit
    uint16 private constant BOT = 6; //Battle Bot
    uint16 private constant GEN = 7; //Human GEN
    uint16 private constant WEAP = 8; //WEAP
    uint16 private constant COMBAT_RANKS = 9; //Combat Ranks
    uint16 private constant BLUEPRINT_COMM = 0;
    uint16 private constant BLUEPRINT_RARE = 1;
    uint16 private constant BLUEPRINT_EPIC = 2;
    uint16 private constant GENOMIC_COMMON = 3;
    uint16 private constant GENOMIC_RARE = 4;
    uint16 private constant GENOMIC_EPIC = 5;
    uint16 private constant SPACE_WARRIOR = 6;
    uint16 private constant COMMON_BOX = 0;
    uint16 private constant RARE_BOX = 1;
    uint16 private constant EPIC_BOX = 2;
    uint16 private constant SPECIAL_BOX = 3;
    uint16 private constant COMMON = 0;
    uint16 private constant RARE = 1;
    uint16 private constant EPIC = 2;

    //EPool
    mapping(uint16 => uint16) public EPool;

    mapping(uint16 => uint16[]) rateResults;
    mapping(uint16 => uint256[]) percentage;

    mapping(uint16 => mapping(uint16 => uint256[])) GenPoolPercentage;
    mapping(uint16 => mapping(uint16 => uint16[])) GenPoolResults;

    mapping(uint16 => mapping(uint16 => mapping(uint16 => uint256[]))) BPPoolPercentage;
    mapping(uint16 => mapping(uint16 => mapping(uint16 => uint16[]))) BPPoolResults;

    mapping(uint16 => mapping(uint16 => uint16[])) SWPoolResults;
    mapping(uint16 => mapping(uint16 => uint256[])) SWPoolPercentage;

    function initial() public onlyOwner {
        EPool[0] = GEAR; //Battle Gear
        EPool[1] = DRO; //Battle DRO
        EPool[2] = SUITE; //Battle Suit
        EPool[3] = BOT; //Battle Bot
        EPool[4] = WEAP; //WEAP

        //-----------------START COMMON BOX RATE --------------------------------
        rateResults[COMMON_BOX] = [
            BLUEPRINT_COMM,
            BLUEPRINT_RARE,
            GENOMIC_COMMON,
            SPACE_WARRIOR
        ];
        percentage[COMMON_BOX] = [
            uint256(3000),
            uint256(2000),
            uint256(4000),
            uint256(1000)
        ];

        GenPoolPercentage[COMMON_BOX][COMMON] = [0, 1, 2, 3, 4, 5, 6];
        GenPoolPercentage[COMMON_BOX][COMMON] = [
            uint256(1400),
            uint256(1400),
            uint256(1400),
            uint256(1400),
            uint256(1400),
            uint256(1400),
            uint256(1400)
        ];

        //COMMON
        BPPoolPercentage[COMMON_BOX][COMMON][GEAR] = [
            uint256(2500),
            uint256(2500),
            uint256(2500),
            uint256(2500)
        ];
        BPPoolResults[COMMON_BOX][COMMON][GEAR] = [1, 2, 3, 4];

        BPPoolPercentage[COMMON_BOX][COMMON][DRO] = [
            uint256(2500),
            uint256(2500),
            uint256(2500),
            uint256(2500)
        ];
        BPPoolResults[COMMON_BOX][COMMON][DRO] = [1, 2, 3, 4];

        BPPoolPercentage[COMMON_BOX][COMMON][SUITE] = [
            uint256(3300),
            uint256(3300),
            uint256(3300)
        ];
        BPPoolResults[COMMON_BOX][COMMON][SUITE] = [0, 1, 2];

        BPPoolPercentage[COMMON_BOX][COMMON][BOT] = [
            uint256(2500),
            uint256(2500),
            uint256(2500),
            uint256(2500)
        ];
        BPPoolResults[COMMON_BOX][COMMON][BOT] = [1, 2, 3, 4];

        BPPoolPercentage[COMMON_BOX][COMMON][WEAP] = [
            uint256(2500),
            uint256(2500),
            uint256(2500),
            uint256(2500)
        ];
        BPPoolResults[COMMON_BOX][COMMON][WEAP] = [0, 1, 2, 3];

        //RARE
        BPPoolPercentage[COMMON_BOX][RARE][GEAR] = [
            uint256(3300),
            uint256(3300),
            uint256(3300)
        ];
        BPPoolResults[COMMON_BOX][RARE][GEAR] = [5, 6, 7];

        BPPoolPercentage[COMMON_BOX][RARE][DRO] = [
            uint256(3300),
            uint256(3300),
            uint256(3300)
        ];
        BPPoolResults[COMMON_BOX][RARE][DRO] = [5, 6, 7];

        BPPoolPercentage[COMMON_BOX][RARE][SUITE] = [
            uint256(3300),
            uint256(3300),
            uint256(3300)
        ];
        BPPoolResults[COMMON_BOX][RARE][SUITE] = [3, 4, 5];

        BPPoolPercentage[COMMON_BOX][RARE][BOT] = [
            uint256(3300),
            uint256(3300),
            uint256(3300)
        ];
        BPPoolResults[COMMON_BOX][RARE][BOT] = [5, 6, 7];

        BPPoolPercentage[COMMON_BOX][RARE][WEAP] = [
            uint256(2000),
            uint256(2000),
            uint256(2000),
            uint256(2000),
            uint256(2000)
        ];
        BPPoolResults[COMMON_BOX][RARE][WEAP] = [4, 5, 6, 7, 8];

        //SW
        SWPoolResults[TRANING_CAMP][COMMON_BOX] = [0, 1, 2, 3, 4];
        SWPoolPercentage[TRANING_CAMP][COMMON_BOX] = [
            uint256(2000),
            uint256(2000),
            uint256(2000),
            uint256(2000),
            uint256(2000)
        ];

        SWPoolResults[GEAR][COMMON_BOX] = [0, 1, 2, 3, 4, 5, 6, 7];
        SWPoolPercentage[GEAR][COMMON_BOX] = [
            uint256(8000),
            uint256(425),
            uint256(425),
            uint256(425),
            uint256(425),
            uint256(100),
            uint256(100),
            uint256(100)
        ];

        SWPoolResults[DRO][COMMON_BOX] = [0, 1, 2, 3, 4, 5, 6, 7];
        SWPoolPercentage[DRO][COMMON_BOX] = [
            uint256(8000),
            uint256(425),
            uint256(425),
            uint256(425),
            uint256(425),
            uint256(100),
            uint256(100),
            uint256(100)
        ];

        SWPoolResults[SUITE][COMMON_BOX] = [0, 1, 2, 3, 4, 5];
        SWPoolPercentage[SUITE][COMMON_BOX] = [
            uint256(2783),
            uint256(2783),
            uint256(2784),
            uint256(550),
            uint256(550),
            uint256(550)
        ];

        SWPoolResults[BOT][COMMON_BOX] = [0, 1, 2, 3, 4, 5, 6, 7];
        SWPoolPercentage[BOT][COMMON_BOX] = [
            uint256(8000),
            uint256(425),
            uint256(425),
            uint256(425),
            uint256(425),
            uint256(10),
            uint256(10),
            uint256(10)
        ];

        SWPoolResults[GEN][COMMON_BOX] = [0, 1, 2, 3, 4, 5, 6];
        SWPoolPercentage[GEN][COMMON_BOX] = [
            uint256(1428),
            uint256(1428),
            uint256(1428),
            uint256(1429),
            uint256(1429),
            uint256(1429),
            uint256(1429)
        ];

        SWPoolResults[WEAP][COMMON_BOX] = [0, 1, 2, 3, 4, 5, 6, 7, 8];
        SWPoolPercentage[WEAP][COMMON_BOX] = [
            uint256(2000),
            uint256(2000),
            uint256(2000),
            uint256(2000),
            uint256(40),
            uint256(40),
            uint256(40),
            uint256(40),
            uint256(40)
        ];

        //-----------------END COMMON BOX RATE --------------------------------

        //-----------------START RARE BOX RATE --------------------------------
        rateResults[RARE_BOX] = [
            BLUEPRINT_COMM,
            BLUEPRINT_RARE,
            BLUEPRINT_EPIC,
            GENOMIC_COMMON,
            GENOMIC_RARE,
            SPACE_WARRIOR
        ];
        percentage[RARE_BOX] = [
            uint256(1000),
            uint256(1000),
            uint256(500),
            uint256(2000),
            uint256(3000),
            uint256(2500)
        ];

        GenPoolPercentage[RARE_BOX][COMMON] = [0, 1, 2, 3, 4, 5, 6];
        GenPoolPercentage[RARE_BOX][COMMON] = [
            uint256(1400),
            uint256(1400),
            uint256(1400),
            uint256(1400),
            uint256(1400),
            uint256(1400),
            uint256(1400)
        ];

        GenPoolPercentage[RARE_BOX][RARE] = [7, 8, 9, 10, 11, 12];
        GenPoolPercentage[RARE_BOX][RARE] = [
            uint256(1600),
            uint256(1600),
            uint256(1600),
            uint256(1600),
            uint256(1600),
            uint256(1600)
        ];

        //COMMON
        BPPoolPercentage[RARE_BOX][COMMON][GEAR] = [
            uint256(2500),
            uint256(2500),
            uint256(2500),
            uint256(2500)
        ];
        BPPoolResults[RARE_BOX][COMMON][GEAR] = [1, 2, 3, 4];

        BPPoolPercentage[RARE_BOX][COMMON][DRO] = [
            uint256(2500),
            uint256(2500),
            uint256(2500),
            uint256(2500)
        ];
        BPPoolResults[RARE_BOX][COMMON][DRO] = [1, 2, 3, 4];

        BPPoolPercentage[RARE_BOX][COMMON][SUITE] = [
            uint256(3300),
            uint256(3300),
            uint256(3300)
        ];
        BPPoolResults[RARE_BOX][COMMON][SUITE] = [0, 1, 2];

        BPPoolPercentage[RARE_BOX][COMMON][BOT] = [
            uint256(2500),
            uint256(2500),
            uint256(2500),
            uint256(2500)
        ];
        BPPoolResults[RARE_BOX][COMMON][BOT] = [1, 2, 3, 4];

        BPPoolPercentage[RARE_BOX][COMMON][WEAP] = [
            uint256(2500),
            uint256(2500),
            uint256(2500),
            uint256(2500)
        ];
        BPPoolResults[RARE_BOX][COMMON][WEAP] = [0, 1, 2, 3];

        //RARE
        BPPoolPercentage[RARE_BOX][RARE][GEAR] = [
            uint256(3300),
            uint256(3300),
            uint256(3300)
        ];
        BPPoolResults[RARE_BOX][RARE][GEAR] = [5, 6, 7];

        BPPoolPercentage[RARE_BOX][RARE][DRO] = [
            uint256(3300),
            uint256(3300),
            uint256(3300)
        ];
        BPPoolResults[RARE_BOX][RARE][DRO] = [5, 6, 7];

        BPPoolPercentage[RARE_BOX][RARE][SUITE] = [
            uint256(3300),
            uint256(3300),
            uint256(3300)
        ];
        BPPoolResults[RARE_BOX][RARE][SUITE] = [3, 4, 5];

        BPPoolPercentage[RARE_BOX][RARE][BOT] = [
            uint256(3300),
            uint256(3300),
            uint256(3300)
        ];
        BPPoolResults[RARE_BOX][RARE][BOT] = [5, 6, 7];

        BPPoolPercentage[RARE_BOX][RARE][WEAP] = [
            uint256(2000),
            uint256(2000),
            uint256(2000),
            uint256(2000),
            uint256(2000)
        ];
        BPPoolResults[RARE_BOX][RARE][WEAP] = [4, 5, 6, 7, 8];

        //EPIC
        BPPoolPercentage[RARE_BOX][EPIC][GEAR] = [
            uint256(3300),
            uint256(3300),
            uint256(3300)
        ];
        BPPoolResults[RARE_BOX][EPIC][GEAR] = [8, 9, 10];

        BPPoolPercentage[RARE_BOX][EPIC][DRO] = [
            uint256(3300),
            uint256(3300),
            uint256(3300)
        ];
        BPPoolResults[RARE_BOX][EPIC][DRO] = [8, 9, 10];

        BPPoolPercentage[RARE_BOX][EPIC][SUITE] = [
            uint256(2500),
            uint256(2500),
            uint256(2500),
            uint256(2500)
        ];
        BPPoolResults[RARE_BOX][EPIC][SUITE] = [6, 7, 8, 9];

        BPPoolPercentage[RARE_BOX][EPIC][BOT] = [
            uint256(3300),
            uint256(3300),
            uint256(3300)
        ];
        BPPoolResults[RARE_BOX][EPIC][BOT] = [8, 9, 10];

        BPPoolPercentage[RARE_BOX][EPIC][WEAP] = [
            uint256(1600),
            uint256(1600),
            uint256(1600),
            uint256(1600),
            uint256(1600)
        ];
        BPPoolResults[RARE_BOX][EPIC][WEAP] = [9, 10, 11, 12, 13, 14];

        //SW
        SWPoolResults[TRANING_CAMP][RARE_BOX] = [0, 1, 2, 3, 4];
        SWPoolPercentage[TRANING_CAMP][RARE_BOX] = [
            uint256(2000),
            uint256(2000),
            uint256(2000),
            uint256(2000),
            uint256(2000)
        ];

        SWPoolResults[GEAR][RARE_BOX] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
        SWPoolPercentage[GEAR][RARE_BOX] = [
            uint256(7200),
            uint256(625),
            uint256(625),
            uint256(625),
            uint256(625),
            uint256(95),
            uint256(95),
            uint256(95),
            uint256(5),
            uint256(5),
            uint256(5)
        ];

        SWPoolResults[DRO][RARE_BOX] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
        SWPoolPercentage[DRO][RARE_BOX] = [
            uint256(7200),
            uint256(625),
            uint256(625),
            uint256(625),
            uint256(625),
            uint256(95),
            uint256(95),
            uint256(95),
            uint256(5),
            uint256(5),
            uint256(5)
        ];

        SWPoolResults[SUITE][RARE_BOX] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
        SWPoolPercentage[SUITE][RARE_BOX] = [
            uint256(2450),
            uint256(2450),
            uint256(2450),
            uint256(750),
            uint256(750),
            uint256(750),
            uint256(100),
            uint256(100),
            uint256(100),
            uint256(100)
        ];

        SWPoolResults[BOT][RARE_BOX] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
        SWPoolPercentage[BOT][RARE_BOX] = [
            uint256(7200),
            uint256(625),
            uint256(625),
            uint256(625),
            uint256(625),
            uint256(95),
            uint256(95),
            uint256(95),
            uint256(5),
            uint256(5),
            uint256(5)
        ];

        SWPoolResults[GEN][RARE_BOX] = [
            0,
            1,
            2,
            3,
            4,
            5,
            6,
            7,
            8,
            9,
            10,
            11,
            12
        ];
        SWPoolPercentage[GEN][RARE_BOX] = [
            uint256(1143),
            uint256(1143),
            uint256(1143),
            uint256(1143),
            uint256(1143),
            uint256(1143),
            uint256(1142),
            uint256(334),
            uint256(334),
            uint256(333),
            uint256(333),
            uint256(333),
            uint256(333)
        ];

        SWPoolResults[WEAP][RARE_BOX] = [
            0,
            1,
            2,
            3,
            4,
            5,
            6,
            7,
            8,
            9,
            10,
            11,
            12,
            13,
            14
        ];
        SWPoolPercentage[WEAP][RARE_BOX] = [
            uint256(1735),
            uint256(1735),
            uint256(1735),
            uint256(1735),
            uint256(600),
            uint256(600),
            uint256(600),
            uint256(600),
            uint256(600),
            uint256(10),
            uint256(10),
            uint256(10),
            uint256(10),
            uint256(10),
            uint256(10)
        ];

        //-----------------END RARE BOX RATE --------------------------------

        //-----------------START EPIC BOX RATE --------------------------------
        rateResults[EPIC_BOX] = [
            BLUEPRINT_EPIC,
            GENOMIC_RARE,
            GENOMIC_EPIC,
            SPACE_WARRIOR
        ];
        percentage[EPIC_BOX] = [
            uint256(1000),
            uint256(1000),
            uint256(1000),
            uint256(7000)
        ];

        GenPoolPercentage[EPIC_BOX][RARE] = [7, 8, 9, 10, 11, 12];
        GenPoolPercentage[EPIC_BOX][RARE] = [
            uint256(1600),
            uint256(1600),
            uint256(1600),
            uint256(1600),
            uint256(1600),
            uint256(1600)
        ];

        GenPoolPercentage[EPIC_BOX][RARE] = [13, 14, 15, 16];
        GenPoolPercentage[EPIC_BOX][RARE] = [
            uint256(2500),
            uint256(2500),
            uint256(2500),
            uint256(2500)
        ];

        //EPIC
        BPPoolPercentage[EPIC_BOX][EPIC][GEAR] = [
            uint256(3300),
            uint256(3300),
            uint256(3300)
        ];
        BPPoolResults[EPIC_BOX][EPIC][GEAR] = [8, 9, 10];

        BPPoolPercentage[EPIC_BOX][EPIC][DRO] = [
            uint256(3300),
            uint256(3300),
            uint256(3300)
        ];
        BPPoolResults[EPIC_BOX][EPIC][DRO] = [8, 9, 10];

        BPPoolPercentage[EPIC_BOX][EPIC][SUITE] = [
            uint256(2500),
            uint256(2500),
            uint256(2500),
            uint256(2500)
        ];
        BPPoolResults[EPIC_BOX][EPIC][SUITE] = [6, 7, 8, 9];

        BPPoolPercentage[EPIC_BOX][EPIC][BOT] = [
            uint256(3300),
            uint256(3300),
            uint256(3300)
        ];
        BPPoolResults[EPIC_BOX][EPIC][BOT] = [8, 9, 10];

        BPPoolPercentage[EPIC_BOX][EPIC][WEAP] = [
            uint256(1600),
            uint256(1600),
            uint256(1600),
            uint256(1600),
            uint256(1600)
        ];
        BPPoolResults[EPIC_BOX][EPIC][WEAP] = [9, 10, 11, 12, 13, 14];

        //SW
        SWPoolResults[TRANING_CAMP][EPIC_BOX] = [0, 1, 2, 3, 4];
        SWPoolPercentage[TRANING_CAMP][EPIC_BOX] = [
            uint256(2000),
            uint256(2000),
            uint256(2000),
            uint256(2000),
            uint256(2000)
        ];

        SWPoolResults[GEAR][EPIC_BOX] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
        SWPoolPercentage[GEAR][EPIC_BOX] = [
            uint256(6525),
            uint256(700),
            uint256(700),
            uint256(700),
            uint256(700),
            uint256(200),
            uint256(200),
            uint256(200),
            uint256(25),
            uint256(25),
            uint256(25)
        ];

        SWPoolResults[DRO][EPIC_BOX] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
        SWPoolPercentage[DRO][EPIC_BOX] = [
            uint256(6525),
            uint256(700),
            uint256(700),
            uint256(700),
            uint256(700),
            uint256(200),
            uint256(200),
            uint256(200),
            uint256(25),
            uint256(25),
            uint256(25)
        ];

        SWPoolResults[SUITE][EPIC_BOX] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
        SWPoolPercentage[SUITE][EPIC_BOX] = [
            uint256(2050),
            uint256(2050),
            uint256(2050),
            uint256(1050),
            uint256(1050),
            uint256(1050),
            uint256(175),
            uint256(175),
            uint256(175),
            uint256(175)
        ];

        SWPoolResults[BOT][EPIC_BOX] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
        SWPoolPercentage[BOT][EPIC_BOX] = [
            uint256(6525),
            uint256(700),
            uint256(700),
            uint256(700),
            uint256(700),
            uint256(200),
            uint256(200),
            uint256(200),
            uint256(25),
            uint256(25),
            uint256(25)
        ];

        SWPoolResults[GEN][EPIC_BOX] = [
            0,
            1,
            2,
            3,
            4,
            5,
            6,
            7,
            8,
            9,
            10,
            11,
            12,
            13,
            14,
            15,
            16
        ];
        SWPoolPercentage[GEN][EPIC_BOX] = [
            uint256(1020),
            uint256(1020),
            uint256(1020),
            uint256(1020),
            uint256(1020),
            uint256(1021),
            uint256(1021),
            uint256(357),
            uint256(357),
            uint256(357),
            uint256(357),
            uint256(357),
            uint256(357),
            uint256(179),
            uint256(179),
            uint256(179),
            uint256(179)
        ];

        SWPoolResults[WEAP][EPIC_BOX] = [
            0,
            1,
            2,
            3,
            4,
            5,
            6,
            7,
            8,
            9,
            10,
            11,
            12,
            13,
            14
        ];
        SWPoolPercentage[WEAP][EPIC_BOX] = [
            uint256(1463),
            uint256(1463),
            uint256(1462),
            uint256(1462),
            uint256(800),
            uint256(800),
            uint256(800),
            uint256(800),
            uint256(800),
            uint256(25),
            uint256(25),
            uint256(25),
            uint256(25),
            uint256(25),
            uint256(25)
        ];

        //-----------------END EPIC BOX RATE --------------------------------

        //-----------------START SPECIAL BOX RATE --------------------------------

        rateResults[SPECIAL_BOX] = [SPACE_WARRIOR];
        percentage[SPECIAL_BOX] = [uint256(10000)];

        SWPoolResults[TRANING_CAMP][SPECIAL_BOX] = [0, 1, 2, 3, 4];
        SWPoolPercentage[TRANING_CAMP][SPECIAL_BOX] = [
            uint256(2000),
            uint256(2000),
            uint256(2000),
            uint256(2000),
            uint256(2000)
        ];

        SWPoolResults[GEAR][SPECIAL_BOX] = [0, 1, 2, 3, 4, 5, 6, 7];
        SWPoolPercentage[GEAR][SPECIAL_BOX] = [
            uint256(6327),
            uint256(666),
            uint256(666),
            uint256(666),
            uint256(666),
            uint256(333),
            uint256(333),
            uint256(333)
        ];

        SWPoolResults[DRO][SPECIAL_BOX] = [0, 1, 2, 3, 4, 5, 6, 7];
        SWPoolPercentage[DRO][SPECIAL_BOX] = [
            uint256(6327),
            uint256(666),
            uint256(666),
            uint256(666),
            uint256(666),
            uint256(333),
            uint256(333),
            uint256(333)
        ];

        SWPoolResults[SUITE][SPECIAL_BOX] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
        SWPoolPercentage[SUITE][SPECIAL_BOX] = [
            uint256(1665),
            uint256(1998),
            uint256(1998),
            uint256(999),
            uint256(999),
            uint256(999),
            uint256(333),
            uint256(333),
            uint256(333),
            uint256(333)
        ];

        SWPoolResults[BOT][SPECIAL_BOX] = [0, 1, 2, 3, 4, 5, 6, 7];
        SWPoolPercentage[BOT][SPECIAL_BOX] = [
            uint256(6327),
            uint256(666),
            uint256(666),
            uint256(666),
            uint256(666),
            uint256(333),
            uint256(333),
            uint256(333)
        ];

        SWPoolResults[GEN][SPECIAL_BOX] = [
            0,
            1,
            2,
            3,
            4,
            5,
            6,
            7,
            8,
            9,
            10,
            11,
            12,
            13,
            14,
            15,
            16
        ];
        SWPoolPercentage[GEN][SPECIAL_BOX] = [
            uint256(333),
            uint256(333),
            uint256(333),
            uint256(333),
            uint256(333),
            uint256(666),
            uint256(666),
            uint256(999),
            uint256(999),
            uint256(999),
            uint256(666),
            uint256(666),
            uint256(666),
            uint256(333),
            uint256(666),
            uint256(333),
            uint256(666)
        ];

        SWPoolResults[WEAP][SPECIAL_BOX] = [0, 1, 2, 3, 4, 5, 6, 7, 8];
        SWPoolPercentage[WEAP][SPECIAL_BOX] = [
            uint256(999),
            uint256(1332),
            uint256(1332),
            uint256(1332),
            uint256(999),
            uint256(999),
            uint256(999),
            uint256(999),
            uint256(999)
        ];
        //-----------------END SPECIAL BOX RATE --------------------------------
    }

    function getGenPool(
        uint16 _nftType,
        uint16 _rarity,
        uint16 _number
    ) public view returns (uint16) {
        uint16 amount = 100;
        uint16 index = 0;
        uint16 count = 0;

        for (
            uint16 p = 0;
            p < GenPoolPercentage[_nftType][_rarity].length;
            p++
        ) {
            uint256 qtyItem = (amount *
                GenPoolPercentage[_nftType][_rarity][p]) / 10000;
            for (uint16 i = 0; i < qtyItem; i++) {
                count++;
            }
        }

        uint16 _modNumber = uint16(_number) % count;

        for (
            uint16 p = 0;
            p < GenPoolPercentage[_nftType][_rarity].length;
            p++
        ) {
            uint256 qtyItem = (amount *
                GenPoolPercentage[_nftType][_rarity][p]) / 10000;
            for (uint16 i = 0; i < qtyItem; i++) {
                if (_modNumber == index) {
                    return GenPoolResults[_nftType][_rarity][p];
                }

                index++;
            }
        }

        return 0;
    }

    function getNFTPool(uint16 _nftType, uint16 _number)
        public
        view
        returns (uint16)
    {
        uint16 amount = 100;
        uint16 count = 0;
        uint16 index = 0;
 
        for (uint16 p = 0; p < percentage[_nftType].length; p++) {
            uint256 qtyItem = (amount * percentage[_nftType][p]) / 10000;
            for (uint16 i = 0; i < qtyItem; i++) {
                count++;
            }
        }

        uint16 _modNumber = uint16(_number) % count;

        for (uint16 p = 0; p < percentage[_nftType].length; p++) {
            uint256 qtyItem = (amount * percentage[_nftType][p]) / 10000;
            for (uint16 i = 0; i < qtyItem; i++) {
                if (_modNumber == index) {
                    return rateResults[_nftType][p];
                }

                index++;
            }
        }

        return 0;
    }

    function getEquipmentPool(uint16 _number) public view returns (uint16) {
        return EPool[_number];
    }

    function getBlueprintPool(
        uint16 _nftType,
        uint16 _rarity,
        uint16 eTypeId,
        uint16 _number
    ) public view returns (uint16) {
        uint16 amount = 100;
        uint16 index = 0;
        uint16 count = 0;
        for (
            uint16 p = 0;
            p < BPPoolPercentage[_nftType][_rarity][eTypeId].length;
            p++
        ) {
            uint256 qtyItem = (amount *
                BPPoolPercentage[_nftType][_rarity][eTypeId][p]) / 10000;
            for (uint16 i = 0; i < qtyItem; i++) {
                count++;
            }
        }

        uint16 _modNumber = uint16(_number) % count;

        for (
            uint16 p = 0;
            p < BPPoolPercentage[_nftType][_rarity][eTypeId].length;
            p++
        ) {
            uint256 qtyItem = (amount *
                BPPoolPercentage[_nftType][_rarity][eTypeId][p]) / 10000;
            for (uint16 i = 0; i < qtyItem; i++) {
                if (_modNumber == index) {
                    return BPPoolResults[_nftType][_rarity][eTypeId][p];
                }

                index++;
            }
        }

        return 0;
    }

    function getSpaceWarriorPool(
        uint16 _part,
        uint16 _nftType,
        uint16 _number
    ) public view returns (uint16) {
        uint16 amount = 100;
        uint16 count = 0;
        uint16 index = 0;

        for (uint16 p = 0; p < SWPoolPercentage[_part][_nftType].length; p++) {
            uint256 qtyItem = (amount * SWPoolPercentage[_part][_nftType][p]) /
                10000;
            for (uint16 i = 0; i < qtyItem; i++) {
                count++;
            }
        }

        uint16 _modNumber = uint16(_number) % count;

        for (uint16 p = 0; p < SWPoolPercentage[_part][_nftType].length; p++) {
            uint256 qtyItem = (amount * SWPoolPercentage[_part][_nftType][p]) /
                10000;
            for (uint16 i = 0; i < qtyItem; i++) {
                if (_modNumber == index) {
                    return SWPoolResults[_part][_nftType][p];
                }

                index++;
            }
        }

        return 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}