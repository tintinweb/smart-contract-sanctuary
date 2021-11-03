// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
interface NFTContract  {
  function uri(uint256 token_id) external returns (string memory);
}

contract UriExtractor {
  function getUri(address nftContractAddress,uint256 token_id) public returns (string memory) {
     string memory res = NFTContract(nftContractAddress).uri(token_id);
     return res;
  }
}