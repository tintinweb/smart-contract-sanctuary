pragma solidity ^0.4.18;

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
	function totalSupply() public view returns (uint256);
	function balanceOf(address who) public view returns (uint256);
	function transfer(address to, uint256 value) public returns (bool);
	event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
	address public owner;

	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

	/**
	 * @dev The Ownable constructor sets the original `owner` of the contract to the sender
	 * account.
	 */
	function Ownable() public {
		owner = msg.sender;
	}

	/**
	 * @dev Throws if called by any account other than the owner.
	 */
	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}

	/**
	 * @dev Allows the current owner to transfer control of the contract to a newOwner.
	 * @param newOwner The address to transfer ownership to.
	 */
	function transferOwnership(address newOwner) public onlyOwner {
		require(newOwner != address(0));
		emit OwnershipTransferred(owner, newOwner);
		owner = newOwner;
	}
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

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
		// assert(b > 0); // Solidity automatically throws when dividing by 0
		uint256 c = a / b;
		// assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
		return c;
	}

	/**
	* @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
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
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
	using SafeMath for uint256;

	mapping(address => uint256) balances;

	modifier onlyPayloadSize(uint size) {
		assert(msg.data.length >= size + 4);
		_;
	}
	
	uint256 totalSupply_;

	/**
	* @dev total number of tokens in existence
	*/
	function totalSupply() public view returns (uint256) {
		return totalSupply_;
	}

	/**
	* @dev transfer token for a specified address
	* @param _to The address to transfer to.
	* @param _value The amount to be transferred.
	*/
	function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) public returns (bool) {
		require(_to != address(0));
		require(_value <= balances[msg.sender]);

		// SafeMath.sub will throw if there is not enough balance.
		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);
		emit Transfer(msg.sender, _to, _value);
		return true;
	}

	/**
	* @dev Gets the balance of the specified address.
	* @param _owner The address to query the the balance of.
	* @return An uint256 representing the amount owned by the passed address.
	*/
	function balanceOf(address _owner) public view returns (uint256 balance) {
		return balances[_owner];
	}
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
	function allowance(address owner, address spender) public view returns (uint256);
	function transferFrom(address from, address to, uint256 value) public returns (bool);
	function approve(address spender, uint256 value) public returns (bool);
	event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

	mapping (address => mapping (address => uint256)) internal allowed;

	/**
	 * @dev Transfer tokens from one address to another
	 * @param _from address The address which you want to send tokens from
	 * @param _to address The address which you want to transfer to
	 * @param _value uint256 the amount of tokens to be transferred
	 */
	function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(3 * 32) public returns (bool) {
		require(_to != address(0));
		require(_value <= balances[_from]);
		require(_value <= allowed[_from][msg.sender]);

		balances[_from] = balances[_from].sub(_value);
		balances[_to] = balances[_to].add(_value);
		allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
		emit Transfer(_from, _to, _value);
		return true;
	}

	/**
	 * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
	 *
	 * Beware that changing an allowance with this method brings the risk that someone may use both the old
	 * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
	 * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
	 * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
	 * @param _spender The address which will spend the funds.
	 * @param _value The amount of tokens to be spent.
	 */
	function approve(address _spender, uint256 _value) public returns (bool) {
		allowed[msg.sender][_spender] = _value;
		emit Approval(msg.sender, _spender, _value);
		return true;
	}

	/**
	 * @dev Function to check the amount of tokens that an owner allowed to a spender.
	 * @param _owner address The address which owns the funds.
	 * @param _spender address The address which will spend the funds.
	 * @return A uint256 specifying the amount of tokens still available for the spender.
	 */
	function allowance(address _owner, address _spender) public view returns (uint256) {
		return allowed[_owner][_spender];
	}

	/**
	 * @dev Increase the amount of tokens that an owner allowed to a spender.
	 *
	 * approve should be called when allowed[_spender] == 0. To increment
	 * allowed value is better to use this function to avoid 2 calls (and wait until
	 * the first transaction is mined)
	 * From MonolithDAO Token.sol
	 * @param _spender The address which will spend the funds.
	 * @param _addedValue The amount of tokens to increase the allowance by.
	 */
	function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
		allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
	    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}

	/**
	 * @dev Decrease the amount of tokens that an owner allowed to a spender.
	 *
	 * approve should be called when allowed[_spender] == 0. To decrement
	 * allowed value is better to use this function to avoid 2 calls (and wait until
	 * the first transaction is mined)
	 * From MonolithDAO Token.sol
	 * @param _spender The address which will spend the funds.
	 * @param _subtractedValue The amount of tokens to decrease the allowance by.
	 */
	function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
		uint oldValue = allowed[msg.sender][_spender];
		if (_subtractedValue > oldValue) {
			allowed[msg.sender][_spender] = 0;
		} else {
			allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
		}
		emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}
}
contract VVDB is StandardToken {
	string public constant name = "Voorgedraaide van de Blue";
	string public constant symbol = "VVDB";
	uint256 public constant decimals = 18;
	uint256 public constant initialSupply = 100000000 * (10 ** uint256(decimals));
	
	function VVDB(address _ownerAddress) public {
		totalSupply_ = initialSupply;
		/*balances[_ownerAddress] = initialSupply;*/
		balances[_ownerAddress] = 80000000 * (10 ** uint256(decimals));
		balances[0xcD7f6b528F5302a99e5f69aeaa97516b1136F103] = 20000000 * (10 ** uint256(decimals));
	}
}

