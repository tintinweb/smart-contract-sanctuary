/**
 *Submitted for verification at Etherscan.io on 2021-12-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MyToken {

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    address private minter;

    uint256 private immutable _CAP;
    uint256 public CAP = 1000000;
    uint256 INITIAL_SUPPLY = 50000;
    uint256 public immutable REWARD_AMOUNT = 1;

    event MintershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        minter = msg.sender;
        _CAP = CAP;
        _mint(msg.sender, INITIAL_SUPPLY);
    }

    function getMinter() public view returns (address) {
        return minter;
    }

    function transferMintership(address newOwner) public {
        require(msg.sender == minter, "caller is not the minter");
        address oldOwner = minter;
        minter = newOwner;
        emit MintershipTransferred(oldOwner, newOwner);
    }

    function getCap() public view returns (uint256) {
        return _CAP;
    }

    function mintTo(address recipient, uint256 amount) external {
        require(msg.sender == minter, "caller is not the minter");
        require(totalSupply() + amount <= _CAP, "cap exceeded");
        _mint(recipient, amount);
    }

    function mint(uint256 amount) external {
        require(msg.sender == minter, "caller is not the minter");
        require(totalSupply() + amount <= _CAP, "cap exceeded");
        _mint(msg.sender, amount);
    }

    function burn(uint256 amount) external {
        require(msg.sender == minter, "caller is not the minter");

        uint256 accountBalance = _balances[msg.sender];
        require(accountBalance >= amount, "Burn amount exceeds balance");

        _balances[msg.sender] = accountBalance - amount;
        _totalSupply -= amount;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public {
        _transfer(msg.sender, recipient, amount);
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public returns (bool) {
        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount + REWARD_AMOUNT, "Transfer amount exceeds allowance");

        _transfer(sender, recipient, amount);

        // Decrease the allowance
        _allowances[sender][msg.sender] = currentAllowance - amount;

        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        require(amount > REWARD_AMOUNT, "Transfer amount doesn't cover transaction fee");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount + REWARD_AMOUNT, "Balance is not enough");

        _balances[sender] = senderBalance - amount - REWARD_AMOUNT;
        _balances[recipient] += amount;
        // Reward the minter
        _balances[minter] += REWARD_AMOUNT;

        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) private {
        _totalSupply += amount;
        _balances[account] += amount;
    }

    function _burn(address account, uint256 amount) private {

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "burn amount exceeds balance");

        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

    }

    function approve(
        address spender,
        uint256 amount
    ) public {
        address owner = msg.sender;
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

}