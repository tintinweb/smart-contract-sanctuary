/**
 *Submitted for verification at Etherscan.io on 2021-02-26
*/

// Sources flattened with hardhat v2.0.8 https://hardhat.org

// File @openzeppelin/contracts/math/[email protected]

// SPDX-License-Identifier: UNLICENSED

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

// File @openzeppelin/contracts/GSN/[email protected]

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

// File @openzeppelin/contracts/token/ERC20/[email protected]

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// File contracts/interfaces/IGLY.sol

pragma solidity ^0.7.3;

interface IGLY is IERC20 {
    function mint(address _to, uint256 _amount) external;
}

// File contracts/Staking.sol

pragma solidity ^0.7.3;

contract Staking is Context {
    using SafeMath for uint256;

    struct StakingInfo {
        uint256 amount;
        uint256 lastUpdateTime;
        uint256 rewardRate;
    }

    IGLY stakingToken;

    uint256[] rewardRates = [75, 75, 75, 50, 50, 50, 35, 35, 35, 20, 20, 20, 7];
    uint256 public stakingStart;

    uint256 _totalStakes;
    mapping(address => StakingInfo[]) internal stakes;

    constructor(IGLY _stakingToken, uint256 _stakingStart) {
        stakingToken = _stakingToken;
        stakingStart = _stakingStart;
    }

    event Staked(address staker, uint256 amount);
    event Unstaked(address staker, uint256 amount);
    event ClaimedReward(address staker, uint256 amount);

    function getStakingStart() public view returns (uint256) {
        return stakingStart;
    }

    function totalStakes() public view returns (uint256) {
        return _totalStakes;
    }

    function isStakeHolder(address _address) public view returns (bool) {
        return stakes[_address].length > 0;
    }

    function totalStakeOf(address _stakeHolder) public view returns (uint256) {
        uint256 _total = 0;
        for (uint256 j = 0; j < stakes[_stakeHolder].length; j += 1) {
            uint256 amount = stakes[_stakeHolder][j].amount;
            _total = _total.add(amount);
        }

        return _total;
    }

    function getRewardRate(uint256 _updateTime)
        public
        view
        returns (uint256 _rewardRate)
    {
        _rewardRate = _updateTime.sub(stakingStart).div(30 days);
        if (_rewardRate > 13) _rewardRate = 12;
    }

    function stake(uint256 _amount) public {
        require(stakingStart <= block.timestamp, "Staking is not started");
        require(
            stakingToken.transferFrom(_msgSender(), address(this), _amount),
            "Stake required!"
        );

        uint256 lastUpdateTime = block.timestamp;

        stakes[_msgSender()].push(
            StakingInfo(_amount, lastUpdateTime, getRewardRate(lastUpdateTime))
        );
        _totalStakes = _totalStakes.add(_amount);
        emit Staked(_msgSender(), _amount);
    }

    function unstake() public {
        uint256 withdrawAmount = 0;
        uint256 _staked = totalStakeOf(_msgSender());
        uint256 _reward = rewardOf(_msgSender());

        stakingToken.transfer(_msgSender(), _staked);
        stakingToken.mint(_msgSender(), _reward);
        _totalStakes = _totalStakes.sub(_staked);
        delete stakes[_msgSender()];
        emit Unstaked(_msgSender(), withdrawAmount);
    }

    function calculateReward(
        uint256 _lastUpdateTime,
        uint256 _rewardRate,
        uint256 _amount
    ) internal view returns (uint256) {
        uint256 rewardAmount;
        uint256 currentTime = block.timestamp;
        uint256 updateTime = _lastUpdateTime;
        uint256 rate = _rewardRate;

        uint256 mod =
            updateTime.sub(stakingStart).mod(30 days).div(1 days).mul(1 days);

        if (updateTime + 30 days - mod <= currentTime) {
            rewardAmount = rewardAmount.add(
                _amount
                    .mul(rewardRates[rate])
                    .mul(30 days - mod)
                    .div(365 days)
                    .div(100)
            );

            updateTime = updateTime + 30 days - mod;
            if (rate < 12) rate = rate.add(1);
        }

        while (updateTime + 30 days <= currentTime) {
            rewardAmount = rewardAmount.add(
                _amount.mul(rewardRates[rate]).mul(30 days).div(365 days).div(
                    100
                )
            );
            updateTime = updateTime + 30 days;
            if (rate < 12) rate = rate.add(1);
        }

        return rewardAmount;
    }

    /**
     * @notice A method to allow a stakeholder to check his rewards.
     * @param _stakeholder The stakeholder to check rewards for.
     */
    function rewardOf(address _stakeholder) public view returns (uint256) {
        uint256 rewardAmount = 0;
        for (uint256 j = 0; j < stakes[_stakeholder].length; j += 1) {
            uint256 amount = stakes[_stakeholder][j].amount;
            uint256 rate = stakes[_stakeholder][j].rewardRate;
            uint256 reward =
                calculateReward(
                    stakes[_stakeholder][j].lastUpdateTime,
                    rate,
                    amount
                );
            rewardAmount = rewardAmount.add(reward);
        }
        return rewardAmount;
    }

    /**
     * @notice A method to check if the holder can claim rewards
     */
    function isClaimable() public view returns (bool, uint256) {
        uint256 reward = rewardOf(_msgSender());

        return (reward > 0, 0);
    }

    /**
     * @notice A method to allow a stakeholder to withdraw his rewards.
     */
    function claimReward() public {
        address stakeholder = _msgSender();

        uint256 rewardAmount = rewardOf(stakeholder);

        require(rewardAmount > 0, "Reward is empty!");

        stakingToken.mint(_msgSender(), rewardAmount);

        for (uint256 j = 0; j < stakes[stakeholder].length; j += 1) {
            uint256 currentTime = block.timestamp;
            uint256 _lastUpdateTime =
                currentTime -
                    currentTime.sub(stakingStart).mod(30 days).div(1 days).mul(
                        1 days
                    );
            stakes[stakeholder][j].lastUpdateTime = _lastUpdateTime;
            stakes[stakeholder][j].rewardRate = getRewardRate(_lastUpdateTime);
        }

        emit ClaimedReward(_msgSender(), rewardAmount);
    }
}