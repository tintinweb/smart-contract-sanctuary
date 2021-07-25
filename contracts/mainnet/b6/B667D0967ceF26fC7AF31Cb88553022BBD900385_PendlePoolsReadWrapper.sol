// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";


interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);
}

interface PendleLiquidityRewardsProxy {
    function redeemLiquidityRewards(
        address liqMiningContract,
        uint256[] calldata expiries,
        address user
    )
        external
        returns (
            uint256 rewards,
            uint256[] memory pendingRewards,
            uint256 currentEpoch
        );
}

interface PendleMarket {
    function approve(address spender, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function expiry() external view returns (uint256);

    function getReserves()
        external
        view
        returns (
            uint256 xytBalance,
            uint256 xytWeight,
            uint256 tokenBalance,
            uint256 tokenWeight,
            uint256 currentBlock
        );

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function token() external view returns (address);

    function xyt() external view returns (address);
}

interface PendleLiquidityMining {
    function stake(uint256 expiry, uint256 amount)
        external
        returns (address newLpHoldingContractAddress);

    function withdraw(uint256 expiry, uint256 amount) external;

    function allocationSettings(uint256 epochId, uint256 expiry) external view returns (uint256);

    function epochDuration() external view returns (uint256);

    function getBalances(uint256 expiry, address user) external view returns (uint256);

    function readExpiryData(uint256 expiry)
        external
        view
        returns (
            uint256 totalStakeLP,
            uint256 lastNYield,
            uint256 paramL,
            address lpHolder
        );

    function startTime() external view returns (uint256);

    function latestSetting() external view returns (uint256 id, uint256 firstEpochToApply);

    function totalRewardsForEpoch(uint256 epochId) external view returns (uint256 rewards);
}

interface PendleSingleStaking {
    function enter(uint256 balance) external;

    function leave(uint256 share) external;

    function balances(address account) external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);
}

interface PendleSingleStakingManager {
    function rewardPerBlock() external view returns (uint256);
}

contract PendlePoolsReadWrapper {
    using SafeMath for uint256;

    struct Reserves {
        uint256 xytBalance;
        uint256 xytWeight;
        uint256 tokenBalance;
        uint256 tokenWeight;
    }

    function marketApprove(PendleMarket _market, address _staking) public {
        _market.approve(_staking, type(uint256).max);
    }

    function tokenApprove(IERC20 _token, address _staking) public {
        _token.approve(_staking, type(uint256).max);
    }

    function claim(
        PendleLiquidityRewardsProxy _rewardsProxy,
        address _liqMiningContract,
        uint256[] calldata _expiries,
        address _user
    )
        public
        returns (
            uint256 rewards,
            uint256[] memory pendingRewards,
            uint256 currentEpoch
        )
    {
        (rewards, pendingRewards, currentEpoch) = _rewardsProxy.redeemLiquidityRewards(
            _liqMiningContract,
            _expiries,
            _user
        );
    }

    function stake(
        PendleLiquidityMining _staking,
        uint256 _expiry,
        uint256 _balance
    ) public {
        _staking.stake(_expiry, _balance);
    }

    function withdraw(
        PendleLiquidityMining _staking,
        uint256 _expiry,
        uint256 _balance
    ) public {
        _staking.withdraw(_expiry, _balance);
    }

    function singleStakingEnter(PendleSingleStaking _staking, uint256 _balance) public {
        _staking.enter(_balance);
    }

    function singleStakingLeaventer(PendleSingleStaking _staking, uint256 _share) public {
        _staking.leave(_share);
    }

    function getLiquidityMiningInfo(PendleMarket _market, PendleLiquidityMining _staking)
        public
        view
        returns (
            uint256 expiry,
            string memory marketSymbol,
            string memory tokenSymbol,
            uint256 lpTotalSupply,
            uint256 totalStakeLP,
            uint256 latestSettingId,
            uint256 allocationSettings,
            uint8 tokenDecimals,
            uint8 xytDecimals,
            Reserves memory reserves
        )
    {
        {
            IERC20 token = IERC20(_market.token());
            IERC20 xyt = IERC20(_market.xyt());

            tokenSymbol = token.symbol();
            tokenDecimals = token.decimals();
            xytDecimals = xyt.decimals();
        }

        {
            (
                uint256 xytBalance,
                uint256 xytWeight,
                uint256 tokenBalance,
                uint256 tokenWeight,

            ) = _market.getReserves();
            reserves.xytBalance = xytBalance;
            reserves.xytWeight = xytWeight;
            reserves.tokenBalance = tokenBalance;
            reserves.tokenWeight = tokenWeight;
        }

        expiry = _market.expiry();
        marketSymbol = _market.symbol();
        lpTotalSupply = _market.totalSupply();
        (totalStakeLP, , , ) = _staking.readExpiryData(expiry);
        (latestSettingId, ) = _staking.latestSetting();
        allocationSettings = _staking.allocationSettings(latestSettingId, expiry);
    }

    function getRewardsPerEpoch(
        PendleMarket _market,
        PendleLiquidityMining _staking,
        address _user
    )
        public
        view
        returns (
            uint256 epochDuration,
            uint256 expiry,
            uint256 rewardsPerEpoch,
            uint256 userStaked,
            uint256 userAvailableToStake,
            uint256 userAllowance
        )
    {
        epochDuration = _staking.epochDuration();
        expiry = _market.expiry();

        uint256 startTime = _staking.startTime();
        uint256 currentEpoch = (block.timestamp < startTime)
            ? 0
            : (block.timestamp.sub(startTime)).div(epochDuration).add(1);

        rewardsPerEpoch = _staking.totalRewardsForEpoch(currentEpoch);

        userStaked = _staking.getBalances(expiry, _user);
        userAvailableToStake = _market.balanceOf(_user);
        userAllowance = _market.allowance(_user, address(_staking));
    }

    function getSingleStakingInfo(
        PendleSingleStaking _staking,
        PendleSingleStakingManager _manager,
        IERC20 _pendle,
        address _user
    )
        public
        view
        returns (
            uint256 totalSupply,
            uint256 rewardPerBlock,
            uint256 userAvailableToStake,
            uint256 userAllowance,
            uint256 userShare
        )
    {
        totalSupply = _staking.totalSupply();
        rewardPerBlock = _manager.rewardPerBlock();
        userAvailableToStake = _pendle.balanceOf(_user);
        userAllowance = _pendle.allowance(_user, address(_staking));
        userShare = _staking.balances(_user);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 15000
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}