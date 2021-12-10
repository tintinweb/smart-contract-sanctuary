/**
 * @authors: [@greenlucid]
 * @reviewers: []
 * @auditors: []
 * @bounties: []
 * @deployments: []
 * SPDX-License-Identifier: Licenses are not real
 */

pragma solidity ^0.8.4;
import "@kleros/erc-792/contracts/IArbitrable.sol";
import "@kleros/erc-792/contracts/IArbitrator.sol";
import "@kleros/erc-792/contracts/erc-1497/IEvidence.sol";

/*
    things to think about

    Current TODO

    rename funcs to get addItem higher

    why not compress the function arguments? saves ~300 gas per argument...

    (assuming current prediction market contribution system sticks)
    should we keep the contributions of losing parties in rounds in which only
    losing party contributes, burned inside the contract?
    or have a way to rescue those spoils, somehow?

    you can, when you make a contrib, check if the contrib is enough to launch the appeal
    instead of launching the appeal separatedly
    the problem is that this would make contribute() more expensive.
    You'd have to view appealCost every single contribution.
*/

/**
 * @title Slot Curate
 * @author Green
 * @dev A gas optimized version of Curate, intended to be used with a subgraph.
 */
contract SlotCurate is IArbitrable, IEvidence {
  uint256 internal constant AMOUNT_BITSHIFT = 32; // this could make submitter lose up to 4 gwei
  uint256 internal constant RULING_OPTIONS = 2;
  uint256 internal constant DIVIDER = 1_000_000; // this is how you divide in solidity, or multiply by floats

  enum ProcessType {
    Add,
    Removal,
    Edit
  }

  enum Party {
    Requester,
    Challenger
  }

  enum DisputeState {
    Free,
    Used,
    Withdrawing
  }

  // settings cannot be mutated once created, otherwise pending processes could get attacked.
  struct Settings {
    uint80 requesterStake; // this is realAmount >> AMOUNT_BITSHIFT !!!!
    uint40 requestPeriod;
    uint64 multiplier; // divide by DIVIDER for float.
    uint72 freeSpace;
    bytes arbitratorExtraData;
  }

  struct Slot {
    uint8 slotdata; // holds "used", "processType" and "disputed", compressed in the same variable.
    uint48 settingsId; // settings spam attack is highly unlikely (1M years of full 15M gas blocks)
    uint40 requestTime; // overflow in 37k years
    address requester;
  }

  // all bounded data related to the DisputeSlot. unbounded data such as contributions is handled out
  // takes 3 slots
  struct DisputeSlot {
    uint256 arbitratorDisputeId; // required
    uint64 slotId; // flexible
    address challenger; // store it here instead of contributions[dispute][0]
    DisputeState state;
    uint8 currentRound;
    uint16 freeSpace;
    uint64 nContributions;
    uint64[2] pendingWithdraws; // pendingWithdraws[_party], used to set the disputeSlot free
    uint40 appealDeadline;
    Party winningParty; // for withdrawals, set at rule()
    uint16 freeSpace2;
  }

  struct Contribution {
    uint8 round; // could be bigger. but because exp cost on appeal, shouldn't be needed.
    uint8 contribdata; // compressed form of bool withdrawn, Party party.
    uint80 amount; // to be raised 32 bits.
    address contributor; // could be compressed to 64 bits, but there's no point.
  }

  struct RoundContributions {
    uint80[2] partyTotal; // partyTotal[Party]
    uint80 appealCost;
    uint16 filler; // to make sure the storage slot never goes back to zero, set it to 1 on discovery.
  }

  // EVENTS //

  event ListCreated(uint48 _settingsId, address _governor, string _ipfsUri);
  event ListUpdated(uint64 _listId, uint48 _settingsId, address _governor);

  event SettingsCreated(uint80 _requesterStake, uint40 _requestPeriod, uint64 multiplier, bytes _arbitratorExtraData);
  // why emit settingsId in the request events?
  // it's cheaper to trust the settingsId in the contract, than read it from the list and verifying
  // the subgraph can check the list at that time and ignore requests with invalid settings.
  // in an optimistic rollup, however, it will be refactored to store this information,

  // every byte costs 8 gas so 80 gas saving by publishing uint176
  event ItemAddRequest(uint176 _addRequestData, string _ipfsUri);
  event ItemRemovalRequest(uint240 _removalRequestData);
  event ItemEditRequest(uint240 _editRequestData, string _ipfsUri);
  // you don't need different events for accept / reject because subgraph remembers the progress per slot.
  event RequestAccepted(uint64 _slotId); // when request is executed after requestPeriod

  event RequestChallenged(uint64 _slotId, uint64 _disputeSlot);

  event NextRound(uint64 _disputeSlot);

  // both events below signal that the Dispute is in Withdrawing state.
  event RequestRejected(uint64 _slotId, uint64 _disputeSlot); // when dispute rules to reject the request
  event DisputeFailed(uint64 _disputeSlot); // signals that the request has its request period reset.

  // called when dispute has no withdraws remaining
  // automatically considers all pending contributions to be withdrawn (or, it deletes them)
  event FreedDisputeSlot(uint64 _disputeSlot);

  // these are to be able to query the contributions status from the subgraph,
  // contributionSlot does not have to be emitted because subgraph can count.
  event Contribute(uint64 _disputeSlot, uint8 _round, uint80 _amount, Party _party);
  event WithdrawnContribution(uint64 _disputeSlot, uint64 _contributionSlot);

  // CONTRACT STORAGE //

  IArbitrator internal immutable arbitrator; // only one arbitrator per contract. changing arbitrator requires redeployment
  // redeploying the contract has the issue of the contract needing settings to be the same in the same order

  uint48 internal settingsCount; // this gives unique ids, and allows to check if settings exist.

  mapping(uint64 => Slot) internal slots;
  mapping(uint64 => DisputeSlot) internal disputes;
  // a spam attack would take ~1M years of full mainnet blocks to deplete settings id space.
  mapping(uint48 => Settings) internal settingsMap;
  mapping(uint64 => mapping(uint64 => Contribution)) internal contributions; // contributions[disputeSlot][n]
  // roundContributionsMap[disputeSlot][round]
  mapping(uint64 => mapping(uint8 => RoundContributions)) internal roundContributionsMap;
  mapping(uint256 => uint64) internal disputeIdToDisputeSlot; // disputeIdToDisputeSlot[disputeId]

  /** @dev Constructs the SlotCurate contract.
   *  @param _arbitrator The address of the arbitrator.
   *  @param _addMetaEvidence The ipfs uri of the addMetaEvidence.
   *  @param _removalMetaEvidence The ipfs uri of the removalMetaEvidence.
   *  @param _editMetaEvidence The ipfs uri of the editMetaEvidence.
   */
  constructor(
    address _arbitrator,
    string memory _addMetaEvidence,
    string memory _removalMetaEvidence,
    string memory _editMetaEvidence
  ) {
    arbitrator = IArbitrator(_arbitrator);

    emit MetaEvidence(0, _addMetaEvidence);
    emit MetaEvidence(1, _removalMetaEvidence);
    emit MetaEvidence(2, _editMetaEvidence);
  }

  // PUBLIC FUNCTIONS

  /** @dev Creates a list that is stored in the subgraph. Its ID will be determined by a counter in the subgraph.
   *  @param _settingsId The id of the settings this list uses. It's verified in the subgraph.
   *  @param _governor The address of the list's governor, that's allowed to update the list.
   *  @param _ipfsUri The ipfs uri of the document detailing the submission requirements for the list.
   */
  function createList(
    uint48 _settingsId,
    address _governor,
    string calldata _ipfsUri
  ) external {
    // the following statement is not needed because it will be verified in the subgraph
    // require(_settingsId < settingsCount, "Settings must exist");
    emit ListCreated(_settingsId, _governor, _ipfsUri);
  }

  /** @dev Updates a list in the subgraph. Subgraph won't accept the update if the msg.sender is not _governor.
   *  Update does NOT allow changing _ipfsUri of the rules of the list, as that would be unfair
   *  if the rules change after unfinished requests are made, or while disputes are taking place.
   *  @param _listId The id of the list to be updated.
   *  @param _settingsId The id of the new settings of the list. It's verified to exist in the subgraph.
   *  @param _newGovernor The address of the new governor of the list.
   */
  function updateList(
    uint64 _listId,
    uint48 _settingsId,
    address _newGovernor
  ) external {
    emit ListUpdated(_listId, _settingsId, _newGovernor);
  }

  /** @dev Creates a settings, and stores it in the contract. Settings are immutable.
   *  @param _requesterStake The stake needed to make any request, be it add, edit or remove.
   *  It has to be already shifted right by 32 bits.
   *  @param _requestPeriod The period of time in seconds that the request must stay unchallenged
   *  To be added to the list.
   *  @param _multiplier A number used to calculate how much more amount is needed to appeal.
   *  When submitted, it has to be already multiplied by DIVIDER.
   *  @param _arbitratorExtraData The arbitratorExtraData used to create disputes.
   */
  function createSettings(
    uint80 _requesterStake,
    uint40 _requestPeriod,
    uint64 _multiplier,
    bytes calldata _arbitratorExtraData
  ) external {
    // require is not used. there can be up to 281T.
    // that's 1M years of full 15M gas blocks every 13s.
    // skipping it makes this cheaper. overflow is not gonna happen.
    // a rollup in which this was a risk might be possible, but then just remake the contract.
    // require(settingsCount != type(uint48).max, "Max settings reached");
    Settings storage settings = settingsMap[settingsCount++];
    settings.requesterStake = _requesterStake;
    settings.requestPeriod = _requestPeriod;
    settings.multiplier = _multiplier;
    settings.arbitratorExtraData = _arbitratorExtraData;
    emit SettingsCreated(_requesterStake, _requestPeriod, _multiplier, _arbitratorExtraData);
  }

  // None of the requests have refunds for overpaying. Consider the excess burned.
  // It is expected of the frontend to make the transaction with the
  // least significant bits set to zero in amount, to protect caller from losing those 4 gwei.

  /** @dev Creates a request to add an item to a list.
   *  @param _listId The id of the list the item is added to.
   *  If the list doesn't exist, the subgraph will ignore the request.
   *  @param _settingsId The trusted settings belonging to that list.
   *  It's trusted to optimize gas costs in mainnet. The subgraph will verify its correctness,
   *  and will ignore the request if the settings are not correct.
   *  @param _idSlot The id of the slot in which the request will have its lifecycle.
   *  This can be frontrun, so there's an equivalent function with frontrun protection.
   *  @param _ipfsUri The ipfs uri of the data of the item to be submitted to the list.
   */
  function addItem(
    uint64 _listId,
    uint48 _settingsId,
    uint64 _idSlot,
    string calldata _ipfsUri
  ) external payable {
    Slot storage slot = slots[_idSlot];
    // If free, it is of form 0xxx0000, so it's smaller than 128
    require(slot.slotdata < 128, "Slot must not be in use");
    require(msg.value >= _decompressAmount(settingsMap[_settingsId].requesterStake), "Not enough to cover stake");
    // used: true, disputed: false, processType: Add
    // _paramsToSlotdata(true, false, ProcessType.Add) = 128
    slot.slotdata = 128;
    slot.requestTime = uint40(block.timestamp);
    slot.requester = msg.sender;
    slot.settingsId = _settingsId;
    // format of uint176 addRequestData: [List: L, Settings: S, idSlot: I]
    // LLLLLLLLSSSSSSIIIIIIII
    emit ItemAddRequest(((_listId << 14) + (_settingsId << 8) + _idSlot), _ipfsUri);
  }

  /** @dev Equivalent to addItem, but with frontrun protection.
   *  @param _listId The id of the list the item is added to.
   *  If the list doesn't exist, the subgraph will ignore the request.
   *  @param _settingsId The trusted settings belonging to that list.
   *  It's trusted to optimize gas costs in mainnet. The subgraph will verify its correctness,
   *  and will ignore the request if the settings are not correct.
   *  @param _fromSlot The id of the slot to start iterating from.
   *  The function will create the request in the first available slot it finds.
   *  @param _ipfsUri The ipfs uri of the data of the item to be submitted to the list.
   */
  function addItemInFirstFreeSlot(
    uint64 _listId,
    uint48 _settingsId,
    uint64 _fromSlot,
    string calldata _ipfsUri
  ) external payable {
    uint64 workSlot = _firstFreeSlot(_fromSlot);
    require(msg.value >= _decompressAmount(settingsMap[_settingsId].requesterStake), "Not enough to cover stake");
    Slot storage slot = slots[workSlot];
    // used: true, disputed: false, processType: Add
    // _paramsToSlotdata(true, false, ProcessType.Add) = 128
    slot.slotdata = 128;
    slot.requestTime = uint40(block.timestamp);
    slot.requester = msg.sender;
    slot.settingsId = _settingsId;
    // format of uint176 addRequestData: [List: L, Settings: S, idSlot: I]
    // LLLLLLLLSSSSSSIIIIIIII
    emit ItemAddRequest(((_listId << 14) + (_settingsId << 8) + workSlot), _ipfsUri);
  }

  /** @dev Creates a request to remove an item from a list.
   *  @param _workSlot The slot in which the request will be processed.
   *  This can be frontrun, so there's an equivalent function with frontrun protection.
   *  @param _settingsId The trusted settings belonging to that list.
   *  It's trusted to optimize gas costs in mainnet. The subgraph will verify its correctness,
   *  and will ignore the request if the settings are not correct.
   *  @param _listId The id of the list the item is removed from.
   *  If the list doesn't exist, the subgraph will ignore the request.
   *  @param _itemId The id of the item to be removed from the list.
   *  @param _reason The ipfs uri of the reason to remove the item from the list.
   *  If incorrect, even if the item does not belong to the list for any other reason,
   *  It should be disputed as a failed request.
   */
  function removeItem(
    uint64 _workSlot,
    uint48 _settingsId,
    uint64 _listId,
    uint64 _itemId,
    string calldata _reason
  ) external payable {
    Slot storage slot = slots[_workSlot];
    // If free, it is of form 0xxx0000, so it's smaller than 128
    require(slot.slotdata < 128, "Slot must not be in use");
    require(msg.value >= _decompressAmount(settingsMap[_settingsId].requesterStake), "Not enough to cover stake");
    // used: true, disputed: false, processType: Removal
    // _paramsToSlotdata(true, false, ProcessType.Removal) = 144
    slot.slotdata = 144;
    slot.requestTime = uint40(block.timestamp);
    slot.requester = msg.sender;
    slot.settingsId = _settingsId;
    // format of uint240 removeRequestData: [WorkSlot: W, Settings: S, List: L, idItem: I]
    // WWWWWWWWSSSSSSLLLLLLLLIIIIIIII
    emit ItemRemovalRequest((_workSlot << 22) + (_settingsId << 16) + (_listId << 8) + _itemId);
    // the evidenceGroupId is the one of this one request.
    uint256 evidenceGroupId = uint256(keccak256(abi.encodePacked(_workSlot, uint40(block.timestamp))));
    emit Evidence(arbitrator, evidenceGroupId, msg.sender, _reason);
  }

  /** @dev Equivalent to removeItem, but with frontrun protection.
   *  @param _fromSlot The id of the slot to start iterating from.
   *  The function will create the request in the first available slot it finds.
   *  @param _settingsId The trusted settings belonging to that list.
   *  It's trusted to optimize gas costs in mainnet. The subgraph will verify its correctness,
   *  and will ignore the request if the settings are not correct.
   *  @param _listId The id of the list the item is removed from.
   *  If the list doesn't exist, the subgraph will ignore the request.
   *  @param _itemId The id of the item to be removed from the list.
   *  @param _reason The ipfs uri of the reason to remove the item from the list.
   *  If incorrect, even if the item does not belong to the list for any other reason,
   *  It should be disputed as a failed request.
   */
  function removeItemInFirstFreeSlot(
    uint64 _fromSlot,
    uint48 _settingsId,
    uint64 _listId,
    uint64 _itemId,
    string calldata _reason
  ) external payable {
    uint64 workSlot = _firstFreeSlot(_fromSlot);
    Slot storage slot = slots[workSlot];
    require(msg.value >= _decompressAmount(settingsMap[_settingsId].requesterStake), "Not enough to cover stake");
    // used: true, disputed: false, processType: Removal
    // _paramsToSlotdata(true, false, ProcessType.Removal) = 144
    slot.slotdata = 144;
    slot.requestTime = uint40(block.timestamp);
    slot.requester = msg.sender;
    slot.settingsId = _settingsId;
    // format of uint240 removeRequestData: [WorkSlot: W, Settings: S, List: L, idItem: I]
    // WWWWWWWWSSSSSSLLLLLLLLIIIIIIII
    emit ItemRemovalRequest((workSlot << 22) + (_settingsId << 16) + (_listId << 8) + _itemId);
    // the evidenceGroupId is the one of this one request.
    uint256 evidenceGroupId = uint256(keccak256(abi.encodePacked(workSlot, uint40(block.timestamp))));
    emit Evidence(arbitrator, evidenceGroupId, msg.sender, _reason);
  }

  /** @dev Creates a request to edit an item in a list.
   *  @param _workSlot The slot in which the request will be processed.
   *  This can be frontrun, so there's an equivalent function with frontrun protection.
   *  @param _settingsId The trusted settings belonging to that list.
   *  It's trusted to optimize gas costs in mainnet. The subgraph will verify its correctness,
   *  and will ignore the request if the settings are not correct.
   *  @param _listId The id of the list the item is edited in.
   *  If the list doesn't exist, the subgraph will ignore the request.
   *  @param _itemId The id of the item to be edited in the list.
   *  @param _ipfsUri The ipfs uri that links to the new data for the item.
   *  It will replace the previous data completely, but the item will maintain
   *  the same id inside the list.
   */
  function editItem(
    uint64 _workSlot,
    uint48 _settingsId,
    uint64 _listId,
    uint64 _itemId,
    string calldata _ipfsUri
  ) external payable {
    Slot storage slot = slots[_workSlot];
    // If free, it is of form 0xxx0000, so it's smaller than 128
    require(slot.slotdata < 128, "Slot must not be in use");
    require(msg.value >= _decompressAmount(settingsMap[_settingsId].requesterStake), "Not enough to cover stake");
    // used: true, disputed: false, processType: Edit
    // _paramsToSlotdata(true, false, ProcessType.Edit) = 160
    slot.slotdata = 160;
    slot.requestTime = uint40(block.timestamp);
    slot.requester = msg.sender;
    slot.settingsId = _settingsId;
    // format of uint240 editRequestData: [WorkSlot: W, Settings: S, List: L, idItem: I]
    // WWWWWWWWSSSSSSLLLLLLLLIIIIIIII
    emit ItemEditRequest(((_workSlot << 22) + (_settingsId << 16) + (_listId << 8) + _itemId), _ipfsUri);
  }

  /** @dev Creates a request to edit an item in a list.
   *  @param _fromSlot The id of the slot to start iterating from.
   *  The function will create the request in the first available slot it finds.
   *  @param _settingsId The trusted settings belonging to that list.
   *  It's trusted to optimize gas costs in mainnet. The subgraph will verify its correctness,
   *  and will ignore the request if the settings are not correct.
   *  @param _listId The id of the list the item is edited in.
   *  If the list doesn't exist, the subgraph will ignore the request.
   *  @param _itemId The id of the item to be edited in the list.
   *  @param _ipfsUri The ipfs uri that links to the new data for the item.
   *  It will replace the previous data completely, but the item will maintain
   *  the same id inside the list.
   */
  function editItemInFirstFreeSlot(
    uint64 _fromSlot,
    uint48 _settingsId,
    uint64 _listId,
    uint64 _itemId,
    string calldata _ipfsUri
  ) external payable {
    uint64 workSlot = _firstFreeSlot(_fromSlot);
    Slot storage slot = slots[workSlot];
    require(msg.value >= _decompressAmount(settingsMap[_settingsId].requesterStake), "Not enough to cover stake");
    // used: true, disputed: false, processType: Edit
    // _paramsToSlotdata(true, false, ProcessType.Edit) = 160
    slot.slotdata = 160;
    slot.requestTime = uint40(block.timestamp);
    slot.requester = msg.sender;
    slot.settingsId = _settingsId;
    // format of uint240 editRequestData: [WorkSlot: W, Settings: S, List: L, idItem: I]
    // WWWWWWWWSSSSSSLLLLLLLLIIIIIIII
    emit ItemEditRequest(((workSlot << 22) + (_settingsId << 16) + (_listId << 8) + _itemId), _ipfsUri);
  }

  /** @dev Accept a request that is over the requestPeriod and undisputed.
   *  @param _slotId The id of the slot containing the request to be accepted.
   */
  function executeRequest(uint64 _slotId) external {
    Slot storage slot = slots[_slotId];
    Settings storage settings = settingsMap[slot.settingsId];
    require(_slotIsExecutable(slot, settings.requestPeriod), "Slot cannot be executed");
    payable(slot.requester).transfer(settings.requesterStake);
    emit RequestAccepted(_slotId);
    // used to false, others don't matter.
    // _paramsToSlotdata(false, false, ProcessType.Add) = 0
    slot.slotdata = 0;
  }

  /** @dev Challenge a request that is not over the requestPeriod.
   *  @param _slotId The id of the slot containing the request to challenge.
   *  @param _disputeSlot The id of the disputeSlot in which the dispute data will be stored.
   *  This can be frontrun, so there's an equivalent function with frontrun protection.
   *  @param _reason The ipfs uri linking to a file describing the reason the request
   *  must be rejected. If the request is incorrect, but not for the reason the challenger
   *  is giving, then the dispute should fail.
   */
  function challengeRequest(
    uint64 _slotId,
    uint64 _disputeSlot,
    string calldata _reason
  ) public payable {
    Slot storage slot = slots[_slotId];
    Settings storage settings = settingsMap[slot.settingsId];
    require(_slotCanBeChallenged(slot, settings.requestPeriod), "Slot cannot be challenged");

    DisputeSlot storage dispute = disputes[_disputeSlot];
    require(dispute.state == DisputeState.Free, "That dispute slot is being used");

    // dont require enough to cover arbitration fees
    // arbitrator will already take care of it
    // challenger pays arbitration fees + gas costs fully

    uint256 arbitratorDisputeId = arbitrator.createDispute{value: msg.value}(RULING_OPTIONS, settings.arbitratorExtraData);
    // store disputeId -> disputeSlot for ruling later on. challenger pays this 20k cost.
    disputeIdToDisputeSlot[arbitratorDisputeId] = _disputeSlot;
    (, , ProcessType processType) = _slotdataToParams(slot.slotdata);
    uint8 newSlotdata = _paramsToSlotdata(true, true, processType);

    slot.slotdata = newSlotdata;
    dispute.arbitratorDisputeId = arbitratorDisputeId;
    dispute.slotId = _slotId;
    dispute.challenger = msg.sender;
    dispute.state = DisputeState.Used;
    dispute.currentRound = 0;

    dispute.nContributions = 0;
    dispute.pendingWithdraws[0] = 0;
    dispute.pendingWithdraws[1] = 0;
    dispute.appealDeadline = 0;
    // you don't need to reset dispute.winningParty because it's not used until Withdrawing
    // and to get to Withdrawing (in rule() function) you set the dispute.winningParty there
    dispute.freeSpace2 = 1; // to make sure slot never cannot go to zero.

    // initialize roundContributions of round: 1
    // will be 5k in reused. but 20k in new.
    RoundContributions storage roundContributions = roundContributionsMap[_disputeSlot][1];
    roundContributions.filler = 1;
    roundContributions.appealCost = 0;
    roundContributions.partyTotal[0] = 0;
    roundContributions.partyTotal[1] = 0;

    emit RequestChallenged(_slotId, _disputeSlot);
    // ERC 1497
    // the evidenceGroupId is obtained from the slot of the challenged request
    uint256 evidenceGroupId = uint256(keccak256(abi.encodePacked(_slotId, slot.requestTime)));
    // metaEvidenceId is related to the processType (different for Add, Removal or Edit)
    emit Dispute(arbitrator, arbitratorDisputeId, uint256(processType), evidenceGroupId);
    emit Evidence(arbitrator, evidenceGroupId, msg.sender, _reason);
  }

  /** @dev Like challengeRequest but with frontrun protection.
   *  @param _slotId The id of the slot containing the request to challenge.
   *  @param _fromSlot The id of the disputeSlot that will checked first for availability.
   *  It will create a dispute in the first available disputeSlot.
   *  @param _reason The ipfs uri linking to a file describing the reason the request
   *  must be rejected. If the request is incorrect, but not for the reason the challenger
   *  is giving, then the dispute should fail.
   */
  function challengeRequestInFirstFreeSlot(
    uint64 _slotId,
    uint64 _fromSlot,
    string calldata _reason
  ) public payable {
    uint64 disputeWorkSlot = _firstFreeDisputeSlot(_fromSlot);
    challengeRequest(_slotId, disputeWorkSlot, _reason);
  }

  /** @dev Submit Evidence to any evidenceGroupId
   *  @param _evidenceGroupId The evidenceGroupId the Evidence is submitted to.
   *  @param _evidence The ipfs uri linking to the file that contains the evidence.
   */
  function submitEvidence(uint256 _evidenceGroupId, string calldata _evidence) external {
    // you can just submit evidence directly to any _evidenceGroupId
    emit Evidence(arbitrator, _evidenceGroupId, msg.sender, _evidence);
  }

  /** @dev Make a contribution towards the appeal of a dispute.
   *  @param _disputeSlot The disputeSlot linked to the dispute the contribution is intended for.
   *  @param _party The party this contribution is siding with. This will decide if this
   *  contribution has a reward or not after the dispute is over.
   */
  function contribute(uint64 _disputeSlot, Party _party) public payable {
    DisputeSlot storage dispute = disputes[_disputeSlot];
    require(dispute.state == DisputeState.Used, "DisputeSlot has to be used");

    _verifyUnderAppealDeadline(dispute);

    dispute.nContributions++;
    dispute.pendingWithdraws[uint256(_party)]++;
    // compress amount, possibly losing up to 4 gwei. they will be burnt.
    uint80 amount = _compressAmount(msg.value);
    uint8 nextRound = dispute.currentRound + 1;
    roundContributionsMap[_disputeSlot][nextRound].partyTotal[uint256(_party)] += amount;

    // pendingWithdrawal = true, party = _party
    uint8 contribdata = _paramsToContribdata(true, _party);
    contributions[_disputeSlot][dispute.nContributions++] = Contribution({round: nextRound, contribdata: contribdata, contributor: msg.sender, amount: amount});
    emit Contribute(_disputeSlot, nextRound, amount, _party);
  }

  /** @dev Appeal a dispute and start the next round. It will use the contributed funds.
   *  @param _disputeSlot The disputeSlot linked to the dispute to be appealed.
   */
  function startNextRound(uint64 _disputeSlot) public {
    DisputeSlot storage dispute = disputes[_disputeSlot];
    uint8 nextRound = dispute.currentRound + 1; // to save gas with less storage reads
    Slot storage slot = slots[dispute.slotId];
    Settings storage settings = settingsMap[slot.settingsId];
    require(dispute.state == DisputeState.Used, "DisputeSlot has to be Used");

    _verifyUnderAppealDeadline(dispute);

    uint256 appealCost = arbitrator.appealCost(dispute.arbitratorDisputeId, settings.arbitratorExtraData);
    uint256 totalAmountNeeded = (appealCost * settings.multiplier) / DIVIDER;

    // make sure you have the required amount
    uint256 currentAmount = _decompressAmount(roundContributionsMap[_disputeSlot][nextRound].partyTotal[0] + roundContributionsMap[_disputeSlot][nextRound].partyTotal[1]);
    require(currentAmount >= totalAmountNeeded, "Not enough to fund round");

    // got enough, it's legit to do so. I can appeal, lets appeal
    arbitrator.appeal{value: appealCost}(dispute.arbitratorDisputeId, settings.arbitratorExtraData);

    // remember the appeal cost, for sharing the spoils later
    roundContributionsMap[_disputeSlot][nextRound].appealCost = _compressAmount(appealCost);

    dispute.currentRound++;

    // set the roundContributions of the upcoming round to zero.
    RoundContributions storage roundContributions = roundContributionsMap[_disputeSlot][nextRound + 1];
    roundContributions.appealCost = 0;
    roundContributions.partyTotal[0] = 0;
    roundContributions.partyTotal[1] = 0;
    roundContributions.filler = 1; // to avoid getting whole storage slot to 0.

    // this may not be needed, if the subgraph listens to the arbitrator
    // done because optimizing ~500 gas in the appeal function is not a priority
    emit NextRound(_disputeSlot);
  }

  /** @dev Give a ruling for a dispute. Can only be called by the arbitrator. TRUSTED.
   *  @param _disputeId The arbitrator id of the dispute.
   *  @param _ruling The ruling for the dispute.
   */
  function rule(uint256 _disputeId, uint256 _ruling) external override {
    // arbitrator is trusted to:
    // a. call this only once, after dispute is final
    // b. not call this with an unknown _disputeId (it would affect the disputeSlot = 0)
    require(msg.sender == address(arbitrator), "Only arbitrator can rule");
    //1. get slot from dispute
    uint64 disputeSlot = disputeIdToDisputeSlot[_disputeId];
    DisputeSlot storage dispute = disputes[disputeSlot];
    Slot storage slot = slots[dispute.slotId];
    // 2. make sure that dispute has an ongoing dispute
    require(dispute.state == DisputeState.Used, "Can only be executed if Used");
    // 3. apply ruling. what to do when refuse to arbitrate? dunno. maybe... just
    // default to requester, in that case.
    // 0 refuse, 1 requester, 2 challenger.
    if (_ruling == 1 || _ruling == 0) {
      // requester won.
      emit DisputeFailed(disputeSlot);
      dispute.winningParty = Party.Requester;
      // dispute.pendingInitialWithdraw stays at false, because challenger lost.
      // 5a. reset timestamp for the request, it will go through the period again.
      slot.requestTime = uint40(block.timestamp);
      (, , ProcessType processType) = _slotdataToParams(slot.slotdata);
      // used: true, disputed: false, ProcessType: processType
      slot.slotdata = _paramsToSlotdata(true, false, processType);
    } else {
      // challenger won. emit disputeslot to update the status to Withdrawing in the subgraph
      emit RequestRejected(dispute.slotId, disputeSlot);
      dispute.winningParty = Party.Challenger;
      // 5b. slot is now Free.. other slotdata doesn't matter.
      // _paramsToSlotdata(false, false, ProcessType.Add) = 0
      slot.slotdata = 0;

      // now, award the requesterStake to challenger
      Settings storage settings = settingsMap[slot.settingsId];
      uint256 amount = _decompressAmount(settings.requesterStake);
      // is it dangerous to send before the end of the function? please answer on audit
      payable(dispute.challenger).send(amount);
    }

    dispute.state = DisputeState.Withdrawing;
    emit Ruling(arbitrator, _disputeId, _ruling);
  }

  /** @dev Withdraw a single contribution from an appeal, if elegible for a reward.
   * @param _disputeSlot The disputeSlot the contribution was made for.
   * @param _contributionSlot The slot in which the contribution was stored.
   */
  function withdrawOneContribution(uint64 _disputeSlot, uint64 _contributionSlot) public {
    // check if dispute is used.
    DisputeSlot storage dispute = disputes[_disputeSlot];
    require(dispute.state == DisputeState.Withdrawing, "DisputeSlot must be in withdraw");
    require(dispute.nContributions > _contributionSlot, "DisputeSlot lacks that contrib");

    Contribution storage contribution = contributions[_disputeSlot][_contributionSlot];
    (bool pendingWithdrawal, Party party) = _contribdataToParams(contribution.contribdata);

    require(pendingWithdrawal, "Contribution withdrawn already");

    // okay, all checked. let's get the contribution.

    RoundContributions memory roundContributions = roundContributionsMap[_disputeSlot][contribution.round];
    Party winningParty = dispute.winningParty;

    if (roundContributions.appealCost != 0) {
      // then this is a contribution from an appealed round.
      // only winner party can withdraw.
      require(party == winningParty, "That side lost the dispute");

      _withdrawSingleReward(contribution, roundContributions, party);
    } else {
      // this is a contrib from a round that didnt get appealed.
      // just refund the same amount
      uint256 refund = _decompressAmount(contribution.amount);
      payable(contribution.contributor).transfer(refund);
    }

    if (dispute.pendingWithdraws[uint256(winningParty)] == 1) {
      // this was last contrib remaining
      // no need to decrement pendingWithdraws if last. saves gas.
      dispute.state = DisputeState.Free;
      emit FreedDisputeSlot(_disputeSlot);
    } else {
      dispute.pendingWithdraws[uint256(winningParty)]--;
      // set contribution as withdrawn. party doesn't matter, so it's chosen as Party.Requester
      // (pendingWithdrawal = false, party = Party.Requester) => paramsToContribution(false, Party.Requester) = 0
      contribution.contribdata = 0;
      emit WithdrawnContribution(_disputeSlot, _contributionSlot);
    }
  }

  /** @dev Withdraws all contributions and the initial stake, and sets the disputeSlot Free.
   *  @param _disputeSlot The target disputeSlot.
   */
  function withdrawAllContributions(uint64 _disputeSlot) public {
    // this func is a "public good". it uses less gas overall to withdraw all
    // contribs. because you only need to change 1 single flag to free the dispute slot.

    DisputeSlot storage dispute = disputes[_disputeSlot];
    require(dispute.state == DisputeState.Withdrawing, "DisputeSlot must be in withdraw");

    Party winningParty = dispute.winningParty;
    // this is due to how contribdata is encoded. the variable name is self-explanatory.
    uint8 pendingAndWinnerContribdata = 128 + 64 * uint8(winningParty);

    // there are two types of contribs that are handled differently:
    // 1. the contributions of appealed rounds.
    uint64 contribSlot = 0;
    uint8 currentRound = 1;
    RoundContributions memory roundContributions = roundContributionsMap[_disputeSlot][currentRound];
    while (contribSlot < dispute.nContributions) {
      Contribution memory contribution = contributions[_disputeSlot][contribSlot];
      // update the round
      if (contribution.round != currentRound) {
        roundContributions = roundContributionsMap[_disputeSlot][contribution.round];
        currentRound = contribution.round;
      }

      if (currentRound > dispute.currentRound) break; // see next loop.

      if (contribution.contribdata == pendingAndWinnerContribdata) {
        _withdrawSingleReward(contribution, roundContributions, winningParty);
      }
      contribSlot++;
    }

    // 2. the contributions of the last, unappealed round.
    while (contribSlot < dispute.nContributions) {
      // refund every transaction
      Contribution memory contribution = contributions[_disputeSlot][contribSlot];
      _refundContribution(contribution);
      contribSlot++;
    }
    // afterwards, set the dispute slot Free.
    dispute.state = DisputeState.Free;
    emit FreedDisputeSlot(_disputeSlot);
  }

  // PRIVATE FUNCTIONS

  /** @dev Called when dispute.appealDeadline is over block.timestamp.
   *  Will check arbitrator deadline, and revert if period is over.
   *  This is to read it from storage instead of calling an external function.
   *  @param _dispute The dispute that is verified.
   */
  function _verifyUnderAppealDeadline(DisputeSlot storage _dispute) private {
    if (block.timestamp >= _dispute.appealDeadline) {
      // you're over it. get updated appealPeriod
      (, uint256 end) = arbitrator.appealPeriod(_dispute.arbitratorDisputeId);
      require(block.timestamp < end, "Over submision period");
      _dispute.appealDeadline = uint40(end);
    }
  }

  /** @dev Withdraws a contribution as a reward.
   *  @param _contribution The contribution to be withdrawn.
   *  @param _roundContributions The contributions of the round to figure out the reward.
   *  @param _winningParty The party that won the dispute.
   */
  function _withdrawSingleReward(
    Contribution memory _contribution,
    RoundContributions memory _roundContributions,
    Party _winningParty
  ) private {
    uint256 spoils = _decompressAmount(_roundContributions.partyTotal[0] + _roundContributions.partyTotal[1] - _roundContributions.appealCost);
    uint256 share = (spoils * uint256(_contribution.amount)) / uint256(_roundContributions.partyTotal[uint256(_winningParty)]);
    // should use transfer instead? if transfer fails, then disputeSlot will stay in DisputeState.Withdrawing
    // if a transaction reverts due to not enough gas, does the send() ether remain sent? if that's so,
    // it would break withdrawAllContributions as currently designed,
    // and for single withdraws, then sending the ether will have to be the very last thing that occurs
    // after all the flags have been modified.
    payable(_contribution.contributor).send(share);
  }

  /** @dev Refunds a contribution when the round for that contribution wasn't appealed.
   *  @param _contribution The contribution to refund.
   */
  function _refundContribution(Contribution memory _contribution) private {
    uint256 refund = _decompressAmount(_contribution.amount);
    // should use send instead? if transfer fails, then disputeSlot will stay in DisputeState.Withdrawing
    // if a transaction reverts due to not enough gas, does the send() ether remain sent?
    payable(_contribution.contributor).transfer(refund);
  }

  // VIEW FUNCTIONS

  // These three public view functions, I don't think they're necessary to have them here.
  // You can get the arbitrator and make a query to check this directly in the frontend,
  // all the needed data to make these queries is in the subgraph.
  // Give me your opinion on removing them.

  /** @dev Check the challenge fee a challenger would incur if challenging a request.
   *  @param _slotId The id of the slot.
   *  @return The arbitration fee to challenge a request.
   */
  function challengeFee(uint64 _slotId) public view returns (uint256) {
    Slot storage slot = slots[_slotId];
    Settings storage settings = settingsMap[slot.settingsId];

    return (arbitrator.arbitrationCost(settings.arbitratorExtraData));
  }

  /** @dev Get the cost of making an appeal for a dispute.
   *  @param _disputeSlot The slot containing the dispute.
   *  @return The cost of appealing the dispute.
   */
  function appealCost(uint64 _disputeSlot) public view returns (uint256) {
    DisputeSlot memory disputeSlot = disputes[_disputeSlot];
    Slot memory slot = slots[disputeSlot.slotId];
    Settings memory settings = settingsMap[slot.settingsId];
    return (arbitrator.appealCost(disputeSlot.arbitratorDisputeId, settings.arbitratorExtraData));
  }

  /** @dev Get the appeal period of making an appeal for a dispute.
   *  @param _disputeSlot The slot containing the dispute.
   *  @return (start, end) the two instants of time you can appeal a dispute.
   */
  function appealPeriod(uint64 _disputeSlot) public view returns (uint256, uint256) {
    DisputeSlot memory disputeSlot = disputes[_disputeSlot];
    return (arbitrator.appealPeriod(disputeSlot.arbitratorDisputeId));
  }

  // From here, all view functions are internal.

  /** @dev Get the first free request slot from a given point.
   *  Relying on this in the frontend could result in collisions.
   *  This view function is used for the frontrun protection request functions.
   *  @param _startPoint The point from which you start looking for a free slot.
   *  @return The first free request slot from the starting point.
   */
  function _firstFreeSlot(uint64 _startPoint) internal view returns (uint64) {
    uint64 i = _startPoint;
    // this is used == true, because if used, slotdata is of shape 1xxx0000, so it's larger than 127
    while (slots[i].slotdata > 127) {
      i++;
    }
    return i;
  }

  /** @dev Get the first free dispute slot from a given point.
   *  Relying on this in the frontend could result in collisions.
   *  This view function is used for the frontrun protection request functions.
   *  @param _startPoint The point from which you start looking for a free slot.
   *  @return The first free dispute slot from the starting point.
   */
  function _firstFreeDisputeSlot(uint64 _startPoint) internal view returns (uint64) {
    uint64 i = _startPoint;
    while (disputes[i].state == DisputeState.Used) {
      i++;
    }
    return i;
  }

  /** @dev Check if a slot can be executed.
   *  @param _slot The slot to check.
   *  @param _requestPeriod The period the request has to last to be executable.
   *  @return True if the slot can be executed, false otherwise.
   */
  function _slotIsExecutable(Slot memory _slot, uint40 _requestPeriod) internal view returns (bool) {
    (bool used, bool disputed, ) = _slotdataToParams(_slot.slotdata);
    return used && (block.timestamp > _slot.requestTime + _requestPeriod) && !disputed;
  }

  /** @dev Check if a slot can be challenged.
   *  @param _slot The slot to check.
   *  @param _requestPeriod The period the request has to last to be executable.
   *  @return True if the slot can be executed, false otherwise.
   */
  function _slotCanBeChallenged(Slot memory _slot, uint40 _requestPeriod) internal view returns (bool) {
    (bool used, bool disputed, ) = _slotdataToParams(_slot.slotdata);
    return used && !(block.timestamp > _slot.requestTime + _requestPeriod) && !disputed;
  }

  /** @dev Compress slot request variables for storage.
   *  @param _used The usage status of the slot.
   *  @param _disputed The disputed status of the slot.
   *  @param _processType The type of request contained in the slot (add, removal, edit)
   *  @return The compressed data.
   */
  function _paramsToSlotdata(
    bool _used,
    bool _disputed, // you store disputed to stop someone from calling executeRequest
    ProcessType _processType
  ) internal pure returns (uint8) {
    uint8 usedAddend;
    if (_used) usedAddend = 128;
    uint8 disputedAddend;
    if (_disputed) disputedAddend = 64;
    uint8 processTypeAddend;
    if (_processType == ProcessType.Removal) processTypeAddend = 16;
    if (_processType == ProcessType.Edit) processTypeAddend = 32;
    uint8 slotdata = usedAddend + processTypeAddend + disputedAddend;
    return slotdata;
  }

  /** @dev Decompress slotdata to its variables.
   *  @param _slotdata The slotdata to decompress.
   *  @return (used, disputed, processType), the decompressed variables of the slotdata.
   */
  function _slotdataToParams(uint8 _slotdata)
    internal
    pure
    returns (
      bool,
      bool,
      ProcessType
    )
  {
    uint8 usedAddend = _slotdata & 128;
    bool used = usedAddend != 0;
    uint8 disputedAddend = _slotdata & 64;
    bool disputed = disputedAddend != 0;

    uint8 processTypeAddend = _slotdata & 48;
    ProcessType processType = ProcessType(processTypeAddend >> 4);

    return (used, disputed, processType);
  }

  /** @dev Compress contribution variables for storage.
   *  @param _pendingWithdrawal The status of withdrawal of the contribution.
   *  @param _party The party supported by the contribution.
   *  @return The compressed data.
   */
  function _paramsToContribdata(bool _pendingWithdrawal, Party _party) internal pure returns (uint8) {
    uint8 pendingWithdrawalAddend;
    if (_pendingWithdrawal) pendingWithdrawalAddend = 128;
    uint8 partyAddend;
    if (_party == Party.Challenger) partyAddend = 64;

    uint8 contribdata = pendingWithdrawalAddend + partyAddend;
    return contribdata;
  }

  /** @dev Decompress contribdata to its variables.
   *  @param _contribdata The contribdata to decompress.
   *  @return (pendingWithdrawal, party), the decompressed variables of the contribdata.
   */
  function _contribdataToParams(uint8 _contribdata) internal pure returns (bool, Party) {
    uint8 pendingWithdrawalAddend = _contribdata & 128;
    bool pendingWithdrawal = pendingWithdrawalAddend != 0;
    uint8 partyAddend = _contribdata & 64;
    Party party = Party(partyAddend >> 6);

    return (pendingWithdrawal, party);
  }

  // always compress / decompress rounding down.
  /** @dev Compress an amount by shifting its bits to the right.
   *  @param _amount The uint256 version of the amount.
   *  @return The uint80 compressed version of the amount.
   */
  function _compressAmount(uint256 _amount) internal pure returns (uint80) {
    return (uint80(_amount >> AMOUNT_BITSHIFT));
  }

  /** @dev Decompress an amount by shifting its bits to the left
   *  @param _compressedAmount The uint80 compressed version of the amount.
   *  @return The uint256 version of the amount, losing its 32 less significant bits, up to 4 gwei.
   */
  function _decompressAmount(uint80 _compressedAmount) internal pure returns (uint256) {
    return (uint256(_compressedAmount) << AMOUNT_BITSHIFT);
  }
}

