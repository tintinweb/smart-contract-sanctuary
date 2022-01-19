// SPDX-License-Identifier: MIT

pragma solidity =0.8.10;

import { IXDEFIDistributionHelper, IXDEFIDistributionLike } from "./interfaces/IXDEFIDistributionHelper.sol";

/// @dev Stateless helper contract for external clients to reduce web3 calls to gather XDEFIDistribution information related to individual accounts.
contract XDEFIDistributionHelper is IXDEFIDistributionHelper {

    function getAllTokensForAccount(address xdefiDistribution_, address account_) public view returns (uint256[] memory tokenIds_) {
        uint256 count = IXDEFIDistributionLike(xdefiDistribution_).balanceOf(account_);
        tokenIds_ = new uint256[](count);

        for (uint256 i; i < count;) {
            tokenIds_[i] = IXDEFIDistributionLike(xdefiDistribution_).tokenOfOwnerByIndex(account_, i);

            unchecked {
                ++i;
            }
        }
    }

    function getAllLockedPositionsForAccount(address xdefiDistribution_, address account_) external view returns (uint256[] memory tokenIds_, IXDEFIDistributionLike.Position[] memory positions_, uint256[] memory withdrawables_) {
        uint256[] memory tokenIds = getAllTokensForAccount(xdefiDistribution_, account_);

        IXDEFIDistributionLike.Position[] memory positions = new IXDEFIDistributionLike.Position[](tokenIds.length);

        uint256 validPositionCount;

        // NOTE: unchecked around entire for-loop due to the continue.
        unchecked {
            for (uint256 i; i < tokenIds.length; ++i) {
                uint256 tokenId = tokenIds[i];
                IXDEFIDistributionLike.Position memory position = IXDEFIDistributionLike(xdefiDistribution_).positionOf(tokenId);

                if (position.expiry == uint32(0)) continue;

                tokenIds[validPositionCount] = tokenId;
                positions[validPositionCount++] = position;
            }
        }


        tokenIds_ = new uint256[](validPositionCount);
        positions_ = new IXDEFIDistributionLike.Position[](validPositionCount);
        withdrawables_ = new uint256[](validPositionCount);

        for (uint256 i; i < validPositionCount;) {
            positions_[i] = positions[i];
            withdrawables_[i] = IXDEFIDistributionLike(xdefiDistribution_).withdrawableOf(tokenIds_[i] = tokenIds[i]);

            unchecked {
                ++i;
            }
        }
    }

}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.10;

import { IXDEFIDistribution } from "./IXDEFIDistribution.sol";

interface IXDEFIDistributionLike {

    struct Position {
        uint96 units;
        uint88 depositedXDEFI;
        uint32 expiry;
        uint32 created;
        uint256 pointsCorrection;
    }

    function balanceOf(address account_) external view returns (uint256 balance_);

    function tokenOfOwnerByIndex(address account_, uint256 index_) external view returns (uint256 tokenId_);

    function positionOf(uint256 tokenId_) external view returns (Position memory position_);

    function withdrawableOf(uint256 tokenId_) external view returns (uint256 withdrawableXDEFI_);

}

interface IXDEFIDistributionHelper {

    function getAllTokensForAccount(address xdefiDistribution_, address account_) external view returns (uint256[] memory tokenIds_);

    function getAllLockedPositionsForAccount(address xdefiDistribution_, address account_) external view returns (uint256[] memory tokenIds_, IXDEFIDistributionLike.Position[] memory positions_, uint256[] memory withdrawables_);

}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.10;

