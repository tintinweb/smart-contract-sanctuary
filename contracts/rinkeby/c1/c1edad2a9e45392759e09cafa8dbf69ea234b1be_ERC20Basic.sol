/**
 *Submitted for verification at Etherscan.io on 2021-10-01
*/

// 1. Нужен token erc20
// 2. Нужно название Geek brains 2, символ: GBR2
// 3. Количество токено 0 с точностью 6
// 4. Токен может быть в любом количестве напечатан
// 5. Мокен можно сжигать.

// SPDX-License-Id/entifier: MIT
pragma solidity 0.8.8;

interface IERC20 {
    function balanceOf(address account) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed from, address indexed spender, uint value);
}

contract ERC20Basic is IERC20 {
    string public name = "Geekbrains Token";
    string public symbol = "GBR2";
    uint public decimals = 6;

    address public owner;

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
    uint public totalSupply;

    constructor() {
        owner = msg.sender;
    }

    function balanceOf(address account) external view override returns (uint) {
        return balances[account];
    }

    function transfer(address recipient, uint amount) public override returns (bool) {
        require(balances[msg.sender] > amount, "ERC20Basic::transfer: amount is not correct");

        balances[msg.sender] = balances[msg.sender] - amount;
        balances[recipient] = balances[recipient] - amount;

        emit Transfer(msg.sender, recipient, amount);

        return true;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "ERC20Basic::onlyOwner: sender is not owner");
        _;
    }

    function mint(uint amount) external onlyOwner returns (bool) {
        balances[msg.sender] += amount;
        totalSupply += amount;

        return true;
    }

    function burn(uint amount) external onlyOwner returns (bool) {
        balances[msg.sender] -= amount;
        totalSupply -= amount;

        return true;
    }

    function approve(address spender, uint amount) external override returns (bool) {
        allowed[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function allowance(address from, address spender) external view override returns (uint) {
        return allowed[from][spender];
    }

    function transferFrom(address sender, address recipient, uint amount) external override returns (bool) {
        require(amount <= balances[sender], "ERC20Basic::transferFrom: amount is not correct");
        require(amount <= allowed[sender][msg.sender], "ERC20Basic::transferFrom: amount is not correct");

        balances[sender] = balances[sender] - amount;
        allowed[sender][msg.sender] = allowed[sender][msg.sender] - amount;
        balances[recipient] = balances[recipient] - amount;

        emit Transfer(sender, recipient, amount);

        return true;
    }
}