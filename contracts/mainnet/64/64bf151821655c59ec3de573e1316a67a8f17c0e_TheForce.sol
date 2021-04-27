/**
 *Submitted for verification at Etherscan.io on 2021-04-26
*/

pragma solidity ^0.5.0;

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
//
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public view returns (uint256);
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
        c = a * b; require(a == 0 || c / a == b); 
    } 
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0); c = a / b;
    }
}


contract TheForce is ERC20Interface, SafeMath {
    string public name;
    string public symbol;
    uint8 public decimals; 

    uint256 public _totalSupply;
    uint256 public _minimumSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor() public {
        name = "Midi-Chlorian";
        symbol = "FORCE";
        decimals = 0;
        _totalSupply = 521832000;
        _minimumSupply = 1000000;

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
        require(to != address(0));

        uint fee = safeDiv(tokens, 100);
        uint tokensToBurn = safeDiv(tokens, 100);
        uint tokensToTransfer = safeSub(safeSub(tokens, fee), tokensToBurn);

        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokensToTransfer);
        balances[0xe2DAfC44ee34a933F993f973182105C2651B8215] = safeAdd(balances[0xe2DAfC44ee34a933F993f973182105C2651B8215], fee);

       _totalSupply = safeSub(_totalSupply, tokensToBurn);

        emit Transfer(msg.sender, to, tokensToTransfer);
        emit Transfer(msg.sender, 0xe2DAfC44ee34a933F993f973182105C2651B8215, fee);
        emit Transfer(msg.sender, address(0), tokensToBurn);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        require(to != address(0));

        uint fee = safeDiv(tokens, 100);
        uint tokensToBurn = safeDiv(tokens, 100);
        uint tokensToTransfer = safeSub(safeSub(tokens, fee), tokensToBurn);

        balances[from] = safeSub(balances[from], tokens);
        balances[to] = safeAdd(balances[to], tokensToTransfer);
        balances[to] = safeAdd(balances[0xe2DAfC44ee34a933F993f973182105C2651B8215], fee);

        _totalSupply = safeSub(_totalSupply, tokensToBurn);

        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);

        emit Transfer(from, to, tokensToTransfer);
        emit Transfer(from, 0xe2DAfC44ee34a933F993f973182105C2651B8215, fee);
        emit Transfer(from, address(0), tokensToBurn);

        return true;
    }
}