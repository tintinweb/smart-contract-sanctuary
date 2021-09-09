/**
 *Submitted for verification at BscScan.com on 2021-09-09
*/

// SPDX-License-Identifier: MIT

/*
EARTHIE

earthie.finance
t.me/earthiefinance
twitter.com/earthiefinance

DeFi + Metaverse

Earthie is the first ecologic metaverse on BSC, built on an elastic supply token designed to increase in price until reaching the price of Bitcoin.
85% of the total supply initially pooled on PancakeSwap, 15% is allocated to the team.
The liquidity is initially locked for 6 months in this timelocked smart contract, renewable.
*/


pragma solidity =0.7.6;


contract TimeLock {

    address public Owner;
    address public constant Token = 0x03A3a5aB7BCBfb9b2a69eA439C8bd98Fc43417a1;

    uint256 public constant StartLock = 1631184659;   //  Thursday 9 September 2021 10:50:55 GMT
    uint256 public constant LockedUntil = 1646823055; //  Wednesday 9 March 2022 10:50:55 GMT

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