/**
 * @authors: [@ferittuncer, @hbarcelos]
 * @reviewers: [@remedcu]
 * @auditors: []
 * @bounties: []
 * @deployments: []
 * SPDX-License-Identifier: MIT
 */
pragma solidity ^0.8.0;

import "./IArbitrator.sol";

/**
 * @title IArbitrable
 * Arbitrable interface.
 * When developing arbitrable contracts, we need to:
 * - Define the action taken when a ruling is received by the contract.
 * - Allow dispute creation. For this a function must call arbitrator.createDispute{value: _fee}(_choices,_extraData);
 */
interface IArbitrable {
    /**
     * @dev To be raised when a ruling is given.
     * @param _arbitrator The arbitrator giving the ruling.
     * @param _disputeID ID of the dispute in the Arbitrator contract.
     * @param _ruling The ruling which was given.
     */
    event Ruling(IArbitrator indexed _arbitrator, uint256 indexed _disputeID, uint256 _ruling);

    /**
     * @dev Give a ruling for a dispute. Must be called by the arbitrator.
     * The purpose of this function is to ensure that the address calling it has the right to rule on the contract.
     * @param _disputeID ID of the dispute in the Arbitrator contract.
     * @param _ruling Ruling given by the arbitrator. Note that 0 is reserved for "Not able/wanting to make a decision".
     */
    function rule(uint256 _disputeID, uint256 _ruling) external;
}

