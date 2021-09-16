/**
 *Submitted for verification at polygonscan.com on 2021-09-16
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract ForgeQuestItems {

    struct Item {
        uint256 id;
        uint256 blades;
        uint256 handles;
        uint256 plates;
        string name;
        string description;
    }
    
    function getQuestById(uint256 _id) public pure returns(Item memory item) {
        if (_id == 1) {
            return armor();
        } else if (_id == 2) {
            return axe();
        } else if (_id == 3) {
            return claw();
        } else if (_id == 4) {
            return glaive();
        } else if (_id == 5) {
            return mace();
        } else if (_id == 6) {
            return staff();
        } else if (_id == 7) {
            return shield();
        } else if (_id == 8) {
            return spear();
        } else if (_id == 9) {
            return shovel();
        } else if (_id == 10) {
            return sword();
        }
    }

    function armor() public pure returns (Item memory item) {
        item.id = 1;
        item.name = "Armor";
        item.description = "";
        item.blades = 1;
        item.handles = 0;
        item.plates = 2;
    }

    function axe() public pure returns (Item memory item) {
        item.id = 2;
        item.name = "Axe";
        item.description = "";
        item.blades = 1;
        item.handles = 1;
        item.plates = 1;
    }

    function claw() public pure returns (Item memory item) {
        item.id = 3;
        item.name = "Claw";
        item.description = "";
        item.blades = 3;
        item.handles = 0;
        item.plates = 0;
    }

    function glaive() public pure returns (Item memory item) {
        item.id = 4;
        item.name = "Glaive";
        item.description = "";
        item.blades = 2;
        item.handles = 0;
        item.plates = 1;
    }

    function mace() public pure returns (Item memory item) {
        item.id = 5;
        item.name = "Mace";
        item.description = "";
        item.blades = 0;
        item.handles = 1;
        item.plates = 2;
    }

    function staff() public pure returns (Item memory item) {
        item.id = 6;
        item.name = "Staff";
        item.description = "";
        item.blades = 0;
        item.handles = 3;
        item.plates = 0;
    }

    function shield() public pure returns (Item memory item) {
        item.id = 7;
        item.name = "Shield";
        item.description = "";
        item.blades = 0;
        item.handles = 0;
        item.plates = 3;
    }

    function spear() public pure returns (Item memory item) {
        item.id = 8;
        item.name = "Spear";
        item.description = "";
        item.blades = 1;
        item.handles = 2;
        item.plates = 0;
    }

    function shovel() public pure returns (Item memory item) {
        item.id = 9;
        item.name = "Shovel";
        item.description = "";
        item.blades = 0;
        item.handles = 2;
        item.plates = 1;
    }

    function sword() public pure returns (Item memory item) {
        item.id = 10;
        item.name = "Sword";
        item.description = "";
        item.blades = 2;
        item.handles = 1;
        item.plates = 0;
    }
}