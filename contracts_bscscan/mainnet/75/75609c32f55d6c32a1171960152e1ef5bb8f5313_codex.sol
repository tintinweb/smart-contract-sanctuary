/**
 *Submitted for verification at BscScan.com on 2021-11-22
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract codex {
    string constant public index = "Items";
    string constant public class = "Goods";

    function item_by_id(uint _id) public pure returns(
        uint id,
        uint cost,
        uint weight,
        string memory name,
        string memory description
    ) {
        if (_id == 1) {
            return caltrops();
        } else if (_id == 2) {
            return candle();
        } else if (_id == 3) {
            return chain();
        } else if (_id == 4) {
            return crowbar();
        } else if (_id == 5) {
            return flint_and_steel();
        } else if (_id == 6) {
            return grappling_hook();
        } else if (_id == 7) {
            return hammer();
        } else if (_id == 8) {
            return ink();
        } else if (_id == 9) {
            return jug_clay();
        } else if (_id == 10) {
            return lamp_common();
        } else if (_id == 11) {
            return lantern_bullseye();
        } else if (_id == 12) {
            return lantern_hooded();
        } else if (_id == 13) {
            return lock_very_simple();
        } else if (_id == 14) {
            return lock_average();
        } else if (_id == 15) {
            return lock_good();
        } else if (_id == 16) {
            return lock_amazing();
        } else if (_id == 17) {
            return manacles();
        } else if (_id == 18) {
            return manacles_masterwork();
        } else if (_id == 19) {
            return oil();
        } else if (_id == 20) {
            return rope_hempen();
        } else if (_id == 21) {
            return rope_silk();
        } else if (_id == 22) {
            return spyglass();
        } else if (_id == 23) {
            return torch();
        } else if (_id == 24) {
            return vial();
        }
    }

    function caltrops() public pure returns (
        uint id,
        uint cost,
        uint weight,
        string memory name,
        string memory description
    ) {
        id = 1;
        name = "Caltrops";
        cost = 1e18;
        weight = 2;
        description = "A caltrop is a four-pronged iron spike crafted so that one prong faces up no matter how the caltrop comes to rest. You scatter caltrops on the ground in the hope that your enemies step on them or are at least forced to slow down to avoid them. One 2-pound bag of caltrops covers an area 5 feet square.";
    }

    function candle() public pure returns (
        uint id,
        uint cost,
        uint weight,
        string memory name,
        string memory description
    ) {
        id = 2;
        name = "Candle";
        cost = 1e16;
        weight = 0;
        description = "A candle dimly illuminates a 5-foot radius and burns for 1 hour.";
    }

    function chain() public pure returns (
        uint id,
        uint cost,
        uint weight,
        string memory name,
        string memory description
    ) {
        id = 3;
        name = "Chain";
        cost = 30e18;
        weight = 2;
        description = "Chain has hardness 10 and 5 hit points. It can be burst with a DC 26 Strength check.";
    }

    function crowbar() public pure returns (
        uint id,
        uint cost,
        uint weight,
        string memory name,
        string memory description
    ) {
        id = 4;
        name = "Crowbar";
        cost = 2e18;
        weight = 5;
        description = "A crowbar grants a +2 circumstance bonus on Strength checks made for such purposes. If used in combat, treat a crowbar as a one-handed improvised weapon that deals bludgeoning damage equal to that of a club of its size.";
    }

    function flint_and_steel() public pure returns (
        uint id,
        uint cost,
        uint weight,
        string memory name,
        string memory description
    ) {
        id = 5;
        name = "Flint and Steel";
        cost = 1e18;
        weight = 0;
        description = "Lighting a torch with flint and steel is a full-round action, and lighting any other fire with them takes at least that long.";
    }

    function grappling_hook() public pure returns (
        uint id,
        uint cost,
        uint weight,
        string memory name,
        string memory description
    ) {
        id = 6;
        name = "Grappling Hook";
        cost = 1e18;
        weight = 4;
        description = "Throwing a grappling hook successfully requires a Use Rope check (DC 10, +2 per 10 feet of distance thrown).";
    }

    function hammer() public pure returns (
        uint id,
        uint cost,
        uint weight,
        string memory name,
        string memory description
    ) {
        id = 7;
        name = "Hammer";
        cost = 5e17;
        weight = 2;
        description = "If a hammer is used in combat, treat it as a one-handed improvised weapon that deals bludgeoning damage equal to that of a spiked gauntlet of its size.";
    }

    function ink() public pure returns (
        uint id,
        uint cost,
        uint weight,
        string memory name,
        string memory description
    ) {
        id = 8;
        name = "Ink";
        cost = 8e18;
        weight = 0;
        description = "This is black ink. You can buy ink in other colors, but it costs twice as much.";
    }

    function jug_clay() public pure returns (
        uint id,
        uint cost,
        uint weight,
        string memory name,
        string memory description
    ) {
        id = 9;
        name = "Jug, Clay";
        cost = 3e16;
        weight = 9;
        description = "This basic ceramic jug is fitted with a stopper and holds 1 gallon of liquid.";
    }

    function lamp_common() public pure returns (
        uint id,
        uint cost,
        uint weight,
        string memory name,
        string memory description
    ) {
        id = 10;
        name = "Lamp, Common";
        cost = 1e17;
        weight = 1;
        description = "A lamp clearly illuminates a 15-foot radius, provides shadowy illumination out to a 30-foot radius, and burns for 6 hours on a pint of oil. You can carry a lamp in one hand.";
    }

    function lantern_bullseye() public pure returns (
        uint id,
        uint cost,
        uint weight,
        string memory name,
        string memory description
    ) {
        id = 11;
        name = "Lantern, Bullseye";
        cost = 12e18;
        weight = 3;
        description = "A bullseye lantern provides clear illumination in a 60-foot cone and shadowy illumination in a 120-foot cone. It burns for 6 hours on a pint of oil. You can carry a bullseye lantern in one hand.";
    }

    function lantern_hooded() public pure returns (
        uint id,
        uint cost,
        uint weight,
        string memory name,
        string memory description
    ) {
        id = 12;
        name = "Lantern, Hooded";
        cost = 7e18;
        weight = 2;
        description = "A hooded lantern clearly illuminates a 30-foot radius and provides shadowy illumination in a 60-foot radius. It burns for 6 hours on a pint of oil. You can carry a hooded lantern in one hand.";
    }

    function lock_very_simple() public pure returns (
        uint id,
        uint cost,
        uint weight,
        string memory name,
        string memory description
    ) {
        id = 13;
        name = "Lock (very simple)";
        cost = 20e18;
        weight = 1;
        description = "The DC to open a lock with the Open Lock skill depends on the locks quality: simple (DC 20), average (DC 25), good (DC 30), or superior (DC 40).";
    }

    function lock_average() public pure returns (
        uint id,
        uint cost,
        uint weight,
        string memory name,
        string memory description
    ) {
        id = 14;
        name = "Lock (average)";
        cost = 40e18;
        weight = 1;
        description = "The DC to open a lock with the Open Lock skill depends on the locks quality: simple (DC 20), average (DC 25), good (DC 30), or superior (DC 40).";
    }

    function lock_good() public pure returns (
        uint id,
        uint cost,
        uint weight,
        string memory name,
        string memory description
    ) {
        id = 15;
        name = "Lock (good)";
        cost = 80e18;
        weight = 1;
        description = "The DC to open a lock with the Open Lock skill depends on the locks quality: simple (DC 20), average (DC 25), good (DC 30), or superior (DC 40).";
    }

    function lock_amazing() public pure returns (
        uint id,
        uint cost,
        uint weight,
        string memory name,
        string memory description
    ) {
        id = 16;
        name = "Lock (amazing)";
        cost = 150e18;
        weight = 1;
        description = "The DC to open a lock with the Open Lock skill depends on the locks quality: simple (DC 20), average (DC 25), good (DC 30), or superior (DC 40).";
    }

    function manacles() public pure returns (
        uint id,
        uint cost,
        uint weight,
        string memory name,
        string memory description
    ) {
        id = 17;
        name = "Manacles";
        cost = 15e18;
        weight = 2;
        description = "Manacles can bind a Medium creature. A manacled creature can use the Escape Artist skill to slip free (DC 30, or DC 35 for masterwork manacles). Breaking the manacles requires a Strength check (DC 26, or DC 28 for masterwork manacles). Manacles have hardness 10 and 10 hit points";
    }

    function manacles_masterwork() public pure returns (
        uint id,
        uint cost,
        uint weight,
        string memory name,
        string memory description
    ) {
        id = 18;
        name = "Manacles, masterwork";
        cost = 50e18;
        weight = 2;
        description = "Manacles can bind a Medium creature. A manacled creature can use the Escape Artist skill to slip free (DC 30, or DC 35 for masterwork manacles). Breaking the manacles requires a Strength check (DC 26, or DC 28 for masterwork manacles). Manacles have hardness 10 and 10 hit points";
    }

    function oil() public pure returns (
        uint id,
        uint cost,
        uint weight,
        string memory name,
        string memory description
    ) {
        id = 19;
        name = "Oil";
        cost = 1e17;
        weight = 1;
        description = "A pint of oil burns for 6 hours in a lantern. You can use a flask of oil as a splash weapon. Use the rules for alchemists fire, except that it takes a full round action to prepare a flask with a fuse. Once it is thrown, there is a 50% chance of the flask igniting successfully. You can pour a pint of oil on the ground to cover an area 5 feet square, provided that the surface is smooth. If lit, the oil burns for 2 rounds and deals 1d3 points of fire damage to each creature in the area.";
    }

    function rope_hempen() public pure returns (
        uint id,
        uint cost,
        uint weight,
        string memory name,
        string memory description
    ) {
        id = 20;
        name = "Rope, Hempen";
        cost = 1e18;
        weight = 10;
        description = "This rope has 2 hit points and can be burst with a DC 23 Strength check.";
    }

    function rope_silk() public pure returns (
        uint id,
        uint cost,
        uint weight,
        string memory name,
        string memory description
    ) {
        id = 21;
        name = "Rope, Silk";
        cost = 10e18;
        weight = 5;
        description = "This rope has 4 hit points and can be burst with a DC 24 Strength check. It is so supple that it provides a +2 circumstance bonus on Use Rope checks.";
    }

    function spyglass() public pure returns (
        uint id,
        uint cost,
        uint weight,
        string memory name,
        string memory description
    ) {
        id = 22;
        name = "Spyglass";
        cost = 1000e18;
        weight = 1;
        description = "Objects viewed through a spyglass are magnified to twice their size.";
    }

    function torch() public pure returns (
        uint id,
        uint cost,
        uint weight,
        string memory name,
        string memory description
    ) {
        id = 23;
        name = "Torch";
        cost = 1e16;
        weight = 1;
        description = "A torch burns for 1 hour, clearly illuminating a 20-foot radius and providing shadowy illumination out to a 40-foot radius. If a torch is used in combat, treat it as a one-handed improvised weapon that deals bludgeoning damage equal to that of a gauntlet of its size, plus 1 point of fire damage.";
    }

    function vial() public pure returns (
        uint id,
        uint cost,
        uint weight,
        string memory name,
        string memory description
    ) {
        id = 24;
        name = "Vial";
        cost = 1e18;
        weight = 1;
        description = "A vial holds 1 ounce of liquid. The stoppered container usually is no more than 1 inch wide and 3 inches high.";
    }
}