pragma solidity 0.4.24;


// interface standard erc20
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// library safe prevent overflow, underflow
library SafeMath {

  // safe multiple
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  // safe division
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  // safe substract value
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  // safe addition value
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

// implement standard interface erc20
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  // implementation of transfer token
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value > 0);
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  // check balance user (map)
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

// more common interface erc20
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;

  // implementation transfer from another user
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_value > 0);
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  // implementation approval to allowed transfer
  function approve(address _spender, uint256 _value) public returns (bool) {
    require(_value > 0);
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  // check total allowance particular user
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

 // implementation increase total approval from particular user
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    require(_addedValue > 0);
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  // implementation decrease total approval from particular user
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    require(_subtractedValue > 0);
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

// Pausable porposes
contract Ownable {
  address public owner;

  // make creator become the owner
  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
}

contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;

  // check if pause stat variable = false
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  // check if pause stat variable = true
  modifier whenPaused() {
    require(paused);
    _;
  }

  // make pause variable = true;
  function pause() public onlyOwner whenNotPaused {
    paused = true;
    emit Pause();
  }

 // make pause variable = false;
  function unpause() public onlyOwner whenPaused {
    paused = false;
    emit Unpause();
  }
}

// implementation pauseable erc20
contract PausableToken is StandardToken, Pausable {

  // call whenNotPaused modifier to check next state
  
  function transfer(
    address _to,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.transfer(_to, _value);
  }

  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(
    address _spender,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.approve(_spender, _value);
  }

  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    whenNotPaused
    returns (bool success)
  {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    whenNotPaused
    returns (bool success)
  {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}

contract TutorialToken is PausableToken {

  string public constant name = "TutorialToken"; 
  string public constant symbol = "TT"; 
  uint8 public constant decimals = 18; 

  uint256 public constant INITIAL_SUPPLY = 888000000 * (10 ** uint256(decimals));

  constructor() public {
    totalSupply = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
    emit Transfer(0x0, msg.sender, INITIAL_SUPPLY);
  }

}