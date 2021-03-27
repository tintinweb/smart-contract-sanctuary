//SPD-License-Identifier : MIT

pragma solidity 0.8.0;

import "./nf-token-metadata.sol";
import "./ownable.sol";

contract PodContract is NFTokenMetadata,Ownable{
    
    constructor(){
        nftName = "Picture of a dream";
        nftSymbol = "Pod";
    }
    
    function mint(address _to, uint256 _tokenId, string calldata _uri) external onlyOwner{
        super._mint(_to,_tokenId);
        super._setTokenUri(_tokenId,_uri);
    }
    
}