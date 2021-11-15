// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./libraries/IERC20.sol";
import "./libraries/FullMath.sol";
import "./MinterReceiver.sol";

/// @title HEX Share Market
/// @author Sam Presnal - Staker
/// @dev Sell shares priced at the original purchase rate
/// plus the applied premium
contract ShareMarket is MinterReceiver {
    IERC20 public immutable hexContract;
    address public immutable minterContract;

    /// @dev Share price is sharesBalance/heartsBalance
    /// Both balances reduce on buyShares to maintain the price,
    /// keep track of hearts owed to supplier, and determine
    /// when the listing is no longer buyable
    struct ShareListing {
        uint72 sharesBalance;
        uint72 heartsBalance;
    }
    mapping(uint40 => ShareListing) public shareListings;

    /// @dev The values are initialized onSharesMinted and
    /// onEarningsMinted respectively. Used to calculate personal
    /// earnings for a listing sharesOwned/sharesTotal*heartsEarned
    struct ShareEarnings {
        uint72 sharesTotal;
        uint72 heartsEarned;
    }
    mapping(uint40 => ShareEarnings) public shareEarnings;

    /// @notice Maintains which addresses own shares of particular stakes
    /// @dev heartsOwed is only set for the supplier to keep track of
    /// repayment for creating the stake
    struct ListingOwnership {
        uint72 sharesOwned;
        uint72 heartsOwed;
        bool isSupplier;
    }
    //keccak(stakeId, address) => ListingOwnership
    mapping(bytes32 => ListingOwnership) internal shareOwners;

    struct ShareOrder {
        uint40 stakeId;
        uint256 sharesPurchased;
        address shareReceiver;
    }

    event AddListing(
        uint40 indexed stakeId,
        address indexed supplier,
        uint256 data0 //shares | hearts << 72
    );
    event AddEarnings(uint40 indexed stakeId, uint256 heartsEarned);
    event BuyShares(
        uint40 indexed stakeId,
        address indexed owner,
        uint256 data0, //sharesPurchased | sharesOwned << 72
        uint256 data1 //sharesBalance | heartsBalance << 72
    );
    event ClaimEarnings(uint40 indexed stakeId, address indexed claimer, uint256 heartsClaimed);
    event SupplierWithdraw(uint40 indexed stakeId, address indexed supplier, uint256 heartsWithdrawn);

    uint256 private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, "LOCKED");
        unlocked = 0;
        _;
        unlocked = 1;
    }

    constructor(IERC20 _hex, address _minter) {
        hexContract = _hex;
        minterContract = _minter;
    }

    /// @inheritdoc MinterReceiver
    function onSharesMinted(
        uint40 stakeId,
        address supplier,
        uint72 stakedHearts,
        uint72 stakeShares
    ) external override {
        require(msg.sender == minterContract, "CALLER_NOT_MINTER");

        //Seed pool with shares and hearts determining the rate
        shareListings[stakeId] = ShareListing(stakeShares, stakedHearts);

        //Store total shares to calculate user earnings for claiming
        shareEarnings[stakeId].sharesTotal = stakeShares;

        //Store how many hearts the supplier needs to be paid back
        shareOwners[_hash(stakeId, supplier)] = ListingOwnership(0, stakedHearts, true);

        emit AddListing(stakeId, supplier, uint256(uint72(stakeShares)) | (uint256(uint72(stakedHearts)) << 72));
    }

    /// @inheritdoc MinterReceiver
    function onEarningsMinted(uint40 stakeId, uint72 heartsEarned) external override {
        require(msg.sender == minterContract, "CALLER_NOT_MINTER");
        //Hearts earned and total shares now stored in earnings
        //for payout calculations
        shareEarnings[stakeId].heartsEarned = heartsEarned;
        emit AddEarnings(stakeId, heartsEarned);
    }

    /// @return Supplier hearts payable resulting from user purchases
    function supplierHeartsPayable(uint40 stakeId, address supplier) external view returns (uint256) {
        uint256 heartsOwed = shareOwners[_hash(stakeId, supplier)].heartsOwed;
        if (heartsOwed == 0) return 0;
        (uint256 heartsBalance, ) = listingBalances(stakeId);
        return heartsOwed - heartsBalance;
    }

    /// @dev Used to calculate share price
    /// @return hearts Balance of hearts remaining in the listing to be input
    /// @return shares Balance of shares reamining in the listing to be sold
    function listingBalances(uint40 stakeId) public view returns (uint256 hearts, uint256 shares) {
        ShareListing memory listing = shareListings[stakeId];
        hearts = listing.heartsBalance;
        shares = listing.sharesBalance;
    }

    /// @dev Used to calculate personal earnings
    /// @return heartsEarned Total hearts earned by the stake
    /// @return sharesTotal Total shares originally on the market
    function listingEarnings(uint40 stakeId) public view returns (uint256 heartsEarned, uint256 sharesTotal) {
        ShareEarnings memory earnings = shareEarnings[stakeId];
        heartsEarned = earnings.heartsEarned;
        sharesTotal = earnings.sharesTotal;
    }

    /// @dev Shares owned is set to 0 when a user claims earnings
    /// @return Current shares owned of a particular listing
    function sharesOwned(uint40 stakeId, address owner) public view returns (uint256) {
        return shareOwners[_hash(stakeId, owner)].sharesOwned;
    }

    /// @dev Hash together stakeId and address to form a key for
    /// storage access
    /// @return Listing address storage key
    function _hash(uint40 stakeId, address addr) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(stakeId, addr));
    }

    /// @notice Allows user to purchase shares from multiple listings
    /// @dev Lumps owed HEX into single transfer
    function multiBuyShares(ShareOrder[] memory orders) external lock {
        uint256 totalHeartsOwed;
        for (uint256 i = 0; i < orders.length; i++) {
            ShareOrder memory order = orders[i];
            totalHeartsOwed += _buyShares(order.stakeId, order.shareReceiver, order.sharesPurchased);
        }

        hexContract.transferFrom(msg.sender, address(this), totalHeartsOwed);
    }

    /// @notice Allows user to purchase shares from a single listing
    /// @param stakeId HEX stakeId to purchase shares from
    /// @param shareReceiver The receiver of the shares being purchased
    /// @param sharesPurchased The number of shares to purchase
    function buyShares(
        uint40 stakeId,
        address shareReceiver,
        uint256 sharesPurchased
    ) external lock {
        uint256 heartsOwed = _buyShares(stakeId, shareReceiver, sharesPurchased);
        hexContract.transferFrom(msg.sender, address(this), heartsOwed);
    }

    function _buyShares(
        uint40 stakeId,
        address shareReceiver,
        uint256 sharesPurchased
    ) internal returns (uint256 heartsOwed) {
        require(sharesPurchased != 0, "INSUFFICIENT_SHARES_PURCHASED");

        (uint256 _heartsBalance, uint256 _sharesBalance) = listingBalances(stakeId);
        require(sharesPurchased <= _sharesBalance, "INSUFFICIENT_SHARES_AVAILABLE");

        //mulDivRoundingUp may result in 1 extra heart cost
        //any shares purchased will always cost at least 1 heart
        heartsOwed = FullMath.mulDivRoundingUp(sharesPurchased, _heartsBalance, _sharesBalance);

        //Reduce hearts owed to remaining hearts balance if it exceeds it
        //This can happen from extra 1 heart cost
        if (heartsOwed >= _heartsBalance) {
            heartsOwed = _heartsBalance;
            sharesPurchased = _sharesBalance;
        }

        //Reduce both sides of the pool to maintain price
        uint256 sharesBalance = _sharesBalance - sharesPurchased;
        uint256 heartsBalance = _heartsBalance - heartsOwed;
        shareListings[stakeId] = ShareListing(uint72(sharesBalance), uint72(heartsBalance));

        //Add shares purchased to currently owned shares if any
        bytes32 shareOwner = _hash(stakeId, shareReceiver);
        uint256 newSharesOwned = shareOwners[shareOwner].sharesOwned + sharesPurchased;
        shareOwners[shareOwner].sharesOwned = uint72(newSharesOwned);
        emit BuyShares(
            stakeId,
            shareReceiver,
            uint256(uint72(sharesPurchased)) | (uint256(uint72(newSharesOwned)) << 72),
            uint256(uint72(sharesBalance)) | (uint256(uint72(heartsBalance)) << 72)
        );
    }

    /// @notice Withdraw earnings as a supplier
    /// @param stakeId HEX stakeId to withdraw earnings from
    /// @dev Combines supplier withdraw from two sources
    /// 1. Hearts paid for supplied shares by market participants
    /// 2. Hearts earned from staking supplied shares (buyer fee %)
    /// Note: If a listing has ended, assigns all leftover shares before withdraw
    function supplierWithdraw(uint40 stakeId) external lock {
        //Track total withdrawable
        uint256 totalHeartsOwed = 0;
        bytes32 supplier = _hash(stakeId, msg.sender);
        require(shareOwners[supplier].isSupplier, "NOT_SUPPLIER");

        //Check to see if heartsOwed for sold shares in listing
        uint256 heartsOwed = uint256(shareOwners[supplier].heartsOwed);
        (uint256 heartsBalance, uint256 sharesBalance) = listingBalances(stakeId);
        //The delta between heartsOwed and heartsBalance is created
        //by users buying shares from the pool and reducing heartsBalance
        if (heartsOwed > heartsBalance) {
            //Withdraw any hearts for shares sold
            uint256 heartsPayable = heartsOwed - heartsBalance;
            uint256 newHeartsOwed = heartsOwed - heartsPayable;
            //Update hearts owed
            shareOwners[supplier].heartsOwed = uint72(newHeartsOwed);

            totalHeartsOwed = heartsPayable;
        }

        //Claim earnings including unsold shares only if the
        //earnings have already been minted
        (uint256 heartsEarned, ) = listingEarnings(stakeId);
        if (heartsEarned != 0) {
            uint256 supplierShares = shareOwners[supplier].sharesOwned;

            //Check for unsold market shares
            if (sharesBalance != 0) {
                //Add unsold shares to supplier shares
                supplierShares += sharesBalance;
                //Update storage to reflect new shares
                shareOwners[supplier].sharesOwned = uint72(supplierShares);
                //Close buying from share listing
                delete shareListings[stakeId];
                //Remove supplier hearts owed
                shareOwners[supplier].heartsOwed = 0;
                emit BuyShares(
                    stakeId,
                    msg.sender,
                    uint256(uint72(sharesBalance)) | (uint256(supplierShares) << 72),
                    0
                );
            }

            //Ensure supplier has shares (claim reverts otherwise)
            if (supplierShares != 0) totalHeartsOwed += _claimEarnings(stakeId);
        }

        require(totalHeartsOwed != 0, "NO_HEARTS_OWED");
        hexContract.transfer(msg.sender, totalHeartsOwed);
        emit SupplierWithdraw(stakeId, msg.sender, totalHeartsOwed);
    }

    /// @notice Withdraw earnings as a market participant
    /// @param stakeId HEX stakeId to withdraw earnings from
    function claimEarnings(uint40 stakeId) external lock {
        uint256 heartsEarned = _claimEarnings(stakeId);
        require(heartsEarned != 0, "NO_HEARTS_EARNED");
        hexContract.transfer(msg.sender, heartsEarned);
    }

    function _claimEarnings(uint40 stakeId) internal returns (uint256 heartsOwed) {
        (uint256 heartsEarned, uint256 sharesTotal) = listingEarnings(stakeId);
        require(sharesTotal != 0, "LISTING_NOT_FOUND");
        require(heartsEarned != 0, "SHARES_NOT_MATURE");

        bytes32 owner = _hash(stakeId, msg.sender);
        uint256 ownedShares = shareOwners[owner].sharesOwned;
        require(ownedShares != 0, "NO_SHARES_OWNED");

        heartsOwed = FullMath.mulDiv(heartsEarned, ownedShares, sharesTotal);
        shareOwners[owner].sharesOwned = 0;
        emit ClaimEarnings(stakeId, msg.sender, heartsOwed);
    }
}

