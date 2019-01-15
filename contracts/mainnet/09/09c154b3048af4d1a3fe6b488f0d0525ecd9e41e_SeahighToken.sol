pragma solidity ^0.4.23;

library SafeMath {
    function add(uint a,uint b) internal pure returns(uint c){
        c = a + b;
        require(c>=a);
    }
    function sub(uint a,uint b) internal pure returns(uint c){
        require(b<=a);
        c = a - b;
    }
    function mul(uint a,uint b) internal pure returns(uint c){
        c = a * b;
        require (a ==0 || c / a ==b);
    }
    function div(uint a,uint b) internal pure returns(uint c){
        require(b>0);
        c = a / b;
    }
}

interface ERC20Interface{
    //总发行量
    function totalSupply() external returns(uint);
    //查询数量
    function balanceOf(address tokenOwner) external returns(uint balance);
    //查询授权数量
    function allowance(address tokenOwner,address spender) external returns(uint remaining);
    //转账
    function transfer(address to,uint tokens) external returns(bool success);
    //授权
    function approve(address spender,uint tokens) external returns(bool success);
    //授权转账
    function transferFrom(address from,address to,uint tokens) external returns(bool success);
    
    event Transfer(address indexed from,address indexed to,uint tokens);
    event Approval(address indexed tokenOwner,address indexed spender,uint tokens);
}

contract ContractRecevier{
    function tokenFallback(address _from,uint _value,bytes _data) public returns(bool ok);
}


interface ERC223{
    function transfer(address to,uint value,bytes data) public returns (bool ok);
    event Transfer(address indexed from,address indexed to,uint value,bytes indexed data);
}

contract Owned{
    address public owner;
    address public newOwner;
    
    event OwnershipTransferred(address indexed _from,address indexed _to);
    
    constructor() public{
        owner = msg.sender;
    }
    
    modifier onlyOwner {
        require (msg.sender == owner);
        _;
    }
    
    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public  {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner,newOwner);
        owner = newOwner ;
        newOwner = address(0);
    }
}


contract SeahighToken is ERC20Interface,ERC223,Owned {
    using SafeMath for uint;
    
    string public symbol;
    string public name;
    uint8 public decimals;
    uint _totalSupply;
    
    mapping(address => uint ) balances;
    mapping(address =>mapping(address =>uint)) allowed;
    
    constructor() public{
        symbol = "SEAH";
        name = "Seahigh Token";
        decimals = 18;
        _totalSupply = 100000000 * 10 **18;
        balances[owner] = _totalSupply;
        
        emit Transfer(address(0),owner,_totalSupply);
    }
    
    function isContract(address _addr)public view returns(bool is_contract){
        uint length;
        assembly{
            length := extcodesize(_addr)
        }
        return (length>0);
    }
    
    
    function totalSupply() public view returns(uint){
//        return _totalSupply;
          return _totalSupply.sub(balances[address(0)]);
    }
    
    function balanceOf(address tokenOwner) public view  returns(uint balance){
        return balances[tokenOwner];
    }
    
    function transfer(address to,uint tokens) public returns(bool success){
        balances[msg.sender] = balances[msg.sender].sub(tokens);
         balances[to] = balances[to].add(tokens);
         emit Transfer(msg.sender,to,tokens);
         return true;
         
    }
    
    function transfer(address to,uint value,bytes data) public returns(bool ok){
        if(isContract(to)){
         balances[msg.sender] = balances[msg.sender].sub(value);
         balances[to] = balances[to].add(value);
         ContractRecevier c = ContractRecevier(to);
         c.tokenFallback(msg.sender,value,data);
         emit Transfer(msg.sender,to,value,data);
         return true; 
        }
    }
    
    
    function approve(address spender, uint tokens) public returns (bool success){
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender,spender,tokens);
        return true;
    }
    
    function transferFrom(address from,address to,uint tokens) public returns(bool success){
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        
        balances[to] = balances[to].add(tokens);
        
        emit Transfer(from,to,tokens);
        return true;
    }
    
    function allowance(address tokenOwner,address spender) public view  returns(uint remaining){
        return allowed[tokenOwner][spender];
    }
}