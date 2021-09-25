pragma solidity 0.8.6;
import "./nf-token-metadata.sol";
import "./ownable.sol";
contract NFT721 is NFTokenMetadata, Ownable {
  constructor () {
    nftName = "Corona Virus 2019";
    nftSymbol = "COVID";
  }
  function mint(address _to, uint256 _tokenId, string calldata _uri) external onlyOwner {
    super._mint(_to, _tokenId);
    super._setTokenUri(_tokenId, _uri);
  }
}