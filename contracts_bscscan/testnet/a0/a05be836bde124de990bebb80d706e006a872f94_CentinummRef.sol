/**
 *Submitted for verification at BscScan.com on 2021-10-16
*/

pragma solidity ^0.4.25;


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


contract CentinummRef is ERC20Interface, SafeMath {
    struct User{
        address dis1;
        address dis2;
        address dis3;
        address dis4;
        address dis5;
    }
    
    string public name;
    string public symbol;
    uint8 public decimals;

    uint256 public _totalSupply;
    mapping(address => User) public users;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    constructor() public {
        name = "CentinummRef";
        symbol = "CTNR";
        decimals = 1;
        _totalSupply = 8000000000;

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
        balances[to] = safeAdd(balances[to], tokens/10); 
        emit Transfer(msg.sender, to, tokens);
        return true;
        
        User memory newUser;
        address sender = to;
        address dis1 = msg.sender;
        address dis2 = users[dis1].dis1;
        address dis3 = users[dis2].dis1;
        address dis4 = users[dis3].dis1;
        address dis5 = users[dis4].dis1;
        
        
        newUser.dis1 = dis1;
        newUser.dis2 = dis2;
        newUser.dis3 = dis3;
        newUser.dis4 = dis4;
        newUser.dis5 = dis5;
        users[sender] = newUser;
        
       
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