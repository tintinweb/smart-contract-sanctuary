/**
 *Submitted for verification at moonbeam.moonscan.io on 2022-03-10
*/

// Sources flattened with hardhat v2.7.1 https://hardhat.org

// File @openzeppelin/contracts/security/[email protected]

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

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

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
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


// File @openzeppelin/contracts/utils/[email protected]


// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
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
        return msg.data;
    }
}


// File @openzeppelin/contracts/access/[email protected]


// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

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
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// File contracts/yield-farm/libraries/IBoringERC20.sol


pragma solidity 0.8.11;

interface IBoringERC20 {
    function mint(address to, uint256 amount) external;

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    /// @notice EIP 2612
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}


// File contracts/yield-farm/libraries/BoringERC20.sol


pragma solidity 0.8.11;

// solhint-disable avoid-low-level-calls
library BoringERC20 {
    bytes4 private constant SIG_SYMBOL = 0x95d89b41; // symbol()
    bytes4 private constant SIG_NAME = 0x06fdde03; // name()
    bytes4 private constant SIG_DECIMALS = 0x313ce567; // decimals()
    bytes4 private constant SIG_TRANSFER = 0xa9059cbb; // transfer(address,uint256)
    bytes4 private constant SIG_TRANSFER_FROM = 0x23b872dd; // transferFrom(address,address,uint256)

    function returnDataToString(bytes memory data)
        internal
        pure
        returns (string memory)
    {
        if (data.length >= 64) {
            return abi.decode(data, (string));
        } else if (data.length == 32) {
            uint8 i = 0;
            while (i < 32 && data[i] != 0) {
                i++;
            }
            bytes memory bytesArray = new bytes(i);
            for (i = 0; i < 32 && data[i] != 0; i++) {
                bytesArray[i] = data[i];
            }
            return string(bytesArray);
        } else {
            return "???";
        }
    }

    /// @notice Provides a safe ERC20.symbol version which returns '???' as fallback string.
    /// @param token The address of the ERC-20 token contract.
    /// @return (string) Token symbol.
    function safeSymbol(IBoringERC20 token)
        internal
        view
        returns (string memory)
    {
        (bool success, bytes memory data) = address(token).staticcall(
            abi.encodeWithSelector(SIG_SYMBOL)
        );
        return success ? returnDataToString(data) : "???";
    }

    /// @notice Provides a safe ERC20.name version which returns '???' as fallback string.
    /// @param token The address of the ERC-20 token contract.
    /// @return (string) Token name.
    function safeName(IBoringERC20 token)
        internal
        view
        returns (string memory)
    {
        (bool success, bytes memory data) = address(token).staticcall(
            abi.encodeWithSelector(SIG_NAME)
        );
        return success ? returnDataToString(data) : "???";
    }

    /// @notice Provides a safe ERC20.decimals version which returns '18' as fallback value.
    /// @param token The address of the ERC-20 token contract.
    /// @return (uint8) Token decimals.
    function safeDecimals(IBoringERC20 token) internal view returns (uint8) {
        (bool success, bytes memory data) = address(token).staticcall(
            abi.encodeWithSelector(SIG_DECIMALS)
        );
        return success && data.length == 32 ? abi.decode(data, (uint8)) : 18;
    }

    /// @notice Provides a safe ERC20.transfer version for different ERC-20 implementations.
    /// Reverts on a failed transfer.
    /// @param token The address of the ERC-20 token.
    /// @param to Transfer tokens to.
    /// @param amount The token amount.
    function safeTransfer(
        IBoringERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(SIG_TRANSFER, to, amount)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "BoringERC20: Transfer failed"
        );
    }

    /// @notice Provides a safe ERC20.transferFrom version for different ERC-20 implementations.
    /// Reverts on a failed transfer.
    /// @param token The address of the ERC-20 token.
    /// @param from Transfer tokens from.
    /// @param to Transfer tokens to.
    /// @param amount The token amount.
    function safeTransferFrom(
        IBoringERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(SIG_TRANSFER_FROM, from, to, amount)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "BoringERC20: TransferFrom failed"
        );
    }
}


// File contracts/sharefarm/ShareFarm.sol


