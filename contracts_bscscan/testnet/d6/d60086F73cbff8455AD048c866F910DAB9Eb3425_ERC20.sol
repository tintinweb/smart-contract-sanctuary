/**
 *Submitted for verification at BscScan.com on 2021-12-24
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

//import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
//import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
//import "@openzeppelin/contracts/utils/Context.sol";

interface IERC20 {
    
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);

    event Approval(address indexed owner, address indexed spender, uint value);
}


interface IERC20Metadata is IERC20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    
    mapping(address => uint) private _balances;
    mapping(address => mapping(address => uint)) private _allowances;
    uint private _totalSupply;
    string private _name;
    string private _symbol; 
    
    constructor(string memory name_, string memory symbol_){
        _name = name_;
        _symbol = symbol_;
        _totalSupply = 1000000000000000000000000000;
        _balances[_msgSender()] += _totalSupply;
    }
    
    function name() public view virtual override returns(string memory){
        return _name;
    }
    
    function symbol() public view virtual override returns(string memory){
        return _symbol;
    }
    
    function decimals() public view virtual override returns(uint){
        return 18;
    }
    
    function totalSupply() public view virtual override returns(uint){
        return _totalSupply;
    }
    
    function balanceOf(address account) public view virtual override returns(uint){
        return _balances[account];
    }
    
    function transfer(address recipient, uint amount) public virtual override returns(bool){
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    
    function allowance(address owner, address spender) public view virtual override returns(uint){
        return _allowances[owner][spender];
    }
    
    function approve(address spender, uint amount) public virtual override returns(bool){
        _approve(_msgSender(), spender, amount);
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint amount) public virtual override returns(bool){
        _transfer(sender, recipient, amount);
        uint currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: tranfer amount exceeds allowance INR");
        unchecked{
            _approve(sender, _msgSender(), currentAllowance);
        }
        return true;
    }
    
    function increaseAllowance(address spender, uint addedvalue) public virtual returns(bool){
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedvalue);
        return true;
    }
    
    function decreaseAllowance(address spender, uint subtractedvalue) public virtual returns(bool){
        uint currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedvalue, "ERC20: decreased allowance below zero");
        unchecked{
            _approve(_msgSender(), spender, currentAllowance - subtractedvalue);
        }
        return true;
    }
    
    function _transfer(address sender, address recipient, uint amount) internal virtual{
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer from the zero address");
        
        _beforeTokenTransfer(sender, recipient, amount);
        
        uint senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance INR");
        unchecked{
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;
        
        emit Transfer(sender, recipient, amount);
        _afterTokenTransfer(sender, recipient, amount);
    }
    
    function _approve(address owner, address spender, uint amount) internal virtual{
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    function _beforeTokenTransfer(address from, address to, uint amount) internal virtual{}
    function _afterTokenTransfer(address from, address to, uint amount) internal virtual{}
}