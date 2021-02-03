/**
 *Submitted for verification at Etherscan.io on 2021-01-31
*/

pragma solidity ^0.4.24;

/**
New808token ERC20 contract
Symbol        : T808
Name          : New808token
Decimals      : 0
Owner Account : 0x9BDD969B35b0BA80014A9Ba771a3842883Eac1bA
(c) by Didar Metu  2021. MIT Licence.
*/

/** Lib: Safe Math */
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
https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
*/
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Mint(address indexed to, uint tokens);
    event Burn(address indexed from, uint tokens);
}

/**
Contract function to receive approval and execute function in one call
*/
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}

/**
ERC20 Token, with the addition of symbol, name and decimals and assisted token transfers
*/
contract New808token is ERC20Interface, SafeMath {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;
    address public contract_owner;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    /** Constructor */
    constructor() public {
        symbol = "T808";
        name = "New808token";
        decimals = 0;
        _totalSupply = 1000000; //1 million
        contract_owner = 0x9BDD969B35b0BA80014A9Ba771a3842883Eac1bA; // didarmetu
        balances[0x6c431c70ce1a5e06e171478824721c35925c6ab1] = 200000; // Lifenaked
        balances[0xFd3066a5299299514E5C796D3B3fae8C744320F5] = 200000; //cunningstunt
        balances[contract_owner] = 600000;
        emit Transfer(address(0), contract_owner, 600000);
        emit Transfer(address(0), 0x6c431c70ce1a5e06e171478824721c35925c6ab1, 200000);
        emit Transfer(address(0), 0xFd3066a5299299514E5C796D3B3fae8C744320F5, 200000);
    }

    /** Total supply */
    function totalSupply() public constant returns (uint) {
        return _totalSupply  - balances[address(0)];
    }

    /** Get the token balance for account tokenOwner */
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }

    /**
    Transfer the balance from token owner's account to to account
    - Owner's account must have sufficient balance to transfer
    */
    function transfer(address to, uint tokens) public returns (bool success) {
        require(tokens <= balances[msg.sender]);
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    /**
    Token owner can approve for spender to transferFrom(...) tokens from the token owner's account
    */
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    /**
    Transfer tokens from the from account to the to account
    The calling account must already have sufficient tokens approve(...)-d for spending from the from account and
    - From account must have sufficient balance to transfer
    - Spender must have sufficient allowance to transfer
    */
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

    /**
    Returns the amount of tokens approved by the owner that can be transferred to the spender's account
    */
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    /**
    Token owner can approve for spender to transferFrom(...) tokens from the token owner's account. The spender contract function
    receiveApproval(...) is then executed
    */
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }

    /**
    Mintable ERC20
    Simple ERC20 Token example, with mintable token creation
    Based on code by TokenMarketNet: https://github.com/TokenMarketNet/smart-contracts/blob/master/contracts/MintableToken.sol
    */
    function CreateT808(address to, uint tokens) public returns (bool success) {
        require(msg.sender == contract_owner);
        _totalSupply = safeAdd(_totalSupply,tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(address(0), to, tokens);
        emit Mint(to, tokens);
        return true;
    }

    /** Burn Tokens */
    function BurnT808(uint tokens) public returns (bool success) {
        require(tokens <= balances[msg.sender]);                           // Check if the sender has enough
        balances[msg.sender] = safeSub(balances[msg.sender],tokens);       // Subtract from the sender
        _totalSupply = safeSub(_totalSupply, tokens);                      // Updates totalSupply
        emit Transfer(msg.sender, address(0), tokens);
        emit Burn(msg.sender, tokens);
        return true;
    }

    /** Don't accept ETH */
    function () public payable {
        revert();
    }
}