pragma solidity ^0.4.25;

/// @dev Interface required by league roster contract to access
/// the mintPlayers(...) function
interface CSportsRosterInterface {

    /// @dev Called by core contract as a sanity check
    function isLeagueRosterContract() external pure returns (bool);

    /// @dev Called to indicate that a commissioner auction has completed
    function commissionerAuctionComplete(uint32 _rosterIndex, uint128 _price) external;

    /// @dev Called to indicate that a commissioner auction was canceled
    function commissionerAuctionCancelled(uint32 _rosterIndex) external view;

    /// @dev Returns the metadata for a specific real world player token
    function getMetadata(uint128 _md5Token) external view returns (string);

    /// @dev Called to return a roster index given the MD5
    function getRealWorldPlayerRosterIndex(uint128 _md5Token) external view returns (uint128);

    /// @dev Returns a player structure given its index
    function realWorldPlayerFromIndex(uint128 idx) external view returns (uint128 md5Token, uint128 prevCommissionerSalePrice, uint64 lastMintedTime, uint32 mintedCount, bool hasActiveCommissionerAuction, bool mintingEnabled);

    /// @dev Called to update a real world player entry - only used dureing development
    function updateRealWorldPlayer(uint32 _rosterIndex, uint128 _prevCommissionerSalePrice, uint64 _lastMintedTime, uint32 _mintedCount, bool _hasActiveCommissionerAuction, bool _mintingEnabled) external;

}

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

/// @dev Interface required by league roster contract to access
/// the mintPlayers(...) function
interface CSportsCoreInterface {

    /// @dev Called as a sanity check to make sure we have linked the core contract
    function isCoreContract() external pure returns (bool);

    /// @dev Escrows all of the tokensIds passed by transfering ownership
    ///   to the teamContract. CAN ONLY BE CALLED BY THE CURRENT TEAM CONTRACT.
    /// @param _owner - Current owner of the token being authorized for transfer
    /// @param _tokenIds The IDs of the PlayerTokens that can be transferred if this call succeeds.
    function batchEscrowToTeamContract(address _owner, uint32[] _tokenIds) external;

