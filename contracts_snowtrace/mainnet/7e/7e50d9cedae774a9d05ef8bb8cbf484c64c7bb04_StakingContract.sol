/**
 *Submitted for verification at snowtrace.io on 2022-01-15
*/

/**
 *Submitted for verification at snowtrace.io on 2022-01-15
*/

/**
 *Submitted for verification at snowtrace.io on 2022-01-08
*/

// SPDX-License-Identifier: MIT

// CHANGE ADDRESSES
pragma solidity ^0.8.6;
interface I {
	function balanceOf(address a) external view returns (uint);
	function transfer(address recipient, uint amount) external returns (bool);
	function transferFrom(address sender,address recipient, uint amount) external returns (bool);
	function totalSupply() external view returns (uint);
	function getRewards(address a,uint rewToClaim) external;
	function burn(uint) external;
}
// this contract' beauty was butchered
contract StakingContract {
	address public _letToken;
	address public _treasury;
	uint public totalLetLocked;

	struct TokenLocker {
		uint128 amount;
		uint32 lastClaim;
		uint32 lockUpTo;
		uint32 epoch;
	}

	mapping(address => TokenLocker) private _ls;
	
    bool public ini;
    
	function init() public {
	    //require(ini==false);ini=true;
		//_letToken = 0x017fe17065B6F973F1bad851ED8c9461c0169c31;
		//_treasury = 0x56D4F9Eed62651D69Af66886A0aA3f9c0500FDeA;
	}

	function lock25days(uint amount) public {// game theory disallows the deployer to exploit this lock, every time locker can exit before a malicious trust minimized upgrade is live
		_getLockRewards(msg.sender);
		_ls[msg.sender].lockUpTo=uint32(block.number+1e6);
		require(amount>0 && I(_letToken).balanceOf(msg.sender)>=amount);
		_ls[msg.sender].amount+=uint128(amount);
		I(_letToken).transferFrom(msg.sender,address(this),amount);
		totalLetLocked+=amount;
	}

	function getLockRewards() public returns(uint){
		return _getLockRewards(msg.sender);
	}

	function _getLockRewards(address a) internal returns(uint){
		uint toClaim = 0;
		if(_ls[a].lockUpTo>block.number&&_ls[a].amount>0){
			toClaim = lockRewardsAvailable(a);
			I(_treasury).getRewards(a, toClaim);
			_ls[msg.sender].lockUpTo=uint32(block.number+1e6);
		}
		_ls[msg.sender].lastClaim = uint32(block.number);
		return toClaim;
	}

	function lockRewardsAvailable(address a) public view returns(uint) {
		if(_ls[a].amount>0){
			uint rate = 62e14;
			///
			uint cap = totalLetLocked*300/100000e18;
			if(cap>100){cap=100;}
			rate = rate*cap/100;
			///
			uint amount = (block.number - _ls[a].lastClaim)*_ls[a].amount*rate/totalLetLocked;
			return amount;
		} else {
			return 0;
		}
	}

	function unlock(uint amount) public {
		require(_ls[msg.sender].amount>=amount && totalLetLocked>=amount);
		_getLockRewards(msg.sender);
		_ls[msg.sender].amount-=uint128(amount);
		I(_letToken).transfer(msg.sender,amount*19/20);
		uint leftOver = amount - amount*19/20;
		I(_letToken).transfer(_treasury,leftOver);//5% burn to treasury as spam protection
		totalLetLocked-=amount;
	}

// VIEW FUNCTIONS ==================================================
	function getVoter(address a) external view returns (uint,uint,uint) {
		return (_ls[a].amount,_ls[a].lockUpTo,_ls[a].lastClaim);
	}
}