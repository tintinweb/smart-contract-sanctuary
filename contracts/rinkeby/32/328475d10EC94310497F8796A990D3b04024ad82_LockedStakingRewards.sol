//SPDX License Identifier: MIT

pragma solidity 0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract LockedStakingRewards is Ownable, ReentrancyGuard {
    IERC20 public stakeToken;

    uint256 public constant depositDuration = 7 minutes;

    struct Pool {
        uint256 tokenPerShareMultiplier;
        bool isTerminated;
        uint256 cycleDuration;
        uint256 startOfDeposit;
        uint256 tokenPerShare;
    }

    mapping(uint256 => Pool) public pool;

    mapping(address => mapping(uint256 => uint256)) private _shares;

    constructor(IERC20 _stakeToken, Pool[] memory _initialPools) {
        stakeToken = _stakeToken;
        for (uint256 i = 0; i < _initialPools.length; i++) {
            createPool(i, _initialPools[i]);
        }
    }

    function receiveApproval
    (
        address _sender,
        uint256 _amount,
        address _stakeToken,
        bytes memory data
    )
        external
        nonReentrant
    {
        uint256 _pool;
        assembly {
            _pool := mload(add(data, 0x20))
        }
        require(isTransferPhase(_pool), "pool is locked currently");

        require(stakeToken.transferFrom(_sender, address(this), _amount));
        _shares[_sender][_pool] += _amount * 1e4 / pool[_pool].tokenPerShare;
        emit Staked(_sender, _pool, _amount);
    }

    function withdraw(uint256 _sharesAmount, uint256 _pool) external nonReentrant {
        require(isTransferPhase(_pool), "pool is locked currently");
        require(_sharesAmount <= _shares[msg.sender][_pool], "cannot withdraw more than balance");

        uint256 _tokenAmount = sharesToToken(_sharesAmount, _pool);
        _shares[msg.sender][_pool] -= _sharesAmount;
        require(stakeToken.transfer(msg.sender, _tokenAmount));
        emit Unstaked(msg.sender, _pool, _tokenAmount);
    }

    function updatePool(uint256 _pool) public {
        require
        (
            block.timestamp > pool[_pool].startOfDeposit + depositDuration &&
            block.timestamp < pool[_pool].startOfDeposit + pool[_pool].cycleDuration &&
            !pool[_pool].isTerminated,
            "can only update once per cycle on not terminated pools"
        );
        pool[_pool].startOfDeposit += pool[_pool].cycleDuration;
        pool[_pool].tokenPerShare = pool[_pool].tokenPerShare * pool[_pool].tokenPerShareMultiplier / 1e4;
        emit PoolUpdated(_pool, pool[_pool].startOfDeposit, pool[_pool].tokenPerShare);
    }

        ///////////// Restricted Access Functions /////////////

    function updateTokenPerShareMultiplier(uint256 _pool, uint256 newTokenPerShareMultiplier) external onlyOwner {
        require(isTransferPhase(_pool), "pool only updateable during transfer phase");
        pool[_pool].tokenPerShareMultiplier = newTokenPerShareMultiplier;
    }

    function terminatePool(uint256 _pool) public onlyOwner {
        pool[_pool].isTerminated = true;
        emit PoolKilled(_pool);
    }

    function createPool(uint256 _pool, Pool memory pool_) public onlyOwner {
        require(pool[_pool].cycleDuration == 0, "cannot override an existing pool");
        pool[_pool] = pool_;
        emit PoolUpdated(_pool, pool[_pool].startOfDeposit, pool[_pool].tokenPerShare);
    }

        ///////////// View Functions /////////////

    function isTransferPhase(uint256 _pool) public view returns(bool) {
        return(
            (block.timestamp > pool[_pool].startOfDeposit &&
            block.timestamp < pool[_pool].startOfDeposit + depositDuration) ||
            pool[_pool].isTerminated
        );
    }

    function getPoolInfo(uint256 _pool) public view returns(bool, uint256) {
        return (isTransferPhase(_pool), pool[_pool].startOfDeposit);
    }

    function viewUserShares(address _user, uint256 _pool) public view returns(uint256) {
        return _shares[_user][_pool];
    }

    function viewUserTokenAmount(address _user, uint256 _pool) public view returns(uint256) {
        return viewUserShares(_user, _pool) * pool[_pool].tokenPerShare / 1e4;
    }

    function sharesToToken(uint256 _sharesAmount, uint256 _pool) public view returns(uint256) {
        return _sharesAmount * pool[_pool].tokenPerShare / 1e4;
    }

    function tokenToShares(uint256 _tokenAmount, uint256 _pool) public view returns(uint256) {
        return _tokenAmount * 1e4 / pool[_pool].tokenPerShare;
    }

    function getUserTokenAmountAfter(address _user, uint256 _pool) public view returns(uint256) {
        if(block.timestamp > pool[_pool].startOfDeposit) {
            return sharesToToken(_shares[_user][_pool], _pool) * pool[_pool].tokenPerShareMultiplier / 1e4;
        }
        return sharesToToken(_shares[_user][_pool], _pool);
    }

        ///////////// Events /////////////
    
    event Staked(address indexed staker, uint256 indexed pool, uint256 amount);
    event Unstaked(address indexed staker, uint256 indexed pool, uint256 amount);
    event PoolUpdated(uint256 indexed pool, uint256 newDepositStart, uint256 newTokenPerShare);
    event PoolKilled(uint256 indexed pool);
}

// SPDX-License-Identifier: MIT

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
}