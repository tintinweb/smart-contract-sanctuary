/**
 *Submitted for verification at Etherscan.io on 2021-05-05
*/

pragma solidity ^0.5.11;

contract A  {
    
   address addressB;
   
   function setAddressB(address _addressB) external {
       addressB = _addressB;
   }
   
   function callHelloWorld() external view returns(string memory) {
       
       B b = B(addressB);
      return b.helloWorld();
   }
    
}

contract B {
      function helloWorld() external pure returns(string memory){
       return 'Hello World';
   }
}