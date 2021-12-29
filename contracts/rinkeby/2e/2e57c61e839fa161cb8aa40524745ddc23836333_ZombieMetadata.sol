/**
 *Submitted for verification at Etherscan.io on 2021-12-29
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/// @title ZombieMetadata
/// @author Elmontos
/// @notice Provides metadata information for zombies
library ZombieMetadata {
    
    enum ZombieTrait { Torso, LeftArm, RightArm, Legs, Head }

    function zombieTorsoTraitCount(uint8 level) internal pure returns (uint8) { if(level > 0) { return 10; } else { return 0; } }
    function zombieTorsoTrait(uint8 level, uint8 traitNumber) internal pure returns (string memory) {
        if(level == 1) {
            string[10] memory TORSO_L1 = ["Level 1 Torso 1","Level 1 Torso 2","Level 1 Torso 3","Level 1 Torso 4","Level 1 Torso 5","Level 1 Torso 6","Level 1 Torso 7","Level 1 Torso 8","Level 1 Torso 9","Level 1 Torso 10"];
            return TORSO_L1[traitNumber - 1];
        } else if(level == 2) {
            string[10] memory TORSO_L2 = ["Level 2 Torso 1","Level 2 Torso 2","Level 2 Torso 3","Level 2 Torso 4","Level 2 Torso 5","Level 2 Torso 6","Level 2 Torso 7","Level 2 Torso 8","Level 2 Torso 9","Level 2 Torso 10"];
            return TORSO_L2[traitNumber - 1];
        } else if(level == 3) {
            string[10] memory TORSO_L3 = ["Level 3 Torso 1","Level 3 Torso 2","Level 3 Torso 3","Level 3 Torso 4","Level 3 Torso 5","Level 3 Torso 6","Level 3 Torso 7","Level 3 Torso 8","Level 3 Torso 9","Level 3 Torso 10"];
            return TORSO_L3[traitNumber - 1];
        } else if(level == 4) {
            string[10] memory TORSO_L3 = ["Level 4 Torso 1","Level 4 Torso 2","Level 4 Torso 3","Level 4 Torso 4","Level 4 Torso 5","Level 4 Torso 6","Level 4 Torso 7","Level 4 Torso 8","Level 4 Torso 9","Level 4 Torso 10"];
            return TORSO_L3[traitNumber - 1];
        } else if(level == 5) {
            string[10] memory TORSO_L3 = ["Level 5 Torso 1","Level 5 Torso 2","Level 5 Torso 3","Level 5 Torso 4","Level 5 Torso 5","Level 5 Torso 6","Level 5 Torso 7","Level 5 Torso 8","Level 5 Torso 9","Level 5 Torso 10"];
            return TORSO_L3[traitNumber - 1];
        } else {
            return "";
        }
    }
    function zombieTorsoSVG(uint8 level, uint8 traitNumber) internal pure returns(string memory) {
        //TBA
        return "";
    }

    function zombieLeftArmTraitCount(uint8 level) internal pure returns (uint8) { 
        if(level == 1) return 12;
        else if(level == 2) return 8;
        else if(level == 3) return 9;
        else if(level == 4) return 9;
        else if(level == 5) return 9;
        else return 0;
    }
    function zombieLeftArmTrait(uint8 level, uint8 traitNumber) internal pure returns (string memory) {
        if(level == 1) {
            string[12] memory LEFTARM_L1 = ["Level 1 Left Arm 1","Level 1 Left Arm 2","Level 1 Left Arm 3","Level 1 Left Arm 4","Level 1 Left Arm 5","Level 1 Left Arm 6","Level 1 Left Arm 7","Level 1 Left Arm 8","Level 1 Left Arm 9","Level 1 Left Arm 10","Level 1 Left Arm 11","Level 1 Left Arm 12"];
            return LEFTARM_L1[traitNumber - 1];
        } else if(level == 2) {
            string[8] memory LEFTARM_L2 = ["Level 2 Left Arm 1","Level 2 Left Arm 2","Level 2 Left Arm 3","Level 2 Left Arm 4","Level 2 Left Arm 5","Level 2 Left Arm 6","Level 2 Left Arm 7","Level 2 Left Arm 8"];
            return LEFTARM_L2[traitNumber - 1];
        } else if(level == 3) {
            string[9] memory LEFTARM_L3 = ["Level 3 Left Arm 1","Level 3 Left Arm 2","Level 3 Left Arm 3","Level 3 Left Arm 4","Level 3 Left Arm 5","Level 3 Left Arm 6","Level 3 Left Arm 7","Level 3 Left Arm 8","Level 3 Left Arm 9"];
            return LEFTARM_L3[traitNumber - 1];
        } else if(level == 4) {
            string[9] memory LEFTARM_L4 = ["Level 4 Left Arm 1","Level 4 Left Arm 2","Level 4 Left Arm 3","Level 4 Left Arm 4","Level 4 Left Arm 5","Level 4 Left Arm 6","Level 4 Left Arm 7","Level 4 Left Arm 8","Level 4 Left Arm 9"];
            return LEFTARM_L4[traitNumber - 1];
        } else if(level == 5) {
            string[9] memory LEFTARM_L5 = ["Level 5 Left Arm 1","Level 5 Left Arm 2","Level 5 Left Arm 3","Level 5 Left Arm 4","Level 5 Left Arm 5","Level 5 Left Arm 6","Level 5 Left Arm 7","Level 5 Left Arm 8","Level 5 Left Arm 9"];
            return LEFTARM_L5[traitNumber - 1];
        } else {
            return "";
        }
    }
    function zombieLeftArmSVG(uint8 level, uint8 traitNumber) internal pure returns(string memory) {
        //TBA
        return "";
    }

    function zombieRightArmTraitCount(uint8 level) internal pure returns (uint8) { 
        if(level == 1) return 15;
        else if(level == 2) return 6;
        else if(level == 3) return 8;
        else if(level == 4) return 9;
        else if(level == 5) return 7;
        else return 0;
    }
    function zombieRightArmTrait(uint8 level, uint8 traitNumber) internal pure returns (string memory) {
        if(level == 1) {
            string[15] memory RIGHTARM_L1 = ["Level 1 Right Arm 1","Level 1 Right Arm 2","Level 1 Right Arm 3","Level 1 Right Arm 4","Level 1 Right Arm 5","Level 1 Right Arm 6","Level 1 Right Arm 7","Level 1 Right Arm 8","Level 1 Right Arm 9","Level 1 Right Arm 10","Level 1 Right Arm 11","Level 1 Right Arm 12","Level 1 Right Arm 13","Level 1 Right Arm 14","Level 1 Right Arm 15"];
            return RIGHTARM_L1[traitNumber - 1];
        } else if(level == 2) {
            string[6] memory RIGHTARM_L2 = ["Level 2 Right Arm 1","Level 2 Right Arm 2","Level 2 Right Arm 3","Level 2 Right Arm 4","Level 2 Right Arm 5","Level 2 Right Arm 6"];
            return RIGHTARM_L2[traitNumber - 1];
        } else if(level == 3) {
            string[8] memory RIGHTARM_L3 = ["Level 3 Right Arm 1","Level 3 Right Arm 2","Level 3 Right Arm 3","Level 3 Right Arm 4","Level 3 Right Arm 5","Level 3 Right Arm 6","Level 3 Right Arm 7","Level 3 Right Arm 8"];
            return RIGHTARM_L3[traitNumber - 1];
        } else if(level == 4) {
            string[9] memory RIGHTARM_L4 = ["Level 4 Right Arm 1","Level 4 Right Arm 2","Level 4 Right Arm 3","Level 4 Right Arm 4","Level 4 Right Arm 5","Level 4 Right Arm 6","Level 4 Right Arm 7","Level 4 Right Arm 8","Level 4 Right Arm 9"];
            return RIGHTARM_L4[traitNumber - 1];
        } else if(level == 5) {
            string[7] memory RIGHTARM_L5 = ["Level 5 Right Arm 1","Level 5 Right Arm 2","Level 5 Right Arm 3","Level 5 Right Arm 4","Level 5 Right Arm 5","Level 5 Right Arm 6","Level 5 Right Arm 7"];
            return RIGHTARM_L5[traitNumber - 1];
        } else {
            return "";
        }
    }
    function zombieRightArmSVG(uint8 level, uint8 traitNumber) internal pure returns(string memory) {
        //TBA
        return "";
    }

    function zombieLegsTraitCount(uint8 level) internal pure returns (uint8) { 
        if(level == 1) return 12;
        else if(level == 2) return 12;
        else if(level == 3) return 8;
        else if(level == 4) return 10;
        else if(level == 5) return 9;
        else return 0;
    }
    function zombieLegsTrait(uint8 level, uint8 traitNumber) internal pure returns (string memory) {
        if(level == 1) {
            string[12] memory LEGS_L1 = ["Level 1 Legs 1","Level 1 Legs 2","Level 1 Legs 3","Level 1 Legs 4","Level 1 Legs 5","Level 1 Legs 6","Level 1 Legs 7","Level 1 Legs 8","Level 1 Legs 9","Level 1 Legs 10","Level 1 Legs 11","Level 1 Legs 12"];
            return LEGS_L1[traitNumber - 1];
        } else if(level == 2) {
            string[12] memory LEGS_L2 = ["Level 2 Legs 1","Level 2 Legs 2","Level 2 Legs 3","Level 2 Legs 4","Level 2 Legs 5","Level 2 Legs 6","Level 2 Legs 7","Level 2 Legs 8","Level 2 Legs 9","Level 2 Legs 10","Level 2 Legs 11","Level 2 Legs 12"];
            return LEGS_L2[traitNumber - 1];
        } else if(level == 3) {
            string[8] memory LEGS_L3 = ["Level 3 Legs 1","Level 3 Legs 2","Level 3 Legs 3","Level 3 Legs 4","Level 3 Legs 5","Level 3 Legs 6","Level 3 Legs 7","Level 3 Legs 8"];
            return LEGS_L3[traitNumber - 1];
        } else if(level == 4) {
            string[10] memory LEGS_L4 = ["Level 4 Legs 1","Level 4 Legs 2","Level 4 Legs 3","Level 4 Legs 4","Level 4 Legs 5","Level 4 Legs 6","Level 4 Legs 7","Level 4 Legs 8","Level 4 Legs 9","Level 4 Legs 10"];
            return LEGS_L4[traitNumber - 1];
        } else if(level == 5) {
            string[9] memory LEGS_L5 = ["Level 5 Legs 1","Level 5 Legs 2","Level 5 Legs 3","Level 5 Legs 4","Level 5 Legs 5","Level 5 Legs 6","Level 5 Legs 7","Level 5 Legs 8","Level 5 Legs 9"];
            return LEGS_L5[traitNumber - 1];
        } else {
            return "";
        }
    }
    function zombieLegsSVG(uint8 level, uint8 traitNumber) internal pure returns(string memory) {
        //TBA
        return "";
    }

    function zombieHeadTraitCount(uint8 level) internal pure returns (uint8) { 
        if(level == 1) return 16;
        else if(level == 2) return 10;
        else if(level == 3) return 11;
        else if(level == 4) return 9;
        else if(level == 5) return 10;
        else return 0;
    }
    function zombieHeadTrait(uint8 level, uint8 traitNumber) internal pure returns (string memory) {
        if(level == 1) {
            string[16] memory HEAD_L1 = ["Level 1 Head 1","Level 1 Head 2","Level 1 Head 3","Level 1 Head 4","Level 1 Head 5","Level 1 Head 6","Level 1 Head 7","Level 1 Head 8","Level 1 Head 9","Level 1 Head 10","Level 1 Head 11","Level 1 Head 12","Level 1 Head 13","Level 1 Head 14","Level 1 Head 15","Level 1 Head 16"];
            return HEAD_L1[traitNumber - 1];
        } else if(level == 2) {
            string[10] memory HEAD_L2 = ["Level 2 Head 1","Level 2 Head 2","Level 2 Head 3","Level 2 Head 4","Level 2 Head 5","Level 2 Head 6","Level 2 Head 7","Level 2 Head 8","Level 2 Head 9","Level 2 Head 10"];
            return HEAD_L2[traitNumber - 1];
        } else if(level == 3) {
            string[11] memory HEAD_L3 = ["Level 3 Head 1","Level 3 Head 2","Level 3 Head 3","Level 3 Head 4","Level 3 Head 5","Level 3 Head 6","Level 3 Head 7","Level 3 Head 8","Level 3 Head 9","Level 3 Head 10","Level 3 Head 11"];
            return HEAD_L3[traitNumber - 1];
        } else if(level == 4) {
            string[9] memory HEAD_L4 = ["Level 4 Head 1","Level 4 Head 2","Level 4 Head 3","Level 4 Head 4","Level 4 Head 5","Level 4 Head 6","Level 4 Head 7","Level 4 Head 8","Level 4 Head 9"];
            return HEAD_L4[traitNumber - 1];
        } else if(level == 5) {
            string[10] memory HEAD_L5 = ["Level 5 Head 1","Level 5 Head 2","Level 5 Head 3","Level 5 Head 4","Level 5 Head 5","Level 5 Head 6","Level 5 Head 7","Level 5 Head 8","Level 5 Head 9","Level 5 Head 10"];
            return HEAD_L5[traitNumber - 1];
        } else {
            return "";
        }
    }
    function zombieHeadSVG(uint8 level, uint8 traitNumber) internal pure returns(string memory) {
        //TBA
        return "";
    }

    function zombieTrait(ZombieTrait trait, uint8 level, uint8 traitNumber) external pure returns (string memory) {
        if(trait == ZombieTrait.Torso) return zombieTorsoTrait(level, traitNumber);
        else if(trait == ZombieTrait.LeftArm) return zombieLeftArmTrait(level, traitNumber);
        else if(trait == ZombieTrait.RightArm) return zombieRightArmTrait(level, traitNumber);
        else if(trait == ZombieTrait.Legs) return zombieLegsTrait(level, traitNumber);
        else if(trait == ZombieTrait.Head) return zombieHeadTrait(level, traitNumber);
        else return "None";
    }

    function zombieSVG(uint8 level, uint8[] memory traits) external pure returns (bytes memory) {
        string memory torsoSVG = zombieTorsoSVG(level, traits[0]);
        string memory leftArmSVG = zombieTorsoSVG(level, traits[1]);
        string memory rightArmSVG = zombieTorsoSVG(level, traits[2]);
        string memory legsSVG = zombieTorsoSVG(level, traits[3]);
        string memory headSVG = zombieTorsoSVG(level, traits[4]);

        return bytes(
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 7 8" shape-rendering="crispEdges">',
                torsoSVG,
                leftArmSVG,
                rightArmSVG,
                legsSVG,
                headSVG,
                '</svg>'
            )
        );
    }
}