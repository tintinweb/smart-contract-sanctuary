/**
 *Submitted for verification at Etherscan.io on 2021-04-15
*/

// File: ../contracts/testing/MockNFT.sol

// SPDX-License-Identifier: MIT

pragma solidity 0.7.5;
pragma abicoder v2;

contract MockNFT {
  event LogNftLifted(address indexed minterT1Address, bytes32 indexed t2OwnerPublicKey, bytes32 indexed externalReferenceHash);
  event LogNftTransferred(bytes32 indexed currentT2ownerPublicKey, bytes32 indexed newT2OwnerPublicKey, bytes32 indexed nftId, uint256 transferNonce, bytes currentOwnerProof);
  event LogNftTest(
    bytes32 indexed nftId,
    bytes32 indexed currentT2ownerPublicKey,
    bytes32 indexed externalReferenceHash,
    uint256 tokenTypeId,
    RoyaltyConfig[] royaltyRates,
    uint256 transferNonce
  );

 struct RoyaltyConfig {
    address recipient;
    uint256 percentage;
  }

  function emitLiftNftEvent(address minterT1Address, bytes32 t2OwnerPublicKey, bytes32 externalReferenceHash)
    external
  {
    emit LogNftLifted(minterT1Address, t2OwnerPublicKey, externalReferenceHash);
  }

  function emitTransferNftEvent(bytes32 currentT2ownerPublicKey, bytes32 newT2OwnerPublicKey, bytes32 nftId, uint256 transferNonce, bytes memory currentOwnerProof)
    external
  {
    emit LogNftTransferred(currentT2ownerPublicKey, newT2OwnerPublicKey, nftId, transferNonce, currentOwnerProof);
  }

  function emitTestEvent(
    bytes32 nftId,
    bytes32 currentT2ownerPublicKey,
    bytes32 externalReferenceHash,
    uint256 tokenTypeId,
    RoyaltyConfig[] memory royaltyRates,
    uint256 transferNonce)
    external
  {
    emit LogNftTest(
      nftId,
      currentT2ownerPublicKey,
      externalReferenceHash,
      tokenTypeId,
      royaltyRates,
      transferNonce);
  }

}