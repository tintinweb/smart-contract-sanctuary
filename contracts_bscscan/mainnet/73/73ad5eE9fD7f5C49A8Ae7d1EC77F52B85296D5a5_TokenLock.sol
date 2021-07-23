/**
 *Submitted for verification at BscScan.com on 2021-07-23
*/

/**
 *Submitted for verification at FtmScan.com on 2021-05-16
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

/**
 * Provides a time-locked function to return any tokens sent to this address.
 */

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract TokenLock {
    address owner;
    uint256 lockedUntil;
    
    constructor(){
        owner = msg.sender;
        lockedUntil = block.timestamp + 1 hours ;
    }
    
    function returnTokens(address token) external {
        require(timeUntilUnlock() == 0, "Tokens are still locked"); 
        require(msg.sender == owner, "Can only return tokens to contract owner");
        
        IERC20(token).transfer(owner, IERC20(token).balanceOf(address(this)));
    }
    
    function returnTokenAmount(address token, uint256 amount) external {
        require(timeUntilUnlock() == 0, "Tokens are still locked"); 
        require(msg.sender == owner, "Can only return tokens to contract owner");
        
        IERC20(token).transfer(owner, amount);
    }
    
    function timeUntilUnlock() public view returns (uint256) {
        if(lockedUntil > block.timestamp){ return lockedUntil - block.timestamp; }
        return 0;
    }
}