/**
 * @authors: [@ferittuncer, @hbarcelos]
 * @reviewers: [@remedcu]
 * @auditors: []
 * @bounties: []
 * @deployments: []
 * SPDX-License-Identifier: MIT
 */

pragma solidity ^0.8.0;

import "./IArbitrable.sol";

/**
 * @title Arbitrator
 * Arbitrator abstract contract.
 * When developing arbitrator contracts we need to:
 * - Define the functions for dispute creation (createDispute) and appeal (appeal). Don't forget to store the arbitrated contract and the disputeID (which should be unique, may nbDisputes).
 * - Define the functions for cost display (arbitrationCost and appealCost).
 * - Allow giving rulings. For this a function must call arbitrable.rule(disputeID, ruling).
 */
interface IArbitrator {
    enum DisputeStatus {
        Waiting,
        Appealable,
        Solved
    }

    /**
     * @dev To be emitted when a dispute is created.
     * @param _disputeID ID of the dispute.
     * @param _arbitrable The contract which created the dispute.
     */
    event DisputeCreation(uint256 indexed _disputeID, IArbitrable indexed _arbitrable);

    /**
     * @dev To be emitted when a dispute can be appealed.
     * @param _disputeID ID of the dispute.
     * @param _arbitrable The contract which created the dispute.
     */
    event AppealPossible(uint256 indexed _disputeID, IArbitrable indexed _arbitrable);

