/**
 *Submitted for verification at Etherscan.io on 2021-08-25
*/

// SPDX-License-Identifier: UNLICENCED

pragma solidity ^0.8.4;

interface IERC721 {

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

contract MultiSenderERC721 {

   function send(address _token, address _to, uint256[] calldata _tokenIds) external {
      require(_token != address(0), "EMPTY_TOKEN");
      require(_to != address(0), "EMPTY_TO");
      require(_tokenIds.length > 0, "EMPTY_TOKEN_IDS");
      require(IERC721(_token).isApprovedForAll(msg.sender, address(this)), "NOT_APPROVED_FOR_ALL");

      uint numberOfTokens = _tokenIds.length;
      for (uint256 i = 0; i < numberOfTokens; i++) {
          uint256 tokenId = _tokenIds[i];
          IERC721(_token).safeTransferFrom(msg.sender, _to, tokenId);
          assert(IERC721(_token).ownerOf(tokenId) == _to);
      }
   }
}