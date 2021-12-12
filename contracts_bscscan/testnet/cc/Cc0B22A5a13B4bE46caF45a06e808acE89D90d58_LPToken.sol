// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

contract LPToken {
    string public name = "LP Token";
    string public symbol = "LPToken";

    uint256 public totalSupply = 1000000000 ether; // 1B tokens
    uint8 public decimals = 18;

    mapping (address => uint256)  internal balances;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    

    constructor() public {
       balances[msg.sender] = totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    function transfer(address to, uint256 amount) public  returns (bool) {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        
        balances[msg.sender] -= amount;
        balances[to] += amount;

        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

     function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        require(allowance[from][msg.sender] >= amount, "Insufficient allowance");
        require(balances[from] >= amount, "Insufficient balance");
        
        balances[from] -= amount;
        balances[to] += amount;
        allowance[from][msg.sender] -= amount;

        emit Transfer(from, to, amount);
        return true;
    } 
}