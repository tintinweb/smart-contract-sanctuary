/**
 * SPDX-License-Identifier: MIT
 * @authors: @ferittuncer
 * @reviewers: [@shalzz*]
 * @auditors: []
 * @bounties: []
 * @deployments: []
 */

pragma solidity ^0.8.10;
import "@kleros/dispute-resolver-interface-contract/contracts/IDisputeResolver.sol";
import "./IProveMeWrong.sol";

/*
·---------------------------------------|---------------------------|--------------|-----------------------------·
|         Solc version: 0.8.10          ·  Optimizer enabled: true  ·  Runs: 1000  ·  Block limit: 30000000 gas  │
········································|···························|··············|······························
|  Methods                              ·               100 gwei/gas               ·       4218.94 usd/eth       │
·················|······················|·············|·············|··············|···············|··············
|  Contract      ·  Method              ·  Min        ·  Max        ·  Avg         ·  # calls      ·  usd (avg)  │
·················|······················|·············|·············|··············|···············|··············
|  Arbitrator    ·  createDispute       ·      82579  ·      99679  ·       84289  ·           20  ·      35.56  │
·················|······················|·············|·············|··············|···············|··············
|  Arbitrator    ·  executeRuling       ·          -  ·          -  ·       66719  ·            3  ·      28.15  │
·················|······················|·············|·············|··············|···············|··············
|  Arbitrator    ·  giveRuling          ·      78640  ·      98528  ·       93556  ·            4  ·      39.47  │
·················|······················|·············|·············|··············|···············|··············
|  ProveMeWrong  ·  challenge           ·          -  ·          -  ·      147901  ·            3  ·      62.40  │
·················|······················|·············|·············|··············|···············|··············
|  ProveMeWrong  ·  fundAppeal          ·     133525  ·     138580  ·      135547  ·            5  ·      57.19  │
·················|······················|·············|·············|··············|···············|··············
|  ProveMeWrong  ·  increaseBounty      ·          -  ·          -  ·       28602  ·            2  ·      12.07  │
·················|······················|·············|·············|··············|···············|··············
|  ProveMeWrong  ·  initializeClaim     ·      31655  ·      51060  ·       38956  ·           10  ·      16.44  │
·················|······················|·············|·············|··············|···············|··············
|  ProveMeWrong  ·  initiateWithdrawal  ·          -  ·          -  ·       28085  ·            4  ·      11.85  │
·················|······················|·············|·············|··············|···············|··············
|  ProveMeWrong  ·  submitEvidence      ·          -  ·          -  ·       26117  ·            2  ·      11.02  │
·················|······················|·············|·············|··············|···············|··············
|  ProveMeWrong  ·  withdraw            ·      28403  ·      35103  ·       30636  ·            3  ·      12.93  │
·················|······················|·············|·············|··············|···············|··············
|  Deployments                          ·                                          ·  % of limit   ·             │
········································|·············|·············|··············|···············|··············
|  Arbitrator                           ·          -  ·          -  ·      877877  ·        2.9 %  ·     370.37  │
········································|·············|·············|··············|···············|··············
|  ProveMeWrong                         ·          -  ·          -  ·     2322785  ·        7.7 %  ·     979.97  │
·---------------------------------------|-------------|-------------|--------------|---------------|-------------·
*/

/** @title  Prove Me Wrong
    @notice Smart contract for a type of curation, where submitted items are on hold until they are withdrawn and the amount of security deposits are determined by submitters.
    @dev    Claims are not addressed with their identifiers. That enables us to reuse same storage address for another claim later.
            Arbitrator and the extra data is fixed. Also the metaevidence. Deploy another contract to change them.
            We prevent claims to get withdrawn immediately. This is to prevent submitter to escape punishment in case someone discovers an argument to debunk the claim.
            Bounty amounts are compressed with a lossy compression method to save on storage cost.
 */
