pragma solidity 0.6.6;


/**
 * @dev Taken from node_modules/erc1820
 * updated solidity version
 * commented out interfaceAddr & delegateManagement
 */
interface ERC1820Registry {
	function setInterfaceImplementer(
		address _addr,
		bytes32 _interfaceHash,
		address _implementer
	) external;

	function getInterfaceImplementer(address _addr, bytes32 _interfaceHash)
		external
		view
		returns (address);

	function setManager(address _addr, address _newManager) external;

	function getManager(address _addr) external view returns (address);
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
}

pragma solidity 0.6.6;

import "../../node_modules/@openzeppelin/contracts/GSN/IRelayRecipient.sol";
import "../../node_modules/@openzeppelin/contracts/GSN/IRelayHub.sol";
import "../../node_modules/@openzeppelin/contracts/GSN/Context.sol";

import "../storage/SecurityTokenStorage.sol";


// copied here to be included in coverage

/**
 * @dev Base GSN recipient contract: includes the {IRelayRecipient} interface
 * and enables GSN support on all contracts in the inheritance tree.
 *
 * TIP: This contract is abstract. The functions {IRelayRecipient-acceptRelayedCall},
 *  {_preRelayedCall}, and {_postRelayedCall} are not implemented and must be
 * provided by derived contracts. See the
 * xref:ROOT:gsn-strategies.adoc#gsn-strategies[GSN strategies] for more
 * information on how to use the pre-built {GSNRecipientSignature} and
 * {GSNRecipientERC20Fee}, or how to write your own.
 */
abstract contract GSNRecipient is
	SecurityTokenStorage,
	IRelayRecipient,
	Context
{
	/**
	 * @dev Emitted when a contract changes its {IRelayHub} contract to a new one.
	 */
	event RelayHubChanged(
		address indexed oldRelayHub,
		address indexed newRelayHub
	);

	/**
	 * @dev Returns the address of the {IRelayHub} contract for this recipient.
	 */
	function getHubAddr() public override view returns (address) {
		return _relayHub;
	}

	/**
	 * @dev Switches to a new {IRelayHub} instance. This method is added for future-proofing: there's no reason to not
	 * use the default instance.
	 *
	 * IMPORTANT: After upgrading, the {GSNRecipient} will no longer be able to receive relayed calls from the old
	 * {IRelayHub} instance. Additionally, all funds should be previously withdrawn via {_withdrawDeposits}.
	 */
	function _upgradeRelayHub(address newRelayHub) internal virtual {
		address currentRelayHub = _relayHub;
		require(newRelayHub != address(0), "zero address");
		require(newRelayHub != currentRelayHub, "current one");

		emit RelayHubChanged(currentRelayHub, newRelayHub);

		_relayHub = newRelayHub;
	}

	/**
	 * @dev Returns the version string of the {IRelayHub} for which this recipient implementation was built. If
	 * {_upgradeRelayHub} is used, the new {IRelayHub} instance should be compatible with this version.
	 */
	// This function is view for future-proofing, it may require reading from
	// storage in the future.
	function relayHubVersion() public view returns (string memory) {
		this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
		return "1.0.0";
	}

	/**
	 * @dev Withdraws the recipient's deposits in `RelayHub`.
	 *
	 * Derived contracts should expose this in an external interface with proper access control.
	 */
	function _withdrawDeposits(uint256 amount, address payable payee)
		internal
		virtual
	{
		IRelayHub(_relayHub).withdraw(amount, payee);
	}

	// Overrides for Context's functions: when called from RelayHub, sender and
	// data require some pre-processing: the actual sender is stored at the end
	// of the call data, which in turns means it needs to be removed from it
	// when handling said data.

	/**
	 * @dev Replacement for msg.sender. Returns the actual sender of a transaction: msg.sender for regular transactions,
	 * and the end-user for GSN relayed calls (where msg.sender is actually `RelayHub`).
	 *
	 * IMPORTANT: Contracts derived from {GSNRecipient} should never use `msg.sender`, and use {_msgSender} instead.
	 */
	function _msgSender()
		internal
		virtual
		override
		view
		returns (address payable)
	{
		if (msg.sender != _relayHub) {
			return msg.sender;
		} else {
			return _getRelayedCallSender();
		}
	}

	/**
	 * @dev Replacement for msg.data. Returns the actual calldata of a transaction: msg.data for regular transactions,
	 * and a reduced version for GSN relayed calls (where msg.data contains additional information).
	 *
	 * IMPORTANT: Contracts derived from {GSNRecipient} should never use `msg.data`, and use {_msgData} instead.
	 */
	function _msgData() internal virtual override view returns (bytes memory) {
		if (msg.sender != _relayHub) {
			return msg.data;
		} else {
			return _getRelayedCallData();
		}
	}

	// Base implementations for pre and post relayedCall: only RelayHub can invoke them, and data is forwarded to the
	// internal hook.

	/**
	 * @dev See `IRelayRecipient.preRelayedCall`.
	 *
	 * This function should not be overriden directly, use `_preRelayedCall` instead.
	 *
	 * * Requirements:
	 *
	 * - the caller must be the `RelayHub` contract.
	 */
	function preRelayedCall(bytes memory context)
		public
		virtual
		override
		returns (bytes32)
	{
		require(msg.sender == getHubAddr(), "not hub");
		return _preRelayedCall(context);
	}

	/**
	 * @dev See `IRelayRecipient.preRelayedCall`.
	 *
	 * Called by `GSNRecipient.preRelayedCall`, which asserts the caller is the `RelayHub` contract. Derived contracts
	 * must implement this function with any relayed-call preprocessing they may wish to do.
	 *
	 */
	function _preRelayedCall(bytes memory context)
		internal
		virtual
		returns (bytes32);

	/**
	 * @dev See `IRelayRecipient.postRelayedCall`.
	 *
	 * This function should not be overriden directly, use `_postRelayedCall` instead.
	 *
	 * * Requirements:
	 *
	 * - the caller must be the `RelayHub` contract.
	 */
	function postRelayedCall(
		bytes memory context,
		bool success,
		uint256 actualCharge,
		bytes32 preRetVal
	) public virtual override {
		require(msg.sender == getHubAddr(), "not hub");
		_postRelayedCall(context, success, actualCharge, preRetVal);
	}

	/**
	 * @dev See `IRelayRecipient.postRelayedCall`.
	 *
	 * Called by `GSNRecipient.postRelayedCall`, which asserts the caller is the `RelayHub` contract. Derived contracts
	 * must implement this function with any relayed-call postprocessing they may wish to do.
	 *
	 */
	function _postRelayedCall(
		bytes memory context,
		bool success,
		uint256 actualCharge,
		bytes32 preRetVal
	) internal virtual;

	/**
	 * @dev Return this in acceptRelayedCall to proceed with the execution of a relayed call. Note that this contract
	 * will be charged a fee by RelayHub
	 */
	function _approveRelayedCall()
		internal
		view
		returns (uint256, bytes memory)
	{
		return _approveRelayedCall("");
	}

	/**
	 * @dev See `GSNRecipient._approveRelayedCall`.
	 *
	 * This overload forwards `context` to _preRelayedCall and _postRelayedCall.
	 */
	function _approveRelayedCall(bytes memory context)
		internal
		view
		returns (uint256, bytes memory)
	{
		return (_RELAYED_CALL_ACCEPTED, context);
	}

	/**
	 * @dev Return this in acceptRelayedCall to impede execution of a relayed call. No fees will be charged.
	 */
	function _rejectRelayedCall(uint256 errorCode)
		internal
		view
		returns (uint256, bytes memory)
	{
		return (_RELAYED_CALL_REJECTED + errorCode, "");
	}

	/*
	 * @dev Calculates how much RelayHub will charge a recipient for using `gas` at a `gasPrice`, given a relayer's
	 * `serviceFee`.
	 */
	function _computeCharge(
		uint256 gas,
		uint256 gasPrice,
		uint256 serviceFee
	) internal pure returns (uint256) {
		// The fee is expressed as a percentage. E.g. a value of 40 stands for a 40% fee, so the recipient will be
		// charged for 1.4 times the spent amount.
		return (gas * gasPrice * (100 + serviceFee)) / 100;
	}

	function _getRelayedCallSender()
		private
		pure
		returns (address payable result)
	{
		// We need to read 20 bytes (an address) located at array index msg.data.length - 20. In memory, the array
		// is prefixed with a 32-byte length value, so we first add 32 to get the memory read index. However, doing
		// so would leave the address in the upper 20 bytes of the 32-byte word, which is inconvenient and would
		// require bit shifting. We therefore subtract 12 from the read index so the address lands on the lower 20
		// bytes. This can always be done due to the 32-byte prefix.

		// The final memory read index is msg.data.length - 20 + 32 - 12 = msg.data.length. Using inline assembly is the
		// easiest/most-efficient way to perform this operation.

		// These fields are not accessible from assembly
		bytes memory array = msg.data;
		uint256 index = msg.data.length;

		// solhint-disable-next-line no-inline-assembly
		assembly {
			// Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
			result := and(
				mload(add(array, index)),
				0xffffffffffffffffffffffffffffffffffffffff
			)
		}
		return result;
	}

	function _getRelayedCallData() private pure returns (bytes memory) {
		// RelayHub appends the sender address at the end of the calldata, so in order to retrieve the actual msg.data,
		// we must strip the last 20 bytes (length of an address type) from it.

		uint256 actualDataLength = msg.data.length - 20;
		bytes memory actualData = new bytes(actualDataLength);

		for (uint256 i = 0; i < actualDataLength; ++i) {
			actualData[i] = msg.data[i];
		}

		return actualData;
	}
}

pragma solidity 0.6.6;

import "../../node_modules/@openzeppelin/contracts/GSN/IRelayRecipient.sol";
import "./GSNRecipient.sol";


/**
 * @author Simon Dosch
 * @title GSNable
 * @dev enables GSN capability by implementing GSNRecipient
 * Can be set to accept ALL, NONE or add a MODULE implementing restrictions
 */
contract GSNable is GSNRecipient {
	/**
	 * @dev Emitted when a new GSN mode is set
	 */
	event GSNModeSet(gsnMode);

	/**
	 * @dev Emitted when a new GSN module address is set
	 */
	event GSNModuleSet(IRelayRecipient);

	/**
	 * @dev Add access control by overriding this function!
	 * should return true if sender is authorized
	 */
	function _isGSNController() internal virtual view returns (bool) {
		this;
		return true;
	}

	/**
	 * @dev Address of the GSN MODULE implementing IRelayRecipient
	 */
	IRelayRecipient private _gsnModule = IRelayRecipient(address(0));

	/**
	 * @dev Modifier to make a function callable only when _isGSNController returns true
	 */
	modifier onlyGSNController() {
		require(_isGSNController(), "!GSN_CONTROLLER");
		_;
	}

	/**
	 * @dev doc in IRelayRecipient
	 */
	function acceptRelayedCall(
		address relay,
		address from,
		bytes calldata encodedFunction,
		uint256 transactionFee,
		uint256 gasPrice,
		uint256 gasLimit,
		uint256 nonce,
		bytes calldata approvalData,
		uint256 maxPossibleCharge
	) external override view returns (uint256, bytes memory) {
		if (_gsnMode == gsnMode.ALL) {
			return _approveRelayedCall();
		} else if (_gsnMode == gsnMode.MODULE) {
			return
				_gsnModule.acceptRelayedCall(
					relay,
					from,
					encodedFunction,
					transactionFee,
					gasPrice,
					gasLimit,
					nonce,
					approvalData,
					maxPossibleCharge
				);
		} else {
			return _rejectRelayedCall(0);
		}
	}

	/**
	 * @dev doc in IRelayRecipient
	 */
	function _preRelayedCall(bytes memory context)
		internal
		override
		returns (bytes32)
	{
		if (_gsnMode == gsnMode.MODULE) {
			return _gsnModule.preRelayedCall(context);
		}
	}

	/**
	 * @dev doc in IRelayRecipient
	 */
	function _postRelayedCall(
		bytes memory context,
		bool success,
		uint256 actualCharge,
		bytes32 preRetVal
	) internal override {
		if (_gsnMode == gsnMode.MODULE) {
			return
				_gsnModule.postRelayedCall(
					context,
					success,
					actualCharge,
					preRetVal
				);
		}
	}

	/**
	 * @dev Sets GSN mode to either ALL, NONE or MODULE
	 * @param mode ALL, NONE or MODULE
	 */
	function setGSNMode(gsnMode mode) public onlyGSNController {
		_gsnMode = gsnMode(mode);
		emit GSNModeSet(mode);
	}

	/**
	 * @dev Gets GSN mode
	 * @return gsnMode ALL, NONE or MODULE
	 */
	function getGSNMode() public view onlyGSNController returns (gsnMode) {
		return _gsnMode;
	}

	/**
	 * @dev Sets Module address for MODULE mode
	 * @param newGSNModule Address of new GSN module
	 */
	function setGSNModule(IRelayRecipient newGSNModule)
		public
		onlyGSNController
	{
		_gsnModule = newGSNModule;
		emit GSNModuleSet(newGSNModule);
	}

	/**
	 * @dev Upgrades the relay hub address
	 * @param newRelayHub Address of new relay hub
	 */
	function upgradeRelayHub(address newRelayHub) public onlyGSNController {
		_upgradeRelayHub(newRelayHub);
	}

	/**
	 * @dev Withdraws GSN deposits for this contract
	 * @param amount Amount to be withdrawn
	 * @param payee Address to sned the funds to
	 */
	function withdrawDeposits(uint256 amount, address payable payee)
		public
		onlyGSNController
	{
		_withdrawDeposits(amount, payee);
	}
}

