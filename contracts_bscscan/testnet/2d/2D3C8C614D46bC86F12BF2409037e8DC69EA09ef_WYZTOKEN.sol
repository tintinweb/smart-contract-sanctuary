/**
 *Submitted for verification at BscScan.com on 2021-09-15
*/

pragma solidity ^0.5.10;

interface IWYZTOKEN {
function totalSupply() external view returns(uint256);
function balanceOf(address owner) external view returns(uint256);
function transfer(address reciever, uint256 amount) external returns(bool);
function transferFrom(address from, address to,uint amount) external returns (bool);
function mint(uint256 _qty) external returns(uint256);
function burn(uint256 _quty) external returns(uint256);
function allowance(address _owner,address _spender) external view returns(uint256 remaining);
function approve(address _spender, uint256 amount) external returns(bool success);
}
contract WYZTOKEN{
    
    
    
    address internal  admin;
    string public constant name = "WYZ";
    string public constant symbol = "WYZ";
    uint256 public constant decimals = 18;
    uint256 public  totalSupply_ = 1000000000000000000000000;
    
    constructor() public{
        admin=msg.sender;
        balances[msg.sender] = totalSupply_;
        
    }
    
    
    event Approval(address indexed owner,address indexed spender,uint256 amount);
    event Transfer(address indexed from,address indexed to,uint256 amount);
     
     
    mapping (address => uint256) balances;
    mapping (address => mapping(address =>uint256)) allowed;
    
    
    modifier onlyAdmin(){
    require(address(msg.sender)==admin);    
        
        _;
        
    }
    
    
    
    
    function totalSupply() public view returns(uint256){
        return (totalSupply_);
    }
   
    
    function balanceOf(address owner) public view returns(uint256){
        
        return balances[owner];
    }
    
    function transfer(address reciever, uint256 amount) public returns(bool){
    require(amount <= balances[msg.sender]);    
    balances[msg.sender]= balances[msg.sender]-amount;
    balances[reciever]= balances[reciever]+amount;
    emit Transfer(msg.sender,reciever,amount);
    return true;
    }
    
    function transferFrom(address from, address to,uint amount) public returns (bool){
        
    require(allowed[from][to]>=amount,"Approve First");
    require(amount <= balances[from]); 
    balances[from]= balances[from]-amount;
    balances[to]= balances[to]+amount;
    allowed[from][to]=0;
    emit Transfer(from,to,amount);
    return true;
        
    }
    
    
    
    function mint(uint256 _qty) public onlyAdmin returns(uint256){
     totalSupply_ = totalSupply_ + _qty ;
     balances[msg.sender] += _qty; 
     return totalSupply_;
    }
    
    
    
    function burn(uint256 _quty) public onlyAdmin returns(uint256){
    require(balances[msg.sender]>=_quty);
     totalSupply_ = totalSupply_ - _quty ;
     balances[msg.sender] -= _quty; 
     return totalSupply_;
    }
    
    
    
    function allowance(address _owner,address _spender) public view returns(uint256 remaining){
     return allowed[_owner][_spender];   
    }
    
    function approve(address _spender, uint256 amount) public  returns(bool success){
    allowed[msg.sender][_spender]=amount;    
    emit Approval(msg.sender,_spender,amount);
    return true;
    }
}