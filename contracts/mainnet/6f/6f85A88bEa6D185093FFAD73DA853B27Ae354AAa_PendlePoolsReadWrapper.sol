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

    function totalSupply() external view returns (uint256);
}

interface PendleYieldToken is IERC20 {
    function expiry() external view returns (uint256);
}

interface PendleMarket is IERC20 {
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

    function token() external view returns (address);

    function xyt() external view returns (address);
}

interface SushiSwapPool is IERC20 {
    function getReserves()
        external
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        );

    function token0() external view returns (address);

    function token1() external view returns (address);
}

interface PendleLiquidityMining {
    function allocationSettings(uint256 epochId, uint256 expiry) external view returns (uint256);

    function balances(address user) external view returns (uint256);

    function epochDuration() external view returns (uint256);

    function getBalances(uint256 expiry, address user) external view returns (uint256);

    function numberOfEpochs() external view returns (uint256);

    function readEpochData(uint256 epochId, address user)
        external
        view
        returns (
            uint256 totalStakeUnits,
            uint256 totalRewards,
            uint256 lastUpdated,
            uint256 stakeUnitsForUser,
            uint256 availableRewardsForUser
        );

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
    function balances(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);
}

interface PendleSingleStakingManager {
    function rewardPerBlock() external view returns (uint256);
}

interface PendleLiquidityRewardsProxy {
    function redeemAndCalculateAccruing(
        address liqMining,
        uint256 expiry,
        address user
    )
        external
        returns (
            uint256 userStakeUnits,
            uint256 userStake,
            uint256 totalStakeUnits,
            uint256 totalStake,
            uint256 userTentativeReward
        );
    
    function redeemAndCalculateAccruingV2(
        address liqMiningV2,
        address user
    )
        external
        returns (
            uint256 userStakeUnits,
            uint256 userStake,
            uint256 totalStakeUnits,
            uint256 totalStake,
            uint256 userTentativeReward
        );

    function redeemAndCalculateVested(
        address liqMiningContract,
        uint256[] calldata expiries,
        address user
    )
        external
        returns (
            uint256 rewards,
            uint256[] memory vestedRewards,
            uint256 currentEpoch
        );

    function redeemAndCalculateVestedV2(
        address liqMiningContractV2,
        address user
    )
        external
        returns (
            uint256 rewards,
            uint256[] memory vestedRewards,
            uint256 currentEpoch
        );
}

