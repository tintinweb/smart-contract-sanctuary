pragma solidity ^0.4.24;

// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
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
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

// ----------------------------------------------------------------------------
// Ownership functionality for authorization controls and user permissions
// ----------------------------------------------------------------------------
/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


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

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }
}

// ERC20 Standard Interface
// ----------------------------------------------------------------------------
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
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

// ----------------------------------------------------------------------------
// Basic version of StandardToken, with no allowances.
// ----------------------------------------------------------------------------

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

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
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
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
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
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
  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
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
  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    returns (bool)
  {
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
    // no need to require value <= totalSupply, since that would imply the
    // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
  }
}

/**
 * @title Standard Burnable Token
 * @dev Adds burnFrom method to ERC20 implementations
 */
contract StandardBurnableToken is BurnableToken, StandardToken {

  /**
   * @dev Burns a specific amount of tokens from the target address and decrements allowance
   * @param _from address The address which you want to send tokens from
   * @param _value uint256 The amount of token to be burned
   */
  function burnFrom(address _from, uint256 _value) public {
    require(_value <= allowed[_from][msg.sender]);
    // Should https://github.com/OpenZeppelin/zeppelin-solidity/issues/707 be accepted,
    // this function needs to emit an event with the updated approval.
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    _burn(_from, _value);
  }
}


