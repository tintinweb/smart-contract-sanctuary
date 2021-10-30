// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./Context.sol";
import "./Ownable.sol";
import "./MinterRole.sol";
import "./Pausable.sol";
import "./ERC721.sol";

contract DracooMaster is Context, Ownable, MinterRole, Pausable, ERC721 {
    using SafeMath for uint256;

    mapping(uint256 => uint256[2]) private _parents;

    constructor() ERC721("Dracoo Master", "Dracoo") public {

    }

    // start from tokenId = 1; all minted tokens(include airdrops)' parents are uint256(0)
    function safeMint(address to) public virtual onlyMinter returns(uint256) {
        uint256 tokenId = totalSupply() + 1;
        _setParents(tokenId, [uint256(0), uint256(0)]);
        _safeMint(to, tokenId);

        return tokenId;
    }

    function breedMint(address to, uint256[2] memory parentsId) public virtual onlyMinter returns(uint256) {
        uint256 tokenId = totalSupply() + 1;
        _setParents(tokenId, parentsId);
        _safeMint(to, tokenId);

        return tokenId;
    }

    function burn(uint256 tokenId) public virtual {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    } 

    function checkParents(uint256 tokenId) public view returns(uint256[2] memory) {
        require(_exists(tokenId), "DracooMaster: query for nonexistance tokenId");
        return _parents[tokenId];
    } 

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }

    function setTokenURI(uint256 tokenId, string memory tokenURI) public onlyOwner {
        _setTokenURI(tokenId, tokenURI);
    }

    function _setParents(uint256 childId, uint256[2] memory parentsId) internal {
        require(!_exists(childId), "childId exists");

        _parents[childId] = parentsId;
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

}