// 0xca35b7d915458ef540ade6068dfe2f44e8fa733c, &quot;rocky&quot;, 5, 1, &quot;aaaa&quot;, 1
// 0x41C23D5bb81905Cb6bD71Debf0610aC348AaF693, &quot;rocky&quot;, 5, 2, &quot;aaaa&quot;, 1
// 0x117Db95382362AeAa5Db527989918F7868C5D693, &quot;666666&quot;, 5, 2, &quot;1111&quot;, 1

pragma solidity ^0.4.24;

contract MultiSigWallet {

    /*
     *  Events
     */
    event EventCreate(address   indexed _sender,
                        uint256 indexed _total,
                        uint256 indexed _required,
                        string  _creator_name,
                        string  _comment,
                        uint256 _timestamp,
                        uint256 _ret_code);

    event EventCancelCreate(address indexed _sender,
                            uint256 _timestamp,
                            uint256 _ret_code);

    event EventJoin(address indexed _sender,
                    string  _joiner_name,
                    string  _comment,
                    uint256 _timestamp,
                    uint256 _ret_code);

    event EventSubmission(address   indexed _sender,
                        uint256     indexed _transactionId,
                        address     _destination,
                        uint256     _value,
                        uint256     _valid_time,
                        string      _comment,
                        uint256     _timestamp);

    event EventConfirmation(address indexed _sender,
                            uint256 indexed _transactionId,
                            address _destination,
                            uint256 _choice,
                            string  _comment,
                            uint256 _timestamp,
                            uint256 _ret_code);

    event EventExecution(address    indexed _sender,
                        uint256     indexed _transactionId,
                        address     _destination,
                        uint256     _timestamp,
                        uint256     _value,
                        uint256     _ret_code);

    event EventDeposit(address  indexed _sender,
                        uint256 _value,
                        uint256 _timestamp);

    /*
     *  Constants
     */
    uint256 constant public MAX_OWNER_COUNT = 50;                   //最大的成员数量
    uint256 constant internal APPROVE = 1;                          //同意交易
    uint256 constant internal DECLINE = 2;                          //拒绝交易

    uint256 constant internal ERR_CODE_SUCC = 0;                            //成功
    uint256 constant internal ERR_CODE_TRANSACTION_EXEC_FAIL = 1;           //钱包转账交易执行失败
    uint256 constant internal ERR_CODE_ADD_EXISTED_OWNER = 2;               //加入一个已存在的成员
    uint256 constant internal ERR_CODE_ADD_OWNER_REACH_UPLIMIT = 3;         //成员已满
    uint256 constant internal ERR_CODE_TRANSFER_NOT_EXIST = 4;              //转账交易不存在
    uint256 constant internal ERR_CODE_TRANSFER_DUPLICATE_CONFIRM = 5;      //转账交易重复确认
    uint256 constant internal ERR_CODE_TRANSACTION_DUPLICATE_EXEC = 6;      //转账交易重复执行
    uint256 constant internal ERR_CODE_TRANSFER_EXPIRED = 7;                //转账交易过期

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
    address public creator;
    string public creator_name;

    bool public is_cancel;

    struct Transaction {
        address destination;
        uint256 value;
        uint256 valid_time;
        string comment;
        uint256 timestamp;
        bytes data;
        bool executed;
    }

    struct OwnerInfo {
        address owner_address;
        string owner_name;
        uint256 join_time;
    }

    /*
     *  Modifiers
     */
    modifier ownerExists(address owner) {
        require(isOwner[owner]);
        _;
    }

    modifier ownerNotExists(address owner) {
        require(!isOwner[owner]);
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

    modifier verifyCancelCreation() {
        require(creator == msg.sender
            && owners.length < total);
        _;
    }

    modifier validOwnerIndex(uint256 index){
        require(index >= 0 && index < owners.length);
        _;
    }

    modifier notCancel(){
        require(is_cancel == false);
        _;
    }

    /// @dev Fallback function allows to deposit ether.
    function() public payable
    {
        if (msg.value > 0)
            emit EventDeposit(msg.sender, msg.value, now);
    }

    /// @dev Returns the approveation status of a transaction.
    /// @param transactionId Transaction ID.
    /// @return Confirmation status.
    function isTransferConfirmed(uint256 transactionId)
        internal
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

    function isTransferNotExpired(uint256 curr_time, uint256 valid_time)
        internal
        pure
        returns (bool)
    {
        if (valid_time <= curr_time)
            return false;
        else
            return true;
    }

    function isApprove(uint256 choice)
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
     * Public functions
     */
    /// @dev Contract constructor sets initial owners and required number of approves.
    /// @param _required Number of required approves.
    constructor(string _creator_name,
                uint256 _total,
                uint256 _required,
                string _comment,
                uint256 _creator_is_owner)
        public
        verifyCreation(1, _required, _total)
    {
        if (_creator_is_owner == 1)
        {
            require(!isOwner[msg.sender]);

            isOwner[msg.sender] = true;
            owners.length++;
            owners[owners.length - 1].owner_address = msg.sender;
            owners[owners.length - 1].owner_name = _creator_name;
            owners[owners.length - 1].join_time = now;

            emit EventJoin(msg.sender, _creator_name, _comment, now, ERR_CODE_SUCC);
        }

        total = _total;
        required = _required;
        create_comment = _comment;
        create_time = now;
        creator = msg.sender;
        creator_name = _creator_name;
        is_cancel = false;

        emit EventCreate(msg.sender, _total, _required, _creator_name,
                        _comment, now, ERR_CODE_SUCC);
    }

    function cancelCreation()
        public
        verifyCancelCreation()
        notCancel()
    {
        is_cancel = true;
        emit EventCancelCreate(msg.sender, now, ERR_CODE_SUCC);
    }

    // &quot;0x117Db95382362AeAa5Db527989918F7868C5D693&quot;, &quot;xxxx&quot;, &quot;xxxx&quot;
    // &quot;0x14723a09acff6d2a60dcdf7aa4aff308fddc160c&quot;, &quot;xxxx&quot;, &quot;xxxx&quot;
    /// @dev Allows to add a new owner. Transaction has to be sent by wallet.
    /// @param _joiner_name Name of new owner.
    function join(string _joiner_name, string _comment)
        public
        notCancel()
        ownerNotExists(msg.sender)
    {
        // //owner existed
        // if (isOwner[_joiner_addr])
        // {
        //     emit EventJoin(_joiner_addr, _joiner_name, _comment,
        //                     now, ERR_CODE_ADD_EXISTED_OWNER);
        //     return;
        // }

        //owner reach uplimit
        if (owners.length + 1 > total)
        {
            emit EventJoin(msg.sender, _joiner_name, _comment,
                            now, ERR_CODE_ADD_OWNER_REACH_UPLIMIT);
            return;
        }

        isOwner[msg.sender] = true;
        owners.length++;
        owners[owners.length - 1].owner_address = msg.sender;
        owners[owners.length - 1].owner_name = _joiner_name;
        owners[owners.length - 1].join_time = now;

        emit EventJoin(msg.sender, _joiner_name, _comment, now, ERR_CODE_SUCC);
    }

    // &quot;0x0367f6b8D2aDA776D6833557c374A39Ab0C4af51&quot;, 1, 1535896554, &quot;xxx&quot;, &quot;&quot;
    // &quot;0x14723a09acff6d2a60dcdf7aa4aff308fddc160c&quot;, 1, 1535896554, &quot;xxx&quot;, &quot;&quot;
    function sendTransaction(address _to_addr,
                            uint256 _value,
                            uint256 _valid_time,
                            string _comment,
                            bytes _data)
        public
        notCancel()
        ownerExists(msg.sender)
        returns (uint256 transactionId)
    {
        transactionId = addTransaction(_to_addr, _value, _valid_time, _comment, _data);
        approveTransaction(transactionId, APPROVE, _comment);
    }

    // 0, 1, &quot;bbb&quot;
    /// @dev Allows an owner to approve a transaction.
    /// @param _transactionId Transaction ID.
    function approveTransaction(uint256 _transactionId,
                                uint256 _choice,
                                string _comment)
        public
        notCancel()
        ownerExists(msg.sender)
    {
        //check if tx existed
        if (transactions[_transactionId].destination == 0)
        {
            emit EventConfirmation(msg.sender, _transactionId,
                                    transactions[_transactionId].destination,
                                    _choice, _comment,
                                    now, ERR_CODE_TRANSFER_NOT_EXIST);
            return;
        }

        //check if tx has hasApproved by curr onwer
        if (approves[_transactionId][msg.sender])
        {
            emit EventConfirmation(msg.sender, _transactionId,
                                    transactions[_transactionId].destination,
                                    _choice, _comment,
                                    now, ERR_CODE_TRANSFER_DUPLICATE_CONFIRM);
            return;
        }

        Transaction storage txn = transactions[_transactionId];
        if (!isTransferNotExpired(now, txn.valid_time))
        {
            // expired event
            emit EventConfirmation(msg.sender, _transactionId,
                                    transactions[_transactionId].destination,
                                    _choice, _comment,
                                    now, ERR_CODE_TRANSFER_EXPIRED);
        }
        else
        {
            if(!isApprove(_choice))
            {
                // DECLINE event
                approves[_transactionId][msg.sender] = false;
                emit EventConfirmation(msg.sender, _transactionId,
                                        transactions[_transactionId].destination,
                                        _choice, _comment,
                                        now, ERR_CODE_SUCC);
            }
            else
            {
                // APPROVE event
                approves[_transactionId][msg.sender] = true;
                emit EventConfirmation(msg.sender, _transactionId,
                                        transactions[_transactionId].destination,
                                        _choice, _comment,
                                        now, ERR_CODE_SUCC);
                executeTransaction(_transactionId);
            }
        }
    }

    /// @dev Allows anyone to execute a hasApproved transaction.
    /// @param _transactionId Transaction ID.
    function executeTransaction(uint256 _transactionId)
        internal
        ownerExists(msg.sender)
        hasApproved(_transactionId, msg.sender)
    {
        //check if tx has been executed
        if (transactions[_transactionId].executed)
        {
            emit EventExecution(msg.sender, _transactionId,
                                transactions[_transactionId].destination,
                                transactions[_transactionId].value,
                                now, ERR_CODE_TRANSACTION_DUPLICATE_EXEC);
            return;
        }

        if (isTransferConfirmed(_transactionId))
        {
            Transaction storage txn = transactions[_transactionId];
            txn.executed = true;
            if (txn.destination.call.value(txn.value)(txn.data))
                emit EventExecution(msg.sender, _transactionId,
                                    transactions[_transactionId].destination,
                                    transactions[_transactionId].value,
                                    now, ERR_CODE_SUCC);
            else
            {
                emit EventExecution(msg.sender, _transactionId,
                                    transactions[_transactionId].destination,
                                    transactions[_transactionId].value,
                                    now, ERR_CODE_TRANSACTION_EXEC_FAIL);
                txn.executed = false;
            }
        }
    }

    /*
     * Internal functions
     */
    /// @dev Adds a new transaction to the transaction mapping, if transaction does not exist yet.
    /// @param _destination Transaction target address.
    /// @param _value Transaction ether value.
    /// @param _data Transaction data payload.
    /// @return Returns transaction ID.
    function addTransaction(address _destination,
                            uint256 _value,
                            uint256 _valid_time,
                            string _comment,
                            bytes _data)
        internal
        notNull(_destination)
        returns (uint256 transactionId)
    {
        transactionId = transactionCount;
        transactions[transactionId] = Transaction({
                                    destination: _destination,
                                    value: _value,
                                    valid_time: _valid_time,
                                    comment: _comment,
                                    timestamp: now,
                                    data: _data,
                                    executed: false
        });
        transactionCount += 1;
        emit EventSubmission(msg.sender,
                            transactionId,
                            _destination,
                            _value,
                            _valid_time,
                            _comment,
                            now);
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
        count = 0;
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
        count = 0;
        for (uint256 i=0; i<transactionCount; i++)
        {
            if (pending && !transactions[i].executed ||
                executed && transactions[i].executed)
            {
                count += 1;
            }
        }
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

    /// @dev Returns count of owners.
    /// @return owner count.
    // function getOwners()
    //     public
    //     constant
    //     returns (address[], string[], uint256[])
    // {
    //     address[] memory owner_address = new address[](owners.length);
    //     string[] memory owner_name = new string[](owners.length);
    //     uint256[] memory join_time = new uint256[](owners.length);

    //     for (uint256 i = 0; i < owners.length; i++)
    //     {
    //         owner_address[i] = owners[i].owner_address;
    //         owner_name[i] = owners[i].owner_name;
    //         join_time[i] = owners[i].join_time;
    //     }

    //     return (owner_address, owner_name, join_time);
    // }

    function getOwnerInfoByIndex(uint256 index)
        public
        constant
        validOwnerIndex(index)
        returns (address, string, uint256)
    {
        return (owners[index].owner_address,
                owners[index].owner_name,
                owners[index].join_time);
    }

    function getWalletInfo()
        public
        view
        returns (address, uint256, uint256, uint256, uint256, string, address, string, bool)
    {
        return (address(this),
                owners.length,
                total,
                required,
                create_time,
                create_comment,
                creator,
                creator_name,
                is_cancel);
    }

    function getTransactionInfo(uint256 _transactionId)
        public
        constant
        returns (address[]  _approves,
                address[]   _declines,
                address     _destination,
                uint256     _value,
                uint256     _valid_time,
                string      _comment,
                uint256     _timestamp,
                bool        _executed)
    {
        address[] memory approvesTemp = new address[](owners.length);
        address[] memory declinesTemp = new address[](owners.length);

        uint256 approve_count = 0;
        uint256 decline_count = 0;
        uint256 i = 0;
        for (i=0; i<owners.length; i++)
        {
            if (approves[_transactionId][owners[i].owner_address])
            {
                approvesTemp[approve_count] = owners[i].owner_address;
                approve_count += 1;
            }

            if (!approves[_transactionId][owners[i].owner_address])
            {
                declinesTemp[approve_count] = owners[i].owner_address;
                decline_count += 1;
            }
        }

        _approves = new address[](approve_count);
        _declines = new address[](decline_count);

        for (i=0; i<approve_count; i++)
            _approves[i] = approvesTemp[i];

        for (i=0; i<decline_count; i++)
            _declines[i] = declinesTemp[i];

        _destination = transactions[_transactionId].destination;
        _value = transactions[_transactionId].value;
        _valid_time = transactions[_transactionId].valid_time;
        _comment = transactions[_transactionId].comment;
        _timestamp = transactions[_transactionId].timestamp;
        _executed = transactions[_transactionId].executed;
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
        require((to - from) > 0);

        uint256[] memory transactionIdsTemp = new uint256[](transactionCount);
        uint256 count = 0;
        uint256 i = 0;
        for (i=0; i<transactionCount; i++)
        {
            if (pending && !transactions[i].executed ||
                executed && transactions[i].executed)
            {
                transactionIdsTemp[count] = i;
                count += 1;
            }
        }

        uint256 tx_size = 0;
        if ((to - from) > count)
        {
            tx_size = count;
        }
        else
        {
            tx_size = (to - from);
        }

        _transactionIds = new uint256[](tx_size);
        for (i=0; i<tx_size; i++)
            _transactionIds[i + from] = transactionIdsTemp[i + from];
    }
}