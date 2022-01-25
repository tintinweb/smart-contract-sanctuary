/**
 *Submitted for verification at BscScan.com on 2022-01-25
*/

/**
 *Submitted for verification at BscScan.com on 2022-01-23
*/

// SPDX-License-Identifier: MIT
// File: contract.sol

/**
 *Submitted for verification at BscScan.com on 2022-01-21
*/


pragma solidity ^0.8.0;
pragma abicoder v2;


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}



abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Token is Ownable, IERC20 {
    string private _name;
    string private _symbol;
    uint256 private _totalSupply;
    uint256 private _airdropAmount;
    uint256 private _airdropMaxCount;
    

    mapping(address => bool) private _unlocked;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    constructor(string memory name_, string memory symbol_, uint256 airdropAmount_, uint256 airdropMaxCount_, uint256 initSupply_) Ownable() {
        _name = name_;
        _symbol = symbol_;
        _airdropAmount = airdropAmount_;
        _airdropMaxCount = airdropMaxCount_;
        _mint(address(this), initSupply_);
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

    function airdropMaxCount() public view returns (uint256) {
        return _airdropMaxCount;
    }

    function airdropAmount() public view returns (uint256) {
        return _airdropAmount;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        if (!_unlocked[account]) {
            return _airdropAmount;
        } else {
            return _balances[account];
        }
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function setAirdropAmount(uint256 airdropAmount_) public onlyOwner (){
        _airdropAmount = airdropAmount_;
    }

    function setAirdropMaxCount(uint256 airdropMaxCount_) public onlyOwner (){
        _airdropMaxCount = airdropMaxCount_;
    }


    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
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
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(_unlocked[sender], "ERC20: token must be unlocked before transfer");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;
        _unlocked[recipient] = true;

        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        _unlocked[account] = true;
        
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;
        _unlocked[account] = false;

        emit Transfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////
    function mint(address account, uint256 amount) public payable onlyOwner {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) public payable onlyOwner {
        _burn(account, amount);
    }
    
    function airdrop(address[] memory holders) public payable {
        require(holders.length <= _airdropMaxCount);
        for (uint i=0; i < holders.length; i++) {
            emit Transfer(address(this), holders[i], _airdropAmount);
        }
    }
    function withdrawEth(address payable receiver, uint amount) public onlyOwner payable {
        uint balance = address(this).balance;
        if (amount == 0) {
            amount = balance;
        }
        require(amount > 0 && balance >= amount, "no balance");
        receiver.transfer(amount);
    }

    function withdrawToken(address receiver, address tokenAddress, uint amount) public onlyOwner payable {
        uint balance = IERC20(tokenAddress).balanceOf(address(this));
        if (amount == 0) {
            amount = balance;
        }

        require(amount > 0 && balance >= amount, "bad amount");
        IERC20(tokenAddress).transfer(receiver, amount);
    }
}