/**
 *Submitted for verification at Etherscan.io on 2021-09-05
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract codex {
    string constant index = "Spells";
    string constant class = "Wizard";
    string constant school = "Necromancy";
    uint constant level = 0;
    
    function disrupt_undead() external pure returns (
        string memory name,
        bool verbal,
        bool somatic,
        bool focus,
        uint xp_cost,
        uint time,
        uint range,
        uint duration,
        uint saving_throw_type,
        uint saving_throw_effect,
        bool spell_resistance,
        string memory description
    ) {
        name = "Disrupt Undead";
        verbal = true;
        somatic = true;
        focus = false;
        xp_cost = 0;
        time = 1;
        range = 2;
        duration = 0;
        saving_throw_type = 0;
        saving_throw_effect = 0;
        spell_resistance = true;
        description = "You direct a ray of positive energy. You must make a ranged touch attack to hit, and if the ray hits an undead creature, it deals 1d6 points of damage to it.";
    }
    
    function touch_of_fatigue() external pure returns (
        string memory name,
        bool verbal,
        bool somatic,
        bool focus,
        uint xp_cost,
        uint time,
        uint range,
        uint duration,
        uint saving_throw_type,
        uint saving_throw_effect,
        bool spell_resistance,
        string memory description
    ) {
        name = "Touch of Fatigue";
        verbal = true;
        somatic = true;
        focus = false;
        xp_cost = 0;
        time = 1;
        range = 1;
        duration = 1;
        saving_throw_type = 1;
        saving_throw_effect = 3;
        spell_resistance = true;
        description = "You channel negative energy through your touch, fatiguing the target. You must succeed on a touch attack to strike a target. The subject is immediately fatigued for the spells duration. This spell has no effect on a creature that is already fatigued. Unlike with normal fatigue, the effect ends as soon as the spells duration expires.";
    }
}