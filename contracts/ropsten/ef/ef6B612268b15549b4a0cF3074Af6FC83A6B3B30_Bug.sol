/**
 *Submitted for verification at Etherscan.io on 2021-10-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Artiox{
    mapping(address => uint256) private _balances;
    string private _name;
    string private _symbol;
    address private _owner;
    uint256 private _totalSupply;
    uint256 private _lockedSupply;
    uint256 private _releaseTime;

    constructor(string memory name_, string memory symbol_, uint256 totalSupply_, uint256 lockedSupply_, uint256 releaseTime_) {
        _name = name_;
        _symbol = symbol_;
        _owner = msg.sender;
        require(lockedSupply_ <= totalSupply_, "Locked supply can't be greater than total supply");
        _lockedSupply = lockedSupply_ * 10 ** decimals();
        _mint(msg.sender, totalSupply_ * 10 ** decimals());
        require(releaseTime_ >= block.timestamp, "New release time is before current time");
        _releaseTime = releaseTime_;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return 2;
    }
    
    function owner() public view returns (address) {
        return _owner;
    }
    
    function lockedSupply() public view returns (uint256) {
        return _lockedSupply;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    
    function releaseTime() public view returns (uint256) {
        return _releaseTime;
    }
    
    function setReleaseTime(uint256 releaseTime_) public returns (bool) {
        require(msg.sender == owner(), "Only contract owner can set release time");
        require(block.timestamp >= releaseTime(), "Current time is before release time");
        require(releaseTime_ >= block.timestamp, "New release time is before current time");
        _releaseTime = releaseTime_;
        return true;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
    
    function lock(uint256 amount) public returns (bool) {
        require(msg.sender == owner(), "Only contract owner can lock tokens");
        require(balanceOf(msg.sender) - lockedSupply() >= amount, "Lock amount exceeds balance");
        _lockedSupply += amount;
        return true;
    }
    
    function release(uint256 amount) public returns (bool) {
        require(msg.sender == owner(), "Only contract owner can release tokens");
        require(block.timestamp >= releaseTime(), "Current time is before release time");
        require(lockedSupply() >= amount, "Release amount exceeds locked balance");
        _lockedSupply -= amount;
        return true;
    }


    function transfer(address recipient, uint256 amount) public returns (bool) {
        if (msg.sender == owner()){
            require(balanceOf(msg.sender) - lockedSupply() >= amount, "Can't transfer locked tokes");
            _transfer(msg.sender, recipient, amount);
        }
        else{
            _transfer(msg.sender, recipient, amount);
        }
        return true;
    }
    
    function burn(uint256 amount) public {
        if (msg.sender == owner()){
            require(balanceOf(msg.sender) - lockedSupply() >= amount, "Can't burn locked tokes");
            _burn(msg.sender, amount);
        }
        else{
            _burn(msg.sender, amount);
        }
    }
    
    event Transfer(address indexed from, address indexed to, uint256 value);

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "Transfer from the zero address");
        require(recipient != address(0), "Transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "Transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "Mint to the zero address");
        
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }


    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "Burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "Burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }
}

contract Bug is Artiox{
    constructor() Artiox("Bocek, Inan Ergin", "BUG", 150000, 0, block.timestamp + 1 days) {}
}