/**
 *Submitted for verification at Etherscan.io on 2021-05-26
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

/**
 * @dev Just testing events
 *
 */
contract test_events {

    event Mix(uint256 indexed tokenId1, uint256 indexed tokenId2, uint256 indexed tokenId3);
    event NewBaseMixingFee(address indexed owner, uint256 indexed newFee);
    event NewTokenMixingFee(uint256 indexed tokenId, uint256 indexed newFee);
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);


    function gift(address to, uint256 tokenId) public {
      emit Transfer(address(0), to, tokenId);
    }

    function transferToken(address from, address to, uint256 tokenId) public {
      emit Transfer(from, to, tokenId);
    }

    function mix(address to, uint256 tokenId1, uint256 tokenId2, uint256 tokenId3) public {
      uint256 tokenId = tokenId1+tokenId2+tokenId3;
      emit Transfer(address(0), to, tokenId);
      emit Mix(tokenId1, tokenId2, tokenId3);
    }

    function setBaseMixingFee(address from, uint256 fee) external {
      emit NewBaseMixingFee(from, fee);
    }

    function setSpecificMixingFee(uint256 tokenId, uint256 fee) external {
      emit NewTokenMixingFee(tokenId, fee);
    }
}