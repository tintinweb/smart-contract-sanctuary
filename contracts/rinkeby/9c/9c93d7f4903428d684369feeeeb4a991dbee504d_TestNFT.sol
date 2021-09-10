// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./NDR.sol";

contract TestNFT is ERC721UpgradeSafe, Configurable {
    function __TestNFT_init(address governor, string memory name, string memory symbol) public initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721_init_unchained(name, symbol);
        __Governable_init_unchained(governor);
    }
    
    function mint(address to, uint256 tokenId) external governance {
        _safeMint(to, tokenId);
    }

    /**
     * @dev Internal function to burn a specific token.
     * Reverts if the token does not exist.
     * @param tokenId uint256 ID of the token being burned
     */
    function burn(uint256 tokenId) external {
        require(_msgSender() == governor || _msgSender() == ownerOf(tokenId), 'not owner');
        _burn(tokenId);
    }
}