/**
 *Submitted for verification at Etherscan.io on 2021-05-17
*/

pragma solidity ^0.8.4;
contract commissionContract {
   
    function multipleOutputs (address[] memory addresses, uint256[] memory amt) public payable {
      
      for(uint256 i=0; i<addresses.length; i++){
          payable(addresses[i]).transfer(amt[i]);
      }
        // address1.transfer(amt1);
        // address2.transfer(amt2);
       
    }
   
}