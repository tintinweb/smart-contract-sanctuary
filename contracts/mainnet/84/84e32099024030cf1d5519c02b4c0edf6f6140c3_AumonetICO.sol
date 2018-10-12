pragma solidity ^0.4.25;

/**
 * @title ICO for Aumonet token based on ERC20 and ERC223 standards
 *
 * R&D performed and issued by BLOCKCHAIN INNOVATIVE TECHNOLOGIES LTD
 * Company number 11344164
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev https://github.com/ethereum/EIPs/issues/223
 * @dev Based on code from OpenZeppelin: https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/token/ERC20/StandardToken.sol
 *      and on code from Dexaran ERC223: https://github.com/Dexaran/ERC223-token-standard/blob/master/token/ERC223/ERC223_token.sol
 */

/**
 * Contract that is working with ERC223 tokens
 */

contract ContractReceiver {
	function tokenFallback(address _from, uint _value, bytes _data)public pure {
		/* Fix for Mist warning */
		_from;
		_value;
		_data;
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
	function mul(uint256 a, uint256 b)internal pure returns(uint256 c) {
		// Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
		// benefit is lost if &#39;b&#39; is also tested.
		// See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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
	function div(uint256 a, uint256 b)internal pure returns(uint256) {
		// assert(b > 0); // Solidity automatically throws when dividing by 0
		// uint256 c = a / b;
		// assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
		return a / b;
	}

	/**
	 * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
	 */
	function sub(uint256 a, uint256 b)internal pure returns(uint256) {
		assert(b <= a);
		return a - b;
	}

	/**
	 * @dev Adds two numbers, throws on overflow.
	 */
	function add(uint256 a, uint256 b)internal pure returns(uint256 c) {
		c = a + b;
		assert(c >= a);
		return c;
	}
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
	address public owner;

	event OwnershipRenounced(address indexed previousOwner);
	event OwnershipTransferred(address indexed previousOwner, address indexed _newOwner);

	/**
	 * @dev The Ownable constructor sets the original `owner` of the contract to the sender
	 * account.
	 */
	constructor()public {
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
	 * @param _newOwner The address to transfer ownership to.
	 */
	function transferOwnership(address _newOwner)public onlyOwner {
		require(_newOwner != address(0));
		emit OwnershipTransferred(owner, _newOwner);
		owner = _newOwner;
	}

	/**
	 * @dev Allows the current owner to relinquish control of the contract.
	 */
	function renounceOwnership()public onlyOwner {
		emit OwnershipRenounced(owner);
		owner = address(0);
	}
}

contract ERC223Interface {
	uint public _totalSupply;
	function balanceOf(address who)public view returns(uint);

	function totalSupply()public view returns(uint256) {
		return _totalSupply;
	}

	event Transfer(address indexed from, address indexed to, uint value, bytes data);
}

/**
 * @title Aumonet ERC223 token
 *
 * @dev Implementation of the ERC223 token.
 * @dev https://github.com/ethereum/EIPs/issues/223
 * @dev Based on code from Dexaran ERC223: https://github.com/Dexaran/ERC223-token-standard/blob/master/token/ERC223/ERC223_token.sol
 */
contract AumonetERC223 is ERC223Interface {
	using SafeMath for uint256;

	/* Contract Variables */
	address public owner;
	mapping(address => uint256)public balances;
	mapping(address => mapping(address => uint256))public allowed;

	constructor()public {
		owner = msg.sender;
	}

	/* ERC20 Events */
	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed from, address indexed to, uint256 value);

	/* ERC223 Events */
	event Transfer(address indexed from, address indexed to, uint value, bytes data);

	/* Returns the balance of a particular account */
	function balanceOf(address _address)public view returns(uint256 balance) {
		return balances[_address];
	}

	/* Transfer the balance from the sender&#39;s address to the address _to */
	function transfer(address _to, uint _value)public returns(bool success) {
		bytes memory empty;
		if (isContract(_to)) {
			return transferToContract(_to, _value, empty);
		} else {
			return transferToAddress(_to, _value, empty);
		}
	}

	/* Withdraws to address _to form the address _from up to the amount _value */
	function transferFrom(address _from, address _to, uint256 _value)public returns(bool success) {
		if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0 && balances[_to].add(_value) > balances[_to]) {
			balances[_from] = balances[_from].sub(_value);
			allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
			balances[_to] = balances[_to].add(_value);
			emit Transfer(_from, _to, _value);
			return true;
		} else {
			return false;
		}
	}

	/* Allows _spender to withdraw the _allowance amount form sender */
	function approve(address _spender, uint256 _allowance)public returns(bool success) {
		allowed[msg.sender][_spender] = _allowance;
		emit Approval(msg.sender, _spender, _allowance);
		return true;
	}

	/* Checks how much _spender can withdraw from _owner */
	function allowance(address _owner, address _spender)public view returns(uint256 remaining) {
		return allowed[_owner][_spender];
	}

	/**
	 * @notice Standard function transfer used in ERC223 with _data parameter and custom fallback
	 *
	 * @dev called when a user or another ERC223 contract wants to transfer tokens.
	 * @dev transfer token to a specified address
	 * @param _to The address to transfer to.
	 * @param _value The amount to be transferred.
	 * @param _data There is a way to attach bytes _data to token transaction similar to _data attached to Ether transactions.
	 * @param _custom_fallback If there are defined custom fallbacks in ERC223 contracts, you specify it here.
	 */
	function transfer(address _to, uint _value, bytes _data, string _custom_fallback)public returns(bool success) {
		if (isContract(_to)) {
			return transferToContractWithCustomFallback(_to, _value, _data, _custom_fallback);
		} else {
			return transferToAddress(_to, _value, _data);
		}
	}

	/**
	 * @notice Transfer the specified amount of tokens to the specified address.
	 *
	 * @dev Invokes the `tokenFallback` function if the recipient is a contract.
	 * The token transfer fails if the recipient is a contract
	 * but does not implement the `tokenFallback` function
	 * or the fallback function to receive funds.
	 *
	 * @param _to    Receiver address.
	 * @param _value Amount of tokens that will be transferred.
	 * @param _data  Transaction metadata.
	 */
	function transfer(address _to, uint _value, bytes _data)public returns(bool) {
		if (isContract(_to)) {
			return transferToContract(_to, _value, _data);
		} else {
			return transferToAddress(_to, _value, _data);
		}
	}

	/**
	 * @notice Standard check for ERC223 functions
	 *
	 * @param _addr The address to be checked if it is contract address or not
	 */
	function isContract(address _addr)private view returns(bool is_contract) {
		uint length;
		assembly {
			//retrieve the size of the code on target address, this needs assembly
			length := extcodesize(_addr)
		}
		return (length > 0);
	}

	/**
	 * @notice Function that is called when transaction target is an address
	 *
	 * @dev called when a user or another ERC223 contract wants to transfer tokens to a wallet address.
	 * @dev transfer token to a specified address
	 * @param _to The address to transfer to.
	 * @param _value The amount to be transferred.
	 * @param _data There is a way to attach bytes _data to token transaction similar to _data attached to Ether transactions.
	 */
	function transferToAddress(address _to, uint _value, bytes _data)private returns(bool success) {
		require(balances[msg.sender] >= _value);
		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);
		emit Transfer(msg.sender, _to, _value);
		emit Transfer(msg.sender, _to, _value, _data);
		return true;
	}

	/**
	 * @notice Function that is called when transaction target is contract
	 *
	 * @dev called when a user or another ERC223 contract wants to transfer tokens to a contract address.
	 * @dev transfer token to a specified address
	 * @param _to The address to transfer to.
	 * @param _value The amount to be transferred.
	 * @param _data There is a way to attach bytes _data to token transaction similar to _data attached to Ether transactions.
	 */
	function transferToContract(address _to, uint _value, bytes _data)private returns(bool success) {
		require(balances[msg.sender] >= _value);
		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);
		ContractReceiver receiver = ContractReceiver(_to);
		receiver.tokenFallback(msg.sender, _value, _data);
		emit Transfer(msg.sender, _to, _value);
		emit Transfer(msg.sender, _to, _value, _data);
		return true;
	}

	/**
	 * @notice Function that is called when transaction target is contract with custom fallback
	 *
	 * @dev called when a user or another ERC223 contract wants to transfer tokens.
	 * @dev transfer token to a specified address
	 * @param _to The address to transfer to.
	 * @param _value The amount to be transferred.
	 * @param _data There is a way to attach bytes _data to token transaction similar to _data attached to Ether transactions.
	 * @param _custom_fallback If there are defined custom fallbacks in ERC223 contracts, you specify it here.
	 */
	function transferToContractWithCustomFallback(address _to, uint _value, bytes _data, string _custom_fallback)private returns(bool success) {
		require(balances[msg.sender] >= _value);
		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);
		assert(_to.call.value(0)(bytes4(keccak256(_custom_fallback)), msg.sender, _value, _data));
		emit Transfer(msg.sender, _to, _value, _data);
		return true;
	}

	/* Stops any attempt to send Ether to this contract */
	function ()public {
		revert();
	}
}

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
	using SafeMath for uint256;

	event Pause();
	event Unpause();

	bool public paused = false;

	uint _pauseStartTime = 0;
	uint _pauseTime = 0;

	/**
	 * @dev Modifier to make a function callable only when the contract is not paused.
	 */
	modifier whenNotPaused() {
		require(!paused);
		_;
	}

	/**
	 * @dev Modifier to make a function callable only when the contract is paused.
	 */
	modifier whenPaused() {
		require(paused);
		_;
	}

	/**
	 * @dev called for get pause time
	 */
	function pauseTime()public view returns(uint256) {
		return _pauseTime;
	}

	/**
	 * @dev called by the owner to pause, triggers stopped state
	 */
	function pause()onlyOwner whenNotPaused public {
		_pauseStartTime = block.timestamp;
		paused = true;
		emit Pause();
	}

	/**
	 * @dev called by the owner to unpause, returns to normal state
	 */
	function unpause()onlyOwner whenPaused public {
		_pauseTime = _pauseTime.add(block.timestamp.sub(_pauseStartTime));

		paused = false;
		emit Unpause();
	}
}

