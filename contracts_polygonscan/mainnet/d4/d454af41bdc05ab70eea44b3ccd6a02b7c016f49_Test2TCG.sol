// SPDX-License-Identifier: None
pragma solidity ^0.8.2;

import "ERC721.sol";
import "ERC721URIStorage.sol";
import "Pausable.sol";
import "Ownable.sol";
import "ERC721Burnable.sol";

contract Test2TCG is ERC721, ERC721URIStorage, Pausable, Ownable, ERC721Burnable {
    constructor() ERC721("Test 2 TCG", "TESTTCG") {}

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function safeMint(address to, uint256 tokenId, string memory uri)
        public
        onlyOwner
    {
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, tokenId);
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