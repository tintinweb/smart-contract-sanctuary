/**
 *Submitted for verification at Etherscan.io on 2021-04-25
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

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
        uint256 twos = denominator & (~denominator + 1);
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

interface IMinterReceiver {
    function sharesMinted(
        uint40 stakeId,
        address supplier,
        uint72 stakedHearts,
        uint72 stakeShares
    ) external;

    function earningsMinted(uint40 stakeId, uint72 heartsEarned) external;
}

contract ShareMarket is IMinterReceiver {
    IERC20 public hexContract;
    address public minterContract;

    struct ShareOrder {
        uint40 stakeId;
        uint72 sharesPurchased;
        address shareReceiver;
    }
    struct ShareListing {
        uint72 heartsStaked;
        uint72 sharesTotal;
        uint72 sharesAvailable;
        uint72 heartsEarned;
        uint72 supplierHeartsOwed;
        address supplier;
        mapping(address => uint72) shareOwners;
    }
    mapping(uint40 => ShareListing) public shareListings;

    event AddListing(
        uint40 indexed stakeId,
        address indexed supplier,
        uint72 shares
    );
    event SharesUpdate(
        uint40 indexed stakeId,
        address indexed updater,
        uint72 sharesAvailable
    );
    event AddEarnings(uint40 indexed stakeId, uint72 heartsEarned);
    event BuyShares(
        uint40 indexed stakeId,
        address indexed owner,
        uint72 sharesPurchased
    );
    event ClaimEarnings(
        uint40 indexed stakeId,
        address indexed claimer,
        uint256 heartsClaimed
    );
    event SupplierWithdraw(
        uint40 indexed stakeId,
        address indexed supplier,
        uint72 heartsWithdrawn
    );

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

    function sharesOwned(uint40 stakeId, address owner)
        public
        view
        returns (uint72 shares)
    {
        return shareListings[stakeId].shareOwners[owner];
    }

    function sharesMinted(
        uint40 stakeId,
        address supplier,
        uint72 stakedHearts,
        uint72 stakeShares
    ) external override {
        require(msg.sender == minterContract, "CALLER_NOT_MINTER");

        ShareListing storage listing = shareListings[stakeId];
        listing.heartsStaked = stakedHearts;
        listing.sharesTotal = stakeShares;
        listing.sharesAvailable = stakeShares;
        listing.supplier = supplier;

        emit AddListing(stakeId, supplier, stakeShares);
    }

    function earningsMinted(uint40 stakeId, uint72 heartsEarned)
        external
        override
    {
        require(msg.sender == minterContract, "CALLER_NOT_MINTER");

        shareListings[stakeId].heartsEarned = heartsEarned;

        emit AddEarnings(stakeId, heartsEarned);
    }

    function _buyShares(
        uint40 stakeId,
        address shareReceiver,
        uint72 sharesPurchased
    ) private returns (uint72 heartsOwed) {
        require(sharesPurchased != 0, "INSUFFICIENT_SHARES_PURCHASED");

        ShareListing storage listing = shareListings[stakeId];

        require(
            sharesPurchased <= listing.sharesAvailable,
            "INSUFFICIENT_SHARES_AVAILABLE"
        );

        heartsOwed = uint72(
            FullMath.mulDivRoundingUp(
                sharesPurchased,
                listing.heartsStaked,
                listing.sharesTotal
            )
        );
        require(heartsOwed > 0, "INSUFFICIENT_HEARTS_INPUT");

        listing.sharesAvailable -= sharesPurchased;
        emit SharesUpdate(stakeId, msg.sender, listing.sharesAvailable);

        listing.shareOwners[shareReceiver] += sharesPurchased;
        listing.supplierHeartsOwed += heartsOwed;
        emit BuyShares(stakeId, shareReceiver, sharesPurchased);

        return heartsOwed;
    }

    function multiBuyShares(ShareOrder[] memory orders) external lock {
        uint256 orderCount = orders.length;
        require(orderCount <= 30, "EXCEEDED_ORDER_LIMIT");

        uint256 totalHeartsOwed;
        for (uint256 i = 0; i < orderCount; i++) {
            ShareOrder memory order = orders[i];
            totalHeartsOwed += _buyShares(
                order.stakeId,
                order.shareReceiver,
                order.sharesPurchased
            );
        }

        hexContract.transferFrom(msg.sender, address(this), totalHeartsOwed);
    }

    function buyShares(
        uint40 stakeId,
        address shareReceiver,
        uint72 sharesPurchased
    ) external lock {
        uint72 heartsOwed = _buyShares(stakeId, shareReceiver, sharesPurchased);
        hexContract.transferFrom(msg.sender, address(this), heartsOwed);
    }

    function claimEarnings(uint40 stakeId) external lock {
        ShareListing storage listing = shareListings[stakeId];
        require(listing.heartsEarned != 0, "SHARES_NOT_MATURE");

        uint72 ownedShares = listing.shareOwners[msg.sender];

        if (msg.sender == listing.supplier) {
            ownedShares += listing.sharesAvailable;
            listing.sharesAvailable = 0;
            emit SharesUpdate(stakeId, msg.sender, 0);
        }

        uint256 heartsOwed =
            FullMath.mulDiv(
                listing.heartsEarned,
                ownedShares,
                listing.sharesTotal
            );
        require(heartsOwed != 0, "NO_HEARTS_CLAIMABLE");

        listing.shareOwners[msg.sender] = 0;
        hexContract.transfer(msg.sender, heartsOwed);

        emit ClaimEarnings(stakeId, msg.sender, heartsOwed);
    }

    function supplierWithdraw(uint40 stakeId) external lock {
        ShareListing storage listing = shareListings[stakeId];
        require(msg.sender == listing.supplier, "SENDER_NOT_SUPPLIER");

        uint72 heartsOwed = listing.supplierHeartsOwed;
        require(heartsOwed != 0, "NO_HEARTS_OWED");

        listing.supplierHeartsOwed = 0;
        hexContract.transfer(msg.sender, heartsOwed);

        emit SupplierWithdraw(stakeId, msg.sender, heartsOwed);
    }
}