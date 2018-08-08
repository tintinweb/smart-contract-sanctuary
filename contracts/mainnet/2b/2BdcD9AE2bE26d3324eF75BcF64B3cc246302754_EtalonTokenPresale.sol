pragma solidity ^0.4.11;

/**
 * Math operations with safety checks
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    if ((a == 0) || (c / a == b)) {
      return c;
    }
    revert();
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a / b;
    if (a == b * c + a % b) {
      return c;
    }
    revert();
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    if (b <= a) {
      return a - b;
    }
    revert();
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    if (c >= a) {
      return c;
    }
    revert();
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }

}

/*
 * Ownable
 *
 * Base contract with an owner.
 * Provides onlyOwner modifier, which prevents function from running if it is called by anyone other than the owner.
 */
contract Ownable {
  address public owner;

  function Ownable() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    if (msg.sender != owner) {
      revert();
    }
    _;
  }

  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}

/*
 * Haltable
 *
 * Abstract contract that allows children to implement an
 * emergency stop mechanism. Differs from Pausable by causing a revert() when in halt mode.
 *
 *
 * Originally envisioned in FirstBlood ICO contract.
 */
contract Haltable is Ownable {
  bool public halted;

  event Halted(uint256 _time);
  event Unhalted(uint256 _time);
  
  modifier stopInEmergency {
    if (halted) revert();
    _;
  }

  modifier onlyInEmergency {
    if (!halted) revert();
    _;
  }

  // called by the owner on emergency, triggers stopped state
  function halt() external onlyOwner {
    halted = true;
    Halted( now );
  }

  // called by the owner on end of emergency, returns to normal state
  function unhalt() external onlyOwner onlyInEmergency {
    halted = false;
    Unhalted( now );
  }

}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface - no allowances
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev ERC20Basic with allowances
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value);
  function approve(address spender, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title Basic token
 * @dev realisation of ERC20Basic interface
 * @dev Basic version of StandardToken, with no allowances. 
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  /**
   * @dev Fix for the ERC20 short address attack.
   */
  modifier onlyPayloadSize(uint256 size) {
     if(msg.data.length < size + 4) {
       revert();
     }
     _;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of. 
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

}

/**
 * @title Standard ERC20 token
 *
 * @dev Implemantation of the basic standart token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is BasicToken, ERC20 {
  using SafeMath for uint256;
  
  mapping (address => mapping (address => uint256)) allowed;

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amout of tokens to be transfered
   */
  function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(3 * 32) {
    var _allowance = allowed[_from][msg.sender];
    allowed[_from][msg.sender] = _allowance.sub(_value);
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    
    Transfer(_from, _to, _value);
  }

  /**
   * @dev Aprove the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) onlyPayloadSize(2 * 32) {  //not letting anybody hit himself with short address attack

    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) revert();

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifing the amount of tokens still avaible for the spender.
   */
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

/**
 * @title EtalonToken
 * @dev Base Etalon ERC20 Token, where all tokens are pre-assigned to the creator. 
 * Note they can later distribute these tokens as they wish using `transfer` and other
 * `StandardToken` functions.
 */
contract EtalonToken is StandardToken, Haltable {
  using SafeMath for uint256;
  
  string  public name        = "Etalon Token";
  string  public symbol      = "ETL";
  uint256 public decimals    = 0;
  uint256 public INITIAL     = 4000000;
  
  event MoreTokensMinted(uint256 _minted, string reason);

  /**
   * @dev Contructor that gives msg.sender all of existing tokens. 
   */
  function EtalonToken() {
    totalSupply = INITIAL;
    balances[msg.sender] = INITIAL;
  }
  
  /**
   * @dev Function that creates new tokens by owner
   * @param _amount - how many tokens mint
   * @param reason  - for which reason minted
   */
  function mint( uint256 _amount, string reason ) onlyOwner {
    totalSupply = totalSupply.add(_amount);
    balances[msg.sender] = balances[msg.sender].add(_amount);
    MoreTokensMinted(_amount, reason);
  }
}

/**
 * @title Etalon Token Presale
 * @dev Presale contract
 */
contract EtalonTokenPresale is Haltable {
  using SafeMath for uint256;

  string public name = "Etalon Token Presale";

  EtalonToken public token;
  address public beneficiary;

  uint256 public hardCap;
  uint256 public softCap;
  uint256 public collected;
  uint256 public price;

  uint256 public tokensSold = 0;
  uint256 public weiRaised = 0;
  uint256 public investorCount = 0;
  uint256 public weiRefunded = 0;

  uint256 public startTime;
  uint256 public endTime;
  uint256 public duration;

  bool public softCapReached = false;
  bool public crowdsaleFinished = false;

  mapping (address => bool) refunded;

  event CrowdsaleStarted(uint256 _time, uint256 _softCap, uint256 _hardCap, uint256 _price );
  event CrowdsaleFinished(uint256 _time);
  event CrowdsaleExtended(uint256 _endTime);
  event GoalReached(uint256 _amountRaised);
  event SoftCapReached(uint256 _softCap);
  event NewContribution(address indexed _holder, uint256 _tokenAmount, uint256 _etherAmount);
  event Refunded(address indexed _holder, uint256 _amount);

  modifier onlyAfter(uint256 time) {
    if (now < time) revert();
    _;
  }

  modifier onlyBefore(uint256 time) {
    if (now > time) revert();
    _;
  }
  
  /**
   * @dev Constructor
   * @param _token       - address of ETL contract
   * @param _beneficiary - address, which gets all profits
   */
  function EtalonTokenPresale(
    address _token,
    address _beneficiary
  ) {
    hardCap = 0;
    softCap = 0;
    price   = 0;
  
    token = EtalonToken(_token);
    beneficiary = _beneficiary;

    startTime = 0;
    endTime   = 0;
  }
  
  /**
   * @dev Function that starts sales
   * @param _hardCap     - in ethers (not wei/gwei/finney)
   * @param _softCap     - in ethers (not wei/gwei/finney)
   * @param _duration - length of presale in hours
   * @param _price       - tokens per 1 ether
   * TRANSFER ENOUGH TOKENS TO THIS CONTRACT FIRST OR IT WONT BE ABLE TO SELL THEM
   */  
  function start(
    uint256 _hardCap,
    uint256 _softCap,
    uint256 _duration,
    uint256 _price ) onlyOwner
  {
    if (startTime > 0) revert();
    hardCap = _hardCap * 1 ether;
    softCap = _softCap * 1 ether;
    price   = _price;
    startTime = now;
    endTime   = startTime + _duration * 1 hours;
    duration  = _duration;
    CrowdsaleStarted(now, softCap, hardCap, price );
  }

  /**
   * @dev Function that ends sales
   * Made to insure finishing of sales - starts refunding
   */ 
  function finish() onlyOwner onlyAfter(endTime) {
    crowdsaleFinished = true;
    CrowdsaleFinished( now );
  }

  /**
   * @dev Function to extend period of presale
   * @param _duration - length of prolongation period
   * limited by 1/2 of year
   */
  function extend( uint256 _duration ) onlyOwner {
    endTime  = endTime + _duration * 1 hours;
    duration = duration + _duration;
    if ((startTime + 4500 hours) < endTime) revert();
    CrowdsaleExtended( endTime );
  }

  /**
   * fallback function - to recieve ethers and send tokens
   */
  function () payable stopInEmergency {
    if ( msg.value < uint256( 1 ether ).div( price ) ) revert();
    doPurchase(msg.sender, msg.value);
  }

  /**
   * @dev Function to get your ether back if presale failed 
   */
  function refund() external onlyAfter(endTime) stopInEmergency {  //public???
    if (!crowdsaleFinished) revert();
    if (softCapReached) revert();
    if (refunded[msg.sender]) revert();

    uint256 balance = token.balanceOf(msg.sender);
    if (balance == 0) revert();

    uint256 to_refund = balance.mul(1 ether).div(price);
    if (to_refund > this.balance) {
      to_refund = this.balance;  // if refunding is more than all, that contract hold - return all holded ether
    }

    msg.sender.transfer( to_refund ); // transfer throws on failure
    refunded[msg.sender] = true;
    weiRefunded = weiRefunded.add( to_refund );
    Refunded( msg.sender, to_refund );
  }

  /**
   * @dev Function to send profits and unsold tokens to beneficiary
   */
  function withdraw() onlyOwner {
    if (!softCapReached) revert();
    beneficiary.transfer( collected );
    token.transfer(beneficiary, token.balanceOf(this));
    crowdsaleFinished = true;
  }

  /**
   * @dev Get ether and transfer tokens
   * @param _buyer  - address of ethers sender
   * @param _amount - ethers sended
   */
  function doPurchase(address _buyer, uint256 _amount) private onlyAfter(startTime) onlyBefore(endTime) stopInEmergency {
    
    if (crowdsaleFinished) revert();

    if (collected.add(_amount) > hardCap) revert();

    if ((!softCapReached) && (collected < softCap) && (collected.add(_amount) >= softCap)) {
      softCapReached = true;
      SoftCapReached(softCap);
    }

    uint256 tokens = _amount.mul( price ).div( 1 ether ); //div(1 ether) - because _amount measured in weis
    if (tokens == 0) revert();

    if (token.balanceOf(_buyer) == 0) investorCount++;
    
    collected = collected.add(_amount);

    token.transfer(_buyer, tokens);

    weiRaised = weiRaised.add(_amount);
    tokensSold = tokensSold.add(tokens);

    NewContribution(_buyer, tokens, _amount);

    if (collected == hardCap) {
      GoalReached(hardCap);
    }
  }

  /**
   * @dev Making contract burnable
   * Added for testing reasons
   * onlyInEmergency - fools protection
   */
  function burn() onlyOwner onlyInEmergency { selfdestruct(owner); }
}