/**
 *Submitted for verification at BscScan.com on 2021-07-17
*/

// SPDX-License-Identifier: Unlicensed

/**   __
 *  _|__\_  ______
 * | @@@@ \ $$$$$$\             ____________
 * | @@@@ \     $$\            |$$$$$$$$$$$$\
 * | @@@@ \    $$ \            |$$$       $$\
 * | @@@@ \   $$   \______                   ________________________________
 * | @@@@ \  $$    $$$$$$$\    $   $$$$$$   |$$$$$ $$$$$$   $   $$$$$$ $$$$$$\
 * | @@@@ \ $$     $$         $$$  $$$$$$   |$$      $$    $$$    $$   $$    \
 * | @@@@ \  $$$   $$$$$$$|  $$ $$   $$     |$$$$$   $$   $$ $$   $$   $$$$  \
 * | @@@@ \   $$$  $$       $$$$$$$  $$   $$    $$   $$   $$$$$   $$   $$    \
 * | @@@@ \    $$$ $$$$$$$ $$     $$ $$$$$$$ $$$$$   $$  $$   $$  $$   $$$$$$\
 * |______\     $$$$ _____|  $_____________$
 */

pragma solidity ^0.8.6;

abstract contract Context {

    constructor () { }

    function _msgSender() internal view returns (address payable) {
        
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        
        this;
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    constructor () {
        
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        
        return _owner;
    }

    modifier onlyOwner() {
        
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    function isOwner() public view returns (bool) {
        
        return _msgSender() == _owner;
    }

    function renounceOwnership() public onlyOwner {
        
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract ERC20 is Context, IERC20, Ownable {
    
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;
    mapping (address => bool) private _isBlacklisted;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    function totalSupply() public override view returns (uint256) {
        
        return _totalSupply;
    }

    function balanceOf(address account) public override view returns (uint256) {
        
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public override view returns (uint256) {
        
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        
        // Addresses in Blacklist can't do buy or sell.
        require(_isBlacklisted[sender] == false && _isBlacklisted[recipient] == false, "Blacklisted addresses can't do buy or sell");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal {
        
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _burnFrom(address account, uint256 amount) internal {
        
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }
    
    function setAddressAsBlacklisted(address account) public onlyOwner {
        _isBlacklisted[account] = true;
    }

    function setAddressAsWhitelisted(address account) public onlyOwner {
        _isBlacklisted[account] = false;
    }
}

contract REALESTATEToken is ERC20 {
    
    string constant public name = "DEMORE";
    string constant public symbol = "DRE";
    uint8 constant public decimals = 8;
    uint256 constant public initialSupply = 3 * 10**2 * 10**8;
    
    constructor () {
          
        _mint(msg.sender, initialSupply);
    }
}