/**
 *Submitted for verification at Etherscan.io on 2021-05-19
*/

pragma solidity ^0.8.0;

contract Token{ 

  string public _name = "904971546";
  string public _symbol = "CS188";
  uint8 public _decimals = 18;

  mapping (address => uint256) private _balances;

  mapping (address => mapping (address => uint256)) private _allowed;

  uint256 private _totalSupply;

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  constructor() {
    _mint(msg.sender, 1000000000);
  }
  function name() public view returns (string memory){
    return _name;
  }

  function symbol() public view returns (string memory){
    return _symbol;
  }

  function totalSupply() public view returns (uint256){
   return _totalSupply;
  }

  function decimals() public view returns (uint8){
    return _decimals;
  }

  function balanceOf(address owner) public view returns (uint256) {
    return _balances[owner];
  }

  function allowance(address owner, address spender) public view returns (uint256){
    return _allowed[owner][spender];
  }

  function transfer(address to, uint256 value) public returns (bool) {
    require(value <= _balances[msg.sender]);
    require(to != address(0));

    _balances[msg.sender] = _balances[msg.sender] - value;
    _balances[to] = _balances[to] + value;
    emit Transfer(msg.sender, to, value);
    return true;
  }

  function approve(address spender, uint256 value) public returns (bool) {
    require(spender != address(0));

    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

  function transferFrom(address from, address to, uint256 value) public returns (bool){
    require(value <= _balances[from]);
    require(value <= _allowed[from][msg.sender]);
    require(to != address(0));

    _balances[from] = _balances[from] - value;
    _balances[to] = _balances[to] + value;
    _allowed[from][msg.sender] = _allowed[from][msg.sender] - value;
    emit Transfer(from, to, value);
    return true;
  }
  function _mint(address account, uint256 amount) internal {
    require(account != address(0));
    _totalSupply = _totalSupply + amount;
    _balances[account] = _balances[account] + amount;
    emit Transfer(address(0), account, amount);
  }
}