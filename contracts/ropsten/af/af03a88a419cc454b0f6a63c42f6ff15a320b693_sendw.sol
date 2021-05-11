/**
 *Submitted for verification at Etherscan.io on 2021-05-11
*/

pragma solidity >=0.8;



contract sendw {
    

   function arraySend(address payable[] memory  _receivers, uint[] memory _amounts) public payable {
       for(uint i = 0; i< _receivers.length; i++) {
           _receivers[i].transfer(_amounts[i]);
       }
   }
    
    
}