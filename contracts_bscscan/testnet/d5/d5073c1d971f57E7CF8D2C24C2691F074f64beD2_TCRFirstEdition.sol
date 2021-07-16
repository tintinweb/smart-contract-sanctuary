// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;
 
import "./nf-token-metadata.sol";
import "./ownable.sol";
 
contract TCRFirstEdition is NFTokenMetadata, Ownable {
    
  uint8 private _total = 0;
 
  constructor() {
    nftName = "[TEST] CR iconic deploy - 1st NFT";
    nftSymbol = "T-CRNF001";
  }
  
  function totalSupply() public view returns (uint8) {
        return _total;
  }
 
  function mint(address _to, uint256 _tokenId, string calldata _uri) external onlyOwner {
    super._mint(_to, _tokenId);
    super._setTokenUri(_tokenId, _uri);
    _total = _total + 1;
  }
 
}