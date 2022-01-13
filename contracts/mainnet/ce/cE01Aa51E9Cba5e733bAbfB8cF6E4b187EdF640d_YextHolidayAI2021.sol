// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";


contract YextHolidayAI2021 is ERC721, ERC721URIStorage, Ownable {
    constructor(string memory contractName, string memory contractSymbol)
        ERC721(contractName, contractSymbol) {
    }

    function mintDingDong(address to, uint256 tokenId, string memory uri)
        public onlyOwner
    {
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    function mintDingDongs(address[] memory recipients, uint[] memory tokenIDs, string[] memory tokenURIs) 
        public onlyOwner 
    {
        require(recipients.length <= 125, "cannot mint more than 125 tokens");
        require(recipients.length == tokenIDs.length, "invalid arguments: #recipients must match #tokenIDs");
        require(recipients.length == tokenURIs.length, "invalid arguments: #recipients must match #tokenURIs");
        for (uint ii = 0; ii < recipients.length; ii++) {
            mintDingDong(recipients[ii], tokenIDs[ii], tokenURIs[ii]);
        }
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
}