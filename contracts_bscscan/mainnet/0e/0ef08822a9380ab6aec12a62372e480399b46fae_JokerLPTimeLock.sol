/**
 *Submitted for verification at BscScan.com on 2021-09-13
*/

// SPDX-License-Identifier: MIT

// LP VAULT

// The LP tokens held in this contract are locked and thus prevent any rugpull for the developers and the team.
// Once the locking period ends, the unused LPs will be locked in another timelocked contract.

// joker.farm

pragma solidity =0.7.6;


contract JokerLPTimeLock {

    address public Owner;
    address public constant Token = 0x149CFBebe2D99426b5925D473cb7D76A2743B4b6;

    uint256 public constant StartLock = 1631280002;   //  Friday 10 September 2021 13:20:02 GMT
    uint256 public constant LockedUntil = 1662816002; //  Saturday 10 September 2022 13:20:02 GMT

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