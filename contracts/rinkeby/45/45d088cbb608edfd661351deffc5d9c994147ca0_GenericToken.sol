/**
 *Submitted for verification at Etherscan.io on 2022-01-04
*/

pragma solidity ^0.8.0;


// ----------------------------------------------------------------------------

// 'Banana Token' contract

 
//

// Symbol      : BANANA

// Name        : Banana Token

// Total supply: 100,000,000.00

// Decimals    : 18

//


// ----------------------------------------------------------------------------


 

// ----------------------------------------------------------------------------

// ERC Token Standard #20 Interface

// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md

// ----------------------------------------------------------------------------

abstract contract ERC20Interface {

    function totalSupply() public virtual returns (uint);

    function balanceOf(address tokenOwner) public virtual returns (uint balance);

    function allowance(address tokenOwner, address spender) public virtual returns (uint remaining);

    function transfer(address to, uint tokens) public virtual returns (bool success);

    function approve(address spender, uint tokens) public virtual returns (bool success);

    function transferFrom(address from, address to, uint tokens) public virtual returns (bool success);


    event Transfer(address indexed from, address indexed to, uint tokens);

    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

}

 

 
// ----------------------------------------------------------------------------

// ERC20 Token, with the addition of symbol, name and decimals and an

// initial fixed supply

// ----------------------------------------------------------------------------

contract GenericToken is ERC20Interface  {
 

    string public symbol;

    string public name;

    uint public decimals = 18;

    uint public _totalSupply; 
 

    mapping(address => uint) balances;  

    mapping(address => mapping(address => uint)) allowed;
 

    // ------------------------------------------------------------------------

    // Constructor

    // ------------------------------------------------------------------------

    constructor() {
 
        symbol = "BANANA";

        name = "Banana Token";

        decimals = 18;

        _totalSupply = 100000000 * 10**uint(decimals);
 
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);

    }
 


    // ------------------------------------------------------------------------

    // Total supply

    // ------------------------------------------------------------------------

    function totalSupply() public view override returns (uint) {

        return _totalSupply  - balances[address(0)];

    }



    // ------------------------------------------------------------------------

    // Get the token balance for account `tokenOwner`

    // ------------------------------------------------------------------------

    function balanceOf(address tokenOwner) public view override returns (uint balance) {

        return balances[tokenOwner];

    }



    // ------------------------------------------------------------------------

    // Transfer the balance from token owner's account to `to` account

    // - Owner's account must have sufficient balance to transfer

    // - 0 value transfers are allowed

    // ------------------------------------------------------------------------

    function transfer(address to, uint tokens) public override returns (bool success) {

        balances[msg.sender] = balances[msg.sender] - (tokens);

        balances[to] = balances[to] + (tokens);

        emit Transfer(msg.sender, to, tokens);

        return true;

    }



    // ------------------------------------------------------------------------

    // Token owner can approve for `spender` to transferFrom(...) `tokens`

    // from the token owner's account

    //

    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md

    // recommends that there are no checks for the approval double-spend attack

    // as this should be implemented in user interfaces

    // ------------------------------------------------------------------------

    function approve(address spender, uint tokens) public override returns (bool success) {

        allowed[msg.sender][spender] = tokens;

        emit Approval(msg.sender, spender, tokens);

        return true;

    }



    // ------------------------------------------------------------------------

    // Transfer `tokens` from the `from` account to the `to` account

    //

    // The calling account must already have sufficient tokens approve(...)-d

    // for spending from the `from` account and

    // - From account must have sufficient balance to transfer

    // - Spender must have sufficient allowance to transfer

    // - 0 value transfers are allowed

    // ------------------------------------------------------------------------

    function transferFrom(address from, address to, uint tokens) public override returns (bool success) {

        balances[from] = balances[from] - (tokens);

        allowed[from][msg.sender] = allowed[from][msg.sender] - (tokens);

        balances[to] = balances[to] + (tokens);

        emit Transfer(from, to, tokens);

        return true;

    }



    // ------------------------------------------------------------------------

    // Returns the amount of tokens approved by the owner that can be

    // transferred to the spender's account

    // ------------------------------------------------------------------------

    function allowance(address tokenOwner, address spender) public view override returns (uint remaining) {

        return allowed[tokenOwner][spender];

    }



    

    // ------------------------------------------------------------------------

    // Don't accept ETH

    // ------------------------------------------------------------------------

    fallback () external payable  {
        revert();
    }
   

    receive() external payable {
        revert();
    }
 

}