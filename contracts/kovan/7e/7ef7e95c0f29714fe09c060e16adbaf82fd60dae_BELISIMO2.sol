/**
 *Submitted for verification at Etherscan.io on 2021-08-01
*/

//https://tut.by
pragma solidity ^0.5.0;


//  https://www.google.by/search?sa=G&hl=ru&tbs=simg:CAQSkgIJFlaULtX29YgahgILELCMpwgaOgo4CAQSFOcCnhaaPNIe5hKWONoh_1SHbGJARGho-uhvvcP0y2CJAij39yiDSQfwqUrZnvcJ9ZyAFMAQMCxCOrv4IGgoKCAgBEgSAg61zDAsQne3BCRqmAQooChVlYXN0ZXJuIGdyYXkgc3F1aXJyZWzapYj2AwsKCS9tLzAyNHFiMgohCg1hbmltYWwgZmlndXJl2qWI9gMMCgovbS8waDhtN2NzCh8KDGZveCBzcXVpcnJlbNqliPYDCwoJL20vMDZzOTA4ChkKB2RyYXdpbmfapYj2AwoKCC9tLzAyY3NmChsKCGNsaXAgYXJ02qWI9gMLCgkvbS8wM2cwOXQM&sxsrf=ALeKk03QyJnItNIo_76VLUPwMr3E8jUpKQ:1627840963800&q=%D0%BB%D0%B8%D1%81%D1%82%D0%BE%D0%B2%D0%BA%D0%B0+%D0%BD%D0%B0+%D1%82%D0%B5%D0%BC%D1%83+%D0%B1%D0%B5%D1%80%D0%B5%D0%B3%D0%B8%D1%82%D0%B5+%D0%BF%D1%80%D0%B8%D1%80%D0%BE%D0%B4%D1%83&tbm=isch&ved=2ahUKEwilj5eTtJDyAhWSOOwKHRJ3A-8Qwg4oAHoECAEQMQ
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
        require(b <= a); c = a - b; } function safeMul(uint a, uint b) public pure returns (uint c) { c = a * b; require(a == 0 || c / a == b); } function safeDiv(uint a, uint b) public pure returns (uint c) { require(b > 0);
        c = a / b;
    }
}


contract BELISIMO2  is ERC20Interface, SafeMath {
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
        name = "BELISIMO2";
        symbol = "BLSM2";
        decimals = 18;
        _totalSupply = 20000000000000000000000000;
       
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