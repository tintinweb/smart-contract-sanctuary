// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract PublicNFT is ERC721Enumerable, Ownable {
    using Address for address;
    using Strings for uint256;
    
    uint256 public constant MAX_BUY_COUNT = 15;
    
    string public baseURI = "";

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory __name, string memory __symbol)
        ERC721(__name, __symbol)
    {}
    
    // Metadata handlers
    
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
    
    function setBaseUri(string memory _uri) external {
        baseURI = _uri;
    }
    
    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Nonexistent token");
        
        string memory base = _baseURI();
        return string(abi.encodePacked(base, tokenId.toString()));
    }
    
    // Minting
            
    function mint(address toAddress, uint256 count) public {
      require(toAddress != address(0), "To address error");
      require(count > 0, "Count can't be 0");
      
      for (uint256 i = 0; i < count; i++) {
        _mint(toAddress, totalSupply());
      }
    }
}