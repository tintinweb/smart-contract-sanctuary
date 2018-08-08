pragma solidity ^0.4.16;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
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


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() {
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
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();
  event PauseRefund();
  event UnpauseRefund();

  bool public paused = true;
  bool public refundPaused = true;

  /**
   * @dev modifier to allow actions only when the contract IS NOT paused
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev modifier to allow actions only when the refund IS NOT paused
   */
  modifier whenRefundNotPaused() {
    require(!refundPaused);
    _;
  }

  /**
   * @dev modifier to allow actions only when the contract IS paused
   */
  modifier whenPaused {
    require(paused);
    _;
  }
  
  /**
   * @dev modifier to allow actions only when the refund IS paused
   */
  modifier whenRefundPaused {
    require(refundPaused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused returns (bool) {
    paused = true;
    Pause();
    return true;
  }
  
  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pauseRefund() onlyOwner whenRefundNotPaused returns (bool) {
    refundPaused = true;
    PauseRefund();
    return true;
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused returns (bool) {
    paused = false;
    Unpause();
    return true;
  }
  
  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpauseRefund() onlyOwner whenRefundPaused returns (bool) {
    refundPaused = false;
    UnpauseRefund();
    return true;
  }
}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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
  function transfer(address _to, uint256 _value) returns (bool) {
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
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
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

  mapping (address => mapping (address => uint256)) allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amout of tokens to be transfered
   */
  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    var _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // require (_value <= _allowance);

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Aprove the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) returns (bool) {

    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifing the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

/**
 * @title SimpleToken
 * @dev Very simple ERC20 Token example, where all tokens are pre-assigned to the creator.
 * Note they can later distribute these tokens as they wish using `transfer` and other
 * `StandardToken` functions.
 */
contract AssetToken is Pausable, StandardToken {

  using SafeMath for uint256;

  address public treasurer = 0x0;

  uint256 public purchasableTokens = 0;

  string public name = "Asset Token";
  string public symbol = "AST";
  uint256 public decimals = 18;
  uint256 public INITIAL_SUPPLY = 1000000000 * 10**18;

  uint256 public RATE = 200;
  uint256 public REFUND_RATE = 200;

  /**
   * @dev Contructor that gives msg.sender all of existing tokens.
   */
  function AssetToken() {
    totalSupply = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner {
    address oldOwner = owner;
    super.transferOwnership(newOwner);
    balances[newOwner] = balances[oldOwner];
    balances[oldOwner] = 0;
  }

  /**
   * @dev Allows the current owner to transfer treasurership of the contract to a newTreasurer.
   * @param newTreasurer The address to transfer treasurership to.
   */
  function transferTreasurership(address newTreasurer) onlyOwner {
    if (newTreasurer != address(0)) {
      treasurer = newTreasurer;
    }
  }

  /**
   * @dev Allows owner to release tokens for purchase
   * @param amount The number of tokens to release
   */
  function setPurchasable(uint256 amount) onlyOwner {
    require(amount > 0);
    require(balances[owner] >= amount);
    purchasableTokens = amount.mul(10**18);
  }
  
  /**
   * @dev Allows owner to change the rate Tokens per 1 Ether
   * @param rate The number of tokens to release
   */
  function setRate(uint256 rate) onlyOwner {
      RATE = rate;
  }
  
  /**
   * @dev Allows owner to change the refund rate Tokens per 1 Ether
   * @param rate The number of tokens to release
   */
  function setRefundRate(uint256 rate) onlyOwner {
      REFUND_RATE = rate;
  }

  /**
   * @dev fallback function
   */
  function () payable {
    buyTokens(msg.sender);
  }

  /**
   * @dev function that sells available tokens
   */
  function buyTokens(address addr) payable whenNotPaused {
    require(treasurer != 0x0); // Must have a treasurer

    // Calculate tokens to sell and check that they are purchasable
    uint256 weiAmount = msg.value;
    uint256 tokens = weiAmount.mul(RATE);
    require(purchasableTokens >= tokens);

    // Send tokens to buyer
    purchasableTokens = purchasableTokens.sub(tokens);
    balances[owner] = balances[owner].sub(tokens);
    balances[addr] = balances[addr].add(tokens);

    Transfer(owner, addr, tokens);

    // Send money to the treasurer
    treasurer.transfer(msg.value);
  }
  
  function fund() payable {}

  function defund() onlyOwner {
      treasurer.transfer(this.balance);
  }
  
  function refund(uint256 _amount) whenRefundNotPaused {
      require(balances[msg.sender] >= _amount);
      
      // Calculate refund
      uint256 refundAmount = _amount.div(REFUND_RATE);
      require(this.balance >= refundAmount);
      
      balances[msg.sender] = balances[msg.sender].sub(_amount);
      balances[owner] = balances[owner].add(_amount);
      
      msg.sender.transfer(refundAmount);
  }
}