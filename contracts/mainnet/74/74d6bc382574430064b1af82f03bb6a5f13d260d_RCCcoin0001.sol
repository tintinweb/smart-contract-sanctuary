pragma solidity ^0.4.18;
////////////////////////////////////////////////////////////
// Rimdeika Consulting and Coaching AB (RC&C AB)
// Alingsas SWEDEN
////////////////////////////////////////////////////////////
// &#39;RCCcoin0001&#39; token contract
// Deployed to : 0x504474e3c6BCacfFbF85693F44D050007b9C5257
// Symbol      : 1st
// Name        : RCC-coin
// Total supply: 1
// Decimals    : 0
////////////////////////////////////////////////////////////
// Safe maths
////////////////////////////////////////////////////////////
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
////////////////////////////////////////////////////////////
// RCCToken Standard ERC20Interface
////////////////////////////////////////////////////////////
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
////////////////////////////////////////////////////////////
// Contract function to receive approval and execute function in one call
////////////////////////////////////////////////////////////
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}
////////////////////////////////////////////////////////////
// Owned contract
////////////////////////////////////////////////////////////
contract Owned {
    address public owner;
    address public newOwner;
    event OwnershipTransferred(address indexed _from, address indexed _to);
    constructor() public {
        owner = msg.sender;
    }
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}
////////////////////////////////////////////////////////////
// ERC20 Token, with the addition of symbol, name and decimals and assisted token transfers
////////////////////////////////////////////////////////////
contract RCCcoin0001 is ERC20Interface, Owned, SafeMath {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    /////////////////////////////////////////////////////////////
    // Constructor
    /////////////////////////////////////////////////////////////
    constructor() public {
        symbol = "1st";
        name = "RCC-coin";
        decimals = 0;
        _totalSupply = 1;
        balances[0x504474e3c6BCacfFbF85693F44D050007b9C5257] = _totalSupply;
        emit Transfer(address(0), 0x504474e3c6BCacfFbF85693F44D050007b9C5257, _totalSupply);
    }
    /////////////////////////////////////////////////////////////
    // Total supply
    /////////////////////////////////////////////////////////////
    function totalSupply() public constant returns (uint) {
        return _totalSupply  - balances[address(0)];
    }
    /////////////////////////////////////////////////////////////
    // Get the token balance for account tokenOwner
    /////////////////////////////////////////////////////////////
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }
    ////////////////////////////////////////////////////////////
    // Transfer the balance from token owner&#39;s account to to account
    // - Owner&#39;s account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    ////////////////////////////////////////////////////////////
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
    ////////////////////////////////////////////////////////////
    // Token owner can approve for spender to transferFrom(...) tokens
    // from the token owner&#39;s account
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
    // recommends that there are no checks for the approval double-spend attack
    // as this should be implemented in user interfaces 
    ////////////////////////////////////////////////////////////
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    ////////////////////////////////////////////////////////////
    // Transfer tokens from the from account to the to account
    // The calling account must already have sufficient tokens approve(...)-d
    // for spending from the from account and
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer
    // - 0 value transfers are allowed
    ////////////////////////////////////////////////////////////
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
    ////////////////////////////////////////////////////////////
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender&#39;s account
    ////////////////////////////////////////////////////////////
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
    ////////////////////////////////////////////////////////////
    // Token owner can approve for spender to transferFrom(...) tokens
    // from the token owner&#39;s account. The spender contract function
    // receiveApproval(...) is then executed
    ////////////////////////////////////////////////////////////
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }
    ////////////////////////////////////////////////////////////
    // Don&#39;t accept ETH
    ////////////////////////////////////////////////////////////
    function () public payable {
        revert();
    }
    ////////////////////////////////////////////////////////////
    // Owner can transfer out any accidentally sent ERC20 tokens
    ////////////////////////////////////////////////////////////
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}