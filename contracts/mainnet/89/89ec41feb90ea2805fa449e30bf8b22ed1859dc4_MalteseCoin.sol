/**
 *Submitted for verification at Etherscan.io on 2021-05-01
*/

pragma solidity ^0.5.0;

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
//
// ----------------------------------------------------------------------------
contract ERC20Interface {
     /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() public view returns (uint);
     /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address tokenOwner) public view returns (uint balance);
     /**
     * @dev Returns the remaining number of tokens, `spender`
     * allowed to spend on behalf of `owner` through `transferFrom`. 
     * zero by default.
     *
     * This value changes when `approve` or `transferFrom` are called.
     */
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
     /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     */
    function transfer(address to, uint tokens) public returns (bool success);
     /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits an `Approval` event.
     */
    function approve(address spender, uint tokens) public returns (bool success);
     /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. 
     *`amount` is then deducted from the caller's allowance.
     *Returns a boolean value indicating whether the operation succeeded.
     * Emits a `Transfer` event.
     */
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

     /**
     * @dev Emitted `value` tokens are moved from account (`from`) to
     * another (`to`).
     *
     * Note:`value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint tokens);
     /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to `approve`. `value` is the new allowance.
     */
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


contract MalteseCoin is ERC20Interface, SafeMath {
    string public name; 
    string public symbol;
    uint8 public decimals; // 18 decimals is the strongly suggested default, avoid changing it

    uint256 public _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor() public {
        name = "MalteCoin"; //set name of coin
        symbol = "MTC"; //set coin symbol
        decimals = 18;
        _totalSupply = 500000000000000000000000000000000;

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
}