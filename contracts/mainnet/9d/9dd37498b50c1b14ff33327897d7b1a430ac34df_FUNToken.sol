pragma solidity ^0.4.22;

// File: contracts/zeppelin/math/SafeMath.sol

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

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {

  address public owner;

  address public newOwner;

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
  
  event OwnershipTransferred(address oldOwner, address newOwner);
}

contract FUNToken is Ownable { //ERC - 20 token contract
  using SafeMath for uint;
  // Triggered when tokens are transferred.
  event Transfer(address indexed _from, address indexed _to, uint256 _value);

  // Triggered whenever approve(address _spender, uint256 _value) is called.
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  string public constant symbol = "FUN"; // solium-disable-line uppercase
  string public constant name = "THEFORTUNEFUND"; // solium-disable-line uppercase
  uint8 public constant decimals = 18; // solium-disable-line uppercase
  /** @dev maximum token supply
  */
  uint256 _totalSupply = 88888888 ether;

  // Balances for each account
  mapping(address => uint256) balances;

  // Owner of account approves the transfer of an amount to another account
  mapping(address => mapping (address => uint256)) allowed;

  /**
  * @dev total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) { //standart ERC-20 function
    return _totalSupply;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256 balance) {//standart ERC-20 function
    return balances[_owner];
  }
  
  // @dev is token transfer is locked
  bool public locked = false;

  // @dev is token transfer can be changed
  bool public canChangeLocked = true;

  /**
  * @dev change lock transfer token (&#39;locked&#39;)
  * @param _request true or false
  */
  function changeLockTransfer (bool _request) public onlyOwner {
    require(canChangeLocked);
    locked = _request;
  }

  /**
  * @dev final unlock transfer token (&#39;locked&#39; and &#39;canChangeLocked&#39;)
  * Makes for crypto exchangers to prevent the possibility of further blocking
  */
  function finalUnlockTransfer () public {
    require (canChangeLocked);
  
    locked = false;
    canChangeLocked = false;
  }
  
  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _amount The amount to be transferred.
  */
  function transfer(address _to, uint256 _amount) public returns (bool success) {
    require(this != _to);
    require (_to != address(0));
    require(!locked);
    balances[msg.sender] = balances[msg.sender].sub(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Transfer(msg.sender,_to,_amount);
    return true;
  }

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _amount uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _amount) public returns(bool success){
    require(this != _to);
    require (_to != address(0));
    require(!locked);
    balances[_from] = balances[_from].sub(_amount);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Transfer(_from,_to,_amount);
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
   * @param _amount The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _amount)public returns (bool success) { 
    allowed[msg.sender][_spender] = _amount;
    emit Approval(msg.sender, _spender, _amount);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender)public view returns (uint256 remaining) {
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

  /** @dev Token cunstructor
    */
  constructor () public {
    owner = 0x85BC7DC54c637Dd432e90B91FE803AaA7744E158;
    tokenHolder = 0x85BC7DC54c637Dd432e90B91FE803AaA7744E158;
    balances[tokenHolder] = _totalSupply;
  }

  // @dev Address which contains all minted tokens
  address public tokenHolder;

  // @dev Crowdsale contract address
  address public crowdsaleContract;

  /**
   * @dev setting &#39;crowdsaleContract&#39; variable. Call automatically when crowdsale contract deployed 
   * throws &#39;crowdsaleContract&#39; already exists
   */
  function setCrowdsaleContract (address _address) public{
    require(crowdsaleContract == address(0));

    crowdsaleContract = _address;
  }

  //@dev How many tokens crowdsale contract has to sell
  uint public crowdsaleBalance = 77333333 ether; //Tokens
  
  /**
   * @dev gets `_address` and `_value` as input and sells tokens to &#39;_address&#39;
   * throws if not enough tokens after calculation
   */
  function sendCrowdsaleTokens (address _address, uint _value) public {
    require(msg.sender == crowdsaleContract);

    balances[tokenHolder] = balances[tokenHolder].sub(_value);
    balances[_address] = balances[_address].add(_value);
    
    crowdsaleBalance = crowdsaleBalance.sub(_value);
    
    emit Transfer(tokenHolder,_address,_value);    
  }

  /// @dev event when someone burn Tokens
  event Burn(address indexed burner, uint tokens);

  /**
   * @dev `_value` as input and burn tokens 
   * throws if message sender has not enough tokens after calculation
   */
  function burnTokens (uint _value) external {
    balances[msg.sender] = balances[msg.sender].sub(_value);

    _totalSupply = _totalSupply.sub(_value);

    emit Transfer(msg.sender, 0, _value);
    emit Burn(msg.sender, _value);
  } 
}