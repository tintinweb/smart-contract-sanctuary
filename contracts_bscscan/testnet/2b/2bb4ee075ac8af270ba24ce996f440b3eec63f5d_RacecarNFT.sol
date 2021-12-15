// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";

contract RacecarNFT is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {

    mapping(uint256 => uint256) public racecarTypeMap;

    constructor() ERC721("RacecarNFT", "RacecarNFT") {}

    function safeMint(address to, uint256 tokenId, string memory uri, uint256 racecarType)
        public
        onlyOwner
    {
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        _setRacecarType(tokenId, racecarType);
    }

    function _setRacecarType(uint256 tokenId,uint256 racecarType) internal {
        racecarTypeMap[tokenId] = racecarType;
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

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

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}