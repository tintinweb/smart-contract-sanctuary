/**
 *Submitted for verification at Etherscan.io on 2021-04-23
*/

// SPDX-License-Identifier: Block8
pragma solidity 0.8.3;

contract Utility {
    uint256 nonce = 4568741236787;
    uint256 digits = 1000;

    function getRandomNumber() public view returns (uint256) {
        uint256 random =
            uint256(
                keccak256(abi.encodePacked(msg.sender, block.timestamp, nonce))
            );
        return (random % digits);
    }
}