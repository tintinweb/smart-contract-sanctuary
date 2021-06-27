/**
 *Submitted for verification at Etherscan.io on 2021-06-27
*/

pragma solidity ^0.8.0;

contract Payable {

    address payable public owner;
    uint Blkhour;
    uint DataHourCreate;


    constructor(uint blockingDays) payable {
        owner = payable(msg.sender);
        Blkhour=blockingDays;
        DataHourCreate=block.timestamp/60;
    }

   
    function deposit() public payable {
    }

  
  function DaysLeft()private view returns (uint)
  {
      uint _hours = (DataHourCreate+Blkhour)-block.timestamp/60;
      
      if(_hours<=Blkhour)
      {
          return _hours;
      }
      else
      {
          return 0; 
      }
     
  }
  


    function withdraw() public {
        
        if(DaysLeft()==0)
        {
         uint amount = address(this).balance;

        (bool success,) = owner.call{value: amount}("");
        require(success, "Failed to send Ether");
            
        }
       else
       {
           require(false, "Blocking time has not passed");
           
       }
    }


   
    function GetBalance()public view returns (uint){
        return address(this).balance;        
    }
    
    function DaysCheck() public view returns(uint){

    return DaysLeft();

    } 
    
}