pragma solidity ^0.4.24;

interface ERC20{
function totalSupply() public constant returns (uint);
function balanceOf(address tokenOwner) public constant returns (uint balance);
function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
function transfer(address to, uint tokens) public returns (bool success);
function approve(address spender, uint tokens) public returns (bool success);
function transferFrom(address from, address to, uint tokens) public returns (bool success);
 event Transfer(address indexed from, address indexed to, uint tokens);
 event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    
}

contract myFirstToken is ERC20 {
    
string public name ;
string public symbol;
uint8 public decimals;


uint256 public _totalSypply;
address public _tokenOwner; 
uint256 public _AvlaibleSypply;
mapping (address => uint256) balances;
mapping (address => mapping(address => uint256)) allowed;

function myFirstToken(){
     name="my First Real Token";
 symbol = "MRF";
 decimals = 18;
 _totalSypply = 1000000;
  _tokenOwner= msg.sender;  // wallet id from which token will be intialized.
  balances[_tokenOwner] = _totalSypply;
  _AvlaibleSypply = 0;
}

function totalSupply() public constant returns (uint){
    return _totalSypply;
}
function balanceOf(address tokenOwner) public constant returns (uint balance){
    return balances[tokenOwner];
}
function allowance(address tokenOwner, address spender) public constant returns (uint remaining){
    return allowed[tokenOwner][spender];
}
function transfer(address to, uint tokens) public returns (bool success){
    balances[msg.sender] -= tokens;
    balances[to] += tokens;
    return true;
}
function approve(address spender, uint tokens) public returns (bool success){
    allowed[msg.sender][spender] = tokens;
    return true;
}
function transferFrom(address from, address to, uint tokens) public returns (bool success){
    
    balances[from] -= tokens;
    balances[to] += tokens;
    allowed[from][msg.sender] -= tokens;
    return true;

}

}