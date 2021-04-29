/**
 *Submitted for verification at Etherscan.io on 2021-04-29
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

contract GDT {
    mapping (address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    string public constant name = "GDT";
    string public constant symbol = "GDT";
    uint8 public constant decimals = 8;
    address private immutable initial_address;
    uint256 public totalSupply = 400_000_000 * (uint256(10) ** decimals);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    modifier validAddress(address addr) {
        require(addr != address(0), "Address cannot be 0x0");
        require(addr != address(this), "Address cannot be contract address");
        _;
    }

    constructor(address manager) validAddress(manager) {
        initial_address = manager;
        balanceOf[manager] = totalSupply;
        emit Transfer(address(0), manager, totalSupply);
    }

    function transfer(address to, uint256 value) external validAddress(to) returns (bool success) {
        uint256 senderBalance = balanceOf[msg.sender];
        require(senderBalance >= value, "ERC20: insufficient balance for transfer");
        balanceOf[msg.sender] = senderBalance - value; // deduct from sender's balance
        balanceOf[to] += value; // add to recipient's balance
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value)
        public
        validAddress(spender)
        returns (bool success)
    {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value)
        external
        validAddress(to)
        returns (bool success)
    {
        uint256 balanceFrom = balanceOf[from];
        uint256 allowanceSender = allowance[from][msg.sender];
        require(value <= balanceFrom, "ERC20: insufficient balance for transferFrom");
        require(value <= allowanceSender, "ERC20: unauthorized transferFrom");
        balanceOf[from] = balanceFrom - value;
        balanceOf[to] += value;
        allowance[from][msg.sender] = allowanceSender - value;
        emit Transfer(from, to, value);
        return true;
    }

    function burn(uint256 amount)
        external
        returns (bool success)
    {
        require(msg.sender==initial_address,'ERC20: burn not authorized.');
        uint256 accountBalance = balanceOf[msg.sender];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        balanceOf[msg.sender] = accountBalance - amount;
        totalSupply -= amount;
        emit Transfer(msg.sender, address(0), amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        external
        validAddress(spender)
        returns (bool)
    {
        approve(spender, allowance[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        validAddress(spender)
        returns (bool)
    {
        uint256 currentAllowance = allowance[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        approve(spender, currentAllowance - subtractedValue);
        return true;
    }
}