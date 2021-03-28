/**
 *Submitted for verification at Etherscan.io on 2021-03-28
*/

pragma solidity ^0.5.10;

interface IWET {
    function accumulated(uint256 id) external view returns (uint256);
}

contract Accoomulator {
  IWET WET = IWET(0x76280AF9D18a868a0aF3dcA95b57DDE816c1aaf2);

  function accoomulate(uint256[] calldata ids) external view returns (uint256[] memory) {
    uint256[] memory wetAccumulated = new uint256[](ids.length);
    for (uint256 i = 0; i < ids.length; i++) {
      wetAccumulated[i] = WET.accumulated(i);
    }
    return wetAccumulated;
  }
}