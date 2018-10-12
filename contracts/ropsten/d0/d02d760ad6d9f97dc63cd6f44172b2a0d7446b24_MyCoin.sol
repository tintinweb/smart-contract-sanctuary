pragma solidity ^0.4.13;

contract MyCoin {
    
    string public name = "Software HSE Coin";
    
    string public symbol = "HSESFW";
    uint public decimals = 10^18;
    
    uint public totalSuply;
    
    mapping(address=>uint) ballances;
    
    address public owner;
    

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    
    function MyCoin(){
        owner = msg.sender;
    }
    
    function mint(address _investor, uint amount) onlyOwner {
        
        ballances[_investor] += amount * decimals;
        totalSuply += amount * decimals;
        
        
    }
    
     function buy() payable {
        
        ballances[msg.sender] += msg.value ;
        totalSuply += msg.value;
        
    }
    
    function transfer ( address _to, uint amount){
            
        require(ballances[msg.sender] >= amount);
        
        ballances[_to] += amount;
        ballances[msg.sender] -= amount;
        
    }
    
    
    
    

    
   

}