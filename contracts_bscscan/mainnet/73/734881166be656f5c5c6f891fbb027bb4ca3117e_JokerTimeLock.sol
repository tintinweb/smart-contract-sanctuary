/**
 *Submitted for verification at BscScan.com on 2021-09-10
*/

// SPDX-License-Identifier: MIT

// DEVELOPMENT VAULT

// The tokens held in this contract are dedicated to further development purposes, such as funding new farms/pools and create new JOKER-OTHERTOKEN pairs.
// Once the locking period ends, I will lock the unused tokens in another timelocked contract.

// joker.farm

pragma solidity =0.7.6;


contract JokerTimeLock {

    address public Owner;
    address public constant Token = 0xC7980F82A4fb8970219E35e6Fcac98A6f32B2325;

    uint256 public constant StartLock = 1631280002;   //  Friday 10 September 2021 13:20:02 GMT
    uint256 public constant LockedUntil = 1633872002; //  Sunday 10 October 2021 13:20:02 GMT

	uint256 constant Decimals = 18;
	uint256 constant incrementAmount = 10 ** (5 + Decimals);
	
    
    // Constructor. 
   constructor() payable {  
		Owner = payable(msg.sender);
    }  
    

    // Modifiers
    modifier checkRequirements {
        require(StartLock < block.timestamp, "Time travel is not allowed!");
		require(LockedUntil > block.timestamp, "Locking period is not over!");
		require(msg.sender == Owner, "Admin function!");
        _;
    }
    

    function payOutIncrementToken() external checkRequirements {
        TIMELOCK(Token).transfer(Owner, incrementAmount);
    }
    
    
    function payOutTotalToken() external checkRequirements {
        uint256 balance = TIMELOCK(Token).balanceOf(address(this));
		TIMELOCK(Token).transfer(Owner, balance);
    }

}

// Interface for TIMELOCK
abstract contract TIMELOCK {
    function balanceOf(address tokenOwner) virtual external view returns (uint256);
    function transfer(address receiver, uint256 numTokens) virtual public returns (bool);
}