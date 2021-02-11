// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./libraries/math/SafeMath.sol";
import "./libraries/token/IERC20.sol";
import "./interfaces/IX2TimeDistributor.sol";
import "./interfaces/IX2Farm.sol";

contract X2StakeReader {
    using SafeMath for uint256;

    uint256 constant PRECISION = 1e30;

    function getTokenInfo(
        address _farm,
        address _stakingToken,
        address _account
    ) public view returns (uint256[] memory) {
        uint256[] memory amounts = new uint256[](4);

        amounts[0] = IERC20(_farm).totalSupply();
        amounts[1] = IERC20(_stakingToken).balanceOf(_account);
        amounts[2] = IERC20(_farm).balanceOf(_account);
        amounts[3] = IERC20(_stakingToken).allowance(_account, _farm);

        return amounts;
    }

    function getStakeInfo(
        address _xlgeFarm,
        address _uniFarm,
        address _burnVault,
        address _timeVault,
        address _xlgeWeth,
        address _xvixEth,
        address _xvix,
        address _weth,
        address _account
    ) public view returns (uint256[] memory) {
        uint256[] memory amounts = new uint256[](16);

        amounts[0] = IERC20(_timeVault).balanceOf(_account);
        amounts[1] = IERC20(_burnVault).balanceOf(_account);
        amounts[2] = IERC20(_timeVault).totalSupply();
        amounts[3] = IERC20(_burnVault).totalSupply();
        amounts[4] = IERC20(_xlgeFarm).totalSupply();
        amounts[5] = IERC20(_uniFarm).totalSupply();
        amounts[6] = IERC20(_xvix).balanceOf(_account);
        amounts[7] = IERC20(_xlgeWeth).balanceOf(_account);
        amounts[8] = IERC20(_xlgeFarm).balanceOf(_account);
        amounts[9] = IERC20(_xlgeWeth).allowance(_account, _xlgeFarm);
        amounts[10] = IERC20(_xvixEth).balanceOf(_account);
        amounts[11] = IERC20(_uniFarm).balanceOf(_account);
        amounts[12] = IERC20(_xvixEth).allowance(_account, _uniFarm);
        amounts[13] = IERC20(_xvixEth).totalSupply();
        amounts[14] = IERC20(_weth).balanceOf(_xvixEth);
        amounts[15] = IERC20(_xvix).balanceOf(_xvixEth);

        return amounts;
    }

    function getRewards(address _farm, address _account, address _distributor) public view returns (uint256[] memory) {
        uint256[] memory amounts = new uint256[](2);

        amounts[0] = IX2TimeDistributor(_distributor).ethPerInterval(_farm);

        uint256 balance = IERC20(_farm).balanceOf(_account);
        uint256 supply = IERC20(_farm).totalSupply();
        uint256 pendingRewards = IX2TimeDistributor(_distributor).getDistributionAmount(_farm);
        uint256 cumulativeRewardPerToken = IX2Farm(_farm).cumulativeRewardPerToken();
        uint256 claimableReward = IX2Farm(_farm).claimableReward(_account);
        uint256 previousCumulatedRewardPerToken = IX2Farm(_farm).previousCumulatedRewardPerToken(_account);

        if (supply > 0) {
            uint256 rewards = claimableReward.add(pendingRewards.mul(balance).div(supply));
            uint256 additionalRewards = balance.mul(cumulativeRewardPerToken.sub(previousCumulatedRewardPerToken)).div(PRECISION);
            amounts[1] = rewards.add(additionalRewards);
        }

        return amounts;
    }

    function getRawRewards(address _farm, address _account, address _distributor) public view returns (uint256[] memory) {
        uint256[] memory amounts = new uint256[](2);

        amounts[0] = IX2TimeDistributor(_distributor).ethPerInterval(_farm);

        uint256 balance = IX2Farm(_farm).balances(_account);
        uint256 supply = IERC20(_farm).totalSupply();
        uint256 pendingRewards = IX2TimeDistributor(_distributor).getDistributionAmount(_farm);
        uint256 cumulativeRewardPerToken = IX2Farm(_farm).cumulativeRewardPerToken();
        uint256 claimableReward = IX2Farm(_farm).claimableReward(_account);
        uint256 previousCumulatedRewardPerToken = IX2Farm(_farm).previousCumulatedRewardPerToken(_account);

        if (supply > 0) {
            uint256 rewards = claimableReward.add(pendingRewards.mul(balance).div(supply));
            uint256 additionalRewards = balance.mul(cumulativeRewardPerToken.sub(previousCumulatedRewardPerToken)).div(PRECISION);
            amounts[1] = rewards.add(additionalRewards);
        }

        return amounts;
    }
}

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

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

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

pragma solidity 0.6.12;

interface IX2TimeDistributor {
    function getDistributionAmount(address receiver) external view returns (uint256);
    function ethPerInterval(address receiver) external view returns (uint256);
    function lastDistributionTime(address receiver) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IX2Farm {
    function balances(address account) external view returns (uint256);
    function cumulativeRewardPerToken() external view returns (uint256);
    function claimableReward(address account) external view returns (uint256);
    function previousCumulatedRewardPerToken(address account) external view returns (uint256);
}