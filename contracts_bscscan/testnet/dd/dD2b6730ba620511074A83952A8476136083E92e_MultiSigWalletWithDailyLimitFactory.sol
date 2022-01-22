/**
 *Submitted for verification at BscScan.com on 2022-01-21
*/

// File: contracts/Factory.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract Factory {

    /*
     *  Events
     */
    event ContractInstantiation(address sender, address instantiation);

    /*
     *  Storage
     */
    mapping(address => bool) public isInstantiation;
    mapping(address => address[]) public instantiations;

    /*
     * Public functions
     */
    /// @dev Returns number of instantiations by creator.
    /// @param creator Contract creator.
    /// @return Returns number of instantiations by creator.
    function getInstantiationCount(address creator)
        public
        view
        returns (uint)
    {
        return instantiations[creator].length;
    }

    /*
     * Internal functions
     */
    /// @dev Registers contract in factory registry.
    /// @param instantiation Address of contract instantiation.
    function register(address instantiation)
        internal
    {
        isInstantiation[instantiation] = true;
        instantiations[msg.sender].push(instantiation);
        emit ContractInstantiation(msg.sender, instantiation);
    }
}

// File: contracts/MultiSigWallet.sol

pragma solidity ^0.8.0;


/// @title Multisignature wallet - Allows multiple parties to agree on transactions before execution.
/// @author Stefan George - <[email protected]>
contract MultiSigWallet {

    /*
     *  Events
     */
    event Confirmation(uint8 group, uint256 indexed transactionId);
    event Revocation(uint8 group, uint256 indexed transactionId);
    event Submission(uint256 indexed transactionId);
    event Execution(uint256 indexed transactionId);
    event ExecutionFailure(uint256 indexed transactionId);
    event Deposit(address indexed sender, uint256 value);
    event OwnerAddition(address indexed owner, uint8 group);
    event OwnerRemoval(address indexed owner, uint8 group);
    event RequirementChange(uint8 required);

    /*
     *  Constants
     */
    uint8 constant public MAX_GROUP_COUNT = 50;

    /*
     *  Storage
     */
    mapping (uint256 => Transaction) public transactions;
    mapping (uint256 => mapping (uint8 => bool)) public confirmations;

    // 组对应的人数
    mapping (uint8 => uint8) public groupNum;
    // 用户对应组
    mapping (address => uint8) public ownerToGroup;
    // 组
    uint8[] public groups;
    uint8 public required;
    uint256 public transactionCount;

    struct Transaction {
        address destination;
        uint256 value;
        bytes data;
        bool executed;
    }

    /*
     *  Modifiers
     */
    modifier onlyWallet() {
        require(msg.sender == address(this));
        _;
    }

    modifier ownerDoesNotExist(address owner) {
        require(ownerToGroup[owner] == 0);
        _;
    }

    modifier ownerExists(address owner) {
        require(ownerToGroup[owner] > 0);
        _;
    }

    modifier ownerExistGroups(address owner, uint8 group) {
        require(ownerToGroup[owner] == group);
        _;
    }

     modifier groupGteOne(uint8 group) {
        require(groupNum[group] > 1);
        _;
    }

    modifier transactionExists(uint256 transactionId) {
        require(transactions[transactionId].destination != address(0));
        _;
    }

    modifier confirmed(uint256 transactionId, address owner) {
        require(confirmations[transactionId][ownerToGroup[owner]]);
        _;
    }

    modifier notConfirmed(uint256 transactionId, address owner) {
        require(!confirmations[transactionId][ownerToGroup[owner]]);
        _;
    }

    modifier notExecuted(uint256 transactionId) {
        require(!transactions[transactionId].executed);
        _;
    }

    modifier notNull(address _address) {
        require(_address != address(0));
        _;
    }

    modifier validRequirement(uint256 groupCount, uint8 _required) {
        require(groupCount <= MAX_GROUP_COUNT
            && _required <= groupCount
            && _required != 0
            && groupCount != 0);
        _;
    }

    /// @dev Fallback function allows to deposit ether.
    receive() external payable {
        if(msg.value > 0) 
        emit Deposit(msg.sender, msg.value);
    }

    /*
     * Public functions
     */
    /// @dev Contract constructor sets initial owners and required number of confirmations.
    /// @param _owners List of initial owners.
    /// @param _required Number of required confirmations.
    constructor(address[] memory _owners, uint8 _group, uint8 _required) validRequirement(_owners.length, _required) {
        groups = new uint8[](_owners.length);
        for (uint8 i=0; i<_owners.length; i++) {
            require(ownerToGroup[_owners[i]] == 0 && _owners[i] != address(0));
            groups[i] = i%_group + 1;
            ownerToGroup[_owners[i]] = groups[i];
            groupNum[groups[i]]++;
        }
        required = _required;
    }

    /// @dev Allows to add a new owner. Transaction has to be sent by wallet.
    /// @param owner Address of new owner.
    function addOwner(address owner, uint8 group)
        public
        onlyWallet
        ownerDoesNotExist(owner)
        notNull(owner)
    {   
        // groupToOwner[group] = owner;
        ownerToGroup[owner] = group;
        groupNum[group]++;
        emit OwnerAddition(owner, group);
    }

    /// @dev Allows to remove an owner. Transaction has to be sent by wallet.
    /// @param owner Address of owner.
    function removeOwner(address owner, uint8 group)
        public
        onlyWallet
        ownerExistGroups(owner, group)
        groupGteOne(group)
    {
        ownerToGroup[owner] = 0;
        groupNum[group]--;
        emit OwnerRemoval(owner, group);
    }

    /// @dev Allows to replace an owner with a new owner. Transaction has to be sent by wallet.
    /// @param owner Address of owner to be replaced.
    /// @param newOwner Address of new owner.
    function replaceOwner(address owner, address newOwner)
        public
        onlyWallet
        ownerExists(owner)
        ownerDoesNotExist(newOwner)
    {
        ownerToGroup[newOwner] = ownerToGroup[owner];
        ownerToGroup[owner] = 0;
        emit OwnerRemoval(owner, ownerToGroup[newOwner]);
        emit OwnerAddition(newOwner, ownerToGroup[newOwner]);
    }

    /// @dev Allows to change the number of required confirmations. Transaction has to be sent by wallet.
    /// @param _required Number of required confirmations.
    function changeRequirement(uint8 _required)
        public
        onlyWallet
        validRequirement(groups.length, _required)
    {
        required = _required;
        emit RequirementChange(_required);
    }

    // @dev Allows an owner to submit and confirm a transaction.
    // @param destination Transaction target address.
    // @param value Transaction ether value.
    // @param data Transaction data payload.
    // @return Returns transaction ID.
    function submitTransaction(address destination, uint256 value, bytes memory data)
        public
        returns (uint256 transactionId)
    {
        transactionId = addTransaction(destination, value, data);
        confirmTransaction(transactionId);
    }

    /// @dev Allows an owner to confirm a transaction.
    /// @param transactionId Transaction ID.
    function confirmTransaction(uint256 transactionId)
        public
        ownerExists(msg.sender)
        transactionExists(transactionId)
        notConfirmed(transactionId, msg.sender)
    {
        confirmations[transactionId][ownerToGroup[msg.sender]] = true;
        emit Confirmation(ownerToGroup[msg.sender], transactionId);
        executeTransaction(transactionId);
    }

    /// @dev Allows an owner to revoke a confirmation for a transaction.
    /// @param transactionId Transaction ID.
    function revokeConfirmation(uint256 transactionId)
        public
        ownerExists(msg.sender)
        confirmed(transactionId, msg.sender)
        notExecuted(transactionId)
    {
        confirmations[transactionId][ownerToGroup[msg.sender]] = false;
        emit Revocation(ownerToGroup[msg.sender], transactionId);
    }

    /// @dev Allows anyone to execute a confirmed transaction.
    /// @param transactionId Transaction ID.
    function executeTransaction(uint256 transactionId)
        public virtual
        ownerExists(msg.sender)
        confirmed(transactionId, msg.sender)
        notExecuted(transactionId)
    {
        if (isConfirmed(transactionId)) {
            Transaction storage txn = transactions[transactionId];
            txn.executed = true;
            if (external_call(txn.destination, txn.value, txn.data))
                emit Execution(transactionId);
            else {
                emit ExecutionFailure(transactionId);
                txn.executed = false;
            }
        }
    }

    // call has been separated into its own function in order to take advantage
    // of the Solidity's code generator to produce a loop that copies tx.data into memory.
    function external_call(address destination, uint256 value, bytes memory data) internal virtual returns (bool) {
        (bool success, ) = destination.call{value: value}(data);
        require(success, "tx failed");
        return success;
    }

    // @dev Returns the confirmation status of a transaction.
    // @param transactionId Transaction ID.
    // @return Confirmation status.
    function isConfirmed(uint256 transactionId)
        public
        view
        returns (bool)
    {
        uint8 count = 0;
        for (uint8 i=0; i<groups.length; i++) {
            if (confirmations[transactionId][groups[i]])
                count += 1;
            if (count == required)
                return true;
        }
        return false;
    }

    /*
     * Internal functions
     */
    // @dev Adds a new transaction to the transaction mapping, if transaction does not exist yet.
    // @param destination Transaction target address.
    // @param value Transaction ether value.
    // @param data Transaction data payload.
    // @return Returns transaction ID.
    function addTransaction(address destination, uint256 value, bytes memory data)
        internal
        notNull(destination)
        returns (uint256 transactionId)
    {
        transactionId = transactionCount;
        transactions[transactionId] = Transaction({
            destination: destination,
            value: value,
            data: data,
            executed: false
        });
        transactionCount += 1;
        emit Submission(transactionId);
    }

    /*
     * Web3 call functions
     */
    // @dev Returns number of confirmations of a transaction.
    // @param transactionId Transaction ID.
    // @return Number of confirmations.
    function getConfirmationCount(uint256 transactionId)
        public
        view
        returns (uint8 count)
    {
        for (uint8 i=0; i<groups.length; i++) {
            if (confirmations[transactionId][groups[i]])
                count += 1;
        }
        return count;
            
    }

    // @dev Returns total number of transactions after filers are applied.
    // @param pending Include pending transactions.
    // @param executed Include executed transactions.
    // @return Total number of transactions after filters are applied.
    function getTransactionCount(bool pending, bool executed)
        public
        view
        returns (uint256 count)
    {
        for (uint256 i=0; i<transactionCount; i++) {
            if (pending && !transactions[i].executed
                || executed && transactions[i].executed)
                count += 1;
        }
        return count;
            
    }

    // @dev Returns list of owners.
    // @return List of owner addresses.
    function getGroups()
        public
        view
        returns (uint8[] memory)
    {
        return groups;
    }

    // @dev Returns array with owner addresses, which confirmed transaction.
    // @param transactionId Transaction ID.
    // @return Returns array of owner addresses.
    function getConfirmations(uint256 transactionId)
        public
        view
        returns (uint8[] memory _confirmations)
    {
        uint8[] memory confirmationsTemp = new uint8[](groups.length);
        uint8 count = 0;
        uint8 i;
        for (i=0; i<groups.length; i++)
            if (confirmations[transactionId][groups[i]]) {
                confirmationsTemp[count] = groups[i];
                count += 1;
            }
        _confirmations = new uint8[](count);
        for (i=0; i<count; i++)
            _confirmations[i] = confirmationsTemp[i];
        return _confirmations;
    }

    // @dev Returns list of transaction IDs in defined range.
    // @param from Index start position of transaction array.
    // @param to Index end position of transaction array.
    // @param pending Include pending transactions.
    // @param executed Include executed transactions.
    // @return Returns array of transaction IDs.
    function getTransactionIds(uint256 from, uint256 to, bool pending, bool executed)
        public
        view
        returns (uint256[] memory _transactionIds)
    {
        uint256[] memory transactionIdsTemp = new uint256[](transactionCount);
        uint256 count = 0;
        uint256 i;
        for (i=0; i<transactionCount; i++)
            if (   pending && !transactions[i].executed
                || executed && transactions[i].executed)
            {
                transactionIdsTemp[count] = i;
                count += 1;
            }
        _transactionIds = new uint256[](to - from);
        for (i=from; i<to; i++)
            _transactionIds[i - from] = transactionIdsTemp[i];
        return _transactionIds;
    }
}

