/**
 *Submitted for verification at BscScan.com on 2021-10-05
*/

pragma solidity 0.8.0;

contract hello{
      function random()public returns(uint256[] memory expandedValues){
       expandedValues = new uint256[](3);
    for (uint256 i = 0; i < 3; i++) {
        expandedValues[i] = uint256(keccak256(abi.encodePacked(block.timestamp,block.difficulty,msg.sender, i)))%100;
    }
    return expandedValues ;
  } 
}