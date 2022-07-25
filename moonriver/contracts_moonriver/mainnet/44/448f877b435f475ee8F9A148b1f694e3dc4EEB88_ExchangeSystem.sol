/**
 *Submitted for verification at moonriver.moonscan.io on 2022-03-29
*/

// SPDX-License-Identifier: MIT

// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// File @openzeppelin/contracts-upgradeable/utils/[email protected]

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {}

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    uint256[50] private __gap;
}

// File @openzeppelin/contracts-upgradeable/access/[email protected]

pragma solidity ^0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    uint256[49] private __gap;
}

// File @openzeppelin/contracts-upgradeable/utils/math/[email protected]

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
library SafeMathUpgradeable {
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

// File @openzeppelin/contracts/token/ERC20/[email protected]

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

// File contracts/interfaces/IAsset.sol

pragma solidity >=0.6.12 <0.9.0;

interface IAsset {
    function keyName() external view returns (bytes32);

    function mint(address account, uint256 amount) external;

    function burn(address account, uint256 amount) external;

    function move(
        address from,
        address to,
        uint256 amount
    ) external;
}

// File contracts/interfaces/IAssetRegistry.sol

pragma solidity >=0.6.12 <0.9.0;

interface IAssetRegistry {
    function assetSymbolToAddresses(bytes32 key) external view returns (address value);

    function perpAddresses(bytes32 symbol) external view returns (address);

    function perpSymbols(address perpAddress) external view returns (bytes32);

    function isPerpAddressRegistered(address perpAddress) external view returns (bool);

    function totalAssetsInUsd() external view returns (uint256 rTotal);
}

// File contracts/interfaces/IConfig.sol

pragma solidity >=0.6.12 <0.9.0;

interface IConfig {
    function getUint(bytes32 key) external view returns (uint);
}

// File contracts/interfaces/IOracleRouter.sol

pragma solidity >=0.6.12 <0.9.0;

interface IOracleRouter {
    function getPrice(bytes32 currencyKey) external view returns (uint);

    function exchange(
        bytes32 sourceKey,
        uint sourceAmount,
        bytes32 destKey
    ) external view returns (uint);
}

// File contracts/libraries/SafeDecimalMath.sol

pragma solidity >=0.8.0 <0.9.0;

library SafeDecimalMath {
    uint8 internal constant decimals = 18;
    uint8 internal constant highPrecisionDecimals = 27;

    uint internal constant UNIT = 10**uint(decimals);

    uint internal constant PRECISE_UNIT = 10**uint(highPrecisionDecimals);
    uint private constant UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR = 10**uint(highPrecisionDecimals - decimals);

    function unit() internal pure returns (uint) {
        return UNIT;
    }

    function preciseUnit() internal pure returns (uint) {
        return PRECISE_UNIT;
    }

    function multiplyDecimal(uint x, uint y) internal pure returns (uint) {
        return (x * y) / UNIT;
    }

    function _multiplyDecimalRound(
        uint x,
        uint y,
        uint precisionUnit
    ) private pure returns (uint) {
        uint quotientTimesTen = (x * y) / (precisionUnit / 10);

        if (quotientTimesTen % 10 >= 5) {
            quotientTimesTen += 10;
        }

        return quotientTimesTen / 10;
    }

    function multiplyDecimalRoundPrecise(uint x, uint y) internal pure returns (uint) {
        return _multiplyDecimalRound(x, y, PRECISE_UNIT);
    }

    function multiplyDecimalRound(uint x, uint y) internal pure returns (uint) {
        return _multiplyDecimalRound(x, y, UNIT);
    }

    function divideDecimal(uint x, uint y) internal pure returns (uint) {
        return (x * UNIT) / y;
    }

    function _divideDecimalRound(
        uint x,
        uint y,
        uint precisionUnit
    ) private pure returns (uint) {
        uint resultTimesTen = (x * (precisionUnit * 10)) / y;

        if (resultTimesTen % 10 >= 5) {
            resultTimesTen += 10;
        }

        return resultTimesTen / 10;
    }

    function divideDecimalRound(uint x, uint y) internal pure returns (uint) {
        return _divideDecimalRound(x, y, UNIT);
    }

    function divideDecimalRoundPrecise(uint x, uint y) internal pure returns (uint) {
        return _divideDecimalRound(x, y, PRECISE_UNIT);
    }

    function decimalToPreciseDecimal(uint i) internal pure returns (uint) {
        return i * UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR;
    }

    function preciseDecimalToDecimal(uint i) internal pure returns (uint) {
        uint quotientTimesTen = i / (UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR / 10);

        if (quotientTimesTen % 10 >= 5) {
            quotientTimesTen += 10;
        }

        return quotientTimesTen / 10;
    }
}

// File contracts/ExchangeSystem.sol

pragma solidity =0.8.9;

contract ExchangeSystem is OwnableUpgradeable {
    using SafeDecimalMath for uint256;
    using SafeMathUpgradeable for uint256;

    event ExchangeAsset(
        address fromAddr,
        bytes32 sourceKey,
        uint sourceAmount,
        address destAddr,
        bytes32 destKey,
        uint destRecived,
        uint feeForPool,
        uint feeForFoundation
    );
    event FoundationFeeHolderChanged(address oldHolder, address newHolder);
    event ExitPositionOnlyChanged(bool oldValue, bool newValue);
    event PendingExchangeAdded(
        uint256 id,
        address fromAddr,
        address destAddr,
        uint256 fromAmount,
        bytes32 fromCurrency,
        bytes32 toCurrency
    );
    event PendingExchangeSettled(
        uint256 id,
        address settler,
        uint256 destRecived,
        uint256 feeForPool,
        uint256 feeForFoundation
    );
    event PendingExchangeReverted(uint256 id);
    event AssetExitPositionOnlyChanged(bytes32 asset, bool newValue);

    struct PendingExchangeEntry {
        uint64 id;
        uint64 timestamp;
        address fromAddr;
        address destAddr;
        uint256 fromAmount;
        bytes32 fromCurrency;
        bytes32 toCurrency;
    }

    IAssetRegistry mAssets;
    IOracleRouter mPrices;
    IConfig mConfig;
    address mRewardSys;
    address foundationFeeHolder;

    bool public exitPositionOnly;

    uint256 public lastPendingExchangeEntryId;
    mapping(uint256 => PendingExchangeEntry) public pendingExchangeEntries;

    mapping(bytes32 => bool) assetExitPositionOnly;

    bytes32 private constant CONFIG_FEE_SPLIT = "FoundationFeeSplit";
    bytes32 private constant CONFIG_TRADE_SETTLEMENT_DELAY = "TradeSettlementDelay";
    bytes32 private constant CONFIG_TRADE_REVERT_DELAY = "TradeRevertDelay";

    bytes32 private constant LUSD_KEY = "cUSD";

    function __ExchangeSystem_init(
        IAssetRegistry _mAssets,
        IOracleRouter _mPrices,
        IConfig _mConfig,
        address _mRewardSys
    ) public initializer {
        __Ownable_init();

        require(address(_mAssets) != address(0), "ExchangeSystem: zero address");
        require(address(_mPrices) != address(0), "ExchangeSystem: zero address");
        require(address(_mConfig) != address(0), "ExchangeSystem: zero address");
        require(address(_mRewardSys) != address(0), "ExchangeSystem: zero address");

        mAssets = _mAssets;
        mPrices = _mPrices;
        mConfig = _mConfig;
        mRewardSys = _mRewardSys;
    }

    function setFoundationFeeHolder(address _foundationFeeHolder) public onlyOwner {
        require(_foundationFeeHolder != address(0), "ExchangeSystem: zero address");
        require(_foundationFeeHolder != foundationFeeHolder, "ExchangeSystem: foundation fee holder not changed");

        address oldHolder = foundationFeeHolder;
        foundationFeeHolder = _foundationFeeHolder;

        emit FoundationFeeHolderChanged(oldHolder, foundationFeeHolder);
    }

    function setExitPositionOnly(bool newValue) public onlyOwner {
        require(exitPositionOnly != newValue, "ExchangeSystem: value not changed");

        bool oldValue = exitPositionOnly;
        exitPositionOnly = newValue;

        emit ExitPositionOnlyChanged(oldValue, newValue);
    }

    function setAssetExitPositionOnly(bytes32 asset, bool newValue) public onlyOwner {
        require(assetExitPositionOnly[asset] != newValue, "LnExchangeSystem: value not changed");

        assetExitPositionOnly[asset] = newValue;

        emit AssetExitPositionOnlyChanged(asset, newValue);
    }

    function exchange(
        bytes32 sourceKey,
        uint sourceAmount,
        address destAddr,
        bytes32 destKey
    ) external {
        return _exchange(msg.sender, sourceKey, sourceAmount, destAddr, destKey);
    }

    function settle(uint256 pendingExchangeEntryId) external {
        _settle(pendingExchangeEntryId, msg.sender);
    }

    function revert(uint256 pendingExchangeEntryId) external {
        _revert(pendingExchangeEntryId, msg.sender);
    }

    function _exchange(
        address fromAddr,
        bytes32 sourceKey,
        uint sourceAmount,
        address destAddr,
        bytes32 destKey
    ) private {
        // The global flag forces everyone to trade into lUSD
        if (exitPositionOnly) {
            require(destKey == LUSD_KEY, "ExchangeSystem: can only exit position");
        }

        // The asset-specific flag only forbids entering (can sell into other assets)
        require(!assetExitPositionOnly[destKey], "LnExchangeSystem: can only exit position for this asset");

        // We don't need the return value here. It's just for preventing entering invalid trades
        getAssetByKey(destKey);

        IAsset source = getAssetByKey(sourceKey);

        // Only lock up the source amount here. Everything else will be performed in settlement.
        // The `move` method is a special variant of `transferForm` that doesn't require approval.
        source.move(fromAddr, address(this), sourceAmount);

        // Record the pending entry
        PendingExchangeEntry memory newPendingEntry = PendingExchangeEntry({
            id: uint64(++lastPendingExchangeEntryId),
            timestamp: uint64(block.timestamp),
            fromAddr: fromAddr,
            destAddr: destAddr,
            fromAmount: sourceAmount,
            fromCurrency: sourceKey,
            toCurrency: destKey
        });
        pendingExchangeEntries[uint256(newPendingEntry.id)] = newPendingEntry;

        // Emit event for off-chain indexing
        emit PendingExchangeAdded(newPendingEntry.id, fromAddr, destAddr, sourceAmount, sourceKey, destKey);
    }

    function _settle(uint256 pendingExchangeEntryId, address settler) private {
        PendingExchangeEntry memory exchangeEntry = pendingExchangeEntries[pendingExchangeEntryId];
        require(exchangeEntry.id > 0, "ExchangeSystem: pending entry not found");

        uint settlementDelay = mConfig.getUint(CONFIG_TRADE_SETTLEMENT_DELAY);
        uint256 revertDelay = mConfig.getUint(CONFIG_TRADE_REVERT_DELAY);
        require(settlementDelay > 0, "ExchangeSystem: settlement delay not set");
        require(revertDelay > 0, "ExchangeSystem: revert delay not set");
        require(block.timestamp >= exchangeEntry.timestamp + settlementDelay, "ExchangeSystem: settlement delay not passed");
        require(block.timestamp <= exchangeEntry.timestamp + revertDelay, "ExchangeSystem: trade can only be reverted now");

        IAsset source = getAssetByKey(exchangeEntry.fromCurrency);
        IAsset dest = getAssetByKey(exchangeEntry.toCurrency);
        uint destAmount = mPrices.exchange(exchangeEntry.fromCurrency, exchangeEntry.fromAmount, exchangeEntry.toCurrency);

        // This might cause a transaction to deadlock, but impact would be negligible
        require(destAmount > 0, "ExchangeSystem: zero dest amount");

        uint feeRate = mConfig.getUint(exchangeEntry.toCurrency);
        uint destRecived = destAmount.multiplyDecimal(SafeDecimalMath.unit().sub(feeRate));
        uint fee = destAmount.sub(destRecived);

        // Fee going into the pool, to be adjusted based on foundation split
        uint feeForPoolInUsd = mPrices.exchange(exchangeEntry.toCurrency, fee, LUSD_KEY);

        // Split the fee between pool and foundation when both holder and ratio are set
        uint256 foundationSplit;
        if (foundationFeeHolder == address(0)) {
            foundationSplit = 0;
        } else {
            uint256 splitRatio = mConfig.getUint(CONFIG_FEE_SPLIT);

            if (splitRatio == 0) {
                foundationSplit = 0;
            } else {
                foundationSplit = feeForPoolInUsd.multiplyDecimal(splitRatio);
                feeForPoolInUsd = feeForPoolInUsd.sub(foundationSplit);
            }
        }

        IAsset lusd = getAssetByKey(LUSD_KEY);

        if (feeForPoolInUsd > 0) lusd.mint(mRewardSys, feeForPoolInUsd);
        if (foundationSplit > 0) lusd.mint(foundationFeeHolder, foundationSplit);

        source.burn(address(this), exchangeEntry.fromAmount);
        dest.mint(exchangeEntry.destAddr, destRecived);

        delete pendingExchangeEntries[pendingExchangeEntryId];

        emit PendingExchangeSettled(exchangeEntry.id, settler, destRecived, feeForPoolInUsd, foundationSplit);
    }

    function _revert(uint256 pendingExchangeEntryId, address reverter) private {
        PendingExchangeEntry memory exchangeEntry = pendingExchangeEntries[pendingExchangeEntryId];
        require(exchangeEntry.id > 0, "ExchangeSystem: pending entry not found");

        uint256 revertDelay = mConfig.getUint(CONFIG_TRADE_REVERT_DELAY);
        require(revertDelay > 0, "ExchangeSystem: revert delay not set");
        require(block.timestamp > exchangeEntry.timestamp + revertDelay, "ExchangeSystem: revert delay not passed");

        IAsset source = getAssetByKey(exchangeEntry.fromCurrency);

        // Refund the amount locked
        source.move(address(this), exchangeEntry.fromAddr, exchangeEntry.fromAmount);

        delete pendingExchangeEntries[pendingExchangeEntryId];

        emit PendingExchangeReverted(exchangeEntry.id);
    }

    function getAssetByKey(bytes32 key) private view returns (IAsset asset) {
        address assetAddress = mAssets.assetSymbolToAddresses(key);
        require(assetAddress != address(0), "ExchangeSystem: asset no tfound");

        return IAsset(assetAddress);
    }
}