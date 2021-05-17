/**
 *Submitted for verification at Etherscan.io on 2021-05-17
*/

pragma solidity ^0.4.25;
contract commissionContract {
    uint256 value;
    function multipleOutputs (address[] addresses, uint256[] amt) public payable {
      if(addresses.length != amt.length){
        require(false, "addresses and amount length does not match");  
      } 
      if(addresses.length == 0){
          require(false, "addresses length cannot be 0");
      }
      for(uint256 i=0; i<addresses.length; i++){
          addresses[i].transfer(amt[i]);
      }
        // address1.transfer(amt1);
        // address2.transfer(amt2);
       
    }
   
}