// SPDX-License-Identifier: MIT

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
pragma solidity >=0.4.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            require(denominator > 0);
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        // Make sure the result is less than 2**256.
        // Also prevents denominator == 0
        require(denominator > prod1);

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0]
        // Compute remainder using mulmod
        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
        }
        // Subtract 256 bit number from 512 bit number
        assembly {
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator
        // Compute largest power of two divisor of denominator.
        // Always >= 1.
        uint256 twos = (type(uint256).max - denominator + 1) & denominator;
        // Divide denominator by power of two
        assembly {
            denominator := div(denominator, twos)
        }

        // Divide [prod1 prod0] by the factors of two
        assembly {
            prod0 := div(prod0, twos)
        }
        // Shift in bits from prod1 into prod0. For this we need
        // to flip `twos` such that it is 2**256 / twos.
        // If twos is zero, then it becomes one
        assembly {
            twos := add(div(sub(0, twos), twos), 1)
        }
        prod0 |= prod1 * twos;

        // Invert denominator mod 2**256
        // Now that denominator is an odd number, it has an inverse
        // modulo 2**256 such that denominator * inv = 1 mod 2**256.
        // Compute the inverse by starting with a seed that is correct
        // correct for four bits. That is, denominator * inv = 1 mod 2**4
        uint256 inv = (3 * denominator) ^ 2;
        // Now use Newton-Raphson iteration to improve the precision.
        // Thanks to Hensel's lifting lemma, this also works in modular
        // arithmetic, doubling the correct bits in each step.
        inv *= 2 - denominator * inv; // inverse mod 2**8
        inv *= 2 - denominator * inv; // inverse mod 2**16
        inv *= 2 - denominator * inv; // inverse mod 2**32
        inv *= 2 - denominator * inv; // inverse mod 2**64
        inv *= 2 - denominator * inv; // inverse mod 2**128
        inv *= 2 - denominator * inv; // inverse mod 2**256

        // Because the division is now exact we can divide by multiplying
        // with the modular inverse of denominator. This will give us the
        // correct result modulo 2**256. Since the precoditions guarantee
        // that the outcome is less than 2**256, this is the final result.
        // We don't need to compute the high bits of the result and prod1
        // is no longer required.
        result = prod0 * inv;
        return result;
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./libraries/ERC165.sol";

/// @title HEX Minter Receiver
/// @author Sam Presnal - Staker
/// @dev Receives shares and hearts earned from the ShareMinter
abstract contract MinterReceiver is ERC165 {
    /// @notice ERC165 ensures the minter receiver supports the interface
    /// @param interfaceId The MinterReceiver interface id
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(MinterReceiver).interfaceId || super.supportsInterface(interfaceId);
    }

    /// @notice Receives newly started stake properties
    /// @param stakeId The HEX stakeId
    /// @param supplier The reimbursement address for the supplier
    /// @param stakedHearts Hearts staked
    /// @param stakeShares Shares available
    function onSharesMinted(
        uint40 stakeId,
        address supplier,
        uint72 stakedHearts,
        uint72 stakeShares
    ) external virtual;

    /// @notice Receives newly ended stake properties
    /// @param stakeId The HEX stakeId
    /// @param heartsEarned Hearts earned from the stake
    function onEarningsMinted(uint40 stakeId, uint72 heartsEarned) external virtual;
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

