/**
 *Submitted for verification at Etherscan.io on 2022-01-14
*/

// Copyright (c) 2019-2021 Blockchain Presence
// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.0;

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
//
// ----------------------------------------------------------------------------
abstract contract ERC20Interface {
    function totalSupply() public view virtual returns (uint);
    function balanceOf(address tokenOwner) public view virtual returns (uint balance);
    function allowance(address tokenOwner, address spender) public view virtual returns (uint remaining);
    function transfer(address to, uint tokens) public virtual returns (bool success);
    function approve(address spender, uint tokens) virtual public returns (bool success);
    function transferFrom(address from, address to, uint tokens) virtual public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    
    event SubmittedRegistration(address indexed tokenOwner, uint hash, uint balance);
    event AppliedforDividend(address indexed tokenOwner, uint div_rights, bytes32 inv_key);
    event DividendPulled(address indexed tokenOwner, uint amount);
    event ChangeInRegistry(address indexed tokenOwner, uint balance); //this event is triggered by any token transfer with a none zero hash involved. the backend still needs to screen for the relevant accounts
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
        require(b <= a); c = a - b; } 
}

// ----------------------------------------------------------------------------
// Change Ownership
// ----------------------------------------------------------------------------
contract Ownable {
    address payable public owner;
    event OwnerChanged(address indexed previousOwner, address indexed newOwner);
    
    constructor() {
    owner = msg.sender;
    }
        
    modifier isOwner() {
        require(msg.sender == owner);
        _; //throws an exception if condition is not met and transaction will be reverted to the initial state
    }

    function changeOwner(address payable newOwner) public isOwner {
        require(newOwner != address(0));
        emit OwnerChanged(owner, newOwner);
        owner = newOwner;
    }
}

// ----------------------------------------------------------------------------
// Equity Token Contract
// ----------------------------------------------------------------------------   
    
contract BCP_Token is ERC20Interface, SafeMath, Ownable {
    string public name;
    string public symbol;
    uint8 public decimals; // 18 decimals is the strongly suggested default, avoid changing it
    uint256 public _totalSupply;
    
    bool public application; //application period
    bool public dividend; //dividend period
    uint public BCP_key;
    uint public divPerShare;
    

    mapping(address => uint) balances; //preset by ERC20
    mapping(address => mapping(address => uint)) allowed;
    mapping(address => status) investors; 
    
// ----------------------------------------------------------------------------
// Setup for ETH transfer
// ----------------------------------------------------------------------------
    receive() external payable {} //this fallback function is essential to making the contract receive ether from the owner
    
    function depositDividends() public payable isOwner { //allows owner to transfer dividend funds to the contract 
        payable(address(this)).transfer(msg.value);
    }
    
    function getContractBalance() public view isOwner returns (uint) { //gets the current balance of the contract 
        return address(this).balance;
    }
    
    
    /**
     * Constructor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor() {
        name = "BCP_Token";
        symbol = "BCP";
        decimals = 18;
        _totalSupply = 10000000000000000000000000; //10 million (10^7) shares times 10^18 = 10^25 

        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    
    struct status { 
        uint balances; 
        uint hash;
        uint rights;
        bytes32 key;
    }    
    
// ----------------------------------------------------------------------------
// Shareholder module
// ----------------------------------------------------------------------------
    
    function register(uint inv_hash) public returns (bool success) {
        require(balances[msg.sender] >= 1);
        investors[msg.sender].hash = inv_hash;
        emit SubmittedRegistration(msg.sender, inv_hash, balances[msg.sender]);
        return true;
    }
    
    function apply_div(uint div_rights, bytes32 inv_key) public returns (bool success) { //apply is an already reserved keyword, therefore the function is named apply_div
        require(application == true);
        investors[msg.sender].rights = div_rights;
        investors[msg.sender].key = inv_key;
        emit AppliedforDividend(msg.sender, div_rights, inv_key);
        return true;
    }
    
    function pull_div() public payable returns (bool success) {
        require(dividend == true);
        require(sha256(abi.encode(msg.sender, investors[msg.sender].rights, BCP_key)) == investors[msg.sender].key);
        uint amount = investors[msg.sender].rights*divPerShare;
        msg.sender.transfer(amount);
        investors[msg.sender].rights = 0;
        emit DividendPulled(msg.sender, amount);
        return true;
    }
    
// ----------------------------------------------------------------------------
// Contract management module
// ----------------------------------------------------------------------------
    
    function enableA() isOwner public returns (bool success) {
        require(dividend == false);
        application = true;
        return true;
    }
    
    function disableA() isOwner public returns (bool success) {
        application = false;
        return true;
    }
    
    function enableD(uint a_key, uint a_divPerShare) isOwner public returns (bool success) {
        require(application == false);
        BCP_key = a_key;
        divPerShare = a_divPerShare;
        dividend = true;
        return true;
    }
    
    function disableD() isOwner public returns (bool success) {
        dividend = false;
        owner.transfer(address(this).balance); //should transfer the remaining ETH from this contract balance to owner 
        return true;
    }
    
    function checkStatus(address tokenOwner) isOwner public view returns (uint, uint, uint, bytes32) {
        return (
            investors[tokenOwner].balances, //redundant because separate "mapping(address => uint)" preset by ERC20 standard 
            investors[tokenOwner].hash,
            investors[tokenOwner].rights,
            investors[tokenOwner].key
        );
     
    }
    
    function raiseTokens(address recipient, uint256 amount) public isOwner returns (bool success) {
        _totalSupply += amount;
        balances[recipient] += amount;
        emit Transfer(address(0), recipient, amount);
        
        if (investors[recipient].hash != 0) {
            emit ChangeInRegistry(recipient, balances[recipient]);
            }
        return true;    
    }
    
    function confiscate(address tokenOwner, uint256 amount) public isOwner returns (bool success) {
        balances[tokenOwner] -= amount;
        balances[owner] += amount;
        emit Transfer(tokenOwner, owner, amount);
        
        if (investors[tokenOwner].hash != 0) {
            emit ChangeInRegistry(tokenOwner, balances[tokenOwner]);
            }
        if (investors[owner].hash != 0) {
            emit ChangeInRegistry(owner, balances[owner]);
            }
        return true;
    }

// ----------------------------------------------------------------------------
// ERC20 module
// ----------------------------------------------------------------------------
    
    function totalSupply() public view override returns (uint) {
        return _totalSupply  - balances[address(0)];
    }

    function balanceOf(address tokenOwner) public view override returns (uint balance) {
        return balances[tokenOwner];
    }

    function allowance(address tokenOwner, address spender) public view override returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function approve(address spender, uint tokens) public override returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transfer(address to, uint tokens) public override returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        
        if (investors[msg.sender].hash != 0) {
            emit ChangeInRegistry(msg.sender, balances[msg.sender]);
        }
        if (investors[to].hash != 0) {
            emit ChangeInRegistry(to, balances[to]);
        }
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public override returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        
        if (investors[from].hash != 0) {
            emit ChangeInRegistry(from, balances[from]);
        }
        if (investors[to].hash != 0) {
            emit ChangeInRegistry(to, balances[to]);
        }
        return true;
    }
    
}