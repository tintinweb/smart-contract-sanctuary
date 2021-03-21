// SPDX-License-Identifier: Apache 2.0

pragma solidity ^0.7.3;

contract beacon {
  // Global event namespace
  bytes32 constant EVENT_NAMESPACE = 'monax';

  // Event names
  bytes32 constant EVENT_NAME_REQUEST_CREATE_AGREEMENT = 'request:create-agreement';
  bytes32 constant EVENT_NAME_REQUEST_ADD_AGREEMENT_PARTY = 'request:add-agreement-party';
  bytes32 constant EVENT_NAME_REPORT_AGREEMENT_CREATION = 'report:agreement-creation';
  bytes32 constant EVENT_NAME_REPORT_AGREEMENT_STATE_CHANGE = 'report:agreement-state-change';

  // Prices- replace with whatever's reasonable later
  uint256 public constant BASE_PRICE = 1;
  uint256 public constant STATE_CHANGE_REPORT_PRICE = 1; // to implement later; price shoud depend on number of parties?

  struct CreateRequest {
    address msgSender;
    address txOrigin;
    uint256 tokenId;
    address tokenContractAddress;
    bytes32 templateId;
    uint64 templateConfig;
    address[] parties;
    bool reportStateChange;
    uint256 currentBlockHeight;
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
    uint8 state;
    uint256 currentBlockHeight;
    uint256 requestIndex; // maybe not necessary? can be tied to a single CreationReport via agreement which gives us the requestIndex.
    uint256 currentEventIndex;
  }

  // Request events
  event LogRequestCreateAgreement(
    bytes32 indexed eventNamespace,
    bytes32 indexed eventCategory,
    address indexed msgSender,
    address txOrigin,
    uint256 tokenId,
    address tokenContractAddress,
    bytes32 templateId,
    uint64 templateConfig,
    bool reportStateChange,
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

  // Report events
  // event LogReportAgreementCreation(
  //   bytes32 indexed eventNamespace,
  //   bytes32 indexed eventCategory,
  //   uint256 indexed tokenId,
  //   address tokenContractAddress,
  //   string errorCode,
  //   address agreement,
  //   string permalink,
  //   uint256 currentBlockHeight,
  //   uint256 requestIndex,
  //   uint256 currentEventIndex
  // );
  // event LogReportAgreementStateChange(
  //   bytes32 indexed eventNamespace,
  //   bytes32 indexed eventCategory,
  //   uint256 indexed tokenId,
  //   address tokenContractAddress,
  //   address agreement,
  //   uint8 state,
  //   uint256 currentBlockHeight,
  //   uint256 requestIndex,
  //   uint256 currentEventIndex
  // );
  // More reports to come... eg LogReportObligationCompleted?

  mapping(address => mapping(uint256 => CreateRequest)) createRequests;
  mapping(address => mapping(uint256 => CreationReport)) creationReports;
  mapping(address => mapping(uint256 => StateChangeReport)) stateChangeReports;

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

  modifier requireCharge(bool reportStateChange) {
    uint256 price = BASE_PRICE;
    if (reportStateChange) {
      price += STATE_CHANGE_REPORT_PRICE;
    }
    require(msg.value >= price, 'Insufficient funds for requested agreement and report(s)');
    _;
  }

  modifier addEvent(uint256 eventCount) {
    _;
    currentEventIndex += eventCount;
  }

  /**
   * Request
   */
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

  function emitCreateAgreementRequest(
    address tokenContractAddress,
    uint256 tokenId,
    bytes32 templateId,
    uint64 templateConfig,
    bool reportStateChange
  ) private addEvent(1) {
    emit LogRequestCreateAgreement(
      EVENT_NAMESPACE,
      EVENT_NAME_REQUEST_CREATE_AGREEMENT,
      msg.sender,
      tx.origin,
      tokenId,
      tokenContractAddress,
      templateId,
      templateConfig,
      reportStateChange,
      block.number,
      requestIndex,
      currentEventIndex
    );
  }

  function requestCreateAgreement(
    address tokenContractAddress,
    uint256 tokenId,
    bytes32 templateId,
    uint64 templateConfig,
    address[] memory parties,
    bool reportStateChange
  ) public payable requireCharge(reportStateChange) {
    requestIndex += 1;
    createRequests[tokenContractAddress][tokenId] = CreateRequest({
      msgSender: msg.sender,
      txOrigin: tx.origin,
      tokenId: tokenId,
      tokenContractAddress: tokenContractAddress,
      templateId: templateId,
      templateConfig: templateConfig,
      parties: parties,
      reportStateChange: reportStateChange,
      currentBlockHeight: block.number,
      requestIndex: requestIndex,
      currentEventIndex: currentEventIndex
    });
    emitAddPartyRequest(parties);
    emitCreateAgreementRequest(tokenContractAddress, tokenId, templateId, templateConfig, reportStateChange);
  }

  /**
   * Reports
   */
  function reportAgreementCreation(
    address tokenContractAddress,
    uint256 tokenId,
    string memory errorCode,
    address agreement,
    string memory permalink,
    uint256 requestIndexInput
  ) public ownersOnly() {
    //addEvent(1) {
    creationReports[tokenContractAddress][tokenId] = CreationReport({
      errorCode: errorCode,
      agreement: agreement,
      permalink: permalink,
      currentBlockHeight: block.number,
      requestIndex: requestIndexInput,
      currentEventIndex: currentEventIndex
    });
    // emit LogReportAgreementCreation(
    //   EVENT_NAMESPACE,
    //   EVENT_NAME_REPORT_AGREEMENT_CREATION,
    //   tokenId,
    //   tokenContractAddress,
    //   errorCode,
    //   agreement,
    //   permalink,
    //   block.number,
    //   requestIndex,
    //   currentEventIndex
    // );
  }

  function reportAgreementStateChange(
    address tokenContractAddress,
    uint256 tokenId,
    address agreement,
    uint8 state,
    uint256 requestIndexInput
  ) public ownersOnly() {
    //addEvent(1) {
    stateChangeReports[tokenContractAddress][tokenId] = StateChangeReport({
      agreement: agreement,
      state: state,
      currentBlockHeight: block.number,
      requestIndex: requestIndexInput,
      currentEventIndex: currentEventIndex
    });
    // emit LogReportAgreementStateChange(
    //   EVENT_NAMESPACE,
    //   EVENT_NAME_REPORT_AGREEMENT_STATE_CHANGE,
    //   tokenId,
    //   tokenContractAddress,
    //   agreement,
    //   state,
    //   block.number,
    //   requestIndex,
    //   currentEventIndex
    // );
  }

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