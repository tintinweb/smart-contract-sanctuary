// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import {IBtcRater} from "./interfaces/IBtcRater.sol";
import {BtcUtility} from "./utils/BtcUtility.sol";

interface IERC20Extension {
    function decimals() external view returns (uint8);
}

contract BtcRater is Ownable, IBtcRater {
    using SafeMath for uint256;

    mapping(address => uint256) public btcConversionRates; // For homogeneous BTC asset, the rate is 1. For Sats, the rate is 1e8

    constructor(address[] memory assets, uint256[] memory rates) public {
        for (uint256 i = 0; i < assets.length; i++) {
            btcConversionRates[assets[i]] = rates[i];
        }
    }

    function updateRates(address asset, uint256 rate) external onlyOwner {
        btcConversionRates[asset] = rate;
    }

    function calcAmountInWei(address asset, uint256 amount)
        external
        view
        override
        returns (uint256)
    {
        // e.g. wbtc&1e8, returns 1e18
        // e.g. hbtc&1e18, returns 1e18
        // e.g. sats&1e18, returns 1e18
        uint256 valueInWeiDecimal = amount.mul(
            BtcUtility.getWeiMultiplier(IERC20Extension(asset).decimals())
        );
        return valueInWeiDecimal.div(btcConversionRates[asset]);
    }

    function calcOrigAmount(address asset, uint256 weiAmount)
        external
        view
        override
        returns (uint256)
    {
        // e.g. 1e18 => wbtc&1e8
        // e.g. 1e18 => hbtc&1e18
        // e.g. 1e18 => sats&1e18
        return
            (weiAmount.mul(btcConversionRates[asset])).div(
                BtcUtility.getWeiMultiplier(IERC20Extension(asset).decimals())
            );
    }

    function getConversionRate(address asset) external view override returns (uint256) {
        return btcConversionRates[asset];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface IBtcRater {
    function getConversionRate(address asset) external view returns (uint256);

    function calcAmountInWei(address asset, uint256 amount) external view returns (uint256);

    function calcOrigAmount(address asset, uint256 weiAmount) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

library BtcUtility {
    uint256 public constant ERC20_DECIMAL = 18;
    uint256 public constant SATOSHI_DECIMAL = 8;

    function getSatsAmountMultiplier() internal pure returns (uint256) {
        return 1e10;
    }

    function getWeiMultiplier(uint256 decimal) internal pure returns (uint256) {
        require(ERC20_DECIMAL >= decimal, "asset decimal not supported");

        // the result is strictly <= 10**18, no need to check overflow
        return 10**uint256(ERC20_DECIMAL - decimal);
    }

    function getSatoshiDivisor(uint256 decimal) internal pure returns (uint256) {
        require((SATOSHI_DECIMAL <= decimal) && (decimal <= 18), "asset decimal not supported");

        // the result is strictly <= 10**10, no need to check overflow
        return 10**uint256(decimal - SATOSHI_DECIMAL);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import {SATS} from "./SATS.sol";
import {IKeeperRegistry} from "./interfaces/IKeeperRegistry.sol";
import {IBtcRater} from "./interfaces/IBtcRater.sol";
import {BtcUtility} from "./utils/BtcUtility.sol";

contract KeeperRegistry is Ownable, IKeeperRegistry, ERC20("DeCus CToken", "DCS-CT") {
    using Math for uint256;
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    address public treasury;
    address public system;
    SATS public immutable sats;
    IBtcRater public immutable btcRater;

    EnumerableSet.AddressSet assetSet;
    uint32 public MIN_KEEPER_PERIOD = 15552000; // 6 month
    uint8 public earlyExitFeeBps = 100;
    uint256 public minKeeperCollateral = 1e13;

    mapping(address => KeeperData) public keeperData;
    uint256 public overissuedTotal;
    mapping(address => uint256) public confiscations;

    modifier onlySystem() {
        require(system == _msgSender(), "require system role");
        _;
    }

    constructor(
        address[] memory _assets,
        address _sats,
        address _btcRater
    ) public {
        btcRater = IBtcRater(_btcRater);
        for (uint256 i = 0; i < _assets.length; i++) {
            _addAsset(_assets[i]);
        }
        sats = SATS(_sats);
    }

    function updateMinKeeperCollateral(uint256 amount) external onlyOwner {
        minKeeperCollateral = amount;
        emit MinCollateralUpdated(amount);
    }

    function setSystem(address _system) external onlyOwner {
        emit SystemUpdated(system, _system);
        system = _system;
    }

    function getCollateralWei(address keeper) external view override returns (uint256) {
        return keeperData[keeper].amount;
    }

    function isKeeperQualified(address keeper) external view override returns (bool) {
        return keeperData[keeper].amount > minKeeperCollateral;
    }

    function getKeeper(address keeper) external view returns (KeeperData memory) {
        return keeperData[keeper];
    }

    function addAsset(address asset) external onlyOwner {
        _addAsset(asset);
    }

    function updateEarlyExitFeeBps(uint8 bps) external onlyOwner {
        earlyExitFeeBps = bps;
        emit EarlyExitFeeBpsUpdated(bps);
    }

    function swapAsset(address asset, uint256 amount) external {
        require(assetSet.contains(asset), "assets not accepted");
        require(IERC20(asset).transferFrom(msg.sender, address(this), amount), "transfer failed");

        KeeperData storage data = keeperData[msg.sender];
        require(data.asset != address(0), "keeper not exist");
        require(data.asset != asset, "same asset");

        _refundKeeper(data);

        uint256 normalizedAmount = btcRater.calcAmountInWei(asset, amount);
        require(normalizedAmount >= data.amount, "cannot reduce amount");

        data.asset = asset;
        data.amount = normalizedAmount;
        data.joinTimestamp = _blockTimestamp();

        emit KeeperAssetSwapped(msg.sender, asset, amount);
    }

    function addKeeper(address asset, uint256 amount) external {
        require(assetSet.contains(asset), "assets not accepted");
        require(IERC20(asset).transferFrom(msg.sender, address(this), amount), "transfer failed");

        address origAsset = keeperData[msg.sender].asset;
        require((origAsset == address(0)) || (origAsset == asset), "asset not allowed");

        _addKeeper(msg.sender, asset, btcRater.calcAmountInWei(asset, amount));
    }

    function deleteKeeper() external {
        KeeperData storage data = keeperData[msg.sender];
        require(data.refCount == 0, "ref count > 0");

        _burn(msg.sender, data.amount);

        uint256 refundAmount = _refundKeeper(data);

        emit KeeperDeleted(msg.sender, data.asset, refundAmount);

        delete keeperData[msg.sender];
    }

    function importKeepers(
        uint256 amount,
        address asset,
        address[] calldata keepers
    ) external override {
        require(assetSet.contains(asset), "unknown asset");
        require(amount > 0, "amount != 0");

        uint256 totalAmount;
        uint256 normalizedAmount = btcRater.calcAmountInWei(asset, amount);
        for (uint256 i = 0; i < keepers.length; i++) {
            address keeper = keepers[i];
            if (keeper != address(0)) {
                _addKeeper(keeper, asset, normalizedAmount);
                totalAmount = totalAmount.add(amount);
            }
        }

        require(IERC20(asset).transferFrom(msg.sender, address(this), totalAmount));

        emit KeeperImported(msg.sender, asset, keepers, normalizedAmount);
    }

    function punishKeeper(address[] calldata keepers) external onlyOwner {
        for (uint256 i = 0; i < keepers.length; i++) {
            address keeper = keepers[i];
            KeeperData storage data = keeperData[keeper];

            address asset = data.asset;
            uint256 amount = data.amount;
            confiscations[asset] = confiscations[asset].add(amount);
            data.amount = 0;
            emit KeeperPunished(keeper, asset, amount);
        }
    }

    function updateTreasury(address newTreasury) external onlyOwner {
        emit TreasuryTransferred(treasury, newTreasury);
        treasury = newTreasury;
    }

    function confiscate(address[] calldata assets) external {
        require(treasury != address(0), "treasury not up yet");

        for (uint256 i = 0; i < assets.length; i++) {
            uint256 confiscation = confiscations[assets[i]];
            require(IERC20(assets[i]).transfer(treasury, confiscation), "transfer failed");
            emit Confiscated(treasury, assets[i], confiscation);
            delete confiscations[assets[i]];
        }
    }

    function addOverissue(uint256 overissuedAmount) external onlyOwner {
        require(overissuedAmount > 0, "zero overissued amount");
        uint256 satsConfiscation = confiscations[address(sats)];
        uint256 deduction = 0;
        if (satsConfiscation > 0) {
            deduction = overissuedAmount.min(satsConfiscation);
            sats.burn(deduction);
            overissuedAmount = overissuedAmount.sub(deduction);
            confiscations[address(sats)] = satsConfiscation.sub(deduction);
        }
        overissuedTotal = overissuedTotal.add(overissuedAmount);
        emit OverissueAdded(overissuedTotal, overissuedAmount, deduction);
    }

    function offsetOverissue(uint256 satsAmount) external {
        sats.burnFrom(msg.sender, satsAmount);
        overissuedTotal = overissuedTotal.sub(satsAmount);

        emit OffsetOverissued(msg.sender, satsAmount, overissuedTotal);
    }

    function incrementRefCount(address keeper) external override onlySystem {
        KeeperData storage data = keeperData[keeper];
        uint32 refCount = data.refCount + 1;
        require(refCount > data.refCount, "overflow"); // safe math
        data.refCount = refCount;
        emit KeeperRefCount(keeper, refCount);
    }

    function decrementRefCount(address keeper) external override onlySystem {
        KeeperData storage data = keeperData[keeper];
        require(data.refCount > 0); // safe math
        data.refCount = data.refCount - 1;
        emit KeeperRefCount(keeper, data.refCount);
    }

    function _addAsset(address asset) private {
        assetSet.add(asset);
        emit AssetAdded(asset);
    }

    function _blockTimestamp() internal view virtual returns (uint32) {
        return uint32(block.timestamp);
    }

    function _addKeeper(
        address keeper,
        address asset,
        uint256 amount
    ) private {
        KeeperData storage data = keeperData[keeper];
        data.asset = asset;
        data.amount = data.amount.add(amount);
        data.joinTimestamp = _blockTimestamp();

        _mint(keeper, amount);

        emit KeeperAdded(keeper, asset, amount);
    }

    function _refundKeeper(KeeperData storage data) private returns (uint256) {
        uint256 amount = data.amount;
        if (_blockTimestamp() < data.joinTimestamp + MIN_KEEPER_PERIOD) {
            amount = amount.mul(10000 - earlyExitFeeBps).div(10000);
        }
        address asset = data.asset;
        require(
            IERC20(asset).transfer(msg.sender, btcRater.calcOrigAmount(data.asset, amount)),
            "transfer failed"
        );
        return amount;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract SATS is AccessControl, ERC20Burnable, ERC20Pausable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor() public ERC20("DeCus Satoshi", "SATS") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        _setupDecimals(10);
    }

    function mint(address to, uint256 amount) public {
        require(hasRole(MINTER_ROLE, msg.sender), "require minter role");
        _mint(to, amount);
    }

    function pause() public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "require admin role");
        _pause();
    }

    function unpause() public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "require admin role");
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20, ERC20Pausable) {
        super._beforeTokenTransfer(from, to, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

interface IKeeperRegistry {
    struct KeeperData {
        uint256 amount;
        address asset;
        uint32 refCount;
        uint32 joinTimestamp;
    }

    function getCollateralWei(address keeper) external view returns (uint256);

    function isKeeperQualified(address keeper) external view returns (bool);

    function importKeepers(
        uint256 amount,
        address asset,
        address[] calldata keepers
    ) external;

    function incrementRefCount(address keeper) external;

    function decrementRefCount(address keeper) external;

    event MinCollateralUpdated(uint256 amount);

    event SystemUpdated(address oldSystem, address newSystem);
    event AssetAdded(address indexed asset);

    event KeeperAdded(address indexed keeper, address asset, uint256 amount);
    event KeeperDeleted(address indexed keeper, address asset, uint256 amount);
    event KeeperImported(address indexed from, address asset, address[] keepers, uint256 amount);
    event KeeperAssetSwapped(address indexed keeper, address asset, uint256 amount);

    event KeeperRefCount(address indexed keeper, uint256 count);
    event KeeperPunished(address indexed keeper, address asset, uint256 collateral);

    event EarlyExitFeeBpsUpdated(uint8 bps);

    event TreasuryTransferred(address indexed previousTreasury, address indexed newTreasury);
    event Confiscated(address indexed treasury, address asset, uint256 amount);
    event OverissueAdded(uint256 total, uint256 added, uint256 deduction);
    event OffsetOverissued(
        address indexed operator,
        uint256 satsAmount,
        uint256 remainingOverissueAmount
    );
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./ERC20.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    using SafeMath for uint256;

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./ERC20.sol";
import "../../utils/Pausable.sol";

/**
 * @dev ERC20 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC20Pausable is ERC20, Pausable {
    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), "ERC20Pausable: token transfer while paused");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/EnumerableSet.sol";
import "../utils/Address.sol";
import "../utils/Context.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/drafts/EIP712.sol";

import {IDeCusSystem} from "./interfaces/IDeCusSystem.sol";
import {IKeeperRegistry} from "./interfaces/IKeeperRegistry.sol";
import {IToken} from "./interfaces/IToken.sol";
import {ISwapRewarder} from "./interfaces/ISwapRewarder.sol";
import {ISwapFee} from "./interfaces/ISwapFee.sol";
import {BtcUtility} from "./utils/BtcUtility.sol";

contract DeCusSystem is AccessControl, Pausable, IDeCusSystem, EIP712("DeCus", "1.0") {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    bytes32 public constant GROUP_ROLE = keccak256("GROUP_ROLE");

    bytes32 private constant REQUEST_TYPEHASH =
        keccak256(abi.encodePacked("MintRequest(bytes32 receiptId,bytes32 txId,uint256 height)"));

    uint32 public constant KEEPER_COOLDOWN = 10 minutes;
    uint32 public constant WITHDRAW_VERIFICATION_END = 1 hours; // TODO: change to 1/2 days for production
    uint32 public constant MINT_REQUEST_GRACE_PERIOD = 1 hours; // TODO: change to 8 hours for production
    uint32 public constant GROUP_REUSING_GAP = 10 minutes; // TODO: change to 30 minutes for production
    uint32 public constant REFUND_GAP = 10 minutes; // TODO: change to 1 day or more for production

    IToken public sats;
    IKeeperRegistry public keeperRegistry;
    ISwapRewarder public rewarder;
    ISwapFee public fee;

    mapping(string => Group) private groups; // btc address -> Group
    mapping(bytes32 => Receipt) private receipts; // receipt ID -> Receipt
    mapping(address => uint32) private cooldownUntil; // keeper address -> cooldown end timestamp

    BtcRefundData private btcRefundData;

    //================================= Public =================================
    constructor() public {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        _setupRole(GROUP_ROLE, msg.sender);
    }

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "require admin role");
        _;
    }

    modifier onlyGroupAdmin() {
        require(hasRole(GROUP_ROLE, msg.sender), "require group admin role");
        _;
    }

    function initialize(
        IToken _sats,
        IKeeperRegistry _registry,
        ISwapRewarder _rewarder,
        ISwapFee _fee
    ) external onlyAdmin {
        sats = _sats;
        keeperRegistry = _registry;
        rewarder = _rewarder;
        fee = _fee;
    }

    // ------------------------------ keeper -----------------------------------
    function chill(address keeper, uint32 chillTime) external onlyAdmin {
        _cooldown(keeper, _safeAdd(_blockTimestamp(), chillTime));
    }

    function getCooldownTime(address keeper) external view returns (uint32) {
        return cooldownUntil[keeper];
    }

    // -------------------------------- group ----------------------------------
    function getGroup(string calldata btcAddress)
        external
        view
        returns (
            uint32 required,
            uint32 maxSatoshi,
            uint32 currSatoshi,
            uint32 nonce,
            address[] memory keepers,
            bytes32 workingReceiptId
        )
    {
        Group storage group = groups[btcAddress];

        keepers = new address[](group.keeperSet.length());
        for (uint8 i = 0; i < group.keeperSet.length(); i++) {
            keepers[i] = group.keeperSet.at(i);
        }

        workingReceiptId = getReceiptId(btcAddress, group.nonce);

        return (
            uint32(group.required),
            uint32(group.maxSatoshi),
            uint32(group.currSatoshi),
            uint32(group.nonce),
            keepers,
            workingReceiptId
        );
    }

    function addGroup(
        string calldata btcAddress,
        uint32 required,
        uint32 maxSatoshi,
        address[] calldata keepers
    ) external onlyGroupAdmin whenNotPaused {
        Group storage group = groups[btcAddress];
        require(group.maxSatoshi == 0, "group id already exist");

        group.required = required;
        group.maxSatoshi = maxSatoshi;
        for (uint8 i = 0; i < keepers.length; i++) {
            address keeper = keepers[i];
            require(keeperRegistry.isKeeperQualified(keeper), "keeper has insufficient collateral");
            group.keeperSet.add(keeper);
            keeperRegistry.incrementRefCount(keeper);
        }

        emit GroupAdded(btcAddress, required, maxSatoshi, keepers);
    }

    function deleteGroup(string calldata btcAddress) external onlyGroupAdmin whenNotPaused {
        Group storage group = groups[btcAddress];

        bytes32 receiptId = getReceiptId(btcAddress, group.nonce);
        Receipt storage receipt = receipts[receiptId];
        require(
            (receipt.status != Status.Available) ||
                (_blockTimestamp() > receipt.updateTimestamp + GROUP_REUSING_GAP),
            "receipt in resuing gap"
        );

        _clearReceipt(receipt, receiptId);

        for (uint8 i = 0; i < group.keeperSet.length(); i++) {
            address keeper = group.keeperSet.at(i);
            keeperRegistry.decrementRefCount(keeper);
        }

        require(group.currSatoshi == 0, "group balance > 0");

        delete groups[btcAddress];

        emit GroupDeleted(btcAddress);
    }

    // ------------------------------- receipt ---------------------------------
    function getReceipt(bytes32 receiptId) external view returns (Receipt memory) {
        return receipts[receiptId];
    }

    function getReceiptId(string calldata groupBtcAddress, uint256 nonce)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(groupBtcAddress, nonce));
    }

    function requestMint(
        string calldata groupBtcAddress,
        uint32 amountInSatoshi,
        uint32 nonce
    ) public payable whenNotPaused {
        require(amountInSatoshi > 0, "amount 0 is not allowed");
        fee.payMintEthFee{value: msg.value}();

        Group storage group = groups[groupBtcAddress];
        require(nonce == (group.nonce + 1), "invalid nonce");

        bytes32 prevReceiptId = getReceiptId(groupBtcAddress, group.nonce);
        Receipt storage prevReceipt = receipts[prevReceiptId];
        require(prevReceipt.status == Status.Available, "working receipt in progress");
        require(
            _blockTimestamp() > prevReceipt.updateTimestamp + GROUP_REUSING_GAP,
            "group cooling down"
        );
        delete receipts[prevReceiptId];

        group.nonce = nonce;

        require(
            (group.maxSatoshi - group.currSatoshi) == amountInSatoshi,
            "should fill all group allowance"
        );

        bytes32 receiptId = getReceiptId(groupBtcAddress, nonce);
        Receipt storage receipt = receipts[receiptId];
        _requestDeposit(receipt, groupBtcAddress, amountInSatoshi);

        emit MintRequested(receiptId, msg.sender, amountInSatoshi, groupBtcAddress);
    }

    function revokeMint(bytes32 receiptId) public {
        Receipt storage receipt = receipts[receiptId];
        require(receipt.recipient == msg.sender, "require receipt recipient");

        _revokeMint(receiptId, receipt);
    }

    function forceRequestMint(
        string calldata groupBtcAddress,
        uint32 amountInSatoshi,
        uint32 nonce
    ) public payable {
        bytes32 prevReceiptId = getReceiptId(groupBtcAddress, groups[groupBtcAddress].nonce);
        Receipt storage prevReceipt = receipts[prevReceiptId];

        _clearReceipt(prevReceipt, prevReceiptId);

        requestMint(groupBtcAddress, amountInSatoshi, nonce);
    }

    function verifyMint(
        MintRequest calldata request,
        address[] calldata keepers,
        bytes32[] calldata r,
        bytes32[] calldata s,
        uint256 packedV
    ) public whenNotPaused {
        Receipt storage receipt = receipts[request.receiptId];
        Group storage group = groups[receipt.groupBtcAddress];
        group.currSatoshi += receipt.amountInSatoshi;
        require(group.currSatoshi <= group.maxSatoshi, "amount exceed max allowance");

        _verifyMintRequest(group, request, keepers, r, s, packedV);
        _approveDeposit(receipt, request.txId, request.height);

        _mintSATS(receipt.recipient, receipt.amountInSatoshi);

        rewarder.mintReward(receipt.recipient, receipt.amountInSatoshi);

        emit MintVerified(
            request.receiptId,
            receipt.groupBtcAddress,
            keepers,
            request.txId,
            request.height
        );
    }

    function requestBurn(bytes32 receiptId, string calldata withdrawBtcAddress)
        public
        whenNotPaused
    {
        Receipt storage receipt = receipts[receiptId];

        _requestWithdraw(receipt, withdrawBtcAddress);

        _paySATSForBurn(msg.sender, address(this), receipt.amountInSatoshi);

        emit BurnRequested(receiptId, receipt.groupBtcAddress, withdrawBtcAddress, msg.sender);
    }

    function verifyBurn(bytes32 receiptId) public whenNotPaused {
        // TODO: allow only user or keepers to verify? If someone verified wrongly, we can punish
        Receipt storage receipt = receipts[receiptId];

        _approveWithdraw(receipt);

        _burnSATS(receipt.amountInSatoshi);

        Group storage group = groups[receipt.groupBtcAddress];
        group.currSatoshi -= receipt.amountInSatoshi;

        if (rewarder != ISwapRewarder(0))
            rewarder.burnReward(receipt.recipient, receipt.amountInSatoshi);

        emit BurnVerified(receiptId, receipt.groupBtcAddress, msg.sender);
    }

    function recoverBurn(bytes32 receiptId) public onlyAdmin {
        Receipt storage receipt = receipts[receiptId];

        _revokeWithdraw(receipt);

        _refundSATSForBurn(receipt.recipient, receipt.amountInSatoshi);

        emit BurnRevoked(receiptId, receipt.groupBtcAddress, receipt.recipient, msg.sender);
    }

    // -------------------------------- BTC refund -----------------------------------
    function getRefundData() external view returns (BtcRefundData memory) {
        return btcRefundData;
    }

    function refundBtc(string calldata groupBtcAddress, bytes32 txId)
        public
        onlyAdmin
        whenNotPaused
    {
        bytes32 receiptId = getReceiptId(groupBtcAddress, groups[groupBtcAddress].nonce);
        Receipt storage receipt = receipts[receiptId];

        _clearReceipt(receipt, receiptId);

        require(receipt.status == Status.Available, "receipt not in available state");
        require(btcRefundData.expiryTimestamp < _blockTimestamp(), "refund cool down");

        uint32 expiryTimestamp = _blockTimestamp() + REFUND_GAP;
        btcRefundData.expiryTimestamp = expiryTimestamp;
        btcRefundData.txId = txId;
        btcRefundData.groupBtcAddress = groupBtcAddress;

        emit BtcRefunded(groupBtcAddress, txId, expiryTimestamp);
    }

    // -------------------------------- Pausable -----------------------------------
    function pause() public onlyAdmin {
        _pause();
    }

    function unpause() public onlyAdmin {
        _unpause();
    }

    //=============================== Private ==================================
    // ------------------------------ keeper -----------------------------------
    function _cooldown(address keeper, uint32 cooldownEnd) private {
        cooldownUntil[keeper] = cooldownEnd;
        emit Cooldown(keeper, cooldownEnd);
    }

    function _clearReceipt(Receipt storage receipt, bytes32 receiptId) private {
        if (receipt.status == Status.WithdrawRequested) {
            require(
                _blockTimestamp() > receipt.updateTimestamp + WITHDRAW_VERIFICATION_END,
                "withdraw in progress"
            );
            _forceVerifyBurn(receiptId, receipt);
        } else if (receipt.status == Status.DepositRequested) {
            require(
                _blockTimestamp() > receipt.updateTimestamp + MINT_REQUEST_GRACE_PERIOD,
                "deposit in progress"
            );
            _forceRevokeMint(receiptId, receipt);
        }
    }

    // -------------------------------- group ----------------------------------
    function _revokeMint(bytes32 receiptId, Receipt storage receipt) private {
        _revokeDeposit(receipt);

        emit MintRevoked(receiptId, receipt.groupBtcAddress, msg.sender);
    }

    function _forceRevokeMint(bytes32 receiptId, Receipt storage receipt) private {
        receipt.status = Status.Available;

        emit MintRevoked(receiptId, receipt.groupBtcAddress, msg.sender);
    }

    function _verifyMintRequest(
        Group storage group,
        MintRequest calldata request,
        address[] calldata keepers,
        bytes32[] calldata r,
        bytes32[] calldata s,
        uint256 packedV
    ) private {
        require(keepers.length >= group.required, "not enough keepers");

        uint32 cooldownTime = _blockTimestamp() + KEEPER_COOLDOWN;
        bytes32 digest = _hashTypedDataV4(
            keccak256(abi.encode(REQUEST_TYPEHASH, request.receiptId, request.txId, request.height))
        );

        for (uint256 i = 0; i < keepers.length; i++) {
            address keeper = keepers[i];

            require(cooldownUntil[keeper] <= _blockTimestamp(), "keeper is in cooldown");
            require(group.keeperSet.contains(keeper), "keeper is not in group");
            require(ecrecover(digest, uint8(packedV), r[i], s[i]) == keeper, "invalid signature");
            // assert keepers.length <= 32
            packedV >>= 8;

            _cooldown(keeper, cooldownTime);
        }
    }

    function _forceVerifyBurn(bytes32 receiptId, Receipt storage receipt) private {
        receipt.status = Status.Available;

        _burnSATS(receipt.amountInSatoshi);

        Group storage group = groups[receipt.groupBtcAddress];
        group.currSatoshi -= receipt.amountInSatoshi;

        emit BurnVerified(receiptId, receipt.groupBtcAddress, msg.sender);
    }

    // ------------------------------- receipt ---------------------------------
    function _requestDeposit(
        Receipt storage receipt,
        string calldata groupBtcAddress,
        uint32 amountInSatoshi
    ) private {
        require(receipt.status == Status.Available, "receipt is not in Available state");

        receipt.groupBtcAddress = groupBtcAddress;
        receipt.recipient = msg.sender;
        receipt.amountInSatoshi = amountInSatoshi;
        receipt.updateTimestamp = _blockTimestamp();
        receipt.status = Status.DepositRequested;
    }

    function _approveDeposit(
        Receipt storage receipt,
        bytes32 txId,
        uint32 height
    ) private {
        require(
            receipt.status == Status.DepositRequested,
            "receipt is not in DepositRequested state"
        );

        receipt.txId = txId;
        receipt.height = height;
        receipt.status = Status.DepositReceived;
    }

    function _revokeDeposit(Receipt storage receipt) private {
        require(receipt.status == Status.DepositRequested, "receipt is not DepositRequested");

        _markFinish(receipt);
    }

    function _requestWithdraw(Receipt storage receipt, string calldata withdrawBtcAddress) private {
        require(
            receipt.status == Status.DepositReceived,
            "receipt is not in DepositReceived state"
        );

        receipt.recipient = msg.sender;
        receipt.withdrawBtcAddress = withdrawBtcAddress;
        receipt.updateTimestamp = _blockTimestamp();
        receipt.status = Status.WithdrawRequested;
    }

    function _approveWithdraw(Receipt storage receipt) private {
        require(
            receipt.status == Status.WithdrawRequested,
            "receipt is not in withdraw requested status"
        );

        _markFinish(receipt);
    }

    function _revokeWithdraw(Receipt storage receipt) private {
        require(
            receipt.status == Status.WithdrawRequested,
            "receipt is not in WithdrawRequested status"
        );

        receipt.status = Status.DepositReceived;
    }

    function _markFinish(Receipt storage receipt) private {
        receipt.updateTimestamp = _blockTimestamp();
        receipt.status = Status.Available;
    }

    function _blockTimestamp() internal view virtual returns (uint32) {
        return uint32(block.timestamp);
    }

    function _safeAdd(uint32 x, uint32 y) internal pure returns (uint32 z) {
        require((z = x + y) >= x);
    }

    // -------------------------------- SATS -----------------------------------
    function _mintSATS(address to, uint256 amountInSatoshi) private {
        uint256 amount = (amountInSatoshi).mul(BtcUtility.getSatsAmountMultiplier());

        uint256 feeAmount = fee.payExtraMintFee(to, amount);
        if (feeAmount > 0) {
            sats.mint(address(fee), feeAmount);
            sats.mint(to, amount.sub(feeAmount));
        } else {
            sats.mint(to, amount);
        }
    }

    function _burnSATS(uint256 amountInSatoshi) private {
        uint256 amount = (amountInSatoshi).mul(BtcUtility.getSatsAmountMultiplier());

        sats.burn(amount);
    }

    // user transfer SATS when requestBurn
    function _paySATSForBurn(
        address from,
        address to,
        uint256 amountInSatoshi
    ) private {
        uint256 amount = (amountInSatoshi).mul(BtcUtility.getSatsAmountMultiplier());

        uint256 feeAmount = fee.payExtraBurnFee(from, amount);

        sats.transferFrom(from, to, amount.add(feeAmount));

        if (feeAmount > 0) {
            sats.transfer(address(fee), feeAmount);
        }
    }

    // refund user when recoverBurn
    function _refundSATSForBurn(address to, uint256 amountInSatoshi) private {
        // fee is not refunded
        uint256 amount = (amountInSatoshi).mul(BtcUtility.getSatsAmountMultiplier());

        sats.transfer(to, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;
    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) internal {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = _getChainId();
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view virtual returns (bytes32) {
        if (_getChainId() == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(bytes32 typeHash, bytes32 name, bytes32 version) private view returns (bytes32) {
        return keccak256(
            abi.encode(
                typeHash,
                name,
                version,
                _getChainId(),
                address(this)
            )
        );
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", _domainSeparatorV4(), structHash));
    }

    function _getChainId() private view returns (uint256 chainId) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        // solhint-disable-next-line no-inline-assembly
        assembly {
            chainId := chainid()
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/EnumerableSet.sol";

interface IDeCusSystem {
    struct Group {
        uint32 maxSatoshi;
        uint32 currSatoshi;
        uint32 nonce;
        uint32 required;
        EnumerableSet.AddressSet keeperSet;
    }

    enum Status {
        Available,
        DepositRequested,
        DepositReceived,
        WithdrawRequested
    }

    struct Receipt {
        string groupBtcAddress;
        string withdrawBtcAddress;
        bytes32 txId;
        uint32 amountInSatoshi;
        uint32 updateTimestamp;
        uint32 height;
        address recipient;
        Status status;
    }

    struct BtcRefundData {
        bytes32 txId;
        string groupBtcAddress;
        uint32 expiryTimestamp;
    }

    struct MintRequest {
        bytes32 receiptId;
        bytes32 txId;
        uint32 height;
    }

    // events
    event GroupAdded(string btcAddress, uint32 required, uint32 maxSatoshi, address[] keepers);
    event GroupDeleted(string btcAddress);

    event MintRequested(
        bytes32 indexed receiptId,
        address indexed recipient,
        uint32 amountInSatoshi,
        string groupBtcAddress
    );
    event MintRevoked(bytes32 indexed receiptId, string groupBtcAddress, address operator);
    event MintVerified(
        bytes32 indexed receiptId,
        string groupBtcAddress,
        address[] keepers,
        bytes32 btcTxId,
        uint32 btcTxHeight
    );
    event BurnRequested(
        bytes32 indexed receiptId,
        string groupBtcAddress,
        string withdrawBtcAddress,
        address operator
    );
    event BurnRevoked(
        bytes32 indexed receiptId,
        string groupBtcAddress,
        address recipient,
        address operator
    );
    event BurnVerified(bytes32 indexed receiptId, string groupBtcAddress, address operator);

    event Cooldown(address indexed keeper, uint32 endTime);

    event BtcRefunded(string groupBtcAddress, bytes32 txId, uint32 expiryTimestamp);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IToken is IERC20 {
    function mint(address to, uint256 amount) external;

    function burn(uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ISwapRewarder {
    function mintReward(address to, uint256 amount) external;

    function burnReward(address to, uint256 amount) external;

    event SwapRewarded(address indexed to, uint256 amount, bool isMint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

interface ISwapFee {
    function getMintEthFee() external view returns (uint256);

    function getMintFeeBps() external view returns (uint8);

    function getBurnFeeBps() external view returns (uint8);

    function updateMintEthGasUsed(uint32 gasUsed) external;

    function updateMintEthGasPrice(uint16 gasPrice) external;

    function updateMintFeeBps(uint8 bps) external;

    function updateBurnFeeBps(uint8 bps) external;

    function getMintFeeAmount(uint256 amount) external view returns (uint256);

    function getBurnFeeAmount(uint256 amount) external view returns (uint256);

    function payMintEthFee() external payable;

    function payExtraMintFee(address from, uint256 amount) external returns (uint256);

    function payExtraBurnFee(address from, uint256 amount) external returns (uint256);

    event MintFeeBpsUpdate(uint8 bps);

    event BurnFeeBpsUpdate(uint8 bps);

    event MintEthFeeUpdate(uint32 gasUsed, uint16 gasPrice);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IToken} from "./interfaces/IToken.sol";
import {ISwapFee} from "./interfaces/ISwapFee.sol";

contract SwapFee is ISwapFee, Ownable {
    using SafeMath for uint256;

    uint8 private _mintFeeBps;
    uint8 private _burnFeeBps;
    uint16 private _mintFeeGasPrice; // in gwei
    uint32 private _mintFeeGasUsed;
    IToken public immutable sats;

    event SatsCollected(address indexed to, address indexed asset, uint256 amount);
    event EtherCollected(address indexed to, uint256 amount);

    //================================= Public =================================
    constructor(
        uint8 mintFeeBps,
        uint8 burnFeeBps,
        uint16 mintFeeGasPrice,
        uint32 mintFeeGasUsed,
        IToken _sats
    ) public {
        _mintFeeBps = mintFeeBps;
        _burnFeeBps = burnFeeBps;
        _mintFeeGasUsed = mintFeeGasUsed;
        _mintFeeGasPrice = mintFeeGasPrice;
        sats = _sats;
    }

    function getMintEthFee() public view override returns (uint256) {
        return 1e9 * uint256(_mintFeeGasUsed) * uint256(_mintFeeGasPrice);
    }

    function getMintFeeBps() external view override returns (uint8) {
        return _mintFeeBps;
    }

    function getBurnFeeBps() external view override returns (uint8) {
        return _burnFeeBps;
    }

    function updateMintEthGasUsed(uint32 gasUsed) external override onlyOwner {
        _mintFeeGasUsed = gasUsed;

        emit MintEthFeeUpdate(gasUsed, _mintFeeGasPrice);
    }

    function updateMintEthGasPrice(uint16 gasPrice) external override onlyOwner {
        _mintFeeGasPrice = gasPrice;

        emit MintEthFeeUpdate(_mintFeeGasUsed, gasPrice);
    }

    function updateMintFeeBps(uint8 bps) external override onlyOwner {
        _mintFeeBps = bps;

        emit MintFeeBpsUpdate(bps);
    }

    function updateBurnFeeBps(uint8 bps) external override onlyOwner {
        _burnFeeBps = bps;

        emit MintFeeBpsUpdate(bps);
    }

    function getMintFeeAmount(uint256 amount) external view override returns (uint256) {
        return amount.mul(_mintFeeBps).div(10000);
    }

    function getBurnFeeAmount(uint256 amount) public view override returns (uint256) {
        return amount.mul(_burnFeeBps).div(10000);
    }

    function payMintEthFee() external payable override {
        require(msg.value >= getMintEthFee(), "not enough eth");
    }

    function payExtraMintFee(address, uint256 amount) external override returns (uint256) {
        // potentially to receive dcs
        return amount.mul(_mintFeeBps).div(10000);
    }

    function payExtraBurnFee(address, uint256 amount) external override returns (uint256) {
        // potentially to receive dcs
        return amount.mul(_burnFeeBps).div(10000);
    }

    function collectSats(uint256 amount) public onlyOwner {
        sats.transfer(msg.sender, amount);
        emit SatsCollected(msg.sender, address(sats), amount);
    }

    function collectEther(address payable to, uint256 amount) public onlyOwner {
        (bool sent, ) = to.call{value: amount}("");
        require(sent, "failed to send ether");
        emit EtherCollected(to, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {ISwapRewarder} from "./interfaces/ISwapRewarder.sol";

contract SwapRewarder is ISwapRewarder {
    IERC20 public immutable dcs;
    address public immutable owner;
    address public immutable minter;
    uint256 public mintRewardAmount = 2000 ether;
    uint256 public burnRewardAmount = 100 ether;

    event RewarderAbort(address indexed to, uint256 amount);

    modifier onlyMinter() {
        require(minter == msg.sender, "require system role");
        _;
    }

    constructor(IERC20 _dcs, address _minter) public {
        dcs = _dcs;
        minter = _minter;
        owner = msg.sender;
    }

    function mintReward(address to, uint256) external override onlyMinter {
        if (mintRewardAmount == 0) return;

        dcs.transfer(to, mintRewardAmount);

        emit SwapRewarded(to, mintRewardAmount, true);
    }

    function burnReward(address to, uint256) external override onlyMinter {
        if (burnRewardAmount == 0) return;

        dcs.transfer(to, burnRewardAmount);

        emit SwapRewarded(to, burnRewardAmount, false);
    }

    function abort() external {
        require(owner == msg.sender, "only owner");

        uint256 balance = dcs.balanceOf(address(this));

        dcs.transfer(msg.sender, balance);

        emit RewarderAbort(msg.sender, balance);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract KeeperRewarder is ReentrancyGuard {
    using SafeMath for uint256;
    using Math for uint256;

    IERC20 public immutable dcs;
    IERC20 public immutable stakeToken;
    uint256 public immutable startTimestamp;
    uint256 public immutable endTimestamp;
    address public immutable owner;
    uint256 private constant PRECISE_UNIT = 1e18;

    uint256 public rate;
    uint256 public lastTimestamp;
    uint256 public eps; // earnings per stake
    uint256 public totalStakes;
    mapping(address => uint256) public stakes;
    mapping(address => uint256) public userEps;
    mapping(address => uint256) public claimableRewards;

    event RateUpdated(uint256 oldRate, uint256 newRate);

    constructor(
        IERC20 _dcs,
        IERC20 _stakeToken,
        uint256 _startTimestamp,
        uint256 _endTimestamp
    ) public {
        require(_startTimestamp >= block.timestamp, "Start cannot be in the past");
        dcs = _dcs;
        stakeToken = _stakeToken;
        startTimestamp = _startTimestamp;
        endTimestamp = _endTimestamp;
        owner = msg.sender;
    }

    function updateRate(uint256 _rate) external {
        require(msg.sender == owner, "require owner");
        require(_rate != rate, "same rate");

        _checkpoint();

        uint256 remainingTime = endTimestamp.sub(startTimestamp.max(block.timestamp));
        if (_rate > rate) {
            uint256 rewardDifference = (_rate - rate).mul(remainingTime);
            dcs.transferFrom(msg.sender, address(this), rewardDifference);
        } else {
            uint256 rewardDifference = (rate - _rate).mul(remainingTime);
            dcs.transfer(msg.sender, rewardDifference);
        }

        emit RateUpdated(rate, _rate);

        rate = _rate;
    }

    function userCheckpoint(address account) public {
        _checkpoint();
        _rewardCheckpoint(account);
    }

    function deposit(uint256 amount) external nonReentrant {
        userCheckpoint(msg.sender);

        stakeToken.transferFrom(msg.sender, address(this), amount);
        totalStakes = totalStakes.add(amount);
        stakes[msg.sender] = stakes[msg.sender].add(amount);
    }

    function withdraw(uint256 amount) external nonReentrant {
        userCheckpoint(msg.sender);
        _withdraw(msg.sender, amount);
    }

    function exit() external nonReentrant returns (uint256 rewards) {
        userCheckpoint(msg.sender);
        _withdraw(msg.sender, stakes[msg.sender]);
        rewards = _claimRewards(msg.sender);
    }

    function claimRewards() external nonReentrant returns (uint256 rewards) {
        userCheckpoint(msg.sender);
        rewards = _claimRewards(msg.sender);
    }

    function _claimRewards(address account) private returns (uint256 rewards) {
        rewards = claimableRewards[account];
        dcs.transfer(account, rewards);
        delete claimableRewards[account];
    }

    function _withdraw(address account, uint256 amount) private {
        stakeToken.transfer(account, amount);
        totalStakes = totalStakes.sub(amount, "Exceed staked balances");
        stakes[account] = stakes[account].sub(amount, "Exceed staked balances");
    }

    function _checkpoint() private {
        // Skip if before start timestamp
        if (block.timestamp < startTimestamp) return;

        uint256 nextTimestamp = endTimestamp.min(block.timestamp);
        uint256 timeLapse = nextTimestamp.sub(lastTimestamp);
        if (timeLapse != 0) {
            uint256 _totalStakes = totalStakes;
            if (_totalStakes != 0) {
                eps = eps.add(_divideDecimalPrecise(rate.mul(timeLapse), _totalStakes));
            }

            // update global state
            lastTimestamp = nextTimestamp;
        }
    }

    function _rewardCheckpoint(address account) private {
        // claim rewards till now
        uint256 claimableReward = _multiplyDecimalPrecise(
            stakes[account],
            eps.sub(userEps[account])
        );
        if (claimableReward > 0) {
            claimableRewards[account] = claimableRewards[account].add(claimableReward);
        }

        // update per-user state
        userEps[account] = eps;
    }

    function _divideDecimalPrecise(uint256 x, uint256 y) internal pure returns (uint256) {
        return x.mul(PRECISE_UNIT).div(y);
    }

    function _multiplyDecimalPrecise(uint256 x, uint256 y) internal pure returns (uint256) {
        return x.mul(y).div(PRECISE_UNIT);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

    constructor () internal {
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
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";

contract MockBTC is ERC20Burnable {
    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals
    ) public ERC20(name, symbol) {
        _setupDecimals(decimals);
    }

    function mint(address account, uint256 amount) public {
        _mint(account, amount);
    }
}

contract MockWBTC is MockBTC {
    constructor() public MockBTC("Wrapped Bitcoin", "WBTC", 8) {}
}

contract MockERC20 is MockBTC {
    constructor() public MockBTC("Other ERC20", "OTHER", 18) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract DCS is AccessControl, ERC20("DeCus", "DCS") {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "require admin role");
        _;
    }

    constructor() public {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        _setupRole(MINTER_ROLE, msg.sender);
    }

    function mint(address to, uint256 amount) public {
        require(hasRole(MINTER_ROLE, msg.sender), "require minter role");
        _mint(to, amount);
    }
}

