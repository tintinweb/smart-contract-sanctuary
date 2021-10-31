// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./ERC721Pausable.sol";
import "./Context.sol";
import "./Counters.sol";
import "./IERC721Receiver.sol";

contract PumpkinSmash is
    Context,
    Ownable,
    ERC721Enumerable,
    ERC721Burnable,
    IERC721Receiver,
    ERC721Pausable
{
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdTracker;

    string private _baseTokenURI;
    string private _contractURI;
    
    bool public tokenURIFrozen = false;
    
    address public pumpkinAddress = 0xf1Ea02228D9C9a53272FBA32663723Ee35A105ce;
    ERC721 private pumpkin;
    
    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI
    ) ERC721(name, symbol) {
        _baseTokenURI = baseTokenURI;
        pumpkin = ERC721(pumpkinAddress);
        _tokenIdTracker.increment();
        _pause();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
    
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }
    
    function smash(uint256 tokenId1, uint256 tokenId2) public {
        require(paused() == false, "Contract is paused");
        require(pumpkin.isApprovedForAll(_msgSender(), address(this)) == true, "Must approve contract.");
        require(_msgSender() == pumpkin.ownerOf(tokenId1), "Need to own Party Pumpkin 1.");
        require(_msgSender() == pumpkin.ownerOf(tokenId2), "Need to own Party Pumpkin 2.");
        pumpkin.safeTransferFrom(_msgSender(), address(this), tokenId1, "0x00");
        pumpkin.safeTransferFrom(_msgSender(), address(this), tokenId2, "0x00");
        _mint(_msgSender(), _tokenIdTracker.current());
        _tokenIdTracker.increment();
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