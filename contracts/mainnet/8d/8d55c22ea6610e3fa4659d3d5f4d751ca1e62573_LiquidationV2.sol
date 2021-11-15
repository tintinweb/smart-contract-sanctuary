// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ILiquidationV2.sol";

contract LiquidationV2 is ILiquidationV2, Ownable {

    using SafeMath for uint256;

    uint8 private constant MAX_LEVERAGE = 8;
    uint16 private constant MAX_CVI_VALUE = 20000;

    uint16 public liquidationMinRewardPercent = 5;
    uint256 public constant LIQUIDATION_MAX_FEE_PERCENTAGE = 1000;

    uint16[MAX_LEVERAGE] public liquidationMinThresholdPercents = [50, 50, 100, 100, 150, 150, 200, 200];
    uint16[MAX_LEVERAGE] public liquidationMaxRewardPercents = [30, 30, 30, 30, 30, 30, 30, 30];

    function setMinLiquidationThresholdPercents(uint16[MAX_LEVERAGE] calldata _newMinThresholdPercents) external override onlyOwner {
        for (uint256 i = 0; i < MAX_LEVERAGE; i++) {
            require(_newMinThresholdPercents[i] >= liquidationMaxRewardPercents[i], "Threshold less than some max");    
        }

        liquidationMinThresholdPercents = _newMinThresholdPercents;
    }

    function setMinLiquidationRewardPercent(uint16 _newMinRewardPercent) external override onlyOwner {
        for (uint256 i = 0; i < MAX_LEVERAGE; i++) {
            require(_newMinRewardPercent <= liquidationMaxRewardPercents[i], "Min greater than some max");    
        }
        
        liquidationMinRewardPercent = _newMinRewardPercent;
    }

    function setMaxLiquidationRewardPercents(uint16[MAX_LEVERAGE] calldata _newMaxRewardPercents) external override onlyOwner {
        for (uint256 i = 0; i < MAX_LEVERAGE; i++) {
            require(_newMaxRewardPercents[i] <= liquidationMinThresholdPercents[i], "Some max greater than threshold");
            require(_newMaxRewardPercents[i] >= liquidationMinRewardPercent, "Some max less than min");
        }

        liquidationMaxRewardPercents = _newMaxRewardPercents;
    }

    function isLiquidationCandidate(uint256 _positionBalance, bool _isPositive, uint168 _positionUnitsAmount, uint16 _openCVIValue, uint8 _leverage) public view override returns (bool) {
        return (!_isPositive ||  _positionBalance < uint256(_positionUnitsAmount).mul(liquidationMinThresholdPercents[_leverage - 1]).mul(_openCVIValue).div(MAX_CVI_VALUE).div(_leverage) / LIQUIDATION_MAX_FEE_PERCENTAGE);
    }

    function getLiquidationReward(uint256 _positionBalance, bool _isPositive, uint168 _positionUnitsAmount, uint16 _openCVIValue, uint8 _leverage) external view override returns (uint256 finderFeeAmount) {
        if (!isLiquidationCandidate(_positionBalance, _isPositive, _positionUnitsAmount, _openCVIValue, _leverage)) {
            return 0;
        }

        uint256 originalBalance = uint256(_positionUnitsAmount).mul(_openCVIValue).div(MAX_CVI_VALUE).div(_leverage);
        uint256 minLiuquidationReward = originalBalance.mul(liquidationMinRewardPercent).div(LIQUIDATION_MAX_FEE_PERCENTAGE);

        if (!_isPositive || _positionBalance < minLiuquidationReward) {
            return minLiuquidationReward;
        }

        uint256 maxLiquidationReward = originalBalance.mul(liquidationMaxRewardPercents[_leverage - 1]).div(LIQUIDATION_MAX_FEE_PERCENTAGE);
        
        if (_isPositive && _positionBalance >= minLiuquidationReward && _positionBalance <= maxLiquidationReward) {
            finderFeeAmount = _positionBalance;
        } else {
            finderFeeAmount = maxLiquidationReward;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.2;
pragma experimental ABIEncoderV2;

interface ILiquidationV2 {	
	function setMinLiquidationThresholdPercents(uint16[8] calldata newMinThresholdPercents) external;
	function setMinLiquidationRewardPercent(uint16 newMinRewardPercent) external;
  function setMaxLiquidationRewardPercents(uint16[8] calldata newMaxRewardPercents) external;
	function isLiquidationCandidate(uint256 positionBalance, bool isPositive, uint168 positionUnitsAmount, uint16 openCVIValue, uint8 leverage) external view returns (bool);
	function getLiquidationReward(uint256 positionBalance, bool isPositive, uint168 positionUnitsAmount, uint16 openCVIValue, uint8 leverage) external view returns (uint256 finderFeeAmount);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

pragma solidity ^0.6.0;

import "../GSN/Context.sol";
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
contract Ownable is Context {
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
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

pragma solidity ^0.6.0;

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}

