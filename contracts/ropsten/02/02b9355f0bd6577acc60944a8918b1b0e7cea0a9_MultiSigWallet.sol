// 0xca35b7d915458ef540ade6068dfe2f44e8fa733c, "rocky", 5, 1, "aaaa"
// 0x41C23D5bb81905Cb6bD71Debf0610aC348AaF693, "rocky", 5, 1, "aaaa"
// "0x117Db95382362AeAa5Db527989918F7868C5D693", "666666", 5, 2, "1111"

pragma solidity ^0.4.17;

contract MultiSigWallet {

    /*
     *  Events
     */
    event EventCreate(address indexed sender, 
                        uint256 indexed _total, 
                        uint256 indexed _required, 
                        string _owner_name, 
                        string comment,
                        uint256 ret_code);

    event EventConfirmation(address indexed sender, 
                            uint256 indexed transactionId, 
                            uint256 choice,
                            string comment,
                            uint256 ret_code);

    event EventExpired(address indexed sender, 
                        uint256 indexed transactionId, 
                        uint256 curr_time,
                        uint256 valid_time);

    event EventSubmission(address indexed sender,
                        uint256 indexed transactionId);

    event EventExecution(address indexed sender,
                        uint256 indexed transactionId,
                        uint256 ret_code);

    event EventDeposit(address indexed sender, 
                        uint256 value);

    event EventJoin(address indexed sender, 
                            string comment,
                            uint256 ret_code);

    /*
     *  Constants
     */
    uint256 constant public MAX_OWNER_COUNT = 50;
    uint256 constant internal APPROVE = 1;
    uint256 constant internal DECLINE = 2;

    uint256 constant internal ERR_CODE_SUCC = 0;
    uint256 constant internal ERR_CODE_TOTAL_TOO_LOW = 1;
    uint256 constant internal ERR_CODE_TOTAL_TOO_HIGH = 2;
    uint256 constant internal ERR_CODE_REQUIRE_TOO_LOW = 3;
    uint256 constant internal ERR_CODE_REQUIRE_TOO_HIGH = 4;
    uint256 constant internal ERR_CODE_TRANSACTION_EXEC_FAIL = 5;
    uint256 constant internal ERR_CODE_ADD_EXISTED_OWNER = 6;
    uint256 constant internal ERR_CODE_ADD_OWNER_REACH_UPLIMIT = 7;
    uint256 constant internal ERR_CODE_TRANSFER_NOT_EXIST = 8;
    uint256 constant internal ERR_CODE_TRANSFER_DUPLICATE_CONFIRM = 9;
    uint256 constant internal ERR_CODE_TRANSACTION_DUPLICATE_EXEC = 10;

    /*
     *  Storage
     */
    mapping (uint256 => Transaction) public transactions;
    mapping (uint256 => mapping (address => bool)) public approves;
    mapping (address => bool) public isOwner;
    OwnerInfo[] public owners;
    uint256 public total;
    uint256 public required;
    uint256 public transactionCount;
    string public create_comment;
    uint256 public create_time;

    struct Transaction {
        address destination;
        uint256 value;
        uint256 valid_time;
        string comment;
        bytes data;
        bool executed;
    }
    
    struct OwnerInfo {
        address owner_address;
        string owner_name;
        uint256 add_time;
    }

    /*
     *  Modifiers
     */
    modifier ownerExists(address owner) {
        require(isOwner[owner]);
        _;
    }

    modifier hasApproved(uint256 transactionId, address owner) {
        require(approves[transactionId][owner]);
        _;
    }

    modifier notNull(address _address) {
        require(_address != 0);
        _;
    }

    modifier verifyCreation(uint256 initOwnerCount, uint256 _required, uint256 _total) {
        require(_total <= MAX_OWNER_COUNT
            && initOwnerCount <= _total
            && _required <= _total
            && _required != 0
            && initOwnerCount != 0);
        _;
    }

    modifier validOwnerIndex(uint256 index){
        require(index >= 0 && index < owners.length);
        _;
    }

    /// @dev Fallback function allows to deposit ether.
    function() public payable
    {
        if (msg.value > 0)
            EventDeposit(msg.sender, msg.value);
    }

    /*
     * Public functions
     */
    /// @dev Contract constructor sets initial owners and required number of approves.
    /// @param _owner_addr List of initial owners.
    /// @param _required Number of required approves.
    function MultiSigWallet(address _owner_addr,
                string _owner_name,
                uint256 _total,
                uint256 _required, 
                string comment)
        public
        verifyCreation(1, _required, _total)
    {
        require(_owner_addr == msg.sender);
        require(!isOwner[_owner_addr] && _owner_addr != 0);

        isOwner[_owner_addr] = true;

        owners.length++;
        owners[owners.length - 1].owner_address = _owner_addr;
        owners[owners.length - 1].owner_name = _owner_name;
        owners[owners.length - 1].add_time = now;

        total = _total;
        required = _required;
        create_comment = comment;
        create_time = now;
        EventCreate(_owner_addr, _total, _required, _owner_name, comment, ERR_CODE_SUCC);
    }

    // "0x117Db95382362AeAa5Db527989918F7868C5D693", "xxxx", "xxxx"
    // "0x14723a09acff6d2a60dcdf7aa4aff308fddc160c", "xxxx", "xxxx"
    /// @dev Allows to add a new owner. Transaction has to be sent by wallet.
    /// @param _owner_addr Address of new owner.
    function join(address _owner_addr, string _owner_name, string comment)
        public
        notNull(_owner_addr)
    {
        require(_owner_addr == msg.sender);

        //owner existed
        if (isOwner[_owner_addr])
        {
            EventJoin(_owner_addr, comment, ERR_CODE_ADD_EXISTED_OWNER);
            return;
        }

        //owner reach uplimit
        if (owners.length + 1 > total)
        {
            EventJoin(_owner_addr, comment, ERR_CODE_ADD_OWNER_REACH_UPLIMIT);
            return;
        }

        isOwner[_owner_addr] = true;
        owners.length++;
        owners[owners.length - 1].owner_address = _owner_addr;
        owners[owners.length - 1].owner_name = _owner_name;
        owners[owners.length - 1].add_time = now;

        EventJoin(_owner_addr, comment, ERR_CODE_SUCC);
    }

    // "0x0367f6b8D2aDA776D6833557c374A39Ab0C4af51", 1, 1535896554, "xxx", ""
    // "0x14723a09acff6d2a60dcdf7aa4aff308fddc160c", 1, 1535896554, "xxx", ""
    function sendTransaction(address _to_addr, 
                            uint256 value,
                            uint256 valid_time, 
                            string comment, 
                            bytes data)
        public
        returns (uint256 transactionId)
    {
        transactionId = addTransaction(_to_addr, value, valid_time, comment, data);
        approveTransaction(transactionId, APPROVE, comment);
    }

    // 0, 1, "bbb"
    /// @dev Allows an owner to approve a transaction.
    /// @param transactionId Transaction ID.
    function approveTransaction(uint256 transactionId, uint256 choice, string comment)
        public
        ownerExists(msg.sender)
    {
        //check if tx existed
        if (transactions[transactionId].destination == 0)
        {
            EventConfirmation(msg.sender, transactionId, choice, comment, ERR_CODE_TRANSFER_NOT_EXIST);
            return;
        }

        //check if tx has hasApproved by curr onwer
        if (approves[transactionId][msg.sender])
        {
            EventConfirmation(msg.sender, transactionId, choice, comment, ERR_CODE_TRANSFER_DUPLICATE_CONFIRM);
            return;
        }

        Transaction storage txn = transactions[transactionId];
        if (!isNotExpired(now, txn.valid_time))
        {
            // expired event
            EventExpired(msg.sender, transactionId, now, txn.valid_time);
        }
        else
        {
            if(!isApproveConfirm(choice))
            {
                // DECLINE event
                approves[transactionId][msg.sender] = false;
                EventConfirmation(msg.sender, transactionId, choice, comment, ERR_CODE_SUCC);
            }
            else
            {
                // APPROVE event
                approves[transactionId][msg.sender] = true;
                EventConfirmation(msg.sender, transactionId, choice, comment, ERR_CODE_SUCC);
                executeTransaction(transactionId);
            }
        }
    }

    /// @dev Allows anyone to execute a hasApproved transaction.
    /// @param transactionId Transaction ID.
    function executeTransaction(uint256 transactionId)
        internal
        ownerExists(msg.sender)
        hasApproved(transactionId, msg.sender)
    {
        //check if tx has been executed
        if (transactions[transactionId].executed)
        {
            EventExecution(msg.sender, transactionId, ERR_CODE_TRANSACTION_DUPLICATE_EXEC);
            return;
        }

        if (isConfirmed(transactionId)) 
        {
            Transaction storage txn = transactions[transactionId];
            txn.executed = true;
            if (txn.destination.call.value(txn.value)(txn.data))
                EventExecution(msg.sender, transactionId, ERR_CODE_SUCC);
            else 
            {
                EventExecution(msg.sender, transactionId, ERR_CODE_TRANSACTION_EXEC_FAIL);
                txn.executed = false;
            }
        }
    }

    /// @dev Returns the approveation status of a transaction.
    /// @param transactionId Transaction ID.
    /// @return Confirmation status.
    function isConfirmed(uint256 transactionId)
        public
        constant
        returns (bool)
    {
        uint256 count = 0;
        for (uint256 i=0; i<owners.length; i++) {
            if (approves[transactionId][owners[i].owner_address])
                count += 1;
            if (count >= required)
                return true;
        }
    }

    function isNotExpired(uint256 curr_time, uint256 valid_time) 
        internal 
        pure 
        returns (bool) 
    {
        if (valid_time <= curr_time)
            return false;
        else
            return true;
    }
    
    function isApproveConfirm(uint256 choice)
        internal
        pure
        returns (bool)
    {
        if (choice == APPROVE)
        {
            return true;
        }
        else
        {
            return false;
        }
    }

    /*
     * Internal functions
     */
    /// @dev Adds a new transaction to the transaction mapping, if transaction does not exist yet.
    /// @param destination Transaction target address.
    /// @param value Transaction ether value.
    /// @param data Transaction data payload.
    /// @return Returns transaction ID.
    function addTransaction(address destination, 
                            uint256 value, 
                            uint256 valid_time, 
                            string comment, 
                            bytes data)
        internal
        notNull(destination)
        returns (uint256 transactionId)
    {
        transactionId = transactionCount;
        transactions[transactionId] = Transaction({
            destination: destination,
            value: value,
            valid_time: valid_time,
            comment: comment,
            data: data,
            executed: false
        });
        transactionCount += 1;
        EventSubmission(msg.sender, transactionId);
    }

    /*
     * Web3 call functions
     */
    /// @dev Returns number of approves of a transaction.
    /// @param transactionId Transaction ID.
    /// @return Number of approves.
    function getConfirmationCount(uint256 transactionId)
        public
        constant
        returns (uint256 count)
    {
        for (uint256 i=0; i<owners.length; i++)
            if (approves[transactionId][owners[i].owner_address])
                count += 1;
    }

    /// @dev Returns total number of transactions after filers are applied.
    /// @param pending Include pending transactions.
    /// @param executed Include executed transactions.
    /// @return Total number of transactions after filters are applied.
    function getTransactionCount(bool pending, bool executed)
        public
        constant
        returns (uint256 count)
    {
        for (uint256 i=0; i<transactionCount; i++)
            if (   pending && !transactions[i].executed
                || executed && transactions[i].executed)
                count += 1;
    }

    /// @dev Returns count of owners.
    /// @return owner count.
    function getOwnersCount()
        public
        constant
        returns (uint256)
    {
        return owners.length;
    }

    function getOwnerInfoByIndex(uint256 index)
        public
        constant
        validOwnerIndex(index)
        returns (address, string, uint256)
    {
        return (owners[index].owner_address, owners[index].owner_name, owners[index].add_time);
    }

    function getWalletSetting()
        public
        view
        returns (address, uint256, uint256, uint256, uint256, string, uint256)
    {
        return (address(this), owners.length, total, required, create_time, create_comment, MAX_OWNER_COUNT);
    }

    /// @dev Returns array with owner addresses, which hasApproved transaction.
    /// @param transactionId Transaction ID.
    /// @return Returns array of owner addresses.
    function getConfirmations(uint256 transactionId)
        public
        constant
        returns (address[] _approves)
    {
        address[] memory approvesTemp = new address[](owners.length);
        uint256 count = 0;
        uint256 i;
        for (i=0; i<owners.length; i++)
            if (approves[transactionId][owners[i].owner_address]) {
                approvesTemp[count] = owners[i].owner_address;
                count += 1;
            }
        _approves = new address[](count);
        for (i=0; i<count; i++)
            _approves[i] = approvesTemp[i];
    }

    /// @dev Returns list of transaction IDs in defined range.
    /// @param from Index start position of transaction array.
    /// @param to Index end position of transaction array.
    /// @param pending Include pending transactions.
    /// @param executed Include executed transactions.
    /// @return Returns array of transaction IDs.
    function getTransactionIds(uint256 from, uint256 to, bool pending, bool executed)
        public
        constant
        returns (uint256[] _transactionIds)
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
    }
}