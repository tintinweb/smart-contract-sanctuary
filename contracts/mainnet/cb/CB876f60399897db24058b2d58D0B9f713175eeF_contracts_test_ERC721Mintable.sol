pragma solidity >=0.6.0 <0.7.0;

import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC721/ERC721.sol";

/**
 * @dev Extension of {ERC721} for Minting/Burning
 */
contract ERC721Mintable is ERC721UpgradeSafe {

    constructor () public {
        __ERC721_init("ERC 721", "NFT");
    }

    /**
     * @dev See {ERC721-_mint}.
     */
    function mint(address to, uint256 tokenId) public {
        _mint(to, tokenId);
    }

    /**
     * @dev See {ERC721-_burn}.
     */
    function burn(uint256 tokenId) public {
        _burn(tokenId);
    }
}
