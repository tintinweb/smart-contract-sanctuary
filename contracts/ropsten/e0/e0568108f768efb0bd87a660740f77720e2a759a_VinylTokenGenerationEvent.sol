pragma solidity ^0.4.23;

// File: math\SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
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
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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

// File: contracts\includes\ERC20Basic.sol

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

// File: contracts\includes\BasicToken.sol

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
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

// File: contracts\includes\BurnableToken.sol

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
    _burn(msg.sender, _value);
  }

  function _burn(address _who, uint256 _value) internal {
    require(_value <= balances[_who]);
    // requires value <= totalSupply, since that would imply the
    // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure
    assert(_value <= totalSupply);

    balances[_who] = balances[_who].sub(_value);
    totalSupply = totalSupply.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
  }
}

// File: contracts\includes\Ownable.sol

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
  constructor() public {
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

// File: contracts\includes\ERC20.sol

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

// File: contracts\includes\StandardToken.sol

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

// File: contracts\VinylToken.sol

/**
* @title VinylToken
* @dev VINYL
*/
contract VinylToken is StandardToken, BurnableToken, Ownable {
    string public constant name = "Vinyl";
    string public constant symbol = "VINYL";
    uint8 public constant decimals = 18;
    // locked tokens can not be transferred
    bool private isLocked = true;

    /**
    * @dev constructor to initiate values
    */
    constructor() public {
        totalSupply = 30000000 * (uint256(10) ** decimals);
        balances[owner] = totalSupply;
        emit Transfer(address(0), owner, totalSupply);
    }

    /**
    * @dev checks if tokens are not locked
    * owner can always transfer tokens
    */
    modifier canTransfer(address _sender, uint _value) {
        require(!isLocked || (isLocked && _sender == owner));
        _;
    }

    /**
    * @dev locked tokens can not be transferred
    */
    function transfer(address _to, uint _value) 
        public canTransfer(msg.sender, _value) 
        returns (bool success) 
    {
        return super.transfer(_to, _value);
    }

    /**
    * @dev locked tokens can not be transferred
    */
    function transferFrom(address _from, address _to, uint _value) 
        public canTransfer(_from, _value) 
        returns (bool success) 
    {
        return super.transferFrom(_from, _to, _value);
    }

    /**
    * @dev enables token transfer
    */
    function unlockTokens() public onlyOwner {
        isLocked = false;
    }

}

// File: contracts\VinylTokenGenerationEvent.sol

/**
* @title VinylTokenGenerationEvent
* @dev base contract for managing a token crowdsale,
* allowing investors to purchase tokens with ether
* only the owner can change parameters
* deploys VINYL token when this contract is deployed
* keeps separate list of participants: pre sale and main sale
* multiple rounds are possible for pre sale and main sale
* within a round, all participants have the same contribution min, max and rate
*/
contract VinylTokenGenerationEvent is Ownable {
    using SafeMath for uint256;

    // hard cap
    uint256 constant public CAP_ETH = 11550 ether;
    uint256 constant public CAP_TOKENS = 18000000 * (uint256(10) ** 18);
    uint256 constant public CAP_RESERVED = 12000000 * (uint256(10) ** 18);

    // The token being sold
    VinylToken public token;

    // Address where funds are collected
    address public wallet; 

    // if crowdsale has ended
    // disables all contract functions if true
    bool public eventEnded = false;
    // if tokens were unlocked
    bool public areTokensUnlocked = false;

    // Amount of wei raised
    uint256 public weiRaised = 0;

    // Amount of tokens sold
    uint256 public tokensAllocated = 0;

    // Amount of tokens reserved
    uint256 public tokensReserved = 0;

    // time constraints, rate and caps
    uint256 public startTimePreSale;
    uint256 public startTimeMainSale;
    uint256 public endTimePreSale;
    uint256 public endTimeMainSale;
    uint256 public ratePreSale;
    uint256 public rateMainSale;
    uint256 public minCapPreSale;
    uint256 public minCapMainSale;
    
    // whitelisted addresses
    mapping(address => bool) public whitelistPreSale;
    mapping(address => bool) public whitelistMainSale;
    // keeps track of total contributions
    mapping(address => uint256) public contributedPreSale;
    mapping(address => uint256) public contributedMainSale;

    event TokenPurchasePreSale(address indexed beneficiary, uint256 value, uint256 tokens);
    event TokenPurchaseMainSale(address indexed beneficiary, uint256 value, uint256 tokens);
    event PreSaleParamsChanged(uint256 startTimePreSale, uint256 endTimePreSale, uint256 minCapPreSale, uint256 ratePreSale);
    event MainSaleParamsChanged(uint256 startTimeMainSale, uint256 endTimeMainSale, uint256 minCapMainSale, uint256 rateMainSale);

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
    constructor(address _wallet) public {
        token = new VinylToken();
        wallet = _wallet;
    }

    /**
    * @dev default function to call the right function for exchanging tokens
    * main sale should start only after pre sale
    */
    function () public payable {
        // participates in crowdsale
        if (now <= endTimePreSale) { 
            enterPreSale();
        } else if (now <= endTimeMainSale) { 
            enterMainSale();
        } else {
            revert();
        }
    }

    /**
    * @dev set the parameters for the contribution round
    * associated with variables, functions, events of suffix Pre
    * @param _startTimePreSale start time of contribution round
    * @param _endTimePreSale end time of contribution round
    * @param _minCapPreSale minimum contribution for this round
    * @param _ratePreSale token exchange rate for this round
    */
    function setPreSaleParams(
        uint256 _startTimePreSale,
        uint256 _endTimePreSale,
        uint256 _minCapPreSale,
        uint256 _ratePreSale
    )
        public
        onlyOwner
        eventNotEnded
    {
        //start time must be in the future
        require(now < _startTimePreSale); 
        require(_startTimePreSale < _endTimePreSale); 
        require(_ratePreSale > 0);
        startTimePreSale = _startTimePreSale;
        endTimePreSale = _endTimePreSale;
        minCapPreSale = _minCapPreSale;
        ratePreSale = _ratePreSale;
        emit PreSaleParamsChanged(startTimePreSale, endTimePreSale, minCapPreSale, ratePreSale);
    }

    /**
    * @dev set the parameters for the contribution round
    * associated with variables, functions, events of suffix Main
    * @param _startTimeMainSale start time of contribution round
    * @param _endTimeMainSale end time of contribution round
    * @param _minCapMainSale minimum contribution for this round
    * @param _rateMainSale token exchange rate for this round
    */
    function setMainSaleParams(
        uint256 _startTimeMainSale,
        uint256 _endTimeMainSale,
        uint256 _minCapMainSale,
        uint256 _rateMainSale
    )
        external
        onlyOwner
        eventNotEnded
    {
        //start time must be in the future
        require(now < _startTimeMainSale); 
        require(_startTimeMainSale < _endTimeMainSale); 
        require(_rateMainSale > 0);
        //main sale should be after pre sale
        require(_startTimeMainSale > endTimePreSale); 
        startTimeMainSale = _startTimeMainSale;
        endTimeMainSale = _endTimeMainSale;
        minCapMainSale = _minCapMainSale;
        rateMainSale = _rateMainSale;
        emit MainSaleParamsChanged(_startTimeMainSale, _endTimeMainSale, _minCapMainSale, _rateMainSale);
    }

    /**
     * @dev Adds/removes single address to pre sale whitelist.
     * @param _beneficiary Address to be added to the whitelist
     * @param _whitelistStatus whitelist status
     */
    function whitelistPreSaleAddress(address _beneficiary, bool _whitelistStatus) 
        external 
        onlyOwner
        eventNotEnded
    {
        whitelistPreSale[_beneficiary] = _whitelistStatus;
    }

    /**
    * @dev Adds/removes list of addresses to pre sale whitelist.
    * @param _beneficiaries list of addresses for whitelist status change
    * @param _whitelistStatus set the address whitelist status to true or false
    */
    function whitelistPreSaleAddressMany(address[] _beneficiaries, bool _whitelistStatus)
        external
        onlyOwner
        eventNotEnded
    {
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            whitelistPreSale[_beneficiaries[i]] = _whitelistStatus;
        }
    }

    /**
     * @dev Adds/removes single address to main sale whitelist.
     * @param _beneficiary Address to be added to the whitelist
     * @param _whitelistStatus whitelist status
     */
    function whitelistMainSaleAddress(address _beneficiary, bool _whitelistStatus) 
        external 
        onlyOwner
        eventNotEnded
    {
        whitelistMainSale[_beneficiary] = _whitelistStatus;
    }

    /**
    * @dev Adds/removes list of addresses to main sale whitelist.
    * @param _beneficiaries list of addresses for whitelist status change
    * @param _whitelistStatus set the address whitelist status to true or false
    */
    function whitelistMainSaleAddressMany(address[] _beneficiaries, bool _whitelistStatus)
        external
        onlyOwner
        eventNotEnded
    {
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            whitelistMainSale[_beneficiaries[i]] = _whitelistStatus;
        }
    }

    /**
    * @dev unlocks tokens
    * only after crowdsale ends
    */
    function unlockTokens() onlyOwner public {
        require(!areTokensUnlocked && eventEnded);
        areTokensUnlocked = true;
        token.unlockTokens();
    }

    /**
    * @dev transfers reserved tokens
    */
    function reserveTokens(address _addr, uint256 _tokenAmount) 
        public
        onlyOwner
        eventNotEnded
    {
        _preValidateTransaction(_addr, _tokenAmount);
        // check for maximum reserved cap
        require(tokensReserved.add(_tokenAmount) < CAP_RESERVED);
        tokensReserved = tokensReserved.add(_tokenAmount);
        token.transfer(_addr, _tokenAmount);
    } 

    /**
    * @dev end the token generation event and deactivates all functions
    * can only be called after end time
    * burn all remaining tokens in this contract that are not exchanged
    */
    function endEvent()
        public
        onlyOwner
        eventNotEnded
    {
        // checks if params were set
        require(endTimePreSale > 0);
        // ends crowdsale
        eventEnded = true;  
        // burns unsold tokens
        uint256 leftTokens = token.balanceOf(this); 
        if (leftTokens > 0) {
            token.burn(leftTokens); 
        }
    }


    /**
    * @dev pre sale token purchasing
    * associated with variables, functions, events with suffix Pre
    */
    function enterPreSale()
        public
        payable
        eventNotEnded
    {
        address beneficiary = msg.sender;
        uint256 weiAmount = msg.value;

        _preValidateTransaction(beneficiary, weiAmount);
        // Time constraints
        require(now >= startTimePreSale && now <= endTimePreSale);
        require(ratePreSale > 0);
        // minCap
        require(weiAmount >= minCapPreSale);
        // user is whitelisted
        require(whitelistPreSale[beneficiary] == true);

        // calculates amount of tokens
        uint256 tokens = weiAmount.mul(ratePreSale);

        // checks cap
        _checkCap(weiAmount, tokens);

        // stores total collected eth
        weiRaised = weiRaised.add(weiAmount);
        // keeps track of total number of tokens sold
        tokensAllocated = tokensAllocated.add(tokens);

        // sends token to the participant
        token.transfer(beneficiary, tokens); 
        emit TokenPurchasePreSale(beneficiary, weiAmount, tokens); 
        // saves contributed value
        contributedPreSale[beneficiary] = contributedPreSale[beneficiary].add(weiAmount); 

        // transfers eth
        _forwardFunds(); 
    }

    /**
    * @dev main sale token purchasing
    * associated with variables, functions, events of suffix Main
    */
    function enterMainSale()
        public
        payable
        eventNotEnded
    {
        address beneficiary = msg.sender;
        uint256 weiAmount = msg.value;

        _preValidateTransaction(beneficiary, weiAmount);
        // Time constraints
        require(now >= startTimeMainSale && now <= endTimeMainSale);
        require(rateMainSale > 0);
        // minCap
        require(weiAmount >= minCapMainSale);
        // user is whitelisted
        require(whitelistMainSale[beneficiary] == true);

        // calculates amount of tokens
        uint256 tokens = weiAmount.mul(rateMainSale);

        // checks cap
        _checkCap(weiAmount, tokens);

        // stores total collected eth
        weiRaised = weiRaised.add(weiAmount);
        // keeps track of total number of tokens sold
        tokensAllocated = tokensAllocated.add(tokens);

        // sends token to the participant
        token.transfer(beneficiary, tokens);
        emit TokenPurchaseMainSale(beneficiary, weiAmount, tokens);
        // saves contributed value
        contributedMainSale[beneficiary] = contributedMainSale[beneficiary].add(weiAmount);

        // transfers eth
        _forwardFunds();

    }

    /**
    * @dev Determines how ETH is stored/forwarded on purchases.
    */
    function _forwardFunds() internal {
        wallet.transfer(msg.value);
    }

    /**
    * @dev checks for cap.
    */
    function _checkCap(uint256 _weiAmount, uint256 _tokens) internal view {
        if (tokensAllocated.add(_tokens) > CAP_TOKENS || weiRaised.add(_weiAmount) > CAP_ETH) {
            revert();
        }
    }

    /**
     * @dev Validation of an incoming purchase. 
     * @param _beneficiary Address performing the token purchase
     * @param _weiAmount Value in wei involved in the purchase
     */
    function _preValidateTransaction(address _beneficiary, uint256 _weiAmount) internal pure {
        require(_beneficiary != address(0));
        require(_weiAmount != 0);
    }   

}