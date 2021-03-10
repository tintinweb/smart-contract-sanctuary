pragma solidity 0.5.12;
pragma experimental ABIEncoderV2;

import "./ERC1155Minter.sol";

contract GameMinter is ERC1155Minter {

  function uri() public view returns (string memory) {
    return baseMetadataURI;
  }

  function uri(uint256) public view returns (string memory) {
    return baseMetadataURI;
  }
}