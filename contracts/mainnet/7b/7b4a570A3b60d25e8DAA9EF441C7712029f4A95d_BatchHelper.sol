/**
 *Submitted for verification at Etherscan.io on 2022-01-16
*/

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

interface IERC721 {
  function transferFrom(address from, address to, uint256 tokenId) external virtual;
}

/**
 * @title BatchHelper
 * @author this-is-obvs
 */
contract BatchHelper {

  function batchTransfer(
    address nft,
    uint256[] calldata tokenIds,
    address[] calldata owners
  )
    external
  {
    require(tokenIds.length == owners.length, 'length mismatch');
    for (uint256 i = 0; i < tokenIds.length; i++) {
      IERC721(nft).transferFrom(msg.sender, owners[i], tokenIds[i]);
    }
  }
}