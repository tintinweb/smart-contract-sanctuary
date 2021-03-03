/**
 *Submitted for verification at Etherscan.io on 2021-03-02
*/

/**
 *Submitted for verification at BscScan.com on 2021-03-02
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

/**
 * Provides a time-locked function to return any tokens sent to this address.
 */

interface IBEP20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract BogTokenLock {
    address owner;
    uint256 lockedUntil;

    constructor(){
        owner = msg.sender;
        lockedUntil = block.timestamp + 15 minutes; // 6 months from creation
    }

    function returnTokens(address token) external {
        // Using the public function timeUntilUnlock() means you are able to check the remaining time yourselves by calling this function on BscScan
        require(timeUntilUnlock() == 0, "Tokens are still locked");
        require(msg.sender == owner, "Can only return tokens to contract owner");

        IBEP20(token).transfer(owner, IBEP20(token).balanceOf(address(this)));
    }

    function timeUntilUnlock() public view returns (uint256) {
        if(lockedUntil > block.timestamp){ return lockedUntil - block.timestamp; }
        return 0;
    }
}