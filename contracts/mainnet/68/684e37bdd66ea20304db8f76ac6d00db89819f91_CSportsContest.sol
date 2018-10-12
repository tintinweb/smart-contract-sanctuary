pragma solidity ^0.4.25;

/// @title A facet of CSportsCore that holds all important constants and modifiers
/// @author CryptoSports, Inc. (https://cryptosports.team))
/// @dev See the CSportsCore contract documentation to understand how the various CSports contract facets are arranged.
contract CSportsConstants {

    /// @dev The maximum # of marketing tokens that can ever be created
    /// by the commissioner.
    uint16 public MAX_MARKETING_TOKENS = 2500;

    /// @dev The starting price for commissioner auctions (if the average
    ///   of the last 2 is less than this, we will use this value)
    ///   A finney is 1/1000 of an ether.
    uint256 public COMMISSIONER_AUCTION_FLOOR_PRICE = 5 finney; // 5 finney for production, 15 for script testing and 1 finney for Rinkeby

    /// @dev The duration of commissioner auctions
    uint256 public COMMISSIONER_AUCTION_DURATION = 14 days; // 30 days for testing;

    /// @dev Number of seconds in a week
    uint32 constant WEEK_SECS = 1 weeks;

}

/// @title A facet of CSportsCore that manages an individual&#39;s authorized role against access privileges.
/// @author CryptoSports, Inc. (https://cryptosports.team))
/// @dev See the CSportsCore contract documentation to understand how the various CSports contract facets are arranged.
contract CSportsAuth is CSportsConstants {
    // This facet controls access control for CryptoSports. There are four roles managed here:
    //
    //     - The CEO: The CEO can reassign other roles and change the addresses of our dependent smart
    //         contracts. It is also the only role that can unpause the smart contract. It is initially
    //         set to the address that created the smart contract in the CSportsCore constructor.
    //
    //     - The CFO: The CFO can withdraw funds from CSportsCore and its auction contracts.
    //
    //     - The COO: The COO can perform administrative functions.
    //
    //     - The Commisioner can perform "oracle" functions like adding new real world players,
    //       setting players active/inactive, and scoring contests.
    //

    /// @dev Emited when contract is upgraded - See README.md for updgrade plan
    event ContractUpgrade(address newContract);

    /// The addresses of the accounts (or contracts) that can execute actions within each roles.
    address public ceoAddress;
    address public cfoAddress;
    address public cooAddress;
    address public commissionerAddress;

    /// @dev Keeps track whether the contract is paused. When that is true, most actions are blocked
    bool public paused = false;

    /// @dev Flag that identifies whether or not we are in development and should allow development
    /// only functions to be called.
    bool public isDevelopment = true;

    /// @dev Access modifier to allow access to development mode functions
    modifier onlyUnderDevelopment() {
      require(isDevelopment == true);
      _;
    }

    /// @dev Access modifier for CEO-only functionality
    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }

    /// @dev Access modifier for CFO-only functionality
    modifier onlyCFO() {
        require(msg.sender == cfoAddress);
        _;
    }

    /// @dev Access modifier for COO-only functionality
    modifier onlyCOO() {
        require(msg.sender == cooAddress);
        _;
    }

    /// @dev Access modifier for Commissioner-only functionality
    modifier onlyCommissioner() {
        require(msg.sender == commissionerAddress);
        _;
    }

    /// @dev Requires any one of the C level addresses
    modifier onlyCLevel() {
        require(
            msg.sender == cooAddress ||
            msg.sender == ceoAddress ||
            msg.sender == cfoAddress ||
            msg.sender == commissionerAddress
        );
        _;
    }

    /// @dev prevents contracts from hitting the method
    modifier notContract() {
        address _addr = msg.sender;
        uint256 _codeLength;

        assembly {_codeLength := extcodesize(_addr)}
        require(_codeLength == 0);
        _;
    }

    /// @dev One way switch to set the contract into prodution mode. This is one
    /// way in that the contract can never be set back into development mode. Calling
    /// this function will block all future calls to functions that are meant for
    /// access only while we are under development. It will also enable more strict
    /// additional checking on various parameters and settings.
    function setProduction() public onlyCEO onlyUnderDevelopment {
      isDevelopment = false;
    }

    /// @dev Assigns a new address to act as the CEO. Only available to the current CEO.
    /// @param _newCEO The address of the new CEO
    function setCEO(address _newCEO) public onlyCEO {
        require(_newCEO != address(0));
        ceoAddress = _newCEO;
    }

    /// @dev Assigns a new address to act as the CFO. Only available to the current CEO.
    /// @param _newCFO The address of the new CFO
    function setCFO(address _newCFO) public onlyCEO {
        require(_newCFO != address(0));

        cfoAddress = _newCFO;
    }

    /// @dev Assigns a new address to act as the COO. Only available to the current CEO.
    /// @param _newCOO The address of the new COO
    function setCOO(address _newCOO) public onlyCEO {
        require(_newCOO != address(0));

        cooAddress = _newCOO;
    }

    /// @dev Assigns a new address to act as the Commissioner. Only available to the current CEO.
    /// @param _newCommissioner The address of the new COO
    function setCommissioner(address _newCommissioner) public onlyCEO {
        require(_newCommissioner != address(0));

        commissionerAddress = _newCommissioner;
    }

    /// @dev Assigns all C-Level addresses
    /// @param _ceo CEO address
    /// @param _cfo CFO address
    /// @param _coo COO address
    /// @param _commish Commissioner address
    function setCLevelAddresses(address _ceo, address _cfo, address _coo, address _commish) public onlyCEO {
        require(_ceo != address(0));
        require(_cfo != address(0));
        require(_coo != address(0));
        require(_commish != address(0));
        ceoAddress = _ceo;
        cfoAddress = _cfo;
        cooAddress = _coo;
        commissionerAddress = _commish;
    }

    /// @dev Transfers the balance of this contract to the CFO
    function withdrawBalance() external onlyCFO {
        cfoAddress.transfer(address(this).balance);
    }

    /*** Pausable functionality adapted from OpenZeppelin ***/

    /// @dev Modifier to allow actions only when the contract IS NOT paused
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /// @dev Modifier to allow actions only when the contract IS paused
    modifier whenPaused {
        require(paused);
        _;
    }

    /// @dev Called by any "C-level" role to pause the contract. Used only when
    ///  a bug or exploit is detected and we need to limit damage.
    function pause() public onlyCLevel whenNotPaused {
        paused = true;
    }

    /// @dev Unpauses the smart contract. Can only be called by the CEO, since
    ///  one reason we may pause the contract is when CFO or COO accounts are
    ///  compromised.
    function unpause() public onlyCEO whenPaused {
        paused = false;
    }
}

