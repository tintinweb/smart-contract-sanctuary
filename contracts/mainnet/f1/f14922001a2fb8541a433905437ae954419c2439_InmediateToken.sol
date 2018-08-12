pragma solidity 0.4.24;


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


/// @title Owned - Add an owner to the contract.
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


/// @title SafeMath contract - Math operations with safety checks.
/// @author OpenZeppelin: https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts/math/SafeMath.sol
library SafeMath {
	/**
	* @dev Multiplies two numbers, throws on overflow.
	*/
	function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
		if (a == 0) {
			return 0;
		}
		c = a * b;
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
	function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
		c = a + b;
		assert(c >= a);
		return c;
	}
}


/// @title StandardToken - Implements ERC 20 Token standard: https://github.com/ethereum/EIPs/issues/20
/// @author Zerion - <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="a8c1c6cac7d0e8d2cddac1c7c686c1c7">[email&#160;protected]</a>>
contract StandardToken is AbstractToken, Owned {
	using SafeMath for uint256;

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
		require(_value <= allowed[_from][msg.sender]);
		allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
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
		require(_value <= balances[_from]);
		require(_to != address(0));

		balances[_from] = balances[_from].sub(_value);
		balances[_to] = balances[_to].add(_value);
		emit Transfer(_from, _to, _value);
		return true;
	}
}


/// @title BurnableToken contract - Implements burnable functionality of the ERC-20 token
/// @author Zerion - <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="ed84838f8295ad97889f848283c38482">[email&#160;protected]</a>>
contract BurnableToken is StandardToken {

	address public burner;

	modifier onlyBurner {
		require(msg.sender == burner);
		_;
	}

	event NewBurner(address burner);

	function setBurner(address _burner)
		public
		onlyOwner
	{
		burner = _burner;
		emit NewBurner(_burner);
	}

	function burn(uint256 amount)
		public
		onlyBurner
	{
		require(balanceOf(msg.sender) >= amount);
		balances[msg.sender] = balances[msg.sender].sub(amount);
		totalSupply = totalSupply.sub(amount);
		emit Transfer(msg.sender, address(0x0000000000000000000000000000000000000000), amount);
	}
}


/// @title Token contract - Implements Standard ERC20 with additional features.
/// @author Zerion - <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="167f7874796e566c73647f7978387f79">[email&#160;protected]</a>>
contract Token is BurnableToken {

	// Time of the contract creation
	uint256 public creationTime;

	constructor() public {
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
		assert(receiverNewBalance == receiverBalance.add(_value));

		return true;
	}

	/// @dev Increases approved amount of tokens for spender. Returns success.
	function increaseApproval(address _spender, uint256 _value) public returns (bool success) {
		allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_value);
		emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}

	/// @dev Decreases approved amount of tokens for spender. Returns success.
	function decreaseApproval(address _spender, uint256 _value) public returns (bool success) {
		uint256 oldValue = allowed[msg.sender][_spender];
		if (_value > oldValue) {
			allowed[msg.sender][_spender] = 0;
		} else {
			allowed[msg.sender][_spender] = oldValue.sub(_value);
		}
		emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}
}