// File: contracts/MultiSigWalletWithDailyLimit.sol

pragma solidity ^0.8.0;



/// @title Multisignature wallet with daily limit - Allows an owner to withdraw a daily limit without multisig.
/// @author Stefan George - <[email protected]>
contract MultiSigWalletWithDailyLimit is MultiSigWallet {

    /*
     *  Events
     */
    event DailyLimitChange(uint dailyLimit);

    /*
     *  Storage
     */
    uint public dailyLimit;
    uint public lastDay;
    uint public spentToday;

    /*
     * Public functions
     */
    // @dev Contract constructor sets initial owners, required number of confirmations and daily withdraw limit.
    // @param _owners List of initial owners.
    // @param _required Number of required confirmations.
    // @param _dailyLimit Amount in wei, which can be withdrawn without confirmations on a daily basis.
    constructor(address[] memory owners_, uint8 group_, uint8 required_, uint dailyLimit_) MultiSigWallet(owners_, group_, required_) {
        dailyLimit = dailyLimit_;
    }

    // @dev Allows to change the daily limit. Transaction has to be sent by wallet.
    // @param _dailyLimit Amount in wei.
    function changeDailyLimit(uint _dailyLimit)
        public
        onlyWallet
    {
        dailyLimit = _dailyLimit;
        emit DailyLimitChange(_dailyLimit);
    }

    // @dev Allows anyone to execute a confirmed transaction or ether withdraws until daily limit is reached.
    // @param transactionId Transaction ID.
    function executeTransaction(uint transactionId)
        public override
        ownerExists(msg.sender)
        confirmed(transactionId, msg.sender)
        notExecuted(transactionId)
    {
        Transaction storage txn = transactions[transactionId];
        bool _confirmed = isConfirmed(transactionId);
        if (_confirmed || txn.data.length == 0 && isUnderLimit(txn.value)) {
            txn.executed = true;
            if (!_confirmed)
                spentToday += txn.value;
            if (external_call(txn.destination, txn.value, txn.data))
                emit Execution(transactionId);
            else {
                emit ExecutionFailure(transactionId);
                txn.executed = false;
                if (!_confirmed)
                    spentToday -= txn.value;
            }
        }
    }

    /*
     * Internal functions
     */
    /// @dev Returns if amount is within daily limit and resets spentToday after one day.
    /// @param amount Amount to withdraw.
    /// @return Returns if amount is under daily limit.
    function isUnderLimit(uint amount)
        internal
        returns (bool)
    {
        if (block.timestamp > lastDay + 24 hours) {
            lastDay = block.timestamp;
            spentToday = 0;
        }
        if (spentToday + amount > dailyLimit || spentToday + amount < spentToday)
            return false;
        return true;
    }

    /*
     * Web3 call functions
     */
    /// @dev Returns maximum withdraw amount.
    /// @return Returns amount.
    function calcMaxWithdraw()
        public
        view
        returns (uint)
    {
        if (block.timestamp > lastDay + 24 hours)
            return dailyLimit;
        if (dailyLimit < spentToday)
            return 0;
        return dailyLimit - spentToday;
    }
}

// File: contracts/MultiSigWalletWithDailyLimitFactory.sol

pragma solidity ^0.8.0;




/// @title Multisignature wallet factory for daily limit version - Allows creation of multisig wallet.
/// @author Stefan George - <[email protected]>
contract MultiSigWalletWithDailyLimitFactory is Factory {

    MultiSigWallet multiSigWallet;

    /*
     * Public functions
     */
    // @dev Allows verified creation of multisignature wallet.
    // @param _owners List of initial owners.
    // @param _required Number of required confirmations.
    // @param _dailyLimit Amount in wei, which can be withdrawn without confirmations on a daily basis.
    // @return Returns wallet address.
    function create(address[] memory _owners, uint8 _group, uint8 _required, uint _dailyLimit)
        public
        returns (address)
    {
        multiSigWallet = new MultiSigWalletWithDailyLimit(_owners, _group, _required, _dailyLimit);
        register(address(multiSigWallet));
        return address(multiSigWallet);
    }
}