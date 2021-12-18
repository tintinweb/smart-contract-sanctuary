/**
 *Submitted for verification at Etherscan.io on 2021-12-18
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Token{
function _msgSender() internal view virtual returns (address) {
return msg.sender;
}

function _msgData() internal view virtual returns (bytes calldata) {
return msg.data;
}
event Transfer(address indexed from, address indexed to, uint tokens);
event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract TestToken is Token{
string _name;
string _symbol;

uint256 _totalSupply;

mapping(address => uint) balance;
mapping(address => mapping(address => uint)) allowed;

constructor () {
_name = 'KotiaBSC';
_symbol = 'KOT';
}

function name() public view virtual returns (string memory){
return _name;
}
function symbol() public view virtual returns (string memory){
return _symbol;
}
function decimals() public view virtual returns (uint8) {
return 18;
}
function totalSupply() public view virtual returns (uint256){
return _totalSupply;
}
function balanceOf(address account) public view returns (uint256 value){
return balance[account];
}
function tranfer(address recipient, uint256 amount) public virtual returns (bool){
_transfer(_msgSender(), recipient, amount);
return true;
}
function _transfer(address sender, address recipient, uint256 amount) internal virtual{
require(sender != address(0), 'Address cannot be zero');
require(recipient != address(0), 'Address cannot be zero');
_beforeTokenTransfer(sender, recipient, amount);
uint256 senderBalance = balance[sender];
require(senderBalance >= amount, 'Balance Limit Reached');
unchecked{
balance[sender] = senderBalance - amount;
}
balance[recipient] += amount;
emit Transfer(sender, recipient, amount);
_afterTokenTransfer(sender, recipient, amount);
}
function mint(address receiver, uint amount) public {
require(receiver != address (0), 'Address cannot be zero!!!');
_beforeTokenTransfer(address(0), receiver, amount);
balance[receiver] += amount;
_totalSupply += amount;
emit Transfer(address(0), receiver, amount);
_afterTokenTransfer(address(0), receiver, amount);
}
function burn(address account, uint256 amount) public {
require(account != address(0), 'Address cannot be zero');
_beforeTokenTransfer(account, address(0), amount);
uint256 accountBalance = balance[account];
require(accountBalance >= amount, 'Balance Limit Reached');
unchecked{
balance[account] = accountBalance - amount;
}
_totalSupply -= amount;
emit Transfer(account, address(0), amount);
_afterTokenTransfer(account, address(0), amount);

}
function _beforeTokenTransfer(
address from,
address to,
uint256 amount
) internal virtual {}

function _afterTokenTransfer(
address from,
address to,
uint256 amount
) internal virtual {}
}