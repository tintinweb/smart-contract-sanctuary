/**
 *Submitted for verification at Etherscan.io on 2021-09-05
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract codex {
    string constant index = "Spells";
    string constant class = "Wizard";
    string constant school = "Abjuration";
    uint constant level = 0;
    
    function resistance() external pure returns (
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
        name = "Resistance";
        verbal = true;
        somatic = true;
        focus = false;
        xp_cost = 0;
        time = 1;
        range = 1;
        duration = 60;
        saving_throw_type = 3;
        saving_throw_effect = 3;
        spell_resistance = true;
        description = "You imbue the subject with magical energy that protects it from harm, granting it a +1 resistance bonus on saves. Resistance can be made permanent with a permanency spell.";
    }
}