    /// @dev Change or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    ///  Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param _to The new approved NFT controller
    /// @param _tokenId The NFT to approve
    function approve(address _to, uint256 _tokenId) external;

    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///  THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
}
/// @title Generic CSports Team Contract
/// @dev Implementation of interface CSportsTeam for a generic team contract
/// that supports a variable # players per team (set in constructor)
contract CSportsTeamGeneric is CSportsAuth, CSportsTeam,  CSportsContestBase {

  /// STORAGE

  /// @dev Reference to core contract ownership of player tokens
  CSportsCoreInterface public coreContract;

  /// @dev Reference to contest contract ownership of player tokens
  address public contestContractAddress;

  /// @dev Instance of our CSportsLeagueRoster contract. Can be set by
  ///   the CEO.
  CSportsRosterInterface public leagueRosterContract;

  // Next team ID to assign
  uint64 uniqueTeamId;

  // Number of players on a team
  uint32 playersPerTeam;

  /// @dev Structure to hold our active teams
  mapping (uint32 => Team) teamIdToTeam;

  /// PUBLIC METHODS

  /// @dev Class constructor creates the main CSportsTeamMlb smart contract instance.
  constructor(uint32 _playersPerTeam) public {

      // All C-level roles are the message sender
      ceoAddress = msg.sender;
      cfoAddress = msg.sender;
      cooAddress = msg.sender;
      commissionerAddress = msg.sender;

      // Notice our uniqueTeamId starts at 1, making a 0 value indicate
      // a non-existent team.
      uniqueTeamId = 1;

      // Initialize parent properties
      isTeamContract = true;

      // Players per team
      playersPerTeam = _playersPerTeam;
  }

  /// @dev Sets the contestContractAddress that we interact with
  /// @param _address - Address of our contest contract
  function setContestContractAddress(address _address) public onlyCEO {
    contestContractAddress = _address;
  }

  /// @dev Sets the coreContract that we interact with
  /// @param _address - Address of our core contract
  function setCoreContractAddress(address _address) public onlyCEO {
    CSportsCoreInterface candidateContract = CSportsCoreInterface(_address);
    require(candidateContract.isCoreContract());
    coreContract = candidateContract;
  }

  /// @dev Sets the leagueRosterContract that we interact with
  /// @param _address - The address of our league roster contract
  function setLeagueRosterContractAddress(address _address) public onlyCEO {
    CSportsRosterInterface candidateContract = CSportsRosterInterface(_address);
    require(candidateContract.isLeagueRosterContract());
    leagueRosterContract = candidateContract;
  }

  /// @dev Consolidates setting of contract links into a single call for deployment expediency
  function setLeagueRosterAndCoreAndContestContractAddress(address _league, address _core, address _contest) public onlyCEO {
    setLeagueRosterContractAddress(_league);
    setCoreContractAddress(_core);
    setContestContractAddress(_contest);
  }

  /// @dev Called to create a team for use in CSports.
  ///   _escrow(...) Verifies that all of the tokens presented
  ///   are owned by the sender, and transfers ownership to this contract. This
  ///   assures that the PlayerTokens cannot be sold in an auction, or entered
  ///   into a different contest. CALLED ONLY BY CONTEST CONTRACT
  ///
  ///   Also note that the size of the _tokenIds array passed must be 10. This is
  ///   particular to the kind of contest we are running (10 players fielded).
  /// @param _owner - Owner of the team, must own all of the player tokens being
  ///   associated with the team.
  /// @param _tokenIds - Player token IDs to associate with the team, must be owned
  ///   by _owner and will be held in escrow unless released through an update
  ///   or the team is destroyed.
  function createTeam(address _owner, uint32[] _tokenIds) public returns (uint32) {
    require(msg.sender == contestContractAddress);
    require(_tokenIds.length == playersPerTeam);

    // Escrow the player tokens held by this team
    // it will throw if _owner does not own any of the tokens or this CSportsTeam contract
    // has not been set in the CSportsCore contract.
    coreContract.batchEscrowToTeamContract(_owner, _tokenIds);

    uint32 _teamId =  _createTeam(_owner, _tokenIds);

    emit TeamCreated(_teamId, _owner);

    return _teamId;
  }

  /// @dev Upates the player tokens held by a specific team. Throws if the
  ///   message sender does not own the team, or if the team does not
  ///   exist. CALLED ONLY BY CONTEST CONTRACT
  /// @param _owner - Owner of the team
  /// @param _teamId - ID of the team we wish to update
  /// @param _indices - Indices of playerTokens to be replaced
  /// @param _tokenIds - Array of player token IDs that will replace those
  ///   currently held at the indices specified.
  function updateTeam(address _owner, uint32 _teamId, uint8[] _indices, uint32[] _tokenIds) public {
    require(msg.sender == contestContractAddress);
    require(_owner != address(0));
    require(_tokenIds.length <= playersPerTeam);
    require(_indices.length <= playersPerTeam);
    require(_indices.length == _tokenIds.length);

    Team storage _team = teamIdToTeam[_teamId];
    require(_owner == _team.owner);

    // Escrow the player tokens that will replace those in the team currently -
    // it will throw if _owner does not own any of the tokens or this CSportsTeam contract
    // has not been set in the CSportsCore contract.
    coreContract.batchEscrowToTeamContract(_owner, _tokenIds);

    // Loop through the indices we are updating, and make the update
    for (uint8 i = 0; i < _indices.length; i++) {
      require(_indices[i] <= playersPerTeam);

      uint256 _oldTokenId = uint256(_team.playerTokenIds[_indices[i]]);
      uint256 _newTokenId = _tokenIds[i];

      // Release the _oldToken back to its original owner.
      // (note _owner == _team.owner == original owner of token we are returning)
      coreContract.approve(_owner, _oldTokenId);
      coreContract.transferFrom(address(this), _owner, _oldTokenId);

      // Update the token ID in the team at the same index as the player token removed.
      _team.playerTokenIds[_indices[i]] = uint32(_newTokenId);

    }

    emit TeamUpdated(_teamId);
  }

  /// @dev Releases the team by returning all of the tokens held by the team and removing
  ///   the team from our mapping. CALLED ONLY BY CONTEST CONTRACT
  /// @param _teamId - team id of the team being destroyed
  function releaseTeam(uint32 _teamId) public {

    require(msg.sender == contestContractAddress);
    Team storage _team = teamIdToTeam[_teamId];
    require(_team.owner != address(0));

    if (_team.ownsPlayerTokens) {
      // Loop through all of the player tokens held by the team, and
      // release them back to the original owner.
      for (uint32 i = 0; i < _team.playerTokenIds.length; i++) {
        uint32 _tokenId = _team.playerTokenIds[i];
        coreContract.approve(_team.owner, _tokenId);
        coreContract.transferFrom(address(this), _team.owner, _tokenId);
      }

      // This team&#39;s player tokens are no longer held in escrow
      _team.ownsPlayerTokens = false;

      emit TeamReleased(_teamId);
    }

  }

  /// @dev Marks the team as having its entry fee refunded
  ///   CALLED ONLY BY CONTEST CONTRACT
  /// @param _teamId - ID of team to refund entry fee.
  function refunded(uint32 _teamId) public {
    require(msg.sender == contestContractAddress);
    Team storage _team = teamIdToTeam[_teamId];
    require(_team.owner != address(0));
    _team.holdsEntryFee = false;
  }

  /// @dev Assigns a score and place for an array of teams. The indexes into the
  ///   arrays are what tie a particular teamId to score and place.
  ///   CALLED ONLY BY CONTEST CONTRACT
  /// @param _teamIds - IDs of the teams we are scoring
  /// @param _scores - Scores to assign
  /// @param _places - Places to assign
  function scoreTeams(uint32[] _teamIds, int32[] _scores, uint32[] _places) public {

    require(msg.sender == contestContractAddress);
    require ((_teamIds.length == _scores.length) && (_teamIds.length == _places.length)) ;
    for (uint i = 0; i < _teamIds.length; i++) {
      Team storage _team = teamIdToTeam[_teamIds[i]];
      if (_team.owner != address(0)) {
        _team.score = _scores[i];
        _team.place = _places[i];
      }
    }
  }

  /// @dev Returns the score assigned to a particular team.
  /// @param _teamId ID of the team we are inquiring about
  function getScore(uint32 _teamId) public view returns (int32) {
    Team storage _team = teamIdToTeam[_teamId];
    require(_team.owner != address(0));
    return _team.score;
  }

  /// @dev Returns the place assigned to a particular team.
  /// @param _teamId ID of the team we are inquiring about
  function getPlace(uint32 _teamId) public view returns (uint32) {
    Team storage _team = teamIdToTeam[_teamId];
    require(_team.owner != address(0));
    return _team.place;
  }

  /// @dev Returns whether or not this team owns the player tokens it
  ///   references in the playerTokenIds property.
  /// @param _teamId ID of the team we are inquiring about
  function ownsPlayerTokens(uint32 _teamId) public view returns (bool) {
    Team storage _team = teamIdToTeam[_teamId];
    require(_team.owner != address(0));
    return _team.ownsPlayerTokens;
  }

  /// @dev Returns the owner of a specific team
  /// @param _teamId - ID of team we are inquiring about
  function getTeamOwner(uint32 _teamId) public view returns (address) {
    Team storage _team = teamIdToTeam[_teamId];
    require(_team.owner != address(0));
    return _team.owner;
  }

  /// @dev Returns all of the token id held by a particular team. Throws if the
  ///   _teamId isn&#39;t valid. Anybody can call this, making teams visible to the
  ///   world.
  /// @param _teamId - ID of the team we are looking to get player tokens for.
  function tokenIdsForTeam(uint32 _teamId) public view returns (uint32 count, uint32[50]) {

     /// @dev A fixed array we can return current auction price information in.
     uint32[50] memory _tokenIds;

     Team storage _team = teamIdToTeam[_teamId];
     require(_team.owner != address(0));

     for (uint32 i = 0; i < _team.playerTokenIds.length; i++) {
       _tokenIds[i] = _team.playerTokenIds[i];
     }

     return (uint32(_team.playerTokenIds.length), _tokenIds);
  }

  /// @dev Returns the entire team structure (less the token IDs) for a specific team
  /// @param _teamId - ID of team we are inquiring about
  function getTeam(uint32 _teamId) public view returns (
      address _owner,
      int32 _score,
      uint32 _place,
      bool _holdsEntryFee,
      bool _ownsPlayerTokens
    ) {
    Team storage t = teamIdToTeam[_teamId];
    require(t.owner != address(0));
    _owner = t.owner;
    _score = t.score;
    _place = t.place;
    _holdsEntryFee = t.holdsEntryFee;
    _ownsPlayerTokens = t.ownsPlayerTokens;
  }

  /// INTERNAL METHODS

  /// @dev Internal function that creates a new team entry. We know that the
  ///   size of the _tokenIds array is correct at this point (checked in calling method)
  /// @param _owner - Account address of team owner (should own all _playerTokenIds)
  /// @param _playerTokenIds - Token IDs of team players
  function _createTeam(address _owner, uint32[] _playerTokenIds) internal returns (uint32) {

    Team memory _team = Team({
      owner: _owner,
      score: 0,
      place: 0,
      holdsEntryFee: true,
      ownsPlayerTokens: true,
      playerTokenIds: _playerTokenIds
    });

    uint32 teamIdToReturn = uint32(uniqueTeamId);
    teamIdToTeam[teamIdToReturn] = _team;

    // Increment our team ID for the next one.
    uniqueTeamId++;

    // It&#39;s probably never going to happen, 4 billion teams is A LOT, but
    // let&#39;s just be 100% sure we never let this happen because teamIds are
    // often cast as uint32.
    require(uniqueTeamId < 4294967295);

    // We should do additional validation on the team here (like are the player
    // positions correct, etc.)

    return teamIdToReturn;
  }

}