contract ProveMeWrong is IProveMeWrong, IArbitrable, IEvidence {
  IArbitrator public immutable ARBITRATOR;
  uint256 public constant NUMBER_OF_RULING_OPTIONS = 2;
  uint256 public constant NUMBER_OF_LEAST_SIGNIFICANT_BITS_TO_IGNORE = 32; // To compress bounty amount to gain space in struct. Lossy compression.
  uint256 public immutable WINNER_STAKE_MULTIPLIER; // Multiplier of the arbitration cost that the winner has to pay as fee stake for a round in basis points.
  uint256 public immutable LOSER_STAKE_MULTIPLIER; // Multiplier of the arbitration cost that the loser has to pay as fee stake for a round in basis points.
  uint256 public constant LOSER_APPEAL_PERIOD_MULTIPLIER = 5000; // Multiplier of the appeal period for losers (any other ruling options) in basis points. The loser is given less time to fund its appeal to defend against last minute appeal funding attacks.
  uint256 public constant MULTIPLIER_DENOMINATOR = 10000; // Denominator for multipliers.

  struct DisputeData {
    address payable challenger;
    RulingOptions outcome;
    bool resolved; // To remove dependency to disputeStatus function of arbitrator. This function is likely to be removed in Kleros v2.
    uint80 claimStorageAddress; // 2^16 is sufficient. Just using extra available space.
    Round[] rounds; // Tracks each appeal round of a dispute.
  }

  struct Round {
    mapping(address => mapping(RulingOptions => uint256)) contributions;
    mapping(RulingOptions => bool) hasPaid; // True if the fees for this particular answer has been fully paid in the form hasPaid[rulingOutcome].
    mapping(RulingOptions => uint256) totalPerRuling;
    uint256 totalClaimableAfterExpenses;
  }

  struct Claim {
    address payable owner;
    uint32 withdrawalPermittedAt; // Overflows in year 2106.
    uint64 bountyAmount; // 32-bits compression. Decompressed size is 96 bits. Can be shrinked to uint48 with 40-bits compression in case we need space for another field.
  }

  bytes public ARBITRATOR_EXTRA_DATA; // Immutable.

  mapping(uint80 => Claim) public claimStorage; // Key: Storage address of claim. Claims are not addressed with their identifiers, to enable reusing a storage slot.
  mapping(uint256 => DisputeData) disputes; // Key: Dispute ID as in arbitrator.

  constructor(
    IArbitrator _arbitrator,
    bytes memory _arbitratorExtraData,
    string memory _metaevidenceIpfsUri,
    uint256 _claimWithdrawalTimelock,
    uint256 _winnerStakeMultiplier,
    uint256 _loserStakeMultiplier
  ) IProveMeWrong(_claimWithdrawalTimelock) {
    ARBITRATOR = _arbitrator;
    ARBITRATOR_EXTRA_DATA = _arbitratorExtraData;
    WINNER_STAKE_MULTIPLIER = _winnerStakeMultiplier;
    LOSER_STAKE_MULTIPLIER = _loserStakeMultiplier;

    emit MetaEvidence(0, _metaevidenceIpfsUri); // Metaevidence is constant. Deploy another contract for another metaevidence.
  }

  /** @notice Initializes a claim.
      @param _claimID Unique identifier of a claim. Usually an IPFS content identifier.
      @param _searchPointer Starting point of the search. Find a vacant storage slot before calling this function to minimize gas cost.
   */
  function initializeClaim(string calldata _claimID, uint80 _searchPointer) external payable override {
    Claim storage claim;
    do {
      claim = claimStorage[_searchPointer++];
    } while (claim.bountyAmount != 0);

    claim.owner = payable(msg.sender);
    claim.bountyAmount = uint64(msg.value >> NUMBER_OF_LEAST_SIGNIFICANT_BITS_TO_IGNORE);

    require(claim.bountyAmount > 0, "You can't initialize a claim without putting a bounty.");

    uint256 claimStorageAddress = _searchPointer - 1;
    emit NewClaim(_claimID, claimStorageAddress);
    emit BalanceUpdate(claimStorageAddress, uint256(claim.bountyAmount) << NUMBER_OF_LEAST_SIGNIFICANT_BITS_TO_IGNORE);
  }

  /** @notice Lets you submit evidence as defined in evidence (ERC-1497) standard.
      @param _disputeID Dispute ID as in arbitrator.
      @param _evidenceURI IPFS content identifier of the evidence.
   */
  function submitEvidence(uint256 _disputeID, string calldata _evidenceURI) external override {
    emit Evidence(ARBITRATOR, _disputeID, msg.sender, _evidenceURI);
  }

  /** @notice Lets you increase a bounty of a live claim.
      @param _claimStorageAddress The address of the claim in the storage.
   */
  function increaseBounty(uint80 _claimStorageAddress) external payable override {
    Claim storage claim = claimStorage[_claimStorageAddress];
    require(msg.sender == claim.owner, "Only claimant can increase bounty of a claim."); // To prevent mistakes.

    claim.bountyAmount += uint64(msg.value >> NUMBER_OF_LEAST_SIGNIFICANT_BITS_TO_IGNORE);

    emit BalanceUpdate(_claimStorageAddress, uint256(claim.bountyAmount) << NUMBER_OF_LEAST_SIGNIFICANT_BITS_TO_IGNORE);
  }

  /** @notice Lets a claimant to start withdrawal process.
      @dev withdrawalPermittedAt has some special values: 0 indicates withdrawal possible but process not started yet, max value indicates there is a challenge and during challenge it's forbidden to start withdrawal process.
      @param _claimStorageAddress The address of the claim in the storage.
   */
  function initiateWithdrawal(uint80 _claimStorageAddress) external override {
    Claim storage claim = claimStorage[_claimStorageAddress];
    require(msg.sender == claim.owner, "Only claimant can withdraw a claim.");
    require(claim.withdrawalPermittedAt == 0, "Withdrawal already initiated or there is a challenge.");

    claim.withdrawalPermittedAt = uint32(block.timestamp + CLAIM_WITHDRAWAL_TIMELOCK);
    emit TimelockStarted(_claimStorageAddress);
  }

  /** @notice Executes a withdrawal. Can only be executed by claimant.
      @dev withdrawalPermittedAt has some special values: 0 indicates withdrawal possible but process not started yet, max value indicates there is a challenge and during challenge it's forbidden to start withdrawal process.
      @param _claimStorageAddress The address of the claim in the storage.
   */
  function withdraw(uint80 _claimStorageAddress) external override {
    Claim storage claim = claimStorage[_claimStorageAddress];

    require(msg.sender == claim.owner, "Only claimant can withdraw a claim.");
    require(claim.withdrawalPermittedAt != 0, "You need to initiate withdrawal first.");
    require(claim.withdrawalPermittedAt <= block.timestamp, "You need to wait for timelock or wait until the challenge ends.");

    uint256 withdrawal = uint96(claim.bountyAmount) << NUMBER_OF_LEAST_SIGNIFICANT_BITS_TO_IGNORE;
    claim.bountyAmount = 0; // This is critical to reset.
    claim.withdrawalPermittedAt = 0; // This too, otherwise new claim inside the same slot can withdraw instantly.
    payable(msg.sender).transfer(withdrawal);
    emit Withdrew(_claimStorageAddress);
  }

  /** @notice Challenges the claim at the given storage address. Follow events to find out which claim resides in which slot.
      @dev withdrawalPermittedAt has some special values: 0 indicates withdrawal possible but process not started yet, max value indicates there is a challenge and during challenge it's forbidden to start another challenge.
      @param _claimStorageAddress The address of the claim in the storage.
   */
  function challenge(uint80 _claimStorageAddress) public payable override {
    Claim storage claim = claimStorage[_claimStorageAddress];
    require(claim.withdrawalPermittedAt != type(uint32).max, "There is an ongoing challenge.");
    claim.withdrawalPermittedAt = type(uint32).max; // Mark as challenged.

    require(claim.bountyAmount > 0, "Nothing to challenge."); // To prevent mistakes.

    uint256 disputeID = ARBITRATOR.createDispute{value: msg.value}(NUMBER_OF_RULING_OPTIONS, ARBITRATOR_EXTRA_DATA);

    disputes[disputeID].challenger = payable(msg.sender);
    disputes[disputeID].rounds.push();
    disputes[disputeID].claimStorageAddress = uint80(_claimStorageAddress);

    // Evidence group ID is dispute ID.
    emit Dispute(ARBITRATOR, disputeID, 0, disputeID);
    // This event links the dispute to a claim storage address.
    emit Challenge(_claimStorageAddress, msg.sender, disputeID);
  }

  /** @notice Lets you fund a crowdfunded appeal. In case of funding is incomplete, you will be refunded. Withdrawal will be carried out using withdrawFeesAndRewards function.
      @param _disputeID The dispute ID as in the arbitrator.
      @param _supportedRuling The supported ruling in this funding.
   */
  function fundAppeal(uint256 _disputeID, RulingOptions _supportedRuling) external payable override returns (bool fullyFunded) {
    DisputeData storage dispute = disputes[_disputeID];

    RulingOptions currentRuling = RulingOptions(ARBITRATOR.currentRuling(_disputeID));
    uint256 basicCost;
    uint256 totalCost;
    {
      (uint256 appealWindowStart, uint256 appealWindowEnd) = ARBITRATOR.appealPeriod(_disputeID);

      uint256 multiplier;

      if (_supportedRuling == currentRuling) {
        require(block.timestamp < appealWindowEnd, "Funding must be made within the appeal period.");

        multiplier = WINNER_STAKE_MULTIPLIER;
      } else {
        require(
          block.timestamp < (appealWindowStart + ((appealWindowEnd - appealWindowStart) / 2)),
          "Funding must be made within the first half appeal period."
        );

        multiplier = LOSER_STAKE_MULTIPLIER;
      }

      basicCost = ARBITRATOR.appealCost(_disputeID, ARBITRATOR_EXTRA_DATA);
      totalCost = basicCost + ((basicCost * (multiplier)) / MULTIPLIER_DENOMINATOR);
    }

    RulingOptions supportedRulingOutcome = RulingOptions(_supportedRuling);

    uint256 lastRoundIndex = dispute.rounds.length - 1;
    Round storage lastRound = dispute.rounds[lastRoundIndex];
    require(!lastRound.hasPaid[supportedRulingOutcome], "Appeal fee has already been paid.");

    uint256 contribution;
    {
      uint256 paidSoFar = lastRound.totalPerRuling[supportedRulingOutcome];

      if (paidSoFar >= totalCost) {
        contribution = 0; // This can happen if arbitration fee gets lowered in between contributions.
      } else {
        contribution = totalCost - paidSoFar > msg.value ? msg.value : totalCost - paidSoFar;
      }
    }

    emit Contribution(_disputeID, lastRoundIndex, _supportedRuling, msg.sender, contribution);

    lastRound.contributions[msg.sender][supportedRulingOutcome] += contribution;
    lastRound.totalPerRuling[supportedRulingOutcome] += contribution;

    if (lastRound.totalPerRuling[supportedRulingOutcome] >= totalCost) {
      lastRound.totalClaimableAfterExpenses += lastRound.totalPerRuling[supportedRulingOutcome];
      lastRound.hasPaid[supportedRulingOutcome] = true;
      emit RulingFunded(_disputeID, lastRoundIndex, _supportedRuling);
    }

    if (lastRound.hasPaid[RulingOptions.ChallengeFailed] && lastRound.hasPaid[RulingOptions.Debunked]) {
      dispute.rounds.push();
      lastRound.totalClaimableAfterExpenses -= basicCost;
      ARBITRATOR.appeal{value: basicCost}(_disputeID, ARBITRATOR_EXTRA_DATA);
    }

    // Ignoring failure condition deliberately.
    if (msg.value - contribution > 0) payable(msg.sender).send(msg.value - contribution);

    return lastRound.hasPaid[supportedRulingOutcome];
  }

  /** @notice For arbitrator to call, to execute it's ruling. In case arbitrator rules in favor of challenger, challenger wins the bounty. In any case, withdrawalPermittedAt will be reset.
      @param _disputeID The dispute ID as in the arbitrator.
      @param _ruling The ruling that arbitrator gave.
   */
  function rule(uint256 _disputeID, uint256 _ruling) external override {
    require(IArbitrator(msg.sender) == ARBITRATOR);

    DisputeData storage dispute = disputes[_disputeID];
    Round storage lastRound = dispute.rounds[dispute.rounds.length - 1];

    // Appeal overrides arbitrator ruling. If a ruling option was not fully funded and the counter ruling option was funded, funded ruling option wins by default.
    RulingOptions wonByDefault;
    if (lastRound.hasPaid[RulingOptions.ChallengeFailed]) {
      wonByDefault = RulingOptions.ChallengeFailed;
    } else if (!lastRound.hasPaid[RulingOptions.ChallengeFailed]) {
      wonByDefault = RulingOptions.Debunked;
    }

    RulingOptions actualRuling = wonByDefault != RulingOptions.Tied ? wonByDefault : RulingOptions(_ruling);
    dispute.outcome = actualRuling;

    uint80 claimStorageAddress = dispute.claimStorageAddress;

    Claim storage claim = claimStorage[claimStorageAddress];

    if (actualRuling == RulingOptions.Debunked) {
      uint256 bounty = uint96(claim.bountyAmount) << NUMBER_OF_LEAST_SIGNIFICANT_BITS_TO_IGNORE;
      claim.bountyAmount = 0;

      emit Debunked(claimStorageAddress);
      disputes[_disputeID].challenger.send(bounty); // Ignoring failure condition deliberately.
    } // In case of tie, claim stands.
    claim.withdrawalPermittedAt = 0; // Unmark as challenged.
    dispute.resolved = true;

    emit Ruling(IArbitrator(msg.sender), _disputeID, _ruling);
  }

  /** @notice Allows to withdraw any rewards or reimbursable fees after the dispute gets resolved. For all rounds at once.
      This function has O(m) time complexity where m is number of rounds.
      It is safe to assume m is always less than 10 as appeal cost growth order is O(2^m).
      @param _disputeID ID of the dispute as in arbitrator.
      @param _contributor The address whose rewards to withdraw.
      @param _ruling Ruling that received contributions from contributor.
   */
  function withdrawFeesAndRewardsForAllRounds(
    uint256 _disputeID,
    address payable _contributor,
    RulingOptions _ruling
  ) external override {
    DisputeData storage dispute = disputes[_disputeID];

    uint256 noOfRounds = dispute.rounds.length;

    for (uint256 roundNumber = 0; roundNumber < noOfRounds; roundNumber++) {
      withdrawFeesAndRewards(_disputeID, _contributor, roundNumber, _ruling);
    }
  }

  /** @notice Allows to withdraw any reimbursable fees or rewards after the dispute gets solved.
      @param _disputeID ID of the dispute as in arbitrator.
      @param _contributor The address whose rewards to withdraw.
      @param _roundNumber The number of the round caller wants to withdraw from.
      @param _ruling Ruling that received contribution from contributor.
      @return amount The amount available to withdraw for given question, contributor, round number and ruling option.
   */
  function withdrawFeesAndRewards(
    uint256 _disputeID,
    address payable _contributor,
    uint256 _roundNumber,
    RulingOptions _ruling
  ) public override returns (uint256 amount) {
    DisputeData storage dispute = disputes[_disputeID];
    require(dispute.resolved, "There is no ruling yet.");

    Round storage round = dispute.rounds[_roundNumber];

    amount = getWithdrawableAmount(round, _contributor, _ruling, dispute.outcome);

    if (amount != 0) {
      round.contributions[_contributor][RulingOptions(_ruling)] = 0;
      _contributor.send(amount); // Ignoring failure condition deliberately.
      emit Withdrawal(_disputeID, _roundNumber, _ruling, _contributor, amount);
    }
  }

  /** @notice Lets you to transfer ownership of a claim. This is useful when you want to change owner account without withdrawing and resubmitting.
   */
  function transferOwnership(uint80 _claimStorageAddress, address payable _newOwner) external override {
    Claim storage claim = claimStorage[_claimStorageAddress];
    require(msg.sender == claim.owner, "Only claimant can transfer ownership.");
    claim.owner = _newOwner;
  }

  /** @notice Returns the total amount needs to be paid to challenge a claim.
   */
  function challengeFee() external view override returns (uint256 arbitrationFee) {
    arbitrationFee = ARBITRATOR.arbitrationCost(ARBITRATOR_EXTRA_DATA);
  }

  /** @notice Returns the total amount needs to be paid to appeal a dispute.
   */
  function appealFee(uint256 _disputeID) external view override returns (uint256 arbitrationFee) {
    arbitrationFee = ARBITRATOR.appealCost(_disputeID, ARBITRATOR_EXTRA_DATA);
  }

  /** @notice Helper function to find a vacant slot for claim. Use this function before calling initialize to minimize your gas cost.
   */
  function findVacantStorageSlot(uint80 _searchPointer) external view override returns (uint256 vacantSlotIndex) {
    Claim storage claim;
    do {
      claim = claimStorage[_searchPointer++];
    } while (claim.bountyAmount != 0);

    return _searchPointer - 1;
  }

  /** @notice Returns the sum of withdrawable amount.
      This function has O(m) time complexity where m is number of rounds.
      It is safe to assume m is always less than 10 as appeal cost growth order is O(m^2).
   */
  function getTotalWithdrawableAmount(
    uint256 _disputeID,
    address payable _contributor,
    RulingOptions _ruling
  ) external view override returns (uint256 sum) {
    DisputeData storage dispute = disputes[_disputeID];
    if (!dispute.resolved) return 0;
    uint256 noOfRounds = dispute.rounds.length;
    RulingOptions finalRuling = dispute.outcome;

    for (uint256 roundNumber = 0; roundNumber < noOfRounds; roundNumber++) {
      Round storage round = dispute.rounds[roundNumber];
      sum += getWithdrawableAmount(round, _contributor, _ruling, finalRuling);
    }
  }

  /** @notice Returns withdrawable amount for given parameters.
   */
  function getWithdrawableAmount(
    Round storage _round,
    address _contributor,
    RulingOptions _ruling,
    RulingOptions _finalRuling
  ) internal view returns (uint256 amount) {
    RulingOptions givenRuling = RulingOptions(_ruling);

    if (!_round.hasPaid[givenRuling]) {
      // Allow to reimburse if funding was unsuccessful for this ruling option.
      amount = _round.contributions[_contributor][givenRuling];
    } else {
      // Funding was successful for this ruling option.
      if (_ruling == _finalRuling) {
        // This ruling option is the ultimate winner.
        amount = _round.totalPerRuling[givenRuling] > 0
          ? (_round.contributions[_contributor][givenRuling] * _round.totalClaimableAfterExpenses) / _round.totalPerRuling[givenRuling]
          : 0;
      } else if (!_round.hasPaid[RulingOptions(_finalRuling)]) {
        // The ultimate winner was not funded in this round. Contributions discounting the appeal fee are reimbursed proportionally.
        amount =
          (_round.contributions[_contributor][givenRuling] * _round.totalClaimableAfterExpenses) /
          (_round.totalPerRuling[RulingOptions.ChallengeFailed] + _round.totalPerRuling[RulingOptions.Debunked]);
      }
    }
  }
}

