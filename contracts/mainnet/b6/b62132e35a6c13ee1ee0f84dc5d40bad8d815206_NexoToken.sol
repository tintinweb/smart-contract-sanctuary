pragma solidity 0.4.23;

//
// This source file is part of the current-contracts open source project
// Copyright 2018 Zerion LLC
// Licensed under Apache License v2.0
//


// @title Abstract ERC20 token interface
contract AbstractToken {
	function balanceOf(address owner) public view returns (uint256 balance);
	function transfer(address to, uint256 value) public returns (bool success);
	function transferFrom(address from, address to, uint256 value) public returns (bool success);
	function approve(address spender, uint256 value) public returns (bool success);
	function allowance(address owner, address spender) public view returns (uint256 remaining);

	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Owned {

	address public owner = msg.sender;
	address public potentialOwner;

	modifier onlyOwner {
		require(msg.sender == owner);
		_;
	}

	modifier onlyPotentialOwner {
		require(msg.sender == potentialOwner);
		_;
	}

	event NewOwner(address old, address current);
	event NewPotentialOwner(address old, address potential);

	function setOwner(address _new)
		public
		onlyOwner
	{
		emit NewPotentialOwner(owner, _new);
		potentialOwner = _new;
	}

	function confirmOwnership()
		public
		onlyPotentialOwner
	{
		emit NewOwner(owner, potentialOwner);
		owner = potentialOwner;
		potentialOwner = address(0);
	}
}

// @title SafeMath contract - Math operations with safety checks.
// @author OpenZeppelin: https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts/math/SafeMath.sol
contract SafeMath {
	/**
	* @dev Multiplies two numbers, throws on overflow.
	*/
	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		if (a == 0) {
			return 0;
		}
		uint256 c = a * b;
		assert(c / a == b);
		return c;
	}

	/**
	* @dev Integer division of two numbers, truncating the quotient.
	*/
	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		return a / b;
	}

	/**
	* @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
	*/
	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		assert(b <= a);
		return a - b;
	}

	/**
	* @dev Adds two numbers, throws on overflow.
	*/
	function add(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
		assert(c >= a);
		return c;
	}

	/**
	* @dev Raises `a` to the `b`th power, throws on overflow.
	*/
	function pow(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a ** b;
		assert(c >= a);
		return c;
	}
}

/// Implements ERC 20 Token standard: https://github.com/ethereum/EIPs/issues/20
contract StandardToken is AbstractToken, Owned, SafeMath {

	/*
	 *  Data structures
	 */
	mapping (address => uint256) internal balances;
	mapping (address => mapping (address => uint256)) internal allowed;
	uint256 public totalSupply;

	/*
	 *  Read and write storage functions
	 */
	/// @dev Transfers sender&#39;s tokens to a given address. Returns success.
	/// @param _to Address of token receiver.
	/// @param _value Number of tokens to transfer.
	function transfer(address _to, uint256 _value) public returns (bool success) {
		return _transfer(msg.sender, _to, _value);
	}

	/// @dev Allows allowed third party to transfer tokens from one address to another. Returns success.
	/// @param _from Address from where tokens are withdrawn.
	/// @param _to Address to where tokens are sent.
	/// @param _value Number of tokens to transfer.
	function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
		require(allowed[_from][msg.sender] >= _value);
		allowed[_from][msg.sender] -= _value;

		return _transfer(_from, _to, _value);
	}

	/// @dev Returns number of tokens owned by given address.
	/// @param _owner Address of token owner.
	function balanceOf(address _owner) public view returns (uint256 balance) {
		return balances[_owner];
	}

	/// @dev Sets approved amount of tokens for spender. Returns success.
	/// @param _spender Address of allowed account.
	/// @param _value Number of approved tokens.
	function approve(address _spender, uint256 _value) public returns (bool success) {
		allowed[msg.sender][_spender] = _value;
		emit Approval(msg.sender, _spender, _value);
		return true;
	}

	/*
	 * Read storage functions
	 */
	/// @dev Returns number of allowed tokens for given address.
	/// @param _owner Address of token owner.
	/// @param _spender Address of token spender.
	function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
		return allowed[_owner][_spender];
	}

	/**
	* @dev Private transfer, can only be called by this contract.
	* @param _from The address of the sender.
	* @param _to The address of the recipient.
	* @param _value The amount to send.
	* @return success True if the transfer was successful, or throws.
	*/
	function _transfer(address _from, address _to, uint256 _value) private returns (bool success) {
		require(_to != address(0));
		require(balances[_from] >= _value);
		balances[_from] -= _value;
		balances[_to] = add(balances[_to], _value);
		emit Transfer(_from, _to, _value);
		return true;
	}
}

