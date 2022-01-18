// SPDX-License-Identifier: MIT

pragma solidity 0.6.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/cryptography/MerkleProof.sol";
import "./interfaces/IStakingRewards.sol";

import { FundRaisingGuild } from "./FundRaisingGuild.sol";

/// @title Fund raising platform by SkyLaunch
/// @notice Developed by Chris Ciszak
/// @dev Only the owner can add new pools
contract SkyLaunchFundRaising is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /// @dev Details about each user in a pool
    struct UserInfo {
        uint256 amount;
        uint256 fundingAmount; // Based on staked tokens, the funding that has come from the user (or not if they choose to pull out)
        uint256 multiplier;
        uint256 nftValue;
        uint256 utilityNFTTokenId;
        uint256 collectedRewards;
    }

    /// @dev Info of each pool.
    struct PoolInfo {
        IERC20 rewardToken; // Address of the reward token contract.
        IERC20 fundRaisingToken;
        uint256 subscriptionStartTimestamp ; // Block when users stake counts towards earning reward token allocation
        uint256 subscriptionEndTimestamp; // Before this block, staking is permitted
        uint256 fundingEndTimestamp; // Between subscriptionEndTimestamp and this number pledge funding is permitted
        uint256 targetRaise; // Amount that the project wishes to raise
        uint256 price; // Price per token
        uint256 maxStakingAmountPerUser; // Max. amount of tokens that can be staked per account/user
        uint256 maxUtilityNFTsValue; // max amount of tokens that are permitted to participate in this pool
        uint256 rewardsStartTime;
        uint256 rewardsCliffEndTime;
        uint256 rewardsEndTime;
    }

    struct Multiplier {
        uint256 scoreFrom;
        uint256 multiplier; // 1.5 represented as 150 
    }

    // Utility NFTs with guaranteed allocations
    address utilityNFT;

    /// @notice staking token is fixed for all pools
    IERC20 public stakingFactory;

    /// @notice staking token is fixed for all pools
    address[] public stakingRewards;

    /// @notice Container for holding all rewards
    FundRaisingGuild public rewardGuildBank;

    /// @notice List of pools that users can stake into
    PoolInfo[] public poolInfo;

    // Pool to accumulated share counters
    mapping(uint256 => uint256) public poolIdToAccPercentagePerShare;
    mapping(uint256 => uint256) public poolIdToLastPercentageAllocBlock;

    // Number of reward tokens distributed per block for this pool
    mapping(uint256 => uint256) public poolIdToRewardPerBlock;

    // Last block number that reward token distribution took place
    mapping(uint256 => uint256) public poolIdToLastRewardBlock;

    // Block number when rewards start
    mapping(uint256 => uint256) public poolIdToRewardStartBlock;

    // Block number when cliff ends
    mapping(uint256 => uint256) public poolIdToRewardCliffEndBlock;

    // Block number when rewards end
    mapping(uint256 => uint256) public poolIdToRewardEndBlock;

    // Per LPOOL token staked, how much reward token earned in pool that users will get
    mapping(uint256 => uint256) public poolIdToAccRewardPerShareVesting;

    // Total rewards being distributed up to rewardEndBlock
    mapping(uint256 => uint256) public poolIdToMaxRewardTokensAvailableForVesting;

    // Total amount staked into the pool
    mapping(uint256 => uint256) public poolIdToTotalStaked;

    // Total amount of funding received by stakers after subscriptionEndTimestamp and before fundingEndTimestamp
    mapping(uint256 => uint256) public poolIdToTotalRaised;

    mapping(uint256 => uint256) public poolIdToTotalGuaranteedAllocationsRaised;

    mapping(uint256 => uint256) public poolIdToTotalGuaranteedAllocationsSubscribed;

    mapping(uint256 => uint256) public poolIdToTotalMultipliers;

    // For every staker that funded their pledge, the sum of all of their allocated percentages
    mapping(uint256 => uint256) public poolIdToTotalFundedPercentageOfTargetRaise;

    // True when funds have been claimed
    mapping(uint256 => bool) public poolIdToFundsClaimed;

    /// @notice Per pool, info of each user that stakes ERC20 tokens.
    /// @notice Pool ID => User Address => User Info
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    // Available before staking ends for any given project. Essentitally 100% to 18 dp
    uint256 public constant TOTAL_TOKEN_ALLOCATION_POINTS = (100 * (10 ** 18));

    // KYCed users Merkle Root
    bytes32 public merkleRootKYC;

    // multiplier brackets for score
    Multiplier[] public multipliers;

    event ContractDeployed(address indexed guildBank);
    event PoolAdded(uint256 indexed pid);
    event Subscribe(address indexed user, uint256 indexed pid);
    event SubscribeWithUtilityNFT(address indexed user, uint256 indexed pid, uint256 amount);
    event SubscriptionFunded(address indexed user, uint256 indexed pid, uint256 amount);
    event RewardsSetUp(uint256 indexed pid, uint256 amount, uint256 rewardStartTime, uint256 rewardCliffEndTime, uint256 rewardEndTime);
    event RewardClaimed(address indexed user, uint256 indexed pid, uint256 amount);
    event FundRaisingClaimed(uint256 indexed pid, address indexed recipient, uint256 amount);

    constructor(uint256[] memory scores, uint256[] memory mps, address _utilityNFT) public {
        //require(address(_stakingRewards) != address(0), "constructor: stakingRewards must not be zero address");
        require(scores.length == mps.length, "constructor: incorrect multipliers");

        //stakingRewards = _stakingRewards;
        rewardGuildBank = new FundRaisingGuild(address(this));
        utilityNFT = _utilityNFT;

        for(uint256 i = 0; i < scores.length; i++){
            Multiplier memory mp;
            mp.scoreFrom = scores[i];
            mp.multiplier = mps[i];
            multipliers.push(mp);
        }

        emit ContractDeployed(address(rewardGuildBank));
    }

    function addStakingRewards(address _stakingRewards) onlyOwner external {
        stakingRewards.push(_stakingRewards);
    }

    function removeStakingRewards(address _stakingRewards) onlyOwner external {
        for(uint256 i = 0; i < stakingRewards.length; i++){
            if(stakingRewards[i] == _stakingRewards){
                stakingRewards[i] = stakingRewards[stakingRewards.length -1];
                stakingRewards.pop();
            }
        }
    }

    function setKYCMerkleRoot(bytes32 _merkleRootKYC) onlyOwner external {
        merkleRootKYC = _merkleRootKYC;
    }

    /// @notice Returns the number of pools that have been added by the owner
    /// @return Number of pools
    function numberOfPools() external view returns (uint256) {
        return poolInfo.length;
    }

    /// @dev Can only be called by the contract owner
    function add(
        IERC20 _rewardToken,
        IERC20 _fundRaisingToken,
        uint256 _subscriptionStartTimestamp,
        uint256 _subscriptionEndTimestamp,
        uint256 _fundingEndTimestamp,
        uint256 _targetRaise,
        uint256 _price,
        uint256 _maxStakingAmountPerUser,
        uint256 _maxUtilityNFTsValue
    ) public onlyOwner {
        address rewardTokenAddress = address(_rewardToken);
        require(rewardTokenAddress != address(0), "add: _rewardToken is zero address");
        address fundRaisingTokenAddress = address(_fundRaisingToken);

        require(_subscriptionStartTimestamp < _subscriptionEndTimestamp, "add: _subscriptionStartTimestamp must be before staking end");
        require(_subscriptionEndTimestamp < _fundingEndTimestamp, "add: staking end must be before funding end");
        require(_targetRaise > 0, "add: Invalid raise amount");
        require(_price > 0, "add: Invalid price amount");

        poolInfo.push(PoolInfo({
            rewardToken : _rewardToken,
            fundRaisingToken : _fundRaisingToken,
            subscriptionStartTimestamp: _subscriptionStartTimestamp,
            subscriptionEndTimestamp: _subscriptionEndTimestamp,
            fundingEndTimestamp: _fundingEndTimestamp,
            targetRaise: _targetRaise,
            price: _price,
            maxStakingAmountPerUser: _maxStakingAmountPerUser,
            maxUtilityNFTsValue: _maxUtilityNFTsValue,
            rewardsStartTime: 0,
            rewardsCliffEndTime: 0,
            rewardsEndTime: 0

        }));

        //poolIdToLastPercentageAllocBlock[poolInfo.length.sub(1)] = _subscriptionStartTimestamp;

        emit PoolAdded(poolInfo.length.sub(1));
    }

    // step 
    // subscribe
    function subscribe(uint256 _pid, uint256 _index, bytes32[] calldata _merkleProof) external nonReentrant {
        // join upcoming IDO
        require(_pid < poolInfo.length, "subscribe: Invalid PID");

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        require(block.timestamp >= pool.subscriptionStartTimestamp, "subscribe: subscription not started");
        require(block.timestamp <= pool.subscriptionEndTimestamp, "subscribe: subscription no longer permitted");

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(_index, msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRootKYC, node), 'subscribe: Invalid proof.');

        // Collect the users multiplier
        uint256 userMultiplier = getMultiplier(msg.sender);
        require(userMultiplier > 0, "subscribe: not sufficient score");

        // Add user to the pool
        user.multiplier = userMultiplier;

        // update multipliers
        poolIdToTotalMultipliers[_pid] = poolIdToTotalMultipliers[_pid].add(userMultiplier);

        emit Subscribe(msg.sender, _pid);
    }

    // step 
    // subscribe
    function subscribeWithUtilityNFT(uint256 _pid, uint256 utilityNFTTokenId, uint256 _index, bytes32[] calldata _merkleProof) external nonReentrant {
        // join upcoming IDO
        require(_pid < poolInfo.length, "subscribeWithUtilityNFT: Invalid PID");

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        require(user.nftValue == 0, "subscribeWithUtilityNFT: already subscribed with utility nft");
        require(address(pool.fundRaisingToken) != address(0), "subscribeWithUtilityNFT: Utility NFTs cannot be used for native cryptocurrency fund raising");
        require(poolIdToTotalGuaranteedAllocationsSubscribed[_pid] < pool.maxUtilityNFTsValue, "subscribeWithUtilityNFT: Guaranteed allocations oversubscribed");

        require(block.timestamp >= pool.subscriptionStartTimestamp, "subscribe: subscription not started");
        require(block.timestamp <= pool.subscriptionEndTimestamp, "subscribe: subscription no longer permitted");

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(_index, msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRootKYC, node), 'subscribe: Invalid proof.');

        require(UtilityNFT(utilityNFT).ownerOf(utilityNFTTokenId) == msg.sender, 'subscribe: This utility NFT id is not yours');
        uint256 nftValue = UtilityNFT(utilityNFT).getAvailableAllocation(utilityNFTTokenId);
        uint256 availableValue = pool.maxUtilityNFTsValue.sub(poolIdToTotalGuaranteedAllocationsSubscribed[_pid]);

        // Add user to the pool
        user.nftValue = nftValue > pool.maxStakingAmountPerUser ? pool.maxStakingAmountPerUser : nftValue;

        if(user.nftValue > availableValue)
            user.nftValue = availableValue;

        user.utilityNFTTokenId = utilityNFTTokenId;

        // update poolIdToTotalGuaranteedAllocationsSubscribed
        poolIdToTotalGuaranteedAllocationsSubscribed[_pid] = poolIdToTotalGuaranteedAllocationsSubscribed[_pid].add(user.nftValue);

        emit SubscribeWithUtilityNFT(msg.sender, _pid, user.nftValue);
    }

    function getMaximumAllocation(uint256 _pid) public view returns (uint256) {
        require(_pid < poolInfo.length, "getFundingAmount: Invalid PID");
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo memory user = userInfo[_pid][msg.sender];

        // utility nft has got priority
        if(user.nftValue > 0)
            return user.nftValue;

        // subtrack the utility NFTs
        uint256 singleAllocation = pool.targetRaise.sub(poolIdToTotalGuaranteedAllocationsSubscribed[_pid]).div(poolIdToTotalMultipliers[_pid]);
        return singleAllocation * user.multiplier / 100;
    }

    // step 2
    function fundSubscription(uint256 _pid, uint256 _amount) external payable nonReentrant {
        require(_pid < poolInfo.length, "fundSubscription: Invalid PID");

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        require(user.multiplier > 0 || user.nftValue > 0, "fundSubscription: not subscribed");
        // require(user.fundingAmount == 0, "fundSubscription: Subscribe has already been funded");

        require(block.timestamp > pool.subscriptionEndTimestamp, "fundSubscription: Subscription is still taking place");
        require(block.timestamp <= pool.fundingEndTimestamp, "fundSubscription: Deadline has passed to fund your subscription");
        uint256 maximumAllocation = getMaximumAllocation(_pid);

        require(maximumAllocation > 0, "fundSubscription: must have positive allocation amount");

        uint256 userFundingTotalAmount = 0;
        // collecting the payment
        if(address(pool.fundRaisingToken) == address(0)){
            // ETH/BNB etc native cryptocurrency of the platform
            userFundingTotalAmount=user.fundingAmount.add(msg.value);
            // require(msg.value <= maximumAllocation, "fundSubscription: Too much value provided");
            require(userFundingTotalAmount <= maximumAllocation, "fundSubscription: Too much value provided");
            require(msg.value == _amount, "fundSubscription: Incorrect amounts");
            poolIdToTotalRaised[_pid] = poolIdToTotalRaised[_pid].add(msg.value);
            // user.fundingAmount = msg.value; // ensures pledges can only be done once
            user.fundingAmount = user.fundingAmount.add(msg.value); 
        }
        else {
            // this will fail if the sender does not have the right amount of the token or the allowance is not given
            userFundingTotalAmount=user.fundingAmount.add(msg.value);
            // require(_amount <= maximumAllocation, "fundSubscription: Too many tokens provided");
            require(userFundingTotalAmount <= maximumAllocation, "fundSubscription: Too many tokens provided");
            pool.fundRaisingToken.safeTransferFrom(msg.sender, address(this), _amount);
            user.fundingAmount = user.fundingAmount.add(_amount); // ensures pledges can only be done once
            poolIdToTotalRaised[_pid] = poolIdToTotalRaised[_pid].add(_amount);
            if(user.nftValue > 0){
                poolIdToTotalGuaranteedAllocationsRaised[_pid] = poolIdToTotalGuaranteedAllocationsRaised[_pid].add(_amount);
                UtilityNFT(utilityNFT).spendAllocation(user.utilityNFTTokenId, _amount);
            }
        }

        emit SubscriptionFunded(msg.sender, _pid, _amount);
    }

    // pre-step 3 for project
    function getTotalRaisedVsTarget(uint256 _pid) external view returns (uint256 raised, uint256 target) {
        return (poolIdToTotalRaised[_pid], poolInfo[_pid].targetRaise);
    }

    function getRequiredRewardAmountForAmountRaised(uint256 _pid) public view returns (uint256 rewardAmount) {
        PoolInfo memory pool = poolInfo[_pid];        
        return poolIdToTotalRaised[_pid].div(pool.price).mul(10**18);
    }

    // step 3
    function setupVestingRewards(uint256 _pid, uint256 _rewardAmount,  uint256 _rewardStartTimestamp, uint256 _rewardCliffEndTimestamp, uint256 _rewardEndTimestamp)
    external nonReentrant onlyOwner {
        require(_pid < poolInfo.length, "setupVestingRewards: Invalid PID");
        require(_rewardStartTimestamp > block.timestamp, "setupVestingRewards: start block in the past");
        require(_rewardCliffEndTimestamp >= _rewardStartTimestamp, "setupVestingRewards: Cliff must be after or equal to start time");
        require(_rewardEndTimestamp > _rewardCliffEndTimestamp, "setupVestingRewards: end time must be after cliff time");
        PoolInfo storage pool = poolInfo[_pid];

        require(block.timestamp > pool.fundingEndTimestamp, "setupVestingRewards: Users are still funding");
        require(_rewardAmount == getRequiredRewardAmountForAmountRaised(_pid), "setupVestingRewards: wrong reward amount provided");

        uint256 vestingLength = _rewardEndTimestamp.sub(_rewardStartTimestamp);

        pool.rewardsStartTime = _rewardStartTimestamp;
        pool.rewardsCliffEndTime = _rewardCliffEndTimestamp;
        pool.rewardsEndTime = _rewardEndTimestamp;

        pool.rewardToken.safeTransferFrom(msg.sender, address(rewardGuildBank), _rewardAmount);

        emit RewardsSetUp(_pid, _rewardAmount, _rewardStartTimestamp, _rewardCliffEndTimestamp, _rewardEndTimestamp);
    }

    function pendingRewards(uint256 _pid, address _user) public view returns (uint256) {
        require(_pid < poolInfo.length, "pendingRewards: invalid _pid");

        UserInfo memory user = userInfo[_pid][_user];

        // not funded have no rewards
        if (user.fundingAmount == 0) {
            return 0;
        }

        PoolInfo memory pool = poolInfo[_pid];

        if (pool.rewardsStartTime > block.timestamp){
            return 0;
        }

        uint256 vestingLength = pool.rewardsEndTime.sub(pool.rewardsStartTime);
        uint256 totalReward = getTotalReward(_pid, _user);
        uint256 rewardPerSecond = totalReward.div(vestingLength);
        uint256 totalUnlocked = block.timestamp.sub(pool.rewardsStartTime).mul(rewardPerSecond);

        return totalUnlocked.sub(user.collectedRewards);
    }

    function getTotalReward(uint256 _pid, address _user) public view returns (uint256) {
        require(_pid < poolInfo.length, "pendingRewards: invalid _pid");

        UserInfo memory user = userInfo[_pid][_user];

        // not funded have no rewards
        if (user.fundingAmount == 0) {
            return 0;
        }
        
        PoolInfo memory pool = poolInfo[_pid];
        return user.fundingAmount.div(pool.price).mul(10**18);
    }

    function claimReward(uint256 _pid) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        require(block.timestamp >= pool.rewardsCliffEndTime, "claimReward: Not past cliff");

        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.fundingAmount > 0, "claimReward: Not funded");

        uint256 pending = pendingRewards(_pid, msg.sender);

        if (pending > 0) {
            user.collectedRewards = user.collectedRewards.add(pending);
            safeRewardTransfer(pool.rewardToken, msg.sender, pending);

            emit RewardClaimed(msg.sender, _pid, pending);
        }
    }

    function claimFundRaising(uint256 _pid) external nonReentrant onlyOwner {
        require(_pid < poolInfo.length, "claimFundRaising: invalid _pid");
        PoolInfo storage pool = poolInfo[_pid];

        require(pool.rewardsStartTime != 0, "claimFundRaising: rewards not yet sent");
        require(poolIdToFundsClaimed[_pid] == false, "claimFundRaising: Already claimed funds");

        poolIdToFundsClaimed[_pid] = true;

        if(address(pool.fundRaisingToken) == address(0)){
            owner().call{value: poolIdToTotalRaised[_pid]}("");
            //owner.transfer(poolIdToTotalRaised[_pid]);
        }
        else {
            pool.fundRaisingToken.transfer(owner(), poolIdToTotalRaised[_pid]);
        }        

        emit FundRaisingClaimed(_pid, owner(), poolIdToTotalRaised[_pid]);
    }

    ////////////
    // Private /
    ////////////

    /// @dev Safe reward transfer function, just in case if rounding error causes pool to not have enough rewards.

    function safeRewardTransfer(IERC20 _rewardToken, address _to, uint256 _amount) private {
        uint256 bal = rewardGuildBank.tokenBalance(_rewardToken);
        if (_amount > bal) {
            rewardGuildBank.withdrawTo(_rewardToken, _to, bal);
        } else {
            rewardGuildBank.withdrawTo(_rewardToken, _to, _amount);
        }
    }

    /// @notice Return reward multiplier.
    /// @param _account account
    /// @return Multiplier
    function getMultiplier(address _account) private view returns (uint256) {
        // connect to the factory
        // loop through the pools and get the user score
        uint256 score;
        uint256 multiplier = 0;

        for(uint256 i = 0; i < stakingRewards.length; i++){
            score = score.add(IStakingRewards(stakingRewards[i]).getUserScore(_account));
        }

        // get the multiplier based on the score
        for (uint256 i = 0; i < multipliers.length - 1; i++){
            Multiplier memory mp = multipliers[i];
            if(score >= mp.scoreFrom){
                return mp.multiplier;
                break;
            }
        }

        return multiplier;
    }
}

interface UtilityNFT {
    function getAvailableAllocation(uint256 id) external view returns (uint256);
    function spendAllocation(uint256 id, uint256 amount) external;
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

pragma solidity >=0.6.6;


interface IStakingRewards {
    // Views
    function lastTimeRewardApplicable() external view returns (uint256);

    function rewardPerToken() external view returns (uint256);

    function earned(address account) external view returns (uint256);

    function getRewardForDuration() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    // Mutative

    function stake(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function getReward() external;

    function exit() external;

    function getUserScore(address account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

contract FundRaisingGuild {
    using SafeERC20 for IERC20;

    address public stakingContract;

    constructor(address _stakingContract) public {
        stakingContract = _stakingContract;
    }

    function withdrawTo(IERC20 _token, address _recipient, uint256 _amount) external {
        require(msg.sender == stakingContract, "Guild.withdrawTo: Only staking contract");
        _token.safeTransfer(_recipient, _amount);
    }

    function tokenBalance(IERC20 _token) external returns (uint256) {
        return _token.balanceOf(address(this));
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
 * @dev These functions deal with verification of Merkle trees (hash trees),
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
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