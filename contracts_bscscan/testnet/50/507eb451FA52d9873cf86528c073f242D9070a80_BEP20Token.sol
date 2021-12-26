/**
 *Submitted for verification at BscScan.com on 2021-12-26
*/

// SPDX-License-Identifier: MIT




pragma solidity ^0.8.9;  // latest version

interface IBEP20 {
    function totalSupply() external view returns (uint256); 

    function balanceOf(address tokenOwner)
        external
        view
        returns (uint256 balance);

    function allowance(address tokenOwner, address spender)
        external
        view
        returns (uint256 remaining);

    function transfer(address to, uint256 tokens) external returns (bool success);

    function approve(address spender, uint256 tokens)
        external
        returns (bool success);

    function transferFrom(
        address from,
        address to,
        uint256 tokens
    ) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(
        address indexed tokenOwner,
        address indexed spender,
        uint256 tokens
    );
}

// ----------------------------------------------------------------------------
// Safe Math Library
// ----------------------------------------------------------------------------
contract SafeMath {
    function safeAdd(uint256 a, uint256 b) public pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
    }

    function safeSub(uint256 a, uint256 b) public pure returns (uint256 c) {
        require(b <= a);
        c = a - b;
    }

    function safeMul(uint256 a, uint256 b) public pure returns (uint256 c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }

    function safeDiv(uint256 a, uint256 b) public pure returns (uint256 c) {
        require(b > 0);
        c = a / b;
    }
}

contract BEP20Token is IBEP20, SafeMath {
    string public name;
    string public symbol;
    uint8 public decimals; // 18 decimals

    uint256 public _totalSupply;
    address public _owner;
    address public _admin;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    constructor() {
        name = "Test USD";
        symbol = "USDT23";
        decimals = 18;
        _totalSupply = 70140 * 10**18;

        _admin = 0xC9617eEafe8175FeE75123c483c20c2bAc236301; // admin account
        
        //_owner = msg.sender; // a record of the contract owner's address
        _owner = _admin;

        //balances[msg.sender] = _totalSupply;
        balances[_admin] = _totalSupply;

        //emit Transfer(address(0), msg.sender, _totalSupply);
        emit Transfer(address(0), _admin, _totalSupply);
    }

    modifier onlyOwner() {
        // modifier - owner verification
        require(_owner == msg.sender, "BEP20: caller is not the owner");
        _;
    }

    function owner() public view returns (address) {
        return _owner;  // returns the address of the contract owner
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply - balances[address(0)];
    }


    /*
    "balanceOf" function - returns the number of tokens belonging to the address (account).
    
    "tokenOwner" - token owner
    */
    function balanceOf(address tokenOwner)
        public
        view
        override
        returns (uint256 balance)
    {
        return balances[tokenOwner];
    }

    /*
    "allowance" function - The ERC-20 standard allows an address to give permission 
    to another address to receive tokens from it. This getter returns the remaining number 
    of tokens that are allowed to be spent on behalf of the owner. This function is a getter
    and does not change the state of the contract
    
    "tokenOwner" - token owner
    "spender" - spender of tokens
    */
    function allowance(address tokenOwner, address spender)
        public
        view
        override
        returns (uint256 remaining)
    {
        return allowed[tokenOwner][spender];
    }

    /*
    "approve" function - sets the amount of allowance that is allowed 
    to be transferred from the balance of function caller
    
    "spender" - spender
    "tokens" - amount of tokens
    */
    function approve(address spender, uint256 tokens)
        public
        override
        returns (bool success)
    {
        allowed[msg.sender][spender] = tokens;

        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    /*
    "transfer" function - moves tokens from the account 
    of one user that called the function to another account
    
    "to" - to where to transfer tokens
    "tokens" - amount of tokens
    */
    function transfer(address to, uint256 tokens)
        public
        override
        returns (bool success)
    {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
 
    /*
    "transferFrom" function - moves tokens from certain account 
    of one account that was given into the function to another 
    
    "from" - from where to transfer tokens
    "to" - to where to transfer tokens
    "tokens" - amount of tokens
    */
    function transferFrom( 
        address from,
        address to,
        uint256 tokens
    ) public override returns (bool success) {

        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);

        emit Transfer(from, to, tokens);
        return true;
    }

    /* 
    "burn" function (only owner) - function for reduction
    amount of total supply
    
    This function can only be called by contract owner,
    "onlyOwner()" - this will be secured by this modifer

    "_value" - amount of tokens to be burned
    */
    function burn(uint256 _value) public onlyOwner returns (bool success) {
        require(_value <= balances[msg.sender], "ERC20: small balances");

        balances[msg.sender] = balances[msg.sender] - _value;
        _totalSupply = _totalSupply - _value;

        emit Transfer(msg.sender, address(0), _value);
        return true;
    }

    /* 
    "expand" function (only owner) - function for adding
    more tokens in total supply
    
    This function can only be called by contract owner,
    "onlyOwner()" - this will be secured by this modifer

    "_value" - amount of tokens to be add
    */
    function expand(uint256 _value) public onlyOwner returns (bool success) {
        

        balances[msg.sender] = balances[msg.sender] + _value;
        _totalSupply = _totalSupply + _value;

        emit Transfer(msg.sender, address(0), _value);
        return true;
    }
}