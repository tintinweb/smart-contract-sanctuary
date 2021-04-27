/**
 *Submitted for verification at Etherscan.io on 2021-04-26
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

/**
    Note: The ERC-165 identifier for this interface is 0x4e2312e0.
*/
interface IERC1155TokenReceiver {
    /**
        @notice Handle the receipt of a single ERC1155 token type.
        @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeTransferFrom` after the balance has been updated.
        This function MUST return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` (i.e. 0xf23a6e61) if it accepts the transfer.
        This function MUST revert if it rejects the transfer.
        Return of any other value than the prescribed keccak256 generated value MUST result in the transaction being reverted by the caller.
        @param _operator  The address which initiated the transfer (i.e. msg.sender)
        @param _from      The address which previously owned the token
        @param _id        The ID of the token being transferred
        @param _value     The amount of tokens being transferred
        @param _data      Additional data with no specified format
        @return           `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
    */
    function onERC1155Received(
        address _operator,
        address _from,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    ) external returns (bytes4);

    /**
        @notice Handle the receipt of multiple ERC1155 token types.
        @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeBatchTransferFrom` after the balances have been updated.
        This function MUST return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` (i.e. 0xbc197c81) if it accepts the transfer(s).
        This function MUST revert if it rejects the transfer(s).
        Return of any other value than the prescribed keccak256 generated value MUST result in the transaction being reverted by the caller.
        @param _operator  The address which initiated the batch transfer (i.e. msg.sender)
        @param _from      The address which previously owned the token
        @param _ids       An array containing ids of each token being transferred (order and length must match _values array)
        @param _values    An array containing amounts of each token being transferred (order and length must match _ids array)
        @param _data      Additional data with no specified format
        @return           `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
    */
    function onERC1155BatchReceived(
        address _operator,
        address _from,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) external returns (bytes4);
}

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

/// @author Stefan George - <[email protected]> - adjusted by the Calystral Team
/// @title Multisignature wallet - Allows multiple parties to agree on transactions before execution.
interface IMultiSigEthAdmin is IERC1155TokenReceiver, IERC165 {
    /*==============================
    =           EVENTS             =
    ==============================*/
    event Confirmation(address indexed sender, uint256 indexed transactionId);
    event Revocation(address indexed sender, uint256 indexed transactionId);
    event Submission(uint256 indexed transactionId);
    event Execution(uint256 indexed transactionId);
    event ExecutionFailure(uint256 indexed transactionId);
    event Deposit(address indexed sender, uint256 value);
    event OwnerAddition(address indexed owner);
    event OwnerRemoval(address indexed owner);
    event RequirementChange(uint256 required);

    /*==============================
    =          FUNCTIONS           =
    ==============================*/
    /// @dev Fallback function allows to deposit ether.
    receive() external payable;

    /// @dev Allows an owner to submit and confirm a transaction.
    /// @param destination Transaction target address.
    /// @param value Transaction ether value.
    /// @param data Transaction data payload.
    /// @return transactionId transactionId Returns transaction ID.
    function submitTransaction(
        address destination,
        uint256 value,
        bytes memory data
    ) external returns (uint256 transactionId);

    /// @dev Allows to add a new owner. Transaction has to be sent by wallet.
    /// @param owner Address of new owner.
    function addOwner(address owner) external;

    /// @dev Allows to remove an owner. Transaction has to be sent by wallet.
    /// @param owner Address of owner.
    function removeOwner(address owner) external;

    /// @dev Allows to replace an owner with a new owner. Transaction has to be sent by wallet.
    /// @param owner Address of owner to be replaced.
    /// @param newOwner Address of new owner.
    function replaceOwner(address owner, address newOwner) external;

    /// @dev Allows to change the number of required confirmations. Transaction has to be sent by wallet.
    /// @param _required Number of required confirmations.
    function changeRequirement(uint256 _required) external;

    /// @dev Allows an owner to confirm a transaction.
    /// @param transactionId Transaction ID.
    function confirmTransaction(uint256 transactionId) external;

    /// @dev Allows an owner to revoke a confirmation for a transaction.
    /// @param transactionId Transaction ID.
    function revokeConfirmation(uint256 transactionId) external;

    /// @dev Allows anyone to execute a confirmed transaction.
    /// @param transactionId Transaction ID.
    function executeTransaction(uint256 transactionId) external;

