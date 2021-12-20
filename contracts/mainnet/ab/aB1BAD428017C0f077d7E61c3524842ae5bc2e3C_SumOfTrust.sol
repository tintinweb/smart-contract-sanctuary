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

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

/**
 * @title CreditLimitModel Interface
 *  @dev Calculate the user's credit line based on the trust he receives from the vouchees.
 */
interface ICreditLimitModel {
    struct LockedInfo {
        address staker;
        uint256 vouchingAmount;
        uint256 lockedAmount;
        uint256 availableStakingAmount;
    }

    function isCreditLimitModel() external pure returns (bool);

    function effectiveNumber() external returns (uint256);

    /**
     * @notice Calculates the staker locked amount
     * @return Member credit limit
     */
    function getLockedAmount(
        LockedInfo[] calldata vouchAmountList,
        address staker,
        uint256 amount,
        bool isIncrease
    ) external pure returns (uint256);

    /**
     * @notice Calculates the member credit limit by vouchs
     * @return Member credit limit
     */
    function getCreditLimit(uint256[] calldata vouchs) external view returns (uint256);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

import "../interfaces/ICreditLimitModel.sol";

contract SumOfTrust is Ownable, ICreditLimitModel {
    bool public constant override isCreditLimitModel = true;
    uint256 public override effectiveNumber;

    constructor(uint256 effectiveNumber_) {
        effectiveNumber = effectiveNumber_;
    }

    function getCreditLimit(uint256[] memory vouchs) public view override returns (uint256) {
        uint256 vouchLength = vouchs.length;
        if (vouchLength >= effectiveNumber) {
            uint256 limit;
            for (uint256 i = 0; i < vouchLength; i++) {
                limit += vouchs[i];
            }

            return limit;
        } else {
            return 0;
        }
    }

    function getLockedAmount(
        LockedInfo[] memory array,
        address account,
        uint256 amount,
        bool isIncrease
    ) public pure override returns (uint256) {
        uint256 arrLength = array.length;
        if (arrLength == 0) return 0;

        uint256 remaining = amount;
        uint256 newLockedAmount;
        if (isIncrease) {
            array = _sortArray(array, true);
            for (uint256 i = 0; i < arrLength; i++) {
                uint256 remainingVouchingAmount;
                if (array[i].vouchingAmount > array[i].lockedAmount) {
                    remainingVouchingAmount = array[i].vouchingAmount - array[i].lockedAmount;
                } else {
                    remainingVouchingAmount = 0;
                }

                if (remainingVouchingAmount > array[i].availableStakingAmount) {
                    if (array[i].availableStakingAmount > remaining) {
                        newLockedAmount = array[i].lockedAmount + remaining;
                        remaining = 0;
                    } else {
                        newLockedAmount = array[i].lockedAmount + array[i].availableStakingAmount;
                        remaining = remaining - array[i].availableStakingAmount;
                    }
                } else {
                    if (remainingVouchingAmount > remaining) {
                        newLockedAmount = array[i].lockedAmount + remaining;
                        remaining = 0;
                    } else {
                        newLockedAmount = array[i].lockedAmount + remainingVouchingAmount;
                        remaining -= remainingVouchingAmount;
                    }
                }

                if (account == array[i].staker) {
                    return newLockedAmount;
                }
            }
        } else {
            array = _sortArray(array, false);
            for (uint256 i = 0; i < arrLength; i++) {
                if (array[i].lockedAmount > remaining) {
                    newLockedAmount = array[i].lockedAmount - remaining;
                    remaining = 0;
                } else {
                    newLockedAmount = 0;
                    remaining -= array[i].lockedAmount;
                }

                if (account == array[i].staker) {
                    return newLockedAmount;
                }
            }
        }

        return 0;
    }

    function setEffectNumber(uint256 number) external onlyOwner {
        effectiveNumber = number;
    }

    //use bubble
    function _sortArray(LockedInfo[] memory arr, bool isPositive) private pure returns (LockedInfo[] memory) {
        uint256 length = arr.length;

        for (uint256 i = 0; i < length; i++) {
            for (uint256 j = i + 1; j < length; j++) {
                if (isPositive) {
                    if (arr[i].vouchingAmount < arr[j].vouchingAmount) {
                        LockedInfo memory temp = arr[j];
                        arr[j] = arr[i];
                        arr[i] = temp;
                    }
                } else {
                    if (arr[i].vouchingAmount > arr[j].vouchingAmount) {
                        LockedInfo memory temp = arr[j];
                        arr[j] = arr[i];
                        arr[i] = temp;
                    }
                }
            }
        }

        return arr;
    }
}