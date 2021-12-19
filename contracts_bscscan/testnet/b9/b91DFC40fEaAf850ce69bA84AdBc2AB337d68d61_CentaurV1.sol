//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "Ownable.sol";

contract CentaurV1 {
    // Map user address to a list of ledger accounts
    // Each account is identifiable by index
    mapping(address => uint256[]) public userAccountsMap;
    LedgerAccount[] public allAccounts;

    mapping(address => uint256[]) public userTransactionsMap;
    LedgerTransaction[] public allTransactions;

    mapping(uint256 => uint256) public accountTransactionCountMap;

    // Entries can be public because they are anonymous
    LedgerEntry[] public allEntries;

    enum ACCOUNT_TYPE {
        ASSET,
        LIABILITY,
        SHAREHOLDER_EQUITY,
        TEMPORARY
    }

    enum ACTION {
        DEBIT,
        CREDIT
    }

    // Each user maintains a list of his/her personal accounts.
    struct LedgerAccount {
        address owner;
        uint256 id;
        ACCOUNT_TYPE accountType;
        string accountName;
        uint256 deleted;
    }

    // A ledger transaction is valid is credit equals debit amount
    // A transaction consists of >= 2 ledger entries
    struct LedgerTransaction {
        address owner;
        int256 date;
        uint256 id;
        uint256[] entries;
        uint256 deleted;
    }

    // Ledger entry is the building blocks of transaction
    // A minimum transaction consists of one credit and one debit entry
    struct LedgerEntry {
        uint256 id;
        uint256 ledgerAccountId;
        ACTION action;
        uint256 amount;
    }

    event AddLedgerAccount(
        address indexed _owner,
        uint256 _accountId,
        string _accountName
    );
    event UpdateLedgerAccount(
        address indexed _owner,
        uint256 _accountId,
        string _accountName
    );
    event DeleteLedgerAccount(address indexed _owner, uint256 _accountId);
    event AddLedgerTransaction(address indexed _owner, uint256 _transactionId);
    event UpdateLedgerTransaction(
        address indexed _owner,
        uint256 _oldId,
        uint256 _newId
    );
    event DeleteLedgerTransaction(
        address indexed _owner,
        uint256 _transactionId
    );

    function addLedgerAccount(
        string memory _accountName,
        ACCOUNT_TYPE _accountType
    ) public {
        for (uint256 i = 0; i < userAccountsMap[msg.sender].length; i++) {
            LedgerAccount memory existAcc = allAccounts[
                userAccountsMap[msg.sender][i]
            ];
            require(
                keccak256(bytes(existAcc.accountName)) !=
                    keccak256(bytes(_accountName)),
                "Account exists!"
            );
        }
        uint256 nextId = allAccounts.length;
        LedgerAccount memory newAccount = LedgerAccount(
            msg.sender,
            nextId,
            _accountType,
            _accountName,
            0
        );
        allAccounts.push(newAccount);
        userAccountsMap[msg.sender].push(nextId);
        emit AddLedgerAccount(msg.sender, nextId, _accountName);
    }

    function updateLedgerAccount(uint256 _accountId, string memory _accountName)
        public
    {
        require(_accountId < allAccounts.length, "Account does not exist!");
        LedgerAccount memory acc = allAccounts[_accountId];
        require(acc.owner == msg.sender, "Not owner of account!");
        acc.accountName = _accountName;
        emit UpdateLedgerAccount(msg.sender, _accountId, _accountName);
    }

    function addLedgerTransaction(
        int256 _date,
        LedgerEntry[] calldata _ledgerEntries
    ) public {
        require(
            validateLedgerTransaction(_ledgerEntries) == true,
            "Invalid transaction!"
        );

        uint256 nextTransactionId = allTransactions.length;
        uint256 nextEntryId = allEntries.length;

        allTransactions.push(
            LedgerTransaction({
                owner: msg.sender,
                date: _date,
                id: nextTransactionId,
                deleted: 0,
                entries: new uint256[](0)
            })
        );
        LedgerTransaction storage latest = allTransactions[nextTransactionId];

        for (uint256 i = 0; i < _ledgerEntries.length; i++) {
            LedgerEntry memory entry = _ledgerEntries[i];
            entry.id = nextEntryId + i;
            allEntries.push(entry);
            latest.entries.push(entry.id);
            accountTransactionCountMap[entry.ledgerAccountId] += 1;
        }
        userTransactionsMap[msg.sender].push(nextTransactionId);

        emit AddLedgerTransaction(msg.sender, nextTransactionId);
    }

    function updateTransaction(
        uint256 _transactionId,
        int256 _date,
        LedgerEntry[] calldata _ledgerEntries
    ) public {
        require(_transactionId < allTransactions.length);
        deleteTransactionById(_transactionId);
        addLedgerTransaction(_date, _ledgerEntries);

        uint256[] storage transactionIds = userTransactionsMap[msg.sender];
        emit UpdateLedgerTransaction(
            msg.sender,
            _transactionId,
            transactionIds[transactionIds.length - 1]
        );
    }

    function deleteTransactionById(uint256 _transactionId) public {
        LedgerTransaction storage txn = allTransactions[_transactionId];
        require(txn.owner == msg.sender, "Not owner of transaction!");
        for (uint256 i = 0; i < txn.entries.length; i++) {
            LedgerEntry memory entry = allEntries[txn.entries[i]];
            accountTransactionCountMap[entry.ledgerAccountId] -= 1;
        }
        txn.deleted = 1;
        emit DeleteLedgerTransaction(msg.sender, _transactionId);
    }

    function deleteAccountById(uint256 _accountId) public {
        LedgerAccount storage acc = allAccounts[_accountId];
        require(acc.owner == msg.sender, "Not owner of account!");
        require(
            accountTransactionCountMap[acc.id] == 0,
            "Account cannot have transactions!"
        );
        acc.deleted = 1;
        emit DeleteLedgerAccount(msg.sender, _accountId);
    }

    function validateLedgerTransaction(LedgerEntry[] calldata _ledgerEntries)
        internal
        returns (bool)
    {
        uint256 debit = 0;
        uint256 credit = 0;
        for (uint256 i = 0; i < _ledgerEntries.length; i++) {
            LedgerEntry memory entry = _ledgerEntries[i];
            require(
                entry.ledgerAccountId < allAccounts.length,
                "Unknown ledger account!"
            );
            require(
                allAccounts[entry.ledgerAccountId].owner == msg.sender,
                "Not owner of ledger account!"
            );
            if (entry.action == ACTION.DEBIT) {
                debit = debit + entry.amount;
            } else if (entry.action == ACTION.CREDIT) {
                credit = credit + entry.amount;
            }
        }
        require(credit == debit, "Credit must equal debit!");
        return true;
    }

    function getUserAccounts() public view returns (uint256[] memory) {
        return userAccountsMap[msg.sender];
    }

    function getAccountById(uint256 _ledgerAccountId)
        public
        view
        returns (LedgerAccount memory)
    {
        LedgerAccount memory acc = allAccounts[_ledgerAccountId];
        return acc;
    }

    function getUserTransaction() public view returns (uint256[] memory) {
        return userTransactionsMap[msg.sender];
    }

    function getTransactionById(uint256 _transactionId)
        public
        view
        returns (LedgerTransaction memory)
    {
        LedgerTransaction memory txn = allTransactions[_transactionId];
        return txn;
    }

    function getEntryById(uint256 _entryId)
        public
        view
        returns (LedgerEntry memory)
    {
        LedgerEntry memory entry = allEntries[_entryId];
        return entry;
    }

    function getUserEntriesForTransaction(uint256 transactionId)
        public
        view
        returns (LedgerEntry[] memory)
    {
        LedgerTransaction memory trans = allTransactions[transactionId];

        uint256 count = trans.entries.length;
        LedgerEntry[] memory entries = new LedgerEntry[](count);

        for (uint256 i = 0; i < count; i++) {
            LedgerEntry memory entry = allEntries[trans.entries[i]];
            entries[i] = entry;
        }
        return entries;
    }

    function getAccountReferenceCount(uint256 _ledgerAccountId)
        public
        view
        returns (uint256)
    {
        return accountTransactionCountMap[_ledgerAccountId];
    }

    function getUserAccountCount() public view returns (uint256) {
        return userAccountsMap[msg.sender].length;
    }

    function getUserTransactionCount() public view returns (uint256) {
        return userTransactionsMap[msg.sender].length;
    }

    function getAccountCount() public view returns (uint256) {
        return allAccounts.length;
    }

    function getTransactionCount() public view returns (uint256) {
        return allTransactions.length;
    }

    function getEntriesCount() public view returns (uint256) {
        return allEntries.length;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "Context.sol";

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
        return msg.data;
    }
}