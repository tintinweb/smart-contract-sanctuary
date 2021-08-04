/**
 *Submitted for verification at BscScan.com on 2021-08-04
*/

pragma solidity ^0.8.0;

contract TankLottery {

event PlayUpdated(address indexed player, bool indexed isPlayed, uint256 indexed point, uint8  prizeId);

  function getTankFee() external view returns(uint256) {
    return 175000;
  }

  function getSafuFee() external view returns(uint256) {
    return 17500;
  }

  function getBUSDFee() external view returns(uint256) {
    return 5;
  }

  function play(uint8 mode) external {
    if (mode == 0) {
      
    } else if (mode == 1) {
      
    } else if (mode == 2) {
      
    } else {
      return;
    }
        emit PlayUpdated(msg.sender, false, 0, 0);

  }
  
  function receiveRandomness(address player, uint256 random) external {
    // require(msg.sender == address(rng));
    // require(plays[hash].isPlayed == false);
    uint8 prizeId;
    uint256 point = random % 1000;
    if (point == 999) {
      prizeId = 5;
    } else if (point > 989) {
      prizeId = 4;
    } else if (point > 939) {
      prizeId = 3;
    } else if (point > 739) {
      prizeId = 2;
    } else if (point > 39) {
      prizeId = 1;
    }

 
    emit PlayUpdated(player, true, point, prizeId);
  }
}