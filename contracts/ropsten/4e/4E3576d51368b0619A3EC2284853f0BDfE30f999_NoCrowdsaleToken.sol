pragma solidity ^0.4.24;


contract ERC20 {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);

  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);

  event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract NoCrowdsaleToken is ERC20 {
  uint256 _totalSupply = 10 * 1000 * 1000 * 1000;

  function totalSupply() public view returns (uint256)
  {
    return _totalSupply;
  }

  uint8 public decimals = 3;

  // Store these in fixed byte arrays to avoid analyzer warnings
  // TODO: is this compatible?
  bytes17 public name = "Pidor token #1337";
  bytes5 public symbol = "PIDOR";

  address _ownerAddress;

  mapping(address => uint256) _balances;
  // INV_BAL: sum(values of `_balances`) = `_totalSupply`

  constructor() public {
    _ownerAddress = msg.sender;

    _balances[_ownerAddress] = _totalSupply;
  }

  function transfer(address to, uint256 value) public returns (bool)
  {
    // address(0) is the value of uninitialized `address` variable
    require(to != address(0));

    require(value <= _balances[msg.sender]); // A1

    // Overflow safe from A1
    _balances[msg.sender] = _balances[msg.sender] - value;

    // Overflow safe from A1 & INV_BAL
    _balances[to] = _balances[to] + value;
    
    emit Transfer(msg.sender, to, value);

    return true;
  }

  function balanceOf(address holder) public view returns (uint256)
  {
    return _balances[holder];
  }

  mapping (address => mapping (address => uint256)) internal _allowed;
  // INV_ALLOW: max(values of `_allowed`) <= `totalSupply`

  function transferFrom(address from, address to, uint256 value) public returns (bool)
  {
    require(to != address(0));

    require(value <= _balances[from]); // A1
    require(value <= _allowed[from][msg.sender]); // A2

    // Overflow safe from A1
    _balances[from] = _balances[from] - value;

    // Overflow safe from (A1 | A2) & INV_ALLOW
    _balances[to] = _balances[to] + value;

    // Overflow safe from A2
    _allowed[from][msg.sender] = _allowed[from][msg.sender] - value;

    emit Transfer(from, to, value);

    return true;
  }

  function approve(address spender, uint256 value) public returns (bool)
  {
    require(value <= _totalSupply);

    _allowed[msg.sender][spender] = value;

    emit Approval(msg.sender, spender, value);

    return true;
  }

  function allowance(address holder, address spender) public view returns (uint256)
  {
    return _allowed[holder][spender];
  }

  /*
   * TODO: implement dividends
   */
}