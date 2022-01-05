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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// Contracts
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';

// Interfaces
import {IFeeStrategy} from './IFeeStrategy.sol';

contract FeeStrategy2 is Ownable, IFeeStrategy {
    /// @dev Purchase Fee: x% of the price of the underlying asset * the amount of options being bought * OTM Fee Multiplier
    uint256 public purchaseFeePercentage = 25e8 / 100; // 0.125%

    /// @dev Settlement Fee: x% of the settlement price
    uint256 public settlementFeePercentage = 25e8 / 100; // 0.125%

    event PurchaseFeePercentageUpdate(uint256 newFee);

    event SettlementFeePercentageUpdate(uint256 newFee);

    /// @notice Update the purchase fee percentage
    /// @dev Can only be called by owner
    /// @param newFee The new fee
    /// @return Whether it was successfully updated
    function updatePurchaseFeePercentage(uint256 newFee)
        external
        onlyOwner
        returns (bool)
    {
        purchaseFeePercentage = newFee;
        emit PurchaseFeePercentageUpdate(newFee);
        return true;
    }

    /// @notice Update the settlement fee percentage
    /// @dev Can only be called by owner
    /// @param newFee The new fee
    /// @return Whether it was successfully updated
    function updateSettlementFeePercentage(uint256 newFee)
        external
        onlyOwner
        returns (bool)
    {
        settlementFeePercentage = newFee;
        emit SettlementFeePercentageUpdate(newFee);
        return true;
    }

    /// @notice Calculate Fees for purchase
    /// @param price settlement price of DPX
    /// @param strike total pnl
    /// @param amount amount of options being bought
    function calculatePurchaseFees(
        uint256 price,
        uint256 strike,
        uint256 amount
    ) external view returns (uint256 finalFee) {
        finalFee = (purchaseFeePercentage * amount) / 1e10;

        if (price < strike) {
            uint256 feeMultiplier = (((strike * 100) / (price)) - 100) + 100;
            finalFee = (feeMultiplier * finalFee) / 100;
        }
    }

    /// @notice Calculate Fees for settlement
    function calculateSettlementFees(
        uint256,
        uint256,
        uint256
    ) external view returns (uint256 finalFee) {
        finalFee = settlementFeePercentage * 0;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IFeeStrategy {
    function calculatePurchaseFees(
        uint256,
        uint256,
        uint256
    ) external view returns (uint256);

    function calculateSettlementFees(
        uint256,
        uint256,
        uint256
    ) external view returns (uint256);
}