    /**
     * @dev To be emitted when the current ruling is appealed.
     * @param _disputeID ID of the dispute.
     * @param _arbitrable The contract which created the dispute.
     */
    event AppealDecision(uint256 indexed _disputeID, IArbitrable indexed _arbitrable);

    /**
     * @dev Create a dispute. Must be called by the arbitrable contract.
     * Must be paid at least arbitrationCost(_extraData).
     * @param _choices Amount of choices the arbitrator can make in this dispute.
     * @param _extraData Can be used to give additional info on the dispute to be created.
     * @return disputeID ID of the dispute created.
     */
    function createDispute(uint256 _choices, bytes calldata _extraData) external payable returns (uint256 disputeID);

    /**
     * @dev Compute the cost of arbitration. It is recommended not to increase it often, as it can be highly time and gas consuming for the arbitrated contracts to cope with fee augmentation.
     * @param _extraData Can be used to give additional info on the dispute to be created.
     * @return cost Amount to be paid.
     */
    function arbitrationCost(bytes calldata _extraData) external view returns (uint256 cost);

    /**
     * @dev Appeal a ruling. Note that it has to be called before the arbitrator contract calls rule.
     * @param _disputeID ID of the dispute to be appealed.
     * @param _extraData Can be used to give extra info on the appeal.
     */
    function appeal(uint256 _disputeID, bytes calldata _extraData) external payable;

