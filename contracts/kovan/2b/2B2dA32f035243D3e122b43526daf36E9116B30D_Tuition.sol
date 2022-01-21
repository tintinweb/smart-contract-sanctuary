//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";

contract Tuition is Ownable {
    address public TREASURY;
    bool public allowPayments = true;
    mapping(address => bool) public isStaff;
    mapping(address => bool) public alreadyPaid;
    mapping(address => uint256) public amountPaidBy;

    constructor(address newOwner, address treasury) {
        isStaff[msg.sender] = true;
        TREASURY = treasury;
        transferOwnership(newOwner);
    }

    modifier onlyStaff() {
        // Owner should be considered part of staff
        require(isStaff[msg.sender] || msg.sender == owner(), "STAFF_ONLY");
        _;
    }

    modifier contractNotLocked() {
        require(allowPayments, "NOT_TAKING_PAYMENTS");
        _;
    }

    /**
     * Takes a 1 ETH or 4 ETH contribution from a student
     */
    function contribute() public payable contractNotLocked {
        require(!alreadyPaid[msg.sender], "ALREADY_PAID");
        require(msg.value == 1 ether || msg.value == 4 ether, "WRONG_AMOUNT");

        alreadyPaid[msg.sender] = true;
        amountPaidBy[msg.sender] = msg.value;
    }

    /**
     * Allows staff to refund the entirety of a student's contribution
     * @param account Student address to be refunded
     */
    function refundUser(address account) public onlyStaff contractNotLocked {
        require(alreadyPaid[account], "STUDENT_DIDNT_PAY");
        require(amountPaidBy[account] > 0, "NOTHING_TO_REFUND");

        uint256 amountToRefund = amountPaidBy[account];
        amountPaidBy[account] = 0;
        alreadyPaid[account] = false;

        (bool success, ) = account.call{value: amountToRefund}("");
        require(success, "TRANSFER_FAILED");
    }

    /**
     * Allows staff to move a student's funds to treasury
     * @param account Contributer of the funds to move to the treasury
     */
    function moveStudentFundsToTreasury(address account)
        public
        onlyStaff
        contractNotLocked
    {
        require(alreadyPaid[account], "STUDENT_DIDNT_PAY");
        require(amountPaidBy[account] > 0, "NO_FUNDS_AVAILABLE");

        uint256 amountToMove = amountPaidBy[account];
        amountPaidBy[account] = 0;
        alreadyPaid[account] = false;

        (bool success, ) = TREASURY.call{value: amountToMove}("");
        require(success, "TRANSFER_FAILED");
    }

    function addStaff(address account) public onlyOwner {
        isStaff[account] = true;
    }

    function removeStaff(address account) public onlyOwner {
        isStaff[account] = false;
    }

    /**
     * @dev This function should only be used in case of an emergency to move all
     *      funds to the treasury, it will permanently lock the contract
     */
    function moveAllFundsToTreasury() public onlyOwner {
        (bool success, ) = TREASURY.call{value: address(this).balance}("");
        require(success, "TRANSFER_FAILED");
        allowPayments = false;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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