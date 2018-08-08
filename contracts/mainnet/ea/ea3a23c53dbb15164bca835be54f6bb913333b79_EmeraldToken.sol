pragma solidity ^0.4.13;
/* 
* From OpenZeppelin project: https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts/math/SafeMath.sol
*/

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

/*
 * ERC20 interface
 * see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  function allowance(address owner, address spender) constant returns (uint);

  function transfer(address to, uint value) returns (bool);
  function transferFrom(address from, address to, uint value) returns (bool);
  function approve(address spender, uint value) returns (bool ok);
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}


/**
 * Standard ERC20 token with Short Hand Attack and approve() race condition mitigation.
 *
 * Based on code by FirstBlood:
 * https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20 {

  using SafeMath for uint;

  /* Actual balances of token holders */
  mapping (address => uint) balances;

  /* approve() allowances */
  mapping (address => mapping (address => uint)) allowed;

  /* Interface declaration */
  function isToken() public constant returns (bool) {
    return true;
  }

  /**
   *
   * Fix for the ERC20 short address attack
   *
   * http://vessenes.com/the-erc20-short-address-attack-explained/
   */
  modifier onlyPayloadSize(uint size) {
    assert(msg.data.length >= size + 4);
    _;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) returns (bool) {
    require(balances[msg.sender] >= _value);
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(2 * 32) returns (bool) {
    require(balances[_from] >= _value && allowed[_from][_to] >= _value);
    allowed[_from][_to] = allowed[_from][_to].sub(_value);
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of. 
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
  }
  
  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint _value) returns (bool success) {
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
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }

}



/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner = msg.sender;

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
    require(newOwner != address(0));
    owner = newOwner;
  }

}


contract EmeraldToken is StandardToken, Ownable {

  string public name;
  string public symbol;
  uint public decimals;

  mapping (address => bool) public producers;

  bool public released = false;

  /*
  * Only producer allowed
  */
  modifier onlyProducer() {
    require(producers[msg.sender] == true);
    _;
  }

  /**
   * Limit token transfer until the distribution is over.
   * Owner can transfer tokens anytime
   */
  modifier canTransfer(address _sender) {
    if (_sender != owner)
      require(released);
    _;
  }

  modifier inProduction() {
    require(!released);
    _;
  }

  function EmeraldToken(string _name, string _symbol, uint _decimals) {
    require(_decimals > 0);
    name = _name;
    symbol = _symbol;
    decimals = _decimals;

    // Make owner a producer of Emeralds
    producers[msg.sender] = true;
  }

  /*
  * Sets a producer&#39;s status
  * Distribution contract can be a producer
  */
  function setProducer(address _addr, bool _status) onlyOwner {
    producers[_addr] = _status;
  }

  /*
  * Creates new Emeralds
  */
  function produceEmeralds(address _receiver, uint _amount) onlyProducer inProduction {
    balances[_receiver] = balances[_receiver].add(_amount);
    totalSupply = totalSupply.add(_amount);
    Transfer(0, _receiver, _amount);
  }

  /**
   * One way function to release the tokens to the wild. No more tokens can be created.
   */
  function releaseTokenTransfer() onlyOwner {
    released = true;
  }

  function transfer(address _to, uint _value) canTransfer(msg.sender) returns (bool) {
    // Call StandardToken.transfer()
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint _value) canTransfer(_from) returns (bool) {
    // Call StandardToken.transferForm()
    return super.transferFrom(_from, _to, _value);
  }

}