// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./ERC721Pausable.sol";
import "./Context.sol";
import "./IERC721Receiver.sol";

contract OCTONFT is
    Context,
    Ownable,
    ERC721Enumerable,
    ERC721Burnable,
    IERC721Receiver,
    ERC721Pausable
{

    address public eggAddress = 0x1039600f4D73fb30e08C569e1096109bab1fd514;
    ERC721 private eggs;

    string public _baseTokenURI;
    string public _contractURI;
    bool public tokenURIFrozen = false;

    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI
    ) ERC721(name, symbol) {
        _baseTokenURI = baseTokenURI;
        eggs = ERC721(eggAddress);
        _pause();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
    
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }
    
    function octo(uint256 tokenId) public virtual {
        require(_msgSender() == eggs.ownerOf(tokenId), "Need to own EGG.");
        require(eggs.isApprovedForAll(_msgSender(), address(this)) == true, "Must approve contract.");
        eggs.safeTransferFrom(_msgSender(), address(this), tokenId, "0x00");
        _safeMint(_msgSender(), tokenId);
    }
    function egg(uint256 tokenId) public virtual {
        require(_msgSender() == ownerOf(tokenId), "Need to own OCTO.");
        eggs.safeTransferFrom(address(this), _msgSender(), tokenId, "0x00");
        _burn(tokenId);
    }
    
    function setContractURI(string memory uri) public onlyOwner {
        require(tokenURIFrozen == false, "Token URIs are frozen");
        _contractURI = uri;
    }
    function setBaseTokenURI(string memory uri) public onlyOwner {
        require(tokenURIFrozen == false, "Token URIs are frozen");
        _baseTokenURI = uri;
    }
    
    function unpause() public onlyOwner {
        _unpause();
    }

    function freezeBaseURI() public onlyOwner {
        tokenURIFrozen = true;
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
    
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable) {
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