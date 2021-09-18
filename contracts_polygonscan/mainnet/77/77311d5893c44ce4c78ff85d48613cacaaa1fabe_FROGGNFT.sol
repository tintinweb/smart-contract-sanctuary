// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Context.sol";
import "./IERC721Receiver.sol";

contract FROGGNFT is
    Context,
    Ownable,
    ERC721Enumerable,
    ERC721Burnable,
    IERC721Receiver
{

    string private _baseTokenURI;
    address public eggAddress = 0x1039600f4D73fb30e08C569e1096109bab1fd514;
    ERC721 private eggs;

    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI
    ) ERC721(name, symbol) {
        _baseTokenURI = baseTokenURI;
        eggs = ERC721(eggAddress);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
    
    function contractURI() public pure returns (string memory) {
        return "ipfs://QmZ7ocKGWH3it1GuNqmFhAi9GEjuYjj8Co3bD5v9YT9rLd";
    }
    
    function frogg(uint256 tokenId) public virtual {
        require(_msgSender() == eggs.ownerOf(tokenId), "Need to own EGG.");
        require(eggs.isApprovedForAll(_msgSender(), address(this)) == true, "Must approve contract.");
        eggs.safeTransferFrom(_msgSender(), address(this), tokenId, "0x00");
        _safeMint(_msgSender(), tokenId);
    }
    function unfrogg(uint256 tokenId) public virtual {
        require(_msgSender() == ownerOf(tokenId), "Need to own FROGG.");
        eggs.safeTransferFrom(address(this), _msgSender(), tokenId, "0x00");
        _burn(tokenId);
    }
    
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
    
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}