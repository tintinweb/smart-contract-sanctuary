// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "ERC721Upgradeable.sol";
import "PausableUpgradeable.sol";
import "OwnableUpgradeable.sol";
import "ERC721BurnableUpgradeable.sol";
import "Initializable.sol";

contract CryptoTopTen is Initializable, ERC721Upgradeable, PausableUpgradeable, OwnableUpgradeable, ERC721BurnableUpgradeable {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() initializer public {
        __ERC721_init("Crypto Top 10 Snapshot Editions - CryptoTCG", "CTCGTTEN");
        __Pausable_init();
        __Ownable_init();
        __ERC721Burnable_init();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function safeMint(address to, uint256 tokenId) public onlyOwner {
        _safeMint(to, tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}