    /**
     * @dev Compute the cost of appeal. It is recommended not to increase it often, as it can be higly time and gas consuming for the arbitrated contracts to cope with fee augmentation.
     * @param _disputeID ID of the dispute to be appealed.
     * @param _extraData Can be used to give additional info on the dispute to be created.
     * @return cost Amount to be paid.
     */
    function appealCost(uint256 _disputeID, bytes calldata _extraData) external view returns (uint256 cost);

    /**
     * @dev Compute the start and end of the dispute's current or next appeal period, if possible. If not known or appeal is impossible: should return (0, 0).
     * @param _disputeID ID of the dispute.
     * @return start The start of the period.
     * @return end The end of the period.
     */
    function appealPeriod(uint256 _disputeID) external view returns (uint256 start, uint256 end);

    /**
     * @dev Return the status of a dispute.
     * @param _disputeID ID of the dispute to rule.
     * @return status The status of the dispute.
     */
    function disputeStatus(uint256 _disputeID) external view returns (DisputeStatus status);

    /**
     * @dev Return the current ruling of a dispute. This is useful for parties to know if they should appeal.
     * @param _disputeID ID of the dispute.
     * @return ruling The ruling which has been given or the one which will be given if there is no appeal.
     */
    function currentRuling(uint256 _disputeID) external view returns (uint256 ruling);
}

