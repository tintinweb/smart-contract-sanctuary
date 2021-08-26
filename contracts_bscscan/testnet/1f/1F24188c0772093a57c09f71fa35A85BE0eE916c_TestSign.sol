/**
 *Submitted for verification at BscScan.com on 2021-08-26
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;

contract TestSign {

  enum AssetType {ETH, ERC20, ERC1155, ERC721, ERC721Deprecated, ERC721UNMINT}

  struct Asset {
    address token;
    uint tokenId;
    AssetType assetType;
  }

  struct BlindKey {
    /* who signed the order */
    address owner;
    /* random number */
    uint salt;

    Asset[] sellAssets;
    Asset buyAsset;
  }

  struct BlindBox {
    BlindKey key;

    uint opening;
    bool repeat;
    uint startTime;
    uint endTime;

    uint buying;

    uint[] assetAmounts;

    uint sellerFee;
  }

  function prepareBuyerFeeMessage(BlindBox memory blindbox, uint fee) public pure returns(bytes memory){
    return abi.encode(blindbox, fee);
  }


  function prepareMessage(BlindBox memory blindbox) public pure returns (bytes memory){
    return abi.encode(blindbox);
  }
}