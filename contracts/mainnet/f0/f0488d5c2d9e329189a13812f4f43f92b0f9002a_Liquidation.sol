// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./utils/AddressResolver.sol";
import "./utils/BasicMaths.sol";

import "./interfaces/ISystemSetting.sol";
import "./interfaces/IDepot.sol";
import "./interfaces/ILiquidation.sol";
import "./interfaces/IExchangeRates.sol";

contract Liquidation is AddressResolver, ILiquidation {
    using SafeMath for uint;
    using BasicMaths for uint;
    using BasicMaths for bool;

    bytes32 private constant CONTRACT_FUNDTOKEN = "FundToken";
    bytes32 private constant CONTRACT_EXCHANGERATES = "ExchangeRates";
    bytes32 private constant CONTRACT_DEPOT = "Depot";
    bytes32 private constant CONTRACT_SYSTEMSETTING = "SystemSetting";
    bytes32 private constant CONTRACT_BASECURRENCY = "BaseCurrency";

    /* -------------  contract interfaces  ------------- */
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


    function liquidate(uint32 positionId) external override {
        ISystemSetting setting = systemSetting();
        setting.requireSystemActive();
        IDepot depot = getDepot();

        require(IERC20(fundToken()).balanceOf(msg.sender) >= setting.minFundTokenRequired(),
            "Not Meet Min Fund Token Required");

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

        require(position.account != address(0), "Position Not Match");

        uint serviceFee = position.leveragedPosition.mul(setting.positionClosingFee()) / 1e18;
        uint marginLoss = depot.calMarginLoss(position.leveragedPosition, position.share, position.direction);

        uint rateForCurrency = exchangeRates().rateForCurrencyByIdx(position.currencyKeyIdx);
        uint value = position.leveragedPosition.mul(rateForCurrency.diff(position.openPositionPrice)).div(position.openPositionPrice);

        bool isProfit = (rateForCurrency >= position.openPositionPrice) == (position.direction == 1);
        uint feeAddML = serviceFee.add(marginLoss);

        if ( isProfit ) {
            require(position.margin.add(value) > feeAddML, "Position Cannot Be Liquidated in profit");
        } else {
            require(position.margin > value.add(feeAddML), "Position Cannot Be Liquidated in not profit");
        }

        require(
            isProfit.addOrSub(position.margin, value).sub(feeAddML) < position.margin.mul(setting.marginRatio()) / 1e18,
            "Position Cannot Be Liquidated by not in marginRatio");

        uint liqReward = isProfit.addOrSub(position.margin, value).sub(feeAddML);

        depot.liquidate(
            position,
            positionId,
            isProfit,
            serviceFee,
            value,
            marginLoss,
            liqReward,
            msg.sender);

        emit Liquidate(
            msg.sender,
            positionId,
            rateForCurrency,
            serviceFee,
            liqReward,
            marginLoss,
            isProfit,
            value);
    }

    function bankruptedLiquidate(uint32 positionId) external override {
        ISystemSetting setting = systemSetting();
        setting.requireSystemActive();
        IDepot depot = getDepot();
        require(IERC20(fundToken()).balanceOf(msg.sender) >= setting.minFundTokenRequired(),
            "Not Meet Min Fund Token Required");

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
        require(position.account != address(0), "Position Not Match");

        uint serviceFee = position.leveragedPosition.mul(setting.positionClosingFee()) / 1e18;
        uint marginLoss = depot.calMarginLoss(position.leveragedPosition, position.share, position.direction);

        uint rateForCurrency = exchangeRates().rateForCurrencyByIdx(position.currencyKeyIdx);
        uint value = position.leveragedPosition.mul(rateForCurrency.diff(position.openPositionPrice)) / position.openPositionPrice;

        bool isProfit = (rateForCurrency >= position.openPositionPrice) == (position.direction == 1);

        if ( isProfit ) {
            require(position.margin.add(value) < serviceFee.add(marginLoss), "Position Cannot Be Bankrupted Liquidated");
        } else {
            require(position.margin < value.add(serviceFee).add(marginLoss), "Position Cannot Be Bankrupted Liquidated");
        }

        uint liquidateFee = position.margin.mul(setting.liquidationFee()) / 1e18;

        depot.bankruptedLiquidate(
            position,
            positionId,
            liquidateFee,
            marginLoss,
            msg.sender);

        emit BankruptedLiquidate(msg.sender, positionId, rateForCurrency, serviceFee, liquidateFee, marginLoss, isProfit, value);
    }

    function alertLiquidation(uint32 positionId) external override view returns (bool) {
        IDepot depot = getDepot();

        (
            address account,
            uint share,
            uint leveragedPosition,
            uint openPositionPrice,
            uint32 currencyKeyIdx,
            uint8 direction,
            uint margin,
        ) = depot.position(positionId);

        if (account != address(0)) {
            uint serviceFee = leveragedPosition.mul(systemSetting().positionClosingFee()) / 1e18;
            uint marginLoss = depot.calMarginLoss(leveragedPosition, share, direction);

            (bool isProfit, uint value) = depot.calNetProfit(currencyKeyIdx, leveragedPosition, openPositionPrice, direction);

            if (isProfit) {
                if (margin.add(value) > serviceFee.add(marginLoss)) {
                    return margin.add(value).sub(serviceFee).sub(marginLoss) < margin.mul(systemSetting().marginRatio()) / 1e18;
                }
            } else {
                if (margin > value.add(serviceFee).add(marginLoss)) {
                    return margin.sub(value).sub(serviceFee).sub(marginLoss) < margin.mul(systemSetting().marginRatio()) / 1e18;
                }
            }
        }

        return false;
    }

    function alertBankruptedLiquidation(uint32 positionId) external override view returns (bool) {
        IDepot depot = getDepot();

        (
            address account,
            uint share,
            uint leveragedPosition,
            uint openPositionPrice,
            uint32 currencyKeyIdx,
            uint8 direction,
            uint margin,
        ) = depot.position(positionId);

        if (account != address(0)) {
            uint serviceFee = leveragedPosition.mul(systemSetting().positionClosingFee()) / 1e18;
            uint marginLoss = depot.calMarginLoss(leveragedPosition, share, direction);

            (bool isProfit, uint value) = depot.calNetProfit(currencyKeyIdx, leveragedPosition, openPositionPrice, direction);

            if (isProfit) {
                return margin.add(value) < serviceFee.add(marginLoss);
            } else {
                return margin < value.add(serviceFee).add(marginLoss);
            }
        }

        return false;
    }

    event Liquidate(
        address indexed sender,
        uint32 positionId,
        uint price,
        uint serviceFee,
        uint liqReward,
        uint marginLoss,
        bool isProfit,
        uint value);

    event BankruptedLiquidate(address indexed sender,
        uint32 positionId,
        uint price,
        uint serviceFee,
        uint liqReward,
        uint marginLoss,
        bool isProfit,
        uint value);
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