contract ArawToken is StandardBurnableToken, Ownable {

  using SafeMath for uint256;

  string public symbol = "ARAW";
  string public name = "ARAW";
  uint256 public decimals = 18;

  /* Wallet address will be changed for production */ 
  address public arawWallet;

  /* Locked tokens addresses - will be changed for production */
  address public reservedTokensAddress;
  address public foundersTokensAddress;
  address public advisorsTokensAddress;

  /* Variables to manage Advisors tokens vesting periods time */
  uint256 public advisorsTokensFirstReleaseTime; 
  uint256 public advisorsTokensSecondReleaseTime; 
  uint256 public advisorsTokensThirdReleaseTime; 
  
  /* Flags to indicate Advisors tokens released */
  bool public isAdvisorsTokensFirstReleased; 
  bool public isAdvisorsTokensSecondReleased; 
  bool public isAdvisorsTokensThirdReleased; 

  /* Variables to hold reserved and founders tokens locking period */
  uint256 public reservedTokensLockedPeriod;
  uint256 public foundersTokensLockedPeriod;

  /* Total advisors tokens allocated */
  uint256 totalAdvisorsLockedTokens; 

  modifier checkAfterICOLock () {
    if (msg.sender == reservedTokensAddress){
        require (now >= reservedTokensLockedPeriod);
    }
    if (msg.sender == foundersTokensAddress){
        require (now >= foundersTokensLockedPeriod);
    }
    _;
  }

  function transfer(address _to, uint256 _value) 
  public 
  checkAfterICOLock 
  returns (bool) {
    super.transfer(_to,_value);
  }

  function transferFrom(address _from, address _to, uint256 _value) 
  public 
  checkAfterICOLock 
  returns (bool) {
    super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) 
  public 
  checkAfterICOLock 
  returns (bool) {
    super.approve(_spender, _value);
  }

  function increaseApproval(address _spender, uint _addedValue) 
  public 
  checkAfterICOLock 
  returns (bool) {
    super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(address _spender, uint _subtractedValue) 
  public 
  checkAfterICOLock 
  returns (bool) {
    super.decreaseApproval(_spender, _subtractedValue);
  }

  /**
   * @dev Transfer ownership now transfers all owners tokens to new owner 
   */
  function transferOwnership(address newOwner) public onlyOwner {
    balances[newOwner] = balances[newOwner].add(balances[owner]);
    emit Transfer(owner, newOwner, balances[owner]);
    balances[owner] = 0;

    super.transferOwnership(newOwner);
  }

  /* ICO status */
  enum State {
    Active,
    Closed
  }

  event Closed();

  State public state;

  // ------------------------------------------------------------------------
  // Constructor
  // ------------------------------------------------------------------------
  constructor(address _reservedTokensAddress, address _foundersTokensAddress, address _advisorsTokensAddress, address _arawWallet) public {
    owner = msg.sender;

    reservedTokensAddress = _reservedTokensAddress;
    foundersTokensAddress = _foundersTokensAddress;
    advisorsTokensAddress = _advisorsTokensAddress;

    arawWallet = _arawWallet;

    totalSupply_ = 5000000000 ether;
   
    balances[msg.sender] = 3650000000 ether;
    balances[reservedTokensAddress] = 750000000 ether;
    balances[foundersTokensAddress] = 450000000 ether;
    
    totalAdvisorsLockedTokens = 150000000 ether;
    balances[this] = 150000000 ether;
   
    state = State.Active;
   
    emit Transfer(address(0), msg.sender, balances[msg.sender]);
    emit Transfer(address(0), reservedTokensAddress, balances[reservedTokensAddress]);
    emit Transfer(address(0), foundersTokensAddress, balances[foundersTokensAddress]);
    emit Transfer(address(0), address(this), balances[this]);
  }

  /**
   * @dev release tokens for advisors
   */
  function releaseAdvisorsTokens() public returns (bool) {
    require(state == State.Closed);
    
    require (now > advisorsTokensFirstReleaseTime);
    
    if (now < advisorsTokensSecondReleaseTime) {   
      require (!isAdvisorsTokensFirstReleased);
      
      isAdvisorsTokensFirstReleased = true;
      releaseAdvisorsTokensForPercentage(30);

      return true;
    }

    if (now < advisorsTokensThirdReleaseTime) {
      require (!isAdvisorsTokensSecondReleased);
      
      if (!isAdvisorsTokensFirstReleased) {
        isAdvisorsTokensFirstReleased = true;
        releaseAdvisorsTokensForPercentage(60);
      } else{
        releaseAdvisorsTokensForPercentage(30);
      }
      
      isAdvisorsTokensSecondReleased = true;
      return true;
    }

    require (!isAdvisorsTokensThirdReleased);

    if (!isAdvisorsTokensFirstReleased) {
      releaseAdvisorsTokensForPercentage(100);
    } else if (!isAdvisorsTokensSecondReleased) {
      releaseAdvisorsTokensForPercentage(70);
    } else{
      releaseAdvisorsTokensForPercentage(40);
    }

    isAdvisorsTokensFirstReleased = true;
    isAdvisorsTokensSecondReleased = true;
    isAdvisorsTokensThirdReleased = true;

    return true;
  } 
  
  /**
   * @param percent tokens release for advisors from their pool
   */
  function releaseAdvisorsTokensForPercentage(uint256 percent) internal {
    uint256 releasedTokens = (percent.mul(totalAdvisorsLockedTokens)).div(100);

    balances[advisorsTokensAddress] = balances[advisorsTokensAddress].add(releasedTokens);
    balances[this] = balances[this].sub(releasedTokens);
    emit Transfer(this, advisorsTokensAddress, releasedTokens);
  }

  /**
   * @dev all ether transfer to another wallet automatic
   */
  function () public payable {
    require(state == State.Active); // Reject the transactions after ICO ended
    require(msg.value >= 0.1 ether);
    
    arawWallet.transfer(msg.value);
  }

  /**
  * After ICO close it helps to lock tokens for pools
  **/
  function close() onlyOwner public {
    require(state == State.Active);
    state = State.Closed;
    
    foundersTokensLockedPeriod = now + 365 days;
    reservedTokensLockedPeriod = now + 1095 days; //3 years
    advisorsTokensFirstReleaseTime = now + 12 weeks; //3 months to unlock 30 %
    advisorsTokensSecondReleaseTime = now + 24 weeks; // 6 months to unlock 30%
    advisorsTokensThirdReleaseTime = now + 365 days; //1 year to unlock 40 %
    
    emit Closed();
  }
}