/// @title Token contract - Implements Standard ERC20 with additional features.
/// @author Zerion - <<span class="__cf_email__" data-cfemail="e68f8884899ea69c83948f8988c88f89">[email&#160;protected]</span>>
contract Token is StandardToken {

	// Time of the contract creation
	uint256 public creationTime;

	function Token() public {
		/* solium-disable-next-line security/no-block-members */
		creationTime = now;
	}

	/// @dev Owner can transfer out any accidentally sent ERC20 tokens
	function transferERC20Token(AbstractToken _token, address _to, uint256 _value)
		public
		onlyOwner
		returns (bool success)
	{
		require(_token.balanceOf(address(this)) >= _value);
		uint256 receiverBalance = _token.balanceOf(_to);
		require(_token.transfer(_to, _value));

		uint256 receiverNewBalance = _token.balanceOf(_to);
		assert(receiverNewBalance == add(receiverBalance, _value));

		return true;
	}

	/// @dev Increases approved amount of tokens for spender. Returns success.
	function increaseApproval(address _spender, uint256 _value) public returns (bool success) {
		allowed[msg.sender][_spender] = add(allowed[msg.sender][_spender], _value);
		emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}

	/// @dev Decreases approved amount of tokens for spender. Returns success.
	function decreaseApproval(address _spender, uint256 _value) public returns (bool success) {
		uint256 oldValue = allowed[msg.sender][_spender];
		if (_value > oldValue) {
			allowed[msg.sender][_spender] = 0;
		} else {
			allowed[msg.sender][_spender] = sub(oldValue, _value);
		}
		emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}
}

