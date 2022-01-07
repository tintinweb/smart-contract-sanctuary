/**
 *Submitted for verification at arbiscan.io on 2022-01-07
*/

// File: contracts/external/multisig/MultiSig.sol

/*

    Copyright

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity 0.8.9;
pragma abicoder v2;


/**
 * @title MultiSig
 * @author  
 *
 * Multi-Signature Wallet.
 * Allows multiple parties to agree on transactions before execution.
 * Adapted from Stefan George's MultiSigWallet contract.
 *
 * Logic Changes:
 *  - Removed the fallback function
 *  - Ensure newOwner is notNull
 *
 */
contract MultiSig {

    // ============ Events ============

    event Confirmation(address indexed sender, uint256 indexed transactionId);
    event Revocation(address indexed sender, uint256 indexed transactionId);
    event Submission(uint256 indexed transactionId);
    event Execution(uint256 indexed transactionId);
    event ExecutionFailure(uint256 indexed transactionId);
    event OwnerAddition(address indexed owner);
    event OwnerRemoval(address indexed owner);
    event RequirementChange(uint256 required);

    // ============ Constants ============

    uint256 constant public MAX_OWNER_COUNT = 50;
    address constant ADDRESS_ZERO = address(0x0);

    // ============ Storage ============

    mapping (uint256 => Transaction) public transactions;
    mapping (uint256 => mapping (address => bool)) public confirmations;
    mapping (address => bool) public isOwner;
    address[] public owners;
    uint256 public required;
    uint256 public transactionCount;

    // ============ Structs ============

    struct Transaction {
        address destination;
        uint256 value;
        bytes data;
        bool executed;
    }

    // ============ Modifiers ============

    modifier onlyWallet() {
        /* solium-disable-next-line error-reason */
        require(msg.sender == address(this));
        _;
    }

    modifier ownerDoesNotExist(
        address owner
    ) {
        /* solium-disable-next-line error-reason */
        require(!isOwner[owner]);
        _;
    }

    modifier ownerExists(
        address owner
    ) {
        /* solium-disable-next-line error-reason */
        require(isOwner[owner]);
        _;
    }

    modifier transactionExists(
        uint256 transactionId
    ) {
        /* solium-disable-next-line error-reason */
        require(transactions[transactionId].destination != ADDRESS_ZERO);
        _;
    }

    modifier confirmed(
        uint256 transactionId,
        address owner
    ) {
        /* solium-disable-next-line error-reason */
        require(confirmations[transactionId][owner]);
        _;
    }

    modifier notConfirmed(
        uint256 transactionId,
        address owner
    ) {
        /* solium-disable-next-line error-reason */
        require(!confirmations[transactionId][owner]);
        _;
    }

    modifier notExecuted(
        uint256 transactionId
    ) {
        /* solium-disable-next-line error-reason */
        require(!transactions[transactionId].executed);
        _;
    }

    modifier notNull(
        address _address
    ) {
        /* solium-disable-next-line error-reason */
        require(_address != ADDRESS_ZERO);
        _;
    }

    modifier validRequirement(
        uint256 ownerCount,
        uint256 _required
    ) {
        /* solium-disable-next-line error-reason */
        require(
            ownerCount <= MAX_OWNER_COUNT
            && _required <= ownerCount
            && _required != 0
            && ownerCount != 0
        );
        _;
    }

    // ============ Constructor ============

    /**
     * Contract constructor sets initial owners and required number of confirmations.
     *
     * @param  _owners    List of initial owners.
     * @param  _required  Number of required confirmations.
     */
    constructor(
        address[] memory _owners,
        uint256 _required
    )
        validRequirement(_owners.length, _required)
    {
        for (uint256 i = 0; i < _owners.length; i++) {
            /* solium-disable-next-line error-reason */
            require(!isOwner[_owners[i]] && _owners[i] != ADDRESS_ZERO);
            isOwner[_owners[i]] = true;
        }
        owners = _owners;
        required = _required;
    }

    // ============ Wallet-Only Functions ============

    /**
     * Allows to add a new owner. Transaction has to be sent by wallet.
     *
     * @param  owner  Address of new owner.
     */
    function addOwner(
        address owner
    )
        public
        onlyWallet
        ownerDoesNotExist(owner)
        notNull(owner)
        validRequirement(owners.length + 1, required)
    {
        isOwner[owner] = true;
        owners.push(owner);
        emit OwnerAddition(owner);
    }

    /**
     * Allows to remove an owner. Transaction has to be sent by wallet.
     *
     * @param  owner  Address of owner.
     */
    function removeOwner(
        address owner
    )
        public
        onlyWallet
        ownerExists(owner)
    {
        isOwner[owner] = false;
        for (uint256 i = 0; i < owners.length - 1; i++) {
            if (owners[i] == owner) {
                owners[i] = owners[owners.length - 1];
                break;
            }
        }
        //owners.length -= 1;
        owners.pop();
        if (required > owners.length) {
            changeRequirement(owners.length);
        }
        emit OwnerRemoval(owner);
    }

    /**
     * Allows to replace an owner with a new owner. Transaction has to be sent by wallet.
     *
     * @param  owner     Address of owner to be replaced.
     * @param  newOwner  Address of new owner.
     */
    function replaceOwner(
        address owner,
        address newOwner
    )
        public
        onlyWallet
        ownerExists(owner)
        ownerDoesNotExist(newOwner)
        notNull(newOwner)
    {
        for (uint256 i = 0; i < owners.length; i++) {
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

    /**
     * Allows to change the number of required confirmations. Transaction has to be sent by wallet.
     *
     * @param  _required  Number of required confirmations.
     */
    function changeRequirement(
        uint256 _required
    )
        public
        onlyWallet
        validRequirement(owners.length, _required)
    {
        required = _required;
        emit RequirementChange(_required);
    }

    // ============ Admin Functions ============

    /**
     * Allows an owner to submit and confirm a transaction.
     *
     * @param  destination  Transaction target address.
     * @param  value        Transaction ether value.
     * @param  data         Transaction data payload.
     * @return              Transaction ID.
     */
    function submitTransaction(
        address destination,
        uint256 value,
        bytes memory data
    )
        public
        returns (uint256)
    {
        uint256 transactionId = addTransaction(destination, value, data);
        confirmTransaction(transactionId);
        return transactionId;
    }

    /**
     * Allows an owner to confirm a transaction.
     *
     * @param  transactionId  Transaction ID.
     */
    function confirmTransaction(
        uint256 transactionId
    )
        public
        virtual
        ownerExists(msg.sender)
        transactionExists(transactionId)
        notConfirmed(transactionId, msg.sender)
    {
        confirmations[transactionId][msg.sender] = true;
        emit Confirmation(msg.sender, transactionId);
        executeTransaction(transactionId);
    }

    /**
     * Allows an owner to revoke a confirmation for a transaction.
     *
     * @param  transactionId  Transaction ID.
     */
    function revokeConfirmation(
        uint256 transactionId
    )
        public
        ownerExists(msg.sender)
        confirmed(transactionId, msg.sender)
        notExecuted(transactionId)
    {
        confirmations[transactionId][msg.sender] = false;
        emit Revocation(msg.sender, transactionId);
    }

    /**
     * Allows an owner to execute a confirmed transaction.
     *
     * @param  transactionId  Transaction ID.
     */
    function executeTransaction(
        uint256 transactionId
    )
        public
        virtual
        ownerExists(msg.sender)
        confirmed(transactionId, msg.sender)
        notExecuted(transactionId)
    {
        if (isConfirmed(transactionId)) {
            Transaction storage txn = transactions[transactionId];
            txn.executed = true;
            if (externalCall(
                txn.destination,
                txn.value,
                txn.data.length,
                txn.data)
            ) {
                emit Execution(transactionId);
            } else {
                emit ExecutionFailure(transactionId);
                txn.executed = false;
            }
        }
    }

    // ============ Getter Functions ============

    /**
     * Returns the confirmation status of a transaction.
     *
     * @param  transactionId  Transaction ID.
     * @return                Confirmation status.
     */
    function isConfirmed(
        uint256 transactionId
    )
        public
        view
        returns (bool)
    {
        uint256 count = 0;
        for (uint256 i = 0; i < owners.length; i++) {
            if (confirmations[transactionId][owners[i]]) {
                count += 1;
            }
            if (count == required) {
                return true;
            }
        }
        return false;
    }

    /**
     * Returns number of confirmations of a transaction.
     *
     * @param  transactionId  Transaction ID.
     * @return                Number of confirmations.
     */
    function getConfirmationCount(
        uint256 transactionId
    )
        public
        view
        returns (uint256)
    {
        uint256 count = 0;
        for (uint256 i = 0; i < owners.length; i++) {
            if (confirmations[transactionId][owners[i]]) {
                count += 1;
            }
        }
        return count;
    }

    /**
     * Returns total number of transactions after filers are applied.
     *
     * @param  pending   Include pending transactions.
     * @param  executed  Include executed transactions.
     * @return           Total number of transactions after filters are applied.
     */
    function getTransactionCount(
        bool pending,
        bool executed
    )
        public
        view
        returns (uint256)
    {
        uint256 count = 0;
        for (uint256 i = 0; i < transactionCount; i++) {
            if (
                pending && !transactions[i].executed
                || executed && transactions[i].executed
            ) {
                count += 1;
            }
        }
        return count;
    }

    /**
     * Returns array of owners.
     *
     * @return  Array of owner addresses.
     */
    function getOwners()
        public
        view
        returns (address[] memory)
    {
        return owners;
    }

    /**
     * Returns array with owner addresses, which confirmed transaction.
     *
     * @param  transactionId  Transaction ID.
     * @return                Array of owner addresses.
     */
    function getConfirmations(
        uint256 transactionId
    )
        public
        view
        returns (address[] memory)
    {
        address[] memory confirmationsTemp = new address[](owners.length);
        uint256 count = 0;
        uint256 i;
        for (i = 0; i < owners.length; i++) {
            if (confirmations[transactionId][owners[i]]) {
                confirmationsTemp[count] = owners[i];
                count += 1;
            }
        }
        address[] memory _confirmations = new address[](count);
        for (i = 0; i < count; i++) {
            _confirmations[i] = confirmationsTemp[i];
        }
        return _confirmations;
    }

    /**
     * Returns list of transaction IDs in defined range.
     *
     * @param  from      Index start position of transaction array.
     * @param  to        Index end position of transaction array.
     * @param  pending   Include pending transactions.
     * @param  executed  Include executed transactions.
     * @return           Array of transaction IDs.
     */
    function getTransactionIds(
        uint256 from,
        uint256 to,
        bool pending,
        bool executed
    )
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory transactionIdsTemp = new uint256[](transactionCount);
        uint256 count = 0;
        uint256 i;
        for (i = 0; i < transactionCount; i++) {
            if (
                pending && !transactions[i].executed
                || executed && transactions[i].executed
            ) {
                transactionIdsTemp[count] = i;
                count += 1;
            }
        }
        uint256[] memory _transactionIds = new uint256[](to - from);
        for (i = from; i < to; i++) {
            _transactionIds[i - from] = transactionIdsTemp[i];
        }
        return _transactionIds;
    }

    // ============ Helper Functions ============

    // call has been separated into its own function in order to take advantage
    // of the Solidity's code generator to produce a loop that copies tx.data into memory.
    function externalCall(
        address destination,
        uint256 value,
        uint256 dataLength,
        bytes memory data
    )
        internal
        returns (bool)
    {
        bool result;
        /* solium-disable-next-line security/no-inline-assembly */
        assembly {
            let x := mload(0x40)   // "Allocate" memory for output (0x40 is where "free memory" pointer is stored by convention)
            let d := add(data, 32) // First 32 bytes are the padded length of data, so exclude that
            result := call(
                sub(gas(), 34710),   // 34710 is the value that solidity is currently emitting
                                   // It includes callGas (700) + callVeryLow (3, to pay for SUB) + callValueTransferGas (9000) +
                                   // callNewAccountGas (25000, in case the destination address does not exist and needs creating)
                destination,
                value,
                d,
                dataLength,        // Size of the input (in bytes) - this is what fixes the padding problem
                x,
                0                  // Output is ignored, therefore the output size is zero
            )
        }
        return result;
    }

    /**
     * Adds a new transaction to the transaction mapping, if transaction does not exist yet.
     *
     * @param  destination  Transaction target address.
     * @param  value        Transaction ether value.
     * @param  data         Transaction data payload.
     * @return              Transaction ID.
     */
    function addTransaction(
        address destination,
        uint256 value,
        bytes memory data
    )
        internal
        notNull(destination)
        returns (uint256)
    {
        uint256 transactionId = transactionCount;
        transactions[transactionId] = Transaction({
            destination: destination,
            value: value,
            data: data,
            executed: false
        });
        transactionCount += 1;
        emit Submission(transactionId);
        return transactionId;
    }
}

// File: contracts/protocol/v1/multisigners/P1MultisigGateway.sol

/*

    Copyright

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/


/**
 * @title P1MultisigAdmin
 * @author  
 *
 * @notice Multisig contract for gateway.
 */

contract P1MultisigGateway is 
    MultiSig
{
    constructor (
        address[] memory owners,
        uint256 required
    ) MultiSig(
        owners,
        required
    )
    {}

}