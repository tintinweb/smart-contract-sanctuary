/**
 *Submitted for verification at BscScan.com on 2021-10-19
*/

/**
 * Interbits Network
 * Welcome to the universal currency of the people, created by the people, to empower the people.
 * Created to be used in everyday transactions, without paying absurd transactions fees.
 * The power of the sun and wind are the only sources of energy used to run our worldwide network.
 * 
 * Made in The European Union.
 * Our headquarters are located in Stockholm Sweden, but we also have offices in Sydney Australia and and New York USA.
 * Official website: www.interbits.io
 * Telegram: Interbits
 * Reddit: Interbits
 * Created by early Bitcoin investors, Wall Street traders and some anonymous rich people.
 * Deceloped by GitHub engineers and blockchain experts from around the world..
 * We may not be the first, but we are the real deal.
 */
 // SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
abstract contract Unique {
function _msgSender() internal view virtual returns (address) {
return msg.sender;
}
function _msgData() internal view virtual returns (bytes calldata) {
return msg.data;
}
}
abstract contract Decentralized is Unique {
address private _owner;
event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
constructor() {
_setOwner(_msgSender());
}
function owner() public view virtual returns (address) {
return _owner;
}
modifier onlyOwner() {
require(owner() == _msgSender(), "Decentralised: caller is not the owner");
_;
}
function renounceOwnership() public virtual onlyOwner {
_setOwner(address(0));
}
function transferOwnership(address newOwner) public virtual onlyOwner {
require(newOwner != address(0), "Decentralized: new owner is the zero address");
_setOwner(newOwner);
}
function _setOwner(address newOwner) private {
address oldOwner = _owner;
_owner = newOwner;
emit OwnershipTransferred(oldOwner, newOwner);
}
}
interface Reliable {
function totalSupply() external view returns (uint256);
function balanceOf(address account) external view returns (uint256);
function transfer(address recipient, uint256 amount) external returns (bool);
function allowance(address owner, address spender) external view returns (uint256);
function approve(address spender, uint256 amount) external returns (bool);
function transferFrom(
address sender,
address recipient,
uint256 amount
) external returns (bool);
event Transfer(address indexed from, address indexed to, uint256 value);
event Approval(address indexed owner, address indexed spender, uint256 value);
}
interface Freedom is Reliable {
function name() external view returns (string memory);
function symbol() external view returns (string memory);
function decimals() external view returns (uint8);
}
contract Secure is Unique, Reliable, Freedom {
mapping(address => uint256) private _balances;
mapping(address => mapping(address => uint256)) private _allowances;
uint256 private _totalSupply;
string private _name;
string private _symbol;
constructor(string memory name_, string memory symbol_) {
_name = name_;
_symbol = symbol_;
}
function name() public view virtual override returns (string memory) {
return _name;
}
function symbol() public view virtual override returns (string memory) {
return _symbol;
}
function decimals() public view virtual override returns (uint8) {
return 18;
}
function totalSupply() public view virtual override returns (uint256) {
return _totalSupply;
}
function balanceOf(address account) public view virtual override returns (uint256) {
return _balances[account];
}
function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
_transfer(_msgSender(), recipient, amount);
return true;
}
function allowance(address owner, address spender) public view virtual override returns (uint256) {
return _allowances[owner][spender];
}
function approve(address spender, uint256 amount) public virtual override returns (bool) {
_approve(_msgSender(), spender, amount);
return true;
}
function transferFrom(
address sender,
address recipient,
uint256 amount
) public virtual override returns (bool) {
_transfer(sender, recipient, amount);
uint256 currentAllowance = _allowances[sender][_msgSender()];
require(currentAllowance >= amount, "Secure: transfer amount exceeds allowance");
unchecked {
_approve(sender, _msgSender(), currentAllowance - amount);
}
return true;
}
function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
_approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
return true;
}
function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
uint256 currentAllowance = _allowances[_msgSender()][spender];
require(currentAllowance >= subtractedValue, "Secure: decreased allowance below zero");
unchecked {
_approve(_msgSender(), spender, currentAllowance - subtractedValue);
}
return true;
}
function _transfer(
address sender,
address recipient,
uint256 amount
) internal virtual {
require(sender != address(0), "Secure: transfer from the zero address");
require(recipient != address(0), "Secure: transfer to the zero address");
_beforeTokenTransfer(sender, recipient, amount);
uint256 senderBalance = _balances[sender];
require(senderBalance >= amount, "Secure: transfer amount exceeds balance");
unchecked {
_balances[sender] = senderBalance - amount;
}
_balances[recipient] += amount;
emit Transfer(sender, recipient, amount);

_afterTokenTransfer(sender, recipient, amount);
}
function _mint(address account, uint256 amount) internal virtual {
require(account != address(0), "Secure: mint to the zero address");
_beforeTokenTransfer(address(0), account, amount);
_totalSupply += amount;
_balances[account] += amount;
emit Transfer(address(0), account, amount);
_afterTokenTransfer(address(0), account, amount);
}
function _burn(address account, uint256 amount) internal virtual {
require(account != address(0), "Secure: burn from the zero address");
_beforeTokenTransfer(account, address(0), amount);
uint256 accountBalance = _balances[account];
require(accountBalance >= amount, "Secure: burn amount exceeds balance");
unchecked {
_balances[account] = accountBalance - amount;
}
_totalSupply -= amount;
emit Transfer(account, address(0), amount);
_afterTokenTransfer(account, address(0), amount);
}
function _approve(
address owner,
address spender,
uint256 amount
) internal virtual {
require(owner != address(0), "Secure: approve from the zero address");
require(spender != address(0), "Secure: approve to the zero address");
_allowances[owner][spender] = amount;
emit Approval(owner, spender, amount);
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
abstract contract Powerful is Unique, Secure {
function burn(uint256 amount) public virtual {
_burn(_msgSender(), amount);
}
function burnFrom(address account, uint256 amount) public virtual {
uint256 currentAllowance = allowance(account, _msgSender());
require(currentAllowance >= amount, "Secure: burn amount exceeds allowance");
unchecked {
_approve(account, _msgSender(), currentAllowance - amount);
}
_burn(account, amount);
}
}
contract Interbits is Secure, Powerful, Decentralized {
constructor() Secure("Interbits", "BIT") {
_mint(msg.sender, 100000000 * 10 ** decimals());
}
function mint(address to, uint256 amount) public onlyOwner {
_mint(to, amount);
}}