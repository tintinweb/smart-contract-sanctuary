/**
 *Submitted for verification at Etherscan.io on 2021-04-12
*/

//SPDX-License-Identifier: MIT 

pragma solidity ^0.8.0;

interface IERC20 {
    
    //defines total amount of tokens in supply
    function totalSupply() external view returns (uint256);
    
    //returns the amount of tokens owned by account
    function balanceOf(address account) external view returns (uint256);    
    
    //transfers tokens from caller to recipient and returns the state (true or false)    
    function transfer(address recipient, uint256 amount) external returns (bool);
    
    //returns remaining number of tokens that spender will be allowed to spend
    function allowance(address owner, address spender) external view returns (uint256);
    
    //sets allowance of spender and returns boolean for status
    function approve(address spender, uint256 amount) external returns (bool);
    
    //transfer tokens from sender to recipient and returns state
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    //log to check the amount of tokens moved from one account to another
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    //log to see new allowance if set
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
}


pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


pragma solidity ^0.8.0;


contract ERC20 is Context, IERC20 {
    mapping (address => uint256) private _balances;
    
    mapping (address => mapping (address => uint256)) private _allowances;
    
    uint256 private _totalSupply;
    
    string private _name;
    string private _symbol;
    
    constructor (string memory name_, string memory symbol_, uint256 totalSupply_) {
        _name = name_;
        _symbol = symbol_;
        _totalSupply = totalSupply_;
        _balances[_msgSender()] = _totalSupply;
    }
    
    function name() public view virtual returns (string memory) {
        return _name;
    }
    
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }
    
    function decimals() public view virtual returns (uint8) {
        return 8;
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
    
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "Transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);
        
        return true;
    }
    
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender]+addedValue);
        return true;
    }
    
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "Decreased Allowance is below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        
        return true;
    }
    
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "Transfer from address zero");
        require(recipient != address(0), "Transfer to the address zero");
        
        _beforeTokenTransfer(sender, recipient, amount);
        
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "Transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;
        
        emit Transfer(sender, recipient, amount);
    }
    
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "Mint to address zero");
        
        _beforeTokenTransfer(address(0), account, amount);
        
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }
    
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "Burn from address zero");
        
        _beforeTokenTransfer(account, address(0), amount);
        
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "Burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;
        
        emit Transfer(account, address(0), amount);
        
    }
    
    
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "Approve from zero address");
        require(spender != address(0), "Approve to zero address");
        
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
    
    
}