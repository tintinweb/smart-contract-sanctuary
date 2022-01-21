// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

import "../Interfaces/IPriceCurve.sol";
import "../Dependencies/SafeMath.sol";
import "../Dependencies/Ownable.sol";

/** 
 * This contract is used to calculate the variable fee for an input of tokens. 
 * Uses three linear piecewise functions to calculate the fee, and the average 
 * of the system collateralization by that asset before and after the tx. 
 */
contract ThreePieceWiseLinearPriceCurve is IPriceCurve, Ownable {
    using SafeMath for uint256;

    string name;
    uint256 m1;
    uint256 b1;
    uint256 cutoff1;
    uint256 m2;
    uint256 b2;
    uint256 cutoff2;
    uint256 m3;
    uint256 b3;
    uint256 decayTime;

    uint lastFeeTime;
    uint lastFeePercent;
    uint dollarCap;
    address whitelistAddress;

    /** 
     * f1 = m1 * x + b1
     * f1 meets f2 at cutoff1, which is defined by that intersection point and slope m2
     * f2 meets f3 at cutoff2, which is defined by that intersection point and slope m3
     * Everything in terms of actual * 1e18, scaled by 1e18 because can't do percentages
     * Decimal precision = 1e18
     */

    /** 
     * Function for setting slopes and intercepts of linear functions used for fee calculations. 
     */
    function adjustParams(string memory _name, uint256 _m1, uint256 _b1, uint256 _m2, uint256 _cutoff1, uint256 _m3, uint256 _cutoff2, uint _dollarCap) public onlyOwner {
        name = _name;
        m1 = _m1;
        b1 = _b1;
        m2 = _m2;
        b2 = _m1.mul(_cutoff1).div(1e18).add(_b1).sub(_m2.mul(_cutoff1).div(1e18));
        cutoff1 = _cutoff1;
        m3 = _m3;
        b3 = _m2.mul(_cutoff2).div(1e18).add(b2).sub(_m3.mul(_cutoff2).div(1e18));
        cutoff2 = _cutoff2;
        dollarCap = _dollarCap; // Cap in VC terms of max of this asset. dollarCap = 0 means no cap. No cap.
        decayTime = 5 days;
    }

    // Set the whitelist address so that the fee can only be updated by whitelistAddress
    function setAddresses(address _whitelistAddress) public override onlyOwner {
        whitelistAddress = _whitelistAddress;
    }

    // Set the decay time in seconds
    function setDecayTime(uint _decayTime) public override onlyOwner {
        decayTime = _decayTime;
    }

    // Gets the fee cap and time currently. Used for setting new values for next price curve. 
    function getFeeCapAndTime() external override view returns (uint256 _lastFeePercent, uint256 _lastFeeTime) {
        return (lastFeePercent, lastFeeTime);
    }

    // Function for setting the old price curve's last fee cap / value to the new fee cap / value. 
    // Called only by whitelist. 
    function setFeeCapAndTime(uint256 _lastFeePercent, uint256 _lastFeeTime) external override {
        require(msg.sender == whitelistAddress);
        lastFeePercent = _lastFeePercent;
        lastFeeTime = _lastFeeTime;
    }

    /** 
     * Function for getting the fee for a particular collateral type based on percent of YUSD backed
     * by this asset. 
     * @param _collateralVCInput is how much collateral is being input by the user into the system
     * @param _totalCollateralVCBalance is how much collateral is in the system
     * @param _totalVCBalancePost is how much VC the system for all collaterals after all adjustments (additions, subtractions)
     */
    function getFee(uint256 _collateralVCInput, uint256 _totalCollateralVCBalance, uint256 _totalVCBalancePre, uint256 _totalVCBalancePost) override external view returns (uint256 fee) {
        // If dollarCap == 0, then it is not capped. Otherwise, then the total + the total input must be less than the cap.
        if (dollarCap != 0) {
            require(_totalCollateralVCBalance.add(_collateralVCInput) <= dollarCap, "Collateral input exceeds cap");
        }

        uint feePre = _getFeePoint(_totalCollateralVCBalance, _totalVCBalancePre);
        uint feePost = _getFeePoint(_totalCollateralVCBalance.add(_collateralVCInput), _totalVCBalancePost);

        uint decayedLastFee = calculateDecayedFee();
        uint feeCalculated = _max((feePre.add(feePost)).div(2), decayedLastFee);

        return feeCalculated;
    }

    // Called only by whitelist. Updates the last fee time and last fee percent
    function getFeeAndUpdate(uint256 _collateralVCInput, uint256 _totalCollateralVCBalance, uint256 _totalVCBalancePre, uint256 _totalVCBalancePost) override external returns (uint256 fee) {
        require(msg.sender == whitelistAddress, "Only whitelist can update fee");
        // If dollarCap == 0, then it is not capped. Otherwise, then the total + the total input must be less than the cap.
        if (dollarCap != 0) {
            require(_totalCollateralVCBalance.add(_collateralVCInput) <= dollarCap, "Collateral input exceeds cap");
        }
        uint feePre = _getFeePoint(_totalCollateralVCBalance, _totalVCBalancePre);
        uint feePost = _getFeePoint(_totalCollateralVCBalance.add(_collateralVCInput), _totalVCBalancePost);

        uint decayedLastFee = calculateDecayedFee();
        uint feeCalculated = _max((feePre.add(feePost)).div(2), decayedLastFee);

        lastFeeTime = block.timestamp;
        lastFeePercent = feeCalculated;
        return feeCalculated;
    }

    /** 
     * Function for getting the fee for a particular collateral type based on percent of YUSD backed
     * by this asset. 
     */
    function _getFeePoint(uint256 _collateralVCBalance, uint256 _totalVCBalance) internal view returns (uint256 fee) {
        if (_totalVCBalance == 0) {
            return 0;
        }
        // percent of all VC backed by this collateral * 1e18
        uint256 percentBacked = _collateralVCBalance.mul(1e18).div(_totalVCBalance);
        require(percentBacked <= 1e18 && percentBacked >= 0, "percent backed out of bounds");

        if (percentBacked <= cutoff1) { // use function 1
            return _min(m1.mul(percentBacked).div(1e18).add(b1), 1e18);
        } else if (percentBacked <= cutoff2) { // use function 2
            return _min(m2.mul(percentBacked).div(1e18).add(b2), 1e18);
        } else { // use function 3
            return _min(m3.mul(percentBacked).div(1e18).add(b3), 1e18);
        }
    }

    function calculateDecayedFee() public override view returns (uint256 fee) {
        uint256 decay = block.timestamp.sub(lastFeeTime);
        if (decay > 0 && decay < decayTime) {
            fee = lastFeePercent.sub(lastFeePercent.mul(decay).div(decayTime));
        } else {
            fee = lastFeePercent;
        }
        return fee;
    }

    function _min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? b : a;
    }

    function _max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a <= b ? b : a;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

