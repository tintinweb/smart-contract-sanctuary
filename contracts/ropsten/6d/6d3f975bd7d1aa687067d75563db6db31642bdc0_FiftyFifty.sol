pragma solidity 0.4.24;

contract FiftyFifty {
    
    uint totalParticipants;
    uint constant betPrice = 1 ether; 

   
    
    function addMoney(uint) public payable {
        totalParticipants = totalParticipants + 1;
        
      
        
        if (msg.value != betPrice) { 
            throw;
        }
        
     
         /*   
        if (totalParticipants > 3) {
           
           if (ORACLIZE RIGHT HERE)
           selfdestruct(                      )
        }
        */
        
    
       
    }
    
    function checkParticipants() view public returns (uint) {
        return totalParticipants;
    }
    
        function checkBalance() view public returns (uint256) {
        address FUCK = msg.sender; 
        return FUCK.balance;
    }
    
 
    
    
    
}