// SPDX-License-Identifier: MIT

/**
 *  @authors: [@ferittuncer]
 *  @reviewers: [@mtsalenc*, @hbarcelos*, @unknownunknown1, @MerlinEgalite, @fnanni-0*, @shalzz]
 *  @auditors: []
 *  @bounties: []
 *  @deployments: []
 */

pragma solidity ^0.8.0;

import "@kleros/erc-792/contracts/IArbitrable.sol";
import "@kleros/erc-792/contracts/erc-1497/IEvidence.sol";
import "@kleros/erc-792/contracts/IArbitrator.sol";

/**
 *  @title This serves as a standard interface for crowdfunded appeals and evidence submission, which aren't a part of the arbitration (erc-792 and erc-1497) standard yet.
    This interface is used in Dispute Resolver (resolve.kleros.io).
 */
abstract contract IDisputeResolver is IArbitrable, IEvidence {
    string public constant VERSION = "2.0.0"; // Can be used to distinguish between multiple deployed versions, if necessary.

    /** @dev Raised when a contribution is made, inside fundAppeal function.
     *  @param _localDisputeID Identifier of a dispute in scope of arbitrable contract. Arbitrator ids can be translated to local ids via externalIDtoLocalID.
     *  @param _round The round number the contribution was made to.
     *  @param ruling Indicates the ruling option which got the contribution.
     *  @param _contributor Caller of fundAppeal function.
     *  @param _amount Contribution amount.
     */
    event Contribution(uint256 indexed _localDisputeID, uint256 indexed _round, uint256 ruling, address indexed _contributor, uint256 _amount);

    /** @dev Raised when a contributor withdraws non-zero value.
     *  @param _localDisputeID Identifier of a dispute in scope of arbitrable contract. Arbitrator ids can be translated to local ids via externalIDtoLocalID.
     *  @param _round The round number the withdrawal was made from.
     *  @param _ruling Indicates the ruling option which contributor gets rewards from.
     *  @param _contributor The beneficiary of withdrawal.
     *  @param _reward Total amount of withdrawal, consists of reimbursed deposits plus rewards.
     */
    event Withdrawal(uint256 indexed _localDisputeID, uint256 indexed _round, uint256 _ruling, address indexed _contributor, uint256 _reward);

    /** @dev To be raised when a ruling option is fully funded for appeal.
     *  @param _localDisputeID Identifier of a dispute in scope of arbitrable contract. Arbitrator ids can be translated to local ids via externalIDtoLocalID.
     *  @param _round Number of the round this ruling option was fully funded in.
     *  @param _ruling The ruling option which just got fully funded.
     */
    event RulingFunded(uint256 indexed _localDisputeID, uint256 indexed _round, uint256 indexed _ruling);

    /** @dev Maps external (arbitrator side) dispute id to local (arbitrable) dispute id.
     *  @param _externalDisputeID Dispute id as in arbitrator contract.
     *  @return localDisputeID Dispute id as in arbitrable contract.
     */
    function externalIDtoLocalID(uint256 _externalDisputeID) external virtual returns (uint256 localDisputeID);

    /** @dev Returns number of possible ruling options. Valid rulings are [0, return value].
     *  @param _localDisputeID Identifier of a dispute in scope of arbitrable contract. Arbitrator ids can be translated to local ids via externalIDtoLocalID.
     *  @return count The number of ruling options.
     */
    function numberOfRulingOptions(uint256 _localDisputeID) external view virtual returns (uint256 count);

    /** @dev Allows to submit evidence for a given dispute.
     *  @param _localDisputeID Identifier of a dispute in scope of arbitrable contract. Arbitrator ids can be translated to local ids via externalIDtoLocalID.
     *  @param _evidenceURI IPFS path to evidence, example: '/ipfs/Qmarwkf7C9RuzDEJNnarT3WZ7kem5bk8DZAzx78acJjMFH/evidence.json'
     */
    function submitEvidence(uint256 _localDisputeID, string calldata _evidenceURI) external virtual;

    /** @dev Manages contributions and calls appeal function of the specified arbitrator to appeal a dispute. This function lets appeals be crowdfunded.
     *  @param _localDisputeID Identifier of a dispute in scope of arbitrable contract. Arbitrator ids can be translated to local ids via externalIDtoLocalID.
     *  @param _ruling The ruling option to which the caller wants to contribute.
     *  @return fullyFunded True if the ruling option got fully funded as a result of this contribution.
     */
    function fundAppeal(uint256 _localDisputeID, uint256 _ruling) external payable virtual returns (bool fullyFunded);

    /** @dev Returns appeal multipliers.
     *  @return winnerStakeMultiplier Winners stake multiplier.
     *  @return loserStakeMultiplier Losers stake multiplier.
     *  @return loserAppealPeriodMultiplier Losers appeal period multiplier. The loser is given less time to fund its appeal to defend against last minute appeal funding attacks.
     *  @return denominator Multiplier denominator in basis points.
     */
    function getMultipliers()
        external
        view
        virtual
        returns (
            uint256 winnerStakeMultiplier,
            uint256 loserStakeMultiplier,
            uint256 loserAppealPeriodMultiplier,
            uint256 denominator
        );

    /** @dev Allows to withdraw any reimbursable fees or rewards after the dispute gets resolved.
     *  @param _localDisputeID Identifier of a dispute in scope of arbitrable contract. Arbitrator ids can be translated to local ids via externalIDtoLocalID.
     *  @param _contributor Beneficiary of withdraw operation.
     *  @param _round Number of the round that caller wants to execute withdraw on.
     *  @param _ruling A ruling option that caller wants to execute withdraw on.
     *  @return sum The amount that is going to be transferred to contributor as a result of this function call.
     */
    function withdrawFeesAndRewards(
        uint256 _localDisputeID,
        address payable _contributor,
        uint256 _round,
        uint256 _ruling
    ) external virtual returns (uint256 sum);

    /** @dev Allows to withdraw any rewards or reimbursable fees after the dispute gets resolved for all rounds at once.
     *  @param _localDisputeID Identifier of a dispute in scope of arbitrable contract. Arbitrator ids can be translated to local ids via externalIDtoLocalID.
     *  @param _contributor Beneficiary of withdraw operation.
     *  @param _ruling Ruling option that caller wants to execute withdraw on.
     */
    function withdrawFeesAndRewardsForAllRounds(
        uint256 _localDisputeID,
        address payable _contributor,
        uint256 _ruling
    ) external virtual;

    /** @dev Returns the sum of withdrawable amount.
     *  @param _localDisputeID Identifier of a dispute in scope of arbitrable contract. Arbitrator ids can be translated to local ids via externalIDtoLocalID.
     *  @param _contributor Beneficiary of withdraw operation.
     *  @param _ruling Ruling option that caller wants to get withdrawable amount from.
     *  @return sum The total amount available to withdraw.
     */
    function getTotalWithdrawableAmount(
        uint256 _localDisputeID,
        address payable _contributor,
        uint256 _ruling
    ) external view virtual returns (uint256 sum);
}