pragma solidity 0.6.6;


/**
 * @author Simon Dosch
 * @title IAdmin
 * @dev Administrable interface
 */
interface IAdmin {
	/**
	 * @param role Role that is being assigned
	 * @param account The address that is being assigned a role
	 * @dev Assigns a role to an account
	 * only ADMIN
	 */
	function addRole(bytes32 role, address account) external;

	/**
	 * @param roles Roles that are being assigned
	 * @param accounts The addresses that are being assigned a role
	 * @dev Assigns a bulk of roles to accounts
	 * only ADMIN
	 */
	function bulkAddRole(bytes32[] calldata roles, address[] calldata accounts)
		external;

	/**
	 * @param role Role that is being removed
	 * @param account The address that a role is removed from
	 * @dev Removes a role from an account
	 * only ADMIN
	 */
	function removeRole(bytes32 role, address account) external;

	/**
	 * @param role Role that is being renounced by the _msgSender()
	 * @dev Removes a role from the sender's address
	 */
	function renounceRole(bytes32 role) external;

	/**
	 * @dev check if an account has a role
	 * @return bool True if account has role
	 */
	function hasRole(bytes32 role, address account)
		external
		view
		returns (bool);

	/**
	 * @dev Emitted when `account` is granted `role`.
	 *
	 * `sender` is the account that originated the contract call, an admin role
	 * bearer except when using {_setupRole}.
	 */
	event RoleGranted(
		bytes32 indexed role,
		address indexed account,
		address indexed sender
	);

	/**
	 * @dev Emitted when `account` is revoked `role`.
	 *
	 * `sender` is the account that originated the contract call:
	 *   - if using `revokeRole`, it is the admin role bearer
	 *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
	 */
	event RoleRevoked(
		bytes32 indexed role,
		address indexed account,
		address indexed sender
	);

	/**
	 * @dev Emitted whenever an account renounced a role
	 */
	event RoleRenounced(bytes32 indexed role, address indexed account);
}

pragma solidity 0.6.6;

import "../interfaces/IConstraintModule.sol";


/**
 * @author Simon Dosch
 * @title IConstrainable
 * @dev Constrainable interface
 */
interface IConstrainable {
	event ModulesByPartitionSet(
		address indexed caller,
		bytes32 indexed partition,
		IConstraintModule[] newModules
	);

	/**
	 * @dev Returns all modules for requested partition
	 * @param partition Partition to get modules for
	 * @return IConstraintModule[]
	 */
	function getModulesByPartition(bytes32 partition)
		external
		view
		returns (IConstraintModule[] memory);

	/**
	 * @dev Sets all modules for partition
	 * @param partition Partition to set modules for
	 * @param newModules IConstraintModule[] array of new modules for this partition
	 */
	function setModulesByPartition(
		bytes32 partition,
		IConstraintModule[] calldata newModules
	) external;
}

pragma solidity 0.6.6;


/**
 * @author Simon Dosch
 * @title IConstraintModule
 * @dev ConstraintModule's interface
 */
interface IConstraintModule {
	// ConstraintModule should also implement an interface to the token they are referring to
	// to call functions like hasRole() from Administrable

	// string private _module_name;

	/**
	 * @dev Validates live transfer. Can modify state
	 * @param msg_sender Sender of this function call
	 * @param partition Partition the tokens are being transferred from
	 * @param from Token holder.
	 * @param to Token recipient.
	 * @param value Number of tokens to transfer.
	 * @param data Information attached to the transfer.
	 * @param operatorData Information attached to the transfer, by the operator.
	 * @return valid transfer is valid
	 * @return reason Why the transfer failed (intended for require statement)
	 */
	function executeTransfer(
		address msg_sender,
		bytes32 partition,
		address operator,
		address from,
		address to,
		uint256 value,
		bytes calldata data,
		bytes calldata operatorData
	) external returns (bool valid, string memory reason);

	/**
	 * @dev Returns module name
	 * @return bytes32 name of the constraint module
	 */
	function getModuleName() external view returns (bytes32);
}

pragma solidity 0.6.6;


/**
 * @title IERC1400 token standard
 * @dev ERC1400 interface
 */
interface IERC1400 {
	// Document Management
	/**
	 * [ERC1400 INTERFACE (1/9)]
	 * @dev Access a document associated with the token.
	 * @param documentName Short name (represented as a bytes32) associated to the document.
	 * @return Requested document + document hash.
	 */
	function getDocument(bytes32 documentName)
		external
		view
		returns (string memory, bytes32); // 1/9

	/**
	 * [ERC1400 INTERFACE (2/9)]
	 * @dev Associate a document with the token.
	 * @param documentName Short name (represented as a bytes32) associated to the document.
	 * @param uri Document content.
	 * @param documentHash Hash of the document [optional parameter].
	 */
	function setDocument(
		bytes32 documentName,
		string calldata uri,
		bytes32 documentHash
	) external; // 2/9

	/**
	 * @dev Event emitted when a new document is set
	 */
	event Document(bytes32 indexed name, string uri, bytes32 documentHash);

	/**
	 * [ERC1400 INTERFACE (3/9)]
	 * @dev Know if the token can be controlled by operators.
	 * If a token returns 'false' for 'isControllable()'' then it MUST always return 'false' in the future.
	 * @return bool 'true' if the token can still be controlled by operators, 'false' if it can't anymore.
	 */
	function isControllable() external view returns (bool); // 3/9

	/**
	 * [ERC1400 INTERFACE (4/9)]
	 * @dev Know if new tokens can be issued in the future.
	 * @return bool 'true' if tokens can still be issued by the issuer, 'false' if they can't anymore.
	 */
	function isIssuable() external view returns (bool); // 4/9

	/**
	 * [ERC1400 INTERFACE (5/9)]
	 * @dev Issue tokens from a specific partition.
	 * @param partition Name of the partition.
	 * @param tokenHolder Address for which we want to issue tokens.
	 * @param value Number of tokens issued.
	 * @param data Information attached to the issuance, by the issuer.
	 */
	function issueByPartition(
		bytes32 partition,
		address tokenHolder,
		uint256 value,
		bytes calldata data
	) external; // 5/9

	/**
	 * @dev Event emitted when tokens were issued to a partition
	 */
	event IssuedByPartition(
		bytes32 indexed partition,
		address indexed operator,
		address indexed to,
		uint256 value,
		bytes data,
		bytes operatorData
	);

	/**
	 * [ERC1400 INTERFACE (6/9)]
	 * @dev Redeem tokens of a specific partition.
	 * @param partition Name of the partition.
	 * @param value Number of tokens redeemed.
	 * @param data Information attached to the redemption, by the redeemer.
	 */
	function redeemByPartition(
		bytes32 partition,
		uint256 value,
		bytes calldata data
	) external; // 6/9

	/**
	 * [ERC1400 INTERFACE (7/9)]
	 * @dev Redeem tokens of a specific partition.
	 * @param partition Name of the partition.
	 * @param tokenHolder Address for which we want to redeem tokens.
	 * @param value Number of tokens redeemed.
	 * @param data Information attached to the redemption.
	 * @param operatorData Information attached to the redemption, by the operator.
	 */
	function operatorRedeemByPartition(
		bytes32 partition,
		address tokenHolder,
		uint256 value,
		bytes calldata data,
		bytes calldata operatorData
	) external; // 7/9

	/**
	 * @dev Event emitted when tokens are redeemed from a partition
	 */
	event RedeemedByPartition(
		bytes32 indexed partition,
		address indexed operator,
		address indexed from,
		uint256 value,
		bytes data,
		bytes operatorData
	);

	/**
	 * [ERC1400 INTERFACE (8/9)]
	 * function canTransferByPartition
	 * not implemented
	 */

	/**
	 * [ERC1400 INTERFACE (9/9)]
	 * function canOperatorTransferByPartition
	 * not implemented
	 */

	/********************** ERC1400 OPTIONAL FUNCTIONS **************************/

	/**
	 * [NOT MANDATORY FOR ERC1400 STANDARD]
	 * @dev Definitely renounce the possibility to control tokens on behalf of tokenHolders.
	 * Once set to false, '_isControllable' can never be set to 'true' again.
	 */
	function renounceControl() external;

	/**
	 * [NOT MANDATORY FOR ERC1400 STANDARD]
	 * @dev Definitely renounce the possibility to issue new tokens.
	 * Once set to false, '_isIssuable' can never be set to 'true' again.
	 */
	function renounceIssuance() external;
}

pragma solidity 0.6.6;


/**
 * @title IERC1400Capped
 * @dev ERC1400Capped interface
 */
interface IERC1400Capped {
	/**
	 * @dev Returns the cap on the token's total supply.
	 */
	function cap() external view returns (uint256);

	/**
	 * @dev Sets cap to a new value
	 * New value need to be higher than old one
	 * Is only callable by CAP?_EDITOR
	 * @param newCap value of new cap
	 */
	function setCap(uint256 newCap) external;

	/**
	 * @dev Event emitted when a new cap is set
	 */
	event CapSet(uint256 newCap);
}

pragma solidity 0.6.6;


/**
 * @title IERC1400Partition partially fungible token standard
 * @dev ERC1400Partition interface
 */
interface IERC1400Partition {
	/**
	 * @dev ERC20 backwards-compatibility
	 */
	event Transfer(address indexed from, address indexed to, uint256 value);

	/********************** NEW FUNCTIONS **************************/

	/**
	 * @dev Returns the total supply of a given partition
	 * For ERC20 compatibility via proxy
	 * @param partition Requested partition
	 * @return uint256 _totalSupplyByPartition
	 */
	function totalSupplyByPartition(bytes32 partition)
		external
		view
		returns (uint256);

	/********************** ERC1400Partition EXTERNAL FUNCTIONS **************************/

	/**
	 * [ERC1400Partition INTERFACE (1/10)]
	 * @dev Get balance of a tokenholder for a specific partition.
	 * @param partition Name of the partition.
	 * @param tokenHolder Address for which the balance is returned.
	 * @return Amount of token of partition 'partition' held by 'tokenHolder' in the token contract.
	 */
	function balanceOfByPartition(bytes32 partition, address tokenHolder)
		external
		view
		returns (uint256);

	/**
	 * [ERC1400Partition INTERFACE (2/10)]
	 * @dev Get partitions index of a tokenholder.
	 * @param tokenHolder Address for which the partitions index are returned.
	 * @return Array of partitions index of 'tokenHolder'.
	 */
	function partitionsOf(address tokenHolder)
		external
		view
		returns (bytes32[] memory);

	/**
	 * [ERC1400Partition INTERFACE (3/10)]
	 * @dev Transfer tokens from a specific partition.
	 * @param partition Name of the partition.
	 * @param to Token recipient.
	 * @param value Number of tokens to transfer.
	 * @param data Information attached to the transfer, by the token holder.
	 * @return Destination partition.
	 */
	function transferByPartition(
		bytes32 partition,
		address to,
		uint256 value,
		bytes calldata data
	) external returns (bytes32);

	/**
	 * [ERC1400Partition INTERFACE (4/10)]
	 * @dev Transfer tokens from a specific partition through an operator.
	 * @param partition Name of the partition.
	 * @param from Token holder.
	 * @param to Token recipient.
	 * @param value Number of tokens to transfer.
	 * @param data Information attached to the transfer.
	 * @param operatorData Information attached to the transfer, by the operator.
	 * @return Destination partition.
	 */
	function operatorTransferByPartition(
		bytes32 partition,
		address from,
		address to,
		uint256 value,
		bytes calldata data,
		bytes calldata operatorData
	) external returns (bytes32);

