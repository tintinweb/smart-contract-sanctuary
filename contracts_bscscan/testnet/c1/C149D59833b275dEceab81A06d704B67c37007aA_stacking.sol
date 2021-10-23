/**
 *Submitted for verification at BscScan.com on 2021-10-22
*/

pragma solidity >= 0.5.10;



contract stacking {


       struct emp {
            
            uint amount;
            uint reward;
            uint arraival;
            uint checkout; 
            
        }
        
        mapping (address => emp) public Data;
        
        function Emp(uint256 _amount) public {
            Data[msg.sender].amount = _amount;
            
            Data[msg.sender].arraival = now;
            
        }
         function checkout() public{
            
            Data[msg.sender].checkout =  (now-Data[msg.sender].arraival)/60;
            
            Data[msg.sender].reward = Data[msg.sender].amount*2;
            
        }

}