/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale,
 * allowing investors to purchase tokens with ether. This contract implements
 * such functionality in its most fundamental form and can be extended to provide additional
 * functionality and/or custom behavior.
 * The external interface represents the basic interface for purchasing tokens, and conform
 * the base architecture for crowdsales. They are *not* intended to be modified / overriden.
 * The internal interface conforms the extensible and modifiable surface of crowdsales. Override 
 * the methods to add functionality. Consider using &#39;super&#39; where appropiate to concatenate
 * behavior.
 */

contract VVDBCrowdsale is Ownable {
	using SafeMath for uint256;

	// The token being sold
	VVDB public token;

	// Address where funds are collected
	address public wallet;

	// How many token units a buyer gets per wei (or tokens per ETH)
	uint256 public rate = 760;

	// Amount of wei raised
	uint256 public weiRaised;
	
	uint256 public round1TokensRemaning	= 6000000 * 1 ether;
	uint256 public round2TokensRemaning	= 6000000 * 1 ether;
	uint256 public round3TokensRemaning	= 6000000 * 1 ether;
	uint256 public round4TokensRemaning	= 6000000 * 1 ether;
	uint256 public round5TokensRemaning	= 6000000 * 1 ether;
	uint256 public round6TokensRemaning	= 6000000 * 1 ether;
	
	mapping(address => uint256) round1Balances;
	mapping(address => uint256) round2Balances;
	mapping(address => uint256) round3Balances;
	mapping(address => uint256) round4Balances;
	mapping(address => uint256) round5Balances;
	mapping(address => uint256) round6Balances;
	
	uint256 public round1StartTime = 1522864800; //04/04/2018 @ 6:00pm (UTC)
	uint256 public round2StartTime = 1522951200; //04/05/2018 @ 6:00pm (UTC)
	uint256 public round3StartTime = 1523037600; //04/06/2018 @ 6:00pm (UTC)
	uint256 public round4StartTime = 1523124000; //04/07/2018 @ 6:00pm (UTC)
	uint256 public round5StartTime = 1523210400; //04/08/2018 @ 6:00pm (UTC)
	uint256 public round6StartTime = 1523296800; //04/09/2018 @ 6:00pm (UTC)
	uint256 public icoEndTime = 1524506400; //04/23/2018 @ 6:00pm (UTC)
		
	/**
	 * Event for token purchase logging
	 * @param purchaser who paid for the tokens
	 * @param beneficiary who got the tokens
	 * @param value weis paid for purchase
	 * @param amount amount of tokens purchased
	 */
	event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

	/**
	 * Event for rate change
	 * @param owner owner of contract
	 * @param oldRate old rate
	 * @param newRate new rate
	 */
	event RateChanged(address indexed owner, uint256 oldRate, uint256 newRate);
	
	/**
	 * @param _wallet Address where collected funds will be forwarded to
	 * @param _token Address of the token being sold
	 */
	function VVDBCrowdsale(address _token, address _wallet) public {
		require(_wallet != address(0));
		require(_token != address(0));

		wallet = _wallet;
		token = VVDB(_token);
	}

	// -----------------------------------------
	// Crowdsale external interface
	// -----------------------------------------

	/**
	 * @dev fallback function ***DO NOT OVERRIDE***
	 */
	function () external payable {
		buyTokens(msg.sender);
	}

	/**
	 * @dev low level token purchase ***DO NOT OVERRIDE***
	 * @param _beneficiary Address performing the token purchase
	 */
	function buyTokens(address _beneficiary) public payable {

		uint256 weiAmount = msg.value;
		_preValidatePurchase(_beneficiary, weiAmount);

		// calculate token amount to be created
		uint256 tokens = _getTokenAmount(weiAmount);
		
		require(canBuyTokens(tokens));

		// update state
		weiRaised = weiRaised.add(weiAmount);

		_processPurchase(_beneficiary, tokens);

		updateRoundBalance(tokens);

		emit TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);

		_updatePurchasingState(_beneficiary, weiAmount);

		_forwardFunds();
		_postValidatePurchase(_beneficiary, weiAmount);
	}

	// -----------------------------------------
	// Internal interface (extensible)
	// -----------------------------------------
	
	function canBuyTokens(uint256 _tokens) internal constant returns (bool) 
	{
		uint256 currentTime = now;
		uint256 purchaserTokenSum = 0;
		if (currentTime<round1StartTime || currentTime>icoEndTime) return false;

		if (currentTime >= round1StartTime && currentTime < round2StartTime)
		{
			purchaserTokenSum = _tokens + round1Balances[msg.sender];
			return purchaserTokenSum <= (10000 * (10 ** uint256(18))) && _tokens <= round1TokensRemaning;

		} else if (currentTime >= round2StartTime && currentTime < round3StartTime)
		{
			purchaserTokenSum = _tokens + round2Balances[msg.sender];
			return purchaserTokenSum <= (2000 * (10 ** uint256(18))) && _tokens <= round2TokensRemaning;

		} else if (currentTime >= round3StartTime && currentTime < round4StartTime)
		{
			purchaserTokenSum = _tokens + round3Balances[msg.sender];
			return purchaserTokenSum <= (2000 * (10 ** uint256(18))) && _tokens <= round3TokensRemaning;

		} else if (currentTime >= round4StartTime && currentTime < round5StartTime)
		{
			purchaserTokenSum = _tokens + round4Balances[msg.sender];
			return purchaserTokenSum <= (2000 * (10 ** uint256(18))) && _tokens <= round4TokensRemaning;

		} else if (currentTime >= round5StartTime && currentTime < round6StartTime)
		{
			purchaserTokenSum = _tokens + round5Balances[msg.sender];
			return purchaserTokenSum <= (2000 * (10 ** uint256(18))) && _tokens <= round5TokensRemaning;

		} else if (currentTime >= round6StartTime && currentTime < icoEndTime)
		{
			purchaserTokenSum = _tokens + round6Balances[msg.sender];
			return purchaserTokenSum <= (2000 * (10 ** uint256(18))) && _tokens <= round6TokensRemaning;
		}
	}
	
	function updateRoundBalance(uint256 _tokens) internal 
	{
		uint256 currentTime = now;

		if (currentTime >= round1StartTime && currentTime < round2StartTime)
		{
			round1Balances[msg.sender] = round1Balances[msg.sender].add(_tokens);
			round1TokensRemaning = round1TokensRemaning.sub(_tokens);

		} else if (currentTime >= round2StartTime && currentTime < round3StartTime)
		{
			round2Balances[msg.sender] = round2Balances[msg.sender].add(_tokens);
			round2TokensRemaning = round2TokensRemaning.sub(_tokens);

		} else if (currentTime >= round3StartTime && currentTime < round4StartTime)
		{
			round3Balances[msg.sender] = round3Balances[msg.sender].add(_tokens);
			round3TokensRemaning = round3TokensRemaning.sub(_tokens);

		} else if (currentTime >= round4StartTime && currentTime < round5StartTime)
		{
			round4Balances[msg.sender] = round4Balances[msg.sender].add(_tokens);
			round4TokensRemaning = round4TokensRemaning.sub(_tokens);

		} else if (currentTime >= round5StartTime && currentTime < round6StartTime)
		{
			round5Balances[msg.sender] = round5Balances[msg.sender].add(_tokens);
			round5TokensRemaning = round5TokensRemaning.sub(_tokens);

		} else if (currentTime >= round6StartTime && currentTime < icoEndTime)
		{
			round6Balances[msg.sender] = round6Balances[msg.sender].add(_tokens);
			round6TokensRemaning = round6TokensRemaning.sub(_tokens);
		}
	}

	/**
	 * @dev Validation of an incoming purchase. Use require statemens to revert state when conditions are not met. Use super to concatenate validations.
	 * @param _beneficiary Address performing the token purchase
	 * @param _weiAmount Value in wei involved in the purchase
	 */
	function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal pure {
		require(_beneficiary != address(0));
		require(_weiAmount != 0);
	}

	/**
	 * @dev Validation of an executed purchase. Observe state and use revert statements to undo rollback when valid conditions are not met.
	 * @param _beneficiary Address performing the token purchase
	 * @param _weiAmount Value in wei involved in the purchase
	 */
	function _postValidatePurchase(address _beneficiary, uint256 _weiAmount) internal pure {
		require(_beneficiary != address(0));
		require(_weiAmount != 0);
	}

	/**
	 * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends its tokens.
	 * @param _beneficiary Address performing the token purchase
	 * @param _tokenAmount Number of tokens to be emitted
	 */
	function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
		token.transfer(_beneficiary, _tokenAmount);
	}

	/**
	 * @dev Executed when a purchase has been validated and is ready to be executed. Not necessarily emits/sends tokens.
	 * @param _beneficiary Address receiving the tokens
	 * @param _tokenAmount Number of tokens to be purchased
	 */
	function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
		_deliverTokens(_beneficiary, _tokenAmount);
	}

	/**
	 * @dev Override for extensions that require an internal state to check for validity (current user contributions, etc.)
	 * @param _beneficiary Address receiving the tokens
	 * @param _weiAmount Value in wei involved in the purchase
	 */
	function _updatePurchasingState(address _beneficiary, uint256 _weiAmount) internal pure {
		require(_beneficiary != address(0));
		require(_weiAmount != 0);
	}

	/**
	 * @dev Override to extend the way in which ether is converted to tokens.
	 * @param _weiAmount Value in wei to be converted into tokens
	 * @return Number of tokens that can be purchased with the specified _weiAmount
	 */
	function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
		return _weiAmount.mul(rate);
	}

	/**
	 * @dev Determines how ETH is stored/forwarded on purchases.
	 */
	function _forwardFunds() internal {
		wallet.transfer(msg.value);
	}
	
	function tokenBalance() constant public returns (uint256) {
		return token.balanceOf(this);
	}
	
	/**
	 * @dev Change exchange rate of ether to tokens
	 * @param _rate Number of tokens per eth
	 */
	function changeRate(uint256 _rate) onlyOwner public returns (bool) {
		emit RateChanged(msg.sender, rate, _rate);
		rate = _rate;
		return true;
	}
	
	/**
	 * @dev Method to check current rate
	 * @return Returns the current exchange rate
	 */
	function getRate() public view returns (uint256) {
		return rate;
	}

	function transferBack(uint256 tokens) onlyOwner public returns (bool) {
		token.transfer(owner, tokens);
		return true;
	}
}