// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

interface ILevelManager {
    struct Tier {
        string id;
        uint8 multiplier;
        uint256 lockingPeriod; // in seconds
        uint256 minAmount; // tier is applied when userAmount >= minAmount
        bool random;
        uint8 odds; // divider: 2 = 50%, 4 = 25%, 10 = 10%
        bool vip;
    }
    
    function getAlwaysRegister()
    external
    view
    returns (
        address[] memory,
        string[] memory,
        uint256[] memory
    );
    
    function getUserUnlockTime(address account) external view returns (uint256);

    function getTierById(string calldata id)
        external
        view
        returns (Tier memory);

    function getUserTier(address account) external view returns (Tier memory);

    function getTierIds() external view returns (string[] memory);

    function lock(address account, uint256 startTime) external;

    function unlock(address account) external;

    function getUserLatestRegistration(address account)
        external
        view
        returns (address, uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

interface IStakingLockable {
    struct UserInfo {
        uint256 amount;
        // How much was collected and stored until the current moment,
        // keeps rewards if e.g. user staked a big amount at first and then removed half
        uint256 rewardDebt;
        uint256 pendingRewards;
        uint256 lastStakedAt;
        uint256 lastUnstakedAt;
    }

    function getUserInfo(address account)
        external
        view
        returns (UserInfo memory);

    function setLockPeriod(uint256 _lockPeriod) external;

    function setLevelManager(address _address) external;

    function getLockPeriod() external view returns (uint256);

    function lock(address account, uint256 saleStart) external;

    function getUnlocksAt(address account) external view returns (uint256);

    function isLocked(address account) external view returns (bool);

    function getLockedAmount(address account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../levels/IStakingLockable.sol";
import "../levels/ILevelManager.sol";

interface OldStaking {
    struct OldUserInfo {
        uint256 amount;
        uint256 rewardDebt;
        uint256 pendingRewards;
    }

    function userInfo(address account)
        external
        view
        returns (OldUserInfo memory);
}

contract ProxyOldStaking is Ownable, IStakingLockable {
    OldStaking public oldPool;
    uint256 public lockPeriod;
    mapping(address => uint256) public depositLockStart;
    ILevelManager public levelManager;

    constructor(address _oldPool, uint256 _lockPeriod) {
        oldPool = OldStaking(_oldPool);
        lockPeriod = _lockPeriod;
    }

    modifier onlyLevelManager() {
        require(
            msg.sender == address(levelManager),
            "Only LevelManager can lock"
        );
        _;
    }

    function getUserInfo(address account)
        external
        view
        override
        returns (UserInfo memory)
    {
        return UserInfo(oldPool.userInfo(account).amount, 0, 0, 0, 0);
    }

    function isLocked(address account) public view override returns (bool) {
        return block.timestamp < depositLockStart[account] + lockPeriod;
    }

    function getLockedAmount(address account)
        external
        view
        override
        returns (uint256)
    {
        return oldPool.userInfo(account).amount;
    }

    function getLockPeriod() external view override returns (uint256) {
        return lockPeriod;
    }

    function setLockPeriod(uint256 _lockPeriod) external override onlyOwner {
        lockPeriod = _lockPeriod;
    }

    function getUnlocksAt(address account) external view override returns (uint256) {
        return depositLockStart[account] + lockPeriod;
    }

    function lock(address account, uint256 saleStart)
        external
        override
        onlyLevelManager
    {
        if (isLocked(account)) {
            return;
        }

        depositLockStart[account] = block.timestamp;
    }

    function setLevelManager(address _address) external override onlyOwner {
        levelManager = ILevelManager(_address);
    }
}