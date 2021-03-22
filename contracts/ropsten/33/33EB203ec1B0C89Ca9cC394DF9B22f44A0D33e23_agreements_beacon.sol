// SPDX-License-Identifier: Apache 2.0

pragma solidity ^0.7.3;

contract agreements_beacon {
  // Global event namespace
  bytes32 constant EVENT_NAMESPACE = 'monax';

  // Event names
  bytes32 constant EVENT_NAME_ACTIVATE_BEACON = 'request:activate-beacon';
  bytes32 constant EVENT_NAME_REQUEST_CREATE_AGREEMENT = 'request:create-agreement';
  bytes32 constant EVENT_NAME_REQUEST_ADD_AGREEMENT_PARTY = 'request:add-agreement-party';
  bytes32 constant EVENT_NAME_REPORT_AGREEMENT_STATUS = 'report:agreement-status';

  // Prices
  uint256 public constant agreementBeaconPrice = 1; // TODO

  // Global object definitions
  enum LegalState {DRAFT, FORMULATED, EXECUTED, FULFILLED, DEFAULT, CANCELED, UNDEFINED, REDACTED}

  struct Beacon {
    bool activated;
    bytes32 templateId;
  }

  // One of msgSender, txOrigin, or parties[0] must be registered user of monax with a wallet
  // connected to this chain
  struct AgreementCreationRequest {
    address msgSender;
    address txOrigin;
    address tokenContractAddress;
    uint256 tokenId;
    address[] parties;
    bytes32 templateId;
    string templateConfig;
    uint256 currentBlockHeight; // Source blockchain height upon request
    uint256 requestIndex; // Ties a report back to its original request
    uint256 currentEventIndex; // Global index across all event types
  }

  struct AgreementStatus {
    address agreement;
    LegalState state;
    string url;
    string errorCode;
    uint256 requestIndex;
    uint256 currentBlockHeight;
    uint256 currentEventIndex;
  }

  // Request events are segmented between the agreement and the parties
  event LogActivateBeacon(
    bytes32 indexed eventNamespace,
    bytes32 indexed eventCategory,
    address indexed msgSender,
    address txOrigin,
    address tokenContractAddress,
    uint256 tokenId,
    bytes32 templateId,
    uint256 requestIndex,
    uint256 currentBlockHeight,
    uint256 currentEventIndex
  );

  event LogRequestCreateAgreement(
    bytes32 indexed eventNamespace,
    bytes32 indexed eventCategory,
    address indexed msgSender,
    address txOrigin,
    address tokenContractAddress,
    uint256 tokenId,
    bytes32 templateId,
    string templateConfig,
    uint256 requestIndex,
    uint256 currentBlockHeight,
    uint256 currentEventIndex
  );
  event LogRequestAddAgreementParty(
    bytes32 indexed eventNamespace,
    bytes32 indexed eventCategory,
    uint256 indexed requestIndex,
    address party
  );

  // Response events
  event LogAgreementStatus(
    bytes32 indexed eventNamespace,
    bytes32 indexed eventCategory,
    address agreement,
    LegalState state,
    string url,
    string errorCode,
    uint256 requestIndex,
    uint256 currentBlockHeight,
    uint256 currentEventIndex
  );

  // Internal database
  mapping(address => mapping(uint256 => Beacon)) beacons;
  mapping(address => mapping(uint256 => AgreementCreationRequest)) createRequests;
  mapping(address => mapping(uint256 => AgreementStatus)) agreements;

  // Global variables
  uint256 requestIndex;
  uint256 currentEventIndex;
  address[] owners;

  constructor(address[] memory _owners) {
    require(_owners.length > 0, 'At least one contract owner is required');
    requestIndex = 1;
    owners = _owners;
  }

  /**
   * Utility functions
   */
  modifier ownersOnly() {
    bool isOwner;
    for (uint256 i; i < owners.length; i++) {
      if (msg.sender == owners[i]) {
        isOwner = true;
      }
    }
    require(isOwner, 'Sender must be a contract owner');
    _;
  }

  modifier requireCharge() {
    uint256 price = agreementBeaconPrice;
    require(msg.value >= price, 'Insufficient funds for requested agreement and report(s)');
    _;
  }

  modifier addEvent(uint256 eventCount) {
    _;
    currentEventIndex += eventCount;
  }

  /**
   * Emit events
   */
  function emitActivateBeacon(
    address tokenContractAddress,
    uint256 tokenId,
    bytes32 templateId
  ) private addEvent(1) {
    emit LogActivateBeacon(
      EVENT_NAMESPACE,
      EVENT_NAME_ACTIVATE_BEACON,
      msg.sender,
      tx.origin,
      tokenContractAddress,
      tokenId,
      templateId,
      requestIndex,
      block.number,
      currentEventIndex
    );
  }

  function emitCreateAgreementRequest(
    address tokenContractAddress,
    uint256 tokenId,
    string memory templateConfig
  ) private addEvent(1) {
    emit LogRequestCreateAgreement(
      EVENT_NAMESPACE,
      EVENT_NAME_REQUEST_CREATE_AGREEMENT,
      msg.sender,
      tx.origin,
      tokenContractAddress,
      tokenId,
      beacons[tokenContractAddress][tokenId].templateId,
      templateConfig,
      requestIndex,
      block.number,
      currentEventIndex
    );
  }

  function emitAddPartyRequest(address[] memory parties) private addEvent(parties.length) {
    for (uint256 i = 0; i < parties.length; i++) {
      emit LogRequestAddAgreementParty(
        EVENT_NAMESPACE,
        EVENT_NAME_REQUEST_ADD_AGREEMENT_PARTY,
        requestIndex,
        parties[i]
      );
    }
  }

  function emitAgreementStatus(AgreementStatus memory status) private addEvent(1) {
    emit LogAgreementStatus(
      EVENT_NAMESPACE,
      EVENT_NAME_REPORT_AGREEMENT_STATUS,
      status.agreement,
      status.state,
      status.url,
      status.errorCode,
      status.requestIndex,
      block.number,
      currentEventIndex
    );
  }

  /**
   * Public mutable functions
   */
  function activateBeacon(
    address tokenContractAddress,
    uint256 tokenId,
    bytes32 templateId
  ) public payable requireCharge() {
    requestIndex += 1;
    beacons[tokenContractAddress][tokenId] = Beacon({activated: true, templateId: templateId});
    emitActivateBeacon(tokenContractAddress, tokenId, templateId);
  }

  function requestCreateAgreement(
    address tokenContractAddress,
    uint256 tokenId,
    address[] memory parties,
    string memory templateConfig
  ) public payable requireCharge() {
    requestIndex += 1;
    createRequests[tokenContractAddress][tokenId] = AgreementCreationRequest({
      msgSender: msg.sender,
      txOrigin: tx.origin,
      tokenContractAddress: tokenContractAddress,
      tokenId: tokenId,
      parties: parties,
      templateId: beacons[tokenContractAddress][tokenId].templateId,
      templateConfig: templateConfig,
      currentBlockHeight: block.number,
      requestIndex: requestIndex,
      currentEventIndex: currentEventIndex
    });
    emitAddPartyRequest(parties);
    emitCreateAgreementRequest(tokenContractAddress, tokenId, templateConfig);
  }

  /**
   * Owner mutable functions
   */
  function reportAgreementStatus(
    address tokenContractAddress,
    uint256 tokenId,
    address agreement,
    LegalState state,
    string memory url,
    string memory errorCode,
    uint256 requestIndexInput
  ) public ownersOnly() {
    AgreementStatus memory newStatus;
    AgreementStatus memory previousStatus = agreements[tokenContractAddress][tokenId];
    if (previousStatus.requestIndex == 0) {
      newStatus.agreement = agreement;
      newStatus.state = state;
      newStatus.url = url;
      newStatus.errorCode = errorCode;
      newStatus.requestIndex = requestIndexInput;
    } else {
      newStatus.agreement = agreement;
      newStatus.state = state;
      newStatus.url = previousStatus.url;
      newStatus.errorCode = previousStatus.errorCode;
      newStatus.requestIndex = previousStatus.requestIndex;
    }
    newStatus.currentBlockHeight = block.number;
    newStatus.currentEventIndex = currentEventIndex;
    agreements[tokenContractAddress][tokenId] = newStatus;
    emitAgreementStatus(newStatus);
  }

  /**
   * Public view functions
   */
  function getAgreementId(address tokenContractAddress, uint256 tokenId) public view returns (address agreement) {
    return agreements[tokenContractAddress][tokenId].agreement;
  }

  function getAgreementURL(address tokenContractAddress, uint256 tokenId) public view returns (string memory) {
    return agreements[tokenContractAddress][tokenId].url;
  }

  function getAgreementErrorCode(address tokenContractAddress, uint256 tokenId) public view returns (string memory) {
    return agreements[tokenContractAddress][tokenId].errorCode;
  }

  function getAgreementStatus(address tokenContractAddress, uint256 tokenId) public view returns (LegalState state) {
    return agreements[tokenContractAddress][tokenId].state;
  }
}