/**
 * @title Pausable token
 * @dev StandardToken modified with pausable transfers.
 **/
contract PausableToken is AumonetERC223, Pausable {

	function transfer(address _to, uint256 _value)public whenNotPaused returns(bool) {
		return super.transfer(_to, _value);
	}

	function transfer(address _to, uint _value, bytes _data, string _custom_fallback)public whenNotPaused returns(bool) {
		return super.transfer(_to, _value, _data, _custom_fallback);
	}

	function transfer(address _to, uint256 _value, bytes _data)public whenNotPaused returns(bool) {
		return super.transfer(_to, _value, _data);
	}

	function transferFrom(address _from, address _to, uint256 _value)public whenNotPaused returns(bool) {
		return super.transferFrom(_from, _to, _value);
	}

	function approve(address _spender, uint256 _value)public whenNotPaused returns(bool) {
		return super.approve(_spender, _value);
	}

	function increaseApproval(address _spender, uint _addedValue)public whenNotPaused returns(bool success) {
		allowed[msg.sender][_spender] = (allowed[msg.sender][_spender].add(_addedValue));
		emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}

	function decreaseApproval(address _spender, uint _subtractedValue)public whenNotPaused returns(bool success) {
		uint256 oldValue = allowed[msg.sender][_spender];
		if (_subtractedValue > oldValue) {
			allowed[msg.sender][_spender] = 0;
		} else {
			allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
		}
		emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}
}

