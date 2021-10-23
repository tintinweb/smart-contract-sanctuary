/**
 *Submitted for verification at Etherscan.io on 2021-10-22
*/

pragma solidity ^0.8.7;

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// (Implemented from https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md)
// ----------------------------------------------------------------------------

abstract contract ERC20Interface {
    
    // OPTIONAL FUNCTIONS
    
    // function name() public view returns (string) // Returns the name of the token // OPTIONAL
    // function symbol() public view returns (string) // Returns the symbol of the token // OPTIONAL
    // function decimals() public view returns (uint8) // Returns the number of decimals the token uses // OPTIONAL
    
    
    // MAIN FUNCTIONS
    
    // Returns the total supply of the token
    function totalSupply() virtual public view returns (uint);
    
    // Returns account balance with address 'tokenOwner'
    function balanceOf(address tokenOwner) virtual public view returns (uint balance); 
    
    // Returns amount 'spender' can withdraw from 'tokenOwner'
    function allowance(address tokenOwner, address spender) virtual public view returns (uint remaining);
    
    // Transfers 'tokens' amount to address 'to'. Fires Transfer event which can potentially throw error if balance too low.
    function transfer(address to, uint tokens) virtual public returns (bool success); 
    
    // Lets 'spender' withdraw from an account multiple times, up to the amount 'tokens'
    function approve(address spender, uint tokens) virtual public returns (bool success);
    // Transfers 'tokens' amount from address 'from' to address 'to'. Fires Transfer event which can potentially throw error if balance too low.
    function transferFrom(address from, address to, uint tokens) virtual public returns (bool success);
    
    
    // EVENTS
    
    // Triggers when tokens are transferred. This includes zero value transfers.
    event Transfer(address indexed from, address indexed to, uint tokens);
    
    // Triggers on a successful call to approve function
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


contract AuxToken is ERC20Interface, SafeMath {
    string public name;
    string public symbol;
    uint8 public decimals; // 18 decimals is good default

    uint256 public _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;


    // ----------------------------------------------------------------------------
    // Constructor - Initializes Contract
    // ----------------------------------------------------------------------------
    
    constructor() {
        name = "Auxiun"; // Name of ERC20 Token being deployed
        symbol = "AUX"; // Symbol for token, 
        decimals = 18; // Amount of 0's after total supply below
        _totalSupply = 1000000000000000000000000000; // (_totalSupply).length - decimals for true supply count (1 millon default)

        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    
    
    // ----------------------------------------------------------------------------
    // Functions - Functionality for each function commented above, starting on line 7 (contract ERC20Interface).
    // ----------------------------------------------------------------------------
    
    function totalSupply() public override view returns (uint) {
        return _totalSupply - balances[address(0)];
    }

    function balanceOf(address tokenOwner) public override view returns (uint balance) {
        return balances[tokenOwner];
    }

    function allowance(address tokenOwner, address spender) public override view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function approve(address spender, uint tokens) public override returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transfer(address receiver, uint tokens) public override returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[receiver] = safeAdd(balances[receiver], tokens);
        emit Transfer(msg.sender, receiver, tokens);
        return true;
    }

    function transferFrom(address sender, address receiver, uint tokens) public override returns (bool success) {
        balances[sender] = safeSub(balances[sender], tokens);
        allowed[sender][msg.sender] = safeSub(allowed[sender][msg.sender], tokens);
        balances[receiver] = safeAdd(balances[receiver], tokens);
        emit Transfer(sender, receiver, tokens);
        return true;
    }
}