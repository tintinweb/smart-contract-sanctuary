/**
 *Submitted for verification at BscScan.com on 2021-09-13
*/

pragma solidity ^0.8.6;
contract ArrayOfBytes32 {
    struct myStruct {
      address foo;
      uint256 bar;
    }
    myStruct[] public myStructs;
    
    function getMyStruct() public view returns(myStruct[] memory) {
      return myStructs;
    }
}