pragma solidity ^0.4.23;
contract safeMath {
    function safeAdd(uint a, uint b) pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) pure returns (uint c) {
        require(a==b*c+a%b);
        c = a / b;
    }
}
contract ERC20Interface{
    function totalSupply() public constant returns(uint);
    function balanceOf(address tokenOwner) public constant returns(uint balance);
    function allowance(address tokenOwner,address spender) public constant returns(uint remaining);
    function transfer(address to,uint tokens) public returns(bool success);
    function approve(address from,uint tokens) public returns(bool success);
    function transferFrom(address from,address to,uint tokens) public returns(bool success);
    event Transfer(address indexed from,address indexed to,uint tokens);
    event Approval(address indexed tokenOwner,address indexed spender,uint tokens);
}

contract Owned{
    address public owner;
    address public newOwner;
    event OwnershipTransferred(address indexed _from,address indexed _to);
    function Owned() public{
        owner=msg.sender;
    }
    modifier onlyOwner{
        require(owner==msg.sender);
        _;
    }
    function transferOwnership(address _newOwner) public onlyOwner{
        newOwner = _newOwner;
    }
    function acceptOwnership() public{
        require(newOwner==msg.sender);
        OwnershipTransferred(owner,newOwner);
        owner=newOwner;
        newOwner=address(0);
    }
}
contract BGtoken is ERC20Interface,Owned,safeMath{
    string public symbol;
    string public name;
    uint8 public decimals;
    uint public _totalsupply;
    mapping(address=>uint) balances;
    mapping(address=>mapping(address=>uint)) allowed;
    function BGtoken() public{
        symbol = "orange";
        name = "BG";
        decimals = 10;
        _totalsupply = 24000000*10**10;
        balances[owner] = _totalsupply;
        Transfer(address(0),owner,_totalsupply);
    }
   function totalSupply() public constant returns(uint){
       return _totalsupply-balances[address(0)];
   }
   function balanceOf(address tokenOwner) public constant returns(uint balance){
       return balances[tokenOwner];
   }
   function transfer(address to,uint tokens) public returns(bool success){
       balances[msg.sender]= safeSub(balances[msg.sender],tokens);
       balances[to]=safeAdd(balances[to],tokens);
       emit Transfer(msg.sender,to,tokens);
       return true;
   }
    function approve(address spender,uint tokens) public returns(bool success){
        allowed[msg.sender][spender]=tokens;
        emit Approval(msg.sender,spender,tokens);
        return true;
    }
   function transferFrom(address from,address to,uint tokens)public returns(bool success){
       balances[from]=safeSub(balances[from],tokens);
       allowed[from][msg.sender]=safeSub(allowed[from][msg.sender],tokens);
       balances[to]=safeAdd(balances[to],tokens);
       Transfer(from,to,tokens);
       return true;
   }
    function allowance(address tokenOwner,address spender) public constant returns(uint remaining){
        return allowed[tokenOwner][spender];
    }
}