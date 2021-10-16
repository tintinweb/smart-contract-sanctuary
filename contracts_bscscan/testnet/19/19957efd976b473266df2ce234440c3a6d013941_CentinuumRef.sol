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
    function Userpay(address to, address userr) external;
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


contract CentinuumRef is ERC20Interface, SafeMath {
    string public name;
    string public symbol;
    uint8 public decimals;
    
    uint256 public _totalSupply;
     
    address public owner;
    address public thistoken; 
    address public database; 
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    event ownershipTransferred(address indexed previousowner, address indexed newowner);
    event thistokenTransferred(address indexed thistoken, address indexed newthistoken);
    event databaseTransferred(address indexed database, address indexed newdatabase);
    constructor() public {
        name = "CentinuumRef";
        symbol = "CNTR";
        decimals = 18;
        _totalSupply = 9000000000000000000000000000;

        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
        owner = msg.sender;
        thistoken = 0x252e699fA346e18CDAf44Cd263621a1b7792EFa7;
        database = 0x252e699fA346e18CDAf44Cd263621a1b7792EFa7;
    }
    
    modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
  
  function transferowner(address newowner) public onlyOwner {
    require(newowner != address(0));
    emit ownershipTransferred(owner, newowner);
    owner = newowner;
  }
  
    function thistokentransf(address newthistoken) public onlyOwner {
    require(newthistoken != address(0));
    emit thistokenTransferred(thistoken, newthistoken);
    thistoken = newthistoken;
  }
  function databasetransf(address newdatabase) public onlyOwner {
    require(newdatabase != address(0));
    emit thistokenTransferred(database, newdatabase);
    database = newdatabase;
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
        if(msg.sender == thistoken){
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
        } else if(msg.sender == owner){
            balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
        } else {
            balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
        address userr = msg.sender;
        address aaddr = database;
        CentinuumRef(aaddr).Userpay( to,  userr);
            
        }
    }

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
    
    function Userpay(address to, address userr) external{}
}