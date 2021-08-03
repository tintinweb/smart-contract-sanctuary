//SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "./interfaces/IStakingFactory.sol";
import "./StakingRewards.sol";
import "./interfaces/IStakingRewards.sol";

/// @title StakingFactory, A contract where users can create their own staking pool
contract StakingFactory is IStakingFactory {
    address[] private allPools;
    mapping(address => bool) private isOurs;

    /**
     * @notice Caller creates a new StakingRewards pool and it gets added to this factory
     * @param _stakingToken token address that needs to be staked to earn rewards
     * @param _startBlock block number when rewards start
     * @param _endBlock block number when rewards end
     * @param _bufferBlocks no. of blocks after which owner can reclaim any unclaimed rewards
     * @return listaddr address of newly created contract
     */
    function createPool(
        address _stakingToken,
        uint256 _startBlock,
        uint256 _endBlock,
        uint256 _bufferBlocks
    ) external override returns (address listaddr) {
        listaddr = address(
            new StakingRewards(
                _stakingToken,
                _startBlock,
                _endBlock,
                _bufferBlocks
            )
        );

        StakingRewards(listaddr).transferOwnership(msg.sender);

        allPools.push(listaddr);
        isOurs[listaddr] = true;

        emit PoolCreated(msg.sender, listaddr);
    }

    /**
     * @notice Checks if a address belongs to this contract' pools
     */
    function ours(address _a) external view override returns (bool) {
        return isOurs[_a];
    }

    /**
     * @notice Returns no. of pools stored in contract
     */
    function listCount() external view override returns (uint256) {
        return allPools.length;
    }

    /**
     * @notice Returns address of the pool located at given id
     */
    function listAt(uint256 _idx) external view override returns (address) {
        require(_idx < allPools.length, "Index exceeds list length");
        return allPools[_idx];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

interface IStakingFactory {
    event PoolCreated(address indexed sender, address indexed newPool);

    function createPool(
        address _stakingToken,
        uint256 _startBlock,
        uint256 _endBlock,
        uint256 _bufferBlocks
    ) external returns (address);

    function ours(address _a) external view returns (bool);

    function listCount() external view returns (uint256);

    function listAt(uint256 _idx) external view returns (address);
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./interfaces/IStakingRewards.sol";

/// @title StakingRewards, A contract where users can stake a token X "stakingToken" and get Y..X..Z as rewards
/// @notice Based on https://github.com/sushiswap/sushiswap/blob/master/contracts/MasterChef.sol but better
contract StakingRewards is Ownable, ReentrancyGuard, IStakingRewards {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    modifier notStopped {
        require(!isStopped, "Rewards have stopped");
        _;
    }

    modifier onlyRewardsPeriod {
        require(block.number < endBlock, "Rewards period ended");
        _;
    }

    struct RewardInfo {
        IERC20 rewardToken;
        uint256 lastRewardBlock; // Last block number that reward token distribution occurs.
        uint256 rewardPerBlock; // How many reward tokens to distribute per block.
        uint256 totalRewards;
        uint256 accTokenPerShare; // Accumulated token per share, times 1e18.
    }
    RewardInfo[] private rewardInfo;

    IERC20 public immutable stakingToken; // token to be staked for rewards

    uint256 public immutable startBlock; // block number when reward period starts
    uint256 public endBlock; // block number when reward period ends

    // how many blocks to wait after owner can reclaim unclaimed tokens
    uint256 public immutable bufferBlocks;

    // indicates that rewards have stopped forever and can't be extended anymore
    // also means that owner recovered all unclaimed rewards after a certain amount of bufferBlocks has passed
    // new users won't be able to deposit and everyone left can withdraw his/her stake
    bool public isStopped;

    mapping(address => uint256) private userAmount;
    mapping(uint256 => mapping(address => uint256)) private rewardDebt; // rewardDebt[rewardId][user] = N
    mapping(uint256 => mapping(address => uint256)) private rewardPaid; // rewardPaid[rewardId][user] = N

    EnumerableSet.AddressSet private pooledTokens;

    uint8 private constant MAX_POOLED_TOKENS = 5;

    constructor(
        address _stakingToken,
        uint256 _startBlock,
        uint256 _endBlock,
        uint256 _bufferBlocks
    ) {
        _startBlock = (_startBlock == 0) ? block.number : _startBlock;

        require(
            _endBlock > block.number && _endBlock > _startBlock,
            "Invalid end block"
        );

        stakingToken = IERC20(_stakingToken);
        startBlock = _startBlock;
        endBlock = _endBlock;
        bufferBlocks = _bufferBlocks;
    }

    /**
     * @notice Caller deposits the staking token to start earning rewards
     * @param _amount amount of staking token to deposit
     */
    function deposit(uint256 _amount)
        external
        override
        notStopped
        nonReentrant
    {
        updateAllRewards();

        uint256 _currentAmount = userAmount[msg.sender];
        uint256 _balanceBefore = stakingToken.balanceOf(address(this));

        stakingToken.safeTransferFrom(msg.sender, address(this), _amount);

        _amount = stakingToken.balanceOf(address(this)) - _balanceBefore;

        uint256 _newUserAmount = _currentAmount + _amount;

        if (_currentAmount > 0) {
            for (uint256 i = 0; i < rewardInfo.length; i++) {
                RewardInfo memory _reward = rewardInfo[i];

                uint256 _pending =
                    ((_currentAmount * _reward.accTokenPerShare) / 1e18) -
                        rewardDebt[i][msg.sender];

                rewardDebt[i][msg.sender] =
                    (_newUserAmount * _reward.accTokenPerShare) /
                    1e18;

                rewardPaid[i][msg.sender] += _pending;

                _reward.rewardToken.safeTransfer(msg.sender, _pending);
            }
        } else {
            for (uint256 i = 0; i < rewardInfo.length; i++) {
                RewardInfo memory _reward = rewardInfo[i];

                rewardDebt[i][msg.sender] =
                    (_amount * _reward.accTokenPerShare) /
                    1e18;
            }
        }

        userAmount[msg.sender] = _newUserAmount;

        emit Deposit(msg.sender, _amount);
    }

    /**
     * @notice Caller withdraws the staking token and its pending rewards, if any
     * @param _amount amount of staking token to withdraw
     */
    function withdraw(uint256 _amount) external override nonReentrant {
        updateAllRewards();

        uint256 _currentAmount = userAmount[msg.sender];

        require(_currentAmount >= _amount, "withdraw: not good");

        uint256 newUserAmount = _currentAmount - _amount;

        if (!isStopped) {
            for (uint256 i = 0; i < rewardInfo.length; i++) {
                RewardInfo memory _reward = rewardInfo[i];

                uint256 _pending =
                    ((_currentAmount * _reward.accTokenPerShare) / 1e18) -
                        rewardDebt[i][msg.sender];

                rewardDebt[i][msg.sender] =
                    (newUserAmount * _reward.accTokenPerShare) /
                    1e18;

                rewardPaid[i][msg.sender] += _pending;

                _reward.rewardToken.safeTransfer(msg.sender, _pending);
            }
        }

        userAmount[msg.sender] = newUserAmount;

        stakingToken.safeTransfer(msg.sender, _amount);

        emit Withdraw(msg.sender, _amount);
    }

    /**
     * @notice Caller withdraws tokens staked by user without caring about rewards
     */
    function emergencyWithdraw() external override nonReentrant {
        for (uint256 i = 0; i < rewardInfo.length; i++) {
            rewardDebt[i][msg.sender] = 0;
        }

        stakingToken.safeTransfer(msg.sender, userAmount[msg.sender]);
        userAmount[msg.sender] = 0;
        emit EmergencyWithdraw(msg.sender, userAmount[msg.sender]);
    }

    /**
     * @notice Caller claims its pending rewards without having to withdraw its stake
     */
    function claimRewards() external override notStopped nonReentrant {
        for (uint256 i = 0; i < rewardInfo.length; i++) _claimReward(i);
    }

    /**
     * @notice Caller claims a single pending reward without having to withdraw its stake
     * @dev _rid is the index of rewardInfo array
     * @param _rid reward id
     */
    function claimReward(uint256 _rid)
        external
        override
        notStopped
        nonReentrant
    {
        _claimReward(_rid);
    }

    /**
     * @notice Adds a reward token to the pool, only contract owner can call this
     * @param _rewardToken address of the ERC20 token
     * @param _totalRewards amount of total rewards to distribute from startBlock to endBlock
     */
    function add(IERC20 _rewardToken, uint256 _totalRewards)
        external
        override
        nonReentrant
        onlyOwner
        onlyRewardsPeriod
    {
        require(rewardInfo.length < MAX_POOLED_TOKENS, "Pool is full");
        _add(_rewardToken, _totalRewards);
    }

    /**
     * @notice Adds multiple reward tokens to the pool in a single call, only contract owner can call this
     * @param _rewardSettings array of struct composed of "IERC20 rewardToken" and "uint256 totalRewards"
     */
    function addMulti(RewardSettings[] memory _rewardSettings)
        external
        override
        nonReentrant
        onlyOwner
        onlyRewardsPeriod
    {
        require(
            rewardInfo.length + _rewardSettings.length < MAX_POOLED_TOKENS,
            "Pool is full"
        );
        for (uint8 i = 0; i < _rewardSettings.length; i++)
            _add(
                _rewardSettings[i].rewardToken,
                _rewardSettings[i].totalRewards
            );
    }

    /**
     * @notice Owner can recover any ERC20 that's not the staking token neither a pooledToken
     * @param _tokenAddress address of the ERC20 mistakenly sent to this contract
     * @param _tokenAmount amount to recover
     */
    function recoverERC20(address _tokenAddress, uint256 _tokenAmount)
        external
        override
        onlyOwner
    {
        require(
            _tokenAddress != address(stakingToken) &&
                !pooledTokens.contains(_tokenAddress),
            "Cannot recover"
        );
        IERC20(_tokenAddress).safeTransfer(msg.sender, _tokenAmount);
        emit Recovered(_tokenAddress, _tokenAmount);
    }

    /**
     * @notice Owner can recover rewards that's not been claimed after endBlock + bufferBlocks
     * @dev Warning: it will set isStopped to true, so no more deposits, extensions or rewards claim but only withdrawals
     */
    function recoverUnclaimedRewards() external override onlyOwner notStopped {
        require(
            block.number > endBlock + bufferBlocks,
            "Not allowed to reclaim"
        );
        isStopped = true;
        for (uint8 i = 0; i < rewardInfo.length; i++) {
            IERC20 _token = IERC20(rewardInfo[i].rewardToken);
            uint256 _amount = _token.balanceOf(address(this));
            rewardInfo[i].lastRewardBlock = block.number;
            _token.safeTransfer(msg.sender, _amount);
            emit UnclaimedRecovered(address(_token), _amount);
        }
    }

    /**
     * @notice After a reward period has ended owner can decide to extend it by adding more rewards
     * @dev totalRewards will be distributed from block.number to newEndBlock
     * @param _newEndBlock block number when new rewards end
     * @param _newTotalRewards array of new total rewards for each pooled token
     */
    function extendRewards(
        uint256 _newEndBlock,
        uint256[] memory _newTotalRewards
    ) external override onlyOwner notStopped nonReentrant {
        require(block.number > endBlock, "Rewards not ended");
        require(_newEndBlock > block.number, "Invalid end block");
        require(
            _newTotalRewards.length == rewardInfo.length,
            "Pool length mismatch"
        );

        for (uint8 i = 0; i < _newTotalRewards.length; i++) {
            updateReward(i);
            uint256 _balanceBefore =
                IERC20(rewardInfo[i].rewardToken).balanceOf(address(this));
            IERC20(rewardInfo[i].rewardToken).safeTransferFrom(
                msg.sender,
                address(this),
                _newTotalRewards[i]
            );
            _newTotalRewards[i] =
                IERC20(rewardInfo[i].rewardToken).balanceOf(address(this)) -
                _balanceBefore;
            uint256 _rewardPerBlock =
                _newTotalRewards[i] / (_newEndBlock - block.number);
            rewardInfo[i].rewardPerBlock = _rewardPerBlock;
            rewardInfo[i].totalRewards += _newTotalRewards[i];
        }

        endBlock = _newEndBlock;

        emit RewardsExtended(_newEndBlock);
    }

    /**
     * @notice Gets the number of pooled reward tokens in contract
     */
    function rewardsLength() external view override returns (uint256) {
        return rewardInfo.length;
    }

    /**
     * @notice Gets the amount of staked tokens for a given user
     * @param _user address of given user
     */
    function balanceOf(address _user) external view override returns (uint256) {
        return userAmount[_user];
    }

    /**
     * @notice Gets the total amount of staked tokens in contract
     */
    function totalSupply() external view override returns (uint256) {
        return stakingToken.balanceOf(address(this));
    }

    /**
     * @notice Caller can see pending rewards for a given reward id and user
     * @dev _rid is the index of rewardInfo array
     * @param _rid reward id
     * @param _user address of a user
     * @return amount of pending rewards
     */
    function getPendingRewards(uint256 _rid, address _user)
        external
        view
        override
        returns (uint256)
    {
        return _getPendingRewards(_rid, _user);
    }

    /**
     * @notice Caller can see pending rewards for a given user
     * @param _user address of a user
     * @return array of struct containing rewardToken and pendingReward
     */
    function getAllPendingRewards(address _user)
        external
        view
        override
        returns (PendingRewards[] memory)
    {
        PendingRewards[] memory _pendingRewards =
            new PendingRewards[](rewardInfo.length);
        for (uint8 i = 0; i < rewardInfo.length; i++) {
            _pendingRewards[i] = PendingRewards({
                rewardToken: rewardInfo[i].rewardToken,
                pendingReward: _getPendingRewards(i, _user)
            });
        }
        return _pendingRewards;
    }

    /**
     * @notice Caller can see pending rewards for a given user
     * @param _user address of a user
     * @return array of struct containing rewardToken and pendingReward
     */
    function earned(address _user)
        external
        view
        override
        returns (EarnedRewards[] memory)
    {
        EarnedRewards[] memory earnedRewards =
            new EarnedRewards[](rewardInfo.length);
        for (uint8 i = 0; i < rewardInfo.length; i++) {
            earnedRewards[i] = EarnedRewards({
                rewardToken: rewardInfo[i].rewardToken,
                earnedReward: rewardPaid[i][_user] +
                    _getPendingRewards(i, _user)
            });
        }
        return earnedRewards;
    }

    /**
     * @notice Caller can see total rewards for every pooled token
     * @return array of struct containing rewardToken and totalRewards
     */
    function getRewardsForDuration()
        external
        view
        override
        returns (RewardSettings[] memory)
    {
        RewardSettings[] memory _rewardSettings =
            new RewardSettings[](rewardInfo.length);
        for (uint8 i = 0; i < rewardInfo.length; i++) {
            _rewardSettings[i] = RewardSettings({
                rewardToken: rewardInfo[i].rewardToken,
                totalRewards: rewardInfo[i].totalRewards
            });
        }
        return _rewardSettings;
    }

    /**
     * @notice Update reward variables of the given pool to be up-to-date.
     * @dev _rid is the index of rewardInfo array
     * @param _rid reward id
     */
    function updateReward(uint256 _rid) public {
        RewardInfo storage _reward = rewardInfo[_rid];

        if (block.number <= _reward.lastRewardBlock) {
            return;
        }
        uint256 _lpSupply = stakingToken.balanceOf(address(this));

        if (_lpSupply == 0) {
            _reward.lastRewardBlock = block.number;
            return;
        }

        uint256 _tokenReward = getMultiplier(_reward) * _reward.rewardPerBlock;

        _reward.accTokenPerShare += (_tokenReward * 1e18) / _lpSupply;

        _reward.lastRewardBlock = block.number;
    }

    /**
     * @notice Mass updates reward variables
     */
    function updateAllRewards() public {
        uint256 _length = rewardInfo.length;
        for (uint256 pid = 0; pid < _length; pid++) {
            updateReward(pid);
        }
    }

    /**
     * @notice Gets the correct multiplier of rewardPerBlock for a given RewardInfo
     */
    function getMultiplier(RewardInfo memory _reward)
        internal
        view
        returns (uint256 _multiplier)
    {
        uint256 _lastBlock =
            (block.number > endBlock) ? endBlock : block.number;
        _multiplier = (_lastBlock > _reward.lastRewardBlock)
            ? _lastBlock - _reward.lastRewardBlock
            : 0;
    }

    /**
     * @notice Pending rewards for a given reward id and user
     * @dev _rid is the index of rewardInfo array
     * @param _rid reward id
     * @param _user address of a user
     * @return amount of pending rewards
     */
    function _getPendingRewards(uint256 _rid, address _user)
        internal
        view
        returns (uint256)
    {
        if (isStopped) return 0;

        RewardInfo storage _reward = rewardInfo[_rid];

        uint256 _amount = userAmount[_user];
        uint256 _debt = rewardDebt[_rid][_user];

        uint256 _rewardPerBlock = _reward.rewardPerBlock;

        uint256 _accTokenPerShare = _reward.accTokenPerShare;

        uint256 _lpSupply = stakingToken.balanceOf(address(this));

        if (block.number > _reward.lastRewardBlock && _lpSupply != 0) {
            uint256 reward = getMultiplier(_reward) * _rewardPerBlock;
            _accTokenPerShare += ((reward * 1e18) / _lpSupply);
        }

        return ((_amount * _accTokenPerShare) / 1e18) - _debt;
    }

    /**
     * @notice Adds a reward token to the rewards pool
     * @param _rewardToken address of the ERC20 token
     * @param _totalRewards amount of total rewards to distribute from startBlock to endBlock
     */
    function _add(IERC20 _rewardToken, uint256 _totalRewards) internal {
        require(
            address(_rewardToken) != address(stakingToken),
            "rewardToken = stakingToken"
        );
        require(!pooledTokens.contains(address(_rewardToken)), "pool exists");

        uint256 _balanceBefore = _rewardToken.balanceOf(address(this));
        _rewardToken.safeTransferFrom(msg.sender, address(this), _totalRewards);
        _totalRewards = _rewardToken.balanceOf(address(this)) - _balanceBefore;

        require(_totalRewards != 0, "No rewards");

        uint256 _lastRewardBlock =
            block.number > startBlock ? block.number : startBlock;

        pooledTokens.add(address(_rewardToken));

        uint256 _rewardPerBlock = _totalRewards / (endBlock - _lastRewardBlock);

        rewardInfo.push(
            RewardInfo({
                rewardToken: _rewardToken,
                rewardPerBlock: _rewardPerBlock,
                totalRewards: _totalRewards,
                lastRewardBlock: _lastRewardBlock,
                accTokenPerShare: 0
            })
        );
    }

    /**
     * @notice Caller claims a single pending reward without having to withdraw its stake
     * @dev _rid is the index of rewardInfo array
     * @param _rid reward id
     */
    function _claimReward(uint256 _rid) internal {
        updateReward(_rid);

        uint256 _amount = userAmount[msg.sender];

        uint256 _debt = rewardDebt[_rid][msg.sender];

        RewardInfo memory _reward = rewardInfo[_rid];

        uint256 pending = ((_amount * _reward.accTokenPerShare) / 1e18) - _debt;

        rewardPaid[_rid][msg.sender] += pending;

        rewardDebt[_rid][msg.sender] =
            (_amount * _reward.accTokenPerShare) /
            1e18;

        _reward.rewardToken.safeTransfer(msg.sender, pending);
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

struct RewardSettings {
    IERC20 rewardToken;
    uint256 totalRewards;
}

struct PendingRewards {
    IERC20 rewardToken;
    uint256 pendingReward;
}

struct EarnedRewards {
    IERC20 rewardToken;
    uint256 earnedReward;
}

interface IStakingRewards {
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    event Recovered(address token, uint256 amount);
    event UnclaimedRecovered(address token, uint256 amount);
    event RewardsExtended(uint256 newEndBlock);

    function deposit(uint256 _amount) external;

    function withdraw(uint256 _amount) external;

    function emergencyWithdraw() external;

    function claimRewards() external;

    function claimReward(uint256 _rid) external;

    function add(IERC20 _rewardToken, uint256 _totalRewards) external;

    function addMulti(RewardSettings[] memory _poolSettings) external;

    function recoverERC20(address _tokenAddress, uint256 _tokenAmount) external;

    function recoverUnclaimedRewards() external;

    function extendRewards(
        uint256 _newEndBlock,
        uint256[] memory _newTotalRewards
    ) external;

    function rewardsLength() external view returns (uint256);

    function balanceOf(address _user) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function getPendingRewards(uint256 _rid, address _user)
        external
        view
        returns (uint256);

    function getAllPendingRewards(address _user)
        external
        view
        returns (PendingRewards[] memory);

    function getRewardsForDuration()
        external
        view
        returns (RewardSettings[] memory);

    function earned(address _user)
        external
        view
        returns (EarnedRewards[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
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

pragma solidity ^0.8.0;

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
    constructor () {
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

pragma solidity ^0.8.0;

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

    constructor () {
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

pragma solidity ^0.8.0;

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
            set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex

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

pragma solidity ^0.8.0;

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

pragma solidity ^0.8.0;

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

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 1000
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
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}