	/**
	 * [ERC1400Partition INTERFACE (5/10)]
	 * function getDefaultPartitions
	 * default partition is always equal to _totalPartitions
	 */

	/**
	 * [ERC1400Partition INTERFACE (6/10)]
	 * function setDefaultPartitions
	 * default partition is always equal to _totalPartitions
	 */

	/**
	 * [ERC1400Partition INTERFACE (7/10)]
	 * @dev Get controllers for a given partition.
	 * Function used for ERC1400Raw and ERC20 backwards compatibility.
	 * @param partition Name of the partition.
	 * @return Array of controllers for partition.
	 */
	function controllersByPartition(bytes32 partition)
		external
		view
		returns (address[] memory);

	/**
	 * [ERC1400Partition INTERFACE (8/10)]
	 * @dev Set 'operator' as an operator for 'msg.sender' for a given partition.
	 * @param partition Name of the partition.
	 * @param operator Address to set as an operator for 'msg.sender'.
	 */
	function authorizeOperatorByPartition(bytes32 partition, address operator)
		external;

	/**
	 * [ERC1400Partition INTERFACE (9/10)]
	 * @dev Remove the right of the operator address to be an operator on a given
	 * partition for 'msg.sender' and to transfer and redeem tokens on its behalf.
	 * @param partition Name of the partition.
	 * @param operator Address to rescind as an operator on given partition for 'msg.sender'.
	 */
	function revokeOperatorByPartition(bytes32 partition, address operator)
		external;

	/**
	 * [ERC1400Partition INTERFACE (10/10)]
	 * @dev Indicate whether the operator address is an operator of the tokenHolder
	 * address for the given partition.
	 * @param partition Name of the partition.
	 * @param operator Address which may be an operator of tokenHolder for the given partition.
	 * @param tokenHolder Address of a token holder which may have the operator address as an operator for the given partition.
	 * @return 'true' if 'operator' is an operator of 'tokenHolder' for partition 'partition' and 'false' otherwise.
	 */
	function isOperatorForPartition(
		bytes32 partition,
		address operator,
		address tokenHolder
	) external view returns (bool); // 10/10

	/********************* ERC1400Partition OPTIONAL FUNCTIONS ***************************/

	/**
	 * [NOT MANDATORY FOR ERC1400Partition STANDARD]
	 * @dev Get list of existing partitions.
	 * @return Array of all exisiting partitions.
	 */
	function totalPartitions() external view returns (bytes32[] memory);

	/************** ERC1400Raw BACKWARDS RETROCOMPATIBILITY *************************/

	/**
	 * @dev Transfer the amount of tokens from the address 'msg.sender' to the address 'to'.
	 * @param to Token recipient.
	 * @param value Number of tokens to transfer.
	 * @param data Information attached to the transfer, by the token holder.
	 */
	function transferWithData(
		address to,
		uint256 value,
		bytes calldata data
	) external;

	/**
	 * @dev Transfer the amount of tokens on behalf of the address 'from' to the address 'to'.
	 * @param from Token holder (or 'address(0)' to set from to 'msg.sender').
	 * @param to Token recipient.
	 * @param value Number of tokens to transfer.
	 * @param data Information attached to the transfer, and intended for the token holder ('from').
	 */
	function transferFromWithData(
		address from,
		address to,
		uint256 value,
		bytes calldata data,
		bytes calldata operatorData
	) external;

	/**
	 * @dev Event emitted when tokens are transferred from a partition
	 */
	event TransferByPartition(
		bytes32 indexed fromPartition,
		address operator,
		address indexed from,
		address indexed to,
		uint256 value,
		bytes data,
		bytes operatorData
	);

	/**
	 * @dev Event emitted when tokens are transferred between partitions
	 */
	event ChangedPartition(
		bytes32 indexed fromPartition,
		bytes32 indexed toPartition,
		uint256 value
	);

	/**
	 * @dev Event emitted when an operator is authorized for a partition
	 */
	event AuthorizedOperatorByPartition(
		bytes32 indexed partition,
		address indexed operator,
		address indexed tokenHolder
	);

	/**
	 * @dev Event emitted when an operator authorization is revoked for a partition
	 */
	event RevokedOperatorByPartition(
		bytes32 indexed partition,
		address indexed operator,
		address indexed tokenHolder
	);
}

pragma solidity 0.6.6;


/**
 * @title IERC1400Raw token standard
 * @dev ERC1400Raw interface
 */
interface IERC1400Raw {
	/**
	 * [ERC1400Raw INTERFACE (1/13)]
	 * @dev Get the name of the token, e.g., "MyToken".
	 * @return Name of the token.
	 */
	function name() external view returns (string memory); // 1/13

	/**
	 * [ERC1400Raw INTERFACE (2/13)]
	 * @dev Get the symbol of the token, e.g., "MYT".
	 * @return Symbol of the token.
	 */
	function symbol() external view returns (string memory); // 2/13

	// implemented in ERC20
	// function totalSupply() external view returns (uint256); // 3/13
	// function balanceOf(address owner) external view returns (uint256); // 4/13

	/**
	 * [ERC1400Raw INTERFACE (5/13)]
	 * @dev Get the smallest part of the token that’s not divisible.
	 * @return The smallest non-divisible part of the token.
	 */
	function granularity() external view returns (uint256); // 5/13

	/**
	 * [ERC1400Raw INTERFACE (6/13)]
	 * @dev Get the list of controllers
	 * @return List of addresses of all the controllers.
	 */
	// function controllers() external view returns (address[] memory); // 6/13

	/**
	 * [ERC1400Raw INTERFACE (7/13)]
	 * @dev Set a third party operator address as an operator of 'msg.sender' to transfer
	 * and redeem tokens on its behalf.
	 * @param operator Address to set as an operator for 'msg.sender'.
	 */
	function authorizeOperator(address operator) external; // 7/13

	/**
	 * [ERC1400Raw INTERFACE (8/13)]
	 * @dev Remove the right of the operator address to be an operator for 'msg.sender'
	 * and to transfer and redeem tokens on its behalf.
	 * @param operator Address to rescind as an operator for 'msg.sender'.
	 */
	function revokeOperator(address operator) external; // 8/13

	/**
	 * [ERC1400Raw INTERFACE (9/13)]
	 * @dev Indicate whether the operator address is an operator of the tokenHolder address.
	 * @param operator Address which may be an operator of tokenHolder.
	 * @param tokenHolder Address of a token holder which may have the operator address as an operator.
	 * @return 'true' if operator is an operator of 'tokenHolder' and 'false' otherwise.
	 */
	function isOperator(address operator, address tokenHolder)
		external
		view
		returns (bool); // 9/13

	/**
	 * [ERC1400Raw INTERFACE (10/13)]
	 * function transferWithData
	 * is overridden in ERC1400Partition
	 */

	/**
	 * [ERC1400Raw INTERFACE (11/13)]
	 * function transferFromWithData
	 * is overridden in ERC1400Partition
	 */

	/**
	 * [ERC1400Raw INTERFACE (12/13)]
	 * function redeem
	 * is not needed when using ERC1400Partition
	 */

	/**
	 * [ERC1400Raw INTERFACE (13/13)]
	 * function redeemFrom
	 * is not needed when using ERC1400Partition
	 */

	/**
	 * @dev Event emitted when tokens are transferred with data
	 */
	event TransferWithData(
		address indexed operator,
		address indexed from,
		address indexed to,
		uint256 value,
		bytes data,
		bytes operatorData
	);

	/**
	 * @dev Event emitted when tokens are issued
	 */
	event Issued(
		address indexed operator,
		address indexed to,
		uint256 value,
		bytes data,
		bytes operatorData
	);

	/**
	 * @dev Event emitted when tokens are redeemed
	 */
	event Redeemed(
		address indexed operator,
		address indexed from,
		uint256 value,
		bytes data,
		bytes operatorData
	);

	/**
	 * @dev Event emitted when an operator is authorized
	 */
	event AuthorizedOperator(
		address indexed operator,
		address indexed tokenHolder
	);

	/**
	 * @dev Event emitted when an operator authorization is revoked
	 */
	event RevokedOperator(
		address indexed operator,
		address indexed tokenHolder
	);
}

pragma solidity 0.6.6;


/**
 * @author Simon Dosch
 * @title IOwnable
 * @dev IOwnable interface
 */
interface IOwnable {
	/**
	 * @dev Emitted when owership of the security token is transferred.
	 */
	event OwnershipTransferred(
		address indexed previousOwner,
		address indexed newOwner
	);
}

pragma solidity 0.6.6;


/**
 * @author Simon Dosch
 * @title IPausable
 * @dev IPausable interface
 */
interface IPausable {
	/**
	 * @dev Emitted when the pause is triggered by a pauser (`account`).
	 */
	event Paused(address account);

	/**
	 * @dev Emitted when the pause is lifted by a pauser (`account`).
	 */
	event Unpaused(address account);
}

pragma solidity 0.6.6;

import "../interfaces/IConstraintModule.sol";


contract SecurityTokenStorage {
	// Administrable
	/**
	 * @dev Contains all the roles mapped to wether an account holds it or not
	 */
	mapping(bytes32 => mapping(address => bool)) internal _roles;

	// Constrainable
	/**
	 * @dev Contains active constraint modules for a given partition
	 */
	mapping(bytes32 => IConstraintModule[]) internal _modulesByPartition;

	// ERC1400Raw
	string internal _name;
	string internal _symbol;
	uint256 internal _granularity;
	uint256 internal _totalSupply;

	/**
	 * @dev Indicate whether the token can still be controlled by operators or not anymore.
	 */
	bool internal _isControllable;

	/**
	 * @dev Indicates the paused state
	 */
	bool internal _paused;

	/**
	 * @dev Mapping from tokenHolder to balance.
	 */
	mapping(address => uint256) internal _balances;

	/**
	 * @dev Mapping from (operator, tokenHolder) to authorized status. [TOKEN-HOLDER-SPECIFIC]
	 */
	mapping(address => mapping(address => bool)) internal _authorizedOperator;

	// ERC1400Partition
	/**
	 * @dev Contains complete list of partitions that hold tokens.
	 * Is used for ERC20 transfer
	 */
	bytes32[] internal _totalPartitions;

	/**
	 * @dev Mapping from partition to their index.
	 */
	mapping(bytes32 => uint256) internal _indexOfTotalPartitions;

	/**
	 * @dev Mapping from partition to global balance of corresponding partition.
	 */
	mapping(bytes32 => uint256) internal _totalSupplyByPartition;

	/**
	 * @dev Mapping from tokenHolder to their partitions.
	 */
	mapping(address => bytes32[]) internal _partitionsOf;

	/**
	 * @dev Mapping from (tokenHolder, partition) to their index.
	 */
	mapping(address => mapping(bytes32 => uint256)) internal _indexOfPartitionsOf;

	/**
	 * @dev Mapping from (tokenHolder, partition) to balance of corresponding partition.
	 */
	mapping(address => mapping(bytes32 => uint256)) internal _balanceOfByPartition;

	/**************** Mappings to find partition operators ************************/
	/**
	 * @dev Mapping from (tokenHolder, partition, operator) to 'approved for partition' status. [TOKEN-HOLDER-SPECIFIC]
	 */
	mapping(address => mapping(bytes32 => mapping(address => bool))) internal _authorizedOperatorByPartition;

	/**
	 * @dev Mapping from partition to controllers for the partition. [NOT TOKEN-HOLDER-SPECIFIC]
	 */
	mapping(bytes32 => address[]) internal _controllersByPartition;

	// INFO partition controllers can be set by the admin just like other roles
	// Mapping from (partition, operator) to PartitionController status. [NOT TOKEN-HOLDER-SPECIFIC]
	// mapping(bytes32 => mapping(address => bool)) internal _isControllerByPartition;
	/****************************************************************************/

	// ERC1400ERC20
	/**
	 * @dev Mapping from (tokenHolder, spender) to allowed value.
	 */
	mapping(address => mapping(address => uint256)) internal _allowances;

	// ERC1400
	struct Doc {
		string docURI;
		bytes32 docHash;
	}

	/**
	 * @dev Mapping for token URIs.
	 */
	mapping(bytes32 => Doc) internal _documents;

	/**
	 * @dev Indicate whether the token can still be issued by the issuer or not anymore.
	 */
	bool internal _isIssuable;

	// Capped
	/**
	 * @dev Overall cap of the security token
	 */
	uint256 internal _cap;

	// Ownable
	/**
	 * @dev Owner of the security token
	 */
	address internal _owner;

	// GSN
	/**
	 * @dev Enum describing the possible GSN modes
	 */
	enum gsnMode { ALL, MODULE, NONE }

	/**
	 * @dev Can be set to accept ALL, NONE or MODULE mode
	 * Initialized with ALL
	 */
	gsnMode internal _gsnMode;

	/**
	 * @dev Default RelayHub address, deployed on mainnet and all testnets at the same address
	 */
	address internal _relayHub;

	uint256 internal _RELAYED_CALL_ACCEPTED;
	uint256 internal _RELAYED_CALL_REJECTED;

	/**
	 * @dev How much gas is forwarded to postRelayedCall
	 */
	uint256 internal _POST_RELAYED_CALL_MAX_GAS;

	// ReentrancyGuard
	bool internal _notEntered;
}

