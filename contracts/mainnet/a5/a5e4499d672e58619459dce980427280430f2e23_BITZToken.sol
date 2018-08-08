pragma solidity ^0.4.18;

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

contract ReceivingContractCallback {

  function tokenFallback(address _from, uint _value) public;

}

contract WalletsPercents is Ownable {

  address[] public wallets;

  mapping (address => uint) public percents;

  function addWallet(address wallet, uint percent) public onlyOwner {
    wallets.push(wallet);
    percents[wallet] = percent;
  }
 
  function cleanWallets() public onlyOwner {
    wallets.length = 0;
  }

}

contract CommonToken is StandardToken, WalletsPercents {

  event Mint(address indexed to, uint256 amount);

  uint public constant PERCENT_RATE = 100;

  uint32 public constant decimals = 18;

  address[] public tokenHolders;

  bool public locked = false;

  mapping (address => bool)  public registeredCallbacks;

  mapping (address => bool) public unlockedAddresses;
  
  bool public initialized = false;

  function init() public onlyOwner {
    require(!initialized);
    totalSupply = 500000000000000000000000000;
    balances[this] = totalSupply;
    tokenHolders.push(this);
    Mint(this, totalSupply);
    unlockedAddresses[this] = true;
    unlockedAddresses[owner] = true;
    for(uint i = 0; i < wallets.length; i++) {
      address wallet = wallets[i];
      uint amount = totalSupply.mul(percents[wallet]).div(PERCENT_RATE);
      balances[this] = balances[this].sub(amount);
      balances[wallet] = balances[wallet].add(amount);
      tokenHolders.push(wallet);
      Transfer(this, wallet, amount);
    }
    initialized = true;
  }

  modifier notLocked(address sender) {
    require(!locked || unlockedAddresses[sender]);
    _;
  }

  function transferOwnership(address to) public {
    unlockedAddresses[owner] = false;
    super.transferOwnership(to);
    unlockedAddresses[owner] = true;
  }

  function addUnlockedAddress(address addressToUnlock) public onlyOwner {
    unlockedAddresses[addressToUnlock] = true;
  }

  function removeUnlockedAddress(address addressToUnlock) public onlyOwner {
    unlockedAddresses[addressToUnlock] = false;
  }

  function unlockBatchOfAddresses(address[] addressesToUnlock) public onlyOwner {
    for(uint i = 0; i < addressesToUnlock.length; i++) unlockedAddresses[addressesToUnlock[i]] = true;
  }

  function setLocked(bool newLock) public onlyOwner {
    locked = newLock;
  }

  function transfer(address to, uint256 value) public notLocked(msg.sender) returns (bool) {
    tokenHolders.push(to);
    return processCallback(super.transfer(to, value), msg.sender, to, value);
  }

  function transferFrom(address from, address to, uint256 value) public notLocked(from) returns (bool) {
    tokenHolders.push(to);
    return processCallback(super.transferFrom(from, to, value), from, to, value);
  }

  function registerCallback(address callback) public onlyOwner {
    registeredCallbacks[callback] = true;
  }

  function deregisterCallback(address callback) public onlyOwner {
    registeredCallbacks[callback] = false;
  }

  function processCallback(bool result, address from, address to, uint value) internal returns(bool) {
    if (result && registeredCallbacks[to]) {
      ReceivingContractCallback targetCallback = ReceivingContractCallback(to);
      targetCallback.tokenFallback(from, value);
    }
    return result;
  }

}

contract BITTToken is CommonToken {

  string public constant name = "BITT";

  string public constant symbol = "BITT";

}


contract BITZToken is CommonToken {

  string public constant name = "BITZ";

  string public constant symbol = "BITZ";

}

contract Configurator is Ownable {

  CommonToken public bittToken;

  CommonToken public bitzToken;

  function Configurator() public onlyOwner {
    address manager = 0xe99c8d442a5484bE05E3A5AB1AeA967caFf07133;

    bittToken = new BITTToken();
    bittToken.addWallet(0x08C32a099E59c7e913B16cAd4a6C988f1a5A7216, 60);
    bittToken.addWallet(0x5b2A9b86113632d086CcD8c9dAf67294eda78105, 20);
    bittToken.addWallet(0x3019B9ad002Ddec2F49e14FB591c8CcD81800847, 10);
    bittToken.addWallet(0x18fd87AAB645fd4c0cEBc21fb0a271E1E2bA5363, 5);
    bittToken.addWallet(0x1eC03A084Cc02754776a9fEffC4b47dAE4800620, 3);
    bittToken.addWallet(0xb119f842E6A10Dc545Af3c53ff28250B5F45F9b2, 2);
    bittToken.init();
    bittToken.transferOwnership(manager);

    bitzToken = new BITZToken();
    bitzToken.addWallet(0xc0f1a3E91C2D0Bcc5CD398D05F851C2Fb1F3fE30, 60);
    bitzToken.addWallet(0x3019B9ad002Ddec2F49e14FB591c8CcD81800847, 20);
    bitzToken.addWallet(0x04eb6a716c814b0B4A12dC9964916D64C55179C1, 20);
    bitzToken.init();
    bitzToken.transferOwnership(manager);
  }

}