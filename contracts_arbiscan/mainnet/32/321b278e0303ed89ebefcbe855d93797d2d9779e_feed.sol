/**
 *Submitted for verification at arbiscan.io on 2021-09-22
*/

/**
*
*
* _______  _______  ______  _________ _______  _        _______  _______  ______  
*(  ___  )(  ____ )(  ___ \ \__   __/(  ____ \( (    /|(  ____ \(  ____ \(  __  \ 
*| (   ) || (    )|| (   ) )   ) (   | (    \/|  \  ( || (    \/| (    \/| (  \  )
*| (___) || (____)|| (__/ /    | |   | (_____ |   \ | || (__    | (__    | |   ) |
*|  ___  ||     __)|  __ (     | |   (_____  )| (\ \) ||  __)   |  __)   | |   | |
*| (   ) || (\ (   | (  \ \    | |         ) || | \   || (      | (      | |   ) |
*| )   ( || ) \ \__| )___) )___) (___/\____) || )  \  || (____/\| (____/\| (__/  )
*|/     \||/   \__/|/ \___/ \_______/\_______)|/    )_)(_______/(_______/(______/ 
*                                                                                
* 
* 
* 
* The sign is a subtle joke. The shop is called "Sneed's Feed & Seed", where feed and seed both end in the sound "-eed", 
* thus rhyming with the name of the owner, Sneed. The sign says that the shop was "Formerly Chuck's", 
* implying that the two words beginning with "F" and "S" would have ended with "-uck", rhyming with "Chuck". 
* So, when Chuck owned the shop, it would have been called "Chuck's Fuck and Suck".
* 
* 
*/




pragma solidity ^0.5.0;
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
contract feed is ERC20Interface, SafeMath {
    string public name;
    string public symbol;
    uint8 public decimals; 
    uint256 public _totalSupply;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    constructor() public {
        name = "Formerly";
        symbol = "SNEED";
        decimals = 18;
        _totalSupply = 1000000000000000000000000000;
        balances[msg.sender] = 1000000000000000000000000000;
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