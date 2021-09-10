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

/**
 * @dev Library to unparse typed signatures.
 */

library TypedSignature {
    // ============ Constants ============

    bytes32 private constant FILE = "TypedSignature";

    // Prepended message with the length of the signed hash in decimal.
    bytes private constant PREPEND_DEC = "\x19Ethereum Signed Message:\n32";

    // Prepended message with the length of the signed hash in hexadecimal.
    bytes private constant PREPEND_HEX = "\x19Ethereum Signed Message:\n\x20";

    // Number of bytes in a typed signature.
    uint256 private constant NUM_SIGNATURE_BYTES = 66;

    // ============ Enums ============

    // Different RPC providers may implement signing methods differently, so we allow different
    // signature types depending on the string prepended to a hash before it was signed.
    enum SignatureType {
        NoPrepend, // No string was prepended.
        Decimal, // PREPEND_DEC was prepended.
        Hexadecimal, // PREPEND_HEX was prepended.
        Invalid // Not a valid type. Used for bound-checking.
    }

    // ============ Structs ============

    struct Signature {
        bytes32 r;
        bytes32 s;
        bytes2 vType;
    }

    // ============ Functions ============

    /**
     * @dev Gives the address of the signer of a hash. Also allows for the commonly prepended string
     *  of '\x19Ethereum Signed Message:\n' + message.length
     *
     * @param  hash       Hash that was signed (does not include prepended message).
     * @param  signature  Type and ECDSA signature with structure: {32:r}{32:s}{1:v}{1:type}
     * @return            Address of the signer of the hash.
     */
    function recover(bytes32 hash, Signature memory signature)
        internal
        pure
        returns (address)
    {
        SignatureType sigType = SignatureType(
            uint8(bytes1(signature.vType << 8))
        );

        bytes32 signedHash;
        if (sigType == SignatureType.NoPrepend) {
            signedHash = hash;
        } else if (sigType == SignatureType.Decimal) {
            signedHash = keccak256(abi.encodePacked(PREPEND_DEC, hash));
        } else {
            assert(sigType == SignatureType.Hexadecimal);
            signedHash = keccak256(abi.encodePacked(PREPEND_HEX, hash));
        }

        return
            ecrecover(
                signedHash,
                uint8(bytes1(signature.vType)),
                signature.r,
                signature.s
            );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "../utils/SafeMath.sol";
import "./DxlnTraderConstants.sol";
import "../utils/BaseMath.sol";
import "../lib/TypedSignature.sol";
import "../impl/DxlnGetters.sol";
import "../lib/DxlnTypes.sol";

/**
 * @notice Contract allowing trading between accounts using cryptographically signed messages.
 */

contract DxlnOrders is DxlnTraderConstants {
    using BaseMath for uint256;
    using SafeMath for uint256;

    // ============ Constants ============

    // EIP191 header for EIP712 prefix
    bytes2 private constant EIP191_HEADER = 0x1901;

    // EIP712 Domain Name value
    string private constant EIP712_DOMAIN_NAME = "DexOrders";

    // EIP712 Domain Version value
    string private constant EIP712_DOMAIN_VERSION = "1.0";

    // Hash of the EIP712 Domain Separator Schema
    /* solium-disable-next-line indentation */
    bytes32 private constant EIP712_DOMAIN_SEPARATOR_SCHEMA_HASH =
        keccak256(
            abi.encodePacked(
                "EIP712Domain(",
                "string name,",
                "string version,",
                "uint256 chainId,",
                "address verifyingContract",
                ")"
            )
        );

    // Hash of the EIP712 LimitOrder struct
    /* solium-disable-next-line indentation */
    bytes32 private constant EIP712_ORDER_STRUCT_SCHEMA_HASH =
        keccak256(
            abi.encodePacked(
                "Order(",
                "bytes32 flags,",
                "uint256 amount,",
                "uint256 limitPrice,",
                "uint256 triggerPrice,",
                "uint256 limitFee,",
                "address maker,",
                "address taker,",
                "uint256 expiration",
                ")"
            )
        );

    // Bitmasks for the flags field
    bytes32 constant FLAG_MASK_NULL = bytes32(uint256(0));
    bytes32 constant FLAG_MASK_IS_BUY = bytes32(uint256(1));
    bytes32 constant FLAG_MASK_IS_DECREASE_ONLY = bytes32(uint256(1 << 1));
    bytes32 constant FLAG_MASK_IS_NEGATIVE_LIMIT_FEE = bytes32(uint256(1 << 2));

    // ============ Enums ============

    enum OrderStatus {
        Open,
        Approved,
        Canceled
    }

    // ============ Structs ============

    struct Order {
        bytes32 flags;
        uint256 amount;
        uint256 limitPrice;
        uint256 triggerPrice;
        uint256 limitFee;
        address maker;
        address taker;
        uint256 expiration;
    }

    struct Fill {
        uint256 amount;
        uint256 price;
        uint256 fee;
        bool isNegativeFee;
    }

    struct TradeData {
        Order order;
        Fill fill;
        TypedSignature.Signature signature;
    }

    struct OrderQueryOutput {
        OrderStatus status;
        uint256 filledAmount;
    }

    // ============ Events ============

    event LogOrderCanceled(address indexed maker, bytes32 orderHash);

    event LogOrderApproved(address indexed maker, bytes32 orderHash);

    event LogOrderFilled(
        bytes32 orderHash,
        bytes32 flags,
        uint256 triggerPrice,
        Fill fill
    );

    // ============ Immutable Storage ============

    // address of the perpetual contract
    address public _PERPETUAL_V1_;

    // Hash of the EIP712 Domain Separator data
    bytes32 public _EIP712_DOMAIN_HASH_;

    // ============ Mutable Storage ============

    // order hash => filled amount (in position amount)
    mapping(bytes32 => uint256) public _FILLED_AMOUNT_;

    // order hash => status
    mapping(bytes32 => OrderStatus) public _STATUS_;

    // ============ Constructor ============

    constructor(address perpetualV1, uint256 chainId) {
        _PERPETUAL_V1_ = perpetualV1;

        /* solium-disable-next-line indentation */
        _EIP712_DOMAIN_HASH_ = keccak256(
            abi.encode(
                EIP712_DOMAIN_SEPARATOR_SCHEMA_HASH,
                keccak256(bytes(EIP712_DOMAIN_NAME)),
                keccak256(bytes(EIP712_DOMAIN_VERSION)),
                chainId,
                address(this)
            )
        );
    }

    // ============ External Functions ============

    /**
     * @notice Allows an account to take an order cryptographically signed by a different account.
     * @dev Emits the LogOrderFilled event.
     *
     * @param  sender  The address that called the trade() function on PerpetualV1.
     * @param  maker   The maker of the order.
     * @param  taker   The taker of the order.
     * @param  price   The current oracle price of the underlying asset.
     * @param  data    A struct of type TradeData.
     * @return         The assets to be traded and traderFlags that indicate that a trade occurred.
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

        if (taker != sender) {
            require(
                DxlnGetters(perpetual).hasAccountPermissions(taker, sender),
                "Sender does not have permissions for the taker"
            );
        }

        TradeData memory tradeData = abi.decode(data, (TradeData));
        bytes32 orderHash = _getOrderHash(tradeData.order);

        // validations
        _verifyOrderStateAndSignature(tradeData, orderHash);
        _verifyOrderRequest(tradeData, maker, taker, perpetual, price);

        // set _FILLED_AMOUNT_
        uint256 oldFilledAmount = _FILLED_AMOUNT_[orderHash];
        uint256 newFilledAmount = oldFilledAmount.add(tradeData.fill.amount);
        require(
            newFilledAmount <= tradeData.order.amount,
            "Cannot overfill order"
        );
        _FILLED_AMOUNT_[orderHash] = newFilledAmount;

        emit LogOrderFilled(
            orderHash,
            tradeData.order.flags,
            tradeData.order.triggerPrice,
            tradeData.fill
        );

        // Order fee is denoted as a percentage of execution price.
        // Convert into an amount per unit position.
        uint256 fee = tradeData.fill.fee.baseMul(tradeData.fill.price);

        // `isBuyOrder` is from the maker's perspective.
        bool isBuyOrder = _isBuy(tradeData.order);
        uint256 marginPerPosition = (isBuyOrder == tradeData.fill.isNegativeFee)
            ? tradeData.fill.price.sub(fee)
            : tradeData.fill.price.add(fee);

        return
            DxlnTypes.TradeResult({
                marginAmount: tradeData.fill.amount.baseMul(marginPerPosition),
                positionAmount: tradeData.fill.amount,
                isBuy: !isBuyOrder,
                traderFlags: TRADER_FLAG_ORDERS
            });
    }

    /**
     * @notice On-chain approves an order.
     * @dev Emits the LogOrderApproved event.
     *
     * @param  order  The order that will be approved.
     */
    function approveOrder(Order calldata order) external {
        require(
            msg.sender == order.maker,
            "Order cannot be approved by non-maker"
        );
        bytes32 orderHash = _getOrderHash(order);
        require(
            _STATUS_[orderHash] != OrderStatus.Canceled,
            "Canceled order cannot be approved"
        );
        _STATUS_[orderHash] = OrderStatus.Approved;
        emit LogOrderApproved(msg.sender, orderHash);
    }

    /**
     * @notice On-chain cancels an order.
     * @dev Emits the LogOrderCanceled event.
     *
     * @param  order  The order that will be permanently canceled.
     */
    function cancelOrder(Order calldata order) external {
        require(
            msg.sender == order.maker,
            "Order cannot be canceled by non-maker"
        );
        bytes32 orderHash = _getOrderHash(order);
        _STATUS_[orderHash] = OrderStatus.Canceled;
        emit LogOrderCanceled(msg.sender, orderHash);
    }

    // ============ Getter Functions ============

    /**
     * @notice Gets the status (open/approved/canceled) and filled amount of each order in a list.
     *
     * @param  orderHashes  A list of the hashes of the orders to check.
     * @return              A list of OrderQueryOutput structs containing the status and filled
     *                      amount of each order.
     */
    function getOrdersStatus(bytes32[] calldata orderHashes)
        external
        view
        returns (OrderQueryOutput[] memory)
    {
        OrderQueryOutput[] memory result = new OrderQueryOutput[](
            orderHashes.length
        );
        for (uint256 i = 0; i < orderHashes.length; i++) {
            bytes32 orderHash = orderHashes[i];
            result[i] = OrderQueryOutput({
                status: _STATUS_[orderHash],
                filledAmount: _FILLED_AMOUNT_[orderHash]
            });
        }
        return result;
    }

    // ============ Helper Functions ============

    function _verifyOrderStateAndSignature(
        TradeData memory tradeData,
        bytes32 orderHash
    ) private view {
        OrderStatus orderStatus = _STATUS_[orderHash];

        if (orderStatus == OrderStatus.Open) {
            require(
                tradeData.order.maker ==
                    TypedSignature.recover(orderHash, tradeData.signature),
                "Order has an invalid signature"
            );
        } else {
            require(
                orderStatus != OrderStatus.Canceled,
                "Order was already canceled"
            );
            assert(orderStatus == OrderStatus.Approved);
        }
    }

    function _verifyOrderRequest(
        TradeData memory tradeData,
        address maker,
        address taker,
        address perpetual,
        uint256 price
    ) private view {
        require(
            tradeData.order.maker == maker,
            "Order maker does not match maker"
        );
        require(
            tradeData.order.taker == taker ||
                tradeData.order.taker == address(0),
            "Order taker does not match taker"
        );
        require(
            tradeData.order.expiration >= block.timestamp ||
                tradeData.order.expiration == 0,
            "Order has expired"
        );

        // `isBuyOrder` is from the maker's perspective.
        bool isBuyOrder = _isBuy(tradeData.order);
        bool validPrice = isBuyOrder
            ? tradeData.fill.price <= tradeData.order.limitPrice
            : tradeData.fill.price >= tradeData.order.limitPrice;
        require(validPrice, "Fill price is invalid");

        bool validFee = _isNegativeLimitFee(tradeData.order)
            ? tradeData.fill.isNegativeFee &&
                tradeData.fill.fee >= tradeData.order.limitFee
            : tradeData.fill.isNegativeFee ||
                tradeData.fill.fee <= tradeData.order.limitFee;
        require(validFee, "Fill fee is invalid");

        if (tradeData.order.triggerPrice != 0) {
            bool validTriggerPrice = isBuyOrder
                ? tradeData.order.triggerPrice <= price
                : tradeData.order.triggerPrice >= price;
            require(validTriggerPrice, "Trigger price has not been reached");
        }

        if (_isDecreaseOnly(tradeData.order)) {
            DxlnTypes.Balance memory balance = DxlnGetters(perpetual)
                .getAccountBalance(maker);
            require(
                isBuyOrder != balance.positionIsPositive &&
                    tradeData.fill.amount <= balance.position,
                "Fill does not decrease position"
            );
        }
    }

    /**
     * @dev Returns the EIP712 hash of an order.
     */
    function _getOrderHash(Order memory order) private view returns (bytes32) {
        // compute the overall signed struct hash
        /* solium-disable-next-line indentation */
        bytes32 structHash = keccak256(
            abi.encode(EIP712_ORDER_STRUCT_SCHEMA_HASH, order)
        );

        // compute eip712 compliant hash
        /* solium-disable-next-line indentation */
        return
            keccak256(
                abi.encodePacked(
                    EIP191_HEADER,
                    _EIP712_DOMAIN_HASH_,
                    structHash
                )
            );
    }

    function _isBuy(Order memory order) private pure returns (bool) {
        return (order.flags & FLAG_MASK_IS_BUY) != FLAG_MASK_NULL;
    }

    function _isDecreaseOnly(Order memory order) private pure returns (bool) {
        return (order.flags & FLAG_MASK_IS_DECREASE_ONLY) != FLAG_MASK_NULL;
    }

    function _isNegativeLimitFee(Order memory order)
        private
        pure
        returns (bool)
    {
        return
            (order.flags & FLAG_MASK_IS_NEGATIVE_LIMIT_FEE) != FLAG_MASK_NULL;
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