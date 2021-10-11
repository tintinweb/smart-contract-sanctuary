// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.3;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import "./common/Globals.sol";

contract TokenFarming is OwnableUpgradeable, PausableUpgradeable {
    IERC20 public stakeToken;
    IERC20 public distributionToken;

    uint256 public rewardPerBlock;

    uint256 public cumulativeSum;
    uint256 public lastUpdate;

    uint256 public totalPoolStaked;

    uint256 public startDate;

    struct UserInfo {
        uint256 stakedAmount;
        uint256 lastCumulativeSum;
        uint256 aggregatedReward;
    }

    mapping(address => UserInfo) public userInfos;

    event TokensStaked(address _staker, uint256 _stakeAmount);
    event TokensWithdrawn(address _staker, uint256 _withdrawAmount);
    event RewardsClaimed(address _claimer, uint256 _rewardsAmount);

    function initTokenFarming(
        address _stakeToken,
        address _distributioToken,
        uint256 _rewardPerBlock
    ) external initializer() {
        __Pausable_init_unchained();
        __Ownable_init();
        stakeToken = IERC20(_stakeToken);
        distributionToken = IERC20(_distributioToken);
        rewardPerBlock = _rewardPerBlock;
        startDate = block.timestamp;
    }

    modifier updateRewards() {
        _updateUserRewards(_updateCumulativeSum());
        _;
    }

    function updateRewardPerBlock(uint256 _newRewardPerBlock) external onlyOwner {
        _updateCumulativeSum();
        rewardPerBlock = _newRewardPerBlock;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function stake(uint256 _stakeAmount) external updateRewards whenNotPaused() {
        userInfos[msg.sender].stakedAmount += _stakeAmount;
        totalPoolStaked += _stakeAmount;

        stakeToken.transferFrom(msg.sender, address(this), _stakeAmount);

        emit TokensStaked(msg.sender, _stakeAmount);
    }

    function withdrawFunds(uint256 _amountToWithdraw) public updateRewards {
        uint256 _currentStakedAmount = userInfos[msg.sender].stakedAmount;

        require(
            _currentStakedAmount >= _amountToWithdraw,
            "TokenFarming: Not enough staked tokens to withdraw"
        );

        userInfos[msg.sender].stakedAmount = _currentStakedAmount - _amountToWithdraw;
        totalPoolStaked -= _amountToWithdraw;

        stakeToken.transfer(msg.sender, _amountToWithdraw);

        emit TokensWithdrawn(msg.sender, _amountToWithdraw);
    }

    function claimRewards() public updateRewards {
        uint256 _currentRewards = _applySlashing(userInfos[msg.sender].aggregatedReward);

        require(_currentRewards > 0, "TokenFarming: Nothing to claim");

        delete userInfos[msg.sender].aggregatedReward;

        distributionToken.transfer(msg.sender, _currentRewards);

        emit RewardsClaimed(msg.sender, _currentRewards);
    }

    function claimAndWithdraw() external {
        withdrawFunds(userInfos[msg.sender].stakedAmount);
        claimRewards();
    }

    /// @dev prices with the same precision
    function getAPY(
        address _userAddr,
        uint256 _stakeTokenPrice,
        uint256 _distributionTokenPrice
    ) external view returns (uint256 _resultAPY) {
        uint256 _userStakeAmount = userInfos[_userAddr].stakedAmount;

        if (_userStakeAmount > 0) {
            uint256 _newCumulativeSum =
                _getNewCumulativeSum(
                    rewardPerBlock,
                    totalPoolStaked,
                    cumulativeSum,
                    BLOCKS_PER_YEAR
                );

            uint256 _totalReward =
                ((_newCumulativeSum - userInfos[_userAddr].lastCumulativeSum) * _userStakeAmount) /
                    DECIMAL;

            _resultAPY =
                (_totalReward * _distributionTokenPrice * DECIMAL) /
                (_stakeTokenPrice * _userStakeAmount);
        }
    }

    function getTotalAPY(uint256 _stakeTokenPrice, uint256 _distributionTokenPrice)
        external
        view
        returns (uint256)
    {
        uint256 _totalPool = totalPoolStaked;

        if (_totalPool > 0) {
            uint256 _totalRewards = distributionToken.balanceOf(address(this));
            return
                (_totalRewards * _distributionTokenPrice * DECIMAL) /
                (_totalPool * _stakeTokenPrice);
        }
        return 0;
    }

    function _applySlashing(uint256 _rewards) private view returns (uint256) {
        if (block.timestamp < startDate + 150 days) {
            return (_rewards * (block.timestamp - startDate)) / 150 days;
        }

        return _rewards;
    }

    function _updateCumulativeSum() internal returns (uint256 _newCumulativeSum) {
        uint256 _totalPool = totalPoolStaked;
        uint256 _lastUpdate = lastUpdate;
        _lastUpdate = _lastUpdate == 0 ? block.number : _lastUpdate;

        if (_totalPool > 0) {
            _newCumulativeSum = _getNewCumulativeSum(
                rewardPerBlock,
                _totalPool,
                cumulativeSum,
                block.number - _lastUpdate
            );

            cumulativeSum = _newCumulativeSum;
        }

        lastUpdate = block.number;
    }

    function _getNewCumulativeSum(
        uint256 _rewardPerBlock,
        uint256 _totalPool,
        uint256 _prevAP,
        uint256 _blocksDelta
    ) internal pure returns (uint256) {
        uint256 _newPrice = (_rewardPerBlock * DECIMAL) / _totalPool;
        return _blocksDelta * _newPrice + _prevAP;
    }

    function _updateUserRewards(uint256 _newCumulativeSum) internal {
        UserInfo storage userInfo = userInfos[msg.sender];

        uint256 _currentUserStakedAmount = userInfo.stakedAmount;

        if (_currentUserStakedAmount > 0) {
            userInfo.aggregatedReward +=
                ((_newCumulativeSum - userInfo.lastCumulativeSum) * _currentUserStakedAmount) /
                DECIMAL;
        }

        userInfo.lastCumulativeSum = _newCumulativeSum;
    }

    function getLatestUserRewards(address _userAddr) public view returns (uint256) {
        uint256 _totalPool = totalPoolStaked;
        uint256 _lastUpdate = lastUpdate;

        uint256 _newCumulativeSum;

        _lastUpdate = _lastUpdate == 0 ? block.number : _lastUpdate;

        if (_totalPool > 0) {
            _newCumulativeSum = _getNewCumulativeSum(
                rewardPerBlock,
                _totalPool,
                cumulativeSum,
                block.number - _lastUpdate
            );
        }

        UserInfo memory userInfo = userInfos[_userAddr];

        uint256 _currentUserStakedAmount = userInfo.stakedAmount;
        uint256 _agregatedRewards = userInfo.aggregatedReward;

        if (_currentUserStakedAmount > 0) {
            _agregatedRewards =
                _agregatedRewards +
                ((_newCumulativeSum - userInfo.lastCumulativeSum) * _currentUserStakedAmount) /
                DECIMAL;
        }

        return _agregatedRewards;
    }

    function getLatestUserRewardsAfterSlashing(address _userAddr) external view returns (uint256) {
        return _applySlashing(getLatestUserRewards(_userAddr));
    }

    function transferStuckERC20(
        IERC20 _token,
        address _to,
        uint256 _amount
    ) external onlyOwner {
        require(address(_token) != address(stakeToken), "Not possible to withdraw stake token");
        _token.transfer(_to, _amount);
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity 0.8.3;

uint256 constant ONE_PERCENT = 10**25;
uint256 constant DECIMAL = ONE_PERCENT * 100;

uint256 constant BLOCKS_PER_DAY = 6450;
uint256 constant BLOCKS_PER_YEAR = BLOCKS_PER_DAY * 365;

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
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