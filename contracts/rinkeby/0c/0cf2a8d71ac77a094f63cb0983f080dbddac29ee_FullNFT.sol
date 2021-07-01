// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./ERC721.sol";
import "./Ownable.sol";

contract FullNFT is ERC721Enumerable, Ownable {

    string public baseURI = "";
    uint public supplyLimit = 10000;

    constructor(string memory initialBaseURI) ERC721("Plupppppy Token", "PPPNFT")  {
        baseURI = initialBaseURI;
    }

    function mint(address _to, uint256 _tokenId) external onlyOwner {
        require(super.totalSupply() + 1 <= supplyLimit);
        super._mint(_to, _tokenId);
    }
    
    function setBaseURI(string memory newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }
    
    function mintMultiple(address[] memory to, uint256[] memory tokenId) public onlyOwner returns (bool) {
        require(super.totalSupply() + to.length <= supplyLimit);
        for (uint i = 0; i < to.length; i++) {
            _mint(to[i], tokenId[i]);
        }
        return true;
    }
}