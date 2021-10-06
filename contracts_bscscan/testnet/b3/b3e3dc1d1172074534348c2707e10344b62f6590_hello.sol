/**
 *Submitted for verification at BscScan.com on 2021-10-06
*/

pragma solidity 0.8.0;
interface wah{
    function random(uint n) external view returns(uint256[] memory expandedValue);
}



contract hello is wah{
    event noo(uint[] nnnn);
      function random(uint n)public view override returns(uint256[] memory expandedValues){
       expandedValues = new uint256[](n);
    for (uint256 i = 0; i < n; i++) {
        expandedValues[i] = uint256(keccak256(abi.encodePacked(block.timestamp,block.difficulty,msg.sender, i)))%100;
    }
    return expandedValues ;
   // emit noo(expandedValues);
  }
   
}