/**
 *Submitted for verification at Etherscan.io on 2022-01-05
*/

// File: base/Context.sol



pragma solidity ^0.8.0;
/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */

contract Context {

    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor ()  {}

    function _msgSender() internal view returns (address payable) {
        return payable (msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
// File: base/ownable.sol




pragma solidity ^0.8.0;
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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
   */
    constructor ()  {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
   */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
   */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
   * `onlyOwner` functions anymore. Can only be called by the current owner.
   *
   * NOTE: Renouncing ownership will leave the contract without an owner,
   * thereby removing any functionality that is only available to the owner.
   */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
   */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: base/IGameEngine.sol



pragma solidity ^0.8.0;

interface GameEngine{
    function stake ( uint tokenId ) external;
    function alertStake (uint tokenId) external;
}
// File: base/Random.sol

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;


library Random {

    function range(uint min, uint max,uint nonce) external view returns(uint) {
        if(max == 0 || min == max) {
            return 0;
        } else {
            uint rangeNum = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp,nonce))) % max;
            rangeNum = rangeNum + min;
            return rangeNum;
        }
    }

}
// File: metadata/SurvivorMetadata.sol


pragma solidity ^0.8.0;

/// @title SurvivorMetadata
/// @author Elmontos
/// @notice Provides metadata information for survivors
library SurvivorMetadata {
    
    function getShoes() public pure returns (string[28] memory) {
        return ["Shoes 1","Shoes 2","Shoes 3","Shoes 4","Shoes 5","Shoes 6","Shoes 7","Shoes 8","Shoes 9","Shoes 10","Shoes 11","Shoes 12","Shoes 13","Shoes 14","Shoes 15","Shoes 16","Shoes 17","Shoes 18","Shoes 19","Shoes 20","Shoes 21","Shoes 22","Shoes 23","Shoes 24","Shoes 25","Shoes 26","Shoes 27","Shoes 28"];
    }

    function getPants() public pure returns (string[20] memory) {
        return ["Pants 1","Pants 2","Pants 3","Pants 4","Pants 5","Pants 6","Pants 7","Pants 8","Pants 9","Pants 10","Pants 11","Pants 12","Pants 13","Pants 14","Pants 15","Pants 16","Pants 17","Pants 18","Pants 19","Pants 20"];
    }

    function getBody() public pure returns (string[25] memory) {
        return ["Body 1","Body 2","Body 3","Body 4","Body 5","Body 6","Body 7","Body 8","Body 9","Body 10","Body 11","Body 12","Body 13","Body 14","Body 15","Body 16","Body 17","Body 18","Body 19","Body 20","Body 21","Body 22","Body 23","Body 24","Body 25"];
    }

    function getBeard() public pure returns (string[44] memory) {
        return  ["Beard 1","Beard 2","Beard 3","Beard 4","Beard 5","Beard 6","Beard 7","Beard 8","Beard 9","Beard 10","Beard 11","Beard 12","Beard 13","Beard 14","Beard 15","Beard 16","Beard 17","Beard 18","Beard 19","Beard 20","Beard 21","Beard 22","Beard 23","Beard 24","Beard 25","Beard 26","Beard 27","Beard 28","Beard 29","Beard 30","Beard 31","Beard 32","Beard 33","Beard 34","Beard 35","Beard 36","Beard 37","Beard 38","Beard 39","Beard 40","Beard 41","None","None","None"];
    }

    function getHair() public pure returns (string[44] memory) {
        return ["Hair 1","Hair 2","Hair 3","Hair 4","Hair 5","Hair 6","Hair 7","Hair 8","Hair 9","Hair 10","Hair 11","Hair 12","Hair 13","Hair 14","Hair 15","Hair 16","Hair 17","Hair 18","Hair 19","Hair 20","Hair 21","Hair 22","Hair 23","Hair 24","Hair 25","Hair 26","Hair 27","Hair 28","Hair 29","Hair 30","Hair 31","Hair 32","Hair 33","Hair 34","Hair 35","Hair 36","Hair 37","Hair 38","Hair 39","None","None","None","None","None"];
    }

    function getHead() public pure returns (string[44] memory) {
        return ["Hat 1","Hat 2","Hat 3","Hat 4","Hat 5","Hat 6","Hat 7","Hat 8","Sunglasses 1","Sunglasses 2","Face Marking 1","Face Marking 2","Face Marking 3","Hat 9","Sunglasses 3","Sunglasses 4","Sunglasses 5","Sunglasses 6","Sunglasses 7","Sunglasses 8","Sunglasses 9","Sunglasses 10","Face Marking 4","Sunglasses 11","Sunglasses 12","Sunglasses 13","Sunglasses 14","Sunglasses 15","Sunglasses 16","Sunglasses 17","Sunglasses 18","Hat 10","Hat 11","Hat 12","Hat 13","Hat 14","Hat 15","Hat 16","Hat 17","Hat 18","None","None","None","None"];
    }

    function getShirts() public pure returns (string[32] memory) {
        return ["Shirts 1","Shirts 2","Shirts 3","Shirts 4","Shirts 5","Shirts 6","Shirts 7","Shirts 8","Shirts 9","Shirts 10","Shirts 11","Shirts 12","Shirts 13","Shirts 14","Shirts 15","Shirts 16","Shirts 17","Shirts 18","Shirts 19","Shirts 20","Shirts 21","Shirts 22","Shirts 23","Shirts 24","Shirts 25","Shirts 26","Shirts 27","Shirts 28","Shirts 29","Shirts 30","Shirts 31","Shirts 32"];
    }

    function getChestArmorLevel5() public pure returns (string[13] memory) {
        return ["Chest Armor 1","Chest Armor 2","Chest Armor 3","Chest Armor 4","Chest Armor 5","Chest Armor 6","Chest Armor 7","Chest Armor 8","Chest Armor 9","Chest Armor 10","Chest Armor 11","Chest Armor 12","Chest Armor 13"];
    }

    function getShoulderArmorLevel4() public pure returns (string[8] memory) {
        return ["Shoulder Armor 1","Shoulder Armor 2","Shoulder Armor 3","Shoulder Armor 4","Shoulder Armor 5","Shoulder Armor 6","Shoulder Armor 7","Shoulder Armor 8"];
    }

    function getShoulderArmorLevel5() public pure returns (string[8] memory) {
        return ["Shoulder Armor 9","Shoulder Armor 10","Shoulder Armor 11","Shoulder Armor 12","Shoulder Armor 13","Shoulder Armor 14","Shoulder Armor 15","Shoulder Armor 16"];
    }

    function getLegArmorLevel4() public pure returns (string[8] memory) {
        return ["Leg Armor 1","Leg Armor 2","Leg Armor 3","Leg Armor 4","Leg Armor 5","Leg Armor 6","Leg Armor 7","Leg Armor 8"];
    }

    function getRightWeaponLevel1() public pure returns (string[8] memory) {
        return ["Level 1 Right Weapon 1","Level 1 Right Weapon 2","Level 1 Right Weapon 3","Level 1 Right Weapon 4","Level 1 Right Weapon 5","Level 1 Right Weapon 6","Level 1 Right Weapon 7","Level 1 Right Weapon 8"];
    }

    function getRightWeaponLevel2() public pure returns (string[11] memory) {
        return ["Level 2 Right Weapon 1","Level 2 Right Weapon 2","Level 2 Right Weapon 3","Level 2 Right Weapon 4","Level 2 Right Weapon 5","Level 2 Right Weapon 6","Level 2 Right Weapon 7","Level 2 Right Weapon 8","Level 2 Right Weapon 9","Level 2 Right Weapon 10","Level 2 Right Weapon 11"];
    }

    function getLeftWeaponLevel3() public pure returns (string[9] memory) {
        return ["Level 3 Left Weapon 1","Level 3 Left Weapon 2","Level 3 Left Weapon 3","Level 3 Left Weapon 4","Level 3 Left Weapon 5","Level 3 Left Weapon 6","Level 3 Left Weapon 7","Level 3 Left Weapon 8","Level 3 Left Weapon 9"];
    }

    function getLeftWeaponLevel4() public pure returns (string[7] memory) {
        return ["Level 4 Left Weapon 1","Level 4 Left Weapon 2","Level 4 Left Weapon 3","Level 4 Left Weapon 4","Level 4 Left Weapon 5","Level 4 Left Weapon 6","Level 4 Left Weapon 7"];
    }

    function getLeftWeaponLevel5() public pure returns (string[8] memory) {
        return ["Level 5 Left Weapon 1","Level 5 Left Weapon 2","Level 5 Left Weapon 3","Level 5 Left Weapon 4","Level 5 Left Weapon 5","Level 5 Left Weapon 6","Level 5 Left Weapon 7","Level 5 Left Weapon 8"];
    }
}
// File: metadata/SurvivorFactory.sol




pragma solidity ^0.8.0;

/// @title SurvivorFactory
/// @author Elmontos
/// @notice Provides metadata information for survivors
library SurvivorFactory {
    
    enum SurvivorTrait { Shoes, Pants, Body, Beard, Hair, Head, Shirt, ChestArmor, ShoulderArmor, LegArmor, RightWeapon, LeftWeapon }

    //SHOES

    function survivorShoesTraitCount() internal pure returns (uint8) { return 28; }
    function survivorShoesTrait(uint8 traitNumber) internal pure returns (string memory) {
        return SurvivorMetadata.getShoes()[traitNumber - 1]; 
    }
    function survivorShoesSVG(uint8 traitNumber) internal pure returns(string memory) {
        //TBA
        return "";
    }

    //PANTS
    function survivorPantsTraitCount() internal pure returns (uint8) { return 20; }
    function survivorPantsTrait(uint8 traitNumber) internal pure returns (string memory) {
        return SurvivorMetadata.getPants()[traitNumber - 1]; 
    }
    function survivorPantsSVG(uint8 traitNumber) internal pure returns(string memory) {
        //TBA
        return "";
    }

    //BODY
    function survivorBodyTraitCount() internal pure returns (uint8) { return 25; }
    function survivorBodyTrait(uint8 traitNumber) internal pure returns (string memory) {
        return SurvivorMetadata.getBody()[traitNumber - 1];
    }
    function survivorBodySVG(uint8 traitNumber) internal pure returns(string memory) {
        //TBA
        return "";
    }

    //BEARD
    function survivorBeardTraitCount() internal pure returns (uint8) { return 44; }
    function survivorBeardTrait(uint8 traitNumber) internal pure returns (string memory) {
        return SurvivorMetadata.getBeard()[traitNumber - 1];  
    }
    function survivorBeardSVG(uint8 traitNumber) internal pure returns(string memory) {
        //TBA
        return "";
    }

    //HAIR
    function survivorHairTraitCount() internal pure returns (uint8) { return 44; }
    function survivorHairTrait(uint8 traitNumber) internal pure returns (string memory) {
        return SurvivorMetadata.getHair()[traitNumber - 1];  
    }
    function survivorHairSVG(uint8 traitNumber) internal pure returns(string memory) {
        //TBA
        return "";
    }

    //HEAD
    function survivorHeadTraitCount() internal pure returns (uint8) { return 44; }
    function survivorHeadTrait(uint8 traitNumber) internal pure returns (string memory) {
        return SurvivorMetadata.getHead()[traitNumber - 1];
    }
    function survivorHeadSVG(uint8 traitNumber) internal pure returns(string memory) {
        //TBA
        return "";
    }

    //SHIRTS
    function survivorShirtTraitCount() internal pure returns (uint8) { return 32; }
    function survivorShirtTrait(uint8 traitNumber) internal pure returns (string memory) {
        return SurvivorMetadata.getShirts()[traitNumber - 1];
    }
    function survivorShirtSVG(uint8 traitNumber) internal pure returns(string memory) {
        //TBA
        return "";
    }

    //CHESTARMOR
    function survivorChestArmorTraitCount(uint8 level) internal pure returns (uint8) { 
        if(level == 5) return 13;
        else return 0;
    }
    function survivorChestArmorTrait(uint8 level, uint8 traitNumber) internal pure returns (string memory) {
        if(level == 5) {
            return SurvivorMetadata.getChestArmorLevel5()[traitNumber - 1];
        } else {
            return "None";
        }
    }
    function survivorChestArmorSVG(uint8 level, uint8 traitNumber) internal pure returns(string memory) {
        //TBA
        return "";
    }

    //SHOULDERARMOR
    function survivorShoulderArmorTraitCount(uint8 level) internal pure returns (uint8) { 
        if(level == 4) return 8;
        if(level == 5) return 8;
        else return 0;
    }
    function survivorShoulderArmorTrait(uint8 level, uint8 traitNumber) internal pure returns (string memory) {
        if(level == 4) {
            return SurvivorMetadata.getShoulderArmorLevel4()[traitNumber - 1];
        }  if(level == 5) {
            return SurvivorMetadata.getShoulderArmorLevel5()[traitNumber - 1];
        } else {
            return "None";
        }
    }
    function survivorShoulderArmorSVG(uint8 level, uint8 traitNumber) internal pure returns(string memory) {
        //TBA
        return "";
    }

    //LEGARMOR
    function survivorLegArmorTraitCount(uint8 level) internal pure returns (uint8) { 
        if(level >= 4) return 8;
        else return 0;
    }
    function survivorLegArmorTrait(uint8 level, uint8 traitNumber) internal pure returns (string memory) {
        if(level >= 4) {
            return SurvivorMetadata.getLegArmorLevel4()[traitNumber - 1];
        } else {
            return "None";
        }
    }
    function survivorLegArmorSVG(uint8 level, uint8 traitNumber) internal pure returns(string memory) {
        //TBA
        return "";
    }

    //RIGHTWEAPON
    function survivorRightWeaponTraitCount(uint8 level) internal pure returns (uint8) { 
        if(level == 1) return 8;
        else if(level >= 2) return 11;
        else return 0;
    }
    function survivorRightWeaponTrait(uint8 level, uint8 traitNumber) internal pure returns (string memory) {
        if(level == 1) {
            return SurvivorMetadata.getRightWeaponLevel1()[traitNumber - 1];
        } else if(level >= 2) {
            return SurvivorMetadata.getRightWeaponLevel2()[traitNumber - 1];
        } else {
            return "None";
        }
    }
    function survivorRightWeaponSVG(uint8 level, uint8 traitNumber) internal pure returns(string memory) {
        //TBA
        return "";
    }

    //LEFTWEAPON
    function survivorLeftWeaponTraitCount(uint8 level) internal pure returns (uint8) { 
        if(level == 3) return 9;
        else if(level == 4) return 7;
        else if(level == 5) return 8;
        else return 0;
    }
    function survivorLeftWeaponTrait(uint8 level, uint8 traitNumber) internal pure returns (string memory) {
        if(level == 3) {
            return  SurvivorMetadata.getLeftWeaponLevel3()[traitNumber - 1];
        } else if(level == 4) {
            return  SurvivorMetadata.getLeftWeaponLevel4()[traitNumber - 1];
        }  else if(level == 5) {
            return  SurvivorMetadata.getLeftWeaponLevel5()[traitNumber - 1];
        } else {
            return "None";
        }
    }
    function survivorLeftWeaponSVG(uint8 level, uint8 traitNumber) internal pure returns(string memory) {
        //TBA
        return "";
    }

    function survivorTrait(SurvivorTrait trait, uint8 level, uint8 traitNumber) external pure returns (string memory) {
        if(trait == SurvivorTrait.Shoes) return survivorShoesTrait(traitNumber);
        if(trait == SurvivorTrait.Pants) return survivorPantsTrait(traitNumber);
        if(trait == SurvivorTrait.Body) return survivorBodyTrait(traitNumber);
        if(trait == SurvivorTrait.Beard) return survivorBeardTrait(traitNumber);
        if(trait == SurvivorTrait.Hair) return survivorHairTrait(traitNumber);
        if(trait == SurvivorTrait.Head) return survivorHeadTrait(traitNumber);
        if(trait == SurvivorTrait.Shirt) return survivorShirtTrait(traitNumber);

        if(trait == SurvivorTrait.ChestArmor) return survivorChestArmorTrait(level, traitNumber);
        if(trait == SurvivorTrait.ShoulderArmor) return survivorShoulderArmorTrait(level, traitNumber);
        if(trait == SurvivorTrait.LegArmor) return survivorLegArmorTrait(level, traitNumber);
        if(trait == SurvivorTrait.RightWeapon) return survivorRightWeaponTrait(level, traitNumber);
        if(trait == SurvivorTrait.LeftWeapon) return survivorLeftWeaponTrait(level, traitNumber);
        else return "None";
    }

    function survivorSVG(uint8 level, uint8[] memory traits) external pure returns (bytes memory) {
        string memory shoesSVG = survivorShoesSVG(traits[0]);
        string memory pantsSVG = survivorPantsSVG(traits[1]);
        string memory bodySVG = survivorBodySVG(traits[2]);
        string memory beardSVG = survivorBeardSVG(traits[3]);
        string memory hairSVG = survivorHairSVG(traits[4]);
        string memory headSVG = survivorHeadSVG(traits[5]);
        string memory shirtSVG = survivorShirtSVG(traits[6]);

        string memory chestArmorSVG = survivorChestArmorSVG(level, traits[7]);
        string memory shoulderArmorSVG = survivorShoulderArmorSVG(level, traits[8]);
        string memory LegArmorSVG = survivorLegArmorSVG(level, traits[9]);
        string memory rightWeaponSVG = survivorRightWeaponSVG(level, traits[10]);
        string memory leftWeaponSVG = survivorLeftWeaponSVG(level, traits[11]);

        return bytes(
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 7 8" shape-rendering="crispEdges">',
                shoesSVG,
                pantsSVG,
                bodySVG,
                beardSVG,
                hairSVG,
                headSVG,
                shirtSVG,
                chestArmorSVG,
                shoulderArmorSVG,
                LegArmorSVG,
                rightWeaponSVG,
                leftWeaponSVG,
                '</svg>'
            )
        );
    }
}
// File: metadata/ZombieMetadata.sol


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
// File: base/Base64.sol