pragma solidity 0.6.6;

import "../interfaces/IAdmin.sol";
import "../gsn/GSNable.sol";


/**
 * @author Simon Dosch
 * @title Administrable
 * @dev Manages roles for all inheriting contracts
 */
contract Administrable is IAdmin, GSNable {
	/**
     * @dev list of standard roles
     * roles can be added (i.e. for constraint modules)
     *
     * --main roles--
     * ADMIN   (can add and remove roles)
     * CONTROLLER (ERC1400, can force-transfer tokens if contract _isControllable)
     * ISSUER (ISSUER)
     * REDEEMER (BURNER, can redeem tokens, their own OR others IF _isOperatorForPartition())
     * MODULE_EDITOR (can edit constraint modules),
     *
     * --additional roles--
     * DOCUMENT_EDITOR
     * CAP_EDITOR

     * --constraint module roles--
     * PAUSER
     * WHITELIST_EDITOR
     * TIME_LOCK_EDITOR
     * SPENDING_LIMITS_EDITOR
     * VESTING_PERIOD_EDITOR
     * GSN_CONTROLLER
     * DEFAULT_PARTITIONS_EDITOR
	 *
	 * ...
     */

	// EVENTS in IAdmin.sol

	/**
	 * @dev Modifier to make a function callable only when the caller is a specific role.
	 */
	modifier onlyRole(bytes32 role) {
		require(hasRole(role, _msgSender()), "unauthorized");
		_;
	}

	/**
	 * @param role Role that is being assigned
	 * @param account The address that is being assigned a role
	 * @dev Assigns a role to an account
	 * only ADMIN
	 */
	function addRole(bytes32 role, address account)
		public
		override
		onlyRole(bytes32("ADMIN"))
	{
		_add(role, account);
	}

	/**
	 * @param roles Roles that are being assigned
	 * @param accounts The addresses that are being assigned a role
	 * @dev Assigns a bulk of roles to accounts
	 * only ADMIN
	 */
	function bulkAddRole(bytes32[] memory roles, address[] memory accounts)
		public
		override
		onlyRole(bytes32("ADMIN"))
	{
		require(roles.length <= 100, "too many roles");
		require(roles.length == accounts.length, "length");
		for (uint256 i = 0; i < roles.length; i++) {
			_add(roles[i], accounts[i]);
		}
	}

	/**
	 * @param role Role that is being removed
	 * @param account The address that a role is removed from
	 * @dev Removes a role from an account
	 * only ADMIN
	 */
	function removeRole(bytes32 role, address account)
		public
		override
		onlyRole(bytes32("ADMIN"))
	{
		_remove(role, account);
	}

	/**
	 * @param role Role that is being renounced by the _msgSender()
	 * @dev Removes a role from the sender's address
	 * ATTENTION: it is possible to remove the last ADMINN role by renouncing it!
	 */
	function renounceRole(bytes32 role) public override {
		_remove(role, _msgSender());

		emit RoleRenounced(role, _msgSender());
	}

	/**
	 * @dev check if an account has a role
	 * @return bool True if account has role
	 */
	function hasRole(bytes32 role, address account)
		public
		override
		view
		returns (bool)
	{
		return _roles[role][account];
	}

	/******* INTERNAL FUNCTIONS *******/

	/**
	 * @dev give an account access to a role
	 */
	function _add(bytes32 role, address account) internal {
		require(!hasRole(role, account), "already has role");

		_roles[role][account] = true;

		emit RoleGranted(role, account, _msgSender());
	}

	/**
	 * @dev remove an account's access to a role
	 * cannot remove own ADMIN role
	 * address must have role
	 */
	function _remove(bytes32 role, address account) internal {
		require(hasRole(role, account), "does not have role");

		_roles[role][account] = false;

		emit RoleRevoked(role, account, _msgSender());
	}
}

pragma solidity 0.6.6;

import "./Administrable.sol";
import "../interfaces/IConstraintModule.sol";
import "../interfaces/IConstrainable.sol";


/**
 * @author Simon Dosch
 * @title Constrainable
 * @dev Adds transfer constraints in the form of updatable constraint modules
 */
contract Constrainable is IConstrainable, Administrable {
	/**
	 * @dev Validates live transfer. Can modify state
	 * @param msg_sender Sender of this function call
	 * @param partition Partition the tokens are being transferred from
	 * @param from Token holder.
	 * @param to Token recipient.
	 * @param value Number of tokens to transfer.
	 * @param data Information attached to the transfer.
	 * @param operatorData Information attached to the transfer, by the operator
	 */
	function _executeTransfer(
		address msg_sender,
		bytes32 partition,
		address operator,
		address from,
		address to,
		uint256 value,
		bytes memory data,
		bytes memory operatorData
	) internal {
		for (uint256 i = 0; i < _modulesByPartition[partition].length; i++) {
			(
				bool valid,
				string memory reason
			) = _modulesByPartition[partition][i].executeTransfer(
				msg_sender,
				partition,
				operator,
				from,
				to,
				value,
				data,
				operatorData
			);

			require(valid, reason);
		}
	}

	/**
	 * @dev Returns all modules for requested partition
	 * @param partition Partition to get modules for
	 * @return IConstraintModule[]
	 */
	function getModulesByPartition(bytes32 partition)
		external
		override
		view
		returns (IConstraintModule[] memory)
	{
		return _modulesByPartition[partition];
	}

	/**
	 * @dev Sets all modules for partition
	 * @param partition Partition to set modules for
	 * @param newModules IConstraintModule[] array of new modules for this partition
	 */
	function setModulesByPartition(
		bytes32 partition,
		IConstraintModule[] calldata newModules
	) external override {
		require(
			hasRole(bytes32("MODULE_EDITOR"), _msgSender()),
			"!MODULE_EDITOR"
		);
		_modulesByPartition[partition] = newModules;
		emit ModulesByPartitionSet(_msgSender(), partition, newModules);
	}
}

pragma solidity 0.6.6;

import "./Ownable.sol";
import "../interfaces/IERC1400Capped.sol";


/**
 * @author Simon Dosch
 * @title ERC1400Capped
 * @dev Regulating the cap of the security token
 */
contract ERC1400Capped is IERC1400Capped, Ownable {
	/**
	 * @dev Returns the cap on the token's total supply.
	 */
	function cap() public override view returns (uint256) {
		return _cap;
	}

	/**
	 * @dev Sets cap to a new value
	 * New value need to be higher than old one
	 * Is only callable by CAP?_EDITOR
	 * @param newCap value of new cap
	 */
	function setCap(uint256 newCap) public override {
		require(hasRole(bytes32("CAP_EDITOR"), _msgSender()), "!CAP_EDITOR");
		require((newCap > _cap), "new cap needs to be higher");

		// set new cap
		_cap = newCap;
		emit CapSet(newCap);
	}
}

pragma solidity 0.6.6;

import "../../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./ERC1400Partition.sol";
import "../interfaces/IERC1400Raw.sol";


/**
 * @author Simon Dosch
 * @title ERC1400ERC20
 * @dev Expands ERC1400s function by those of the ERC20 standard
 */
contract ERC1400ERC20 is ERC1400Partition, IERC20 {
	/**
	 * @dev Returns the ERC20 decimal property as 0
	 * @return uint8 Always returns decimals as 0
	 */
	function decimals() external pure returns (uint8) {
		return uint8(0);
	}

	/**
	 * @dev Returns the amount of tokens in existence.
	 */
	function totalSupply() public override view returns (uint256) {
		return _totalSupply;
	}

	/**
	 * @dev Returns the amount of tokens owned by `account`.
	 */
	function balanceOf(address who) public override view returns (uint256) {
		return _balances[who];
	}

	/**
	 * @dev Moves `amount` tokens from the caller's account to `recipient`.
	 *
	 * Returns a boolean value indicating whether the operation succeeded.
	 *
	 * Emits a {Transfer} event.
	 */
	function transfer(address to, uint256 value)
		external
		override
		returns (bool)
	{
		_transferFromTotalPartitions(
			_msgSender(),
			_msgSender(),
			to,
			value,
			"",
			""
		);
		// emitted in _transferByPartition
		// emit Transfer(_msgSender(), to, value);		return true;
	}

	/**
	 * @dev Returns the remaining number of tokens that `spender` will be
	 * allowed to spend on behalf of `owner` through {transferFrom}. This is
	 * zero by default.
	 *
	 * This value changes when {approve} or {transferFrom} are called.
	 */
	function allowance(address owner, address spender)
		external
		override
		view
		returns (uint256)
	{
		return _allowances[owner][spender];
	}

	/**
	 * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
	 *
	 * Returns a boolean value indicating whether the operation succeeded.
	 *
	 * Emits an {Approval} event.
	 */
	function approve(address spender, uint256 value)
		external
		override
		returns (bool)
	{
		// Transfer Blocked - Sender not eligible
		require(spender != address(0), "zero address");

		// mitigate https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
		_allowances[_msgSender()][spender] = 0;

		_allowances[_msgSender()][spender] = value;

		emit Approval(_msgSender(), spender, value);
		return true;
	}

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
		address from,
		address to,
		uint256 value
	) external override returns (bool) {
		// check if is operator by partition or has enough allowance here
		require(value <= _allowances[from][_msgSender()], "allowance too low");
		// Transfer Blocked - Identity restriction

		_allowances[from][_msgSender()] = _allowances[from][_msgSender()].sub(
			value
		);

		// transfer by partition
		_transferFromTotalPartitions(from, from, to, value, "", "");

		// emitted in _transferByPartition
		// emit Transfer(_msgSender(), to, value);
		return true;
	}
}

pragma solidity 0.6.6;

import "./ERC1400Raw.sol";
import "../interfaces/IERC1400Partition.sol";


/**
 * @author Simon Dosch
 * @title ERC1400Partition
 * @dev ERC1400Partition logic
 * inspired by and modeled after https://github.com/ConsenSys/UniversalToken
 */
