pragma solidity ^0.7.0;
pragma abicoder v2;

// SPDX-License-Identifier: MIT OR Apache-2.0





import "../zksync/IERC20.sol";
import "../zksync/SafeMath.sol";
import "../zksync/SafeMathUInt128.sol";
import "../zksync/Utils.sol";
import "../zksync/Ownable.sol";
import "../zksync/Config.sol";
import "../strategy/IStrategy.sol";
import "../nft/IZkLinkNFT.sol";
import "../IZkLink.sol";
import "./EnumerableSet.sol";

/// @title Stake pool contract, stake ZkLinkNft and get rewards
/// @author zk.link
contract StakePool is Ownable, Config {
    using SafeMath for uint256;
    using SafeMathUInt128 for uint128;
    using EnumerableSet for EnumerableSet.UintSet;

    /// @dev UINT256.max = 1.15 * 1e77, if reward amount is bigger than 1e65 and power is 1 overflow will happen when update accPerShare
    uint256 constant public MUL_FACTOR = 1e12;

    /// @notice Info of each user
    struct UserInfo {
        uint128 power; // How many final nft mine power the user has provided
        mapping(address => uint256) rewardDebt; // Final nft reward debt of each reward token(include zkl)
        mapping(uint32 => mapping(address => uint256)) pendingRewardDebt; // Pending nft reward debt of each reward token(include zkl)
        mapping(address => uint256) rewardedAmount; // Rewarded amount of each reward token(include zkl)
    }

    /// @notice Info of each pool
    struct PoolInfo {
        IStrategy strategy; // Strategy which put reward tokens to pool
        uint256 bonusStartBlock; // Block number when ZKL mining starts
        uint256 bonusEndBlock; // Block number when bonus ZKL period ends
        uint256 zklPerBlock; // ZKL tokens reward to user per block
        uint128 power; // All final and pending nft mine power
        uint256 lastRewardBlock; // Last block number that ZKLs and strategy reward tokens distribution occurs
        mapping(address => uint256) accPerShare; // Accumulated ZKLs and strategy reward tokens per share, times MUL_FACTOR
        uint256 discardRewardReleaseBlocks; // Discard reward of pending nft must be released slowly to prevent wasting reward hack
        uint256 discardRewardStartBlock; // Discard reward release start block
        uint256 discardRewardEndBlock; // Discard reward release end block
        mapping(address => uint256) discardRewardPerBlock; // Accumulated ZKLs and strategy reward tokens that pending nft power discard
        bool active; // Governor can set active to false to prevent user staking
    }

    /// @notice ZKL NFT staked to pool
    IZkLinkNFT public nft;
    /// @notice Zkl token
    IERC20 public zkl;
    /// @notice zkLink contract
    IZkLink public zkLink;
    /// @notice Nft depositor info, nft token id => address
    mapping(uint32 => address) public nftDepositor;
    /// @notice Info of each user that stakes tokens, zkl token id => user address => user info
    mapping(uint16 => mapping(address => UserInfo)) public userInfo;
    // Pending nft set of each user that stakes tokens, zkl token id => user address => final nft set
    mapping(uint16 => mapping(address => EnumerableSet.UintSet)) private userFinalNftSet;
    // Pending nft set of each user that stakes tokens, zkl token id => user address => pending nft set
    mapping(uint16 => mapping(address => EnumerableSet.UintSet)) private userPendingNftSet;
    /// @notice Info of each pool, zkl token id => pool info
    mapping(uint16 => PoolInfo) public poolInfo;
    // All pool ids
    EnumerableSet.UintSet private poolIdSet;

    event Stake(address indexed user, uint32 indexed nftTokenId);
    event UnStake(address indexed user, uint32 indexed nftTokenId);
    event EmergencyUnStake(address indexed user, uint32 indexed nftTokenId);
    event Harvest(uint16 indexed zklTokenId);
    event RevokePendingNft(uint32 indexed nftTokendId);

    constructor(address _nft, address _zkl, address _zkLink, address _masterAddress) Ownable(_masterAddress) {
        nft = IZkLinkNFT(_nft);
        zkl = IERC20(_zkl);
        zkLink = IZkLink(_zkLink);
    }

    /// @notice Get all pool ids
    function poolIds() external view returns (uint16[] memory) {
        uint16[] memory pids = new uint16[](poolIdSet.length());
        for(uint256 i = 0; i < pids.length; i++) {
            pids[i] = uint16(poolIdSet.at(i));
        }
        return pids;
    }

    function poolRewardAccPerShare(uint16 zklTokenId, address rewardToken) external view returns (uint256) {
        return poolInfo[zklTokenId].accPerShare[rewardToken];
    }

    function poolRewardDiscardPerBlock(uint16 zklTokenId, address rewardToken) external view returns (uint256) {
        return poolInfo[zklTokenId].discardRewardPerBlock[rewardToken];
    }

    function userPower(uint16 zklTokenId, address user) external view returns (uint256) {
        return userInfo[zklTokenId][user].power;
    }

    function userRewardDebt(uint16 zklTokenId, address user, address rewardToken) external view returns (uint256) {
        return userInfo[zklTokenId][user].rewardDebt[rewardToken];
    }

    function isUserFinalNft(uint16 zklTokenId, address user, uint32 nftTokenId) public view returns (bool) {
        return userFinalNftSet[zklTokenId][user].contains(nftTokenId);
    }

    function isUserPendingNft(uint16 zklTokenId, address user, uint32 nftTokenId) public view returns (bool) {
        return userPendingNftSet[zklTokenId][user].contains(nftTokenId);
    }

    function isUserNft(uint16 zklTokenId, address user, uint32 nftTokenId) external view returns (bool) {
        return isUserFinalNft(zklTokenId, user, nftTokenId) || isUserPendingNft(zklTokenId, user, nftTokenId);
    }

    /// @notice Get user all staked nft tokens
    /// @param zklTokenId token id managed by Governance of ZkLink
    /// @param user address of user
    function userNfts(uint16 zklTokenId, address user) public view returns (uint32[] memory) {
        EnumerableSet.UintSet storage finalNftSet = userFinalNftSet[zklTokenId][user];
        EnumerableSet.UintSet storage pendingNftSet = userPendingNftSet[zklTokenId][user];
        uint256 finalNum = finalNftSet.length();
        uint256 pendingNum = pendingNftSet.length();
        uint32[] memory nftTokenIds = new uint32[](finalNum+pendingNum);
        for(uint256 i = 0; i < finalNum; i++) {
            nftTokenIds[i] = uint32(finalNftSet.at(i));
        }
        for(uint256 i = 0; i < pendingNum; i++) {
            nftTokenIds[i+finalNum] = uint32(pendingNftSet.at(i));
        }
        return nftTokenIds;
    }

    /// @notice Get user all staked token amount
    /// @param zklTokenId token id managed by Governance of ZkLink
    /// @param user address of user
    function userStakedAmount(uint16 zklTokenId, address user) external view returns (uint256) {
        uint256 amount = 0;
        uint32[] memory nfts = userNfts(zklTokenId, user);
        for(uint256 i = 0; i < nfts.length; i++) {
            uint32 nftId = nfts[i];
            amount = amount.add(nft.tokenLq(nftId).amount);
        }
        return amount;
    }

    function userPendingRewardDebt(uint16 zklTokenId, address user, uint32 nftTokenId, address rewardToken) external view returns (uint256) {
        return userInfo[zklTokenId][user].pendingRewardDebt[nftTokenId][rewardToken];
    }

    /// @notice Get user all rewarded token and amount
    /// @param zklTokenId token id managed by Governance of ZkLink
    /// @param userAddr address of user
    function userRewarded(uint16 zklTokenId, address userAddr) external view returns (address[] memory, uint256[] memory) {
        PoolInfo storage pool = poolInfo[zklTokenId];
        UserInfo storage user = userInfo[zklTokenId][userAddr];
        address[] memory allTokens;
        if (address(pool.strategy) != address(0)) {
            address[] memory strategyRewardTokens = pool.strategy.rewardTokens();
            allTokens = new address[](1+strategyRewardTokens.length);
            allTokens[0] = address(zkl);
            for(uint256 i = 0; i < strategyRewardTokens.length; i++) {
                allTokens[1+i] = strategyRewardTokens[i];
            }
        } else {
            allTokens = new address[](1);
            allTokens[0] = address(zkl);
        }
        uint256[] memory allAmounts = new uint256[](allTokens.length);
        for(uint256 i = 0; i < allAmounts.length; i++) {
            allAmounts[i] = user.rewardedAmount[allTokens[i]];
        }
        return (allTokens, allAmounts);
    }

    /// @notice Add a stake pool
    /// @dev can only be called by master
    /// @param zklTokenId token id managed by Governance of ZkLink
    /// @param strategy stake token to other defi project to earn reward
    /// @param bonusStartBlock zkl token reward to user start block
    /// @param bonusEndBlock zkl token reward to user end block
    /// @param zklPerBlock zkl token reward to user per block
    /// @param discardRewardReleaseBlocks the number of blocks discarded pending nft rewards distribute to user
    function addPool(uint16 zklTokenId,
        IStrategy strategy,
        uint256 bonusStartBlock,
        uint256 bonusEndBlock,
        uint256 zklPerBlock,
        uint256 discardRewardReleaseBlocks) external {
        requireMaster(msg.sender);
        require(!poolInfo[zklTokenId].active, 'StakePool: pool existed');
        require(_blockNumber() < bonusStartBlock && bonusEndBlock > bonusStartBlock, 'StakePool: invalid bonus time interval');
        require(discardRewardReleaseBlocks > 0, 'StakePool: invalid discard reward release blocks');
        _checkStrategy(strategy);

        PoolInfo storage p = poolInfo[zklTokenId];
        p.strategy = strategy;
        p.bonusStartBlock = bonusStartBlock;
        p.bonusEndBlock = bonusEndBlock;
        p.zklPerBlock = zklPerBlock;
        p.discardRewardReleaseBlocks = discardRewardReleaseBlocks;
        p.active = true;

        poolIdSet.add(zklTokenId);
    }

    /// @notice Set pool active to false to prevent stake
    /// @dev can only be called by master
    /// @param zklTokenId token id managed by Governance of ZkLink
    function freezePool(uint16 zklTokenId) external {
        requireMaster(msg.sender);
        require(poolInfo[zklTokenId].active, 'StakePool: pool not existed');
        poolInfo[zklTokenId].active = false;
    }

    /// @notice Update stake pool zkl reward schedule after last schedule finish
    /// @dev can only be called by master
    /// @param zklTokenId token id managed by Governance of ZkLink
    /// @param bonusStartBlock zkl token reward to user start block
    /// @param bonusEndBlock zkl token reward to user end block
    /// @param zklPerBlock zkl token reward to user per block
    function updatePoolReward(uint16 zklTokenId,
        uint256 bonusStartBlock,
        uint256 bonusEndBlock,
        uint256 zklPerBlock) external {
        requireMaster(msg.sender);
        require(poolInfo[zklTokenId].active, 'StakePool: pool not existed');
        // only last zkl reward schedule finish and then new schedule can start
        uint256 blockNumber = _blockNumber();
        require(poolInfo[zklTokenId].bonusEndBlock < blockNumber
            && blockNumber < bonusStartBlock
            && bonusEndBlock > bonusStartBlock, 'StakePool: invalid bonus time interval');

        updatePool(zklTokenId);

        PoolInfo storage p = poolInfo[zklTokenId];
        p.bonusStartBlock = bonusStartBlock;
        p.bonusEndBlock = bonusEndBlock;
        p.zklPerBlock = zklPerBlock;
    }

    /// @notice Update stake pool strategy，strategy can be set zero address which means only zkl reward user will receive when harvest
    /// @dev can only be called by master
    /// @param zklTokenId token id managed by Governance of ZkLink
    /// @param strategy stake token to other defi project to earn reward
    function updatePoolStrategy(uint16 zklTokenId, IStrategy strategy) external {
        requireMaster(msg.sender);
        require(poolInfo[zklTokenId].active, 'StakePool: pool not existed');
        _checkStrategy(strategy);

        poolInfo[zklTokenId].strategy = strategy;
    }

    /// @notice Update stake pool discardRewardReleaseBlocks
    /// @dev can only be called by master
    /// @param zklTokenId token id managed by Governance of ZkLink
    /// @param discardRewardReleaseBlocks the number of blocks discarded pending nft rewards distribute to user
    function updatePoolDiscardRewardReleaseBlocks(uint16 zklTokenId, uint256 discardRewardReleaseBlocks) external {
        requireMaster(msg.sender);
        require(poolInfo[zklTokenId].active, 'StakePool: pool not existed');
        require(discardRewardReleaseBlocks > 0, 'StakePool: invalid discard reward release blocks');

        poolInfo[zklTokenId].discardRewardReleaseBlocks = discardRewardReleaseBlocks;
    }

    /// @notice Pick pool left reward token after all user exit
    /// @dev can only be called by master
    /// @param zklTokenId token id managed by Governance of ZkLink
    /// @param rewardToken reward token address
    /// @param to reward token receiver
    /// @param amount reward token pick amount
    function pickPool(uint16 zklTokenId, IERC20 rewardToken, address to, uint256 amount) external {
        requireMaster(msg.sender);
        require(_blockNumber() > poolInfo[zklTokenId].bonusEndBlock, 'StakePool: pool reward not end');
        require(poolInfo[zklTokenId].power == 0, 'StakePool: user exist in pool');

        _safeRewardTransfer(rewardToken, to, amount);
    }

    /// @notice Stake ZKLinkNFT to pool for reward allocation
    /// @param nftTokenId token id of ZKLinkNFT
    function stake(uint32 nftTokenId) public {
        IZkLinkNFT.Lq memory lq = nft.tokenLq(nftTokenId);
        // only ADD_PENDING and FINAL nft can be staked
        require(lq.status == IZkLinkNFT.LqStatus.ADD_PENDING ||
            lq.status == IZkLinkNFT.LqStatus.FINAL, 'StakePool: invalid nft status');
        nft.transferFrom(msg.sender, address(this), nftTokenId);
        nftDepositor[nftTokenId] = msg.sender;

        uint16 zklTokenId = lq.tokenId;
        PoolInfo storage pool = poolInfo[zklTokenId];
        require(pool.active, 'StakePool: pool not existed');
        UserInfo storage user = userInfo[zklTokenId][msg.sender];
        EnumerableSet.UintSet storage finalNftSet = userFinalNftSet[zklTokenId][msg.sender];
        EnumerableSet.UintSet storage pendingNftSet = userPendingNftSet[zklTokenId][msg.sender];
        updatePool(zklTokenId);

        if (user.power > 0) {
            _transferRewards(pool, user);
        }

        // add nft power to pool total power whether nft status is final or not
        pool.power = pool.power.add(lq.amount);
        if (lq.status == IZkLinkNFT.LqStatus.FINAL) {
            // add nft power to user power only if nft status is final
            user.power = user.power.add(lq.amount);
            finalNftSet.add(nftTokenId);
        } else {
            // record pending nft reward debt
            pendingNftSet.add(nftTokenId);
            _updatePendingAccShareDebts(pool, user, nftTokenId, lq.amount);
        }
        _updateRewardDebts(pool, user);

        emit Stake(msg.sender, nftTokenId);
    }

    /// @notice Add liquidity to zkLink and then stake ZKLinkNFT to pool for reward allocation
    /// @param token Token added
    /// @param amount Amount of token
    /// @param pair L2 cross chain pair address
    /// @param minLpAmount L2 lp token amount min received
    function addLiquidityAndStake(IERC20 token, uint104 amount, address pair, uint104 minLpAmount) external {
        // token transfer to pool firstly and then transfer from pool to zkLink
        token.transferFrom(msg.sender, address(this), amount);
        token.approve(address(zkLink), amount);
        uint32 nftTokenId = zkLink.addLiquidity(msg.sender, token, amount, pair, minLpAmount);
        // user should have approved all nft to pool
        stake(nftTokenId);
    }

    /// @notice UnStake ZklNft tokens from pool
    /// @param nftTokenId token id of ZKLinkNFT
    function unStake(uint32 nftTokenId) public {
        require(nftDepositor[nftTokenId] == msg.sender, 'StakePool: not depositor');

        // nft token status may be ADD_PENDING, FINAL or ADD_FAIL
        IZkLinkNFT.Lq memory lq = nft.tokenLq(nftTokenId);
        uint16 zklTokenId = lq.tokenId;
        PoolInfo storage pool = poolInfo[zklTokenId];
        UserInfo storage user = userInfo[zklTokenId][msg.sender];
        EnumerableSet.UintSet storage finalNftSet = userFinalNftSet[zklTokenId][msg.sender];
        EnumerableSet.UintSet storage pendingNftSet = userPendingNftSet[zklTokenId][msg.sender];
        updatePool(zklTokenId);

        if (user.power > 0) {
            _transferRewards(pool, user);
        }
        // remove nft power from pool total power whether nft status is final or not
        pool.power = pool.power.sub(lq.amount);
        if (pendingNftSet.contains(nftTokenId)) {
            if (lq.status == IZkLinkNFT.LqStatus.FINAL) {
                // transfer pending reward to user
                _transferPendingRewards(pool, user, nftTokenId, lq.amount);
            } else {
                // discard this pending nft acc reward and release slowly to final nft depositors
                _updateDiscardReward(pool, user, nftTokenId, lq.amount);
            }
            pendingNftSet.remove(nftTokenId);
        } else {
            // remove nft power from user power only if nft status is final when staked
            user.power = user.power.sub(lq.amount);
            finalNftSet.remove(nftTokenId);
        }
        _updateRewardDebts(pool, user);
        _transferNftToDepositor(nftTokenId, msg.sender);
        emit UnStake(msg.sender, nftTokenId);
    }

    /// @notice UnStake ZklNft tokens from pool and then remove liquidity from zkLink
    /// @param nftTokenId token id of ZKLinkNFT
    /// @param minAmount Token amount min received
    function unStakeAndRemoveLiquidity(uint32 nftTokenId, uint104 minAmount) external {
        unStake(nftTokenId);
        // user should have approved all nft to pool
        nft.transferFrom(msg.sender, address(this), nftTokenId);
        zkLink.removeLiquidity(msg.sender, nftTokenId, minAmount);
    }

    /// @notice Emergency unStake ZklNft tokens from pool without caring about rewards
    /// @param nftTokenId token id of ZKLinkNFT
    function emergencyUnStake(uint32 nftTokenId) external {
        require(nftDepositor[nftTokenId] == msg.sender, 'StakePool: not depositor');

        // only FINAL nft can emergency unStake
        IZkLinkNFT.Lq memory lq = nft.tokenLq(nftTokenId);
        require(lq.status == IZkLinkNFT.LqStatus.FINAL, 'StakePool: only FINAL nft can emergency unStake');

        uint16 zklTokenId = lq.tokenId;
        PoolInfo storage pool = poolInfo[zklTokenId];
        UserInfo storage user = userInfo[zklTokenId][msg.sender];
        EnumerableSet.UintSet storage finalNftSet = userFinalNftSet[zklTokenId][msg.sender];
        EnumerableSet.UintSet storage pendingNftSet = userPendingNftSet[zklTokenId][msg.sender];

        // remove nft power from pool total power whether nft status is final or not
        pool.power = pool.power.sub(lq.amount);
        if (pendingNftSet.contains(nftTokenId)) {
            pendingNftSet.remove(nftTokenId);
        } else {
            // remove nft power from user power only if nft status is final when staked
            user.power = user.power.sub(lq.amount);
            finalNftSet.remove(nftTokenId);
        }
        _transferNftToDepositor(nftTokenId, msg.sender);
        emit EmergencyUnStake(msg.sender, nftTokenId);
    }

    /// @notice Any one can revoke ADD_FAIL nft from pool to avoid wasting of reward
    /// @param nftTokenId token id of ZKLinkNFT
    function revokePendingNft(uint32 nftTokenId) external {
        address depositor = nftDepositor[nftTokenId];
        require(depositor != address(0), 'StakePool: nft not staked');

        // nft token status must be ADD_FAIL
        IZkLinkNFT.Lq memory lq = nft.tokenLq(nftTokenId);
        require(lq.status == IZkLinkNFT.LqStatus.ADD_FAIL, 'StakePool: require nft ADD_FAIL');

        uint16 zklTokenId = lq.tokenId;
        PoolInfo storage pool = poolInfo[zklTokenId];
        UserInfo storage user = userInfo[zklTokenId][depositor];
        EnumerableSet.UintSet storage pendingNftSet = userPendingNftSet[zklTokenId][depositor];
        // no need to update pool
        // remove nft power from pool total power
        pool.power = pool.power.sub(lq.amount);
        // discard this pending nft acc reward and release slowly to final nft depositors
        _updateDiscardReward(pool, user, nftTokenId, lq.amount);
        pendingNftSet.remove(nftTokenId);
        _transferNftToDepositor(nftTokenId, depositor);

        emit RevokePendingNft(nftTokenId);
    }

    /// @notice Get pending reward of user
    /// @param zklTokenId token id managed by Governance of ZkLink
    /// @param rewardToken reward token address
    /// @param account user address
    function pendingReward(uint16 zklTokenId, address rewardToken, address account) public view returns (uint256) {
        PoolInfo storage pool = poolInfo[zklTokenId];
        UserInfo storage user = userInfo[zklTokenId][account];
        EnumerableSet.UintSet storage pendingNftSet = userPendingNftSet[zklTokenId][account];
        uint256 accPerShare = pool.accPerShare[rewardToken];
        // acc per share should update to current block
        if (pool.power > 0) {
            uint256 shareIncrement = _calRewardShareIncrement(pool, rewardToken);
            accPerShare = accPerShare.add(shareIncrement);
        }
        uint256 pending = _calPending(user.power, accPerShare, user.rewardDebt[rewardToken]);

        uint256 pendingNftLength = pendingNftSet.length();
        for(uint256 i = 0; i < pendingNftLength; i++) {
            uint32 nftTokenId = uint32(pendingNftSet.at(i));
            IZkLinkNFT.Lq memory lq = nft.tokenLq(nftTokenId);
            // only final status nft will transfer pending acc reward to user
            if (lq.status == IZkLinkNFT.LqStatus.FINAL) {
                uint256 debt = user.pendingRewardDebt[nftTokenId][rewardToken];
                uint256 nftPending = _calPending(lq.amount, accPerShare, debt);
                pending = pending.add(nftPending);
            }
        }
        return pending;
    }

    /// @notice Get all pending reward of user
    /// @param zklTokenId token id managed by Governance of ZkLink
    /// @param account user address
    function pendingRewards(uint16 zklTokenId, address account) external view returns (address[] memory, uint256[] memory) {
        uint256 rewardTokenLen = 1;
        address[] memory harvestRewardTokens;
        PoolInfo storage pool = poolInfo[zklTokenId];
        if (address(pool.strategy) != address(0)) {
            harvestRewardTokens = pool.strategy.rewardTokens();
            rewardTokenLen += harvestRewardTokens.length;
        }
        address[] memory rewardTokens = new address[](rewardTokenLen);
        uint256[] memory rewardAmounts = new uint256[](rewardTokenLen);
        rewardTokens[0] = address(zkl);
        rewardAmounts[0] = pendingReward(zklTokenId, rewardTokens[0], account);
        for (uint256 i = 1; i < rewardTokenLen; i++) {
            rewardTokens[i] = harvestRewardTokens[i-1];
            rewardAmounts[i] = pendingReward(zklTokenId, rewardTokens[i], account);
        }
        return (rewardTokens, rewardAmounts);
    }

    /// @notice Harvest reward tokens from pool
    /// @param zklTokenId token id managed by Governance of ZkLink
    function harvest(uint16 zklTokenId) external {
        PoolInfo storage pool = poolInfo[zklTokenId];
        require(pool.active, 'StakePool: pool not existed');
        UserInfo storage user = userInfo[zklTokenId][msg.sender];
        EnumerableSet.UintSet storage finalNftSet = userFinalNftSet[zklTokenId][msg.sender];
        EnumerableSet.UintSet storage pendingNftSet = userPendingNftSet[zklTokenId][msg.sender];
        updatePool(zklTokenId);

        if (user.power > 0) {
            _transferRewards(pool, user);
        }

        uint256 pendingNftLength = pendingNftSet.length();
        // NOTE: check from the last item of pendingNftSet to ensure correct removal
        // NOTE: pendingNftLength may be zero so pendingNftLength - 1 will be uint.MAX and
        // when i decrease to zero the next i-- will be uint.MAX
        for(uint256 i = pendingNftLength - 1; i < pendingNftLength; i--) {
            uint32 nftTokenId = uint32(pendingNftSet.at(i));
            IZkLinkNFT.Lq memory lq = nft.tokenLq(nftTokenId);
            if (lq.status == IZkLinkNFT.LqStatus.FINAL) {
                // transfer pending reward to user
                _transferPendingRewards(pool, user, nftTokenId, lq.amount);
                user.power = user.power.add(lq.amount);
                finalNftSet.add(nftTokenId);
                pendingNftSet.remove(nftTokenId);
            }
        }

        _updateRewardDebts(pool, user);
        emit Harvest(zklTokenId);
    }

    /// @notice Update reward variables of the given pool to be up-to-date
    /// @param zklTokenId token id managed by Governance of ZkLink
    function updatePool(uint16 zklTokenId) public {
        PoolInfo storage pool = poolInfo[zklTokenId];
        require(pool.active, 'StakePool: pool not existed');
        uint256 lastRewardBlock = pool.lastRewardBlock;
        uint256 blockNumber = _blockNumber();
        // only allocate once at the same block
        if (blockNumber <= lastRewardBlock) {
            return;
        }
        if (pool.power == 0) {
            pool.lastRewardBlock = blockNumber;
            return;
        }
        // the block in (bonusStartBlock, bonusEndBlock] will be allocated zkl
        uint256 zklRewardBlocks = _calRewardBlocks(blockNumber, pool.bonusStartBlock, pool.bonusEndBlock, pool.lastRewardBlock);
        // the block in (discardRewardStartBlock, discardRewardEndBlock] will be allocated discard reward
        uint256 dsdRewardBlocks = _calRewardBlocks(blockNumber, pool.discardRewardStartBlock, pool.discardRewardEndBlock, pool.lastRewardBlock);
        uint256 zklRewardAmount = zklRewardBlocks.mul(pool.zklPerBlock);
        uint256 zklShare = _calRewardShare(pool, address(zkl), zklRewardAmount, dsdRewardBlocks);
        pool.accPerShare[address(zkl)] = pool.accPerShare[address(zkl)].add(zklShare);

        if (address(pool.strategy) != address(0)) {
            // strategy harvest and reward token will transfer to pool
            uint256[] memory rewardAmounts = pool.strategy.harvest();
            address[] memory rewardTokens = pool.strategy.rewardTokens();
            for(uint256 i = 0; i < rewardTokens.length; i++) {
                address rewardToken = rewardTokens[i];
                uint256 rewardAmount = rewardAmounts[i];
                uint256 rewardShare = _calRewardShare(pool, rewardToken, rewardAmount, dsdRewardBlocks);
                pool.accPerShare[rewardToken] = pool.accPerShare[rewardToken].add(rewardShare);
            }
        }
        // update lastRewardBlock to current block number
        pool.lastRewardBlock = blockNumber;
    }

    function _checkStrategy(IStrategy strategy) internal view {
        if (address(strategy) != address(0)) {
            address[] memory rewardTokens = strategy.rewardTokens();
            for(uint256 i = 0; i < rewardTokens.length; i++) {
                require(rewardTokens[i] != address(zkl), 'StakePool: strategy reward token');
            }
        }
    }

    function _transferRewards(PoolInfo storage pool, UserInfo storage user) internal {
        uint256 pending = _calPending(user.power, pool.accPerShare[address(zkl)], user.rewardDebt[address(zkl)]);
        user.rewardedAmount[address(zkl)] = user.rewardedAmount[address(zkl)].add(pending);
        _safeRewardTransfer(zkl, msg.sender, pending);
        if (address(pool.strategy) != address(0)) {
            address[] memory rewardTokens = pool.strategy.rewardTokens();
            for(uint256 i = 0; i < rewardTokens.length; i++) {
                address rewardToken = rewardTokens[i];
                pending = _calPending(user.power, pool.accPerShare[rewardToken], user.rewardDebt[rewardToken]);
                user.rewardedAmount[rewardToken] = user.rewardedAmount[rewardToken].add(pending);
                _safeRewardTransfer(IERC20(rewardToken), msg.sender, pending);
            }
        }
    }

    function _transferPendingRewards(PoolInfo storage pool, UserInfo storage user, uint32 nftTokenId, uint128 nftPower) internal {
         _transferPendingReward(pool, user, nftTokenId, nftPower, address(zkl));
        if (address(pool.strategy) != address(0)) {
            address[] memory rewardTokens = pool.strategy.rewardTokens();
            for(uint256 i = 0; i < rewardTokens.length; i++) {
                address rewardToken = rewardTokens[i];
                _transferPendingReward(pool, user, nftTokenId, nftPower, rewardToken);
            }
        }
    }

    function _transferPendingReward(PoolInfo storage pool, UserInfo storage user, uint32 nftTokenId, uint128 nftPower, address rewardToken) internal {
        uint256 pending = _calPending(nftPower, pool.accPerShare[rewardToken], user.pendingRewardDebt[nftTokenId][rewardToken]);
        user.rewardedAmount[rewardToken] = user.rewardedAmount[rewardToken].add(pending);
        _safeRewardTransfer(IERC20(rewardToken), msg.sender, pending);
        delete user.pendingRewardDebt[nftTokenId][rewardToken];
    }

    /// @dev Safe reward transfer function, just in case if rounding error causes pool to not have enough Rewards
    function _safeRewardTransfer(IERC20 rewardToken, address to, uint256 amount) internal {
        if (amount == 0) {
            return;
        }
        uint256 rewardBal = rewardToken.balanceOf(address(this));
        amount = amount > rewardBal ? rewardBal : amount;
        require(Utils.sendERC20(rewardToken, to, amount), 'StakePool: sendERC20');
    }

    function _updateRewardDebts(PoolInfo storage pool, UserInfo storage user) internal {
        user.rewardDebt[address(zkl)] = _calRewardDebt(user.power, pool.accPerShare[address(zkl)]);
        if (address(pool.strategy) != address(0)) {
            address[] memory rewardTokens = pool.strategy.rewardTokens();
            for(uint256 i = 0; i < rewardTokens.length; i++) {
                address rewardToken = rewardTokens[i];
                user.rewardDebt[rewardToken] = _calRewardDebt(user.power, pool.accPerShare[rewardToken]);
            }
        }
    }

    function _updatePendingAccShareDebts(PoolInfo storage pool, UserInfo storage user, uint32 nftTokenId, uint128 nftPower) internal {
        user.pendingRewardDebt[nftTokenId][address(zkl)] = _calRewardDebt(nftPower, pool.accPerShare[address(zkl)]);
        if (address(pool.strategy) != address(0)) {
            address[] memory rewardTokens = pool.strategy.rewardTokens();
            for(uint256 i = 0; i < rewardTokens.length; i++) {
                address rewardToken = rewardTokens[i];
                user.pendingRewardDebt[nftTokenId][rewardToken] = _calRewardDebt(nftPower, pool.accPerShare[rewardToken]);
            }
        }
    }

    function _updateDiscardReward(PoolInfo storage pool, UserInfo storage user, uint32 nftTokenId, uint128 nftPower) internal {
        _updateDiscardRewardOfToken(pool, user, nftTokenId, nftPower, address(zkl));
        if (address(pool.strategy) != address(0)) {
            address[] memory rewardTokens = pool.strategy.rewardTokens();
            for(uint256 i = 0; i < rewardTokens.length; i++) {
                address rewardToken = rewardTokens[i];
                _updateDiscardRewardOfToken(pool, user, nftTokenId, nftPower, rewardToken);
            }
        }
        pool.discardRewardStartBlock = pool.lastRewardBlock;
        pool.discardRewardEndBlock = pool.lastRewardBlock.add(pool.discardRewardReleaseBlocks);
    }

    function _updateDiscardRewardOfToken(PoolInfo storage pool, UserInfo storage user, uint32 nftTokenId, uint128 nftPower, address rewardToken) internal {
        // if there are any discard reward unreleased accumulate it with new discard reward
        uint256 unReleasedReward = 0;
        if (pool.discardRewardEndBlock > pool.lastRewardBlock) {
            unReleasedReward = pool.discardRewardPerBlock[rewardToken].mul(pool.discardRewardEndBlock - pool.lastRewardBlock);
        }
        uint256 discardReward = _calPending(nftPower, pool.accPerShare[rewardToken], user.pendingRewardDebt[nftTokenId][rewardToken]);
        pool.discardRewardPerBlock[rewardToken] = unReleasedReward.add(discardReward).div(pool.discardRewardReleaseBlocks);
        delete user.pendingRewardDebt[nftTokenId][rewardToken];
    }

    function _transferNftToDepositor(uint32 nftTokenId, address depositor) internal {
        nft.transferFrom(address(this), depositor, nftTokenId);
        delete nftDepositor[nftTokenId];
    }

    function _calRewardShareIncrement(PoolInfo storage pool, address rewardToken) internal view returns (uint256) {
        uint256 blockNumber = _blockNumber();
        uint256 accRewardAmount = 0;
        if (rewardToken == address(zkl)) {
            // the block in (bonusStartBlock, bonusEndBlock] will be allocated zkl
            uint256 zklRewardBlocks = _calRewardBlocks(blockNumber, pool.bonusStartBlock, pool.bonusEndBlock, pool.lastRewardBlock);
            accRewardAmount = zklRewardBlocks.mul(pool.zklPerBlock);
        }
        // the block in (discardRewardStartBlock, discardRewardEndBlock] will be allocated discard reward
        uint256 dsdRewardBlocks = _calRewardBlocks(blockNumber, pool.discardRewardStartBlock, pool.discardRewardEndBlock, pool.lastRewardBlock);
        return _calRewardShare(pool, rewardToken, accRewardAmount, dsdRewardBlocks);
    }

    function _calRewardBlocks(uint256 currentBlock, uint256 startBlock, uint256 endBlock, uint256 lastRewardBlock) internal pure returns (uint256) {
        if (currentBlock <= startBlock || lastRewardBlock >= endBlock) {
            return 0;
        }
        uint256 rewardStart = lastRewardBlock < startBlock ? startBlock : lastRewardBlock;
        uint256 rewardEnd = currentBlock > endBlock ? endBlock : currentBlock;
        return rewardEnd.sub(rewardStart);
    }

    function _calRewardShare(PoolInfo storage pool, address rewardToken, uint256 rewardAmount, uint256 dsdRewardBlocks) internal view returns (uint256) {
        uint256 dsdAmount = dsdRewardBlocks.mul(pool.discardRewardPerBlock[rewardToken]);
        uint256 totalAmount = rewardAmount.add(dsdAmount);
        // pool power will never be zero at this point
        return totalAmount.mul(MUL_FACTOR).div(pool.power);
    }

    function _calRewardDebt(uint128 power, uint256 poolAccPerShare) internal pure returns (uint256) {
        return uint256(power).mul(poolAccPerShare).div(MUL_FACTOR);
    }

    function _calPending(uint128 power, uint256 poolAccPerShare, uint256 rewardDebt) internal pure returns (uint256) {
        return uint256(power).mul(poolAccPerShare).div(MUL_FACTOR).sub(rewardDebt);
    }

    function _blockNumber() virtual internal view returns (uint256) {
        return block.number;
    }
}