pragma solidity 0.8.11;
contract ShareFarm is Ownable, ReentrancyGuard {
    using BoringERC20 for IBoringERC20;

    // Info of each user for each farm.
    struct UserInfo {
        uint256 amount; // How many Staking tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
    }

    // each beamshare stake pool info
    struct StakeInfo {
        IBoringERC20 stakingToken; // Address of Staking token contract.
        IBoringERC20 rewardToken; // Address of Reward token contract
        uint256 precision; //reward token precision
        uint256 startTimestamp; // start timestamp of the stakeinfo
        uint256 lastRewardTimestamp; // Last timestamp that Reward Token distribution occurs.
        uint256 accRewardPerShare; // Accumulated Reward Token per share. See below.
        uint256 totalStaked; // total staked amount each stakeinfo's stake token, typically, each stakeinfo has the same stake token, so need to track it separatedly
        uint256 totalRewards;
    }

    // Reward info
    struct RewardInfo {
        uint256 endTimestamp;
        uint256 rewardPerSec;
    }

    /// @dev this is mostly used for extending reward period
    /// @notice Reward info is a set of {endTimestamp, rewardPerTimestamp}
    mapping(uint256 => RewardInfo[]) public stakeinfoRewardInfo;

    /// @notice Info of each stakeinfo. mapped from stake info id
    StakeInfo[] public stakeInfo;
    /// @notice Info of each user that stakes Staking tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    /// @notice limit length of reward info
    uint256 public rewardInfoLimit;

    /// @dev reward holder account
    address public rewardHolder;

    event Deposit(address indexed user, uint256 amount, uint256 stakeinfo);
    event Withdraw(address indexed user, uint256 amount, uint256 stakeinfo);
    event EmergencyWithdraw(
        address indexed user,
        uint256 amount,
        uint256 stakeinfo
    );
    event AddStakeInfo(
        uint256 indexed stakeinfoID,
        IBoringERC20 stakingToken,
        IBoringERC20 rewardToken,
        uint256 startTimestamp
    );
    event AddRewardInfo(
        uint256 indexed stakeinfoID,
        uint256 indexed phase,
        uint256 endTimestamp,
        uint256 rewardPerTimestamp
    );
    event SetRewardInfoLimit(uint256 rewardInfoLimit);
    event SetRewardHolder(address rewardHolder);

    constructor() {
        rewardInfoLimit = 69;
        rewardHolder = msg.sender;
    }

    /// @notice function for setting a reward holder who is responsible for adding a reward info
    function setRewardHolder(address _rewardHolder) external onlyOwner {
        rewardHolder = _rewardHolder;
        emit SetRewardHolder(_rewardHolder);
    }

    /// @notice set new reward info limit
    function setRewardInfoLimit(uint256 _updatedRewardInfoLimit)
        external
        onlyOwner
    {
        rewardInfoLimit = _updatedRewardInfoLimit;
        emit SetRewardInfoLimit(rewardInfoLimit);
    }

    /// @notice adds stake info, one stake info represents a pair of staking and reward token, last reward Timestamp and acc reward Per Share
    function addStakeInfo(
        IBoringERC20 _stakingToken,
        IBoringERC20 _rewardToken,
        uint256 _startTimestamp
    ) external onlyOwner {
        uint256 decimalsRewardToken = uint256(_rewardToken.safeDecimals());

        require(
            decimalsRewardToken < 30,
            "constructor: reward token decimals must be inferior to 30"
        );

        uint256 precision = uint256(10**(uint256(30) - (decimalsRewardToken)));

        stakeInfo.push(
            StakeInfo({
                stakingToken: _stakingToken,
                rewardToken: _rewardToken,
                precision: precision,
                startTimestamp: _startTimestamp,
                lastRewardTimestamp: _startTimestamp,
                accRewardPerShare: 0,
                totalStaked: 0,
                totalRewards: 0
            })
        );
        emit AddStakeInfo(
            stakeInfo.length - 1,
            _stakingToken,
            _rewardToken,
            _startTimestamp
        );
    }

    /// @notice if the new reward info is added, the reward & its end timestamp will be extended by the newly pushed reward info.
    function addRewardInfo(
        uint256 _stakeID,
        uint256 _endTimestamp,
        uint256 _rewardPerSec
    ) external onlyOwner {
        RewardInfo[] storage rewardInfo = stakeinfoRewardInfo[_stakeID];
        StakeInfo storage stakeinfo = stakeInfo[_stakeID];
        require(
            rewardInfo.length < rewardInfoLimit,
            "addRewardInfo::reward info length exceeds the limit"
        );
        require(
            rewardInfo.length == 0 ||
                rewardInfo[rewardInfo.length - 1].endTimestamp >=
                block.timestamp,
            "addRewardInfo::reward period ended"
        );
        require(
            rewardInfo.length == 0 ||
                rewardInfo[rewardInfo.length - 1].endTimestamp < _endTimestamp,
            "addRewardInfo::bad new endTimestamp"
        );
        uint256 startTimestamp = rewardInfo.length == 0
            ? stakeinfo.startTimestamp
            : rewardInfo[rewardInfo.length - 1].endTimestamp;
        uint256 timeRange = _endTimestamp - startTimestamp;
        uint256 totalRewards = _rewardPerSec * timeRange;
        stakeinfo.rewardToken.safeTransferFrom(
            rewardHolder,
            address(this),
            totalRewards
        );
        stakeinfo.totalRewards += totalRewards;
        rewardInfo.push(
            RewardInfo({
                endTimestamp: _endTimestamp,
                rewardPerSec: _rewardPerSec
            })
        );
        emit AddRewardInfo(
            _stakeID,
            rewardInfo.length - 1,
            _endTimestamp,
            _rewardPerSec
        );
    }

    function rewardInfoLen(uint256 _stakeID)
        external
        view
        returns (uint256)
    {
        return stakeinfoRewardInfo[_stakeID].length;
    }

    function stakeInfoLen() external view returns (uint256) {
        return stakeInfo.length;
    }

    // @notice this will return  end block based on the current block timestamp.
    function currentEndTimestamp(uint256 _stakeID)
        external
        view
        returns (uint256)
    {
        return _endTimestampOf(_stakeID, block.timestamp);
    }

    function _endTimestampOf(uint256 _stakeID, uint256 _blockTimestamp)
        internal
        view
        returns (uint256)
    {
        RewardInfo[] memory rewardInfo = stakeinfoRewardInfo[_stakeID];
        uint256 len = rewardInfo.length;
        if (len == 0) {
            return 0;
        }
        for (uint256 i = 0; i < len; ++i) {
            if (_blockTimestamp <= rewardInfo[i].endTimestamp)
                return rewardInfo[i].endTimestamp;
        }
        // @dev when couldn't find any reward info, it means that _blockTimestamp exceed endTimestamp
        // so return the latest reward info.
        return rewardInfo[len - 1].endTimestamp;
    }

    // @notice this will return reward per block based on the current block timestamp.
    function currentRewardPerSec(uint256 _stakeID)
        external
        view
        returns (uint256)
    {
        return _rewardPerSecOf(_stakeID, block.timestamp);
    }

    function _rewardPerSecOf(uint256 _stakeID, uint256 _blockTimestamp)
        internal
        view
        returns (uint256)
    {
        RewardInfo[] memory rewardInfo = stakeinfoRewardInfo[_stakeID];
        uint256 len = rewardInfo.length;
        if (len == 0) {
            return 0;
        }
        for (uint256 i = 0; i < len; ++i) {
            if (_blockTimestamp <= rewardInfo[i].endTimestamp)
                return rewardInfo[i].rewardPerSec;
        }
        // @dev when couldn't find any reward info, it means that timestamp exceed endtimestamp
        // so return 0
        return 0;
    }

    // @notice Return reward multiplier over the given _from to _to timestamp.
    function getMultiplier(
        uint256 _from,
        uint256 _to,
        uint256 _endTimestamp
    ) public pure returns (uint256) {
        if ((_from >= _endTimestamp) || (_from > _to)) {
            return 0;
        }
        if (_to <= _endTimestamp) {
            return _to - _from;
        }
        return _endTimestamp - _from;
    }

    // @notice View function to see pending Reward on frontend.
    function pendingReward(uint256 _stakeID, address _user)
        external
        view
        returns (uint256)
    {
        return
            _pendingReward(
                _stakeID,
                userInfo[_stakeID][_user].amount,
                userInfo[_stakeID][_user].rewardDebt
            );
    }

    function _pendingReward(
        uint256 _stakeID,
        uint256 _amount,
        uint256 _rewardDebt
    ) internal view returns (uint256) {
        StakeInfo memory stakeinfo = stakeInfo[_stakeID];
        RewardInfo[] memory rewardInfo = stakeinfoRewardInfo[_stakeID];
        uint256 accRewardPerShare = stakeinfo.accRewardPerShare;
        if (
            block.timestamp > stakeinfo.lastRewardTimestamp &&
            stakeinfo.totalStaked != 0
        ) {
            uint256 cursor = stakeinfo.lastRewardTimestamp;
            for (uint256 i = 0; i < rewardInfo.length; ++i) {
                uint256 multiplier = getMultiplier(
                    cursor,
                    block.timestamp,
                    rewardInfo[i].endTimestamp
                );
                if (multiplier == 0) continue;
                cursor = rewardInfo[i].endTimestamp;
                accRewardPerShare +=
                    ((multiplier * rewardInfo[i].rewardPerSec) *
                        stakeinfo.precision) /
                    stakeinfo.totalStaked;
            }
        }
        return
            ((_amount * accRewardPerShare) / stakeinfo.precision) - _rewardDebt;
    }

    function updateStakeInfo(uint256 _stakeID) external nonReentrant {
        _updateStakeInfo(_stakeID);
    }

    /// @notice Update reward variables of the given stakeinfo to be up-to-date.
    function _updateStakeInfo(uint256 _stakeID) internal {
        StakeInfo storage stakeinfo = stakeInfo[_stakeID];
        RewardInfo[] memory rewardInfo = stakeinfoRewardInfo[_stakeID];
        if (block.timestamp <= stakeinfo.lastRewardTimestamp) {
            return;
        }
        if (stakeinfo.totalStaked == 0) {
            // if there is no total supply, return and use the stakeinfo's start block timestamp as the last reward block timestamp
            // so that ALL reward will be distributed.
            // however, if the first deposit is out of reward period, last reward block will be its block timestamp
            // in order to keep the multiplier = 0
            if (
                block.timestamp > _endTimestampOf(_stakeID, block.timestamp)
            ) {
                stakeinfo.lastRewardTimestamp = block.timestamp;
            }
            return;
        }
        // @dev for each reward info
        for (uint256 i = 0; i < rewardInfo.length; ++i) {
            // @dev get multiplier based on current Block and rewardInfo's end block
            // multiplier will be a range of either (current block - stakeinfo.lastRewardBlock)
            // or (reward info's endblock - stakeinfo.lastRewardTimestamp) or 0
            uint256 multiplier = getMultiplier(
                stakeinfo.lastRewardTimestamp,
                block.timestamp,
                rewardInfo[i].endTimestamp
            );
            if (multiplier == 0) continue;
            // @dev if currentTimestamp exceed end block, use end block as the last reward block
            // so that for the next iteration, previous endTimestamp will be used as the last reward block
            if (block.timestamp > rewardInfo[i].endTimestamp) {
                stakeinfo.lastRewardTimestamp = rewardInfo[i].endTimestamp;
            } else {
                stakeinfo.lastRewardTimestamp = block.timestamp;
            }
            stakeinfo.accRewardPerShare +=
                ((multiplier * rewardInfo[i].rewardPerSec) *
                    stakeinfo.precision) /
                stakeinfo.totalStaked;
        }
    }

    /// @notice Update reward variables for all stakeinfos. gas spending is HIGH in this method call, BE CAREFUL
    function massUpdateCampaigns() external nonReentrant {
        uint256 length = stakeInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            _updateStakeInfo(pid);
        }
    }

    function depositWithPermit(
        uint256 _stakeID,
        uint256 _amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external nonReentrant {
        StakeInfo storage stakeinfo = stakeInfo[_stakeID];
        stakeinfo.stakingToken.permit(
            msg.sender,
            address(this),
            _amount,
            deadline,
            v,
            r,
            s
        );
        _deposit(_stakeID, _amount);
    }

    /// @notice Stake Staking tokens to TokenFarm
    function deposit(uint256 _stakeID, uint256 _amount)
        external
        nonReentrant
    {
        _deposit(_stakeID, _amount);
    }

    /// @notice Stake Staking tokens to TokenFarm
    function _deposit(uint256 _stakeID, uint256 _amount) internal {
        StakeInfo storage stakeinfo = stakeInfo[_stakeID];
        UserInfo storage user = userInfo[_stakeID][msg.sender];
        _updateStakeInfo(_stakeID);
        if (user.amount > 0) {
            uint256 pending = ((user.amount * stakeinfo.accRewardPerShare) /
                stakeinfo.precision) - user.rewardDebt;
            if (pending > 0) {
                stakeinfo.rewardToken.safeTransfer(address(msg.sender), pending);
            }
        }
        if (_amount > 0) {
            stakeinfo.stakingToken.safeTransferFrom(
                address(msg.sender),
                address(this),
                _amount
            );
            user.amount += _amount;
            stakeinfo.totalStaked += _amount;
        }
        user.rewardDebt =
            (user.amount * stakeinfo.accRewardPerShare) /
            stakeinfo.precision;
        emit Deposit(msg.sender, _amount, _stakeID);
    }

    /// @notice Withdraw Staking tokens from STAKING.
    function withdraw(uint256 _stakeID, uint256 _amount)
        external
        nonReentrant
    {
        _withdraw(_stakeID, _amount);
    }

    /// @notice internal method for withdraw (withdraw and harvest method depend on this method)
    function _withdraw(uint256 _stakeID, uint256 _amount) internal {
        StakeInfo storage stakeinfo = stakeInfo[_stakeID];
        UserInfo storage user = userInfo[_stakeID][msg.sender];
        require(user.amount >= _amount, "withdraw::bad withdraw amount");
        _updateStakeInfo(_stakeID);
        uint256 pending = ((user.amount * stakeinfo.accRewardPerShare) /
            stakeinfo.precision) - user.rewardDebt;
        if (pending > 0) {
            stakeinfo.rewardToken.safeTransfer(address(msg.sender), pending);
        }
        if (_amount > 0) {
            user.amount -= _amount;
            stakeinfo.stakingToken.safeTransfer(address(msg.sender), _amount);
            stakeinfo.totalStaked -= _amount;
        }
        user.rewardDebt =
            (user.amount * stakeinfo.accRewardPerShare) /
            stakeinfo.precision;

        emit Withdraw(msg.sender, _amount, _stakeID);
    }

    /// @notice method for harvest stakeinfos (used when the user want to claim their reward token based on specified stakeinfos)
    function harvest(uint256[] calldata _stakeIDs) external nonReentrant {
        for (uint256 i = 0; i < _stakeIDs.length; ++i) {
            _withdraw(_stakeIDs[i], 0);
        }
    }

    /// @notice Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _stakeID) external nonReentrant {
        StakeInfo storage stakeinfo = stakeInfo[_stakeID];
        UserInfo storage user = userInfo[_stakeID][msg.sender];
        uint256 _amount = user.amount;
        stakeinfo.totalStaked -= _amount;
        user.amount = 0;
        user.rewardDebt = 0;
        stakeinfo.stakingToken.safeTransfer(address(msg.sender), _amount);
        emit EmergencyWithdraw(msg.sender, _amount, _stakeID);
    }

    /// @notice Withdraw reward. EMERGENCY ONLY.
    function emergencyRewardWithdraw(
        uint256 _stakeID,
        uint256 _amount,
        address _beneficiary
    ) external onlyOwner nonReentrant {
        StakeInfo storage stakeinfo = stakeInfo[_stakeID];
        uint256 currentStakingPendingReward = _pendingReward(
            _stakeID,
            stakeinfo.totalStaked,
            0
        );
        require(
            currentStakingPendingReward + _amount <= stakeinfo.totalRewards,
            "not enough reward token"
        );
        stakeinfo.totalRewards -= _amount;
        stakeinfo.rewardToken.safeTransfer(_beneficiary, _amount);
    }
}