contract ERC1400Partition is IERC1400Partition, ERC1400Raw {
	/**
	 * @dev Returns the total supply of a given partition
	 * For ERC20 compatibility via proxy
	 * @param partition Requested partition
	 * @return uint256 _totalSupplyByPartition
	 */
	function totalSupplyByPartition(bytes32 partition)
		public
		override
		view
		returns (uint256)
	{
		return _totalSupplyByPartition[partition];
	}

	/********************** ERC1400Partition EXTERNAL FUNCTIONS **************************/

	/**
	 * [ERC1400Partition INTERFACE (1/10)]
	 * @dev Get balance of a tokenholder for a specific partition.
	 * @param partition Name of the partition.
	 * @param tokenHolder Address for which the balance is returned.
	 * @return Amount of token of partition 'partition' held by 'tokenHolder' in the token contract.
	 */
	function balanceOfByPartition(bytes32 partition, address tokenHolder)
		external
		override
		view
		returns (uint256)
	{
		return _balanceOfByPartition[tokenHolder][partition];
	}

	/**
	 * [ERC1400Partition INTERFACE (2/10)]
	 * @dev Get partitions index of a tokenholder.
	 * @param tokenHolder Address for which the partitions index are returned.
	 * @return Array of partitions index of 'tokenHolder'.
	 */
	function partitionsOf(address tokenHolder)
		external
		override
		view
		returns (bytes32[] memory)
	{
		return _partitionsOf[tokenHolder];
	}

	/**
	 * [ERC1400Partition INTERFACE (3/10)]
	 * @dev Transfer tokens from a specific partition.
	 * @param partition Name of the partition.
	 * @param to Token recipient.
	 * @param value Number of tokens to transfer.
	 * @param data Information attached to the transfer, by the token holder.
	 * @return Destination partition.
	 */
	function transferByPartition(
		bytes32 partition,
		address to,
		uint256 value,
		bytes calldata data
	) external override returns (bytes32) {
		return
			_transferByPartition(
				partition,
				_msgSender(),
				_msgSender(),
				to,
				value,
				data,
				""
			);
	}

	/**
	 * [ERC1400Partition INTERFACE (4/10)]
	 * @dev Transfer tokens from a specific partition through an operator.
	 * @param partition Name of the partition.
	 * @param from Token holder.
	 * @param to Token recipient.
	 * @param value Number of tokens to transfer.
	 * @param data Information attached to the transfer.
	 * @param operatorData Information attached to the transfer, by the operator.
	 * @return Destination partition.
	 */
	function operatorTransferByPartition(
		bytes32 partition,
		address from,
		address to,
		uint256 value,
		bytes calldata data,
		bytes calldata operatorData
	) external override returns (bytes32) {
		require(
			_isOperatorForPartition(partition, _msgSender(), from),
			"!CONTROLLER or !operator"
		);
		// Transfer Blocked - Identity restriction

		return
			_transferByPartition(
				partition,
				_msgSender(),
				from,
				to,
				value,
				data,
				operatorData
			);
	}

	/**
	 * [ERC1400Partition INTERFACE (5/10)]
	 * function getDefaultPartitions
	 * default partition is always equal to _totalPartitions
	 */

	/**
	 * [ERC1400Partition INTERFACE (6/10)]
	 * function setDefaultPartitions
	 * default partition is always equal to _totalPartitions
	 */

	/**
	 * [ERC1400Partition INTERFACE (7/10)]
	 * @dev Get controllers for a given partition.
	 * Function used for ERC1400Raw and ERC20 backwards compatibility.
	 * @param partition Name of the partition.
	 * @return Array of controllers for partition.
	 */
	function controllersByPartition(bytes32 partition)
		external
		override
		view
		returns (address[] memory)
	{
		return _controllersByPartition[partition];
	}

	/**
	 * [ERC1400Partition INTERFACE (8/10)]
	 * @dev Set 'operator' as an operator for 'msg.sender' for a given partition.
	 * @param partition Name of the partition.
	 * @param operator Address to set as an operator for 'msg.sender'.
	 */
	function authorizeOperatorByPartition(bytes32 partition, address operator)
		external
		override
	{
		_authorizedOperatorByPartition[_msgSender()][partition][operator] = true;
		emit AuthorizedOperatorByPartition(partition, operator, _msgSender());
	}

	/**
	 * [ERC1400Partition INTERFACE (9/10)]
	 * @dev Remove the right of the operator address to be an operator on a given
	 * partition for 'msg.sender' and to transfer and redeem tokens on its behalf.
	 * @param partition Name of the partition.
	 * @param operator Address to rescind as an operator on given partition for 'msg.sender'.
	 */
	function revokeOperatorByPartition(bytes32 partition, address operator)
		external
		override
	{
		_authorizedOperatorByPartition[_msgSender()][partition][operator] = false;
		emit RevokedOperatorByPartition(partition, operator, _msgSender());
	}

	/**
	 * [ERC1400Partition INTERFACE (10/10)]
	 * @dev Indicate whether the operator address is an operator of the tokenHolder
	 * address for the given partition.
	 * @param partition Name of the partition.
	 * @param operator Address which may be an operator of tokenHolder for the given partition.
	 * @param tokenHolder Address of a token holder which may have the operator address as an operator for the given partition.
	 * @return 'true' if 'operator' is an operator of 'tokenHolder' for partition 'partition' and 'false' otherwise.
	 */
	function isOperatorForPartition(
		bytes32 partition,
		address operator,
		address tokenHolder
	) external override view returns (bool) {
		return _isOperatorForPartition(partition, operator, tokenHolder);
	}

	/********************** ERC1400Partition INTERNAL FUNCTIONS **************************/

	/**
	 * [INTERNAL]
	 * @dev Indicate whether the operator address is an operator of the tokenHolder
	 * address for the given partition.
	 * @param partition Name of the partition.
	 * @param operator Address which may be an operator of tokenHolder for the given partition.
	 * @param tokenHolder Address of a token holder which may have the operator address as an operator for the given partition.
	 * @return 'true' if 'operator' is an operator of 'tokenHolder' for partition 'partition' and 'false' otherwise.
	 */
	function _isOperatorForPartition(
		bytes32 partition,
		address operator,
		address tokenHolder
	) internal view returns (bool) {
		return (_authorizedOperatorByPartition[tokenHolder][partition][operator] ||
			(_isControllable && hasRole(bytes32("CONTROLLER"), operator)));
	}

	/**
	 * [INTERNAL]
	 * @dev Transfer tokens from a specific partition.
	 * @param fromPartition Partition of the tokens to transfer.
	 * @param operator The address performing the transfer.
	 * @param from Token holder.
	 * @param to Token recipient.
	 * @param value Number of tokens to transfer.
	 * @param data Information attached to the transfer. [CAN CONTAIN THE DESTINATION PARTITION]
	 * @param operatorData Information attached to the transfer, by the operator (if any).
	 * @return Destination partition.
	 */
	function _transferByPartition(
		bytes32 fromPartition,
		address operator,
		address from,
		address to,
		uint256 value,
		bytes memory data,
		bytes memory operatorData
	) internal returns (bytes32) {
		require(
			_balanceOfByPartition[from][fromPartition] >= value,
			"insufficient funds"
		);
		// Transfer Blocked - Sender balance insufficient

		// The RIVER Principle
		// all transaction go to base partition by default
		// so over time, tokens converge towards the base!
		bytes32 toPartition = bytes32(0);

		if (operatorData.length != 0 && data.length >= 64) {
			toPartition = _getDestinationPartition(fromPartition, data);
		}

		_removeTokenFromPartition(from, fromPartition, value);
		_transferWithData(
			fromPartition,
			operator,
			from,
			to,
			value,
			data,
			operatorData
		);
		_addTokenToPartition(to, toPartition, value);

		emit TransferByPartition(
			fromPartition,
			operator,
			from,
			to,
			value,
			data,
			operatorData
		);

		// purely for better visibility on etherscan
		emit Transfer(from, to, value);

		if (toPartition != fromPartition) {
			emit ChangedPartition(fromPartition, toPartition, value);
		}

		return toPartition;
	}

	/**
	 * [INTERNAL]
	 * @dev Remove a token from a specific partition.
	 * @param from Token holder.
	 * @param partition Name of the partition.
	 * @param value Number of tokens to transfer.
	 */
	function _removeTokenFromPartition(
		address from,
		bytes32 partition,
		uint256 value
	) internal {
		_balanceOfByPartition[from][partition] = _balanceOfByPartition[from][partition]
			.sub(value);
		_totalSupplyByPartition[partition] = _totalSupplyByPartition[partition]
			.sub(value);

		// If the total supply is zero, finds and deletes the partition.
		if (_totalSupplyByPartition[partition] == 0) {
			uint256 index1 = _indexOfTotalPartitions[partition];
			require(index1 > 0, "last partition");
			// Transfer Blocked - Token restriction

			// move the last item into the index being vacated
			bytes32 lastValue = _totalPartitions[_totalPartitions.length - 1];
			_totalPartitions[index1 - 1] = lastValue;
			// adjust for 1-based indexing
			_indexOfTotalPartitions[lastValue] = index1;

			_totalPartitions.pop();
			_indexOfTotalPartitions[partition] = 0;
		}

		// If the balance of the TokenHolder's partition is zero, finds and deletes the partition.
		if (_balanceOfByPartition[from][partition] == 0) {
			uint256 index2 = _indexOfPartitionsOf[from][partition];
			require(index2 > 0, "last partition");
			// Transfer Blocked - Token restriction

			// move the last item into the index being vacated
			bytes32 lastValue = _partitionsOf[from][_partitionsOf[from].length -
				1];
			_partitionsOf[from][index2 - 1] = lastValue;
			// adjust for 1-based indexing
			_indexOfPartitionsOf[from][lastValue] = index2;

			_partitionsOf[from].pop();
			_indexOfPartitionsOf[from][partition] = 0;
		}
	}

	/**
	 * [INTERNAL]
	 * @dev Add a token to a specific partition.
	 * @param to Token recipient.
	 * @param partition Name of the partition.
	 * @param value Number of tokens to transfer.
	 */
	function _addTokenToPartition(
		address to,
		bytes32 partition,
		uint256 value
	) internal {
		if (value != 0) {
			if (_indexOfPartitionsOf[to][partition] == 0) {
				_partitionsOf[to].push(partition);
				_indexOfPartitionsOf[to][partition] = _partitionsOf[to].length;
			}
			_balanceOfByPartition[to][partition] = _balanceOfByPartition[to][partition]
				.add(value);

			if (_indexOfTotalPartitions[partition] == 0) {
				_totalPartitions.push(partition);
				_indexOfTotalPartitions[partition] = _totalPartitions.length;
			}
			_totalSupplyByPartition[partition] = _totalSupplyByPartition[partition]
				.add(value);
		}
	}

	/**
	 * [INTERNAL]
	 * @dev Retrieve the destination partition from the 'data' field.
	 * By convention, a partition change is requested ONLY when 'data' starts
	 * with the flag: 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
	 * When the flag is detected, the destination tranche is extracted from the
	 * 32 bytes following the flag.
	 * @param fromPartition Partition of the tokens to transfer.
	 * @param data Information attached to the transfer. [CAN CONTAIN THE DESTINATION PARTITION]
	 * @return toPartition Destination partition.
	 */
	function _getDestinationPartition(bytes32 fromPartition, bytes memory data)
		internal
		pure
		returns (bytes32 toPartition)
	{
		/* prettier-ignore */
		bytes32 changePartitionFlag = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

		bytes32 flag;
		assembly {
			flag := mload(add(data, 32))
		}
		if (flag == changePartitionFlag) {
			assembly {
				toPartition := mload(add(data, 64))
			}
		} else {
			toPartition = fromPartition;
		}
	}

	/********************* ERC1400Partition OPTIONAL FUNCTIONS ***************************/

	/**
	 * [NOT MANDATORY FOR ERC1400Partition STANDARD]
	 * @dev Get list of existing partitions.
	 * @return Array of all exisiting partitions.
	 */
	function totalPartitions()
		external
		override
		view
		returns (bytes32[] memory)
	{
		return _totalPartitions;
	}

	/************** ERC1400Raw BACKWARDS RETROCOMPATIBILITY *************************/

	/**
	 * @dev Transfer the amount of tokens from the address 'msg.sender' to the address 'to'.
	 * @param to Token recipient.
	 * @param value Number of tokens to transfer.
	 * @param data Information attached to the transfer, by the token holder.
	 */
	function transferWithData(
		address to,
		uint256 value,
		bytes calldata data
	) external override {
		_transferFromTotalPartitions(
			_msgSender(),
			_msgSender(),
			to,
			value,
			data,
			""
		);
	}

	/**
	 * @dev Transfer the amount of tokens on behalf of the address 'from' to the address 'to'.
	 * @param from Token holder (or 'address(0)' to set from to 'msg.sender').
	 * @param to Token recipient.
	 * @param value Number of tokens to transfer.
	 * @param data Information attached to the transfer, and intended for the token holder ('from').
	 */
	function transferFromWithData(
		address from,
		address to,
		uint256 value,
		bytes calldata data,
		bytes calldata operatorData
	) external override {
		require(_isOperator(_msgSender(), from), "!operator");

		_transferFromTotalPartitions(
			_msgSender(),
			from,
			to,
			value,
			data,
			operatorData
		);
	}

	/**
	 * [NOT MANDATORY FOR ERC1400Partition STANDARD]
	 * @dev Transfer tokens from all partitions.
	 * @param operator The address performing the transfer.
	 * @param from Token holder.
	 * @param to Token recipient.
	 * @param value Number of tokens to transfer.
	 * @param data Information attached to the transfer, and intended for the token holder ('from') [CAN CONTAIN THE DESTINATION PARTITION].
	 * @param operatorData Information attached to the transfer by the operator (if any).
	 */
	function _transferFromTotalPartitions(
		address operator,
		address from,
		address to,
		uint256 value,
		bytes memory data,
		bytes memory operatorData
	) internal {
		require(_totalPartitions.length != 0, "no partitions"); // Transfer Blocked - Token restriction
		require(_totalPartitions.length <= 100, "too many partitions");

		uint256 _remainingValue = value;
		uint256 _localBalance;

		for (uint256 i = 0; i < _totalPartitions.length; i++) {
			_localBalance = _balanceOfByPartition[from][_totalPartitions[i]];
			if (_remainingValue <= _localBalance) {
				_transferByPartition(
					_totalPartitions[i],
					operator,
					from,
					to,
					_remainingValue,
					data,
					operatorData
				);
				_remainingValue = 0;
				break;
			} else if (_localBalance != 0) {
				_transferByPartition(
					_totalPartitions[i],
					operator,
					from,
					to,
					_localBalance,
					data,
					operatorData
				);
				_remainingValue = _remainingValue - _localBalance;
			}
		}

		require(_remainingValue == 0, "insufficient balance"); // Transfer Blocked - Token restriction
	}
}

