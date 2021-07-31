/**
 *Submitted for verification at BscScan.com on 2021-07-31
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


/**
 * @title SimpleTimelock
 * @dev SimpleTimelock is an ETH holder contract that will allow a
 * beneficiary to receive the ETH after a given release time.
 */
contract SimpleTimelock {

    // beneficiary of ETH after it is released
    address public beneficiary = 0x93e6e4B0f3b493A0415646F5Ca8f42b0634A8991;

    // timestamp when ETH release is enabled
    uint256 public releaseTime;
    
    // accept incoming ETH
    receive() external payable {}

    constructor () {
        releaseTime = block.timestamp + 60*5;
    }

    // transfers ETH held by timelock to beneficiary.
    function release() public {
        require(block.timestamp >= releaseTime, "current time is before release time");

        uint256 amount = address(this).balance;
        require(amount > 0, "no ETH to release");

        payable(beneficiary).transfer(amount);
    }
}