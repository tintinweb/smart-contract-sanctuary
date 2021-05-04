/**
 *Submitted for verification at Etherscan.io on 2021-05-04
*/

pragma solidity ^0.5.0;

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
//
// Optimization 1 (5/3/2021): restrict the raw amount of transfer to be 2^96-1.
// ----------------------------------------------------------------------------
contract ERC20Interface { // six  functions
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint rawAmt) public returns (bool success);
    function approve(address spender, uint rawAmt) public returns (bool success);
    function transferFrom(address from, address to, uint rawAmt) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint rawAmt);
    event Approval(address indexed tokenOwner, address indexed spender, uint rawAmt);
}

// ----------------------------------------------------------------------------
// Safe Math Library
// ----------------------------------------------------------------------------
contract SafeMath {
    function safeAdd(uint96 a, uint96 b) public pure returns (uint96 c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint96 a, uint96 b) public pure returns (uint96 c) {
        require(b <= a); 
        c = a - b; 
    } 
        
    function safeMul(uint96 a, uint96 b) public pure returns (uint96 c) { 
        c = a * b; 
        require(a == 0 || c / a == b); 
    } 
        
    function safeDiv(uint96 a, uint96 b) public pure returns (uint96 c) { 
        require(b > 0);
        c = a / b;
    }
}


contract PPSwap is ERC20Interface, SafeMath {
    string public constant name = "PPSwap";
    string public constant symbol = "PPS";
    uint8 public constant decimals = 6; // 18 decimals is the strongly suggested default, avoid changing it
    uint public constant _totalSupply = 1000000000*10**6;

    mapping(address => uint96) balances;       // two column table: owneraddress, balance
    mapping(address => mapping(address => uint96)) allowed; // three column table: owneraddress, spenderaddress, allowance

    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor() public {
        balances[msg.sender] = uint96(_totalSupply);
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }

    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    // called by the owner
    function approve(address spender, uint rawAmt) public returns (bool success) {
        require(rawAmt < 2**96, "Approve amount is too big.");
        allowed[msg.sender][spender] = uint96(rawAmt);
        emit Approval(msg.sender, spender, uint96(rawAmt));
        return true;
    }

    function transfer(address to, uint rawAmt) public returns (bool success) {
        require(rawAmt < 2**96, "Transfer amount is too big.");
        balances[msg.sender] = safeSub(balances[msg.sender], uint96(rawAmt));
        balances[to] = safeAdd(balances[to], uint96(rawAmt));
        emit Transfer(msg.sender, to, rawAmt);
        return true;
    }

    function transferFrom(address from, address to, uint rawAmt) public returns (bool success) {
        require(rawAmt < 2**96, "Transfer amount is too big.");
        balances[from] = safeSub(balances[from], uint96(rawAmt));
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], uint96(rawAmt));
        balances[to] = safeAdd(balances[to], uint96(rawAmt));
        emit Transfer(from, to, rawAmt);
        return true;
    }
}