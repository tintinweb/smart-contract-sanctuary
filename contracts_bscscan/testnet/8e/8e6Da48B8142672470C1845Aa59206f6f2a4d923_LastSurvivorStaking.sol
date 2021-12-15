// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../dependencies/open-zeppelin/proxy/utils/Initializable.sol";
import "../dependencies/open-zeppelin/token/ERC20/IERC20Upgradeable.sol";
import "../dependencies/open-zeppelin/access/OwnableUpgradeable.sol";

contract LastSurvivorStaking is Initializable , OwnableUpgradeable{
    
    constructor() initializer {}

    address public REWARD_TOKEN;
    address public TREASURY_ADDRESS;

    uint256 public lockTime;
    uint256 public releasePeriod;

    struct StakingInfo {
        uint256 amount;
        uint256 stakingAt;
    } 

    struct RewardLock {
        uint256 amount;
        uint256 lockAt;
        uint256 claimed;
    }

    struct PoolInfo {
        address stakeToken;
        uint256 emissionRate;
        bool isEnabled;
    } 

    mapping (address => RewardLock) public rewardInfo;
    mapping (uint256 => PoolInfo) public poolInfo;
    mapping (uint256 => mapping (address => StakingInfo)) public userStakingInfo;
    

    function initialize() initializer public {
        __Ownable_init();
    }

    function updateConfig(address _rewardToken, address _treasury, uint256 _lockTime, uint256 _releasePeriod) public onlyOwner returns (bool) {
        REWARD_TOKEN = _rewardToken;
        TREASURY_ADDRESS = _treasury;
        lockTime = _lockTime;
        releasePeriod = _releasePeriod;
        return true;
    }

    function addPool(address _stakeToken, uint256 _poolId, uint256 _emissionRate) public onlyOwner {
        require(poolInfo[_poolId].stakeToken == address(0), "This pool already init.");
        poolInfo[_poolId].stakeToken = _stakeToken;
        poolInfo[_poolId].emissionRate = _emissionRate;
    }

    function updatePool(uint256 _poolId, uint256 _emissionRate, bool _isEnabled) public onlyOwner {
        require(poolInfo[_poolId].stakeToken != address(0), "This pool not available.");
        poolInfo[_poolId].isEnabled = _isEnabled;
        poolInfo[_poolId].emissionRate = _emissionRate;
    }

    function getReward(
        address _address, uint256 _poolId
    ) public view returns (uint256) {
        require(poolInfo[_poolId].stakeToken != address(0), "This pool not available.");
        require(poolInfo[_poolId].isEnabled, "This pool not available.");
        uint256 totalStaked = IERC20Upgradeable(poolInfo[_poolId].stakeToken).balanceOf(address(this));
        if (totalStaked == 0) {
            return (0);    
        } else {
            uint256 amountReward =  (block.timestamp - userStakingInfo[_poolId][_address].stakingAt) * poolInfo[_poolId].emissionRate * userStakingInfo[_poolId][_address].amount / totalStaked;
            return (amountReward);
        }
        
    }

    function getClaimableReward(address _add) public view returns (uint256) {
        uint256 processPeriod = (block.timestamp - rewardInfo[_add].lockAt) / releasePeriod;
        uint256 estimateReward = processPeriod * (rewardInfo[_add].amount / (lockTime / releasePeriod));
        uint256 availableReward = rewardInfo[_add].amount - rewardInfo[_add].claimed;
        uint256 amountReward = estimateReward > availableReward ? availableReward : estimateReward;
        return amountReward;
    }

    function claimReward(address _add) public {
        uint256 amountReward = getClaimableReward(_add);
        rewardInfo[msg.sender].claimed += amountReward;
        IERC20Upgradeable(REWARD_TOKEN).transferFrom(TREASURY_ADDRESS, _add, amountReward);
    }

    function staking(
        uint256 _amount, uint256 _poolId
    ) public returns (bool) {
        // Return reward if user is staking
        require(poolInfo[_poolId].isEnabled, "This pool not available.");
        if (userStakingInfo[_poolId][msg.sender].amount > 0) {
            uint256 reward = getReward(msg.sender, _poolId);
            rewardInfo[msg.sender].amount = rewardInfo[msg.sender].amount - rewardInfo[msg.sender].claimed + reward;
            rewardInfo[msg.sender].claimed = 0;
            rewardInfo[msg.sender].lockAt = block.timestamp;
        }
        IERC20Upgradeable(poolInfo[_poolId].stakeToken).transferFrom(msg.sender, address(this), _amount);
        userStakingInfo[_poolId][msg.sender].amount += _amount;
        userStakingInfo[_poolId][msg.sender].stakingAt = block.timestamp;
        return true;
    }

    function unstaking(
        uint256 _amount, uint256 _poolId
    ) public returns (bool) {
        require(poolInfo[_poolId].isEnabled, "This pool not available.");
        require(userStakingInfo[_poolId][msg.sender].amount >= _amount, "Amount greater than staked amount.");
        // Return reward if amount = 0
        if (userStakingInfo[_poolId][msg.sender].amount > 0) {
            uint256 reward = getReward(msg.sender, _poolId);
            rewardInfo[msg.sender].amount = rewardInfo[msg.sender].amount - rewardInfo[msg.sender].claimed + reward;
            rewardInfo[msg.sender].claimed = 0;
            rewardInfo[msg.sender].lockAt = block.timestamp;
            userStakingInfo[_poolId][msg.sender].stakingAt = block.timestamp;
        }
        if (_amount > 0) {
            IERC20Upgradeable(poolInfo[_poolId].stakeToken).transfer(msg.sender, _amount);
            userStakingInfo[_poolId][msg.sender].amount -= _amount;
            userStakingInfo[_poolId][msg.sender].stakingAt = block.timestamp;
        }
        return true;
    }


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
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * constructor() initializer {}
 * ```
 * ====
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

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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