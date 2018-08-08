pragma solidity ^ 0.4.21;

pragma solidity ^0.4.10;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}
pragma solidity ^0.4.10;

interface ERC20 {
  function balanceOf(address who) view returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  function allowance(address owner, address spender) view returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}
pragma solidity ^0.4.10;

interface ERC223 {
    function transfer(address to, uint value, bytes data) returns (bool);
    event Transfer(address indexed from, address indexed to, uint value, bytes indexed data);
}
pragma solidity ^0.4.10;

contract ERC223ReceivingContract { 
    function tokenFallback(address _from, uint _value, bytes _data) public;
}

pragma solidity ^0.4.21;

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
	function Ownable()public {
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
	function transferOwnership(address newOwner)public onlyOwner {
		require(newOwner != address(0));
		emit OwnershipTransferred(owner, newOwner);
		owner = newOwner;
	}

}

pragma solidity ^0.4.21;

/**
 * @title RefundVault
 * @dev This contract is used for storing funds while a crowdsale
 * is in progress. Supports refunding the money if crowdsale fails,
 * and forwarding it if crowdsale is successful.
 */
contract RefundVault is Ownable {
	using SafeMath for uint256;

	enum State {
		Active,
		Refunding,
		Closed
	}

	mapping(address => uint256)public deposited;
	address public wallet;
	State public state;

	event Closed();
	event RefundsEnabled();
	event Refunded(address indexed beneficiary, uint256 weiAmount);

	/**
	 * @param _wallet Vault address
	 */
	function RefundVault(address _wallet)public {
		require(_wallet != address(0));
		wallet = _wallet;
		state = State.Active;
	}

	/**
	 * @param investor Investor address
	 */
	function deposit(address investor)onlyOwner public payable {
		require(state == State.Active);
		deposited[investor] = deposited[investor].add(msg.value);
	}

	function close()onlyOwner public {
		require(state == State.Active);
		state = State.Closed;
		emit Closed();
		wallet.transfer(address(this).balance);
	}

	function enableRefunds()onlyOwner public {
		require(state == State.Active);
		state = State.Refunding;
		emit RefundsEnabled();
	}

	/**
	 * @param investor Investor address
	 */
	function refund(address investor)public {
		require(state == State.Refunding);
		uint256 depositedValue = deposited[investor];
		deposited[investor] = 0;
		investor.transfer(depositedValue);
		emit Refunded(investor, depositedValue);
	}
}
pragma solidity ^0.4.21;

/**
 * @title BonusScheme
 * @dev This contract is used for storing and granting tokens calculated 
 * according to bonus scheme while a crowdsale is in progress.
 * When crowdsale ends the rest of tokens is transferred to developers.
 */
contract BonusScheme is Ownable {
	using SafeMath for uint256;

	/**
	* Defining timestamps for bonuscheme from White Paper. 
	* The start of bonuses is 15 May 2018 and the end is 23 June 2018. 
	* There are 2 seconds in between changing the phases.  */
	uint256 startOfFirstBonus = 1526021400;
	uint256 endOfFirstBonus = (startOfFirstBonus - 1) + 5 minutes;	
	uint256 startOfSecondBonus = (startOfFirstBonus + 1) + 5 minutes;
	uint256 endOfSecondBonus = (startOfSecondBonus - 1) + 5 minutes;
	uint256 startOfThirdBonus = (startOfSecondBonus + 1) + 5 minutes;
	uint256 endOfThirdBonus = (startOfThirdBonus - 1) + 5 minutes;
	uint256 startOfFourthBonus = (startOfThirdBonus + 1) + 5 minutes;
	uint256 endOfFourthBonus = (startOfFourthBonus - 1) + 5 minutes;
	uint256 startOfFifthBonus = (startOfFourthBonus + 1) + 5 minutes;
	uint256 endOfFifthBonus = (startOfFifthBonus - 1) + 5 minutes;
	
	/**
	* Defining bonuses according to White Paper.
	* First week there is bonus 35%.
	* Second week there is bonus 30%.
	* Third week there is bonus 20%.
	* Fourth week there is bonus 10%.
	* Fifth week there is bonus 5%.
	*/
	uint256 firstBonus = 35;
	uint256 secondBonus = 30;
	uint256 thirdBonus = 20;
	uint256 fourthBonus = 10;
	uint256 fifthBonus = 5;

	event BonusCalculated(uint256 tokenAmount);

    function BonusScheme() public {
        
    }

	/**
	 * @dev Calculates from Bonus Scheme how many tokens can be added to purchased _tokenAmount.
	 * @param _tokenAmount The amount of calculated tokens to sent Ether.
	 * @return Number of bonus tokens that can be granted with the specified _tokenAmount.
	 */
	function getBonusTokens(uint256 _tokenAmount)onlyOwner public returns(uint256) {
		if (block.timestamp >= startOfFirstBonus && block.timestamp <= endOfFirstBonus) {
			_tokenAmount = _tokenAmount.mul(firstBonus).div(100);
		} else if (block.timestamp >= startOfSecondBonus && block.timestamp <= endOfSecondBonus) {
			_tokenAmount = _tokenAmount.mul(secondBonus).div(100);
		} else if (block.timestamp >= startOfThirdBonus && block.timestamp <= endOfThirdBonus) {
			_tokenAmount = _tokenAmount.mul(thirdBonus).div(100);
		} else if (block.timestamp >= startOfFourthBonus && block.timestamp <= endOfFourthBonus) {
			_tokenAmount = _tokenAmount.mul(fourthBonus).div(100);
		} else if (block.timestamp >= startOfFifthBonus && block.timestamp <= endOfFifthBonus) {
			_tokenAmount = _tokenAmount.mul(fifthBonus).div(100);
		} else _tokenAmount=0;
		emit BonusCalculated(_tokenAmount);
		return _tokenAmount;
	}
}

