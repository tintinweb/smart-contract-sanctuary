pragma solidity ^0.4.13;

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
   * @return A uint256 specifing the amount of tokens still avaible for the spender.
   */
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
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

  bool public paused = false;


  /**
   * @dev modifier to allow actions only when the contract IS paused
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev modifier to allow actions only when the contract IS NOT paused
   */
  modifier whenPaused {
    require(paused);
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
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused returns (bool) {
    paused = false;
    Unpause();
    return true;
  }
}

/**
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract BurnableToken is StandardToken {
 
  /**
   * @dev Burns a specific amount of tokens.
   * @param _value The amount of token to be burned.
   */
  function burn(uint _value) public {
    require(_value > 0);
    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_value);
    totalSupply = totalSupply.sub(_value);
    Burn(burner, _value);
  }
 
  event Burn(address indexed burner, uint indexed value);
 
}

/**
 * @title Hamster Marketplace Token Network Token
 * @dev ERC20 Hamster Marketplace Token Network Token (HMT)
 *
 * HMT Tokens are divisible by 1e8 (100,000,000) base
 * units referred to as &#39;Grains&#39;.
 *
 * HMT are displayed using 8 decimal places of precision.
 *
 * 1 HMT is equivalent to:
 *   100000000 == 1 * 10**8 == 1e8 == One Hundred Million Grains
 *
 * 10 Million HMT (total supply) is equivalent to:
 *   1000000000000000 == 10000000 * 10**8 == 1e15 == One Quadrillion Grains
 *
 * All initial HMT Grains are assigned to the creator of
 * this contract.
 *
 */
contract HamsterMarketplaceToken is BurnableToken, Pausable {

  string public constant name = &#39;Hamster Marketplace Token&#39;;                   // Set the token name for display
  string public constant symbol = &#39;HMT&#39;;                                       // Set the token symbol for display
  uint8 public constant decimals = 8;                                          // Set the number of decimals for display
  uint256 constant INITIAL_SUPPLY = 10000000 * 10**uint256(decimals);          // 10 Million HMT specified in Grains
  uint256 public sellPrice;
  mapping(address => uint256) bonuses;
  uint8 public freezingPercentage;
  uint32 public constant unfreezingTimestamp = 1550534400;                     // 2019, February, 19, 00:00:00 UTC

  /**
   * @dev HamsterMarketplaceToken Constructor
   * Runs only on initial contract creation.
   */
  function HamsterMarketplaceToken() {
    totalSupply = INITIAL_SUPPLY;                                              // Set the total supply
    balances[msg.sender] = INITIAL_SUPPLY;                                     // Creator address is assigned all
    sellPrice = 0;
    freezingPercentage = 100;
  }

  function balanceOf(address _owner) constant returns (uint256 balance) {
    return super.balanceOf(_owner) - bonuses[_owner] * freezingPercentage / 100;
  }

  /**
   * @dev Transfer token for a specified address when not paused
   * @param _to The address to transfer to.
   * @param _value The amount to be transferred.
   */
  function transfer(address _to, uint256 _value) whenNotPaused returns (bool) {
    require(_to != address(0));
    require(balances[msg.sender] - bonuses[msg.sender] * freezingPercentage / 100 >= _value);
    return super.transfer(_to, _value);
  }

  /**
   * @dev Transfer tokens and bonus tokens to a specified address
   * @param _to The address to transfer to.
   * @param _value The amount to be transferred.
   * @param _bonus The bonus amount.
   */
  function transferWithBonuses(address _to, uint256 _value, uint256 _bonus) onlyOwner returns (bool) {
    require(_to != address(0));
    require(balances[msg.sender] - bonuses[msg.sender] * freezingPercentage / 100 >= _value + _bonus);
    bonuses[_to] = bonuses[_to].add(_bonus);
    return super.transfer(_to, _value + _bonus);
  }

  /**
   * @dev Check the frozen bonus balance
   * @param _owner The address to check the balance of.
   */
  function bonusesOf(address _owner) constant returns (uint256 balance) {
    return bonuses[_owner] * freezingPercentage / 100;
  }

  /**
   * @dev Unfreezing part of bonus tokens by owner
   * @param _percentage uint8 Percentage of bonus tokens to be left frozen
   */
  function setFreezingPercentage(uint8 _percentage) onlyOwner returns (bool) {
    require(_percentage < freezingPercentage);
    require(now < unfreezingTimestamp);
    freezingPercentage = _percentage;
    return true;
  }

  /**
   * @dev Unfreeze all bonus tokens
   */
  function unfreezeBonuses() returns (bool) {
    require(now >= unfreezingTimestamp);
    freezingPercentage = 0;
    return true;
  }

  /**
   * @dev Transfer tokens from one address to another when not paused
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) whenNotPaused returns (bool) {
    require(_to != address(0));
    require(balances[_from] - bonuses[_from] * freezingPercentage / 100 >= _value);
    return super.transferFrom(_from, _to, _value);
  }

  /**
   * @dev Aprove the passed address to spend the specified amount of tokens on behalf of msg.sender when not paused.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) whenNotPaused returns (bool) {
    return super.approve(_spender, _value);
  }

 /**
  * @dev Gets the purchase price of tokens by contract
  */
  function getPrice() constant returns (uint256 _sellPrice) {
      return sellPrice;
  }

  /**
  * @dev Sets the purchase price of tokens by contract
  * @param newSellPrice New purchase price
  */
  function setPrice(uint256 newSellPrice) external onlyOwner returns (bool success) {
      require(newSellPrice > 0);
      sellPrice = newSellPrice;
      return true;
  }

  /**
    * @dev Buying ethereum for tokens
    * @param amount Number of tokens
    */
  function sell(uint256 amount) external returns (uint256 revenue){
      require(balances[msg.sender] - bonuses[msg.sender] * freezingPercentage / 100 >= amount);           // Checks if the sender has enough to sell
      balances[this] = balances[this].add(amount);                                                        // Adds the amount to owner&#39;s balance
      balances[msg.sender] = balances[msg.sender].sub(amount);                                            // Subtracts the amount from seller&#39;s balance
      revenue = amount.mul(sellPrice);                                                                    // Calculate the seller reward
      msg.sender.transfer(revenue);                                                                       // Sends ether to the seller: it&#39;s important to do this last to prevent recursion attacks
      Transfer(msg.sender, this, amount);                                                                 // Executes an event reflecting on the change
      return revenue;                                                                                     // Ends function and returns
  }

  /**
  * @dev Allows you to get tokens from the contract
  * @param amount Number of tokens
  */
  function getTokens(uint256 amount) onlyOwner external returns (bool success) {
      require(balances[this] >= amount);
      balances[msg.sender] = balances[msg.sender].add(amount);
      balances[this] = balances[this].sub(amount);
      Transfer(this, msg.sender, amount);
      return true;
  }

  /**
  * @dev Allows you to put Ethereum to the smart contract
  */
  function sendEther() payable onlyOwner external returns (bool success) {
      return true;
  }

  /**
  * @dev Allows you to get ethereum from the contract
  * @param amount Number of tokens
  */
  function getEther(uint256 amount) onlyOwner external returns (bool success) {
      require(amount > 0);
      msg.sender.transfer(amount);
      return true;
  }
}