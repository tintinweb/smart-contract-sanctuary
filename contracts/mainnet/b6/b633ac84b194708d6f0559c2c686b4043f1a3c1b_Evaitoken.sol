/**
 *Submitted for verification at Etherscan.io on 2021-06-06
*/

/**
 *Submitted for verification at Etherscan.io on 2020-07-21
 */

// SPDX-License-Identifier: MIT

pragma solidity 0.6.10;

//--------------------------------------
//  EVAI contract
//
// Symbol      : EVAI
// Name        : EVAI.IO
// Total supply: 1000000000
// Decimals    : 8
//--------------------------------------

abstract contract ERC20Interface {
    function totalSupply() external view virtual returns (uint256);

    function balanceOf(address tokenOwner)
        external
        view
        virtual
        returns (uint256);

    function allowance(address tokenOwner, address spender)
        external
        view
        virtual
        returns (uint256);

    function transfer(address to, uint256 tokens)
        external
        virtual
        returns (bool);

    function approve(address spender, uint256 tokens)
        external
        virtual
        returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 tokens
    ) external virtual returns (bool);

    function burn(uint256 tokens) external virtual returns (bool success);

    function buy(address to, uint256 tokens) external virtual returns (bool);

    function operationProfit(uint256 _profit) external virtual returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(
        address indexed tokenOwner,
        address indexed spender,
        uint256 tokens
    );
    event Burn(address from, address, uint256 value);
    event Profit(address from, uint256 profit, uint256 totalProfit);
}

// ----------------------------------------------------------------------------
// Safe Math Library
// ----------------------------------------------------------------------------
contract SafeMath {
    function safeAdd(uint256 a, uint256 b) public pure returns (uint256 c) {
        c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function safeSub(uint256 a, uint256 b) public pure returns (uint256 c) {
        require(b <= a, "SafeMath: subtraction overflow");
        c = a - b;
        return c;
    }
}

contract Evaitoken is ERC20Interface, SafeMath {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public initialSupply;
    uint256 public _totalSupply;
    address public owner;
    uint256 public totalProfit;
    uint256 public profit;

    mapping(address => uint256) internal balances;
    mapping(address => mapping(address => uint256)) internal allowed;
    mapping(uint256 => uint256) internal token;

    constructor() public {
        name = "EVAI.IO";
        symbol = "EVAI";
        decimals = 8;
        _totalSupply = 1000000000 * 10**uint256(decimals);
        initialSupply = _totalSupply;
        balances[msg.sender] = _totalSupply;
        owner = msg.sender;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function totalSupply() external view override returns (uint256) {
        return safeSub(_totalSupply, balances[address(0)]);
    }

    function balanceOf(address tokenOwner)
        external
        view
        override
        returns (uint256 getBalance)
    {
        return balances[tokenOwner];
    }

    function allowance(address tokenOwner, address spender)
        external
        view
        override
        returns (uint256 remaining)
    {
        return allowed[tokenOwner][spender];
    }

    function approve(address spender, uint256 tokens)
        external
        override
        returns (bool success)
    {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transfer(address to, uint256 tokens)
        external
        override
        returns (bool success)
    {
        require(to != address(0));
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokens
    ) external override returns (bool success) {
        require(to != address(0));
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

    function buy(address to, uint256 tokens)
        external
        override
        returns (bool success)
    {
        require(to != address(0));
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function operationProfit(uint256 _profit)
        external
        override
        returns (bool success)
    {
        require(owner == msg.sender, "This is not owner");
        profit = _profit;
        totalProfit = safeAdd(totalProfit, profit);
        emit Profit(msg.sender, profit, totalProfit);
        return true;
    }

    function burn(uint256 tokens) external override returns (bool success) {
        require(owner == msg.sender, "This is not owner");
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        _totalSupply = safeSub(_totalSupply, tokens);
        emit Burn(msg.sender, address(0), tokens);
        return true;
    }
}