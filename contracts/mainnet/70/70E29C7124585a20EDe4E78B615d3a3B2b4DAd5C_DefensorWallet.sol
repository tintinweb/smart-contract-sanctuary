pragma solidity ^0.4.18;

contract Owner {
    address public owner;
    modifier onlyOwner { 
      require(msg.sender == owner);
     _;
    }
    function Owner() public { owner = msg.sender; }
}

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract DefensorWallet is ERC20, Owner {

  string public name;
  string public symbol;
  uint8 public decimals;
  mapping(address => uint256) balances;
  mapping (address => mapping (address => uint256)) allowed;

  struct FrozenToken {
    bool isFrozenAll;
    uint256 amount;
    uint256 unfrozenDate;
  }
  mapping(address => FrozenToken) frozenTokens;

  event FrozenAccount(address target,bool freeze);
  event FrozenAccountToken(address target,uint256 amount,uint256 unforzenDate);

  function DefensorWallet(uint256 initialSupply,string tokenName,string tokenSymbol,uint8 decimalUnits) public {
    balances[msg.sender] = initialSupply;
    totalSupply = initialSupply;
    name = tokenName;
    decimals = decimalUnits;
    symbol = tokenSymbol;
  }

  function changeOwner(address newOwner) onlyOwner public {
    owner = newOwner;
  }

  function freezeAccount(address target,bool freeze) onlyOwner public {
      frozenTokens[target].isFrozenAll = freeze;
      FrozenAccount(target, freeze);
  }

  function isAccountFreeze(address target) public constant returns (bool) {
    return frozenTokens[target].isFrozenAll;
  }

  function freezeAccountToken(address target,uint256 amount,uint256 date)  onlyOwner public {
      require(amount > 0);
      require(date > now);
      frozenTokens[target].amount = amount;
      frozenTokens[target].unfrozenDate = date;

      FrozenAccountToken(target,amount,date);
  }

  function freezeAccountOf(address target) public view returns (uint256,uint256) {
    return (frozenTokens[target].unfrozenDate,frozenTokens[target].amount);
  }

  function transfer(address to,uint256 value) public returns (bool) {
    require(msg.sender != to);
    require(value > 0);
    require(balances[msg.sender] >= value);
    require(frozenTokens[msg.sender].isFrozenAll != true);

    if (frozenTokens[msg.sender].unfrozenDate > now) {
        require(balances[msg.sender] - value >= frozenTokens[msg.sender].amount);
    }

    balances[msg.sender] -= value;
    balances[to] += value;
    Transfer(msg.sender,to,value);

    return true;
  }

  function balanceOf(address addr) public constant returns (uint256) {
    return balances[addr];
  }

  function allowance(address owner, address spender) public constant returns (uint256) {
    return allowed[owner][spender];
  }

  function transferFrom(address from, address to, uint256 value) public returns (bool) {
    require (balances[from] >= value);
    var _allowance = allowed[from][msg.sender];
    require (_allowance >= value);
    
    balances[to] += value;
    balances[from] -= value;
    allowed[from][msg.sender] -= value;
    Transfer(from, to, value);
    return true;
  }

  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function kill() onlyOwner public {
    selfdestruct(owner);
  }
}