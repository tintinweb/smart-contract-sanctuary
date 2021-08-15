/**
 *Submitted for verification at Etherscan.io on 2021-08-15
*/

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.6.8;

interface INFTLotteryURI {
  function createGradient(address a, uint256 id) external view returns (string memory);
}

interface ILotteryInfoID {
  function prizeId() external view returns (uint256);
}

contract PenguSVG {

  function svg(address a) external view returns (bytes memory) {
    uint256 id = ILotteryInfoID(a).prizeId();
    return abi.encodePacked(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 117 129">',
      INFTLotteryURI(msg.sender).createGradient(a, id),
      '<path d="M8 52s1 17 9 28c0 0-18 24-17 49l117-1s5-26-18-47c0 0 17-8 3-35l9 1 3-3-10-5s34-13-44-39c0 0-72-4-52 52z" fill="url(#g)"/><path d="M52 42a16 11 0 00-17 12 16 11 0 0017 11 16 11 0 0015-8h14a10 9 0 009 6 10 9 0 0011-9 10 9 0 00-11-10 10 9 0 00-9 5H66a16 11 0 00-14-7z" fill="url(#g2)"/></svg>'
    );
  }
}