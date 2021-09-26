/**
 *Submitted for verification at BscScan.com on 2021-09-25
*/

pragma solidity ^0.4.15;

contract token {
	function transferFrom(address sender, address receiver, uint amount) returns(bool success) {}
 

	function burn() {}
	
	function setStart(uint newStart) {}
}

contract SafeMath {
	//internals

	function safeMul(uint a, uint b) internal returns(uint) {
		uint c = a * b;
		assert(a == 0 || c / a == b);
		return c;
	}

	function safeSub(uint a, uint b) internal returns(uint) {
		assert(b <= a);
		return a - b;
	}

	function safeAdd(uint a, uint b) internal returns(uint) {
		uint c = a + b;
		assert(c >= a && c >= b);
		return c;
	}

}


contract Crowdsale is SafeMath {
	/* tokens will be transfered from this address */
	address public tokenOwner;
	/* if the funding goal is not reached, investors may withdraw their funds */
	uint constant public fundingGoal = 250000000000000000;
	/* when the soft cap is reached, the price for monetha tokens will rise */
	uint constant public softCap = 250000000000000000;
	/* the maximum amount of tokens to be sold */
	uint constant public maxGoal = 500000000000000000;
	/* how much has been raised by crowdale (in ETH) */
	uint public amountRaised;
	/* the start date of the crowdsale */
	uint public start;
	/* the end date of the crowdsale*/
	uint public end;
	/* time after reaching the soft cap, while the crowdsale will be still available*/
	uint public timeAfterSoftCap;
	/* the number of tokens already sold */
	uint public tokensSold = 0;
	/* the rates before and after the soft cap is reached */
	uint constant public rateSoft = 2;
	uint constant public rateHard = 1;

	uint constant public rateCoefficient = 640;
	/* the address of the token contract */
	token public tokenReward;
	/* the balances (in ETH) of all investors */
	mapping(address => uint) public balanceOf;
	/* indicates if the crowdsale has been closed already */
	bool public crowdsaleClosed = false;
	/* the wallet on which the funds will be stored */
	address msWallet;
	/* notifying transfers and the success of the crowdsale*/
	event GoalReached(address _tokenOwner, uint _amountRaised);
	event FundTransfer(address backer, uint amount, bool isContribution, uint _amountRaised);




	function Crowdsale(
		address _tokenAddr, 
		address _walletAddr, 
		address _tokenOwner, 
		uint _start, 
		uint _end,
		uint _timeAfterSoftCap)
	{
		tokenReward = token(_tokenAddr);
		msWallet = _walletAddr;
		tokenOwner = _tokenOwner;

		require(_start < _end);
		start = _start;
		end = _end;
		timeAfterSoftCap = _timeAfterSoftCap;
	}

	/* invest by sending ether to the contract. */
	function() payable {
		if (msg.sender != msWallet) //do not trigger investment if the wallet is returning the funds
			invest(msg.sender);
	}

	/* make an investment
	 *  only callable if the crowdsale started and hasn't been closed already and the maxGoal wasn't reached yet.
	 *  the current token price is looked up and the corresponding number of tokens is transfered to the receiver.
	 *  the sent value is directly forwarded to a safe wallet.
	 *  this method allows to purchase tokens in behalf of another address.*/
	function invest(address _receiver) payable {
		uint amount = msg.value;
		var (numTokens, reachedSoftCap) = getNumTokens(amount);
		require(numTokens>0);
		require(!crowdsaleClosed && now >= start && now <= end && safeAdd(tokensSold, numTokens) <= maxGoal);
		msWallet.transfer(amount);
		balanceOf[_receiver] = safeAdd(balanceOf[_receiver], amount);
		amountRaised = safeAdd(amountRaised, amount);
		tokensSold += numTokens;
		assert(tokenReward.transferFrom(tokenOwner, _receiver, numTokens));
	emit	FundTransfer(_receiver, amount, true, amountRaised);
		if (reachedSoftCap) {
			uint newEnd = now + timeAfterSoftCap;
			if (newEnd < end) {
				end = newEnd;
				tokenReward.setStart(newEnd);
			} 
		}
	}
	
	function getNumTokens(uint _value) constant returns(uint numTokens, bool reachedSoftCap) {
		if (tokensSold < softCap) {
			numTokens = safeMul(_value,rateSoft)/rateCoefficient;
			if (safeAdd(tokensSold,numTokens) < softCap) 
				return (numTokens, false);
			else if (safeAdd(tokensSold,numTokens) == softCap) 
				return (numTokens, true);
			else {
				numTokens = safeSub(softCap, tokensSold);
				uint missing = safeSub(_value, safeMul(numTokens,rateCoefficient)/rateSoft);
				return (safeAdd(numTokens, safeMul(missing,rateHard)/rateCoefficient), true);
			}
		} 
		else 
			return (safeMul(_value,rateHard)/rateCoefficient, false);
	}

	modifier afterDeadline() {
		if (now > end) 
			_;
	}

	/* checks if the goal or time limit has been reached and ends the campaign */
	function checkGoalReached() afterDeadline {
		require(msg.sender == tokenOwner);

		if (tokensSold >= fundingGoal) {
			tokenReward.burn(); //burn remaining tokens but the reserved ones
		emit	GoalReached(tokenOwner, amountRaised);
		}
		crowdsaleClosed = true;
	}

	/* allows the funders to withdraw their funds if the goal has not been reached.
	 *  only works after funds have been returned from the wallet. */
	function safeWithdrawal() afterDeadline {
		uint amount = balanceOf[msg.sender];
		if (address(this).balance >= amount) {
			balanceOf[msg.sender] = 0;
			if (amount > 0) {
				msg.sender.transfer(amount);
			emit	FundTransfer(msg.sender, amount, false, amountRaised);
			}
		}
	}

}