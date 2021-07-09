/**
 *Submitted for verification at Etherscan.io on 2021-07-08
*/

/**
 *Submitted for verification at Etherscan.io on 2021-07-05
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
        require(b <= a); c = a - b;
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


contract Prosper is ERC20Interface, SafeMath {
    string public name;
    string public symbol;
    uint8 public decimals; // 18 decimals is the strongly suggested default, avoid changing it

    uint256 public _totalSupply;
    uint public checkpoint;
    address owner;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor() public{
        name = "Prosper";
        symbol = "PSP";
        decimals = 18;
        _totalSupply = 100000000000000000000000000;

        checkpoint = 8902139;
        owner = msg.sender;

        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    event tokensDistributed (
        address owner,
        uint tokens,
        address[] addresses,
        uint[] txCounts,
        uint checkpoint
    );

    event loggingTemp(
        uint msg
    );

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

    function distributeTokens(uint tokens, address[] memory addresses, uint[] memory txCounts, uint _checkpoint) public returns (bool success) {
        uint totalTx = 0;
        for(uint i = 0; i < txCounts.length; i++){
            totalTx += txCounts[i];
        }
        
        uint TokenPerTx = tokens / totalTx;
        
        for (uint i = 0; i < addresses.length - 1; i++) {
            transfer(addresses[i], TokenPerTx * txCounts[i]);
        }

        uint remainingTokens = tokens - (TokenPerTx * (totalTx - txCounts[txCounts.length - 1]) );
        transfer(addresses[addresses.length - 1], remainingTokens);

        if(msg.sender == owner){
            checkpoint = _checkpoint;
        }
        emit tokensDistributed( msg.sender, tokens, addresses, txCounts, checkpoint );
        return true;
    }
}