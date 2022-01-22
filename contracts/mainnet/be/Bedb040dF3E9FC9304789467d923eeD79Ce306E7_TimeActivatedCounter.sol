/**
 *Submitted for verification at Etherscan.io on 2022-01-22
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;

contract TimeActivatedCounter {
    uint256 private activationTimestamp = 1642818395;
    uint256 public count = 0;

    function setActivationTimestamp(uint256 newActivationTimestamp) public {
        activationTimestamp = newActivationTimestamp;
    }

    function increment() public {
        require(block.timestamp >= activationTimestamp, 'too early!');
        count += 1;
    }
}