contract StandardToken is ERC20, ERC223, Ownable {
	using SafeMath for uint;

	string internal _name;
	string internal _symbol;
	uint8 internal _decimals;
	uint256 internal _totalSupply;
	uint256 internal _bonusSupply;

	uint256 public ethRate; // How many token units a buyer gets per eth
	uint256 public min_contribution; // Minimal contribution in ICO
	uint256 public totalWeiRaised; // WEI is the smallest unit of ETH (the equivalent of cent in USD or satoshi in BTC). We&#39;ll store the total ETH raised via our ICO here.
	uint public tokensSold; // the number of tokens already sold

	uint public softCap; //softcap in tokens
	uint public start; // the start date of the crowdsale
	uint public end; // the end date of the crowdsale
	bool public crowdsaleClosed; // indicates if the crowdsale has been closed already
	RefundVault public vault; // refund vault used to hold funds while crowdsale is running
	BonusScheme public bonusScheme; // contract used to hold and give tokens according to bonus scheme from white paper

	address public fundsWallet; // Where should the raised ETH go?

	mapping(address => bool)public frozenAccount;
	mapping(address => uint256)internal balances;
	mapping(address => mapping(address => uint256))internal allowed;

	/* This generates a public event on the blockchain that will notify clients */
	event Burn(address indexed burner, uint256 value);
	event FrozenFunds(address target, bool frozen);
	event Finalized();
	event BonusSent(address indexed from, address indexed to, uint256 boughtTokens, uint256 bonusTokens);

	/**
	 * Event for token purchase logging
	 * @param purchaser who paid for the tokens
	 * @param beneficiary who got the tokens
	 * @param value weis paid for purchase
	 * @param amount of tokens purchased
	 */
	event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

	//TODO: correction of smart contract balance of tokens //done
	//TODO: change symbol and name of token
	//TODO: change start and end timestamps
	function StandardToken()public {
		_symbol = "AmTC1";
		_name = "AmTokenTestCase1";
		_decimals = 5;
		_totalSupply = 1100000 * (10 ** uint256(_decimals));
		//_creatorSupply = _totalSupply * 25 / 100; 			// The creator has 25% of tokens
		//_icoSupply = _totalSupply * 58 / 100; 				// Smart contract balance is 58% of tokens (638 000 tokens)
		_bonusSupply = _totalSupply * 17 / 100; // The Bonus scheme supply is 17% (187 000 tokens)
		
		fundsWallet = msg.sender; // The owner of the contract gets ETH
		vault = new RefundVault(fundsWallet);
		bonusScheme = new BonusScheme();

		//balances[this] = _icoSupply;          				// Token balance to smart contract will be added manually from owners wallet
		balances[msg.sender] = _totalSupply.sub(_bonusSupply);
		balances[bonusScheme] = _bonusSupply;
		ethRate = 40000000; // Set the rate of token to ether exchange for the ICO
		min_contribution = 1 ether / (10**11); // 0.1 ETH is minimum deposit
		totalWeiRaised = 0;
		tokensSold = 0;
		softCap = 20000 * 10 ** uint(_decimals);
		start = 1526021100;
		end = 1526023500;
		crowdsaleClosed = false;
	}

	modifier beforeICO() {
		require(block.timestamp <= start);
		_;
	}
	
	modifier afterDeadline() {
		require(block.timestamp > end);
		_;
	}

	function name()
	public
	view
	returns(string) {
		return _name;
	}

	function symbol()
	public
	view
	returns(string) {
		return _symbol;
	}

	function decimals()
	public
	view
	returns(uint8) {
		return _decimals;
	}

	function totalSupply()
	public
	view
	returns(uint256) {
		return _totalSupply;
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
	 * @dev low level token purchase ***DO NOT OVERRIDE***
	 * @param _beneficiary Address performing the token purchase
	 */
	//bad calculations, change  //should be ok
	//TODO: pre-ico phase to be defined and checked with other tokens, ICO-when closed check softcap, softcap-add pre-ico tokens, if isnt achieved revert all transactions, hardcap, timestamps&bonus scheme(will be discussed next week), minimum amount is 0,1ETH ...
	function buyTokens(address _beneficiary)public payable {
		uint256 weiAmount = msg.value;
		_preValidatePurchase(_beneficiary, weiAmount);
		uint256 tokens = _getTokenAmount(weiAmount); // calculate token amount to be sold
		require(balances[this] > tokens); //check if the contract has enough tokens

		totalWeiRaised = totalWeiRaised.add(weiAmount); //update state
		tokensSold = tokensSold.add(tokens); //update state

		_processPurchase(_beneficiary, tokens);
		emit TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);
		_processBonus(_beneficiary, tokens);

		_updatePurchasingState(_beneficiary, weiAmount);

		_forwardFunds();
		_postValidatePurchase(_beneficiary, weiAmount);

		/*
		balances[this] = balances[this].sub(weiAmount);
		balances[_beneficiary] = balances[_beneficiary].add(weiAmount);

		emit Transfer(this, _beneficiary, weiAmount); 					// Broadcast a message to the blockchain
		 */

	}

	// -----------------------------------------
	// Crowdsale internal interface (extensible)
	// -----------------------------------------

	/**
	 * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met. Use super to concatenate validations.
	 * @param _beneficiary Address performing the token purchase
	 * @param _weiAmount Value in wei involved in the purchase
	 */
	function _preValidatePurchase(address _beneficiary, uint256 _weiAmount)internal view {
		require(_beneficiary != address(0));
		require(_weiAmount >= min_contribution);
		require(!crowdsaleClosed && block.timestamp >= start && block.timestamp <= end);
	}

	/**
	 * @dev Validation of an executed purchase. Observe state and use revert statements to undo rollback when valid conditions are not met.
	 * @param _beneficiary Address performing the token purchase
	 * @param _weiAmount Value in wei involved in the purchase
	 */
	function _postValidatePurchase(address _beneficiary, uint256 _weiAmount)internal pure {
		// optional override
	}

	/**
	 * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends its tokens.
	 * @param _beneficiary Address performing the token purchase
	 * @param _tokenAmount Number of tokens to be emitted
	 */
	function _deliverTokens(address _beneficiary, uint256 _tokenAmount)internal {
		this.transfer(_beneficiary, _tokenAmount);
	}

	/**
	 * @dev Executed when a purchase has been validated and is ready to be executed. Not necessarily emits/sends tokens.
	 * @param _beneficiary Address receiving the tokens
	 * @param _tokenAmount Number of tokens to be purchased
	 */
	function _processPurchase(address _beneficiary, uint256 _tokenAmount)internal {
		_deliverTokens(_beneficiary, _tokenAmount);
	}

	/**
	 * @dev Executed when a purchase has been validated and bonus tokens need to be calculated. Not necessarily emits/sends bonus tokens.
	 * @param _beneficiary Address receiving the tokens
	 * @param _tokenAmount Number of tokens from which is calculated bonus amount
	 */
	function _processBonus(address _beneficiary, uint256 _tokenAmount)internal {
		uint256 bonusTokens = bonusScheme.getBonusTokens(_tokenAmount); // Calculate bonus token amount
		if (balances[bonusScheme] < bonusTokens) { // If the bonus scheme does not have enough tokens, send all remaining
			bonusTokens = balances[bonusScheme];
		}
		if (bonusTokens > 0) { // If there are no tokens left in bonus scheme, we do not need transaction.
			balances[bonusScheme] = balances[bonusScheme].sub(bonusTokens);
			balances[_beneficiary] = balances[_beneficiary].add(bonusTokens);
			emit Transfer(address(bonusScheme), _beneficiary, bonusTokens);
			emit BonusSent(address(bonusScheme), _beneficiary, _tokenAmount, bonusTokens);
			tokensSold = tokensSold.add(bonusTokens); // update state
		}
	}

	/**
	 * @dev Override for extensions that require an internal state to check for validity (current user contributions, etc.)
	 * @param _beneficiary Address receiving the tokens
	 * @param _weiAmount Value in wei involved in the purchase
	 */
	function _updatePurchasingState(address _beneficiary, uint256 _weiAmount)internal {
		// optional override
	}

	/**
	 * @dev Override to extend the way in which ether is converted to tokens.
	 * @param _weiAmount Value in wei to be converted into tokens
	 * @return Number of tokens that can be purchased with the specified _weiAmount
	 */
	function _getTokenAmount(uint256 _weiAmount)internal view returns(uint256) {
		_weiAmount = _weiAmount.mul(ethRate);
		return _weiAmount.div(10 ** uint(18 - _decimals)); //as we have other decimals number than standard 18, we need to calculate
	}

	/**
	 * @dev Determines how ETH is stored/forwarded on purchases, sending funds to vault.
	 */
	function _forwardFunds()internal {
		vault.deposit.value(msg.value)(msg.sender); //Transfer ether to vault
	}

	///!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! bad function, refactor   //should be solved now
	//standard function transfer similar to ERC20 transfer with no _data
	//added due to backwards compatibility reasons
	function transfer(address _to, uint256 _value)public returns(bool) {
		require(_to != address(0));
		require(_value <= balances[msg.sender]);
		require(!frozenAccount[msg.sender]); // Check if sender is frozen
		require(!frozenAccount[_to]); // Check if recipient is frozen
		//require(!isContract(_to));
		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);
		emit Transfer(msg.sender, _to, _value);
		return true;
	}

	function balanceOf(address _owner)public view returns(uint256 balance) {
		return balances[_owner];
	}

	//standard function transferFrom similar to ERC20 transferFrom with no _data
	//added due to backwards compatibility reasons
	function transferFrom(address _from, address _to, uint256 _value)public returns(bool) {
		require(_to != address(0));
		require(!frozenAccount[_from]); // Check if sender is frozen
		require(!frozenAccount[_to]); // Check if recipient is frozen
		require(_value <= balances[_from]);
		require(_value <= allowed[_from][msg.sender]);

		balances[_from] = balances[_from].sub(_value);
		balances[_to] = balances[_to].add(_value);
		allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
		emit Transfer(_from, _to, _value);
		return true;
	}

	function approve(address _spender, uint256 _value)public returns(bool) {
		allowed[msg.sender][_spender] = _value;
		emit Approval(msg.sender, _spender, _value);
		return true;
	}

	function allowance(address _owner, address _spender)public view returns(uint256) {
		return allowed[_owner][_spender];
	}

	function increaseApproval(address _spender, uint _addedValue)public returns(bool) {
		allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
		emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}

	function decreaseApproval(address _spender, uint _subtractedValue)public returns(bool) {
		uint oldValue = allowed[msg.sender][_spender];
		if (_subtractedValue > oldValue) {
			allowed[msg.sender][_spender] = 0;
		} else {
			allowed[msg.sender][_spender] = SafeMath.sub(oldValue, _subtractedValue);
		}
		emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}

	// Function that is called when a user or another contract wants to transfer funds .    ///add trasnfertocontractwithcustomfallback  //done
	function transfer(address _to, uint _value, bytes _data, string _custom_fallback)public returns(bool success) {
		require(!frozenAccount[msg.sender]); // Check if sender is frozen
		require(!frozenAccount[_to]); // Check if recipient is frozen
		if (isContract(_to)) {
			return transferToContractWithCustomFallback(_to, _value, _data, _custom_fallback);
		} else {
			return transferToAddress(_to, _value, _data);
		}
	}

	// Function that is called when a user or another contract wants to transfer funds .
	function transfer(address _to, uint _value, bytes _data)public returns(bool) {
		require(!frozenAccount[msg.sender]); // Check if sender is frozen
		require(!frozenAccount[_to]); // Check if recipient is frozen
		if (isContract(_to)) {
			return transferToContract(_to, _value, _data);
		} else {
			return transferToAddress(_to, _value, _data);
		}
		/*
		require(_to != address(0));
		require(_value > 0 && _value <= balances[msg.sender]);
		if(isContract(_to)) {
		ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
		receiver.tokenFallback(msg.sender, _value, _data);
		return true;
		}
		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);
		emit Transfer(msg.sender, _to, _value, _data);
		 */
	}

	function isContract(address _addr)private view returns(bool is_contract) {
		uint length;
		assembly {
			//retrieve the size of the code on target address, this needs assembly
			length := extcodesize(_addr)
		}
		return (length > 0);
	}

	//function that is called when transaction target is an address
	function transferToAddress(address _to, uint _value, bytes _data)private returns(bool success) {
		require(balanceOf(msg.sender) > _value);
		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);
		emit Transfer(msg.sender, _to, _value, _data);
		return true;
	}

	//function that is called when transaction target is a contract
	function transferToContract(address _to, uint _value, bytes _data)private returns(bool success) {
		require(balanceOf(msg.sender) > _value);
		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);
		ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
		receiver.tokenFallback(msg.sender, _value, _data);
		emit Transfer(msg.sender, _to, _value, _data);
		return true;
	}

	//function that is called when transaction target is a contract with custom fallback
	function transferToContractWithCustomFallback(address _to, uint _value, bytes _data, string _custom_fallback)private returns(bool success) {
		require(balanceOf(msg.sender) > _value);
		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);
		assert(_to.call.value(0)(bytes4(keccak256(_custom_fallback)), msg.sender, _value, _data));
		emit Transfer(msg.sender, _to, _value, _data);
		return true;
	}

	function setPreICOSoldAmount(uint256 _soldTokens, uint256 _raisedWei)onlyOwner beforeICO public {
		tokensSold = tokensSold.add(_soldTokens);
		totalWeiRaised = totalWeiRaised.add(_raisedWei);
	}
	
	/// @notice `freeze? Prevent | Allow` `target` from sending & receiving tokens
	/// @param target Address to be frozen
	/// @param freeze either to freeze it or not
	function freezeAccount(address target, bool freeze)onlyOwner public {
		frozenAccount[target] = freeze;
		emit FrozenFunds(target, freeze);
	}

	/**
	 * Destroy tokens
	 *
	 * Remove `_value` tokens from the system irreversibly
	 *
	 * @param _value the amount of money to burn
	 */
	function burn(uint256 _value)onlyOwner public returns(bool success) {
		require(balances[msg.sender] >= _value); // Check if the sender has enough
		balances[msg.sender] = balances[msg.sender].sub(_value); // Subtract from the sender
		_totalSupply = _totalSupply.sub(_value); // Updates totalSupply
		emit Burn(msg.sender, _value);
		emit Transfer(msg.sender, address(0), _value);
		return true;
	}

	/* NOT NEEDED as ethers are in vault
	//check the functionality
	// @notice Failsafe drain
	function withdrawEther()onlyOwner public returns(bool) {
	owner.transfer(address(this).balance);
	return true;
	}
	 */

	// @notice Failsafe transfer tokens for the team to given account
	function withdrawTokens()onlyOwner public returns(bool) {
		require(this.transfer(owner, balances[this]));
		uint256 bonusTokens = balances[address(bonusScheme)];
		balances[address(bonusScheme)] = 0;
		if (bonusTokens > 0) { // If there are no tokens left in bonus scheme, we do not need transaction.
			balances[owner] = balances[owner].add(bonusTokens);
			emit Transfer(address(bonusScheme), owner, bonusTokens);
		}
		return true;
	}

	/**
	 * @dev Allow the owner to transfer out any accidentally sent ERC20 tokens.
	 * @param _tokenAddress The address of the ERC20 contract.
	 * @param _amount The amount of tokens to be transferred.
	 */
	function transferAnyERC20Token(address _tokenAddress, uint256 _amount)onlyOwner public returns(bool success) {
		return ERC20(_tokenAddress).transfer(owner, _amount);
	}

	/**
	 * @dev Investors can claim refunds here if crowdsale is unsuccessful
	 */
	function claimRefund()public {
		require(crowdsaleClosed);
		require(!goalReached());

		vault.refund(msg.sender);
	}

	/**
	 * @dev Checks whether funding goal was reached.
	 * @return Whether funding goal was reached
	 */
	function goalReached()public view returns(bool) {
		return tokensSold >= softCap;
	}

	/**
	 * @dev vault finalization task, called when owner calls finalize()
	 */
	function finalization()internal {
		if (goalReached()) {
			vault.close();
		} else {
			vault.enableRefunds();
		}
	}

	/**
	 * @dev Must be called after crowdsale ends, to do some extra finalization
	 * work. Calls the contract&#39;s finalization function.
	 */
	function finalize()onlyOwner afterDeadline public {
		require(!crowdsaleClosed);

		finalization();
		emit Finalized();
		withdrawTokens();

		crowdsaleClosed = true;
	}

}