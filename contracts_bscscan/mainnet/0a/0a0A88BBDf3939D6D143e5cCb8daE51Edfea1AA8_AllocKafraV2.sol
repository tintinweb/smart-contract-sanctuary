//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interfaces/IAllocKafraV2.sol";

contract AllocKafraV2 is Ownable, IAllocKafraV2 {
    uint16 public constant override MAX_ALLOCATION = 10000;
    uint16 public override limitAllocation;
    uint256 public holdingKSW;
    uint16 public holdingKSWAllocationIncrease;
    address public immutable ksw;

    event SetLimitAllocation(uint16 limitAllocation);
    event SetHoldingKSW(uint256 amount, uint16 increase);

    constructor(
        address _ksw,
        uint16 _limitAllocation,
        uint256 _holdingKSW,
        uint16 _holdingKSWAllocationIncrease
    ) {
        ksw = _ksw;
        limitAllocation = _limitAllocation;
        holdingKSW = _holdingKSW;
        holdingKSWAllocationIncrease = _holdingKSWAllocationIncrease;
    }

    function isHoldingKSW(address user) public view returns (bool) {
        if (holdingKSW == 0) {
            return false;
        }

        uint256 bal = IERC20(ksw).balanceOf(user);
        return bal >= holdingKSW;
    }

    function canAllocate(
        uint256,
        uint256 _balanceOfWant,
        uint256 _balanceOfMasterChef,
        address user
    ) external view override returns (bool) {
        if (limitAllocation == 0) {
            return true;
        }
        uint256 percentage = (_balanceOfWant * MAX_ALLOCATION) / _balanceOfMasterChef;
        if (isHoldingKSW(user)) {
            return percentage <= limitAllocation + holdingKSWAllocationIncrease;
        }
        return percentage <= limitAllocation;
    }

    function setLimitAllocation(uint16 _limitAllocation) external onlyOwner {
        require(_limitAllocation <= MAX_ALLOCATION, "invalid limit");

        limitAllocation = _limitAllocation;
        emit SetLimitAllocation(_limitAllocation);
    }

    function setHoldingKSW(uint256 amount, uint16 increase) external onlyOwner {
        holdingKSW = amount;
        holdingKSWAllocationIncrease = increase;
        emit SetHoldingKSW(amount, increase);
    }

    function userLimitAllocation(address user) external view override returns (uint16) {
        if (isHoldingKSW(user)) {
            return limitAllocation + holdingKSWAllocationIncrease;
        }
        return limitAllocation;
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

//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./IAllocKafra.sol";

interface IAllocKafraV2 is IAllocKafra {
    function MAX_ALLOCATION() external view returns (uint16);

    function limitAllocation() external view returns (uint16);

    function userLimitAllocation(address user) external view returns (uint16);

    function canAllocate(
        uint256 _amount,
        uint256 _balanceOfWant,
        uint256 _balanceOfMasterChef,
        address _user
    ) external view returns (bool);
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

//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IAllocKafra {
    function MAX_ALLOCATION() external view returns (uint16);

    function limitAllocation() external view returns (uint16);

    function canAllocate(
        uint256 _amount,
        uint256 _balanceOfWant,
        uint256 _balanceOfMasterChef,
        address _user
    ) external view returns (bool);
}