/**
 * @title Ownable Token
 * @dev Token that has modified transfer functions with onlyOwner approval.
 */
contract OwnableToken is PausableToken {

	event Burn(address indexed burner, uint256 value);

	/**
	 * @notice Allows the owner to transfer out any accidentally sent ERC20 tokens.
	 *
	 * @param _tokenAddress The address of the ERC20 contract.
	 * @param _amount The amount of tokens to be transferred.
	 */
	function transferAnyERC20Token(address _tokenAddress, uint256 _amount)onlyOwner public returns(bool success) {
		return AumonetERC223(_tokenAddress).transfer(owner, _amount);
	}

	/**
	 * @dev Burns a specific amount of tokens.
	 * @param _value The amount of token to be burned.
	 */
	function burn(uint256 _value)public {
		_burn(msg.sender, _value);
	}

	function _burn(address _who, uint256 _value)internal {
		require(_value <= balances[_who]);
		// no need to require value <= totalSupply, since that would imply the
		// sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

		balances[_who] = balances[_who].sub(_value);
		_totalSupply = _totalSupply.sub(_value);
		emit Burn(_who, _value);
		emit Transfer(_who, address(0), _value);
	}
}

/**
 * @title Aumonet Token
 * @dev Defining constants used in Aumonet smart contract.
 */
