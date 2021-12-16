// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// NPM Imports
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// Internal Imports
import "./interface/IRevoStaking.sol";
import "./helpers/Error.sol";
import {PoolInfo, StakingInfo} from "./types/Type.sol";

/// @title RevoStaking
/// @author Nodeberry (P) Ltd.,
/// @dev inherits from {IRevoStaking}, implements the common functions
/// to facilitate staking & yield farming of REVOL tokens.

contract RevoStaking is IRevoStaking, Ownable, ReentrancyGuard {
    /// @dev represents the pools-created
    uint256 public poolCount;

    /// @dev Mapping pool information to a poolId
    mapping(uint256 => PoolInfo) public pool;

    /// @dev Mapping staking information to a wallet address
    mapping(address => mapping(uint256 => StakingInfo)) public stake;

    /// @dev Mapping poolId to status of the pool
    mapping(uint256 => uint256) public poolStatus;

    /// @dev see {IRevoStaking-createPool}
    function createPool(
        address stakingToken,
        address rewardToken,
        uint256 yieldPerSecond
    ) public virtual override onlyOwner returns (bool) {
        poolCount += 1;
        pool[poolCount] = PoolInfo(
            stakingToken,
            rewardToken,
            yieldPerSecond,
            0
        );

        emit PoolCreated(poolCount, stakingToken, rewardToken, yieldPerSecond);
        return true;
    }

    /// @dev see {IRevoStaking-changePoolStatus}
    function changePoolStatus(uint256 poolId, uint256 status)
        public
        virtual
        override
        onlyOwner
        returns (bool)
    {
        require(poolId <= poolCount, Error.VE_INVALID_POOLID);

        poolStatus[poolId] = status;
        emit PoolStatusChanged(poolId, status);
        return true;
    }

    /// @dev see {IRevoStaking-stakeToken}
    function stakeToken(uint256 poolId, uint256 amount)
        public
        virtual
        override
        nonReentrant
        returns (bool)
    {
        require(poolId <= poolCount, Error.VE_INVALID_POOLID);
        require(poolStatus[poolId] == 0, Error.VE_INVALID_POOLID);

        PoolInfo storage p = pool[poolId];
        StakingInfo storage s = stake[_msgSender()][poolId];
        address tokenAddress = p.stakingToken;

        /// @dev Validation of sanity checks
        require(
            IERC20(tokenAddress).allowance(_msgSender(), address(this)) >=
                amount,
            Error.VE_INSUFFICIENT_ALLOWANCE
        );
        require(
            IERC20(tokenAddress).balanceOf(_msgSender()) >= amount,
            Error.VE_INSUFFICIENT_BALANCE
        );

        if (s.amount > 0) {
            uint256 unclaimed = fetchUnclaimed(poolId);
            IERC20(p.rewardToken).transfer(_msgSender(), unclaimed);
        }

        /// @dev writes the stake info into the storage
        s.amount += amount;
        s.stakeTime = block.timestamp;
        p.totalStaked += amount;

        /// @dev transferring tokens to smart contract
        IERC20(p.stakingToken).transferFrom(
            _msgSender(),
            address(this),
            amount
        );
        emit Stake(_msgSender(), amount, poolId, block.timestamp);
        return true;
    }

    /// @dev see {IRevoStaking-claimToken}
    function claimToken(uint256 poolId, bool includingPrincipal)
        public
        virtual
        override
        nonReentrant
        returns (bool)
    {
        uint256 unclaimed = fetchUnclaimed(poolId);
        require(unclaimed > 0, Error.VE_NO_VALUE_TO_CLAIM);

        PoolInfo storage p = pool[poolId];
        StakingInfo storage s = stake[_msgSender()][poolId];

        uint256 principal = s.amount;
        s.stakeTime = block.timestamp;
        p.totalStaked -= s.amount;

        if (includingPrincipal) {
            s.amount = 0;
            IERC20(p.stakingToken).transfer(_msgSender(), principal);
        }
        IERC20(p.rewardToken).transfer(_msgSender(), unclaimed);

        emit Claim(
            _msgSender(),
            unclaimed,
            poolId,
            block.timestamp,
            includingPrincipal
        );
        return true;
    }

    /// @dev see {IRevoStaking-fetchUnclaimed}
    function stakeInfo(address user, uint256 poolId)
        public
        view
        virtual
        override
        returns (StakingInfo memory)
    {
        return stake[user][poolId];
    }

    /// @dev see {IRevoStaking-fetchUnclaimed}
    function fetchUnclaimed(uint256 poolId)
        public
        view
        virtual
        override
        returns (uint256)
    {
        StakingInfo storage s = stake[_msgSender()][poolId];
        PoolInfo storage p = pool[poolId];

        require(s.amount > 0, Error.VE_ZERO_STAKED);
        uint256 totalStakeTime = block.timestamp - s.stakeTime;
        uint256 totalReward = s.amount * totalStakeTime * p.yieldPerSecond;
        totalReward = (totalReward / 315360000000);
        return totalReward;
    }
}

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {StakingInfo} from "../types/Type.sol";

