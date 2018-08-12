pragma solidity ^0.4.11;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns(uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns(uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns(uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns(uint256) {
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
  function pause() public onlyOwner whenNotPaused returns(bool) {
    paused = true;
    emit Pause();
    return true;
  }
  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() public onlyOwner whenPaused returns(bool) {
    paused = false;
    emit Unpause();
    return true;
  }
}

contract ERC20 {

  uint256 public totalSupply;

  function transfer(address _to, uint256 _value) public returns(bool success);

  function transferFrom(address _from, address _to, uint256 _value) public returns(bool success);

  function balanceOf(address _owner) constant public returns(uint256 balance);

  function approve(address _spender, uint256 _value) public returns(bool success);

  function allowance(address _owner, address _spender) constant public returns(uint256 remaining);

  event Transfer(address indexed _from, address indexed _to, uint256 _value);

  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract BasicToken is ERC20, Pausable {
  using SafeMath for uint256;

  mapping(address => uint256) balances;
  mapping(address => mapping(address => uint256)) allowed;

  function _transfer(address _from, address _to, uint256 _value) internal returns(bool success) {
    require(_to != 0x0);
    require(_value > 0);
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  function transfer(address _to, uint256 _value) public whenNotPaused returns(bool success) {
    require(balances[msg.sender] >= _value);
    return _transfer(msg.sender, _to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns(bool success) {
    require(balances[_from] >= _value);
    require(allowed[_from][msg.sender] >= _value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    return _transfer(_from, _to, _value);
  }

  function balanceOf(address _owner) constant public returns(uint256 balance) {
    return balances[_owner];
  }

  function approve(address _spender, uint256 _value) public returns(bool success) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) constant public returns(uint256 remaining) {
    return allowed[_owner][_spender];
  }
}

contract PayChainCoin is BasicToken {

  string public constant name = "PayChainCoin";
  string public constant symbol = "PCC";
  uint256 public constant decimals = 18;

  constructor() public {
    _assign(0xa3f351bD8A2cB33822DeFE13e0efB968fc22A186, 690);
    _assign(0xd3C72E4D0EAdab0Eb7A4f416b67754185F72A1fa, 10);
    _assign(0x32A2594Ba3af6543E271e5749Dc39Dd85cFbE1e8, 150);
    _assign(0x7c3db3C5862D32A97a53BFEbb34C384a4b52C2Cc, 150);
  }

  function _assign(address _address, uint256 _value) private {
    uint256 amount = _value * (10 ** 6) * (10 ** decimals);
    balances[_address] = amount;
    totalSupply = totalSupply.add(amount);
  }
}