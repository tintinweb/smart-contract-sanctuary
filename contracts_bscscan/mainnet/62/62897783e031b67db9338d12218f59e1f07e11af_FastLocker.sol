//"SPDX-License-Identifier: MIT"
// belfast token locker
pragma solidity ^0.8.0;
import "./Ownable.sol";

contract FastLocker is Ownable {
    uint public locked_until;
    
    constructor(uint _locked_until) {
        locked_until = _locked_until;
    }
    
    modifier controlla_tempo {
        require(block.timestamp > locked_until,"You cannot withdraw yet. (Time)");
        require(msg.sender == owner(),"Not owner");
        _;
    }

    function updateLock(uint _newTime) external {
        require(msg.sender == owner(),"Not owner");
        require(locked_until <= _newTime,"new date cannot be in the past");
        locked_until = _newTime;
    } 
    
    function Withdraw(address Token) external controlla_tempo {
    uint256 balance = BEP20(Token).balanceOf(address(this));
        require(balance > 0,"you have 0 of this.");
		require(BEP20(Token).transfer(owner(), balance),"transfer error");
    }
}
abstract contract BEP20 {
    function balanceOf(address tokenOwner) virtual external view returns (uint256);
    function transfer(address receiver, uint256 numTokens) virtual public returns (bool);
}