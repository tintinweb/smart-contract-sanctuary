// "SPDX-License-Identifier: GPL-3.0-or-later"

pragma solidity 0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./ILiquidityMining.sol";
import "./IERC20Metadata.sol";

contract LiquidityMiningView {

    struct PoolInfo {
        uint256 pid;
        address token;
        uint8 decimals;
        uint256 totalStaked;
        uint256 accRewardPerShare;
        uint256 allocPoint;
        uint256 lastRewardBlock;

    }

    struct LiquidityMining {
        address rewardToken;
        uint8 rewardTokenDecimals;
        address reservoir;
        uint256 rewardPerBlock;
        uint256 startBlock;
        uint256 endBlock;
        uint256 currentBlock;
        uint256 currentTimestamp;
        PoolInfo[] pools;
        ILiquidityMining.UnlockInfo[] unlocks;
    }

    function getLiquidityMiningInfo(address _liquidityMining)
    external view
    returns (
        LiquidityMining memory liquidityMiningData
    )
    {
        ILiquidityMining liquidityMining = ILiquidityMining(_liquidityMining);

        ILiquidityMining.PoolInfo[] memory poolInfos = liquidityMining.getAllPools();
        PoolInfo[] memory pools = new PoolInfo[](poolInfos.length);
        uint256 i;
        for(i = 0; i < poolInfos.length; i++) {
            ILiquidityMining.PoolInfo memory pi = poolInfos[i];
            PoolInfo memory info = PoolInfo(
                i,
                pi.token,
                IERC20Metadata(pi.token).decimals(),
                IERC20(pi.token).balanceOf(_liquidityMining),
                pi.accRewardPerShare,
                pi.allocPoint,
                pi.lastRewardBlock
            );
            pools[i] = info;
        }

        liquidityMiningData = LiquidityMining(
            liquidityMining.rewardToken(),
            IERC20Metadata(liquidityMining.rewardToken()).decimals(),
            liquidityMining.reservoir(),
            liquidityMining.rewardPerBlock(),
            liquidityMining.startBlock(),
            liquidityMining.endBlock(),
            block.number,
            block.timestamp,
            pools,
            liquidityMining.getAllUnlocks()
        );
    }

    struct UserCommonRewardInfo {
        uint256 reward;
        uint256 claimedReward;
        uint256 unlockedReward;
        uint8 rewardTokenDecimals;
    }

    struct UserPoolRewardInfo {
        uint256 pid;
        address poolToken;
        uint8   poolTokenDecimals;
        uint256 unlockedReward;
        uint256 totalReward;
        uint256 staked;
        uint256 balance;
    }

    function getUserRewardInfos(address _liquidityMining, address _staker)
    external view
    returns (
        UserCommonRewardInfo memory userCommonRewardInfo,
        UserPoolRewardInfo[] memory userPoolRewardInfos
    )
    {
        ILiquidityMining liquidityMining = ILiquidityMining(_liquidityMining);

        userCommonRewardInfo = UserCommonRewardInfo(
            liquidityMining.rewards(_staker),
            liquidityMining.claimedRewards(_staker),
            liquidityMining.calcUnlocked(liquidityMining.rewards(_staker)),
            IERC20Metadata(liquidityMining.rewardToken()).decimals()
        );

        ILiquidityMining.PoolInfo[] memory pools = liquidityMining.getAllPools();
        userPoolRewardInfos = new UserPoolRewardInfo[](pools.length);
        uint256 i;
        for(i = 0; i < pools.length; i++) {
            uint256 pid = liquidityMining.poolPidByAddress(pools[i].token);
            (uint256 total, uint256 unlocked) = liquidityMining.getPendingReward(pid, _staker);

            UserPoolRewardInfo memory info = UserPoolRewardInfo(
                pid,
                pools[i].token,
                IERC20Metadata(pools[i].token).decimals(),
                unlocked,
                total,
                liquidityMining.userPoolInfo(pid, _staker).amount,
                IERC20(pools[i].token).balanceOf(msg.sender)
            );
            userPoolRewardInfos[i] = info;
        }
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
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

interface ILiquidityMining {
    struct UnlockInfo {
        uint256 block;
        uint256 quota;
    }
    function getAllUnlocks() external view returns (UnlockInfo[] memory);
    function unlocksTotalQuotation() external view returns(uint256);

    struct PoolInfo {
        address token;
        uint256 accRewardPerShare;
        uint256 allocPoint;
        uint256 lastRewardBlock;
    }
    function getAllPools() external view returns (PoolInfo[] memory);
    function totalAllocPoint() external returns(uint256);

    function deposit(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
    function claim() external;
    function getPendingReward(uint256 _pid, address _user)
    external view
    returns(uint256 total, uint256 available);

    function rewardToken() external view returns(address);
    function reservoir() external view returns(address);
    function rewardPerBlock() external view returns(uint256);
    function startBlock() external view returns(uint256);
    function endBlock() external view returns(uint256);

    function rewards(address) external view returns(uint256);
    function claimedRewards(address) external view returns(uint256);
    function poolPidByAddress(address) external view returns(uint256);
    function isTokenAdded(address _token) external view returns (bool);
    function calcUnlocked(uint256 reward) external view returns(uint256 claimable);

    struct UserPoolInfo {
        uint256 amount;
        uint256 accruedReward;
    }
    function userPoolInfo(uint256, address) external view returns(UserPoolInfo memory);
}

// "SPDX-License-Identifier: GPL-3.0-or-later"

pragma solidity 0.7.6;

interface IERC20Metadata {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

{
  "optimizer": {
    "enabled": true,
    "runs": 1000000
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