/**
 * @authors: [@ferittuncer, @hbarcelos]
 * @reviewers: []
 * @auditors: []
 * @bounties: []
 * @deployments: []
 * SPDX-License-Identifier: MIT
 */
pragma solidity ^0.8.0;

import "../IArbitrator.sol";

/** @title IEvidence
 *  ERC-1497: Evidence Standard
 */
interface IEvidence {
    /**
     * @dev To be emitted when meta-evidence is submitted.
     * @param _metaEvidenceID Unique identifier of meta-evidence.
     * @param _evidence IPFS path to metaevidence, example: '/ipfs/Qmarwkf7C9RuzDEJNnarT3WZ7kem5bk8DZAzx78acJjMFH/metaevidence.json'
     */
    event MetaEvidence(uint256 indexed _metaEvidenceID, string _evidence);

    /**
     * @dev To be raised when evidence is submitted. Should point to the resource (evidences are not to be stored on chain due to gas considerations).
     * @param _arbitrator The arbitrator of the contract.
     * @param _evidenceGroupID Unique identifier of the evidence group the evidence belongs to.
     * @param _party The address of the party submiting the evidence. Note that 0x0 refers to evidence not submitted by any party.
     * @param _evidence IPFS path to evidence, example: '/ipfs/Qmarwkf7C9RuzDEJNnarT3WZ7kem5bk8DZAzx78acJjMFH/evidence.json'
     */
    event Evidence(
        IArbitrator indexed _arbitrator,
        uint256 indexed _evidenceGroupID,
        address indexed _party,
        string _evidence
    );

    /**
     * @dev To be emitted when a dispute is created to link the correct meta-evidence to the disputeID.
     * @param _arbitrator The arbitrator of the contract.
     * @param _disputeID ID of the dispute in the Arbitrator contract.
     * @param _metaEvidenceID Unique identifier of meta-evidence.
     * @param _evidenceGroupID Unique identifier of the evidence group that is linked to this dispute.
     */
    event Dispute(
        IArbitrator indexed _arbitrator,
        uint256 indexed _disputeID,
        uint256 _metaEvidenceID,
        uint256 _evidenceGroupID
    );
}