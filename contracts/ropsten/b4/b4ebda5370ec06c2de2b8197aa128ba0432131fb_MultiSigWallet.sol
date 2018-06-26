pragma solidity ^0.4.21;

contract MultiSigWallet {
    struct Transaction {
        address destination;
        uint value;
        bytes data;
        bool executed;
    }

    uint constant public MAX_OWNER_COUNT = 50;

    mapping (uint => Transaction) public transactions;
    mapping (uint => mapping (address => bool)) public confirmations;
    mapping (address => bool) public isOwner;
    address[] public owners;
    uint public required;
    uint public transactionCount;

    event Confirmation(address indexed sender, uint indexed transactionId);
    event Revocation(address indexed sender, uint indexed transactionId);
    event Submission(uint indexed transactionId);
    event Execution(uint indexed transactionId);
    event ExecutionFailure(uint indexed transactionId);
    event Deposit(address indexed sender, uint value);
    event OwnerAddition(address indexed owner);
    event OwnerRemoval(address indexed owner);
    event RequirementChange(uint required);

    modifier onlyWallet() {
        require(msg.sender == address(this));
        _;
    }

    modifier ownerDoesNotExist(address owner) {
        require(!isOwner[owner]);
        _;
    }

    modifier ownerExists(address owner) {
        require(isOwner[owner]);
        _;
    }

    modifier transactionExists(uint transactionId) {
        require(transactions[transactionId].destination != address(0));
        _;
    }

    modifier confirmed(uint transactionId, address owner) {
        require(confirmations[transactionId][owner]);
        _;
    }

    modifier notConfirmed(uint transactionId, address owner) {
        require(!confirmations[transactionId][owner]);
        _;
    }

    modifier notExecuted(uint transactionId) {
        require(!transactions[transactionId].executed);
        _;
    }

    modifier notNull(address _address) {
        require(_address != address(0));
        _;
    }

    modifier validRequirement(uint ownerCount, uint _required) {
        require(ownerCount <= MAX_OWNER_COUNT&&_required <= ownerCount&&_required != 0&&ownerCount != 0);
        _;
    }

    function () public payable {
        if (msg.value > 0) {
            emit Deposit(msg.sender, msg.value);
        }
    }

    function MultiSigWallet(address[] _owners, uint _required) 
        validRequirement(_owners.length, _required) 
        public {
        for (uint i = 0; i < _owners.length; i++) {
            if (isOwner[_owners[i]] || _owners[i] == address(0)) {
                revert();
            }
            isOwner[_owners[i]] = true;
        }
        owners = _owners;
        required = _required;
    }

    function addOwner(address owner)
        onlyWallet
        ownerDoesNotExist(owner)
        notNull(owner)
        validRequirement(owners.length + 1, required)
        public {
        isOwner[owner] = true;
        owners.push(owner);
        emit OwnerAddition(owner);
    }

    function removeOwner(address owner)
        onlyWallet
        ownerExists(owner)
        public {
        isOwner[owner] = false;
        for (uint i = 0; i < owners.length - 1; i++) {
            if (owners[i] == owner) {
                owners[i] = owners[owners.length - 1];
                break;
            }
        }
        owners.length -= 1;
        if (required > owners.length) {
            changeRequirement(owners.length);
        }
        emit OwnerRemoval(owner);
    }

    function replaceOwner(address owner, address newOwner)
        onlyWallet
        ownerExists(owner)
        ownerDoesNotExist(newOwner)
        public {
        for (uint i = 0; i < owners.length; i++) {
            if (owners[i] == owner) {
                owners[i] = newOwner;
                break;
            }
        }
        isOwner[owner] = false;
        isOwner[newOwner] = true;
        emit OwnerRemoval(owner);
        emit OwnerAddition(newOwner);
    }

    function changeRequirement(uint _required)
        onlyWallet
        validRequirement(owners.length, _required)
        public {
        required = _required;
        emit RequirementChange(_required);
    }

    function submitTransaction(address destination, uint value, bytes data) 
        public 
        returns (uint transactionId) {
        transactionId = addTransaction(destination, value, data);
        confirmTransaction(transactionId);
    }

    function confirmTransaction(uint transactionId)
        ownerExists(msg.sender)
        transactionExists(transactionId)
        notConfirmed(transactionId, msg.sender)
        public {
        confirmations[transactionId][msg.sender] = true;
        emit Confirmation(msg.sender, transactionId);
        executeTransaction(transactionId);
    }

    function revokeConfirmation(uint transactionId)
        ownerExists(msg.sender)
        confirmed(transactionId, msg.sender)
        notExecuted(transactionId)
        public {
        confirmations[transactionId][msg.sender] = false;
        emit Revocation(msg.sender, transactionId);
    }

    function executeTransaction(uint transactionId)
        notExecuted(transactionId)
        public {
        if (isConfirmed(transactionId)) {
            Transaction storage tr = transactions[transactionId];
            tr.executed = true;
            if (tr.destination.call.value(tr.value)(tr.data)) {
                emit Execution(transactionId);
            } else {
                emit ExecutionFailure(transactionId);
                tr.executed = false;
            }
        }
    }

    function isConfirmed(uint transactionId) 
        public 
        view
        returns (bool) {
        uint count = 0;
        for (uint i = 0; i < owners.length; i++) {
            if (confirmations[transactionId][owners[i]]) {
                count += 1;
            }
            if (count == required) {
                return true;
            }
        }

        return false;
    }

    // Internal functions
    function addTransaction(address destination, uint value, bytes data) 
        notNull(destination)
        internal 
        returns (uint transactionId) {
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

    // getters
    function getConfirmationCount(uint transactionId)
        public 
        view 
        returns (uint count) {
        for (uint i = 0; i < owners.length; i++) {
            if (confirmations[transactionId][owners[i]]) {
                count += 1;
            }
        }
    }

    function getTransactionCount(bool pending, bool executed) 
        public 
        view 
        returns (uint count) {
        for (uint i = 0; i < transactionCount; i++) {
            if ((pending && !transactions[i].executed) || (executed && transactions[i].executed)) {
                count += 1;
            }
        }
    }

    function getOwners()
        public
        view 
        returns (address[]) {
        return owners;
    }

    function getConfirmations(uint transactionId) 
        public
        view 
        returns (address[] _confirmations) {
        address[] memory confirmationsTemp = new address[](owners.length);
        uint count = 0;
        uint i = 0; 
        for (i = 0; i < owners.length; i++) {
            if (confirmations[transactionId][owners[i]]) {
                confirmationsTemp[count] = owners[i];
                count += 1;
            }
        }

        _confirmations = new address[](count);
        for (i = 0; i < count; i++) {
            _confirmations[i] = confirmationsTemp[i];
        }
    }

    function getTransactionIds(uint from, uint to, bool pending, bool executed)
        public 
        view
        returns (uint[] _transactionIds) {
        uint[] memory transactoinsTemp = new uint[](transactionCount);
        uint count = 0;
        uint i = 0;
        for (i = 0; i < transactionCount; i++) {
            if ((pending && !transactions[i].executed) || (executed && transactions[i].executed)) {
                transactoinsTemp[count] = i;
                count += 1;
            }
        }
        _transactionIds = new uint[](to - from);
        for (i = from; i < to; i++) {
            _transactionIds[i - from] = transactoinsTemp[i];
        }
    }
}