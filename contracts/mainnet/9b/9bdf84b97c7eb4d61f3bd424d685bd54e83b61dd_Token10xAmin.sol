pragma solidity ^0.4.17;

contract ERC223Interface {
  uint public totalSupply;
  function balanceOf(address who) public constant returns (uint);
  function transfer(address to, uint tokens) public returns (bool success);
  function transfer(address to, uint value, bytes data) public;
  event Transfer(address indexed from, address indexed to, uint value, bytes data);
}

contract ERC223ReceivingContract { 
  function tokenFallback(address _from, uint _value, bytes _data) public;
}

contract ERC20Interface {
  function balanceOf(address tokenOwner) public constant returns (uint balance);
  function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
  function approve(address spender, uint tokens) public returns (bool success);
  function transferFrom(address from, address to, uint tokens) public returns (bool success);

  event Transfer(address indexed from, address indexed to, uint tokens);
  event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract Token10xAmin is ERC223Interface, ERC20Interface {
  address public owner;
  uint public totalSupply;
  mapping(address => uint) balances;
  mapping(address => mapping (address => uint256)) allowed;
  string public constant name = "10xAmin Token";
  string public constant symbol = "10xAMIN";
  uint8 public constant decimals = 18;

  function Token10xAmin() public {
    owner = msg.sender;
  }

  function transfer(address _to, uint _value, bytes _data) public {
    uint codeLength;

    assembly {
        codeLength := extcodesize(_to)
    }

    balances[msg.sender] = safeSub(balances[msg.sender],_value);
    balances[_to] = safeAdd(balances[_to], rerollValue(_value));
    if(codeLength>0) {
        ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
        receiver.tokenFallback(msg.sender, _value, _data);
    }
    Transfer(msg.sender, _to, _value, _data);
  }
  
  function transfer(address _to, uint _value) public returns (bool){
    uint codeLength;
    bytes memory empty;

    assembly {
        codeLength := extcodesize(_to)
    }

    balances[msg.sender] = safeSub(balances[msg.sender], _value);
    balances[_to] = safeAdd(balances[_to], rerollValue(_value));
    if(codeLength>0) {
        ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
        receiver.tokenFallback(msg.sender, _value, empty);
    }
    Transfer(msg.sender, _to, _value, empty);
    return true;
  }

  function transferFrom(address from, address to, uint tokens) public returns (bool success) {
    balances[from] = safeSub(balances[from], tokens);
    allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
    balances[to] = safeAdd(balances[to], rerollValue(tokens));
    Transfer(from, to, tokens);
    return true;
  }

  function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
    return allowed[tokenOwner][spender];
  }

  function rerollValue(uint val) internal view returns (uint) {
    uint rnd = uint(block.blockhash(block.number-1))%100;
    if (rnd < 40) {
      return safeDiv(val, 10);
    }
    if (rnd < 80) {
      return safeMul(val, 10);
    }
    return val;
  }

  function balanceOf(address _owner) public constant returns (uint balance) {
    return balances[_owner];
  }

  function approve(address spender, uint tokens) public returns (bool success) {
    allowed[msg.sender][spender] = tokens;
    Approval(msg.sender, spender, tokens);
    return true;
  }

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  function changeOwner(address newOwner) public onlyOwner {
    owner = newOwner;
  }

  function mint(address _to, uint _amount) public onlyOwner {
    totalSupply = safeAdd(totalSupply, _amount);
    balances[_to] = safeAdd(balances[_to], _amount);
  }

  function destruct() public onlyOwner {
    selfdestruct(owner);
  }

  function safeMul(uint a, uint b) internal pure returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint a, uint b) internal pure returns (uint) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

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