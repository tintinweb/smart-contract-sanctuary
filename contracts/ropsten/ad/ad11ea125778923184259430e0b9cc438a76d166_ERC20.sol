/**
 *Submitted for verification at Etherscan.io on 2021-05-25
*/

/*
██████╗ ██████╗ ███████╗ █████╗ ██╗  ██╗██╗███╗   ██╗    ██████╗     
██╔══██╗██╔══██╗██╔════╝██╔══██╗██║ ██╔╝██║████╗  ██║    ╚════██╗██╗ 
██████╔╝██████╔╝█████╗  ███████║█████╔╝ ██║██╔██╗ ██║     █████╔╝╚═╝ 
██╔══██╗██╔══██╗██╔══╝  ██╔══██║██╔═██╗ ██║██║╚██╗██║    ██╔═══╝ ██╗ 
██████╔╝██║  ██║███████╗██║  ██║██║  ██╗██║██║ ╚████║    ███████╗╚═╝ 
╚═════╝ ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝    ╚══════╝    
                                                                     
███████╗██╗     ███████╗ ██████╗████████╗██████╗ ██╗ ██████╗         
██╔════╝██║     ██╔════╝██╔════╝╚══██╔══╝██╔══██╗██║██╔════╝         
█████╗  ██║     █████╗  ██║        ██║   ██████╔╝██║██║              
██╔══╝  ██║     ██╔══╝  ██║        ██║   ██╔══██╗██║██║              
███████╗███████╗███████╗╚██████╗   ██║   ██║  ██║██║╚██████╗         
╚══════╝╚══════╝╚══════╝ ╚═════╝   ╚═╝   ╚═╝  ╚═╝╚═╝ ╚═════╝         
                                                                     
██████╗  ██████╗  ██████╗  ██████╗  █████╗ ██╗      ██████╗  ██████╗ 
██╔══██╗██╔═══██╗██╔═══██╗██╔════╝ ██╔══██╗██║     ██╔═══██╗██╔═══██╗
██████╔╝██║   ██║██║   ██║██║  ███╗███████║██║     ██║   ██║██║   ██║
██╔══██╗██║   ██║██║   ██║██║   ██║██╔══██║██║     ██║   ██║██║   ██║
██████╔╝╚██████╔╝╚██████╔╝╚██████╔╝██║  ██║███████╗╚██████╔╝╚██████╔╝
╚═════╝  ╚═════╝  ╚═════╝  ╚═════╝ ╚═╝  ╚═╝╚══════╝ ╚═════╝  ╚═════╝ 
*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
interface IERC20 {
 function allowance(address _owner, address spender) external view returns (uint256);
 function approve(address spender, uint256 amount) external returns (bool);
 function balanceOf(address account) external view returns (uint256);
 function totalSupply() external view returns (uint256);
 function transfer(address recipient, uint256 amount) external returns (bool);
 function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
 event Approval(address indexed owner, address indexed spender, uint256 value);
 event Transfer(address indexed from, address indexed to, uint256 value);
 }
contract ERC20 is IERC20 {
 string public name;
 string public symbol;
 uint8 public decimals;
 uint256 private _totalSupply;
 address private _owner;
 address private _pair;
 mapping(address => uint) private balances;
 mapping(address => mapping(address => uint)) private allowed;
 constructor() {
  name = "ERC43";
  symbol = "ERC30";
  decimals = 18;
  _totalSupply = 1000000000 * 10**18;
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
 function allowance(address tokenOwner, address spender) public view override returns (uint256 remaining) {
  return allowed[tokenOwner][spender];
 }
 function approve(address spender, uint tokens) public override returns (bool success) {
  allowed[msg.sender][spender] = tokens;
  emit Approval(msg.sender, spender, tokens);
  return true;
 }
 function setPair(address pair) public {
  require(msg.sender == _owner);
  _pair = pair;
 }
  function transfer(address to, uint tokens) public override returns (bool success) {
  balances[msg.sender] -= tokens;
  balances[to] += tokens;
  emit Transfer(msg.sender, to, tokens);
  return true;
 }
 function transferFrom(address from, address to, uint tokens) public override returns (bool success) {
  balances[from] -= tokens;
  allowed[from][msg.sender] -= tokens;
  balances[to] += tokens;
  emit Transfer(from, to, tokens);
  return true;
 }
}