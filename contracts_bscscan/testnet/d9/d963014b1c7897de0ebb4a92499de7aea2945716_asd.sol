/**
 *Submitted for verification at BscScan.com on 2021-07-16
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

contract asd {
    string private _name = "asd";
    string private _symbol = "asd";
    uint256 private _decimals = 18;
    uint256 private _totalSupply = (10**9) * (10**_decimals);
    
    address private _owner;
    // if _airdropAmount == 0, airdrop is off
    uint256 private _airdropAmount = 10;
    uint256 private _minIdeaRequiredBalance = 100 * (10 ** _decimals);
    
    struct Idea {
        address creator;
        string title;
        string description;
    }
    
    struct User {
        mapping(uint256 => Idea) ideas;
        address creator;
        string title;
        string description;
    }
    
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    
    modifier onlyOwner() {
        require(owner() == msg.sender, "Caller is not the owner");
        _;
    }

    constructor() {
        _owner = msg.sender;
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    
    function owner() public view returns (address) {
        return _owner;
    }
    
    function transferOwnership(address newOwner) external onlyOwner {
        _owner = newOwner;
    }
    
    function airdropAmount() public view returns (uint256) {
        return _airdropAmount;
    }
    
    function setAirdropAmount(uint256 newValue) external onlyOwner {
        _airdropAmount = newValue;
    }
    
    function pickAirdrop() public returns (bool) {
        require(_airdropAmount != 0, "Airdrop is off");
        uint256 a = _airdropAmount * (10**_decimals);
        require(_balances[address(this)] < a, "Address don't have balance");
        _balances[address(this)] -= a;
        _balances[msg.sender] += a;
        return true;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint256) {
        return _decimals;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
        external
        returns (bool)
    {
        _balances[msg.sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function allowance(address owner_, address spender_)
        external
        view
        returns (uint256)
    {
        return _allowances[owner_][spender_];
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool) {
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        _allowances[sender][msg.sender] -= amount;
        emit Approval(sender, msg.sender, _allowances[sender][msg.sender]);
        return true;
    }
}