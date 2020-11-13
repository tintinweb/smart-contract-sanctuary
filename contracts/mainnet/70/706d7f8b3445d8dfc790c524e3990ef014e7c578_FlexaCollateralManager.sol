// SPDX-License-Identifier: MIT

pragma solidity 0.6.10;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IAmp {
    function registerCollateralManager() external;
}

/**
 * @title Ownable is a contract the provides contract ownership functionality, including a two-
 * phase transfer.
 */
contract Ownable {
    address private _owner;
    address private _authorizedNewOwner;

    /**
     * @notice Emitted when the owner authorizes ownership transfer to a new address
     * @param authorizedAddress New owner address
     */
    event OwnershipTransferAuthorization(address indexed authorizedAddress);

    /**
     * @notice Emitted when the authorized address assumed ownership
     * @param oldValue Old owner
     * @param newValue New owner
     */
    event OwnerUpdate(address indexed oldValue, address indexed newValue);

    /**
     * @notice Sets the owner to the sender / contract creator
     */
    constructor() internal {
        _owner = msg.sender;
    }

    /**
     * @notice Retrieves the owner of the contract
     * @return The contract owner
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @notice Retrieves the authorized new owner of the contract
     * @return The authorized new contract owner
     */
    function authorizedNewOwner() public view returns (address) {
        return _authorizedNewOwner;
    }

    /**
     * @notice Authorizes the transfer of ownership from owner to the provided address.
     * NOTE: No transfer will occur unless authorizedAddress calls assumeOwnership().
     * This authorization may be removed by another call to this function authorizing the zero
     * address.
     * @param _authorizedAddress The address authorized to become the new owner
     */
    function authorizeOwnershipTransfer(address _authorizedAddress) external {
        require(msg.sender == _owner, "Invalid sender");

        _authorizedNewOwner = _authorizedAddress;

        emit OwnershipTransferAuthorization(_authorizedNewOwner);
    }

    /**
     * @notice Transfers ownership of this contract to the _authorizedNewOwner
     * @dev Error invalid sender.
     */
    function assumeOwnership() external {
        require(msg.sender == _authorizedNewOwner, "Invalid sender");

        address oldValue = _owner;
        _owner = _authorizedNewOwner;
        _authorizedNewOwner = address(0);

        emit OwnerUpdate(oldValue, _owner);
    }
}

abstract contract ERC1820Registry {
    function setInterfaceImplementer(
        address _addr,
        bytes32 _interfaceHash,
        address _implementer
    ) external virtual;

    function getInterfaceImplementer(address _addr, bytes32 _interfaceHash)
        external
        virtual
        view
        returns (address);

    function setManager(address _addr, address _newManager) external virtual;

    function getManager(address _addr) public virtual view returns (address);
}

/// Base client to interact with the registry.
contract ERC1820Client {
    ERC1820Registry constant ERC1820REGISTRY = ERC1820Registry(
        0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24
    );

    function setInterfaceImplementation(
        string memory _interfaceLabel,
        address _implementation
    ) internal {
        bytes32 interfaceHash = keccak256(abi.encodePacked(_interfaceLabel));
        ERC1820REGISTRY.setInterfaceImplementer(
            address(this),
            interfaceHash,
            _implementation
        );
    }

    function interfaceAddr(address addr, string memory _interfaceLabel)
        internal
        view
        returns (address)
    {
        bytes32 interfaceHash = keccak256(abi.encodePacked(_interfaceLabel));
        return ERC1820REGISTRY.getInterfaceImplementer(addr, interfaceHash);
    }

    function delegateManagement(address _newManager) internal {
        ERC1820REGISTRY.setManager(address(this), _newManager);
    }
}

/**
 * @title IAmpTokensRecipient
 * @dev IAmpTokensRecipient token transfer hook interface
 */
interface IAmpTokensRecipient {
    /**
     * @dev Report if the recipient will successfully receive the tokens
     */
    function canReceive(
        bytes4 functionSig,
        bytes32 partition,
        address operator,
        address from,
        address to,
        uint256 value,
        bytes calldata data,
        bytes calldata operatorData
    ) external view returns (bool);

    /**
     * @dev Hook executed upon a transfer to the recipient
     */
    function tokensReceived(
        bytes4 functionSig,
        bytes32 partition,
        address operator,
        address from,
        address to,
        uint256 value,
        bytes calldata data,
        bytes calldata operatorData
    ) external;
}

/**
 * @title IAmpTokensSender
 * @dev IAmpTokensSender token transfer hook interface
 */
interface IAmpTokensSender {
    /**
     * @dev Report if the transfer will succeed from the pespective of the
     * token sender
     */
    function canTransfer(
        bytes4 functionSig,
        bytes32 partition,
        address operator,
        address from,
        address to,
        uint256 value,
        bytes calldata data,
        bytes calldata operatorData
    ) external view returns (bool);

    /**
     * @dev Hook executed upon a transfer on behalf of the sender
     */
    function tokensToTransfer(
        bytes4 functionSig,
        bytes32 partition,
        address operator,
        address from,
        address to,
        uint256 value,
        bytes calldata data,
        bytes calldata operatorData
    ) external;
}

/**
 * @title PartitionUtils
 * @notice Partition related helper functions.
 */

library PartitionUtils {
    bytes32 public constant CHANGE_PARTITION_FLAG = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    /**
     * @notice Retrieve the destination partition from the 'data' field.
     * A partition change is requested ONLY when 'data' starts with the flag:
     *
     *   0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
     *
     * When the flag is detected, the destination partition is extracted from the
     * 32 bytes following the flag.
     * @param _data Information attached to the transfer. Will contain the
     * destination partition if a change is requested.
     * @param _fallbackPartition Partition value to return if a partition change
     * is not requested in the `_data`.
     * @return toPartition Destination partition. If the `_data` does not contain
     * the prefix and bytes32 partition in the first 64 bytes, the method will
     * return the provided `_fromPartition`.
     */
    function _getDestinationPartition(bytes memory _data, bytes32 _fallbackPartition)
        internal
        pure
        returns (bytes32)
    {
        if (_data.length < 64) {
            return _fallbackPartition;
        }

        (bytes32 flag, bytes32 toPartition) = abi.decode(_data, (bytes32, bytes32));
        if (flag == CHANGE_PARTITION_FLAG) {
            return toPartition;
        }

        return _fallbackPartition;
    }

    /**
     * @notice Helper to get the strategy identifying prefix from the `_partition`.
     * @param _partition Partition to get the prefix for.
     * @return 4 byte partition strategy prefix.
     */
    function _getPartitionPrefix(bytes32 _partition) internal pure returns (bytes4) {
        return bytes4(_partition);
    }

    /**
     * @notice Helper method to split the partition into the prefix, sub partition
     * and partition owner components.
     * @param _partition The partition to split into parts.
     * @return The 4 byte partition prefix, 8 byte sub partition, and final 20
     * bytes representing an address.
     */
    function _splitPartition(bytes32 _partition)
        internal
        pure
        returns (
            bytes4,
            bytes8,
            address
        )
    {
        bytes4 prefix = bytes4(_partition);
        bytes8 subPartition = bytes8(_partition << 32);
        address addressPart = address(uint160(uint256(_partition)));
        return (prefix, subPartition, addressPart);
    }

    /**
     * @notice Helper method to get a partition strategy ERC1820 interface name
     * based on partition prefix.
     * @param _prefix 4 byte partition prefix.
     * @dev Each 4 byte prefix has a unique interface name so that an individual
     * hook implementation can be set for each prefix.
     */
    function _getPartitionStrategyValidatorIName(bytes4 _prefix)
        internal
        pure
        returns (string memory)
    {
        return string(abi.encodePacked("AmpPartitionStrategyValidator", _prefix));
    }
}

