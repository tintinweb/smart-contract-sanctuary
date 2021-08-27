// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract MultiSigWallet {
    struct Transaction {
        address destination;
        uint256 value;
        bytes data;
        bool executed;
    }
    /*
     *  Events
     */
    event Confirmation(address indexed sender, uint256 indexed transactionId);
    event Revocation(address indexed sender, uint256 indexed transactionId);
    event Submission(uint256 indexed transactionId, bytes data, address indexed _destination);
    event Execution(uint256 indexed transactionId);
    event ExecutionFailure(uint256 indexed transactionId);
    event Deposit(address indexed sender, uint256 value);
    event OwnerAddition(address indexed owner);
    event OwnerRemoval(address indexed owner);
    event RequirementChange(uint256 required);

    /*
     *  Constants
     */
    uint256 public constant MAX_OWNER_COUNT = 50;

    /*
     *  Storage
     */
    mapping(uint256 => Transaction) public transactions;
    mapping(uint256 => mapping(address => bool)) public confirmations;
    mapping(address => bool) public isOwner;
    mapping(bytes32 => address) public destinations;
    address[] public owners;
    address public executer;
    uint256 public required;
    uint256 public transactionCount;

    /*
     *  Modifiers
     */
    modifier onlyWallet() {
        require(
            msg.sender == address(this),
            "Trying to execute OnlyWallet operation"
        );
        _;
    }

    modifier ownerExists(address _owner) {
        require(isOwner[_owner], "Owner should exists");
        _;
    }

    modifier confirmed(uint256 _transactionId, address _owner) {
        require(
            confirmations[_transactionId][_owner],
            "transaction is not confirmed"
        );
        _;
    }

    modifier notNull(address _address) {
        require(_address != address(0), "zero address");
        _;
    }

    modifier validRequirement(uint256 _ownerCount, uint256 _required) {
        require(
            _ownerCount <= MAX_OWNER_COUNT &&
                _required <= _ownerCount &&
                _required != 0 &&
                _ownerCount != 0
        );
        _;
    }

    /// @dev Fallback function allows to deposit ether.
    fallback() external payable {
        if (msg.value > 0) emit Deposit(msg.sender, msg.value);
    }

    /*
     * Public functions
     */
    /// @dev Contract constructor sets initial owners and required number of confirmations.
    /// @param _owners List of initial owners.
    /// @param _required Number of required confirmations.
    constructor(address[] memory _owners, uint256 _required, address _executer)
        validRequirement(_owners.length, _required)
    {
        for (uint256 i = 0; i < _owners.length; i++) {
            require(
                !isOwner[_owners[i]] && _owners[i] != address(0),
                "constructor failed"
            );
            isOwner[_owners[i]] = true;
        }
        owners = _owners;
        required = _required;
        executer = _executer;
    }

    /// @dev Allows to add a new owner. Transaction has to be sent by wallet.
    /// @param _owner Address of new owner.
    function addOwner(address _owner)
        public
        onlyWallet
        notNull(_owner)
        validRequirement(owners.length + 1, required)
    {
        require(!isOwner[_owner], "Owner should not exists");
        isOwner[_owner] = true;
        owners.push(_owner);
        emit OwnerAddition(_owner);
    }

    /// @dev Allows to remove an owner. Transaction has to be sent by wallet.
    /// @param _owner Address of owner.
    function removeOwner(address _owner) public onlyWallet ownerExists(_owner) {
        isOwner[_owner] = false;
        for (uint256 i = 0; i < owners.length - 1; i++)
            if (owners[i] == _owner) {
                owners[i] = owners[owners.length - 1];
                break;
            }
        // owners.length -= 1;
        if (required > owners.length) changeRequirement(owners.length);
        emit OwnerRemoval(_owner);
    }

    /// @dev Allows to replace an owner with a new owner. Transaction has to be sent by wallet.
    /// @param _owner Address of owner to be replaced.
    /// @param _newOwner Address of new owner.
    function _replaceOwner(address _owner, address _newOwner)
        public
        onlyWallet
        ownerExists(_owner)
    {
        require(!isOwner[_owner], "Owner should not exists");
        for (uint256 i = 0; i < owners.length; i++)
            if (owners[i] == _owner) {
                owners[i] = _newOwner;
                break;
            }
        isOwner[_owner] = false;
        isOwner[_newOwner] = true;
        emit OwnerRemoval(_owner);
        emit OwnerAddition(_newOwner);
    }

    /// @dev Allows to change the number of required confirmations. Transaction has to be sent by wallet.
    /// @param _required Number of required confirmations.
    function changeRequirement(uint256 _required)
        public
        onlyWallet
        validRequirement(owners.length, _required)
    {
        required = _required;
        emit RequirementChange(_required);
    }

    function setExecuter(address _executer) public onlyWallet {
        executer = _executer;
    }

    function submitTransaction(
        address _destination,
        uint256 _value,
        bytes memory _data,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {
        bytes32 hashMsg = keccak256(
            abi.encodePacked(_destination, _value, _data)
        );
        address user = getRecover(hashMsg, _v, _r, _s);
        _submitTransaction(_destination, _value, _data, user);
    }

    /// @dev Allows an owner to submit and confirm a transaction.
    /// @param _destination Transaction target address.
    /// @param _value Transaction ether value.
    /// @param _data Transaction data payload.
    /// @return transactionId_ Returns transaction ID.
    function _submitTransaction(
        address _destination,
        uint256 _value,
        bytes memory _data,
        address _user
    ) private ownerExists(_user) returns (uint256 transactionId_) {
        transactionId_ = addTransaction(_destination, _value, _data);
        _confirmTransaction(transactionId_, _user);
    }

    function confirmTransaction(
        uint256 _transactionId,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {
        bytes32 hashMsg = keccak256(abi.encodePacked(_transactionId));
        address user = getRecover(hashMsg, _v, _r, _s);
        _confirmTransaction(_transactionId, user);
    }

    /// @dev Allows an owner to confirm a transaction.
    /// @param _transactionId Transaction ID.
    function _confirmTransaction(uint256 _transactionId, address _user)
        private
        ownerExists(_user)
    {
        require(
            !confirmations[_transactionId][_user],
            "transaction is confirmed"
        );
        require(
            transactions[_transactionId].destination != address(0),
            "zero addressed transaction"
        );
        confirmations[_transactionId][_user] = true;
        emit Confirmation(_user, _transactionId);
        // _executeTransaction(_transactionId, _user);
    }

    function revokeConfirmation(
        uint256 _transactionId,
        bytes32 hashMsg,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) public {
        address user = getRecover(hashMsg, _v, _r, _s);
        _revokeConfirmation(_transactionId, user);
    }

    /// @dev Allows an owner to revoke a confirmation for a transaction.
    /// @param _transactionId Transaction ID.
    function _revokeConfirmation(uint256 _transactionId, address _user)
        public
        ownerExists(_user)
        confirmed(_transactionId, _user)
    {
        require(!transactions[_transactionId].executed, "transaction executed");
        confirmations[_transactionId][_user] = false;
        emit Revocation(_user, _transactionId);
    }


    /// @dev Allows anyone to execute a confirmed transaction.
    /// @param _transactionId Transaction ID.
    function executeTransaction(
        uint256 _transactionId
    ) public {
        require(msg.sender==executer, "Caller is not executer!");
        require(!transactions[_transactionId].executed, "transaction executed");
        if (isConfirmed(_transactionId)) {
            Transaction storage txn = transactions[_transactionId];
            txn.executed = true;
            if (
                external_call(
                    txn.destination,
                    txn.value,
                    txn.data.length,
                    txn.data
                )
            ) emit Execution(_transactionId);
            else {
                emit ExecutionFailure(_transactionId);
                txn.executed = false;
            }
        }
    }

    // call has been separated into its own function in order to take advantage
    // of the Solidity's code generator to produce a loop that copies tx.data into memory.
    function external_call(
        address _destination,
        uint256 _value,
        uint256 _dataLength,
        bytes memory _data
    ) internal returns (bool) {
        bool result;
        assembly {
            let x := mload(0x40) // "Allocate" memory for output (0x40 is where "free memory" pointer is stored by convention)
            let d := add(_data, 32) // First 32 bytes are the padded length of data, so exclude that
            result := call(
                gas(),
                //sub(gas(), 34710), // 34710 is the value that solidity is currently emitting
                // It includes callGas (700) + callVeryLow (3, to pay for SUB) + callValueTransferGas (9000) +
                // callNewAccountGas (25000, in case the destination address does not exist and needs creating)
                _destination,
                _value,
                d,
                _dataLength, // Size of the input (in bytes) - this is what fixes the padding problem
                x,
                0 // Output is ignored, therefore the output size is zero
            )
            let retSz := returndatasize()
            returndatacopy(0, 0, retSz)
            switch result
            case 0 {
                revert(0, retSz)
            }
            default {
                return(0, retSz)
            }
        }
    }

    /// @dev Returns the confirmation status of a transaction.
    /// @param _transactionId Transaction ID.
    /// @return Confirmation status.
    function isConfirmed(uint256 _transactionId) public view returns (bool) {
        uint256 count = 0;
        for (uint256 i = 0; i < owners.length; i++) {
            if (confirmations[_transactionId][owners[i]]) count += 1;
            if (count == required) return true;
        }
    }

    /*
     * Internal functions
     */
    /// @dev Adds a new transaction to the transaction mapping, if transaction does not exist yet.
    /// @param _destination Transaction target address.
    /// @param _value Transaction ether value.
    /// @param _data Transaction data payload.
    /// @return transactionId_ Returns transaction ID.
    function addTransaction(
        address _destination,
        uint256 _value,
        bytes memory _data
    ) internal notNull(_destination) returns (uint256 transactionId_) {
        transactionId_ = transactionCount;
        transactions[transactionId_] = Transaction({
            destination: _destination,
            value: _value,
            data: _data,
            executed: false
        });
        transactionCount += 1;
        emit Submission(transactionId_, _data, _destination);
    }

    /*
     * Web3 call functions
     */
    /// @dev Returns number of confirmations of a transaction.
    /// @param _transactionId Transaction ID.
    /// @return count Number of confirmations.
    function getConfirmationCount(uint256 _transactionId)
        public
        view
        returns (uint256 count)
    {
        for (uint256 i = 0; i < owners.length; i++)
            if (confirmations[_transactionId][owners[i]]) count += 1;
    }

    /// @dev Returns total number of transactions after filers are applied.
    /// @param _pending Include pending transactions.
    /// @param _executed Include executed transactions.
    /// @return count Total number of transactions after filters are applied.
    function getTransactionCount(bool _pending, bool _executed)
        public
        view
        returns (uint256 count)
    {
        for (uint256 i = 0; i < transactionCount; i++)
            if (
                (_pending && !transactions[i].executed) ||
                (_executed && transactions[i].executed)
            ) count += 1;
    }

    /// @dev Returns list of owners.
    /// @return List of owner addresses.
    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    /// @dev Returns array with owner addresses, which confirmed transaction.
    /// @param transactionId Transaction ID.
    /// @return confirmations_ Returns array of owner addresses.
    function getConfirmations(uint256 transactionId)
        public
        view
        returns (address[] memory confirmations_)
    {
        address[] memory confirmationsTemp = new address[](owners.length);
        uint256 count = 0;
        uint256 i;
        for (i = 0; i < owners.length; i++)
            if (confirmations[transactionId][owners[i]]) {
                confirmationsTemp[count] = owners[i];
                count += 1;
            }
        confirmations_ = new address[](count);
        for (i = 0; i < count; i++) confirmations_[i] = confirmationsTemp[i];
    }

    /// @dev Returns list of transaction IDs in defined range.
    /// @param _from Index start position of transaction array.
    /// @param _to Index end position of transaction array.
    /// @param _pending Include pending transactions.
    /// @param _executed Include executed transactions.
    /// @return transactionIds_ Returns array of transaction IDs.
    function getTransactionIds(
        uint256 _from,
        uint256 _to,
        bool _pending,
        bool _executed
    ) public view returns (uint256[] memory transactionIds_) {
        uint256[] memory transactionIdsTemp = new uint256[](transactionCount);
        uint256 count = 0;
        uint256 i;
        for (i = 0; i < transactionCount; i++)
            if (
                (_pending && !transactions[i].executed) ||
                (_executed && transactions[i].executed)
            ) {
                transactionIdsTemp[count] = i;
                count += 1;
            }
        transactionIds_ = new uint256[](_to - _from);
        for (i = _from; i < _to; i++)
            transactionIds_[i - _from] = transactionIdsTemp[i];
    }

    function getRecover(
        bytes32 hashMsg,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) public pure returns (address) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, hashMsg));
        return ecrecover(prefixedHash, _v, _r, _s);
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}