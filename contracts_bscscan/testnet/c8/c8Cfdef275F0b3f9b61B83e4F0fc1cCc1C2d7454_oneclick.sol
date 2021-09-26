/**
 *Submitted for verification at BscScan.com on 2021-09-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IRarity {
    function adventure(uint _summoner) external;
    function level_up(uint _summoner) external;
    function approve(address, uint256) external;
    function getApproved(uint256) external view returns (address);
}

/**
 * @title oneclick
 * @dev sends multiple summoners on an adventure
 */
contract oneclick {
    IRarity rarity = IRarity(0xDd17D7D183F2954cE53a7d559B08236263c67918);

    // you'll be able to send summoners that you (the caller) don't own on an
    // adventure, as long as it's approved for this contract
    function adventure(uint256[] calldata _ids) external {
        uint len = _ids.length;
        for (uint i = 0; i < len; i++) {
            rarity.adventure(_ids[i]);
        }
        // that's literally it
    }

    function level_up(uint256[] calldata _ids) external {
        for (uint i = 0; i < _ids.length; i++) {
            rarity.level_up(_ids[i]);
        }
    }

    // @dev Approve an array of summoners
    function approve_all(uint256[] calldata _ids) external {
        for (uint i = 0; i < _ids.length; i++) {
            rarity.approve(address(this), _ids[i]);
        }
    }
}