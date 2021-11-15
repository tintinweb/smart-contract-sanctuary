// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "./interfaces/IFluidity.sol";
import "./interfaces/ILiquidation.sol";
import "./interfaces/IExchange.sol";
import "./interfaces/IExchangeRates.sol";
import "./interfaces/IFundToken.sol";
import "./interfaces/ISystemSetting.sol";
import "./interfaces/IDepot.sol";

import "./utils/AddressResolver.sol";
import "./utils/BasicMaths.sol";

contract Exchange is AddressResolver, IExchange {
    using SafeMath for uint;
    using BasicMaths for uint;
    using BasicMaths for bool;
    using SafeERC20 for IERC20;

    uint public _lastRebaseTime = 0;

    uint private constant E18 = 1e18;
    bytes32 private constant CONTRACT_FUNDTOKEN = "FundToken";
    bytes32 private constant CONTRACT_EXCHANGERATES = "ExchangeRates";
    bytes32 private constant CONTRACT_DEPOT = "Depot";
    bytes32 private constant CONTRACT_SYSTEMSETTING = "SystemSetting";
    bytes32 private constant CONTRACT_BASECURRENCY = "BaseCurrency";

    function fundToken() internal view returns (address) {
        return requireAndGetAddress(CONTRACT_FUNDTOKEN, "Missing FundToken Address");
    }

    function exchangeRates() internal view returns (IExchangeRates) {
        return IExchangeRates(requireAndGetAddress(CONTRACT_EXCHANGERATES, "Missing ExchangeRates Address"));
    }

    function systemSetting() internal view returns (ISystemSetting) {
        return ISystemSetting(requireAndGetAddress(CONTRACT_SYSTEMSETTING, "Missing SystemSetting Address"));
    }

    function depotAddress() internal view returns (address) {
        return requireAndGetAddress(CONTRACT_DEPOT, "Missing Depot Address");
    }

    function getDepot() internal view returns (IDepot) {
        return IDepot(depotAddress());
    }

    function baseCurrency() internal view returns (IERC20) {
        return IERC20(requireAndGetAddress(CONTRACT_BASECURRENCY, "Missing BaseCurrency Address"));
    }

    function openPosition(bytes32 currencyKey, uint8 direction, uint16 level, uint position) external override returns (uint32) {
        systemSetting().checkOpenPosition(position, level);

        require(direction == 1 || direction == 2, "Direction Only Can Be 1 Or 2");

        (uint32 currencyKeyIdx, uint openPrice) = exchangeRates().rateForCurrency(currencyKey);
        uint32 index = getDepot().newPosition(msg.sender, openPrice, position, currencyKeyIdx, level, direction);

        emit OpenPosition(msg.sender, index, openPrice, currencyKey, direction, level, position);

        return index;
    }

    function addDeposit(uint32 positionId, uint margin) external override {
        systemSetting().checkAddDeposit(margin);
        getDepot().addDeposit(msg.sender, positionId, margin);
        emit MarginCall(msg.sender, positionId, margin);
    }

    function closePosition(uint32 positionId) external override {
        ISystemSetting setting = systemSetting();
        setting.requireSystemActive();

        IDepot depot = getDepot();

        Position memory position;
        (
            position.account,
            position.share,
            position.leveragedPosition,
            position.openPositionPrice,
            position.currencyKeyIdx,
            position.direction,
            position.margin,
            position.openRebaseLeft
        ) = depot.position(positionId);

        require(position.account == msg.sender, "Position Not Match");

        uint shareSubnetValue = position.share.mul(depot.netValue(position.direction)) / 1e18;
        uint serviceFee = position.leveragedPosition.mul(setting.positionClosingFee()) / 1e18;
        uint marginLoss = position.leveragedPosition.sub2Zero(shareSubnetValue);

        uint rateForCurrency = exchangeRates().rateForCurrencyByIdx(position.currencyKeyIdx);
        uint value = position.leveragedPosition.mul(rateForCurrency.diff(position.openPositionPrice)) / position.openPositionPrice;

        bool isProfit = (rateForCurrency >= position.openPositionPrice) == (position.direction == 1);

        if ( isProfit ) {
            require(position.margin.add(value) > serviceFee.add(marginLoss), "Bankrupted Liquidation");
        } else {
            require(position.margin > value.add(serviceFee).add(marginLoss), "Bankrupted Liquidation");
        }

        depot.closePosition(
            position,
            positionId,
            isProfit,
            value,
            marginLoss,
            serviceFee);

        emit ClosePosition(msg.sender, positionId, rateForCurrency, serviceFee, marginLoss, isProfit, value);
    }

    function rebase() external override {
        IDepot depot = getDepot();
        ISystemSetting setting = systemSetting();
        uint time = block.timestamp;

        require(_lastRebaseTime + setting.rebaseInterval() <= time, "Not Meet Rebase Interval");
        require(depot.liquidityPool() > 0, "liquidity pool must more than 0");

        (uint totalMarginLong, uint totalMarginShort, uint totalValueLong, uint totalValueShort) = depot.getTotalPositionState();
        uint D = (totalValueLong.diff(totalValueShort)).mul(1e18) / depot.liquidityPool();

        require(D > setting.imbalanceThreshold(), "not meet imbalance threshold");

        uint lpd = depot.liquidityPool().mul(setting.imbalanceThreshold()) / 1e18;
        uint r = totalValueLong.diff(totalValueShort).sub(lpd) / setting.rebaseRate();
        uint rebaseLeft;

        if(totalValueLong > totalValueShort) {
            require(totalMarginLong >= r, "Long Margin Pool Has Bankrupted");
            rebaseLeft = E18.sub(r.mul(1e18) / totalValueLong);
        } else {
            require(totalMarginShort >= r, "Short Margin Pool Has Bankrupted");
            rebaseLeft = E18.sub(r.mul(1e18) / totalValueShort);
        }

        _lastRebaseTime = time;
        depot.updateSubTotalState(totalValueLong > totalValueShort,
            r.add(depot.liquidityPool()),
            r, r, 0, rebaseLeft);

        emit Rebase(time, r);
    }

    event OpenPosition(address indexed sender, uint32 positionId, uint price, bytes32 currencyKey, uint8 direction, uint16 level, uint position);
    event MarginCall(address indexed sender, uint32 positionId, uint margin);
    event ClosePosition(address indexed sender, uint32 positionId, uint price, uint serviceFee, uint marginLoss, bool isProfit, uint value);
    event Rebase(uint time, uint r);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.6;
pragma abicoder v2;

struct Position {
    uint share;                 // decimals 18
    uint openPositionPrice;     // decimals 18
    uint leveragedPosition;     // decimals 6
    uint margin;                // decimals 6
    uint openRebaseLeft;        // decimals 18
    address account;
    uint32 currencyKeyIdx;
    uint8 direction;
}

interface IDepot {
    function initialFundingCompleted() external view returns (bool);
    function liquidityPool() external view returns (uint);
    function totalLeveragedPositions() external view returns (uint);
    function totalValue() external view returns (uint);

    function position(uint32 index) external view returns (
        address account,
        uint share,
        uint leveragedPosition,
        uint openPositionPrice,
        uint32 currencyKeyIdx,
        uint8 direction,
        uint margin,
        uint openRebaseLeft);

    function netValue(uint8 direction) external view returns (uint);
    function calMarginLoss(uint leveragedPosition, uint share, uint8 direction) external view returns (uint);
    function calNetProfit(uint32 currencyKeyIdx,
        uint leveragedPosition,
        uint openPositionPrice,
        uint8 direction) external view returns (bool, uint);

    function completeInitialFunding() external;

    function updateSubTotalState(bool isLong, uint liquidity, uint detaMargin,
        uint detaLeveraged, uint detaShare, uint rebaseLeft) external;
    function getTotalPositionState() external view returns (uint, uint, uint, uint);

    function newPosition(
        address account,
        uint openPositionPrice,
        uint margin,
        uint32 currencyKeyIdx,
        uint16 level,
        uint8 direction) external returns (uint32);

    function addDeposit(
        address account,
        uint32 positionId,
        uint margin) external;

    function liquidate(
        Position memory position,
        uint32 positionId,
        bool isProfit,
        uint fee,
        uint value,
        uint marginLoss,
        uint liqReward,
        address liquidator) external;

    function bankruptedLiquidate(
        Position memory position,
        uint32 positionId,
        uint liquidateFee,
        uint marginLoss,
        address liquidator) external;

    function closePosition(
        Position memory position,
        uint32 positionId,
        bool isProfit,
        uint value,
        uint marginLoss,
        uint fee) external;

    function addLiquidity(address account, uint value) external;
    function withdrawLiquidity(address account, uint value) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.6;

interface IExchange {

    function openPosition(bytes32 currencyKey, uint8 direction, uint16 leverage, uint position) external returns (uint32);

    function addDeposit(uint32 positionId, uint margin) external;

    function closePosition(uint32 positionId) external;

    function rebase() external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.6;

interface IExchangeRates {
    function addCurrencyKey(bytes32 currencyKey_, address aggregator_) external;

    function updateCurrencyKey(bytes32 currencyKey_, address aggregator_) external;

    function deleteCurrencyKey(bytes32 currencyKey) external;

    function rateForCurrency(bytes32 currencyKey) external view returns (uint32, uint);

    function rateForCurrencyByIdx(uint32 idx) external view returns (uint);

    function currencyKeyExist(bytes32 currencyKey) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.6;

interface IFluidity {
    function initialFunding(uint value) external;

    function closeInitialFunding() external;

    function fundLiquidity(uint value) external;

    function withdrawLiquidity(uint value) external;

    function fundTokenPrice() external view returns (uint);

    function availableToFund() external view returns (uint);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.6;

interface IFundToken {
    function mint(address account, uint value) external;

    function burn(address account, uint value) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.6;

interface ILiquidation {
    function liquidate(uint32 positionId) external;

    function bankruptedLiquidate(uint32 positionId) external;

    function alertLiquidation(uint32 positionId) external view returns (bool);

    function alertBankruptedLiquidation(uint32 positionId) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.6;

interface ISystemSetting {
    // maxInitialLiquidityFunding
    function maxInitialLiquidityFunding() external view returns (uint256);

    // constantMarginRatio
    function constantMarginRatio() external view returns (uint256);

    // leverageExist
    function leverageExist(uint32 leverage_) external view returns (bool);

    // minInitialMargin
    function minInitialMargin() external view returns (uint256);

    // minAddDeposit
    function minAddDeposit() external view returns (uint256);

    // minHoldingPeriod
    function minHoldingPeriod() external view returns (uint);

    // marginRatio
    function marginRatio() external view returns (uint256);

    // positionClosingFee
    function positionClosingFee() external view returns (uint256);

    // liquidationFee
    function liquidationFee() external view returns (uint256);

    // rebaseInterval
    function rebaseInterval() external view returns (uint);

    // rebaseRate
    function rebaseRate() external view returns (uint);

    // imbalanceThreshold
    function imbalanceThreshold() external view returns (uint);

    // minFundTokenRequired
    function minFundTokenRequired() external view returns (uint);

    function checkOpenPosition(uint position, uint16 level) external view;
    function checkAddDeposit(uint margin) external view;

    function requireSystemActive() external;
    function resumeSystem() external;
    function suspendSystem() external;

    event Suspend(address indexed sender);
    event Resume(address indexed sender);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.6;

import "@openzeppelin/contracts/access/Ownable.sol";

contract AddressResolver is Ownable {
    mapping(bytes32 => address) public repository;

    function importAddresses(bytes32[] calldata names, address[] calldata destinations) external onlyOwner {
        require(names.length == destinations.length, "Input lengths must match");

        for (uint i = 0; i < names.length; i++) {
            repository[names[i]] = destinations[i];
        }
    }

    function requireAndGetAddress(bytes32 name, string memory reason) internal view returns (address) {
        address _foundAddress = repository[name];
        require(_foundAddress != address(0), reason);
        return _foundAddress;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.6;

import "@openzeppelin/contracts/math/SafeMath.sol";

library BasicMaths {
    /**
     * @dev Returns the abs of substraction of two unsigned integers
     *
     * _Available since v3.4._
     */
    function diff(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a >= b) {
            return a - b;
        } else {
            return b - a;
        }
    }

    /**
     * @dev Returns a - b if a > b, else return 0
     *
     * _Available since v3.4._
     */
    function sub2Zero(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a > b) {
            return a - b;
        } else {
            return 0;
        }
    }

    /**
     * @dev if isSub then Returns a - b, else return a + b
     *
     * _Available since v3.4._
     */
    function addOrSub(bool isAdd, uint256 a, uint256 b) internal pure returns (uint256) {
        if (isAdd) {
            return SafeMath.add(a, b);
        } else {
            return SafeMath.sub(a, b);
        }
    }

    /**
     * @dev if isSub then Returns sub2Zero(a, b), else return a + b
     *
     * _Available since v3.4._
     */
    function addOrSub2Zero(bool isAdd, uint256 a, uint256 b) internal pure returns (uint256) {
        if (isAdd) {
            return SafeMath.add(a, b);
        } else {
            if (a > b) {
                return a - b;
            } else {
                return 0;
            }
        }
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

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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

