/**
 *Submitted for verification at BscScan.com on 2021-11-13
*/

//SPDX-License-Identifier: UNLICENSED

/*

129 Orbital Flights

*/

pragma solidity ^0.8.6;


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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}

contract ERC20 is Context, IERC20 {
    address private _owner;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    address private _devWallet;
    
    uint8 private _devFeePercentage;
    uint8 private _burnFeePercentage;

    constructor () {
        _name = "129 Orbital Flights";
        _symbol = "129 Orbital Flights";
        _decimals = 18;
        _devWallet = 0x2E61af7E4FFec86De4e655850d6f74E7b85310d4;
        _mint(msg.sender, 1000000000 * (10 ** 18));
        
        _devFeePercentage = 5;
        _burnFeePercentage = 1;
        
        _owner = msg.sender;
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }
    
    function devWallet() public view returns (address) {
        return _devWallet;
    }
    
    function fee() public view returns(uint256, uint256) {
        return(_devFeePercentage, _burnFeePercentage);
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
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount * (100 - (_devFeePercentage + _burnFeePercentage)) / 100;
        _balances[_devWallet] += amount * (100 - (_devFeePercentage)) / 100;
        _burn(msg.sender, amount * (100 - (100 - _burnFeePercentage)) / 100);

        emit Transfer(sender, recipient, (amount * (100 - (_devFeePercentage + _burnFeePercentage)) / 100));
        emit Transfer(sender, _devWallet, (amount * (100 - (_devFeePercentage)) / 100));
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
    
    //////////////////
    // Owner functions
    
    function setOwner(address _account) external {
        require(msg.sender == _owner);
        
        _owner = _account;
    }
    
    function setDevFeePercentage(uint8 _devFee) external {
        require(msg.sender == _owner);
        
        _devFeePercentage = _devFee;
        
    }
    
    function setBurnFeePercentage(uint8 _burnFee) external {
        require(msg.sender == _owner);
        
        _burnFeePercentage = _burnFee;
        
    }
    
    function setDevWallet(address _account) external {
        require(msg.sender == _owner);
        
        _devWallet = _account;
    }
}