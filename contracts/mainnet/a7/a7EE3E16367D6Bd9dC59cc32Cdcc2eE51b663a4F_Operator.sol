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
contract Operator is
  AuthorizedReceiver,
  ConfirmedOwner,
  LinkTokenReceiver,
  OperatorInterface,
  WithdrawalInterface
{
  using Address for address;
  using SafeMathChainlink for uint256;

  struct Commitment {
    bytes31 paramsHash;
    uint8 dataVersion;
  }

  uint256 constant public getExpiryTime = 5 minutes;
  uint256 constant private MAXIMUM_DATA_VERSION = 256;
  uint256 constant private MINIMUM_CONSUMER_GAS_LIMIT = 400000;
  uint256 constant private SELECTOR_LENGTH = 4;
  uint256 constant private EXPECTED_REQUEST_WORDS = 2;
  uint256 constant private MINIMUM_REQUEST_LENGTH = SELECTOR_LENGTH + (32 * EXPECTED_REQUEST_WORDS);
  // We initialize fields to 1 instead of 0 so that the first invocation
  // does not cost more gas.
  uint256 constant private ONE_FOR_CONSISTENT_GAS_COST = 1;
  // oracleRequest is version 1, enabling single word responses
  bytes4 constant private ORACLE_REQUEST_SELECTOR = this.oracleRequest.selector;
  // requestOracleData is version 2, enabling multi-word responses
  bytes4 constant private OPERATOR_REQUEST_SELECTOR = this.requestOracleData.selector;

  LinkTokenInterface internal immutable linkToken;
  mapping(bytes32 => Commitment) private s_commitments;
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

  event CancelOracleRequest(
    bytes32 indexed requestId
  );

  event OracleResponse(
    bytes32 indexed requestId
  );

  event OwnableContractAccepted(
    address indexed accpetedContract
  );

  event TargetsUpdatedAuthorizedSenders(
    address[] targets,
    address[] senders,
    address changedBy
  );

  /**
   * @notice Deploy with the address of the LINK token
   * @dev Sets the LinkToken address for the imported LinkTokenInterface
   * @param link The address of the LINK token
   * @param owner The address of the owner
   */
  constructor(
    address link,
    address owner
  )
    ConfirmedOwner(owner)
  {
    linkToken = LinkTokenInterface(link); // external but already deployed and unalterable
  }

  function oracleRequest(
    address sender,
    uint256 payment,
    bytes32 specId,
    address callbackAddress,
    bytes4 callbackFunctionId,
    uint256 nonce,
    uint256 dataVersion,
    bytes calldata data
  )
    external
    override
  {
    requestOracleData(
      sender,
      payment,
      specId,
      callbackAddress,
      callbackFunctionId,
      nonce,
      dataVersion,
      data
    );
  }

  /**
   * @notice Creates the Chainlink request
   * @dev Stores the hash of the params as the on-chain commitment for the request.
   * Emits OracleRequest event for the Chainlink node to detect.
   * @param sender The sender of the request
   * @param payment The amount of payment given (specified in wei)
   * @param specId The Job Specification ID
   * @param callbackAddress The callback address for the response
   * @param callbackFunctionId The callback function ID for the response
   * @param nonce The nonce sent by the requester
   * @param dataVersion The specified data version
   * @param data The CBOR payload of the request
   */
  function requestOracleData(
    address sender,
    uint256 payment,
    bytes32 specId,
    address callbackAddress,
    bytes4 callbackFunctionId,
    uint256 nonce,
    uint256 dataVersion,
    bytes calldata data
  )
    public
    override
    validateFromLINK()
    validateNotToLINK(callbackAddress)
  {
    (bytes32 requestId, uint256 expiration) = _verifyOracleRequest(
      sender,
      payment,
      callbackAddress,
      callbackFunctionId,
      nonce,
      dataVersion
    );
    emit OracleRequest(
      specId,
      sender,
      requestId,
      payment,
      callbackAddress,
      callbackFunctionId,
      expiration,
      dataVersion,
      data);
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
    validateAuthorizedSender()
    validateRequestId(requestId)
    returns (
      bool
    )
  {
    _verifyOracleResponse(
      requestId,
      payment,
      callbackAddress,
      callbackFunctionId,
      expiration,
      1
    );
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
    validateAuthorizedSender()
    validateRequestId(requestId)
    validateMultiWordResponseId(requestId, data)
    returns (
      bool
    )
  {
    _verifyOracleResponse(
      requestId,
      payment,
      callbackAddress,
      callbackFunctionId,
      expiration,
      2
    );
    emit OracleResponse(requestId);
    require(gasleft() >= MINIMUM_CONSUMER_GAS_LIMIT, "Must provide consumer enough gas");
    // All updates to the oracle's fulfillment should come before calling the
    // callback(addr+functionId) as it is untrusted.
    // See: https://solidity.readthedocs.io/en/develop/security-considerations.html#use-the-checks-effects-interactions-pattern
    (bool success, ) = callbackAddress.call(abi.encodePacked(callbackFunctionId, data)); // solhint-disable-line avoid-low-level-calls
    return success;
  }

  /**
   * @notice Transfer the ownership of ownable contracts
   * @param ownable list of addresses to transfer
   * @param newOwner address to transfer ownership to
   */
  function transferOwnableContracts(
    address[] calldata ownable,
    address newOwner
  )
    external
    onlyOwner()
  {
    for (uint256 i = 0; i < ownable.length; i++) {
      OwnableInterface(ownable[i]).transferOwnership(newOwner);
    }
  }

  /**
   * @notice Accept the ownership of an ownable contract
   * @dev Must be the pending owner on the contract
   * @param ownable list of addresses of Ownable contracts to accept
   */
  function acceptOwnableContracts(
    address[] calldata ownable
  )
    public
    validateAuthorizedSenderSetter()
  {
    for (uint256 i = 0; i < ownable.length; i++) {
      OwnableInterface(ownable[i]).acceptOwnership();
      emit OwnableContractAccepted(ownable[i]);
    }
  }

  /**
   * @notice Sets the fulfillment permission for
   * @param targets The addresses to set permissions on
   * @param senders The addresses that are allowed to send updates
   */
  function setAuthorizedSendersOn(
    address[] calldata targets,
    address[] calldata senders
  )
    public
    validateAuthorizedSenderSetter()
  {
    TargetsUpdatedAuthorizedSenders(targets, senders, msg.sender);

    for (uint256 i = 0; i < targets.length; i++) {
      AuthorizedReceiverInterface(targets[i]).setAuthorizedSenders(senders);
    }
  }

  /**
   * @notice Sets the fulfillment permission for
   * @param targets The addresses to set permissions on
   * @param senders The addresses that are allowed to send updates
   */
  function acceptAuthorizedReceivers(
    address[] calldata targets,
    address[] calldata senders
  )
    external
    validateAuthorizedSenderSetter()
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
  function withdraw(
    address recipient,
    uint256 amount
  )
    external
    override(OracleInterface, WithdrawalInterface)
    onlyOwner()
    validateAvailableFunds(amount)
  {
    assert(linkToken.transfer(recipient, amount));
  }

  /**
   * @notice Displays the amount of LINK that is available for the node operator to withdraw
   * @dev We use `ONE_FOR_CONSISTENT_GAS_COST` in place of 0 in storage
   * @return The amount of withdrawable LINK on the contract
   */
  function withdrawable()
    external
    view
    override(OracleInterface, WithdrawalInterface)
    returns (uint256)
  {
    return _fundsAvailable();
  }

  /**
   * @notice Forward a call to another contract
   * @dev Only callable by the owner
   * @param to address
   * @param data to forward
   */
  function ownerForward(
    address to,
    bytes calldata data
  )
    external
    onlyOwner()
    validateNotToLINK(to)
  {
    require(to.isContract(), "Must forward to a contract");
    (bool status,) = to.call(data);
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
  )
    external
    override
    onlyOwner()
    validateAvailableFunds(value)
    returns (
      bool success
    )
  {
    return linkToken.transferAndCall(to, value, data);
  }

  /**
   * @notice Distribute funds to multiple addresses using ETH send
   * to this payable function.
   * @dev Array length must be equal, ETH sent must equal the sum of amounts.
   * @param receivers list of addresses
   * @param amounts list of amounts
   */
  function distributeFunds(
    address payable[] calldata receivers,
    uint[] calldata amounts
  )
    external
    payable
  {
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
   * @notice Allows requesters to cancel requests sent to this oracle contract. Will transfer the LINK
   * sent for the request back to the requester's address.
   * @dev Given params must hash to a commitment stored on the contract in order for the request to be valid
   * Emits CancelOracleRequest event.
   * @param requestId The request ID
   * @param payment The amount of payment given (specified in wei)
   * @param callbackFunc The requester's specified callback address
   * @param expiration The time of the expiration for the request
   */
  function cancelOracleRequest(
    bytes32 requestId,
    uint256 payment,
    bytes4 callbackFunc,
    uint256 expiration
  )
    external
    override
  {
    bytes31 paramsHash = _buildFunctionHash(payment, msg.sender, callbackFunc, expiration);
    require(s_commitments[requestId].paramsHash == paramsHash, "Params do not match request ID");
    // solhint-disable-next-line not-rely-on-time
    require(expiration <= block.timestamp, "Request is not expired");

    delete s_commitments[requestId];
    emit CancelOracleRequest(requestId);

    assert(linkToken.transfer(msg.sender, payment));
  }

  /**
   * @notice Returns the address of the LINK token
   * @dev This is the public implementation for chainlinkTokenAddress, which is
   * an internal method of the ChainlinkClient contract
   */
  function getChainlinkToken()
    public
    view
    override
    returns (
      address
    )
  {
    return address(linkToken);
  }


  /**
   * @notice Require that the token transfer action is valid
   * @dev OPERATOR_REQUEST_SELECTOR = multiword, ORACLE_REQUEST_SELECTOR = singleword
   */
  function _validateTokenTransferAction(
    bytes4 funcSelector,
    bytes memory data
  )
    internal
    override
    pure
  {
    require(data.length >= MINIMUM_REQUEST_LENGTH, "Invalid request length");
    require(funcSelector == OPERATOR_REQUEST_SELECTOR || funcSelector == ORACLE_REQUEST_SELECTOR, "Must use whitelisted functions");
  }

  /**
   * @notice Verify the Oracle Request
   * @param sender The sender of the request
   * @param payment The amount of payment given (specified in wei)
   * @param callbackAddress The callback address for the response
   * @param callbackFunctionId The callback function ID for the response
   * @param nonce The nonce sent by the requester
   */
  function _verifyOracleRequest(
    address sender,
    uint256 payment,
    address callbackAddress,
    bytes4 callbackFunctionId,
    uint256 nonce,
    uint256 dataVersion
  )
    private
    returns (
      bytes32 requestId,
      uint256 expiration
    )
  {
    requestId = keccak256(abi.encodePacked(sender, nonce));
    require(s_commitments[requestId].paramsHash == 0, "Must use a unique ID");
    // solhint-disable-next-line not-rely-on-time
    expiration = block.timestamp.add(getExpiryTime);
    bytes31 paramsHash = _buildFunctionHash(payment, callbackAddress, callbackFunctionId, expiration);
    s_commitments[requestId] = Commitment(paramsHash, _safeCastToUint8(dataVersion));
    s_tokensInEscrow = s_tokensInEscrow.add(payment);
    return (requestId, expiration);
  }

  /**
   * @notice Verify the Oracle Response
   * @param requestId The fulfillment request ID that must match the requester's
   * @param payment The payment amount that will be released for the oracle (specified in wei)
   * @param callbackAddress The callback address to call for fulfillment
   * @param callbackFunctionId The callback function ID to use for fulfillment
   * @param expiration The expiration that the node should respond by before the requester can cancel
   */
  function _verifyOracleResponse(
    bytes32 requestId,
    uint256 payment,
    address callbackAddress,
    bytes4 callbackFunctionId,
    uint256 expiration,
    uint256 dataVersion
  )
    internal
  {
    bytes31 paramsHash = _buildFunctionHash(payment, callbackAddress, callbackFunctionId, expiration);
    require(s_commitments[requestId].paramsHash == paramsHash, "Params do not match request ID");
    require(s_commitments[requestId].dataVersion <= _safeCastToUint8(dataVersion), "Data versions must match");
    s_tokensInEscrow = s_tokensInEscrow.sub(payment);
    delete s_commitments[requestId];
  }

  /**
   * @notice Build the bytes31 function hash from the payment, callback and expiration.
   * @param payment The payment amount that will be released for the oracle (specified in wei)
   * @param callbackAddress The callback address to call for fulfillment
   * @param callbackFunctionId The callback function ID to use for fulfillment
   * @param expiration The expiration that the node should respond by before the requester can cancel
   * @return hash bytes31
   */
  function _buildFunctionHash(
    uint256 payment,
    address callbackAddress,
    bytes4 callbackFunctionId,
    uint256 expiration
  )
    internal
    pure
    returns (
      bytes31
    )
  {
    return bytes31(keccak256(
      abi.encodePacked(
        payment,
        callbackAddress,
        callbackFunctionId,
        expiration
      )
    ));
  }

  /**
   * @notice Safely cast uint256 to uint8
   * @param number uint256
   * @return uint8 number
   */
  function _safeCastToUint8(
    uint256 number
  )
    internal
    pure
    returns (
      uint8
    )
  {
    require(number < MAXIMUM_DATA_VERSION, "number too big to cast");
    return uint8(number);
  }

  /**
   * @notice Returns the LINK available in this contract, not locked in escrow
   * @return uint256 LINK tokens available
   */
  function _fundsAvailable()
    private
    view
    returns (
      uint256
    )
  {
    uint256 inEscrow = s_tokensInEscrow.sub(ONE_FOR_CONSISTENT_GAS_COST);
    return linkToken.balanceOf(address(this)).sub(inEscrow);
  }

  /**
   * @notice concrete implementation of AuthorizedReceiver
   * @return bool of whether sender is authorized
   */
  function _canSetAuthorizedSenders()
    internal
    view
    override
    returns (bool)
  {
    return isAuthorizedSender(msg.sender) || owner() == msg.sender;
  }


  // MODIFIERS

  /**
   * @dev Reverts if the first 32 bytes of the bytes array is not equal to requestId
   * @param requestId bytes32
   * @param data bytes
   */
  modifier validateMultiWordResponseId(
    bytes32 requestId,
    bytes memory data
  ) {
    bytes32 firstWord;
    assembly{
      firstWord := mload(add(data, 0x20))
    }
    require(requestId == firstWord, "First word must be requestId");
    _;
  }

  /**
   * @dev Reverts if amount requested is greater than withdrawable balance
   * @param amount The given amount to compare to `s_withdrawableTokens`
   */
  modifier validateAvailableFunds(
    uint256 amount
  ) {
    require(_fundsAvailable() >= amount, "Amount requested is greater than withdrawable balance");
    _;
  }

  /**
   * @dev Reverts if request ID does not exist
   * @param requestId The given request ID to check in stored `commitments`
   */
  modifier validateRequestId(
    bytes32 requestId
  ) {
    require(s_commitments[requestId].paramsHash != 0, "Must have a valid requestId");
    _;
  }

  /**
   * @dev Reverts if the callback address is the LINK token
   * @param to The callback address
   */
  modifier validateNotToLINK(
    address to
  ) {
    require(to != address(linkToken), "Cannot call to LINK");
    _;
  }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./interfaces/AuthorizedReceiverInterface.sol";

abstract contract AuthorizedReceiver is
  AuthorizedReceiverInterface
{

  mapping(address => bool) private s_authorizedSenders;
  address[] private s_authorizedSenderList;

  event AuthorizedSendersChanged(
    address[] senders,
    address changedBy
  );

  /**
   * @notice Sets the fulfillment permission for a given node. Use `true` to allow, `false` to disallow.
   * @param senders The addresses of the authorized Chainlink node
   */
  function setAuthorizedSenders(
    address[] calldata senders
  )
    external
    override
    validateAuthorizedSenderSetter()
  {
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
  function getAuthorizedSenders()
    external
    view
    override
    returns (
      address[] memory
    )
  {
    return s_authorizedSenderList;
  }

  /**
   * @notice Use this to check if a node is authorized for fulfilling requests
   * @param sender The address of the Chainlink node
   * @return The authorization status of the node
   */
  function isAuthorizedSender(
    address sender
  )
    public
    view
    override
    returns (bool)
  {
    return s_authorizedSenders[sender];
  }

  /**
   * @notice customizable guard of who can update the authorized sender list
   * @return bool whether sender can update authorized sender list
   */
  function _canSetAuthorizedSenders()
    internal
    virtual
    returns (bool);

  /**
   * @notice validates the sender is an authorized sender
   */
  function _validateIsAuthorizedSender()
    internal
    view
  {
    require(isAuthorizedSender(msg.sender), "Not authorized sender");
  }

  /**
   * @notice prevents non-authorized addresses from calling this method
   */
  modifier validateAuthorizedSender()
  {
    _validateIsAuthorizedSender();
    _;
  }

  /**
   * @notice prevents non-authorized addresses from calling this method
   */
  modifier validateAuthorizedSenderSetter()
  {
    require(_canSetAuthorizedSenders(), "Cannot set authorized senders");
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
  )
    public
    validateFromLINK()
    permittedFunctionsForLINK(data)
  {
    assembly {
      // solhint-disable-next-line avoid-low-level-calls
      mstore(add(data, 36), sender) // ensure correct sender is passed
      // solhint-disable-next-line avoid-low-level-calls
      mstore(add(data, 68), amount)    // ensure correct amount is passed
    }
    // solhint-disable-next-line avoid-low-level-calls
    (bool success, ) = address(this).delegatecall(data); // calls oracleRequest
    require(success, "Unable to create request");
  }

  function getChainlinkToken()
    public
    view
    virtual
    returns (
      address
    );

  /**
   * @notice Validate the function called on token transfer
   */
  function _validateTokenTransferAction(
    bytes4 funcSelector,
    bytes memory data
  )
    internal
    virtual;

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
  modifier permittedFunctionsForLINK(
    bytes memory data
  ) {
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

  constructor(
    address newOwner
  )
    ConfirmedOwnerWithProposal(
      newOwner,
      address(0)
    )
  {
  }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface LinkTokenInterface {

  function allowance(
    address owner,
    address spender
  )
    external
    view
    returns (
      uint256 remaining
    );

  function approve(
    address spender,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function balanceOf(
    address owner
  )
    external
    view
    returns (
      uint256 balance
    );

  function decimals()
    external
    view
    returns (
      uint8 decimalPlaces
    );

  function decreaseApproval(
    address spender,
    uint256 addedValue
  )
    external
    returns (
      bool success
    );

  function increaseApproval(
    address spender,
    uint256 subtractedValue
  ) external;

  function name()
    external
    view
    returns (
      string memory tokenName
    );

  function symbol()
    external
    view
    returns (
      string memory tokenSymbol
    );

  function totalSupply()
    external
    view
    returns (
      uint256 totalTokensIssued
    );

  function transfer(
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  )
    external
    returns (
      bool success
    );

  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./ChainlinkRequestInterface.sol";
import "./OracleInterface.sol";

interface OperatorInterface is
  ChainlinkRequestInterface,
  OracleInterface
{

  function requestOracleData(
    address sender,
    uint256 payment,
    bytes32 specId,
    address callbackAddress,
    bytes4 callbackFunctionId,
    uint256 nonce,
    uint256 dataVersion,
    bytes calldata data
  )
    external;

  function fulfillOracleRequest2(
    bytes32 requestId,
    uint256 payment,
    address callbackAddress,
    bytes4 callbackFunctionId,
    uint256 expiration,
    bytes calldata data
  )
    external
    returns (
      bool
    );

  function ownerTransferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  )
    external
    returns (
      bool success
    );

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface OwnableInterface {
  function owner()
    external
    returns (
      address
    );

  function transferOwnership(
    address recipient
  )
    external;

  function acceptOwnership()
    external;
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
  function withdraw(
    address recipient,
    uint256 amount
  ) external;

  /**
   * @notice query the available amount of LINK to withdraw by msg.sender
   */
  function withdrawable()
    external
    view
    returns (
      uint256
    );
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
        assembly { size := extcodesize(account) }
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
        (bool success, ) = recipient.call{ value: amount }("");
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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
  function add(
    uint256 a,
    uint256 b
  )
    internal
    pure
    returns (
      uint256
    )
  {
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
  function sub(
    uint256 a,
    uint256 b
  )
    internal
    pure
    returns (
      uint256
    )
  {
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
  function mul(
    uint256 a,
    uint256 b
  )
    internal
    pure
    returns (
      uint256
    )
  {
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
  function div(
    uint256 a,
    uint256 b
  )
    internal
    pure
    returns (
      uint256
    )
  {
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
  function mod(
    uint256 a,
    uint256 b
  )
    internal
    pure
    returns (
      uint256
    )
  {
    require(b != 0, "SafeMath: modulo by zero");
    return a % b;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface AuthorizedReceiverInterface {

  function isAuthorizedSender(
    address sender
  )
    external
    view
    returns (bool);

  function getAuthorizedSenders()
    external
    returns (
      address[] memory
    );

  function setAuthorizedSenders(
    address[] calldata senders
  )
    external;

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

  event OwnershipTransferRequested(
    address indexed from,
    address indexed to
  );
  event OwnershipTransferred(
    address indexed from,
    address indexed to
  );

  constructor(
    address newOwner,
    address pendingOwner
  ) {
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
  function transferOwnership(
    address to
  )
    public
    override
    onlyOwner()
  {
    _transferOwnership(to);
  }

  /**
   * @notice Allows an ownership transfer to be completed by the recipient.
   */
  function acceptOwnership()
    external
    override
  {
    require(msg.sender == s_pendingOwner, "Must be proposed owner");

    address oldOwner = s_owner;
    s_owner = msg.sender;
    s_pendingOwner = address(0);

    emit OwnershipTransferred(oldOwner, msg.sender);
  }

  /**
   * @notice Get the current owner
   */
  function owner()
    public
    view
    override
    returns (
      address
    )
  {
    return s_owner;
  }

  /**
   * @notice validate, transfer ownership, and emit relevant events
   */
  function _transferOwnership(
    address to
  )
    private
  {
    require(to != msg.sender, "Cannot transfer to self");

    s_pendingOwner = to;

    emit OwnershipTransferRequested(s_owner, to);
  }

  /**
   * @notice validate access
   */
  function _validateOwnership()
    internal
    view
  {
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
  )
    external
    returns (
      bool
    );

  function withdraw(
    address recipient,
    uint256 amount
  ) external;

  function withdrawable()
    external
    view
    returns (
      uint256
    );
}