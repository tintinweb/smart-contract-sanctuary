// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./ERC721URIStorage.sol";

contract TestNFT is ERC721URIStorage, Ownable {
    address public handleAddress;
    
    uint256 public constant maxTotalSupply = 2000;
    uint256 public currentBox;
    struct NFT{
        uint token_id;
        string token_uri;
    }
    struct NFTList {
        // string bookID;
        NFT[] nfts;
    }
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    mapping(address => NFTList) nftList;
    
    constructor( string memory _name, string memory _symbol) public ERC721(_name, _symbol) {
        handleAddress = owner();
        currentBox = 0;
    }

    function mintBox(address recipient, string memory tokenURI) external returns (uint256) {
        require(msg.sender == handleAddress, "WRONG CALLER");
        _tokenIds.increment();
        
        require(_tokenIds.current() <= maxTotalSupply, "OUT OF AMOUNT");
        
        uint256 newItemId = _tokenIds.current();
        _mint(recipient, newItemId);
        _setTokenURI(newItemId, tokenURI);
        currentBox = _tokenIds.current();
        
        NFT memory c = NFT({
            token_id: _tokenIds.current(),
            token_uri: tokenURI
        });
        
        nftList[recipient].nfts.push(c);
        
        return newItemId;
    }
    
    function setHandleAddress(address _handleAddress) external onlyOwner {
        require(_handleAddress != address(0));
        handleAddress = _handleAddress;
    }
    
    function getURI(uint256 tokenId) external view returns (string memory) {
        string memory uri = super.tokenURI(tokenId);
        return string(uri);
    }
    
    function getNFTList(address _owner) external view returns (NFT[] memory) {
        return nftList[_owner].nfts;
    }
}