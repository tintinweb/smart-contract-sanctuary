// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IRarity {
    function adventure(uint _summoner) external;
}

/**
 * @title AdventureTime
 * @dev sends multiple summoners on an adventure
 */
contract AdventureTime {
    IRarity rarity = IRarity(0x4fb729BDb96d735692DCACD9640cF7e3aA859B25);

    // you'll be able to send summoners that you (the caller) don't own on an
    // adventure, as long as it's approved for this contract
    function adventureTime(uint256[] calldata _ids) external {
        uint len = _ids.length;
        for (uint i = 0; i < len; i++) {
            rarity.adventure(_ids[i]);
        }
        // that's literally it
    }
}

