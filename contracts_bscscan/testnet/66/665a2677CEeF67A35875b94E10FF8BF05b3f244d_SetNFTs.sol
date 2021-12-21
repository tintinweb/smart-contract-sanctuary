// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;
import "./ERC721Enumerable.sol";
import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./Strings.sol";
import "./SafeMath.sol";
import "./Counters.sol";
import "./Ownable.sol";


contract SetNFTs is ERC721,ERC721URIStorage,Ownable {
    using SafeMath for uint256;
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    
    constructor()  ERC721("SET-NFT", "SET-NFT"){}
    
  
     /**
     * @notice  mint Nfts onlyOwner
     * @param receiver --  to address
     * @param tokenUrl --  url
     * @return  TokenId  
     */
    function mintNftTo(address receiver, string memory tokenUrl) external onlyOwner  returns (uint256) {
        
        _tokenIds.increment();
        uint256 newNftTokenId = _tokenIds.current();
        _mint(receiver, newNftTokenId);
        
        _setTokenURI(newNftTokenId, tokenUrl);
        return newNftTokenId;
    }
    
     /**
     * @notice  mint Nfts onlyOwner
     * @param tokenUrl --  url
     * @return  TokenId  
     */
    function mintNft(string memory tokenUrl) external  returns (uint256) {
        
        _tokenIds.increment();
        uint256 newNftTokenId = _tokenIds.current();
        _mint(msg.sender, newNftTokenId);
        
        _setTokenURI(newNftTokenId, tokenUrl);
        return newNftTokenId;
    }

    /**
     * @notice "Open" 
     * @param tokenId - NFT ID
     */
    function _burn(uint256 tokenId) internal override(ERC721,ERC721URIStorage){
        
        super._burn(tokenId);
        
    }
 
    /**
     * @notice tokenURI override
     * @dev This will be done by a lottery contract
     * @param tokenId - NFT ID
     */
    function tokenURI(uint256 tokenId) public view override(ERC721,ERC721URIStorage) returns (string memory){
        return super.tokenURI(tokenId);
        
    }
}