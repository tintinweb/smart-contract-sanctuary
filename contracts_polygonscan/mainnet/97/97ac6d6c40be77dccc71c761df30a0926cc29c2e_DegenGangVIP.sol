// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "./Ownable.sol";
import "./ERC721.sol";
import "./SafeMath.sol";
import "./Counters.sol";

/**
 * @title DegenGang VIP Contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract DegenGangVIP is ERC721, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdTracker;

    event CreateDeggnVIP(
        address indexed minter,
        uint256 indexed id
    );

    constructor() ERC721("Degen Gang VIP Card", "DEGGNVIP") {
    }

    /**
     * Set Base URI, only Owner call it
     */
    function setBaseURI(string memory baseURI) external onlyOwner {
        _setBaseURI(baseURI);
    }

    /**
     * Get Total Supply
     */
    function _totalSupply() internal view returns (uint) {
        return _tokenIdTracker.current();
    }

    /**
     * Get Total Mint
     */
    function totalMint() public view returns (uint) {
        return _totalSupply();
    }
    
    /**
     * Check if certain token id is exists.
     */
    function exists(uint256 _tokenId) public view returns (bool) {
        return _exists(_tokenId);
    }

    /**
     * Get Tokens Of Owner
     */
    function getTokensOfOwner(address _owner) public view returns (uint256 [] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokenIdList = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokenIdList[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokenIdList;
    }

    /**
     * Mint An Element, Internal Function
     */
    function _mintAnElement(address _to) internal {
        uint256 id = _totalSupply();

        _tokenIdTracker.increment();
        _safeMint(_to, id);

        emit CreateDeggnVIP(_to, id);
    }

    /**
     * Mint DEGGN By Owner
     */
    function mintByOwner(address _to, uint256 mintQuantity) public onlyOwner {
        for (uint256 i = 0; i < mintQuantity; i += 1) {
            _mintAnElement(_to);
        }
    }

    /**
     * Batch Mint DEGGN By Owner
     */
    function batchMintByOwner(
        address[] memory mintAddressList,
        uint256[] memory quantityList
    ) external onlyOwner {
        require (mintAddressList.length == quantityList.length, "The length should be same");

        for (uint256 i = 0; i < mintAddressList.length; i += 1) {
            mintByOwner(mintAddressList[i], quantityList[i]);
        }
    }
}