//Abdullah Rangoonwala
pragma solidity 0.8.7;
 
import "./token.sol";
import "./ownable.sol";
import "./tokenMeta.sol";
 
contract newNFT is NFTokenMetadata, Ownable {
 
  constructor() payable {
    nftName = "Gezegen NFT";
    nftSymbol = "GFT";
  }
  
  fallback() external payable { }
  receive() external payable { }
 
  function mint(address _to, uint256 _tokenId, string calldata _uri) external onlyOwner payable {
    require(msg.value >= 10000000000000000 wei, "Invalid ETH Amount");
    super._mint(_to, _tokenId);
    super._setTokenUri(_tokenId, _uri);
  }
 
}