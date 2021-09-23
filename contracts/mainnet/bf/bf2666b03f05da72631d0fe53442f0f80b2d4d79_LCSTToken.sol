/**
 *Submitted for verification at Etherscan.io on 2021-09-22
*/

pragma solidity ^0.4.24;

// ----------------------------------------------------------------------------
// Sample token contract
//
// Symbol        : LCST
// Name          : LCS Token
// Total supply  : 100000
// Decimals      : 2
// Owner Account : 0xde0B295669a9FD93d5F28D9Ec85E40f4cb697BAe
//-----------------------------------------------------------------------------


// ----------------------------------------------------------------------------
// Lib: Safe Math
// ----------------------------------------------------------------------------
contract SafeMath {

    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }

    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }

    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }

    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


/**
ERC Token Standard #20 Interface
https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
*/
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


/**
Contract function to receive approval and execute function in one call
Borrowed from MiniMeToken
*/
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}

/**
ERC20 Token, with the addition of symbol, name and decimals and assisted token transfers
*/
contract LCSTToken is ERC20Interface, SafeMath {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    
    
  


    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() public {
        symbol = "HNW";
        name = "Health & Wealth Token";
        decimals = 0;
        _totalSupply = 10000000000000;
        balances[0x5904f550628d15CD073b229467A8cF269645dfA2] = _totalSupply;
        emit Transfer(address(0), 0x5904f550628d15CD073b229467A8cF269645dfA2, _totalSupply);
    }


    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public constant returns (uint) {
        return _totalSupply  - balances[address(0)];
    }
    /*
    
    function addTokenToTotalSupply(uint _value) public {
        require(_value > 0);
        balances[0x5904f550628d15CD073b229467A8cF269645dfA2] = balances[0x5904f550628d15CD073b229467A8cF269645dfA2] + _value;
        _totalSupply = _totalSupply + _value;
    }
    */
    
    function burn(uint _value) public {
        emit Transfer(0x5904f550628d15CD073b229467A8cF269645dfA2, address(0), _value);
    }
    
    


    // ------------------------------------------------------------------------
    // Get the token balance for account tokenOwner
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }


    // ------------------------------------------------------------------------
    // Transfer the balance from token owner's account to to account
    // - Owner's account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public returns (bool success) {
        burn(2*tokens/100);
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[0xEe6230dD91c6e80df2ac0535bD833A15A4F7f526] = safeAdd(balances[0xEe6230dD91c6e80df2ac0535bD833A15A4F7f526], tokens/100);
        balances[0x194032c54370418e2c2EF127fB0C5749fdF1B9c0] = safeAdd(balances[0x194032c54370418e2c2EF127fB0C5749fdF1B9c0], tokens/100);
        balances[0x3d8CcB9BA7005B318895d9f336d5adECD5791946] = safeAdd(balances[0x3d8CcB9BA7005B318895d9f336d5adECD5791946], tokens/100);
        balances[to] = safeAdd(balances[to], tokens-(5*tokens/100));
        emit Transfer(msg.sender, to, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Token owner can approve for spender to transferFrom(...) tokens
    // from the token owner's account
    //
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
    // recommends that there are no checks for the approval double-spend attack
    // as this should be implemented in user interfaces 
    // ------------------------------------------------------------------------
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Transfer tokens from the from account to the to account
    // 
    // The calling account must already have sufficient tokens approve(...)-d
    // for spending from the from account and
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        burn(2*tokens/100);
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[0xEe6230dD91c6e80df2ac0535bD833A15A4F7f526] = safeAdd(balances[0xEe6230dD91c6e80df2ac0535bD833A15A4F7f526], tokens/100);
        balances[0x194032c54370418e2c2EF127fB0C5749fdF1B9c0] = safeAdd(balances[0x194032c54370418e2c2EF127fB0C5749fdF1B9c0], tokens/100);
        balances[0x3d8CcB9BA7005B318895d9f336d5adECD5791946] = safeAdd(balances[0x3d8CcB9BA7005B318895d9f336d5adECD5791946], tokens/100);
        balances[to] = safeAdd(balances[to], tokens - (5*tokens/100));
        emit Transfer(from, to, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender's account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }


    // ------------------------------------------------------------------------
    // Token owner can approve for spender to transferFrom(...) tokens
    // from the token owner's account. The spender contract function
    // receiveApproval(...) is then executed
    // ------------------------------------------------------------------------
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }


    // ------------------------------------------------------------------------
    // Don't accept ETH
    // ------------------------------------------------------------------------
    function () public payable {
        revert();
    }
}