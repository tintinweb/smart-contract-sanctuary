pragma solidity 0.8.0;

import "./nf-token-metadata.sol";
import "./ownable.sol";

/**
 * @dev This is an example contract implementation of NFToken with metadata extension.
 */
contract MyArtSale is
  NFTokenMetadata,
  Ownable
{

  /**
   * @dev Contract constructor. Sets metadata extension `name` and `symbol`.
   */
  constructor()
  {
    nftName = "LaoCai's Art Sale";
    nftSymbol = "LCAS";
  }

  uint256 constant MAX_INT_FROM_BYTE = 256;
  uint256 constant NUM_RANDOM_BYTES_REQUESTED = 7;    
  /**
   * @dev Mints a new NFT.
   * @param _to The address that will own the minted NFT.
   * @param _tokenId of the NFT to be minted by the msg.sender.
   * @param _uri String representing RFC 3986 URI.
   */
  function mint(
    address _to,
    uint256 _tokenId,
    string calldata _uri
  )
    external
    onlyOwner
  {
    super._mint(_to, _tokenId);
    super._setTokenUri(_tokenId, _uri);
  }
  
  function MintNewArts(string calldata _uri) external payable{
      require(msg.value==0.001 ether);
      uint256 ceiling = (MAX_INT_FROM_BYTE ** NUM_RANDOM_BYTES_REQUESTED) - 1;
      uint256 tokenId=uint256(keccak256(abi.encodePacked(_uri))) % ceiling;
      super._mint(msg.sender,tokenId);
      super._setTokenUri(tokenId,_uri);
  }

}