    /*==============================
    =          VIEW & PURE         =
    ==============================*/
    /// @dev Returns the confirmation status of a transaction.
    /// @param transactionId Transaction ID.
    /// @return isConfirmed Confirmation status.
    function isConfirmed(uint256 transactionId) external view returns (bool);

    /// @dev Returns number of confirmations of a transaction.
    /// @param transactionId Transaction ID.
    /// @return count Number of confirmations.
    function getConfirmationCount(uint256 transactionId)
        external
        view
        returns (uint256 count);

    /// @dev Returns total number of transactions after filers are applied.
    /// @param pending Include pending transactions.
    /// @param executed Include executed transactions.
    /// @return count Total number of transactions after filters are applied.
    function getTransactionCount(bool pending, bool executed)
        external
        view
        returns (uint256 count);

    /// @dev Returns list of owners.
    /// @return owners List of owner addresses.
    function getOwners() external view returns (address[] memory);

    /// @dev Returns the amount of required confirmations.
    /// @return required Amount of required confirmations.
    function getRequired() external view returns (uint256);

    /// @dev Returns array with owner addresses, which confirmed transaction.
    /// @param transactionId Transaction ID.
    /// @return _confirmations Returns array of owner addresses.
    function getConfirmations(uint256 transactionId)
        external
        view
        returns (address[] memory _confirmations);

    /// @dev Returns list of transaction IDs in defined range.
    /// @param from Index start position of transaction array.
    /// @param to Index end position of transaction array.
    /// @param pending Include pending transactions.
    /// @param executed Include executed transactions.
    /// @return _transactionIds Returns array of transaction IDs.
    function getTransactionIds(
        uint256 from,
        uint256 to,
        bool pending,
        bool executed
    ) external view returns (uint256[] memory _transactionIds);
}

/// @title Multisignature Payments wallet for Ethereum
/// @author The Calystral Team
interface IMultiSigEthPayments is IMultiSigEthAdmin {
    /*==============================
    =            EVENTS            =
    ==============================*/
    /**
        @dev MUST emit when a token allowance changes.
        The `tokenAddress` argument MUST be the token address.
        The `allowed` argument MUST be the allowance.
    */
    event OnTokenUpdate(address indexed tokenAddress, bool allowed);
    /**
        @dev MUST emit when the withdraw address changes.
        The `withdrawAddress` argument MUST be the withdraw address.
    */
    event OnWithdrawAddressUpdate(address withdrawAddress);
    /**
        @dev MUST emit when an is payed with ETH.
        The `orderId` argument MUST be the orderId.
        The `amount` argument MUST be the amount payed in WEI.
    */
    event OnPayedEthOrder(uint256 indexed orderId, uint256 amount);
    /**
        @dev MUST emit when an is payed with a token.
        The `orderId` argument MUST be the orderId.
        The `tokenAddress` argument MUST be the token's contract address.
        The `amount` argument MUST be the amount payed in full DECIMALS of the token.
    */
    event OnPayedTokenOrder(
        uint256 indexed orderId,
        address indexed tokenAddress,
        uint256 amount
    );
    /**
        @dev MUST emit when ETH is withdrawn through withdraw function.
        The `receiver` argument MUST be the receiving address.
        The `amount` argument MUST be the amount payed in WEI.
    */
    event OnEthWithdraw(address indexed receiver, uint256 amount);
    /**
        @dev MUST emit when a token is withdrawn through withdrawToken function.
        The `receiver` argument MUST be the receiving address.
        The `tokenAddress` argument MUST be the token's contract address.
        The `amount` argument MUST be the amount payed in full DECIMALS of the token.
    */
    event OnTokenWithdraw(
        address indexed receiver,
        address indexed tokenAddress,
        uint256 amount
    );

    /*==============================
    =          FUNCTIONS           =
    ==============================*/
    /**
        @notice Used to pay an open order with ETH.
        @dev Payable function used to pay a created order in ETH. 
        @param orderId The orderId
    */
    function payEthOrder(uint256 orderId) external payable;

    /**
        @notice Used to pay an open order with an allowed ERC20 token.
        @dev Used to pay a created order with an allowed ERC20 token.
        @param orderId      The orderId
        @param tokenAddress The smart contract address of the ERC20 token
        @param amount       The amount of tokens payed
    */
    function payTokenOrder(
        uint256 orderId,
        address tokenAddress,
        uint256 amount
    ) external;