contract PendlePoolsReadWrapper {
    using SafeMath for uint256;

    enum Type {
        PendleMarket,
        SushiSwapPool
    }

    struct Reserves {
        uint256 ytotBalance;
        uint256 ytotWeight;
        uint256 tokenBalance;
        uint256 tokenWeight;
    }

    address constant public SUSHISWAP_MASTERCHEF = 0xc2EdaD668740f1aA35E4D8f227fB8E17dcA888Cd;

    function tokenApprove(
        IERC20 _token,
        address _staking,
        uint256 _allowance
    ) public {
        _token.approve(_staking, _allowance);
    }

    function claim(
        PendleLiquidityRewardsProxy _rewardsProxy,
        address _liqMining,
        uint256 _expiry,
        address _user,
        Type _type
    )
        public
        returns (
            uint256 accruingRewards,
            uint256[] memory vestedRewards
        )
    {
        if (_type == Type.PendleMarket) {
            uint256[] memory expiry = new uint256[](1);
            expiry[0] = _expiry;

            ( , , , , accruingRewards) = _rewardsProxy.redeemAndCalculateAccruing(
                _liqMining,
                _expiry,
                _user
            );

            (, vestedRewards, ) = _rewardsProxy.redeemAndCalculateVested(
                _liqMining,
                expiry,
                _user
            );
        } else if (_type == Type.SushiSwapPool) {
            uint256[] memory expiry = new uint256[](1);
            expiry[0] = _expiry;

            ( , , , , accruingRewards) = _rewardsProxy.redeemAndCalculateAccruingV2(
                _liqMining,
                _user
            );

            (, vestedRewards, ) = _rewardsProxy.redeemAndCalculateVested(
                _liqMining,
                expiry,
                _user
            );
        } else {
            revert("invalid type");
        }
    }

    function getLiquidityMiningInfo(
        address _poolOrMarket,
        PendleLiquidityMining _staking,
        Type _type
    )
        public
        view
        returns (
            uint256 expiry,
            string memory marketSymbol,
            string memory tokenSymbol,
            uint256 lpTotalSupply,
            uint256 totalStakeLP,
            uint256 totalRewards,
            uint8 tokenDecimals,
            uint8 xytDecimals,
            Reserves memory reserves
        )
    {
        if (_type == Type.PendleMarket) {
            (tokenSymbol, tokenDecimals, xytDecimals, expiry) = _getYTTokenInfo(_poolOrMarket);
            reserves = _getYTReserves(_poolOrMarket);
            marketSymbol = PendleMarket(_poolOrMarket).symbol();
            lpTotalSupply = PendleMarket(_poolOrMarket).totalSupply();

            (totalStakeLP, , , ) = _staking.readExpiryData(expiry);
            (uint256 latestSettingId, ) = _staking.latestSetting();
            uint256 allocationSettings = _staking.allocationSettings(latestSettingId, expiry);
            uint256 currentEpoch = _epochOfTimestamp(block.timestamp, _staking);
            totalRewards =
                allocationSettings.mul(_staking.totalRewardsForEpoch(currentEpoch)) /
                1e9;
        } else if (_type == Type.SushiSwapPool) {
            (tokenSymbol, tokenDecimals, xytDecimals, expiry) = _getOTTokenInfo(_poolOrMarket);
            reserves = _getOTReserves(_poolOrMarket);
            marketSymbol = SushiSwapPool(_poolOrMarket).symbol();
            lpTotalSupply = SushiSwapPool(_poolOrMarket).totalSupply();

            uint256 epoch = _epochOfTimestamp(block.timestamp, _staking);
            totalStakeLP = IERC20(_poolOrMarket).balanceOf(address(_staking));
            if (totalStakeLP == 0) { // If the LP is staked in SushiSwap MasterChef
              totalStakeLP = IERC20(_poolOrMarket).balanceOf(SUSHISWAP_MASTERCHEF);
            }
            (, totalRewards, , , ) = _staking.readEpochData(epoch, address(0));
        } else {
            revert("invalid type");
        }
    }

    function getStakingInfo(
        PendleYieldToken _pool,
        PendleLiquidityMining _staking,
        address _user,
        Type _type
    )
        public
        view
        returns (
            uint256 expiry,
            uint256 numberOfEpochs,
            uint256 epochDuration,
            uint256 userStaked,
            uint256 userAvailableToStake,
            uint256 userAllowance
        )
    {
        if (_type == Type.PendleMarket) {
            expiry = _pool.expiry();
        } else if (_type == Type.SushiSwapPool) {
            address token0 = SushiSwapPool(address(_pool)).token0();
            address token1 = SushiSwapPool(address(_pool)).token1();

            try PendleYieldToken(token0).expiry() returns (uint256 _expiry) {
                expiry = _expiry;
            } catch {
                expiry = PendleYieldToken(token1).expiry();
            }
        } else {
            revert("invalid type");
        }

        numberOfEpochs = _staking.numberOfEpochs();
        epochDuration = _staking.epochDuration();

        try _staking.getBalances(expiry, _user) returns (uint256 res) {
            userStaked = res;
        } catch {
            userStaked = _staking.balances(_user);
        }

        userAvailableToStake = _pool.balanceOf(_user);
        userAllowance = _pool.allowance(_user, address(_staking));
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

    function _epochOfTimestamp(uint256 _t, PendleLiquidityMining _lm)
        internal
        view
        returns (uint256)
    {
        return (_t.sub(_lm.startTime())).div(_lm.epochDuration()).add(1);
    }

    function _getYTTokenInfo(address _market)
        internal
        view
        returns (
            string memory tokenSymbol,
            uint8 tokenDecimals,
            uint8 ytotDecimals,
            uint256 expiry
        )
    {
        IERC20 token = IERC20(PendleMarket(_market).token());
        IERC20 xyt = IERC20(PendleMarket(_market).xyt());

        tokenSymbol = token.symbol();
        tokenDecimals = token.decimals();
        ytotDecimals = xyt.decimals();
        expiry = PendleMarket(_market).expiry();
    }

    function _getOTTokenInfo(address _pool)
        internal
        view
        returns (
            string memory tokenSymbol,
            uint8 tokenDecimals,
            uint8 ytotDecimals,
            uint256 expiry
        )
    {
        address token0 = SushiSwapPool(address(_pool)).token0();
        address token1 = SushiSwapPool(address(_pool)).token1();
        PendleYieldToken ot;
        IERC20 token;

        try PendleYieldToken(token0).expiry() returns (uint256 _expiry) {
            expiry = _expiry;
            ot = PendleYieldToken(SushiSwapPool(_pool).token0());
            token = IERC20(SushiSwapPool(_pool).token1());
        } catch {
            expiry = PendleYieldToken(token1).expiry();
            ot = PendleYieldToken(SushiSwapPool(_pool).token1());
            token = IERC20(SushiSwapPool(_pool).token0());
        }

        tokenSymbol = token.symbol();
        tokenDecimals = token.decimals();
        ytotDecimals = ot.decimals();
    }

    function _getYTReserves(address _market) internal view returns (Reserves memory reserves) {
        (
            uint256 xytBalance,
            uint256 xytWeight,
            uint256 tokenBalance,
            uint256 tokenWeight,

        ) = PendleMarket(_market).getReserves();
        reserves.ytotBalance = xytBalance;
        reserves.ytotWeight = xytWeight;
        reserves.tokenBalance = tokenBalance;
        reserves.tokenWeight = tokenWeight;
    }

    function _getOTReserves(address _pool) internal view returns (Reserves memory reserves) {
        uint256 reserve0;
        uint256 reserve1;
        bool token0IsYT = false;
        address token0 = SushiSwapPool(_pool).token0();

        try PendleYieldToken(token0).expiry() {
            token0IsYT = true;
        } catch {}

        if (token0IsYT) {
            (reserve0, reserve1, ) = SushiSwapPool(_pool).getReserves();
        } else {
            (reserve1, reserve0, ) = SushiSwapPool(_pool).getReserves();
        }

        reserves.ytotBalance = reserve0;
        reserves.ytotWeight = (uint256(1) << 40) / 2;
        reserves.tokenBalance = reserve1;
        reserves.tokenWeight = reserves.ytotWeight;
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