import { IERC721Enumerable } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface IXDEFIDistribution is IERC721Enumerable {

    error CannotUnlock();
    error EmptyArray();
    error IncorrectBonusMultiplier();
    error InsufficientAmountUnlocked();
    error InvalidDuration();
    error InvalidMultiplier();
    error InvalidToken();
    error LockingIsDisabled();
    error LockResultsInTooFewUnits();
    error MustMergeMultiple();
    error NoReentering();
    error NoUnitSupply();
    error NotInEmergencyMode();
    error NotTokenOwner();
    error PositionAlreadyUnlocked();
    error PositionStillLocked();
    error TokenDoesNotExist();
    error Unauthorized();

    struct Position {
        uint96 units;  // 240,000,000,000,000,000,000,000,000 XDEFI * 2.55x bonus (which fits in a `uint96`).
        uint88 depositedXDEFI;  // XDEFI cap is 240000000000000000000000000 (which fits in a `uint88`).
        uint32 expiry;  // block timestamps for the next 50 years (which fits in a `uint32`).
        uint32 created;
        uint256 pointsCorrection;
    }

    /// @notice Emitted when owner proposed an account that can accept ownership.
    event OwnershipProposed(address indexed owner, address indexed pendingOwner);

    /// @notice Emitted when an account has accepted ownership.
    event OwnershipAccepted(address indexed previousOwner, address indexed owner);

    /// @notice Emitted when the base URI is set (or re-set).
    event BaseURISet(string);

    /// @notice Emitted when the contract is no longer allowing locking XDEFI, and is allowing all locked positions to be unlocked effective immediately.
    event EmergencyModeActivated();

    /// @notice Emitted when a new lock period duration, in seconds, has been enabled with some bonus multiplier (scaled by 100, 0 signaling it is disabled).
    event LockPeriodSet(uint256 indexed duration, uint256 indexed bonusMultiplier);

    /// @notice Emitted when a new locked position is created for some amount of XDEFI, and the NFT is minted to an owner.
    event LockPositionCreated(uint256 indexed tokenId, address indexed owner, uint256 amount, uint256 indexed duration);

    /// @notice Emitted when a locked position is unlocked, withdrawing some amount of XDEFI.
    event LockPositionWithdrawn(uint256 indexed tokenId, address indexed owner, uint256 amount);

    /// @notice Emitted when a new amount of XDEFI is distributed to all locked positions, by some caller.
    event DistributionUpdated(address indexed caller, uint256 amount);

    /// @notice Emitted when unlocked tokens are merged into one.
    event TokensMerged(uint256[] mergedTokenIds, uint256 resultingTokenId);

    /// @notice The address of the XDEFI token.
    function xdefi() external view returns (address XDEFI_);

    /// @notice The amount of XDEFI that is distributable to all currently locked positions.
    function distributableXDEFI() external view returns (uint256 distributableXDEFI_);

    /// @notice The amount of XDEFI that was deposited by all currently locked positions.
    function totalDepositedXDEFI() external view returns (uint256 totalDepositedXDEFI_);

    /// @notice The amount of locked position units (in some way, it is the denominator use to distribute new XDEFI to each unit).
    function totalUnits() external view returns (uint256 totalUnits_);

    /// @notice Returns the position details (`pointsCorrection_` is a value used in the amortized work pattern for token distribution).
    function positionOf(uint256 tokenId_) external view returns (uint96 units_, uint88 depositedXDEFI_, uint32 expiry_, uint32 created_, uint256 pointsCorrection_);

    /// @notice The multiplier applied to the deposited XDEFI amount to determine the units of a position, and thus its share of future distributions.
    function bonusMultiplierOf(uint256 duration_) external view returns (uint256 bonusMultiplier_);

    /// @notice The base URI for NFT metadata.
    function baseURI() external view returns (string memory baseURI_);

    /// @notice The account that can set and unset lock periods and transfer ownership of the contract.
    function owner() external view returns (address owner_);

    /// @notice The account that can take ownership of the contract.
    function pendingOwner() external view returns (address pendingOwner_);

    /// @notice The contract is no longer allowing locking XDEFI, and is allowing all locked positions to be unlocked effective immediately.
    function inEmergencyMode() external view returns (bool lockingDisabled_);

    /// @notice The minimum units that can result from a lock of XDEFI.
    function MINIMUM_UNITS() external view returns (uint256 minimumUnits_);

    /*******************/
    /* Admin Functions */
    /*******************/

    /// @notice Allows the `pendingOwner` to take ownership of the contract.
    function acceptOwnership() external;

    /// @notice Disallows locking XDEFI, and is allows all locked positions to be unlocked effective immediately.
    function activateEmergencyMode() external;

    /// @notice Allows the owner to propose a new owner for the contract.
    function proposeOwnership(address newOwner_) external;

    /// @notice Sets the base URI for NFT metadata.
    function setBaseURI(string calldata baseURI_) external;

    /// @notice Allows the setting or un-setting (when the multiplier is 0) of multipliers for lock durations. Scaled such that 1x is 100.
    function setLockPeriods(uint256[] calldata durations_, uint256[] calldata multipliers) external;

    /**********************/
    /* Position Functions */
    /**********************/

    /// @notice Unlock only the deposited amount from a non-fungible position, sending the XDEFI to some destination, when in emergency mode.
    function emergencyUnlock(uint256 tokenId_, address destination_) external returns (uint256 amountUnlocked_);

    /// @notice Locks some amount of XDEFI into a non-fungible (NFT) position, for a duration of time. The caller must first approve this contract to spend its XDEFI.
    function lock(uint256 amount_, uint256 duration_, uint256 bonusMultiplier_, address destination_) external returns (uint256 tokenId_);

    /// @notice Locks some amount of XDEFI into a non-fungible (NFT) position, for a duration of time, with a signed permit to transfer XDEFI from the caller.
    function lockWithPermit(uint256 amount_, uint256 duration_, uint256 bonusMultiplier_, address destination_, uint256 deadline_, uint8 v_, bytes32 r_, bytes32 s_) external returns (uint256 tokenId_);

    /// @notice Unlock an un-lockable non-fungible position and re-lock some amount, for a duration of time, sending the balance XDEFI to some destination.
    function relock(uint256 tokenId_, uint256 lockAmount_, uint256 duration_, uint256 bonusMultiplier_, address destination_) external returns (uint256 amountUnlocked_, uint256 newTokenId_);

    /// @notice Unlock an un-lockable non-fungible position, sending the XDEFI to some destination.
    function unlock(uint256 tokenId_, address destination_) external returns (uint256 amountUnlocked_);

    /// @notice To be called as part of distributions to force the contract to recognize recently transferred XDEFI as distributable.
    function updateDistribution() external;

    /// @notice Returns the amount of XDEFI that can be withdrawn when the position is unlocked. This will increase as distributions are made.
    function withdrawableOf(uint256 tokenId_) external view returns (uint256 withdrawableXDEFI_);

    /****************************/
    /* Batch Position Functions */
    /****************************/

    /// @notice Unlocks several un-lockable non-fungible positions and re-lock some amount, for a duration of time, sending the balance XDEFI to some destination.
    function relockBatch(uint256[] calldata tokenIds_, uint256 lockAmount_, uint256 duration_, uint256 bonusMultiplier_, address destination_) external returns (uint256 amountUnlocked_, uint256 newTokenId_);

    /// @notice Unlocks several un-lockable non-fungible positions, sending the XDEFI to some destination.
    function unlockBatch(uint256[] calldata tokenIds_, address destination_) external returns (uint256 amountUnlocked_);

    /*****************/
    /* NFT Functions */
    /*****************/

    /// @notice Returns the score an NFT will have, given some amount locked for some duration.
    function getScore(uint256 amount_, uint256 duration_) external pure returns (uint256 score_);

    /// @notice Burns several unlocked NFTs to mint a new NFT that has their combined score.
    function merge(uint256[] calldata tokenIds_, address destination_) external returns (uint256 tokenId_);

    /// @notice Returns the score of an NFT.
    function scoreOf(uint256 tokenId_) external view returns (uint256 score_);

    /// @notice Returns the URI for the NFT metadata for a given token ID.
    function tokenURI(uint256 tokenId_) external view returns (string memory tokenURI_);

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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