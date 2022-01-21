// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "./IZoraOverride.sol";

/**
 * @dev Implementation of Zora override
 */
contract ZoraOverride is IZoraOverride, ERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165) returns (bool) {
        return interfaceId == type(IZoraOverride).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IZoraOverride.convertBidShares}.
     */
    function convertBidShares(address media, uint256 tokenId) public view override returns (address payable[] memory receivers, uint256[] memory bps) {
        IZoraMarket.ZoraBidShares memory bidShares = IZoraMarket(IZoraMedia(media).marketContract()).bidSharesForToken(tokenId);

        // Get the total length of receivers/bps
        uint256 totalLength = 0;

        // Note: We do not support previous owner bps because it requires recalculation/sell-on support
        // Only Zora marketplace does this properly
        // if (bidShares.prevOwner.value != 0) totalLength++;

        if (bidShares.creator.value != 0) totalLength++;

        // NOTE: We do not support owner bps because these are expected to be handled by the individual market
        // implementations and are not truly royalties
        // if (bidShares.owner.value != 0) totalLength++;

        receivers = new address payable[](totalLength);
        bps = new uint256[](totalLength);

        if (bidShares.creator.value != 0) {
            receivers[0] = payable(IZoraMedia(media).tokenCreators(tokenId));
            bps[0] = bidShares.creator.value / (10**(18 - 2));
        }

        return (receivers, bps);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// https://github.com/manifoldxyz/royalty-registry-solidity/blob/main/contracts/specs/IZoraOverride.sol

pragma solidity ^0.8.0;

/**
 * Paired down version of the Zora Market interface
 */
interface IZoraMarket {
    struct ZoraDecimal {
        uint256 value;
    }

    struct ZoraBidShares {
        // % of sale value that goes to the _previous_ owner of the nft
        ZoraDecimal prevOwner;
        // % of sale value that goes to the original creator of the nft
        ZoraDecimal creator;
        // % of sale value that goes to the seller (current owner) of the nft
        ZoraDecimal owner;
    }

    function bidSharesForToken(uint256 tokenId) external view returns (ZoraBidShares memory);
}

/**
 * Paired down version of the Zora Media interface
 */
interface IZoraMedia {
    /**
     * Auto-generated accessors of public variables
     */
    function marketContract() external view returns (address);

    function previousTokenOwners(uint256 tokenId) external view returns (address);

    function tokenCreators(uint256 tokenId) external view returns (address);

    /**
     * ERC721 function
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

/**
 * Interface for a Zora media override
 */
interface IZoraOverride {
    /**
     * @dev Convert bid share configuration of a Zora Media token into an array of receivers and bps values
     *      Does not support prevOwner and sell-on amounts as that is specific to Zora marketplace implementation
     *      and requires updates on the Zora Media and Marketplace to update the sell-on amounts/previous owner values.
     *      An off-Zora marketplace sale will break the sell-on functionality.
     */
    function convertBidShares(address media, uint256 tokenId) external view returns (address payable[] memory, uint256[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}