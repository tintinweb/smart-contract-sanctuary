/**
 *Submitted for verification at BscScan.com on 2021-10-22
*/

pragma solidity >= 0.5.10;

   contract counter{
     
       
   mapping(address=>uint256)  private amount;
   
    function increaseValue(uint256 _value) public{
    amount[msg.sender]+=_value;
    
        }
        
    function decreaseValue(uint256 _value) public{
        require(_value<=amount[msg.sender],"Value is too large");
        amount[msg.sender]-=_value;
    } 
    
    
     function getAddress(address adds) public view returns (address, uint256,string memory)  {
         return (adds,amount[adds],"abc");
     }
    
    
    
    
   }