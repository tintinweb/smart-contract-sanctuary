// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "./DxlnStorage.sol";
import "../intf/I_DxlnOracle.sol";
import "../lib/DxlnTypes.sol";

/**
 * @notice Contract for read-only getters.
 */
contract DxlnGetters is DxlnStorage {
    // ============ Account Getters ============

    /**
     * @notice Get the balance of an account, without accounting for changes in the index.
     *
     * @param  account  The address of the account to query the balances of.
     * @return          The balances of the account.
     */
    function getAccountBalance(address account)
        external
        view
        returns (DxlnTypes.Balance memory)
    {
        return _BALANCES_[account];
    }

    /**
     * @notice Gets the most recently cached index of an account.
     *
     * @param  account  The address of the account to query the index of.
     * @return          The index of the account.
     */
    function getAccountIndex(address account)
        external
        view
        returns (DxlnTypes.Index memory)
    {
        return _LOCAL_INDEXES_[account];
    }

    /**
     * @notice Gets the local operator status of an operator for a particular account.
     *
     * @param  account   The account to query the operator for.
     * @param  operator  The address of the operator to query the status of.
     * @return           True if the operator is a local operator of the account, false otherwise.
     */
    function getIsLocalOperator(address account, address operator)
        external
        view
        returns (bool)
    {
        return _LOCAL_OPERATORS_[account][operator];
    }

    // ============ Global Getters ============

    /**
     * @notice Gets the global operator status of an address.
     *
     * @param  operator  The address of the operator to query the status of.
     * @return           True if the address is a global operator, false otherwise.
     */
    function getIsGlobalOperator(address operator)
        external
        view
        returns (bool)
    {
        return _GLOBAL_OPERATORS_[operator];
    }

    /**
     * @notice Gets the address of the ERC20 margin contract used for margin deposits.
     *
     * @return The address of the ERC20 token.
     */
    function getTokenContract() external view returns (address) {
        return _TOKEN_;
    }

    /**
     * @notice Gets the current address of the price oracle contract.
     *
     * @return The address of the price oracle contract.
     */
    function getOracleContract() external view returns (address) {
        return _ORACLE_;
    }

    /**
     * @notice Gets the current address of the funder contract.
     *
     * @return The address of the funder contract.
     */
    function getFunderContract() external view returns (address) {
        return _FUNDER_;
    }

    /**
     * @notice Gets the most recently cached global index.
     *
     * @return The most recently cached global index.
     */
    function getGlobalIndex() external view returns (DxlnTypes.Index memory) {
        return _GLOBAL_INDEX_;
    }

    /**
     * @notice Gets minimum collateralization ratio of the protocol.
     *
     * @return The minimum-acceptable collateralization ratio, returned as a fixed-point number with
     *  18 decimals of precision.
     */
    function getMinCollateral() external view returns (uint256) {
        return _MIN_COLLATERAL_;
    }

    /**
     * @notice Gets the status of whether final-settlement was initiated by the Admin.
     *
     * @return True if final-settlement was enabled, false otherwise.
     */
    function getFinalSettlementEnabled() external view returns (bool) {
        return _FINAL_SETTLEMENT_ENABLED_;
    }

    // ============ Authorized External Getters ============

    /**
     * @notice Gets the price returned by the oracle.
     * @dev Only able to be called by global operators.
     *
     * @return The price returned by the current price oracle.
     */
    function getOraclePrice() external view returns (uint256) {
        require(
            _GLOBAL_OPERATORS_[msg.sender],
            "Oracle price requester not global operator"
        );
        return I_DxlnOracle(_ORACLE_).getPrice();
    }

    // ============ Public Getters ============

    /**
     * @notice Gets whether an address has permissions to operate an account.
     *
     * @param  account   The account to query.
     * @param  operator  The address to query.
     * @return           True if the operator has permission to operate the account,
     *                   and false otherwise.
     */
    function hasAccountPermissions(address account, address operator)
        public
        view
        returns (bool)
    {
        return
            account == operator ||
            _GLOBAL_OPERATORS_[operator] ||
            _LOCAL_OPERATORS_[account][operator];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "../utils/Adminable.sol";
import "../lib/DxlnTypes.sol";
import "../utils/ReentrancyGuard.sol";
import "../lib/DxlnTypes.sol";

/**
 * @notice Storage contract. Contains or inherits from all contracts that have ordered storage.
 */
contract DxlnStorage is Adminable, ReentrancyGuard {
    mapping(address => DxlnTypes.Balance) internal _BALANCES_;
    mapping(address => DxlnTypes.Index) internal _LOCAL_INDEXES_;

    mapping(address => bool) internal _GLOBAL_OPERATORS_;
    mapping(address => mapping(address => bool)) internal _LOCAL_OPERATORS_;

    address internal _TOKEN_;
    address internal _ORACLE_;
    address internal _FUNDER_;

    DxlnTypes.Index internal _GLOBAL_INDEX_;
    uint256 internal _MIN_COLLATERAL_;

    bool internal _FINAL_SETTLEMENT_ENABLED_;
    uint256 internal _FINAL_SETTLEMENT_PRICE_;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

/**
 * @notice Interface that DxlnPerpetualV1 Price Oracles must implement.
 */
interface I_DxlnOracle {
    /**
     * @notice Returns the price of the underlying asset relative to the margin token.
     *
     * @return The price as a fixed-point number with 18 decimals.
     */
    function getPrice() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "../utils/BaseMath.sol";
import "../utils/SafeMath.sol";
import "../utils/SignedMath.sol";
import "./DxlnTypes.sol";
import "../utils/SafeCast.sol";

/**
 * @dev Library for manipulating DxlnTypes.Balance structs.
 */

library DxlnBalanceMath {
    using BaseMath for uint256;
    using SafeCast for uint256;
    using SafeMath for uint256;
    using SignedMath for SignedMath.Int;
    using DxlnBalanceMath for DxlnTypes.Balance;

    // ============ Constants ============

    uint256 private constant FLAG_MARGIN_IS_POSITIVE = 1 << (8 * 31);
    uint256 private constant FLAG_POSITION_IS_POSITIVE = 1 << (8 * 15);

    // ============ Functions ============

    /**
     * @dev Create a copy of the balance struct.
     */
    function copy(DxlnTypes.Balance memory balance)
        internal
        pure
        returns (DxlnTypes.Balance memory)
    {
        return
            DxlnTypes.Balance({
                marginIsPositive: balance.marginIsPositive,
                positionIsPositive: balance.positionIsPositive,
                margin: balance.margin,
                position: balance.position
            });
    }

    /**
     * @dev In-place add amount to balance.margin.
     */
    function addToMargin(DxlnTypes.Balance memory balance, uint256 amount)
        internal
        pure
    {
        SignedMath.Int memory signedMargin = balance.getMargin();
        signedMargin = signedMargin.add(amount);
        balance.setMargin(signedMargin);
    }

    /**
     * @dev In-place subtract amount from balance.margin.
     */
    function subFromMargin(DxlnTypes.Balance memory balance, uint256 amount)
        internal
        pure
    {
        SignedMath.Int memory signedMargin = balance.getMargin();
        signedMargin = signedMargin.sub(amount);
        balance.setMargin(signedMargin);
    }

    /**
     * @dev In-place add amount to balance.position.
     */
    function addToPosition(DxlnTypes.Balance memory balance, uint256 amount)
        internal
        pure
    {
        SignedMath.Int memory signedPosition = balance.getPosition();
        signedPosition = signedPosition.add(amount);
        balance.setPosition(signedPosition);
    }

    /**
     * @dev In-place subtract amount from balance.position.
     */
    function subFromPosition(DxlnTypes.Balance memory balance, uint256 amount)
        internal
        pure
    {
        SignedMath.Int memory signedPosition = balance.getPosition();
        signedPosition = signedPosition.sub(amount);
        balance.setPosition(signedPosition);
    }

    /**
     * @dev Returns the positive and negative values of the margin and position together, given a
     *  price, which is used as a conversion rate between the two currencies.
     *
     *  No rounding occurs here--the returned values are "base values" with extra precision.
     */
    function getPositiveAndNegativeValue(
        DxlnTypes.Balance memory balance,
        uint256 price
    ) internal pure returns (uint256, uint256) {
        uint256 positiveValue = 0;
        uint256 negativeValue = 0;

        // add value of margin
        if (balance.marginIsPositive) {
            positiveValue = uint256(balance.margin).mul(BaseMath.base());
        } else {
            negativeValue = uint256(balance.margin).mul(BaseMath.base());
        }

        // add value of position
        uint256 positionValue = uint256(balance.position).mul(price);
        if (balance.positionIsPositive) {
            positiveValue = positiveValue.add(positionValue);
        } else {
            negativeValue = negativeValue.add(positionValue);
        }

        return (positiveValue, negativeValue);
    }

    /**
     * @dev Returns a compressed bytes32 representation of the balance for logging.
     */
    function toBytes32(DxlnTypes.Balance memory balance)
        internal
        pure
        returns (bytes32)
    {
        uint256 result = uint256(balance.position) |
            (uint256(balance.margin) << 128) |
            (balance.marginIsPositive ? FLAG_MARGIN_IS_POSITIVE : 0) |
            (balance.positionIsPositive ? FLAG_POSITION_IS_POSITIVE : 0);
        return bytes32(result);
    }

    // ============ Helper Functions ============

    /**
     * @dev Returns a SignedMath.Int version of the margin in balance.
     */
    function getMargin(DxlnTypes.Balance memory balance)
        internal
        pure
        returns (SignedMath.Int memory)
    {
        return
            SignedMath.Int({
                value: balance.margin,
                isPositive: balance.marginIsPositive
            });
    }

    /**
     * @dev Returns a SignedMath.Int version of the position in balance.
     */
    function getPosition(DxlnTypes.Balance memory balance)
        internal
        pure
        returns (SignedMath.Int memory)
    {
        return
            SignedMath.Int({
                value: balance.position,
                isPositive: balance.positionIsPositive
            });
    }

    /**
     * @dev In-place modify the signed margin value of a balance.
     */
    function setMargin(
        DxlnTypes.Balance memory balance,
        SignedMath.Int memory newMargin
    ) internal pure {
        balance.margin = newMargin.value.toUint120();
        balance.marginIsPositive = newMargin.isPositive;
    }

    /**
     * @dev In-place modify the signed position value of a balance.
     */
    function setPosition(
        DxlnTypes.Balance memory balance,
        SignedMath.Int memory newPosition
    ) internal pure {
        balance.position = newPosition.value.toUint120();
        balance.positionIsPositive = newPosition.isPositive;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

/**
 * @dev Library for common types used in PerpetualV1 contracts.
 */

library DxlnTypes {
    // ============ Structs ============

    /**
     * @dev Used to represent the global index and each account's cached index.
     *  Used to settle funding payments on a per-account basis.
     */
    struct Index {
        uint32 timestamp;
        bool isPositive;
        uint128 value;
    }

    /**
     * @dev Used to track the signed margin balance and position balance values for each account.
     */
    struct Balance {
        bool marginIsPositive;
        bool positionIsPositive;
        uint120 margin;
        uint120 position;
    }

    /**
     * @dev Used to cache commonly-used variables that are relatively gas-intensive to obtain.
     */
    struct Context {
        uint256 price;
        uint256 minCollateral;
        Index index;
    }

    /**
     * @dev Used by contracts implementing the I_DxlnTrader interface to return the result of a trade.
     */
    struct TradeResult {
        uint256 marginAmount;
        uint256 positionAmount;
        bool isBuy; // From taker's perspective.
        bytes32 traderFlags;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "../utils/SafeMath.sol";
import "./DxlnTraderConstants.sol";
import "../utils/BaseMath.sol";
import "../utils/Math.sol";
import "../impl/DxlnGetters.sol";
import "../lib/DxlnBalanceMath.sol";
import "../lib/DxlnTypes.sol";

/**
 * @notice Contract allowing accounts to be liquidated by other accounts.
 */

contract DxlnLiquidation is DxlnTraderConstants {
    using SafeMath for uint256;
    using Math for uint256;
    using DxlnBalanceMath for DxlnTypes.Balance;

    // ============ Structs ============

    struct TradeData {
        uint256 amount;
        bool isBuy; // from taker's perspective
        bool allOrNothing; // if true, will revert if maker's position is less than the amount
    }

    // ============ Events ============

    event LogLiquidated(
        address indexed maker,
        address indexed taker,
        uint256 amount,
        bool isBuy, // from taker's perspective
        uint256 oraclePrice
    );

    // ============ Immutable Storage ============

    // address of the perpetual contract
    address public _PERPETUAL_V1_;

    // ============ Constructor ============

    constructor(address perpetualV1) {
        _PERPETUAL_V1_ = perpetualV1;
    }

    // ============ External Functions ============

    /**
     * @notice Allows an account below the minimum collateralization to be liquidated by another
     *  account. This allows the account to be partially or fully subsumed by the liquidator.
     * @dev Emits the LogLiquidated event.
     *
     * @param  sender  The address that called the trade() function on PerpetualV1.
     * @param  maker   The account to be liquidated.
     * @param  taker   The account of the liquidator.
     * @param  price   The current oracle price of the underlying asset.
     * @param  data    A struct of type TradeData.
     * @return         The amounts to be traded, and flags indicating that a liquidation occurred.
     */
    function trade(
        address sender,
        address maker,
        address taker,
        uint256 price,
        bytes calldata data,
        bytes32 /* traderFlags */
    ) external returns (DxlnTypes.TradeResult memory) {
        address perpetual = _PERPETUAL_V1_;

        require(msg.sender == perpetual, "msg.sender must be PerpetualV1");

        require(
            DxlnGetters(perpetual).getIsGlobalOperator(sender),
            "Sender is not a global operator"
        );

        TradeData memory tradeData = abi.decode(data, (TradeData));
        DxlnTypes.Balance memory makerBalance = DxlnGetters(perpetual)
            .getAccountBalance(maker);

        _verifyTrade(tradeData, makerBalance, perpetual, price);

        // Bound the execution amount by the size of the maker position.
        uint256 amount = Math.min(tradeData.amount, makerBalance.position);

        // When partially liquidating the maker, maintain the same position/margin ratio.
        // Ensure the collateralization of the maker does not decrease.
        uint256 marginAmount;
        if (tradeData.isBuy) {
            marginAmount = uint256(makerBalance.margin).getFractionRoundUp(
                amount,
                makerBalance.position
            );
        } else {
            marginAmount = uint256(makerBalance.margin).getFraction(
                amount,
                makerBalance.position
            );
        }

        emit LogLiquidated(maker, taker, amount, tradeData.isBuy, price);

        return
            DxlnTypes.TradeResult({
                marginAmount: marginAmount,
                positionAmount: amount,
                isBuy: tradeData.isBuy,
                traderFlags: TRADER_FLAG_LIQUIDATION
            });
    }

    // ============ Helper Functions ============

    function _verifyTrade(
        TradeData memory tradeData,
        DxlnTypes.Balance memory makerBalance,
        address perpetual,
        uint256 price
    ) private view {
        require(
            _isUndercollateralized(makerBalance, perpetual, price),
            "Cannot liquidate since maker is not undercollateralized"
        );
        require(
            !tradeData.allOrNothing ||
                makerBalance.position >= tradeData.amount,
            "allOrNothing is set and maker position is less than amount"
        );
        require(
            tradeData.isBuy == makerBalance.positionIsPositive,
            "liquidation must not increase maker's position size"
        );

        // Disallow liquidating in the edge case where both the position and margin are negative.
        //
        // This case is not handled correctly by P1Trade. If an account is in this situation, the
        // margin should first be set to zero via a deposit, then the account should be deleveraged.
        require(
            makerBalance.marginIsPositive ||
                makerBalance.margin == 0 ||
                makerBalance.positionIsPositive ||
                makerBalance.position == 0,
            "Cannot liquidate when maker position and margin are both negative"
        );
    }

    function _isUndercollateralized(
        DxlnTypes.Balance memory balance,
        address perpetual,
        uint256 price
    ) private view returns (bool) {
        uint256 minCollateral = DxlnGetters(perpetual).getMinCollateral();
        (uint256 positive, uint256 negative) = balance
            .getPositiveAndNegativeValue(price);

        // See P1Settlement.sol for discussion of overflow risk.
        return positive.mul(BaseMath.base()) < negative.mul(minCollateral);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

/**
 * @notice Constants for traderFlags set by contracts implementing the I_DxlnTrader interface.
 */

contract DxlnTraderConstants {
    bytes32 internal constant TRADER_FLAG_ORDERS = bytes32(uint256(1));
    bytes32 internal constant TRADER_FLAG_LIQUIDATION = bytes32(uint256(2));
    bytes32 internal constant TRADER_FLAG_DELEVERAGING = bytes32(uint256(4));
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;
import "./Storage.sol";

/**
 * @dev EIP-1967 Proxy Admin contract.
 */
contract Adminable {
    /**
     * @dev Storage slot with the admin of the contract.
     *  This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1.
     */
    bytes32 internal constant ADMIN_SLOT =
        0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Modifier to check whether the `msg.sender` is the admin.
     *  If it is, it will run the function. Otherwise, it will revert.
     */
    modifier onlyAdmin() {
        require(msg.sender == getAdmin(), "Adminable: caller is not admin");
        _;
    }

    /**
     * @return The EIP-1967 proxy admin
     */
    function getAdmin() public view returns (address) {
        return address(uint160(uint256(Storage.load(ADMIN_SLOT))));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;
import "./SafeMath.sol";

/**
 * @dev Arithmetic for fixed-point numbers with 18 decimals of precision.
 */
library BaseMath {
    using SafeMath for uint256;

    // The number One in the BaseMath system.
    uint256 internal constant BASE = 10**18;

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function base() internal pure returns (uint256) {
        return BASE;
    }

    /**
     * @dev Multiplies a value by a base value (result is rounded down).
     */
    function baseMul(uint256 value, uint256 baseValue)
        internal
        pure
        returns (uint256)
    {
        return value.mul(baseValue).div(BASE);
    }

    /**
     * @dev Multiplies a value by a base value (result is rounded down).
     *  Intended as an alternaltive to baseMul to prevent overflow, when `value` is known
     *  to be divisible by `BASE`.
     */
    function baseDivMul(uint256 value, uint256 baseValue)
        internal
        pure
        returns (uint256)
    {
        return value.div(BASE).mul(baseValue);
    }

    /**
     * @dev Multiplies a value by a base value (result is rounded up).
     */
    function baseMulRoundUp(uint256 value, uint256 baseValue)
        internal
        pure
        returns (uint256)
    {
        if (value == 0 || baseValue == 0) {
            return 0;
        }
        return value.mul(baseValue).sub(1).div(BASE).add(1);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "./SafeMath.sol";

/**
 * @dev Library for non-standard Math functions.
 */

library Math {
    using SafeMath for uint256;

    // ============ Library Functions ============

    /**
     * @dev Return target * (numerator / denominator), rounded down.
     */
    function getFraction(
        uint256 target,
        uint256 numerator,
        uint256 denominator
    ) internal pure returns (uint256) {
        return target.mul(numerator).div(denominator);
    }

    /**
     * @dev Return target * (numerator / denominator), rounded up.
     */
    function getFractionRoundUp(
        uint256 target,
        uint256 numerator,
        uint256 denominator
    ) internal pure returns (uint256) {
        if (target == 0 || numerator == 0) {
            // SafeMath will check for zero denominator
            return SafeMath.div(0, denominator);
        }
        return target.mul(numerator).sub(1).div(denominator).add(1);
    }

    /**
     * @dev Returns the minimum between a and b.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the maximum between a and b.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

/**
 * @dev Library for casting uint256 to other types of uint.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     *  overflow (i.e. when the input is greater than largest uint128).
     *
     *  Counterpart to Solidity's `uint128` operator.
     *
     *  Requirements:
     *  - `value` must fit into 128 bits.
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value < 2**128, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     *  overflow (i.e. when the input is greater than largest uint120).
     *
     *  Counterpart to Solidity's `uint120` operator.
     *
     *  Requirements:
     *  - `value` must fit into 120 bits.
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value < 2**120, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     *  overflow (i.e. when the input is greater than largest uint32).
     *
     *  Counterpart to Solidity's `uint32` operator.
     *
     *  Requirements:
     *  - `value` must fit into 32 bits.
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value < 2**32, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "./SafeMath.sol";

/**
 * @dev SignedMath library for doing math with signed integers.
 */
 
library SignedMath {
    using SafeMath for uint256;

    // ============ Structs ============

    struct Int {
        uint256 value;
        bool isPositive;
    }

    // ============ Functions ============

    /**
     * @dev Returns a new signed integer equal to a signed integer plus an unsigned integer.
     */
    function add(Int memory sint, uint256 value)
        internal
        pure
        returns (Int memory)
    {
        if (sint.isPositive) {
            return Int({value: value.add(sint.value), isPositive: true});
        }
        if (sint.value < value) {
            return Int({value: value.sub(sint.value), isPositive: true});
        }
        return Int({value: sint.value.sub(value), isPositive: false});
    }

    /**
     * @dev Returns a new signed integer equal to a signed integer minus an unsigned integer.
     */
    function sub(Int memory sint, uint256 value)
        internal
        pure
        returns (Int memory)
    {
        if (!sint.isPositive) {
            return Int({value: value.add(sint.value), isPositive: false});
        }
        if (sint.value > value) {
            return Int({value: sint.value.sub(value), isPositive: true});
        }
        return Int({value: value.sub(sint.value), isPositive: false});
    }

    /**
     * @dev Returns a new signed integer equal to a signed integer plus another signed integer.
     */
    function signedAdd(Int memory augend, Int memory addend)
        internal
        pure
        returns (Int memory)
    {
        return
            addend.isPositive
                ? add(augend, addend.value)
                : sub(augend, addend.value);
    }

    /**
     * @dev Returns a new signed integer equal to a signed integer minus another signed integer.
     */
    function signedSub(Int memory minuend, Int memory subtrahend)
        internal
        pure
        returns (Int memory)
    {
        return
            subtrahend.isPositive
                ? sub(minuend, subtrahend.value)
                : add(minuend, subtrahend.value);
    }

    /**
     * @dev Returns true if signed integer `a` is greater than signed integer `b`, false otherwise.
     */
    function gt(Int memory a, Int memory b) internal pure returns (bool) {
        if (a.isPositive) {
            if (b.isPositive) {
                return a.value > b.value;
            } else {
                // True, unless both values are zero.
                return a.value != 0 || b.value != 0;
            }
        } else {
            if (b.isPositive) {
                return false;
            } else {
                return a.value < b.value;
            }
        }
    }

    /**
     * @dev Returns the minimum of signed integers `a` and `b`.
     */
    function min(Int memory a, Int memory b)
        internal
        pure
        returns (Int memory)
    {
        return gt(b, a) ? a : b;
    }

    /**
     * @dev Returns the maximum of signed integers `a` and `b`.
     */
    function max(Int memory a, Int memory b)
        internal
        pure
        returns (Int memory)
    {
        return gt(a, b) ? a : b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

/**
 * @dev Storage library for reading/writing storage at a low level.
 */

library Storage {
    /**
     * @dev Performs an SLOAD and returns the data in the slot.
     */
    function load(bytes32 slot) internal view returns (bytes32) {
        bytes32 result;
        /* solium-disable-next-line security/no-inline-assembly */
        assembly {
            result := sload(slot)
        }
        return result;
    }

    /**
     * @dev Performs an SSTORE to save the value to the slot.
     */
    function store(bytes32 slot, bytes32 value) internal {
        /* solium-disable-next-line security/no-inline-assembly */
        assembly {
            sstore(slot, value)
        }
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}