/**
 * @title FlexaCollateralManager is an implementation of IAmpTokensSender and IAmpTokensRecipient
 * which serves as the Amp collateral manager for the Flexa Network.
 */
contract FlexaCollateralManager is Ownable, IAmpTokensSender, IAmpTokensRecipient, ERC1820Client {
    /**
     * @dev AmpTokensSender interface label.
     */
    string internal constant AMP_TOKENS_SENDER = "AmpTokensSender";

    /**
     * @dev AmpTokensRecipient interface label.
     */
    string internal constant AMP_TOKENS_RECIPIENT = "AmpTokensRecipient";

    /**
     * @dev Change Partition Flag used in transfer data parameters to signal which partition
     * will receive the tokens.
     */
    bytes32
        internal constant CHANGE_PARTITION_FLAG = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    /**
     * @dev Required prefix for all registered partitions. Used to ensure the Collateral Pool
     * Partition Validator is used within Amp.
     */
    bytes4 internal constant PARTITION_PREFIX = 0xCCCCCCCC;

    /**********************************************************************************************
     * Operator Data Flags
     *********************************************************************************************/

    /**
     * @dev Flag used in operator data parameters to indicate the transfer is a withdrawal
     */
    bytes32
        internal constant WITHDRAWAL_FLAG = 0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;

    /**
     * @dev Flag used in operator data parameters to indicate the transfer is a fallback
     * withdrawal
     */
    bytes32
        internal constant FALLBACK_WITHDRAWAL_FLAG = 0xbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb;

    /**
     * @dev Flag used in operator data parameters to indicate the transfer is a supply refund
     */
    bytes32
        internal constant REFUND_FLAG = 0xcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc;

    /**
     * @dev Flag used in operator data parameters to indicate the transfer is a direct transfer
     */
    bytes32
        internal constant DIRECT_TRANSFER_FLAG = 0xdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;

    /**********************************************************************************************
     * Configuration
     *********************************************************************************************/

    /**
     * @notice Address of the Amp contract. Immutable.
     */
    address public amp;

    /**
     * @notice Permitted partitions
     */
    mapping(bytes32 => bool) public partitions;

    /**********************************************************************************************
     * Roles
     *********************************************************************************************/

    /**
     * @notice Address authorized to publish withdrawal roots
     */
    address public withdrawalPublisher;

    /**
     * @notice Address authorized to publish fallback withdrawal roots
     */
    address public fallbackPublisher;

    /**
     * @notice Address authorized to adjust the withdrawal limit
     */
    address public withdrawalLimitPublisher;

    /**
     * @notice Address authorized to directly transfer tokens
     */
    address public directTransferer;

    /**
     * @notice Address authorized to manage permitted partition
     */
    address public partitionManager;

    /**
     * @notice Struct used to record received tokens that can be recovered during the fallback
     * withdrawal period
     * @param supplier Token supplier
     * @param partition Partition which received the tokens
     * @param amount Number of tokens received
     */
    struct Supply {
        address supplier;
        bytes32 partition;
        uint256 amount;
    }

    /**********************************************************************************************
     * Supply State
     *********************************************************************************************/

    /**
     * @notice Supply nonce used to track incoming token transfers
     */
    uint256 public supplyNonce = 0;

    /**
     * @notice Mapping of all incoming token transfers
     */
    mapping(uint256 => Supply) public nonceToSupply;

    /**********************************************************************************************
     * Withdrawal State
     *********************************************************************************************/

    /**
     * @notice Remaining withdrawal limit. Initially set to 100,000 Amp.
     */
    uint256 public withdrawalLimit = 100 * 1000 * (10**18);

    /**
     * @notice Withdrawal maximum root nonce
     */
    uint256 public maxWithdrawalRootNonce = 0;

    /**
     * @notice Active set of withdrawal roots
     */
    mapping(bytes32 => uint256) public withdrawalRootToNonce;

    /**
     * @notice Last invoked withdrawal root for each account, per partition
     */
    mapping(bytes32 => mapping(address => uint256)) public addressToWithdrawalNonce;

    /**
     * @notice Total amount withdrawn for each account, per partition
     */
    mapping(bytes32 => mapping(address => uint256)) public addressToCumulativeAmountWithdrawn;

    /**********************************************************************************************
     * Fallback Withdrawal State
     *********************************************************************************************/

    /**
     * @notice Withdrawal fallback delay. Initially set to one week.
     */
    uint256 public fallbackWithdrawalDelaySeconds = 1 weeks;

    /**
     * @notice Current fallback withdrawal root
     */
    bytes32 public fallbackRoot;

    /**
     * @notice Timestamp of when the last fallback root was published
     */
    uint256 public fallbackSetDate = 2**200; // very far in the future

    /**
     * @notice Latest supply reflected in the fallback withdrawal authorization tree
     */
    uint256 public fallbackMaxIncludedSupplyNonce = 0;

    /**********************************************************************************************
     * Supplier Events
     *********************************************************************************************/

    /**
     * @notice Indicates a token supply has been received
     * @param supplier Token supplier
     * @param amount Number of tokens transferred
     * @param nonce Nonce of the supply
     */
    event SupplyReceipt(
        address indexed supplier,
        bytes32 indexed partition,
        uint256 amount,
        uint256 indexed nonce
    );

    /**
     * @notice Indicates that a withdrawal was executed
     * @param supplier Address whose withdrawal authorization was executed
     * @param partition Partition from which the tokens were transferred
     * @param amount Amount of tokens transferred
     * @param rootNonce Nonce of the withdrawal root used for authorization
     * @param authorizedAccountNonce Maximum previous nonce used by the account
     */
    event Withdrawal(
        address indexed supplier,
        bytes32 indexed partition,
        uint256 amount,
        uint256 indexed rootNonce,
        uint256 authorizedAccountNonce
    );

    /**
     * @notice Indicates a fallback withdrawal was executed
     * @param supplier Address whose fallback withdrawal authorization was executed
     * @param partition Partition from which the tokens were transferred
     * @param amount Amount of tokens transferred
     */
    event FallbackWithdrawal(
        address indexed supplier,
        bytes32 indexed partition,
        uint256 indexed amount
    );

    /**
     * @notice Indicates a release of supply is requested
     * @param supplier Token supplier
     * @param partition Parition from which the tokens should be released
     * @param amount Number of tokens requested to be released
     * @param data Metadata provided by the requestor
     */
    event ReleaseRequest(
        address indexed supplier,
        bytes32 indexed partition,
        uint256 indexed amount,
        bytes data
    );

    /**
     * @notice Indicates a supply refund was executed
     * @param supplier Address whose refund authorization was executed
     * @param partition Partition from which the tokens were transferred
     * @param amount Amount of tokens transferred
     * @param nonce Nonce of the original supply
     */
    event SupplyRefund(
        address indexed supplier,
        bytes32 indexed partition,
        uint256 amount,
        uint256 indexed nonce
    );

    /**********************************************************************************************
     * Direct Transfer Events
     *********************************************************************************************/

    /**
     * @notice Emitted when tokens are directly transfered
     * @param operator Address that executed the direct transfer
     * @param from_partition Partition from which the tokens were transferred
     * @param to_address Address to which the tokens were transferred
     * @param to_partition Partition to which the tokens were transferred
     * @param value Amount of tokens transferred
     */
    event DirectTransfer(
        address operator,
        bytes32 indexed from_partition,
        address indexed to_address,
        bytes32 indexed to_partition,
        uint256 value
    );

    /**********************************************************************************************
     * Admin Configuration Events
     *********************************************************************************************/

    /**
     * @notice Emitted when a partition is permitted for supply
     * @param partition Partition added to the permitted set
     */
    event PartitionAdded(bytes32 indexed partition);

    /**
     * @notice Emitted when a partition is removed from the set permitted for supply
     * @param partition Partition removed from the permitted set
     */
    event PartitionRemoved(bytes32 indexed partition);

    /**********************************************************************************************
     * Admin Withdrawal Management Events
     *********************************************************************************************/

    /**
     * @notice Emitted when a new withdrawal root hash is added to the active set
     * @param rootHash Merkle root hash.
     * @param nonce Nonce of the Merkle root hash.
     */
    event WithdrawalRootHashAddition(bytes32 indexed rootHash, uint256 indexed nonce);

    /**
     * @notice Emitted when a withdrawal root hash is removed from the active set
     * @param rootHash Merkle root hash.
     * @param nonce Nonce of the Merkle root hash.
     */
    event WithdrawalRootHashRemoval(bytes32 indexed rootHash, uint256 indexed nonce);

    /**
     * @notice Emitted when the withdrawal limit is updated
     * @param oldValue Old limit.
     * @param newValue New limit.
     */
    event WithdrawalLimitUpdate(uint256 indexed oldValue, uint256 indexed newValue);

    /**********************************************************************************************
     * Admin Fallback Management Events
     *********************************************************************************************/

    /**
     * @notice Emitted when a new fallback withdrawal root hash is set
     * @param rootHash Merkle root hash
     * @param maxSupplyNonceIncluded Nonce of the last supply reflected in the tree data
     * @param setDate Timestamp of when the root hash was set
     */
    event FallbackRootHashSet(
        bytes32 indexed rootHash,
        uint256 indexed maxSupplyNonceIncluded,
        uint256 setDate
    );

    /**
     * @notice Emitted when the fallback root hash set date is reset
     * @param newDate Timestamp of when the fallback reset date was set
     */
    event FallbackMechanismDateReset(uint256 indexed newDate);

    /**
     * @notice Emitted when the fallback delay is updated
     * @param oldValue Old delay
     * @param newValue New delay
     */
    event FallbackWithdrawalDelayUpdate(uint256 indexed oldValue, uint256 indexed newValue);

    /**********************************************************************************************
     * Role Management Events
     *********************************************************************************************/

    /**
     * @notice Emitted when the Withdrawal Publisher is updated
     * @param oldValue Old publisher
     * @param newValue New publisher
     */
    event WithdrawalPublisherUpdate(address indexed oldValue, address indexed newValue);

    /**
     * @notice Emitted when the Fallback Publisher is updated
     * @param oldValue Old publisher
     * @param newValue New publisher
     */
    event FallbackPublisherUpdate(address indexed oldValue, address indexed newValue);

    /**
     * @notice Emitted when Withdrawal Limit Publisher is updated
     * @param oldValue Old publisher
     * @param newValue New publisher
     */
    event WithdrawalLimitPublisherUpdate(address indexed oldValue, address indexed newValue);

    /**
     * @notice Emitted when the DirectTransferer address is updated
     * @param oldValue Old DirectTransferer address
     * @param newValue New DirectTransferer address
     */
    event DirectTransfererUpdate(address indexed oldValue, address indexed newValue);

    /**
     * @notice Emitted when the Partition Manager address is updated
     * @param oldValue Old Partition Manager address
     * @param newValue New Partition Manager address
     */
    event PartitionManagerUpdate(address indexed oldValue, address indexed newValue);

    /**********************************************************************************************
     * Constructor
     *********************************************************************************************/

    /**
     * @notice FlexaCollateralManager constructor
     * @param _amp Address of the Amp token contract
     */
    constructor(address _amp) public {
        amp = _amp;

        ERC1820Client.setInterfaceImplementation(AMP_TOKENS_RECIPIENT, address(this));
        ERC1820Client.setInterfaceImplementation(AMP_TOKENS_SENDER, address(this));

        IAmp(amp).registerCollateralManager();
    }

    /**********************************************************************************************
     * IAmpTokensRecipient Hooks
     *********************************************************************************************/

    /**
     * @notice Validates where the supplied parameters are valid for a transfer of tokens to this
     * contract
     * @dev Implements IAmpTokensRecipient
     * @param _partition Partition from which the tokens were transferred
     * @param _to The destination address of the tokens. Must be this.
     * @param _data Optional data sent with the transfer. Used to set the destination partition.
     * @return true if the tokens can be received, otherwise false
     */
    function canReceive(
        bytes4, /* functionSig */
        bytes32 _partition,
        address, /* operator */
        address, /* from */
        address _to,
        uint256, /* value */
        bytes calldata _data,
        bytes calldata /* operatorData */
    ) external override view returns (bool) {
        if (msg.sender != amp || _to != address(this)) {
            return false;
        }

        bytes32 _destinationPartition = PartitionUtils._getDestinationPartition(_data, _partition);

        return partitions[_destinationPartition];
    }

    /**
     * @notice Function called by the token contract after executing a transfer.
     * @dev Implements IAmpTokensRecipient
     * @param _partition Partition from which the tokens were transferred
     * @param _operator Address which triggered the transfer. This address will be credited with
     * the supply.
     * @param _to The destination address of the tokens. Must be this.
     * @param _value Number of tokens the token holder balance is decreased by.
     * @param _data Optional data sent with the transfer. Used to set the destination partition.
     */
    function tokensReceived(
        bytes4, /* functionSig */
        bytes32 _partition,
        address _operator,
        address, /* from */
        address _to,
        uint256 _value,
        bytes calldata _data,
        bytes calldata /* operatorData */
    ) external override {
        require(msg.sender == amp, "Invalid sender");
        require(_to == address(this), "Invalid to address");

        bytes32 _destinationPartition = PartitionUtils._getDestinationPartition(_data, _partition);

        require(partitions[_destinationPartition], "Invalid destination partition");

        supplyNonce = SafeMath.add(supplyNonce, 1);
        nonceToSupply[supplyNonce].supplier = _operator;
        nonceToSupply[supplyNonce].partition = _destinationPartition;
        nonceToSupply[supplyNonce].amount = _value;

        emit SupplyReceipt(_operator, _destinationPartition, _value, supplyNonce);
    }

    /**********************************************************************************************
     * IAmpTokensSender Hooks
     *********************************************************************************************/

    /**
     * @notice Validates where the supplied parameters are valid for a transfer of tokens from this
     * contract
     * @dev Implements IAmpTokensSender
     * @param _partition Source partition of the tokens
     * @param _operator Address which triggered the transfer
     * @param _from The source address of the tokens. Must be this.
     * @param _value Amount of tokens to be transferred
     * @param _operatorData Extra information attached by the operator. Must include the transfer
     * operation flag and additional authorization data custom for each transfer operation type.
     * @return true if the token transfer would succeed, otherwise false
     */
    function canTransfer(
        bytes4, /*functionSig*/
        bytes32 _partition,
        address _operator,
        address _from,
        address, /* to */
        uint256 _value,
        bytes calldata, /* data */
        bytes calldata _operatorData
    ) external override view returns (bool) {
        if (msg.sender != amp || _from != address(this)) {
            return false;
        }

        bytes32 flag = _decodeOperatorDataFlag(_operatorData);

        if (flag == WITHDRAWAL_FLAG) {
            return _validateWithdrawal(_partition, _operator, _value, _operatorData);
        }
        if (flag == FALLBACK_WITHDRAWAL_FLAG) {
            return _validateFallbackWithdrawal(_partition, _operator, _value, _operatorData);
        }
        if (flag == REFUND_FLAG) {
            return _validateRefund(_partition, _operator, _value, _operatorData);
        }
        if (flag == DIRECT_TRANSFER_FLAG) {
            return _validateDirectTransfer(_operator, _value);
        }

        return false;
    }

    /**
     * @notice Function called by the token contract when executing a transfer
     * @dev Implements IAmpTokensSender
     * @param _partition Source partition of the tokens
     * @param _operator Address which triggered the transfer
     * @param _from The source address of the tokens. Must be this.
     * @param _to The target address of the tokens.
     * @param _value Amount of tokens to be transferred
     * @param _data Data attached to the transfer. Typically includes partition change information.
     * @param _operatorData Extra information attached by the operator. Must include the transfer
     * operation flag and additional authorization data custom for each transfer operation type.
     */
    function tokensToTransfer(
        bytes4, /* functionSig */
        bytes32 _partition,
        address _operator,
        address _from,
        address _to,
        uint256 _value,
        bytes calldata _data,
        bytes calldata _operatorData
    ) external override {
        require(msg.sender == amp, "Invalid sender");
        require(_from == address(this), "Invalid from address");

        bytes32 flag = _decodeOperatorDataFlag(_operatorData);

        if (flag == WITHDRAWAL_FLAG) {
            _executeWithdrawal(_partition, _operator, _value, _operatorData);
        } else if (flag == FALLBACK_WITHDRAWAL_FLAG) {
            _executeFallbackWithdrawal(_partition, _operator, _value, _operatorData);
        } else if (flag == REFUND_FLAG) {
            _executeRefund(_partition, _operator, _value, _operatorData);
        } else if (flag == DIRECT_TRANSFER_FLAG) {
            _executeDirectTransfer(_partition, _operator, _to, _value, _data);
        } else {
            revert("invalid flag");
        }
    }

    /**********************************************************************************************
     * Withdrawals
     *********************************************************************************************/

    /**
     * @notice Validates withdrawal data
     * @param _partition Source partition of the withdrawal
     * @param _operator Address that is invoking the transfer
     * @param _value Number of tokens to be transferred
     * @param _operatorData Contains the withdrawal authorization data
     * @return true if the withdrawal data is valid, otherwise false
     */
    function _validateWithdrawal(
        bytes32 _partition,
        address _operator,
        uint256 _value,
        bytes memory _operatorData
    ) internal view returns (bool) {
        (
            address supplier,
            uint256 maxAuthorizedAccountNonce,
            uint256 withdrawalRootNonce
        ) = _getWithdrawalData(_partition, _value, _operatorData);

        return
            _validateWithdrawalData(
                _partition,
                _operator,
                _value,
                supplier,
                maxAuthorizedAccountNonce,
                withdrawalRootNonce
            );
    }

    /**
     * @notice Validates the withdrawal data and updates state to reflect the transfer
     * @param _partition Source partition of the withdrawal
     * @param _operator Address that is invoking the transfer
     * @param _value Number of tokens to be transferred
     * @param _operatorData Contains the withdrawal authorization data
     */
    function _executeWithdrawal(
        bytes32 _partition,
        address _operator,
        uint256 _value,
        bytes memory _operatorData
    ) internal {
        (
            address supplier,
            uint256 maxAuthorizedAccountNonce,
            uint256 withdrawalRootNonce
        ) = _getWithdrawalData(_partition, _value, _operatorData);

        require(
            _validateWithdrawalData(
                _partition,
                _operator,
                _value,
                supplier,
                maxAuthorizedAccountNonce,
                withdrawalRootNonce
            ),
            "Transfer unauthorized"
        );

        addressToCumulativeAmountWithdrawn[_partition][supplier] = SafeMath.add(
            _value,
            addressToCumulativeAmountWithdrawn[_partition][supplier]
        );

        addressToWithdrawalNonce[_partition][supplier] = withdrawalRootNonce;

        withdrawalLimit = SafeMath.sub(withdrawalLimit, _value);

        emit Withdrawal(
            supplier,
            _partition,
            _value,
            withdrawalRootNonce,
            maxAuthorizedAccountNonce
        );
    }

    /**
     * @notice Extracts withdrawal data from the supplied parameters
     * @param _partition Source partition of the withdrawal
     * @param _value Number of tokens to be transferred
     * @param _operatorData Contains the withdrawal authorization data, including the withdrawal
     * operation flag, supplier, maximum authorized account nonce, and Merkle proof.
     * @return supplier, the address whose account is authorized
     * @return maxAuthorizedAccountNonce, the maximum existing used withdrawal nonce for the
     * supplier and partition
     * @return withdrawalRootNonce, the active withdrawal root nonce found based on the supplied
     * data and Merkle proof
     */
    function _getWithdrawalData(
        bytes32 _partition,
        uint256 _value,
        bytes memory _operatorData
    )
        internal
        view
        returns (
            address, /* supplier */
            uint256, /* maxAuthorizedAccountNonce */
            uint256 /* withdrawalRootNonce */
        )
    {
        (
            address supplier,
            uint256 maxAuthorizedAccountNonce,
            bytes32[] memory merkleProof
        ) = _decodeWithdrawalOperatorData(_operatorData);

        bytes32 leafDataHash = _calculateWithdrawalLeaf(
            supplier,
            _partition,
            _value,
            maxAuthorizedAccountNonce
        );

        bytes32 calculatedRoot = _calculateMerkleRoot(merkleProof, leafDataHash);
        uint256 withdrawalRootNonce = withdrawalRootToNonce[calculatedRoot];

        return (supplier, maxAuthorizedAccountNonce, withdrawalRootNonce);
    }

    /**
     * @notice Validates that the parameters are valid for the requested withdrawal
     * @param _partition Source partition of the tokens
     * @param _operator Address that is executing the withdrawal
     * @param _value Number of tokens to be transferred
     * @param _supplier The address whose account is authorized
     * @param _maxAuthorizedAccountNonce The maximum existing used withdrawal nonce for the
     * supplier and partition
     * @param _withdrawalRootNonce The active withdrawal root nonce found based on the supplied
     * data and Merkle proof
     * @return true if the withdrawal data is valid, otherwise false
     */
    function _validateWithdrawalData(
        bytes32 _partition,
        address _operator,
        uint256 _value,
        address _supplier,
        uint256 _maxAuthorizedAccountNonce,
        uint256 _withdrawalRootNonce
    ) internal view returns (bool) {
        return
            // Only owner, withdrawal publisher or supplier can invoke withdrawals
            (_operator == owner() || _operator == withdrawalPublisher || _operator == _supplier) &&
            // Ensure maxAuthorizedAccountNonce has not been exceeded
            (addressToWithdrawalNonce[_partition][_supplier] <= _maxAuthorizedAccountNonce) &&
            // Ensure we are within the global withdrawal limit
            (_value <= withdrawalLimit) &&
            // Merkle tree proof is valid
            (_withdrawalRootNonce > 0) &&
            // Ensure the withdrawal root is more recent than the maxAuthorizedAccountNonce
            (_withdrawalRootNonce > _maxAuthorizedAccountNonce);
    }

    /**********************************************************************************************
     * Fallback Withdrawals
     *********************************************************************************************/

    /**
     * @notice Validates fallback withdrawal data
     * @param _partition Source partition of the withdrawal
     * @param _operator Address that is invoking the transfer
     * @param _value Number of tokens to be transferred
     * @param _operatorData Contains the fallback withdrawal authorization data
     * @return true if the fallback withdrawal data is valid, otherwise false
     */
    function _validateFallbackWithdrawal(
        bytes32 _partition,
        address _operator,
        uint256 _value,
        bytes memory _operatorData
    ) internal view returns (bool) {
        (
            address supplier,
            uint256 maxCumulativeWithdrawalAmount,
            uint256 newCumulativeWithdrawalAmount,
            bytes32 calculatedRoot
        ) = _getFallbackWithdrawalData(_partition, _value, _operatorData);

        return
            _validateFallbackWithdrawalData(
                _operator,
                maxCumulativeWithdrawalAmount,
                newCumulativeWithdrawalAmount,
                supplier,
                calculatedRoot
            );
    }

    /**
     * @notice Validates the fallback withdrawal data and updates state to reflect the transfer
     * @param _partition Source partition of the withdrawal
     * @param _operator Address that is invoking the transfer
     * @param _value Number of tokens to be transferred
     * @param _operatorData Contains the fallback withdrawal authorization data
     */
    function _executeFallbackWithdrawal(
        bytes32 _partition,
        address _operator,
        uint256 _value,
        bytes memory _operatorData
    ) internal {
        (
            address supplier,
            uint256 maxCumulativeWithdrawalAmount,
            uint256 newCumulativeWithdrawalAmount,
            bytes32 calculatedRoot
        ) = _getFallbackWithdrawalData(_partition, _value, _operatorData);

        require(
            _validateFallbackWithdrawalData(
                _operator,
                maxCumulativeWithdrawalAmount,
                newCumulativeWithdrawalAmount,
                supplier,
                calculatedRoot
            ),
            "Transfer unauthorized"
        );

        addressToCumulativeAmountWithdrawn[_partition][supplier] = newCumulativeWithdrawalAmount;

        addressToWithdrawalNonce[_partition][supplier] = maxWithdrawalRootNonce;

        emit FallbackWithdrawal(supplier, _partition, _value);
    }

    /**
     * @notice Extracts withdrawal data from the supplied parameters
     * @param _partition Source partition of the withdrawal
     * @param _value Number of tokens to be transferred
     * @param _operatorData Contains the fallback withdrawal authorization data, including the
     * fallback withdrawal operation flag, supplier, max cumulative withdrawal amount, and Merkle
     * proof.
     * @return supplier, the address whose account is authorized
     * @return maxCumulativeWithdrawalAmount, the maximum amount of tokens that can be withdrawn
     * for the supplier's account, including both withdrawals and fallback withdrawals
     * @return newCumulativeWithdrawalAmount, the new total of all withdrawals include the
     * current request
     * @return calculatedRoot, the Merkle tree root calculated based on the supplied data and proof
     */
    function _getFallbackWithdrawalData(
        bytes32 _partition,
        uint256 _value,
        bytes memory _operatorData
    )
        internal
        view
        returns (
            address, /* supplier */
            uint256, /* maxCumulativeWithdrawalAmount */
            uint256, /* newCumulativeWithdrawalAmount */
            bytes32 /* calculatedRoot */
        )
    {
        (
            address supplier,
            uint256 maxCumulativeWithdrawalAmount,
            bytes32[] memory merkleProof
        ) = _decodeWithdrawalOperatorData(_operatorData);

        uint256 newCumulativeWithdrawalAmount = SafeMath.add(
            _value,
            addressToCumulativeAmountWithdrawn[_partition][supplier]
        );

        bytes32 leafDataHash = _calculateFallbackLeaf(
            supplier,
            _partition,
            maxCumulativeWithdrawalAmount
        );
        bytes32 calculatedRoot = _calculateMerkleRoot(merkleProof, leafDataHash);

        return (
            supplier,
            maxCumulativeWithdrawalAmount,
            newCumulativeWithdrawalAmount,
            calculatedRoot
        );
    }

    /**
     * @notice Validates that the parameters are valid for the requested fallback withdrawal
     * @param _operator Address that is executing the withdrawal
     * @param _maxCumulativeWithdrawalAmount, the maximum amount of tokens that can be withdrawn
     * for the supplier's account, including both withdrawals and fallback withdrawals
     * @param _newCumulativeWithdrawalAmount, the new total of all withdrawals include the
     * current request
     * @param _supplier The address whose account is authorized
     * @param _calculatedRoot The Merkle tree root calculated based on the supplied data and proof
     * @return true if the fallback withdrawal data is valid, otherwise false
     */
    function _validateFallbackWithdrawalData(
        address _operator,
        uint256 _maxCumulativeWithdrawalAmount,
        uint256 _newCumulativeWithdrawalAmount,
        address _supplier,
        bytes32 _calculatedRoot
    ) internal view returns (bool) {
        return
            // Only owner or supplier can invoke the fallback withdrawal
            (_operator == owner() || _operator == _supplier) &&
            // Ensure we have entered fallback mode
            (SafeMath.add(fallbackSetDate, fallbackWithdrawalDelaySeconds) <= block.timestamp) &&
            // Check that the maximum allowable withdrawal for the supplier has not been exceeded
            (_newCumulativeWithdrawalAmount <= _maxCumulativeWithdrawalAmount) &&
            // Merkle tree proof is valid
            (fallbackRoot == _calculatedRoot);
    }

    /**********************************************************************************************
     * Supply Refunds
     *********************************************************************************************/

    /**
     * @notice Validates refund data
     * @param _partition Source partition of the refund
     * @param _operator Address that is invoking the transfer
     * @param _value Number of tokens to be transferred
     * @param _operatorData Contains the refund authorization data
     * @return true if the refund data is valid, otherwise false
     */
    function _validateRefund(
        bytes32 _partition,
        address _operator,
        uint256 _value,
        bytes memory _operatorData
    ) internal view returns (bool) {
        (uint256 _supplyNonce, Supply memory supply) = _getRefundData(_operatorData);

        return _verifyRefundData(_partition, _operator, _value, _supplyNonce, supply);
    }

    /**
     * @notice Validates the refund data and updates state to reflect the transfer
     * @param _partition Source partition of the refund
     * @param _operator Address that is invoking the transfer
     * @param _value Number of tokens to be transferred
     * @param _operatorData Contains the refund authorization data
     */
    function _executeRefund(
        bytes32 _partition,
        address _operator,
        uint256 _value,
        bytes memory _operatorData
    ) internal {
        (uint256 nonce, Supply memory supply) = _getRefundData(_operatorData);

        require(
            _verifyRefundData(_partition, _operator, _value, nonce, supply),
            "Transfer unauthorized"
        );

        delete nonceToSupply[nonce];

        emit SupplyRefund(supply.supplier, _partition, supply.amount, nonce);
    }

    /**
     * @notice Extracts refund data from the supplied parameters
     * @param _operatorData Contains the refund authorization data, including the refund
     * operation flag and supply nonce.
     * @return supplyNonce, nonce of the recorded supply
     * @return supply, The supplier, partition and amount of tokens in the original supply
     */
    function _getRefundData(bytes memory _operatorData)
        internal
        view
        returns (uint256, Supply memory)
    {
        uint256 _supplyNonce = _decodeRefundOperatorData(_operatorData);
        Supply memory supply = nonceToSupply[_supplyNonce];

        return (_supplyNonce, supply);
    }

    /**
     * @notice Validates that the parameters are valid for the requested refund
     * @param _partition Source partition of the tokens
     * @param _operator Address that is executing the refund
     * @param _value Number of tokens to be transferred
     * @param _supplyNonce nonce of the recorded supply
     * @param _supply The supplier, partition and amount of tokens in the original supply
     * @return true if the refund data is valid, otherwise false
     */
    function _verifyRefundData(
        bytes32 _partition,
        address _operator,
        uint256 _value,
        uint256 _supplyNonce,
        Supply memory _supply
    ) internal view returns (bool) {
        return
            // Supply record exists
            (_supply.amount > 0) &&
            // Only owner or supplier can invoke the refund
            (_operator == owner() || _operator == _supply.supplier) &&
            // Requested partition matches the Supply record
            (_partition == _supply.partition) &&
            // Requested value matches the Supply record
            (_value == _supply.amount) &&
            // Ensure we have entered fallback mode
            (SafeMath.add(fallbackSetDate, fallbackWithdrawalDelaySeconds) <= block.timestamp) &&
            // Supply has not already been included in the fallback withdrawal data
            (_supplyNonce > fallbackMaxIncludedSupplyNonce);
    }

    /**********************************************************************************************
     * Direct Transfers
     *********************************************************************************************/

    /**
     * @notice Validates direct transfer data
     * @param _operator Address that is invoking the transfer
     * @param _value Number of tokens to be transferred
     * @return true if the direct transfer data is valid, otherwise false
     */
    function _validateDirectTransfer(address _operator, uint256 _value)
        internal
        view
        returns (bool)
    {
        return
            // Only owner and directTransferer can invoke withdrawals
            (_operator == owner() || _operator == directTransferer) &&
            // Ensure we are within the global withdrawal limit
            (_value <= withdrawalLimit);
    }

    /**
     * @notice Validates the direct transfer data and updates state to reflect the transfer
     * @param _partition Source partition of the direct transfer
     * @param _operator Address that is invoking the transfer
     * @param _to The target address of the tokens.
     * @param _value Number of tokens to be transferred
     * @param _data Data attached to the transfer. Typically includes partition change information.
     */
    function _executeDirectTransfer(
        bytes32 _partition,
        address _operator,
        address _to,
        uint256 _value,
        bytes memory _data
    ) internal {
        require(_validateDirectTransfer(_operator, _value), "Transfer unauthorized");

        withdrawalLimit = SafeMath.sub(withdrawalLimit, _value);

        bytes32 to_partition = PartitionUtils._getDestinationPartition(_data, _partition);

        emit DirectTransfer(_operator, _partition, _to, to_partition, _value);
    }

    /**********************************************************************************************
     * Release Request
     *********************************************************************************************/

    /**
     * @notice Emits a release request event that can be used to trigger the release of tokens
     * @param _partition Parition from which the tokens should be released
     * @param _amount Number of tokens requested to be released
     * @param _data Metadata to include with the release request
     */
    function requestRelease(
        bytes32 _partition,
        uint256 _amount,
        bytes memory _data
    ) external {
        emit ReleaseRequest(msg.sender, _partition, _amount, _data);
    }

    /**********************************************************************************************
     * Partition Management
     *********************************************************************************************/

    /**
     * @notice Adds a partition to the set allowed to receive tokens
     * @param _partition Parition to be permitted for incoming transfers
     */
    function addPartition(bytes32 _partition) external {
        require(msg.sender == owner() || msg.sender == partitionManager, "Invalid sender");
        require(partitions[_partition] == false, "Partition already permitted");

        (bytes4 prefix, , address partitionOwner) = PartitionUtils._splitPartition(_partition);

        require(prefix == PARTITION_PREFIX, "Invalid partition prefix");
        require(partitionOwner == address(this), "Invalid partition owner");

        partitions[_partition] = true;

        emit PartitionAdded(_partition);
    }

    /**
     * @notice Removes a partition from the set allowed to receive tokens
     * @param _partition Parition to be disallowed from incoming transfers
     */
    function removePartition(bytes32 _partition) external {
        require(msg.sender == owner() || msg.sender == partitionManager, "Invalid sender");
        require(partitions[_partition], "Partition not permitted");

        delete partitions[_partition];

        emit PartitionRemoved(_partition);
    }

    /**********************************************************************************************
     * Withdrawal Management
     *********************************************************************************************/

    /**
     * @notice Modifies the withdrawal limit by the provided amount.
     * @param _amount Limit delta
     */
    function modifyWithdrawalLimit(int256 _amount) external {
        require(msg.sender == owner() || msg.sender == withdrawalLimitPublisher, "Invalid sender");
        uint256 oldLimit = withdrawalLimit;
        if (_amount < 0) {
            uint256 unsignedAmount = uint256(-_amount);
            withdrawalLimit = SafeMath.sub(withdrawalLimit, unsignedAmount);
        } else {
            uint256 unsignedAmount = uint256(_amount);
            withdrawalLimit = SafeMath.add(withdrawalLimit, unsignedAmount);
        }
        emit WithdrawalLimitUpdate(oldLimit, withdrawalLimit);
    }

    /**
     * @notice Adds the root hash of a Merkle tree containing authorized token withdrawals to the
     * active set
     * @param _root The root hash to be added to the active set
     * @param _nonce The nonce of the new root hash. Must be exactly one higher than the existing
     * max nonce.
     * @param _replacedRoots The root hashes to be removed from the repository.
     */
    function addWithdrawalRoot(
        bytes32 _root,
        uint256 _nonce,
        bytes32[] calldata _replacedRoots
    ) external {
        require(msg.sender == owner() || msg.sender == withdrawalPublisher, "Invalid sender");

        require(_root != 0, "Invalid root");
        require(maxWithdrawalRootNonce + 1 == _nonce, "Nonce not current max plus one");
        require(withdrawalRootToNonce[_root] == 0, "Nonce already used");

        withdrawalRootToNonce[_root] = _nonce;
        maxWithdrawalRootNonce = _nonce;

        emit WithdrawalRootHashAddition(_root, _nonce);

        for (uint256 i = 0; i < _replacedRoots.length; i++) {
            deleteWithdrawalRoot(_replacedRoots[i]);
        }
    }

    /**
     * @notice Removes withdrawal root hashes from active set
     * @param _roots The root hashes to be removed from the active set
     */
    function removeWithdrawalRoots(bytes32[] calldata _roots) external {
        require(msg.sender == owner() || msg.sender == withdrawalPublisher, "Invalid sender");

        for (uint256 i = 0; i < _roots.length; i++) {
            deleteWithdrawalRoot(_roots[i]);
        }
    }

    /**
     * @notice Removes a withdrawal root hash from active set
     * @param _root The root hash to be removed from the active set
     */
    function deleteWithdrawalRoot(bytes32 _root) private {
        uint256 nonce = withdrawalRootToNonce[_root];

        require(nonce > 0, "Root not found");

        delete withdrawalRootToNonce[_root];

        emit WithdrawalRootHashRemoval(_root, nonce);
    }

    /**********************************************************************************************
     * Fallback Management
     *********************************************************************************************/

    /**
     * @notice Sets the root hash of the Merkle tree containing fallback
     * withdrawal authorizations.
     * @param _root The root hash of a Merkle tree containing the fallback withdrawal
     * authorizations
     * @param _maxSupplyNonce The nonce of the latest supply whose value is reflected in the
     * fallback withdrawal authorizations.
     */
    function setFallbackRoot(bytes32 _root, uint256 _maxSupplyNonce) external {
        require(msg.sender == owner() || msg.sender == fallbackPublisher, "Invalid sender");
        require(_root != 0, "Invalid root");
        require(
            SafeMath.add(fallbackSetDate, fallbackWithdrawalDelaySeconds) > block.timestamp,
            "Fallback is active"
        );
        require(
            _maxSupplyNonce >= fallbackMaxIncludedSupplyNonce,
            "Included supply nonce decreased"
        );
        require(_maxSupplyNonce <= supplyNonce, "Included supply nonce exceeds latest supply");

        fallbackRoot = _root;
        fallbackMaxIncludedSupplyNonce = _maxSupplyNonce;
        fallbackSetDate = block.timestamp;

        emit FallbackRootHashSet(_root, fallbackMaxIncludedSupplyNonce, block.timestamp);
    }

    /**
     * @notice Resets the fallback set date to the current block's timestamp. This can be used to
     * delay the start of the fallback period without publishing a new root, or to deactivate the
     * fallback mechanism so a new fallback root may be published.
     */
    function resetFallbackMechanismDate() external {
        require(msg.sender == owner() || msg.sender == fallbackPublisher, "Invalid sender");
        fallbackSetDate = block.timestamp;

        emit FallbackMechanismDateReset(fallbackSetDate);
    }

    /**
     * @notice Updates the time-lock period before the fallback mechanism is activated after the
     * last fallback root was published.
     * @param _newFallbackDelaySeconds The new delay period in seconds
     */
    function setFallbackWithdrawalDelay(uint256 _newFallbackDelaySeconds) external {
        require(msg.sender == owner(), "Invalid sender");
        require(_newFallbackDelaySeconds != 0, "Invalid zero delay seconds");
        require(_newFallbackDelaySeconds < 10 * 365 days, "Invalid delay over 10 years");

        uint256 oldDelay = fallbackWithdrawalDelaySeconds;
        fallbackWithdrawalDelaySeconds = _newFallbackDelaySeconds;

        emit FallbackWithdrawalDelayUpdate(oldDelay, _newFallbackDelaySeconds);
    }

    /**********************************************************************************************
     * Role Management
     *********************************************************************************************/

    /**
     * @notice Updates the Withdrawal Publisher address, the only address other than the owner that
     * can publish / remove withdrawal Merkle tree roots.
     * @param _newWithdrawalPublisher The address of the new Withdrawal Publisher
     * @dev Error invalid sender.
     */
    function setWithdrawalPublisher(address _newWithdrawalPublisher) external {
        require(msg.sender == owner(), "Invalid sender");

        address oldValue = withdrawalPublisher;
        withdrawalPublisher = _newWithdrawalPublisher;

        emit WithdrawalPublisherUpdate(oldValue, withdrawalPublisher);
    }

    /**
     * @notice Updates the Fallback Publisher address, the only address other than the owner that
     * can publish / remove fallback withdrawal Merkle tree roots.
     * @param _newFallbackPublisher The address of the new Fallback Publisher
     * @dev Error invalid sender.
     */
    function setFallbackPublisher(address _newFallbackPublisher) external {
        require(msg.sender == owner(), "Invalid sender");

        address oldValue = fallbackPublisher;
        fallbackPublisher = _newFallbackPublisher;

        emit FallbackPublisherUpdate(oldValue, fallbackPublisher);
    }

    /**
     * @notice Updates the Withdrawal Limit Publisher address, the only address other than the
     * owner that can set the withdrawal limit.
     * @param _newWithdrawalLimitPublisher The address of the new Withdrawal Limit Publisher
     * @dev Error invalid sender.
     */
    function setWithdrawalLimitPublisher(address _newWithdrawalLimitPublisher) external {
        require(msg.sender == owner(), "Invalid sender");

        address oldValue = withdrawalLimitPublisher;
        withdrawalLimitPublisher = _newWithdrawalLimitPublisher;

        emit WithdrawalLimitPublisherUpdate(oldValue, withdrawalLimitPublisher);
    }

    /**
     * @notice Updates the DirectTransferer address, the only address other than the owner that
     * can execute direct transfers
     * @param _newDirectTransferer The address of the new DirectTransferer
     */
    function setDirectTransferer(address _newDirectTransferer) external {
        require(msg.sender == owner(), "Invalid sender");

        address oldValue = directTransferer;
        directTransferer = _newDirectTransferer;

        emit DirectTransfererUpdate(oldValue, directTransferer);
    }

    /**
     * @notice Updates the Partition Manager address, the only address other than the owner that
     * can add and remove permitted partitions
     * @param _newPartitionManager The address of the new PartitionManager
     */
    function setPartitionManager(address _newPartitionManager) external {
        require(msg.sender == owner(), "Invalid sender");

        address oldValue = partitionManager;
        partitionManager = _newPartitionManager;

        emit PartitionManagerUpdate(oldValue, partitionManager);
    }

    /**********************************************************************************************
     * Operator Data Decoders
     *********************************************************************************************/

    /**
     * @notice Extract flag from operatorData
     * @param _operatorData The operator data to be decoded
     * @return flag, the transfer operation type
     */
    function _decodeOperatorDataFlag(bytes memory _operatorData) internal pure returns (bytes32) {
        return abi.decode(_operatorData, (bytes32));
    }

    /**
     * @notice Extracts the supplier, max authorized nonce, and Merkle proof from the operator data
     * @param _operatorData The operator data to be decoded
     * @return supplier, the address whose account is authorized
     * @return For withdrawals: max authorized nonce, the last used withdrawal root nonce for the
     * supplier and partition. For fallback withdrawals: max cumulative withdrawal amount, the
     * maximum amount of tokens that can be withdrawn for the supplier's account, including both
     * withdrawals and fallback withdrawals
     * @return proof, the Merkle proof to be used for the authorization
     */
    function _decodeWithdrawalOperatorData(bytes memory _operatorData)
        internal
        pure
        returns (
            address,
            uint256,
            bytes32[] memory
        )
    {
        (, address supplier, uint256 nonce, bytes32[] memory proof) = abi.decode(
            _operatorData,
            (bytes32, address, uint256, bytes32[])
        );

        return (supplier, nonce, proof);
    }

    /**
     * @notice Extracts the supply nonce from the operator data
     * @param _operatorData The operator data to be decoded
     * @return nonce, the nonce of the supply to be refunded
     */
    function _decodeRefundOperatorData(bytes memory _operatorData) internal pure returns (uint256) {
        (, uint256 nonce) = abi.decode(_operatorData, (bytes32, uint256));

        return nonce;
    }

    /**********************************************************************************************
     * Merkle Tree Verification
     *********************************************************************************************/

    /**
     * @notice Hashes the supplied data and returns the hash to be used in conjunction with a proof
     * to calculate the Merkle tree root
     * @param _supplier The address whose account is authorized
     * @param _partition Source partition of the tokens
     * @param _value Number of tokens to be transferred
     * @param _maxAuthorizedAccountNonce The maximum existing used withdrawal nonce for the
     * supplier and partition
     * @return leaf, the hash of the supplied data
     */
    function _calculateWithdrawalLeaf(
        address _supplier,
        bytes32 _partition,
        uint256 _value,
        uint256 _maxAuthorizedAccountNonce
    ) internal pure returns (bytes32) {
        return
            keccak256(abi.encodePacked(_supplier, _partition, _value, _maxAuthorizedAccountNonce));
    }

    /**
     * @notice Hashes the supplied data and returns the hash to be used in conjunction with a proof
     * to calculate the Merkle tree root
     * @param _supplier The address whose account is authorized
     * @param _partition Source partition of the tokens
     * @param _maxCumulativeWithdrawalAmount, the maximum amount of tokens that can be withdrawn
     * for the supplier's account, including both withdrawals and fallback withdrawals
     * @return leaf, the hash of the supplied data
     */
    function _calculateFallbackLeaf(
        address _supplier,
        bytes32 _partition,
        uint256 _maxCumulativeWithdrawalAmount
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_supplier, _partition, _maxCumulativeWithdrawalAmount));
    }

    /**
     * @notice Calculates the Merkle root for the unique Merkle tree described by the provided
       Merkle proof and leaf hash.
     * @param _merkleProof The sibling node hashes at each level of the tree.
     * @param _leafHash The hash of the leaf data for which merkleProof is an inclusion proof.
     * @return The calculated Merkle root.
     */
    function _calculateMerkleRoot(bytes32[] memory _merkleProof, bytes32 _leafHash)
        private
        pure
        returns (bytes32)
    {
        bytes32 computedHash = _leafHash;

        for (uint256 i = 0; i < _merkleProof.length; i++) {
            bytes32 proofElement = _merkleProof[i];

            if (computedHash < proofElement) {
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        return computedHash;
    }
}