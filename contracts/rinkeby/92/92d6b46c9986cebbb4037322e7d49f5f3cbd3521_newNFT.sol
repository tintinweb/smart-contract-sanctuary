//Abdullah Rangoonwala
pragma solidity 0.8.7;
 
import "./token.sol";
import "./ownable.sol";
import "./tokenMeta.sol";
 
contract newNFT is NFTokenMetadata, Ownable {
 
  constructor() {
    nftName = "Sjors NFT";
    nftSymbol = "SFT";
  }
 
  function mint(address _to, uint256 _tokenId, string calldata _uri) external onlyOwner {
    super._mint(_to, _tokenId);
    super._setTokenUri(_tokenId, _uri);
  }
 
}