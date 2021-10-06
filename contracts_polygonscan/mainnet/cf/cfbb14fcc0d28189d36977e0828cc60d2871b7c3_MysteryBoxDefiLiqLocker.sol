/**
 *Submitted for verification at polygonscan.com on 2021-10-06
*/

// SPDX-License-Identifier: MIT
// CONTRACT ORIGINALLY MADE BY RUGDOC

pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract MysteryBoxDefiLiqLocker {
    address public MysteryBoxDefiDev = 0x3DcE2E83809322398Ac92616c6Fcd85D000bb41d;
    uint256 public unlockTimestamp;
    
    constructor() {
        unlockTimestamp = block.timestamp + 60 * 60 * 24 * 365; // 1 year lock
    }
    
    function withdraw(IERC20 token) external {
        require(msg.sender == MysteryBoxDefiDev, "withdraw: message sender is not MysteryBoxDefiDev");
        require(block.timestamp > unlockTimestamp, "withdraw: the token is still locked");
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }
    
}