/**
 *Submitted for verification at Etherscan.io on 2021-05-20
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address tokenOwner) external view returns (uint256 balance);
    function allowance(address tokenOwner, address spender) external  view returns (uint remaining);
    function transfer(address to, uint256 amount) external  returns (bool success);
    function approve(address spender, uint256 amount) external  returns (bool success);
    function transferFrom(address from, address to, uint256 amount) external  returns (bool success);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 value);
}

contract OxCoinToken3 is IERC20 {
    
    address public owner;
    string public name;
    string public symbol;
    uint8 public decimals; // 8 decimals is the strongly suggested default, avoid changing it

    uint256 public _totalSupply;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor(address _owner) {
        name = "OxCoin Token3";
        symbol = "OXCT3";
        decimals = 8;
        _totalSupply = 10 ** 10 * 10 ** 8;
        owner = _owner;
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    
    function getOwner() public view returns (address) {
        return owner;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }
    
    function increaseSupply(uint256 amount) public returns (bool) {
        require(msg.sender == getOwner(), "ERC20: increaseSupply only owner");
        _totalSupply = _totalSupply + amount;
        balances[msg.sender] = balances[msg.sender] + amount;
        emit Transfer(address(0), msg.sender, amount);
        return true;
    }
    
    function transferOwnership(address newOwner) public returns (bool) {
        require(msg.sender == getOwner(), "ERC20: transferOwnership only owner");
        require(newOwner != getOwner(), "ERC20: transferOwnership owner address invalid");
        owner = newOwner;
        return true;
    }

    function balanceOf(address tokenOwner) public view override returns (uint256) {
        return balances[tokenOwner];
    }

    function allowance(address tokenOwner, address spender) public view override returns (uint256) {
        return allowed[tokenOwner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        allowed[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        require(balances[msg.sender] >= amount, "ERC20: transfer amount exceeds balance");
        balances[msg.sender] = balances[msg.sender] - amount;
        balances[to] = balances[to] + amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        require(balances[from] >= amount, "ERC20: transfer amount exceeds balance");
        balances[from] = balances[from] - amount;
        allowed[from][msg.sender] = allowed[from][msg.sender] - amount;
        balances[to] = balances[to] + amount;
        emit Transfer(from, to, amount);
        return true;
    }
    
}