contract AumonetToken is OwnableToken {

	/* Contract Constants */
	string public _name = "Ezekiel";
	string public _symbol = "EZ37";
	uint8 public _decimals = 5;
	uint256 public _creatorSupply;
	uint256 public _icoSupply;
	uint256 public _bonusSupply = 187000 * (10 ** uint256(_decimals)); // The Bonus scheme supply is 17% (187 000 tokens);

	constructor()public {
		//pause();

		_totalSupply = 1100000 * (10 ** uint256(_decimals));

		_creatorSupply = _totalSupply * 25 / 100; // The creator has 25% of tokens
		_icoSupply = _totalSupply * 58 / 100; // Smart contract balance is 58% of tokens (638 000 tokens)

		//balances[this] = _icoSupply.add(_bonusSupply); // Token balance to smart contract.
		//balances[msg.sender] = _creatorSupply;
		balances[msg.sender] = _icoSupply.add(_bonusSupply);
		balances[tx.origin] = _creatorSupply; //instead of tx.origin should be address of where will be sended money

	}

	function name()public view returns(string) {
		return _name;
	}

	function symbol()public view returns(string) {
		return _symbol;
	}

	function decimals()public view returns(uint8) {
		return _decimals;
	}

	function bonusSupply()public view returns(uint256) {
		return _bonusSupply;
	}

	function icoSupply()public view returns(uint256) {
		return _icoSupply;
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
contract Crowdsale {
	using SafeMath for uint256;

	// The token being sold
	AumonetToken public token;

	// start and end timestamps of crowdsale
	uint public start; // the start date of the crowdsale
	uint public end; // the end date of the crowdsale
	uint256 increaseTime; // time paused
	// Address where funds are collected
	address public wallet;

	// How many token units a buyer gets per eth.
	// The rate is the conversion between wei and the smallest and indivisible token unit.
	uint256 public ethRate;

	// Amount of wei raised
	uint256 public totalWeiRaised; // WEI is the smallest unit of ETH (the equivalent of cent in USD or satoshi in BTC). We&#39;ll store the total ETH raised via our ICO here.

	uint256 public tokensSold; // the number of tokens already sold

	bool public crowdsaleClosed = false; // indicates if the crowdsale has been closed already


	/**
	 * Event for token purchase logging
	 * @param purchaser who paid for the tokens
	 * @param beneficiary who got the tokens
	 * @param value weis paid for purchase
	 * @param amount amount of tokens purchased
	 */
	event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

	/**
	 * @param _wallet Address where collected funds will be forwarded to
	 * @param _startICO starting time of ICO
	 * @param _endICO ending time of ICO
	 */
	constructor(address _wallet, uint _startICO, uint _endICO)public {
		require(_wallet != address(0));

		token = new AumonetToken(); // creates the token to be sold.
		ethRate = 124; // Set the rate of token to ether exchange for the ICO
		totalWeiRaised = 0;
		tokensSold = 0;
		start = _startICO; // Start of ICO is at 08.11.2018 00:00 (UTC)
		end = _endICO; // End of ICO is at 20.12.2018 23:59 (UTC)
		increaseTime = 0;
		wallet = _wallet;
	}

	modifier afterDeadline() {
		increaseTime = token.pauseTime();
		require(block.timestamp > end.add(increaseTime));
		_;
	}

	// -----------------------------------------
	// Crowdsale external interface
	// -----------------------------------------

	/**
	 * @dev fallback function ***DO NOT OVERRIDE***
	 */
	function ()external payable {
		buyTokens(msg.sender);
	}

	/**
	 * @notice Function calls other functions to calculate tokenamount to send to beneficiary. Checks if the process of buying is correct.
	 *
	 * @dev low level token purchase
	 * @param _beneficiary Address performing the token purchase
	 */
	function buyTokens(address _beneficiary)public payable {}

	// -----------------------------------------
	// Crowdsale internal interface (extensible)
	// -----------------------------------------

	/**
	 * @notice Validation of an incoming purchase.
	 *
	 * @dev Use require statements to revert state when conditions are not met. Use super to concatenate validations.
	 * @param _beneficiary Address performing the token purchase
	 * @param _weiAmount Value in wei involved in the purchase
	 */
	function _preValidatePurchase(address _beneficiary, uint256 _weiAmount)internal {
		require(_beneficiary != address(0));
		require(_weiAmount != 0);
		increaseTime = token.pauseTime();
		require(!crowdsaleClosed && block.timestamp >= start.add(increaseTime) && block.timestamp <= end.add(increaseTime));
	}

	/**
	 * @notice Function transfers tokens from contract to beneficiary address.
	 *
	 * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends its tokens.
	 * @param _beneficiary Address performing the token purchase
	 * @param _tokenAmount Number of tokens to be emitted
	 */
	function _deliverTokens(address _beneficiary, uint256 _tokenAmount)internal {
		token.transfer(_beneficiary, _tokenAmount);
	}

	/**
	 * @notice Function to calculate tokenamount from wei.
	 *
	 * @dev Override to extend the way in which ether is converted to tokens.
	 * @param _weiAmount Value in wei to be converted into tokens
	 * @return Number of tokens that can be purchased with the specified _weiAmount
	 */
	function _getTokenAmount(uint256 _weiAmount)internal view returns(uint256) {
		_weiAmount = _weiAmount.mul(ethRate).div(100);
		return _weiAmount.div(10 ** uint(18 - token.decimals())); //as we have other decimals number than standard 18, we need to calculate
	}

	/**
	 * @notice Determines how ETH is stored/forwarded on purchases.
	 */
	function _forwardFunds()internal {
		wallet.transfer(msg.value);
	}

	// @return true if crowdsale event has ended
	function hasEnded()public returns(bool) {
		increaseTime = token.pauseTime();
		return now > end.add(increaseTime);
	}
}

/**
 * @title FinalizableCrowdsale
 * @dev Extension of Crowdsale where an owner can do extra work
 * after finishing.
 */
contract FinalizableCrowdsale is Crowdsale, Ownable {

	bool public isFinalized = false;

    event Finalized();

	constructor()Ownable()public {}

	/**
	 * @notice Failsafe transfer of tokens for the team to owner wallet.
	 */
	function withdrawTokens()onlyOwner public returns(bool) {
		require(token.transfer(owner, token.balanceOf(this)));
		return true;
	}

	/**
	 * @notice Function to indicate the end of ICO.
	 *
	 * @dev Must be called after crowdsale ends, to do some extra finalization
	 * work. Calls the contract&#39;s finalization function.
	 */
	function finalize()onlyOwner afterDeadline public {
		require(!crowdsaleClosed);

		emit Finalized();
		withdrawTokens();

		crowdsaleClosed = true;
		isFinalized = true;
	}

	/**
	 * @dev Can be overridden to add finalization logic. The overriding function
	 * should call super.finalization() to ensure the chain of finalization is
	 * executed entirely.
	 */
	function finalization()internal {}
}

contract AumonetICO is FinalizableCrowdsale {
	using SafeMath for uint256;

	uint256 public BONUS_TOKENS = 18700000000;
	/**
	 * Defining timestamps for bonuscheme from White Paper.
	 * The start of bonuses is 8 November 2018 and the end is 20 December 2018.
	 * There are 2 seconds in between changing the phases.  */
	uint256 startOfFirstBonus;
	uint256 endOfFirstBonus;
	uint256 startOfSecondBonus;
	uint256 endOfSecondBonus;
	uint256 startOfThirdBonus;
	uint256 endOfThirdBonus;
	uint256 startOfFourthBonus;
	uint256 endOfFourthBonus;
	uint256 startOfFifthBonus;
	uint256 endOfFifthBonus;

	/**
	 * Defining bonuses according to White Paper.
	 * First week there is bonus 30%.
	 * Second week there is bonus 25%.
	 * Third week there is bonus 20%.
	 * Fourth week there is bonus 15%.
	 * Fifth week there is bonus 10%.
	 * The remaining week will have bonus 3%.
	 */
	uint256 firstBonus = 30;
	uint256 secondBonus = 25;
	uint256 thirdBonus = 20;
	uint256 fourthBonus = 15;
	uint256 fifthBonus = 10;
	uint256 sixthBonus = 3;

	constructor(address _wallet, uint _startICO, uint _endICO)FinalizableCrowdsale()Crowdsale(_wallet, _startICO, _endICO)public {
		/*
		 * Set bonusscheme week values
		 */
		startOfFirstBonus = _startICO;
		endOfFirstBonus = (startOfFirstBonus - 1) + 8 days;
		startOfSecondBonus = (startOfFirstBonus + 1) + 8 days;
		endOfSecondBonus = (startOfSecondBonus - 1) + 8 days;
		startOfThirdBonus = (startOfSecondBonus + 1) + 8 days;
		endOfThirdBonus = (startOfThirdBonus - 1) + 8 days;
		startOfFourthBonus = (startOfThirdBonus + 1) + 8 days;
		endOfFourthBonus = (startOfFourthBonus - 1) + 8 days;
		startOfFifthBonus = (startOfFourthBonus + 1) + 8 days;
		endOfFifthBonus = (startOfFifthBonus - 1) + 8 days;

	}

	event BonusCalculated(uint256 tokenAmount);
	event BonusSent(address indexed from, address indexed to, uint256 boughtTokens, uint256 bonusTokens);

	modifier beforeICO() {
		increaseTime = token.pauseTime();
		require(block.timestamp <= start.add(increaseTime));
		_;
	}

	/**
	 * @notice Sets how many tokens have we sold in PRE-ICO phase
	 *
	 * @param _soldTokens Number of tokens sold in PRE-ICO. The number needs to be multiplied by 10**number of decimals before entering it into function.
	 * @param _raisedWei The amount of ETH in wei raised in PRE-ICO.
	 */
	function setPreICOSoldAmount(uint256 _soldTokens, uint256 _raisedWei)onlyOwner beforeICO public {
		tokensSold = tokensSold.add(_soldTokens);
		totalWeiRaised = totalWeiRaised.add(_raisedWei);
	}

	/**
	 * @dev Calculates from Bonus Scheme how many tokens can be added to purchased _tokenAmount.
	 * @param _tokenAmount The amount of calculated tokens to sent Ether.
	 * @return Number of bonus tokens that can be granted with the specified _tokenAmount.
	 */
	function getBonusTokens(uint256 _tokenAmount)public returns(uint256) {
		increaseTime = token.pauseTime();
		if (block.timestamp >= startOfFirstBonus.add(increaseTime) && block.timestamp <= endOfFirstBonus.add(increaseTime)) {
			_tokenAmount = _tokenAmount.mul(firstBonus).div(100);
		} else if (block.timestamp >= startOfSecondBonus.add(increaseTime) && block.timestamp <= endOfSecondBonus.add(increaseTime)) {
			_tokenAmount = _tokenAmount.mul(secondBonus).div(100);
		} else if (block.timestamp >= startOfThirdBonus.add(increaseTime) && block.timestamp <= endOfThirdBonus.add(increaseTime)) {
			_tokenAmount = _tokenAmount.mul(thirdBonus).div(100);
		} else if (block.timestamp >= startOfFourthBonus.add(increaseTime) && block.timestamp <= endOfFourthBonus.add(increaseTime)) {
			_tokenAmount = _tokenAmount.mul(fourthBonus).div(100);
		} else if (block.timestamp >= startOfFifthBonus.add(increaseTime) && block.timestamp <= endOfFifthBonus.add(increaseTime)) {
			_tokenAmount = _tokenAmount.mul(fifthBonus).div(100);
		} else
			_tokenAmount = _tokenAmount.mul(sixthBonus).div(100);
		emit BonusCalculated(_tokenAmount);
		return _tokenAmount;
	}

	/**
	 * @notice Function calls other functions to calculate tokenamount to send to beneficiary. Checks if the process of buying is correct.
	 *
	 * @dev low level token purchase
	 * @param _beneficiary Address performing the token purchase
	 */
	function buyTokens(address _beneficiary)public payable {
		uint256 weiAmount = msg.value;
		_preValidatePurchase(_beneficiary, weiAmount);

		uint256 tokens = _getTokenAmount(weiAmount); // calculate token amount to be sold

		require(token.balanceOf(this) >= tokens); //check if the contract has enough tokens

		totalWeiRaised = totalWeiRaised.add(weiAmount); //update state
		tokensSold = tokensSold.add(tokens); //update state

		_deliverTokens(_beneficiary, tokens);
		emit TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);
		_processBonus(msg.sender, tokens);

		_forwardFunds();
	}

	/**
	 * @notice Function to calculate bonus from bought tokens.
	 *
	 * @dev Executed when a purchase has been validated and bonus tokens need to be calculated. Not necessarily emits/sends bonus tokens.
	 * @param _beneficiary Address receiving the tokens
	 * @param _tokenAmount Number of tokens from which is calculated bonus amount
	 */
	function _processBonus(address _beneficiary, uint256 _tokenAmount)internal {
		uint256 bonusTokens = getBonusTokens(_tokenAmount); // Calculate bonus token amount
		if (BONUS_TOKENS < bonusTokens) { // If the bonus scheme does not have enough tokens, send all remaining
			bonusTokens = BONUS_TOKENS;
		}
		if (bonusTokens > 0) { // If there are no tokens left in bonus scheme, we do not need transaction.
			BONUS_TOKENS = BONUS_TOKENS.sub(bonusTokens);
			token.transfer(_beneficiary, bonusTokens);
			emit BonusSent(address(token), _beneficiary, _tokenAmount, bonusTokens);
			tokensSold = tokensSold.add(bonusTokens); // update state of sold tokens
		}
	}

	function transferTokenOwnership(address _newOwner)public {
		token.transferOwnership(_newOwner);
	}

	function finalization()internal {
		token.transferOwnership(wallet);
	}

}