/**
 * SPDX-License-Identifier: MIT
 * @authors: @ferittuncer
 * @reviewers: []
 * @auditors: []
 * @bounties: []
 * @deployments: []
 */

pragma solidity ^0.8.10;

/** @title  Prove Me Wrong
    @notice Interface smart contract for a type of curation, where submitted items are on hold until they are withdrawn and the amount of security deposits are determined by submitters.
    @dev    Claims are not addressed with their identifiers. That enables us to reuse same storage address for another claim later.
            We prevent claims to get withdrawn immediately. This is to prevent submitter to escape punishment in case someone discovers an argument to debunk the claim. Front-ends should be able to take account only this interface and disregard implementation details.
 */
abstract contract IProveMeWrong {
  string public constant PMW_VERSION = "1.0.0";

  enum RulingOptions {
    Tied,
    ChallengeFailed,
    Debunked
  }

  uint256 public immutable CLAIM_WITHDRAWAL_TIMELOCK; // To prevent claimants to act fast and escape punishment.

  constructor(uint256 _claimWithdrawalTimelock) {
    CLAIM_WITHDRAWAL_TIMELOCK = _claimWithdrawalTimelock;
  }

  event NewClaim(string claimID, uint256 indexed claimAddress);
  event Debunked(uint256 claimAddress);
  event Withdrew(uint256 claimAddress);
  event BalanceUpdate(uint256 claimAddress, uint256 newTotal);
  event TimelockStarted(uint256 claimAddress);
  event Challenge(uint256 indexed claimAddress, address challanger, uint256 disputeID);
  event Contribution(uint256 indexed claimStorageAddress, uint256 indexed round, RulingOptions ruling, address indexed contributor, uint256 amount);
  event Withdrawal(uint256 indexed claimStorageAddress, uint256 indexed round, RulingOptions ruling, address indexed contributor, uint256 reward);
  event RulingFunded(uint256 indexed claimStorageAddress, uint256 indexed round, RulingOptions indexed ruling);

  /** @notice Allows to submit evidence for a given dispute.
   *  @param _disputeID The dispute ID as in arbitrator.
   *  @param _evidenceURI IPFS path to evidence, example: '/ipfs/Qmarwkf7C9RuzDEJNnarT3WZ7kem5bk8DZAzx78acJjMFH/evidence.json'
   */
  function submitEvidence(uint256 _disputeID, string calldata _evidenceURI) external virtual;

  /** @notice Manages contributions and calls appeal function of the specified arbitrator to appeal a dispute. This function lets appeals be crowdfunded.
   *  @param _disputeID The dispute ID as in arbitrator.
   *  @param _ruling The ruling option to which the caller wants to contribute.
   *  @return fullyFunded True if the ruling option got fully funded as a result of this contribution.
   */
  function fundAppeal(uint256 _disputeID, RulingOptions _ruling) external payable virtual returns (bool fullyFunded);

  /** @notice Initializes a claim. Emits NewClaim. If bounty changed also emits BalanceUpdate.
      @dev    Do not confuse claimID with claimAddress.
      @param _claimID Unique identifier of a claim. Usually an IPFS content identifier.
      @param _searchPointer Starting point of the search. Find a vacant storage slot before calling this function to minimize gas cost.
   */
  function initializeClaim(string calldata _claimID, uint80 _searchPointer) external payable virtual;

  /** @notice Lets claimant to increase a bounty of a live claim. Emits BalanceUpdate.
      @param _claimStorageAddress The address of the claim in the storage.
   */
  function increaseBounty(uint80 _claimStorageAddress) external payable virtual;

  /** @notice Lets a claimant to start withdrawal process. Emits TimelockStarted.
      @param _claimStorageAddress The address of the claim in the storage.
   */
  function initiateWithdrawal(uint80 _claimStorageAddress) external virtual;

  /** @notice Executes a withdrawal. Emits Withdrew.
      @param _claimStorageAddress The address of the claim in the storage.
   */
  function withdraw(uint80 _claimStorageAddress) external virtual;

  /** @notice Challenges the claim at the given storage address. Emit Challenge.
      @param _claimStorageAddress The address of the claim in the storage.
   */
  function challenge(uint80 _claimStorageAddress) public payable virtual;

  /** @notice Lets you to transfer ownership of a claim. This is useful when you want to change owner account without withdrawing and resubmitting.
      @param _claimStorageAddress The address of claim in the storage.
      @param _claimStorageAddress The new owner of the claim which resides in the storage address, provided by the previous parameter.
   */
  function transferOwnership(uint80 _claimStorageAddress, address payable _newOwner) external virtual;

  /** @notice Helper function to find a vacant slot for claim. Use this function before calling initialize to minimize your gas cost.
      @param _searchPointer Starting point of the search. If you do not have a guess, just pass 0.
   */
  function findVacantStorageSlot(uint80 _searchPointer) external view virtual returns (uint256 vacantSlotIndex);

  /** @notice Returns the total amount needs to be paid to challenge a claim.
   */
  function challengeFee() external view virtual returns (uint256 arbitrationFee);

  /** @notice Returns the total amount needs to be paid to appeal a dispute.
      @param _disputeID ID of the dispute as in arbitrator.
   */
  function appealFee(uint256 _disputeID) external view virtual returns (uint256 arbitrationFee);

  /** @dev Allows to withdraw any reimbursable fees or rewards after the dispute gets resolved.
   *  @param _disputeID The dispute ID as in arbitrator.
   *  @param _contributor Beneficiary of withdraw operation.
   *  @param _round Number of the round that caller wants to execute withdraw on.
   *  @param _ruling A ruling option that caller wants to execute withdraw on.
   *  @return sum The amount that is going to be transferred to contributor as a result of this function call.
   */
  function withdrawFeesAndRewards(
    uint256 _disputeID,
    address payable _contributor,
    uint256 _round,
    RulingOptions _ruling
  ) external virtual returns (uint256 sum);

  /** @dev Allows to withdraw any rewards or reimbursable fees after the dispute gets resolved for all rounds at once.
   *  @param _disputeID The dispute ID as in arbitrator.
   *  @param _contributor Beneficiary of withdraw operation.
   *  @param _ruling Ruling option that caller wants to execute withdraw on.
   */
  function withdrawFeesAndRewardsForAllRounds(
    uint256 _disputeID,
    address payable _contributor,
    RulingOptions _ruling
  ) external virtual;

  /** @dev Returns the sum of withdrawable amount.
   *  @param _disputeID The dispute ID as in arbitrator.
   *  @param _contributor Beneficiary of withdraw operation.
   *  @param _ruling Ruling option that caller wants to get withdrawable amount from.
   *  @return sum The total amount available to withdraw.
   */
  function getTotalWithdrawableAmount(
    uint256 _disputeID,
    address payable _contributor,
    RulingOptions _ruling
  ) external view virtual returns (uint256 sum);
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