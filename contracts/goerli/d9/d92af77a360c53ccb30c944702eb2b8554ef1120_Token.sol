/**
 *Submitted for verification at Etherscan.io on 2021-09-16
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >= 0.8.4;

//start of token contract
contract Token {
    string public name;
    string public symbol;
    uint public decimals;
    uint public _totalSupply;
    
    //define Approval and Transfer events
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    
    //define associative array (dictionary) to store acount addresses (keys) and adress token values (values) as object "balances"
    mapping(address => uint256) balances;

    //define associative array (dictionary) to store account addresses approved to withdrawel (keys) and approved amount of token transfer (values) as object 'allowed'
    mapping(address => mapping (address => uint256)) allowed;
    
    constructor() {
        name = 'Acorns';
        symbol = 'ACRN';
        decimals = 18;
        _totalSupply = 1000000000000 * 10**18;
        balances[msg.sender] = _totalSupply;
    }
    
    //return the total number of all tokens in circulation
    function totalSupply() public view returns (uint256 Acorns) {
        return _totalSupply;
    }
    
    //return the current token balance of a specific account
    function balanceOf(address account) public view returns (uint256 Acorns) {
        return balances[account];
    }
    
    //transfer tokens from owner address to that of another user
    function transfer(address to, uint256 value) public returns (bool success) {
        require(value <= balances[msg.sender]);
        balances[msg.sender] -= value;
        balances[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    //allow owner to approve "delegate" account to withdrawal tokens from his account and transfer to other users (often used for token marketplace scenereo)
    function approve(address delegate, uint256 value) public returns (bool success) {
        allowed[msg.sender][delegate] = value;
        emit Approval(msg.sender, delegate, value);
        return true;
    }
    
    //returns the current approved number of tokens by an owner to a specific delegate (set in approve function)
    function allowance(address owner, address delegate) public view returns (uint256 Acorns) {
        return allowed[owner][delegate];
    }
    
    //verify the owner has enough tokens and the delegate has enough withdrawal allowance left, then subtract from owner's account and delegate's withdrawal allowance
    function transferFrom(address owner, address buyer, uint value) public returns (bool success) {
        require(value <= balances[owner]);
        require(value <= allowed[owner][msg.sender]);
        balances[owner] -= value;
        allowed[owner][msg.sender] -= value;
        balances[buyer] += value;
        emit Transfer(owner, buyer, value);
        return true;
    }
}