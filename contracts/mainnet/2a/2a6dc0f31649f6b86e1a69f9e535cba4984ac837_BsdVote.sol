/**
 *Submitted for verification at Etherscan.io on 2021-01-20
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

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

interface IVoteProxy {
    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address _voter) external view returns (uint256);
}

interface IFaasPool is IERC20 {
    function getBalance(address token) external view returns (uint256);

    function getUserInfo(uint8 _pid, address _account)
        external
        view
        returns (
            uint256 amount,
            uint256 rewardDebt,
            uint256 accumulatedEarned,
            uint256 lockReward,
            uint256 lockRewardReleased
        );
}

contract BsdVote is IVoteProxy {
    using SafeMath for uint256;

    IFaasPool[10] public faasPools;
    IERC20[10] public stakePools;
    IERC20 bsdsToken;
    address public bsds;
    uint256 public totalFaasPools;
    uint256 public totalStakePools;
    address public governance;

    constructor(
        address _bsds,
        address[] memory _faasPoolAddresses,
        address[] memory _stakePoolAddresses
    ) public {
        _setFaasPools(_faasPoolAddresses);
        _setStakePools(_stakePoolAddresses);
        bsds = _bsds;
        bsdsToken = IERC20(bsds);
        governance = msg.sender;
    }

    function _setFaasPools(address[] memory _faasPoolAddresses) internal {
        totalFaasPools = _faasPoolAddresses.length;
        for (uint256 i = 0; i < totalFaasPools; i++) {
            faasPools[i] = IFaasPool(_faasPoolAddresses[i]);
        }
    }

    function _setStakePools(address[] memory _stakePoolAddresses) internal {
        totalStakePools = _stakePoolAddresses.length;
        for (uint256 i = 0; i < totalStakePools; i++) {
            stakePools[i] = IERC20(_stakePoolAddresses[i]);
        }
    }

    function decimals() public pure virtual override returns (uint8) {
        return uint8(18);
    }

    function totalSupply() public view override returns (uint256) {
        uint256 totalSupplyPool = 0;
        uint256 i;
        for (i = 0; i < totalFaasPools; i++) {
            totalSupplyPool = totalSupplyPool.add(bsdsToken.balanceOf(address(faasPools[i])));
        }
        uint256 totalSupplyStake = 0;
        for (i = 0; i < totalStakePools; i++) {
            totalSupplyStake = totalSupplyStake.add(bsdsToken.balanceOf(address(stakePools[i])));
        }
        return totalSupplyPool.add(totalSupplyStake);
    }

    function totalInFaaSPool() public view returns (uint256) {
        uint256 total = 0;
        uint256 i;
        for (i = 0; i < totalFaasPools; i++) {
            total = total.add(bsdsToken.balanceOf(address(faasPools[i])));
        }
        return total;
    }

    function totalInStakePool() public view returns (uint256) {
        uint256 total = 0;
        uint256 i;
        for (i = 0; i < totalStakePools; i++) {
            total = total.add(bsdsToken.balanceOf(address(stakePools[i])));
        }
        return total;
    }

    function getBsdsAmountInPool(address _voter) internal view returns (uint256) {
        uint256 stakeAmount = 0;
        for (uint256 i = 0; i < totalFaasPools; i++) {
            (uint256 _stakeAmountInPool, , , , ) = faasPools[i].getUserInfo(uint8(0), _voter);
            stakeAmount = stakeAmount.add(_stakeAmountInPool.mul(faasPools[i].getBalance(bsds)).div(faasPools[i].totalSupply()));
        }
        return stakeAmount;
    }

    function getBsdsAmountInStakeContracts(address _voter) internal view returns (uint256) {
        uint256 stakeAmount = 0;
        for (uint256 i = 0; i < totalStakePools; i++) {
            stakeAmount = stakeAmount.add(stakePools[i].balanceOf(_voter));
        }
        return stakeAmount;
    }

    function balanceOf(address _voter) public view override returns (uint256) {
        uint256 balanceInPool = getBsdsAmountInPool(_voter);
        uint256 balanceInStakeContract = getBsdsAmountInStakeContracts(_voter);
        return balanceInPool.add(balanceInStakeContract);
    }

    function setFaasPools(address[] memory _faasPoolAddresses) external {
        require(msg.sender == governance, "!governance");
        _setFaasPools(_faasPoolAddresses);
    }

    function setStakePools(address[] memory _stakePoolAddresses) external {
        require(msg.sender == governance, "!governance");
        _setStakePools(_stakePoolAddresses);
    }
}