pragma solidity =0.7.6;
pragma abicoder v2;

import './interfaces/IAlgebraStaker.sol';
import './libraries/IncentiveId.sol';
import './libraries/RewardMath.sol';
import './libraries/NFTPositionInfo.sol';

import './AlgebraVirtualPool.sol';

import 'algebra/contracts/interfaces/IAlgebraPoolDeployer.sol';
import 'algebra/contracts/interfaces/IERC20Minimal.sol';
import 'algebra/contracts/interfaces/IAlgebraPool.sol';

import 'algebra-periphery/contracts/interfaces/INonfungiblePositionManager.sol';
import 'algebra-periphery/contracts/libraries/TransferHelper.sol';
import 'algebra-periphery/contracts/base/Multicall.sol';

/// @title Algebra canonical staking interface
contract AlgebraStaker is IAlgebraStaker, Multicall {
    /// @notice Represents a staking incentive
    struct Incentive {
        uint256 totalReward;
        uint256 algReward;
        address virtualPoolAddress;
        uint96 numberOfStakes;
        bool isPoolCreated;
        uint224 totalLiquidity;
    }

    /// @notice Represents the deposit of a liquidity NFT
    struct Deposit {
        address owner;
        uint48 numberOfStakes;
        int24 tickLower;
        int24 tickUpper;
    }

    /// @notice Represents a staked liquidity NFT
    struct Stake {
        uint96 liquidityNoOverflow;
        uint128 liquidityIfOverflow;
    }

    /// @inheritdoc IAlgebraStaker
    INonfungiblePositionManager public immutable override nonfungiblePositionManager;

    IAlgebraPoolDeployer public immutable override deployer;

    /// @inheritdoc IAlgebraStaker
    uint256 public immutable override maxIncentiveStartLeadTime;
    /// @inheritdoc IAlgebraStaker
    uint256 public immutable override maxIncentiveDuration;

    address public immutable override algebraToken;

    /// @dev bytes32 refers to the return value of IncentiveId.compute
    mapping(bytes32 => Incentive) public override incentives;

    /// @dev deposits[tokenId] => Deposit
    mapping(uint256 => Deposit) public override deposits;

    /// @dev stakes[tokenId][incentiveHash] => Stake
    mapping(uint256 => mapping(bytes32 => Stake)) private _stakes;

    /// @inheritdoc IAlgebraStaker
    function stakes(uint256 tokenId, bytes32 incentiveId) public view override returns (uint128 liquidity) {
        Stake storage stake = _stakes[tokenId][incentiveId];
        liquidity = stake.liquidityNoOverflow;
        if (liquidity == type(uint96).max) {
            liquidity = stake.liquidityIfOverflow;
        }
    }

    /// @dev rewards[rewardToken][owner] => uint256
    /// @inheritdoc IAlgebraStaker
    mapping(IERC20Minimal => mapping(address => uint256)) public override rewards;

    /// @param _nonfungiblePositionManager the NFT position manager contract address
    /// @param _maxIncentiveStartLeadTime the max duration of an incentive in seconds
    /// @param _maxIncentiveDuration the max amount of seconds into the future the incentive startTime can be set
    constructor(
        IAlgebraPoolDeployer _deployer,
        INonfungiblePositionManager _nonfungiblePositionManager,
        uint256 _maxIncentiveStartLeadTime,
        uint256 _maxIncentiveDuration,
        address _algebraToken
    ) {
        deployer = _deployer;
        nonfungiblePositionManager = _nonfungiblePositionManager;
        maxIncentiveStartLeadTime = _maxIncentiveStartLeadTime;
        maxIncentiveDuration = _maxIncentiveDuration;
        algebraToken = _algebraToken;
    }

    /// @inheritdoc IAlgebraStaker
    function createIncentive(
        IncentiveKey memory key,
        uint256 reward,
        uint256 _algReward
    ) external override returns (address virtualPool) {
        (, uint32 _activeEndTimestamp, ) = key.pool.activeIncentive();
        require(
            _activeEndTimestamp < block.timestamp,
            'AlgebraStaker::createIncentive: there is already active incentive'
        );
        require(reward > 0, 'AlgebraStaker::createIncentive: reward must be positive');
        require(
            block.timestamp <= key.startTime,
            'AlgebraStaker::createIncentive: start time must be now or in the future'
        );
        require(
            key.startTime - block.timestamp <= maxIncentiveStartLeadTime,
            'AlgebraStaker::createIncentive: start time too far into future'
        );
        require(key.startTime < key.endTime, 'AlgebraStaker::createIncentive: start time must be before end time');
        require(
            key.endTime - key.startTime <= maxIncentiveDuration,
            'AlgebraStaker::createIncentive: incentive duration is too long'
        );

        bytes32 incentiveId = IncentiveId.compute(key);

        incentives[incentiveId].totalReward += reward;
        incentives[incentiveId].algReward += _algReward;

        virtualPool = address(new AlgebraVirtualPool(address(key.pool), address(this)));
        key.pool.setIncentive(virtualPool, uint32(key.endTime), uint32(key.startTime));

        incentives[incentiveId].isPoolCreated = true;
        incentives[incentiveId].virtualPoolAddress = address(virtualPool);

        TransferHelper.safeTransferFrom(address(algebraToken), msg.sender, address(this), reward);
        TransferHelper.safeTransferFrom(address(key.rewardToken), msg.sender, address(this), reward);

        emit IncentiveCreated(key.rewardToken, key.pool, virtualPool, key.startTime, key.endTime, key.refundee, reward, _algReward);
    }

    /// @notice Upon receiving a Algebra ERC721, creates the token deposit setting owner to `from`. Also stakes token
    /// in one or more incentives if properly formatted `data` has a length > 0.
    /// @inheritdoc IERC721Receiver
    function onERC721Received(
        address,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        require(
            msg.sender == address(nonfungiblePositionManager),
            'AlgebraStaker::onERC721Received: not a  Algebra nft'
        );

        (, , , , int24 tickLower, int24 tickUpper, , , , , ) = nonfungiblePositionManager.positions(tokenId);

        deposits[tokenId] = Deposit({owner: from, numberOfStakes: 0, tickLower: tickLower, tickUpper: tickUpper});
        emit DepositTransferred(tokenId, address(0), from);

        if (data.length > 0) {
            if (data.length == 160) {
                _stakeToken(abi.decode(data, (IncentiveKey)), tokenId);
            } else {
                IncentiveKey[] memory keys = abi.decode(data, (IncentiveKey[]));
                for (uint256 i = 0; i < keys.length; i++) {
                    _stakeToken(keys[i], tokenId);
                }
            }
        }
        return this.onERC721Received.selector;
    }

    /// @inheritdoc IAlgebraStaker
    function transferDeposit(uint256 tokenId, address to) external override {
        require(to != address(0), 'AlgebraStaker::transferDeposit: invalid transfer recipient');
        address owner = deposits[tokenId].owner;
        require(owner == msg.sender, 'AlgebraStaker::transferDeposit: can only be called by deposit owner');
        deposits[tokenId].owner = to;
        emit DepositTransferred(tokenId, owner, to);
    }

    /// @inheritdoc IAlgebraStaker
    function withdrawToken(
        uint256 tokenId,
        address to,
        bytes memory data
    ) external override {
        require(to != address(this), 'AlgebraStaker::withdrawToken: cannot withdraw to staker');
        Deposit memory deposit = deposits[tokenId];
        require(deposit.numberOfStakes == 0, 'AlgebraStaker::withdrawToken: cannot withdraw token while staked');
        require(deposit.owner == msg.sender, 'AlgebraStaker::withdrawToken: only owner can withdraw token');

        delete deposits[tokenId];
        emit DepositTransferred(tokenId, deposit.owner, address(0));

        nonfungiblePositionManager.safeTransferFrom(address(this), to, tokenId, data);
    }

    /// @inheritdoc IAlgebraStaker
    function stakeToken(IncentiveKey memory key, uint256 tokenId) external override {
        require(deposits[tokenId].owner == msg.sender, 'AlgebraStaker::stakeToken: only owner can stake token');
        require(deposits[tokenId].numberOfStakes == 0, 'AlgebraStaker::stakeToken: already staked');
        _stakeToken(key, tokenId);
    }

    /// @inheritdoc IAlgebraStaker
    function unstakeToken(IncentiveKey memory key, uint256 tokenId) external override {
        Deposit memory deposit = deposits[tokenId];
        bytes32 incentiveId = IncentiveId.compute(key);
        Incentive storage incentive = incentives[incentiveId];
        // anyone can call unstakeToken if the block time is after the end time of the incentive
        require(block.timestamp > key.endTime, 'AlgebraStaker::unstakeToken: cannot unstake before end time');

        uint128 liquidity = stakes(tokenId, incentiveId);

        require(liquidity != 0, 'AlgebraStaker::unstakeToken: stake does not exist');

        deposits[tokenId].numberOfStakes--;
        incentive.numberOfStakes--;

        (uint160 secondsPerLiquidityInsideX128, uint256 initTimestamp, uint256 endTimestamp) = IAlgebraVirtualPool(
            incentive.virtualPoolAddress
        ).getInnerSecondsPerLiquidity(deposit.tickLower, deposit.tickUpper);

        if (endTimestamp == 0) {
            IAlgebraVirtualPool(incentive.virtualPoolAddress).finish(uint32(block.timestamp), uint32(key.startTime));
            (secondsPerLiquidityInsideX128, initTimestamp, endTimestamp) = IAlgebraVirtualPool(
                incentive.virtualPoolAddress
            ).getInnerSecondsPerLiquidity(deposit.tickLower, deposit.tickUpper);
        }

        uint256 reward = RewardMath.computeRewardAmount(
            incentive.totalReward,
            initTimestamp,
            endTimestamp,
            liquidity,
            incentive.totalLiquidity,
            secondsPerLiquidityInsideX128
        );

        uint256 algReward = RewardMath.computeRewardAmount(
            incentive.algReward,
            initTimestamp,
            endTimestamp,
            liquidity,
            incentive.totalLiquidity,
            secondsPerLiquidityInsideX128
        );

        rewards[key.rewardToken][deposit.owner] += reward;
        rewards[IERC20Minimal(algebraToken)][deposit.owner] += algReward;

        Stake storage stake = _stakes[tokenId][incentiveId];
        delete stake.liquidityNoOverflow;
        if (liquidity >= type(uint96).max) delete stake.liquidityIfOverflow;
        emit TokenUnstaked(tokenId, incentiveId, address(key.rewardToken), deposit.owner, reward, algReward);
    }

    /// @inheritdoc IAlgebraStaker
    function claimReward(
        IERC20Minimal rewardToken,
        address to,
        uint256 amountRequested
    ) external override returns (uint256 reward) {
        reward = rewards[rewardToken][msg.sender];

        if (amountRequested != 0 && amountRequested < reward) {
            reward = amountRequested;
        }

        rewards[rewardToken][msg.sender] -= reward;
        TransferHelper.safeTransfer(address(rewardToken), to, reward);

        emit RewardClaimed(to, reward, address(rewardToken), msg.sender);
    }

    /// @inheritdoc IAlgebraStaker
    function getRewardInfo(IncentiveKey memory key, uint256 tokenId)
        external
        view
        override
        returns (uint256 reward, uint256 algReward)
    {
        bytes32 incentiveId = IncentiveId.compute(key);

        uint128 liquidity = stakes(tokenId, incentiveId);
        require(liquidity > 0, 'AlgebraStaker::getRewardInfo: stake does not exist');

        Deposit memory deposit = deposits[tokenId];
        Incentive memory incentive = incentives[incentiveId];

        (uint160 secondsPerLiquidityInsideX128, uint256 initTimestamp, uint256 endTimestamp) = IAlgebraVirtualPool(
            incentive.virtualPoolAddress
        ).getInnerSecondsPerLiquidity(deposit.tickLower, deposit.tickUpper);

        if (initTimestamp == 0) {
            initTimestamp = key.startTime;
            endTimestamp = key.endTime;
        }
        if (endTimestamp == 0) {
            endTimestamp = key.endTime;
        }

        reward = RewardMath.computeRewardAmount(
            incentive.totalReward,
            initTimestamp,
            endTimestamp,
            liquidity,
            incentive.totalLiquidity,
            secondsPerLiquidityInsideX128
        );

        algReward = RewardMath.computeRewardAmount(
            incentive.totalReward,
            initTimestamp,
            endTimestamp,
            liquidity,
            incentive.totalLiquidity,
            secondsPerLiquidityInsideX128
        );
    }

    /// @dev Stakes a deposited token without doing an ownership check
    function _stakeToken(IncentiveKey memory key, uint256 tokenId) private {
        require(block.timestamp < key.startTime, 'AlgebraStaker::stakeToken: incentive has already started');

        bytes32 incentiveId = IncentiveId.compute(key);

        require(incentives[incentiveId].totalReward > 0, 'AlgebraStaker::stakeToken: non-existent incentive');
        require(
            _stakes[tokenId][incentiveId].liquidityNoOverflow == 0,
            'AlgebraStaker::stakeToken: token already staked'
        );

        (IAlgebraPool pool, int24 tickLower, int24 tickUpper, uint128 liquidity) = NFTPositionInfo.getPositionInfo(
            deployer,
            nonfungiblePositionManager,
            tokenId
        );

        require(pool == key.pool, 'AlgebraStaker::stakeToken: token pool is not the incentive pool');
        require(liquidity > 0, 'AlgebraStaker::stakeToken: cannot stake token with 0 liquidity');

        deposits[tokenId].numberOfStakes++;
        incentives[incentiveId].numberOfStakes++;
        (, int24 tick, , , , , , ) = pool.globalState();
        IAlgebraVirtualPool virtualPool = IAlgebraVirtualPool(incentives[incentiveId].virtualPoolAddress);
        virtualPool.applyLiquidityDeltaToPosition(tickLower, tickUpper, int128(liquidity), tick);

        if (liquidity >= type(uint96).max) {
            _stakes[tokenId][incentiveId] = Stake({
                liquidityNoOverflow: type(uint96).max,
                liquidityIfOverflow: liquidity
            });
        } else {
            Stake storage stake = _stakes[tokenId][incentiveId];
            stake.liquidityNoOverflow = uint96(liquidity);
        }
        incentives[incentiveId].totalLiquidity += liquidity;

        emit TokenStaked(tokenId, incentiveId, liquidity);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;
pragma abicoder v2;

import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';

import 'algebra/contracts/interfaces/IAlgebraPoolDeployer.sol';
import 'algebra/contracts/interfaces/IAlgebraPool.sol';
import 'algebra/contracts/interfaces/IERC20Minimal.sol';

import 'algebra-periphery/contracts/interfaces/INonfungiblePositionManager.sol';
import 'algebra-periphery/contracts/interfaces/IMulticall.sol';

/// @title Algebra Staker Interface
/// @notice Allows staking nonfungible liquidity tokens in exchange for reward tokens
interface IAlgebraStaker is IERC721Receiver, IMulticall {
    /// @param rewardToken The token being distributed as a reward
    /// @param pool The Algebra pool
    /// @param startTime The time when the incentive program begins
    /// @param endTime The time when rewards stop accruing
    /// @param refundee The address which receives any remaining reward tokens when the incentive is ended
    struct IncentiveKey {
        IERC20Minimal rewardToken;
        IAlgebraPool pool;
        uint256 startTime;
        uint256 endTime;
        address refundee;
    }

    function deployer() external view returns (IAlgebraPoolDeployer);

    /// @notice The nonfungible position manager with which this staking contract is compatible
    function nonfungiblePositionManager() external view returns (INonfungiblePositionManager);

    /// @notice The max duration of an incentive in seconds
    function maxIncentiveDuration() external view returns (uint256);

    /// @notice The max amount of seconds into the future the incentive startTime can be set
    function maxIncentiveStartLeadTime() external view returns (uint256);

    function algebraToken() external view returns (address);

    /// @notice Represents a staking incentive
    /// @param incentiveId The ID of the incentive computed from its parameters
    /// @return totalReward The amount of reward token not yet claimed by users
    function incentives(bytes32 incentiveId)
        external
        view
        returns (
            uint256 totalReward,
            uint256 algReward,
            address virtualPoolAddress,
            uint96 numberOfStakes,
            bool isPoolCreated,
            uint224 totalLiquidity
        );

    /// @notice Returns information about a deposited NFT
    /// @return owner The owner of the deposited NFT
    /// @return numberOfStakes Counter of how many incentives for which the liquidity is staked
    /// @return tickLower The lower tick of the range
    /// @return tickUpper The upper tick of the range
    function deposits(uint256 tokenId)
        external
        view
        returns (
            address owner,
            uint48 numberOfStakes,
            int24 tickLower,
            int24 tickUpper
        );

    /// @notice Returns information about a staked liquidity NFT
    /// @param tokenId The ID of the staked token
    /// @param incentiveId The ID of the incentive for which the token is staked
    /// @return liquidity The amount of liquidity in the NFT as of the last time the rewards were computed
    function stakes(uint256 tokenId, bytes32 incentiveId) external view returns (uint128 liquidity);

    /// @notice Returns amounts of reward tokens owed to a given address according to the last time all stakes were updated
    /// @param rewardToken The token for which to check rewards
    /// @param owner The owner for which the rewards owed are checked
    /// @return rewardsOwed The amount of the reward token claimable by the owner
    function rewards(IERC20Minimal rewardToken, address owner) external view returns (uint256 rewardsOwed);

    /// @notice Creates a new liquidity mining incentive program
    /// @param key Details of the incentive to create
    /// @param reward The amount of reward tokens to be distributed
    function createIncentive(
        IncentiveKey memory key,
        uint256 reward,
        uint256 algReward
    ) external returns (address virtualPool);

    /// @notice Ends an incentive after the incentive end time has passed and all stakes have been withdrawn
    /// @param key Details of the incentive to end
    /// @return refund The remaining reward tokens when the incentive is ended
    //function endIncentive(IncentiveKey memory key) external returns (uint256 refund);

    /// @notice Transfers ownership of a deposit from the sender to the given recipient
    /// @param tokenId The ID of the token (and the deposit) to transfer
    /// @param to The new owner of the deposit
    function transferDeposit(uint256 tokenId, address to) external;

    /// @notice Withdraws a Algebra LP token `tokenId` from this contract to the recipient `to`
    /// @param tokenId The unique identifier of an Algebra LP token
    /// @param to The address where the LP token will be sent
    /// @param data An optional data array that will be passed along to the `to` address via the NFT safeTransferFrom
    function withdrawToken(
        uint256 tokenId,
        address to,
        bytes memory data
    ) external;

    /// @notice Stakes a Algebra LP token
    /// @param key The key of the incentive for which to stake the NFT
    /// @param tokenId The ID of the token to stake
    function stakeToken(IncentiveKey memory key, uint256 tokenId) external;

    /// @notice Unstakes a Algebra LP token
    /// @param key The key of the incentive for which to unstake the NFT
    /// @param tokenId The ID of the token to unstake
    function unstakeToken(IncentiveKey memory key, uint256 tokenId) external;

    /// @notice Transfers `amountRequested` of accrued `rewardToken` rewards from the contract to the recipient `to`
    /// @param rewardToken The token being distributed as a reward
    /// @param to The address where claimed rewards will be sent to
    /// @param amountRequested The amount of reward tokens to claim. Claims entire reward amount if set to 0.
    /// @return reward The amount of reward tokens claimed
    function claimReward(
        IERC20Minimal rewardToken,
        address to,
        uint256 amountRequested
    ) external returns (uint256 reward);

    /// @notice Calculates the reward amount that will be received for the given stake
    /// @param key The key of the incentive
    /// @param tokenId The ID of the token
    /// @return reward The reward accrued to the NFT for the given incentive thus far
    function getRewardInfo(IncentiveKey memory key, uint256 tokenId)
        external
        returns (uint256 reward, uint256 algReward);

    /// @notice Event emitted when a liquidity mining incentive has been created
    /// @param rewardToken The token being distributed as a reward
    /// @param pool The Algebra pool
    /// @param startTime The time when the incentive program begins
    /// @param endTime The time when rewards stop accruing
    /// @param refundee The address which receives any remaining reward tokens after the end time
    /// @param reward The amount of reward tokens to be distributed
    event IncentiveCreated(
        IERC20Minimal indexed rewardToken,
        IAlgebraPool indexed pool,
        address virtualPool,
        uint256 startTime,
        uint256 endTime,
        address refundee,
        uint256 reward,
        uint256 algReward
    );

    /// @notice Event that can be emitted when a liquidity mining incentive has ended
    /// @param incentiveId The incentive which is ending
    /// @param refund The amount of reward tokens refunded
    //event IncentiveEnded(bytes32 indexed incentiveId, uint256 refund);

    /// @notice Emitted when ownership of a deposit changes
    /// @param tokenId The ID of the deposit (and token) that is being transferred
    /// @param oldOwner The owner before the deposit was transferred
    /// @param newOwner The owner after the deposit was transferred
    event DepositTransferred(uint256 indexed tokenId, address indexed oldOwner, address indexed newOwner);

    /// @notice Event emitted when a Algebra LP token has been staked
    /// @param tokenId The unique identifier of an Algebra LP token
    /// @param liquidity The amount of liquidity staked
    /// @param incentiveId The incentive in which the token is staking
    event TokenStaked(uint256 indexed tokenId, bytes32 indexed incentiveId, uint128 liquidity);

    /// @notice Event emitted when a Algebra LP token has been unstaked
    /// @param tokenId The unique identifier of an Algebra LP token
    /// @param incentiveId The incentive in which the token is staking
    event TokenUnstaked(
        uint256 indexed tokenId,
        bytes32 indexed incentiveId,
        address indexed rewardAddress,
        address owner,
        uint256 reward,
        uint256 algReward
    );

    /// @notice Event emitted when a reward token has been claimed
    /// @param to The address where claimed rewards were sent to
    /// @param reward The amount of reward tokens claimed
    event RewardClaimed(address indexed to, uint256 reward, address indexed rewardAddress, address indexed owner);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;
pragma abicoder v2;

import '../interfaces/IAlgebraStaker.sol';

library IncentiveId {
    /// @notice Calculate the key for a staking incentive
    /// @param key The components used to compute the incentive identifier
    /// @return incentiveId The identifier for the incentive
    function compute(IAlgebraStaker.IncentiveKey memory key) internal pure returns (bytes32 incentiveId) {
        return keccak256(abi.encode(key));
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;

import 'algebra/contracts/libraries/FullMath.sol';
import '@openzeppelin/contracts/math/Math.sol';

/// @title Math for computing rewards
/// @notice Allows computing rewards given some parameters of stakes and incentives
library RewardMath {
    /// @notice Compute the amount of rewards owed given parameters of the incentive and stake
    /// @param totalReward The total amount of unclaimed rewards left for an incentive
    /// @param startTime When the incentive rewards began in epoch seconds
    /// @param endTime When rewards are no longer being dripped out in epoch seconds
    /// @param liquidity The amount of liquidity, assumed to be constant over the period over which the snapshots are measured
    /// @param secondsPerLiquidityInsideX128 The seconds per liquidity of the liquidity tick range as of the current block timestamp
    /// @return reward The amount of rewards owed
    function computeRewardAmount(
        uint256 totalReward,
        uint256 startTime,
        uint256 endTime,
        uint128 liquidity,
        uint224 totalLiquidity,
        uint160 secondsPerLiquidityInsideX128
    ) internal pure returns (uint256 reward) {
        // this operation is safe, as the difference cannot be greater than 1/stake.liquidity
        uint256 secondsInsideX128 = secondsPerLiquidityInsideX128 * liquidity;

        if (endTime - startTime == 0) {
            reward = FullMath.mulDiv(totalReward, liquidity, totalLiquidity);
        } else {
            reward = FullMath.mulDiv(totalReward, secondsInsideX128, (endTime - startTime) << 128);
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;

import 'algebra-periphery/contracts/interfaces/INonfungiblePositionManager.sol';
import 'algebra/contracts/interfaces/IAlgebraFactory.sol';
import 'algebra/contracts/interfaces/IAlgebraPool.sol';
import 'algebra/contracts/interfaces/IAlgebraPoolDeployer.sol';
import 'algebra-periphery/contracts/libraries/PoolAddress.sol';

/// @notice Encapsulates the logic for getting info about a NFT token ID
library NFTPositionInfo {
    /// @param deployer The address of the Algebra Deployer used in computing the pool address
    /// @param nonfungiblePositionManager The address of the nonfungible position manager to query
    /// @param tokenId The unique identifier of an Algebra LP token
    /// @return pool The address of the Algebra pool
    /// @return tickLower The lower tick of the Algebra position
    /// @return tickUpper The upper tick of the Algebra position
    /// @return liquidity The amount of liquidity staked
    function getPositionInfo(
        IAlgebraPoolDeployer deployer,
        INonfungiblePositionManager nonfungiblePositionManager,
        uint256 tokenId
    )
        internal
        view
        returns (
            IAlgebraPool pool,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity
        )
    {
        address token0;
        address token1;
        (, , token0, token1, tickLower, tickUpper, liquidity, , , , ) = nonfungiblePositionManager.positions(tokenId);

        pool = IAlgebraPool(
            PoolAddress.computeAddress(address(deployer), PoolAddress.PoolKey({token0: token0, token1: token1}))
        );
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;

import './libraries/TickManager.sol';
import './libraries/TickTable.sol';
import './libraries/LiquidityMath.sol';

import './interfaces/IAlgebraVirtualPool.sol';

contract AlgebraVirtualPool is IAlgebraVirtualPool {
    using TickTable for mapping(int16 => uint256);
    using TickManager for mapping(int24 => TickManager.Tick);

    // @inheritdoc IAlgebraVirtualPool
    address public immutable poolAddress;
    // @inheritdoc IAlgebraVirtualPool
    address public immutable stakerAddress;

    // @inheritdoc IAlgebraVirtualPool
    uint32 public override initTimestamp;
    // @inheritdoc IAlgebraVirtualPool
    uint32 public override endTimestamp;
    // @inheritdoc IAlgebraVirtualPool
    uint32 public override timeOutside;
    uint160 public override globalSecondsPerLiquidityCumulative;
    // @inheritdoc IAlgebraVirtualPool
    uint128 public override prevLiquidity;
    // @inheritdoc IAlgebraVirtualPool
    uint128 public override currentLiquidity;
    // @inheritdoc IAlgebraVirtualPool
    uint32 public override _prevTimestamp;
    // @inheritdoc IAlgebraVirtualPool
    int24 public override globalTick;

    // @inheritdoc IAlgebraVirtualPool
    mapping(int24 => TickManager.Tick) public override ticks;
    mapping(int16 => uint256) private tickTable;

    modifier onlyPool() {
        require(msg.sender == poolAddress, 'only the pool can call this function');
        _;
    }

    modifier onlyStaker() {
        require(msg.sender == stakerAddress, 'only staker can call this function');
        _;
    }

    constructor(address _poolAddress, address _stakerAddress) {
        poolAddress = _poolAddress;
        stakerAddress = _stakerAddress;
    }

    // @inheritdoc IAlgebraVirtualPool
    function finish(uint32 _endTimestamp, uint32 startTime) external override onlyStaker {
        uint32 currentTimestamp = _endTimestamp;
        uint32 previousTimestamp = _prevTimestamp;

        if (initTimestamp == 0) {
            initTimestamp = startTime;
            prevLiquidity = currentLiquidity;
            previousTimestamp = startTime;
        }

        previousTimestamp = previousTimestamp < initTimestamp ? initTimestamp : previousTimestamp;
        if (prevLiquidity > 0)
            globalSecondsPerLiquidityCumulative =
                globalSecondsPerLiquidityCumulative +
                ((uint160(currentTimestamp - previousTimestamp) << 128) / (prevLiquidity));
        else timeOutside += currentTimestamp - previousTimestamp;

        endTimestamp = _endTimestamp;
    }

    // @inheritdoc IAlgebraVirtualPool
    function getInnerSecondsPerLiquidity(int24 bottomTick, int24 topTick)
        external
        view
        override
        returns (
            uint160 innerSecondsSpentPerLiquidity,
            uint32 initTime,
            uint32 endTime
        )
    {
        uint160 lowerSecondsPerLiquidity = ticks[bottomTick].outerSecondsPerLiquidity;
        uint160 upperSecondsPerLiquidity = ticks[topTick].outerSecondsPerLiquidity;

        if (globalTick < bottomTick) {
            return (
                lowerSecondsPerLiquidity - upperSecondsPerLiquidity,
                initTimestamp,
                endTimestamp == 0 ? 0 : endTimestamp - timeOutside
            );
        } else if (globalTick < topTick) {
            return (
                globalSecondsPerLiquidityCumulative - lowerSecondsPerLiquidity - upperSecondsPerLiquidity,
                initTimestamp,
                endTimestamp == 0 ? 0 : endTimestamp - timeOutside
            );
        } else {
            return (
                upperSecondsPerLiquidity - lowerSecondsPerLiquidity,
                initTimestamp,
                endTimestamp == 0 ? 0 : endTimestamp - timeOutside
            );
        }
    }

    // @inheritdoc IAlgebraVirtualPool
    function cross(int24 nextTick, bool zeroForOne) external override onlyPool {
        if (ticks[nextTick].initialized) {
            int128 liquidityDelta = ticks.cross(nextTick, 0, 0, globalSecondsPerLiquidityCumulative, 0, 0);

            if (zeroForOne) liquidityDelta = -liquidityDelta;
            currentLiquidity = LiquidityMath.addDelta(currentLiquidity, liquidityDelta);
        }
        globalTick = zeroForOne ? nextTick - 1 : nextTick;
    }

    // @inheritdoc IAlgebraVirtualPool
    function increaseCumulative(uint32 previousTimestamp, uint32 currentTimestamp) external override onlyPool {
        if (initTimestamp == 0) {
            initTimestamp = currentTimestamp;
            prevLiquidity = currentLiquidity;
        }
        previousTimestamp = previousTimestamp < initTimestamp ? initTimestamp : previousTimestamp;
        if (prevLiquidity > 0)
            globalSecondsPerLiquidityCumulative =
                globalSecondsPerLiquidityCumulative +
                ((uint160(currentTimestamp - previousTimestamp) << 128) / (prevLiquidity));
        else timeOutside += currentTimestamp - previousTimestamp;
        _prevTimestamp = currentTimestamp;
    }

    // @inheritdoc IAlgebraVirtualPool
    function processSwap() external override onlyPool {
        prevLiquidity = currentLiquidity;
    }

    // @inheritdoc IAlgebraVirtualPool
    function applyLiquidityDeltaToPosition(
        int24 bottomTick,
        int24 topTick,
        int128 liquidityDelta,
        int24 tick
    ) external override onlyStaker {
        // if we need to update the ticks, do it
        bool flippedBottom;
        bool flippedTop;
        globalTick = tick;
        if (liquidityDelta != 0) {
            if (globalTick >= bottomTick && globalTick < topTick) {
                currentLiquidity = LiquidityMath.addDelta(currentLiquidity, liquidityDelta);
            }

            if (ticks.update(bottomTick, globalTick, liquidityDelta, 0, 0, 0, 0, 0, false)) {
                flippedBottom = true;
                tickTable.toggleTick(bottomTick);
            }

            if (ticks.update(topTick, globalTick, liquidityDelta, 0, 0, 0, 0, 0, true)) {
                flippedTop = true;
                tickTable.toggleTick(topTick);
            }
        }

        // clear any tick data that is no longer needed
        if (liquidityDelta < 0) {
            if (flippedBottom) {
                ticks.clear(bottomTick);
            }
            if (flippedTop) {
                ticks.clear(topTick);
            }
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/**
 * @title An interface for a contract that is capable of deploying Algebra Pools
 * @notice A contract that constructs a pool must implement this to pass arguments to the pool
 * @dev This is used to avoid having constructor arguments in the pool contract, which results in the init code hash
 * of the pool being constant allowing the CREATE2 address of the pool to be cheaply computed on-chain
 */
interface IAlgebraPoolDeployer {
    /**
     * @notice Get the parameters to be used in constructing the pool, set transiently during pool creation.
     * @dev Called by the pool constructor to fetch the parameters of the pool
     * Returns dataStorage The pools associated dataStorage
     * Returns factory The factory address
     * Returns token0 The first token of the pool by address sort order
     * Returns token1 The second token of the pool by address sort order
     */
    function parameters()
        external
        view
        returns (
            address dataStorage,
            address factory,
            address token0,
            address token1
        );

    /**
     * @dev Deploys a pool with the given parameters by transiently setting the parameters storage slot and then
     * clearing it after deploying the pool.
     * @param dataStorage The pools associated dataStorage
     * @param factory The contract address of the Algebra factory
     * @param token0 The first token of the pool by address sort order
     * @param token1 The second token of the pool by address sort order
     * @return pool The deployed pool's address
     */
    function deploy(
        address dataStorage,
        address factory,
        address token0,
        address token1
    ) external returns (address pool);

    /**
     * @dev Sets the factory address to the poolDeployer for permissioned actions
     * @param factory The address of the Algebra factory
     */
    function setFactory(address factory) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Minimal ERC20 interface for Algebra
/// @notice Contains a subset of the full ERC20 interface that is used in Algebra
interface IERC20Minimal {
    /// @notice Returns the balance of a token
    /// @param account The account for which to look up the number of tokens it has, i.e. its balance
    /// @return The number of tokens held by the account
    function balanceOf(address account) external view returns (uint256);

    /// @notice Transfers the amount of token from the `msg.sender` to the recipient
    /// @param recipient The account that will receive the amount transferred
    /// @param amount The number of tokens to send from the sender to the recipient
    /// @return Returns true for a successful transfer, false for an unsuccessful transfer
    function transfer(address recipient, uint256 amount) external returns (bool);

    /// @notice Returns the current allowance given to a spender by an owner
    /// @param owner The account of the token owner
    /// @param spender The account of the token spender
    /// @return The current allowance granted by `owner` to `spender`
    function allowance(address owner, address spender) external view returns (uint256);

    /// @notice Sets the allowance of a spender from the `msg.sender` to the value `amount`
    /// @param spender The account which will be allowed to spend a given amount of the owners tokens
    /// @param amount The amount of tokens allowed to be used by `spender`
    /// @return Returns true for a successful approval, false for unsuccessful
    function approve(address spender, uint256 amount) external returns (bool);

    /// @notice Transfers `amount` tokens from `sender` to `recipient` up to the allowance given to the `msg.sender`
    /// @param sender The account from which the transfer will be initiated
    /// @param recipient The recipient of the transfer
    /// @param amount The amount of the transfer
    /// @return Returns true for a successful transfer, false for unsuccessful
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /// @notice Event emitted when tokens are transferred from one address to another, either via `#transfer` or `#transferFrom`.
    /// @param from The account from which the tokens were sent, i.e. the balance decreased
    /// @param to The account to which the tokens were sent, i.e. the balance increased
    /// @param value The amount of tokens that were transferred
    event Transfer(address indexed from, address indexed to, uint256 value);

    /// @notice Event emitted when the approval amount for the spender of a given owner's tokens changes.
    /// @param owner The account that approved spending of its tokens
    /// @param spender The account for which the spending allowance was modified
    /// @param value The new allowance from the owner to the spender
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import './pool/IAlgebraPoolImmutables.sol';
import './pool/IAlgebraPoolState.sol';
import './pool/IAlgebraPoolDerivedState.sol';
import './pool/IAlgebraPoolActions.sol';
import './pool/IAlgebraPoolPermissionedActions.sol';
import './pool/IAlgebraPoolEvents.sol';

/**
 * @title The interface for a Algebra Pool
 * @dev The pool interface is broken up into many smaller pieces
 */
interface IAlgebraPool is
    IAlgebraPoolImmutables,
    IAlgebraPoolState,
    IAlgebraPoolDerivedState,
    IAlgebraPoolActions,
    IAlgebraPoolPermissionedActions,
    IAlgebraPoolEvents
{

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@openzeppelin/contracts/token/ERC721/IERC721Metadata.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Enumerable.sol';

import './IPoolInitializer.sol';
import './IERC721Permit.sol';
import './IPeripheryPayments.sol';
import './IPeripheryImmutableState.sol';
import '../libraries/PoolAddress.sol';

/// @title Non-fungible token for positions
/// @notice Wraps Algebra positions in a non-fungible token interface which allows for them to be transferred
/// and authorized.
interface INonfungiblePositionManager is
    IPoolInitializer,
    IPeripheryPayments,
    IPeripheryImmutableState,
    IERC721Metadata,
    IERC721Enumerable,
    IERC721Permit
{
    /// @notice Emitted when liquidity is increased for a position NFT
    /// @dev Also emitted when a token is minted
    /// @param tokenId The ID of the token for which liquidity was increased
    /// @param liquidity The amount by which liquidity for the NFT position was increased
    /// @param actualLiquidity the actual liquidity that was added into a pool. Could differ from
    /// _liquidity_ when using FeeOnTransfer tokens
    /// @param amount0 The amount of token0 that was paid for the increase in liquidity
    /// @param amount1 The amount of token1 that was paid for the increase in liquidity
    event IncreaseLiquidity(
        uint256 indexed tokenId,
        uint128 liquidity,
        uint128 actualLiquidity,
        uint256 amount0,
        uint256 amount1,
        address pool
    );
    /// @notice Emitted when liquidity is decreased for a position NFT
    /// @param tokenId The ID of the token for which liquidity was decreased
    /// @param liquidity The amount by which liquidity for the NFT position was decreased
    /// @param amount0 The amount of token0 that was accounted for the decrease in liquidity
    /// @param amount1 The amount of token1 that was accounted for the decrease in liquidity
    event DecreaseLiquidity(uint256 indexed tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);
    /// @notice Emitted when tokens are collected for a position NFT
    /// @dev The amounts reported may not be exactly equivalent to the amounts transferred, due to rounding behavior
    /// @param tokenId The ID of the token for which underlying tokens were collected
    /// @param recipient The address of the account that received the collected tokens
    /// @param amount0 The amount of token0 owed to the position that was collected
    /// @param amount1 The amount of token1 owed to the position that was collected
    event Collect(uint256 indexed tokenId, address recipient, uint256 amount0, uint256 amount1);

    /// @notice Returns the position information associated with a given token ID.
    /// @dev Throws if the token ID is not valid.
    /// @param tokenId The ID of the token that represents the position
    /// @return nonce The nonce for permits
    /// @return operator The address that is approved for spending
    /// @return token0 The address of the token0 for a specific pool
    /// @return token1 The address of the token1 for a specific pool
    /// @return tickLower The lower end of the tick range for the position
    /// @return tickUpper The higher end of the tick range for the position
    /// @return liquidity The liquidity of the position
    /// @return feeGrowthInside0LastX128 The fee growth of token0 as of the last action on the individual position
    /// @return feeGrowthInside1LastX128 The fee growth of token1 as of the last action on the individual position
    /// @return tokensOwed0 The uncollected amount of token0 owed to the position as of the last computation
    /// @return tokensOwed1 The uncollected amount of token1 owed to the position as of the last computation
    function positions(uint256 tokenId)
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    struct MintParams {
        address token0;
        address token1;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    /// @notice Creates a new position wrapped in a NFT
    /// @dev Call this when the pool does exist and is initialized. Note that if the pool is created but not initialized
    /// a method does not exist, i.e. the pool is assumed to be initialized.
    /// @param params The params necessary to mint a position, encoded as `MintParams` in calldata
    /// @return tokenId The ID of the token that represents the minted position
    /// @return liquidity The amount of liquidity for this position
    /// @return amount0 The amount of token0
    /// @return amount1 The amount of token1
    function mint(MintParams calldata params)
        external
        payable
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    struct IncreaseLiquidityParams {
        uint256 tokenId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Increases the amount of liquidity in a position, with tokens paid by the `msg.sender`
    /// @param params tokenId The ID of the token for which liquidity is being increased,
    /// amount0Desired The desired amount of token0 to be spent,
    /// amount1Desired The desired amount of token1 to be spent,
    /// amount0Min The minimum amount of token0 to spend, which serves as a slippage check,
    /// amount1Min The minimum amount of token1 to spend, which serves as a slippage check,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return liquidity The new liquidity amount as a result of the increase
    /// @return amount0 The amount of token0 to acheive resulting liquidity
    /// @return amount1 The amount of token1 to acheive resulting liquidity
    function increaseLiquidity(IncreaseLiquidityParams calldata params)
        external
        payable
        returns (
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    struct DecreaseLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Decreases the amount of liquidity in a position and accounts it to the position
    /// @param params tokenId The ID of the token for which liquidity is being decreased,
    /// amount The amount by which liquidity will be decreased,
    /// amount0Min The minimum amount of token0 that should be accounted for the burned liquidity,
    /// amount1Min The minimum amount of token1 that should be accounted for the burned liquidity,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return amount0 The amount of token0 accounted to the position's tokens owed
    /// @return amount1 The amount of token1 accounted to the position's tokens owed
    function decreaseLiquidity(DecreaseLiquidityParams calldata params)
        external
        payable
        returns (uint256 amount0, uint256 amount1);

    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    /// @notice Collects up to a maximum amount of fees owed to a specific position to the recipient
    /// @param params tokenId The ID of the NFT for which tokens are being collected,
    /// recipient The account that should receive the tokens,
    /// amount0Max The maximum amount of token0 to collect,
    /// amount1Max The maximum amount of token1 to collect
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(CollectParams calldata params) external payable returns (uint256 amount0, uint256 amount1);

    /// @notice Burns a token ID, which deletes it from the NFT contract. The token must have 0 liquidity and all tokens
    /// must be collected first.
    /// @param tokenId The ID of the token that is being burned
    function burn(uint256 tokenId) external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    /// @notice Transfers NativeToken to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferNative(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;
pragma abicoder v2;

import '../interfaces/IMulticall.sol';

/// @title Multicall
/// @notice Enables calling multiple methods in a single call to the contract
abstract contract Multicall is IMulticall {
    /// @inheritdoc IMulticall
    function multicall(bytes[] calldata data) external payable override returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(data[i]);

            if (!success) {
                // Next 5 lines from https://ethereum.stackexchange.com/a/83577
                if (result.length < 68) revert();
                assembly {
                    result := add(result, 0x04)
                }
                revert(abi.decode(result, (string)));
            }

            results[i] = result;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

/// @title Multicall interface
/// @notice Enables calling multiple methods in a single call to the contract
interface IMulticall {
    /// @notice Call multiple functions in the current contract and return the data from all of them if they all succeed
    /// @dev The `msg.value` should not be trusted for any method callable from multicall.
    /// @param data The encoded function data for each of the calls to make to this contract
    /// @return results The results from each of the calls passed in via data
    function multicall(bytes[] calldata data) external payable returns (bytes[] memory results);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import '../IDataStorageOperator.sol';

// @title Pool state that never changes
interface IAlgebraPoolImmutables {
    /**
     * @notice The contract that stores all the timepoints and can perform actions with them
     * @return The operator address
     */
    function dataStorageOperator() external view returns (address);

    /**
     * @notice The contract that deployed the pool, which must adhere to the IAlgebraFactory interface
     * @return The contract address
     */
    function factory() external view returns (address);

    /**
     * @notice The first of the two tokens of the pool, sorted by address
     * @return The token contract address
     */
    function token0() external view returns (address);

    /**
     * @notice The second of the two tokens of the pool, sorted by address
     * @return The token contract address
     */
    function token1() external view returns (address);

    /**
     * @notice The pool tick spacing
     * @dev Ticks can only be used at multiples of this value
     * e.g.: a tickSpacing of 60 means ticks can be initialized every 60th tick, i.e., ..., -120, -60, 0, 60, 120, ...
     * This value is an int24 to avoid casting even though it is always positive.
     * @return The tick spacing
     */
    function tickSpacing() external view returns (uint8);

    /**
     * @notice The maximum amount of position liquidity that can use any tick in the range
     * @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
     * also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
     * @return The max amount of liquidity per tick
     */
    function maxLiquidityPerTick() external view returns (uint128);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

// @title Pool state that can change
interface IAlgebraPoolState {
    /**
     * @notice The globalState structure in the pool stores many values but requires only one slot
     * and is exposed as a single method to save gas when accessed externally.
     * @return price The current price of the pool as a sqrt(token1/token0) Q64.96 value
     * @return tick The current tick of the pool, i.e. according to the last tick transition that was run.
     * This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(price) if the price is on a tick
     * boundary.
     * timepointIndex The index of the last written timepoint
     * timepointIndexSwap The index of the last written (on swap) timepoint
     * communityFee The community fee for both tokens of the pool.
     * Encoded as two 4 bit values, where the community fee of token1 is shifted 4 bits and the community fee of token0
     * is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
     * unlocked Whether the pool is currently locked to reentrancy
     */
    function globalState()
        external
        view
        returns (
            uint160 price,
            int24 tick,
            uint16 fee,
            uint16 timepointIndex,
            uint16 timepointIndexSwap,
            uint8 communityFeeToken0,
            uint8 communityFeeToken1,
            bool unlocked
        );

    /**
     * @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
     * @dev This value can overflow the uint256
     */
    function totalFeeGrowth0Token() external view returns (uint256);

    /**
     * @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
     * @dev This value can overflow the uint256
     */
    function totalFeeGrowth1Token() external view returns (uint256);

    /**
     * @notice The amounts of token0 and token1 that are owed to the protocol
     * @dev Protocol fees will never exceed uint128 max in either token
     */
    function communityFees() external view returns (uint128 token0, uint128 token1);

    /**
     * @notice The currently in range liquidity available to the pool
     * @dev This value has no relationship to the total liquidity across all ticks
     */
    function liquidity() external view returns (uint128);

    /**
     * @notice The pool's fee in hundredths of a bip, i.e. 1e-6
     * @return The fee
     */
    //function fee() external view returns (uint24);

    /**
     * @notice Look up information about a specific tick in the pool
     * @param tick The tick to look up
     * @return liquidityTotal the total amount of position liquidity that uses the pool either as tick lower or
     * tick upper,
     * @return liquidityDelta how much liquidity changes when the pool price crosses the tick,
     * outerFeeGrowth0Token the fee growth on the other side of the tick from the current tick in token0,
     * outerFeeGrowth1Token the fee growth on the other side of the tick from the current tick in token1,
     * outerTickCumulative the cumulative tick value on the other side of the tick from the current tick
     * outerSecondsPerLiquidity the seconds spent per liquidity on the other side of the tick from the current tick,
     * outerSecondsSpent the seconds spent on the other side of the tick from the current tick,
     * initialized Set to true if the tick is initialized, i.e. liquidityTotal is greater than 0,
     * otherwise equal to false. Outside values can only be used if the tick is initialized.
     * In addition, these values are only relative and must be used only in comparison to previous snapshots for
     * a specific position.
     */
    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityTotal,
            int128 liquidityDelta,
            uint256 outerFeeGrowth0Token,
            uint256 outerFeeGrowth1Token,
            int56 outerTickCumulative,
            uint160 outerSecondsPerLiquidity,
            uint32 outerSecondsSpent,
            bool initialized
        );

    /** @notice Returns 256 packed tick initialized boolean values. See TickTable for more information */
    function tickTable(int16 wordPosition) external view returns (uint256);

    /**
     * @notice Returns the information about a position by the position's key
     * @param key The position's key is a hash of a preimage composed by the owner, bottomTick and topTick
     * @return  _liquidity The amount of liquidity in the position,
     * innerFeeGrowth0Token fee growth of token0 inside the tick range as of the last mint/burn/poke,
     * innerFeeGrowth1Token fee growth of token1 inside the tick range as of the last mint/burn/poke,
     * fees0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
     * fees1 the computed amount of token1 owed to the position as of the last mint/burn/poke
     */
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 _liquidity,
            uint256 innerFeeGrowth0Token,
            uint256 innerFeeGrowth1Token,
            uint128 fees0,
            uint128 fees1
        );

    /**
     * @notice Returns data about a specific timepoint index
     * @param index The element of the timepoints array to fetch
     * @dev You most likely want to use #getTimepoints() instead of this method to get an timepoint as of some amount of time
     * ago, rather than at a specific index in the array.
     * @return initialized whether the timepoint has been initialized and the values are safe to use
     * blockTimestamp The timestamp of the timepoint,
     * tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the timepoint timestamp,
     * secondsPerLiquidityCumulative the seconds per in range liquidity for the life of the pool as of the timepoint timestamp,
     * volatilityCumulative Cumulative standard deviation for the life of the pool as of the timepoint timestamp
     * volumePerAvgLiquidity Cumulative swap volume per liquidity for the life of the pool as of the timepoint timestamp
     */
    function timepoints(uint256 index)
        external
        view
        returns (
            bool initialized,
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulative,
            uint112 volatilityCumulative,
            uint256 volumePerAvgLiquidity
        );

    /**
     * @notice Returns the information about active incentive
     * @dev if there is no active incentive at the moment, virtualPool,endTimestamp,startTimestamp would be equal to 0
     * @return virtualPool The address of a virtual pool associated with the current active incentive
     * endTimestamp The timestamp when the active incentive is finished
     * startTimestamp The first swap after this timestamp is going to initialize the virtual pool
     */
    function activeIncentive()
        external
        view
        returns (
            address virtualPool,
            uint32 endTimestamp,
            uint32 startTimestamp
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/**
 * @title Pool state that is not stored
 * @notice Contains view functions to provide information about the pool that is computed rather than stored on the
 * blockchain. The functions here may have variable gas costs.
 */
interface IAlgebraPoolDerivedState {
    /**
     * @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
     * @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
     * the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
     * you must call it with secondsAgos = [3600, 0].
     * @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
     * log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
     * @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
     * @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
     * @return secondsPerLiquidityCumulatives Cumulative seconds per liquidity-in-range value as of each `secondsAgos`
     * from the current block timestamp
     * @return volatilityCumulatives Cumulative standard deviation as of each `secondsAgos`
     * @return volumePerAvgLiquiditys Cumulative swap volume per liquidity as of each `secondsAgos`
     */
    function getTimepoints(uint32[] calldata secondsAgos)
        external
        view
        returns (
            int56[] memory tickCumulatives,
            uint160[] memory secondsPerLiquidityCumulatives,
            uint112[] memory volatilityCumulatives,
            uint256[] memory volumePerAvgLiquiditys
        );

    /**
     * @notice Returns a snapshot of the tick cumulative, seconds per liquidity and seconds inside a tick range
     * @dev Snapshots must only be compared to other snapshots, taken over a period for which a position existed.
     * I.e., snapshots cannot be compared if a position is not held for the entire period between when the first
     * snapshot is taken and the second snapshot is taken.
     * @param bottomTick The lower tick of the range
     * @param topTick The upper tick of the range
     * @return innerTickCumulative The snapshot of the tick accumulator for the range
     * @return innerSecondsSpentPerLiquidity The snapshot of seconds per liquidity for the range
     * @return innerSecondsSpent The snapshot of seconds per liquidity for the range
     */
    function getInnerCumulatives(int24 bottomTick, int24 topTick)
        external
        view
        returns (
            int56 innerTickCumulative,
            uint160 innerSecondsSpentPerLiquidity,
            uint32 innerSecondsSpent
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

// @title Permissionless pool actions
interface IAlgebraPoolActions {
    /**
     * @notice Sets the initial price for the pool
     * @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
     * @param price the initial sqrt price of the pool as a Q64.96
     */
    function initialize(uint160 price) external;

    /**
     * @notice Adds liquidity for the given recipient/bottomTick/topTick position
     * @dev The caller of this method receives a callback in the form of IAlgebraMintCallback# AlgebraMintCallback
     * in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
     * on bottomTick, topTick, the amount of liquidity, and the current price.
     * @param recipient The address for which the liquidity will be created
     * @param bottomTick The lower tick of the position in which to add liquidity
     * @param topTick The upper tick of the position in which to add liquidity
     * @param amount The amount of liquidity to mint
     * @param data Any data that should be passed through to the callback
     * @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
     * amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
     */
    function mint(
        address sender,
        address recipient,
        int24 bottomTick,
        int24 topTick,
        uint128 amount,
        bytes calldata data
    )
        external
        returns (
            uint256 amount0,
            uint256 amount1,
            uint256 liquidityAmount
        );

    /**
     *  @notice Collects tokens owed to a position
     *  @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
     *  Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
     *  amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
     *  actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
     *  @param recipient The address which should receive the fees collected
     *  @param bottomTick The lower tick of the position for which to collect fees
     *  @param topTick The upper tick of the position for which to collect fees
     *  @param amount0Requested How much token0 should be withdrawn from the fees owed
     *  @param amount1Requested How much token1 should be withdrawn from the fees owed
     *  @return amount0 The amount of fees collected in token0
     *  amount1 The amount of fees collected in token1
     */
    function collect(
        address recipient,
        int24 bottomTick,
        int24 topTick,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    /**
     *  @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
     *  @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
     *  @dev Fees must be collected separately via a call to #collect
     *  @param bottomTick The lower tick of the position for which to burn liquidity
     *  @param topTick The upper tick of the position for which to burn liquidity
     *  @param amount How much liquidity to burn
     *  @return amount0 The amount of token0 sent to the recipient
     *  amount1 The amount of token1 sent to the recipient
     */
    function burn(
        int24 bottomTick,
        int24 topTick,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

    /**
     *  @notice Swap token0 for token1, or token1 for token0
     *  @dev The caller of this method receives a callback in the form of IAlgebraSwapCallback# AlgebraSwapCallback
     *  @param recipient The address to receive the output of the swap
     *  @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
     *  @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
     *  @param limitSqrtPrice The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
     *  value after the swap. If one for zero, the price cannot be greater than this value after the swap
     *  @param data Any data to be passed through to the callback. If using the Router it should contain
     *  SwapRouter#SwapCallbackData
     *  @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
     *  amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
     */
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 limitSqrtPrice,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /**
     *  @notice Swap token0 for token1, or token1 for token0 (tokens that have fee on transfer)
     *  @dev The caller of this method receives a callback in the form of I AlgebraSwapCallback# AlgebraSwapCallback
     *  @param sender The address called this function (Comes from the Router)
     *  @param recipient The address to receive the output of the swap
     *  @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
     *  @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
     *  @param limitSqrtPrice The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
     *  value after the swap. If one for zero, the price cannot be greater than this value after the swap
     *  @param data Any data to be passed through to the callback. If using the Router it should contain
     *  SwapRouter#SwapCallbackData
     *  @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
     *  amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
     */
    function swapSupportingFeeOnInputTokens(
        address sender,
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 limitSqrtPrice,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /**
     *  @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
     *  @dev The caller of this method receives a callback in the form of IAlgebraFlashCallback# AlgebraFlashCallback
     *  @dev Can be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling
     *  with 0 amount{0,1} and sending the donation amount(s) from the callback
     *  @param recipient The address which will receive the token0 and token1 amounts
     *  @param amount0 The amount of token0 to send
     *  @param amount1 The amount of token1 to send
     *  @param data Any data to be passed through to the callback
     */
    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/**
 * @title Permissioned pool actions
 * @notice Contains pool methods that may only be called by the factory owner or staker
 */
interface IAlgebraPoolPermissionedActions {
    /**
     * @notice Set the denominator of the protocol's % share of the fees
     * @param communityFee0 new community fee for token0 of the pool
     * @param communityFee1 new community fee for token1 of the pool
     */
    function setCommunityFee(uint8 communityFee0, uint8 communityFee1) external;

    /**
     * @notice Sets an active incentive
     * @param virtualPoolAddress The address of a virtual pool associated with the incentive
     * @param endTimestamp The timestamp when the active incentive is finished
     * @param startTimestamp The first swap after this timestamp is going to initialize the virtual pool
     */
    function setIncentive(
        address virtualPoolAddress,
        uint32 endTimestamp,
        uint32 startTimestamp
    ) external;

    /**
     * @notice Collect the community fee accrued to the pool
     * @param recipient The address to which collected community fees should be sent
     * @param amount0Requested The maximum amount of token0 to send, can be 0 to collect fees in only token1
     * @param amount1Requested The maximum amount of token1 to send, can be 0 to collect fees in only token0
     * @return amount0 The community fee collected in token0
     * amount1 The community fee collected in token1
     */
    function collectCommunityFee(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

// @title Events emitted by a pool
interface IAlgebraPoolEvents {
    /**
     * @notice Emitted exactly once by a pool when #initialize is first called on the pool
     * @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
     * @param price The initial sqrt price of the pool, as a Q64.96
     * @param tick The initial tick of the pool, i.e. log base 1.0001 of the starting price of the pool
     */
    event Initialize(uint160 price, int24 tick);

    /**
     * @notice Emitted when liquidity is minted for a given position
     * @param sender The address that minted the liquidity
     * @param owner The owner of the position and recipient of any minted liquidity
     * @param bottomTick The lower tick of the position
     * @param topTick The upper tick of the position
     * @param amount The amount of liquidity minted to the position range
     * @param amount0 How much token0 was required for the minted liquidity
     * @param amount1 How much token1 was required for the minted liquidity
     */
    event Mint(
        address sender,
        address indexed owner,
        int24 indexed bottomTick,
        int24 indexed topTick,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /**
     * @notice Emitted when fees are collected by the owner of a position
     * @dev Collect events may be emitted with zero amount0 and amount1 when the caller chooses not to collect fees
     * @param owner The owner of the position for which fees are collected
     * @param bottomTick The lower tick of the position
     * @param topTick The upper tick of the position
     * @param amount0 The amount of token0 fees collected
     * @param amount1 The amount of token1 fees collected
     */
    event Collect(
        address indexed owner,
        address recipient,
        int24 indexed bottomTick,
        int24 indexed topTick,
        uint128 amount0,
        uint128 amount1
    );

    /**
     * @notice Emitted when a position's liquidity is removed
     * @dev Does not withdraw any fees earned by the liquidity position, which must be withdrawn via #collect
     * @param owner The owner of the position for which liquidity is removed
     * @param bottomTick The lower tick of the position
     * @param topTick The upper tick of the position
     * @param amount The amount of liquidity to remove
     * @param amount0 The amount of token0 withdrawn
     * @param amount1 The amount of token1 withdrawn
     */
    event Burn(
        address indexed owner,
        int24 indexed bottomTick,
        int24 indexed topTick,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /**
     * @notice Emitted by the pool for any swaps between token0 and token1
     * @param sender The address that initiated the swap call, and that received the callback
     * @param recipient The address that received the output of the swap
     * @param amount0 The delta of the token0 balance of the pool
     * @param amount1 The delta of the token1 balance of the pool
     * @param price The sqrt(price) of the pool after the swap, as a Q64.96
     * @param liquidity The liquidity of the pool after the swap
     * @param tick The log base 1.0001 of price of the pool after the swap
     */
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 price,
        uint128 liquidity,
        int24 tick
    );

    /**
     * @notice Emitted by the pool for any flashes of token0/token1
     * @param sender The address that initiated the swap call, and that received the callback
     * @param recipient The address that received the tokens from flash
     * @param amount0 The amount of token0 that was flashed
     * @param amount1 The amount of token1 that was flashed
     * @param paid0 The amount of token0 paid for the flash, which can exceed the amount0 plus the fee
     * @param paid1 The amount of token1 paid for the flash, which can exceed the amount1 plus the fee
     */
    event Flash(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1,
        uint256 paid0,
        uint256 paid1
    );

    /**
     * @notice Emitted when the community fee is changed by the pool
     * @param communityFee0Old The previous value of the token0 community fee
     * @param communityFee1Old The previous value of the token1 community fee
     * @param communityFee0New The updated value of the token0 community fee
     * @param communityFee1New The updated value of the token1 community fee
     */
    event SetCommunityFee(
        uint8 communityFee0Old,
        uint8 communityFee1Old,
        uint8 communityFee0New,
        uint8 communityFee1New
    );

    /**
     * @notice Emitted when the collected community fees are withdrawn by the factory owner
     * @param sender The address that collects the community fees
     * @param recipient The address that receives the collected community fees
     * @param amount0 The amount of token0 community fees that is withdrawn
     * @param amount0 The amount of token1 community fees that is withdrawn
     */
    event CollectCommunityFee(address indexed sender, address indexed recipient, uint128 amount0, uint128 amount1);

    /**
     * @notice Emitted when new activeIncentive is set
     * @param virtualPoolAddress The address of a virtual pool associated with the current active incentive
     * @param endTimestamp The timestamp when the active incentive is finished
     * @param startTimestamp The first swap after this timestamp is going to initialize the virtual pool
     */
    event IncentiveSet(address virtualPoolAddress, uint32 endTimestamp, uint32 startTimestamp);
    /**
     * @notice Emitted when the fee changes
     * @param Fee The value of the token fee
     */
    event ChangeFee(uint16 Fee);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.7.0;

interface IDataStorageOperator {
    /**
     * @notice Returns data belonging to a certain timepoint
     * @param index The index of timepoint in the array
     * @dev There is more convenient function to fetch a timepoint: observe(). Which requires not an index but seconds
     * @return initialized whether the timepoint has been initialized and the values are safe to use
     * blockTimestamp The timestamp of the observation,
     * tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the timepoint timestamp,
     * secondsPerLiquidityCumulative the seconds per in range liquidity for the life of the pool as of the timepoint timestamp,
     * volatilityCumulative Cumulative standard deviation for the life of the pool as of the timepoint timestamp
     * volumePerAvgLiquidity Cumulative swap volume per liquidity for the life of the pool as of the timepoint timestamp
     */
    function timepoints(uint256 index)
        external
        view
        returns (
            bool initialized,
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulative,
            uint112 volatilityCumulative,
            uint144 volumePerLiquidityCumulative
        );

    function initialize(uint32 time) external;

    function getSingleTimepoint(
        uint32 time,
        uint32 secondsAgo,
        int24 tick,
        uint16 index,
        uint128 liquidity
    )
        external
        view
        returns (
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulative,
            uint112 volatilityCumulative,
            uint256 volumePerAvgLiquidity
        );

    function getTimepoints(
        uint32 time,
        uint32[] memory secondsAgos,
        int24 tick,
        uint16 index,
        uint128 liquidity
    )
        external
        view
        returns (
            int56[] memory tickCumulatives,
            uint160[] memory secondsPerLiquidityCumulatives,
            uint112[] memory volatilityCumulatives,
            uint256[] memory volumePerAvgLiquiditys
        );

    function getAverages(
        uint32 time,
        int24 tick,
        uint16 index,
        uint128 liquidity
    ) external view returns (uint112 TWVolatilityAverage, uint256 TWVolumePerLiqAverage);

    function write(
        uint16 index,
        uint32 blockTimestamp,
        int24 tick,
        uint128 liquidity,
        uint128 volumePerLiquidity
    ) external returns (uint16 indexUpdated);

    function calculateVolumePerLiquidity(
        uint128 liquidity,
        int256 amount0,
        int256 amount1
    ) external pure returns (uint128 volumePerLiquidity);

    function timeAgo() external view returns (uint32);

    function getFee(
        uint32 _time,
        int24 _tick,
        uint16 _index,
        uint128 _liquidity
    ) external view returns (uint16 fee);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

/// @title Creates and initializes V3 Pools
/// @notice Provides a method for creating and initializing a pool, if necessary, for bundling with other methods that
/// require the pool to exist.
interface IPoolInitializer {
    /// @notice Creates a new pool if it does not exist, then initializes if not initialized
    /// @dev This method can be bundled with others via IMulticall for the first action (e.g. mint) performed against a pool
    /// @param token0 The contract address of token0 of the pool
    /// @param token1 The contract address of token1 of the pool
    /// @param sqrtPriceX96 The initial square root price of the pool as a Q64.96 value
    /// @return pool Returns the pool address based on the pair of tokens and fee, will return the newly created pool address if necessary
    function createAndInitializePoolIfNecessary(
        address token0,
        address token1,
        uint160 sqrtPriceX96
    ) external payable returns (address pool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

/// @title ERC721 with permit
/// @notice Extension to ERC721 that includes a permit function for signature based approvals
interface IERC721Permit is IERC721 {
    /// @notice The permit typehash used in the permit signature
    /// @return The typehash for the permit
    function PERMIT_TYPEHASH() external pure returns (bytes32);

    /// @notice The domain separator used in the permit signature
    /// @return The domain seperator used in encoding of permit signature
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    /// @notice Approve of a specific token ID for spending by spender via signature
    /// @param spender The account that is being approved
    /// @param tokenId The ID of the token that is being approved for spending
    /// @param deadline The deadline timestamp by which the call must be mined for the approve to work
    /// @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function permit(
        address spender,
        uint256 tokenId,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;

/// @title Periphery Payments
/// @notice Functions to ease deposits and withdrawals of NativeToken
interface IPeripheryPayments {
    /// @notice Unwraps the contract's WNativeToken balance and sends it to recipient as NativeToken.
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing WNativeToken from users.
    /// @param amountMinimum The minimum amount of WNativeToken to unwrap
    /// @param recipient The address receiving NativeToken
    function unwrapWNativeToken(uint256 amountMinimum, address recipient) external payable;

    /// @notice Refunds any NativeToken balance held by this contract to the `msg.sender`
    /// @dev Useful for bundling with mint or increase liquidity that uses ether, or exact output swaps
    /// that use ether for the input amount
    function refundNativeToken() external payable;

    /// @notice Transfers the full amount of a token held by this contract to recipient
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing the token from users
    /// @param token The contract address of the token which will be transferred to `recipient`
    /// @param amountMinimum The minimum amount of token required for a transfer
    /// @param recipient The destination address of the token
    function sweepToken(
        address token,
        uint256 amountMinimum,
        address recipient
    ) external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Immutable state
/// @notice Functions that return immutable state of the router
interface IPeripheryImmutableState {
    /// @return Returns the address of the Algebra factory
    function factory() external view returns (address);

    /// @return Returns the address of the pool Deployer
    function poolDeployer() external view returns (address);

    /// @return Returns the address of WNativeToken
    function WNativeToken() external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Provides functions for deriving a pool address from the factory, tokens, and the fee
library PoolAddress {
    bytes32 internal constant POOL_INIT_CODE_HASH = 0x7f46fa63e80af4b4245cb4819c3af72a0417f14239c1af2596c4515297e80e40;

    /// @notice The identifying key of the pool
    struct PoolKey {
        address token0;
        address token1;
    }

    /// @notice Returns PoolKey: the ordered tokens with the matched fee levels
    /// @param tokenA The first token of a pool, unsorted
    /// @param tokenB The second token of a pool, unsorted
    /// @return Poolkey The pool details with ordered token0 and token1 assignments
    function getPoolKey(address tokenA, address tokenB) internal pure returns (PoolKey memory) {
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);
        return PoolKey({token0: tokenA, token1: tokenB});
    }

    /// @notice Deterministically computes the pool address given the factory and PoolKey
    /// @param factory The Algebra factory contract address
    /// @param key The PoolKey
    /// @return pool The contract address of the V3 pool
    function computeAddress(address factory, PoolKey memory key) internal pure returns (address pool) {
        require(key.token0 < key.token1);
        pool = address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        hex'ff',
                        factory,
                        keccak256(abi.encode(key.token0, key.token1)),
                        POOL_INIT_CODE_HASH
                    )
                )
            )
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../../introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0 = a * b; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(a, b, not(0))
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Make sure the result is less than 2**256.
        // Also prevents denominator == 0
        require(denominator > prod1);

        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0]
        // Compute remainder using mulmod
        // Subtract 256 bit remainder from 512 bit number
        assembly {
            let remainder := mulmod(a, b, denominator)
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator
        // Compute largest power of two divisor of denominator.
        // Always >= 1.
        uint256 twos = -denominator & denominator;
        // Divide denominator by power of two
        assembly {
            denominator := div(denominator, twos)
        }

        // Divide [prod1 prod0] by the factors of two
        assembly {
            prod0 := div(prod0, twos)
        }
        // Shift in bits from prod1 into prod0. For this we need
        // to flip `twos` such that it is 2**256 / twos.
        // If twos is zero, then it becomes one
        assembly {
            twos := add(div(sub(0, twos), twos), 1)
        }
        prod0 |= prod1 * twos;

        // Invert denominator mod 2**256
        // Now that denominator is an odd number, it has an inverse
        // modulo 2**256 such that denominator * inv = 1 mod 2**256.
        // Compute the inverse by starting with a seed that is correct
        // correct for four bits. That is, denominator * inv = 1 mod 2**4
        uint256 inv = (3 * denominator) ^ 2;
        // Now use Newton-Raphson iteration to improve the precision.
        // Thanks to Hensel's lifting lemma, this also works in modular
        // arithmetic, doubling the correct bits in each step.
        inv *= 2 - denominator * inv; // inverse mod 2**8
        inv *= 2 - denominator * inv; // inverse mod 2**16
        inv *= 2 - denominator * inv; // inverse mod 2**32
        inv *= 2 - denominator * inv; // inverse mod 2**64
        inv *= 2 - denominator * inv; // inverse mod 2**128
        inv *= 2 - denominator * inv; // inverse mod 2**256

        // Because the division is now exact we can divide by multiplying
        // with the modular inverse of denominator. This will give us the
        // correct result modulo 2**256. Since the precoditions guarantee
        // that the outcome is less than 2**256, this is the final result.
        // We don't need to compute the high bits of the result and prod1
        // is no longer required.
        result = prod0 * inv;
        return result;
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        if (a == 0 || ((result = a * b) / a == b)) {
            require(denominator > 0);
            assembly {
                result := add(div(result, denominator), gt(mod(result, denominator), 0))
            }
            return result;
        }

        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }

    /// @notice Returns ceil(x / y)
    /// @dev division by 0 has unspecified behavior, and must be checked externally
    /// @param x The dividend
    /// @param y The divisor
    /// @return z The quotient, ceil(x / y)
    function divRoundingUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            z := add(div(x, y), gt(mod(x, y), 0))
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/**
 * @title The interface for the Algebra Factory
 */
interface IAlgebraFactory {
    /**
     *  @notice Emitted when the owner of the factory is changed
     *  @param oldOwner The owner before the owner was changed
     *  @param newOwner The owner after the owner was changed
     */
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    /**
     *  @notice Emitted when a pool is created
     *  @param token0 The first token of the pool by address sort order
     *  @param token1 The second token of the pool by address sort order
     *  @param pool The address of the created pool
     */
    event PoolCreated(address indexed token0, address indexed token1, address pool);

    /**
     *  @notice Returns the current owner of the factory
     *  @dev Can be changed by the current owner via setOwner
     *  @return The address of the factory owner
     */
    function owner() external view returns (address);

    /**
     *  @notice Returns the current poolDeployerAddress
     *  @return The address of the poolDeployer
     */
    function poolDeployer() external view returns (address);

    /**
     * @dev Is retrieved from the pools to restrict calling
     * certain functions not by a staker contract
     * @return The staker contract address
     */
    function stakerAddress() external view returns (address);

    /**
     *  @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
     *  @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
     *  @param tokenA The contract address of either token0 or token1
     *  @param tokenB The contract address of the other token
     *  @return pool The pool address
     */
    function poolByPair(address tokenA, address tokenB) external view returns (address pool);

    /**
     *  @notice Creates a pool for the given two tokens and fee
     *  @param tokenA One of the two tokens in the desired pool
     *  @param tokenB The other of the two tokens in the desired pool
     *  @dev tokenA and tokenB may be passed in either order: token0/token1 or token1/token0. tickSpacing is retrieved
     *  from the fee. The call will revert if the pool already exists, the fee is invalid, or the token arguments
     *  are invalid.
     *  @return pool The address of the newly created pool
     */
    function createPool(address tokenA, address tokenB) external returns (address pool);

    /**
     *  @notice Updates the owner of the factory
     *  @dev Must be called by the current owner
     *  @param _owner The new owner of the factory
     */
    function setOwner(address _owner) external;

    /**
     * @dev updates staker address on the factory
     * @param _stakerAddress The new staker contract address
     */
    function setStakerAddress(address _stakerAddress) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import './LowGasSafeMath.sol';
import './SafeCast.sol';

import './LiquidityMath.sol';

/// @title TickManager
/// @notice Contains functions for managing tick processes and relevant calculations
library TickManager {
    using LowGasSafeMath for int256;
    using SafeCast for int256;

    // info stored for each initialized individual tick
    struct Tick {
        // the total position liquidity that references this tick
        uint128 liquidityTotal;
        // amount of net liquidity added (subtracted) when tick is crossed from left to right (right to left),
        int128 liquidityDelta;
        // fee growth per unit of liquidity on the _other_ side of this tick (relative to the current tick)
        // only has relative meaning, not absolute — the value depends on when the tick is initialized
        uint256 outerFeeGrowth0Token;
        uint256 outerFeeGrowth1Token;
        // the cumulative tick value on the other side of the tick
        int56 outerTickCumulative;
        // the seconds per unit of liquidity on the _other_ side of this tick (relative to the current tick)
        // only has relative meaning, not absolute — the value depends on when the tick is initialized
        uint160 outerSecondsPerLiquidity;
        // the seconds spent on the other side of the tick (relative to the current tick)
        // only has relative meaning, not absolute — the value depends on when the tick is initialized
        uint32 outerSecondsSpent;
        // true iff the tick is initialized, i.e. the value is exactly equivalent to the expression liquidityTotal != 0
        // these 8 bits are set to prevent fresh sstores when crossing newly initialized ticks
        bool initialized;
    }

    /// @notice Retrieves fee growth data
    /// @param self The mapping containing all tick information for initialized ticks
    /// @param bottomTick The lower tick boundary of the position
    /// @param topTick The upper tick boundary of the position
    /// @param currentTick The current tick
    /// @param totalFeeGrowth0Token The all-time global fee growth, per unit of liquidity, in token0
    /// @param totalFeeGrowth1Token The all-time global fee growth, per unit of liquidity, in token1
    /// @return innerFeeGrowth0Token The all-time fee growth in token0, per unit of liquidity, inside the position's tick boundaries
    /// @return innerFeeGrowth1Token The all-time fee growth in token1, per unit of liquidity, inside the position's tick boundaries
    function getInnerFeeGrowth(
        mapping(int24 => Tick) storage self,
        int24 bottomTick,
        int24 topTick,
        int24 currentTick,
        uint256 totalFeeGrowth0Token,
        uint256 totalFeeGrowth1Token
    ) internal view returns (uint256 innerFeeGrowth0Token, uint256 innerFeeGrowth1Token) {
        Tick storage lower = self[bottomTick];
        Tick storage upper = self[topTick];

        if (currentTick < topTick) {
            if (currentTick >= bottomTick) {
                innerFeeGrowth0Token = totalFeeGrowth0Token - upper.outerFeeGrowth0Token - lower.outerFeeGrowth0Token;
                innerFeeGrowth1Token = totalFeeGrowth1Token - upper.outerFeeGrowth1Token - lower.outerFeeGrowth1Token;
            } else {
                innerFeeGrowth0Token = lower.outerFeeGrowth0Token - upper.outerFeeGrowth0Token;
                innerFeeGrowth1Token = lower.outerFeeGrowth1Token - upper.outerFeeGrowth1Token;
            }
        } else {
            innerFeeGrowth0Token = upper.outerFeeGrowth0Token - lower.outerFeeGrowth0Token;
            innerFeeGrowth1Token = upper.outerFeeGrowth1Token - lower.outerFeeGrowth1Token;
        }
    }

    /// @notice Updates a tick and returns true if the tick was flipped from initialized to uninitialized, or vice versa
    /// @param self The mapping containing all tick information for initialized ticks
    /// @param tick The tick that will be updated
    /// @param currentTick The current tick
    /// @param liquidityDelta A new amount of liquidity to be added (subtracted) when tick is crossed from left to right (right to left)
    /// @param totalFeeGrowth0Token The all-time global fee growth, per unit of liquidity, in token0
    /// @param totalFeeGrowth1Token The all-time global fee growth, per unit of liquidity, in token1
    /// @param secondsPerLiquidityCumulative The all-time seconds per max(1, liquidity) of the pool
    /// @param time The current block timestamp cast to a uint32
    /// @param upper true for updating a position's upper tick, or false for updating a position's lower tick
    /// @return flipped Whether the tick was flipped from initialized to uninitialized, or vice versa
    function update(
        mapping(int24 => Tick) storage self,
        int24 tick,
        int24 currentTick,
        int128 liquidityDelta,
        uint256 totalFeeGrowth0Token,
        uint256 totalFeeGrowth1Token,
        uint160 secondsPerLiquidityCumulative,
        int56 tickCumulative,
        uint32 time,
        bool upper
    ) internal returns (bool flipped) {
        Tick storage data = self[tick];

        uint128 liquidityTotalBefore = data.liquidityTotal;
        uint128 liquidityTotalAfter = LiquidityMath.addDelta(liquidityTotalBefore, liquidityDelta);

        require(liquidityTotalAfter <= 11505743598341114571880798222544994, 'LO');

        flipped = (liquidityTotalAfter == 0) != (liquidityTotalBefore == 0);

        if (liquidityTotalBefore == 0) {
            // by convention, we assume that all growth before a tick was initialized happened _below_ the tick
            if (tick <= currentTick) {
                data.outerFeeGrowth0Token = totalFeeGrowth0Token;
                data.outerFeeGrowth1Token = totalFeeGrowth1Token;
                data.outerSecondsPerLiquidity = secondsPerLiquidityCumulative;
                data.outerTickCumulative = tickCumulative;
                data.outerSecondsSpent = time;
            }
            data.initialized = true;
        }

        data.liquidityTotal = liquidityTotalAfter;

        // when the lower (upper) tick is crossed left to right (right to left), liquidity must be added (removed)
        data.liquidityDelta = upper
            ? int256(data.liquidityDelta).sub(liquidityDelta).toInt128()
            : int256(data.liquidityDelta).add(liquidityDelta).toInt128();
    }

    /// @notice Clears tick data
    /// @param self The mapping containing all initialized tick information for initialized ticks
    /// @param tick The tick that will be cleared
    function clear(mapping(int24 => Tick) storage self, int24 tick) internal {
        delete self[tick];
    }

    /// @notice Transitions to next tick as needed by price movement
    /// @param self The mapping containing all tick information for initialized ticks
    /// @param tick The destination tick of the transition
    /// @param totalFeeGrowth0Token The all-time global fee growth, per unit of liquidity, in token0
    /// @param totalFeeGrowth1Token The all-time global fee growth, per unit of liquidity, in token1
    /// @param secondsPerLiquidityCumulative The current seconds per liquidity
    /// @param time The current block.timestamp
    /// @return liquidityDelta The amount of liquidity added (subtracted) when tick is crossed from left to right (right to left)
    function cross(
        mapping(int24 => Tick) storage self,
        int24 tick,
        uint256 totalFeeGrowth0Token,
        uint256 totalFeeGrowth1Token,
        uint160 secondsPerLiquidityCumulative,
        int56 tickCumulative,
        uint32 time
    ) internal returns (int128 liquidityDelta) {
        Tick storage data = self[tick];
        data.outerFeeGrowth0Token = totalFeeGrowth0Token - data.outerFeeGrowth0Token;
        data.outerFeeGrowth1Token = totalFeeGrowth1Token - data.outerFeeGrowth1Token;
        data.outerSecondsPerLiquidity = secondsPerLiquidityCumulative - data.outerSecondsPerLiquidity;
        data.outerTickCumulative = tickCumulative - data.outerTickCumulative;
        data.outerSecondsSpent = time - data.outerSecondsSpent;
        liquidityDelta = data.liquidityDelta;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Packed tick initialized state library
/// @notice Stores a packed mapping of tick index to its initialized state
/// @dev The mapping uses int16 for keys since ticks are represented as int24 and there are 256 (2^8) values per word.
library TickTable {
    /// @notice Computes the position in the mapping where the initialized bit for a tick lives
    /// @param tick The tick for which to compute the position
    /// @return rowNumber The key in the mapping containing the word in which the bit is stored
    /// @return bitNumber The bit position in the word where the flag is stored
    function position(int24 tick) private pure returns (int16 rowNumber, uint8 bitNumber) {
        assembly {
            bitNumber := smod(tick, 256)
            rowNumber := shr(8, tick)
        }
    }

    /// @notice Flips the initialized state for a given tick from false to true, or vice versa
    /// @param self The mapping in which to flip the tick
    /// @param tick The tick to flip
    function toggleTick(mapping(int16 => uint256) storage self, int24 tick) internal {
        require(tick % 60 == 0, 'tick is not spaced'); // ensure that the tick is spaced
        (int16 rowNumber, uint8 bitNumber) = position(tick / 60);
        self[rowNumber] ^= 1 << bitNumber;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Math library for liquidity
library LiquidityMath {
    /// @notice Add a signed liquidity delta to liquidity and revert if it overflows or underflows
    /// @param x The liquidity before change
    /// @param y The delta by which liquidity should be changed
    /// @return z The liquidity delta
    function addDelta(uint128 x, int128 y) internal pure returns (uint128 z) {
        if (y < 0) {
            require((z = x - uint128(-y)) < x, 'LS');
        } else {
            require((z = x + uint128(y)) >= x, 'LA');
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;
pragma abicoder v2;

interface IAlgebraVirtualPool {
    // returns the timestamp of the first swap after start timestamp
    function initTimestamp() external returns (uint32);

    // returns the timestamp when the incentive was actually finished
    function endTimestamp() external returns (uint32);

    // returns how much time the price was out of any staked liquidity
    function timeOutside() external returns (uint32);

    // returns total seconds per staked liquidity from the moment of initialization of the virtual pool
    function globalSecondsPerLiquidityCumulative() external returns (uint160);

    // returns the current liquidity in virtual pool
    function currentLiquidity() external returns (uint128);

    // returns the current tick in virtual pool
    function globalTick() external returns (int24);

    // returns the liquidity after previous swap (like the last timepoint in a default pool)
    function prevLiquidity() external returns (uint128);

    // returns the timestamp after previous swap (like the last timepoint in a default pool)
    function _prevTimestamp() external returns (uint32);

    // returns data associated with a tick
    function ticks(int24 tickId)
        external
        returns (
            uint128 liquidityTotal,
            int128 liquidityDelta,
            uint256 outerFeeGrowth0Token,
            uint256 outerFeeGrowth1Token,
            int56 outerTickCumulative,
            uint160 outerSecondsPerLiquidity,
            uint32 outerSecondsSpent,
            bool initialized
        );

    /**
     * @dev This function is called when anyone stakes their liquidity. The position in a virtual pool
     * should be changed accordingly
     * @param bottomTick The bottom tick of a position
     * @param topTick The top tick of a position
     * @param liquidityDelta The amount of liquidity in a position
     * @param tick The current tick in the main pool
     */
    function applyLiquidityDeltaToPosition(
        int24 bottomTick,
        int24 topTick,
        int128 liquidityDelta,
        int24 tick
    ) external;

    /**
     * @dev This function is called by the main pool when an initialized tick is crossed there.
     * If the tick is also initialized in a virtual pool it should ne crossed too
     * @param nextTick The crossed tick
     * @param zeroForOne The direction
     */
    function cross(int24 nextTick, bool zeroForOne) external;

    /**
     * @dev This function is called by a staker when someone calls #unstake() after the end timestamp
     * @param _endTimestamp The timestamp of the unstake
     * @param startTime The timestamp of planned start of the incentive. Used as initTimestamp
     * if there were no swaps through the entire incentive
     */
    function finish(uint32 _endTimestamp, uint32 startTime) external;

    /**
     * @dev This function is used to calculate the seconds per liquidity inside a certain position
     * @param bottomTick The bottom tick of a position
     * @param topTick The top tick of a position
     * @return innerSecondsSpentPerLiquidity The seconds per liquidity inside the position
     * Returns initTime the #initTimestamp
     * Returns endTime the #endTimestamp
     */
    function getInnerSecondsPerLiquidity(int24 bottomTick, int24 topTick)
        external
        view
        returns (
            uint160 innerSecondsSpentPerLiquidity,
            uint32 initTime,
            uint32 endTime
        );

    // This function updates the #prevLiquidity
    function processSwap() external;

    /**
     * @dev This function is called from the main pool before every swap To increase seconds per liquidity
     * cumulative considering previous timestamp and liquidity. The liquidity is stored in a virtual pool
     * @param previousTimestamp The timestamp of the previous swap
     * @param currentTimestamp The timestamp of the current swap
     */
    function increaseCumulative(uint32 previousTimestamp, uint32 currentTimestamp) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.0;

/// @title Optimized overflow and underflow safe math operations
/// @notice Contains methods for doing math operations that revert on overflow or underflow for minimal gas cost
library LowGasSafeMath {
    /// @notice Returns x + y, reverts if sum overflows uint256
    /// @param x The augend
    /// @param y The addend
    /// @return z The sum of x and y
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x);
    }

    /// @notice Returns x - y, reverts if underflows
    /// @param x The minuend
    /// @param y The subtrahend
    /// @return z The difference of x and y
    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x);
    }

    /// @notice Returns x * y, reverts if overflows
    /// @param x The multiplicand
    /// @param y The multiplier
    /// @return z The product of x and y
    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(x == 0 || (z = x * y) / x == y);
    }

    /// @notice Returns x + y, reverts if overflows or underflows
    /// @param x The augend
    /// @param y The addend
    /// @return z The sum of x and y
    function add(int256 x, int256 y) internal pure returns (int256 z) {
        require((z = x + y) >= x == (y >= 0));
    }

    /// @notice Returns x - y, reverts if overflows or underflows
    /// @param x The minuend
    /// @param y The subtrahend
    /// @return z The difference of x and y
    function sub(int256 x, int256 y) internal pure returns (int256 z) {
        require((z = x - y) <= x == (y >= 0));
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Safe casting methods
/// @notice Contains methods for safely casting between types
library SafeCast {
    /// @notice Cast a int256 to a int128, revert on overflow or underflow
    /// @param y The int256 to be downcasted
    /// @return z The downcasted integer, now type int128
    function toInt128(int256 y) internal pure returns (int128 z) {
        require((z = int128(y)) == y);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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