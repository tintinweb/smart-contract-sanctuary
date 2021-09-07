/**
 *Submitted for verification at BscScan.com on 2021-09-06
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.7.0;

contract Test {
    
    uint256[] public levelBase = [0.05 ether, 0.06 ether, 0.08 ether];
    
    function getLevelInfo(uint256 levelID) public view returns(uint256, uint256){
      levelID--;
      require(levelID < 21 * 3, '!levelID');
      uint256 level = levelID % 3;
      uint256 round = (levelID - level) / 3;
      return(round, level);
    }
    
    function lvlAmount (uint256 levelID) public view returns(uint256) {
      (uint256 round, uint256 level) = getLevelInfo(levelID);
      uint256 price = (levelBase[level] * (round + 1)**2);
      return price;
    }
    
}