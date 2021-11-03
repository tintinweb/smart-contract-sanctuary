// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
interface NFTContract  {
  function uri(uint256 token_id) external returns (string memory);
}

contract UriExtractor {
    string res = "";
  function getUri(address nftContractAddress,uint256 token_id) public  {
     res = NFTContract(nftContractAddress).uri(token_id);
   
  }
  function gUri() public view returns (string memory) 
  { 
        return res;
  }
}