/// @title Token contract - Implements Standard ERC20 Token for Inmediate project.
/// @author Zerion - <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="b9d0d7dbd6c1f9c3dccbd0d6d797d0d6">[email&#160;protected]</a>>
contract InmediateToken is Token {

	/// TOKEN META DATA
	string constant public name = &#39;Inmediate&#39;;
	string constant public symbol = &#39;DIT&#39;;
	uint8  constant public decimals = 8;


	/// ALLOCATIONS
	// To calculate vesting periods we assume that 1 month is always equal to 30 days 


	/*** Initial Investors&#39; tokens ***/

	// 400,000,000 (40%) tokens are distributed among initial investors
	// These tokens will be distributed without vesting

	address public investorsAllocation = address(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF);
	uint256 public investorsTotal = 400000000e8;


	/*** Tokens reserved for the Inmediate team ***/

	// 100,000,000 (10%) tokens will be eventually available for the team
	// These tokens will be distributed querterly after a 6 months cliff
	// 20,000,000 will be unlocked immediately after 6 months
	// 10,000,000 tokens will be unlocked quarterly within 2 years after the cliff

	address public teamAllocation  = address(0x1111111111111111111111111111111111111111);
	uint256 public teamTotal = 100000000e8;
	uint256 public teamPeriodAmount = 10000000e8;
	uint256 public teamCliff = 6 * 30 days;
	uint256 public teamUnlockedAfterCliff = 20000000e8;
	uint256 public teamPeriodLength = 3 * 30 days;
	uint8   public teamPeriodsNumber = 8;

	/*** Tokens reserved for Advisors ***/

	// 50,000,000 (5%) tokens will be eventually available for advisors
	// These tokens will be distributed querterly after a 6 months cliff
	// 10,000,000 will be unlocked immediately after 6 months
	// 10,000,000 tokens will be unlocked quarterly within a year after the cliff

	address public advisorsAllocation  = address(0x2222222222222222222222222222222222222222);
	uint256 public advisorsTotal = 50000000e8;
	uint256 public advisorsPeriodAmount = 10000000e8;
	uint256 public advisorsCliff = 6 * 30 days;
	uint256 public advisorsUnlockedAfterCliff = 10000000e8;
	uint256 public advisorsPeriodLength = 3 * 30 days;
	uint8   public advisorsPeriodsNumber = 4;


	/*** Tokens reserved for pre- and post- ICO Bounty ***/

	// 50,000,000 (5%) tokens will be spent on various bounty campaigns
	// These tokens are available immediately, without vesting


	address public bountyAllocation  = address(0x3333333333333333333333333333333333333333);
	uint256 public bountyTotal = 50000000e8;


	/*** Liquidity pool ***/

	// 150,000,000 (15%) tokens will be used to manage token volatility
	// These tokens are available immediately, without vesting


	address public liquidityPoolAllocation  = address(0x4444444444444444444444444444444444444444);
	uint256 public liquidityPoolTotal = 150000000e8;


	/*** Tokens reserved for Contributors ***/

	// 250,000,000 (25%) tokens will be used to reward parties that contribute to the ecosystem
	// These tokens are available immediately, without vesting


	address public contributorsAllocation  = address(0x5555555555555555555555555555555555555555);
	uint256 public contributorsTotal = 250000000e8;


	/// CONSTRUCTOR

	constructor() public {
		//  Overall, 1,000,000,000 tokens exist
		totalSupply = 1000000000e8;

		balances[investorsAllocation] = investorsTotal;
		balances[teamAllocation] = teamTotal;
		balances[advisorsAllocation] = advisorsTotal;
		balances[bountyAllocation] = bountyTotal;
		balances[liquidityPoolAllocation] = liquidityPoolTotal;
		balances[contributorsAllocation] = contributorsTotal;
		

		// Unlock some tokens without vesting
		allowed[investorsAllocation][msg.sender] = investorsTotal;
		allowed[bountyAllocation][msg.sender] = bountyTotal;
		allowed[liquidityPoolAllocation][msg.sender] = liquidityPoolTotal;
		allowed[contributorsAllocation][msg.sender] = contributorsTotal;
	}

	/// DISTRIBUTION

	function distributeInvestorsTokens(address _to, uint256 _amountWithDecimals)
		public
		onlyOwner
	{
		require(transferFrom(investorsAllocation, _to, _amountWithDecimals));
	}

	/// VESTED ALLOCATIONS

	function withdrawTeamTokens(address _to, uint256 _amountWithDecimals)
		public
		onlyOwner 
	{
		allowed[teamAllocation][msg.sender] = allowance(teamAllocation, msg.sender);
		require(transferFrom(teamAllocation, _to, _amountWithDecimals));
	}

	function withdrawAdvisorsTokens(address _to, uint256 _amountWithDecimals)
		public
		onlyOwner 
	{
		allowed[advisorsAllocation][msg.sender] = allowance(advisorsAllocation, msg.sender);
		require(transferFrom(advisorsAllocation, _to, _amountWithDecimals));
	}


	/// UNVESTED ALLOCATIONS

	function withdrawBountyTokens(address _to, uint256 _amountWithDecimals)
		public
		onlyOwner
	{
		require(transferFrom(bountyAllocation, _to, _amountWithDecimals));
	}

	function withdrawLiquidityPoolTokens(address _to, uint256 _amountWithDecimals)
		public
		onlyOwner
	{
		require(transferFrom(liquidityPoolAllocation, _to, _amountWithDecimals));
	}

	function withdrawContributorsTokens(address _to, uint256 _amountWithDecimals)
		public
		onlyOwner
	{
		require(transferFrom(contributorsAllocation, _to, _amountWithDecimals));
	}
	
	/// OVERRIDEN FUNCTIONS

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

		if (_owner == teamAllocation) {
			unlockedTokens = _calculateUnlockedTokens(
				teamCliff, teamUnlockedAfterCliff,
				teamPeriodLength, teamPeriodAmount, teamPeriodsNumber
			);
			spentTokens = balanceOf(teamAllocation) < teamTotal ? teamTotal.sub(balanceOf(teamAllocation)) : 0;
		} else if (_owner == advisorsAllocation) {
			unlockedTokens = _calculateUnlockedTokens(
				advisorsCliff, advisorsUnlockedAfterCliff,
				advisorsPeriodLength, advisorsPeriodAmount, advisorsPeriodsNumber
			);
			spentTokens = balanceOf(advisorsAllocation) < advisorsTotal ? advisorsTotal.sub(balanceOf(advisorsAllocation)) : 0;
		} else {
			return allowed[_owner][_spender];
		}

		return unlockedTokens.sub(spentTokens);
	}

	/// @dev Overrides Owned.sol function
	function confirmOwnership()
		public
		onlyPotentialOwner
	{   
		// Forbids the old owner to distribute investors&#39; tokens
		allowed[investorsAllocation][owner] = 0;

		// Allows the new owner to distribute investors&#39; tokens
		allowed[investorsAllocation][msg.sender] = balanceOf(investorsAllocation);

		// Forbidsthe old owner to withdraw any tokens from the reserves
		allowed[teamAllocation][owner] = 0;
		allowed[advisorsAllocation][owner] = 0;
		allowed[bountyAllocation][owner] = 0;
		allowed[liquidityPoolAllocation][owner] = 0;
		allowed[contributorsAllocation][owner] = 0;

		// Allows the new owner to withdraw tokens from the unvested allocations
		allowed[bountyAllocation][msg.sender] = balanceOf(bountyAllocation);
		allowed[liquidityPoolAllocation][msg.sender] = balanceOf(liquidityPoolAllocation);
		allowed[contributorsAllocation][msg.sender] = balanceOf(contributorsAllocation);
		
		super.confirmOwnership();
	}

	/// PRIVATE FUNCTIONS

	function _calculateUnlockedTokens(
		uint256 _cliff,
		uint256 _unlockedAfterCliff,
		uint256 _periodLength,
		uint256 _periodAmount,
		uint8 _periodsNumber
	)
		private
		view
		returns (uint256) 
	{
		/* solium-disable-next-line security/no-block-members */
		if (now < creationTime.add(_cliff)) {
			return 0;
		}
		/* solium-disable-next-line security/no-block-members */
		uint256 periods = now.sub(creationTime.add(_cliff)).div(_periodLength);
		periods = periods > _periodsNumber ? _periodsNumber : periods;
		return _unlockedAfterCliff.add(periods.mul(_periodAmount));
	}
}