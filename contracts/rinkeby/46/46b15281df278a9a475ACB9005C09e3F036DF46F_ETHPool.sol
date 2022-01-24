// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";

contract ETHPool is Ownable {
    event Deposit(address indexed from, uint256 amount);
    event Withdrawal(address indexed to, uint256 deposit, uint256 rewards);
    event RewardsAdded(uint256 amount);

    struct Account {
        uint256 balance;
        uint256 rewards;
    }

    mapping(address => Account) private accountOf;

    // keys of accountOf
    address[] private accountsAddresses;

    // stores indexes to speed up deletions on accountsAddresses
    mapping(address => uint256) private accountAddressIndexOf;

    uint256 deposited;

    receive() external payable {
        deposit();
    }

    function deposit() public payable {
        uint256 amount = msg.value;
        address sender = msg.sender;
        require(amount > 0, "Deposit amount must be greater than zero");

        Account storage account = accountOf[sender];
        if (account.balance == 0) {
            // first time deposit
            accountAddressIndexOf[sender] = accountsAddresses.length;
            accountsAddresses.push(sender);
        }
        account.balance += amount;
        deposited += amount;
        emit Deposit(sender, amount);
    }

    function depositRewards() external payable onlyOwner {
        uint256 amount = msg.value;
        require(amount > 0, "Rewards must be greater than zero");

        // compute rewards for all accounts
        for (uint256 i = 0; i < accountsAddresses.length; i++) {
            Account storage account = accountOf[accountsAddresses[i]];
            uint256 share = (account.balance * 100) / deposited;
            account.rewards += (amount * share) / 100;
        }

        emit RewardsAdded(amount);
    }

    function withdraw() external {
        address sender = msg.sender;
        Account storage account = accountOf[sender];
        require(account.balance > 0, "Not enough funds to withdraw");

        uint256 balance = account.balance;
        uint256 rewards = account.rewards;
        payable(sender).transfer(balance + rewards);
        removeAccount(account, sender);
        emit Withdrawal(sender, balance, rewards);
    }

    function removeAccount(Account storage account, address accountAddress) private {
        deposited -= account.balance;
        delete accountOf[accountAddress];

        // removes entry from accountsAddresses by swapping it for the last element and removing its index
        uint256 index = accountAddressIndexOf[accountAddress];
        address lastElem = accountsAddresses[accountsAddresses.length - 1];
        accountsAddresses[index] = lastElem;
        accountsAddresses.pop();
        delete accountAddressIndexOf[accountAddress];
        accountAddressIndexOf[lastElem] = index;
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