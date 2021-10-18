/**
 *Submitted for verification at Etherscan.io on 2021-10-17
*/

pragma solidity ^0.4.24;
 
//Safe Math Interface
 
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
 
 
//ERC Token Standard #20 Interface
 
interface ERC20Interface {
    function totalSupply() external constant returns (uint);
    function balanceOf(address tokenOwner) external constant returns (uint balance);
    function allowance(address tokenOwner, address spender) external constant returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
 
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}
 
 
//Contract function to receive approval and execute function in one call
 
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}
 
//Actual token contract
 
contract TESR3SmartContract is ERC20Interface, SafeMath {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public Multiplier;
    uint public _totalSupply;
 
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
 
    constructor() public {
        symbol = "TESR14";
        name = "TestTokenRink14";
        decimals = 18;
        Multiplier = 1000000000000000000;
        _totalSupply = 1000000000*Multiplier;
        balances[0x842201C0d4612FC3A20434FC697a43881AAbAA9A] = _totalSupply;
        emit Transfer(address(0), 0x842201C0d4612FC3A20434FC697a43881AAbAA9A, _totalSupply);
    }
 
    function totalSupply() external constant returns (uint) { 
        return _totalSupply  - balances[address(0)];
    }
    function balanceOf(address tokenOwner) external constant returns (uint balance) {
        return balances[tokenOwner];
    }
 
    function transfer(address to, uint tokens) external returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens*Multiplier);
        balances[to] = safeAdd(balances[to], tokens*Multiplier);
        emit Transfer(msg.sender, to, tokens*Multiplier);
        return true;
    }
    function approve(address spender, uint tokens) external returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
 
    function transferFrom(address from, address to, uint tokens) external returns (bool success) {
        balances[from] = safeSub(balances[from], tokens*Multiplier);
        //allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens*Multiplier);
        emit Transfer(from, to, tokens*Multiplier);
        return true;
    }
 
    function allowance(address tokenOwner, address spender) external constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
 
    function approveAndCall(address spender, uint tokens, bytes data) external returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }
    function () external payable {
        revert();
    }
    //mint 
    //burn
    //undo transaction
    //selfdestruct
}