// SPDX-License-Identifier: Apache 2.0

pragma solidity ^0.7.3;

contract agreements_beacon {
  // Global event namespace
  bytes32 constant EVENT_NAMESPACE = 'monax';

  // Event names
  bytes32 constant EVENT_NAME_REQUEST_CREATE_AGREEMENT = 'request:create-agreement';
  bytes32 constant EVENT_NAME_REQUEST_ADD_AGREEMENT_PARTY = 'request:add-agreement-party';
  bytes32 constant EVENT_NAME_REPORT_AGREEMENT_CREATION = 'report:agreement-creation';
  bytes32 constant EVENT_NAME_REPORT_AGREEMENT_STATE_CHANGE = 'report:agreement-state-change';

  // Prices
  uint256 public constant agreementBeaconPrice = 1; // TODO

  // Global object definitions
  enum LegalState {DRAFT, FORMULATED, EXECUTED, FULFILLED, DEFAULT, CANCELED, UNDEFINED, REDACTED}

  // One of msgSender, txOrigin, or parties[0] must be registered user of monax with a wallet
  // connected to this chain
  struct CreateRequest {
    address msgSender;
    address txOrigin;
    address tokenContractAddress;
    uint256 tokenId;
    address[] parties;
    bytes32 templateId; // nullable
    uint64 templateConfig; // nullable
    uint256 currentBlockHeight; // Source blockchain height upon request
    uint256 requestIndex; // Ties a report back to its original request
    uint256 currentEventIndex; // Global index across all event types
  }

  struct CreationReport {
    string errorCode;
    address agreement;
    string permalink;
    uint256 currentBlockHeight;
    uint256 requestIndex;
    uint256 currentEventIndex;
  }

  struct StateChangeReport {
    address agreement;
    LegalState state;
    uint256 currentBlockHeight;
    uint256 currentEventIndex;
  }

  // Request events are segmented between the agreement and the parties
  event LogRequestCreateAgreement(
    bytes32 indexed eventNamespace,
    bytes32 indexed eventCategory,
    address indexed msgSender,
    address txOrigin,
    address tokenContractAddress,
    uint256 tokenId,
    bytes32 templateId,
    uint64 templateConfig,
    uint256 currentBlockHeight,
    uint256 requestIndex,
    uint256 currentEventIndex
  );
  event LogRequestAddAgreementParty(
    bytes32 indexed eventNamespace,
    bytes32 indexed eventCategory,
    uint256 indexed requestIndex,
    address party
  );

  // Internal database
  mapping(address => mapping(uint256 => CreateRequest)) createRequests;
  mapping(address => mapping(uint256 => CreationReport)) creationReports;
  mapping(address => mapping(uint256 => StateChangeReport)) stateChangeReports;

  // Global variables
  uint256 requestIndex;
  uint256 currentEventIndex;
  address[] owners;

  constructor(address[] memory _owners) {
    require(_owners.length > 0, 'At least one contract owner is required');
    owners = _owners;
  }

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
   * Emit request events
   */
  function emitCreateAgreementRequest(
    address tokenContractAddress,
    uint256 tokenId,
    bytes32 templateId,
    uint64 templateConfig
  ) private addEvent(1) {
    emit LogRequestCreateAgreement(
      EVENT_NAMESPACE,
      EVENT_NAME_REQUEST_CREATE_AGREEMENT,
      msg.sender,
      tx.origin,
      tokenContractAddress,
      tokenId,
      templateId,
      templateConfig,
      block.number,
      requestIndex,
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

  /**
   * Public mutable functions
   */
  function requestCreateAgreement(
    address tokenContractAddress,
    uint256 tokenId,
    address[] memory parties,
    bytes32 templateId, // nullable
    uint64 templateConfig // nullable
  ) public payable requireCharge() {
    requestIndex += 1;
    createRequests[tokenContractAddress][tokenId] = CreateRequest({
      msgSender: msg.sender,
      txOrigin: tx.origin,
      tokenContractAddress: tokenContractAddress,
      tokenId: tokenId,
      parties: parties,
      templateId: templateId,
      templateConfig: templateConfig,
      currentBlockHeight: block.number,
      requestIndex: requestIndex,
      currentEventIndex: currentEventIndex
    });
    emitAddPartyRequest(parties);
    emitCreateAgreementRequest(tokenContractAddress, tokenId, templateId, templateConfig);
  }

  /**
   * Owner mutable functions
   */
  function reportAgreementCreation(
    address tokenContractAddress,
    uint256 tokenId,
    string memory errorCode,
    address agreement,
    string memory permalink,
    uint256 requestIndexInput
  ) public ownersOnly() {
    creationReports[tokenContractAddress][tokenId] = CreationReport({
      errorCode: errorCode,
      agreement: agreement,
      permalink: permalink,
      currentBlockHeight: block.number,
      requestIndex: requestIndexInput,
      currentEventIndex: currentEventIndex
    });
  }

  function reportAgreementStateChange(
    address tokenContractAddress,
    uint256 tokenId,
    address agreement,
    LegalState state
  ) public ownersOnly() {
    stateChangeReports[tokenContractAddress][tokenId] = StateChangeReport({
      agreement: agreement,
      state: state,
      currentBlockHeight: block.number,
      currentEventIndex: currentEventIndex
    });
  }

  /**
   * Public view functions
   */
  function getAgreementId(address tokenContractAddress, uint256 tokenId) public view returns (address agreement) {
    return creationReports[tokenContractAddress][tokenId].agreement;
  }

  function getAgreementPermalink(address tokenContractAddress, uint256 tokenId) public view returns (string memory) {
    return creationReports[tokenContractAddress][tokenId].permalink;
  }

  function getAgreementErrorCode(address tokenContractAddress, uint256 tokenId) public view returns (string memory) {
    return creationReports[tokenContractAddress][tokenId].errorCode;
  }

  function getAgreementStatus(address tokenContractAddress, uint256 tokenId) public view returns (int8 state) {
    bool created = creationReports[tokenContractAddress][tokenId].agreement != address(0);
    bool hasStatus = stateChangeReports[tokenContractAddress][tokenId].agreement != address(0);
    if (created && !hasStatus) {
      return 0;
    } else if (hasStatus) {
      return int8(stateChangeReports[tokenContractAddress][tokenId].state);
    } else {
      return -1;
    }
  }
}