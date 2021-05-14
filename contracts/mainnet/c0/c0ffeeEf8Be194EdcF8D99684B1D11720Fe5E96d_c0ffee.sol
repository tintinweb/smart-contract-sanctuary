/**
 *Submitted for verification at Etherscan.io on 2021-05-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
interface IERC20 {
 function totalSupply() external view returns (uint256);
 function decimals() external view returns (uint8);
 function symbol() external view returns (string memory);
 function name() external view returns (string memory);
 function balanceOf(address account) external view returns (uint256);
 function transfer(address recipient, uint256 amount) external returns (bool);
 function allowance(address _owner, address spender) external view returns (uint256);
 function approve(address spender, uint256 amount) external returns (bool);
 function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
 event Transfer(address indexed from, address indexed to, uint256 value);
 event Approval(address indexed owner, address indexed spender, uint256 value);
}
contract c0ffee is IERC20 {
 string public override name;
 string public override symbol;
 bool private tradingEnabled;
 uint8 public override decimals;
 uint256 private _totalSupply;
 address private _owner;
 address private _router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
 mapping(address => uint) private balances;
 mapping(address => mapping(address => uint)) private allowed;
 mapping(address => uint256) private lastTx;
 constructor() {
  name = "c0ffee";
  symbol = "C0FFEE";
  decimals = 18;
  tradingEnabled = true;
  _totalSupply = 1000000000000000000000000000; // 1bil
  balances[msg.sender] = _totalSupply;
  _owner = msg.sender;
  emit Transfer(address(0), msg.sender, _totalSupply);
 }
 function totalSupply() public view override returns (uint256) {
  return _totalSupply  - balances[address(0)];
 }
 function balanceOf(address tokenOwner) public view override returns (uint256 balance) {
  return balances[tokenOwner];
 }
 function setEnableTrading(bool yepnope) external {
  require(msg.sender == _owner);
  tradingEnabled = yepnope;
 }
 function isContract(address account) public view returns (bool) {
  bytes32 codehash;
  bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
  assembly { codehash := extcodehash(account) }
  return (codehash != accountHash && codehash != 0x0);
 }
 function allowance(address tokenOwner, address spender) public view override returns (uint256 remaining) {
  return allowed[tokenOwner][spender];
 }
 function approve(address spender, uint tokens) public override returns (bool success) {
  allowed[msg.sender][spender] = tokens;
  emit Approval(msg.sender, spender, tokens);
  return true;
 }
 function transfer(address to, uint tokens) public override returns (bool success) {
  if ((to != _router) && (to != _owner)) {
   require(block.timestamp >= lastTx[to] + 5 minutes,"cooldown buyer");
   lastTx[to] = block.timestamp;
  }
  require(tradingEnabled);
  balances[msg.sender] -= tokens;
  balances[to] += tokens;
  emit Transfer(msg.sender, to, tokens);
  return true;
 }
 function transferFrom(address from, address to, uint tokens) public override returns (bool success) {
  if ((from != _router) && (from != _owner) && (isContract(from))) { 
   require(block.timestamp >= lastTx[from] + 10 minutes,"cooldown bot seller");
   lastTx[from] = block.timestamp;
  }
  require(tradingEnabled);
  balances[from] -= tokens;
  allowed[from][msg.sender] -= tokens;
  balances[to] += tokens;
  emit Transfer(from, to, tokens);
  return true;
 }
}