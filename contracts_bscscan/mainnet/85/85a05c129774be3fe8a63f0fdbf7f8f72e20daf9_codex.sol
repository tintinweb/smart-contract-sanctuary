/**
 *Submitted for verification at BscScan.com on 2021-11-22
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract codex {
    string constant public index = "Items";
    string constant public class = "Weapons";
    
    function get_proficiency_by_id(uint _id) public pure returns (string memory description) {
        if (_id == 1) {
            return "Simple";
        } else if (_id == 2) {
            return "Martial";
        } else if (_id == 3) {
            return "Exotic";
        }
    }
    
    function get_encumbrance_by_id(uint _id) public pure returns (string memory description) {
        if (_id == 1) {
            return "Unarmed";
        } else if (_id == 2) {
            return "Light Melee Weapons";
        } else if (_id == 3) {
            return "One-Handed Melee Weapons";
        } else if (_id == 4) {
            return "Two-Handed Melee Weapons";
        } else if (_id == 5) {
            return "Ranged Weapons";
        }
    }
    
    function get_damage_type_by_id(uint _id) public pure returns (string memory description) {
        if (_id == 1) {
            return "Bludgeoning";
        } else if (_id == 2) {
            return "Piercing";
        } else if (_id == 3) {
            return "Slashing";
        }
    }
    
    struct weapon {
        uint id;
        uint cost;
        uint proficiency;
        uint encumbrance;
        uint damage_type;
        uint weight;
        uint damage;
        uint critical;
        int critical_modifier;
        uint range_increment;
        string name;
        string description;
    }

    function item_by_id(uint _id) public pure returns(weapon memory _weapon) {
        if (_id == 1) {
            return gauntlet();
        } else if (_id == 2) {
            return dagger();
        } else if (_id == 3) {
            return gauntlet_spiked();
        } else if (_id == 4) {
            return mace_light();
        } else if (_id == 5) {
            return sickle();
        } else if (_id == 6) {
            return club();
        } else if (_id == 7) {
            return mace_heavy();
        } else if (_id == 8) {
            return morningstar();
        } else if (_id == 9) {
            return shortspear();
        } else if (_id == 10) {
            return longspear();
        } else if (_id == 11) {
            return quarterstaff();
        } else if (_id == 12) {
            return spear();
        } else if (_id == 13) {
            return crossbow_heavy();
        } else if (_id == 14) {
            return crossbow_light();
        } else if (_id == 15) {
            return dart();
        } else if (_id == 16) {
            return javelin();
        } else if (_id == 17) {
            return sling();
        } else if (_id == 18) {
            return axe();
        } else if (_id == 19) {
            return hammer_light();
        } else if (_id == 20) {
            return handaxe();
        } else if (_id == 21) {
            return kukri();
        } else if (_id == 22) {
            return pick_light();
        } else if (_id == 23) {
            return sap();
        } else if (_id == 24) {
            return sword_short();
        } else if (_id == 25) {
            return battleaxe();
        } else if (_id == 26) {
            return flail();
        } else if (_id == 27) {
            return longsword();
        } else if (_id == 28) {
            return pick_heavy();
        } else if (_id == 29) {
            return rapier();
        } else if (_id == 30) {
            return scimitar();
        } else if (_id == 31) {
            return trident();
        } else if (_id == 32) {
            return warhammer();
        } else if (_id == 33) {
            return falchion();
        } else if (_id == 34) {
            return glaive();
        } else if (_id == 35) {
            return greataxe();
        } else if (_id == 36) {
            return greatclub();
        } else if (_id == 37) {
            return flail_heavy();
        } else if (_id == 38) {
            return greatsword();
        } else if (_id == 39) {
            return guisarme();
        } else if (_id == 40) {
            return halberd();
        } else if (_id == 41) {
            return lance();
        } else if (_id == 42) {
            return ranseur();
        } else if (_id == 43) {
            return scythe();
        } else if (_id == 44) {
            return longbow();
        } else if (_id == 45) {
            return longbow_composite();
        } else if (_id == 46) {
            return shortbow();
        } else if (_id == 47) {
            return shortbow_composite();
        } else if (_id == 48) {
            return kama();
        } else if (_id == 49) {
            return nunchaku();
        } else if (_id == 50) {
            return sai();
        } else if (_id == 51) {
            return siangham();
        } else if (_id == 52) {
            return sword_bastard();
        } else if (_id == 53) {
            return waraxe_dwarven();
        } else if (_id == 54) {
            return axe_orc_double();
        } else if (_id == 55) {
            return chain_spiked();
        } else if (_id == 56) {
            return flail_dire();
        } else if (_id == 57) {
            return crossbow_hand();
        } else if (_id == 58) {
            return crossbow_repeating_heavy();
        } else if (_id == 59) {
            return crossbow_repeating_light();
        }
    }

    function gauntlet() public pure returns (weapon memory _weapon) {
        _weapon.id = 1;
        _weapon.name = "Gauntlet";
        _weapon.cost = 2e18;
        _weapon.proficiency = 1;
        _weapon.encumbrance = 1;
        _weapon.damage_type = 1;
        _weapon.weight = 1;
        _weapon.damage = 3;
        _weapon.critical = 2;
        _weapon.critical_modifier = 0;
        _weapon.range_increment = 0;
        _weapon.description = "This metal glove lets you deal lethal damage rather than nonlethal damage with unarmed strikes. A strike with a gauntlet is otherwise considered an unarmed attack. The cost and weight given are for a single gauntlet. Medium and heavy armors (except breastplate) come with gauntlets.";
    }

    function dagger() public pure returns (weapon memory _weapon) {
        _weapon.id = 2;
        _weapon.name = "Dagger";
        _weapon.cost = 2e18;
        _weapon.proficiency = 1;
        _weapon.encumbrance = 2;
        _weapon.damage_type = 2;
        _weapon.weight = 1;
        _weapon.damage = 4;
        _weapon.critical = 2;
        _weapon.critical_modifier = -1;
        _weapon.range_increment = 0;
        _weapon.description = "You get a +2 bonus on Sleight of Hand checks made to conceal a dagger on your body (see the Sleight of Hand skill).";
    }

    function gauntlet_spiked() public pure returns (weapon memory _weapon) {
        _weapon.id = 3;
        _weapon.name = "Gauntlet, spiked";
        _weapon.cost = 5e18;
        _weapon.proficiency = 1;
        _weapon.encumbrance = 2;
        _weapon.damage_type = 2;
        _weapon.weight = 1;
        _weapon.damage = 4;
        _weapon.critical = 2;
        _weapon.critical_modifier = 0;
        _weapon.range_increment = 0;
        _weapon.description = "Your opponent cannot use a disarm action to disarm you of spiked gauntlets. The cost and weight given are for a single gauntlet. An attack with a spiked gauntlet is considered an armed attack.";
    }

    function mace_light() public pure returns (weapon memory _weapon) {
        _weapon.id = 4;
        _weapon.name = "Mace, light";
        _weapon.cost = 5e18;
        _weapon.proficiency = 1;
        _weapon.encumbrance = 2;
        _weapon.damage_type = 1;
        _weapon.weight = 4;
        _weapon.damage = 6;
        _weapon.critical = 2;
        _weapon.critical_modifier = 0;
        _weapon.range_increment = 0;
        _weapon.description = "";
    }

    function sickle() public pure returns (weapon memory _weapon) {
        _weapon.id = 5;
        _weapon.name = "Sickle";
        _weapon.cost = 6e18;
        _weapon.proficiency = 1;
        _weapon.encumbrance = 2;
        _weapon.damage_type = 3;
        _weapon.weight = 2;
        _weapon.damage = 6;
        _weapon.critical = 2;
        _weapon.critical_modifier = 0;
        _weapon.range_increment = 0;
        _weapon.description = "A sickle can be used to make trip attacks. If you are tripped during your own trip attempt, you can drop the sickle to avoid being tripped.";
    }

    function club() public pure returns (weapon memory _weapon) {
        _weapon.id = 6;
        _weapon.name = "Club";
        _weapon.cost = 1e17;
        _weapon.proficiency = 1;
        _weapon.encumbrance = 3;
        _weapon.damage_type = 1;
        _weapon.weight = 3;
        _weapon.damage = 6;
        _weapon.critical = 2;
        _weapon.critical_modifier = 0;
        _weapon.range_increment = 0;
        _weapon.description = "";
    }

    function mace_heavy() public pure returns (weapon memory _weapon) {
        _weapon.id = 7;
        _weapon.name = "Mace, heavy";
        _weapon.cost = 12e18;
        _weapon.proficiency = 1;
        _weapon.encumbrance = 3;
        _weapon.damage_type = 1;
        _weapon.weight = 8;
        _weapon.damage = 8;
        _weapon.critical = 2;
        _weapon.critical_modifier = 0;
        _weapon.range_increment = 0;
        _weapon.description = "";
    }

    function morningstar() public pure returns (weapon memory _weapon) {
        _weapon.id = 8;
        _weapon.name = "Morningstar";
        _weapon.cost = 8e18;
        _weapon.proficiency = 1;
        _weapon.encumbrance = 3;
        _weapon.damage_type = 1;
        _weapon.weight = 6;
        _weapon.damage = 8;
        _weapon.critical = 2;
        _weapon.critical_modifier = 0;
        _weapon.range_increment = 0;
        _weapon.description = "";
    }

    function shortspear() public pure returns (weapon memory _weapon) {
        _weapon.id = 9;
        _weapon.name = "Shortspear";
        _weapon.cost = 1e18;
        _weapon.proficiency = 1;
        _weapon.encumbrance = 3;
        _weapon.damage_type = 2;
        _weapon.weight = 3;
        _weapon.damage = 6;
        _weapon.critical = 2;
        _weapon.critical_modifier = 0;
        _weapon.range_increment = 0;
        _weapon.description = "A shortspear is small enough to wield one-handed. It may also be thrown.";
    }

    function longspear() public pure returns (weapon memory _weapon) {
        _weapon.id = 10;
        _weapon.name = "Longspear";
        _weapon.cost = 5e18;
        _weapon.proficiency = 1;
        _weapon.encumbrance = 4;
        _weapon.damage_type = 2;
        _weapon.weight = 9;
        _weapon.damage = 8;
        _weapon.critical = 3;
        _weapon.critical_modifier = 0;
        _weapon.range_increment = 0;
        _weapon.description = "A longspear has reach. You can strike opponents 10 feet away with it, but you cant use it against an adjacent foe. If you use a ready action to set a longspear against a charge, you deal double damage on a successful hit against a charging character.";
    }

    function quarterstaff() public pure returns (weapon memory _weapon) {
        _weapon.id = 11;
        _weapon.name = "Quarterstaff";
        _weapon.cost = 1e17;
        _weapon.proficiency = 1;
        _weapon.encumbrance = 4;
        _weapon.damage_type = 1;
        _weapon.weight = 4;
        _weapon.damage = 6;
        _weapon.critical = 2;
        _weapon.critical_modifier = 0;
        _weapon.range_increment = 0;
        _weapon.description = "A quarterstaff is a double weapon. You can fight with it as if fighting with two weapons, but if you do, you incur all the normal attack penalties associated with fighting with two weapons, just as if you were using a one-handed weapon and a light weapon. A creature wielding a quarterstaff in one hand cant use it as a double weapon-only one end of the weapon can be used in any given round.";
    }

    function spear() public pure returns (weapon memory _weapon) {
        _weapon.id = 12;
        _weapon.name = "Spear";
        _weapon.cost = 2e18;
        _weapon.proficiency = 1;
        _weapon.encumbrance = 4;
        _weapon.damage_type = 2;
        _weapon.weight = 6;
        _weapon.damage = 8;
        _weapon.critical = 3;
        _weapon.critical_modifier = 0;
        _weapon.range_increment = 0;
        _weapon.description = "";
    }

    function crossbow_heavy() public pure returns (weapon memory _weapon) {
        _weapon.id = 13;
        _weapon.name = "Crossbow, heavy";
        _weapon.cost = 50e18;
        _weapon.proficiency = 1;
        _weapon.encumbrance = 5;
        _weapon.damage_type = 2;
        _weapon.weight = 8;
        _weapon.damage = 10;
        _weapon.critical = 2;
        _weapon.critical_modifier = -1;
        _weapon.range_increment = 120;
        _weapon.description = "You draw a heavy crossbow back by turning a small winch. Loading a heavy crossbow is a full-round action that provokes attacks of opportunity.";
    }

    function crossbow_light() public pure returns (weapon memory _weapon) {
        _weapon.id = 14;
        _weapon.name = "Crossbow, light";
        _weapon.cost = 35e18;
        _weapon.proficiency = 1;
        _weapon.encumbrance = 5;
        _weapon.damage_type = 2;
        _weapon.weight = 4;
        _weapon.damage = 8;
        _weapon.critical = 2;
        _weapon.critical_modifier = -1;
        _weapon.range_increment = 80;
        _weapon.description = "You draw a light crossbow back by pulling a lever. Loading a light crossbow is a move action that provokes attacks of opportunity.";
    }

    function dart() public pure returns (weapon memory _weapon) {
        _weapon.id = 15;
        _weapon.name = "Dart";
        _weapon.cost = 5e17;
        _weapon.proficiency = 1;
        _weapon.encumbrance = 5;
        _weapon.damage_type = 2;
        _weapon.weight = 1;
        _weapon.damage = 4;
        _weapon.critical = 2;
        _weapon.critical_modifier = 0;
        _weapon.range_increment = 20;
        _weapon.description = "";
    }

    function javelin() public pure returns (weapon memory _weapon) {
        _weapon.id = 16;
        _weapon.name = "Javelin";
        _weapon.cost = 1e18;
        _weapon.proficiency = 1;
        _weapon.encumbrance = 5;
        _weapon.damage_type = 2;
        _weapon.weight = 2;
        _weapon.damage = 6;
        _weapon.critical = 2;
        _weapon.critical_modifier = 0;
        _weapon.range_increment = 30;
        _weapon.description = "Since it is not designed for melee, you are treated as nonproficient with it and take a -4 penalty on attack rolls if you use a javelin as a melee weapon.";
    }

    function sling() public pure returns (weapon memory _weapon) {
        _weapon.id = 17;
        _weapon.name = "Sling";
        _weapon.cost = 1e17;
        _weapon.proficiency = 1;
        _weapon.encumbrance = 5;
        _weapon.damage_type = 1;
        _weapon.weight = 0;
        _weapon.damage = 4;
        _weapon.critical = 2;
        _weapon.critical_modifier = 0;
        _weapon.range_increment = 50;
        _weapon.description = "Your Strength modifier applies to damage rolls when you use a sling, just as it does for thrown weapons. You can fire, but not load, a sling with one hand. Loading a sling is a move action that requires two hands and provokes attacks of opportunity.";
    }

    function axe() public pure returns (weapon memory _weapon) {
        _weapon.id = 18;
        _weapon.name = "Axe";
        _weapon.cost = 8e18;
        _weapon.proficiency = 2;
        _weapon.encumbrance = 2;
        _weapon.damage_type = 3;
        _weapon.weight = 2;
        _weapon.damage = 6;
        _weapon.critical = 2;
        _weapon.critical_modifier = 0;
        _weapon.range_increment = 0;
        _weapon.description = "";
    }

    function hammer_light() public pure returns (weapon memory _weapon) {
        _weapon.id = 19;
        _weapon.name = "Hammer, light";
        _weapon.cost = 1e18;
        _weapon.proficiency = 2;
        _weapon.encumbrance = 2;
        _weapon.damage_type = 1;
        _weapon.weight = 2;
        _weapon.damage = 4;
        _weapon.critical = 2;
        _weapon.critical_modifier = 0;
        _weapon.range_increment = 0;
        _weapon.description = "";
    }

    function handaxe() public pure returns (weapon memory _weapon) {
        _weapon.id = 20;
        _weapon.name = "Handaxe";
        _weapon.cost = 6e18;
        _weapon.proficiency = 2;
        _weapon.encumbrance = 2;
        _weapon.damage_type = 3;
        _weapon.weight = 3;
        _weapon.damage = 6;
        _weapon.critical = 3;
        _weapon.critical_modifier = 0;
        _weapon.range_increment = 0;
        _weapon.description = "";
    }

    function kukri() public pure returns (weapon memory _weapon) {
        _weapon.id = 21;
        _weapon.name = "Kukri";
        _weapon.cost = 8e18;
        _weapon.proficiency = 2;
        _weapon.encumbrance = 2;
        _weapon.damage_type = 3;
        _weapon.weight = 2;
        _weapon.damage = 4;
        _weapon.critical = 2;
        _weapon.critical_modifier = -2;
        _weapon.range_increment = 0;
        _weapon.description = "";
    }

    function pick_light() public pure returns (weapon memory _weapon) {
        _weapon.id = 22;
        _weapon.name = "Pick, light";
        _weapon.cost = 4e18;
        _weapon.proficiency = 2;
        _weapon.encumbrance = 2;
        _weapon.damage_type = 2;
        _weapon.weight = 3;
        _weapon.damage = 4;
        _weapon.critical = 4;
        _weapon.critical_modifier = 0;
        _weapon.range_increment = 0;
        _weapon.description = "";
    }

    function sap() public pure returns (weapon memory _weapon) {
        _weapon.id = 23;
        _weapon.name = "Sap";
        _weapon.cost = 1e18;
        _weapon.proficiency = 2;
        _weapon.encumbrance = 2;
        _weapon.damage_type = 1;
        _weapon.weight = 2;
        _weapon.damage = 6;
        _weapon.critical = 2;
        _weapon.critical_modifier = 0;
        _weapon.range_increment = 0;
        _weapon.description = "";
    }

    function sword_short() public pure returns (weapon memory _weapon) {
        _weapon.id = 24;
        _weapon.name = "Sword, short";
        _weapon.cost = 10e18;
        _weapon.proficiency = 2;
        _weapon.encumbrance = 2;
        _weapon.damage_type = 2;
        _weapon.weight = 2;
        _weapon.damage = 6;
        _weapon.critical = 2;
        _weapon.critical_modifier = -1;
        _weapon.range_increment = 0;
        _weapon.description = "";
    }

    function battleaxe() public pure returns (weapon memory _weapon) {
        _weapon.id = 25;
        _weapon.name = "Battleaxe";
        _weapon.cost = 10e18;
        _weapon.proficiency = 2;
        _weapon.encumbrance = 3;
        _weapon.damage_type = 3;
        _weapon.weight = 6;
        _weapon.damage = 8;
        _weapon.critical = 3;
        _weapon.critical_modifier = 0;
        _weapon.range_increment = 0;
        _weapon.description = "";
    }

    function flail() public pure returns (weapon memory _weapon) {
        _weapon.id = 26;
        _weapon.name = "Flail";
        _weapon.cost = 8e18;
        _weapon.proficiency = 2;
        _weapon.encumbrance = 3;
        _weapon.damage_type = 1;
        _weapon.weight = 5;
        _weapon.damage = 8;
        _weapon.critical = 2;
        _weapon.critical_modifier = 0;
        _weapon.range_increment = 0;
        _weapon.description = "With a flail, you get a +2 bonus on opposed attack rolls made to disarm an enemy (including the roll to avoid being disarmed if such an attempt fails).";
    }

    function longsword() public pure returns (weapon memory _weapon) {
        _weapon.id = 27;
        _weapon.name = "Longsword";
        _weapon.cost = 15e18;
        _weapon.proficiency = 2;
        _weapon.encumbrance = 3;
        _weapon.damage_type = 3;
        _weapon.weight = 4;
        _weapon.damage = 8;
        _weapon.critical = 2;
        _weapon.critical_modifier = -1;
        _weapon.range_increment = 0;
        _weapon.description = "";
    }

    function pick_heavy() public pure returns (weapon memory _weapon) {
        _weapon.id = 28;
        _weapon.name = "Pick, heavy";
        _weapon.cost = 8e18;
        _weapon.proficiency = 2;
        _weapon.encumbrance = 3;
        _weapon.damage_type = 2;
        _weapon.weight = 6;
        _weapon.damage = 6;
        _weapon.critical = 4;
        _weapon.critical_modifier = 0;
        _weapon.range_increment = 0;
        _weapon.description = "";
    }

    function rapier() public pure returns (weapon memory _weapon) {
        _weapon.id = 29;
        _weapon.name = "Rapier";
        _weapon.cost = 20e18;
        _weapon.proficiency = 2;
        _weapon.encumbrance = 3;
        _weapon.damage_type = 2;
        _weapon.weight = 2;
        _weapon.damage = 6;
        _weapon.critical = 2;
        _weapon.critical_modifier = -2;
        _weapon.range_increment = 0;
        _weapon.description = "You can use the Weapon Finesse feat to apply your Dexterity modifier instead of your Strength modifier to attack rolls with a rapier sized for you, even though it isnt a light weapon for you. You cant wield a rapier in two hands in order to apply 1.5 times your Strength bonus to damage.";
    }

    function scimitar() public pure returns (weapon memory _weapon) {
        _weapon.id = 30;
        _weapon.name = "Scimitar";
        _weapon.cost = 15e18;
        _weapon.proficiency = 2;
        _weapon.encumbrance = 3;
        _weapon.damage_type = 3;
        _weapon.weight = 4;
        _weapon.damage = 6;
        _weapon.critical = 2;
        _weapon.critical_modifier = -2;
        _weapon.range_increment = 0;
        _weapon.description = "";
    }

    function trident() public pure returns (weapon memory _weapon) {
        _weapon.id = 31;
        _weapon.name = "Trident";
        _weapon.cost = 15e18;
        _weapon.proficiency = 2;
        _weapon.encumbrance = 3;
        _weapon.damage_type = 2;
        _weapon.weight = 4;
        _weapon.damage = 8;
        _weapon.critical = 2;
        _weapon.critical_modifier = 0;
        _weapon.range_increment = 0;
        _weapon.description = "This weapon can be thrown. If you use a ready action to set a trident against a charge, you deal double damage on a successful hit against a charging character.";
    }

    function warhammer() public pure returns (weapon memory _weapon) {
        _weapon.id = 32;
        _weapon.name = "Warhammer";
        _weapon.cost = 12e18;
        _weapon.proficiency = 2;
        _weapon.encumbrance = 3;
        _weapon.damage_type = 1;
        _weapon.weight = 5;
        _weapon.damage = 8;
        _weapon.critical = 3;
        _weapon.critical_modifier = 0;
        _weapon.range_increment = 0;
        _weapon.description = "";
    }

    function falchion() public pure returns (weapon memory _weapon) {
        _weapon.id = 33;
        _weapon.name = "Falchion";
        _weapon.cost = 75e18;
        _weapon.proficiency = 2;
        _weapon.encumbrance = 4;
        _weapon.damage_type = 3;
        _weapon.weight = 8;
        _weapon.damage = 8;
        _weapon.critical = 2;
        _weapon.critical_modifier = -2;
        _weapon.range_increment = 0;
        _weapon.description = "";
    }

    function glaive() public pure returns (weapon memory _weapon) {
        _weapon.id = 34;
        _weapon.name = "Glaive";
        _weapon.cost = 8e18;
        _weapon.proficiency = 2;
        _weapon.encumbrance = 4;
        _weapon.damage_type = 3;
        _weapon.weight = 10;
        _weapon.damage = 10;
        _weapon.critical = 3;
        _weapon.critical_modifier = 0;
        _weapon.range_increment = 0;
        _weapon.description = "A glaive has reach. You can strike opponents 10 feet away with it, but you cant use it against an adjacent foe.";
    }

    function greataxe() public pure returns (weapon memory _weapon) {
        _weapon.id = 35;
        _weapon.name = "Greataxe";
        _weapon.cost = 20e18;
        _weapon.proficiency = 2;
        _weapon.encumbrance = 4;
        _weapon.damage_type = 3;
        _weapon.weight = 12;
        _weapon.damage = 12;
        _weapon.critical = 3;
        _weapon.critical_modifier = 0;
        _weapon.range_increment = 0;
        _weapon.description = "";
    }

    function greatclub() public pure returns (weapon memory _weapon) {
        _weapon.id = 36;
        _weapon.name = "Greatclub";
        _weapon.cost = 5e18;
        _weapon.proficiency = 2;
        _weapon.encumbrance = 4;
        _weapon.damage_type = 1;
        _weapon.weight = 8;
        _weapon.damage = 10;
        _weapon.critical = 2;
        _weapon.critical_modifier = 0;
        _weapon.range_increment = 0;
        _weapon.description = "";
    }

    function flail_heavy() public pure returns (weapon memory _weapon) {
        _weapon.id = 37;
        _weapon.name = "Flail, heavy";
        _weapon.cost = 15e18;
        _weapon.proficiency = 2;
        _weapon.encumbrance = 4;
        _weapon.damage_type = 1;
        _weapon.weight = 10;
        _weapon.damage = 10;
        _weapon.critical = 2;
        _weapon.critical_modifier = -1;
        _weapon.range_increment = 0;
        _weapon.description = "With a flail, you get a +2 bonus on opposed attack rolls made to disarm an enemy (including the roll to avoid being disarmed if such an attempt fails).";
    }

    function greatsword() public pure returns (weapon memory _weapon) {
        _weapon.id = 38;
        _weapon.name = "Greatsword";
        _weapon.cost = 50e18;
        _weapon.proficiency = 2;
        _weapon.encumbrance = 4;
        _weapon.damage_type = 3;
        _weapon.weight = 8;
        _weapon.damage = 12;
        _weapon.critical = 2;
        _weapon.critical_modifier = -1;
        _weapon.range_increment = 0;
        _weapon.description = "";
    }

    function guisarme() public pure returns (weapon memory _weapon) {
        _weapon.id = 39;
        _weapon.name = "Guisarme";
        _weapon.cost = 9e18;
        _weapon.proficiency = 2;
        _weapon.encumbrance = 4;
        _weapon.damage_type = 3;
        _weapon.weight = 12;
        _weapon.damage = 8;
        _weapon.critical = 3;
        _weapon.critical_modifier = 0;
        _weapon.range_increment = 0;
        _weapon.description = "A guisarme has reach. You can strike opponents 10 feet away with it, but you cant use it against an adjacent foe.";
    }

    function halberd() public pure returns (weapon memory _weapon) {
        _weapon.id = 40;
        _weapon.name = "Halberd";
        _weapon.cost = 10e18;
        _weapon.proficiency = 2;
        _weapon.encumbrance = 4;
        _weapon.damage_type = 2;
        _weapon.weight = 12;
        _weapon.damage = 10;
        _weapon.critical = 3;
        _weapon.critical_modifier = 0;
        _weapon.range_increment = 0;
        _weapon.description = "If you use a ready action to set a halberd against a charge, you deal double damage on a successful hit against a charging character.";
    }

    function lance() public pure returns (weapon memory _weapon) {
        _weapon.id = 41;
        _weapon.name = "Lance";
        _weapon.cost = 10e18;
        _weapon.proficiency = 2;
        _weapon.encumbrance = 4;
        _weapon.damage_type = 2;
        _weapon.weight = 10;
        _weapon.damage = 8;
        _weapon.critical = 3;
        _weapon.critical_modifier = 0;
        _weapon.range_increment = 0;
        _weapon.description = "A lance deals double damage when used from the back of a charging mount. It has reach, so you can strike opponents 10 feet away with it, but you cant use it against an adjacent foe.";
    }

    function ranseur() public pure returns (weapon memory _weapon) {
        _weapon.id = 42;
        _weapon.name = "Ranseur";
        _weapon.cost = 10e18;
        _weapon.proficiency = 2;
        _weapon.encumbrance = 4;
        _weapon.damage_type = 2;
        _weapon.weight = 12;
        _weapon.damage = 8;
        _weapon.critical = 3;
        _weapon.critical_modifier = 0;
        _weapon.range_increment = 0;
        _weapon.description = "A ranseur has reach. You can strike opponents 10 feet away with it, but you cant use it against an adjacent foe.";
    }

    function scythe() public pure returns (weapon memory _weapon) {
        _weapon.id = 43;
        _weapon.name = "Scythe";
        _weapon.cost = 18e18;
        _weapon.proficiency = 2;
        _weapon.encumbrance = 4;
        _weapon.damage_type = 3;
        _weapon.weight = 10;
        _weapon.damage = 8;
        _weapon.critical = 4;
        _weapon.critical_modifier = 0;
        _weapon.range_increment = 0;
        _weapon.description = "A scythe can be used to make trip attacks. If you are tripped during your own trip attempt, you can drop the scythe to avoid being tripped.";
    }

    function longbow() public pure returns (weapon memory _weapon) {
        _weapon.id = 44;
        _weapon.name = "Longbow";
        _weapon.cost = 75e18;
        _weapon.proficiency = 2;
        _weapon.encumbrance = 5;
        _weapon.damage_type = 2;
        _weapon.weight = 3;
        _weapon.damage = 8;
        _weapon.critical = 3;
        _weapon.critical_modifier = 0;
        _weapon.range_increment = 100;
        _weapon.description = "You need at least two hands to use a bow, regardless of its size. A longbow is too unwieldy to use while you are mounted. If you have a penalty for low Strength, apply it to damage rolls when you use a longbow. If you have a bonus for high Strength, you can apply it to damage rolls when you use a composite longbow (see below) but not a regular longbow.";
    }

    function longbow_composite() public pure returns (weapon memory _weapon) {
        _weapon.id = 45;
        _weapon.name = "Longbow, composite";
        _weapon.cost = 100e18;
        _weapon.proficiency = 2;
        _weapon.encumbrance = 5;
        _weapon.damage_type = 2;
        _weapon.weight = 3;
        _weapon.damage = 8;
        _weapon.critical = 3;
        _weapon.critical_modifier = 0;
        _weapon.range_increment = 110;
        _weapon.description = "You need at least two hands to use a bow, regardless of its size. You can use a composite longbow while mounted. All composite bows are made with a particular strength rating (that is, each requires a minimum Strength modifier to use with proficiency). If your Strength bonus is less than the strength rating of the composite bow, you cant effectively use it, so you take a -2 penalty on attacks with it. The default composite longbow requires a Strength modifier of +0 or higher to use with proficiency. A composite longbow can be made with a high strength rating to take advantage of an above-average Strength score; this feature allows you to add your Strength bonus to damage, up to the maximum bonus indicated for the bow. Each point of Strength bonus granted by the bow adds 100 gp to its cost.";
    }

    function shortbow() public pure returns (weapon memory _weapon) {
        _weapon.id = 46;
        _weapon.name = "Shortbow";
        _weapon.cost = 30e18;
        _weapon.proficiency = 2;
        _weapon.encumbrance = 5;
        _weapon.damage_type = 2;
        _weapon.weight = 2;
        _weapon.damage = 6;
        _weapon.critical = 3;
        _weapon.critical_modifier = 0;
        _weapon.range_increment = 60;
        _weapon.description = "You need at least two hands to use a bow, regardless of its size. You can use a shortbow while mounted. If you have a penalty for low Strength, apply it to damage rolls when you use a shortbow. If you have a bonus for high Strength, you can apply it to damage rolls when you use a composite shortbow (see below) but not a regular shortbow.";
    }

    function shortbow_composite() public pure returns (weapon memory _weapon) {
        _weapon.id = 47;
        _weapon.name = "Shortbow, composite";
        _weapon.cost = 75e18;
        _weapon.proficiency = 2;
        _weapon.encumbrance = 5;
        _weapon.damage_type = 2;
        _weapon.weight = 2;
        _weapon.damage = 6;
        _weapon.critical = 3;
        _weapon.critical_modifier = 0;
        _weapon.range_increment = 70;
        _weapon.description = "You need at least two hands to use a bow, regardless of its size. You can use a composite shortbow while mounted. All composite bows are made with a particular strength rating (that is, each requires a minimum Strength modifier to use with proficiency). If your Strength bonus is lower than the strength rating of the composite bow, you cant effectively use it, so you take a -2 penalty on attacks with it. The default composite shortbow requires a Strength modifier of +0 or higher to use with proficiency. A composite shortbow can be made with a high strength rating to take advantage of an above-average Strength score; this feature allows you to add your Strength bonus to damage, up to the maximum bonus indicated for the bow. Each point of Strength bonus granted by the bow adds 75 gp to its cost.";
    }

    function kama() public pure returns (weapon memory _weapon) {
        _weapon.id = 48;
        _weapon.name = "Kama";
        _weapon.cost = 2e18;
        _weapon.proficiency = 3;
        _weapon.encumbrance = 2;
        _weapon.damage_type = 3;
        _weapon.weight = 2;
        _weapon.damage = 6;
        _weapon.critical = 2;
        _weapon.critical_modifier = 0;
        _weapon.range_increment = 0;
        _weapon.description = "The kama is a special monk weapon. This designation gives a monk wielding a kama special options.";
    }

    function nunchaku() public pure returns (weapon memory _weapon) {
        _weapon.id = 49;
        _weapon.name = "Nunchaku";
        _weapon.cost = 2e18;
        _weapon.proficiency = 3;
        _weapon.encumbrance = 2;
        _weapon.damage_type = 1;
        _weapon.weight = 2;
        _weapon.damage = 6;
        _weapon.critical = 2;
        _weapon.critical_modifier = 0;
        _weapon.range_increment = 0;
        _weapon.description = "The nunchaku is a special monk weapon. This designation gives a monk wielding a nunchaku special options. With a nunchaku, you get a +2 bonus on opposed attack rolls made to disarm an enemy (including the roll to avoid being disarmed if such an attempt fails).";
    }

    function sai() public pure returns (weapon memory _weapon) {
        _weapon.id = 50;
        _weapon.name = "Sai";
        _weapon.cost = 1e18;
        _weapon.proficiency = 3;
        _weapon.encumbrance = 2;
        _weapon.damage_type = 1;
        _weapon.weight = 1;
        _weapon.damage = 4;
        _weapon.critical = 2;
        _weapon.critical_modifier = 0;
        _weapon.range_increment = 0;
        _weapon.description = "With a sai, you get a +4 bonus on opposed attack rolls made to disarm an enemy (including the roll to avoid being disarmed if such an attempt fails).";
    }

    function siangham() public pure returns (weapon memory _weapon) {
        _weapon.id = 51;
        _weapon.name = "Siangham";
        _weapon.cost = 3e18;
        _weapon.proficiency = 3;
        _weapon.encumbrance = 2;
        _weapon.damage_type = 2;
        _weapon.weight = 1;
        _weapon.damage = 6;
        _weapon.critical = 2;
        _weapon.critical_modifier = 0;
        _weapon.range_increment = 0;
        _weapon.description = "The siangham is a special monk weapon. This designation gives a monk wielding a siangham special options.";
    }

    function sword_bastard() public pure returns (weapon memory _weapon) {
        _weapon.id = 52;
        _weapon.name = "Sword, bastard";
        _weapon.cost = 35e18;
        _weapon.proficiency = 3;
        _weapon.encumbrance = 3;
        _weapon.damage_type = 3;
        _weapon.weight = 6;
        _weapon.damage = 10;
        _weapon.critical = 2;
        _weapon.critical_modifier = -1;
        _weapon.range_increment = 0;
        _weapon.description = "A bastard sword is too large to use in one hand without special training; thus, it is an exotic weapon. A character can use a bastard sword two-handed as a martial weapon.";
    }

    function waraxe_dwarven() public pure returns (weapon memory _weapon) {
        _weapon.id = 53;
        _weapon.name = "Waraxe, dwarven";
        _weapon.cost = 30e18;
        _weapon.proficiency = 3;
        _weapon.encumbrance = 3;
        _weapon.damage_type = 3;
        _weapon.weight = 8;
        _weapon.damage = 10;
        _weapon.critical = 3;
        _weapon.critical_modifier = 0;
        _weapon.range_increment = 0;
        _weapon.description = "A dwarven waraxe is too large to use in one hand without special training; thus, it is an exotic weapon. A Medium character can use a dwarven waraxe two-handed as a martial weapon, or a Large creature can use it one-handed in the same way. A dwarf treats a dwarven waraxe as a martial weapon even when using it in one hand.";
    }

    function axe_orc_double() public pure returns (weapon memory _weapon) {
        _weapon.id = 54;
        _weapon.name = "Axe, orc double";
        _weapon.cost = 60e18;
        _weapon.proficiency = 3;
        _weapon.encumbrance = 4;
        _weapon.damage_type = 3;
        _weapon.weight = 15;
        _weapon.damage = 8;
        _weapon.critical = 3;
        _weapon.critical_modifier = 0;
        _weapon.range_increment = 0;
        _weapon.description = "An orc double axe is a double weapon. You can fight with it as if fighting with two weapons, but if you do, you incur all the normal attack penalties associated with fighting with two weapons, just as if you were using a one-handed weapon and a light weapon.";
    }

    function chain_spiked() public pure returns (weapon memory _weapon) {
        _weapon.id = 55;
        _weapon.name = "Chain, spiked";
        _weapon.cost = 25e18;
        _weapon.proficiency = 3;
        _weapon.encumbrance = 4;
        _weapon.damage_type = 2;
        _weapon.weight = 10;
        _weapon.damage = 8;
        _weapon.critical = 2;
        _weapon.critical_modifier = 0;
        _weapon.range_increment = 0;
        _weapon.description = "A spiked chain has reach, so you can strike opponents 10 feet away with it. In addition, unlike most other weapons with reach, it can be used against an adjacent foe.";
    }

    function flail_dire() public pure returns (weapon memory _weapon) {
        _weapon.id = 56;
        _weapon.name = "Flail, dire";
        _weapon.cost = 90e18;
        _weapon.proficiency = 3;
        _weapon.encumbrance = 4;
        _weapon.damage_type = 1;
        _weapon.weight = 10;
        _weapon.damage = 8;
        _weapon.critical = 2;
        _weapon.critical_modifier = 0;
        _weapon.range_increment = 0;
        _weapon.description = "A dire flail is a double weapon. You can fight with it as if fighting with two weapons, but if you do, you incur all the normal attack penalties associated with fighting with two weapons, just as if you were using a one-handed weapon and a light weapon. A creature wielding a dire flail in one hand cant use it as a double weapon- only one end of the weapon can be used in any given round.";
    }

    function crossbow_hand() public pure returns (weapon memory _weapon) {
        _weapon.id = 57;
        _weapon.name = "Crossbow, hand";
        _weapon.cost = 100e18;
        _weapon.proficiency = 3;
        _weapon.encumbrance = 5;
        _weapon.damage_type = 2;
        _weapon.weight = 2;
        _weapon.damage = 4;
        _weapon.critical = 2;
        _weapon.critical_modifier = -1;
        _weapon.range_increment = 30;
        _weapon.description = "You can draw a hand crossbow back by hand. Loading a hand crossbow is a move action that provokes attacks of opportunity.";
    }

    function crossbow_repeating_heavy() public pure returns (weapon memory _weapon) {
        _weapon.id = 58;
        _weapon.name = "Crossbow, repeating heavy";
        _weapon.cost = 400e18;
        _weapon.proficiency = 3;
        _weapon.encumbrance = 5;
        _weapon.damage_type = 2;
        _weapon.weight = 12;
        _weapon.damage = 10;
        _weapon.critical = 2;
        _weapon.critical_modifier = -1;
        _weapon.range_increment = 120;
        _weapon.description = "The repeating crossbow (whether heavy or light) holds 5 crossbow bolts. As long as it holds bolts, you can reload it by pulling the reloading lever (a free action). Loading a new case of 5 bolts is a full-round action that provokes attacks of opportunity.";
    }

    function crossbow_repeating_light() public pure returns (weapon memory _weapon) {
        _weapon.id = 59;
        _weapon.name = "Crossbow, repeating light";
        _weapon.cost = 250e18;
        _weapon.proficiency = 3;
        _weapon.encumbrance = 5;
        _weapon.damage_type = 2;
        _weapon.weight = 6;
        _weapon.damage = 8;
        _weapon.critical = 2;
        _weapon.critical_modifier = -1;
        _weapon.range_increment = 80;
        _weapon.description = "The repeating crossbow (whether heavy or light) holds 5 crossbow bolts. As long as it holds bolts, you can reload it by pulling the reloading lever (a free action). Loading a new case of 5 bolts is a full-round action that provokes attacks of opportunity.";
    }
}