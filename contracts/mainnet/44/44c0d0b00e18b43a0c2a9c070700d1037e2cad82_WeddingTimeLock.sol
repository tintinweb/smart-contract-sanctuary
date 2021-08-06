/**
 *Submitted for verification at Etherscan.io on 2021-08-06
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

/*

Congrats on the marriage!

We wish the best for you both in your new life together! 

With love,

Miquel, Pietro, Enrico, Adria, Pablo

*/

contract WeddingTimeLock {
    
    uint256 public timeUnlock;
    address public beneficiary = 0xa6eac7714c6F7c7f73F1De61c543b3D87FFD4e8a;
 
    constructor() {
        timeUnlock = block.timestamp + (20 * 36525 * 24 * 60 * 60) / 100;
    }
    
    function unlockGift() public {
        require(block.timestamp > timeUnlock, "Too early :P");
        require(msg.sender == beneficiary, "Not authorized address");
        transfer(payable(msg.sender), address(this).balance);
    }

    function transfer(address payable acc, uint256 amount) private returns (bool) {
        if (amount == 0) {
            return true;
        }
        (bool sent,) = acc.call{value: amount}("");
        return sent;
    }
    
    // Payable fallback to accept incomming ether
    fallback() external payable {}

    receive() external payable {}
}