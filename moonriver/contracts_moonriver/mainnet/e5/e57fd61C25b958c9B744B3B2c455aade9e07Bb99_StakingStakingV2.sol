// SPDX-License-Identifier: MIT

pragma solidity 0.7.5;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

interface IwsFHM {
    function sFHMValue(uint _amount) external view returns (uint);

    function unwrap( uint _amount ) external returns ( uint );
}

interface IRewardsHolder {
    function newTick() external;
}

interface IVotingEscrow {
    function balanceOfVotingToken(address _owner) external view returns (uint);
}

interface IStakingStaking {
    function migrateFrom(address _owner, uint _amount, bool _force) external;
}

interface IStaking {
    function unstake( uint _amount, bool _trigger ) external;
}

interface IBurnable {
    function burn(uint amount) external;
}

/// @title Double staking vault for FantOHM
/// @author pwntr0n
/// @notice With this staking vault you can receive rebases from 3,3 staking and rewards for 6,6 double staking
contract StakingStakingV2 is Ownable, AccessControl, ReentrancyGuard, IVotingEscrow {

    using SafeERC20 for IERC20;
    using SafeMath for uint;

    /// @dev ACL role for borrower contract to whitelist call our methods
    bytes32 public constant BORROWER_ROLE = keccak256("BORROWER_ROLE");

    /// @dev ACL role for calling newSample() from RewardsHolder contract
    bytes32 public constant REWARDS_ROLE = keccak256("REWARDS_ROLE");

    address public immutable wsFHM;
    address public immutable sFHM;
    address public immutable FHM;
    address public immutable staking;
    address public immutable DAO;
    address public rewardsHolder;
    uint public noFeeSeconds; // 30 days in seconds
    uint public unstakeFee; // 100 means 1%
    uint public claimPageSize; // maximum iteration threshold

    // actual number of wsFHM staking, which is user staking pool
    uint public totalStaking;
    // actual number of wsFHM transferred during sample ticks which were not claimed to any user, which is rewards pool
    uint public totalPendingClaim;
    // actual number of wsFHM borrowed
    uint public totalBorrowed;
    // total number of fhm burnt
    uint public totalBurntFhm;

    bool public pauseNewStakes;
    bool public useWhitelist;
    bool public enableEmergencyWithdraw;
    bool private initCalled;

    /// @notice data structure holding info about all stakers
    struct UserInfo {
        uint staked; // absolute number of wsFHM user is staking or rewarded

        uint borrowed; // absolute number of wsFHM user agains user has borrowed something

        uint lastStakeTimestamp; // time of last stake from which is counting noFeeDuration
        uint lastClaimIndex; // index in rewardSamples last claimed
        uint usersIndex; // index in users array

        mapping(address => uint) allowances;
    }

    /// @notice data structure holding info about all rewards gathered during time
    struct SampleInfo {
        uint blockNumber; // time of newSample tick
        uint timestamp; // time of newSample tick as unix timestamp

        uint totalRewarded; // absolute number of wsFHM transferred during newSample

        uint tvl; // wsFHM supply staking contract is holding from which rewards will be dispersed
    }

    mapping(address => bool) public whitelist;

    mapping(address => bool) public noFeeWhitelist;

    mapping(address => UserInfo) public userInfo;

    address[] private users;

    SampleInfo[] public rewardSamples;

    /* ///////////////////////////////////////////////////////////////
                                EVENTS
    ////////////////////////////////////////////////////////////// */

    /// @notice deposit event
    /// @param _from user who triggered the deposit
    /// @param _to user who is able to withdraw the deposited tokens
    /// @param _value deposited wsFHM value
    /// @param _lastStakeTimestamp unix timestamp of deposit
    event StakingDeposited(address indexed _from, address indexed _to, uint _value, uint _lastStakeTimestamp);

    /// @notice withdraw event
    /// @param _owner user who triggered the withdrawal
    /// @param _to user who received the withdrawn tokens
    /// @param _unstaked amount in wsFHM token to be withdrawn
    /// @param _transferred amount in wsFHM token actually withdrawn - potential fee was applied
    /// @param _unstakeTimestamp unix timestamp of event generated
    event StakingWithdraw(address indexed _owner, address indexed _to, uint _unstaked, uint _transferred, uint _unstakeTimestamp);

    /// @notice new rewards were sampled and prepared for claim
    /// @param _blockNumber  block number of event generated
    /// @param _blockTimestamp  block timestamp of event generated
    /// @param _rewarded  block timestamp of event generated
    /// @param _tvl  wsFHM supply in the time of sample
    event RewardSampled(uint _blockNumber, uint _blockTimestamp, uint _rewarded, uint _tvl);

    /// @notice reward claimed during one claim() method
    /// @param _wallet  user who triggered the claim
    /// @param _startClaimIndex first rewards which were claimed
    /// @param _lastClaimIndex last rewards which were claimed
    /// @param _claimed how many wsFHM claimed
    event RewardClaimed(address indexed _wallet, uint indexed _startClaimIndex, uint indexed _lastClaimIndex, uint _claimed);

    /// @notice token transferred inside vault
    /// @param _from  user who triggered the transfer
    /// @param _to user to which is transferring to
    /// @param _amount amount in wrapped token to transfer
    event TokenTransferred(address indexed _from, address indexed _to, uint _amount);

    /// @notice approve borrow contract for 9,9 borrowing against
    /// @param _owner user who triggered approval
    /// @param _spender user who has rights to call borrow and return borrow or liquidate borrow
    /// @param _value how much he can borrow against
    event BorrowApproved(address indexed _owner, address indexed _spender, uint _value);

    /// @notice newer staking pool contract transferred wsFHM of owner from the vault
    /// @param _owner user whos account is used
    /// @param _spender calling smart contract
    /// @param _migrated how much was migrated
    /// @param _timestamp unix timestamp of event generated
    event Migrated(address indexed _owner, address indexed _spender, uint _migrated, uint _timestamp);

    /// @notice newer staking pool contract transferred wsFHM of owner from the vault
    /// @param _owner user whos account is used
    /// @param _spender calling smart contract
    /// @param _poolFrom the preious pool to be migrated from
    /// @param _migrated how much was migrated
    /// @param _timestamp unix timestamp of event generated
    event MigratedTo(address indexed _owner, address indexed _spender, address indexed _poolFrom, uint _migrated, uint _timestamp);

    /// @notice borrow contract transferred wsFHM of owner from the vault
    /// @param _owner user whos account is used
    /// @param _spender calling smart contract
    /// @param _borrowed how borrowed against
    /// @param _timestamp unix timestamp of event generated
    event Borrowed(address indexed _owner, address indexed _spender, uint _borrowed, uint _timestamp);

    /// @notice borrow contract returned wsFHM to owner to the vault
    /// @param _owner user whos account is used
    /// @param _spender calling smart contract
    /// @param _returned how much returned from borrow against
    /// @param _timestamp unix timestamp of event generated
    event BorrowReturned(address indexed _owner, address indexed _spender, uint _returned, uint _timestamp);

    /// @notice borrow contract liquidated wsFHM to owner to the vault
    /// @param _owner user whos account is used
    /// @param _spender calling smart contract
    /// @param _liquidated how much was lost during borrow against
    /// @param _timestamp unix timestamp of event generated
    event BorrowLiquidated(address indexed _owner, address indexed _spender, uint _liquidated, uint _timestamp);

    /// @notice emergency token transferred
    /// @param _token ERC20 token
    /// @param _recipient recipient of transaction
    /// @param _amount token amount
    event EmergencyTokenRecovered(address indexed _token, address indexed _recipient, uint _amount);

    /// @notice emergency withdraw of unclaimed rewards
    /// @param _recipient recipient of transaction
    /// @param _rewarded wsFHM amount of unclaimed rewards transferred
    event EmergencyRewardsWithdraw(address indexed _recipient, uint _rewarded);

    /// @notice emergency withdraw of ETH
    /// @param _recipient recipient of transaction
    /// @param _amount ether value of transaction
    event EmergencyEthRecovered(address indexed _recipient, uint _amount);

    constructor(address _wsFHM, address _sFHM, address _FHM, address _staking, address _DAO) {
        require(_wsFHM != address(0));
        wsFHM = _wsFHM;
        require(_sFHM != address(0));
        sFHM = _sFHM;
        require(_FHM != address(0));
        FHM = _FHM;
        require(_staking != address(0));
        staking = _staking;
        require(_DAO != address(0));
        DAO = _DAO;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        IERC20(_sFHM).approve(_staking, type(uint).max);
    }

    /// @notice suggested values:
    /// @param _noFeeSeconds - 30 days in seconds
    /// @param _unstakeFee - 3000 aka 30%
    /// @param _claimPageSize - 100/1000
    /// @param _useWhitelist - false (we can set it when we will test on production)
    /// @param _pauseNewStakes - false (you can set as some emergency leave precaution)
    /// @param _enableEmergencyWithdraw - false (you can set as some emergency leave precaution)
    function setParameters(address _rewardsHolder, uint _noFeeSeconds, uint _unstakeFee, uint _claimPageSize, bool _useWhitelist, bool _pauseNewStakes, bool _enableEmergencyWithdraw) public onlyOwner {
        rewardsHolder = _rewardsHolder;
        noFeeSeconds = _noFeeSeconds;
        unstakeFee = _unstakeFee;
        claimPageSize = _claimPageSize;
        useWhitelist = _useWhitelist;
        pauseNewStakes = _pauseNewStakes;
        enableEmergencyWithdraw = _enableEmergencyWithdraw;

        _setupRole(REWARDS_ROLE, _rewardsHolder);
        _setupRole(REWARDS_ROLE, msg.sender);

        if (!initCalled) {
            newSample(0);
            initCalled = true;
        }
    }

    function modifyWhitelist(address user, bool add) external onlyOwner {
        if (add) {
            require(!whitelist[user], "ALREADY_IN_WHITELIST");
            whitelist[user] = true;
        } else {
            require(whitelist[user], "NOT_IN_WHITELIST");
            delete whitelist[user];
        }
    }

    function modifyNoFeeWhitelist(address user, bool add) external onlyOwner {
        if (add) {
            require(!noFeeWhitelist[user], "ALREADY_IN_WHITELIST");
            noFeeWhitelist[user] = true;
        } else {
            require(noFeeWhitelist[user], "NOT_IN_WHITELIST");
            delete noFeeWhitelist[user];
        }
    }

    /// @notice Insert _amount to the pool, add to your share, need to claim everything before new stake
    /// @param _to user onto which account we want to transfer money
    /// @param _amount how much wsFHM user wants to deposit
    function deposit(address _to, uint _amount) public nonReentrant {
        // temporary disable new stakes, but allow to call claim and unstake
        require(!pauseNewStakes, "PAUSED");
        // allow only whitelisted contracts
        if (useWhitelist) require(whitelist[msg.sender], "SENDER_IS_NOT_IN_WHITELIST");

        doClaim(_to, claimPageSize);

        // unsure that user claim everything before stake again
        require(userInfo[_to].lastClaimIndex == rewardSamples.length - 1, "CLAIM_PAGE_TOO_SMALL");

        // erc20 transfer of staked tokens
        IERC20(wsFHM).safeTransferFrom(msg.sender, address(this), _amount);

        uint staked = userInfo[_to].staked.add(_amount);

        // persist it
        UserInfo storage info = userInfo[_to];
        if (info.lastStakeTimestamp == 0) {
            users.push(_to);
            info.usersIndex = users.length - 1;
        }
        info.staked = staked;
        info.lastStakeTimestamp = block.timestamp;

        totalStaking = totalStaking.add(_amount);

        // and record in history
        emit StakingDeposited(msg.sender, _to, _amount, info.lastStakeTimestamp);
    }

    /// @notice whitelisted and approved by user contract can migrate all his funds into new contract
    /// @param _owner user which we want to migrate
    /// @param _amount amount to withdraw
    /// @param _force force withdraw without claiming rewards
    function migrateFrom(address _owner, uint _amount, bool _force) external nonReentrant {
        require(hasRole(BORROWER_ROLE, msg.sender), "MISSING_BORROWER_ROLE");

        uint approved = allowance(_owner, msg.sender);
        require(approved >= _amount, "NOT_ENOUGH_BALANCE");

        // auto claim before unstake
        if (!_force) doClaim(_owner, claimPageSize);

        UserInfo storage info = userInfo[_owner];

        // unsure that user claim everything before unstaking
        require(info.lastClaimIndex == rewardSamples.length - 1 || _force, "CLAIM_PAGE_TOO_SMALL");

        uint maxToUnstake = info.staked.sub(info.borrowed);

        require(_amount <= maxToUnstake, "NOT_ENOUGH_USER_TOKENS");
        require(_amount <= totalStaking, "NOT_ENOUGH_TOKENS_IN_POOL");

        info.staked = info.staked.sub(_amount);

        if (info.staked == 0) {
            // if unstaking everything just delete whole record
            users[info.usersIndex] = address(0);
            delete userInfo[_owner];
        } else {
            // refresh allowance
            info.allowances[msg.sender] = info.allowances[msg.sender].sub(_amount);
        }

        if (totalStaking > _amount) {
            totalStaking = totalStaking.sub(_amount);
        } else {
            // wsfhm balance of last one is the same, so wsfhm should be rounded
            require(totalStaking == _amount, "LAST_USER_NEED_BALANCE");
            totalStaking = 0;
        }

        // and record in history
        emit Migrated(_owner, msg.sender, _amount, block.timestamp);

        // erc20 transfer of staked tokens
        IERC20(wsFHM).safeTransfer(msg.sender, _amount);
    }

    /// @notice users can migrate his funds from previous contract
    /// @param _to user onto which account we want to migrate money
    /// @param _poolFrom previous pool address to be migrated from
    /// @param _amount amount to withdraw
    /// @param _force force withdraw without claiming rewards
    function migrateTo(address _to, address _poolFrom, uint _amount, bool _force) external nonReentrant {
        // temporary disable new stakes, but allow to call claim and unstake
        require(!pauseNewStakes, "PAUSED");

        // allow only whitelisted contracts
        if (useWhitelist) require(whitelist[msg.sender], "SENDER_IS_NOT_IN_WHITELIST");

        doClaim(_to, claimPageSize);

        // unsure that user claim everything before stake again
        require(userInfo[_to].lastClaimIndex == rewardSamples.length - 1, "CLAIM_PAGE_TOO_SMALL");

        // migrate from previous pool
        IStakingStaking(_poolFrom).migrateFrom(msg.sender, _amount, _force);
        // and record in history
        emit MigratedTo(_to, msg.sender, _poolFrom, _amount, block.timestamp);

        uint staked = userInfo[_to].staked.add(_amount);

        // persist it
        UserInfo storage info = userInfo[_to];
        if (info.lastStakeTimestamp == 0) {
            users.push(_to);
            info.usersIndex = users.length - 1;
        }
        info.staked = staked;
        info.lastStakeTimestamp = block.timestamp;

        totalStaking = totalStaking.add(_amount);

        // and record in history
        emit StakingDeposited(msg.sender, _to, _amount, info.lastStakeTimestamp);
    }

    /// @notice Return current TVL of staking contract
    /// @return totalStaking plus totalPendingClaim even with amount borrowed against
    function totalValueLocked() public view returns (uint) {
        return totalStaking.add(totalPendingClaim);
    }

    /// @notice Returns the amount of underlying tokens that idly sit in the Vault.
    /// @return The amount of underlying tokens that sit idly in the Vault.
    function totalHoldings() public view returns (uint) {
        return IERC20(wsFHM).balanceOf(address(this));
    }

    /// @notice underlying token used for accounting
    function underlying() public view returns (address) {
        return wsFHM;
    }

    /// @notice last rewards to stakers
    /// @dev APY => 100 * (1 + <actualRewards> / <totalValueLocked>)^(365 * <rebases per day>)
    /// @return rewards for last sample
    function actualRewards() public view returns (uint) {
        return rewardSamples[rewardSamples.length - 1].totalRewarded;
    }

    function getRewardSamplesLength() public view returns (uint) {
        return rewardSamples.length;
    }

    function getRewardSample(uint i) public view returns (uint _blockNumber, uint _timestamp, uint _totalRewarded, uint _tvl) {
        require(i <= rewardSamples.length - 1, "SAMPLE_NOT_FOUND");
        SampleInfo memory info = rewardSamples[i];
        return (info.blockNumber, info.timestamp, info.totalRewarded, info.tvl);
    }

    /// @notice Return user balance
    /// @return 1 - staked and to claim from rewards, 2 - withdrawable, 3 - borrowed
    function userBalance(address _user) public view returns (uint, uint, uint) {
        UserInfo storage info = userInfo[_user];

        // count amount to withdraw from staked tokens except borrowed tokens
        uint toWithdraw = 0;
        (uint allClaimable,,) = claimable(_user, claimPageSize);
        uint stakedAndToClaim = info.staked.add(allClaimable);
        if (stakedAndToClaim >= info.borrowed) {
            toWithdraw = stakedAndToClaim.sub(info.borrowed);
        }

        uint withdrawable = getWithdrawableBalance(_user, info.lastStakeTimestamp, toWithdraw);

        return (stakedAndToClaim, withdrawable, info.borrowed);
    }

    /// @notice safety check if user need to manually call claim to see additional rewards
    /// @param _user owner
    /// @return true if need to manually call claim or borrow/return/liquidate before additional deposit/withdraw
    function needToClaim(address _user) external view returns (bool) {
        UserInfo storage info = userInfo[_user];
        return info.lastClaimIndex + claimPageSize < rewardSamples.length;
    }

    /// @notice Returns a user's Vault balance in underlying tokens.
    /// @param _owner The user to get the underlying balance of.
    /// @return The user's Vault balance in underlying tokens.
    function balanceOfUnderlying(address _owner) public view returns (uint) {
        (uint stakedAndToClaim,,) = userBalance(_owner);
        return stakedAndToClaim;
    }

    /// @notice This method shows staked token balance from wrapped token balance even from rewards
    /// @dev Should be used in snapshot.eth strategy contract call
    /// @param _owner The user to get the underlying balance of.
    /// @return Balance in staked token usefull for voting escrow
    function balanceOfVotingToken(address _owner) external override view returns (uint) {
        (uint stakedAndToClaim,,) = userBalance(_owner);
        return IwsFHM(wsFHM).sFHMValue(stakedAndToClaim);
    }

    function isLocked(uint lastStakeTimestamp, uint currentTimestamp) private view returns (bool) {
        return currentTimestamp <= lastStakeTimestamp.add(noFeeSeconds);
    }

    function getWithdrawableBalance(address _user, uint lastStakeTimestamp, uint _balanceWithdrawable) private view returns (uint) {
        if (noFeeWhitelist[_user]) return _balanceWithdrawable;
        else if (isLocked(lastStakeTimestamp, block.timestamp)) {
            uint fee = _balanceWithdrawable.mul(unstakeFee).div(10 ** 4);
            _balanceWithdrawable = _balanceWithdrawable.sub(fee);
        }
        return _balanceWithdrawable;
    }

    /// @notice Rewards holder accumulated enough balance during its period to create new sample, Record our current staking TVL
    /// @param _rewarded wsFHM amount rewarded
    function newSample(uint _rewarded) public {
        require(hasRole(REWARDS_ROLE, msg.sender), "MISSING_REWARDS_ROLE");

        // transfer balance from rewards holder
        if (_rewarded > 0) IERC20(wsFHM).safeTransferFrom(msg.sender, address(this), _rewarded);

        uint tvl = totalValueLocked();

        rewardSamples.push(SampleInfo({
        // remember time data
        blockNumber : block.number,
        timestamp : block.timestamp,

        // rewards size
        totalRewarded : _rewarded,

        // holders snapshot based on staking and pending claim wsFHM
        tvl : tvl
        }));

        // count total value to be claimed
        totalPendingClaim = totalPendingClaim.add(_rewarded);

        // and record in history
        emit RewardSampled(block.number, block.timestamp, _rewarded, tvl);
    }

    /// @notice Counts claimable tokens from totalPendingClaim tokens for given user
    /// @param _user claiming user
    /// @param _claimPageSize page size for iteration loop
    /// @return claimable amount up to the page size, last claim index and amount which was not used to claim
    function claimable(address _user, uint _claimPageSize) private view returns (uint, uint, uint){
        UserInfo storage info = userInfo[_user];

        uint lastStakeTimestamp = info.lastStakeTimestamp;
        uint lastClaimIndex = info.lastClaimIndex;
        // last item already claimed
        if (lastClaimIndex == rewardSamples.length - 1) return (0, rewardSamples.length - 1, 0);

        // start claiming with wsFHM staking previously
        uint allClaimed = 0;
        uint allBlacklisted = 0;

        // new user considered as claimed last sample
        if (lastStakeTimestamp == 0) {
            lastClaimIndex = rewardSamples.length - 1;
        } else {
            uint staked = info.staked;
            uint startIndex = lastClaimIndex + 1;
            // page size is either _claimPageSize or the rest
            uint endIndex = Math.min(lastClaimIndex + _claimPageSize, rewardSamples.length - 1);

            if (staked > 0) {
                for (uint i = startIndex; i <= endIndex; i++) {
                    SampleInfo memory sample = rewardSamples[i];

                    // compute share from current TVL, which means not yet claimed rewards are _counted_ to the APY
                    if (sample.tvl > 0) {
                        uint claimed = 0;
                        // 40 * 10 / 20000
                        uint share = staked.add(allClaimed);
                        uint wsfhm = rewardSamples[i].totalRewarded.mul(share);
                        claimed = wsfhm.div(rewardSamples[i].tvl);

                        if (isLocked(lastStakeTimestamp, sample.timestamp)) {
                            allClaimed = allClaimed.add(claimed);
                        } else {
                            allBlacklisted = allBlacklisted.add(claimed);
                        }
                    }
                }
            }
            lastClaimIndex = endIndex;
        }

        return (allClaimed, lastClaimIndex, allBlacklisted);
    }

    function claim(uint _claimPageSize) external nonReentrant {
        doClaim(msg.sender, _claimPageSize);
    }

    /// @notice Claim unprocessed rewards to belong to userInfo staking amount with possibility to choose _claimPageSize
    /// @param _user claiming user
    /// @param _claimPageSize page size for iteration loop
    function doClaim(address _user, uint _claimPageSize) private {
        // clock new tick
        IRewardsHolder(rewardsHolder).newTick();

        UserInfo storage info = userInfo[_user];

        // last item already claimed
        if (info.lastClaimIndex == rewardSamples.length - 1) return;

        // otherwise collect rewards
        uint startIndex = info.lastClaimIndex + 1;
        (uint allClaimed, uint lastClaimIndex, uint allBlacklisted) = claimable(_user, _claimPageSize);
        uint allClaimedAndBlacklisted = allClaimed.add(allBlacklisted);

        // persist it
        info.staked = info.staked.add(allClaimed);
        info.lastClaimIndex = lastClaimIndex;

        totalStaking = totalStaking.add(allClaimed);

        // remove it from total balance if is not last one
        if (totalPendingClaim > allClaimedAndBlacklisted) {
            totalPendingClaim = totalPendingClaim.sub(allClaimedAndBlacklisted);
        } else {
            // wsfhm balance of last one is the same, so gons should be rounded
            require(totalPendingClaim == allClaimedAndBlacklisted, "LAST_USER_NEED_BALANCE");
            totalPendingClaim = 0;
        }

        // and record in history
        emit RewardClaimed(_user, startIndex, info.lastClaimIndex, allClaimed);

        if (allBlacklisted > 0) {
            burnFees(allBlacklisted);
        }
    }

    /// @notice Unstake _amount from staking pool. Automatically call claim.
    /// @param _to user who will receive withdraw amount
    /// @param _amount amount to withdraw
    /// @param _force force withdraw without claiming rewards
    function withdraw(address _to, uint _amount, bool _force) public nonReentrant {
        return doWithdraw(msg.sender, _to, _amount, _force);
    }

    function doWithdraw(address _owner, address _to, uint _amount, bool _force) private {
        // auto claim before unstake
        if (!_force) doClaim(_owner, claimPageSize);

        UserInfo storage info = userInfo[_owner];

        // unsure that user claim everything before unstaking
        require(info.lastClaimIndex == rewardSamples.length - 1 || _force, "CLAIM_PAGE_TOO_SMALL");

        // count amount to withdraw from staked except borrowed
        uint maxToUnstake = info.staked.sub(info.borrowed);
        require(_amount <= maxToUnstake, "NOT_ENOUGH_USER_TOKENS");

        uint transferring = getWithdrawableBalance(_owner, info.lastStakeTimestamp, _amount);
        // and more than we have
        require(transferring <= totalStaking, "NOT_ENOUGH_TOKENS_IN_POOL");

        info.staked = info.staked.sub(_amount);
        if (info.staked == 0) {
            // if unstaking everything just delete whole record
            users[info.usersIndex] = address(0);
            delete userInfo[_owner];
        }

        // remove it from total balance
        if (totalStaking > _amount) {
            totalStaking = totalStaking.sub(_amount);
        } else {
            // wsfhm balance of last one is the same, so wsfhm should be rounded
            require(totalStaking == _amount, "LAST_USER_NEED_BALANCE");
            totalStaking = 0;
        }

        // and record in history
        emit StakingWithdraw(_owner, _to, _amount, transferring, block.timestamp);

        // actual erc20 transfer
        IERC20(wsFHM).safeTransfer(_to, transferring);

        // and burn fees
        uint fee = _amount.sub(transferring);
        if (fee > 0) {
            burnFees(fee);
        }
    }

    function burnFees(uint amount) private {
        uint sfhmAmount = IwsFHM(wsFHM).unwrap(amount);
        uint fhmAmountBefore = IERC20(FHM).balanceOf(address(this));
        IStaking(staking).unstake(sfhmAmount, true);
        uint fhmAmountAfter = IERC20(FHM).balanceOf(address(this));
        uint toBurn = fhmAmountAfter.sub(fhmAmountBefore);
        totalBurntFhm = totalBurntFhm.add(toBurn);
        IBurnable(FHM).burn(toBurn);
    }

    /// @notice transfers amount to different user with preserving lastStakedBlock
    /// @param _to user transferring amount to
    /// @param _amount wsfhm amount
    function transfer(address _to, uint _amount) external nonReentrant {
        doTransfer(msg.sender, _to, _amount);
    }

    function doTransfer(address _from, address _to, uint _amount) private {
        // need to claim before any operation with staked amounts
        // use half of the page size to have same complexity
        uint halfPageSize = claimPageSize.div(2);
        doClaim(_from, halfPageSize);
        doClaim(_to, halfPageSize);

        // subtract from caller
        UserInfo storage fromInfo = userInfo[_from];
        require(fromInfo.staked.sub(fromInfo.borrowed) >= _amount, "NOT_ENOUGH_USER_TOKENS");
        fromInfo.staked = fromInfo.staked.sub(_amount);

        // add it to the callee
        UserInfo storage toInfo = userInfo[_to];
        toInfo.staked = toInfo.staked.add(_amount);
        // act as normal deposit()
        toInfo.lastStakeTimestamp = Math.max(fromInfo.lastStakeTimestamp, toInfo.lastStakeTimestamp);

        // and record in history
        emit TokenTransferred(_from, _to, _amount);
    }

    function usersLength() external view returns (uint) {
        return users.length;
    }

    function usersWithdrawNotLocked(uint _from, uint _to) external {
        require(_from <= users.length && _to <= users.length && _from <= _to, "ILLEGAL_FROM_TO");

        for (uint i = _from; i <= _to; i++) {
            address user = users[i];
            if (user == address(0)) continue;

            UserInfo storage info = userInfo[user];
            if (!isLocked(info.lastStakeTimestamp, block.timestamp)) {
                (uint staked,uint withdrawable,uint borrowed) = userBalance(user);
                // never unstake user with fee
                require(withdrawable == staked, "WITHDRAWING_BEFORE_VESTING_PERIOD_END");

                doWithdraw(user, user, staked.sub(borrowed), false);
            }
        }
    }


    /* ///////////////////////////////////////////////////////////////
                          BORROWING FUNCTIONS
    ////////////////////////////////////////////////////////////// */

    /// @notice approve _spender to do anything with _amount of tokens for current caller user
    /// @param _spender who will have right to do whatever he wants with _amount of user's money
    /// @param _amount approved amount _spender can withdraw
    function allow(address _spender, uint _amount) external {
        address user = msg.sender;
        UserInfo storage info = userInfo[user];
        info.allowances[_spender] = _amount;

        emit BorrowApproved(user, _spender, _amount);
    }

    /// @notice check approve result, how much is approved for _owner and arbitrary _spender
    /// @param _owner who gives right to the _spender
    /// @param _spender who will have right to do whatever he wants with _amount of user's money
    function allowance(address _owner, address _spender) public view returns (uint) {
        UserInfo storage info = userInfo[_owner];
        return info.allowances[_spender];
    }

    /// @notice allow to borrow asset against wsFHM collateral which are staking in this pool.
    /// You are able to borrow up to usd worth of staked + claimed tokens
    /// @param _user from which account
    /// @param _amount how much tokens _user wants to borrow against
    function borrow(address _user, uint _amount) external nonReentrant {
        require(hasRole(BORROWER_ROLE, msg.sender), "MISSING_BORROWER_ROLE");

        // temporary disable borrows, but allow to call returnBorrow
        require(!pauseNewStakes, "PAUSED");

        uint approved = allowance(_user, msg.sender);
        require(approved >= _amount, "NOT_ENOUGH_BALANCE");

        // auto claim before borrow
        // but don't enforce to be claimed all
        doClaim(_user, claimPageSize);

        UserInfo storage info = userInfo[_user];

        info.borrowed = info.borrowed.add(_amount);

        // refresh allowance
        info.allowances[msg.sender] = info.allowances[msg.sender].sub(_amount);

        // cannot borrow what is not mine
        require(info.borrowed <= info.staked, "NOT_ENOUGH_USER_TOKENS");
        // and more than we have staking or claimed
        uint availableToBorrow = totalStaking.sub(totalBorrowed);
        require(_amount <= availableToBorrow, "NOT_ENOUGH_POOL_TOKENS");

        // add it from total balance
        totalBorrowed = totalBorrowed.add(_amount);

        // and record in history
        emit Borrowed(_user, msg.sender, _amount, block.timestamp);

        // erc20 transfer of staked tokens
        IERC20(wsFHM).safeTransfer(msg.sender, _amount);
    }

    /// @notice return borrowed staked tokens
    /// @param _user from which account
    /// @param _amount how much tokens _user wants to return
    function returnBorrow(address _user, uint _amount) external nonReentrant {
        require(hasRole(BORROWER_ROLE, msg.sender), "MISSING_BORROWER_ROLE");

        // erc20 transfer of staked tokens
        IERC20(wsFHM).safeTransferFrom(msg.sender, address(this), _amount);

        // auto claim returnBorrow borrow
        // but don't enforce to be claimed all
        doClaim(_user, claimPageSize);

        UserInfo storage info = userInfo[_user];

        uint returningBorrowed = _amount;
        // return less then borrow this turn
        if (info.borrowed >= _amount) {
            info.borrowed = info.borrowed.sub(_amount);
        }
        // repay all plus give profit back
        else {
            returningBorrowed = info.borrowed;
            uint toStake = _amount.sub(returningBorrowed);
            info.staked = info.staked.add(toStake);
            info.borrowed = 0;
            totalStaking = totalStaking.add(toStake);
        }

        // subtract it from total balance
        if (totalBorrowed > returningBorrowed) {
            totalBorrowed = totalBorrowed.sub(returningBorrowed);
        } else {
            totalBorrowed = 0;
        }

        // and record in history
        emit BorrowReturned(_user, msg.sender, _amount, block.timestamp);
    }

    /// @notice liquidation of borrowed staked tokens
    /// @param _user from which account
    /// @param _amount how much tokens _user wants to liquidate
    function liquidateBorrow(address _user, uint _amount) external nonReentrant {
        require(hasRole(BORROWER_ROLE, msg.sender), "MISSING_BORROWER_ROLE");

        // auto claim returnBorrow borrow
        // but don't enforce to be claimed all
        doClaim(_user, claimPageSize);

        UserInfo storage info = userInfo[_user];

        // liquidate less or equal then borrow this turn
        if (info.borrowed >= _amount) {
            // 1. subs from user staked
            if (info.staked > _amount) {
                info.staked = info.staked.sub(_amount);
            } else {
                info.staked = 0;
            }

            // 2. subs from total staking
            if (totalStaking > _amount) {
                totalStaking = totalStaking.sub(_amount);
            } else {
                totalStaking = 0;
            }

            // 3. subs total borrowed
            if (totalBorrowed > _amount) {
                totalBorrowed = totalBorrowed.sub(_amount);
            } else {
                totalBorrowed = 0;
            }

            // 4. subs from user borrowed
            info.borrowed = info.borrowed.sub(_amount);
        }
        // liquidate all plus take a loss
        else {
            uint toTakeLoss = _amount.sub(info.borrowed);

            // 1. subs from user staked
            if (info.staked > toTakeLoss) {
                info.staked = info.staked.sub(toTakeLoss);
            } else {
                info.staked = 0;
            }

            // 2. subs from total staking
            if (totalStaking > toTakeLoss) {
                totalStaking = totalStaking.sub(toTakeLoss);
            } else {
                totalStaking = 0;
            }

            // 3. subs from total borrowed
            if (totalBorrowed > info.borrowed) {
                totalBorrowed = totalBorrowed.sub(info.borrowed);
            } else {
                totalBorrowed = 0;
            }

            // 4. subs from borrowed
            info.borrowed = 0;
        }

        // and record in history
        emit BorrowLiquidated(_user, msg.sender, _amount, block.timestamp);
    }

    /* ///////////////////////////////////////////////////////////////
                           EMERGENCY FUNCTIONS
    ////////////////////////////////////////////////////////////// */

    /// @notice emergency withdraw of user holding
    function emergencyWithdraw() external {
        require(enableEmergencyWithdraw, "EMERGENCY_WITHDRAW_NOT_ENABLED");

        UserInfo storage info = userInfo[msg.sender];

        uint toWithdraw = info.staked.sub(info.borrowed);

        // clear the data
        info.staked = info.staked.sub(toWithdraw);

        // repair total values
        if (totalStaking >= toWithdraw) {
            totalStaking = totalStaking.sub(toWithdraw);
        } else {
            // wsfhm balance of last one is the same, so gons should be rounded
            require(totalStaking == toWithdraw, "Last user emergency withdraw needs balance");
            totalStaking = 0;
        }

        // erc20 transfer
        IERC20(wsFHM).safeTransfer(msg.sender, toWithdraw);

        // and record in history
        emit StakingWithdraw(msg.sender, msg.sender, toWithdraw, toWithdraw, block.number);
    }

    /// @dev Once called, any user who not claimed cannot claim/withdraw, should be used only in emergency.
    function emergencyWithdrawRewards() external onlyOwner {
        require(enableEmergencyWithdraw, "EMERGENCY_WITHDRAW_NOT_ENABLED");

        // repair total values
        uint amount = totalPendingClaim;
        totalPendingClaim = 0;

        // erc20 transfer
        IERC20(wsFHM).safeTransfer(DAO, amount);

        emit EmergencyRewardsWithdraw(DAO, amount);
    }

    /// @notice Been able to recover any token which is sent to contract by mistake
    /// @param token erc20 token
    function emergencyRecoverToken(address token) external virtual onlyOwner {
        require(token != wsFHM);

        uint amount = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransfer(DAO, amount);

        emit EmergencyTokenRecovered(token, DAO, amount);
    }

    /// @notice Been able to recover any ftm/movr token sent to contract by mistake
    function emergencyRecoverEth() external virtual onlyOwner {
        uint amount = address(this).balance;

        payable(DAO).transfer(amount);

        emit EmergencyEthRecovered(DAO, amount);
    }

    /// @notice grants borrower role to given _account
    /// @param _account borrower contract
    function grantRoleBorrower(address _account) external {
        grantRole(BORROWER_ROLE, _account);
    }

    /// @notice revoke borrower role to given _account
    /// @param _account borrower contract
    function revokeRoleBorrower(address _account) external {
        revokeRole(BORROWER_ROLE, _account);
    }

    /// @notice grants rewards role to given _account
    /// @param _account rewards contract
    function grantRoleRewards(address _account) external {
        grantRole(REWARDS_ROLE, _account);
    }

    /// @notice revoke rewards role to given _account
    /// @param _account rewards contract
    function revokeRoleRewards(address _account) external {
        revokeRole(REWARDS_ROLE, _account);
    }

    /* ///////////////////////////////////////////////////////////////
                            RECEIVE ETHER LOGIC
    ////////////////////////////////////////////////////////////// */

    /// @dev Required for the Vault to receive unwrapped ETH.
    receive() external payable {}

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/EnumerableSet.sol";
import "../utils/Address.sol";
import "../utils/Context.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

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