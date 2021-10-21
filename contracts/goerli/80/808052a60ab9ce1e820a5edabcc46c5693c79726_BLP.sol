// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./nf-token-metadata.sol";
import "./ownable.sol";

/**
 * @dev This is an example contract implementation of NFToken with metadata extension.
 */
contract BLP is
  NFTokenMetadata,
  Ownable
{

  /**
   * @dev Contract constructor. Sets metadata extension `name` and `symbol`.
   */
  constructor(
     string memory name,
     string memory symbol
  )
  {
    nftName = name;
    nftSymbol = symbol;
  }

  /**
   * @dev Mints a new NFT.
   * @param _to The address that will own the minted NFT.
   * @param _tokenId of the NFT to be minted by the msg.sender.
   * @param _uri String representing RFC 3986 URI.
   */
  function mint(
    address _to,
    uint256 _tokenId,
    uint256 _amount,
    string[] calldata _uri
  )
    public
  {
    for(uint i = 0; i<_amount; i++){
      super._mint(_to, _tokenId+i);
      super._setTokenUri(_tokenId+i, _uri[i]);
    }
    
  }

}