pragma solidity 0.6.6;

import "../../node_modules/@openzeppelin/contracts/math/SafeMath.sol";

import "../erc1820/ERC1820Client.sol";
import "../utils/ReentrancyGuard.sol";
import "../interfaces/IERC1400Raw.sol";


/**
 * @author Simon Dosch
 * @title ERC1400Raw
 * @dev ERC1400Raw logic
 * inspired by and modeled after https://github.com/ConsenSys/UniversalToken
 */
contract ERC1400Raw is IERC1400Raw, ERC1820Client, ReentrancyGuard {
	using SafeMath for uint256;

	// INFO
	// moved functionality to admin contract controller role
	// Array of controllers. [GLOBAL - NOT TOKEN-HOLDER-SPECIFIC]
	// address[] internal _controllers;

	// Mapping from operator to controller status. [GLOBAL - NOT TOKEN-HOLDER-SPECIFIC]
	// mapping(address => bool) internal _isController;

	/********************** ERC1400Raw EXTERNAL FUNCTIONS ***************************/

	/**
	 * [ERC1400Raw INTERFACE (1/13)]
	 * @dev Get the name of the token, e.g., "MyToken".
	 * @return Name of the token.
	 */
	function name() external override view returns (string memory) {
		return _name;
	}

	/**
	 * [ERC1400Raw INTERFACE (2/13)]
	 * @dev Get the symbol of the token, e.g., "MYT".
	 * @return Symbol of the token.
	 */
	function symbol() external override view returns (string memory) {
		return _symbol;
	}

	/**
	 * [ERC1400Raw INTERFACE (3/13)]
	 * INFO replaced by ERC20
	 * @dev Get the total number of issued tokens.
	 * @return Total supply of tokens currently in circulation.
	 */
	/* function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    } */

	/**
	 * [ERC1400Raw INTERFACE (4/13)]
	 * INFO replaced by ERC20
	 * @dev Get the balance of the account with address 'tokenHolder'.
	 * @param tokenHolder Address for which the balance is returned.
	 * @return Amount of token held by 'tokenHolder' in the token contract.
	 */
	/* function balanceOf(address tokenHolder) public override view returns (uint256) {
        return _balances[tokenHolder];
    } */

	/**
	 * [ERC1400Raw INTERFACE (5/13)]
	 * @dev Get the smallest part of the token that’s not divisible.
	 * @return The smallest non-divisible part of the token.
	 */
	function granularity() external override view returns (uint256) {
		return _granularity;
	}

	/**
	 * [ERC1400Raw INTERFACE (6/13)]
	 * @dev Always returns an empty array, since controllers are only managed in Administrable
	 * @return c Empty list
	 */
	/* function controllers() external override view returns (address[] memory c) {
		return c;
	} */

	/**
	 * [ERC1400Raw INTERFACE (7/13)]
	 * @dev Set a third party operator address as an operator of 'msg.sender' to transfer
	 * and redeem tokens on its behalf.
	 * @param operator Address to set as an operator for 'msg.sender'.
	 */
	function authorizeOperator(address operator) external override {
		require(operator != _msgSender(), "cannot authorize yourself");
		_authorizedOperator[operator][_msgSender()] = true;
		emit AuthorizedOperator(operator, _msgSender());
	}

	/**
	 * [ERC1400Raw INTERFACE (8/13)]
	 * @dev Remove the right of the operator address to be an operator for 'msg.sender'
	 * and to transfer and redeem tokens on its behalf.
	 * @param operator Address to rescind as an operator for 'msg.sender'.
	 */
	function revokeOperator(address operator) external override {
		require(operator != _msgSender(), "cannot revoke yourself");
		_authorizedOperator[operator][_msgSender()] = false;
		emit RevokedOperator(operator, _msgSender());
	}

	/**
	 * [ERC1400Raw INTERFACE (9/13)]
	 * @dev Indicate whether the operator address is an operator of the tokenHolder address.
	 * @param operator Address which may be an operator of tokenHolder.
	 * @param tokenHolder Address of a token holder which may have the operator address as an operator.
	 * @return 'true' if operator is an operator of 'tokenHolder' and 'false' otherwise.
	 */
	function isOperator(address operator, address tokenHolder)
		external
		override
		view
		returns (bool)
	{
		return _isOperator(operator, tokenHolder);
	}

	/**
	 * [ERC1400Raw INTERFACE (10/13)]
	 * function transferWithData
	 * is overridden in ERC1400Partition
	 */

	/**
	 * [ERC1400Raw INTERFACE (11/13)]
	 * function transferFromWithData
	 * is overridden in ERC1400Partition
	 */

	/**
	 * [ERC1400Raw INTERFACE (12/13)]
	 * function redeem
	 * is not needed when using ERC1400Partition
	 */

	/**
	 * [ERC1400Raw INTERFACE (13/13)]
	 * function redeemFrom
	 * is not needed when using ERC1400Partition
	 */

	/********************** ERC1400Raw INTERNAL FUNCTIONS ***************************/

	/**
	 * [INTERNAL]
	 * @dev Check if 'value' is multiple of the granularity.
	 * @param value The quantity that want's to be checked.
	 * @return 'true' if 'value' is a multiple of the granularity.
	 */
	function _isMultiple(uint256 value) internal view returns (bool) {
		return (value.div(_granularity).mul(_granularity) == value);
	}

	/**
	 * [INTERNAL]
	 * @dev Indicate whether the operator address is an operator of the tokenHolder address.
	 * @param operator Address which may be an operator of 'tokenHolder'.
	 * @param tokenHolder Address of a token holder which may have the 'operator' address as an operator.
	 * @return 'true' if 'operator' is an operator of 'tokenHolder' and 'false' otherwise.
	 */
	function _isOperator(address operator, address tokenHolder)
		internal
		view
		returns (bool)
	{
		return (operator == tokenHolder ||
			_authorizedOperator[operator][tokenHolder] ||
			(_isControllable && hasRole(bytes32("CONTROLLER"), operator)));
	}

	/**
	 * [INTERNAL]
	 * @dev Perform the transfer of tokens.
	 * @param partition Name of the partition (bytes32 to be left empty for ERC1400Raw transfer).
	 * @param operator The address performing the transfer.
	 * @param from Token holder.
	 * @param to Token recipient.
	 * @param value Number of tokens to transfer.
	 * @param data Information attached to the transfer.
	 * @param operatorData Information attached to the transfer by the operator (if any)..
	 */

	function _transferWithData(
		bytes32 partition,
		address operator,
		address from,
		address to,
		uint256 value,
		bytes memory data,
		bytes memory operatorData
	) internal nonReentrant {
		require(_isMultiple(value), "violates granularity");
		// Transfer Blocked - Token granularity
		require(to != address(0), "zero address");
		// Transfer Blocked - Receiver not eligible
		// require(_balances[from] >= value, "insufficient balance"); // already checked in ERC1400Partition
		// Transfer Blocked - Sender balance insufficient

		require(!_paused, "paused");

		// CONTROLLER bypasses constraint modules
		if (
			!(_isControllable && hasRole(bytes32("CONTROLLER"), _msgSender()))
		) {
			_executeTransfer(
				_msgSender(),
				partition,
				operator,
				from,
				to,
				value,
				data,
				operatorData
			);
		}

		// _callSender(partition, operator, from, to, value, data, operatorData);

		_balances[from] = _balances[from].sub(value);
		_balances[to] = _balances[to].add(value);

		// _callRecipient(partition, operator, from, to, value, data, operatorData, preventLocking);

		emit TransferWithData(operator, from, to, value, data, operatorData);
	}

	/**
	 * [INTERNAL]
	 * @dev Perform the token redemption.
	 * @param operator The address performing the redemption.
	 * @param from Token holder whose tokens will be redeemed.
	 * @param value Number of tokens to redeem.
	 * @param data Information attached to the redemption.
	 * @param operatorData Information attached to the redemption, by the operator (if any).
	 */
	function _redeem(
		address operator,
		address from,
		uint256 value,
		bytes memory data,
		bytes memory operatorData
	) internal nonReentrant {
		require(_isMultiple(value), "violates granularity");
		// Transfer Blocked - Token granularity
		require(from != address(0), "zero address");
		// Transfer Blocked - Sender not eligible
		// require(_balances[from] >= value, "insufficient balance");
		// already checked in _redeemByPartition

		// is REDEEMER
		require(hasRole(bytes32("REDEEMER"), _msgSender()), "!REDEEMER");

		// we don't validate when redeeming

		_balances[from] = _balances[from].sub(value);
		_totalSupply = _totalSupply.sub(value);

		emit Redeemed(operator, from, value, data, operatorData);
	}

	/**
	 * [INTERNAL]
	 * @dev Perform the issuance of tokens.
	 * @param operator Address which triggered the issuance.
	 * @param to Token recipient.
	 * @param value Number of tokens issued.
	 * @param data Information attached to the issuance, and intended for the recipient (to).
	 * @param operatorData Information attached to the issuance by the operator (if any).
	 */
	function _issue(
		address operator,
		address to,
		uint256 value,
		bytes memory data,
		bytes memory operatorData
	) internal nonReentrant {
		require(_isMultiple(value), "violates granularity");
		// Transfer Blocked - Token granularity
		require(to != address(0), "zero address");
		// Transfer Blocked - Receiver not eligible

		require(hasRole(bytes32("ISSUER"), _msgSender()), "!ISSUER");

		// we don't validate when minting

		_totalSupply = _totalSupply.add(value);
		_balances[to] = _balances[to].add(value);

		// _callRecipient(partition, operator, address(0), to, value, data, operatorData, true);

		emit Issued(operator, to, value, data, operatorData);
	}
}

pragma solidity 0.6.6;

import "./Pausable.sol";
import "../interfaces/IOwnable.sol";


/**
 * @author Simon Dosch
 * @title Ownable
 * @dev modeled after @openzeppelin/contracts/access/Ownable.sol
 */
contract Ownable is IOwnable, Pausable {
	// EVENTS in IOwnable.sol

	/**
	 * @dev Returns the address of the current owner.
	 */
	function owner() public view returns (address) {
		return _owner;
	}

	/**
	 * @dev Transfers ownership of the contract to a new account (`newOwner`).
	 * Can only be called by the current owner.
	 */
	function transferOwnership(address newOwner) public virtual {
		require(hasRole(bytes32("ADMIN"), _msgSender()), "!ADMIN");
		require(
			newOwner != address(0),
			"Ownable: new owner is the zero address"
		);
		emit OwnershipTransferred(_owner, newOwner);
		_owner = newOwner;
	}
}

pragma solidity 0.6.6;

import "./Constrainable.sol";
import "../interfaces/IPausable.sol";


/**
 * @author Simon Dosch
 * @title Pausable
 * @dev modeled after @openzeppelin/contracts/utils/Pausable.sol
 */
contract Pausable is IPausable, Constrainable {
	// EVENTS in IPausable.sol

	/**
	 * @dev Returns true if the contract is paused, and false otherwise.
	 * @return bool True if the contract is paused
	 */
	function paused() public view returns (bool) {
		return _paused;
	}

	/**
	 * @dev Called by a pauser to pause, triggers stopped state.
	 */
	function pause() public {
		require(!_paused, "paused");
		require(hasRole(bytes32("PAUSER"), _msgSender()), "!PAUSER");
		_paused = true;
		emit Paused(_msgSender());
	}

	/**
	 * @dev Called by a pauser to unpause, returns to normal state.
	 */
	function unpause() public {
		require(_paused, "not paused");
		require(hasRole(bytes32("PAUSER"), _msgSender()), "!PAUSER");
		_paused = false;
		emit Unpaused(_msgSender());
	}
}

pragma solidity 0.6.6;

import "../../node_modules/@openzeppelin/upgrades/contracts/Initializable.sol";

import "./ERC1400ERC20.sol";
import "../interfaces/IERC1400.sol";


/**
 * @author Simon Dosch
 * @title SecurityToken
 * @dev Main contract of the micobo Security Token Contract Suite
 * inspired by and modeled after https://github.com/ConsenSys/UniversalToken
 * implements access control for GSN
 * implements new function bulkIssueByPartition
 * implements IERC1400
 * inherits ERC1400ERC20
 */
