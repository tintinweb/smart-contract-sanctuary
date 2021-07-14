// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./IBridge.sol";
import "./IWrappedToken.sol";
import "./IFeeV2.sol";
import "./BridgeBaseV2.sol";

contract BridgeBurnerV2 is BridgeBaseV2 {
    IWrappedToken public token;

    constructor(
        IWrappedToken token_,
        string memory name,
        IBridge prev,
        IFeeV2 fee,
        ILimiter limiter
    ) BridgeBaseV2(name, prev, fee, limiter) {
        token = token_;
    }

    function lock(uint256 amount) external payable override {
        _beforeLock(amount);
        token.burnFrom(_msgSender(), amount);
        emit Locked(_msgSender(), amount);
    }

    function unlock(address account, uint256 amount, bytes32 hash) external override onlyOwner {
        _setUnlockCompleted(hash);
        token.mint(account, amount);
        emit Unlocked(account, amount);
    }

    function renounceOwnership() public override onlyOwner {
        _pause();
        Ownable.renounceOwnership();
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IBridge {
    event Locked(address indexed sender, uint256 amount);
    event Unlocked(address indexed sender, uint256 amount);

    function lock(uint256 amount) external payable;
    function unlock(address account, uint256 amount, bytes32 hash) external;
    function isUnlockCompleted(bytes32 hash) external view returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IWrappedToken {
    function mint(address account, uint256 amount) external;
    function burn(uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IFeeV2 {
    function calculate(address sender, uint256 amount) external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./@openzeppelin/contracts/utils/Context.sol";
import "./@openzeppelin/contracts/security/Pausable.sol";
import "./@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./@openzeppelin/contracts/access/Ownable.sol";
import "./IBridge.sol";
import "./IFeeV2.sol";
import "./ILimiter.sol";

abstract contract BridgeBaseV2 is IBridge, Ownable, Pausable, ReentrancyGuard {
    string public name;
    IBridge public prev; // migrate from
    IFeeV2 public fee;
    ILimiter public limiter;
    mapping(bytes32 => bool) private _unlockedCompleted;

    constructor(string memory name_, IBridge prev_, IFeeV2 fee_, ILimiter limiter_) {
        name = name_;
        prev = prev_;
        fee = fee_;
        limiter = limiter_;
    }

    receive() external payable {
        revert();
    }

    function calculateFee(address sender, uint256 amount) public view returns (uint256) {
        if (address(fee) == address(0)) {
            return 0;
        }
        return fee.calculate(sender, amount);
    }

    function setFee(IFeeV2 fee_) external onlyOwner {
        fee = fee_;
    }

    function getLimiterUsage() public view returns (uint256) {
        if (address(limiter) == address(0)) {
            return 0;
        }
        return limiter.getUsage(address(this));
    }

    function isLimited(uint256 amount) public view returns (bool) {
        if (address(limiter) == address(0)) {
            return false;
        }
        return limiter.isLimited(address(this), amount);
    }

    function setLimiter(ILimiter limiter_) external onlyOwner {
        limiter = limiter_;
    }

    function _transferFee(uint256 amount) private nonReentrant {
        uint256 calculatedFee = calculateFee(_msgSender(), amount);
        if (calculatedFee == 0) {
            return;
        }

        require(msg.value >= calculatedFee, "BridgeBase: not enough fee");

        (bool success,) = owner().call{value : msg.value}("");
        require(success, "BridgeBase: can not transfer fee");
    }

    function _checkLimit(uint256 amount) internal {
        if (address(limiter) == address(0)) {
            return;
        }
        limiter.increaseUsage(amount);
    }

    function _beforeLock(uint256 amount) internal whenNotPaused {
        _checkLimit(amount);
        _transferFee(amount);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function isUnlockCompleted(bytes32 hash) public view override returns (bool) {
        if (address(prev) != address(0)) {
            if (prev.isUnlockCompleted(hash)) {
                return true;
            }
        }
        return _unlockedCompleted[hash];
    }

    function _setUnlockCompleted(bytes32 hash) internal {
        require(!isUnlockCompleted(hash), "BridgeBase: already unlocked");
        _unlockedCompleted[hash] = true;
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor () {
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface ILimiter {
    function getLimit(address bridge) external view returns (uint256);

    function getUsage(address bridge) external view returns (uint256);

    function isLimited(address bridge, uint256 amount) external view returns (bool);

    function increaseUsage(uint256 amount) external;
}