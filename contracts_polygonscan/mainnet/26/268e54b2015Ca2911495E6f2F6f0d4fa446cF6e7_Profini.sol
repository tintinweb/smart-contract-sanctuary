// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./ERC1155Burnable.sol";
import "./Counters.sol";

contract Profini is ERC1155, Ownable, Pausable, ERC1155Burnable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenCounter;

    mapping(uint256 => string) private _uris;

    constructor() ERC1155("") {}

    function uri(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return _uris[tokenId];
    }

    function setURI(uint256 tokenId, string memory newuri) public onlyOwner {
        _uris[tokenId] = newuri;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function tokenIDs() public view returns (uint256[] memory) {
        uint256[] memory ids = new uint256[](_tokenCounter.current());
        for (uint256 i = 0; i < _tokenCounter.current(); i++) {
            ids[i] = i + 1;
        }
        return ids;
    }

    function uris() public view returns (string[] memory) {
        uint256 lastTokenId = _tokenCounter.current();
        string[] memory uriList = new string[](lastTokenId);

        for (uint256 i = 1; i <= lastTokenId; i++) {
            uriList[i - 1] = _uris[i];
        }

        return uriList;
    }

    function mint(
        address account,
        uint256 amount,
        string memory tokenURI,
        bytes memory data
    ) public onlyOwner {
        _tokenCounter.increment();

        uint256 newTokenId = _tokenCounter.current();
        _mint(account, newTokenId, amount, data);
        setURI(newTokenId, tokenURI);
    }

    function mintBatch(
        address account,
        uint256[] memory amounts,
        string[] memory tokenURIs,
        bytes memory data
    ) public onlyOwner {
        for (uint256 i = 0; i < amounts.length; i++) {
            mint(account, amounts[i], tokenURIs[i], data);
        }
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}