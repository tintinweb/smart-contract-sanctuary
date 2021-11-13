// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

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
    string public name = "Xemirp TOKEN";
    string public symbol = "XEM";
    uint public decimals = 18;

    address public owner;

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
    uint public totalSupply;

    constructor(uint initSupply) {
        owner = msg.sender;
        balances[msg.sender] += initSupply;
        totalSupply = initSupply;

        emit Transfer(address(0), msg.sender, initSupply);
    }

    function balanceOf(address account) external view override returns (uint) {
        return balances[account];
    }

    function transfer(address recipient, uint amount) public override returns (bool) {
        require(balances[msg.sender] >= amount, "ERC20Basic::transfer: amount is not correct");

        balances[msg.sender] = balances[msg.sender] - amount;
        balances[recipient] = balances[recipient] + amount;

        emit Transfer(msg.sender, recipient, amount);

        return true;
    }

    function mint(uint amount) external returns (bool) {
        balances[msg.sender] += amount;
        totalSupply += amount;

        emit Transfer(address(0), msg.sender, amount);

        return true;
    }

    function burn(uint amount) external returns (bool) {
        balances[msg.sender] -= amount;
        totalSupply -= amount;

        emit Transfer(msg.sender, address(0), amount);

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
        balances[recipient] = balances[recipient] + amount;

        emit Transfer(sender, recipient, amount);

        return true;
    }
}