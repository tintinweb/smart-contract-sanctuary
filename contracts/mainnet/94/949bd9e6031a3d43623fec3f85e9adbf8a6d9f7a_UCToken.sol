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

  event Frozen(address indexed _address, bool _value);

  mapping(address => uint256) balances;
  mapping(address => bool) public frozens;
  mapping(address => mapping(address => uint256)) allowed;

  function _transfer(address _from, address _to, uint256 _value) internal returns(bool success) {
    require(_to != 0x0);
    require(_value > 0);
    require(frozens[_from] == false);
    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
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

  function freeze(address[] _targets, bool _value) public onlyOwner returns(bool success) {
    require(_targets.length > 0);
    require(_targets.length <= 255);
    for (uint8 i = 0; i < _targets.length; i++) {
      assert(_targets[i] != 0x0);
      frozens[_targets[i]] = _value;
      emit Frozen(_targets[i], _value);
    }
    return true;
  }

  function transferMulti(address[] _to, uint256[] _value) public whenNotPaused returns(bool success) {
    require(_to.length > 0);
    require(_to.length <= 255);
    require(_to.length == _value.length);
    require(frozens[msg.sender] == false);
    uint8 i;
    uint256 amount;
    for (i = 0; i < _to.length; i++) {
      assert(_to[i] != 0x0);
      assert(_value[i] > 0);
      amount = amount.add(_value[i]);
    }
    require(balances[msg.sender] >= amount);
    balances[msg.sender] = balances[msg.sender].sub(amount);
    for (i = 0; i < _to.length; i++) {
      balances[_to[i]] = balances[_to[i]].add(_value[i]);
      emit Transfer(msg.sender, _to[i], _value[i]);
    }
    return true;
  }
}

contract UCToken is BasicToken {

  string public constant name = "UnityChainToken";
  string public constant symbol = "UCT";
  uint256 public constant decimals = 18;

  constructor() public {
    // 私募
    _assign(0x490657f65380fe9e47ab46671B9CE7d02a06dF40, 1500);
    // 团队
    _assign(0xA0d5366E74E56Be39542BD6125897E30775C7bd8, 1500);
    // 商城返利
    _assign(0xDdb844341f70DC7FB45Ca27E26cB5a131823AE74, 1000);
    // 推广分红
    _assign(0xfdE4884AD60012b80c1E57cCf4526d38746899a0, 250);
    // 持仓分红
    _assign(0xf5Cfb87CAe4bC2D314D824De5B1B7a9F00Ef30Ee, 250);
    // 交易分红
    _assign(0xbbFc3e1Fc45fEDaA9FaB4fF1f74374ED4f217b4c, 250);
    // 二次分红
    _assign(0x2EAdc466b18bAb66369C52CF8F37DAf383F793a7, 250);
  }

  function _assign(address _address, uint256 _value) private {
    uint256 amount = _value * (10 ** 6) * (10 ** decimals);
    balances[_address] = amount;
    allowed[_address][owner] = amount;
    totalSupply = totalSupply.add(amount);
  }
}