pragma solidity 0.4.24;

contract ERC20 {
    function totalSupply() constant public returns (uint256 supply);
    function balanceOf(address _owner) constant public returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) constant public returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
  function safeSub(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }
}

contract EmanateToken is ERC20 {

  using SafeMath for uint256;

  string public constant name = "Emanate (MN8) Token";
  string public constant symbol = "MN8";
  uint256 public constant decimals = 18;
  uint256 public constant totalTokens = 208000000 * (10 ** decimals);

  mapping (address => uint256) public balances;
  mapping (address => mapping (address => uint256)) public allowed;

  bool public locked = true;
  bool public burningEnabled = false;
  address public owner;
  address public burnAddress;

  modifier unlocked (address _to) {
    require(
      owner == msg.sender ||
      locked == false ||
      allowance(owner, msg.sender) > 0 ||
      (_to == burnAddress && burningEnabled == true)
    );
    _;
  }

  constructor () public {
    balances[msg.sender] = totalTokens;
    owner = msg.sender;
  }

  function totalSupply() public view returns (uint256) {
    return totalTokens;
  }

  
  function transfer(address _to, uint _tokens) unlocked(_to) public returns (bool success) {
    balances[msg.sender] = balances[msg.sender].safeSub(_tokens);
    balances[_to] = balances[_to].safeAdd(_tokens);
    emit Transfer(msg.sender, _to, _tokens);
    return true;
  }

  function transferFrom(address from, address _to, uint _tokens) unlocked(_to) public returns (bool success) {
    balances[from] = balances[from].safeSub(_tokens);
    allowed[from][msg.sender] = allowed[from][msg.sender].safeSub(_tokens);
    balances[_to] = balances[_to].safeAdd(_tokens);
    emit Transfer(from, _to, _tokens);
    return true;
  }

  function balanceOf(address _owner) constant public returns (uint256) {
    return balances[_owner];
  }
  

  function approve(address _spender, uint256 _value) unlocked(_spender) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) constant public returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  function setBurnAddress (address _burnAddress) public {
    require(msg.sender == owner);
    burningEnabled = true;
    burnAddress = _burnAddress;
  }

  function unlock () public {
    require(msg.sender == owner);
    locked = false;
    owner = 0x0000000000000000000000000000000000000001;
  }
}