    /**
        @notice Adds or removes a specific ERC20 token for payments.
        @dev Adds or removes the address of an ERC20 contract for valid payment options.
        @param tokenAddress The smart contract address of the ERC20 token
        @param allowed      True or False as the allowence
    */
    function updateAllowedToken(address tokenAddress, bool allowed) external;

    /**
        @notice Withdraws ETH to the specified withdraw address.
        @dev Withdraws ETH to the specified `_withdrawAddress`.
    */
    function withdraw() external;

    /**
        @notice Withdraws a token to the specified withdraw address.
        @dev Withdraws a token to the specified `_withdrawAddress`.
        @param tokenAddress The smart contract address of the ERC20 token
    */
    function withdrawToken(address tokenAddress) external;

    /**
        @notice Updated the withdraw address.
        @dev Updates `_withdrawAddress`.
        @param withdrawAddress The withdraw address
    */
    function updateWithdrawAddress(address payable withdrawAddress) external;

    /**
        @notice Used to check if a specific token is allowed providing the token's contract address.
        @dev Used to check if a specific token is allowed providing the token's contract address.
        @param tokenAddress The smart contract address of the ERC20 token
        @return             Returns True or False
    */
    function isTokenAllowed(address tokenAddress) external view returns (bool);

    /**
        @notice Used to check if a specific order is payed already by orderId.
        @dev Used to check if a specific order is payed already by orderId.
        @param orderId  The orderId
        @return         Returns True or False
    */
    function isOrderIdExecuted(uint256 orderId) external view returns (bool);

    /**
        @notice Gets the withdraw address.
        @dev Gets the `_withdrawAddress`.
        @return Returns the withdraw address
    */
    function getWithdrawAddress() external view returns (address);
}