pragma solidity ^0.8.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
library Base64 {
    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';
        
        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)
            
            // prepare the lookup table
            let tablePtr := add(table, 1)
            
            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))
            
            // result ptr, jump over length
            let resultPtr := add(result, 32)
            
            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
               dataPtr := add(dataPtr, 3)
               
               // read 3 bytes
               let input := mload(dataPtr)
               
               // write 4 characters
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
               resultPtr := add(resultPtr, 1)
            }
            
            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }
        
        return result;
    }
}
// File: metadata/MetadataFactory.sol







pragma solidity ^0.8.0;

/// @title MetadataFactory
/// @author Elmontos
/// @notice Provides metadata utility functions for creation
library MetadataFactory {
    
    struct nftMetadata {
        uint8 nftType;//0->Zombie 1->Survivor
        uint8[] traits;
        uint8 level;
    //    uint nftCreationTime;
        bool canClaim;
        uint stakedTime;
        uint lastClaimTime;
    }

    function constructNft(uint8 nftType, uint8[] memory traits, uint8 level, bool canClaim, uint stakedTime, uint lastClaimTime) public pure returns(nftMetadata memory) {
        nftMetadata memory nft;
        nft.nftType = nftType;
        nft.traits = traits;
        nft.level = level;
        nft.canClaim = canClaim;
        nft.stakedTime = stakedTime;
        nft.lastClaimTime = lastClaimTime;
        return nft;
    }

    function buildMetadata(MetadataFactory.nftMetadata memory nft, bool survivor) public pure returns(string memory) {

        if(survivor) {
            return string(abi.encodePacked(
                    'data:application/json;base64,', Base64.encode(survivorMetadataBytes(nft))));
        } else {
            return string(abi.encodePacked(
                    'data:application/json;base64,', Base64.encode(zombieMetadataBytes(nft))));
        }
    }

    function levelUpMetadata(MetadataFactory.nftMetadata memory nft,uint nonce) public view returns (nftMetadata memory) {
        
        if(nft.nftType == 0) {
            return createRandomMetadata(nft.level + 1, nft.nftType,nonce);
        } else {
            //So basically the rule is that if an item availability ends at a set level it persists. If the availability continues it re-rolls for non base traits
            return levelUpSurvivor(nft,nonce);
        }
    }

    function levelUpSurvivor(MetadataFactory.nftMetadata memory nft,uint nonce) public view returns (nftMetadata memory) {
        
        //increment level here
        nft.level++;
        uint8[] memory traits = new uint8[](12);

        { //Base traits remain consistent through leveling up
            traits[0] = nft.traits[0];
            traits[1] = nft.traits[1];
            traits[2] = nft.traits[2];
            traits[3] = nft.traits[3];
            traits[4] = nft.traits[4];
            traits[5] = nft.traits[5];
            traits[6] = nft.traits[6];
        }

        {
            //re roll this
            uint8 chestArmorTrait = uint8(Random.range(1, SurvivorFactory.survivorChestArmorTraitCount(nft.level),nonce));
            traits[7] = chestArmorTrait;
            //re roll this
            uint8 shoulderArmorTrait = uint8(Random.range(1, SurvivorFactory.survivorShoulderArmorTraitCount(nft.level),nonce)); 
            traits[8] = shoulderArmorTrait;
            
            //persist - if it's already set
            if(nft.traits[9] == 0) {
                uint8 legArmorTrait = uint8(Random.range(1, SurvivorFactory.survivorLegArmorTraitCount(nft.level),nonce)); 
                traits[9] = legArmorTrait > 0 ? legArmorTrait : nft.traits[9];
            } else traits[9] = nft.traits[9];
    
            //persist - if level is > 2
            if(nft.level <= 2) {
                uint8 rightWeaponTrait = uint8(Random.range(1, SurvivorFactory.survivorRightWeaponTraitCount(nft.level),nonce));
                traits[10] = rightWeaponTrait;
            } else traits[10] = nft.traits[10];

            //re roll this
            uint8 leftWeaponTrait = uint8(Random.range(1, SurvivorFactory.survivorLeftWeaponTraitCount(nft.level),nonce));
            traits[11] = leftWeaponTrait;
        }
        
        return constructNft(nft.nftType, traits, nft.level, nft.canClaim, nft.stakedTime, nft.lastClaimTime);
    }

    function createRandomMetadata(uint8 level, uint8 tokenType,uint nonce) public view returns(nftMetadata memory) {

        uint8[] memory traits;
        bool canClaim;
        uint stakedTime;
        uint lastClaimTime;
        //uint8 nftType = 0;//implement random here between 0 and 1

        if(tokenType == 0) {
            (traits, level, canClaim, stakedTime, lastClaimTime) = createRandomZombie(level,nonce);
        } else {
            (traits, level, canClaim, stakedTime, lastClaimTime) = createRandomSurvivor(level,nonce);
        }

        return constructNft(tokenType, traits, level, canClaim, stakedTime, lastClaimTime);
    }

    function createRandomZombie(uint8 level,uint nonce) public view returns(uint8[] memory, uint8, bool, uint, uint) {
        return (
            randomZombieTraits(level,nonce),
            level,
            false,
            0,
            0
        );
    }

    function randomZombieTraits(uint8 level,uint nonce) public view returns(uint8[] memory) {
        uint8[] memory traits = new uint8[](5);

        uint8 torsoTrait = uint8(Random.range(1, ZombieMetadata.zombieTorsoTraitCount(level),nonce));
        traits[0] = torsoTrait;
        uint8 leftArmTrait = uint8(Random.range(1, ZombieMetadata.zombieLeftArmTraitCount(level),nonce)); 
        traits[1] = leftArmTrait;
        uint8 rightArmTrait = uint8(Random.range(1, ZombieMetadata.zombieRightArmTraitCount(level),nonce));
        traits[2] = rightArmTrait;
        uint8 legsTrait = uint8(Random.range(1, ZombieMetadata.zombieLegsTraitCount(level),nonce)); 
        traits[3] = legsTrait;
        uint8 headTrait = uint8(Random.range(1, ZombieMetadata.zombieHeadTraitCount(level),nonce)); 
        traits[4] = headTrait;

        return traits;
    }

    function createRandomSurvivor(uint8 level,uint nonce) public view returns(uint8[] memory, uint8, bool, uint, uint) {
        return (
            randomSurvivorTraits(level, nonce),
            level,
            false,
            0,
            0
        );
   }

   function randomSurvivorTraits(uint8 level,uint nonce) public view returns(uint8[] memory) {
       uint8[] memory traits = new uint8[](12);

        {
            uint8 shoesTrait = uint8(Random.range(1, SurvivorFactory.survivorShoesTraitCount(),nonce)); 
            traits[0] = shoesTrait;
            uint8 pantsTrait = uint8(Random.range(1, SurvivorFactory.survivorPantsTraitCount(),nonce));
            traits[1] = pantsTrait;
            uint8 bodyTrait = uint8(Random.range(1, SurvivorFactory.survivorBodyTraitCount(),nonce)); 
            traits[2] = bodyTrait;
            uint8 beardTrait = uint8(Random.range(1, SurvivorFactory.survivorBeardTraitCount(),nonce)); 
            traits[3] = beardTrait;
            uint8 hairTrait = uint8(Random.range(1, SurvivorFactory.survivorHairTraitCount(),nonce)); 
            traits[4] = hairTrait;
            uint8 headTrait = uint8(Random.range(1, SurvivorFactory.survivorHeadTraitCount(),nonce)); 
            traits[5] = headTrait;
            uint8 shirtTrait = uint8(Random.range(1, SurvivorFactory.survivorShirtTraitCount(),nonce)); 
            traits[6] = shirtTrait;
        }

        {
            uint8 chestArmorTrait = uint8(Random.range(1, SurvivorFactory.survivorChestArmorTraitCount(level),nonce));
            traits[7] = chestArmorTrait;
            uint8 shoulderArmorTrait = uint8(Random.range(1, SurvivorFactory.survivorShoulderArmorTraitCount(level),nonce)); 
            traits[8] = shoulderArmorTrait;
            uint8 legArmorTrait = uint8(Random.range(1, SurvivorFactory.survivorLegArmorTraitCount(level),nonce)); 
            traits[9] = legArmorTrait;
            uint8 rightWeaponTrait = uint8(Random.range(1, SurvivorFactory.survivorRightWeaponTraitCount(level),nonce));
            traits[10] = rightWeaponTrait;
            uint8 leftWeaponTrait = uint8(Random.range(1, SurvivorFactory.survivorLeftWeaponTraitCount(level),nonce));
            traits[11] = leftWeaponTrait;
        }
        return traits;
   }

   function survivorMetadataBytes(nftMetadata memory survivor) public pure returns(bytes memory) {

        return bytes(
            abi.encodePacked(
                '{"type":"',
                'human',
                '", "level":"',
                survivor.level,
                survivorTraitsMetadata(survivor), //split out otherwise too many local variables for stack to support, stack too deep error
                '", "image": "',
                'data:image/svg+xml;base64,',
                Base64.encode(SurvivorFactory.survivorSVG(survivor.level, survivor.traits)),
                '"}'
            )
        );
    }

    function survivorTraitsMetadata(nftMetadata memory survivor) public pure returns(string memory) {

        string memory traits1;
        string memory traits2;

        {
            traits1 = string(abi.encodePacked(
                '", "shoes":"',
                SurvivorFactory.survivorTrait(SurvivorFactory.SurvivorTrait.Shoes, survivor.level, survivor.traits[0]),
                '", "pants":"',
                SurvivorFactory.survivorTrait(SurvivorFactory.SurvivorTrait.Pants, survivor.level, survivor.traits[1]),
                '", "body":"',
                SurvivorFactory.survivorTrait(SurvivorFactory.SurvivorTrait.Body, survivor.level, survivor.traits[2]),
                '", "beard":"',
                SurvivorFactory.survivorTrait(SurvivorFactory.SurvivorTrait.Beard, survivor.level, survivor.traits[3]),
                '", "hair":"',
                SurvivorFactory.survivorTrait(SurvivorFactory.SurvivorTrait.Hair, survivor.level, survivor.traits[4]),
                '", "head":"',
                SurvivorFactory.survivorTrait(SurvivorFactory.SurvivorTrait.Head, survivor.level, survivor.traits[5])
            ));
        }

        {
            traits2 = string(abi.encodePacked(
                '", "shirt":"',
                SurvivorFactory.survivorTrait(SurvivorFactory.SurvivorTrait.Shirt, survivor.level, survivor.traits[6]),
                '", "chest armor":"',
                SurvivorFactory.survivorTrait(SurvivorFactory.SurvivorTrait.ChestArmor, survivor.level, survivor.traits[7]),
                '", "shoulder armor":"',
                SurvivorFactory.survivorTrait(SurvivorFactory.SurvivorTrait.ShoulderArmor, survivor.level, survivor.traits[8]),
                '", "leg armor":"',
                SurvivorFactory.survivorTrait(SurvivorFactory.SurvivorTrait.LegArmor, survivor.level, survivor.traits[9]),
                '", "right weapon":"',
                SurvivorFactory.survivorTrait(SurvivorFactory.SurvivorTrait.RightWeapon, survivor.level, survivor.traits[10]),
                '", "left weapon":"',
                SurvivorFactory.survivorTrait(SurvivorFactory.SurvivorTrait.LeftWeapon, survivor.level, survivor.traits[11])
            ));
        }

        return string(abi.encodePacked(traits1, traits2));
    }

    function zombieMetadataBytes(nftMetadata memory zombie) public pure returns(bytes memory) {
        return bytes(
            abi.encodePacked(
                '{"type":"',
                'zombie',
                '", "level":"',
                zombie.level,
                '", "torso":"',
                ZombieMetadata.zombieTrait(ZombieMetadata.ZombieTrait.Torso, zombie.level, zombie.traits[0]),
                '", "left arm":"',
                ZombieMetadata.zombieTrait(ZombieMetadata.ZombieTrait.LeftArm, zombie.level, zombie.traits[1]),
                '", "right arm":"',
                ZombieMetadata.zombieTrait(ZombieMetadata.ZombieTrait.RightArm, zombie.level, zombie.traits[2]),
                '", "legs":"',
                ZombieMetadata.zombieTrait(ZombieMetadata.ZombieTrait.Legs, zombie.level, zombie.traits[3]),
                '", "head":"',
                ZombieMetadata.zombieTrait(ZombieMetadata.ZombieTrait.Head, zombie.level, zombie.traits[4]),
                '", "image": "',
                'data:image/svg+xml;base64,',
                Base64.encode(ZombieMetadata.zombieSVG(zombie.level, zombie.traits)),
                '"}'
            )
        );
    }
    
}
// File: TestContracts/nftMetadata.sol