interface IPriceCurve {
    function setAddresses(address _whitelistAddress) external;

    function setDecayTime(uint _decayTime) external;

    /** 
     * Returns fee based on inputted collateral VC balance and total VC balance of system. 
     * fee is in terms of percentage * 1e18. 
     * If the fee were 1%, this would be 0.01 * 1e18 = 1e16
     */
    function getFee(uint256 _collateralVCInput, uint256 _collateralVCBalancePost, uint256 _totalVCBalancePre, uint256 _totalVCBalancePost) external view returns (uint256 fee);

    // Same function, updates the fee as well. Called only by whitelist. 
    function getFeeAndUpdate(uint256 _collateralVCInput, uint256 _totalCollateralVCBalance, uint256 _totalVCBalancePre, uint256 _totalVCBalancePost) external returns (uint256 fee);

    // Function for setting the old price curve's last fee cap / value to the new fee cap / value. 
    // Called only by whitelist. 
    function setFeeCapAndTime(uint256 _lastFeePercent, uint256 _lastFeeTime) external;

    // Gets the fee cap and time currently. Used for setting new values for next price curve. 
    function getFeeCapAndTime() external view returns (uint256 _lastFeePercent, uint256 _lastFeeTime);

    /** 
     * Returns fee based on decay since last fee calculation, which we take to be 
     * a reasonable fee amount. If it has decayed a certain amount since then, we let
     * the new fee amount slide. 
     */
    function calculateDecayedFee() external view returns (uint256 fee);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

/**
 * Based on OpenZeppelin's SafeMath:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol
 *
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
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

/**
 * Based on OpenZeppelin's Ownable contract:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol
 *
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     *
     * NOTE: This function is not safe, as it doesn’t check owner is calling it.
     * Make sure you check it before calling it.
     */
    function _renounceOwnership() internal {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}