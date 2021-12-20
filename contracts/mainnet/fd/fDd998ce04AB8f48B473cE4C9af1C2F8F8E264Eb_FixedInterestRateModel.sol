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
 * @title InterestRateModel Interface
 *  @dev Calculate the borrowers' interest rate.
 */
interface IInterestRateModel {
    /**
     * @dev Check to see if it is a valid interest rate model
     * @return Return true for a valid interest rate model
     */
    function isInterestRateModel() external pure returns (bool);

    /**
     * @dev Calculates the current borrow interest rate per block
     * @return The borrow rate per block (as a percentage, and scaled by 1e18)
     */
    function getBorrowRate() external view returns (uint256);

    /**
     * @dev Calculates the current suppier interest rate per block
     * @return The supply rate per block (as a percentage, and scaled by 1e18)
     */
    function getSupplyRate(uint256 reserveFactorMantissa) external view returns (uint256);

    /**
     * @dev Set the borrow interest rate per block
     */
    function setInterestRate(uint256 interestRatePerBlock_) external;
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;
pragma abicoder v1;

import "@openzeppelin/contracts/access/Ownable.sol";

import "../interfaces/IInterestRateModel.sol";

contract FixedInterestRateModel is Ownable, IInterestRateModel {
    uint256 public constant BORROW_RATE_MAX_MANTISSA = 0.005e16; //Maximum borrow rate that can ever be applied (.005% / block)
    bool public constant override isInterestRateModel = true;
    uint256 public interestRatePerBlock;

    /**
     *  @dev Update interest parameters event
     *  @param interestRate New interest rate, 1e18 = 100%
     */
    event LogNewInterestParams(uint256 interestRate);

    constructor(uint256 interestRatePerBlock_) {
        interestRatePerBlock = interestRatePerBlock_;

        emit LogNewInterestParams(interestRatePerBlock_);
    }

    function getBorrowRate() public view override returns (uint256) {
        return interestRatePerBlock;
    }

    function getSupplyRate(uint256 reserveFactorMantissa) public view override returns (uint256) {
        require(reserveFactorMantissa <= 1e18, "reserveFactorMantissa error");
        uint256 ratio = uint256(1e18) - reserveFactorMantissa;
        return (interestRatePerBlock * ratio) / 1e18;
    }

    function setInterestRate(uint256 interestRatePerBlock_) external override onlyOwner {
        require(interestRatePerBlock_ <= BORROW_RATE_MAX_MANTISSA, "borrow rate is absurdly high");
        interestRatePerBlock = interestRatePerBlock_;
        emit LogNewInterestParams(interestRatePerBlock_);
    }
}