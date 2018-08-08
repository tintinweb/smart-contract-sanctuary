pragma solidity 0.4.19;

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
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
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
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract BurnableToken is BasicToken {

    event Burn(address indexed burner, uint256 value);

    /**
     * @dev Burns a specific amount of tokens.
     * @param _value The amount of token to be burned.
     */
    function burn(uint256 _value) public {
        require(_value <= balances[msg.sender]);
        // no need to require value <= totalSupply, since that would imply the
        // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(burner, _value);
    }
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
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
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
    Approval(msg.sender, _spender, _value);
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
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
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
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

/**
* @title LendingBlockToken
* @dev LND or LendingBlock Token
* Max supply of 1 billion
* 18 decimals
* not transferable before end of token generation event
* transferable time can be set
*/
contract LendingBlockToken is StandardToken, BurnableToken, Ownable {
	string public constant name = "Lendingblock";
	string public constant symbol = "LND";
	uint8 public constant decimals = 18;
	uint256 public transferableTime = 1546300800;// 1/1/2019
	address public tokenEventAddress;

	/**
	* @dev before transferableTime, only the token event contract and owner
	* can transfer tokens
	*/
	modifier afterTransferableTime() {
		if (now <= transferableTime) {
			require(msg.sender == tokenEventAddress || msg.sender == owner);
		}
		_;
	}

	/**
	* @dev constructor to initiate values
	* msg.sender is the token event contract
	* supply is 1 billion
	* @param _owner address that has can transfer tokens and access to change transferableTime
	*/
	function LendingBlockToken(address _owner) public {
		tokenEventAddress = msg.sender;
		owner = _owner;
		totalSupply = 1e9 * 1e18;
		balances[_owner] = totalSupply;
		Transfer(address(0), _owner, totalSupply);
	}

	/**
	* @dev transferableTime restrictions on the parent function
	* @param _to address that will receive tokens
	* @param _value amount of tokens to transfer
	* @return boolean that indicates if the operation was successful
	*/
	function transfer(address _to, uint256 _value)
		public
		afterTransferableTime
		returns (bool)
	{
		return super.transfer(_to, _value);
	}

	/**
	* @dev transferableTime restrictions on the parent function
	* @param _from address that is approving the tokens
	* @param _to address that will receive approval for the tokens
	* @param _value amount of tokens to approve
	* @return boolean that indicates if the operation was successful
	*/
	function transferFrom(address _from, address _to, uint256 _value)
		public
		afterTransferableTime
		returns (bool)
	{
		return super.transferFrom(_from, _to, _value);
	}

	/**
	* @dev set transferableTime
	* transferableTime can only be set earlier, not later
	* once tokens are transferable, it cannot be paused
	* @param _transferableTime epoch time for transferableTime
	*/
	function setTransferableTime(uint256 _transferableTime)
		external
		onlyOwner
	{
		require(_transferableTime < transferableTime);
		transferableTime = _transferableTime;
	}
}

/**
* @title LendingBlockTokenEvent
* @dev sale contract that accepts eth and sends LND tokens in return
* only the owner can change parameters
* deploys LND token when this contract is deployed
* 2 separate list of participants, mainly pre sale and main sale
* multiple rounds are possible for pre sale and main sale
* within a round, all participants have the same contribution min, max and rate
*/
contract LendingBlockTokenEvent is Ownable {
	using SafeMath for uint256;

	LendingBlockToken public token;
	address public wallet;
	bool public eventEnded;
	uint256 public startTimePre;
	uint256 public startTimeMain;
	uint256 public endTimePre;
	uint256 public endTimeMain;
	uint256 public ratePre;
	uint256 public rateMain;
	uint256 public minCapPre;
	uint256 public minCapMain;
	uint256 public maxCapPre;
	uint256 public maxCapMain;
	uint256 public weiTotal;
	mapping(address => bool) public whitelistedAddressPre;
	mapping(address => bool) public whitelistedAddressMain;
	mapping(address => uint256) public contributedValue;

	event TokenPre(address indexed participant, uint256 value, uint256 tokens);
	event TokenMain(address indexed participant, uint256 value, uint256 tokens);
	event SetPre(uint256 startTimePre, uint256 endTimePre, uint256 minCapPre, uint256 maxCapPre, uint256 ratePre);
	event SetMain(uint256 startTimeMain, uint256 endTimeMain, uint256 minCapMain, uint256 maxCapMain, uint256 rateMain);
	event WhitelistPre(address indexed whitelistedAddress, bool whitelistedStatus);
	event WhitelistMain(address indexed whitelistedAddress, bool whitelistedStatus);

	/**
	* @dev all functions can only be called before event has ended
	*/
	modifier eventNotEnded() {
		require(eventEnded == false);
		_;
	}

	/**
	* @dev constructor to initiate values
	* @param _wallet address that will receive the contributed eth
	*/
	function LendingBlockTokenEvent(address _wallet) public {
		token = new LendingBlockToken(msg.sender);
		wallet = _wallet;
	}

	/**
	* @dev function to join the pre sale
	* associated with variables, functions, events of suffix Pre
	*/
	function joinPre()
		public
		payable
		eventNotEnded
	{
		require(now >= startTimePre);//after start time
		require(now <= endTimePre);//before end time
		require(msg.value >= minCapPre);//contribution is at least minimum
		require(whitelistedAddressPre[msg.sender] == true);//sender is whitelisted

		uint256 weiValue = msg.value;
		contributedValue[msg.sender] = contributedValue[msg.sender].add(weiValue);//store amount contributed
		require(contributedValue[msg.sender] <= maxCapPre);//total contribution not above maximum

		uint256 tokens = weiValue.mul(ratePre);//find amount of tokens
		weiTotal = weiTotal.add(weiValue);//store total collected eth

		token.transfer(msg.sender, tokens);//send token to participant
		TokenPre(msg.sender, weiValue, tokens);//record contribution in logs

		forwardFunds();//send eth for safekeeping
	}

	/**
	* @dev function to join the main sale
	* associated with variables, functions, events of suffix Main
	*/
	function joinMain()
		public
		payable
		eventNotEnded
	{
		require(now >= startTimeMain);//after start time
		require(now <= endTimeMain);//before end time
		require(msg.value >= minCapMain);//contribution is at least minimum
		require(whitelistedAddressMain[msg.sender] == true);//sender is whitelisted

		uint256 weiValue = msg.value;
		contributedValue[msg.sender] = contributedValue[msg.sender].add(weiValue);//store amount contributed
		require(contributedValue[msg.sender] <= maxCapMain);//total contribution not above maximum

		uint256 tokens = weiValue.mul(rateMain);//find amount of tokens
		weiTotal = weiTotal.add(weiValue);//store total collected eth

		token.transfer(msg.sender, tokens);//send token to participant
		TokenMain(msg.sender, weiValue, tokens);//record contribution in logs

		forwardFunds();//send eth for safekeeping
	}

	/**
	* @dev send eth for safekeeping
	*/
	function forwardFunds() internal {
		wallet.transfer(msg.value);
	}

	/**
	* @dev set the parameters for the contribution round
	* associated with variables, functions, events of suffix Pre
	* @param _startTimePre start time of contribution round
	* @param _endTimePre end time of contribution round
	* @param _minCapPre minimum contribution for this round
	* @param _maxCapPre maximum contribution for this round
	* @param _ratePre token exchange rate for this round
	*/
	function setPre(
		uint256 _startTimePre,
		uint256 _endTimePre,
		uint256 _minCapPre,
		uint256 _maxCapPre,
		uint256 _ratePre
	)
		external
		onlyOwner
		eventNotEnded
	{
		require(now < _startTimePre);//start time must be in the future
		require(_startTimePre < _endTimePre);//end time must be later than start time
		require(_minCapPre <= _maxCapPre);//minimum must be smaller or equal to maximum
		startTimePre = _startTimePre;
		endTimePre = _endTimePre;
		minCapPre = _minCapPre;
		maxCapPre = _maxCapPre;
		ratePre = _ratePre;
		SetPre(_startTimePre, _endTimePre, _minCapPre, _maxCapPre, _ratePre);
	}

	/**
	* @dev set the parameters for the contribution round
	* associated with variables, functions, events of suffix Main
	* @param _startTimeMain start time of contribution round
	* @param _endTimeMain end time of contribution round
	* @param _minCapMain minimum contribution for this round
	* @param _maxCapMain maximum contribution for this round
	* @param _rateMain token exchange rate for this round
	*/
	function setMain(
		uint256 _startTimeMain,
		uint256 _endTimeMain,
		uint256 _minCapMain,
		uint256 _maxCapMain,
		uint256 _rateMain
	)
		external
		onlyOwner
		eventNotEnded
	{
		require(now < _startTimeMain);//start time must be in the future
		require(_startTimeMain < _endTimeMain);//end time must be later than start time
		require(_minCapMain <= _maxCapMain);//minimum must be smaller or equal to maximum
		require(_startTimeMain > endTimePre);//main round should be after pre round
		startTimeMain = _startTimeMain;
		endTimeMain = _endTimeMain;
		minCapMain = _minCapMain;
		maxCapMain = _maxCapMain;
		rateMain = _rateMain;
		SetMain(_startTimeMain, _endTimeMain, _minCapMain, _maxCapMain, _rateMain);
	}

	/**
	* @dev change the whitelist status of an address for pre sale
	* associated with variables, functions, events of suffix Pre
	* @param whitelistedAddress list of addresses for whitelist status change
	* @param whitelistedStatus set the address whitelist status to true or false
	*/
	function setWhitelistedAddressPre(address[] whitelistedAddress, bool whitelistedStatus)
		external
		onlyOwner
		eventNotEnded
	{
		for (uint256 i = 0; i < whitelistedAddress.length; i++) {
			whitelistedAddressPre[whitelistedAddress[i]] = whitelistedStatus;
			WhitelistPre(whitelistedAddress[i], whitelistedStatus);
		}
	}

	/**
	* @dev change the whitelist status of an address for main sale
	* associated with variables, functions, events of suffix Main
	* @param whitelistedAddress list of addresses for whitelist status change
	* @param whitelistedStatus set the address whitelist status to true or false
	*/
	function setWhitelistedAddressMain(address[] whitelistedAddress, bool whitelistedStatus)
		external
		onlyOwner
		eventNotEnded
	{
		for (uint256 i = 0; i < whitelistedAddress.length; i++) {
			whitelistedAddressMain[whitelistedAddress[i]] = whitelistedStatus;
			WhitelistMain(whitelistedAddress[i], whitelistedStatus);
		}
	}

	/**
	* @dev end the token generation event and deactivates all functions
	* can only be called after end time
	* burn all remaining tokens in this contract that are not exchanged
	*/
	function endEvent()
		external
		onlyOwner
		eventNotEnded
	{
		require(now > endTimeMain);//can only be called after end time
		require(endTimeMain > 0);//can only be called after end time has been set
		uint256 leftTokens = token.balanceOf(this);//find if any tokens are left
		if (leftTokens > 0) {
			token.burn(leftTokens);//burn all remaining tokens
		}
		eventEnded = true;//deactivates all functions
	}

	/**
	* @dev default function to call the right function for exchanging tokens
	* main sale should start only after pre sale
	*/
	function () external payable {
		if (now <= endTimePre) {//call pre function if before pre sale end time
			joinPre();
		} else if (now <= endTimeMain) {//call main function if before main sale end time
			joinMain();
		} else {
			revert();
		}
	}

}