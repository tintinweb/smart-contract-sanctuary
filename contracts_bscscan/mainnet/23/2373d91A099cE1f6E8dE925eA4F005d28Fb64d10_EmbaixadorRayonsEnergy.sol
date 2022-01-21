/**
 *Submitted for verification at BscScan.com on 2022-01-21
*/

/**
  _____              __     __   ____    _   _    _____     ______   _   _   ______   _____     _____  __     __
 |  __ \      /\     \ \   / /  / __ \  | \ | |  / ____|   |  ____| | \ | | |  ____| |  __ \   / ____| \ \   / /
 | |__) |    /  \     \ \_/ /  | |  | | |  \| | | (___     | |__    |  \| | | |__    | |__) | | |  __   \ \_/ / 
 |  _  /    / /\ \     \   /   | |  | | | . ` |  \___ \    |  __|   | . ` | |  __|   |  _  /  | | |_ |   \   /  
 | | \ \   / ____ \     | |    | |__| | | |\  |  ____) |   | |____  | |\  | | |____  | | \ \  | |__| |    | |   
 |_|  \_\ /_/    \_\    |_|     \____/  |_| \_| |_____/    |______| |_| \_| |______| |_|  \_\  \_____|    |_|   
                                                                                                                
                                                                                                                


            ______   __  __   ____               _____  __   __             _____     ____    _____  
            |  ____| |  \/  | |  _ \      /\     |_   _| \ \ / /     /\     |  __ \   / __ \  |  __ \ 
            | |__    | \  / | | |_) |    /  \      | |    \ V /     /  \    | |  | | | |  | | | |__) |
            |  __|   | |\/| | |  _ <    / /\ \     | |     > <     / /\ \   | |  | | | |  | | |  _  / 
            | |____  | |  | | | |_) |  / ____ \   _| |_   / . \   / ____ \  | |__| | | |__| | | | \ \ 
            |______| |_|  |_| |____/  /_/    \_\ |_____| /_/ \_\ /_/    \_\ |_____/   \____/  |_|  \_\
                                                                                           
                                                                                           

**/

/**

------------------------------------------------------------------------------------------------------------------------------
This token is a seal of authenticity whose purpose is to validate its holder as
an ambassador of Rayons Energy (the people who pre-purchased our token).

This token guarantees that the collectible item (a physical coin) received by the
ambassadors is an original, exclusive, and limited item that also grants early access
to the purchase of NFTs.

By transferring this token to somebody else, you automatically transfer your title of
Ambassador, as well as the early access to the purchase of NFTs, and you commit to
sending the physical coin to the new holder.

WARNING: this token cannot be sold separately from the collectible item (the physical coin).
------------------------------------------------------------------------------------------------------------------------------

Rayons Energy is a technology company focused on solar energy generation and its applications, 
seeking to consolidate the use of clean energy in the market. Initially, we are going to create 
a photovoltaic plant to use the energy to mine cryptocurrencies. In a second stage, we are going
create a large-scale solar plant to sell the energy generated to companies via a consortium. 
In the third stage, we are going to create a business condominium within the plant so that 
companies that demand high energy consumption migrate their operations to the Rayons's condominium.

● Follow on social media:


  Telegram: https://t.me/RayonsEnergy_BR
  Telegram: https://t.me/RayonsEnergy_USA
  Twitter:  https://twitter.com/en_rayons
  Website:  https://rayonsenergy.com

**/



/**
 *Submitted for verification at BscScan.com on 2021-04-27
*/

pragma solidity ^0.5.0;

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


contract EmbaixadorRayonsEnergy is ERC20Interface, SafeMath {
    string public name;
    string public symbol;
    uint8 public decimals;

    uint256 public _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor() public {
        name = "Embaixador Rayons Energy";
        symbol = "EMBAIXADOR";
        decimals = 0;
        _totalSupply = 1000;

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
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
}