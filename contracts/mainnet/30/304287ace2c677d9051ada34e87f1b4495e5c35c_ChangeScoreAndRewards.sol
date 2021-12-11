/**
 *Submitted for verification at Etherscan.io on 2021-12-11
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

interface IEthemerals {
  function changeRewards(uint _tokenId, uint32 offset, bool add, uint8 action) external;
  function changeScore(uint _tokenId, uint16 offset, bool add, uint32 amount) external;
}

contract ChangeScoreAndRewards {

  address private admin;
  IEthemerals private coreContract;

  constructor(address _ethemeralsAddress) {
    admin = msg.sender;
    coreContract = IEthemerals(_ethemeralsAddress);
  }

  function changeRewards(uint256[] memory tokenIndices, uint32 offset, bool add, uint8 action) external {// ADMIN
    require(msg.sender == admin, 'no');
    for (uint i = 0; i < tokenIndices.length; i++) {
      coreContract.changeRewards(tokenIndices[i], offset, add, action);
    }
  }

  function changeScore(uint256[] memory tokenIndices, uint16 offset, bool add, uint32 amount) external {// ADMIN
    require(msg.sender == admin, 'no');
    for (uint i = 0; i < tokenIndices.length; i++) {
      coreContract.changeScore(tokenIndices[i], offset, add, amount);
    }
  }


}