pragma solidity ^0.7.0;

// SPDX-License-Identifier: UNLICENSED


/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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

pragma solidity ^0.7.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



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
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "14");

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
        return sub(a, b, "v");
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
        require(c / a == b, "15");

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
        return div(a, b, "x");
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
        return mod(a, b, "y");
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.7.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



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
library SafeMathUInt128 {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint128 a, uint128 b) internal pure returns (uint128) {
        uint128 c = a + b;
        require(c >= a, "12");

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
    function sub(uint128 a, uint128 b) internal pure returns (uint128) {
        return sub(a, b, "aa");
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
    function sub(
        uint128 a,
        uint128 b,
        string memory errorMessage
    ) internal pure returns (uint128) {
        require(b <= a, errorMessage);
        uint128 c = a - b;

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
    function mul(uint128 a, uint128 b) internal pure returns (uint128) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint128 c = a * b;
        require(c / a == b, "13");

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
    function div(uint128 a, uint128 b) internal pure returns (uint128) {
        return div(a, b, "ac");
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
    function div(
        uint128 a,
        uint128 b,
        string memory errorMessage
    ) internal pure returns (uint128) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint128 c = a / b;
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
    function mod(uint128 a, uint128 b) internal pure returns (uint128) {
        return mod(a, b, "ad");
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
    function mod(
        uint128 a,
        uint128 b,
        string memory errorMessage
    ) internal pure returns (uint128) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.7.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



import "./IERC20.sol";
import "./Bytes.sol";

library Utils {
    /// @notice Returns lesser of two values
    function minU32(uint32 a, uint32 b) internal pure returns (uint32) {
        return a < b ? a : b;
    }

    /// @notice Returns lesser of two values
    function minU64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a < b ? a : b;
    }

    /// @notice Sends tokens
    /// @dev NOTE: this function handles tokens that have transfer function not strictly compatible with ERC20 standard
    /// @dev NOTE: call `transfer` to this token may return (bool) or nothing
    /// @param _token Token address
    /// @param _to Address of recipient
    /// @param _amount Amount of tokens to transfer
    /// @return bool flag indicating that transfer is successful
    function sendERC20(
        IERC20 _token,
        address _to,
        uint256 _amount
    ) internal returns (bool) {
        (bool callSuccess, bytes memory callReturnValueEncoded) =
            address(_token).call(abi.encodeWithSignature("transfer(address,uint256)", _to, _amount));
        // `transfer` method may return (bool) or nothing.
        bool returnedSuccess = callReturnValueEncoded.length == 0 || abi.decode(callReturnValueEncoded, (bool));
        return callSuccess && returnedSuccess;
    }

    /// @notice Transfers token from one address to another
    /// @dev NOTE: this function handles tokens that have transfer function not strictly compatible with ERC20 standard
    /// @dev NOTE: call `transferFrom` to this token may return (bool) or nothing
    /// @param _token Token address
    /// @param _from Address of sender
    /// @param _to Address of recipient
    /// @param _amount Amount of tokens to transfer
    /// @return bool flag indicating that transfer is successful
    function transferFromERC20(
        IERC20 _token,
        address _from,
        address _to,
        uint256 _amount
    ) internal returns (bool) {
        (bool callSuccess, bytes memory callReturnValueEncoded) =
            address(_token).call(abi.encodeWithSignature("transferFrom(address,address,uint256)", _from, _to, _amount));
        // `transferFrom` method may return (bool) or nothing.
        bool returnedSuccess = callReturnValueEncoded.length == 0 || abi.decode(callReturnValueEncoded, (bool));
        return callSuccess && returnedSuccess;
    }

    /// @notice Recovers signer's address from ethereum signature for given message
    /// @param _signature 65 bytes concatenated. R (32) + S (32) + V (1)
    /// @param _messageHash signed message hash.
    /// @return address of the signer
    function recoverAddressFromEthSignature(bytes memory _signature, bytes32 _messageHash)
        internal
        pure
        returns (address)
    {
        require(_signature.length == 65, "P"); // incorrect signature length

        bytes32 signR;
        bytes32 signS;
        uint8 signV;
        assembly {
            signR := mload(add(_signature, 32))
            signS := mload(add(_signature, 64))
            signV := byte(0, mload(add(_signature, 96)))
        }

        return ecrecover(_messageHash, signV, signR, signS);
    }

    /// @notice Returns new_hash = hash(old_hash + bytes)
    function concatHash(bytes32 _hash, bytes memory _bytes) internal pure returns (bytes32) {
        bytes32 result;
        assembly {
            let bytesLen := add(mload(_bytes), 32)
            mstore(_bytes, _hash)
            result := keccak256(_bytes, bytesLen)
        }
        return result;
    }

    function hashBytesToBytes20(bytes memory _bytes) internal pure returns (bytes20) {
        return bytes20(uint160(uint256(keccak256(_bytes))));
    }
}

pragma solidity ^0.7.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



/// @title Ownable Contract
/// @author Matter Labs
contract Ownable {
    /// @dev Storage position of the masters address (keccak256('eip1967.proxy.admin') - 1)
    bytes32 private constant masterPosition = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /// @notice Contract constructor
    /// @dev Sets msg sender address as masters address
    /// @param masterAddress Master address
    constructor(address masterAddress) {
        setMaster(masterAddress);
    }

    /// @notice Check if specified address is master
    /// @param _address Address to check
    function requireMaster(address _address) internal view {
        require(_address == getMaster(), "1c"); // oro11 - only by master
    }

    /// @notice Returns contract masters address
    /// @return master Master's address
    function getMaster() public view returns (address master) {
        bytes32 position = masterPosition;
        assembly {
            master := sload(position)
        }
    }

    /// @dev Sets new masters address
    /// @param _newMaster New master's address
    function setMaster(address _newMaster) internal {
        bytes32 position = masterPosition;
        assembly {
            sstore(position, _newMaster)
        }
    }

    /// @notice Transfer mastership of the contract to new master
    /// @param _newMaster New masters address
    function transferMastership(address _newMaster) external {
        requireMaster(msg.sender);
        require(_newMaster != address(0), "1d"); // otp11 - new masters address can't be zero address
        setMaster(_newMaster);
    }
}

pragma solidity ^0.7.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



/// @title zkSync configuration constants
/// @author Matter Labs
contract Config {
    /// @dev Bytes in one chunk
    uint8 constant CHUNK_BYTES = 9;

    /// @dev zkSync address length
    uint8 constant ADDRESS_BYTES = 20;

    uint8 constant PUBKEY_HASH_BYTES = 20;

    /// @dev Public key bytes length
    uint8 constant PUBKEY_BYTES = 32;

    /// @dev Ethereum signature r/s bytes length
    uint8 constant ETH_SIGN_RS_BYTES = 32;

    /// @dev Success flag bytes length
    uint8 constant SUCCESS_FLAG_BYTES = 1;

    /// @dev Max amount of tokens registered in the network (excluding ETH, which is hardcoded as tokenId = 0)
    uint16 constant MAX_AMOUNT_OF_REGISTERED_TOKENS = 127;

    /// @dev Max account id that could be registered in the network
    uint32 constant MAX_ACCOUNT_ID = (2**24) - 1;

    /// @dev Expected average period of block creation
    uint256 constant BLOCK_PERIOD = 2 seconds;

    /// @dev ETH blocks verification expectation
    /// @dev Blocks can be reverted if they are not verified for at least EXPECT_VERIFICATION_IN.
    /// @dev If set to 0 validator can revert blocks at any time.
    uint256 constant EXPECT_VERIFICATION_IN = 0 hours / BLOCK_PERIOD;

    uint256 constant NOOP_BYTES = 1 * CHUNK_BYTES;
    uint256 constant DEPOSIT_BYTES = 6 * CHUNK_BYTES;
    uint256 constant QUICK_SWAP_BYTES = 16 * CHUNK_BYTES;
    uint256 constant TRANSFER_TO_NEW_BYTES = 6 * CHUNK_BYTES;
    uint256 constant PARTIAL_EXIT_BYTES = 6 * CHUNK_BYTES;
    uint256 constant TRANSFER_BYTES = 2 * CHUNK_BYTES;
    uint256 constant FORCED_EXIT_BYTES = 6 * CHUNK_BYTES;

    /// @dev Full exit operation length
    uint256 constant FULL_EXIT_BYTES = 6 * CHUNK_BYTES;

    /// @dev ChangePubKey operation length
    uint256 constant CHANGE_PUBKEY_BYTES = 6 * CHUNK_BYTES;
    uint256 constant MAPPING_BYTES = 10 * CHUNK_BYTES;
    uint256 constant L1ADDLQ_BYTES = 11 * CHUNK_BYTES;
    uint256 constant L1REMOVELQ_BYTES = 11 * CHUNK_BYTES;

    /// @dev Expiration delta for priority request to be satisfied (in seconds)
    /// @dev NOTE: Priority expiration should be > (EXPECT_VERIFICATION_IN * BLOCK_PERIOD)
    /// @dev otherwise incorrect block with priority op could not be reverted.
    uint256 constant PRIORITY_EXPIRATION_PERIOD = 3 days;

    /// @dev Expiration delta for priority request to be satisfied (in ETH blocks)
    uint256 constant PRIORITY_EXPIRATION =
        PRIORITY_EXPIRATION_PERIOD/BLOCK_PERIOD;

    /// @dev Maximum number of priority request to clear during verifying the block
    /// @dev Cause deleting storage slots cost 5k gas per each slot it's unprofitable to clear too many slots
    /// @dev Value based on the assumption of ~750k gas cost of verifying and 5 used storage slots per PriorityOperation structure
    uint64 constant MAX_PRIORITY_REQUESTS_TO_DELETE_IN_VERIFY = 6;

    /// @dev Reserved time for users to send full exit priority operation in case of an upgrade (in seconds)
    uint256 constant MASS_FULL_EXIT_PERIOD = 9 days;

    /// @dev Reserved time for users to withdraw funds from full exit priority operation in case of an upgrade (in seconds)
    uint256 constant TIME_TO_WITHDRAW_FUNDS_FROM_FULL_EXIT = 2 days;

    /// @dev Notice period before activation preparation status of upgrade mode (in seconds)
    /// @dev NOTE: we must reserve for users enough time to send full exit operation, wait maximum time for processing this operation and withdraw funds from it.
    uint256 constant UPGRADE_NOTICE_PERIOD =
        0;

    /// @dev Timestamp - seconds since unix epoch
    uint256 constant COMMIT_TIMESTAMP_NOT_OLDER = 24 hours;

    /// @dev Maximum available error between real commit block timestamp and analog used in the verifier (in seconds)
    /// @dev Must be used cause miner's `block.timestamp` value can differ on some small value (as we know - 15 seconds)
    uint256 constant COMMIT_TIMESTAMP_APPROXIMATION_DELTA = 15 minutes;

    /// @dev Bit mask to apply for verifier public input before verifying.
    uint256 constant INPUT_MASK = 14474011154664524427946373126085988481658748083205070504932198000989141204991;

    /// @dev Auth fact reset timelock
    uint256 constant AUTH_FACT_RESET_TIMELOCK = 1 days;

    /// @dev When set fee = 100, it means 1%
    uint16 constant MAX_WITHDRAW_FEE = 10000;

    /// @dev Chain id
    uint8 constant CHAIN_ID = 2;
}

pragma solidity ^0.7.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



/// @title Interface of the strategy contract
/// @author zk.link
/// @notice IStrategy implement must has default receive function
interface IStrategy {

    /**
     * @notice Returns vault contract address.
     */
    function vault() external view returns (address);

    /**
     * @notice Returns token id strategy want to invest.
     */
    function want() external view returns (uint16);

    /**
     * @notice Returns token strategy want to invest.
     */
    function wantToken() external view returns (address);

    /**
    * @notice Response on vault deposit token to strategy
    */
    function deposit() external;

    /**
     * @notice Withdraw `amountNeeded` token to vault
     * @param amountNeeded amount need to withdraw from strategy
     */
    function withdraw(uint256 amountNeeded) external;

    /**
     * @notice Harvest reward tokens.
     */
    function rewardTokens() external view returns (address[] memory);

    /**
     * @notice Harvest reward tokens to pool.
     * @return amounts of each reward token
     */
    function harvest() external returns (uint256[] memory);

    /**
     * @notice Migrate all assets to `_newStrategy`.
     */
    function migrate(address _newStrategy) external;

    /**
     * @notice Response after old strategy migrate all assets to this new strategy
     */
    function onMigrate() external;

    /**
     * @notice Emergency exit from strategy, all assets will return back to vault regardless of loss
     */
    function emergencyExit() external;
}

pragma solidity ^0.7.0;
pragma abicoder v2;

// SPDX-License-Identifier: MIT OR Apache-2.0





/// @title Interface of the ZkLinkNFT
/// @author zk.link
interface IZkLinkNFT {

    enum LqStatus { NONE, ADD_PENDING, FINAL, ADD_FAIL, REMOVE_PENDING }

    // liquidity info
    struct Lq {
        uint16 tokenId; // token in l2 cross chain pair
        uint128 amount; // liquidity add amount, this is the mine power in stake pool
        address pair; // l2 cross chain pair token address
        LqStatus status;
        uint128 lpTokenAmount; // l2 cross chain pair token amount
    }

    function tokenLq(uint32 nftTokenId) external view returns (Lq memory);
    function addLq(address to, uint16 tokenId, uint128 amount, address pair) external returns (uint32);
    function confirmAddLq(uint32 nftTokenId, uint128 lpTokenAmount) external;
    function revokeAddLq(uint32 nftTokenId) external;
    function removeLq(uint32 nftTokenId) external;
    function confirmRemoveLq(uint32 nftTokenId) external;
    function revokeRemoveLq(uint32 nftTokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address);
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
}

pragma solidity ^0.7.0;

// SPDX-License-Identifier: MIT OR Apache-2.0


import "./zksync/IERC20.sol";

/// @title Interface of the ZKLink
/// @author zk.link
interface IZkLink {

    /// @notice Add token to l2 cross chain pair
    /// @param _zkLinkAddress Receiver Layer 2 address if add liquidity failed
    /// @param _token Token added
    /// @param _amount Amount of token
    /// @param _pair L2 cross chain pair address
    /// @param _minLpAmount L2 lp token amount min received
    /// @return nft token id
    function addLiquidity(address _zkLinkAddress, IERC20 _token, uint104 _amount, address _pair, uint104 _minLpAmount) external returns (uint32);

    /// @notice Remove liquidity from l1 and get token back from l2 cross chain pair
    /// @param _zkLinkAddress Receiver Layer 2 address if remove liquidity success
    /// @param _nftTokenId Nft token that contains info about the liquidity
    /// @param _minAmount Token amount min received
    function removeLiquidity(address _zkLinkAddress, uint32 _nftTokenId, uint104 _minAmount) external;
}

pragma solidity ^0.7.0;

// SPDX-License-Identifier: MIT



/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

pragma solidity ^0.7.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



// Functions named bytesToX, except bytesToBytes20, where X is some type of size N < 32 (size of one word)
// implements the following algorithm:
// f(bytes memory input, uint offset) -> X out
// where byte representation of out is N bytes from input at the given offset
// 1) We compute memory location of the word W such that last N bytes of W is input[offset..offset+N]
// W_address = input + 32 (skip stored length of bytes) + offset - (32 - N) == input + offset + N
// 2) We load W from memory into out, last N bytes of W are placed into out

library Bytes {
    function toBytesFromUInt16(uint16 self) internal pure returns (bytes memory _bts) {
        return toBytesFromUIntTruncated(uint256(self), 2);
    }

    function toBytesFromUInt24(uint24 self) internal pure returns (bytes memory _bts) {
        return toBytesFromUIntTruncated(uint256(self), 3);
    }

    function toBytesFromUInt32(uint32 self) internal pure returns (bytes memory _bts) {
        return toBytesFromUIntTruncated(uint256(self), 4);
    }

    function toBytesFromUInt128(uint128 self) internal pure returns (bytes memory _bts) {
        return toBytesFromUIntTruncated(uint256(self), 16);
    }

    // Copies 'len' lower bytes from 'self' into a new 'bytes memory'.
    // Returns the newly created 'bytes memory'. The returned bytes will be of length 'len'.
    function toBytesFromUIntTruncated(uint256 self, uint8 byteLength) private pure returns (bytes memory bts) {
        require(byteLength <= 32, "Q");
        bts = new bytes(byteLength);
        // Even though the bytes will allocate a full word, we don't want
        // any potential garbage bytes in there.
        uint256 data = self << ((32 - byteLength) * 8);
        assembly {
            mstore(
                add(bts, 32), // BYTES_HEADER_SIZE
                data
            )
        }
    }

    // Copies 'self' into a new 'bytes memory'.
    // Returns the newly created 'bytes memory'. The returned bytes will be of length '20'.
    function toBytesFromAddress(address self) internal pure returns (bytes memory bts) {
        bts = toBytesFromUIntTruncated(uint256(self), 20);
    }

    // See comment at the top of this file for explanation of how this function works.
    // NOTE: theoretically possible overflow of (_start + 20)
    function bytesToAddress(bytes memory self, uint256 _start) internal pure returns (address addr) {
        uint256 offset = _start + 20;
        require(self.length >= offset, "R");
        assembly {
            addr := mload(add(self, offset))
        }
    }

    // Reasoning about why this function works is similar to that of other similar functions, except NOTE below.
    // NOTE: that bytes1..32 is stored in the beginning of the word unlike other primitive types
    // NOTE: theoretically possible overflow of (_start + 20)
    function bytesToBytes20(bytes memory self, uint256 _start) internal pure returns (bytes20 r) {
        require(self.length >= (_start + 20), "S");
        assembly {
            r := mload(add(add(self, 0x20), _start))
        }
    }

    // See comment at the top of this file for explanation of how this function works.
    // NOTE: theoretically possible overflow of (_start + 0x2)
    function bytesToUInt16(bytes memory _bytes, uint256 _start) internal pure returns (uint16 r) {
        uint256 offset = _start + 0x2;
        require(_bytes.length >= offset, "T");
        assembly {
            r := mload(add(_bytes, offset))
        }
    }

    // See comment at the top of this file for explanation of how this function works.
    // NOTE: theoretically possible overflow of (_start + 0x3)
    function bytesToUInt24(bytes memory _bytes, uint256 _start) internal pure returns (uint24 r) {
        uint256 offset = _start + 0x3;
        require(_bytes.length >= offset, "U");
        assembly {
            r := mload(add(_bytes, offset))
        }
    }

    // NOTE: theoretically possible overflow of (_start + 0x4)
    function bytesToUInt32(bytes memory _bytes, uint256 _start) internal pure returns (uint32 r) {
        uint256 offset = _start + 0x4;
        require(_bytes.length >= offset, "V");
        assembly {
            r := mload(add(_bytes, offset))
        }
    }

    // NOTE: theoretically possible overflow of (_start + 0x10)
    function bytesToUInt128(bytes memory _bytes, uint256 _start) internal pure returns (uint128 r) {
        uint256 offset = _start + 0x10;
        require(_bytes.length >= offset, "W");
        assembly {
            r := mload(add(_bytes, offset))
        }
    }

    // See comment at the top of this file for explanation of how this function works.
    // NOTE: theoretically possible overflow of (_start + 0x14)
    function bytesToUInt160(bytes memory _bytes, uint256 _start) internal pure returns (uint160 r) {
        uint256 offset = _start + 0x14;
        require(_bytes.length >= offset, "X");
        assembly {
            r := mload(add(_bytes, offset))
        }
    }

    // NOTE: theoretically possible overflow of (_start + 0x20)
    function bytesToBytes32(bytes memory _bytes, uint256 _start) internal pure returns (bytes32 r) {
        uint256 offset = _start + 0x20;
        require(_bytes.length >= offset, "Y");
        assembly {
            r := mload(add(_bytes, offset))
        }
    }

    // Original source code: https://github.com/GNSPS/solidity-bytes-utils/blob/master/contracts/BytesLib.sol#L228
    // Get slice from bytes arrays
    // Returns the newly created 'bytes memory'
    // NOTE: theoretically possible overflow of (_start + _length)
    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes memory) {
        require(_bytes.length >= (_start + _length), "Z"); // bytes length is less then start byte + length bytes

        bytes memory tempBytes = new bytes(_length);

        if (_length != 0) {
            assembly {
                let slice_curr := add(tempBytes, 0x20)
                let slice_end := add(slice_curr, _length)

                for {
                    let array_current := add(_bytes, add(_start, 0x20))
                } lt(slice_curr, slice_end) {
                    slice_curr := add(slice_curr, 0x20)
                    array_current := add(array_current, 0x20)
                } {
                    mstore(slice_curr, mload(array_current))
                }
            }
        }

        return tempBytes;
    }

    /// Reads byte stream
    /// @return new_offset - offset + amount of bytes read
    /// @return data - actually read data
    // NOTE: theoretically possible overflow of (_offset + _length)
    function read(
        bytes memory _data,
        uint256 _offset,
        uint256 _length
    ) internal pure returns (uint256 new_offset, bytes memory data) {
        data = slice(_data, _offset, _length);
        new_offset = _offset + _length;
    }

    // NOTE: theoretically possible overflow of (_offset + 1)
    function readBool(bytes memory _data, uint256 _offset) internal pure returns (uint256 new_offset, bool r) {
        new_offset = _offset + 1;
        r = uint8(_data[_offset]) != 0;
    }

    // NOTE: theoretically possible overflow of (_offset + 1)
    function readUint8(bytes memory _data, uint256 _offset) internal pure returns (uint256 new_offset, uint8 r) {
        new_offset = _offset + 1;
        r = uint8(_data[_offset]);
    }

    // NOTE: theoretically possible overflow of (_offset + 2)
    function readUInt16(bytes memory _data, uint256 _offset) internal pure returns (uint256 new_offset, uint16 r) {
        new_offset = _offset + 2;
        r = bytesToUInt16(_data, _offset);
    }

    // NOTE: theoretically possible overflow of (_offset + 3)
    function readUInt24(bytes memory _data, uint256 _offset) internal pure returns (uint256 new_offset, uint24 r) {
        new_offset = _offset + 3;
        r = bytesToUInt24(_data, _offset);
    }

    // NOTE: theoretically possible overflow of (_offset + 4)
    function readUInt32(bytes memory _data, uint256 _offset) internal pure returns (uint256 new_offset, uint32 r) {
        new_offset = _offset + 4;
        r = bytesToUInt32(_data, _offset);
    }

    // NOTE: theoretically possible overflow of (_offset + 16)
    function readUInt128(bytes memory _data, uint256 _offset) internal pure returns (uint256 new_offset, uint128 r) {
        new_offset = _offset + 16;
        r = bytesToUInt128(_data, _offset);
    }

    // NOTE: theoretically possible overflow of (_offset + 20)
    function readUInt160(bytes memory _data, uint256 _offset) internal pure returns (uint256 new_offset, uint160 r) {
        new_offset = _offset + 20;
        r = bytesToUInt160(_data, _offset);
    }

    // NOTE: theoretically possible overflow of (_offset + 20)
    function readAddress(bytes memory _data, uint256 _offset) internal pure returns (uint256 new_offset, address r) {
        new_offset = _offset + 20;
        r = bytesToAddress(_data, _offset);
    }

    // NOTE: theoretically possible overflow of (_offset + 20)
    function readBytes20(bytes memory _data, uint256 _offset) internal pure returns (uint256 new_offset, bytes20 r) {
        new_offset = _offset + 20;
        r = bytesToBytes20(_data, _offset);
    }

    // NOTE: theoretically possible overflow of (_offset + 32)
    function readBytes32(bytes memory _data, uint256 _offset) internal pure returns (uint256 new_offset, bytes32 r) {
        new_offset = _offset + 32;
        r = bytesToBytes32(_data, _offset);
    }

    /// Trim bytes into single word
    function trim(bytes memory _data, uint256 _new_length) internal pure returns (uint256 r) {
        require(_new_length <= 0x20, "10"); // new_length is longer than word
        require(_data.length >= _new_length, "11"); // data is to short

        uint256 a;
        assembly {
            a := mload(add(_data, 0x20)) // load bytes into uint256
        }

        return a >> ((0x20 - _new_length) * 8);
    }

    // Helper function for hex conversion.
    function halfByteToHex(bytes1 _byte) internal pure returns (bytes1 _hexByte) {
        require(uint8(_byte) < 0x10, "hbh11"); // half byte's value is out of 0..15 range.

        // "FEDCBA9876543210" ASCII-encoded, shifted and automatically truncated.
        return bytes1(uint8(0x66656463626139383736353433323130 >> (uint8(_byte) * 8)));
    }

    // Convert bytes to ASCII hex representation
    function bytesToHexASCIIBytes(bytes memory _input) internal pure returns (bytes memory _output) {
        bytes memory outStringBytes = new bytes(_input.length * 2);

        // code in `assembly` construction is equivalent of the next code:
        // for (uint i = 0; i < _input.length; ++i) {
        //     outStringBytes[i*2] = halfByteToHex(_input[i] >> 4);
        //     outStringBytes[i*2+1] = halfByteToHex(_input[i] & 0x0f);
        // }
        assembly {
            let input_curr := add(_input, 0x20)
            let input_end := add(input_curr, mload(_input))

            for {
                let out_curr := add(outStringBytes, 0x20)
            } lt(input_curr, input_end) {
                input_curr := add(input_curr, 0x01)
                out_curr := add(out_curr, 0x02)
            } {
                let curr_input_byte := shr(0xf8, mload(input_curr))
                // here outStringByte from each half of input byte calculates by the next:
                //
                // "FEDCBA9876543210" ASCII-encoded, shifted and automatically truncated.
                // outStringByte = byte (uint8 (0x66656463626139383736353433323130 >> (uint8 (_byteHalf) * 8)))
                mstore(
                    out_curr,
                    shl(0xf8, shr(mul(shr(0x04, curr_input_byte), 0x08), 0x66656463626139383736353433323130))
                )
                mstore(
                    add(out_curr, 0x01),
                    shl(0xf8, shr(mul(and(0x0f, curr_input_byte), 0x08), 0x66656463626139383736353433323130))
                )
            }
        }
        return outStringBytes;
    }
}