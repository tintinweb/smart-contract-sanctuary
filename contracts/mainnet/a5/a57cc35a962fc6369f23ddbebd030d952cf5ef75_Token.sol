pragma solidity ^0.4.18;
contract Ownable {
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  function Ownable() public {
    owner = msg.sender;
  }
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}
contract Pausable is Ownable {
  event Pause();
  event Unpause();
  bool public paused = false;
  modifier whenNotPaused() {
    require(!paused);
    _;
  }
  modifier whenPaused() {
    require(paused);
    _;
  }
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}
library SafeMath {
  function mul(uint a, uint b) internal pure returns (uint) {
    if (a == 0) {
      return 0;
    }
    uint c = a * b;
    assert(c / a == b);
    return c;
  }
  function div(uint a, uint b) internal pure returns (uint) {
    uint c = a / b;
    return c;
  }
  function sub(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }
  function add(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }
}
contract ERC20 {
  string public name;
  string public symbol;
  uint8 public decimals;
  uint public totalSupply;  
  function ERC20(string _name, string _symbol, uint8 _decimals) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
  }
  function balanceOf(address who) public view returns (uint);
  function transfer(address to, uint value) public returns (bool);
  function allowance(address owner, address spender) public view returns (uint);
  function transferFrom(address from, address to, uint value) public returns (bool);
  function approve(address spender, uint value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}
contract Token is Pausable, ERC20 {
  using SafeMath for uint;
  mapping(address => uint) balances;
  mapping (address => mapping (address => uint)) internal allowed;
  mapping(address => uint) public balanceOfLocked;
  mapping(address => bool) public addressLocked;
  uint public unlocktime;
  bool manualUnlock;
  address public crowdsaleAddress = 0;
  function Token() ERC20("ALexchange", "ALEX", 18) public {
    manualUnlock = false;
    unlocktime = 1527868800;
    totalSupply = 10000000000 * 10 ** uint(decimals);
    balances[msg.sender] = totalSupply;
  }
  function allowCrowdsaleAddress(address crowdsale) onlyOwner public {
    crowdsaleAddress = crowdsale;
  }
  function isLocked() view public returns (bool) {
    return (now < unlocktime && !manualUnlock);
  }
  modifier lockCheck(address from, uint value) { 
    require(addressLocked[from] == false);
    if (isLocked()) {
      require(value <= balances[from] - balanceOfLocked[from]);
    } else {
      balanceOfLocked[from] = 0; 
    }
    _;
  }
  function lockAddress(address addr) onlyOwner public {
    addressLocked[addr] = true;
  }
  function unlockAddress(address addr) onlyOwner public {
    addressLocked[addr] = false;
  }
  function unlock() onlyOwner public {
    require(!manualUnlock);
    manualUnlock = true;
  }
  function transfer(address _to, uint _value) lockCheck(msg.sender, _value) whenNotPaused public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }
  function transferLockedPart(address _to, uint _value) whenNotPaused public returns (bool) {
    require(msg.sender == crowdsaleAddress);
    if (transfer(_to, _value)) {
      balanceOfLocked[_to] = balanceOfLocked[_to].add(_value);
      return true;
    }
  }
  function balanceOf(address _owner) public view returns (uint balance) {
    return balances[_owner];
  }
  function transferFrom(address _from, address _to, uint _value) public lockCheck(_from, _value) whenNotPaused returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }
  function approve(address _spender, uint _value) public whenNotPaused returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }
  function allowance(address _owner, address _spender) public view returns (uint) {
    return allowed[_owner][_spender];
  }
  function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }
  function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool) {
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