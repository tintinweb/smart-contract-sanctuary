// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./rarity.sol";

contract firstcontract {
    rarity public Rarity = rarity(0xce761D788DF608BD21bdd59d6f4B54b2e27F25Bb);

    function adventureAll(uint[] memory summoners) external {
        for (uint i = 0; i < summoners.length; i++) {
            Rarity.adventure(summoners[i]);
        }
    }

    function levelUpAll(uint[] memory summoners) external {
        for (uint i = 0; i < summoners.length; i++) {
            Rarity.level_up(summoners[i]);
        }
    }
}