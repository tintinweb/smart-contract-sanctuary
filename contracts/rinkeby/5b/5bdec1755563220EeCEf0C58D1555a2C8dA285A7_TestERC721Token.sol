pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "ERC721.sol";
import "IERC721Metadata.sol";
import "ERC721Enumerable.sol";
import "ERC721URIStorage.sol";
import "ERC721Burnable.sol";
import "Context.sol";
import "Counters.sol";


contract TestERC721Token is Context, ERC721, ERC721Enumerable, ERC721URIStorage, ERC721Burnable {

    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    //
    // ERC165
    //

    function supportsInterface(bytes4 interfaceId) public  view  override(ERC721, ERC721Enumerable)  returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    //
    // INSTANTIATE
    //

    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {

    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)  internal  override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function tokenURI(uint256 tokenId)  public  view  override(ERC721, ERC721URIStorage)  returns (string memory) {
        return super.tokenURI(tokenId);
    }

    //
    // MINT & BURN
    //

    function safeMint(address to_, string memory tokenURI_) public {
        _tokenIdCounter.increment();

        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(to_, tokenId);
        _setTokenURI(tokenId, tokenURI_);
    }

    function mint(address to_, string memory tokenURI_) public {
        _tokenIdCounter.increment();

        uint256 tokenId = _tokenIdCounter.current();
        _mint(to_, tokenId);
        _setTokenURI(tokenId, tokenURI_);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

}