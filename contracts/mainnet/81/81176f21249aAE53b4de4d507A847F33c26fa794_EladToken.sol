pragma solidity ^0.4.18;

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

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;
  mapping(address => uint256) balances;
  uint256 totalSupply_;

  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }
}

contract StandardToken is ERC20, BasicToken {
  mapping (address => mapping (address => uint256)) internal allowed;

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

  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

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

contract PausableToken is StandardToken, Pausable {
  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
    return super.approve(_spender, _value);
  }

  function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}

contract EladToken is PausableToken {
  string public constant name = "Elad Token";
  string public constant symbol = "ELAD";
  uint8 public constant decimals = 18;

  uint256 public constant initialSupply = 100000000 * 10 ** uint256(decimals);

  uint256 public startTime = 1524470400; // 04/23/2018 @ 8:00am (UTC)
  
  struct TokenLock { uint256 amount; uint256 duration; bool withdrawn; }

  TokenLock public advisorLock = TokenLock({
    amount: initialSupply.div(uint256(100/5)), // 5% of initialSupply
    duration: 180 days,
    withdrawn: false
  });

  TokenLock public foundationLock = TokenLock({
    amount: initialSupply.div(uint256(100/10)), // 10% of initialSupply
    duration: 360 days,
    withdrawn: false
  });

  TokenLock public teamLock = TokenLock({
    amount: initialSupply.div(uint256(100/10)), // 10% of initialSupply
    duration: 720 days,
    withdrawn: false
  });

  function EladToken() public {
    totalSupply_ = initialSupply;
    balances[owner] = initialSupply;
    Transfer(address(0), owner, balances[owner]);

    lockTokens(advisorLock);
    lockTokens(foundationLock);
    lockTokens(teamLock);
  }

  function withdrawLocked() external onlyOwner {
    if (unlockTokens(advisorLock)) advisorLock.withdrawn = true;
    if (unlockTokens(foundationLock)) foundationLock.withdrawn = true;
    if (unlockTokens(teamLock)) teamLock.withdrawn = true;
  }

  function lockTokens(TokenLock lock) internal {
    balances[owner] = balances[owner].sub(lock.amount);
    balances[address(0)] = balances[address(0)].add(lock.amount);
    Transfer(owner, address(0), lock.amount);
  }

  function unlockTokens(TokenLock lock) internal returns (bool) {
    if (startTime + lock.duration < now && lock.withdrawn == false) {
      balances[owner] = balances[owner].add(lock.amount);
      balances[address(0)] = balances[address(0)].sub(lock.amount);
      Transfer(address(0), owner, lock.amount);
      return true;
    }
    return false;
  }
}