/// @title IRevoStaking
/// @author Nodeberry (P) Ltd.,
/// @dev this is the interface for staking contracts.

interface IRevoStaking {
    /// @dev emitted when the owner creates a new pool
    event PoolCreated(
        uint256 poolId,
        address stakingToken,
        address rewardToken,
        uint256 yieldPerSecond
    );

    /// @dev emitted when the owner creates a new pool
    event PoolStatusChanged(uint256 poolId, uint256 status);

    /// @dev emitted when a user stakes token into a pool
    event Stake(address user, uint256 amount, uint256 poolId, uint256 time);

    /// @dev emitted when a user claims token from a pool
    event Claim(
        address user,
        uint256 reward,
        uint256 poolId,
        uint256 time,
        bool withPrincipal
    );

    /// @dev can create a new staking pool
    /// @param stakingToken is the address of token that users have to stake
    /// @param rewardToken is the address of the token users will claim
    /// @param yieldPerSecond is the yield per second.
    /// @return a boolean representing the status of the transaction.
    /// Note Set rewardToken to Zero Address to open a pool without reward.
    function createPool(
        address stakingToken,
        address rewardToken,
        uint256 yieldPerSecond
    ) external returns (bool);

    /// @dev can deactivate a pool for further staking.
    /// @param poolId is the identifier of the pool.
    /// @param status is the representation of the pool status.
    /// @return a bool representing the status of the transaction.
    /// Note 1 represents inactive pool & 0 represents active pool.
    function changePoolStatus(uint256 poolId, uint256 status)
        external
        returns (bool);

    /// @dev can allow users to stake their tokens in the smart contract.
    /// @param poolId is the identifier of the staking pool.
    /// @param amount is the amount of tokens willing to be staked.
    /// @return a bool representing the status of the transaction.
    /// Note make sure the amount of tokens is approved
    function stakeToken(uint256 poolId, uint256 amount) external returns (bool);

    /// @dev can allow users to claim their tokens in the smart contract.
    /// @param poolId is the identifier of the staking pool.
    /// @param includingPrincipal is to harvest/entirely claim the tokens from pool.
    /// @return a bool representing the status of the transaction.
    /// Note make sure the amount of tokens is approved
    function claimToken(uint256 poolId, bool includingPrincipal)
        external
        returns (bool);

    /// @dev allows users to see unclaimed token value.
    /// @param poolId is the identifier of the staking pool.
    /// @return uint256 representing the amount of unclaimed tokens.
    function stakeInfo(address user, uint256 poolId)
        external
        returns (StakingInfo memory);

    /// @dev allows users to see unclaimed token value.
    /// @param poolId is the identifier of the staking pool.
    /// @return uint256 representing the amount of unclaimed tokens.
    function fetchUnclaimed(uint256 poolId) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @title Error
/// @author Nodeberry (P) Ltd.,
/// @dev all error codes can be found here.
/// Note all the require function inherit error codes from here.

library Error {
    string public constant VE_INSUFFICIENT_ALLOWANCE =
        "Error: Insufficient Allowance";
    string public constant VE_INSUFFICIENT_BALANCE =
        "Error: Insufficient Balance";
    string public constant VE_DECREASE_ALLOWANCE =
        "Error: Decreased allowance less than zero";
    string public constant VE_ZERO_ADDRESS =
        "Error: address cannot be zero address";
    string public constant VE_INVALID_POOLID =
        "Error: pool is either not created or paused";
    string public constant VE_ZERO_STAKED =
        "Error: no stake found to fetch unclaimed amount";
    string public constant VE_NO_VALUE_TO_CLAIM =
        "Error: no tokens left for claiming";
    string public constant VE_INVALID_SALEID =
        "Error: sale is either not created or ended";
    string public constant VE_SALE_NOT_ENDED =
        "Error: withdraw once the sale is ended";
    string public constant VE_ZERO_LEFT = "Error: sale is completely sold out";
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

/// @title Type.sol
/// @author Nodeberry (P) Ltd.,
/// All user defined types would be added in here

struct PoolInfo {
    address rewardToken;
    address stakingToken;
    /// @dev yieldPerSecond is 2 precision.
    uint256 yieldPerSecond;
    uint256 totalStaked;
}

struct StakingInfo {
    uint256 stakeTime;
    uint256 amount;
}

struct SaleInfo {
    address tokenAddress;
    /// @dev whitelist is false then it is staking only.
    bool whitelist;
    uint256 totalAllocated;
    uint256 totalSold;
    uint256 startTime;
    uint256 endTime;
    uint256 stakePoolId;
    /// @dev cost in usd is 8-precision.
    uint256 cost;
    /// @dev only available for staking allocation.
    uint256[3] tierAllocation;
    string ipfsHash;
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