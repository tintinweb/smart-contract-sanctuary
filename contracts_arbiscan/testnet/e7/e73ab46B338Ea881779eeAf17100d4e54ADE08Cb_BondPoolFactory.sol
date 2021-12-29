// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./BondPool.sol";
import "./interfaces/IBondPoolFactory.sol";
import "./interfaces/IPCVTreasury.sol";
import "../utils/Ownable.sol";

contract BondPoolFactory is IBondPoolFactory, Ownable {
    address public immutable override apeXToken;
    address public immutable override treasury;
    address public override priceOracle;
    uint256 public override maxPayout;
    uint256 public override discount; // [0, 10000]
    uint256 public override vestingTerm;

    address[] public override allPools;
    // amm => pool
    mapping(address => address) public override getPool;

    constructor(
        address apeXToken_,
        address treasury_,
        address priceOracle_,
        uint256 maxPayout_,
        uint256 discount_,
        uint256 vestingTerm_
    ) {
        owner = msg.sender;
        apeXToken = apeXToken_;
        treasury = treasury_;
        priceOracle = priceOracle_;
        maxPayout = maxPayout_;
        discount = discount_;
        vestingTerm = vestingTerm_;
    }

    function setPriceOracle(address newOracle) external override onlyOwner {
        require(newOracle != address(0), "BondPoolFactory.setPriceOracle: ZERO_ADDRESS");
        emit PriceOracleUpdated(priceOracle, newOracle);
        priceOracle = newOracle;
    }

    function updateParams(
        uint256 maxPayout_,
        uint256 discount_,
        uint256 vestingTerm_
    ) external override onlyOwner {
        maxPayout = maxPayout_;
        require(discount_ <= 10000, "BondPoolFactory.updateParams: DISCOUNT_OVER_100%");
        discount = discount_;
        require(vestingTerm_ >= 129600, "BondPoolFactory.updateParams: MUST_BE_LONGER_THAN_36_HOURS");
        vestingTerm = vestingTerm_;
    }

    function createPool(address amm) external override onlyOwner returns (address) {
        require(getPool[amm] == address(0), "BondPoolFactory.createPool: POOL_EXIST");
        address pool = address(new BondPool(owner, apeXToken, treasury, priceOracle, amm, maxPayout, discount, vestingTerm));
        getPool[amm] = pool;
        allPools.push(pool);
        IPCVTreasury(treasury).addLiquidityToken(amm);
        IPCVTreasury(treasury).addBondPool(pool);
        emit BondPoolCreated(amm, pool);
        return pool;
    }

    function allPoolsLength() external view override returns (uint256) {
        return allPools.length;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./interfaces/IBondPool.sol";
import "./interfaces/IPCVTreasury.sol";
import "../core/interfaces/IAmm.sol";
import "../core/interfaces/IERC20.sol";
import "../core/interfaces/IPriceOracle.sol";
import "../libraries/TransferHelper.sol";
import "../libraries/FullMath.sol";
import "../utils/Ownable.sol";

contract BondPool is IBondPool, Ownable {
    address public immutable override apeXToken;
    address public immutable override treasury;
    address public immutable override amm;
    address public override priceOracle;
    uint256 public override maxPayout;
    uint256 public override discount; // [0, 10000]
    uint256 public override vestingTerm; // in seconds
    bool public override bondPaused;

    mapping(address => Bond) private bondInfo; // stores bond information for depositor

    constructor(
        address owner_,
        address apeXToken_,
        address treasury_,
        address priceOracle_,
        address amm_,
        uint256 maxPayout_,
        uint256 discount_,
        uint256 vestingTerm_
    ) {
        owner = owner_;
        require(apeXToken_ != address(0), "BondPool: ZERO_ADDRESS");
        apeXToken = apeXToken_;
        require(treasury_ != address(0), "BondPool: ZERO_ADDRESS");
        treasury = treasury_;
        require(priceOracle_ != address(0), "BondPool: ZERO_ADDRESS");
        priceOracle = priceOracle_;
        require(amm_ != address(0), "BondPool: ZERO_ADDRESS");
        amm = amm_;
        maxPayout = maxPayout_;
        require(discount_ <= 10000, "BondPool: DISCOUNT_OVER_100%");
        discount = discount_;
        require(vestingTerm_ >= 129600, "BondPool: MUST_BE_LONGER_THAN_36_HOURS");
        vestingTerm = vestingTerm_;
    }

    function setBondPaused(bool state) external override onlyOwner {
        bondPaused = state;
        emit BondPaused(state);
    }

    function setPriceOracle(address newOracle) external override onlyOwner {
        require(newOracle != address(0), "BondPool.setPriceOracle: ZERO_ADDRESS");
        emit PriceOracleChanged(priceOracle, newOracle);
        priceOracle = newOracle;
    }

    function setMaxPayout(uint256 maxPayout_) external override onlyOwner {
        emit MaxPayoutChanged(maxPayout, maxPayout_);
        maxPayout = maxPayout_;
    }

    function setDiscount(uint256 discount_) external override onlyOwner {
        require(discount_ <= 10000, "BondPool.setDiscount: OVER_100%");
        emit DiscountChanged(discount, discount_);
        discount = discount_;
    }

    function setVestingTerm(uint256 vestingTerm_) external override onlyOwner {
        require(vestingTerm_ >= 129600, "BondPool.setVestingTerm: MUST_BE_LONGER_THAN_36_HOURS");
        emit VestingTermChanged(vestingTerm, vestingTerm_);
        vestingTerm = vestingTerm_;
    }

    function deposit(
        address depositor,
        uint256 depositAmount,
        uint256 minPayout
    ) external override returns (uint256 payout) {
        require(!bondPaused, "BondPool.deposit: BOND_PAUSED");
        require(depositor != address(0), "BondPool.deposit: ZERO_ADDRESS");
        require(depositAmount > 0, "BondPool.deposit: ZERO_AMOUNT");

        TransferHelper.safeTransferFrom(IAmm(amm).baseToken(), msg.sender, amm, depositAmount);
        (uint256 actualDepositAmount, , uint256 liquidity) = IAmm(amm).mint(address(this));
        require(actualDepositAmount == depositAmount, "BondPool.deposit: AMOUNT_NOT_MATCH");

        payout = payoutFor(depositAmount);
        require(payout >= minPayout, "BondPool.deposit: UNDER_MIN_LAYOUT");
        require(payout <= maxPayout, "BondPool.deposit: OVER_MAX_PAYOUT");
        maxPayout -= payout;
        TransferHelper.safeApprove(amm, treasury, liquidity);
        IPCVTreasury(treasury).deposit(amm, liquidity, payout);

        bondInfo[depositor] = Bond({
            payout: bondInfo[depositor].payout + payout,
            vesting: vestingTerm,
            lastBlockTime: block.timestamp,
            paidAmount: bondInfo[depositor].paidAmount + depositAmount
        });
        emit BondCreated(depositor, depositAmount, payout, block.timestamp + vestingTerm);
    }

    function redeem(address depositor) external override returns (uint256 payout) {
        Bond memory info = bondInfo[depositor];
        uint256 percentVested = percentVestedFor(depositor); // (blocks since last interaction / vesting term remaining)

        if (percentVested >= 10000) {
            // if fully vested
            delete bondInfo[depositor]; // delete user info
            payout = info.payout;
            emit BondRedeemed(depositor, payout, 0); // emit bond data
            TransferHelper.safeTransfer(apeXToken, depositor, payout);
        } else {
            // if unfinished
            // calculate payout vested
            payout = (info.payout * percentVested) / 10000;

            // store updated deposit info
            bondInfo[depositor] = Bond({
                payout: info.payout - payout,
                vesting: info.vesting - (block.timestamp - info.lastBlockTime),
                lastBlockTime: block.timestamp,
                paidAmount: info.paidAmount
            });

            emit BondRedeemed(depositor, payout, bondInfo[depositor].payout);
            TransferHelper.safeTransfer(apeXToken, depositor, payout);
        }
    }

    function bondInfoFor(address depositor) external view override returns (Bond memory) {
        return bondInfo[depositor];
    }

    // calculate how many APEX out for input amount of base token
    // marketPrice = amount / marketApeXAmount
    // bondPrice = marketPrice * (1 - discount) = amount * (1 - discount) / marketApeXAmount
    // payout = amount / bondPrice = marketApeXAmount / (1 - discount))
    function payoutFor(uint256 amount) public view override returns (uint256 payout) {
        address baseToken = IAmm(amm).baseToken();
        uint256 marketApeXAmount = IPriceOracle(priceOracle).quote(baseToken, apeXToken, amount);
        payout = marketApeXAmount * 10000 / (10000 - discount);
    }

    function percentVestedFor(address depositor) public view override returns (uint256 percentVested) {
        Bond memory bond = bondInfo[depositor];
        uint256 deltaSinceLast = block.timestamp - bond.lastBlockTime;
        uint256 vesting = bond.vesting;
        if (vesting > 0) {
            percentVested = (deltaSinceLast * 10000) / vesting;
        } else {
            percentVested = 0;
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title The interface for a bond pool factory
/// @notice For create bond pool
interface IBondPoolFactory {
    event BondPoolCreated(address indexed amm, address indexed pool);
    event PriceOracleUpdated(address indexed oldOracle, address indexed newOracle);

    function setPriceOracle(address newOracle) external;

    function updateParams(
        uint256 maxPayout_,
        uint256 discount_,
        uint256 vestingTerm_
    ) external;

    function createPool(address amm) external returns (address);

    function apeXToken() external view returns (address);

    function treasury() external view returns (address);

    function priceOracle() external view returns (address);

    function maxPayout() external view returns (uint256);

    function discount() external view returns (uint256);

    function vestingTerm() external view returns (uint256);

    function getPool(address amm) external view returns (address);

    function allPools(uint256) external view returns (address);

    function allPoolsLength() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IPCVTreasury {
    event NewLiquidityToken(address indexed lpToken);
    event NewBondPool(address indexed pool);
    event Deposit(address indexed pool, address indexed lpToken, uint256 amountIn, uint256 payout);
    event Withdraw(address indexed lpToken, address indexed policy, uint256 amount);
    event ApeXGranted(address indexed to, uint256 amount);

    function apeXToken() external view returns (address);

    function isLiquidityToken(address) external view returns (bool);

    function isBondPool(address) external view returns (bool);

    function addLiquidityToken(address lpToken) external;

    function addBondPool(address pool) external;

    function deposit(
        address lpToken,
        uint256 amountIn,
        uint256 payout
    ) external;

    function withdraw(
        address lpToken,
        address policy,
        uint256 amount,
        bytes calldata data
    ) external;

    function grantApeX(address to, uint256 amount) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

abstract contract Ownable {
    address public owner;
    address public pendingOwner;

    event NewOwner(address indexed oldOwner, address indexed newOwner);
    event NewPendingOwner(address indexed oldPendingOwner, address indexed newPendingOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: REQUIRE_OWNER");
        _;
    }

    function setPendingOwner(address newPendingOwner) external onlyOwner {
        require(pendingOwner != newPendingOwner, "Ownable: ALREADY_SET");
        emit NewPendingOwner(pendingOwner, newPendingOwner);
        pendingOwner = newPendingOwner;
    }

    function acceptOwner() external {
        require(msg.sender == pendingOwner, "Ownable: REQUIRE_PENDING_OWNER");
        address oldOwner = owner;
        address oldPendingOwner = pendingOwner;
        owner = pendingOwner;
        pendingOwner = address(0);
        emit NewOwner(oldOwner, owner);
        emit NewPendingOwner(oldPendingOwner, pendingOwner);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title The interface for a bond pool
/// @notice A bond pool always be created by bond pool factory
interface IBondPool {
    /// @notice Emitted when a user finish deposit for a bond
    /// @param depositor User's address
    /// @param deposit The base token amount paid by sender
    /// @param payout The amount of apeX token for this bond
    /// @param expires The bonding's expire timestamp
    event BondCreated(address depositor, uint256 deposit, uint256 payout, uint256 expires);

    /// @notice Emitted when a redeem finish
    /// @param depositor Bonder's address
    /// @param payout The amount of apeX redeemed
    /// @param remaining The amount of apeX remaining in the bond
    event BondRedeemed(address depositor, uint256 payout, uint256 remaining);

    event BondPaused(bool state);
    event PriceOracleChanged(address indexed oldOracle, address indexed newOracle);
    event MaxPayoutChanged(uint256 oldMaxPayout, uint256 newMaxPayout);
    event DiscountChanged(uint256 oldDiscount, uint256 newDiscount);
    event VestingTermChanged(uint256 oldVestingTerm, uint256 newVestingTerm);

    // Info for bond depositor
    struct Bond {
        uint256 payout; // apeX token amount
        uint256 vesting; // bonding term, in seconds
        uint256 lastBlockTime; // last action time
        uint256 paidAmount; // base token paid
    }

    /// @notice Set bond open or pause
    function setBondPaused(bool state) external;

    /// @notice Set a new price oracle
    function setPriceOracle(address newOracle) external;

    /// @notice Only owner can set this
    function setMaxPayout(uint256 maxPayout_) external;

    /// @notice Only owner can set this
    function setDiscount(uint256 discount_) external;

    /// @notice Only owner can set this
    function setVestingTerm(uint256 vestingTerm_) external;

    /// @notice User deposit the base token to make a bond for the apeX token
    function deposit(
        address depositor,
        uint256 depositAmount,
        uint256 minPayout
    ) external returns (uint256 payout);

    /// @notice For user to redeem the apeX
    function redeem(address depositor) external returns (uint256 payout);

    /// @notice ApeXToken address
    function apeXToken() external view returns (address);

    /// @notice PCV treasury contract address
    function treasury() external view returns (address);

    /// @notice Amm pool address
    function amm() external view returns (address);

    /// @notice Price oracle address
    function priceOracle() external view returns (address);

    /// @notice Left total amount of apeX token for bonding in this bond pool
    function maxPayout() external view returns (uint256);

    /// @notice Discount percent for bonding
    function discount() external view returns (uint256);

    /// @notice Bonding term in seconds, at least 129600 = 36 hours
    function vestingTerm() external view returns (uint256);

    /// @notice If is true, the bond is paused
    function bondPaused() external view returns (bool);

    /// @notice Get depositor's bond info
    function bondInfoFor(address depositor) external view returns (Bond memory);

    /// @notice Calculate how many apeX payout for input base token amount
    function payoutFor(uint256 amount) external view returns (uint256 payout);

    /// @notice Get the percent of apeX redeemable
    function percentVestedFor(address depositor) external view returns (uint256 percentVested);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IAmm {
    event Mint(address indexed sender, address indexed to, uint256 baseAmount, uint256 quoteAmount, uint256 liquidity);
    event Burn(address indexed sender, address indexed to, uint256 baseAmount, uint256 quoteAmount, uint256 liquidity);
    event Swap(address indexed inputToken, address indexed outputToken, uint256 inputAmount, uint256 outputAmount);
    event ForceSwap(address indexed inputToken, address indexed outputToken, uint256 inputAmount, uint256 outputAmount);
    event Rebase(uint256 quoteReserveBefore, uint256 quoteReserveAfter);
    event Sync(uint112 reserveBase, uint112 reserveQuote);

    // only factory can call this function
    function initialize(
        address baseToken_,
        address quoteToken_,
        address margin_
    ) external;

    function mint(address to)
        external
        returns (
            uint256 baseAmount,
            uint256 quoteAmount,
            uint256 liquidity
        );

    function burn(address to)
        external
        returns (
            uint256 baseAmount,
            uint256 quoteAmount,
            uint256 liquidity
        );

    // only binding margin can call this function
    function swap(
        address inputToken,
        address outputToken,
        uint256 inputAmount,
        uint256 outputAmount
    ) external returns (uint256[2] memory amounts);

    // only binding margin can call this function
    function forceSwap(
        address inputToken,
        address outputToken,
        uint256 inputAmount,
        uint256 outputAmount
    ) external;

    function rebase() external returns (uint256 quoteReserveAfter);

    function factory() external view returns (address);

    function config() external view returns (address);

    function baseToken() external view returns (address);

    function quoteToken() external view returns (address);

    function margin() external view returns (address);

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function lastPrice() external view returns (uint256);

    function getReserves()
        external
        view
        returns (
            uint112 reserveBase,
            uint112 reserveQuote,
            uint32 blockTimestamp
        );

    function estimateSwap(
        address inputToken,
        address outputToken,
        uint256 inputAmount,
        uint256 outputAmount
    ) external view returns (uint256[2] memory amounts);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IPriceOracle {
    function quote(
        address baseToken,
        address quoteToken,
        uint256 baseAmount
    ) external view returns (uint256 quoteAmount);

    function getIndexPrice(address amm) external view returns (uint256);

    function getMarkPrice(address amm) external view returns (uint256 price);

    function getMarkPriceAcc(
        address amm,
        uint8 beta,
        uint256 quoteAmount,
        bool negative
    ) external view returns (uint256 baseAmount);

    function getPremiumFraction(address amm) external view returns (int256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeApprove: approve failed"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeTransfer: transfer failed"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::transferFrom: transferFrom failed"
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper::safeTransferETH: ETH transfer failed");
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

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

        // todo unchecked
        unchecked {
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
            uint256 twos = (~denominator + 1) & denominator;
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