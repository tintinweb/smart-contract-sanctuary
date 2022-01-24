/**
 *Submitted for verification at BscScan.com on 2022-01-23
*/

// SPDX-License-Identifier: Unlicensed

// File: 1.sol



pragma solidity >=0.7.0 <0.9.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address tokenOwner) external view returns (uint256 balance);
    function allowance(address tokenOwner, address spender) external view returns (uint256 remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}

// ----------------------------------------------------------------------------
// Safe Math Library
// ----------------------------------------------------------------------------
contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a); c = a - b; 
        
    } 
    function safeMul(uint a, uint b) public pure returns (uint c) { 
        c = a * b; require(a == 0 || c / a == b); 
        
    } 
    function safeDiv(uint a, uint b) public pure returns (uint c) { 
        require(b > 0);
        c = a / b;
    }
}


contract DiscoCoin is IERC20, SafeMath {
    string public name;
    string public symbol;
    uint8 public decimals; // 18 decimals is the strongly suggested default, avoid changing it

    uint256 public _totalSupply;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor() {
        name = "Disco Coin";
        symbol = "DISCO";
        decimals = 10;
        _totalSupply = 1000000;

        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

        function totalSupply() public override view returns (uint256) {
            return _totalSupply  - balances[address(0)];
        }

        function balanceOf(address tokenOwner) public override view returns (uint256 balance) {
            return balances[tokenOwner];
        }

        function allowance(address tokenOwner, address spender) public override view returns (uint256 remaining) {
            return allowed[tokenOwner][spender];
        }

        function approve(address spender, uint256 tokens) public override returns (bool success) {
            allowed[msg.sender][spender] = tokens;
            emit Approval(msg.sender, spender, tokens);
            return true;
        }

        function transfer(address to, uint256 tokens) public override returns (bool success) {
           require(balances[msg.sender] >= tokens&& tokens > 0);
		balances[msg.sender] -= tokens;
		balances[to] += tokens;
            emit Transfer(msg.sender, to, tokens);
            return true;
        }

        function transferFrom(address from, address to, uint256 tokens) public override returns (bool success) {
        require(allowed[from][msg.sender] >= tokens&& balances[from] >= tokens&& tokens > 0);
		balances[from] -= tokens;
		balances[to] += tokens;
		allowed[from][msg.sender] -= tokens;
            emit Transfer(from, to, tokens);
            return true;
        }
    }