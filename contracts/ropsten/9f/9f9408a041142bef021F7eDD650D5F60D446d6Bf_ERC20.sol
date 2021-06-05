// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";

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

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

contract ERC20 is Ownable, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private _globalMintLimit;
    mapping(address => mapping(uint256 => uint256)) private _dailyMintLimit;
    
    uint256 private _totalSupply;
    string private _tokenName = "Marcoin";
    string private _tokenSymbol = "MRCN";
    uint8 private _decimals = 5;
    uint256 public dailyLimit = 10000000000;
    uint256 public globalLimit = 1000000000000;
    
    uint256 constant private SECONDS_PER_DAY = 24 * 60 * 60;
    
    function name() public view override returns (string memory) {
        return _tokenName;
    }
    
    function symbol() public view override returns (string memory) {
        return _tokenSymbol;
    }
    
    function decimals() public view override returns (uint8) {
        return _decimals;
    }
    
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }
    
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, msg.sender, currentAllowance - amount);
        }

        return true;
    }
    
    function requestTokens(uint256 amount) public returns (bool) {
        uint256 dayToday = _getDayToday();
        require(_dailyMintLimit[msg.sender][dayToday] + amount <= dailyLimit, "Mint: Exceeding daily mint limit");
        require(_globalMintLimit[msg.sender] <= globalLimit, "Mint: Exceeding global mint limit");
        _dailyMintLimit[msg.sender][dayToday] += amount;
        _globalMintLimit[msg.sender] += amount;
        _mint(msg.sender, amount);
        return true;
    }
    
    function dailyWithdrawable() public view returns (uint256) {
        uint256 dayToday = _getDayToday();
        return dailyLimit - _dailyMintLimit[msg.sender][dayToday];
    }
    
    function setDailyLimit(uint256 newLimit) public onlyOwner returns (bool) {
        dailyLimit = newLimit;
        return true;
    }
    
    function setGlobalLimit(uint256 newLimit) public onlyOwner returns (bool) {
        globalLimit = newLimit;
        return true;
    }
    
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
    
    function _getDayToday() internal view returns (uint256) {
        return block.timestamp / SECONDS_PER_DAY;
    }
}