/**
 *Submitted for verification at Etherscan.io on 2021-07-08
*/

pragma solidity ^0.4.24;
/*
    Owned contract interface
*/
contract IOwned {
    // this function isn't abstract since the compiler emits automatically generated getter functions as external
    function owner() public constant returns (address) {}

    function transferOwnership(address _newOwner) public;
    function acceptOwnership() public;
}


/*
    ERC20 Standard Token interface
*/
contract IERC20Token {
    // these functions aren't abstract since the compiler emits automatically generated getter functions as external
    function name() public constant returns (string) {}
    function symbol() public constant returns (string) {}
    function decimals() public constant returns (uint8) {}
    function totalSupply() public constant returns (uint256) {}
    function balanceOf(address _owner) public constant returns (uint256) { _owner; }
    function allowance(address _owner, address _spender) public constant returns (uint256) { _owner; _spender; }

    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
}


/*
    Provides support and utilities for contract ownership
*/
contract Owned is IOwned {
	address public owner;
	address public newOwner;

	event OwnerUpdate(address _prevOwner, address _newOwner);

	/**
		@dev constructor
	*/
	constructor () public {
		owner = msg.sender;
	}

	// allows execution by the owner only
	modifier ownerOnly {
		assert(msg.sender == owner);
		_;
	}

	/**
		@dev allows transferring the contract ownership
		the new owner still needs to accept the transfer
		can only be called by the contract owner

		@param _newOwner    new contract owner
	*/
	function transferOwnership(address _newOwner) public ownerOnly {
		require(_newOwner != owner);
		newOwner = _newOwner;
	}

	/**
		@dev used by a new owner to accept an ownership transfer
	*/
	function acceptOwnership() public {
		require(msg.sender == newOwner);
		emit OwnerUpdate(owner, newOwner);
		owner = newOwner;
		newOwner = 0x0;
	}
}


contract CrowdSale is Owned 
{

	uint constant public softCap = 300000 * 1 ether;

	uint constant public startDate = 1625260546;

	uint constant public endDate = 1751491846;

	uint constant public price = 1000000000000000;

	uint public amountRaised;

	IERC20Token public tokenReward;

	mapping (address => uint256) public balanceOf;

	bool public crowdSaleClosed = false;

	bool public crowdSalePaused = false;

	event FundTransfer(address backer, uint amount, bool isContribution);

	/**
	 * Constrctor function
	 *
	 * Setup the owner
	 */
    constructor (address addressOfTokenUsedAsReward) public {
		tokenReward = IERC20Token(addressOfTokenUsedAsReward);
	}

	/**
	 * Fallback function
	 *
	 * The function without name is the default function that is called whenever anyone sends funds to a contract
	 */
	function() payable external {
		require(!crowdSaleClosed);
		require(!crowdSalePaused);
		require(startDate <= now);
		require(endDate >= now);

		uint contractTokenBalance = tokenReward.balanceOf(this);
		require(contractTokenBalance > 0);

		uint amount = msg.value;
		uint tokenAmount = amount / price;

		if (tokenAmount > contractTokenBalance) {
			tokenAmount = contractTokenBalance;
		}

		amount = tokenAmount * price;
		if (amount < msg.value) {
			msg.sender.transfer(msg.value - amount);
		}

		balanceOf[msg.sender] += amount;
		amountRaised += amount;
		tokenReward.transfer(msg.sender, tokenAmount);
		emit FundTransfer(msg.sender, amount, true);
	}

	/**
		Set or off pause crowdsale
		@param _pause - true or false (1 or 0)
	*/
	function setPauseStatus(bool _pause) external ownerOnly {
		require(amountRaised >= softCap);
		crowdSalePaused = _pause;
	}


	/**
		Close crowdsale
	*/
	function closeCrowdsale() external ownerOnly {
		require(amountRaised >= softCap);
		crowdSaleClosed = true;
	}

	/**
	 * Withdraw the funds
	 *
	 * Checks to see if goal or time limit has been reached, and if so, and the funding goal was reached,
	 * sends the entire amount to the owner. If goal was not reached, each contributor can withdraw
	 * the amount they contributed.
	 */
	function safeWithdrawal() external ownerOnly {
		require(crowdSaleClosed || endDate < now || tokenReward.balanceOf(this) == 0);
		owner.transfer(address(this).balance);
	}
}