contract SecurityToken is ERC1400ERC20, IERC1400, Initializable {
	/**
	 * @dev Returns the version string of the {SecurityToken} for which this recipient implementation was built.
	 */
	function version() public view returns (string memory) {
		this;
		return "1.0.0";
	}

	// INITIALIZATION
	/**
	 * @dev Initialize ERC1400 + register
	 * the contract implementation in ERC1820Registry.
	 * @param name Name of the token.
	 * @param symbol Symbol of the token.
	 * @param granularity Granularity of the token.
	 */
	function initialize(
		string calldata name,
		string calldata symbol,
		uint256 granularity,
		uint256 cap,
		address admin,
		address controller,
		address issuer,
		address redeemer,
		address module_editor
	) external initializer {
		_add(bytes32("ADMIN"), admin);
		_add(bytes32("CONTROLLER"), controller);
		_add(bytes32("ISSUER"), issuer);
		_add(bytes32("REDEEMER"), redeemer);
		_add(bytes32("MODULE_EDITOR"), module_editor);

		_cap = cap;
		emit CapSet(cap);

		setInterfaceImplementation("ERC1400Token", address(this));

		_isIssuable = true;
		_isControllable = true;

		_owner = admin;
		emit OwnershipTransferred(address(0), admin);

		// ERC1400Raw
		_name = name;
		_symbol = symbol;
		_totalSupply = 0;

		// Token granularity can not be lower than 1
		require(granularity >= 1, "granularity too low");
		_granularity = granularity;

		// GSN
		_gsnMode = gsnMode.ALL;

		// Default RelayHub address, deployed on mainnet and all testnets at the same address
		_relayHub = 0xD216153c06E857cD7f72665E0aF1d7D82172F494;

		_RELAYED_CALL_ACCEPTED = 0;
		_RELAYED_CALL_REJECTED = 11;

		// How much gas is forwarded to postRelayedCall
		_POST_RELAYED_CALL_MAX_GAS = 100000;

		// Reentrancy
		_initializeReentrancyGuard();
	}

	// GSN
	/**
	 * @dev Adding access control by overriding this function!
	 * @return true if sender is GSN_CONTROLLER
	 */
	function _isGSNController() internal override view returns (bool) {
		return hasRole(bytes32("GSN_CONTROLLER"), _msgSender());
	}

	// BULK ISSUANCE
	/**
	 * @dev Mints to a number of token holder at the same time
	 * Must be issuable and tokenHolders and values must bne same length
	 * @param partition partition id tokens should be minted for
	 * @param tokenHolders addresses of all token receiver in the same order as "values"
	 * @param values amounts of tokens to be minted in the same order as "tokenHolders"
	 * @param data Additional data for issueByPartition
	 */
	function bulkIssueByPartition(
		bytes32 partition,
		address[] memory tokenHolders,
		uint256[] memory values,
		bytes memory data
	) public {
		require(_isIssuable, "token not issuable");
		require(tokenHolders.length <= 100, "too many tokenHolders");
		require(
			tokenHolders.length == values.length,
			"different array lengths"
		);

		for (uint256 i = 0; i < tokenHolders.length; i++) {
			require(_totalSupply.add(values[i]) <= _cap, "exceeds cap");
			_issueByPartition(
				partition,
				_msgSender(),
				tokenHolders[i],
				values[i],
				data,
				""
			);
		}
	}

	/********************** ERC1400 EXTERNAL FUNCTIONS **************************/

	/**
	 * [ERC1400 INTERFACE (1/9)]
	 * @dev Access a document associated with the token.
	 * @param documentName Short name (represented as a bytes32) associated to the document.
	 * @return Requested document + document hash.
	 */
	function getDocument(bytes32 documentName)
		external
		override
		view
		returns (string memory, bytes32)
	{
		return (
			_documents[documentName].docURI,
			_documents[documentName].docHash
		);
	}

	/**
	 * [ERC1400 INTERFACE (2/9)]
	 * @dev Associate a document with the token.
	 * @param documentName Short name (represented as a bytes32) associated to the document.
	 * @param uri Document content.
	 * @param documentHash Hash of the document [optional parameter].
	 */
	function setDocument(
		bytes32 documentName,
		string calldata uri,
		bytes32 documentHash
	) external override {
		require(
			hasRole(bytes32("DOCUMENT_EDITOR"), _msgSender()),
			"!DOCUMENT_EDITOR"
		);
		_documents[documentName] = Doc({ docURI: uri, docHash: documentHash });
		emit Document(documentName, uri, documentHash);
	}

	/**
	 * [ERC1400 INTERFACE (3/9)]
	 * @dev Know if the token can be controlled by operators.
	 * If a token returns 'false' for 'isControllable()'' then it MUST always return 'false' in the future.
	 * @return bool 'true' if the token can still be controlled by operators, 'false' if it can't anymore.
	 */
	function isControllable() external override view returns (bool) {
		return _isControllable;
	}

	/**
	 * [ERC1400 INTERFACE (4/9)]
	 * @dev Know if new tokens can be issued in the future.
	 * @return bool 'true' if tokens can still be issued by the issuer, 'false' if they can't anymore.
	 */
	function isIssuable() external override view returns (bool) {
		return _isIssuable;
	}

	/**
	 * [ERC1400 INTERFACE (5/9)]
	 * @dev Issue tokens from a specific partition.
	 * @param partition Name of the partition.
	 * @param tokenHolder Address for which we want to issue tokens.
	 * @param value Number of tokens issued.
	 * @param data Information attached to the issuance, by the issuer.
	 */
	function issueByPartition(
		bytes32 partition,
		address tokenHolder,
		uint256 value,
		bytes calldata data // onlyMinter is taken care of in _issue function
	) external override {
		require(_isIssuable, "token not issuable");

		// total cap is always the sum of all partitionCaps, so it can't be violated

		require(_totalSupply.add(value) <= _cap, "exceeds cap");

		_issueByPartition(
			partition,
			_msgSender(),
			tokenHolder,
			value,
			data,
			""
		);
	}

	/**
	 * [ERC1400 INTERFACE (6/9)]
	 * @dev Redeem tokens of a specific partition.
	 * only controllers can redeem
	 * @param partition Name of the partition.
	 * @param value Number of tokens redeemed.
	 * @param data Information attached to the redemption, by the redeemer.
	 */
	function redeemByPartition(
		bytes32 partition,
		uint256 value,
		bytes calldata data
	) external override {
		// only REDEEMER can burn tokens (checked in _redeem())

		_redeemByPartition(
			partition,
			_msgSender(),
			_msgSender(),
			value,
			data,
			""
		);
	}

	/**
	 * [ERC1400 INTERFACE (7/9)]
	 * @dev Redeem tokens of a specific partition.
	 * @param partition Name of the partition.
	 * @param tokenHolder Address for which we want to redeem tokens.
	 * @param value Number of tokens redeemed.
	 * @param data Information attached to the redemption.
	 * @param operatorData Information attached to the redemption, by the operator.
	 */
	function operatorRedeemByPartition(
		bytes32 partition,
		address tokenHolder,
		uint256 value,
		bytes calldata data,
		bytes calldata operatorData
	) external override {
		// only REDEEMER can burn tokens (checked in _redeem())

		require(
			_isOperatorForPartition(partition, _msgSender(), tokenHolder),
			"!CONTROLLER or !operator"
		);
		// Transfer Blocked - Identity restriction

		_redeemByPartition(
			partition,
			_msgSender(),
			tokenHolder,
			value,
			data,
			operatorData
		);
	}

	/**
	 * [ERC1400 INTERFACE (8/9)]
	 * function canTransferByPartition
	 * not implemented
	 */

	/**
	 * [ERC1400 INTERFACE (9/9)]
	 * function canOperatorTransferByPartition
	 * not implemented
	 */

	/********************** ERC1400 INTERNAL FUNCTIONS **************************/

	/**
	 * [INTERNAL]
	 * @dev Issue tokens from a specific partition.
	 * @param toPartition Name of the partition.
	 * @param operator The address performing the issuance.
	 * @param to Token recipient.
	 * @param value Number of tokens to issue.
	 * @param data Information attached to the issuance.
	 * @param operatorData Information attached to the issuance, by the operator (if any).
	 */

	function _issueByPartition(
		bytes32 toPartition,
		address operator,
		address to,
		uint256 value,
		bytes memory data,
		bytes memory operatorData
	) internal {
		_issue(operator, to, value, data, operatorData);
		_addTokenToPartition(to, toPartition, value);

		emit IssuedByPartition(
			toPartition,
			operator,
			to,
			value,
			data,
			operatorData
		);

		// purely for better visibility on etherscan
		emit Transfer(address(0), to, value);
	}

	/**
	 * [INTERNAL]
	 * @dev Redeem tokens of a specific partition.
	 * @param fromPartition Name of the partition.
	 * @param operator The address performing the redemption.
	 * @param from Token holder whose tokens will be redeemed.
	 * @param value Number of tokens to redeem.
	 * @param data Information attached to the redemption.
	 * @param operatorData Information attached to the redemption, by the operator (if any).
	 */

	function _redeemByPartition(
		bytes32 fromPartition,
		address operator,
		address from,
		uint256 value,
		bytes memory data,
		bytes memory operatorData
	) internal {
		require(
			_balanceOfByPartition[from][fromPartition] >= value,
			"insufficient balance"
		);
		// Transfer Blocked - Sender balance insufficient

		_removeTokenFromPartition(from, fromPartition, value);
		_redeem(operator, from, value, data, operatorData);

		emit RedeemedByPartition(
			fromPartition,
			operator,
			from,
			value,
			data,
			operatorData
		);

		// purely for better visibility on etherscan
		emit Transfer(from, address(0), value);
	}

	/********************** ERC1400 OPTIONAL FUNCTIONS **************************/

	/**
	 * [NOT MANDATORY FOR ERC1400 STANDARD]
	 * @dev Definitely renounce the possibility to control tokens on behalf of tokenHolders.
	 * Once set to false, '_isControllable' can never be set to 'true' again.
	 */
	function renounceControl() external override {
		require(hasRole(bytes32("ADMIN"), _msgSender()), "!ADMIN");
		_isControllable = false;
	}

	/**
	 * [NOT MANDATORY FOR ERC1400 STANDARD]
	 * @dev Definitely renounce the possibility to issue new tokens.
	 * Once set to false, '_isIssuable' can never be set to 'true' again.
	 */
	function renounceIssuance() external override {
		require(hasRole(bytes32("ADMIN"), _msgSender()), "!ADMIN");
		_isIssuable = false;
	}
}

pragma solidity 0.6.6;

import "../token/ERC1400Capped.sol";