/// @title CSportsContestBase base class for contests and teams contracts
/// @dev This interface defines base class for contests and teams contracts
/// @author CryptoSports
contract CSportsContestBase {

    /// @dev Structure holding the player token IDs for a team
    struct Team {
      address owner;              // Address of the owner of the player tokens
      int32 score;                // Score assigned to this team after a contest
      uint32 place;               // Place this team finished in its contest
      bool holdsEntryFee;         // TRUE if this team currently holds an entry fee
      bool ownsPlayerTokens;      // True if the tokens are being escrowed by the Team contract
      uint32[] playerTokenIds;    // IDs of the tokens held by this team
    }

}

/// @title CSportsTeam Interface
/// @dev This interface defines methods required by the CSportsContestCore
///   in implementing a contest.
/// @author CryptoSports
contract CSportsTeam {

    bool public isTeamContract;

    /// @dev Define team events
    event TeamCreated(uint256 teamId, address owner);
    event TeamUpdated(uint256 teamId);
    event TeamReleased(uint256 teamId);
    event TeamScored(uint256 teamId, int32 score, uint32 place);
    event TeamPaid(uint256 teamId);

    function setCoreContractAddress(address _address) public;
    function setLeagueRosterContractAddress(address _address) public;
    function setContestContractAddress(address _address) public;
    function createTeam(address _owner, uint32[] _tokenIds) public returns (uint32);
    function updateTeam(address _owner, uint32 _teamId, uint8[] _indices, uint32[] _tokenIds) public;
    function releaseTeam(uint32 _teamId) public;
    function getTeamOwner(uint32 _teamId) public view returns (address);
    function scoreTeams(uint32[] _teamIds, int32[] _scores, uint32[] _places) public;
    function getScore(uint32 _teamId) public view returns (int32);
    function getPlace(uint32 _teamId) public view returns (uint32);
    function ownsPlayerTokens(uint32 _teamId) public view returns (bool);
    function refunded(uint32 _teamId) public;
    function tokenIdsForTeam(uint32 _teamId) public view returns (uint32, uint32[50]);
    function getTeam(uint32 _teamId) public view returns (
        address _owner,
        int32 _score,
        uint32 _place,
        bool _holdsEntryFee,
        bool _ownsPlayerTokens);
}

