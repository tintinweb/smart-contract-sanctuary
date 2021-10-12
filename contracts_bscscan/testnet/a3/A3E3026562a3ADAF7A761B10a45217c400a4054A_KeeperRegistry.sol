// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./interfaces/OperatorInterface.sol";
import "./ConfirmedOwnerWithProposal.sol";
import "./AuthorizedReceiver.sol";
import "./vendor/Address.sol";

contract AuthorizedForwarder is ConfirmedOwnerWithProposal, AuthorizedReceiver {
  using Address for address;

  address public immutable getChainlinkToken;

  event OwnershipTransferRequestedWithMessage(address indexed from, address indexed to, bytes message);

  constructor(
    address link,
    address owner,
    address recipient,
    bytes memory message
  ) ConfirmedOwnerWithProposal(owner, recipient) {
    getChainlinkToken = link;
    if (recipient != address(0)) {
      emit OwnershipTransferRequestedWithMessage(owner, recipient, message);
    }
  }

  /**
   * @notice The type and version of this contract
   * @return Type and version string
   */
  function typeAndVersion() external pure virtual returns (string memory) {
    return "AuthorizedForwarder 1.0.0";
  }

  /**
   * @notice Forward a call to another contract
   * @dev Only callable by an authorized sender
   * @param to address
   * @param data to forward
   */
  function forward(address to, bytes calldata data) external validateAuthorizedSender {
    require(to != getChainlinkToken, "Cannot forward to Link token");
    _forward(to, data);
  }

  /**
   * @notice Forward a call to another contract
   * @dev Only callable by the owner
   * @param to address
   * @param data to forward
   */
  function ownerForward(address to, bytes calldata data) external onlyOwner {
    _forward(to, data);
  }

  /**
   * @notice Transfer ownership with instructions for recipient
   * @param to address proposed recipient of ownership
   * @param message instructions for recipient upon accepting ownership
   */
  function transferOwnershipWithMessage(address to, bytes calldata message) external {
    transferOwnership(to);
    emit OwnershipTransferRequestedWithMessage(msg.sender, to, message);
  }

  /**
   * @notice concrete implementation of AuthorizedReceiver
   * @return bool of whether sender is authorized
   */
  function _canSetAuthorizedSenders() internal view override returns (bool) {
    return owner() == msg.sender;
  }

  /**
   * @notice common forwarding functionality and validation
   */
  function _forward(address to, bytes calldata data) private {
    require(to.isContract(), "Must forward to a contract");
    (bool status, ) = to.call(data);
    require(status, "Forwarded call failed");
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./ChainlinkRequestInterface.sol";
import "./OracleInterface.sol";

interface OperatorInterface is ChainlinkRequestInterface, OracleInterface {
  function operatorRequest(
    address sender,
    uint256 payment,
    bytes32 specId,
    bytes4 callbackFunctionId,
    uint256 nonce,
    uint256 dataVersion,
    bytes calldata data
  ) external;

  function fulfillOracleRequest2(
    bytes32 requestId,
    uint256 payment,
    address callbackAddress,
    bytes4 callbackFunctionId,
    uint256 expiration,
    bytes calldata data
  ) external returns (bool);

  function ownerTransferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./interfaces/OwnableInterface.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwnerWithProposal is OwnableInterface {
  address private s_owner;
  address private s_pendingOwner;

  event OwnershipTransferRequested(address indexed from, address indexed to);
  event OwnershipTransferred(address indexed from, address indexed to);

  constructor(address newOwner, address pendingOwner) {
    require(newOwner != address(0), "Cannot set owner to zero");

    s_owner = newOwner;
    if (pendingOwner != address(0)) {
      _transferOwnership(pendingOwner);
    }
  }

  /**
   * @notice Allows an owner to begin transferring ownership to a new address,
   * pending.
   */
  function transferOwnership(address to) public override onlyOwner {
    _transferOwnership(to);
  }

  /**
   * @notice Allows an ownership transfer to be completed by the recipient.
   */
  function acceptOwnership() external override {
    require(msg.sender == s_pendingOwner, "Must be proposed owner");

    address oldOwner = s_owner;
    s_owner = msg.sender;
    s_pendingOwner = address(0);

    emit OwnershipTransferred(oldOwner, msg.sender);
  }

  /**
   * @notice Get the current owner
   */
  function owner() public view override returns (address) {
    return s_owner;
  }

  /**
   * @notice validate, transfer ownership, and emit relevant events
   */
  function _transferOwnership(address to) private {
    require(to != msg.sender, "Cannot transfer to self");

    s_pendingOwner = to;

    emit OwnershipTransferRequested(s_owner, to);
  }

  /**
   * @notice validate access
   */
  function _validateOwnership() internal view {
    require(msg.sender == s_owner, "Only callable by owner");
  }

  /**
   * @notice Reverts if called by anyone other than the contract owner.
   */
  modifier onlyOwner() {
    _validateOwnership();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./interfaces/AuthorizedReceiverInterface.sol";

abstract contract AuthorizedReceiver is AuthorizedReceiverInterface {
  mapping(address => bool) private s_authorizedSenders;
  address[] private s_authorizedSenderList;

  event AuthorizedSendersChanged(address[] senders, address changedBy);

  /**
   * @notice Sets the fulfillment permission for a given node. Use `true` to allow, `false` to disallow.
   * @param senders The addresses of the authorized Chainlink node
   */
  function setAuthorizedSenders(address[] calldata senders) external override validateAuthorizedSenderSetter {
    require(senders.length > 0, "Must have at least 1 authorized sender");
    // Set previous authorized senders to false
    uint256 authorizedSendersLength = s_authorizedSenderList.length;
    for (uint256 i = 0; i < authorizedSendersLength; i++) {
      s_authorizedSenders[s_authorizedSenderList[i]] = false;
    }
    // Set new to true
    for (uint256 i = 0; i < senders.length; i++) {
      s_authorizedSenders[senders[i]] = true;
    }
    // Replace list
    s_authorizedSenderList = senders;
    emit AuthorizedSendersChanged(senders, msg.sender);
  }

  /**
   * @notice Retrieve a list of authorized senders
   * @return array of addresses
   */
  function getAuthorizedSenders() external view override returns (address[] memory) {
    return s_authorizedSenderList;
  }

  /**
   * @notice Use this to check if a node is authorized for fulfilling requests
   * @param sender The address of the Chainlink node
   * @return The authorization status of the node
   */
  function isAuthorizedSender(address sender) public view override returns (bool) {
    return s_authorizedSenders[sender];
  }

  /**
   * @notice customizable guard of who can update the authorized sender list
   * @return bool whether sender can update authorized sender list
   */
  function _canSetAuthorizedSenders() internal virtual returns (bool);

  /**
   * @notice validates the sender is an authorized sender
   */
  function _validateIsAuthorizedSender() internal view {
    require(isAuthorizedSender(msg.sender), "Not authorized sender");
  }

  /**
   * @notice prevents non-authorized addresses from calling this method
   */
  modifier validateAuthorizedSender() {
    _validateIsAuthorizedSender();
    _;
  }

  /**
   * @notice prevents non-authorized addresses from calling this method
   */
  modifier validateAuthorizedSenderSetter() {
    require(_canSetAuthorizedSenders(), "Cannot set authorized senders");
    _;
  }
}

// SPDX-License-Identifier: MIT
// From https://github.com/OpenZeppelin/openzeppelin-contracts v3.4.0(fa64a1ced0b70ab89073d5d0b6e01b0778f7e7d6)

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
  /**
   * @dev Returns true if `account` is a contract.
   *
   * [IMPORTANT]
   * ====
   * It is unsafe to assume that an address for which this function returns
   * false is an externally-owned account (EOA) and not a contract.
   *
   * Among others, `isContract` will return false for the following
   * types of addresses:
   *
   *  - an externally-owned account
   *  - a contract in construction
   *  - an address where a contract will be created
   *  - an address where a contract lived, but was destroyed
   * ====
   */
  function isContract(address account) internal view returns (bool) {
    // This method relies on extcodesize, which returns 0 for contracts in
    // construction, since the code is only stored at the end of the
    // constructor execution.

    uint256 size;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      size := extcodesize(account)
    }
    return size > 0;
  }

  /**
   * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
   * `recipient`, forwarding all available gas and reverting on errors.
   *
   * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
   * of certain opcodes, possibly making contracts go over the 2300 gas limit
   * imposed by `transfer`, making them unable to receive funds via
   * `transfer`. {sendValue} removes this limitation.
   *
   * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
   *
   * IMPORTANT: because control is transferred to `recipient`, care must be
   * taken to not create reentrancy vulnerabilities. Consider using
   * {ReentrancyGuard} or the
   * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
   */
  function sendValue(address payable recipient, uint256 amount) internal {
    require(address(this).balance >= amount, "Address: insufficient balance");

    // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
    (bool success, ) = recipient.call{value: amount}("");
    require(success, "Address: unable to send value, recipient may have reverted");
  }

  /**
   * @dev Performs a Solidity function call using a low level `call`. A
   * plain`call` is an unsafe replacement for a function call: use this
   * function instead.
   *
   * If `target` reverts with a revert reason, it is bubbled up by this
   * function (like regular Solidity function calls).
   *
   * Returns the raw returned data. To convert to the expected return value,
   * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
   *
   * Requirements:
   *
   * - `target` must be a contract.
   * - calling `target` with `data` must not revert.
   *
   * _Available since v3.1._
   */
  function functionCall(address target, bytes memory data) internal returns (bytes memory) {
    return functionCall(target, data, "Address: low-level call failed");
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
   * `errorMessage` as a fallback revert reason when `target` reverts.
   *
   * _Available since v3.1._
   */
  function functionCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
    return functionCallWithValue(target, data, 0, errorMessage);
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
   * but also transferring `value` wei to `target`.
   *
   * Requirements:
   *
   * - the calling contract must have an ETH balance of at least `value`.
   * - the called Solidity function must be `payable`.
   *
   * _Available since v3.1._
   */
  function functionCallWithValue(
    address target,
    bytes memory data,
    uint256 value
  ) internal returns (bytes memory) {
    return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
  }

  /**
   * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
   * with `errorMessage` as a fallback revert reason when `target` reverts.
   *
   * _Available since v3.1._
   */
  function functionCallWithValue(
    address target,
    bytes memory data,
    uint256 value,
    string memory errorMessage
  ) internal returns (bytes memory) {
    require(address(this).balance >= value, "Address: insufficient balance for call");
    require(isContract(target), "Address: call to non-contract");

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory returndata) = target.call{value: value}(data);
    return _verifyCallResult(success, returndata, errorMessage);
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
   * but performing a static call.
   *
   * _Available since v3.3._
   */
  function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
    return functionStaticCall(target, data, "Address: low-level static call failed");
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
   * but performing a static call.
   *
   * _Available since v3.3._
   */
  function functionStaticCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal view returns (bytes memory) {
    require(isContract(target), "Address: static call to non-contract");

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory returndata) = target.staticcall(data);
    return _verifyCallResult(success, returndata, errorMessage);
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
   * but performing a delegate call.
   *
   * _Available since v3.4._
   */
  function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
    return functionDelegateCall(target, data, "Address: low-level delegate call failed");
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
   * but performing a delegate call.
   *
   * _Available since v3.4._
   */
  function functionDelegateCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
    require(isContract(target), "Address: delegate call to non-contract");

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory returndata) = target.delegatecall(data);
    return _verifyCallResult(success, returndata, errorMessage);
  }

  function _verifyCallResult(
    bool success,
    bytes memory returndata,
    string memory errorMessage
  ) private pure returns (bytes memory) {
    if (success) {
      return returndata;
    } else {
      // Look for revert reason and bubble it up if present
      if (returndata.length > 0) {
        // The easiest way to bubble the revert reason is using memory via assembly

        // solhint-disable-next-line no-inline-assembly
        assembly {
          let returndata_size := mload(returndata)
          revert(add(32, returndata), returndata_size)
        }
      } else {
        revert(errorMessage);
      }
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface ChainlinkRequestInterface {
  function oracleRequest(
    address sender,
    uint256 requestPrice,
    bytes32 serviceAgreementID,
    address callbackAddress,
    bytes4 callbackFunctionId,
    uint256 nonce,
    uint256 dataVersion,
    bytes calldata data
  ) external;

  function cancelOracleRequest(
    bytes32 requestId,
    uint256 payment,
    bytes4 callbackFunctionId,
    uint256 expiration
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface OracleInterface {
  function fulfillOracleRequest(
    bytes32 requestId,
    uint256 payment,
    address callbackAddress,
    bytes4 callbackFunctionId,
    uint256 expiration,
    bytes32 data
  ) external returns (bool);

  function withdraw(address recipient, uint256 amount) external;

  function withdrawable() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface OwnableInterface {
  function owner() external returns (address);

  function transferOwnership(address recipient) external;

  function acceptOwnership() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface AuthorizedReceiverInterface {
  function isAuthorizedSender(address sender) external view returns (bool);

  function getAuthorizedSenders() external returns (address[] memory);

  function setAuthorizedSenders(address[] calldata senders) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./Operator.sol";
import "./AuthorizedForwarder.sol";

/**
 * @title Operator Factory
 * @notice Creates Operator contracts for node operators
 */
contract OperatorFactory {
  address public immutable getChainlinkToken;
  mapping(address => bool) private s_created;

  event OperatorCreated(address indexed operator, address indexed owner, address indexed sender);
  event AuthorizedForwarderCreated(address indexed forwarder, address indexed owner, address indexed sender);

  /**
   * @param linkAddress address
   */
  constructor(address linkAddress) {
    getChainlinkToken = linkAddress;
  }

  /**
   * @notice The type and version of this contract
   * @return Type and version string
   */
  function typeAndVersion() external pure virtual returns (string memory) {
    return "OperatorFactory 1.0.0";
  }

  /**
   * @notice creates a new Operator contract with the msg.sender as owner
   */
  function deployNewOperator() external returns (address) {
    Operator operator = new Operator(getChainlinkToken, msg.sender);

    s_created[address(operator)] = true;
    emit OperatorCreated(address(operator), msg.sender, msg.sender);

    return address(operator);
  }

  /**
   * @notice creates a new Operator contract with the msg.sender as owner and a
   * new Operator Forwarder with the Operator as the owner
   */
  function deployNewOperatorAndForwarder() external returns (address, address) {
    Operator operator = new Operator(getChainlinkToken, msg.sender);
    s_created[address(operator)] = true;
    emit OperatorCreated(address(operator), msg.sender, msg.sender);

    bytes memory tmp = new bytes(0);
    AuthorizedForwarder forwarder = new AuthorizedForwarder(getChainlinkToken, address(this), address(operator), tmp);
    s_created[address(forwarder)] = true;
    emit AuthorizedForwarderCreated(address(forwarder), address(this), msg.sender);

    return (address(operator), address(forwarder));
  }

  /**
   * @notice creates a new Forwarder contract with the msg.sender as owner
   */
  function deployNewForwarder() external returns (address) {
    bytes memory tmp = new bytes(0);
    AuthorizedForwarder forwarder = new AuthorizedForwarder(getChainlinkToken, msg.sender, address(0), tmp);

    s_created[address(forwarder)] = true;
    emit AuthorizedForwarderCreated(address(forwarder), msg.sender, msg.sender);

    return address(forwarder);
  }

  /**
   * @notice creates a new Forwarder contract with the msg.sender as owner
   */
  function deployNewForwarderAndTransferOwnership(address to, bytes calldata message) external returns (address) {
    AuthorizedForwarder forwarder = new AuthorizedForwarder(getChainlinkToken, msg.sender, to, message);

    s_created[address(forwarder)] = true;
    emit AuthorizedForwarderCreated(address(forwarder), msg.sender, msg.sender);

    return address(forwarder);
  }

  /**
   * @notice indicates whether this factory deployed an address
   */
  function created(address query) external view returns (bool) {
    return s_created[query];
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./AuthorizedReceiver.sol";
import "./LinkTokenReceiver.sol";
import "./ConfirmedOwner.sol";
import "./interfaces/LinkTokenInterface.sol";
import "./interfaces/OperatorInterface.sol";
import "./interfaces/OwnableInterface.sol";
import "./interfaces/WithdrawalInterface.sol";
import "./vendor/Address.sol";
import "./vendor/SafeMathChainlink.sol";

/**
 * @title The Chainlink Operator contract
 * @notice Node operators can deploy this contract to fulfill requests sent to them
 */
contract Operator is AuthorizedReceiver, ConfirmedOwner, LinkTokenReceiver, OperatorInterface, WithdrawalInterface {
  using Address for address;
  using SafeMathChainlink for uint256;

  struct Commitment {
    bytes31 paramsHash;
    uint8 dataVersion;
  }

  uint256 public constant getExpiryTime = 5 minutes;
  uint256 private constant MAXIMUM_DATA_VERSION = 256;
  uint256 private constant MINIMUM_CONSUMER_GAS_LIMIT = 400000;
  uint256 private constant SELECTOR_LENGTH = 4;
  uint256 private constant EXPECTED_REQUEST_WORDS = 2;
  uint256 private constant MINIMUM_REQUEST_LENGTH = SELECTOR_LENGTH + (32 * EXPECTED_REQUEST_WORDS);
  // We initialize fields to 1 instead of 0 so that the first invocation
  // does not cost more gas.
  uint256 private constant ONE_FOR_CONSISTENT_GAS_COST = 1;
  // oracleRequest is intended for version 1, enabling single word responses
  bytes4 private constant ORACLE_REQUEST_SELECTOR = this.oracleRequest.selector;
  // operatorRequest is intended for version 2, enabling multi-word responses
  bytes4 private constant OPERATOR_REQUEST_SELECTOR = this.operatorRequest.selector;

  LinkTokenInterface internal immutable linkToken;
  mapping(bytes32 => Commitment) private s_commitments;
  mapping(address => bool) private s_owned;
  // Tokens sent for requests that have not been fulfilled yet
  uint256 private s_tokensInEscrow = ONE_FOR_CONSISTENT_GAS_COST;

  event OracleRequest(
    bytes32 indexed specId,
    address requester,
    bytes32 requestId,
    uint256 payment,
    address callbackAddr,
    bytes4 callbackFunctionId,
    uint256 cancelExpiration,
    uint256 dataVersion,
    bytes data
  );

  event CancelOracleRequest(bytes32 indexed requestId);

  event OracleResponse(bytes32 indexed requestId);

  event OwnableContractAccepted(address indexed acceptedContract);

  event TargetsUpdatedAuthorizedSenders(address[] targets, address[] senders, address changedBy);

  /**
   * @notice Deploy with the address of the LINK token
   * @dev Sets the LinkToken address for the imported LinkTokenInterface
   * @param link The address of the LINK token
   * @param owner The address of the owner
   */
  constructor(address link, address owner) ConfirmedOwner(owner) {
    linkToken = LinkTokenInterface(link); // external but already deployed and unalterable
  }

  /**
   * @notice The type and version of this contract
   * @return Type and version string
   */
  function typeAndVersion() external pure virtual returns (string memory) {
    return "Operator 1.0.0";
  }

  /**
   * @notice Creates the Chainlink request. This is a backwards compatible API
   * with the Oracle.sol contract, but the behavior changes because
   * callbackAddress is assumed to be the same as the request sender.
   * @param callbackAddress The consumer of the request
   * @param payment The amount of payment given (specified in wei)
   * @param specId The Job Specification ID
   * @param callbackAddress The address the oracle data will be sent to
   * @param callbackFunctionId The callback function ID for the response
   * @param nonce The nonce sent by the requester
   * @param dataVersion The specified data version
   * @param data The extra request parameters
   */
  function oracleRequest(
    address sender,
    uint256 payment,
    bytes32 specId,
    address callbackAddress,
    bytes4 callbackFunctionId,
    uint256 nonce,
    uint256 dataVersion,
    bytes calldata data
  ) external override validateFromLINK {
    (bytes32 requestId, uint256 expiration) = _verifyAndProcessOracleRequest(
      sender,
      payment,
      callbackAddress,
      callbackFunctionId,
      nonce,
      dataVersion
    );
    emit OracleRequest(specId, sender, requestId, payment, sender, callbackFunctionId, expiration, dataVersion, data);
  }

  /**
   * @notice Creates the Chainlink request
   * @dev Stores the hash of the params as the on-chain commitment for the request.
   * Emits OracleRequest event for the Chainlink node to detect.
   * @param sender The sender of the request
   * @param payment The amount of payment given (specified in wei)
   * @param specId The Job Specification ID
   * @param callbackFunctionId The callback function ID for the response
   * @param nonce The nonce sent by the requester
   * @param dataVersion The specified data version
   * @param data The extra request parameters
   */
  function operatorRequest(
    address sender,
    uint256 payment,
    bytes32 specId,
    bytes4 callbackFunctionId,
    uint256 nonce,
    uint256 dataVersion,
    bytes calldata data
  ) external override validateFromLINK {
    (bytes32 requestId, uint256 expiration) = _verifyAndProcessOracleRequest(
      sender,
      payment,
      sender,
      callbackFunctionId,
      nonce,
      dataVersion
    );
    emit OracleRequest(specId, sender, requestId, payment, sender, callbackFunctionId, expiration, dataVersion, data);
  }

  /**
   * @notice Called by the Chainlink node to fulfill requests
   * @dev Given params must hash back to the commitment stored from `oracleRequest`.
   * Will call the callback address' callback function without bubbling up error
   * checking in a `require` so that the node can get paid.
   * @param requestId The fulfillment request ID that must match the requester's
   * @param payment The payment amount that will be released for the oracle (specified in wei)
   * @param callbackAddress The callback address to call for fulfillment
   * @param callbackFunctionId The callback function ID to use for fulfillment
   * @param expiration The expiration that the node should respond by before the requester can cancel
   * @param data The data to return to the consuming contract
   * @return Status if the external call was successful
   */
  function fulfillOracleRequest(
    bytes32 requestId,
    uint256 payment,
    address callbackAddress,
    bytes4 callbackFunctionId,
    uint256 expiration,
    bytes32 data
  )
    external
    override
    validateAuthorizedSender
    validateRequestId(requestId)
    validateCallbackAddress(callbackAddress)
    returns (bool)
  {
    _verifyOracleRequestAndProcessPayment(requestId, payment, callbackAddress, callbackFunctionId, expiration, 1);
    emit OracleResponse(requestId);
    require(gasleft() >= MINIMUM_CONSUMER_GAS_LIMIT, "Must provide consumer enough gas");
    // All updates to the oracle's fulfillment should come before calling the
    // callback(addr+functionId) as it is untrusted.
    // See: https://solidity.readthedocs.io/en/develop/security-considerations.html#use-the-checks-effects-interactions-pattern
    (bool success, ) = callbackAddress.call(abi.encodeWithSelector(callbackFunctionId, requestId, data)); // solhint-disable-line avoid-low-level-calls
    return success;
  }

  /**
   * @notice Called by the Chainlink node to fulfill requests with multi-word support
   * @dev Given params must hash back to the commitment stored from `oracleRequest`.
   * Will call the callback address' callback function without bubbling up error
   * checking in a `require` so that the node can get paid.
   * @param requestId The fulfillment request ID that must match the requester's
   * @param payment The payment amount that will be released for the oracle (specified in wei)
   * @param callbackAddress The callback address to call for fulfillment
   * @param callbackFunctionId The callback function ID to use for fulfillment
   * @param expiration The expiration that the node should respond by before the requester can cancel
   * @param data The data to return to the consuming contract
   * @return Status if the external call was successful
   */
  function fulfillOracleRequest2(
    bytes32 requestId,
    uint256 payment,
    address callbackAddress,
    bytes4 callbackFunctionId,
    uint256 expiration,
    bytes calldata data
  )
    external
    override
    validateAuthorizedSender
    validateRequestId(requestId)
    validateCallbackAddress(callbackAddress)
    validateMultiWordResponseId(requestId, data)
    returns (bool)
  {
    _verifyOracleRequestAndProcessPayment(requestId, payment, callbackAddress, callbackFunctionId, expiration, 2);
    emit OracleResponse(requestId);
    require(gasleft() >= MINIMUM_CONSUMER_GAS_LIMIT, "Must provide consumer enough gas");
    // All updates to the oracle's fulfillment should come before calling the
    // callback(addr+functionId) as it is untrusted.
    // See: https://solidity.readthedocs.io/en/develop/security-considerations.html#use-the-checks-effects-interactions-pattern
    (bool success, ) = callbackAddress.call(abi.encodePacked(callbackFunctionId, data)); // solhint-disable-line avoid-low-level-calls
    return success;
  }

  /**
   * @notice Transfer the ownership of ownable contracts. This is primarilly
   * intended for Authorized Forwarders but could possibly be extended to work
   * with future contracts.
   * @param ownable list of addresses to transfer
   * @param newOwner address to transfer ownership to
   */
  function transferOwnableContracts(address[] calldata ownable, address newOwner) external onlyOwner {
    for (uint256 i = 0; i < ownable.length; i++) {
      s_owned[ownable[i]] = false;
      OwnableInterface(ownable[i]).transferOwnership(newOwner);
    }
  }

  /**
   * @notice Accept the ownership of an ownable contract. This is primarilly
   * intended for Authorized Forwarders but could possibly be extended to work
   * with future contracts.
   * @dev Must be the pending owner on the contract
   * @param ownable list of addresses of Ownable contracts to accept
   */
  function acceptOwnableContracts(address[] calldata ownable) public validateAuthorizedSenderSetter {
    for (uint256 i = 0; i < ownable.length; i++) {
      s_owned[ownable[i]] = true;
      emit OwnableContractAccepted(ownable[i]);
      OwnableInterface(ownable[i]).acceptOwnership();
    }
  }

  /**
   * @notice Sets the fulfillment permission for
   * @param targets The addresses to set permissions on
   * @param senders The addresses that are allowed to send updates
   */
  function setAuthorizedSendersOn(address[] calldata targets, address[] calldata senders)
    public
    validateAuthorizedSenderSetter
  {
    TargetsUpdatedAuthorizedSenders(targets, senders, msg.sender);

    for (uint256 i = 0; i < targets.length; i++) {
      AuthorizedReceiverInterface(targets[i]).setAuthorizedSenders(senders);
    }
  }

  /**
   * @notice Accepts ownership of ownable contracts and then immediately sets
   * the authorized sender list on each of the newly owned contracts. This is
   * primarilly intended for Authorized Forwarders but could possibly be
   * extended to work with future contracts.
   * @param targets The addresses to set permissions on
   * @param senders The addresses that are allowed to send updates
   */
  function acceptAuthorizedReceivers(address[] calldata targets, address[] calldata senders)
    external
    validateAuthorizedSenderSetter
  {
    acceptOwnableContracts(targets);
    setAuthorizedSendersOn(targets, senders);
  }

  /**
   * @notice Allows the node operator to withdraw earned LINK to a given address
   * @dev The owner of the contract can be another wallet and does not have to be a Chainlink node
   * @param recipient The address to send the LINK token to
   * @param amount The amount to send (specified in wei)
   */
  function withdraw(address recipient, uint256 amount)
    external
    override(OracleInterface, WithdrawalInterface)
    onlyOwner
    validateAvailableFunds(amount)
  {
    assert(linkToken.transfer(recipient, amount));
  }

  /**
   * @notice Displays the amount of LINK that is available for the node operator to withdraw
   * @dev We use `ONE_FOR_CONSISTENT_GAS_COST` in place of 0 in storage
   * @return The amount of withdrawable LINK on the contract
   */
  function withdrawable() external view override(OracleInterface, WithdrawalInterface) returns (uint256) {
    return _fundsAvailable();
  }

  /**
   * @notice Forward a call to another contract
   * @dev Only callable by the owner
   * @param to address
   * @param data to forward
   */
  function ownerForward(address to, bytes calldata data) external onlyOwner validateNotToLINK(to) {
    require(to.isContract(), "Must forward to a contract");
    (bool status, ) = to.call(data);
    require(status, "Forwarded call failed");
  }

  /**
   * @notice Interact with other LinkTokenReceiver contracts by calling transferAndCall
   * @param to The address to transfer to.
   * @param value The amount to be transferred.
   * @param data The extra data to be passed to the receiving contract.
   * @return success bool
   */
  function ownerTransferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external override onlyOwner validateAvailableFunds(value) returns (bool success) {
    return linkToken.transferAndCall(to, value, data);
  }

  /**
   * @notice Distribute funds to multiple addresses using ETH send
   * to this payable function.
   * @dev Array length must be equal, ETH sent must equal the sum of amounts.
   * A malicious receiver could cause the distribution to revert, in which case
   * it is expected that the address is removed from the list.
   * @param receivers list of addresses
   * @param amounts list of amounts
   */
  function distributeFunds(address payable[] calldata receivers, uint256[] calldata amounts) external payable {
    require(receivers.length > 0 && receivers.length == amounts.length, "Invalid array length(s)");
    uint256 valueRemaining = msg.value;
    for (uint256 i = 0; i < receivers.length; i++) {
      uint256 sendAmount = amounts[i];
      valueRemaining = valueRemaining.sub(sendAmount);
      receivers[i].transfer(sendAmount);
    }
    require(valueRemaining == 0, "Too much ETH sent");
  }

  /**
   * @notice Allows recipient to cancel requests sent to this oracle contract.
   * Will transfer the LINK sent for the request back to the recipient address.
   * @dev Given params must hash to a commitment stored on the contract in order
   * for the request to be valid. Emits CancelOracleRequest event.
   * @param requestId The request ID
   * @param payment The amount of payment given (specified in wei)
   * @param callbackFunc The requester's specified callback function selector
   * @param expiration The time of the expiration for the request
   */
  function cancelOracleRequest(
    bytes32 requestId,
    uint256 payment,
    bytes4 callbackFunc,
    uint256 expiration
  ) external override {
    bytes31 paramsHash = _buildParamsHash(payment, msg.sender, callbackFunc, expiration);
    require(s_commitments[requestId].paramsHash == paramsHash, "Params do not match request ID");
    // solhint-disable-next-line not-rely-on-time
    require(expiration <= block.timestamp, "Request is not expired");

    delete s_commitments[requestId];
    emit CancelOracleRequest(requestId);

    linkToken.transfer(msg.sender, payment);
  }

  /**
   * @notice Allows requester to cancel requests sent to this oracle contract.
   * Will transfer the LINK sent for the request back to the recipient address.
   * @dev Given params must hash to a commitment stored on the contract in order
   * for the request to be valid. Emits CancelOracleRequest event.
   * @param nonce The nonce used to generate the request ID
   * @param payment The amount of payment given (specified in wei)
   * @param callbackFunc The requester's specified callback function selector
   * @param expiration The time of the expiration for the request
   */
  function cancelOracleRequestByRequester(
    uint256 nonce,
    uint256 payment,
    bytes4 callbackFunc,
    uint256 expiration
  ) external {
    bytes32 requestId = keccak256(abi.encodePacked(msg.sender, nonce));
    bytes31 paramsHash = _buildParamsHash(payment, msg.sender, callbackFunc, expiration);
    require(s_commitments[requestId].paramsHash == paramsHash, "Params do not match request ID");
    // solhint-disable-next-line not-rely-on-time
    require(expiration <= block.timestamp, "Request is not expired");

    delete s_commitments[requestId];
    emit CancelOracleRequest(requestId);

    linkToken.transfer(msg.sender, payment);
  }

  /**
   * @notice Returns the address of the LINK token
   * @dev This is the public implementation for chainlinkTokenAddress, which is
   * an internal method of the ChainlinkClient contract
   */
  function getChainlinkToken() public view override returns (address) {
    return address(linkToken);
  }

  /**
   * @notice Require that the token transfer action is valid
   * @dev OPERATOR_REQUEST_SELECTOR = multiword, ORACLE_REQUEST_SELECTOR = singleword
   */
  function _validateTokenTransferAction(bytes4 funcSelector, bytes memory data) internal pure override {
    require(data.length >= MINIMUM_REQUEST_LENGTH, "Invalid request length");
    require(
      funcSelector == OPERATOR_REQUEST_SELECTOR || funcSelector == ORACLE_REQUEST_SELECTOR,
      "Must use whitelisted functions"
    );
  }

  /**
   * @notice Verify the Oracle Request and record necessary information
   * @param sender The sender of the request
   * @param payment The amount of payment given (specified in wei)
   * @param callbackAddress The callback address for the response
   * @param callbackFunctionId The callback function ID for the response
   * @param nonce The nonce sent by the requester
   */
  function _verifyAndProcessOracleRequest(
    address sender,
    uint256 payment,
    address callbackAddress,
    bytes4 callbackFunctionId,
    uint256 nonce,
    uint256 dataVersion
  ) private validateNotToLINK(callbackAddress) returns (bytes32 requestId, uint256 expiration) {
    requestId = keccak256(abi.encodePacked(sender, nonce));
    require(s_commitments[requestId].paramsHash == 0, "Must use a unique ID");
    // solhint-disable-next-line not-rely-on-time
    expiration = block.timestamp.add(getExpiryTime);
    bytes31 paramsHash = _buildParamsHash(payment, callbackAddress, callbackFunctionId, expiration);
    s_commitments[requestId] = Commitment(paramsHash, _safeCastToUint8(dataVersion));
    s_tokensInEscrow = s_tokensInEscrow.add(payment);
    return (requestId, expiration);
  }

  /**
   * @notice Verify the Oracle request and unlock escrowed payment
   * @param requestId The fulfillment request ID that must match the requester's
   * @param payment The payment amount that will be released for the oracle (specified in wei)
   * @param callbackAddress The callback address to call for fulfillment
   * @param callbackFunctionId The callback function ID to use for fulfillment
   * @param expiration The expiration that the node should respond by before the requester can cancel
   */
  function _verifyOracleRequestAndProcessPayment(
    bytes32 requestId,
    uint256 payment,
    address callbackAddress,
    bytes4 callbackFunctionId,
    uint256 expiration,
    uint256 dataVersion
  ) internal {
    bytes31 paramsHash = _buildParamsHash(payment, callbackAddress, callbackFunctionId, expiration);
    require(s_commitments[requestId].paramsHash == paramsHash, "Params do not match request ID");
    require(s_commitments[requestId].dataVersion <= _safeCastToUint8(dataVersion), "Data versions must match");
    s_tokensInEscrow = s_tokensInEscrow.sub(payment);
    delete s_commitments[requestId];
  }

  /**
   * @notice Build the bytes31 hash from the payment, callback and expiration.
   * @param payment The payment amount that will be released for the oracle (specified in wei)
   * @param callbackAddress The callback address to call for fulfillment
   * @param callbackFunctionId The callback function ID to use for fulfillment
   * @param expiration The expiration that the node should respond by before the requester can cancel
   * @return hash bytes31
   */
  function _buildParamsHash(
    uint256 payment,
    address callbackAddress,
    bytes4 callbackFunctionId,
    uint256 expiration
  ) internal pure returns (bytes31) {
    return bytes31(keccak256(abi.encodePacked(payment, callbackAddress, callbackFunctionId, expiration)));
  }

  /**
   * @notice Safely cast uint256 to uint8
   * @param number uint256
   * @return uint8 number
   */
  function _safeCastToUint8(uint256 number) internal pure returns (uint8) {
    require(number < MAXIMUM_DATA_VERSION, "number too big to cast");
    return uint8(number);
  }

  /**
   * @notice Returns the LINK available in this contract, not locked in escrow
   * @return uint256 LINK tokens available
   */
  function _fundsAvailable() private view returns (uint256) {
    uint256 inEscrow = s_tokensInEscrow.sub(ONE_FOR_CONSISTENT_GAS_COST);
    return linkToken.balanceOf(address(this)).sub(inEscrow);
  }

  /**
   * @notice concrete implementation of AuthorizedReceiver
   * @return bool of whether sender is authorized
   */
  function _canSetAuthorizedSenders() internal view override returns (bool) {
    return isAuthorizedSender(msg.sender) || owner() == msg.sender;
  }

  // MODIFIERS

  /**
   * @dev Reverts if the first 32 bytes of the bytes array is not equal to requestId
   * @param requestId bytes32
   * @param data bytes
   */
  modifier validateMultiWordResponseId(bytes32 requestId, bytes calldata data) {
    require(data.length >= 32, "Response must be > 32 bytes");
    bytes32 firstDataWord;
    assembly {
      // extract the first word from data
      // functionSelector = 4
      // wordLength = 32
      // dataArgumentOffset = 7 * wordLength
      // funcSelector + dataArgumentOffset == 0xe4
      firstDataWord := calldataload(0xe4)
    }
    require(requestId == firstDataWord, "First word must be requestId");
    _;
  }

  /**
   * @dev Reverts if amount requested is greater than withdrawable balance
   * @param amount The given amount to compare to `s_withdrawableTokens`
   */
  modifier validateAvailableFunds(uint256 amount) {
    require(_fundsAvailable() >= amount, "Amount requested is greater than withdrawable balance");
    _;
  }

  /**
   * @dev Reverts if request ID does not exist
   * @param requestId The given request ID to check in stored `commitments`
   */
  modifier validateRequestId(bytes32 requestId) {
    require(s_commitments[requestId].paramsHash != 0, "Must have a valid requestId");
    _;
  }

  /**
   * @dev Reverts if the callback address is the LINK token
   * @param to The callback address
   */
  modifier validateNotToLINK(address to) {
    require(to != address(linkToken), "Cannot call to LINK");
    _;
  }

  /**
   * @dev Reverts if the target address is owned by the operator
   */
  modifier validateCallbackAddress(address callbackAddress) {
    require(!s_owned[callbackAddress], "Cannot call owned contract");
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

abstract contract LinkTokenReceiver {
  /**
   * @notice Called when LINK is sent to the contract via `transferAndCall`
   * @dev The data payload's first 2 words will be overwritten by the `sender` and `amount`
   * values to ensure correctness. Calls oracleRequest.
   * @param sender Address of the sender
   * @param amount Amount of LINK sent (specified in wei)
   * @param data Payload of the transaction
   */
  function onTokenTransfer(
    address sender,
    uint256 amount,
    bytes memory data
  ) public validateFromLINK permittedFunctionsForLINK(data) {
    assembly {
      // solhint-disable-next-line avoid-low-level-calls
      mstore(add(data, 36), sender) // ensure correct sender is passed
      // solhint-disable-next-line avoid-low-level-calls
      mstore(add(data, 68), amount) // ensure correct amount is passed
    }
    // solhint-disable-next-line avoid-low-level-calls
    (bool success, ) = address(this).delegatecall(data); // calls oracleRequest
    require(success, "Unable to create request");
  }

  function getChainlinkToken() public view virtual returns (address);

  /**
   * @notice Validate the function called on token transfer
   */
  function _validateTokenTransferAction(bytes4 funcSelector, bytes memory data) internal virtual;

  /**
   * @dev Reverts if not sent from the LINK token
   */
  modifier validateFromLINK() {
    require(msg.sender == getChainlinkToken(), "Must use LINK token");
    _;
  }

  /**
   * @dev Reverts if the given data does not begin with the `oracleRequest` function selector
   * @param data The data payload of the request
   */
  modifier permittedFunctionsForLINK(bytes memory data) {
    bytes4 funcSelector;
    assembly {
      // solhint-disable-next-line avoid-low-level-calls
      funcSelector := mload(add(data, 32))
    }
    _validateTokenTransferAction(funcSelector, data);
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./ConfirmedOwnerWithProposal.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwner is ConfirmedOwnerWithProposal {
  constructor(address newOwner) ConfirmedOwnerWithProposal(newOwner, address(0)) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface WithdrawalInterface {
  /**
   * @notice transfer LINK held by the contract belonging to msg.sender to
   * another address
   * @param recipient is the address to send the LINK to
   * @param amount is the amount of LINK to send
   */
  function withdraw(address recipient, uint256 amount) external;

  /**
   * @notice query the available amount of LINK to withdraw by msg.sender
   */
  function withdrawable() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

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
library SafeMathChainlink {
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
    require(b <= a, "SafeMath: subtraction overflow");
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
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, "SafeMath: division by zero");
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
    require(b != 0, "SafeMath: modulo by zero");
    return a % b;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./vendor/SafeMathChainlink.sol";

import "./interfaces/LinkTokenInterface.sol";

import "./VRFRequestIDBase.sol";

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constuctor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator, _link) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash), and have told you the minimum LINK
 * @dev price for VRF service. Make sure your contract has sufficient LINK, and
 * @dev call requestRandomness(keyHash, fee, seed), where seed is the input you
 * @dev want to generate randomness from.
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomness method.
 *
 * @dev The randomness argument to fulfillRandomness is the actual random value
 * @dev generated from your seed.
 *
 * @dev The requestId argument is generated from the keyHash and the seed by
 * @dev makeRequestId(keyHash, seed). If your contract could have concurrent
 * @dev requests open, you can use the requestId to track which seed is
 * @dev associated with which randomness. See VRFRequestIDBase.sol for more
 * @dev details. (See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.)
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ. (Which is critical to making unpredictable randomness! See the
 * @dev next section.)
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the ultimate input to the VRF is mixed with the block hash of the
 * @dev block in which the request is made, user-provided seeds have no impact
 * @dev on its economic security properties. They are only included for API
 * @dev compatability with previous versions of this contract.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request.
 */
abstract contract VRFConsumerBase is VRFRequestIDBase {
  using SafeMathChainlink for uint256;

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBase expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomness the VRF output
   */
  function fulfillRandomness(bytes32 requestId, uint256 randomness) internal virtual;

  /**
   * @dev In order to keep backwards compatibility we have kept the user
   * seed field around. We remove the use of it because given that the blockhash
   * enters later, it overrides whatever randomness the used seed provides.
   * Given that it adds no security, and can easily lead to misunderstandings,
   * we have removed it from usage and can now provide a simpler API.
   */
  uint256 private constant USER_SEED_PLACEHOLDER = 0;

  /**
   * @notice requestRandomness initiates a request for VRF output given _seed
   *
   * @dev The fulfillRandomness method receives the output, once it's provided
   * @dev by the Oracle, and verified by the vrfCoordinator.
   *
   * @dev The _keyHash must already be registered with the VRFCoordinator, and
   * @dev the _fee must exceed the fee specified during registration of the
   * @dev _keyHash.
   *
   * @dev The _seed parameter is vestigial, and is kept only for API
   * @dev compatibility with older versions. It can't *hurt* to mix in some of
   * @dev your own randomness, here, but it's not necessary because the VRF
   * @dev oracle will mix the hash of the block containing your request into the
   * @dev VRF seed it ultimately uses.
   *
   * @param _keyHash ID of public key against which randomness is generated
   * @param _fee The amount of LINK to send with the request
   *
   * @return requestId unique ID for this request
   *
   * @dev The returned requestId can be used to distinguish responses to
   * @dev concurrent requests. It is passed as the first argument to
   * @dev fulfillRandomness.
   */
  function requestRandomness(bytes32 _keyHash, uint256 _fee) internal returns (bytes32 requestId) {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
    // nonces[_keyHash] must stay in sync with
    // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
    // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
    // This provides protection against the user repeating their input seed,
    // which would result in a predictable/duplicate output, if multiple such
    // requests appeared in the same block.
    nonces[_keyHash] = nonces[_keyHash].add(1);
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface internal immutable LINK;
  address private immutable vrfCoordinator;

  // Nonces for each VRF key from which randomness has been requested.
  //
  // Must stay in sync with VRFCoordinator[_keyHash][this]
  mapping(bytes32 => uint256) /* keyHash */ /* nonce */
    private nonces;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   * @param _link address of LINK token contract
   *
   * @dev https://docs.chain.link/docs/link-token-contracts
   */
  constructor(address _vrfCoordinator, address _link) {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract VRFRequestIDBase {
  /**
   * @notice returns the seed which is actually input to the VRF coordinator
   *
   * @dev To prevent repetition of VRF output due to repetition of the
   * @dev user-supplied seed, that seed is combined in a hash with the
   * @dev user-specific nonce, and the address of the consuming contract. The
   * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
   * @dev the final seed, but the nonce does protect against repetition in
   * @dev requests which are included in a single block.
   *
   * @param _userSeed VRF seed input provided by user
   * @param _requester Address of the requesting contract
   * @param _nonce User-specific nonce at the time of the request
   */
  function makeVRFInputSeed(
    bytes32 _keyHash,
    uint256 _userSeed,
    address _requester,
    uint256 _nonce
  ) internal pure returns (uint256) {
    return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  /**
   * @notice Returns the id for this request
   * @param _keyHash The serviceAgreement ID to be used for this request
   * @param _vRFInputSeed The seed to be passed directly to the VRF
   * @return The id for this request
   *
   * @dev Note that _vRFInputSeed is not the seed passed by the consuming
   * @dev contract, but the one generated by makeVRFInputSeed
   */
  function makeRequestId(bytes32 _keyHash, uint256 _vRFInputSeed) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./interfaces/LinkTokenInterface.sol";
import "./interfaces/KeeperRegistryInterface.sol";
import "./vendor/SafeMath96.sol";
import "./ConfirmedOwner.sol";

/**
 * @notice Contract to accept requests for upkeep registrations
 * @dev There are 2 registration workflows in this contract
 * Flow 1. auto approve OFF / manual registration - UI calls `register` function on this contract, this contract owner at a later time then manually
 *  calls `approve` to register upkeep and emit events to inform UI and others interested.
 * Flow 2. auto approve ON / real time registration - UI calls `register` function as before, which calls the `registerUpkeep` function directly on
 *  keeper registry and then emits approved event to finish the flow automatically without manual intervention.
 * The idea is to have same interface(functions,events) for UI or anyone using this contract irrespective of auto approve being enabled or not.
 * they can just listen to `RegistrationRequested` & `RegistrationApproved` events and know the status on registrations.
 */
contract UpkeepRegistrationRequests is ConfirmedOwner {
  using SafeMath96 for uint96;

  bytes4 private constant REGISTER_REQUEST_SELECTOR = this.register.selector;

  uint256 private s_minLINKJuels;
  mapping(bytes32 => PendingRequest) private s_pendingRequests;

  LinkTokenInterface public immutable LINK;

  struct AutoApprovedConfig {
    bool enabled;
    uint16 allowedPerWindow;
    uint32 windowSizeInBlocks;
    uint64 windowStart;
    uint16 approvedInCurrentWindow;
  }

  struct PendingRequest {
    address admin;
    uint96 balance;
  }

  AutoApprovedConfig private s_config;
  KeeperRegistryBaseInterface private s_keeperRegistry;

  event RegistrationRequested(
    bytes32 indexed hash,
    string name,
    bytes encryptedEmail,
    address indexed upkeepContract,
    uint32 gasLimit,
    address adminAddress,
    bytes checkData,
    uint96 amount,
    uint8 indexed source
  );

  event RegistrationApproved(bytes32 indexed hash, string displayName, uint256 indexed upkeepId);

  event RegistrationRejected(bytes32 indexed hash);

  event ConfigChanged(
    bool enabled,
    uint32 windowSizeInBlocks,
    uint16 allowedPerWindow,
    address keeperRegistry,
    uint256 minLINKJuels
  );

  constructor(address LINKAddress, uint256 minimumLINKJuels) ConfirmedOwner(msg.sender) {
    LINK = LinkTokenInterface(LINKAddress);
    s_minLINKJuels = minimumLINKJuels;
  }

  //EXTERNAL

  /**
   * @notice register can only be called through transferAndCall on LINK contract
   * @param name string of the upkeep to be registered
   * @param encryptedEmail email address of upkeep contact
   * @param upkeepContract address to peform upkeep on
   * @param gasLimit amount of gas to provide the target contract when performing upkeep
   * @param adminAddress address to cancel upkeep and withdraw remaining funds
   * @param checkData data passed to the contract when checking for upkeep
   * @param amount quantity of LINK upkeep is funded with (specified in Juels)
   * @param source application sending this request
   */
  function register(
    string memory name,
    bytes calldata encryptedEmail,
    address upkeepContract,
    uint32 gasLimit,
    address adminAddress,
    bytes calldata checkData,
    uint96 amount,
    uint8 source
  ) external onlyLINK {
    require(adminAddress != address(0), "invalid admin address");
    bytes32 hash = keccak256(abi.encode(upkeepContract, gasLimit, adminAddress, checkData));

    emit RegistrationRequested(
      hash,
      name,
      encryptedEmail,
      upkeepContract,
      gasLimit,
      adminAddress,
      checkData,
      amount,
      source
    );

    AutoApprovedConfig memory config = s_config;
    if (config.enabled && _underApprovalLimit(config)) {
      _incrementApprovedCount(config);

      _approve(name, upkeepContract, gasLimit, adminAddress, checkData, amount, hash);
    } else {
      uint96 newBalance = s_pendingRequests[hash].balance.add(amount);
      s_pendingRequests[hash] = PendingRequest({admin: adminAddress, balance: newBalance});
    }
  }

  /**
   * @dev register upkeep on KeeperRegistry contract and emit RegistrationApproved event
   */
  function approve(
    string memory name,
    address upkeepContract,
    uint32 gasLimit,
    address adminAddress,
    bytes calldata checkData,
    bytes32 hash
  ) external onlyOwner {
    PendingRequest memory request = s_pendingRequests[hash];
    require(request.admin != address(0), "request not found");
    bytes32 expectedHash = keccak256(abi.encode(upkeepContract, gasLimit, adminAddress, checkData));
    require(hash == expectedHash, "hash and payload do not match");
    delete s_pendingRequests[hash];
    _approve(name, upkeepContract, gasLimit, adminAddress, checkData, request.balance, hash);
  }

  /**
   * @notice cancel will remove a registration request and return the refunds to the msg.sender
   * @param hash the request hash
   */
  function cancel(bytes32 hash) external {
    PendingRequest memory request = s_pendingRequests[hash];
    require(msg.sender == request.admin || msg.sender == owner(), "only admin / owner can cancel");
    require(request.admin != address(0), "request not found");
    delete s_pendingRequests[hash];
    require(LINK.transfer(msg.sender, request.balance), "LINK token transfer failed");
    emit RegistrationRejected(hash);
  }

  /**
   * @notice owner calls this function to set if registration requests should be sent directly to the Keeper Registry
   * @param enabled setting for autoapprove registrations
   * @param windowSizeInBlocks window size defined in number of blocks
   * @param allowedPerWindow number of registrations that can be auto approved in above window
   * @param keeperRegistry new keeper registry address
   */
  function setRegistrationConfig(
    bool enabled,
    uint32 windowSizeInBlocks,
    uint16 allowedPerWindow,
    address keeperRegistry,
    uint256 minLINKJuels
  ) external onlyOwner {
    s_config = AutoApprovedConfig({
      enabled: enabled,
      allowedPerWindow: allowedPerWindow,
      windowSizeInBlocks: windowSizeInBlocks,
      windowStart: 0,
      approvedInCurrentWindow: 0
    });
    s_minLINKJuels = minLINKJuels;
    s_keeperRegistry = KeeperRegistryBaseInterface(keeperRegistry);

    emit ConfigChanged(enabled, windowSizeInBlocks, allowedPerWindow, keeperRegistry, minLINKJuels);
  }

  /**
   * @notice read the current registration configuration
   */
  function getRegistrationConfig()
    external
    view
    returns (
      bool enabled,
      uint32 windowSizeInBlocks,
      uint16 allowedPerWindow,
      address keeperRegistry,
      uint256 minLINKJuels,
      uint64 windowStart,
      uint16 approvedInCurrentWindow
    )
  {
    AutoApprovedConfig memory config = s_config;
    return (
      config.enabled,
      config.windowSizeInBlocks,
      config.allowedPerWindow,
      address(s_keeperRegistry),
      s_minLINKJuels,
      config.windowStart,
      config.approvedInCurrentWindow
    );
  }

  /**
   * @notice gets the admin address and the current balance of a registration request
   */
  function getPendingRequest(bytes32 hash) external view returns (address, uint96) {
    PendingRequest memory request = s_pendingRequests[hash];
    return (request.admin, request.balance);
  }

  /**
   * @notice Called when LINK is sent to the contract via `transferAndCall`
   * @param amount Amount of LINK sent (specified in Juels)
   * @param data Payload of the transaction
   */
  function onTokenTransfer(
    address, /* sender */
    uint256 amount,
    bytes calldata data
  ) external onlyLINK permittedFunctionsForLINK(data) isActualAmount(amount, data) {
    require(amount >= s_minLINKJuels, "Insufficient payment");
    (bool success, ) = address(this).delegatecall(data);
    // calls register
    require(success, "Unable to create request");
  }

  //PRIVATE

  /**
   * @dev reset auto approve window if passed end of current window
   */
  function _resetWindowIfRequired(AutoApprovedConfig memory config) private {
    uint64 blocksPassed = uint64(block.number - config.windowStart);
    if (blocksPassed >= config.windowSizeInBlocks) {
      config.windowStart = uint64(block.number);
      config.approvedInCurrentWindow = 0;
      s_config = config;
    }
  }

  /**
   * @dev register upkeep on KeeperRegistry contract and emit RegistrationApproved event
   */
  function _approve(
    string memory name,
    address upkeepContract,
    uint32 gasLimit,
    address adminAddress,
    bytes calldata checkData,
    uint96 amount,
    bytes32 hash
  ) private {
    KeeperRegistryBaseInterface keeperRegistry = s_keeperRegistry;

    // register upkeep
    uint256 upkeepId = keeperRegistry.registerUpkeep(upkeepContract, gasLimit, adminAddress, checkData);
    // fund upkeep
    bool success = LINK.transferAndCall(address(keeperRegistry), amount, abi.encode(upkeepId));
    require(success, "failed to fund upkeep");

    emit RegistrationApproved(hash, name, upkeepId);
  }

  /**
   * @dev determine approval limits and check if in range
   */
  function _underApprovalLimit(AutoApprovedConfig memory config) private returns (bool) {
    _resetWindowIfRequired(config);
    if (config.approvedInCurrentWindow < config.allowedPerWindow) {
      return true;
    }
    return false;
  }

  /**
   * @dev record new latest approved count
   */
  function _incrementApprovedCount(AutoApprovedConfig memory config) private {
    config.approvedInCurrentWindow++;
    s_config = config;
  }

  //MODIFIERS

  /**
   * @dev Reverts if not sent from the LINK token
   */
  modifier onlyLINK() {
    require(msg.sender == address(LINK), "Must use LINK token");
    _;
  }

  /**
   * @dev Reverts if the given data does not begin with the `register` function selector
   * @param _data The data payload of the request
   */
  modifier permittedFunctionsForLINK(bytes memory _data) {
    bytes4 funcSelector;
    assembly {
      // solhint-disable-next-line avoid-low-level-calls
      funcSelector := mload(add(_data, 32))
    }
    require(funcSelector == REGISTER_REQUEST_SELECTOR, "Must use whitelisted functions");
    _;
  }

  /**
   * @dev Reverts if the actual amount passed does not match the expected amount
   * @param expected amount that should match the actual amount
   * @param data bytes
   */
  modifier isActualAmount(uint256 expected, bytes memory data) {
    uint256 actual;
    assembly {
      actual := mload(add(data, 228))
    }
    require(expected == actual, "Amount mismatch");
    _;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

interface KeeperRegistryBaseInterface {
  function registerUpkeep(
    address target,
    uint32 gasLimit,
    address admin,
    bytes calldata checkData
  ) external returns (uint256 id);

  function performUpkeep(uint256 id, bytes calldata performData) external returns (bool success);

  function cancelUpkeep(uint256 id) external;

  function addFunds(uint256 id, uint96 amount) external;

  function getUpkeep(uint256 id)
    external
    view
    returns (
      address target,
      uint32 executeGas,
      bytes memory checkData,
      uint96 balance,
      address lastKeeper,
      address admin,
      uint64 maxValidBlocknumber
    );

  function getUpkeepCount() external view returns (uint256);

  function getCanceledUpkeepList() external view returns (uint256[] memory);

  function getKeeperList() external view returns (address[] memory);

  function getKeeperInfo(address query)
    external
    view
    returns (
      address payee,
      bool active,
      uint96 balance
    );

  function getConfig()
    external
    view
    returns (
      uint32 paymentPremiumPPB,
      uint24 checkFrequencyBlocks,
      uint32 checkGasLimit,
      uint24 stalenessSeconds,
      uint16 gasCeilingMultiplier,
      uint256 fallbackGasPrice,
      uint256 fallbackLinkPrice
    );
}

/**
 * @dev The view methods are not actually marked as view in the implementation
 * but we want them to be easily queried off-chain. Solidity will not compile
 * if we actually inherrit from this interface, so we document it here.
 */
interface KeeperRegistryInterface is KeeperRegistryBaseInterface {
  function checkUpkeep(uint256 upkeepId, address from)
    external
    view
    returns (
      bytes memory performData,
      uint256 maxLinkPayment,
      uint256 gasLimit,
      int256 gasWei,
      int256 linkEth
    );
}

interface KeeperRegistryExecutableInterface is KeeperRegistryBaseInterface {
  function checkUpkeep(uint256 upkeepId, address from)
    external
    returns (
      bytes memory performData,
      uint256 maxLinkPayment,
      uint256 gasLimit,
      uint256 adjustedGasWei,
      uint256 linkEth
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
 *
 * This library is a version of Open Zeppelin's SafeMath, modified to support
 * unsigned 96 bit integers.
 */
library SafeMath96 {
  /**
   * @dev Returns the addition of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `+` operator.
   *
   * Requirements:
   * - Addition cannot overflow.
   */
  function add(uint96 a, uint96 b) internal pure returns (uint96) {
    uint96 c = a + b;
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
  function sub(uint96 a, uint96 b) internal pure returns (uint96) {
    require(b <= a, "SafeMath: subtraction overflow");
    uint96 c = a - b;

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
  function mul(uint96 a, uint96 b) internal pure returns (uint96) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint96 c = a * b;
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
  function div(uint96 a, uint96 b) internal pure returns (uint96) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, "SafeMath: division by zero");
    uint96 c = a / b;
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
  function mod(uint96 a, uint96 b) internal pure returns (uint96) {
    require(b != 0, "SafeMath: modulo by zero");
    return a % b;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "../ConfirmedOwner.sol";

contract ConfirmedOwnerTestHelper is ConfirmedOwner {
  event Here();

  constructor() ConfirmedOwner(msg.sender) {}

  function modifierOnlyOwner() public onlyOwner {
    emit Here();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./interfaces/AggregatorV3Interface.sol";
import "./interfaces/LinkTokenInterface.sol";
import "./interfaces/KeeperCompatibleInterface.sol";
import "./interfaces/KeeperRegistryInterface.sol";
import "./interfaces/TypeAndVersionInterface.sol";
import "./vendor/SafeMathChainlink.sol";
import "./vendor/Address.sol";
import "./vendor/Pausable.sol";
import "./vendor/ReentrancyGuard.sol";
import "./vendor/SignedSafeMath.sol";
import "./vendor/SafeMath96.sol";
import "./KeeperBase.sol";
import "./ConfirmedOwner.sol";

/**
 * @notice Registry for adding work for Chainlink Keepers to perform on client
 * contracts. Clients must support the Upkeep interface.
 */
contract KeeperRegistry is
  TypeAndVersionInterface,
  ConfirmedOwner,
  KeeperBase,
  ReentrancyGuard,
  Pausable,
  KeeperRegistryExecutableInterface
{
  using Address for address;
  using SafeMathChainlink for uint256;
  using SafeMath96 for uint96;
  using SignedSafeMath for int256;

  address private constant ZERO_ADDRESS = address(0);
  address private constant IGNORE_ADDRESS = 0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF;
  bytes4 private constant CHECK_SELECTOR = KeeperCompatibleInterface.checkUpkeep.selector;
  bytes4 private constant PERFORM_SELECTOR = KeeperCompatibleInterface.performUpkeep.selector;
  uint256 private constant CALL_GAS_MAX = 5_000_000;
  uint256 private constant CALL_GAS_MIN = 2_300;
  uint256 private constant CANCELATION_DELAY = 50;
  uint256 private constant CUSHION = 5_000;
  uint256 private constant REGISTRY_GAS_OVERHEAD = 80_000;
  uint256 private constant PPB_BASE = 1_000_000_000;
  uint64 private constant UINT64_MAX = 2**64 - 1;
  uint96 private constant LINK_TOTAL_SUPPLY = 1e27;

  uint256 private s_upkeepCount;
  uint256[] private s_canceledUpkeepList;
  address[] private s_keeperList;
  mapping(uint256 => Upkeep) private s_upkeep;
  mapping(address => KeeperInfo) private s_keeperInfo;
  mapping(address => address) private s_proposedPayee;
  mapping(uint256 => bytes) private s_checkData;
  Config private s_config;
  uint256 private s_fallbackGasPrice; // not in config object for gas savings
  uint256 private s_fallbackLinkPrice; // not in config object for gas savings
  uint256 private s_expectedLinkBalance;

  LinkTokenInterface public immutable LINK;
  AggregatorV3Interface public immutable LINK_ETH_FEED;
  AggregatorV3Interface public immutable FAST_GAS_FEED;

  address private s_registrar;

  /**
   * @notice versions:
   * - KeeperRegistry 1.1.0: added flatFeeMicroLink
   * - KeeperRegistry 1.0.0: initial release
   */
  string public constant override typeAndVersion = "KeeperRegistry 1.1.0";

  struct Upkeep {
    address target;
    uint32 executeGas;
    uint96 balance;
    address admin;
    uint64 maxValidBlocknumber;
    address lastKeeper;
  }

  struct KeeperInfo {
    address payee;
    uint96 balance;
    bool active;
  }

  struct Config {
    uint32 paymentPremiumPPB;
    uint32 flatFeeMicroLink; // min 0.000001 LINK, max 4294 LINK
    uint24 blockCountPerTurn;
    uint32 checkGasLimit;
    uint24 stalenessSeconds;
    uint16 gasCeilingMultiplier;
  }

  struct PerformParams {
    address from;
    uint256 id;
    bytes performData;
    uint256 maxLinkPayment;
    uint256 gasLimit;
    uint256 adjustedGasWei;
    uint256 linkEth;
  }

  event UpkeepRegistered(uint256 indexed id, uint32 executeGas, address admin);
  event UpkeepPerformed(
    uint256 indexed id,
    bool indexed success,
    address indexed from,
    uint96 payment,
    bytes performData
  );
  event UpkeepCanceled(uint256 indexed id, uint64 indexed atBlockHeight);
  event FundsAdded(uint256 indexed id, address indexed from, uint96 amount);
  event FundsWithdrawn(uint256 indexed id, uint256 amount, address to);
  event ConfigSet(
    uint32 paymentPremiumPPB,
    uint24 blockCountPerTurn,
    uint32 checkGasLimit,
    uint24 stalenessSeconds,
    uint16 gasCeilingMultiplier,
    uint256 fallbackGasPrice,
    uint256 fallbackLinkPrice
  );
  event FlatFeeSet(uint32 flatFeeMicroLink);
  event KeepersUpdated(address[] keepers, address[] payees);
  event PaymentWithdrawn(address indexed keeper, uint256 indexed amount, address indexed to, address payee);
  event PayeeshipTransferRequested(address indexed keeper, address indexed from, address indexed to);
  event PayeeshipTransferred(address indexed keeper, address indexed from, address indexed to);
  event RegistrarChanged(address indexed from, address indexed to);

  /**
   * @param link address of the LINK Token
   * @param linkEthFeed address of the LINK/ETH price feed
   * @param fastGasFeed address of the Fast Gas price feed
   * @param paymentPremiumPPB payment premium rate oracles receive on top of
   * being reimbursed for gas, measured in parts per billion
   * @param flatFeeMicroLink flat fee paid to oracles for performing upkeeps,
   * priced in MicroLink; can be used in conjunction with or independently of
   * paymentPremiumPPB
   * @param blockCountPerTurn number of blocks each oracle has during their turn to
   * perform upkeep before it will be the next keeper's turn to submit
   * @param checkGasLimit gas limit when checking for upkeep
   * @param stalenessSeconds number of seconds that is allowed for feed data to
   * be stale before switching to the fallback pricing
   * @param gasCeilingMultiplier multiplier to apply to the fast gas feed price
   * when calculating the payment ceiling for keepers
   * @param fallbackGasPrice gas price used if the gas price feed is stale
   * @param fallbackLinkPrice LINK price used if the LINK price feed is stale
   */
  constructor(
    address link,
    address linkEthFeed,
    address fastGasFeed,
    uint32 paymentPremiumPPB,
    uint32 flatFeeMicroLink,
    uint24 blockCountPerTurn,
    uint32 checkGasLimit,
    uint24 stalenessSeconds,
    uint16 gasCeilingMultiplier,
    uint256 fallbackGasPrice,
    uint256 fallbackLinkPrice
  ) ConfirmedOwner(msg.sender) {
    LINK = LinkTokenInterface(link);
    LINK_ETH_FEED = AggregatorV3Interface(linkEthFeed);
    FAST_GAS_FEED = AggregatorV3Interface(fastGasFeed);

    setConfig(
      paymentPremiumPPB,
      flatFeeMicroLink,
      blockCountPerTurn,
      checkGasLimit,
      stalenessSeconds,
      gasCeilingMultiplier,
      fallbackGasPrice,
      fallbackLinkPrice
    );
  }

  // ACTIONS

  /**
   * @notice adds a new upkeep
   * @param target address to perform upkeep on
   * @param gasLimit amount of gas to provide the target contract when
   * performing upkeep
   * @param admin address to cancel upkeep and withdraw remaining funds
   * @param checkData data passed to the contract when checking for upkeep
   */
  function registerUpkeep(
    address target,
    uint32 gasLimit,
    address admin,
    bytes calldata checkData
  ) external override onlyOwnerOrRegistrar returns (uint256 id) {
    require(target.isContract(), "target is not a contract");
    require(gasLimit >= CALL_GAS_MIN, "min gas is 2300");
    require(gasLimit <= CALL_GAS_MAX, "max gas is 5000000");

    id = s_upkeepCount;
    s_upkeep[id] = Upkeep({
      target: target,
      executeGas: gasLimit,
      balance: 0,
      admin: admin,
      maxValidBlocknumber: UINT64_MAX,
      lastKeeper: address(0)
    });
    s_checkData[id] = checkData;
    s_upkeepCount++;

    emit UpkeepRegistered(id, gasLimit, admin);

    return id;
  }

  /**
   * @notice simulated by keepers via eth_call to see if the upkeep needs to be
   * performed. If upkeep is needed, the call then simulates performUpkeep
   * to make sure it succeeds. Finally, it returns the success status along with
   * payment information and the perform data payload.
   * @param id identifier of the upkeep to check
   * @param from the address to simulate performing the upkeep from
   */
  function checkUpkeep(uint256 id, address from)
    external
    override
    whenNotPaused
    cannotExecute
    returns (
      bytes memory performData,
      uint256 maxLinkPayment,
      uint256 gasLimit,
      uint256 adjustedGasWei,
      uint256 linkEth
    )
  {
    bytes memory callData = abi.encodeWithSelector(CHECK_SELECTOR, s_checkData[id]);
    (bool success, bytes memory result) = s_upkeep[id].target.call{gas: s_config.checkGasLimit}(callData);

    if (!success) {
      string memory upkeepRevertReason = getRevertMsg(result);
      string memory reason = string(abi.encodePacked("call to check target failed: ", upkeepRevertReason));
      revert(reason);
    }

    (success, performData) = abi.decode(result, (bool, bytes));
    require(success, "upkeep not needed");

    PerformParams memory params = generatePerformParams(from, id, performData, false);
    success = performUpkeepWithParams(params);
    require(success, "call to perform upkeep failed");

    return (performData, params.maxLinkPayment, params.gasLimit, params.adjustedGasWei, params.linkEth);
  }

  /**
   * @notice executes the upkeep with the perform data returned from
   * checkUpkeep, validates the keeper's permissions, and pays the keeper.
   * @param id identifier of the upkeep to execute the data with.
   * @param performData calldata parameter to be passed to the target upkeep.
   */
  function performUpkeep(uint256 id, bytes calldata performData) external override returns (bool success) {
    return performUpkeepWithParams(generatePerformParams(msg.sender, id, performData, true));
  }

  /**
   * @notice prevent an upkeep from being performed in the future
   * @param id upkeep to be canceled
   */
  function cancelUpkeep(uint256 id) external override {
    uint64 maxValid = s_upkeep[id].maxValidBlocknumber;
    bool notCanceled = maxValid == UINT64_MAX;
    bool isOwner = msg.sender == owner();
    require(notCanceled || (isOwner && maxValid > block.number), "too late to cancel upkeep");
    require(isOwner || msg.sender == s_upkeep[id].admin, "only owner or admin");

    uint256 height = block.number;
    if (!isOwner) {
      height = height.add(CANCELATION_DELAY);
    }
    s_upkeep[id].maxValidBlocknumber = uint64(height);
    if (notCanceled) {
      s_canceledUpkeepList.push(id);
    }

    emit UpkeepCanceled(id, uint64(height));
  }

  /**
   * @notice adds LINK funding for an upkeep by tranferring from the sender's
   * LINK balance
   * @param id upkeep to fund
   * @param amount number of LINK to transfer
   */
  function addFunds(uint256 id, uint96 amount) external override {
    require(s_upkeep[id].maxValidBlocknumber == UINT64_MAX, "upkeep must be active");
    s_upkeep[id].balance = s_upkeep[id].balance.add(amount);
    s_expectedLinkBalance = s_expectedLinkBalance.add(amount);
    LINK.transferFrom(msg.sender, address(this), amount);
    emit FundsAdded(id, msg.sender, amount);
  }

  /**
   * @notice uses LINK's transferAndCall to LINK and add funding to an upkeep
   * @dev safe to cast uint256 to uint96 as total LINK supply is under UINT96MAX
   * @param sender the account which transferred the funds
   * @param amount number of LINK transfer
   */
  function onTokenTransfer(
    address sender,
    uint256 amount,
    bytes calldata data
  ) external {
    require(msg.sender == address(LINK), "only callable through LINK");
    require(data.length == 32, "data must be 32 bytes");
    uint256 id = abi.decode(data, (uint256));
    require(s_upkeep[id].maxValidBlocknumber == UINT64_MAX, "upkeep must be active");

    s_upkeep[id].balance = s_upkeep[id].balance.add(uint96(amount));
    s_expectedLinkBalance = s_expectedLinkBalance.add(amount);

    emit FundsAdded(id, sender, uint96(amount));
  }

  /**
   * @notice removes funding from a canceled upkeep
   * @param id upkeep to withdraw funds from
   * @param to destination address for sending remaining funds
   */
  function withdrawFunds(uint256 id, address to) external validateRecipient(to) {
    require(s_upkeep[id].admin == msg.sender, "only callable by admin");
    require(s_upkeep[id].maxValidBlocknumber <= block.number, "upkeep must be canceled");

    uint256 amount = s_upkeep[id].balance;
    s_upkeep[id].balance = 0;
    s_expectedLinkBalance = s_expectedLinkBalance.sub(amount);
    emit FundsWithdrawn(id, amount, to);

    LINK.transfer(to, amount);
  }

  /**
   * @notice recovers LINK funds improperly transfered to the registry
   * @dev In principle this function’s execution cost could exceed block
   * gaslimit. However, in our anticipated deployment, the number of upkeeps and
   * keepers will be low enough to avoid this problem.
   */
  function recoverFunds() external onlyOwner {
    uint256 total = LINK.balanceOf(address(this));
    LINK.transfer(msg.sender, total.sub(s_expectedLinkBalance));
  }

  /**
   * @notice withdraws a keeper's payment, callable only by the keeper's payee
   * @param from keeper address
   * @param to address to send the payment to
   */
  function withdrawPayment(address from, address to) external validateRecipient(to) {
    KeeperInfo memory keeper = s_keeperInfo[from];
    require(keeper.payee == msg.sender, "only callable by payee");

    s_keeperInfo[from].balance = 0;
    s_expectedLinkBalance = s_expectedLinkBalance.sub(keeper.balance);
    emit PaymentWithdrawn(from, keeper.balance, to, msg.sender);

    LINK.transfer(to, keeper.balance);
  }

  /**
   * @notice proposes the safe transfer of a keeper's payee to another address
   * @param keeper address of the keeper to transfer payee role
   * @param proposed address to nominate for next payeeship
   */
  function transferPayeeship(address keeper, address proposed) external {
    require(s_keeperInfo[keeper].payee == msg.sender, "only callable by payee");
    require(proposed != msg.sender, "cannot transfer to self");

    if (s_proposedPayee[keeper] != proposed) {
      s_proposedPayee[keeper] = proposed;
      emit PayeeshipTransferRequested(keeper, msg.sender, proposed);
    }
  }

  /**
   * @notice accepts the safe transfer of payee role for a keeper
   * @param keeper address to accept the payee role for
   */
  function acceptPayeeship(address keeper) external {
    require(s_proposedPayee[keeper] == msg.sender, "only callable by proposed payee");
    address past = s_keeperInfo[keeper].payee;
    s_keeperInfo[keeper].payee = msg.sender;
    s_proposedPayee[keeper] = ZERO_ADDRESS;

    emit PayeeshipTransferred(keeper, past, msg.sender);
  }

  /**
   * @notice signals to keepers that they should not perform upkeeps until the
   * contract has been unpaused
   */
  function pause() external onlyOwner {
    _pause();
  }

  /**
   * @notice signals to keepers that they can perform upkeeps once again after
   * having been paused
   */
  function unpause() external onlyOwner {
    _unpause();
  }

  // SETTERS

  /**
   * @notice updates the configuration of the registry
   * @param paymentPremiumPPB payment premium rate oracles receive on top of
   * being reimbursed for gas, measured in parts per billion
   * @param flatFeeMicroLink flat fee paid to oracles for performing upkeeps
   * @param blockCountPerTurn number of blocks an oracle should wait before
   * checking for upkeep
   * @param checkGasLimit gas limit when checking for upkeep
   * @param stalenessSeconds number of seconds that is allowed for feed data to
   * be stale before switching to the fallback pricing
   * @param fallbackGasPrice gas price used if the gas price feed is stale
   * @param fallbackLinkPrice LINK price used if the LINK price feed is stale
   */
  function setConfig(
    uint32 paymentPremiumPPB,
    uint32 flatFeeMicroLink,
    uint24 blockCountPerTurn,
    uint32 checkGasLimit,
    uint24 stalenessSeconds,
    uint16 gasCeilingMultiplier,
    uint256 fallbackGasPrice,
    uint256 fallbackLinkPrice
  ) public onlyOwner {
    s_config = Config({
      paymentPremiumPPB: paymentPremiumPPB,
      flatFeeMicroLink: flatFeeMicroLink,
      blockCountPerTurn: blockCountPerTurn,
      checkGasLimit: checkGasLimit,
      stalenessSeconds: stalenessSeconds,
      gasCeilingMultiplier: gasCeilingMultiplier
    });
    s_fallbackGasPrice = fallbackGasPrice;
    s_fallbackLinkPrice = fallbackLinkPrice;

    emit ConfigSet(
      paymentPremiumPPB,
      blockCountPerTurn,
      checkGasLimit,
      stalenessSeconds,
      gasCeilingMultiplier,
      fallbackGasPrice,
      fallbackLinkPrice
    );
    emit FlatFeeSet(flatFeeMicroLink);
  }

  /**
   * @notice update the list of keepers allowed to perform upkeep
   * @param keepers list of addresses allowed to perform upkeep
   * @param payees addreses corresponding to keepers who are allowed to
   * move payments which have been accrued
   */
  function setKeepers(address[] calldata keepers, address[] calldata payees) external onlyOwner {
    require(keepers.length == payees.length, "address lists not the same length");
    require(keepers.length >= 2, "not enough keepers");
    for (uint256 i = 0; i < s_keeperList.length; i++) {
      address keeper = s_keeperList[i];
      s_keeperInfo[keeper].active = false;
    }
    for (uint256 i = 0; i < keepers.length; i++) {
      address keeper = keepers[i];
      KeeperInfo storage s_keeper = s_keeperInfo[keeper];
      address oldPayee = s_keeper.payee;
      address newPayee = payees[i];
      require(newPayee != address(0), "cannot set payee to the zero address");
      require(oldPayee == ZERO_ADDRESS || oldPayee == newPayee || newPayee == IGNORE_ADDRESS, "cannot change payee");
      require(!s_keeper.active, "cannot add keeper twice");
      s_keeper.active = true;
      if (newPayee != IGNORE_ADDRESS) {
        s_keeper.payee = newPayee;
      }
    }
    s_keeperList = keepers;
    emit KeepersUpdated(keepers, payees);
  }

  /**
   * @notice update registrar
   * @param registrar new registrar
   */
  function setRegistrar(address registrar) external onlyOwnerOrRegistrar {
    address previous = s_registrar;
    require(registrar != previous, "Same registrar");
    s_registrar = registrar;
    emit RegistrarChanged(previous, registrar);
  }

  // GETTERS

  /**
   * @notice read all of the details about an upkeep
   */
  function getUpkeep(uint256 id)
    external
    view
    override
    returns (
      address target,
      uint32 executeGas,
      bytes memory checkData,
      uint96 balance,
      address lastKeeper,
      address admin,
      uint64 maxValidBlocknumber
    )
  {
    Upkeep memory reg = s_upkeep[id];
    return (
      reg.target,
      reg.executeGas,
      s_checkData[id],
      reg.balance,
      reg.lastKeeper,
      reg.admin,
      reg.maxValidBlocknumber
    );
  }

  /**
   * @notice read the total number of upkeep's registered
   */
  function getUpkeepCount() external view override returns (uint256) {
    return s_upkeepCount;
  }

  /**
   * @notice read the current list canceled upkeep IDs
   */
  function getCanceledUpkeepList() external view override returns (uint256[] memory) {
    return s_canceledUpkeepList;
  }

  /**
   * @notice read the current list of addresses allowed to perform upkeep
   */
  function getKeeperList() external view override returns (address[] memory) {
    return s_keeperList;
  }

  /**
   * @notice read the current registrar
   */
  function getRegistrar() external view returns (address) {
    return s_registrar;
  }

  /**
   * @notice read the current info about any keeper address
   */
  function getKeeperInfo(address query)
    external
    view
    override
    returns (
      address payee,
      bool active,
      uint96 balance
    )
  {
    KeeperInfo memory keeper = s_keeperInfo[query];
    return (keeper.payee, keeper.active, keeper.balance);
  }

  /**
   * @notice read the current configuration of the registry
   */
  function getConfig()
    external
    view
    override
    returns (
      uint32 paymentPremiumPPB,
      uint24 blockCountPerTurn,
      uint32 checkGasLimit,
      uint24 stalenessSeconds,
      uint16 gasCeilingMultiplier,
      uint256 fallbackGasPrice,
      uint256 fallbackLinkPrice
    )
  {
    Config memory config = s_config;
    return (
      config.paymentPremiumPPB,
      config.blockCountPerTurn,
      config.checkGasLimit,
      config.stalenessSeconds,
      config.gasCeilingMultiplier,
      s_fallbackGasPrice,
      s_fallbackLinkPrice
    );
  }

  /**
   * @notice getFlatFee gets the flat rate fee charged to customers when performing upkeep,
   * in units of of micro LINK
   */
  function getFlatFee() external view returns (uint32) {
    return s_config.flatFeeMicroLink;
  }

  /**
   * @notice calculates the minimum balance required for an upkeep to remain eligible
   */
  function getMinBalanceForUpkeep(uint256 id) external view returns (uint96 minBalance) {
    return getMaxPaymentForGas(s_upkeep[id].executeGas);
  }

  /**
   * @notice calculates the maximum payment for a given gas limit
   */
  function getMaxPaymentForGas(uint256 gasLimit) public view returns (uint96 maxPayment) {
    (uint256 gasWei, uint256 linkEth) = getFeedData();
    uint256 adjustedGasWei = adjustGasPrice(gasWei, false);
    return calculatePaymentAmount(gasLimit, adjustedGasWei, linkEth);
  }

  // PRIVATE

  /**
   * @dev retrieves feed data for fast gas/eth and link/eth prices. if the feed
   * data is stale it uses the configured fallback price. Once a price is picked
   * for gas it takes the min of gas price in the transaction or the fast gas
   * price in order to reduce costs for the upkeep clients.
   */
  function getFeedData() private view returns (uint256 gasWei, uint256 linkEth) {
    uint32 stalenessSeconds = s_config.stalenessSeconds;
    bool staleFallback = stalenessSeconds > 0;
    uint256 timestamp;
    int256 feedValue;
    (, feedValue, , timestamp, ) = FAST_GAS_FEED.latestRoundData();
    if ((staleFallback && stalenessSeconds < block.timestamp - timestamp) || feedValue <= 0) {
      gasWei = s_fallbackGasPrice;
    } else {
      gasWei = uint256(feedValue);
    }
    (, feedValue, , timestamp, ) = LINK_ETH_FEED.latestRoundData();
    if ((staleFallback && stalenessSeconds < block.timestamp - timestamp) || feedValue <= 0) {
      linkEth = s_fallbackLinkPrice;
    } else {
      linkEth = uint256(feedValue);
    }
    return (gasWei, linkEth);
  }

  /**
   * @dev calculates LINK paid for gas spent plus a configure premium percentage
   */
  function calculatePaymentAmount(
    uint256 gasLimit,
    uint256 gasWei,
    uint256 linkEth
  ) private view returns (uint96 payment) {
    Config memory config = s_config;
    uint256 weiForGas = gasWei.mul(gasLimit.add(REGISTRY_GAS_OVERHEAD));
    uint256 premium = PPB_BASE.add(config.paymentPremiumPPB);
    uint256 total = weiForGas.mul(1e9).mul(premium).div(linkEth).add(uint256(config.flatFeeMicroLink).mul(1e12));
    require(total <= LINK_TOTAL_SUPPLY, "payment greater than all LINK");
    return uint96(total); // LINK_TOTAL_SUPPLY < UINT96_MAX
  }

  /**
   * @dev calls target address with exactly gasAmount gas and data as calldata
   * or reverts if at least gasAmount gas is not available
   */
  function callWithExactGas(
    uint256 gasAmount,
    address target,
    bytes memory data
  ) private returns (bool success) {
    assembly {
      let g := gas()
      // Compute g -= CUSHION and check for underflow
      if lt(g, CUSHION) {
        revert(0, 0)
      }
      g := sub(g, CUSHION)
      // if g - g//64 <= gasAmount, revert
      // (we subtract g//64 because of EIP-150)
      if iszero(gt(sub(g, div(g, 64)), gasAmount)) {
        revert(0, 0)
      }
      // solidity calls check that a contract actually exists at the destination, so we do the same
      if iszero(extcodesize(target)) {
        revert(0, 0)
      }
      // call and return whether we succeeded. ignore return data
      success := call(gasAmount, target, 0, add(data, 0x20), mload(data), 0, 0)
    }
    return success;
  }

  /**
   * @dev calls the Upkeep target with the performData param passed in by the
   * keeper and the exact gas required by the Upkeep
   */
  function performUpkeepWithParams(PerformParams memory params)
    private
    nonReentrant
    validUpkeep(params.id)
    returns (bool success)
  {
    require(s_keeperInfo[params.from].active, "only active keepers");
    Upkeep memory upkeep = s_upkeep[params.id];
    require(upkeep.balance >= params.maxLinkPayment, "insufficient funds");
    require(upkeep.lastKeeper != params.from, "keepers must take turns");

    uint256 gasUsed = gasleft();
    bytes memory callData = abi.encodeWithSelector(PERFORM_SELECTOR, params.performData);
    success = callWithExactGas(params.gasLimit, upkeep.target, callData);
    gasUsed = gasUsed - gasleft();

    uint96 payment = calculatePaymentAmount(gasUsed, params.adjustedGasWei, params.linkEth);
    upkeep.balance = upkeep.balance.sub(payment);
    upkeep.lastKeeper = params.from;
    s_upkeep[params.id] = upkeep;
    uint96 newBalance = s_keeperInfo[params.from].balance.add(payment);
    s_keeperInfo[params.from].balance = newBalance;

    emit UpkeepPerformed(params.id, success, params.from, payment, params.performData);
    return success;
  }

  /**
   * @dev ensures a upkeep is valid
   */
  function validateUpkeep(uint256 id) private view {
    require(s_upkeep[id].maxValidBlocknumber > block.number, "invalid upkeep id");
  }

  /**
   * @dev adjusts the gas price to min(ceiling, tx.gasprice) or just uses the ceiling if tx.gasprice is disabled
   */
  function adjustGasPrice(uint256 gasWei, bool useTxGasPrice) private view returns (uint256 adjustedPrice) {
    adjustedPrice = gasWei.mul(s_config.gasCeilingMultiplier);
    if (useTxGasPrice && tx.gasprice < adjustedPrice) {
      adjustedPrice = tx.gasprice;
    }
  }

  /**
   * @dev generates a PerformParams struct for use in performUpkeepWithParams()
   */
  function generatePerformParams(
    address from,
    uint256 id,
    bytes memory performData,
    bool useTxGasPrice
  ) private view returns (PerformParams memory) {
    uint256 gasLimit = s_upkeep[id].executeGas;
    (uint256 gasWei, uint256 linkEth) = getFeedData();
    uint256 adjustedGasWei = adjustGasPrice(gasWei, useTxGasPrice);
    uint96 maxLinkPayment = calculatePaymentAmount(gasLimit, adjustedGasWei, linkEth);

    return
      PerformParams({
        from: from,
        id: id,
        performData: performData,
        maxLinkPayment: maxLinkPayment,
        gasLimit: gasLimit,
        adjustedGasWei: adjustedGasWei,
        linkEth: linkEth
      });
  }

  /**
   * @dev extracts a revert reason from a call result payload
   */
  function getRevertMsg(bytes memory _payload) private pure returns (string memory) {
    if (_payload.length < 68) return "transaction reverted silently";
    assembly {
      _payload := add(_payload, 0x04)
    }
    return abi.decode(_payload, (string));
  }

  // MODIFIERS

  /**
   * @dev ensures a upkeep is valid
   */
  modifier validUpkeep(uint256 id) {
    validateUpkeep(id);
    _;
  }

  /**
   * @dev ensures that burns don't accidentally happen by sending to the zero
   * address
   */
  modifier validateRecipient(address to) {
    require(to != address(0), "cannot send to zero address");
    _;
  }

  /**
   * @dev Reverts if called by anyone other than the contract owner or registrar.
   */
  modifier onlyOwnerOrRegistrar() {
    require(msg.sender == owner() || msg.sender == s_registrar, "Only callable by owner or registrar");
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

interface KeeperCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easilly be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

abstract contract TypeAndVersionInterface {
  function typeAndVersion() external pure virtual returns (string memory);
}

// SPDX-License-Identifier: MIT
// github.com/OpenZeppelin/[email protected]

pragma solidity ^0.7.0;

import "./Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
  /**
   * @dev Emitted when the pause is triggered by `account`.
   */
  event Paused(address account);

  /**
   * @dev Emitted when the pause is lifted by `account`.
   */
  event Unpaused(address account);

  bool private _paused;

  /**
   * @dev Initializes the contract in unpaused state.
   */
  constructor() {
    _paused = false;
  }

  /**
   * @dev Returns true if the contract is paused, and false otherwise.
   */
  function paused() public view virtual returns (bool) {
    return _paused;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   *
   * Requirements:
   *
   * - The contract must not be paused.
   */
  modifier whenNotPaused() {
    require(!paused(), "Pausable: paused");
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   *
   * Requirements:
   *
   * - The contract must be paused.
   */
  modifier whenPaused() {
    require(paused(), "Pausable: not paused");
    _;
  }

  /**
   * @dev Triggers stopped state.
   *
   * Requirements:
   *
   * - The contract must not be paused.
   */
  function _pause() internal virtual whenNotPaused {
    _paused = true;
    emit Paused(_msgSender());
  }

  /**
   * @dev Returns to normal state.
   *
   * Requirements:
   *
   * - The contract must be paused.
   */
  function _unpause() internal virtual whenPaused {
    _paused = false;
    emit Unpaused(_msgSender());
  }
}

// SPDX-License-Identifier: MIT
// github.com/OpenZeppelin/[email protected]

pragma solidity ^0.7.0;

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
abstract contract ReentrancyGuard {
  // Booleans are more expensive than uint256 or any type that takes up a full
  // word because each write operation emits an extra SLOAD to first read the
  // slot's contents, replace the bits taken up by the boolean, and then write
  // back. This is the compiler's defense against contract upgrades and
  // pointer aliasing, and it cannot be disabled.

  // The values being non-zero value makes deployment a bit more expensive,
  // but in exchange the refund on every call to nonReentrant will be lower in
  // amount. Since refunds are capped to a percentage of the total
  // transaction's gas, it is best to keep them low in cases like this one, to
  // increase the likelihood of the full refund coming into effect.
  uint256 private constant _NOT_ENTERED = 1;
  uint256 private constant _ENTERED = 2;

  uint256 private _status;

  constructor() {
    _status = _NOT_ENTERED;
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
    require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

    // Any calls to nonReentrant after this point will fail
    _status = _ENTERED;

    _;

    // By storing the original value once again, a refund is triggered (see
    // https://eips.ethereum.org/EIPS/eip-2200)
    _status = _NOT_ENTERED;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @title SignedSafeMath
 * @dev Signed math operations with safety checks that revert on error.
 */
library SignedSafeMath {
  int256 private constant _INT256_MIN = -2**255;

  /**
   * @dev Returns the multiplication of two signed integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `*` operator.
   *
   * Requirements:
   *
   * - Multiplication cannot overflow.
   */
  function mul(int256 a, int256 b) internal pure returns (int256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
    if (a == 0) {
      return 0;
    }

    require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

    int256 c = a * b;
    require(c / a == b, "SignedSafeMath: multiplication overflow");

    return c;
  }

  /**
   * @dev Returns the integer division of two signed integers. Reverts on
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
  function div(int256 a, int256 b) internal pure returns (int256) {
    require(b != 0, "SignedSafeMath: division by zero");
    require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

    int256 c = a / b;

    return c;
  }

  /**
   * @dev Returns the subtraction of two signed integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   *
   * - Subtraction cannot overflow.
   */
  function sub(int256 a, int256 b) internal pure returns (int256) {
    int256 c = a - b;
    require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

    return c;
  }

  /**
   * @dev Returns the addition of two signed integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `+` operator.
   *
   * Requirements:
   *
   * - Addition cannot overflow.
   */
  function add(int256 a, int256 b) internal pure returns (int256) {
    int256 c = a + b;
    require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

    return c;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract KeeperBase {
  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    require(tx.origin == address(0), "only for simulated backend");
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}

// SPDX-License-Identifier: MIT
// github.com/OpenZeppelin/[email protected]

pragma solidity ^0.7.0;

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
    this;
    // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./KeeperBase.sol";
import "./interfaces/KeeperCompatibleInterface.sol";

abstract contract KeeperCompatible is KeeperBase, KeeperCompatibleInterface {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "../KeeperCompatible.sol";

contract UpkeepReverter is KeeperCompatible {
  function checkUpkeep(bytes calldata data)
    public
    view
    override
    cannotExecute
    returns (bool callable, bytes calldata executedata)
  {
    require(false, "!working");
    return (true, data);
  }

  function performUpkeep(bytes calldata) external pure override {
    require(false, "!working");
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "../KeeperCompatible.sol";

contract UpkeepMock is KeeperCompatible {
  bool public canCheck;
  bool public canPerform;
  uint256 public checkGasToBurn;
  uint256 public performGasToBurn;

  uint256 constant gasBuffer = 1000; // use all but this amount in gas burn loops

  event UpkeepPerformedWith(bytes upkeepData);

  function setCanCheck(bool value) public {
    canCheck = value;
  }

  function setCanPerform(bool value) public {
    canPerform = value;
  }

  function setCheckGasToBurn(uint256 value) public {
    require(value > gasBuffer || value == 0, "checkGasToBurn must be 0 (disabled) or greater than buffer");
    checkGasToBurn = value - gasBuffer;
  }

  function setPerformGasToBurn(uint256 value) public {
    require(value > gasBuffer || value == 0, "performGasToBurn must be 0 (disabled) or greater than buffer");
    performGasToBurn = value - gasBuffer;
  }

  function checkUpkeep(bytes calldata data)
    external
    override
    cannotExecute
    returns (bool callable, bytes calldata executedata)
  {
    uint256 startGas = gasleft();
    bool couldCheck = canCheck;

    setCanCheck(false); // test that state modifcations don't stick

    while (startGas - gasleft() < checkGasToBurn) {} // burn gas

    return (couldCheck, data);
  }

  function performUpkeep(bytes calldata data) external override {
    uint256 startGas = gasleft();

    require(canPerform, "Cannot perform");

    setCanPerform(false);

    emit UpkeepPerformedWith(data);

    while (startGas - gasleft() < performGasToBurn) {} // burn gas
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "../ConfirmedOwner.sol";
import "../vendor/SafeMathChainlink.sol";
import "../interfaces/FlagsInterface.sol";
import "../interfaces/AggregatorV3Interface.sol";
import "../interfaces/KeeperCompatibleInterface.sol";

contract StalenessFlaggingValidator is ConfirmedOwner, KeeperCompatibleInterface {
  using SafeMathChainlink for uint256;

  FlagsInterface private s_flags;
  mapping(address => uint256) private s_thresholdSeconds;

  event FlagsAddressUpdated(address indexed previous, address indexed current);
  event FlaggingThresholdUpdated(address indexed aggregator, uint256 indexed previous, uint256 indexed current);

  /**
   * @notice Create a new StalenessFlaggingValidator
   * @param flagsAddress Address of the flag contract
   * @dev Ensure that this contract has sufficient write permissions
   * on the flag contract
   */
  constructor(address flagsAddress) ConfirmedOwner(msg.sender) {
    setFlagsAddress(flagsAddress);
  }

  /**
   * @notice Updates the flagging contract address for raising flags
   * @param flagsAddress sets the address of the flags contract
   */
  function setFlagsAddress(address flagsAddress) public onlyOwner {
    address previous = address(s_flags);
    if (previous != flagsAddress) {
      s_flags = FlagsInterface(flagsAddress);
      emit FlagsAddressUpdated(previous, flagsAddress);
    }
  }

  /**
   * @notice Set the threshold limits for each aggregator
   * @dev parameters must be same length
   * @param aggregators address[] memory
   * @param flaggingThresholds uint256[] memory
   */
  function setThresholds(address[] memory aggregators, uint256[] memory flaggingThresholds) public onlyOwner {
    require(aggregators.length == flaggingThresholds.length, "Different sized arrays");
    for (uint256 i = 0; i < aggregators.length; i++) {
      address aggregator = aggregators[i];
      uint256 previousThreshold = s_thresholdSeconds[aggregator];
      uint256 newThreshold = flaggingThresholds[i];
      if (previousThreshold != newThreshold) {
        s_thresholdSeconds[aggregator] = newThreshold;
        emit FlaggingThresholdUpdated(aggregator, previousThreshold, newThreshold);
      }
    }
  }

  /**
   * @notice Check for staleness in an array of aggregators
   * @dev If any of the aggregators are stale, this function will return true,
   * otherwise false
   * @param aggregators address[] memory
   * @return address[] memory stale aggregators
   */
  function check(address[] memory aggregators) public view returns (address[] memory) {
    uint256 currentTimestamp = block.timestamp;
    address[] memory staleAggregators = new address[](aggregators.length);
    uint256 staleCount = 0;
    for (uint256 i = 0; i < aggregators.length; i++) {
      address aggregator = aggregators[i];
      if (isStale(aggregator, currentTimestamp)) {
        staleAggregators[staleCount] = aggregator;
        staleCount++;
      }
    }

    if (aggregators.length != staleCount) {
      assembly {
        mstore(staleAggregators, staleCount)
      }
    }
    return staleAggregators;
  }

  /**
   * @notice Check for staleness in an array of aggregators, raise a flag
   * on the flags contract for each aggregator that is stale
   * @dev This contract must have write permissions on the flags contract
   * @param aggregators address[] memory
   * @return address[] memory stale aggregators
   */
  function update(address[] memory aggregators) public returns (address[] memory) {
    address[] memory staleAggregators = check(aggregators);
    s_flags.raiseFlags(staleAggregators);
    return staleAggregators;
  }

  /**
   * @notice Check for staleness in an array of aggregators
   * @dev Overriding KeeperInterface
   * @param data bytes encoded address array
   * @return needsUpkeep bool indicating whether upkeep needs to be performed
   * @return staleAggregators bytes encoded address array of stale aggregator addresses
   */
  function checkUpkeep(bytes calldata data) external view override returns (bool, bytes memory) {
    address[] memory staleAggregators = check(abi.decode(data, (address[])));
    bool needsUpkeep = (staleAggregators.length > 0);
    return (needsUpkeep, abi.encode(staleAggregators));
  }

  /**
   * @notice Check for staleness in an array of aggregators, raise a flag
   * on the flags contract for each aggregator that is stale
   * @dev Overriding KeeperInterface
   * @param data bytes encoded address array
   */
  function performUpkeep(bytes calldata data) external override {
    update(abi.decode(data, (address[])));
  }

  /**
   * @notice Get the threshold of an aggregator
   * @param aggregator address
   * @return uint256
   */
  function threshold(address aggregator) external view returns (uint256) {
    return s_thresholdSeconds[aggregator];
  }

  /**
   * @notice Get the flags address
   * @return address
   */
  function flags() external view returns (address) {
    return address(s_flags);
  }

  /**
   * @notice Check if an aggregator is stale.
   * @dev Staleness is where an aggregator's `updatedAt` field is older
   * than the threshold set for it in this contract
   * @param aggregator address
   * @param currentTimestamp uint256
   * @return stale bool
   */
  function isStale(address aggregator, uint256 currentTimestamp) private view returns (bool stale) {
    if (s_thresholdSeconds[aggregator] == 0) {
      return false;
    }
    (, , , uint256 updatedAt, ) = AggregatorV3Interface(aggregator).latestRoundData();
    uint256 diff = currentTimestamp.sub(updatedAt);
    if (diff > s_thresholdSeconds[aggregator]) {
      return true;
    }
    return false;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface FlagsInterface {
  function getFlag(address) external view returns (bool);

  function getFlags(address[] calldata) external view returns (bool[] memory);

  function raiseFlag(address) external;

  function raiseFlags(address[] calldata) external;

  function lowerFlags(address[] calldata) external;

  function setRaisingAccessController(address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "../ConfirmedOwner.sol";
import "../vendor/SafeMathChainlink.sol";
import "../interfaces/FlagsInterface.sol";
import "../interfaces/AggregatorV3Interface.sol";
import "../interfaces/UniswapAnchoredView.sol";
import "../interfaces/KeeperCompatibleInterface.sol";

/**
 * @notice This validator compares the price of Chainlink aggregators against
 * their equivalent Compound Open Oracle feeds. For each aggregator, a Compound
 * feed is configured with its symbol, number of decimals, and deviation threshold.
 * An aggregator address is flagged when its corresponding Compound feed price deviates
 * by more than the configured threshold from the aggregator price.
 */
contract CompoundPriceFlaggingValidator is ConfirmedOwner, KeeperCompatibleInterface {
  using SafeMathChainlink for uint256;

  struct CompoundFeedDetails {
    // Used to call the Compound Open Oracle
    string symbol;
    // Used to convert price to match aggregator decimals
    uint8 decimals;
    // The numerator used to determine the threshold percentage
    // as parts per billion.
    // 1,000,000,000 = 100%
    //   500,000,000 = 50%
    //   100,000,000 = 10%
    //    50,000,000 = 5%
    //    10,000,000 = 1%
    //     2,000,000 = 0.2%
    //                 etc
    uint32 deviationThresholdNumerator;
  }

  uint256 private constant BILLION = 1_000_000_000;

  FlagsInterface private s_flags;
  UniswapAnchoredView private s_compOpenOracle;
  mapping(address => CompoundFeedDetails) private s_feedDetails;

  event CompoundOpenOracleAddressUpdated(address indexed from, address indexed to);
  event FlagsAddressUpdated(address indexed from, address indexed to);
  event FeedDetailsSet(address indexed aggregator, string symbol, uint8 decimals, uint32 deviationThresholdNumerator);

  /**
   * @notice Create a new CompoundPriceFlaggingValidator
   * @dev Use this contract to compare Chainlink aggregator prices
   * against the Compound Open Oracle prices
   * @param flagsAddress Address of the flag contract
   * @param compoundOracleAddress Address of the Compound Open Oracle UniswapAnchoredView contract
   */
  constructor(address flagsAddress, address compoundOracleAddress) ConfirmedOwner(msg.sender) {
    setFlagsAddress(flagsAddress);
    setCompoundOpenOracleAddress(compoundOracleAddress);
  }

  /**
   * @notice Set the address of the Compound Open Oracle UniswapAnchoredView contract
   * @param oracleAddress Compound Open Oracle UniswapAnchoredView address
   */
  function setCompoundOpenOracleAddress(address oracleAddress) public onlyOwner {
    address previous = address(s_compOpenOracle);
    if (previous != oracleAddress) {
      s_compOpenOracle = UniswapAnchoredView(oracleAddress);
      emit CompoundOpenOracleAddressUpdated(previous, oracleAddress);
    }
  }

  /**
   * @notice Updates the flagging contract address for raising flags
   * @param flagsAddress sets the address of the flags contract
   */
  function setFlagsAddress(address flagsAddress) public onlyOwner {
    address previous = address(s_flags);
    if (previous != flagsAddress) {
      s_flags = FlagsInterface(flagsAddress);
      emit FlagsAddressUpdated(previous, flagsAddress);
    }
  }

  /**
   * @notice Set the threshold details for comparing a Chainlink aggregator
   * to a Compound Open Oracle feed.
   * @param aggregator The Chainlink aggregator address
   * @param compoundSymbol The symbol used by Compound for this feed
   * @param compoundDecimals The number of decimals in the Compound feed
   * @param compoundDeviationThresholdNumerator The threshold numerator use to determine
   * the percentage with which the difference in prices must reside within. Parts per billion.
   *   For example:
   *     If prices are valid within a 5% threshold, assuming x is the compoundDeviationThresholdNumerator:
   *     x / 1,000,000,000 = 0.05
   *     x = 50,000,000
   */
  function setFeedDetails(
    address aggregator,
    string calldata compoundSymbol,
    uint8 compoundDecimals,
    uint32 compoundDeviationThresholdNumerator
  ) public onlyOwner {
    require(
      compoundDeviationThresholdNumerator > 0 && compoundDeviationThresholdNumerator <= BILLION,
      "Invalid threshold numerator"
    );
    require(_compoundPriceOf(compoundSymbol) != 0, "Invalid Compound price");
    string memory currentSymbol = s_feedDetails[aggregator].symbol;
    // If symbol is not set, use the new one
    if (bytes(currentSymbol).length == 0) {
      s_feedDetails[aggregator] = CompoundFeedDetails({
        symbol: compoundSymbol,
        decimals: compoundDecimals,
        deviationThresholdNumerator: compoundDeviationThresholdNumerator
      });
      emit FeedDetailsSet(aggregator, compoundSymbol, compoundDecimals, compoundDeviationThresholdNumerator);
    }
    // If the symbol is already set, don't change it
    else {
      s_feedDetails[aggregator] = CompoundFeedDetails({
        symbol: currentSymbol,
        decimals: compoundDecimals,
        deviationThresholdNumerator: compoundDeviationThresholdNumerator
      });
      emit FeedDetailsSet(aggregator, currentSymbol, compoundDecimals, compoundDeviationThresholdNumerator);
    }
  }

  /**
   * @notice Check the price deviation of an array of aggregators
   * @dev If any of the aggregators provided have an equivalent Compound Oracle feed
   * that with a price outside of the configured deviation, this function will return them.
   * @param aggregators address[] memory
   * @return address[] invalid feeds
   */
  function check(address[] memory aggregators) public view returns (address[] memory) {
    address[] memory invalidAggregators = new address[](aggregators.length);
    uint256 invalidCount = 0;
    for (uint256 i = 0; i < aggregators.length; i++) {
      address aggregator = aggregators[i];
      if (_isInvalid(aggregator)) {
        invalidAggregators[invalidCount] = aggregator;
        invalidCount++;
      }
    }

    if (aggregators.length != invalidCount) {
      assembly {
        mstore(invalidAggregators, invalidCount)
      }
    }
    return invalidAggregators;
  }

  /**
   * @notice Check and raise flags for any aggregator that has an equivalent Compound
   * Open Oracle feed with a price deviation exceeding the configured setting.
   * @dev This contract must have write permissions on the Flags contract
   * @param aggregators address[] memory
   * @return address[] memory invalid aggregators
   */
  function update(address[] memory aggregators) public returns (address[] memory) {
    address[] memory invalidAggregators = check(aggregators);
    s_flags.raiseFlags(invalidAggregators);
    return invalidAggregators;
  }

  /**
   * @notice Check the price deviation of an array of aggregators
   * @dev If any of the aggregators provided have an equivalent Compound Oracle feed
   * that with a price outside of the configured deviation, this function will return them.
   * @param data bytes encoded address array
   * @return needsUpkeep bool indicating whether upkeep needs to be performed
   * @return invalid aggregators - bytes encoded address array of invalid aggregator addresses
   */
  function checkUpkeep(bytes calldata data) external view override returns (bool, bytes memory) {
    address[] memory invalidAggregators = check(abi.decode(data, (address[])));
    bool needsUpkeep = (invalidAggregators.length > 0);
    return (needsUpkeep, abi.encode(invalidAggregators));
  }

  /**
   * @notice Check and raise flags for any aggregator that has an equivalent Compound
   * Open Oracle feed with a price deviation exceeding the configured setting.
   * @dev This contract must have write permissions on the Flags contract
   * @param data bytes encoded address array
   */
  function performUpkeep(bytes calldata data) external override {
    update(abi.decode(data, (address[])));
  }

  /**
   * @notice Get the threshold of an aggregator
   * @param aggregator address
   * @return string Compound Oracle Symbol
   * @return uint8 Compound Oracle Decimals
   * @return uint32 Deviation Threshold Numerator
   */
  function getFeedDetails(address aggregator)
    public
    view
    returns (
      string memory,
      uint8,
      uint32
    )
  {
    CompoundFeedDetails memory compDetails = s_feedDetails[aggregator];
    return (compDetails.symbol, compDetails.decimals, compDetails.deviationThresholdNumerator);
  }

  /**
   * @notice Get the flags address
   * @return address
   */
  function flags() external view returns (address) {
    return address(s_flags);
  }

  /**
   * @notice Get the Compound Open Oracle address
   * @return address
   */
  function compoundOpenOracle() external view returns (address) {
    return address(s_compOpenOracle);
  }

  /**
   * @notice Return the Compound oracle price of an asset using its symbol
   * @param symbol string
   * @return price uint256
   */
  function _compoundPriceOf(string memory symbol) private view returns (uint256) {
    return s_compOpenOracle.price(symbol);
  }

  // VALIDATION FUNCTIONS

  /**
   * @notice Check if an aggregator has an equivalent Compound Oracle feed
   * that's price is deviated more than the threshold.
   * @param aggregator address of the Chainlink aggregator
   * @return invalid bool. True if the deviation exceeds threshold.
   */
  function _isInvalid(address aggregator) private view returns (bool invalid) {
    CompoundFeedDetails memory compDetails = s_feedDetails[aggregator];
    if (compDetails.deviationThresholdNumerator == 0) {
      return false;
    }
    // Get both oracle price details
    uint256 compPrice = _compoundPriceOf(compDetails.symbol);
    (uint256 aggregatorPrice, uint8 aggregatorDecimals) = _aggregatorValues(aggregator);

    // Adjust the prices so the number of decimals in each align
    (aggregatorPrice, compPrice) = _adjustPriceDecimals(
      aggregatorPrice,
      aggregatorDecimals,
      compPrice,
      compDetails.decimals
    );

    // Check whether the prices deviate beyond the threshold.
    return _deviatesBeyondThreshold(aggregatorPrice, compPrice, compDetails.deviationThresholdNumerator);
  }

  /**
   * @notice Retrieve the price and the decimals from an Aggregator
   * @param aggregator address
   * @return price uint256
   * @return decimals uint8
   */
  function _aggregatorValues(address aggregator) private view returns (uint256 price, uint8 decimals) {
    AggregatorV3Interface priceFeed = AggregatorV3Interface(aggregator);
    (, int256 signedPrice, , , ) = priceFeed.latestRoundData();
    price = uint256(signedPrice);
    decimals = priceFeed.decimals();
  }

  /**
   * @notice Adjust the price values of the Aggregator and Compound feeds so that
   * their decimal places align. This enables deviation to be calculated.
   * @param aggregatorPrice uint256
   * @param aggregatorDecimals uint8 - decimal places included in the aggregator price
   * @param compoundPrice uint256
   * @param compoundDecimals uint8 - decimal places included in the compound price
   * @return adjustedAggregatorPrice uint256
   * @return adjustedCompoundPrice uint256
   */
  function _adjustPriceDecimals(
    uint256 aggregatorPrice,
    uint8 aggregatorDecimals,
    uint256 compoundPrice,
    uint8 compoundDecimals
  ) private pure returns (uint256 adjustedAggregatorPrice, uint256 adjustedCompoundPrice) {
    if (aggregatorDecimals > compoundDecimals) {
      uint8 diff = aggregatorDecimals - compoundDecimals;
      uint256 multiplier = 10**uint256(diff);
      compoundPrice = compoundPrice * multiplier;
    } else if (aggregatorDecimals < compoundDecimals) {
      uint8 diff = compoundDecimals - aggregatorDecimals;
      uint256 multiplier = 10**uint256(diff);
      aggregatorPrice = aggregatorPrice * multiplier;
    }
    adjustedAggregatorPrice = aggregatorPrice;
    adjustedCompoundPrice = compoundPrice;
  }

  /**
   * @notice Check whether the compound price deviates from the aggregator price
   * beyond the given threshold
   * @dev Prices must be adjusted to match decimals prior to calling this function
   * @param aggregatorPrice uint256
   * @param compPrice uint256
   * @param deviationThresholdNumerator uint32
   * @return beyondThreshold boolean. Returns true if deviation is beyond threshold.
   */
  function _deviatesBeyondThreshold(
    uint256 aggregatorPrice,
    uint256 compPrice,
    uint32 deviationThresholdNumerator
  ) private pure returns (bool beyondThreshold) {
    // Deviation amount threshold from the aggregator price
    uint256 deviationAmountThreshold = aggregatorPrice.mul(deviationThresholdNumerator).div(BILLION);

    // Calculate deviation
    uint256 deviation;
    if (aggregatorPrice > compPrice) {
      deviation = aggregatorPrice.sub(compPrice);
    } else if (aggregatorPrice < compPrice) {
      deviation = compPrice.sub(aggregatorPrice);
    }
    beyondThreshold = (deviation >= deviationAmountThreshold);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

// Compound Finance's oracle interface
interface UniswapAnchoredView {
  function price(string memory symbol) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "../interfaces/UniswapAnchoredView.sol";

contract MockCompoundOracle is UniswapAnchoredView {
  struct OracleDetails {
    uint256 price;
    uint256 decimals;
  }

  mapping(string => OracleDetails) s_oracleDetails;

  function price(string memory symbol) external view override returns (uint256) {
    return s_oracleDetails[symbol].price;
  }

  function setPrice(
    string memory symbol,
    uint256 newPrice,
    uint256 newDecimals
  ) public {
    OracleDetails memory details = s_oracleDetails[symbol];
    details.price = newPrice;
    details.decimals = newDecimals;
    s_oracleDetails[symbol] = details;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./AggregatorInterface.sol";
import "./AggregatorV3Interface.sol";

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);

  function latestTimestamp() external view returns (uint256);

  function latestRound() external view returns (uint256);

  function getAnswer(uint256 roundId) external view returns (int256);

  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);

  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "../interfaces/AggregatorV2V3Interface.sol";

/**
 * @title MockV3Aggregator
 * @notice Based on the FluxAggregator contract
 * @notice Use this contract when you need to test
 * other contract's ability to read data from an
 * aggregator contract, but how the aggregator got
 * its answer is unimportant
 */
contract MockV3Aggregator is AggregatorV2V3Interface {
  uint256 public constant override version = 0;

  uint8 public override decimals;
  int256 public override latestAnswer;
  uint256 public override latestTimestamp;
  uint256 public override latestRound;

  mapping(uint256 => int256) public override getAnswer;
  mapping(uint256 => uint256) public override getTimestamp;
  mapping(uint256 => uint256) private getStartedAt;

  constructor(uint8 _decimals, int256 _initialAnswer) {
    decimals = _decimals;
    updateAnswer(_initialAnswer);
  }

  function updateAnswer(int256 _answer) public {
    latestAnswer = _answer;
    latestTimestamp = block.timestamp;
    latestRound++;
    getAnswer[latestRound] = _answer;
    getTimestamp[latestRound] = block.timestamp;
    getStartedAt[latestRound] = block.timestamp;
  }

  function updateRoundData(
    uint80 _roundId,
    int256 _answer,
    uint256 _timestamp,
    uint256 _startedAt
  ) public {
    latestRound = _roundId;
    latestAnswer = _answer;
    latestTimestamp = _timestamp;
    getAnswer[latestRound] = _answer;
    getTimestamp[latestRound] = _timestamp;
    getStartedAt[latestRound] = _startedAt;
  }

  function getRoundData(uint80 _roundId)
    external
    view
    override
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    return (_roundId, getAnswer[_roundId], getStartedAt[_roundId], getTimestamp[_roundId], _roundId);
  }

  function latestRoundData()
    external
    view
    override
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    return (
      uint80(latestRound),
      getAnswer[latestRound],
      getStartedAt[latestRound],
      getTimestamp[latestRound],
      uint80(latestRound)
    );
  }

  function description() external pure override returns (string memory) {
    return "v0.6/tests/MockV3Aggregator.sol";
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma abicoder v2;

import "./AggregatorV2V3Interface.sol";

interface FeedRegistryInterface {
  struct Phase {
    uint16 phaseId;
    uint80 startingAggregatorRoundId;
    uint80 endingAggregatorRoundId;
  }

  event FeedProposed(
    address indexed asset,
    address indexed denomination,
    address indexed proposedAggregator,
    address currentAggregator,
    address sender
  );
  event FeedConfirmed(
    address indexed asset,
    address indexed denomination,
    address indexed latestAggregator,
    address previousAggregator,
    uint16 nextPhaseId,
    address sender
  );

  // V3 AggregatorV3Interface

  function decimals(address base, address quote) external view returns (uint8);

  function description(address base, address quote) external view returns (string memory);

  function version(address base, address quote) external view returns (uint256);

  function latestRoundData(address base, address quote)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function getRoundData(
    address base,
    address quote,
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  // V2 AggregatorInterface

  function latestAnswer(address base, address quote) external view returns (int256 answer);

  function latestTimestamp(address base, address quote) external view returns (uint256 timestamp);

  function latestRound(address base, address quote) external view returns (uint256 roundId);

  function getAnswer(
    address base,
    address quote,
    uint256 roundId
  ) external view returns (int256 answer);

  function getTimestamp(
    address base,
    address quote,
    uint256 roundId
  ) external view returns (uint256 timestamp);

  // Registry getters

  function getFeed(address base, address quote) external view returns (AggregatorV2V3Interface aggregator);

  function getPhaseFeed(
    address base,
    address quote,
    uint16 phaseId
  ) external view returns (AggregatorV2V3Interface aggregator);

  function isFeedEnabled(address aggregator) external view returns (bool);

  function getPhase(
    address base,
    address quote,
    uint16 phaseId
  ) external view returns (Phase memory phase);

  // Round helpers

  function getRoundFeed(
    address base,
    address quote,
    uint80 roundId
  ) external view returns (AggregatorV2V3Interface aggregator);

  function getPhaseRange(
    address base,
    address quote,
    uint16 phaseId
  ) external view returns (uint80 startingRoundId, uint80 endingRoundId);

  function getPreviousRoundId(
    address base,
    address quote,
    uint80 roundId
  ) external view returns (uint80 previousRoundId);

  function getNextRoundId(
    address base,
    address quote,
    uint80 roundId
  ) external view returns (uint80 nextRoundId);

  // Feed management

  function proposeFeed(
    address base,
    address quote,
    address aggregator
  ) external;

  function confirmFeed(
    address base,
    address quote,
    address aggregator
  ) external;

  // Proposed aggregator

  function getProposedFeed(address base, address quote)
    external
    view
    returns (AggregatorV2V3Interface proposedAggregator);

  function proposedGetRoundData(
    address base,
    address quote,
    uint80 roundId
  )
    external
    view
    returns (
      uint80 id,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function proposedLatestRoundData(address base, address quote)
    external
    view
    returns (
      uint80 id,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  // Phases
  function getCurrentPhaseId(address base, address quote) external view returns (uint16 currentPhaseId);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "../interfaces/AggregatorInterface.sol";

/**
 * @title MockV2Aggregator
 * @notice Based on the HistoricAggregator contract
 * @notice Use this contract when you need to test
 * other contract's ability to read data from an
 * aggregator contract, but how the aggregator got
 * its answer is unimportant
 */
contract MockV2Aggregator is AggregatorInterface {
  int256 public override latestAnswer;
  uint256 public override latestTimestamp;
  uint256 public override latestRound;

  mapping(uint256 => int256) public override getAnswer;
  mapping(uint256 => uint256) public override getTimestamp;
  mapping(uint256 => uint256) private getStartedAt;

  constructor(int256 _initialAnswer) public {
    updateAnswer(_initialAnswer);
  }

  function updateAnswer(int256 _answer) public {
    latestAnswer = _answer;
    latestTimestamp = block.timestamp;
    latestRound++;
    getAnswer[latestRound] = _answer;
    getTimestamp[latestRound] = block.timestamp;
  }

  function updateRoundData(
    uint256 _roundId,
    int256 _answer,
    uint256 _timestamp,
    uint256 _startedAt
  ) public {
    latestRound = _roundId;
    latestAnswer = _answer;
    latestTimestamp = _timestamp;
    getAnswer[latestRound] = _answer;
    getTimestamp[latestRound] = _timestamp;
    getStartedAt[latestRound] = _startedAt;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./AggregatorV2V3Interface.sol";

interface AggregatorProxyInterface is AggregatorV2V3Interface {
  function phaseAggregators(uint16 phaseId) external view returns (address);

  function phaseId() external view returns (uint16);

  function proposedAggregator() external view returns (address);

  function proposedGetRoundData(uint80 roundId)
    external
    view
    returns (
      uint80 id,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function proposedLatestRoundData()
    external
    view
    returns (
      uint80 id,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function aggregator() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "../ConfirmedOwner.sol";
import "../interfaces/AggregatorProxyInterface.sol";

/**
 * @title A trusted proxy for updating where current answers are read from
 * @notice This contract provides a consistent address for the
 * CurrentAnwerInterface but delegates where it reads from to the owner, who is
 * trusted to update it.
 */
contract AggregatorProxy is AggregatorProxyInterface, ConfirmedOwner {
  struct Phase {
    uint16 id;
    AggregatorProxyInterface aggregator;
  }
  AggregatorProxyInterface private s_proposedAggregator;
  mapping(uint16 => AggregatorProxyInterface) private s_phaseAggregators;
  Phase private s_currentPhase;

  uint256 private constant PHASE_OFFSET = 64;
  uint256 private constant PHASE_SIZE = 16;
  uint256 private constant MAX_ID = 2**(PHASE_OFFSET + PHASE_SIZE) - 1;

  event AggregatorProposed(address indexed current, address indexed proposed);
  event AggregatorConfirmed(address indexed previous, address indexed latest);

  constructor(address aggregatorAddress) ConfirmedOwner(msg.sender) {
    setAggregator(aggregatorAddress);
  }

  /**
   * @notice Reads the current answer from aggregator delegated to.
   *
   * @dev #[deprecated] Use latestRoundData instead. This does not error if no
   * answer has been reached, it will simply return 0. Either wait to point to
   * an already answered Aggregator or use the recommended latestRoundData
   * instead which includes better verification information.
   */
  function latestAnswer() public view virtual override returns (int256 answer) {
    return s_currentPhase.aggregator.latestAnswer();
  }

  /**
   * @notice Reads the last updated height from aggregator delegated to.
   *
   * @dev #[deprecated] Use latestRoundData instead. This does not error if no
   * answer has been reached, it will simply return 0. Either wait to point to
   * an already answered Aggregator or use the recommended latestRoundData
   * instead which includes better verification information.
   */
  function latestTimestamp() public view virtual override returns (uint256 updatedAt) {
    return s_currentPhase.aggregator.latestTimestamp();
  }

  /**
   * @notice get past rounds answers
   * @param roundId the answer number to retrieve the answer for
   *
   * @dev #[deprecated] Use getRoundData instead. This does not error if no
   * answer has been reached, it will simply return 0. Either wait to point to
   * an already answered Aggregator or use the recommended getRoundData
   * instead which includes better verification information.
   */
  function getAnswer(uint256 roundId) public view virtual override returns (int256 answer) {
    if (roundId > MAX_ID) return 0;

    (uint16 phaseId, uint64 aggregatorRoundId) = parseIds(roundId);
    AggregatorProxyInterface aggregator = s_phaseAggregators[phaseId];
    if (address(aggregator) == address(0)) return 0;

    return aggregator.getAnswer(aggregatorRoundId);
  }

  /**
   * @notice get block timestamp when an answer was last updated
   * @param roundId the answer number to retrieve the updated timestamp for
   *
   * @dev #[deprecated] Use getRoundData instead. This does not error if no
   * answer has been reached, it will simply return 0. Either wait to point to
   * an already answered Aggregator or use the recommended getRoundData
   * instead which includes better verification information.
   */
  function getTimestamp(uint256 roundId) public view virtual override returns (uint256 updatedAt) {
    if (roundId > MAX_ID) return 0;

    (uint16 phaseId, uint64 aggregatorRoundId) = parseIds(roundId);
    AggregatorProxyInterface aggregator = s_phaseAggregators[phaseId];
    if (address(aggregator) == address(0)) return 0;

    return aggregator.getTimestamp(aggregatorRoundId);
  }

  /**
   * @notice get the latest completed round where the answer was updated. This
   * ID includes the proxy's phase, to make sure round IDs increase even when
   * switching to a newly deployed aggregator.
   *
   * @dev #[deprecated] Use latestRoundData instead. This does not error if no
   * answer has been reached, it will simply return 0. Either wait to point to
   * an already answered Aggregator or use the recommended latestRoundData
   * instead which includes better verification information.
   */
  function latestRound() public view virtual override returns (uint256 roundId) {
    Phase memory phase = s_currentPhase; // cache storage reads
    return addPhase(phase.id, uint64(phase.aggregator.latestRound()));
  }

  /**
   * @notice get data about a round. Consumers are encouraged to check
   * that they're receiving fresh data by inspecting the updatedAt and
   * answeredInRound return values.
   * Note that different underlying implementations of AggregatorV3Interface
   * have slightly different semantics for some of the return values. Consumers
   * should determine what implementations they expect to receive
   * data from and validate that they can properly handle return data from all
   * of them.
   * @param roundId the requested round ID as presented through the proxy, this
   * is made up of the aggregator's round ID with the phase ID encoded in the
   * two highest order bytes
   * @return id is the round ID from the aggregator for which the data was
   * retrieved combined with an phase to ensure that round IDs get larger as
   * time moves forward.
   * @return answer is the answer for the given round
   * @return startedAt is the timestamp when the round was started.
   * (Only some AggregatorV3Interface implementations return meaningful values)
   * @return updatedAt is the timestamp when the round last was updated (i.e.
   * answer was last computed)
   * @return answeredInRound is the round ID of the round in which the answer
   * was computed.
   * (Only some AggregatorV3Interface implementations return meaningful values)
   * @dev Note that answer and updatedAt may change between queries.
   */
  function getRoundData(uint80 roundId)
    public
    view
    virtual
    override
    returns (
      uint80 id,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    (uint16 phaseId, uint64 aggregatorRoundId) = parseIds(roundId);

    (id, answer, startedAt, updatedAt, answeredInRound) = s_phaseAggregators[phaseId].getRoundData(aggregatorRoundId);

    return addPhaseIds(id, answer, startedAt, updatedAt, answeredInRound, phaseId);
  }

  /**
   * @notice get data about the latest round. Consumers are encouraged to check
   * that they're receiving fresh data by inspecting the updatedAt and
   * answeredInRound return values.
   * Note that different underlying implementations of AggregatorV3Interface
   * have slightly different semantics for some of the return values. Consumers
   * should determine what implementations they expect to receive
   * data from and validate that they can properly handle return data from all
   * of them.
   * @return id is the round ID from the aggregator for which the data was
   * retrieved combined with an phase to ensure that round IDs get larger as
   * time moves forward.
   * @return answer is the answer for the given round
   * @return startedAt is the timestamp when the round was started.
   * (Only some AggregatorV3Interface implementations return meaningful values)
   * @return updatedAt is the timestamp when the round last was updated (i.e.
   * answer was last computed)
   * @return answeredInRound is the round ID of the round in which the answer
   * was computed.
   * (Only some AggregatorV3Interface implementations return meaningful values)
   * @dev Note that answer and updatedAt may change between queries.
   */
  function latestRoundData()
    public
    view
    virtual
    override
    returns (
      uint80 id,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    Phase memory current = s_currentPhase; // cache storage reads

    (id, answer, startedAt, updatedAt, answeredInRound) = current.aggregator.latestRoundData();

    return addPhaseIds(id, answer, startedAt, updatedAt, answeredInRound, current.id);
  }

  /**
   * @notice Used if an aggregator contract has been proposed.
   * @param roundId the round ID to retrieve the round data for
   * @return id is the round ID for which data was retrieved
   * @return answer is the answer for the given round
   * @return startedAt is the timestamp when the round was started.
   * (Only some AggregatorV3Interface implementations return meaningful values)
   * @return updatedAt is the timestamp when the round last was updated (i.e.
   * answer was last computed)
   * @return answeredInRound is the round ID of the round in which the answer
   * was computed.
   */
  function proposedGetRoundData(uint80 roundId)
    external
    view
    virtual
    override
    hasProposal
    returns (
      uint80 id,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    return s_proposedAggregator.getRoundData(roundId);
  }

  /**
   * @notice Used if an aggregator contract has been proposed.
   * @return id is the round ID for which data was retrieved
   * @return answer is the answer for the given round
   * @return startedAt is the timestamp when the round was started.
   * (Only some AggregatorV3Interface implementations return meaningful values)
   * @return updatedAt is the timestamp when the round last was updated (i.e.
   * answer was last computed)
   * @return answeredInRound is the round ID of the round in which the answer
   * was computed.
   */
  function proposedLatestRoundData()
    external
    view
    virtual
    override
    hasProposal
    returns (
      uint80 id,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    return s_proposedAggregator.latestRoundData();
  }

  /**
   * @notice returns the current phase's aggregator address.
   */
  function aggregator() external view override returns (address) {
    return address(s_currentPhase.aggregator);
  }

  /**
   * @notice returns the current phase's ID.
   */
  function phaseId() external view override returns (uint16) {
    return s_currentPhase.id;
  }

  /**
   * @notice represents the number of decimals the aggregator responses represent.
   */
  function decimals() external view override returns (uint8) {
    return s_currentPhase.aggregator.decimals();
  }

  /**
   * @notice the version number representing the type of aggregator the proxy
   * points to.
   */
  function version() external view override returns (uint256) {
    return s_currentPhase.aggregator.version();
  }

  /**
   * @notice returns the description of the aggregator the proxy points to.
   */
  function description() external view override returns (string memory) {
    return s_currentPhase.aggregator.description();
  }

  /**
   * @notice returns the current proposed aggregator
   */
  function proposedAggregator() external view override returns (address) {
    return address(s_proposedAggregator);
  }

  /**
   * @notice return a phase aggregator using the phaseId
   *
   * @param phaseId uint16
   */
  function phaseAggregators(uint16 phaseId) external view override returns (address) {
    return address(s_phaseAggregators[phaseId]);
  }

  /**
   * @notice Allows the owner to propose a new address for the aggregator
   * @param aggregatorAddress The new address for the aggregator contract
   */
  function proposeAggregator(address aggregatorAddress) external onlyOwner {
    s_proposedAggregator = AggregatorProxyInterface(aggregatorAddress);
    emit AggregatorProposed(address(s_currentPhase.aggregator), aggregatorAddress);
  }

  /**
   * @notice Allows the owner to confirm and change the address
   * to the proposed aggregator
   * @dev Reverts if the given address doesn't match what was previously
   * proposed
   * @param aggregatorAddress The new address for the aggregator contract
   */
  function confirmAggregator(address aggregatorAddress) external onlyOwner {
    require(aggregatorAddress == address(s_proposedAggregator), "Invalid proposed aggregator");
    address previousAggregator = address(s_currentPhase.aggregator);
    delete s_proposedAggregator;
    setAggregator(aggregatorAddress);
    emit AggregatorConfirmed(previousAggregator, aggregatorAddress);
  }

  /*
   * Internal
   */

  function setAggregator(address aggregatorAddress) internal {
    uint16 id = s_currentPhase.id + 1;
    s_currentPhase = Phase(id, AggregatorProxyInterface(aggregatorAddress));
    s_phaseAggregators[id] = AggregatorProxyInterface(aggregatorAddress);
  }

  function addPhase(uint16 phase, uint64 originalId) internal pure returns (uint80) {
    return uint80((uint256(phase) << PHASE_OFFSET) | originalId);
  }

  function parseIds(uint256 roundId) internal pure returns (uint16, uint64) {
    uint16 phaseId = uint16(roundId >> PHASE_OFFSET);
    uint64 aggregatorRoundId = uint64(roundId);

    return (phaseId, aggregatorRoundId);
  }

  function addPhaseIds(
    uint80 roundId,
    int256 answer,
    uint256 startedAt,
    uint256 updatedAt,
    uint80 answeredInRound,
    uint16 phaseId
  )
    internal
    pure
    returns (
      uint80,
      int256,
      uint256,
      uint256,
      uint80
    )
  {
    return (
      addPhase(phaseId, uint64(roundId)),
      answer,
      startedAt,
      updatedAt,
      addPhase(phaseId, uint64(answeredInRound))
    );
  }

  /*
   * Modifiers
   */

  modifier hasProposal() {
    require(address(s_proposedAggregator) != address(0), "No proposed aggregator present");
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./Chainlink.sol";
import "./interfaces/ENSInterface.sol";
import "./interfaces/LinkTokenInterface.sol";
import "./interfaces/ChainlinkRequestInterface.sol";
import "./interfaces/OperatorInterface.sol";
import "./interfaces/PointerInterface.sol";
import {ENSResolver as ENSResolver_Chainlink} from "./vendor/ENSResolver.sol";

/**
 * @title The ChainlinkClient contract
 * @notice Contract writers can inherit this contract in order to create requests for the
 * Chainlink network
 */
abstract contract ChainlinkClient {
  using Chainlink for Chainlink.Request;

  uint256 internal constant LINK_DIVISIBILITY = 10**18;
  uint256 private constant AMOUNT_OVERRIDE = 0;
  address private constant SENDER_OVERRIDE = address(0);
  uint256 private constant ORACLE_ARGS_VERSION = 1;
  uint256 private constant OPERATOR_ARGS_VERSION = 2;
  bytes32 private constant ENS_TOKEN_SUBNAME = keccak256("link");
  bytes32 private constant ENS_ORACLE_SUBNAME = keccak256("oracle");
  address private constant LINK_TOKEN_POINTER = 0xC89bD4E1632D3A43CB03AAAd5262cbe4038Bc571;

  ENSInterface private s_ens;
  bytes32 private s_ensNode;
  LinkTokenInterface private s_link;
  OperatorInterface private s_oracle;
  uint256 private s_requestCount = 1;
  mapping(bytes32 => address) private s_pendingRequests;

  event ChainlinkRequested(bytes32 indexed id);
  event ChainlinkFulfilled(bytes32 indexed id);
  event ChainlinkCancelled(bytes32 indexed id);

  /**
   * @notice Creates a request that can hold additional parameters
   * @param specId The Job Specification ID that the request will be created for
   * @param callbackAddr address to operate the callback on
   * @param callbackFunctionSignature function signature to use for the callback
   * @return A Chainlink Request struct in memory
   */
  function buildChainlinkRequest(
    bytes32 specId,
    address callbackAddr,
    bytes4 callbackFunctionSignature
  ) internal pure returns (Chainlink.Request memory) {
    Chainlink.Request memory req;
    return req.initialize(specId, callbackAddr, callbackFunctionSignature);
  }

  /**
   * @notice Creates a request that can hold additional parameters
   * @param specId The Job Specification ID that the request will be created for
   * @param callbackFunctionSignature function signature to use for the callback
   * @return A Chainlink Request struct in memory
   */
  function buildOperatorRequest(bytes32 specId, bytes4 callbackFunctionSignature)
    internal
    view
    returns (Chainlink.Request memory)
  {
    Chainlink.Request memory req;
    return req.initialize(specId, address(this), callbackFunctionSignature);
  }

  /**
   * @notice Creates a Chainlink request to the stored oracle address
   * @dev Calls `chainlinkRequestTo` with the stored oracle address
   * @param req The initialized Chainlink Request
   * @param payment The amount of LINK to send for the request
   * @return requestId The request ID
   */
  function sendChainlinkRequest(Chainlink.Request memory req, uint256 payment) internal returns (bytes32) {
    return sendChainlinkRequestTo(address(s_oracle), req, payment);
  }

  /**
   * @notice Creates a Chainlink request to the specified oracle address
   * @dev Generates and stores a request ID, increments the local nonce, and uses `transferAndCall` to
   * send LINK which creates a request on the target oracle contract.
   * Emits ChainlinkRequested event.
   * @param oracleAddress The address of the oracle for the request
   * @param req The initialized Chainlink Request
   * @param payment The amount of LINK to send for the request
   * @return requestId The request ID
   */
  function sendChainlinkRequestTo(
    address oracleAddress,
    Chainlink.Request memory req,
    uint256 payment
  ) internal returns (bytes32 requestId) {
    uint256 nonce = s_requestCount;
    s_requestCount = nonce + 1;
    bytes memory encodedRequest = abi.encodeWithSelector(
      ChainlinkRequestInterface.oracleRequest.selector,
      SENDER_OVERRIDE, // Sender value - overridden by onTokenTransfer by the requesting contract's address
      AMOUNT_OVERRIDE, // Amount value - overridden by onTokenTransfer by the actual amount of LINK sent
      req.id,
      address(this),
      req.callbackFunctionId,
      nonce,
      ORACLE_ARGS_VERSION,
      req.buf.buf
    );
    return _rawRequest(oracleAddress, nonce, payment, encodedRequest);
  }

  /**
   * @notice Creates a Chainlink request to the stored oracle address
   * @dev This function supports multi-word response
   * @dev Calls `sendOperatorRequestTo` with the stored oracle address
   * @param req The initialized Chainlink Request
   * @param payment The amount of LINK to send for the request
   * @return requestId The request ID
   */
  function sendOperatorRequest(Chainlink.Request memory req, uint256 payment) internal returns (bytes32) {
    return sendOperatorRequestTo(address(s_oracle), req, payment);
  }

  /**
   * @notice Creates a Chainlink request to the specified oracle address
   * @dev This function supports multi-word response
   * @dev Generates and stores a request ID, increments the local nonce, and uses `transferAndCall` to
   * send LINK which creates a request on the target oracle contract.
   * Emits ChainlinkRequested event.
   * @param oracleAddress The address of the oracle for the request
   * @param req The initialized Chainlink Request
   * @param payment The amount of LINK to send for the request
   * @return requestId The request ID
   */
  function sendOperatorRequestTo(
    address oracleAddress,
    Chainlink.Request memory req,
    uint256 payment
  ) internal returns (bytes32 requestId) {
    uint256 nonce = s_requestCount;
    s_requestCount = nonce + 1;
    bytes memory encodedRequest = abi.encodeWithSelector(
      OperatorInterface.operatorRequest.selector,
      SENDER_OVERRIDE, // Sender value - overridden by onTokenTransfer by the requesting contract's address
      AMOUNT_OVERRIDE, // Amount value - overridden by onTokenTransfer by the actual amount of LINK sent
      req.id,
      req.callbackFunctionId,
      nonce,
      OPERATOR_ARGS_VERSION,
      req.buf.buf
    );
    return _rawRequest(oracleAddress, nonce, payment, encodedRequest);
  }

  /**
   * @notice Make a request to an oracle
   * @param oracleAddress The address of the oracle for the request
   * @param nonce used to generate the request ID
   * @param payment The amount of LINK to send for the request
   * @param encodedRequest data encoded for request type specific format
   * @return requestId The request ID
   */
  function _rawRequest(
    address oracleAddress,
    uint256 nonce,
    uint256 payment,
    bytes memory encodedRequest
  ) private returns (bytes32 requestId) {
    requestId = keccak256(abi.encodePacked(this, nonce));
    s_pendingRequests[requestId] = oracleAddress;
    emit ChainlinkRequested(requestId);
    require(s_link.transferAndCall(oracleAddress, payment, encodedRequest), "unable to transferAndCall to oracle");
  }

  /**
   * @notice Allows a request to be cancelled if it has not been fulfilled
   * @dev Requires keeping track of the expiration value emitted from the oracle contract.
   * Deletes the request from the `pendingRequests` mapping.
   * Emits ChainlinkCancelled event.
   * @param requestId The request ID
   * @param payment The amount of LINK sent for the request
   * @param callbackFunc The callback function specified for the request
   * @param expiration The time of the expiration for the request
   */
  function cancelChainlinkRequest(
    bytes32 requestId,
    uint256 payment,
    bytes4 callbackFunc,
    uint256 expiration
  ) internal {
    OperatorInterface requested = OperatorInterface(s_pendingRequests[requestId]);
    delete s_pendingRequests[requestId];
    emit ChainlinkCancelled(requestId);
    requested.cancelOracleRequest(requestId, payment, callbackFunc, expiration);
  }

  /**
   * @notice the next request count to be used in generating a nonce
   * @dev starts at 1 in order to ensure consistent gas cost
   * @return returns the next request count to be used in a nonce
   */
  function getNextRequestCount() internal view returns (uint256) {
    return s_requestCount;
  }

  /**
   * @notice Sets the stored oracle address
   * @param oracleAddress The address of the oracle contract
   */
  function setChainlinkOracle(address oracleAddress) internal {
    s_oracle = OperatorInterface(oracleAddress);
  }

  /**
   * @notice Sets the LINK token address
   * @param linkAddress The address of the LINK token contract
   */
  function setChainlinkToken(address linkAddress) internal {
    s_link = LinkTokenInterface(linkAddress);
  }

  /**
   * @notice Sets the Chainlink token address for the public
   * network as given by the Pointer contract
   */
  function setPublicChainlinkToken() internal {
    setChainlinkToken(PointerInterface(LINK_TOKEN_POINTER).getAddress());
  }

  /**
   * @notice Retrieves the stored address of the LINK token
   * @return The address of the LINK token
   */
  function chainlinkTokenAddress() internal view returns (address) {
    return address(s_link);
  }

  /**
   * @notice Retrieves the stored address of the oracle contract
   * @return The address of the oracle contract
   */
  function chainlinkOracleAddress() internal view returns (address) {
    return address(s_oracle);
  }

  /**
   * @notice Allows for a request which was created on another contract to be fulfilled
   * on this contract
   * @param oracleAddress The address of the oracle contract that will fulfill the request
   * @param requestId The request ID used for the response
   */
  function addChainlinkExternalRequest(address oracleAddress, bytes32 requestId) internal notPendingRequest(requestId) {
    s_pendingRequests[requestId] = oracleAddress;
  }

  /**
   * @notice Sets the stored oracle and LINK token contracts with the addresses resolved by ENS
   * @dev Accounts for subnodes having different resolvers
   * @param ensAddress The address of the ENS contract
   * @param node The ENS node hash
   */
  function useChainlinkWithENS(address ensAddress, bytes32 node) internal {
    s_ens = ENSInterface(ensAddress);
    s_ensNode = node;
    bytes32 linkSubnode = keccak256(abi.encodePacked(s_ensNode, ENS_TOKEN_SUBNAME));
    ENSResolver_Chainlink resolver = ENSResolver_Chainlink(s_ens.resolver(linkSubnode));
    setChainlinkToken(resolver.addr(linkSubnode));
    updateChainlinkOracleWithENS();
  }

  /**
   * @notice Sets the stored oracle contract with the address resolved by ENS
   * @dev This may be called on its own as long as `useChainlinkWithENS` has been called previously
   */
  function updateChainlinkOracleWithENS() internal {
    bytes32 oracleSubnode = keccak256(abi.encodePacked(s_ensNode, ENS_ORACLE_SUBNAME));
    ENSResolver_Chainlink resolver = ENSResolver_Chainlink(s_ens.resolver(oracleSubnode));
    setChainlinkOracle(resolver.addr(oracleSubnode));
  }

  /**
   * @notice Ensures that the fulfillment is valid for this contract
   * @dev Use if the contract developer prefers methods instead of modifiers for validation
   * @param requestId The request ID for fulfillment
   */
  function validateChainlinkCallback(bytes32 requestId)
    internal
    recordChainlinkFulfillment(requestId)
  // solhint-disable-next-line no-empty-blocks
  {

  }

  /**
   * @dev Reverts if the sender is not the oracle of the request.
   * Emits ChainlinkFulfilled event.
   * @param requestId The request ID for fulfillment
   */
  modifier recordChainlinkFulfillment(bytes32 requestId) {
    require(msg.sender == s_pendingRequests[requestId], "Source must be the oracle of the request");
    delete s_pendingRequests[requestId];
    emit ChainlinkFulfilled(requestId);
    _;
  }

  /**
   * @dev Reverts if the request is already pending
   * @param requestId The request ID for fulfillment
   */
  modifier notPendingRequest(bytes32 requestId) {
    require(s_pendingRequests[requestId] == address(0), "Request is already pending");
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import {CBORChainlink} from "./vendor/CBORChainlink.sol";
import {BufferChainlink} from "./vendor/BufferChainlink.sol";

/**
 * @title Library for common Chainlink functions
 * @dev Uses imported CBOR library for encoding to buffer
 */
library Chainlink {
  uint256 internal constant defaultBufferSize = 256; // solhint-disable-line const-name-snakecase

  using CBORChainlink for BufferChainlink.buffer;

  struct Request {
    bytes32 id;
    address callbackAddress;
    bytes4 callbackFunctionId;
    uint256 nonce;
    BufferChainlink.buffer buf;
  }

  /**
   * @notice Initializes a Chainlink request
   * @dev Sets the ID, callback address, and callback function signature on the request
   * @param self The uninitialized request
   * @param jobId The Job Specification ID
   * @param callbackAddr The callback address
   * @param callbackFunc The callback function signature
   * @return The initialized request
   */
  function initialize(
    Request memory self,
    bytes32 jobId,
    address callbackAddr,
    bytes4 callbackFunc
  ) internal pure returns (Chainlink.Request memory) {
    BufferChainlink.init(self.buf, defaultBufferSize);
    self.id = jobId;
    self.callbackAddress = callbackAddr;
    self.callbackFunctionId = callbackFunc;
    return self;
  }

  /**
   * @notice Sets the data for the buffer without encoding CBOR on-chain
   * @dev CBOR can be closed with curly-brackets {} or they can be left off
   * @param self The initialized request
   * @param data The CBOR data
   */
  function setBuffer(Request memory self, bytes memory data) internal pure {
    BufferChainlink.init(self.buf, data.length);
    BufferChainlink.append(self.buf, data);
  }

  /**
   * @notice Adds a string value to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param value The string value to add
   */
  function add(
    Request memory self,
    string memory key,
    string memory value
  ) internal pure {
    self.buf.encodeString(key);
    self.buf.encodeString(value);
  }

  /**
   * @notice Adds a bytes value to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param value The bytes value to add
   */
  function addBytes(
    Request memory self,
    string memory key,
    bytes memory value
  ) internal pure {
    self.buf.encodeString(key);
    self.buf.encodeBytes(value);
  }

  /**
   * @notice Adds a int256 value to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param value The int256 value to add
   */
  function addInt(
    Request memory self,
    string memory key,
    int256 value
  ) internal pure {
    self.buf.encodeString(key);
    self.buf.encodeInt(value);
  }

  /**
   * @notice Adds a uint256 value to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param value The uint256 value to add
   */
  function addUint(
    Request memory self,
    string memory key,
    uint256 value
  ) internal pure {
    self.buf.encodeString(key);
    self.buf.encodeUInt(value);
  }

  /**
   * @notice Adds an array of strings to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param values The array of string values to add
   */
  function addStringArray(
    Request memory self,
    string memory key,
    string[] memory values
  ) internal pure {
    self.buf.encodeString(key);
    self.buf.startArray();
    for (uint256 i = 0; i < values.length; i++) {
      self.buf.encodeString(values[i]);
    }
    self.buf.endSequence();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface ENSInterface {
  // Logged when the owner of a node assigns a new owner to a subnode.
  event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

  // Logged when the owner of a node transfers ownership to a new account.
  event Transfer(bytes32 indexed node, address owner);

  // Logged when the resolver for a node changes.
  event NewResolver(bytes32 indexed node, address resolver);

  // Logged when the TTL of a node changes
  event NewTTL(bytes32 indexed node, uint64 ttl);

  function setSubnodeOwner(
    bytes32 node,
    bytes32 label,
    address owner
  ) external;

  function setResolver(bytes32 node, address resolver) external;

  function setOwner(bytes32 node, address owner) external;

  function setTTL(bytes32 node, uint64 ttl) external;

  function owner(bytes32 node) external view returns (address);

  function resolver(bytes32 node) external view returns (address);

  function ttl(bytes32 node) external view returns (uint64);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface PointerInterface {
  function getAddress() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

abstract contract ENSResolver {
  function addr(bytes32 node) public view virtual returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.19;

import {BufferChainlink} from "./BufferChainlink.sol";

library CBORChainlink {
  using BufferChainlink for BufferChainlink.buffer;

  uint8 private constant MAJOR_TYPE_INT = 0;
  uint8 private constant MAJOR_TYPE_NEGATIVE_INT = 1;
  uint8 private constant MAJOR_TYPE_BYTES = 2;
  uint8 private constant MAJOR_TYPE_STRING = 3;
  uint8 private constant MAJOR_TYPE_ARRAY = 4;
  uint8 private constant MAJOR_TYPE_MAP = 5;
  uint8 private constant MAJOR_TYPE_TAG = 6;
  uint8 private constant MAJOR_TYPE_CONTENT_FREE = 7;

  uint8 private constant TAG_TYPE_BIGNUM = 2;
  uint8 private constant TAG_TYPE_NEGATIVE_BIGNUM = 3;

  function encodeFixedNumeric(BufferChainlink.buffer memory buf, uint8 major, uint64 value) private pure {
    if(value <= 23) {
      buf.appendUint8(uint8((major << 5) | value));
    } else if (value <= 0xFF) {
      buf.appendUint8(uint8((major << 5) | 24));
      buf.appendInt(value, 1);
    } else if (value <= 0xFFFF) {
      buf.appendUint8(uint8((major << 5) | 25));
      buf.appendInt(value, 2);
    } else if (value <= 0xFFFFFFFF) {
      buf.appendUint8(uint8((major << 5) | 26));
      buf.appendInt(value, 4);
    } else {
      buf.appendUint8(uint8((major << 5) | 27));
      buf.appendInt(value, 8);
    }
  }

  function encodeIndefiniteLengthType(BufferChainlink.buffer memory buf, uint8 major) private pure {
    buf.appendUint8(uint8((major << 5) | 31));
  }

  function encodeUInt(BufferChainlink.buffer memory buf, uint value) internal pure {
    if(value > 0xFFFFFFFFFFFFFFFF) {
      encodeBigNum(buf, value);
    } else {
      encodeFixedNumeric(buf, MAJOR_TYPE_INT, uint64(value));
    }
  }

  function encodeInt(BufferChainlink.buffer memory buf, int value) internal pure {
    if(value < -0x10000000000000000) {
      encodeSignedBigNum(buf, value);
    } else if(value > 0xFFFFFFFFFFFFFFFF) {
      encodeBigNum(buf, uint(value));
    } else if(value >= 0) {
      encodeFixedNumeric(buf, MAJOR_TYPE_INT, uint64(uint256(value)));
    } else {
      encodeFixedNumeric(buf, MAJOR_TYPE_NEGATIVE_INT, uint64(uint256(-1 - value)));
    }
  }

  function encodeBytes(BufferChainlink.buffer memory buf, bytes memory value) internal pure {
    encodeFixedNumeric(buf, MAJOR_TYPE_BYTES, uint64(value.length));
    buf.append(value);
  }

  function encodeBigNum(BufferChainlink.buffer memory buf, uint value) internal pure {
    buf.appendUint8(uint8((MAJOR_TYPE_TAG << 5) | TAG_TYPE_BIGNUM));
    encodeBytes(buf, abi.encode(value));
  }

  function encodeSignedBigNum(BufferChainlink.buffer memory buf, int input) internal pure {
    buf.appendUint8(uint8((MAJOR_TYPE_TAG << 5) | TAG_TYPE_NEGATIVE_BIGNUM));
    encodeBytes(buf, abi.encode(uint256(-1 - input)));
  }

  function encodeString(BufferChainlink.buffer memory buf, string memory value) internal pure {
    encodeFixedNumeric(buf, MAJOR_TYPE_STRING, uint64(bytes(value).length));
    buf.append(bytes(value));
  }

  function startArray(BufferChainlink.buffer memory buf) internal pure {
    encodeIndefiniteLengthType(buf, MAJOR_TYPE_ARRAY);
  }

  function startMap(BufferChainlink.buffer memory buf) internal pure {
    encodeIndefiniteLengthType(buf, MAJOR_TYPE_MAP);
  }

  function endSequence(BufferChainlink.buffer memory buf) internal pure {
    encodeIndefiniteLengthType(buf, MAJOR_TYPE_CONTENT_FREE);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

/**
 * @dev A library for working with mutable byte buffers in Solidity.
 *
 * Byte buffers are mutable and expandable, and provide a variety of primitives
 * for writing to them. At any time you can fetch a bytes object containing the
 * current contents of the buffer. The bytes object should not be stored between
 * operations, as it may change due to resizing of the buffer.
 */
library BufferChainlink {
  /**
   * @dev Represents a mutable buffer. Buffers have a current value (buf) and
   *      a capacity. The capacity may be longer than the current value, in
   *      which case it can be extended without the need to allocate more memory.
   */
  struct buffer {
    bytes buf;
    uint256 capacity;
  }

  /**
   * @dev Initializes a buffer with an initial capacity.
   * @param buf The buffer to initialize.
   * @param capacity The number of bytes of space to allocate the buffer.
   * @return The buffer, for chaining.
   */
  function init(buffer memory buf, uint256 capacity) internal pure returns (buffer memory) {
    if (capacity % 32 != 0) {
      capacity += 32 - (capacity % 32);
    }
    // Allocate space for the buffer data
    buf.capacity = capacity;
    assembly {
      let ptr := mload(0x40)
      mstore(buf, ptr)
      mstore(ptr, 0)
      mstore(0x40, add(32, add(ptr, capacity)))
    }
    return buf;
  }

  /**
   * @dev Initializes a new buffer from an existing bytes object.
   *      Changes to the buffer may mutate the original value.
   * @param b The bytes object to initialize the buffer with.
   * @return A new buffer.
   */
  function fromBytes(bytes memory b) internal pure returns (buffer memory) {
    buffer memory buf;
    buf.buf = b;
    buf.capacity = b.length;
    return buf;
  }

  function resize(buffer memory buf, uint256 capacity) private pure {
    bytes memory oldbuf = buf.buf;
    init(buf, capacity);
    append(buf, oldbuf);
  }

  function max(uint256 a, uint256 b) private pure returns (uint256) {
    if (a > b) {
      return a;
    }
    return b;
  }

  /**
   * @dev Sets buffer length to 0.
   * @param buf The buffer to truncate.
   * @return The original buffer, for chaining..
   */
  function truncate(buffer memory buf) internal pure returns (buffer memory) {
    assembly {
      let bufptr := mload(buf)
      mstore(bufptr, 0)
    }
    return buf;
  }

  /**
   * @dev Writes a byte string to a buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param off The start offset to write to.
   * @param data The data to append.
   * @param len The number of bytes to copy.
   * @return The original buffer, for chaining.
   */
  function write(
    buffer memory buf,
    uint256 off,
    bytes memory data,
    uint256 len
  ) internal pure returns (buffer memory) {
    require(len <= data.length);

    if (off + len > buf.capacity) {
      resize(buf, max(buf.capacity, len + off) * 2);
    }

    uint256 dest;
    uint256 src;
    assembly {
      // Memory address of the buffer data
      let bufptr := mload(buf)
      // Length of existing buffer data
      let buflen := mload(bufptr)
      // Start address = buffer address + offset + sizeof(buffer length)
      dest := add(add(bufptr, 32), off)
      // Update buffer length if we're extending it
      if gt(add(len, off), buflen) {
        mstore(bufptr, add(len, off))
      }
      src := add(data, 32)
    }

    // Copy word-length chunks while possible
    for (; len >= 32; len -= 32) {
      assembly {
        mstore(dest, mload(src))
      }
      dest += 32;
      src += 32;
    }

    // Copy remaining bytes
    uint256 mask = 256**(32 - len) - 1;
    assembly {
      let srcpart := and(mload(src), not(mask))
      let destpart := and(mload(dest), mask)
      mstore(dest, or(destpart, srcpart))
    }

    return buf;
  }

  /**
   * @dev Appends a byte string to a buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @param len The number of bytes to copy.
   * @return The original buffer, for chaining.
   */
  function append(
    buffer memory buf,
    bytes memory data,
    uint256 len
  ) internal pure returns (buffer memory) {
    return write(buf, buf.buf.length, data, len);
  }

  /**
   * @dev Appends a byte string to a buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function append(buffer memory buf, bytes memory data) internal pure returns (buffer memory) {
    return write(buf, buf.buf.length, data, data.length);
  }

  /**
   * @dev Writes a byte to the buffer. Resizes if doing so would exceed the
   *      capacity of the buffer.
   * @param buf The buffer to append to.
   * @param off The offset to write the byte at.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function writeUint8(
    buffer memory buf,
    uint256 off,
    uint8 data
  ) internal pure returns (buffer memory) {
    if (off >= buf.capacity) {
      resize(buf, buf.capacity * 2);
    }

    assembly {
      // Memory address of the buffer data
      let bufptr := mload(buf)
      // Length of existing buffer data
      let buflen := mload(bufptr)
      // Address = buffer address + sizeof(buffer length) + off
      let dest := add(add(bufptr, off), 32)
      mstore8(dest, data)
      // Update buffer length if we extended it
      if eq(off, buflen) {
        mstore(bufptr, add(buflen, 1))
      }
    }
    return buf;
  }

  /**
   * @dev Appends a byte to the buffer. Resizes if doing so would exceed the
   *      capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function appendUint8(buffer memory buf, uint8 data) internal pure returns (buffer memory) {
    return writeUint8(buf, buf.buf.length, data);
  }

  /**
   * @dev Writes up to 32 bytes to the buffer. Resizes if doing so would
   *      exceed the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param off The offset to write at.
   * @param data The data to append.
   * @param len The number of bytes to write (left-aligned).
   * @return The original buffer, for chaining.
   */
  function write(
    buffer memory buf,
    uint256 off,
    bytes32 data,
    uint256 len
  ) private pure returns (buffer memory) {
    if (len + off > buf.capacity) {
      resize(buf, (len + off) * 2);
    }

    uint256 mask = 256**len - 1;
    // Right-align data
    data = data >> (8 * (32 - len));
    assembly {
      // Memory address of the buffer data
      let bufptr := mload(buf)
      // Address = buffer address + sizeof(buffer length) + off + len
      let dest := add(add(bufptr, off), len)
      mstore(dest, or(and(mload(dest), not(mask)), data))
      // Update buffer length if we extended it
      if gt(add(off, len), mload(bufptr)) {
        mstore(bufptr, add(off, len))
      }
    }
    return buf;
  }

  /**
   * @dev Writes a bytes20 to the buffer. Resizes if doing so would exceed the
   *      capacity of the buffer.
   * @param buf The buffer to append to.
   * @param off The offset to write at.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function writeBytes20(
    buffer memory buf,
    uint256 off,
    bytes20 data
  ) internal pure returns (buffer memory) {
    return write(buf, off, bytes32(data), 20);
  }

  /**
   * @dev Appends a bytes20 to the buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer, for chhaining.
   */
  function appendBytes20(buffer memory buf, bytes20 data) internal pure returns (buffer memory) {
    return write(buf, buf.buf.length, bytes32(data), 20);
  }

  /**
   * @dev Appends a bytes32 to the buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function appendBytes32(buffer memory buf, bytes32 data) internal pure returns (buffer memory) {
    return write(buf, buf.buf.length, data, 32);
  }

  /**
   * @dev Writes an integer to the buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param off The offset to write at.
   * @param data The data to append.
   * @param len The number of bytes to write (right-aligned).
   * @return The original buffer, for chaining.
   */
  function writeInt(
    buffer memory buf,
    uint256 off,
    uint256 data,
    uint256 len
  ) private pure returns (buffer memory) {
    if (len + off > buf.capacity) {
      resize(buf, (len + off) * 2);
    }

    uint256 mask = 256**len - 1;
    assembly {
      // Memory address of the buffer data
      let bufptr := mload(buf)
      // Address = buffer address + off + sizeof(buffer length) + len
      let dest := add(add(bufptr, off), len)
      mstore(dest, or(and(mload(dest), not(mask)), data))
      // Update buffer length if we extended it
      if gt(add(off, len), mload(bufptr)) {
        mstore(bufptr, add(off, len))
      }
    }
    return buf;
  }

  /**
   * @dev Appends a byte to the end of the buffer. Resizes if doing so would
   * exceed the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer.
   */
  function appendInt(
    buffer memory buf,
    uint256 data,
    uint256 len
  ) internal pure returns (buffer memory) {
    return writeInt(buf, buf.buf.length, data, len);
  }
}

pragma solidity ^0.7.0;

import "../ChainlinkClient.sol";
import "../Chainlink.sol";

contract MultiWordConsumer is ChainlinkClient {
  using Chainlink for Chainlink.Request;

  bytes32 internal specId;
  bytes public currentPrice;

  bytes32 public usd;
  bytes32 public eur;
  bytes32 public jpy;

  uint256 public usdInt;
  uint256 public eurInt;
  uint256 public jpyInt;

  event RequestFulfilled(
    bytes32 indexed requestId, // User-defined ID
    bytes indexed price
  );

  event RequestMultipleFulfilled(bytes32 indexed requestId, bytes32 indexed usd, bytes32 indexed eur, bytes32 jpy);

  event RequestMultipleFulfilledWithCustomURLs(
    bytes32 indexed requestId,
    uint256 indexed usd,
    uint256 indexed eur,
    uint256 jpy
  );

  constructor(
    address _link,
    address _oracle,
    bytes32 _specId
  ) public {
    setChainlinkToken(_link);
    setChainlinkOracle(_oracle);
    specId = _specId;
  }

  function setSpecID(bytes32 _specId) public {
    specId = _specId;
  }

  function requestEthereumPrice(string memory _currency, uint256 _payment) public {
    Chainlink.Request memory req = buildOperatorRequest(specId, this.fulfillBytes.selector);
    sendOperatorRequest(req, _payment);
  }

  function requestMultipleParameters(string memory _currency, uint256 _payment) public {
    Chainlink.Request memory req = buildOperatorRequest(specId, this.fulfillMultipleParameters.selector);
    sendOperatorRequest(req, _payment);
  }

  function requestMultipleParametersWithCustomURLs(
    string memory _urlUSD,
    string memory _pathUSD,
    string memory _urlEUR,
    string memory _pathEUR,
    string memory _urlJPY,
    string memory _pathJPY,
    uint256 _payment
  ) public {
    Chainlink.Request memory req = buildOperatorRequest(specId, this.fulfillMultipleParametersWithCustomURLs.selector);
    req.add("urlUSD", _urlUSD);
    req.add("pathUSD", _pathUSD);
    req.add("urlEUR", _urlEUR);
    req.add("pathEUR", _pathEUR);
    req.add("urlJPY", _urlJPY);
    req.add("pathJPY", _pathJPY);
    sendOperatorRequest(req, _payment);
  }

  function cancelRequest(
    address _oracle,
    bytes32 _requestId,
    uint256 _payment,
    bytes4 _callbackFunctionId,
    uint256 _expiration
  ) public {
    ChainlinkRequestInterface requested = ChainlinkRequestInterface(_oracle);
    requested.cancelOracleRequest(_requestId, _payment, _callbackFunctionId, _expiration);
  }

  function withdrawLink() public {
    LinkTokenInterface _link = LinkTokenInterface(chainlinkTokenAddress());
    require(_link.transfer(msg.sender, _link.balanceOf(address(this))), "Unable to transfer");
  }

  function addExternalRequest(address _oracle, bytes32 _requestId) external {
    addChainlinkExternalRequest(_oracle, _requestId);
  }

  function fulfillMultipleParameters(
    bytes32 _requestId,
    bytes32 _usd,
    bytes32 _eur,
    bytes32 _jpy
  ) public recordChainlinkFulfillment(_requestId) {
    emit RequestMultipleFulfilled(_requestId, _usd, _eur, _jpy);
    usd = _usd;
    eur = _eur;
    jpy = _jpy;
  }

  function fulfillMultipleParametersWithCustomURLs(
    bytes32 _requestId,
    uint256 _usd,
    uint256 _eur,
    uint256 _jpy
  ) public recordChainlinkFulfillment(_requestId) {
    emit RequestMultipleFulfilledWithCustomURLs(_requestId, _usd, _eur, _jpy);
    usdInt = _usd;
    eurInt = _eur;
    jpyInt = _jpy;
  }

  function fulfillBytes(bytes32 _requestId, bytes memory _price) public recordChainlinkFulfillment(_requestId) {
    emit RequestFulfilled(_requestId, _price);
    currentPrice = _price;
  }

  function publicGetNextRequestCount() external view returns (uint256) {
    return getNextRequestCount();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "../Chainlink.sol";
import "../vendor/CBORChainlink.sol";
import "../vendor/BufferChainlink.sol";

contract ChainlinkTestHelper {
  using Chainlink for Chainlink.Request;
  using CBORChainlink for BufferChainlink.buffer;

  Chainlink.Request private req;

  event RequestData(bytes payload);

  function closeEvent() public {
    emit RequestData(req.buf.buf);
  }

  function setBuffer(bytes memory data) public {
    Chainlink.Request memory r2 = req;
    r2.setBuffer(data);
    req = r2;
  }

  function add(string memory _key, string memory _value) public {
    Chainlink.Request memory r2 = req;
    r2.add(_key, _value);
    req = r2;
  }

  function addBytes(string memory _key, bytes memory _value) public {
    Chainlink.Request memory r2 = req;
    r2.addBytes(_key, _value);
    req = r2;
  }

  function addInt(string memory _key, int256 _value) public {
    Chainlink.Request memory r2 = req;
    r2.addInt(_key, _value);
    req = r2;
  }

  function addUint(string memory _key, uint256 _value) public {
    Chainlink.Request memory r2 = req;
    r2.addUint(_key, _value);
    req = r2;
  }

  // Temporarily have method receive bytes32[] memory until experimental
  // string[] memory can be invoked from truffle tests.
  function addStringArray(string memory _key, bytes32[] memory _values) public {
    string[] memory strings = new string[](_values.length);
    for (uint256 i = 0; i < _values.length; i++) {
      strings[i] = bytes32ToString(_values[i]);
    }
    Chainlink.Request memory r2 = req;
    r2.addStringArray(_key, strings);
    req = r2;
  }

  function bytes32ToString(bytes32 x) private pure returns (string memory) {
    bytes memory bytesString = new bytes(32);
    uint256 charCount = 0;
    for (uint256 j = 0; j < 32; j++) {
      bytes1 char = bytes1(bytes32(uint256(x) * 2**(8 * j)));
      if (char != 0) {
        bytesString[charCount] = char;
        charCount++;
      }
    }
    bytes memory bytesStringTrimmed = new bytes(charCount);
    for (uint256 j = 0; j < charCount; j++) {
      bytesStringTrimmed[j] = bytesString[j];
    }
    return string(bytesStringTrimmed);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "../ChainlinkClient.sol";

contract Consumer is ChainlinkClient {
  using Chainlink for Chainlink.Request;

  bytes32 internal specId;
  bytes32 public currentPrice;
  uint256 public currentPriceInt;

  event RequestFulfilled(
    bytes32 indexed requestId, // User-defined ID
    bytes32 indexed price
  );

  constructor(
    address _link,
    address _oracle,
    bytes32 _specId
  ) public {
    setChainlinkToken(_link);
    setChainlinkOracle(_oracle);
    specId = _specId;
  }

  function setSpecID(bytes32 _specId) public {
    specId = _specId;
  }

  function requestEthereumPrice(string memory _currency, uint256 _payment) public {
    Chainlink.Request memory req = buildOperatorRequest(specId, this.fulfill.selector);
    req.add("get", "https://min-api.cryptocompare.com/data/price?fsym=ETH&tsyms=USD,EUR,JPY");
    string[] memory path = new string[](1);
    path[0] = _currency;
    req.addStringArray("path", path);
    // version 2
    sendChainlinkRequest(req, _payment);
  }

  function requestMultipleParametersWithCustomURLs(
    string memory _urlUSD,
    string memory _pathUSD,
    uint256 _payment
  ) public {
    Chainlink.Request memory req = buildOperatorRequest(specId, this.fulfillParametersWithCustomURLs.selector);
    req.add("urlUSD", _urlUSD);
    req.add("pathUSD", _pathUSD);
    sendChainlinkRequest(req, _payment);
  }

  function cancelRequest(
    address _oracle,
    bytes32 _requestId,
    uint256 _payment,
    bytes4 _callbackFunctionId,
    uint256 _expiration
  ) public {
    ChainlinkRequestInterface requested = ChainlinkRequestInterface(_oracle);
    requested.cancelOracleRequest(_requestId, _payment, _callbackFunctionId, _expiration);
  }

  function withdrawLink() public {
    LinkTokenInterface _link = LinkTokenInterface(chainlinkTokenAddress());
    require(_link.transfer(msg.sender, _link.balanceOf(address(this))), "Unable to transfer");
  }

  function addExternalRequest(address _oracle, bytes32 _requestId) external {
    addChainlinkExternalRequest(_oracle, _requestId);
  }

  function fulfill(bytes32 _requestId, bytes32 _price) public recordChainlinkFulfillment(_requestId) {
    emit RequestFulfilled(_requestId, _price);
    currentPrice = _price;
  }

  function fulfillParametersWithCustomURLs(bytes32 _requestId, uint256 _price)
    public
    recordChainlinkFulfillment(_requestId)
  {
    emit RequestFulfilled(_requestId, bytes32(_price));
    currentPriceInt = _price;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "../ChainlinkClient.sol";
import "../vendor/SafeMathChainlink.sol";

contract ChainlinkClientTestHelper is ChainlinkClient {
  using SafeMathChainlink for uint256;

  constructor(address _link, address _oracle) {
    setChainlinkToken(_link);
    setChainlinkOracle(_oracle);
  }

  event Request(bytes32 id, address callbackAddress, bytes4 callbackfunctionSelector, bytes data);
  event LinkAmount(uint256 amount);

  function publicNewRequest(
    bytes32 _id,
    address _address,
    bytes memory _fulfillmentSignature
  ) public {
    Chainlink.Request memory req = buildChainlinkRequest(_id, _address, bytes4(keccak256(_fulfillmentSignature)));
    emit Request(req.id, req.callbackAddress, req.callbackFunctionId, req.buf.buf);
  }

  function publicRequest(
    bytes32 _id,
    address _address,
    bytes memory _fulfillmentSignature,
    uint256 _wei
  ) public {
    Chainlink.Request memory req = buildChainlinkRequest(_id, _address, bytes4(keccak256(_fulfillmentSignature)));
    sendChainlinkRequest(req, _wei);
  }

  function publicRequestRunTo(
    address _oracle,
    bytes32 _id,
    address _address,
    bytes memory _fulfillmentSignature,
    uint256 _wei
  ) public {
    Chainlink.Request memory run = buildChainlinkRequest(_id, _address, bytes4(keccak256(_fulfillmentSignature)));
    sendChainlinkRequestTo(_oracle, run, _wei);
  }

  function publicRequestOracleData(
    bytes32 _id,
    bytes memory _fulfillmentSignature,
    uint256 _wei
  ) public {
    Chainlink.Request memory req = buildOperatorRequest(_id, bytes4(keccak256(_fulfillmentSignature)));
    sendOperatorRequest(req, _wei);
  }

  function publicRequestOracleDataFrom(
    address _oracle,
    bytes32 _id,
    address _address,
    bytes memory _fulfillmentSignature,
    uint256 _wei
  ) public {
    Chainlink.Request memory run = buildOperatorRequest(_id, bytes4(keccak256(_fulfillmentSignature)));
    sendOperatorRequestTo(_oracle, run, _wei);
  }

  function publicCancelRequest(
    bytes32 _requestId,
    uint256 _payment,
    bytes4 _callbackFunctionId,
    uint256 _expiration
  ) public {
    cancelChainlinkRequest(_requestId, _payment, _callbackFunctionId, _expiration);
  }

  function publicChainlinkToken() public view returns (address) {
    return chainlinkTokenAddress();
  }

  function publicFulfillChainlinkRequest(bytes32 _requestId, bytes32) public {
    fulfillRequest(_requestId, bytes32(0));
  }

  function fulfillRequest(bytes32 _requestId, bytes32) public {
    validateChainlinkCallback(_requestId);
  }

  function publicLINK(uint256 _amount) public {
    emit LinkAmount(LINK_DIVISIBILITY.mul(_amount));
  }

  function publicOracleAddress() public view returns (address) {
    return chainlinkOracleAddress();
  }

  function publicAddExternalRequest(address _oracle, bytes32 _requestId) public {
    addChainlinkExternalRequest(_oracle, _requestId);
  }
}