/**
    Note: Simple contract to use as base for const vals
*/
contract CommonConstants {
    bytes4 internal constant ERC1155_ACCEPTED = 0xf23a6e61; // bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))
    bytes4 internal constant ERC1155_BATCH_ACCEPTED = 0xbc197c81; // bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))
}

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor() {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override
        returns (bool)
    {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

/// @author Stefan George - <[email protected]> - adjusted by the Calystral Team
/// @title Multisignature wallet - Allows multiple parties to agree on transactions before execution.
contract MultiSigEthAdmin is IMultiSigEthAdmin, ERC165, CommonConstants {
    /*==============================
    =          CONSTANTS           =
    ==============================*/
    uint256 public constant MAX_OWNER_COUNT = 50;

    /*==============================
    =            STORAGE           =
    ==============================*/
    mapping(uint256 => Transaction) public transactions;
    mapping(uint256 => mapping(address => bool)) public confirmations;
    mapping(address => bool) public isOwner;
    address[] public owners;
    uint256 public required;
    uint256 public transactionCount;

    struct Transaction {
        address destination;
        uint256 value;
        bytes data;
        bool executed;
    }

    /*==============================
    =          MODIFIERS           =
    ==============================*/
    modifier isAuthorizedWallet() {
        require(
            msg.sender == address(this),
            "Can only be executed by the wallet contract itself."
        );
        _;
    }

    modifier isAuthorizedOwner(address owner) {
        require(isOwner[owner], "This address is not an owner.");
        _;
    }

    modifier ownerDoesNotExist(address owner) {
        require(!isOwner[owner], "This address is an owner.");
        _;
    }

    modifier transactionExists(uint256 transactionId) {
        require(
            transactions[transactionId].destination != address(0x0),
            "The transaction destination does not exist."
        );
        _;
    }

    modifier confirmed(uint256 transactionId, address owner) {
        require(
            confirmations[transactionId][owner],
            "The owner did not confirm this transactionId yet."
        );
        _;
    }

    modifier notConfirmed(uint256 transactionId, address owner) {
        require(
            !confirmations[transactionId][owner],
            "This owner did confirm this transactionId already."
        );
        _;
    }

    modifier notExecuted(uint256 transactionId) {
        require(
            !transactions[transactionId].executed,
            "This transactionId is executed already."
        );
        _;
    }

    modifier notNull(address _address) {
        require(_address != address(0x0), "The zero-address is not allowed.");
        _;
    }

    modifier validRequirement(uint256 ownerCount, uint256 _required) {
        require(
            ownerCount <= MAX_OWNER_COUNT &&
                _required <= ownerCount &&
                _required != 0 &&
                ownerCount != 0,
            "This change in requirement is not allowed."
        );
        _;
    }

    /*==============================
    =          CONSTRUCTOR         =
    ==============================*/
    /// @dev Contract constructor sets initial owners and required number of confirmations.
    /// @param _owners List of initial owners.
    /// @param _required Number of required confirmations.
    constructor(address[] memory _owners, uint256 _required)
        validRequirement(_owners.length, _required)
    {
        for (uint256 i = 0; i < _owners.length; i++) {
            require(
                !isOwner[_owners[i]] && _owners[i] != address(0x0),
                "An owner address is included multiple times or as the zero-address."
            );
            isOwner[_owners[i]] = true;
        }
        owners = _owners;
        required = _required;

        _registerInterface(type(IERC1155TokenReceiver).interfaceId); // 0x4e2312e0
        _registerInterface(type(IMultiSigEthAdmin).interfaceId);
    }

    /*==============================
    =      PUBLIC & EXTERNAL       =
    ==============================*/
    receive() external payable override {
        if (msg.value > 0) {
            emit Deposit(msg.sender, msg.value);
        }
    }

    function submitTransaction(
        address destination,
        uint256 value,
        bytes memory data
    ) public override returns (uint256 transactionId) {
        transactionId = addTransaction(destination, value, data);
        confirmTransaction(transactionId);
    }

    /*==============================
    =          RESTRICTED          =
    ==============================*/
    function addOwner(address owner)
        public
        override
        isAuthorizedWallet()
        ownerDoesNotExist(owner)
        notNull(owner)
        validRequirement(owners.length + 1, required)
    {
        isOwner[owner] = true;
        owners.push(owner);
        emit OwnerAddition(owner);
    }

    function removeOwner(address owner)
        public
        override
        isAuthorizedWallet()
        isAuthorizedOwner(owner)
    {
        isOwner[owner] = false;
        for (uint256 i = 0; i < owners.length - 1; i++)
            if (owners[i] == owner) {
                owners[i] = owners[owners.length - 1];
                break;
            }
        owners.pop(); //owners.length -= 1;
        if (required > owners.length) changeRequirement(owners.length);
        emit OwnerRemoval(owner);
    }

    function replaceOwner(address owner, address newOwner)
        public
        override
        isAuthorizedWallet()
        isAuthorizedOwner(owner)
        ownerDoesNotExist(newOwner)
    {
        for (uint256 i = 0; i < owners.length; i++)
            if (owners[i] == owner) {
                owners[i] = newOwner;
                break;
            }
        isOwner[owner] = false;
        isOwner[newOwner] = true;
        emit OwnerRemoval(owner);
        emit OwnerAddition(newOwner);
    }

    function changeRequirement(uint256 _required)
        public
        override
        isAuthorizedWallet()
        validRequirement(owners.length, _required)
    {
        required = _required;
        emit RequirementChange(_required);
    }

    function confirmTransaction(uint256 transactionId)
        public
        override
        isAuthorizedOwner(msg.sender)
        transactionExists(transactionId)
        notConfirmed(transactionId, msg.sender)
    {
        confirmations[transactionId][msg.sender] = true;
        emit Confirmation(msg.sender, transactionId);
        executeTransaction(transactionId);
    }

    function revokeConfirmation(uint256 transactionId)
        public
        override
        isAuthorizedOwner(msg.sender)
        confirmed(transactionId, msg.sender)
        notExecuted(transactionId)
    {
        confirmations[transactionId][msg.sender] = false;
        emit Revocation(msg.sender, transactionId);
    }

    function executeTransaction(uint256 transactionId)
        public
        override
        isAuthorizedOwner(msg.sender)
        confirmed(transactionId, msg.sender)
        notExecuted(transactionId)
    {
        if (isConfirmed(transactionId)) {
            Transaction storage txn = transactions[transactionId];
            txn.executed = true;
            if (
                external_call(
                    txn.destination,
                    txn.value,
                    txn.data.length,
                    txn.data
                )
            ) {
                emit Execution(transactionId);
            } else {
                emit ExecutionFailure(transactionId);
                txn.executed = false;
            }
        }
    }

    /*==============================
    =          VIEW & PURE         =
    ==============================*/
    function isConfirmed(uint256 transactionId)
        public
        view
        override
        returns (bool)
    {
        uint256 count = 0;
        for (uint256 i = 0; i < owners.length; i++) {
            if (confirmations[transactionId][owners[i]]) count += 1;
            if (count == required) return true;
        }
        return false;
    }

    function getConfirmationCount(uint256 transactionId)
        public
        view
        override
        returns (uint256 count)
    {
        for (uint256 i = 0; i < owners.length; i++)
            if (confirmations[transactionId][owners[i]]) count += 1;
    }

    function getTransactionCount(bool pending, bool executed)
        public
        view
        override
        returns (uint256 count)
    {
        for (uint256 i = 0; i < transactionCount; i++)
            if (
                (pending && !transactions[i].executed) ||
                (executed && transactions[i].executed)
            ) count += 1;
    }

    function getOwners() public view override returns (address[] memory) {
        return owners;
    }

    function getRequired() public view override returns (uint256) {
        return required;
    }

    function getConfirmations(uint256 transactionId)
        public
        view
        override
        returns (address[] memory _confirmations)
    {
        address[] memory confirmationsTemp = new address[](owners.length);
        uint256 count = 0;
        uint256 i;
        for (i = 0; i < owners.length; i++)
            if (confirmations[transactionId][owners[i]]) {
                confirmationsTemp[count] = owners[i];
                count += 1;
            }
        _confirmations = new address[](count);
        for (i = 0; i < count; i++) _confirmations[i] = confirmationsTemp[i];
    }

    function getTransactionIds(
        uint256 from,
        uint256 to,
        bool pending,
        bool executed
    ) public view override returns (uint256[] memory _transactionIds) {
        uint256[] memory transactionIdsTemp = new uint256[](transactionCount);
        uint256 count = 0;
        uint256 i;
        for (i = 0; i < transactionCount; i++)
            if (
                (pending && !transactions[i].executed) ||
                (executed && transactions[i].executed)
            ) {
                transactionIdsTemp[count] = i;
                count += 1;
            }
        _transactionIds = new uint256[](to - from);
        for (i = from; i < to; i++)
            _transactionIds[i - from] = transactionIdsTemp[i];
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return ERC1155_ACCEPTED;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure override returns (bytes4) {
        return ERC1155_BATCH_ACCEPTED;
    }

    /*==============================
    =      INTERNAL & PRIVATE      =
    ==============================*/
    // call has been separated into its own function in order to take advantage
    // of the Solidity's code generator to produce a loop that copies tx.data into memory.
    function external_call(
        address destination,
        uint256 value,
        uint256 dataLength,
        bytes memory data
    ) internal returns (bool) {
        bool result;
        assembly {
            let x := mload(0x40) // "Allocate" memory for output (0x40 is where "free memory" pointer is stored by convention)
            let d := add(data, 32) // First 32 bytes are the padded length of data, so exclude that
            result := call(
                sub(gas(), 34710), // 34710 is the value that solidity is currently emitting
                // It includes callGas (700) + callVeryLow (3, to pay for SUB) + callValueTransferGas (9000) +
                // callNewAccountGas (25000, in case the destination address does not exist and needs creating)
                destination,
                value,
                d,
                dataLength, // Size of the input (in bytes) - this is what fixes the padding problem
                x,
                0 // Output is ignored, therefore the output size is zero
            )
        }
        return result;
    }

    /// @dev Adds a new transaction to the transaction mapping, if transaction does not exist yet.
    /// @param destination Transaction target address.
    /// @param value Transaction ether value.
    /// @param data Transaction data payload.
    /// @return transactionId Returns transaction ID.
    function addTransaction(
        address destination,
        uint256 value,
        bytes memory data
    ) internal notNull(destination) returns (uint256 transactionId) {
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
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

/// @title Multisignature Payments wallet for Ethereum
/// @author The Calystral Team
contract MultiSigEthPayments is IMultiSigEthPayments, MultiSigEthAdmin {
    /*==============================
    =          CONSTANTS           =
    ==============================*/

    /*==============================
    =            STORAGE           =
    ==============================*/
    /// @dev token address => allowance
    mapping(address => bool) private _tokenAddressIsAllowed;
    /// @dev orderId => execution
    mapping(uint256 => bool) private _orderIdIsExecuted;
    /// @dev The address where any withdraw value is send to
    address payable private _withdrawAddress;

    /*==============================
    =          MODIFIERS           =
    ==============================*/

    /*==============================
    =          CONSTRUCTOR         =
    ==============================*/
    /// @dev Contract constructor sets initial owners and required number of confirmations.
    /// @param _owners List of initial owners.
    /// @param allowedTokens List of allowed tokens.
    /// @param _required Number of required confirmations.
    /// @param withdrawAddress The withdraw address.
    constructor(
        address[] memory _owners,
        address[] memory allowedTokens,
        uint256 _required,
        address payable withdrawAddress
    ) MultiSigEthAdmin(_owners, _required) {
        require(
            withdrawAddress != address(0),
            "A withdraw address is required"
        );

        for (uint256 index = 0; index < allowedTokens.length; index++) {
            _updateAllowedToken(allowedTokens[index], true);
        }

        _updateWithdrawAddress(withdrawAddress);

        _registerInterface(type(IMultiSigEthPayments).interfaceId);
    }

    /*==============================
    =      PUBLIC & EXTERNAL       =
    ==============================*/
    function payEthOrder(uint256 orderId) external payable override {
        require(
            !_orderIdIsExecuted[orderId],
            "This order is executed already."
        );
        _orderIdIsExecuted[orderId] = true;
        OnPayedEthOrder(orderId, msg.value);
    }

    function payTokenOrder(
        uint256 orderId,
        address tokenAddress,
        uint256 amount
    ) external override {
        require(
            _tokenAddressIsAllowed[tokenAddress],
            "This token is not allowed."
        );
        require(
            !_orderIdIsExecuted[orderId],
            "This order is executed already."
        );
        IERC20 tokenContract = IERC20(tokenAddress);

        bool success =
            tokenContract.transferFrom(msg.sender, address(this), amount);
        require(success, "Paying the order with tokens failed.");

        _orderIdIsExecuted[orderId] = true;
        OnPayedTokenOrder(orderId, tokenAddress, amount);
    }

    /*==============================
    =          RESTRICTED          =
    ==============================*/
    function updateAllowedToken(address tokenAddress, bool allowed)
        public
        override
        isAuthorizedWallet()
    {
        _updateAllowedToken(tokenAddress, allowed);
    }

    function updateWithdrawAddress(address payable withdrawAddress)
        public
        override
        isAuthorizedWallet()
    {
        _updateWithdrawAddress(withdrawAddress);
    }

    function withdraw() external override isAuthorizedOwner(msg.sender) {
        uint256 amount = address(this).balance;
        _withdrawAddress.transfer(amount);

        emit OnEthWithdraw(_withdrawAddress, amount);
    }

    function withdrawToken(address tokenAddress)
        external
        override
        isAuthorizedOwner(msg.sender)
    {
        IERC20 erc20Contract = IERC20(tokenAddress);
        uint256 amount = erc20Contract.balanceOf(address(this));
        erc20Contract.transfer(_withdrawAddress, amount);

        emit OnTokenWithdraw(_withdrawAddress, tokenAddress, amount);
    }

    /*==============================
    =          VIEW & PURE         =
    ==============================*/
    function isTokenAllowed(address tokenAddress)
        public
        view
        override
        returns (bool)
    {
        return _tokenAddressIsAllowed[tokenAddress];
    }

    function isOrderIdExecuted(uint256 orderId)
        public
        view
        override
        returns (bool)
    {
        return _orderIdIsExecuted[orderId];
    }

    function getWithdrawAddress() public view override returns (address) {
        return _withdrawAddress;
    }

    /*==============================
    =      INTERNAL & PRIVATE      =
    ==============================*/
    function _updateWithdrawAddress(address payable withdrawAddress) private {
        _withdrawAddress = withdrawAddress;
        OnWithdrawAddressUpdate(withdrawAddress);
    }

    function _updateAllowedToken(address tokenAddress, bool allowed) private {
        _tokenAddressIsAllowed[tokenAddress] = allowed;
        OnTokenUpdate(tokenAddress, allowed);
    }
}