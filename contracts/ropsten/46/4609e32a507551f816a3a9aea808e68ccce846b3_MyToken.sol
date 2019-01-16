pragma solidity ^0.4.25;

pragma solidity ^0.4.25;
interface ERC20 {
    function totalSupply() external constant returns (uint _totalSupply);
    function balanceOf(address _owner) external constant returns (uint balance);
    function transfer(address to, uint value) external returns (bool success);
    function transferFrom(address from, address to, uint _value) external returns (bool success);
    function approve(address spender, uint value) external returns (bool success);
    function allowance(address owner, address spender) external constant returns (uint remaining);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

}

contract MyToken is ERC20{
    
    string public constant name = "My First Token";
    uint public constant decimal = 18;
    string public constant symbol = "Token";
    
    uint private constant finalsupply = 1000000000000000000;
    mapping (address => uint) private finaladdressof;
    mapping (address => mapping(address => uint)) private finalallowance;
    
    constructor() public{
        finaladdressof[msg.sender]=finalsupply;
    }
    
     function totalSupply()external constant returns (uint theTotalSupply){
         theTotalSupply = finalsupply;
     }
    
    function balanceOf(address owner)public view returns (uint balance){
        return finaladdressof[owner];
    }
    
    function transfer(address to, uint value)external returns (bool success){
        if(value>0 && value<=balanceOf(msg.sender)){
         finaladdressof[msg.sender] -= value;
         finaladdressof[to] += value;
         return true;
        }
        return false;
    }
    
    function transferFrom(address from, address to, uint value)public returns (bool success){
     
       if (
        finalallowance[from][msg.sender] > 0 &&
        value > 0 &&
        finalallowance[from][msg.sender] >= value 
        && 
        finaladdressof[from] >= value
            ) {
            finaladdressof[from] -= value;
            finaladdressof[to] += value;
        
            // finalallowance[_from][msg.sender] -= _value;
            return true;
         }
         return false;
    }
    
     function approve(address spender, uint value)public returns (bool success){
        finalallowance[msg.sender][spender] = value;
        return true;
     }
     
   function allowance(address owner, address spender)public constant returns (uint remaining){
       return finalallowance[owner][spender];
   }
}