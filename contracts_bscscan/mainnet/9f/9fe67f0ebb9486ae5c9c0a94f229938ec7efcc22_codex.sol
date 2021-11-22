/**
 *Submitted for verification at BscScan.com on 2021-11-22
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract codex {
    string constant public index = "Items";
    string constant public class = "Armor";
    
    function get_proficiency_by_id(uint _id) public pure returns (string memory description) {
        if (_id == 1) {
            return "Light";
        } else if (_id == 2) {
            return "Medium";
        } else if (_id == 3) {
            return "Heavy";
        } else if (_id == 4) {
            return "Shields";
        }
    }

    function item_by_id(uint _id) public pure returns(
        uint id,
        uint cost,
        uint proficiency,
        uint weight,
        uint armor_bonus,
        uint max_dex_bonus,
        int penalty,
        uint spell_failure,
        string memory name,
        string memory description
    ) {
        if (_id == 1) {
            return padded();
        } else if (_id == 2) {
            return leather();
        } else if (_id == 3) {
            return studded_leather();
        } else if (_id == 4) {
            return chain_shirt();
        } else if (_id == 5) {
            return hide();
        } else if (_id == 6) {
            return scale_mail();
        } else if (_id == 7) {
            return chainmail();
        } else if (_id == 8) {
            return breastplate();
        } else if (_id == 9) {
            return splint_mail();
        } else if (_id == 10) {
            return banded_mail();
        } else if (_id == 11) {
            return half_plate();
        } else if (_id == 12) {
            return full_plate();
        } else if (_id == 13) {
            return buckler();
        } else if (_id == 14) {
            return shield_light_wooden();
        } else if (_id == 15) {
            return shield_light_steel();
        } else if (_id == 16) {
            return shield_heavy_wooden();
        } else if (_id == 17) {
            return shield_heavy_steel();
        } else if (_id == 18) {
            return shield_tower();
        }
    }

    function padded() public pure returns (
        uint id,
        uint cost,
        uint proficiency,
        uint weight,
        uint armor_bonus,
        uint max_dex_bonus,
        int penalty,
        uint spell_failure,
        string memory name,
        string memory description
    ) {
        id = 1;
        name = "Padded";
        cost = 5e18;
        proficiency = 1;
        weight = 10;
        armor_bonus = 1;
        max_dex_bonus = 8;
        penalty = 0;
        spell_failure = 5;
        description = "";
    }

    function leather() public pure returns (
        uint id,
        uint cost,
        uint proficiency,
        uint weight,
        uint armor_bonus,
        uint max_dex_bonus,
        int penalty,
        uint spell_failure,
        string memory name,
        string memory description
    ) {
        id = 2;
        name = "Leather";
        cost = 10e18;
        proficiency = 1;
        weight = 15;
        armor_bonus = 2;
        max_dex_bonus = 6;
        penalty = 0;
        spell_failure = 10;
        description = "";
    }

    function studded_leather() public pure returns (
        uint id,
        uint cost,
        uint proficiency,
        uint weight,
        uint armor_bonus,
        uint max_dex_bonus,
        int penalty,
        uint spell_failure,
        string memory name,
        string memory description
    ) {
        id = 3;
        name = "Studded leather";
        cost = 25e18;
        proficiency = 1;
        weight = 20;
        armor_bonus = 3;
        max_dex_bonus = 5;
        penalty = -1;
        spell_failure = 15;
        description = "";
    }

    function chain_shirt() public pure returns (
        uint id,
        uint cost,
        uint proficiency,
        uint weight,
        uint armor_bonus,
        uint max_dex_bonus,
        int penalty,
        uint spell_failure,
        string memory name,
        string memory description
    ) {
        id = 4;
        name = "Chain shirt";
        cost = 100e18;
        proficiency = 1;
        weight = 25;
        armor_bonus = 4;
        max_dex_bonus = 4;
        penalty = -2;
        spell_failure = 20;
        description = "A chain shirt comes with a steel cap.";
    }

    function hide() public pure returns (
        uint id,
        uint cost,
        uint proficiency,
        uint weight,
        uint armor_bonus,
        uint max_dex_bonus,
        int penalty,
        uint spell_failure,
        string memory name,
        string memory description
    ) {
        id = 5;
        name = "Hide";
        cost = 15e18;
        proficiency = 2;
        weight = 25;
        armor_bonus = 3;
        max_dex_bonus = 4;
        penalty = -3;
        spell_failure = 20;
        description = "";
    }

    function scale_mail() public pure returns (
        uint id,
        uint cost,
        uint proficiency,
        uint weight,
        uint armor_bonus,
        uint max_dex_bonus,
        int penalty,
        uint spell_failure,
        string memory name,
        string memory description
    ) {
        id = 6;
        name = "Scale mail";
        cost = 50e18;
        proficiency = 2;
        weight = 30;
        armor_bonus = 4;
        max_dex_bonus = 3;
        penalty = -4;
        spell_failure = 25;
        description = "The suit includes gauntlets.";
    }

    function chainmail() public pure returns (
        uint id,
        uint cost,
        uint proficiency,
        uint weight,
        uint armor_bonus,
        uint max_dex_bonus,
        int penalty,
        uint spell_failure,
        string memory name,
        string memory description
    ) {
        id = 7;
        name = "Chainmail";
        cost = 150e18;
        proficiency = 2;
        weight = 40;
        armor_bonus = 5;
        max_dex_bonus = 2;
        penalty = -5;
        spell_failure = 30;
        description = "The suit includes gauntlets";
    }

    function breastplate() public pure returns (
        uint id,
        uint cost,
        uint proficiency,
        uint weight,
        uint armor_bonus,
        uint max_dex_bonus,
        int penalty,
        uint spell_failure,
        string memory name,
        string memory description
    ) {
        id = 8;
        name = "Breastplate";
        cost = 200e18;
        proficiency = 2;
        weight = 30;
        armor_bonus = 5;
        max_dex_bonus = 3;
        penalty = -4;
        spell_failure = 25;
        description = "It comes with a helmet and greaves.";
    }

    function splint_mail() public pure returns (
        uint id,
        uint cost,
        uint proficiency,
        uint weight,
        uint armor_bonus,
        uint max_dex_bonus,
        int penalty,
        uint spell_failure,
        string memory name,
        string memory description
    ) {
        id = 9;
        name = "Splint mail";
        cost = 200e18;
        proficiency = 3;
        weight = 45;
        armor_bonus = 6;
        max_dex_bonus = 0;
        penalty = -7;
        spell_failure = 40;
        description = "The suit includes gauntlets.";
    }

    function banded_mail() public pure returns (
        uint id,
        uint cost,
        uint proficiency,
        uint weight,
        uint armor_bonus,
        uint max_dex_bonus,
        int penalty,
        uint spell_failure,
        string memory name,
        string memory description
    ) {
        id = 10;
        name = "Banded mail";
        cost = 250e18;
        proficiency = 3;
        weight = 35;
        armor_bonus = 6;
        max_dex_bonus = 1;
        penalty = -6;
        spell_failure = 35;
        description = "The suit includes gauntlets.";
    }

    function half_plate() public pure returns (
        uint id,
        uint cost,
        uint proficiency,
        uint weight,
        uint armor_bonus,
        uint max_dex_bonus,
        int penalty,
        uint spell_failure,
        string memory name,
        string memory description
    ) {
        id = 11;
        name = "Half-plate";
        cost = 600e18;
        proficiency = 3;
        weight = 50;
        armor_bonus = 7;
        max_dex_bonus = 0;
        penalty = -7;
        spell_failure = 40;
        description = "The suit includes gauntlets.";
    }

    function full_plate() public pure returns (
        uint id,
        uint cost,
        uint proficiency,
        uint weight,
        uint armor_bonus,
        uint max_dex_bonus,
        int penalty,
        uint spell_failure,
        string memory name,
        string memory description
    ) {
        id = 12;
        name = "Full plate";
        cost = 1500e18;
        proficiency = 3;
        weight = 50;
        armor_bonus = 8;
        max_dex_bonus = 1;
        penalty = -6;
        spell_failure = 35;
        description = "The suit includes gauntlets, heavy leather boots, a visored helmet, and a thick layer of padding that is worn underneath the armor. Each suit of full plate must be individually fitted to its owner by a master armorsmith, although a captured suit can be resized to fit a new owner at a cost of 200 to 800 (2d4x100) gold pieces.";
    }

    function buckler() public pure returns (
        uint id,
        uint cost,
        uint proficiency,
        uint weight,
        uint armor_bonus,
        uint max_dex_bonus,
        int penalty,
        uint spell_failure,
        string memory name,
        string memory description
    ) {
        id = 13;
        name = "Buckler";
        cost = 15e18;
        proficiency = 4;
        weight = 5;
        armor_bonus = 1;
        max_dex_bonus = 8;
        penalty = -1;
        spell_failure = 5;
        description = "This small metal shield is worn strapped to your forearm. You can use a bow or crossbow without penalty while carrying it. You can also use your shield arm to wield a weapon (whether you are using an off-hand weapon or using your off hand to help wield a two-handed weapon), but you take a -1 penalty on attack rolls while doing so. This penalty stacks with those that may apply for fighting with your off hand and for fighting with two weapons. In any case, if you use a weapon in your off hand, you dont get the bucklers AC bonus for the rest of the round.";
    }

    function shield_light_wooden() public pure returns (
        uint id,
        uint cost,
        uint proficiency,
        uint weight,
        uint armor_bonus,
        uint max_dex_bonus,
        int penalty,
        uint spell_failure,
        string memory name,
        string memory description
    ) {
        id = 14;
        name = "Shield, light wooden";
        cost = 3e18;
        proficiency = 4;
        weight = 5;
        armor_bonus = 1;
        max_dex_bonus = 8;
        penalty = -1;
        spell_failure = 5;
        description = "Wooden and steel shields offer the same basic protection, though they respond differently to special attacks";
    }

    function shield_light_steel() public pure returns (
        uint id,
        uint cost,
        uint proficiency,
        uint weight,
        uint armor_bonus,
        uint max_dex_bonus,
        int penalty,
        uint spell_failure,
        string memory name,
        string memory description
    ) {
        id = 15;
        name = "Shield, light steel";
        cost = 9e18;
        proficiency = 4;
        weight = 6;
        armor_bonus = 1;
        max_dex_bonus = 8;
        penalty = -1;
        spell_failure = 5;
        description = "Wooden and steel shields offer the same basic protection, though they respond differently to special attacks";
    }

    function shield_heavy_wooden() public pure returns (
        uint id,
        uint cost,
        uint proficiency,
        uint weight,
        uint armor_bonus,
        uint max_dex_bonus,
        int penalty,
        uint spell_failure,
        string memory name,
        string memory description
    ) {
        id = 16;
        name = "Shield, heavy wooden";
        cost = 7e18;
        proficiency = 4;
        weight = 10;
        armor_bonus = 2;
        max_dex_bonus = 8;
        penalty = -2;
        spell_failure = 15;
        description = "Wooden and steel shields offer the same basic protection, though they respond differently to special attacks.";
    }

    function shield_heavy_steel() public pure returns (
        uint id,
        uint cost,
        uint proficiency,
        uint weight,
        uint armor_bonus,
        uint max_dex_bonus,
        int penalty,
        uint spell_failure,
        string memory name,
        string memory description
    ) {
        id = 17;
        name = "Shield, heavy steel";
        cost = 20e18;
        proficiency = 4;
        weight = 15;
        armor_bonus = 2;
        max_dex_bonus = 8;
        penalty = -2;
        spell_failure = 15;
        description = "Wooden and steel shields offer the same basic protection, though they respond differently to special attacks.";
    }

    function shield_tower() public pure returns (
        uint id,
        uint cost,
        uint proficiency,
        uint weight,
        uint armor_bonus,
        uint max_dex_bonus,
        int penalty,
        uint spell_failure,
        string memory name,
        string memory description
    ) {
        id = 18;
        name = "Shield, tower";
        cost = 30e18;
        proficiency = 4;
        weight = 45;
        armor_bonus = 4;
        max_dex_bonus = 2;
        penalty = -10;
        spell_failure = 50;
        description = "This massive wooden shield is nearly as tall as you are. In most situations, it provides the indicated shield bonus to your AC. However, you can instead use it as total cover, though you must give up your attacks to do so. The shield does not, however, provide cover against targeted spells; a spellcaster can cast a spell on you by targeting the shield you are holding. You cannot bash with a tower shield, nor can you use your shield hand for anything else.";
    }
}