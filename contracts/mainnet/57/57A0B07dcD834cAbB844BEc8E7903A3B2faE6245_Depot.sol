// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "./interfaces/IDepot.sol";
import "./interfaces/IExchangeRates.sol";

import "./utils/AddressResolver.sol";
import "./utils/BasicMaths.sol";

contract Depot is IDepot, AddressResolver {
    using SafeMath for uint;
    using BasicMaths for uint;
    using BasicMaths for bool;
    using SafeERC20 for IERC20;

    mapping(address => uint8) public _powers;

    bool private _initialFundingCompleted = false;

    uint32 public _positionIndex = 0;
    mapping(uint32 => Position) public _positions;

    uint private _liquidityPool = 0;                // decimals 6
    uint public _totalMarginLong = 0;               // decimals 6
    uint public _totalMarginShort = 0;              // decimals 6
    uint public _totalLeveragedPositionsLong = 0;   // decimals 6
    uint public _totalLeveragedPositionsShort = 0;  // decimals 6
    uint public _totalShareLong = 0;                // decimals 18
    uint public _totalShareShort = 0;               // decimals 18
    uint public _totalSizeLong = 0;                 // decimals 18
    uint public _totalSizeShort = 0;                // decimals 18
    uint public _rebaseLeftLong = 0;                // decimals 18
    uint public _rebaseLeftShort = 0;               // decimals 18

    uint private constant E30 = 1e18 * 1e12;
    bytes32 private constant CONTRACT_EXCHANGERATES = "ExchangeRates";
    bytes32 private constant CONTRACT_BASECURRENCY = "BaseCurrency";
    bytes32 private constant CURRENCY_KEY_ETH_USDC = "ETH-USDC";

    constructor(address[] memory powers) AddressResolver() {
        _rebaseLeftLong = 1e18;
        _rebaseLeftShort = 1e18;
        for (uint i = 0; i < powers.length; i++) {
            _powers[powers[i]] = 1;
        }
    }

    function exchangeRates() internal view returns (IExchangeRates) {
        return IExchangeRates(requireAndGetAddress(CONTRACT_EXCHANGERATES, "Missing ExchangeRates Address"));
    }

    function baseCurrency() internal view returns (IERC20) {
        return IERC20(requireAndGetAddress(CONTRACT_BASECURRENCY, "Missing BaseCurrency Address"));
    }

    // decimals 6
    function _netValue(uint8 direction) internal view returns (uint) {
        if(direction == 1) {
            if(_totalShareLong == 0) {
                return 1e6;
            } else {
                return _totalLeveragedPositionsLong.mul(1e18) / _totalShareLong;
            }
        } else {
            if(_totalShareShort == 0) {
                return 1e6;
            } else {
                return _totalLeveragedPositionsShort.mul(1e18) / _totalShareShort;
            }
        }
    }

    // decimals 6
    function netValue(uint8 direction) external override view returns (uint) {
        return _netValue(direction);
    }

    // decimals 6
    function calMarginLoss(uint leveragedPosition, uint share, uint8 direction) external override view returns (uint) {
        return leveragedPosition.sub2Zero(share.mul(_netValue(direction)) / 1e18);
    }

    // decimals 6
    function calNetProfit(
        uint32 currencyKeyIdx,
        uint leveragedPosition,
        uint openPositionPrice,
        uint8 direction) external override view returns (bool, uint) {
        uint rateForCurrency = exchangeRates().rateForCurrencyByIdx(currencyKeyIdx);
        bool isProfit = ((rateForCurrency >= openPositionPrice) && (direction == 1)) ||
             ((rateForCurrency < openPositionPrice) && (direction != 1));

        return (isProfit, leveragedPosition.mul(rateForCurrency.diff(openPositionPrice)) / openPositionPrice);
    }

    function updateSubTotalState(bool isLong, uint liquidity, uint detaMargin,
        uint detaLeveraged, uint detaShare, uint rebaseLeft) external override onlyPower {
        if (isLong) {
            _liquidityPool = liquidity;
            _totalMarginLong = _totalMarginLong.sub(detaMargin);
            _totalLeveragedPositionsLong = _totalLeveragedPositionsLong.sub(detaLeveraged);
            _totalShareLong = _totalShareLong.sub(detaShare);
            _rebaseLeftLong = _rebaseLeftLong.mul(rebaseLeft) / 1e18;
            _totalSizeLong = _totalSizeLong.mul(rebaseLeft) / 1e18;
        } else {
            _liquidityPool = liquidity;
            _totalMarginShort = _totalMarginShort.sub(detaMargin);
            _totalLeveragedPositionsShort = _totalLeveragedPositionsShort.sub(detaLeveraged);
            _totalShareShort = _totalShareShort.sub(detaShare);
            _rebaseLeftShort = _rebaseLeftShort.mul(rebaseLeft) / 1e18;
            _totalSizeShort = _totalSizeShort.mul(rebaseLeft) / 1e18;
        }
    }

    function newPosition(
        address account,
        uint openPositionPrice,
        uint margin,
        uint32 currencyKeyIdx,
        uint16 level,
        uint8 direction) external override onlyPower returns (uint32) {
        require(_initialFundingCompleted, 'Initial Funding Has Not Completed');

        IERC20 baseCurrencyContract = baseCurrency();

        require(
            baseCurrencyContract.allowance(account, address(this)) >= margin,
            "BaseCurrency Approved To Depot Is Not Enough");
        baseCurrencyContract.safeTransferFrom(account, address(this), margin);

        uint leveragedPosition = margin.mul(level);
        uint share = leveragedPosition.mul(1e18) / _netValue(direction);
        uint size = leveragedPosition.mul(1e18).mul(1e12) / openPositionPrice;
        uint openRebaseLeft;

        if (direction == 1) {
            _totalMarginLong = _totalMarginLong.add(margin);
            _totalLeveragedPositionsLong = _totalLeveragedPositionsLong.add(leveragedPosition);
            _totalShareLong = _totalShareLong.add(share);
            _totalSizeLong = _totalSizeLong.add(size);
            openRebaseLeft = _rebaseLeftLong;
        } else {
            _totalMarginShort = _totalMarginShort.add(margin);
            _totalLeveragedPositionsShort = _totalLeveragedPositionsShort.add(leveragedPosition);
            _totalShareShort = _totalShareShort.add(share);
            _totalSizeShort = _totalSizeShort.add(size);
            openRebaseLeft = _rebaseLeftShort;
        }

        _positionIndex++;
        _positions[_positionIndex] = Position(
            share,
            openPositionPrice,
            leveragedPosition,
            margin,
            openRebaseLeft,
            account,
            currencyKeyIdx,
            direction);

        return _positionIndex;
    }

    function addDeposit(
        address account,
        uint32 positionId,
        uint margin) external override onlyPower {
        Position memory p = _positions[positionId];

        require(account == p.account, "Position Not Match");

        IERC20 baseCurrencyContract = baseCurrency();

        require(
            baseCurrencyContract.allowance(account, address(this)) >= margin,
            "BaseCurrency Approved To Depot Is Not Enough");
        baseCurrencyContract.safeTransferFrom(account, address(this), margin);

        _positions[positionId].margin = p.margin.add(margin);
        if (p.direction == 1) {
            _totalMarginLong = _totalMarginLong.add(margin);
        } else {
            _totalMarginShort = _totalMarginShort.add(margin);
        }
    }

    function liquidate(
        Position memory position,
        uint32 positionId,
        bool isProfit,
        uint fee,
        uint value,
        uint marginLoss,
        uint liqReward,
        address liquidator) external override onlyPower {
        uint liquidity = (!isProfit).addOrSub2Zero(_liquidityPool.add(fee), value)
                                    .sub(marginLoss.sub2Zero(position.margin));

        uint detaLeveraged = position.share.mul(_netValue(position.direction)) / 1e18;
        uint openSize = position.leveragedPosition.mul(1e30) / position.openPositionPrice;

        if (position.direction == 1) {
            _liquidityPool = liquidity;
            _totalMarginLong = _totalMarginLong.add(marginLoss).sub(position.margin);
            _totalLeveragedPositionsLong = _totalLeveragedPositionsLong.sub(detaLeveraged);
            _totalShareLong = _totalShareLong.sub(position.share);
            _totalSizeLong = _totalSizeLong.sub(openSize.mul(_rebaseLeftLong) / position.openRebaseLeft);
        } else {
            _liquidityPool = liquidity;
            _totalMarginShort = _totalMarginShort.add(marginLoss).sub(position.margin);
            _totalLeveragedPositionsShort = _totalLeveragedPositionsShort.sub(detaLeveraged);
            _totalShareShort = _totalShareShort.sub(position.share);
            _totalSizeShort = _totalSizeShort.sub(openSize.mul(_rebaseLeftShort) / position.openRebaseLeft);
        }

        baseCurrency().safeTransfer(liquidator, liqReward);
        delete _positions[positionId];
    }

    function bankruptedLiquidate(
        Position memory position,
        uint32 positionId,
        uint liquidateFee,
        uint marginLoss,
        address liquidator) external override onlyPower {
        uint liquidity = (position.margin > marginLoss).addOrSub(
            _liquidityPool, position.margin.diff(marginLoss)).sub(liquidateFee);

        uint detaLeveraged = position.share.mul(_netValue(position.direction)) / 1e18;
        uint openSize = position.leveragedPosition.mul(1e30) / position.openPositionPrice;

        if (position.direction == 1) {
            _liquidityPool = liquidity;
            _totalMarginLong = _totalMarginLong.add(marginLoss).sub(position.margin);
            _totalLeveragedPositionsLong = _totalLeveragedPositionsLong.sub(detaLeveraged);
            _totalShareLong = _totalShareLong.sub(position.share);
            _totalSizeLong = _totalSizeLong.sub(openSize.mul(_rebaseLeftLong) / position.openRebaseLeft);
        } else {
            _liquidityPool = liquidity;
            _totalMarginShort = _totalMarginShort.add(marginLoss).sub(position.margin);
            _totalLeveragedPositionsShort = _totalLeveragedPositionsShort.sub(detaLeveraged);
            _totalShareShort = _totalShareShort.sub(position.share);
            _totalSizeShort = _totalSizeShort.sub(openSize.mul(_rebaseLeftShort) / position.openRebaseLeft);
        }

        baseCurrency().safeTransfer(liquidator, liquidateFee);

        delete _positions[positionId];
    }

    function closePosition(
        Position memory position,
        uint32 positionId,
        bool isProfit,
        uint value,
        uint marginLoss,
        uint fee) external override onlyPower {
        uint transferOutValue = isProfit.addOrSub(position.margin, value).sub(fee).sub(marginLoss);
        if ( isProfit && (_liquidityPool.add(position.margin).sub(marginLoss) <= transferOutValue) ){
            transferOutValue = _liquidityPool.add(position.margin).sub(marginLoss);
        }
        baseCurrency().safeTransfer(position.account, transferOutValue);

        uint liquidityPoolVal = (!isProfit).addOrSub2Zero(_liquidityPool.add(fee), value);
        uint detaLeveraged = position.share.mul(_netValue(position.direction)) / 1e18;
        uint openSize = position.leveragedPosition.mul(1e30) / position.openPositionPrice;

        if (position.direction == 1) {
            _liquidityPool = liquidityPoolVal;
            _totalMarginLong = _totalMarginLong.add(marginLoss).sub(position.margin);
            _totalLeveragedPositionsLong = _totalLeveragedPositionsLong.sub(detaLeveraged);
            _totalShareLong = _totalShareLong.sub(position.share);
            _totalSizeLong = _totalSizeLong.sub(openSize.mul(_rebaseLeftLong) / position.openRebaseLeft);
        } else {
            _liquidityPool = liquidityPoolVal;
            _totalMarginShort = _totalMarginShort.add(marginLoss).sub(position.margin);
            _totalLeveragedPositionsShort = _totalLeveragedPositionsShort.sub(detaLeveraged);
            _totalShareShort = _totalShareShort.sub(position.share);
            _totalSizeShort = _totalSizeShort.sub(openSize.mul(_rebaseLeftShort) / position.openRebaseLeft);
        }

        delete _positions[positionId];
    }

    function addLiquidity(address account, uint value) external override onlyPower {
        _liquidityPool = _liquidityPool.add(value);
        baseCurrency().safeTransferFrom(account, address(this), value);
    }

    function withdrawLiquidity(address account, uint value) external override onlyPower {
        _liquidityPool = _liquidityPool.sub(value);
        baseCurrency().safeTransfer(account, value);
    }

    function position(uint32 positionId) external override view returns (address account, uint share, uint leveragedPosition,
        uint openPositionPrice, uint32 currencyKeyIdx, uint8 direction, uint margin, uint openRebaseLeft) {
        Position memory p = _positions[positionId];
        return (p.account, p.share, p.leveragedPosition, p.openPositionPrice, p.currencyKeyIdx, p.direction, p.margin, p.openRebaseLeft);
    }

    function initialFundingCompleted() external override view returns (bool) {
        return _initialFundingCompleted;
    }

    // decimals 6
    function liquidityPool() external override view returns (uint) {
        return _liquidityPool;
    }

    // decimals 6
    function totalLeveragedPositions() external override view returns (uint) {
        return _totalLeveragedPositionsLong.add(_totalLeveragedPositionsShort);
    }

    // decimals 6
    function totalValue() external override view returns (uint) {
        (, uint nowPrice) = exchangeRates().rateForCurrency(CURRENCY_KEY_ETH_USDC);
        return nowPrice.mul(_totalSizeLong.add(_totalSizeShort)) / E30;
    }

    function completeInitialFunding() external override onlyPower {
        _initialFundingCompleted = true;
    }

    // decimals 6
    function getTotalPositionState() external override view returns (uint, uint, uint, uint) {
        (, uint nowPrice) = exchangeRates().rateForCurrency(CURRENCY_KEY_ETH_USDC);

        uint totalValueLong = _totalSizeLong.mul(nowPrice) / E30;
        uint totalValueShort = _totalSizeShort.mul(nowPrice) / E30;
        return (_totalMarginLong, _totalMarginShort, totalValueLong, totalValueShort);
    }

    modifier onlyPower {
        require(_powers[msg.sender] == 1, "Only the contract owner may perform this action");
        _;
    }
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