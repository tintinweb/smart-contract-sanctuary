/**
 *Submitted for verification at Etherscan.io on 2021-08-05
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }
}

contract CToken {
    using SafeMath for uint256;

    string public symbol = "CTT";
    string public name = "C Token (Test)";

    uint256 public decimals = 18;
    uint256 public totalSupply = 1000000000 * 10 ** uint256(decimals); 

    mapping(address => uint256) internal balances;
    mapping(address => mapping(address => uint256)) internal allowed;

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    constructor() public {
        balances[msg.sender] = totalSupply;
    }

    function balanceOf(address owner) external view returns (uint256 balance) {
        return balances[owner];
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        require(amount <= balances[msg.sender], "Balance of SENDER not enough");

        balances[msg.sender] = balances[msg.sender].sub(amount);
        balances[to] = balances[to].add(amount);
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount ) public returns (bool) {
        require(amount <= balances[from], "Balance of FROM not enough");
        require(amount <= allowed[from][msg.sender], "Allowance not enough");

        balances[from] = balances[from].sub(amount);
        balances[to] = balances[to].add(amount);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(amount);
        emit Transfer(from, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        allowed[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return allowed[owner][spender];
    }
}