// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./ERC721Burnable.sol";
import "./IERC721Receiver.sol";
import "./Pausable.sol";

contract Dphotos is ERC721Burnable,IERC721Receiver,Pausable{

    constructor() public ERC721("Dphotos", "DPT") {
    }

    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        require(!paused(), "ERC721Pausable: token transfer while paused");
    }

    /**
    * create a unique token
    */
    function mintUniqueTokenTo(address to, uint256 tokenId) public {
        super._mint(to, tokenId);
    }

    /**
    * Custom accessor to create a unique token
    */
    function setBaseURI(string memory baseUri) public {
        super._setBaseURI(baseUri);
    }
    
}