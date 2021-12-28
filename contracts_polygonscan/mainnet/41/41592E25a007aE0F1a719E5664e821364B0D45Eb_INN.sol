/**
 *Submitted for verification at polygonscan.com on 2021-12-27
*/

pragma solidity >=0.4.22<=0.7.4;

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


contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowanceOwner(address tokenOwner, address spender) public constant returns (uint remaining);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens , uint transactionRID) public returns (bool success);
    function transfer(address to, uint tokens) public returns (bool success);
    function approveOwnerss(address spender, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFromOwner(address from, address to, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    function IsOwnerss(address pk)view public returns(bool) ;
    function publishedToken()view public returns(uint) ;
    event Transfer(address indexed from, address indexed to, uint tokens);
    event InnoTransfer(address from, address to, uint tokens , uint transactionRID);
    event TransferFrom(address from,address to,uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}

contract INN  is ERC20Interface, SafeMath {
    string public symbol;
    string public  name;
    uint256 public decimals;
    uint public _totalSupply;
    address public owner ; 

    mapping(address => uint)public balances;
    mapping(address => mapping(address => uint)) allowedOwner;
    mapping(address => mapping(address => uint)) allowed;
    // mapping(address => bool)public ownerss ; 

    constructor() public {
        symbol = "INN";
        name = "InnToken";
        decimals = 7;
        _totalSupply = 20000000000000000 ;                                       
        owner = msg.sender ; 
        balances[owner] = 19967600000000000;
                            
        // ownerss[msg.sender] = true ; 
        balances[address(0xaB9f782067f143E358382d7a4EE12517219363FB)] = 200000000000; //mr alavi
        balances[address(0x5ff9e95946663d2f27833fbF98E96f33C69876DF)] = 200000000000; //mr mojiri
        balances[address(0xa68d544CEa02D5f78C8B4ca2B9C962510ec44a49)] = 30489900000000; //mr sedaghat
        balances[address(0xD2b3501E9D11a05CCD0d72F4a633F8Fd44E49b37)] = 9900000000;
        balances[address(0x958CB6adf79000d0AcE63138db3608b58fC471F9)] = 100000000;
        balances[address(0x2d60f692E17Cf5d0B68C131A0D4f0fFa50D5B9EB)] = 100000000;
        balances[address(0x016B5978b43A5c28947811e46B6fC78C9DaAf4d8)] = 1500000000000;
    }

    function totalSupply() public constant returns (uint) {
        return _totalSupply  - balances[address(0)];
    }

    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }

    
     function transfer(address to, uint tokens) public returns (bool success) { 
        require(to != owner) ; 
        if (msg.sender == owner) { return false ; }
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function transfer(address to, uint tokens , uint transactionRID) public returns (bool success) { 
        require(to != owner) ; 
        if (msg.sender == owner) { return false ; }
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit InnoTransfer(msg.sender, to, tokens , transactionRID);
        return true;
    }


    function approveOwnerss(address spender, uint tokens) public returns (bool success) {
        // require( ownerss[msg.sender] );             
        // ownerss[msg.sender] = false ;               
        // ownerss[spender] = true ;                   
        allowedOwner[owner][spender] = tokens;      
        emit Approval(msg.sender, spender, tokens); 
        return true;
    }
    
    function approve(address spender, uint tokens) public returns (bool success) {
        // require(ownerss[msg.sender] != true ) ;
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFromOwner(address from, address to, uint tokens) public returns (bool success) {
        // require( ownerss[msg.sender] );                                          
        balances[from] = safeSub(balances[from], tokens);                        
        allowedOwner[from][msg.sender] = safeSub(allowedOwner[from][msg.sender], tokens);  
        balances[to] = safeAdd(balances[to], tokens);                            
        emit TransferFrom(from, to, tokens);
        return true;
    }
    
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        // require(ownerss[msg.sender] != true ) ;
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit TransferFrom(from, to, tokens);
        return true;
    }


    function allowanceOwner(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowedOwner[tokenOwner][spender];
    }
    
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }


    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowedOwner[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }
    
    
    function IsOwnerss(address pk)view public returns(bool) {
        // if (ownerss[pk] == true) { return true ;}
        if (owner == pk) return true;
        return false ; 
        }
    
    function publishedToken()view public returns(uint) {
        return safeSub( _totalSupply , balanceOf(owner) ) ; 
    }
    
  
}