pragma solidity ^0.4.18;


contract Dragon {
    
    function transfer(address receiver, uint amount)returns(bool ok);
    function balanceOf( address _address )returns(uint256);

    
}



contract DragonLock {
    
  
  
    Dragon public tokenreward; 
    
    
   
   
    
    uint public TimeLock;
    address public receiver;
 
    
    
  
    
    function DragonLock (){
        
        tokenreward = Dragon (  0x814f67fa286f7572b041d041b1d99b432c9155ee ); // dragon token address
        
        TimeLock = now + 90 days;
       
        receiver = 0x2b29397aEC174A52bff15225efbb5311c7d63b38; // Receiver address change
        
      
        
    }
    
    
    //allows token holders to withdar their dragons after timelock expires
    function withdrawDragons(){
        
        require ( now > TimeLock );
        require ( receiver == msg.sender );
      
       
        tokenreward.transfer ( msg.sender , tokenreward.balanceOf (this)  );
        
    }
    
    

}