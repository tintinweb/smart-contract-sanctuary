/**
 *Submitted for verification at BscScan.com on 2021-12-09
*/

//@Author/dev Riccis Cabañeles / RVC Blockchain Technology
//CRYSTAMON Token is compiled for CRYSTAMON NFT & P2E Project
//Mint function are omitted for transparency purpose
//SPDX-License-Identifier: Unlicensed
pragma solidity 0.5.16 ;
interface ICRYSTALMONSTER20 {
  function totalSupply() external view returns (uint256);
  function decimals() external view returns (uint8);
  function symbol() external view returns (string memory);
  function name() external view returns (string memory);
  function getOwner() external view returns (address);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address _owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);}
contract Crystalmonstertext {
  constructor () internal { }
  function _msgSender() internal view returns (address payable) {return msg.sender;}
  function _msgData() internal view returns (bytes memory) {this;return msg.data;}}
library SafeLogic {
  function add(uint256 a, uint256 b) internal pure returns (uint256) {uint256 c = a + b;require(c >= a, "SafeLogic: addition overflow");return c;}
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {return sub(a, b, "SafeLogic: subtraction overflow");}
  function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {require(b <= a, errorMessage);uint256 c = a - b;return c;}
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {if (a == 0) {return 0;}uint256 c = a * b;require(c / a == b, "SafeLogic: multiplication overflow");return c;}
  function div(uint256 a, uint256 b) internal pure returns (uint256) {return div(a, b, "SafeLogic: division by zero");}
  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {require(b > 0, errorMessage);uint256 c = a / b;return c;}
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {return mod(a, b, "SafeLogic: modulo by zero");}
  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {require(b != 0, errorMessage);return a % b;}}

contract CrsytalmonsterTransferable is Crystalmonstertext {
  address private _owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  constructor () internal {
    address msgSender = _msgSender();_owner = msgSender;emit OwnershipTransferred(address(0), msgSender);}
  function owner() public view returns (address) {return _owner;}
  modifier onlyOwner() {require(_owner == _msgSender(), " CrsytalmonsterTransferable: caller is not the owner");_;}
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);}
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0), " CrsytalmonsterTransferable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;}
}
contract CRYSTALMONSTER is Crystalmonstertext, ICRYSTALMONSTER20,  CrsytalmonsterTransferable {
  using SafeLogic for uint256;
  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowances;
  string private _name = "CRYSTAL MONSTER Token";
  string private _symbol = "CRYSTAMON";
  uint8 private _decimals = 18;
  uint256 private _totalSupply = 100000000 * 10**18;
  constructor() public {
    _balances[msg.sender] = _totalSupply;
    emit Transfer(address(0), msg.sender, _totalSupply);}
  function getOwner() external view returns (address) {return owner();}
  function decimals() external view returns (uint8) {return _decimals;}
  function symbol() external view returns (string memory) {return _symbol;}
  function name() external view returns (string memory) {return _name;}
  function totalSupply() external view returns (uint256) {return _totalSupply;}
  function balanceOf(address account) external view returns (uint256) {return _balances[account];}
  function transfer(address recipient, uint256 amount) external returns (bool) {_transfer(_msgSender(), recipient, amount);return true;}
  function allowance(address owner, address spender) external view returns (uint256) {return _allowances[owner][spender];}
  function approve(address spender, uint256 amount) external returns (bool) {_approve(_msgSender(), spender, amount);return true;}
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
    _transfer(sender, recipient, amount);_approve(sender, _msgSender(), _allowances[sender]
    [_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));return true;}
  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));return true;}
  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));return true;}
  function burn(uint256 amount) public returns (bool) {_burn(_msgSender(), amount);return true;}
  function _transfer(address sender, address recipient, uint256 amount) internal {
    require(sender != address(0), "BEP20: transfer from the zero address");
    require(recipient != address(0), "BEP20: transfer to the zero address");
    _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");
    _balances[recipient] = _balances[recipient].add(amount);
    emit Transfer(sender, recipient, amount);}
  function _burn(address account, uint256 amount) internal {
    require(account != address(0), "BEP20: burn from the zero address");
    _balances[account] = _balances[account].sub(amount, "BEP20: burn amount exceeds balance");
    _totalSupply = _totalSupply.sub(amount);
    emit Transfer(account, address(0), amount);}
  function _approve(address owner, address spender, uint256 amount) internal {
    require(owner != address(0), "BEP20: approve from the zero address");
    require(spender != address(0), "BEP20: approve to the zero address");
    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);}
  function _burnFrom(address account, uint256 amount) internal {_burn(account, amount);
    _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "BEP20: burn amount exceeds allowance"));}
}