pragma solidity ^0.8.0;





contract metadata is Ownable{

    MetadataFactory.nftMetadata[] nfts;

    uint nonce;

    address nftContract;

    constructor(address _nftFactory){
        nftContract = _nftFactory;
    }

    modifier onlyNFTFactory{
        require(msg.sender == nftContract,"Not NFT factory");
        _;
    }

    function setContracts(address _nftFactory) external onlyOwner{
        nftContract = _nftFactory;
    }

    function getToken(uint256 _tokenId) external view returns(uint8, uint8, bool, uint,uint) {
        _tokenId--;
        return (
        nfts[_tokenId].nftType,
        nfts[_tokenId].level,
        nfts[_tokenId].canClaim,
        nfts[_tokenId].stakedTime,
        nfts[_tokenId].lastClaimTime) ;
    }

    function addMetadata(uint8 level,uint8 tokenType) external onlyNFTFactory{
        nonce++;
        nfts.push(MetadataFactory.createRandomMetadata(level, tokenType,nonce));
    }

    function getTokenURI(uint tokenId) external view returns (string memory)
    {
        MetadataFactory.nftMetadata memory nft = nfts[tokenId-1];
        return MetadataFactory.buildMetadata(nft, nft.nftType==1);
    }

    function changeNft(uint tokenID, uint8 nftType, uint8 level, bool canClaim, uint stakedTime, uint lastClaimTime) external onlyNFTFactory {
            MetadataFactory.nftMetadata memory original = nfts[tokenID-1];
            nonce++;
            if(original.level != level) { //level up if level changes, level will only ever go up 1 at a time
                original = MetadataFactory.levelUpMetadata(original,nonce);
            } 
            
            if(original.nftType != nftType) { //only recreate metadata if type changes (steal)
                uint8[] memory traits;
                if(nftType == 0) {
                    (traits,,,,) = MetadataFactory.createRandomZombie(level,nonce);
                } else {
                    (traits,,,,) = MetadataFactory.createRandomSurvivor(level,nonce);
                }
                original = MetadataFactory.constructNft(nftType, traits, level, canClaim, stakedTime, lastClaimTime);
            } else {
                //Level and type have not changed, change everything else
                original.canClaim = canClaim;
                original.stakedTime = stakedTime;
                original.lastClaimTime = lastClaimTime;
            }
        nfts[tokenID - 1] = original;
    }
}