/// @title CSports Contest
/// @dev Implementation of a fantasy sports contest using tokens managed
///   by a CSportsCore contract. This class implements functionality that
///   is generic to any sport that involves teams. The specifics of how
///   teams are structured, validated, and scored happen in the attached
///   contract that implements the CSportsTeam interface.
contract CSportsContest is CSportsAuth, CSportsContestBase {

  enum ContestStatus { Invalid, Active, Scoring, Paying, Paid, Canceled }
  enum PayoutKey { Invalid, WinnerTakeAll, FiftyFifty, TopTen }

  /// @dev Used as sanity check by other contracts
  bool public isContestContract = true;

  /// @dev Instance of the team contract connected to this contest. It is
  ///   the team contract that implements most of the specific rules for
  ///   this contrest.
  CSportsTeam public teamContract;

  /// @dev Cut owner takes of the entry fees paid into a contest as a fee for
  ///   scoring the contest (measured in basis points (1/100 of a percent).
  ///   Values 0-10,000 map to 0%-100%
  uint256 public ownerCut;

  /// @dev Structure for the definition of a single contest.
  struct Contest {
    address scoringOracleAddress;                 // Eth address of scoring oracle, if == 0, it&#39;s our commissioner address
    address creator;                              // Address of the creator of the contest
    uint32 gameSetId;                             // ID of the gameset associated with this contest
    uint32 numWinners;                            // Number of winners in this contest
    uint32 winnersToPay;                          // Number of winners that remain to be paid
    uint64 startTime;                             // Starting time for the contest (lock time)
    uint64 endTime;                               // Ending time for  the contest (can score after this time)
    uint128 entryFee;                             // Fee to enter the contest
    uint128 prizeAmount;                          // Fee to enter the contest
    uint128 remainingPrizeAmount;                 // Remaining amount of prize money to payout
    uint64 maxMinEntries;                         // Maximum and minimum number of entries allowed in the contest
    ContestStatus status;                         // 1 = active, 2 = scoring, 3 = paying, 4 = paid, 5 = canceled
    PayoutKey payoutKey;                          // Identifies the payout structure for the contest (see comments above)
    uint32[] teamIds;                             // An array of teams entered into this contest
    string name;                                  // Name of contest
    mapping (uint32 => uint32) placeToWinner;     // Winners list mapping place to teamId
    mapping (uint32 => uint32) teamIdToIdx;       // Maps a team ID to its index into the teamIds array
  }

  /// @dev Holds all of our contests (public)
  Contest[] public contests;

  /// @dev Maps team IDs to contest IDs
  mapping (uint32 => uint32) public teamIdToContestId;

  /// @dev We do not transfer funds directly to users when making any kind of payout. We
  ///   require the user to pull his own funds. This is to eliminate DoS and reentrancy problems.
  mapping (address => uint128) public authorizedUserPayment;

  /// @dev Always has the total amount this contract is authorized to pay out to
  ///   users.
  uint128 public totalAuthorizedForPayment;

  /// @dev Define contest events
  event ContestCreated(uint256 contestId);
  event ContestCanceled(uint256 contestId);
  event ContestEntered(uint256 contestId, uint256 teamId);
  event ContestExited(uint256 contestId, uint256 teamId);
  event ContestClosed(uint32 contestId);
  event ContestTeamWinningsPaid(uint32 contestId, uint32 teamId, uint128 amount);
  event ContestTeamRefundPaid(uint32 contestId, uint32 teamId, uint128 amount);
  event ContestCreatorEntryFeesPaid(uint32 contestId, uint128 amount);
  event ContestApprovedFundsDelivered(address toAddress, uint128 amount);

  /// @dev Class constructor creates the main CSportsContest smart contract instance.
  constructor(uint256 _cut) public {
      require(_cut <= 10000);
      ownerCut = _cut;

      // All C-level roles are the message sender
      ceoAddress = msg.sender;
      cfoAddress = msg.sender;
      cooAddress = msg.sender;
      commissionerAddress = msg.sender;

      // Create a contest to take up the 0th slot.
      // Create it in the canceled state with no teams.
      // This is to deal with the fact that mappings return 0
      // when queried with non-existent keys.
      Contest memory _contest = Contest({
          scoringOracleAddress: commissionerAddress,
          gameSetId: 0,
          maxMinEntries: 0,
          numWinners: 0,
          winnersToPay: 0,
          startTime: 0,
          endTime: 0,
          creator: msg.sender,
          entryFee: 0,
          prizeAmount: 0,
          remainingPrizeAmount: 0,
          status: ContestStatus.Canceled,
          payoutKey: PayoutKey(0),
          name: "mythical",
          teamIds: new uint32[](0)
        });

        contests.push(_contest);
  }

  /// @dev Called by any "C-level" role to pause the contract. Used only when
  ///  a bug or exploit is detected and we need to limit damage.
  function pause() public onlyCLevel whenNotPaused {
    paused = true;
  }

  /// @dev Unpauses the smart contract. Can only be called by the CEO, since
  ///  one reason we may pause the contract is when CFO or COO accounts are
  ///  compromised.
  function unpause() public onlyCEO whenPaused {
    // can&#39;t unpause if contract was upgraded
    paused = false;
  }

  /// @dev Sets the teamContract that will manage teams for this contest
  /// @param _address - Address of our team contract
  function setTeamContractAddress(address _address) public onlyCEO {
    CSportsTeam candidateContract = CSportsTeam(_address);
    require(candidateContract.isTeamContract());
    teamContract = candidateContract;
  }

  /// @dev Allows anyone who has funds approved to receive them. We use this
  ///   "pull" funds mechanism to eliminate problems resulting from malicious behavior.
  function transferApprovedFunds() public {
    uint128 amount = authorizedUserPayment[msg.sender];
    if (amount > 0) {

      // Shouldn&#39;t have to check this, but if for any reason things got screwed up,
      // this prevents anyone from withdrawing more than has been approved in total
      // on the contract.
      if (totalAuthorizedForPayment >= amount) {

        // Imporant to do the delete before the transfer to eliminate re-entrancy attacks
        delete authorizedUserPayment[msg.sender];
        totalAuthorizedForPayment -= amount;
        msg.sender.transfer(amount);

        // Create log entry
        emit ContestApprovedFundsDelivered(msg.sender, amount);
      }
    }
  }

  /// @dev Returns the amount of funds available for a given sender
  function authorizedFundsAvailable() public view returns (uint128) {
    return authorizedUserPayment[msg.sender];
  }

  /// @dev Returns the total amount of ether held by this contract
  /// that has been approved for dispursement to contest creators
  /// and participants.
  function getTotalAuthorizedForPayment() public view returns (uint128) {
    return totalAuthorizedForPayment;
  }

  /// @dev Creates a team for this contest. Called by an end-user of the CSportsCore
  ///   contract. If the contract is paused, no additional contests can be created (although
  ///   all other contract functionality remains valid.
  /// @param _gameSetId - Identifes the games associated with contest. Used by the scoring oracle.
  /// @param _startTime - Start time for the contest, used to determine locking of the teams
  /// @param _endTime - End time representing the earliest this contest can be scored by the oracle
  /// @param _entryFee - Entry fee paid to enter a team into this contest
  /// @param _prizeAmount - Prize amount awarded to the winner
  /// @param _maxEntries - Maximum number of entries in the contest
  /// @param _minEntries - If false, we will return all ether and release all players
  /// @param _payoutKey - Identifes the payout structure for the contest
  ///   if we hit the start time with fewer than _maxEntries teams entered into the contest.
  /// @param _tokenIds - Player token ids to be associated with the creator&#39;s team.
  function createContest
  (
    string _name,
    address _scoringOracleAddress,
    uint32 _gameSetId,
    uint64 _startTime,
    uint64 _endTime,
    uint128 _entryFee,
    uint128 _prizeAmount,
    uint32 _maxEntries,
    uint32 _minEntries,
    uint8 _payoutKey,
    uint32[] _tokenIds
  ) public payable whenNotPaused {

      require (msg.sender != address(0));
      require (_endTime > _startTime);
      require (_maxEntries != 1);
      require (_minEntries <= _maxEntries);
      require(_startTime > uint64(now));

      // The commissioner is allowed to create contests with no initial entry
      require((msg.sender == commissionerAddress) || (_tokenIds.length > 0));

      // Make sure we don&#39;t overflow
      require(((_prizeAmount + _entryFee) >= _prizeAmount) && ((_prizeAmount + _entryFee) >= _entryFee));

      // Creator must put up the correct amount of ether to cover the prize as well
      // as his own entry fee if a team has been entered.
      if (_tokenIds.length > 0) {
        require(msg.value == (_prizeAmount + _entryFee));
      } else {
        require(msg.value == _prizeAmount);
      }

      // The default scoring oracle address will be set to the commissionerAddress
      if (_scoringOracleAddress == address(0)) {
        _scoringOracleAddress = commissionerAddress;
      }

      // Pack our maxMinEntries (due to stack limitations on struct sizes)
      // uint64 maxMinEntries = (uint64(_maxEntries) << 32) | uint64(_minEntries);

      // Create the contest object in memory
      Contest memory _contest = Contest({
          scoringOracleAddress: _scoringOracleAddress,
          gameSetId: _gameSetId,
          maxMinEntries: (uint64(_maxEntries) << 32) | uint64(_minEntries),
          numWinners: 0,
          winnersToPay: 0,
          startTime: _startTime,
          endTime: _endTime,
          creator: msg.sender,
          entryFee: _entryFee,
          prizeAmount: _prizeAmount,
          remainingPrizeAmount: _prizeAmount,
          status: ContestStatus.Active,
          payoutKey: PayoutKey(_payoutKey),
          name: _name,
          teamIds: new uint32[](0)
        });

      // We only create a team if we have tokens
      uint32 uniqueTeamId = 0;
      if (_tokenIds.length > 0) {
        // Create the team for the creator of this contest. This
        // will throw if msg.sender does not own all _tokenIds. The result
        // of this call is that the team contract will now own the tokens.
        //
        // Note that the _tokenIds MUST BE OWNED by the msg.sender, and
        // there may be other conditions enforced by the CSportsTeam contract&#39;s
        // createTeam(...) method.
        uniqueTeamId = teamContract.createTeam(msg.sender, _tokenIds);

        // Again, we make sure our unique teamId stays within bounds
        require(uniqueTeamId < 4294967295);
        _contest.teamIds = new uint32[](1);
        _contest.teamIds[0] = uniqueTeamId;

        // We do not have to do this mapping here because 0 is returned from accessing
        // a non existent member of a mapping (we deal with this when we use this
        // structure in removing a team from the teamIds array). Can&#39;t do it anyway because
        // mappings can&#39;t be accessed outside of storage.
        //
        // _contest.teamIdToIdx[uniqueTeamId] = 0;
      }

      // Save our contest
      //
      // It&#39;s probably never going to happen, 4 billion contests and teams is A LOT, but
      // let&#39;s just be 100% sure we never let this happen because teamIds are
      // often cast as uint32.
      uint256 _contestId = contests.push(_contest) - 1;
      require(_contestId < 4294967295);

      // Map our entered teamId if we in fact entered a team
      if (_tokenIds.length > 0) {
        teamIdToContestId[uniqueTeamId] = uint32(_contestId);
      }

      // Fire events
      emit ContestCreated(_contestId);
      if (_tokenIds.length > 0) {
        emit ContestEntered(_contestId, uniqueTeamId);
      }
  }

  /// @dev Method to enter an existing contest. The msg.sender must own
  ///   all of the player tokens on the team.
  /// @param _contestId - ID of contest being entered
  /// @param _tokenIds - IDs of player tokens on the team being entered
  function enterContest(uint32 _contestId, uint32[] _tokenIds) public  payable whenNotPaused {

    require (msg.sender != address(0));
    require ((_contestId > 0) && (_contestId < contests.length));

    // Grab the contest and make sure it is available to enter
    Contest storage _contestToEnter = contests[_contestId];
    require (_contestToEnter.status == ContestStatus.Active);
    require(_contestToEnter.startTime > uint64(now));

    // Participant must put up the entry fee.
    require(msg.value >= _contestToEnter.entryFee);

    // Cannot exceed the contest&#39;s max entry requirement
    uint32 maxEntries = uint32(_contestToEnter.maxMinEntries >> 32);
    if (maxEntries > 0) {
      require(_contestToEnter.teamIds.length < maxEntries);
    }

    // Note that the _tokenIds MUST BE OWNED by the msg.sender, and
    // there may be other conditions enforced by the CSportsTeam contract&#39;s
    // createTeam(...) method.
    uint32 _newTeamId = teamContract.createTeam(msg.sender, _tokenIds);

    // Add the new team to our contest
    uint256 _teamIndex = _contestToEnter.teamIds.push(_newTeamId) - 1;
    require(_teamIndex < 4294967295);

    // Map the team&#39;s ID to its index in the teamIds array
    _contestToEnter.teamIdToIdx[_newTeamId] = uint32(_teamIndex);

    // Map the team to the contest
    teamIdToContestId[_newTeamId] = uint32(_contestId);

    // Fire event
    emit ContestEntered(_contestId, _newTeamId);

  }

  /// @dev Removes a team from a contest. The msg.sender must be the owner
  ///   of the team being removed.
  function exitContest(uint32 _teamId) public {

    // Get the team from the team contract
    address owner;
    int32 score;
    uint32 place;
    bool holdsEntryFee;
    bool ownsPlayerTokens;
    (owner, score, place, holdsEntryFee, ownsPlayerTokens) = teamContract.getTeam(_teamId);

    // Caller must own the team
    require (owner == msg.sender);

    uint32 _contestId = teamIdToContestId[_teamId];
    require(_contestId > 0);
    Contest storage _contestToExitFrom = contests[_contestId];

    // Cannot exit a contest that has already begun
    require(_contestToExitFrom.startTime > uint64(now));

    // Return the entry fee to the owner and release the team
    if (holdsEntryFee) {
      teamContract.refunded(_teamId);
      if (_contestToExitFrom.entryFee > 0) {
        _authorizePayment(owner, _contestToExitFrom.entryFee);
        emit ContestTeamRefundPaid(_contestId, _teamId, _contestToExitFrom.entryFee);
      }
    }
    teamContract.releaseTeam(_teamId);  // Will throw if _teamId does not exist

    // Remove the team from our list of teams participating in the contest
    //
    // Note that this mechanism works even if the teamId to be removed is the last
    // entry in the teamIds array. In this case, the lastTeamIdx == toRemoveIdx so
    // we would overwrite the last entry with itself. This last entry is subsequently
    // removed from the teamIds array.
    //
    // Note that because of this method of removing a team from the teamIds array,
    // the teamIds array is not guaranteed to be in an order that maps to the order of
    // teams entering the contest (the order is now arbitrary).
    uint32 lastTeamIdx = uint32(_contestToExitFrom.teamIds.length) - 1;
    uint32 lastTeamId = _contestToExitFrom.teamIds[lastTeamIdx];
    uint32 toRemoveIdx = _contestToExitFrom.teamIdToIdx[_teamId];

    require(_contestToExitFrom.teamIds[toRemoveIdx] == _teamId);      // Sanity check (handle&#39;s Solidity&#39;s mapping of non-existing entries to 0)

    _contestToExitFrom.teamIds[toRemoveIdx] = lastTeamId;             // Overwriting the teamIds array entry for the team
                                                                      // being removed with the last entry&#39;s teamId
    _contestToExitFrom.teamIdToIdx[lastTeamId] = toRemoveIdx;         // Re-map the lastTeamId to the removed teamId&#39;s index

    delete _contestToExitFrom.teamIds[lastTeamIdx];                   // Remove the last entry that is now repositioned
    _contestToExitFrom.teamIds.length--;                              // Shorten the array
    delete _contestToExitFrom.teamIdToIdx[_teamId];                   // Remove the index mapping for the removed team

    // Remove the team from our list of teams participating in the contest
    // (OLD way that would limit the # of teams in a contest due to gas consumption)
//    for (uint i = 0; i < _contestToExitFrom.teamIds.length; i++) {
//      if (_contestToExitFrom.teamIds[i] == _teamId) {
//        uint32 stopAt = uint32(_contestToExitFrom.teamIds.length - 1);
//        for (uint  j = i; j < stopAt; j++) {
//          _contestToExitFrom.teamIds[j] = _contestToExitFrom.teamIds[j+1];
//        }
//        delete _contestToExitFrom.teamIds[_contestToExitFrom.teamIds.length-1];
//        _contestToExitFrom.teamIds.length--;
//        break;
//      }
//    }

    // This _teamId will no longer map to any contest
    delete teamIdToContestId[_teamId];

    // Fire event
    emit ContestExited(_contestId, _teamId);
  }

  /// @dev Method that allows a contest creator to cancel his/her contest.
  ///   Throws if we try to cancel a contest not owned by the msg.sender
  ///   or by contract&#39;s scoring oracle. Also throws if we try to cancel a contest that
  ///   is not int the ContestStatus.Active state.
  function cancelContest(uint32 _contestId) public {

    require(_contestId > 0);
    Contest storage _toCancel = contests[_contestId];

    // The a contest can only be canceled if it is in the active state.
    require (_toCancel.status == ContestStatus.Active);

    // Now make sure the calling entity is authorized to cancel the contest
    // based on the state of the contest.
    if (_toCancel.startTime > uint64(now)) {
      // This is a contest that starts in the future. The creator of
      // the contest or the scoringOracle can cancel it.
      require((msg.sender == _toCancel.creator) || (msg.sender == _toCancel.scoringOracleAddress));
    } else {
      // This is a contest that has passed its lock time (i.e. started).
      if (_toCancel.teamIds.length >= uint32(_toCancel.maxMinEntries & 0x00000000FFFFFFFF)) {

        // A contest that has met its minimum entry count can only be canceled
        // by the scoringOracle.
        require(msg.sender == _toCancel.scoringOracleAddress);
      }
    }

    // Note: Contests that have not met their minimum entry requirement
    // can be canceled by anyone since they cannot be scored or paid out. Once canceled,
    // anyone can release the teams back to their owners and refund any entry
    // fees. Otherwise, it would require the contests&#39; ending time to pass
    // before anyone could release and refund as implemented in the
    // releaseTeams(...) method.

    // Return the creator&#39;s prizeAmount
    if (_toCancel.prizeAmount > 0) {
      _authorizePayment(_toCancel.creator, _toCancel.prizeAmount);
      _toCancel.remainingPrizeAmount = 0;
    }

    // Mark the contest as canceled, which then will allow anyone to
    // release the teams (and refund the entryFees if any) for this contest.
    // Generally, this is automatically done by the scoring oracle.
    _toCancel.status = ContestStatus.Canceled;

    // Fire event
    emit ContestCanceled(_contestId);
  }

  /// @dev - Releases a set of teams if the contest has passed its ending
  //    time (or has been canceled). This method can be called by the general
  ///   public, but should called by our scoring oracle automatically.
  /// @param _contestId - The ID of the contest the teams belong to
  /// @param _teamIds - TeamIds of the teams we want to release. Array should
  ///   be short enough in length so as not to run out of gas
  function releaseTeams(uint32 _contestId, uint32[] _teamIds) public {
    require((_contestId < contests.length) && (_contestId > 0));
    Contest storage c = contests[_contestId];

    // Teams can only be released for canceled contests or contests that have
    // passed their end times.
    require ((c.status == ContestStatus.Canceled) || (c.endTime <= uint64(now)));

    for (uint32 i = 0; i < _teamIds.length; i++) {
      uint32 teamId = _teamIds[i];
      uint32 teamContestId = teamIdToContestId[teamId];
      if (teamContestId == _contestId) {
        address owner;
        int32 score;
        uint32 place;
        bool holdsEntryFee;
        bool ownsPlayerTokens;
        (owner, score, place, holdsEntryFee, ownsPlayerTokens) = teamContract.getTeam(teamId);
        if ((c.status == ContestStatus.Canceled) && holdsEntryFee) {
          teamContract.refunded(teamId);
          if (c.entryFee > 0) {
            emit ContestTeamRefundPaid(_contestId, teamId, c.entryFee);
            _authorizePayment(owner, c.entryFee);
          }
        }
        if (ownsPlayerTokens) {
          teamContract.releaseTeam(teamId);
        }
      }
    }
  }

  /// @dev - Updates a team with new player tokens, releasing ones that are replaced back
  ///   to the owner. New player tokens must be approved for transfer to the team contract.
  /// @param _contestId - ID of the contest we are working on
  /// @param _teamId - Team ID of the team being updated
  /// @param _indices - Indices of playerTokens to be replaced
  /// @param _tokenIds - Array of player token IDs that will replace those
  ///   currently held at the indices specified.
  function updateContestTeam(uint32 _contestId, uint32 _teamId, uint8[] _indices, uint32[] _tokenIds) public whenNotPaused {
    require((_contestId > 0) && (_contestId < contests.length));
    Contest storage c = contests[_contestId];
    require (c.status == ContestStatus.Active);

    // To prevent a form of sniping, we do not allow you to update your
    // team within 1 hour of the starting time of the contest.
    require(c.startTime > uint64(now + 1 hours));

    teamContract.updateTeam(msg.sender, _teamId, _indices, _tokenIds);
  }

  /// @dev Returns the contest data for a specific contest
  ///@param _contestId - contest ID we are seeking the full info for
  function getContest(uint32 _contestId) public view returns (
    string name,                    // Name of this contest
    address scoringOracleAddress,   // Address of the scoring oracle for this contest
    uint32 gameSetId,               // ID of the gameset associated with this contest
    uint32 maxEntries,              // Maximum number of entries allowed in the contest
    uint64 startTime,               // Starting time for the contest (lock time)
    uint64 endTime,                 // Ending time for the contest (lock time)
    address creator,                // Address of the creator of the contest
    uint128 entryFee,               // Fee to enter the contest
    uint128 prizeAmount,            // Fee to enter the contest
    uint32 minEntries,              // Wide receivers
    uint8 status,                   // 1 = active, 2 = scored, 3-paying, 4 = paid, 5 = canceled
    uint8 payoutKey,                // Identifies the payout structure for the contest (see comments above)
    uint32 entryCount               // Current number of entries in the contest
  )
  {
    require((_contestId > 0) && (_contestId < contests.length));

    // Unpack max & min entries (packed in struct due to stack limitations)
    // Couldn&#39;t create these local vars due to stack limitation too.
    /* uint32 _maxEntries = uint32(c.maxMinEntries >> 32);
    uint32 _minEntries = uint32(c.maxMinEntries & 0x00000000FFFFFFFF); */

    Contest storage c = contests[_contestId];
    scoringOracleAddress = c.scoringOracleAddress;
    gameSetId = c.gameSetId;
    maxEntries = uint32(c.maxMinEntries >> 32);
    startTime = c.startTime;
    endTime = c.endTime;
    creator = c.creator;
    entryFee = c.entryFee;
    prizeAmount = c.prizeAmount;
    minEntries = uint32(c.maxMinEntries & 0x00000000FFFFFFFF);
    status = uint8(c.status);
    payoutKey = uint8(c.payoutKey);
    name = c.name;
    entryCount = uint32(c.teamIds.length);
  }

  /// @dev Returns the number of teams in a particular contest
  /// @param _contestId ID of contest we are inquiring about
  function getContestTeamCount(uint32 _contestId) public view returns (uint32 count) {
    require((_contestId > 0) && (_contestId < contests.length));
    Contest storage c = contests[_contestId];
    count = uint32(c.teamIds.length);
  }

  /// @dev Returns the index into the teamIds array of a contest a particular teamId sits at
  /// @param _contestId ID of contest we are inquiring about
  /// @param _teamId The team ID within the contest that we are interested in learning its teamIds index
  function getIndexForTeamId(uint32 _contestId, uint32 _teamId) public view returns (uint32 idx) {
    require((_contestId > 0) && (_contestId < contests.length));
    Contest storage c = contests[_contestId];
    idx = c.teamIdToIdx[_teamId];

    require (idx < c.teamIds.length);  // Handles the Solidity returning 0 from mapping for non-existent entries
    require(c.teamIds[idx] == _teamId);
  }

  /// @dev Returns the team data for a particular team entered into the contest
  /// @param _contestId - ID of contest we are getting a team from
  /// @param _teamIndex - Index of team we are getting from the contest
  function getContestTeam(uint32 _contestId, uint32 _teamIndex) public view returns (
    uint32 teamId,
    address owner,
    int score,
    uint place,
    bool holdsEntryFee,
    bool ownsPlayerTokens,
    uint32 count,
    uint32[50] playerTokenIds
  )
  {
    require((_contestId > 0) && (_contestId < contests.length));
    Contest storage c = contests[_contestId];
    require(_teamIndex < c.teamIds.length);

    uint32 _teamId = c.teamIds[_teamIndex];
    (teamId) = _teamId;
    (owner, score, place, holdsEntryFee, ownsPlayerTokens) = teamContract.getTeam(_teamId);
    (count, playerTokenIds) = teamContract.tokenIdsForTeam(_teamId);
  }

  /// @dev - Puts the contest into a state where the scoring oracle can
  ///   now score the contest. CAN ONLY BE CALLED BY THE SCORING ORACLE
  ///   for the given contest.
  function prepareToScore(uint32 _contestId) public {
    require((_contestId > 0) && (_contestId < contests.length));
    Contest storage c = contests[_contestId];
    require ((c.scoringOracleAddress == msg.sender) && (c.status == ContestStatus.Active) && (c.endTime <= uint64(now)));

    // Cannot score a contest that has not met its minimum entry count
    require (uint32(c.teamIds.length) >= uint32(c.maxMinEntries & 0x00000000FFFFFFFF));

    c.status = ContestStatus.Scoring;

    // Calculate the # of winners to payout
    uint32 numWinners = 1;
    if (c.payoutKey == PayoutKey.TopTen) {
        numWinners = 10;
    } else if (c.payoutKey == PayoutKey.FiftyFifty) {
        numWinners = uint32(c.teamIds.length) / 2;
    }
    c.winnersToPay = numWinners;
    c.numWinners = numWinners;

    // We must have at least as many entries into the contest as there are
    // number of winners. i.e. must have 10 or more entries in a top ten
    // payout contest.
    require(c.numWinners <= c.teamIds.length);
  }

  /// @dev Assigns a score and place for an array of teams. The indexes into the
  ///   arrays are what tie a particular teamId to score and place. The contest being
  ///   scored must (a) be in the ContestStatus.Scoring state, and (b) have its
  ///   scoringOracleAddress == the msg.sender.
  /// @param _contestId - ID of contest the teams being scored belong to
  /// @param _teamIds - IDs of the teams we are scoring
  /// @param _scores - Scores to assign
  /// @param _places - Places to assign
  /// @param _startingPlaceOffset - Offset the _places[0] is from first place
  /// @param _totalWinners - Total number of winners including ties
  function scoreTeams(uint32 _contestId, uint32[] _teamIds, int32[] _scores, uint32[] _places, uint32 _startingPlaceOffset, uint32 _totalWinners) public {
    require ((_teamIds.length == _scores.length) && (_teamIds.length == _places.length));
    require((_contestId > 0) && (_contestId < contests.length));
    Contest storage c = contests[_contestId];
    require ((c.scoringOracleAddress == msg.sender) && (c.status == ContestStatus.Scoring));

    // Deal with validating the teams all belong to the contest,
    // and assign to winners list if we have a prizeAmount.
    for (uint32 i = 0; i < _places.length; i++) {
      uint32 teamId = _teamIds[i];

      // Make sure ALL TEAMS PASED IN BELONG TO THE CONTEST BEING SCORED
      uint32 contestIdForTeamBeingScored = teamIdToContestId[teamId];
      require(contestIdForTeamBeingScored == _contestId);

      // Add the team to the winners list if we have a prize
      if (c.prizeAmount > 0) {
        if ((_places[i] <= _totalWinners - _startingPlaceOffset) && (_places[i] > 0)) {
          c.placeToWinner[_places[i] + _startingPlaceOffset] = teamId;
        }
      }
    }

    // Relay request over to the team contract
    teamContract.scoreTeams(_teamIds, _scores, _places);
  }

  /// @dev Returns the place a particular team finished in (or is currently
  ///   recorded as being in). Mostly used just to verify things during dev.
  /// @param _teamId - Team ID of the team we are inquiring about
  function getWinningPosition(uint32 _teamId) public view returns (uint32) {
    uint32 _contestId = teamIdToContestId[_teamId];
    require(_contestId > 0);
    Contest storage c = contests[_contestId];
    for (uint32 i = 1; i <= c.teamIds.length; i++) {
      if (c.placeToWinner[i] == _teamId) {
        return i;
      }
    }
    return 0;
  }

  /// @dev - Puts the contest into a state where the scoring oracle can
  ///   pay the winners of a contest. CAN ONLY BE CALLED BY THE SCORING ORACLE
  ///   for the given contest. Contest must be in the ContestStatus.Scoring state.
  /// @param _contestId - ID of contest being prepared to payout.
  function prepareToPayWinners(uint32 _contestId) public {
    require((_contestId > 0) && (_contestId < contests.length));
    Contest storage c = contests[_contestId];
    require ((c.scoringOracleAddress == msg.sender) && (c.status == ContestStatus.Scoring) && (c.endTime < uint64(now)));
    c.status = ContestStatus.Paying;
  }

  /// @dev Returns the # of winners to pay if we are in the paying state.
  /// @param _contestId - ID of contestId we are inquiring about
  function numWinnersToPay(uint32 _contestId) public view returns (uint32) {
    require((_contestId > 0) && (_contestId < contests.length));
    Contest memory c = contests[_contestId];
    if (c.status == ContestStatus.Paying) {
      return c.winnersToPay;
    } else {
      return 0;
    }
  }

  /// @dev Pays the next batch of winners (authorizes payment) and return TRUE if there
  ///   more to pay, otherwise FALSE. Contest must be in the ContestStatus.Paying state
  ///   and CAN ONLY BE CALLED BY THE SCORING ORACLE. The scoring oracle is intended to
  ///   loop on this until it returns FALSE.
  /// @param _contestId - ID of contest being paid out.
  /// @param _payingStartingIndex - Starting index of winner being paid. Equal to the number
  /// of winners paid in previous calls to this method. Starts at 0 and goes up by numToPay
  /// each time the method is called.
  /// @param _numToPay - The number of winners to pay this time, can exceed the number
  ///   left to pay.
  /// @param _isFirstPlace - True if the first entry at the place being scored is a first
  ///   place winner
  /// @param _prevTies - # of places prior to the first place being paid in this call that
  ///   had a tied value to the first place being paid in this call
  /// @param _nextTies - # of places after to the last place being scored in this call that
  ///   had a tied value to the last place paid in this call
  function payWinners(uint32 _contestId, uint32 _payingStartingIndex, uint _numToPay, bool _isFirstPlace, uint32 _prevTies, uint32 _nextTies) public {
    require((_contestId > 0) && (_contestId < contests.length));
    Contest storage c = contests[_contestId];
    require ((c.scoringOracleAddress == msg.sender) && (c.status == ContestStatus.Paying));

    // Due to EVM stack restrictings, certain local variables are packed into
    // an array that is stored in memory as opposed to the stack.
    //
    // localVars index 0 = placeBeingPaid (
    // localVars index 1 = nextBeingPaid
    uint32[] memory localVars = new uint32[](2);
    localVars[0] = _payingStartingIndex + 1;

    // We have to add _prevTies here to handle the case where a batch holding the final
    // winner to pay position (1, 10, or 50%) finishes processing its batch size, but
    // the final position is a tie and the next batch is a tie of the final position.
    // When the next batch is called, the c.winnersToPay would be 0 but there are still
    // positions to be paid as ties to last place. This is where _prevTies comes in
    // and keeps us going. However, a rogue scoring oracle could keep calling this
    // payWinners method with a positive _prevTies value, which could cause us to
    // pay out too much. This is why we have the c.remainingPrizeAmount check when
    // we loop and actually payout the winners.
    if (c.winnersToPay + _prevTies > 0) {
      // Calculation of place amount:
      //
      // let n = c.numWinners
      //
      // s = sum of numbers 1 through c.numWinners
      // m = (2*prizeAmount) / c.numWinners * (c.numWinners + 1);
      // payout = placeBeingPaid*m
      //
      uint32 s = (c.numWinners * (c.numWinners + 1)) / 2;
      uint128 m = c.prizeAmount / uint128(s);
      while ((c.winnersToPay + _prevTies > 0) && (_numToPay > 0)) {

        uint128 totalPayout = 0;
        uint32 totalNumWinnersWithTies = _prevTies;
        if (_prevTies > 0) {
          // Adding the prize money associated with the _prevTies number of
          // places that are getting aggregated into this tied position.
          totalPayout = m*(_prevTies * c.winnersToPay + (_prevTies * (_prevTies + 1)) / 2);
        }

        // nextBeingPaid = placeBeingPaid;
        localVars[1] = localVars[0];

        // This loop accumulates the payouts associated with a string of tied scores.
        // It always executes at least once.
        uint32 numProcessedThisTime = 0;
        while (teamContract.getScore(c.placeToWinner[localVars[1]]) == teamContract.getScore(c.placeToWinner[localVars[0]])) {

          // Accumulate the prize money for each place in a string of tied scores
          // (but only if there are winners left to pay)
          if (c.winnersToPay > 0) {
            totalPayout += m*c.winnersToPay;
          }

          // This value represents the number of ties at a particular score
          totalNumWinnersWithTies++;

          // Incerement the number processed in this call
          numProcessedThisTime++;

          // We decrement our winnersToPay value for each team at the same
          // score, but we don&#39;t let it go negative.
          if (c.winnersToPay > 0) {
            c.winnersToPay--;
          }

          localVars[1]++;
          _numToPay -= 1;
          if ((_numToPay == 0) || (c.placeToWinner[localVars[1]] == 0)) {
            break;
          }
        }

        // Deal with first place getting the distributed rounding error
        if (_isFirstPlace) {
          totalPayout += c.prizeAmount - m * s;
        }
        _isFirstPlace = false;

        // If we are on the last loop of this call, we need to deal
        // with the _nextTies situation
        if ((_numToPay == 0) && (_nextTies > 0)) {
          totalNumWinnersWithTies += _nextTies;
          if (_nextTies < c.winnersToPay) {
            totalPayout += m*(_nextTies * (c.winnersToPay + 1) - (_nextTies * (_nextTies + 1)) / 2);
          } else {
            totalPayout += m*(c.winnersToPay * (c.winnersToPay + 1) - (c.winnersToPay * (c.winnersToPay + 1)) / 2);
          }
        }

        // Payout is evenly distributed to all players with the same score
        uint128 payout = totalPayout / totalNumWinnersWithTies;

        // If this is the last place being paid, we are going to evenly distribute
        // the remaining amount this contest holds in prize money evenly over other
        // the number of folks remaining to be paid.
        if (c.winnersToPay == 0) {
          payout = c.remainingPrizeAmount / (numProcessedThisTime + _nextTies);
        }

        for (uint32 i = _prevTies; (i < (numProcessedThisTime + _prevTies)) && (c.remainingPrizeAmount > 0); i++) {

          // Deals with rounding error in the last payout in a group of ties since the totalPayout
          // was divided among tied players.
          if (i == (totalNumWinnersWithTies - 1)) {
            if ((c.winnersToPay == 0) && (_nextTies == 0)) {
              payout = c.remainingPrizeAmount;
            } else {
              payout = totalPayout - (totalNumWinnersWithTies - 1)*payout;
            }
          }

          // This is a safety check. Shouldn&#39;t be needed but this prevents a rogue scoringOracle
          // from draining anything more than the prize amount for the contest they are oracle of.
          if (payout > c.remainingPrizeAmount) {
            payout = c.remainingPrizeAmount;
          }
          c.remainingPrizeAmount -= payout;

          _authorizePayment(teamContract.getTeamOwner(c.placeToWinner[localVars[0]]), payout);

          // Fire the event
          emit ContestTeamWinningsPaid(_contestId, c.placeToWinner[localVars[0]], payout);

          // Increment our placeBeingPaid value
          localVars[0]++;
        }

        // We only initialize with _prevTies the first time through the loop
        _prevTies = 0;

      }
    }
  }

  /// @dev Closes out a contest that is currently in the ContestStatus.Paying state.
  ///   The contest being closed must (a) be in the ContestStatus.Paying state, and (b) have its
  ///   scoringOracleAddress == the msg.sender, and (c) have no more winners to payout.
  ///   Will then allow for the player tokens associated with any team in this contest to be released.
  ///   Also authorizes the payment of all entry fees to the contest creator (less ownerCut if
  ///   cryptosports was the scoring oracle)
  /// @param _contestId - ID of the contest to close
  function closeContest(uint32 _contestId) public {
    require((_contestId > 0) && (_contestId < contests.length));
    Contest storage c = contests[_contestId];
    require ((c.scoringOracleAddress == msg.sender) && (c.status == ContestStatus.Paying) && (c.winnersToPay == 0));

    // Move to the Paid state so we can only close the contest once
    c.status = ContestStatus.Paid;

    uint128 totalEntryFees = c.entryFee * uint128(c.teamIds.length);

    // Transfer owner cut to the CFO address if the contest was scored by the commissioner
    if (c.scoringOracleAddress == commissionerAddress) {
      uint128 cut = _computeCut(totalEntryFees);
      totalEntryFees -= cut;
      cfoAddress.transfer(cut);
    }

    // Payout the contest creator
    if (totalEntryFees > 0) {
      _authorizePayment(c.creator, totalEntryFees);
      emit ContestCreatorEntryFeesPaid(_contestId, totalEntryFees);
    }

    emit ContestClosed(_contestId);
  }

  // ---------------------------------------------------------------------------
  // PRIVATE METHODS -----------------------------------------------------------
  // ---------------------------------------------------------------------------

  /// @dev Authorizes a user to receive payment from this contract.
  /// @param _to - Address authorized to withdraw funds
  /// @param _amount - Amount to authorize
  function _authorizePayment(address _to, uint128 _amount) private {
    totalAuthorizedForPayment += _amount;
    uint128 _currentlyAuthorized = authorizedUserPayment[_to];
    authorizedUserPayment[_to] = _currentlyAuthorized + _amount;
  }

  /// @dev Computes owner&#39;s cut of a contest&#39;s entry fees.
  /// @param _amount - Amount owner is getting cut of
  function _computeCut(uint128 _amount) internal view returns (uint128) {
      // NOTE: We don&#39;t use SafeMath (or similar) in this function because
      //  all of our entry functions carefully cap the maximum values for
      //  currency (at 128-bits), and ownerCut <= 10000 (see the require()
      //  statement in the CSportsContest constructor). The result of this
      //  function is always guaranteed to be <= _amount.
      return uint128(_amount * ownerCut / 10000);
  }

}