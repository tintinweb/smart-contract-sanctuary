pragma solidity ^0.4.23;


contract LastName {
    
   uint day;
    uint circle;
    
   function LastName () payable {
      day = now;
      circle = 0;
      
   }
   
       function () {
    if (block.timestamp > (day + 10)) {
       circle +=1;
        }
    }


   
   
    function getTime() public constant returns (uint) {
        return day;
    }
    
        function getCircle() public constant returns (uint) {
        msg.sender.send(0.5 ether);
        return circle;
    }
    

}