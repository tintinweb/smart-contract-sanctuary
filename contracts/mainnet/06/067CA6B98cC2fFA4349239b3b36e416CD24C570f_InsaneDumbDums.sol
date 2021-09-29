// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract InsaneDumbDums is ERC721, ERC721Enumerable, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    uint256 public mintRate = 0.02 ether;
    uint public MaxSupply = 10000;
    bool public isMinting = false;
    
    string private _baseURIextended;
    
    constructor() ERC721("Insane Dumb Dums", "IDUMB") {}

    function safeMint(address to) public payable {
        require(isMinting, "Minting is not live.");
        require(totalSupply() < MaxSupply, "Can't minnt more.");
        require(msg.value >= mintRate, "Not enough ether sent.");
        _tokenIdCounter.increment();
        _safeMint(to, _tokenIdCounter.current());
        
    }
    
    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }
    
    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
    
    function setIsMinting(bool _isminting) public onlyOwner {
        isMinting = _isminting;
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
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