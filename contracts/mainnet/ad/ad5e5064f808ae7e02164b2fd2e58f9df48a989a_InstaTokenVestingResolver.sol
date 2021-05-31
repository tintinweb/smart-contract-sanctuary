/**
 *Submitted for verification at Etherscan.io on 2021-05-30
*/

// Sources flattened with hardhat v2.3.0 https://hardhat.org

// File @openzeppelin/contracts/math/[email protected]

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;


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


// File contracts/InstaVestingResolver.sol

interface TokenInterface {
    function balanceOf(address account) external view returns (uint);
    function delegate(address delegatee) external;
    function transfer(address dst, uint rawAmount) external returns (bool);
}

interface InstaVestingInferface {
    function owner() external view returns(address);
    function recipient() external view returns(address);
    function vestingAmount() external view returns(uint256);
    function vestingBegin() external view returns(uint32);
    function vestingCliff() external view returns(uint32);
    function vestingEnd() external view returns(uint32);
    function lastUpdate() external view returns(uint32);
    function terminateTime() external view returns(uint32);
}

interface InstaVestingFactoryInterface {
    function recipients(address) external view returns(address);
}

contract InstaTokenVestingResolver  {
    using SafeMath for uint256;

    TokenInterface public constant token = TokenInterface(0x6f40d4A6237C257fff2dB00FA0510DeEECd303eb);
    // InstaVestingFactoryInterface public constant factory = InstaVestingFactoryInterface(0x3730D9b06bc23fd2E2F84f1202a7e80815dd054a);
    InstaVestingFactoryInterface public immutable factory;

    constructor(address factory_) {
        factory = InstaVestingFactoryInterface(factory_);
    }
    struct VestingData {
        address recipient;
        address vesting;
        address owner;
        uint256 vestingAmount;
        uint256 vestingBegin;
        uint256 vestingCliff;
        uint256 vestingEnd;
        uint256 lastClaimed;
        uint256 terminatedTime;
        uint256 vestedAmount;
        uint256 unvestedAmount;
        uint256 claimedAmount;
        uint256 claimableAmount;
    }

    function getVestingByRecipient(address recipient) external view returns(VestingData memory vestingData) {
        address vestingAddr = factory.recipients(recipient);
        return getVesting(vestingAddr);
    }

    function getVesting(address vesting) public view returns(VestingData memory vestingData) {
        if (vesting == address(0)) return vestingData;
        InstaVestingInferface VestingContract = InstaVestingInferface(vesting);
        uint256 vestingBegin = uint256(VestingContract.vestingBegin());
        uint256 vestingEnd = uint256(VestingContract.vestingEnd());
        uint256 vestingCliff = uint256(VestingContract.vestingCliff());
        uint256 vestingAmount = VestingContract.vestingAmount();
        uint256 lastUpdate = uint256(VestingContract.lastUpdate());
        uint256 terminatedTime = uint256(VestingContract.terminateTime());

        
        uint256 claimedAmount;
        uint256 claimableAmount;
        uint256 vestedAmount;
        uint256 unvestedAmount;
        if (block.timestamp > vestingCliff) {
            uint256 time = terminatedTime == 0 ? block.timestamp : terminatedTime;
            vestedAmount = vestingAmount.mul(time - vestingBegin).div(vestingEnd - vestingBegin);
            unvestedAmount = vestingAmount.sub(vestedAmount);
            claimableAmount = vestingAmount.mul(time - lastUpdate).div(vestingEnd - vestingBegin);
            claimedAmount = vestedAmount.mul(time - vestingBegin).div(vestingEnd - vestingBegin);
        }

        vestingData = VestingData({
            recipient: VestingContract.recipient(),
            owner: VestingContract.owner(),
            vesting: vesting,
            vestingAmount: vestingAmount,
            vestingBegin: vestingBegin,
            vestingCliff: vestingCliff,
            vestingEnd: vestingEnd,
            lastClaimed: lastUpdate,
            terminatedTime: terminatedTime,
            vestedAmount: vestedAmount,
            unvestedAmount: unvestedAmount,
            claimedAmount: claimedAmount,
            claimableAmount: claimableAmount
        });
    }

}