/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
contract ReentrancyGuard is ERC1400Capped {
	function _initializeReentrancyGuard() internal {
		// Storing an initial non-zero value makes deployment a bit more
		// expensive, but in exchange the refund on every call to nonReentrant
		// will be lower in amount. Since refunds are capped to a percetange of
		// the total transaction's gas, it is best to keep them low in cases
		// like this one, to increase the likelihood of the full refund coming
		// into effect.
		_notEntered = true;
	}

	/**
	 * @dev Prevents a contract from calling itself, directly or indirectly.
	 * Calling a `nonReentrant` function from another `nonReentrant`
	 * function is not supported. It is possible to prevent this from happening
	 * by making the `nonReentrant` function external, and make it call a
	 * `private` function that does the actual work.
	 */
	modifier nonReentrant() {
		// On the first call to nonReentrant, _notEntered will be true
		require(_notEntered, "ReentrancyGuard: reentrant call");

		// Any calls to nonReentrant after this point will fail
		_notEntered = false;

		_;

		// By storing the original value once again, a refund is triggered (see
		// https://eips.ethereum.org/EIPS/eip-2200)
		_notEntered = true;
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Interface for `RelayHub`, the core contract of the GSN. Users should not need to interact with this contract
 * directly.
 *
 * See the https://github.com/OpenZeppelin/openzeppelin-gsn-helpers[OpenZeppelin GSN helpers] for more information on
 * how to deploy an instance of `RelayHub` on your local test network.
 */
interface IRelayHub {
    // Relay management

    /**
     * @dev Adds stake to a relay and sets its `unstakeDelay`. If the relay does not exist, it is created, and the caller
     * of this function becomes its owner. If the relay already exists, only the owner can call this function. A relay
     * cannot be its own owner.
     *
     * All Ether in this function call will be added to the relay's stake.
     * Its unstake delay will be assigned to `unstakeDelay`, but the new value must be greater or equal to the current one.
     *
     * Emits a {Staked} event.
     */
    function stake(address relayaddr, uint256 unstakeDelay) external payable;

    /**
     * @dev Emitted when a relay's stake or unstakeDelay are increased
     */
    event Staked(address indexed relay, uint256 stake, uint256 unstakeDelay);

    /**
     * @dev Registers the caller as a relay.
     * The relay must be staked for, and not be a contract (i.e. this function must be called directly from an EOA).
     *
     * This function can be called multiple times, emitting new {RelayAdded} events. Note that the received
     * `transactionFee` is not enforced by {relayCall}.
     *
     * Emits a {RelayAdded} event.
     */
    function registerRelay(uint256 transactionFee, string calldata url) external;

    /**
     * @dev Emitted when a relay is registered or re-registered. Looking at these events (and filtering out
     * {RelayRemoved} events) lets a client discover the list of available relays.
     */
    event RelayAdded(address indexed relay, address indexed owner, uint256 transactionFee, uint256 stake, uint256 unstakeDelay, string url);

    /**
     * @dev Removes (deregisters) a relay. Unregistered (but staked for) relays can also be removed.
     *
     * Can only be called by the owner of the relay. After the relay's `unstakeDelay` has elapsed, {unstake} will be
     * callable.
     *
     * Emits a {RelayRemoved} event.
     */
    function removeRelayByOwner(address relay) external;

    /**
     * @dev Emitted when a relay is removed (deregistered). `unstakeTime` is the time when unstake will be callable.
     */
    event RelayRemoved(address indexed relay, uint256 unstakeTime);

    /** Deletes the relay from the system, and gives back its stake to the owner.
     *
     * Can only be called by the relay owner, after `unstakeDelay` has elapsed since {removeRelayByOwner} was called.
     *
     * Emits an {Unstaked} event.
     */
    function unstake(address relay) external;

    /**
     * @dev Emitted when a relay is unstaked for, including the returned stake.
     */
    event Unstaked(address indexed relay, uint256 stake);

    // States a relay can be in
    enum RelayState {
        Unknown, // The relay is unknown to the system: it has never been staked for
        Staked, // The relay has been staked for, but it is not yet active
        Registered, // The relay has registered itself, and is active (can relay calls)
        Removed    // The relay has been removed by its owner and can no longer relay calls. It must wait for its unstakeDelay to elapse before it can unstake
    }

    /**
     * @dev Returns a relay's status. Note that relays can be deleted when unstaked or penalized, causing this function
     * to return an empty entry.
     */
    function getRelay(address relay) external view returns (uint256 totalStake, uint256 unstakeDelay, uint256 unstakeTime, address payable owner, RelayState state);

    // Balance management

    /**
     * @dev Deposits Ether for a contract, so that it can receive (and pay for) relayed transactions.
     *
     * Unused balance can only be withdrawn by the contract itself, by calling {withdraw}.
     *
     * Emits a {Deposited} event.
     */
    function depositFor(address target) external payable;

    /**
     * @dev Emitted when {depositFor} is called, including the amount and account that was funded.
     */
    event Deposited(address indexed recipient, address indexed from, uint256 amount);

    /**
     * @dev Returns an account's deposits. These can be either a contract's funds, or a relay owner's revenue.
     */
    function balanceOf(address target) external view returns (uint256);

    /**
     * Withdraws from an account's balance, sending it back to it. Relay owners call this to retrieve their revenue, and
     * contracts can use it to reduce their funding.
     *
     * Emits a {Withdrawn} event.
     */
    function withdraw(uint256 amount, address payable dest) external;

    /**
     * @dev Emitted when an account withdraws funds from `RelayHub`.
     */
    event Withdrawn(address indexed account, address indexed dest, uint256 amount);

    // Relaying

    /**
     * @dev Checks if the `RelayHub` will accept a relayed operation.
     * Multiple things must be true for this to happen:
     *  - all arguments must be signed for by the sender (`from`)
     *  - the sender's nonce must be the current one
     *  - the recipient must accept this transaction (via {acceptRelayedCall})
     *
     * Returns a `PreconditionCheck` value (`OK` when the transaction can be relayed), or a recipient-specific error
     * code if it returns one in {acceptRelayedCall}.
     */
    function canRelay(
        address relay,
        address from,
        address to,
        bytes calldata encodedFunction,
        uint256 transactionFee,
        uint256 gasPrice,
        uint256 gasLimit,
        uint256 nonce,
        bytes calldata signature,
        bytes calldata approvalData
    ) external view returns (uint256 status, bytes memory recipientContext);

    // Preconditions for relaying, checked by canRelay and returned as the corresponding numeric values.
    enum PreconditionCheck {
        OK,                         // All checks passed, the call can be relayed
        WrongSignature,             // The transaction to relay is not signed by requested sender
        WrongNonce,                 // The provided nonce has already been used by the sender
        AcceptRelayedCallReverted,  // The recipient rejected this call via acceptRelayedCall
        InvalidRecipientStatusCode  // The recipient returned an invalid (reserved) status code
    }

    /**
     * @dev Relays a transaction.
     *
     * For this to succeed, multiple conditions must be met:
     *  - {canRelay} must `return PreconditionCheck.OK`
     *  - the sender must be a registered relay
     *  - the transaction's gas price must be larger or equal to the one that was requested by the sender
     *  - the transaction must have enough gas to not run out of gas if all internal transactions (calls to the
     * recipient) use all gas available to them
     *  - the recipient must have enough balance to pay the relay for the worst-case scenario (i.e. when all gas is
     * spent)
     *
     * If all conditions are met, the call will be relayed and the recipient charged. {preRelayedCall}, the encoded
     * function and {postRelayedCall} will be called in that order.
     *
     * Parameters:
     *  - `from`: the client originating the request
     *  - `to`: the target {IRelayRecipient} contract
     *  - `encodedFunction`: the function call to relay, including data
     *  - `transactionFee`: fee (%) the relay takes over actual gas cost
     *  - `gasPrice`: gas price the client is willing to pay
     *  - `gasLimit`: gas to forward when calling the encoded function
     *  - `nonce`: client's nonce
     *  - `signature`: client's signature over all previous params, plus the relay and RelayHub addresses
     *  - `approvalData`: dapp-specific data forwarded to {acceptRelayedCall}. This value is *not* verified by the
     * `RelayHub`, but it still can be used for e.g. a signature.
     *
     * Emits a {TransactionRelayed} event.
     */
    function relayCall(
        address from,
        address to,
        bytes calldata encodedFunction,
        uint256 transactionFee,
        uint256 gasPrice,
        uint256 gasLimit,
        uint256 nonce,
        bytes calldata signature,
        bytes calldata approvalData
    ) external;

    /**
     * @dev Emitted when an attempt to relay a call failed.
     *
     * This can happen due to incorrect {relayCall} arguments, or the recipient not accepting the relayed call. The
     * actual relayed call was not executed, and the recipient not charged.
     *
     * The `reason` parameter contains an error code: values 1-10 correspond to `PreconditionCheck` entries, and values
     * over 10 are custom recipient error codes returned from {acceptRelayedCall}.
     */
    event CanRelayFailed(address indexed relay, address indexed from, address indexed to, bytes4 selector, uint256 reason);

    /**
     * @dev Emitted when a transaction is relayed.
     * Useful when monitoring a relay's operation and relayed calls to a contract
     *
     * Note that the actual encoded function might be reverted: this is indicated in the `status` parameter.
     *
     * `charge` is the Ether value deducted from the recipient's balance, paid to the relay's owner.
     */
    event TransactionRelayed(address indexed relay, address indexed from, address indexed to, bytes4 selector, RelayCallStatus status, uint256 charge);

    // Reason error codes for the TransactionRelayed event
    enum RelayCallStatus {
        OK,                      // The transaction was successfully relayed and execution successful - never included in the event
        RelayedCallFailed,       // The transaction was relayed, but the relayed call failed
        PreRelayedFailed,        // The transaction was not relayed due to preRelatedCall reverting
        PostRelayedFailed,       // The transaction was relayed and reverted due to postRelatedCall reverting
        RecipientBalanceChanged  // The transaction was relayed and reverted due to the recipient's balance changing
    }

    /**
     * @dev Returns how much gas should be forwarded to a call to {relayCall}, in order to relay a transaction that will
     * spend up to `relayedCallStipend` gas.
     */
    function requiredGas(uint256 relayedCallStipend) external view returns (uint256);

    /**
     * @dev Returns the maximum recipient charge, given the amount of gas forwarded, gas price and relay fee.
     */
    function maxPossibleCharge(uint256 relayedCallStipend, uint256 gasPrice, uint256 transactionFee) external view returns (uint256);

     // Relay penalization.
     // Any account can penalize relays, removing them from the system immediately, and rewarding the
    // reporter with half of the relay's stake. The other half is burned so that, even if the relay penalizes itself, it
    // still loses half of its stake.

    /**
     * @dev Penalize a relay that signed two transactions using the same nonce (making only the first one valid) and
     * different data (gas price, gas limit, etc. may be different).
     *
     * The (unsigned) transaction data and signature for both transactions must be provided.
     */
    function penalizeRepeatedNonce(bytes calldata unsignedTx1, bytes calldata signature1, bytes calldata unsignedTx2, bytes calldata signature2) external;

    /**
     * @dev Penalize a relay that sent a transaction that didn't target ``RelayHub``'s {registerRelay} or {relayCall}.
     */
    function penalizeIllegalTransaction(bytes calldata unsignedTx, bytes calldata signature) external;

    /**
     * @dev Emitted when a relay is penalized.
     */
    event Penalized(address indexed relay, address sender, uint256 amount);

    /**
     * @dev Returns an account's nonce in `RelayHub`.
     */
    function getNonce(address from) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Base interface for a contract that will be called via the GSN from {IRelayHub}.
 *
 * TIP: You don't need to write an implementation yourself! Inherit from {GSNRecipient} instead.
 */
interface IRelayRecipient {
    /**
     * @dev Returns the address of the {IRelayHub} instance this recipient interacts with.
     */
    function getHubAddr() external view returns (address);

    /**
     * @dev Called by {IRelayHub} to validate if this recipient accepts being charged for a relayed call. Note that the
     * recipient will be charged regardless of the execution result of the relayed call (i.e. if it reverts or not).
     *
     * The relay request was originated by `from` and will be served by `relay`. `encodedFunction` is the relayed call
     * calldata, so its first four bytes are the function selector. The relayed call will be forwarded `gasLimit` gas,
     * and the transaction executed with a gas price of at least `gasPrice`. ``relay``'s fee is `transactionFee`, and the
     * recipient will be charged at most `maxPossibleCharge` (in wei). `nonce` is the sender's (`from`) nonce for
     * replay attack protection in {IRelayHub}, and `approvalData` is a optional parameter that can be used to hold a signature
     * over all or some of the previous values.
     *
     * Returns a tuple, where the first value is used to indicate approval (0) or rejection (custom non-zero error code,
     * values 1 to 10 are reserved) and the second one is data to be passed to the other {IRelayRecipient} functions.
     *
     * {acceptRelayedCall} is called with 50k gas: if it runs out during execution, the request will be considered
     * rejected. A regular revert will also trigger a rejection.
     */
    function acceptRelayedCall(
        address relay,
        address from,
        bytes calldata encodedFunction,
        uint256 transactionFee,
        uint256 gasPrice,
        uint256 gasLimit,
        uint256 nonce,
        bytes calldata approvalData,
        uint256 maxPossibleCharge
    )
        external
        view
        returns (uint256, bytes memory);

    /**
     * @dev Called by {IRelayHub} on approved relay call requests, before the relayed call is executed. This allows to e.g.
     * pre-charge the sender of the transaction.
     *
     * `context` is the second value returned in the tuple by {acceptRelayedCall}.
     *
     * Returns a value to be passed to {postRelayedCall}.
     *
     * {preRelayedCall} is called with 100k gas: if it runs out during execution or otherwise reverts, the relayed call
     * will not be executed, but the recipient will still be charged for the transaction's cost.
     */
    function preRelayedCall(bytes calldata context) external returns (bytes32);

    /**
     * @dev Called by {IRelayHub} on approved relay call requests, after the relayed call is executed. This allows to e.g.
     * charge the user for the relayed call costs, return any overcharges from {preRelayedCall}, or perform
     * contract-specific bookkeeping.
     *
     * `context` is the second value returned in the tuple by {acceptRelayedCall}. `success` is the execution status of
     * the relayed call. `actualCharge` is an estimate of how much the recipient will be charged for the transaction,
     * not including any gas used by {postRelayedCall} itself. `preRetVal` is {preRelayedCall}'s return value.
     *
     *
     * {postRelayedCall} is called with 100k gas: if it runs out during execution or otherwise reverts, the relayed call
     * and the call to {preRelayedCall} will be reverted retroactively, but the recipient will still be charged for the
     * transaction's cost.
     */
    function postRelayedCall(bytes calldata context, bool success, uint256 actualCharge, bytes32 preRetVal) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
     *
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
     *
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
     *
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity >=0.4.24 <0.7.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