// @title Token contract - Implements Standard ERC20 Token for NEXO project.
/// @author Zerion - <<span class="__cf_email__" data-cfemail="d4bdbab6bbac94aeb1a6bdbbbafabdbb">[email&#160;protected]</span>>
contract NexoToken is Token {

	/// TOKEN META DATA
	string constant public name = &#39;Nexo&#39;;
	string constant public symbol = &#39;NEXO&#39;;
	uint8  constant public decimals = 18;


	/// ALOCATIONS
	// To calculate vesting periods we assume that 1 month is always equal to 30 days 


	/*** Initial Investors&#39; tokens ***/

	// 525,000,000 (52.50%) tokens are distributed among initial investors
	// These tokens will be distributed without vesting

	address public investorsAllocation = address(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF);
	uint256 public investorsTotal = 525000000e18;


	/*** Overdraft Reserves ***/

	// 250,000,000 (25%) tokens will be eventually available for overdraft
	// These tokens will be distributed monthly with a 6 month cliff within a year
	// 41,666,666 tokens will be unlocked every month after the cliff
	// 4 tokens will be unlocked without vesting to ensure that total amount sums up to 250,000,000.

	address public overdraftAllocation = address(0x1111111111111111111111111111111111111111);
	uint256 public overdraftTotal = 250000000e18;
	uint256 public overdraftPeriodAmount = 41666666e18;
	uint256 public overdraftUnvested = 4e18;
	uint256 public overdraftCliff = 5 * 30 days;
	uint256 public overdraftPeriodLength = 30 days;
	uint8   public overdraftPeriodsNumber = 6;


	/*** Tokens reserved for Founders and Team ***/

	// 112,500,000 (11.25%) tokens will be eventually available for the team
	// These tokens will be distributed every 3 month without a cliff within 4 years
	// 7,031,250 tokens will be unlocked every 3 month

	address public teamAllocation  = address(0x2222222222222222222222222222222222222222);
	uint256 public teamTotal = 112500000e18;
	uint256 public teamPeriodAmount = 7031250e18;
	uint256 public teamUnvested = 0;
	uint256 public teamCliff = 0;
	uint256 public teamPeriodLength = 3 * 30 days;
	uint8   public teamPeriodsNumber = 16;



	/*** Tokens reserved for Community Building and Airdrop Campaigns ***/

	// 60,000,000 (6%) tokens will be eventually available for the community
	// 10,000,002 tokens will be available instantly without vesting
	// 49,999,998 tokens will be distributed every 3 month without a cliff within 18 months
	// 8,333,333 tokens will be unlocked every 3 month


	address public communityAllocation  = address(0x3333333333333333333333333333333333333333);
	uint256 public communityTotal = 60000000e18;
	uint256 public communityPeriodAmount = 8333333e18;
	uint256 public communityUnvested = 10000002e18;
	uint256 public communityCliff = 0;
	uint256 public communityPeriodLength = 3 * 30 days;
	uint8   public communityPeriodsNumber = 6;



	/*** Tokens reserved for Advisors, Legal and PR ***/

	// 52,500,000 (5.25%) tokens will be eventually available for advisers
	// 25,000,008 tokens will be available instantly without vesting
	// 27&#160;499&#160;992 tokens will be distributed monthly without a cliff within 12 months
	// 2,291,666 tokens will be unlocked every month

	address public advisersAllocation  = address(0x4444444444444444444444444444444444444444);
	uint256 public advisersTotal = 52500000e18;
	uint256 public advisersPeriodAmount = 2291666e18;
	uint256 public advisersUnvested = 25000008e18;
	uint256 public advisersCliff = 0;
	uint256 public advisersPeriodLength = 30 days;
	uint8   public advisersPeriodsNumber = 12;


	/// CONSTRUCTOR

	function NexoToken() public {
		//  Overall, 1,000,000,000 tokens exist
		totalSupply = 1000000000e18;

		balances[investorsAllocation] = investorsTotal;
		balances[overdraftAllocation] = overdraftTotal;
		balances[teamAllocation] = teamTotal;
		balances[communityAllocation] = communityTotal;
		balances[advisersAllocation] = advisersTotal;

		// Unlock some tokens without vesting
		allowed[investorsAllocation][msg.sender] = investorsTotal;
		allowed[overdraftAllocation][msg.sender] = overdraftUnvested;
		allowed[communityAllocation][msg.sender] = communityUnvested;
		allowed[advisersAllocation][msg.sender] = advisersUnvested;
	}

	/// DISTRIBUTION

	function distributeInvestorsTokens(address _to, uint256 _amountWithDecimals)
		public
		onlyOwner
	{
		require(transferFrom(investorsAllocation, _to, _amountWithDecimals));
	}

	/// VESTING

	function withdrawOverdraftTokens(address _to, uint256 _amountWithDecimals)
		public
		onlyOwner
	{
		allowed[overdraftAllocation][msg.sender] = allowance(overdraftAllocation, msg.sender);
		require(transferFrom(overdraftAllocation, _to, _amountWithDecimals));
	}

	function withdrawTeamTokens(address _to, uint256 _amountWithDecimals)
		public
		onlyOwner 
	{
		allowed[teamAllocation][msg.sender] = allowance(teamAllocation, msg.sender);
		require(transferFrom(teamAllocation, _to, _amountWithDecimals));
	}

	function withdrawCommunityTokens(address _to, uint256 _amountWithDecimals)
		public
		onlyOwner 
	{
		allowed[communityAllocation][msg.sender] = allowance(communityAllocation, msg.sender);
		require(transferFrom(communityAllocation, _to, _amountWithDecimals));
	}

	function withdrawAdvisersTokens(address _to, uint256 _amountWithDecimals)
		public
		onlyOwner 
	{
		allowed[advisersAllocation][msg.sender] = allowance(advisersAllocation, msg.sender);
		require(transferFrom(advisersAllocation, _to, _amountWithDecimals));
	}

	/// @dev Overrides StandardToken.sol function
	function allowance(address _owner, address _spender)
		public
		view
		returns (uint256 remaining)
	{   
		if (_spender != owner) {
			return allowed[_owner][_spender];
		}

		uint256 unlockedTokens;
		uint256 spentTokens;

		if (_owner == overdraftAllocation) {
			unlockedTokens = _calculateUnlockedTokens(
				overdraftCliff,
				overdraftPeriodLength,
				overdraftPeriodAmount,
				overdraftPeriodsNumber,
				overdraftUnvested
			);
			spentTokens = sub(overdraftTotal, balanceOf(overdraftAllocation));
		} else if (_owner == teamAllocation) {
			unlockedTokens = _calculateUnlockedTokens(
				teamCliff,
				teamPeriodLength,
				teamPeriodAmount,
				teamPeriodsNumber,
				teamUnvested
			);
			spentTokens = sub(teamTotal, balanceOf(teamAllocation));
		} else if (_owner == communityAllocation) {
			unlockedTokens = _calculateUnlockedTokens(
				communityCliff,
				communityPeriodLength,
				communityPeriodAmount,
				communityPeriodsNumber,
				communityUnvested
			);
			spentTokens = sub(communityTotal, balanceOf(communityAllocation));
		} else if (_owner == advisersAllocation) {
			unlockedTokens = _calculateUnlockedTokens(
				advisersCliff,
				advisersPeriodLength,
				advisersPeriodAmount,
				advisersPeriodsNumber,
				advisersUnvested
			);
			spentTokens = sub(advisersTotal, balanceOf(advisersAllocation));
		} else {
			return allowed[_owner][_spender];
		}

		return sub(unlockedTokens, spentTokens);
	}

	/// @dev Overrides Owned.sol function
	function confirmOwnership()
		public
		onlyPotentialOwner
	{   
		// Forbid the old owner to distribute investors&#39; tokens
		allowed[investorsAllocation][owner] = 0;

		// Allow the new owner to distribute investors&#39; tokens
		allowed[investorsAllocation][msg.sender] = balanceOf(investorsAllocation);

		// Forbid the old owner to withdraw any tokens from the reserves
		allowed[overdraftAllocation][owner] = 0;
		allowed[teamAllocation][owner] = 0;
		allowed[communityAllocation][owner] = 0;
		allowed[advisersAllocation][owner] = 0;

		super.confirmOwnership();
	}

	function _calculateUnlockedTokens(
		uint256 _cliff,
		uint256 _periodLength,
		uint256 _periodAmount,
		uint8 _periodsNumber,
		uint256 _unvestedAmount
	)
		private
		view
		returns (uint256) 
	{
		/* solium-disable-next-line security/no-block-members */
		if (now < add(creationTime, _cliff)) {
			return _unvestedAmount;
		}
		/* solium-disable-next-line security/no-block-members */
		uint256 periods = div(sub(now, add(creationTime, _cliff)), _periodLength);
		periods = periods > _periodsNumber ? _periodsNumber : periods;
		return add(_unvestedAmount, mul(periods, _periodAmount));
	}
}