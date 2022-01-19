// SPDX-License-Identifier: MIT

pragma solidity =0.8.10;

import { ERC721, ERC721Enumerable, Strings } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { IEIP2612 } from "./interfaces/IEIP2612.sol";
import { IXDEFIDistribution } from "./interfaces/IXDEFIDistribution.sol";

/// @dev Handles distributing XDEFI to NFTs that have locked up XDEFI for various durations of time.
contract XDEFIDistribution is IXDEFIDistribution, ERC721Enumerable {

    address internal constant ZERO_ADDRESS = address(0);

    uint256 internal constant ZERO_UINT256 = uint256(0);
    uint256 internal constant ONE_UINT256 = uint256(1);
    uint256 internal constant TWO_UINT256 = uint256(2);
    uint256 internal constant ONE_HUNDRED_UINT256 = uint256(100);
    uint256 internal constant ONE_HUNDRED_TWENTY_EIGHT_UINT256 = uint256(128);

    // See https://github.com/ethereum/EIPs/issues/1726#issuecomment-472352728
    uint256 internal constant POINTS_MULTIPLIER_BITS = uint256(72);
    uint256 internal _pointsPerUnit;

    address public immutable xdefi;

    uint256 public distributableXDEFI;
    uint256 public totalDepositedXDEFI;
    uint256 public totalUnits;

    mapping(uint256 => Position) public positionOf;

    mapping(uint256 => uint256) public bonusMultiplierOf;  // Scaled by 100, capped at 255 (i.e. 1.1x is 110, 2.55x is 255).

    uint256 internal _tokensMinted;

    string public baseURI;

    address public owner;
    address public pendingOwner;

    uint256 internal constant IS_NOT_LOCKED = uint256(1);
    uint256 internal constant IS_LOCKED = uint256(2);

    uint256 internal _lockedStatus = IS_NOT_LOCKED;

    bool public inEmergencyMode;

    uint256 internal constant MAX_DURATION = uint256(315360000 seconds);  // 10 years.
    uint256 internal constant MAX_BONUS_MULTIPLIER = uint256(255);  // 2.55x.

    uint256 public constant MINIMUM_UNITS = uint256(1e18);

    constructor (address xdefi_, string memory baseURI_) ERC721("Locked XDEFI", "lXDEFI") {
        // Set `xdefi` immutable and check that it's not empty.
        if ((xdefi = xdefi_) == ZERO_ADDRESS) revert InvalidToken();

        owner = msg.sender;
        baseURI = baseURI_;
    }

    modifier onlyOwner() {
        if (owner != msg.sender) revert Unauthorized();

        _;
    }

    modifier noReenter() {
        if (_lockedStatus == IS_LOCKED) revert NoReentering();

        _lockedStatus = IS_LOCKED;
        _;
        _lockedStatus = IS_NOT_LOCKED;
    }

    modifier updatePointsPerUnitAtStart() {
        updateDistribution();
        _;
    }

    modifier updateDistributableAtEnd() {
        _;
        // NOTE: This needs to be done after updating `totalDepositedXDEFI` (which happens in `_destroyLockedPosition`) and transferring out.
        _updateDistributableXDEFI();
    }

    /*******************/
    /* Admin Functions */
    /*******************/

    function acceptOwnership() external {
        if (pendingOwner != msg.sender) revert Unauthorized();

        emit OwnershipAccepted(owner, msg.sender);
        owner = msg.sender;
        pendingOwner = ZERO_ADDRESS;
    }

    function activateEmergencyMode() external onlyOwner {
        inEmergencyMode = true;
        emit EmergencyModeActivated();
    }

    function proposeOwnership(address newOwner_) external onlyOwner {
        emit OwnershipProposed(
            owner,
            pendingOwner = newOwner_
        );
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        emit BaseURISet(
            baseURI = baseURI_
        );
    }

    function setLockPeriods(uint256[] calldata durations_, uint256[] calldata multipliers_) external onlyOwner {
        // Revert if an empty duration array is passed in, which would result in a successful, yet wasted useless transaction.
        if (durations_.length == ZERO_UINT256) revert EmptyArray();

        for (uint256 i; i < durations_.length;) {
            uint256 duration = durations_[i];
            uint256 multiplier = multipliers_[i];

            // Revert if duration is 0 or longer than max defined.
            if (duration == ZERO_UINT256 || duration > MAX_DURATION) revert InvalidDuration();

            // Revert if bonus multiplier is larger than max defined.
            if (multiplier > MAX_BONUS_MULTIPLIER) revert InvalidMultiplier();

            emit LockPeriodSet(
                duration,
                bonusMultiplierOf[duration] = multiplier
            );

            unchecked {
                ++i;
            }
        }
    }

    /**********************/
    /* Position Functions */
    /**********************/

    function emergencyUnlock(uint256 tokenId_, address destination_) external noReenter updateDistributableAtEnd returns (uint256 amountUnlocked_) {
        // Revert if not in emergency mode.
        if (!inEmergencyMode) revert NotInEmergencyMode();

        // Revert if account is not the owner of the token.
        if (ownerOf(tokenId_) != msg.sender) revert NotTokenOwner();

        // Fetch position.
        Position storage position = positionOf[tokenId_];
        uint256 units = uint256(position.units);
        amountUnlocked_ = uint256(position.depositedXDEFI);

        // Track deposits.
        // NOTE: Can be unchecked since `totalDepositedXDEFI` increase in `_createLockedPosition` is the only place where `totalDepositedXDEFI` is set.
        unchecked {
            totalDepositedXDEFI -= amountUnlocked_;
        }

        // Delete FDT Position.
        // NOTE: Can be unchecked since `totalUnits` increase in `_createLockedPosition` is the only place where `totalUnits` is set.
        unchecked {
            totalUnits -= units;
        }

        delete positionOf[tokenId_];

        // Send the unlocked XDEFI to the destination. (Don't need SafeERC20 since XDEFI is standard ERC20).
        IERC20(xdefi).transfer(destination_, amountUnlocked_);
    }

    function lock(uint256 amount_, uint256 duration_, uint256 bonusMultiplier_, address destination_) external noReenter updatePointsPerUnitAtStart returns (uint256 tokenId_) {
        tokenId_ = _lock(amount_, duration_, bonusMultiplier_, destination_);
    }

    function lockWithPermit(uint256 amount_, uint256 duration_, uint256 bonusMultiplier_, address destination_, uint256 deadline_, uint8 v_, bytes32 r_, bytes32 s_) external noReenter updatePointsPerUnitAtStart returns (uint256 tokenId_) {
        // Approve this contract for the amount, using the provided signature.
        IEIP2612(xdefi).permit(msg.sender, address(this), amount_, deadline_, v_, r_, s_);

        tokenId_ = _lock(amount_, duration_, bonusMultiplier_, destination_);
    }

    function relock(uint256 tokenId_, uint256 lockAmount_, uint256 duration_, uint256 bonusMultiplier_, address destination_) external noReenter updatePointsPerUnitAtStart updateDistributableAtEnd returns (uint256 amountUnlocked_, uint256 newTokenId_) {
        // Handle the unlock and get the amount of XDEFI eligible to withdraw.
        amountUnlocked_ = _destroyLockedPosition(msg.sender, tokenId_);

        newTokenId_ = _relock(lockAmount_, amountUnlocked_, duration_, bonusMultiplier_, destination_);
    }

    function unlock(uint256 tokenId_, address destination_) external noReenter updatePointsPerUnitAtStart updateDistributableAtEnd returns (uint256 amountUnlocked_) {
        // Handle the unlock and get the amount of XDEFI eligible to withdraw.
        amountUnlocked_ = _destroyLockedPosition(msg.sender, tokenId_);

        // Send the unlocked XDEFI to the destination. (Don't need SafeERC20 since XDEFI is standard ERC20).
        IERC20(xdefi).transfer(destination_, amountUnlocked_);
    }

    function updateDistribution() public {
        // NOTE: Since `_updateDistributableXDEFI` is called anywhere after XDEFI is withdrawn from the contract, here `changeInDistributableXDEFI` should always be greater than 0.
        uint256 increaseInDistributableXDEFI = _updateDistributableXDEFI();

        // Return if no change in distributable XDEFI.
        if (increaseInDistributableXDEFI == ZERO_UINT256) return;

        uint256 totalUnitsCached = totalUnits;

        // Revert if `totalUnitsCached` is zero. (This would have reverted anyway in the line below.)
        if (totalUnitsCached == ZERO_UINT256) revert NoUnitSupply();

        // NOTE: Max numerator is 240_000_000 * 1e18 * (2 ** 72), which is less than `type(uint256).max`, and min denominator is 1.
        //       So, `_pointsPerUnit` can grow by 2**160 every distribution of XDEFI's max supply.
        unchecked {
            _pointsPerUnit += (increaseInDistributableXDEFI << POINTS_MULTIPLIER_BITS) / totalUnitsCached;
        }

        emit DistributionUpdated(msg.sender, increaseInDistributableXDEFI);
    }

    function withdrawableOf(uint256 tokenId_) external view returns (uint256 withdrawableXDEFI_) {
        Position storage position = positionOf[tokenId_];
        withdrawableXDEFI_ = _withdrawableGiven(position.units, position.depositedXDEFI, position.pointsCorrection);
    }

    /****************************/
    /* Batch Position Functions */
    /****************************/

    function relockBatch(uint256[] calldata tokenIds_, uint256 lockAmount_, uint256 duration_, uint256 bonusMultiplier_, address destination_) external noReenter updatePointsPerUnitAtStart updateDistributableAtEnd returns (uint256 amountUnlocked_, uint256 newTokenId_) {
        // Handle the unlocks and get the amount of XDEFI eligible to withdraw.
        amountUnlocked_ = _unlockBatch(msg.sender, tokenIds_);

        newTokenId_ = _relock(lockAmount_, amountUnlocked_, duration_, bonusMultiplier_, destination_);
    }

    function unlockBatch(uint256[] calldata tokenIds_, address destination_) external noReenter updatePointsPerUnitAtStart updateDistributableAtEnd returns (uint256 amountUnlocked_) {
        // Handle the unlocks and get the amount of XDEFI eligible to withdraw.
        amountUnlocked_ = _unlockBatch(msg.sender, tokenIds_);

        // Send the unlocked XDEFI to the destination. (Don't need SafeERC20 since XDEFI is standard ERC20).
        IERC20(xdefi).transfer(destination_, amountUnlocked_);
    }

    /*****************/
    /* NFT Functions */
    /*****************/

    function getScore(uint256 amount_, uint256 duration_) external pure returns (uint256 score_) {
        score_ = _getScore(amount_, duration_);
    }

    function merge(uint256[] calldata tokenIds_, address destination_) external noReenter returns (uint256 tokenId_) {
        // Revert if trying to merge 0 or 1 tokens, which cannot be done.
        if (tokenIds_.length <= ONE_UINT256) revert MustMergeMultiple();

        // For each NFT, check that it belongs to the caller, burn it, and accumulate the score.
        for (uint256 i; i < tokenIds_.length;) {
            uint256 tokenId = tokenIds_[i];

            // Revert if `msg.sender` is not the owner of the token.
            if (ownerOf(tokenId) != msg.sender) revert NotTokenOwner();

            // Revert if position has an expiry property, which means it still exists.
            // NOTE: `uint256(positionOf[tokenId].expiry) != ZERO_UINT256` is equivalent (in bytecode and gas).
            if (positionOf[tokenId].expiry != uint32(0)) revert PositionStillLocked();

            _burn(tokenId);

            unchecked {
                // Max score of a previously locked position is `type(uint128).max`, so `score` is reasonably not going to overflow.
                // Note: Using the so-far-unused variable `tokenId_` for now as `score`.
                tokenId_ += _getScoreFromTokenId(tokenId);

                ++i;
            }
        }

        // Generate a new tokenId based on the accumulated score.
        // Note: `tokenId_` was used as `score` up until, this point.
        tokenId_ = _generateNewTokenId(tokenId_);

        emit TokensMerged(tokenIds_, tokenId_);

        // Mine a new NFT to the destinations.
        _safeMint(destination_, tokenId_);
    }

    function scoreOf(uint256 tokenId_) external view returns (uint256 score_) {
        // Revert if the token does not exist.
        if (!_exists(tokenId_)) revert TokenDoesNotExist();

        score_ = _getScoreFromTokenId(tokenId_);
    }

    function tokenURI(uint256 tokenId_) public view override(IXDEFIDistribution, ERC721) returns (string memory tokenURI_) {
        // Revert if the token does not exist.
        if (!_exists(tokenId_)) revert TokenDoesNotExist();

        tokenURI_ = string(abi.encodePacked(baseURI, Strings.toString(tokenId_)));
    }

    /**********************/
    /* Internal Functions */
    /**********************/

    function _createLockedPosition(uint256 amount_, uint256 duration_, uint256 bonusMultiplier_, address destination_) internal returns (uint256 tokenId_) {
        // Revert is locking has been disabled.
        if (inEmergencyMode) revert LockingIsDisabled();

        uint256 bonusMultiplier = bonusMultiplierOf[duration_];

        // Revert if the bonus multiplier is zero.
        if (bonusMultiplier == ZERO_UINT256) revert InvalidDuration();

        // Revert if the bonus multiplier is not at least what was expected.
        if (bonusMultiplier < bonusMultiplier_) revert IncorrectBonusMultiplier();

        // Track deposits.
        totalDepositedXDEFI += amount_;

        // Generate a token id.
        tokenId_ = _generateNewTokenId(_getScore(amount_, duration_));

        // Create Position.
        unchecked {
            uint256 units = (amount_ * bonusMultiplier) / ONE_HUNDRED_UINT256;

            // Revert if position will end up with less than define minimum lockable units.
            if (units < MINIMUM_UNITS) revert LockResultsInTooFewUnits();

            totalUnits += units;

            positionOf[tokenId_] =
                Position({
                    units: uint96(units),  // 240M * 1e18 * 255 can never be larger than a `uint96`.
                    depositedXDEFI: uint88(amount_),  // There are only 240M (18 decimals) XDEFI tokens so can never be larger than a `uint88`.
                    expiry: uint32(block.timestamp + duration_),  // For many years, block.timestamp + duration_ will never be larger than a `uint32`.
                    created: uint32(block.timestamp),  // For many years, block.timestamp will never be larger than a `uint32`.
                    pointsCorrection: _pointsPerUnit * units  // _pointsPerUnit * units cannot be greater than a `uint256`.
                });
        }

        emit LockPositionCreated(tokenId_, destination_, amount_, duration_);

        // Mint a locked staked position NFT to the destination.
        _safeMint(destination_, tokenId_);
    }

    function _destroyLockedPosition(address account_, uint256 tokenId_) internal returns (uint256 amountUnlocked_) {
        // Revert if account is not the owner of the token.
        if (ownerOf(tokenId_) != account_) revert NotTokenOwner();

        // Fetch position.
        Position storage position = positionOf[tokenId_];
        uint256 units = uint256(position.units);
        uint256 depositedXDEFI = uint256(position.depositedXDEFI);
        uint256 expiry = uint256(position.expiry);

        // Revert if the position does not have an expiry, which means the position does not exist.
        if (expiry == ZERO_UINT256) revert PositionAlreadyUnlocked();

        // Revert if not enough time has elapsed in order to unlock AND locking is not disabled (which would mean we are allowing emergency withdrawals).
        if (block.timestamp < expiry && !inEmergencyMode) revert CannotUnlock();

        // Get the withdrawable amount of XDEFI for the position.
        amountUnlocked_ = _withdrawableGiven(units, depositedXDEFI, position.pointsCorrection);

        // Track deposits.
        // NOTE: Can be unchecked since `totalDepositedXDEFI` increase in `_createLockedPosition` is the only place where `totalDepositedXDEFI` is set.
        unchecked {
            totalDepositedXDEFI -= depositedXDEFI;
        }

        // Delete FDT Position.
        // NOTE: Can be unchecked since `totalUnits` increase in `_createLockedPosition` is the only place where `totalUnits` is set.
        unchecked {
            totalUnits -= units;
        }

        delete positionOf[tokenId_];

        emit LockPositionWithdrawn(tokenId_, account_, amountUnlocked_);
    }

    function _generateNewTokenId(uint256 score_) internal returns (uint256 tokenId_) {
        // Score is implicitly capped at max supply of XDEFI for 10 years locked (less than 2**119).
        // Total minted NFTs is expected to be reasonably capped at `type(uint128).max`.
        unchecked {
            tokenId_ = (score_ << ONE_HUNDRED_TWENTY_EIGHT_UINT256) + _tokensMinted++;
        }
    }

    function _getScore(uint256 amount_, uint256 duration_) internal pure returns (uint256 score_) {
        // Score is implicitly capped at max supply of XDEFI for 10 years locked (less than 2**116).
        unchecked {
            score_ = amount_ * duration_;
        }
    }

    function _getScoreFromTokenId(uint256 tokenId_) internal pure returns (uint256 score_) {
        score_ = tokenId_ >> ONE_HUNDRED_TWENTY_EIGHT_UINT256;
    }

    function _lock(uint256 amount_, uint256 duration_, uint256 bonusMultiplier_, address destination_) internal returns (uint256 tokenId_) {
        // Lock the XDEFI in the contract. (Don't need SafeERC20 since XDEFI is standard ERC20).
        IERC20(xdefi).transferFrom(msg.sender, address(this), amount_);

        // Handle the lock position creation and get the tokenId of the locked position.
        tokenId_ = _createLockedPosition(amount_, duration_, bonusMultiplier_, destination_);
    }

    function _relock(uint256 lockAmount_, uint256 amountUnlocked_, uint256 duration_, uint256 bonusMultiplier_, address destination_) internal returns (uint256 tokenId_) {
        // Throw convenient error if trying to re-lock more than was unlocked. `amountUnlocked_ - lockAmount_` cannot revert below now.
        if (lockAmount_ > amountUnlocked_) revert InsufficientAmountUnlocked();

        // Handle the lock position creation and get the tokenId of the locked position.
        tokenId_ = _createLockedPosition(lockAmount_, duration_, bonusMultiplier_, destination_);

        unchecked {
            if (amountUnlocked_ - lockAmount_ != ZERO_UINT256) {
                // Send the excess XDEFI to the destination, if needed. (Don't need SafeERC20 since XDEFI is standard ERC20).
                IERC20(xdefi).transfer(destination_, amountUnlocked_ - lockAmount_);
            }
        }
    }

    function _unlockBatch(address account_, uint256[] calldata tokenIds_) internal returns (uint256 amountUnlocked_) {
        // Revert if trying to unlock 0 positions, which would result in a successful, yet wasted useless transaction.
        if (tokenIds_.length == ZERO_UINT256) revert EmptyArray();

        // Handle the unlock for each position and accumulate the unlocked amount.
        for (uint256 i; i < tokenIds_.length;) {
            unchecked {
                amountUnlocked_ += _destroyLockedPosition(account_, tokenIds_[i]);

                ++i;
            }
        }
    }

    function _updateDistributableXDEFI() internal returns (uint256 increaseInDistributableXDEFI_) {
        uint256 xdefiBalance = IERC20(xdefi).balanceOf(address(this));
        uint256 previousDistributableXDEFI = distributableXDEFI;

        unchecked {
            uint256 currentDistributableXDEFI = xdefiBalance > totalDepositedXDEFI ? xdefiBalance - totalDepositedXDEFI : ZERO_UINT256;

            // Return 0 early if distributable XDEFI did not change.
            if (currentDistributableXDEFI == previousDistributableXDEFI) return ZERO_UINT256;

            // Set distributableXDEFI.
            distributableXDEFI = currentDistributableXDEFI;

            // Return 0 early if distributable XDEFI decreased.
            if (currentDistributableXDEFI < previousDistributableXDEFI) return ZERO_UINT256;

            increaseInDistributableXDEFI_ = currentDistributableXDEFI - previousDistributableXDEFI;
        }
    }

    function _withdrawableGiven(uint256 units_, uint256 depositedXDEFI_, uint256 pointsCorrection_) internal view returns (uint256 withdrawableXDEFI_) {
        // NOTE: In a worst case (120k XDEFI locked at 2.55x bonus, 120k XDEFI reward, cycled 1 million times) `_pointsPerUnit * units_` is smaller than 2**248.
        //       Since `pointsCorrection_` is always less than `_pointsPerUnit * units_`, (because `_pointsPerUnit` only grows) there is no underflow on the subtraction.
        //       Finally, `depositedXDEFI_` is at most 88 bits, so after the division by a very large `POINTS_MULTIPLIER`, this doesn't need to be checked.
        unchecked {
            withdrawableXDEFI_ =
                (
                    (
                        (
                            _pointsPerUnit * units_
                        ) - pointsCorrection_
                    ) >> POINTS_MULTIPLIER_BITS
                ) + depositedXDEFI_;
        }
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.10;

interface IEIP2612 {

    function permit(
        address owner_,
        address spender_,
        uint256 value_,
        uint256 deadline_,
        uint8 v_,
        bytes32 r_,
        bytes32 s_
    ) external;

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

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