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

/// @dev This is the data structure that holds a roster player in the CSportsLeagueRoster
/// contract. Also referenced by CSportsCore.
/// @author CryptoSports, Inc. (http://cryptosports.team)
contract CSportsRosterPlayer {

    struct RealWorldPlayer {

        // The player&#39;s certified identification. This is the md5 hash of
        // {player&#39;s last name}-{player&#39;s first name}-{player&#39;s birthday in YYYY-MM-DD format}-{serial number}
        // where the serial number is usually 0, but gives us an ability to deal with making
        // sure all MD5s are unique.
        uint128 md5Token;

        // Stores the average sale price of the most recent 2 commissioner sales
        uint128 prevCommissionerSalePrice;

        // The last time this real world player was minted.
        uint64 lastMintedTime;

        // The number of PlayerTokens minted for this real world player
        uint32 mintedCount;

        // When true, there is an active auction for this player owned by
        // the commissioner (indicating a gen0 minting auction is in progress)
        bool hasActiveCommissionerAuction;

        // Indicates this real world player can be actively minted
        bool mintingEnabled;

        // Any metadata we want to attach to this player (in JSON format)
        string metadata;

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

/// @title Base contract for CryptoSports. Holds all common structs, events and base variables.
/// @author CryptoSports, Inc. (http://cryptosports.team)
/// @dev See the CSportsCore contract documentation to understand how the various contract facets are arranged.
contract CSportsBase is CSportsAuth, CSportsRosterPlayer {

    /// @dev This emits when ownership of any NFT changes by any mechanism.
    ///  This event emits when NFTs are created (`from` == 0) and destroyed
    ///  (`to` == 0). Exception: during contract creation, any number of NFTs
    ///  may be created and assigned without emitting Transfer. At the time of
    ///  any transfer, the approved address for that NFT (if any) is reset to none.
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /// @dev This emits when the approved address for an NFT is changed or
    ///  reaffirmed. The zero address indicates there is no approved address.
    ///  When a Transfer event emits, this also indicates that the approved
    ///  address for that NFT (if any) is reset to none.
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /// @dev This emits when an operator is enabled or disabled for an owner.
    ///  The operator can manage all NFTs of the owner.
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /// @dev This emits when a commissioner auction is successfully closed
    event CommissionerAuctionSuccessful(uint256 tokenId, uint256 totalPrice, address winner);

    /// @dev This emits when a commissioner auction is canceled
    event CommissionerAuctionCanceled(uint256 tokenId);

    /******************/
    /*** DATA TYPES ***/
    /******************/

    /// @dev The main player token structure. Every released player in the League
    ///  is represented by a single instance of this structure.
    struct PlayerToken {

      // @dev ID of the real world player this token represents. We can only have
      // a max of 4,294,967,295 real world players, which seems to be enough for
      // a while (haha)
      uint32 realWorldPlayerId;

      // @dev Serial number indicating the number of PlayerToken(s) for this
      //  same realWorldPlayerId existed at the time this token was minted.
      uint32 serialNumber;

      // The timestamp from the block when this player token was minted.
      uint64 mintedTime;

      // The most recent sale price of the player token in an auction
      uint128 mostRecentPrice;

    }

    /**************************/
    /*** MAPPINGS (STORAGE) ***/
    /**************************/

    /// @dev A mapping from a PlayerToken ID to the address that owns it. All
    /// PlayerTokens have an owner (newly minted PlayerTokens are owned by
    /// the core contract).
    mapping (uint256 => address) public playerTokenToOwner;

    /// @dev Maps a PlayerToken ID to an address approved to take ownership.
    mapping (uint256 => address) public playerTokenToApproved;

    // @dev A mapping to a given address&#39; tokens
    mapping(address => uint32[]) public ownedTokens;

    // @dev A mapping that relates a token id to an index into the
    // ownedTokens[currentOwner] array.
    mapping(uint32 => uint32) tokenToOwnedTokensIndex;

    /// @dev Maps operators
    mapping(address => mapping(address => bool)) operators;

    // This mapping and corresponding uint16 represent marketing tokens
    // that can be created by the commissioner (up to remainingMarketingTokens)
    // and then given to third parties in the form of 4 words that sha256
    // hash into the key for the mapping.
    //
    // Maps uint256(keccak256) => leagueRosterPlayerMD5
    uint16 public remainingMarketingTokens = MAX_MARKETING_TOKENS;
    mapping (uint256 => uint128) marketingTokens;

    /***************/
    /*** STORAGE ***/
    /***************/

    /// @dev Instance of our CSportsLeagueRoster contract. Can be set by
    ///   the CEO only once because this immutable tie to the league roster
    ///   is what relates a playerToken to a real world player. If we could
    ///   update the leagueRosterContract, we could in effect de-value the
    ///   ownership of a playerToken by switching the real world player it
    ///   represents.
    CSportsRosterInterface public leagueRosterContract;

    /// @dev Addresses of team contract that is authorized to hold player
    ///   tokens for contests.
    CSportsTeam public teamContract;

    /// @dev An array containing all PlayerTokens in existence.
    PlayerToken[] public playerTokens;

    /************************************/
    /*** RESTRICTED C-LEVEL FUNCTIONS ***/
    /************************************/

    /// @dev Sets the reference to the CSportsLeagueRoster contract.
    /// @param _address - Address of CSportsLeagueRoster contract.
    function setLeagueRosterContractAddress(address _address) public onlyCEO {
      // This method may only be called once to guarantee the immutable
      // nature of owning a real world player.
      if (!isDevelopment) {
        require(leagueRosterContract == address(0));
      }

      CSportsRosterInterface candidateContract = CSportsRosterInterface(_address);
      // NOTE: verify that a contract is what we expect (not foolproof, just
      // a sanity check)
      require(candidateContract.isLeagueRosterContract());
      // Set the new contract address
      leagueRosterContract = candidateContract;
    }

    /// @dev Adds an authorized team contract that can hold player tokens
    ///   on behalf of a contest, and will return them to the original
    ///   owner when the contest is complete (or if entry is canceled by
    ///   the original owner, or if the contest is canceled).
    function setTeamContractAddress(address _address) public onlyCEO {
      CSportsTeam candidateContract = CSportsTeam(_address);
      // NOTE: verify that a contract is what we expect (not foolproof, just
      // a sanity check)
      require(candidateContract.isTeamContract());
      // Set the new contract address
      teamContract = candidateContract;
    }

    /**************************/
    /*** INTERNAL FUNCTIONS ***/
    /**************************/

    /// @dev Identifies whether or not the addressToTest is a contract or not
    /// @param addressToTest The address we are interested in
    function _isContract(address addressToTest) internal view returns (bool) {
        uint size;
        assembly {
            size := extcodesize(addressToTest)
        }
        return (size > 0);
    }

    /// @dev Returns TRUE if the token exists
    /// @param _tokenId ID to check
    function _tokenExists(uint256 _tokenId) internal view returns (bool) {
        return (_tokenId < playerTokens.length);
    }

    /// @dev An internal method that mints a new playerToken and stores it
    ///   in the playerTokens array.
    /// @param _realWorldPlayerId ID of the real world player to mint
    /// @param _serialNumber - Indicates the number of playerTokens for _realWorldPlayerId
    ///   that exist prior to this to-be-minted playerToken.
    /// @param _owner - The owner of this newly minted playerToken
    function _mintPlayer(uint32 _realWorldPlayerId, uint32 _serialNumber, address _owner) internal returns (uint32) {
        // We are careful here to make sure the calling contract keeps within
        // our structure&#39;s size constraints. Highly unlikely we would ever
        // get to a point where these constraints would be a problem.
        require(_realWorldPlayerId < 4294967295);
        require(_serialNumber < 4294967295);

        PlayerToken memory _player = PlayerToken({
          realWorldPlayerId: _realWorldPlayerId,
          serialNumber: _serialNumber,
          mintedTime: uint64(now),
          mostRecentPrice: 0
        });

        uint256 newPlayerTokenId = playerTokens.push(_player) - 1;

        // It&#39;s probably never going to happen, 4 billion playerToken(s) is A LOT, but
        // let&#39;s just be 100% sure we never let this happen.
        require(newPlayerTokenId < 4294967295);

        // This will assign ownership, and also emit the Transfer event as
        // per ERC721 draft
        _transfer(0, _owner, newPlayerTokenId);

        return uint32(newPlayerTokenId);
    }

    /// @dev Removes a token (specified by ID) from ownedTokens and
    /// tokenToOwnedTokensIndex mappings for a given address.
    /// @param _from Address to remove from
    /// @param _tokenId ID of token to remove
    function _removeTokenFrom(address _from, uint256 _tokenId) internal {

      // Grab the index into the _from owner&#39;s ownedTokens array
      uint32 fromIndex = tokenToOwnedTokensIndex[uint32(_tokenId)];

      // Remove the _tokenId from ownedTokens[_from] array
      uint lastIndex = ownedTokens[_from].length - 1;
      uint32 lastToken = ownedTokens[_from][lastIndex];

      // Swap the last token into the fromIndex position (which is _tokenId&#39;s
      // location in the ownedTokens array) and shorten the array
      ownedTokens[_from][fromIndex] = lastToken;
      ownedTokens[_from].length--;

      // Since we moved lastToken, we need to update its
      // entry in the tokenToOwnedTokensIndex
      tokenToOwnedTokensIndex[lastToken] = fromIndex;

      // _tokenId is no longer mapped
      tokenToOwnedTokensIndex[uint32(_tokenId)] = 0;

    }

    /// @dev Adds a token (specified by ID) to ownedTokens and
    /// tokenToOwnedTokensIndex mappings for a given address.
    /// @param _to Address to add to
    /// @param _tokenId ID of token to remove
    function _addTokenTo(address _to, uint256 _tokenId) internal {
      uint32 toIndex = uint32(ownedTokens[_to].push(uint32(_tokenId))) - 1;
      tokenToOwnedTokensIndex[uint32(_tokenId)] = toIndex;
    }

    /// @dev Assigns ownership of a specific PlayerToken to an address.
    /// @param _from - Address of who this transfer is from
    /// @param _to - Address of who to tranfer to
    /// @param _tokenId - The ID of the playerToken to transfer
    function _transfer(address _from, address _to, uint256 _tokenId) internal {

        // transfer ownership
        playerTokenToOwner[_tokenId] = _to;

        // When minting brand new PlayerTokens, the _from is 0x0, but we don&#39;t deal with
        // owned tokens for the 0x0 address.
        if (_from != address(0)) {

            // Remove the _tokenId from ownedTokens[_from] array (remove first because
            // this method will zero out the tokenToOwnedTokensIndex[_tokenId], which would
            // stomp on the _addTokenTo setting of this value)
            _removeTokenFrom(_from, _tokenId);

            // Clear our approved mapping for this token
            delete playerTokenToApproved[_tokenId];
        }

        // Now add the token to the _to address&#39; ownership structures
        _addTokenTo(_to, _tokenId);

        // Emit the transfer event.
        emit Transfer(_from, _to, _tokenId);
    }

    /// @dev Converts a uint to its string equivalent
    /// @param v uint to convert
    function uintToString(uint v) internal pure returns (string str) {
      bytes32 b32 = uintToBytes32(v);
      str = bytes32ToString(b32);
    }

    /// @dev Converts a uint to a bytes32
    /// @param v uint to convert
    function uintToBytes32(uint v) internal pure returns (bytes32 ret) {
        if (v == 0) {
            ret = &#39;0&#39;;
        }
        else {
            while (v > 0) {
                ret = bytes32(uint(ret) / (2 ** 8));
                ret |= bytes32(((v % 10) + 48) * 2 ** (8 * 31));
                v /= 10;
            }
        }
        return ret;
    }

    /// @dev Converts bytes32 to a string
    /// @param data bytes32 to convert
    function bytes32ToString (bytes32 data) internal pure returns (string) {

        uint count = 0;
        bytes memory bytesString = new bytes(32); //  = new bytes[]; //(32);
        for (uint j=0; j<32; j++) {
            byte char = byte(bytes32(uint(data) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[j] = char;
                count++;
            } else {
              break;
            }
        }

        bytes memory s = new bytes(count);
        for (j = 0; j < count; j++) {
            s[j] = bytesString[j];
        }
        return string(s);

    }

}

/// @title ERC-721 Non-Fungible Token Standard
/// @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
///  Note: the ERC-165 identifier for this interface is 0x80ac58cd.
interface ERC721 /* is ERC165 */ {
    /// @dev This emits when ownership of any NFT changes by any mechanism.
    ///  This event emits when NFTs are created (`from` == 0) and destroyed
    ///  (`to` == 0). Exception: during contract creation, any number of NFTs
    ///  may be created and assigned without emitting Transfer. At the time of
    ///  any transfer, the approved address for that NFT (if any) is reset to none.
    ///
    /// MOVED THIS TO CSportsBase because of how class structure is derived.
    ///
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    /// @dev This emits when the approved address for an NFT is changed or
    ///  reaffirmed. The zero address indicates there is no approved address.
    ///  When a Transfer event emits, this also indicates that the approved
    ///  address for that NFT (if any) is reset to none.
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

    /// @dev This emits when an operator is enabled or disabled for an owner.
    ///  The operator can manage all NFTs of the owner.
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /// @notice Count all NFTs assigned to an owner
    /// @dev NFTs assigned to the zero address are considered invalid, and this
    ///  function throws for queries about the zero address.
    /// @param _owner An address for whom to query the balance
    /// @return The number of NFTs owned by `_owner`, possibly zero
    function balanceOf(address _owner) external view returns (uint256);

    /// @notice Find the owner of an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///  about them do throw.
    /// @param _tokenId The identifier for an NFT
    /// @return The address of the owner of the NFT
    function ownerOf(uint256 _tokenId) external view returns (address);

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
    ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
    ///  `onERC721Received` on `_to` and throws if the return value is not
    ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) external payable;

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to "".
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;

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
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;

    /// @notice Change or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    ///  Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve
    function approve(address _approved, uint256 _tokenId) external payable;

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///  all of `msg.sender`&#39;s assets
    /// @dev Emits the ApprovalForAll event. The contract MUST allow
    ///  multiple operators per owner.
    /// @param _operator Address to add to the set of authorized operators
    /// @param _approved True if the operator is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) external;

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT.
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId) external view returns (address);

    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

/// @title ERC-721 Non-Fungible Token Standard, optional metadata extension
/// @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
///  Note: the ERC-165 identifier for this interface is 0x5b5e139f.
interface ERC721Metadata /* is ERC721 */ {
    /// @notice A descriptive name for a collection of NFTs in this contract
    function name() external view returns (string _name);

    /// @notice An abbreviated name for NFTs in this contract
    function symbol() external view returns (string _symbol);

    /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
    /// @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
    ///  3986. The URI may point to a JSON file that conforms to the "ERC721
    ///  Metadata JSON Schema".
    function tokenURI(uint256 _tokenId) external view returns (string);
}

/// @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
/// @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
///  Note: the ERC-165 identifier for this interface is 0x780e9d63.
interface ERC721Enumerable /* is ERC721 */ {
    /// @notice Count NFTs tracked by this contract
    /// @return A count of valid NFTs tracked by this contract, where each one of
    ///  them has an assigned and queryable owner not equal to the zero address
    function totalSupply() external view returns (uint256);

    /// @notice Enumerate valid NFTs
    /// @dev Throws if `_index` >= `totalSupply()`.
    /// @param _index A counter less than `totalSupply()`
    /// @return The token identifier for the `_index`th NFT,
    ///  (sort order not specified)
    function tokenByIndex(uint256 _index) external view returns (uint256);

    /// @notice Enumerate NFTs assigned to an owner
    /// @dev Throws if `_index` >= `balanceOf(_owner)` or if
    ///  `_owner` is the zero address, representing invalid NFTs.
    /// @param _owner An address where we are interested in NFTs owned by them
    /// @param _index A counter less than `balanceOf(_owner)`
    /// @return The token identifier for the `_index`th NFT assigned to `_owner`,
    ///   (sort order not specified)
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);
}

/// @dev Note: the ERC-165 identifier for this interface is 0x150b7a02.
interface ERC721TokenReceiver {
    /// @notice Handle the receipt of an NFT
    /// @dev The ERC721 smart contract calls this function on the recipient
    ///  after a `transfer`. This function MAY throw to revert and reject the
    ///  transfer. Return of other than the magic value MUST result in the
    ///  transaction being reverted.
    ///  Note: the contract address is always the message sender.
    /// @param _operator The address which called `safeTransferFrom` function
    /// @param _from The address which previously owned the token
    /// @param _tokenId The NFT identifier which is being transferred
    /// @param _data Additional data with no specified format
    /// @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    ///  unless throwing
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes _data) external returns(bytes4);
}

interface ERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

/// @title The facet of the CSports core contract that manages ownership, ERC-721 compliant.
/// @author CryptoSports, Inc. (http://cryptosports.team)
/// @dev Ref: https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md#specification
/// See the CSportsCore contract documentation to understand how the various contract facets are arranged.
contract CSportsOwnership is CSportsBase {

  /// @notice These are set in the contract constructor at deployment time
  string _name;
  string _symbol;
  string _tokenURI;

  // bool public implementsERC721 = true;
  //
  function implementsERC721() public pure returns (bool)
  {
      return true;
  }

  /// @notice A descriptive name for a collection of NFTs in this contract
  function name() external view returns (string) {
    return _name;
  }

  /// @notice An abbreviated name for NFTs in this contract
  function symbol() external view returns (string) {
    return _symbol;
  }

  /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
  /// @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
  ///  3986. The URI may point to a JSON file that conforms to the "ERC721
  ///  Metadata JSON Schema".
  function tokenURI(uint256 _tokenId) external view returns (string ret) {
    string memory tokenIdAsString = uintToString(uint(_tokenId));
    ret = string (abi.encodePacked(_tokenURI, tokenIdAsString, "/"));
  }

  /// @notice Find the owner of an NFT
  /// @dev NFTs assigned to zero address are considered invalid, and queries
  ///  about them do throw.
  /// @param _tokenId The identifier for an NFT
  /// @return The address of the owner of the NFT
  function ownerOf(uint256 _tokenId)
      public
      view
      returns (address owner)
  {
      owner = playerTokenToOwner[_tokenId];
      require(owner != address(0));
  }

  /// @notice Count all NFTs assigned to an owner
  /// @dev NFTs assigned to the zero address are considered invalid, and this
  ///  function throws for queries about the zero address.
  /// @param _owner An address for whom to query the balance
  /// @return The number of NFTs owned by `_owner`, possibly zero
  function balanceOf(address _owner) public view returns (uint256 count) {
      // I am not a big fan of  referencing a property on an array element
      // that may not exist. But if it does not exist, Solidity will return 0
      // which is right.
      return ownedTokens[_owner].length;
  }

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
  function transferFrom(
      address _from,
      address _to,
      uint256 _tokenId
  )
      public
      whenNotPaused
  {
      require(_to != address(0));
      require (_tokenExists(_tokenId));

      // Check for approval and valid ownership
      require(_approvedFor(_to, _tokenId));
      require(_owns(_from, _tokenId));

      // Validate the sender
      require(_owns(msg.sender, _tokenId) || // sender owns the token
             (msg.sender == playerTokenToApproved[_tokenId]) || // sender is the approved address
             operators[_from][msg.sender]); // sender is an authorized operator for this token

      // Reassign ownership (also clears pending approvals and emits Transfer event).
      _transfer(_from, _to, _tokenId);
  }

  /// @notice Transfer ownership of a batch of NFTs -- THE CALLER IS RESPONSIBLE
  ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
  ///  THEY MAY BE PERMANENTLY LOST
  /// @dev Throws unless `msg.sender` is the current owner, an authorized
  ///  operator, or the approved address for all NFTs. Throws if `_from` is
  ///  not the current owner. Throws if `_to` is the zero address. Throws if
  ///  any `_tokenId` is not a valid NFT.
  /// @param _from - Current owner of the token being authorized for transfer
  /// @param _to - Address we are transferring to
  /// @param _tokenIds The IDs of the PlayerTokens that can be transferred if this call succeeds.
  function batchTransferFrom(
        address _from,
        address _to,
        uint32[] _tokenIds
  )
  public
  whenNotPaused
  {
    for (uint32 i = 0; i < _tokenIds.length; i++) {

        uint32 _tokenId = _tokenIds[i];

        // Check for approval and valid ownership
        require(_approvedFor(_to, _tokenId));
        require(_owns(_from, _tokenId));

        // Validate the sender
        require(_owns(msg.sender, _tokenId) || // sender owns the token
        (msg.sender == playerTokenToApproved[_tokenId]) || // sender is the approved address
        operators[_from][msg.sender]); // sender is an authorized operator for this token

        // Reassign ownership, clear pending approvals (not necessary here),
        // and emit Transfer event.
        _transfer(_from, _to, _tokenId);
    }
  }

  /// @notice Change or reaffirm the approved address for an NFT
  /// @dev The zero address indicates there is no approved address.
  ///  Throws unless `msg.sender` is the current NFT owner, or an authorized
  ///  operator of the current owner.
  /// @param _to The new approved NFT controller
  /// @param _tokenId The NFT to approve
  function approve(
      address _to,
      uint256 _tokenId
  )
      public
      whenNotPaused
  {
      address owner = ownerOf(_tokenId);
      require(_to != owner);

      // Only an owner or authorized operator can grant transfer approval.
      require((msg.sender == owner) || (operators[ownerOf(_tokenId)][msg.sender]));

      // Register the approval (replacing any previous approval).
      _approve(_tokenId, _to);

      // Emit approval event.
      emit Approval(msg.sender, _to, _tokenId);
  }

  /// @notice Change or reaffirm the approved address for an NFT
  /// @dev The zero address indicates there is no approved address.
  /// Throws unless `msg.sender` is the current NFT owner, or an authorized
  /// operator of the current owner.
  /// @param _to The address to be granted transfer approval. Pass address(0) to
  ///  clear all approvals.
  /// @param _tokenIds The IDs of the PlayerTokens that can be transferred if this call succeeds.
  function batchApprove(
        address _to,
        uint32[] _tokenIds
  )
  public
  whenNotPaused
  {
    for (uint32 i = 0; i < _tokenIds.length; i++) {

        uint32 _tokenId = _tokenIds[i];

        // Only an owner or authorized operator can grant transfer approval.
        require(_owns(msg.sender, _tokenId) || (operators[ownerOf(_tokenId)][msg.sender]));

        // Register the approval (replacing any previous approval).
        _approve(_tokenId, _to);

        // Emit approval event.
        emit Approval(msg.sender, _to, _tokenId);
    }
  }

  /// @notice Escrows all of the tokensIds passed by transfering ownership
  ///   to the teamContract. CAN ONLY BE CALLED BY THE CURRENT TEAM CONTRACT.
  /// @param _owner - Current owner of the token being authorized for transfer
  /// @param _tokenIds The IDs of the PlayerTokens that can be transferred if this call succeeds.
  function batchEscrowToTeamContract(
    address _owner,
    uint32[] _tokenIds
  )
    public
    whenNotPaused
  {
    require(teamContract != address(0));
    require(msg.sender == address(teamContract));

    for (uint32 i = 0; i < _tokenIds.length; i++) {

      uint32 _tokenId = _tokenIds[i];

      // Only an owner can transfer the token.
      require(_owns(_owner, _tokenId));

      // Reassign ownership, clear pending approvals (not necessary here),
      // and emit Transfer event.
      _transfer(_owner, teamContract, _tokenId);
    }
  }

  bytes4 constant TOKEN_RECEIVED_SIG = bytes4(keccak256("onERC721Received(address,uint256,bytes)"));

  /// @notice Transfers the ownership of an NFT from one address to another address
  /// @dev Throws unless `msg.sender` is the current owner, an authorized
  ///  operator, or the approved address for this NFT. Throws if `_from` is
  ///  not the current owner. Throws if `_to` is the zero address. Throws if
  ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
  ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
  ///  `onERC721Received` on `_to` and throws if the return value is not
  ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
  /// @param _from The current owner of the NFT
  /// @param _to The new owner
  /// @param _tokenId The NFT to transfer
  /// @param data Additional data with no specified format, sent in call to `_to`
  function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) external payable {
    transferFrom(_from, _to, _tokenId);
    if (_isContract(_to)) {
        ERC721TokenReceiver receiver = ERC721TokenReceiver(_to);
        bytes4 response = receiver.onERC721Received.gas(50000)(msg.sender, _from, _tokenId, data);
        require(response == TOKEN_RECEIVED_SIG);
    }
  }

  /// @notice Transfers the ownership of an NFT from one address to another address
  /// @dev This works identically to the other function with an extra data parameter,
  ///  except this function just sets data to "".
  /// @param _from The current owner of the NFT
  /// @param _to The new owner
  /// @param _tokenId The NFT to transfer
  function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable {
    require(_to != address(0));
    transferFrom(_from, _to, _tokenId);
    if (_isContract(_to)) {
        ERC721TokenReceiver receiver = ERC721TokenReceiver(_to);
        bytes4 response = receiver.onERC721Received.gas(50000)(msg.sender, _from, _tokenId, "");
        require(response == TOKEN_RECEIVED_SIG);
    }
  }

  /// @notice Count NFTs tracked by this contract
  /// @return A count of valid NFTs tracked by this contract, where each one of
  ///  them has an assigned and queryable owner not equal to the zero address
  function totalSupply() public view returns (uint) {
      return playerTokens.length;
  }

  /// @notice Enumerate NFTs assigned to an owner
  /// @dev Throws if `index` >= `balanceOf(owner)` or if
  ///  `owner` is the zero address, representing invalid NFTs.
  /// @param owner An address where we are interested in NFTs owned by them
  /// @param index A counter less than `balanceOf(owner)`
  /// @return The token identifier for the `index`th NFT assigned to `owner`,
  ///   (sort order not specified)
  function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 _tokenId) {
      require(owner != address(0));
      require(index < balanceOf(owner));
      return ownedTokens[owner][index];
  }

  /// @notice Enumerate valid NFTs
  /// @dev Throws if `index` >= `totalSupply()`.
  /// @param index A counter less than `totalSupply()`
  /// @return The token identifier for the `index`th NFT,
  ///  (sort order not specified)
  function tokenByIndex(uint256 index) external view returns (uint256) {
      require (_tokenExists(index));
      return index;
  }

  /// @notice Enable or disable approval for a third party ("operator") to manage
  ///  all of `msg.sender`&#39;s assets
  /// @dev Emits the ApprovalForAll event. The contract MUST allow
  ///  multiple operators per owner.
  /// @param _operator Address to add to the set of authorized operators
  /// @param _approved True if the operator is approved, false to revoke approval
  function setApprovalForAll(address _operator, bool _approved) external {
        require(_operator != msg.sender);
        operators[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
  }

  /// @notice Get the approved address for a single NFT
  /// @dev Throws if `_tokenId` is not a valid NFT.
  /// @param _tokenId The NFT to find the approved address for
  /// @return The approved address for this NFT, or the zero address if there is none
  function getApproved(uint256 _tokenId) external view returns (address) {
      require(_tokenExists(_tokenId));
      return playerTokenToApproved[_tokenId];
  }

  /// @notice Query if a contract implements an interface
  /// @param interfaceID The interface identifier, as specified in ERC-165
  /// @dev Interface identification is specified in ERC-165. This function
  ///  uses less than 30,000 gas.
  /// @return `true` if the contract implements `interfaceID` and
  ///  `interfaceID` is not 0xffffffff, `false` otherwise
  function supportsInterface(bytes4 interfaceID) public pure returns (bool) {
      return (
          interfaceID == this.supportsInterface.selector || // ERC165
          interfaceID == 0x5b5e139f || // ERC721Metadata
          interfaceID == 0x80ac58cd || // ERC-721
          interfaceID == 0x780e9d63);  // ERC721Enumerable
  }

  // Internal utility functions: These functions all assume that their input arguments
  // are valid. We leave it to public methods to sanitize their inputs and follow
  // the required logic.

  /// @dev Checks if a given address is the current owner of a particular PlayerToken.
  /// @param _claimant the address we are validating against.
  /// @param _tokenId kitten id, only valid when > 0
  function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
      return playerTokenToOwner[_tokenId] == _claimant;
  }

  /// @dev Checks if a given address currently has transferApproval for a particular PlayerToken.
  /// @param _claimant the address we are confirming PlayerToken is approved for.
  /// @param _tokenId PlayerToken id, only valid when > 0
  function _approvedFor(address _claimant, uint256 _tokenId) internal view returns (bool) {
      return playerTokenToApproved[_tokenId] == _claimant;
  }

  /// @dev Marks an address as being approved for transferFrom(), overwriting any previous
  ///  approval. Setting _approved to address(0) clears all transfer approval.
  ///  NOTE: _approve() does NOT send the Approval event. This is intentional because
  ///  _approve() and transferFrom() are used together for putting PlayerToken on auction, and
  ///  there is no value in spamming the log with Approval events in that case.
  function _approve(uint256 _tokenId, address _approved) internal {
      playerTokenToApproved[_tokenId] = _approved;
  }

}

/// @dev Interface to the sale clock auction contract
interface CSportsAuctionInterface {

    /// @dev Sanity check that allows us to ensure that we are pointing to the
    ///  right auction in our setSaleAuctionAddress() call.
    function isSaleClockAuction() external pure returns (bool);

    /// @dev Creates and begins a new auction.
    /// @param _tokenId - ID of token to auction, sender must be owner.
    /// @param _startingPrice - Price of item (in wei) at beginning of auction.
    /// @param _endingPrice - Price of item (in wei) at end of auction.
    /// @param _duration - Length of auction (in seconds).
    /// @param _seller - Seller, if not the message sender
    function createAuction(
        uint256 _tokenId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        address _seller
    ) external;

    /// @dev Reprices (and updates duration) of an array of tokens that are currently
    /// being auctioned by this contract.
    /// @param _tokenIds Array of tokenIds corresponding to auctions being updated
    /// @param _startingPrices New starting prices
    /// @param _endingPrices New ending price
    /// @param _duration New duration
    /// @param _seller Address of the seller in all specified auctions to be updated
    function repriceAuctions(
        uint256[] _tokenIds,
        uint256[] _startingPrices,
        uint256[] _endingPrices,
        uint256 _duration,
        address _seller
    ) external;

    /// @dev Cancels an auction that hasn&#39;t been won yet by calling
    ///   the super(...) and then notifying any listener.
    /// @param _tokenId - ID of token on auction
    function cancelAuction(uint256 _tokenId) external;

    /// @dev Withdraw the total contract balance to the core contract
    function withdrawBalance() external;

}

/// @title Interface to allow a contract to listen to auction events.
contract SaleClockAuctionListener {
    function implementsSaleClockAuctionListener() public pure returns (bool);
    function auctionCreated(uint256 tokenId, address seller, uint128 startingPrice, uint128 endingPrice, uint64 duration) public;
    function auctionSuccessful(uint256 tokenId, uint128 totalPrice, address seller, address buyer) public;
    function auctionCancelled(uint256 tokenId, address seller) public;
}

/// @title The facet of the CSports core contract that manages interfacing with auctions
/// @author CryptoSports, Inc. (http://cryptosports.team)
/// See the CSportsCore contract documentation to understand how the various contract facets are arranged.
contract CSportsAuction is CSportsOwnership, SaleClockAuctionListener {

  // Holds a reference to our saleClockAuctionContract
  CSportsAuctionInterface public saleClockAuctionContract;

  /// @dev SaleClockAuctionLIstener interface method concrete implementation
  function implementsSaleClockAuctionListener() public pure returns (bool) {
    return true;
  }

  /// @dev SaleClockAuctionLIstener interface method concrete implementation
  function auctionCreated(uint256 /* tokenId */, address /* seller */, uint128 /* startingPrice */, uint128 /* endingPrice */, uint64 /* duration */) public {
    require (saleClockAuctionContract != address(0));
    require (msg.sender == address(saleClockAuctionContract));
  }

  /// @dev SaleClockAuctionLIstener interface method concrete implementation
  /// @param tokenId - ID of the token whose auction successfully completed
  /// @param totalPrice - Price at which the auction closed at
  /// @param seller - Account address of the auction seller
  /// @param winner - Account address of the auction winner (buyer)
  function auctionSuccessful(uint256 tokenId, uint128 totalPrice, address seller, address winner) public {
    require (saleClockAuctionContract != address(0));
    require (msg.sender == address(saleClockAuctionContract));

    // Record the most recent sale price to the token
    PlayerToken storage _playerToken = playerTokens[tokenId];
    _playerToken.mostRecentPrice = totalPrice;

    if (seller == address(this)) {
      // We completed a commissioner auction!
      leagueRosterContract.commissionerAuctionComplete(playerTokens[tokenId].realWorldPlayerId, totalPrice);
      emit CommissionerAuctionSuccessful(tokenId, totalPrice, winner);
    }
  }

  /// @dev SaleClockAuctionLIstener interface method concrete implementation
  /// @param tokenId - ID of the token whose auction was cancelled
  /// @param seller - Account address of seller who decided to cancel the auction
  function auctionCancelled(uint256 tokenId, address seller) public {
    require (saleClockAuctionContract != address(0));
    require (msg.sender == address(saleClockAuctionContract));
    if (seller == address(this)) {
      // We cancelled a commissioner auction!
      leagueRosterContract.commissionerAuctionCancelled(playerTokens[tokenId].realWorldPlayerId);
      emit CommissionerAuctionCanceled(tokenId);
    }
  }

  /// @dev Sets the reference to the sale auction.
  /// @param _address - Address of sale contract.
  function setSaleAuctionContractAddress(address _address) public onlyCEO {

      require(_address != address(0));

      CSportsAuctionInterface candidateContract = CSportsAuctionInterface(_address);

      // Sanity check
      require(candidateContract.isSaleClockAuction());

      // Set the new contract address
      saleClockAuctionContract = candidateContract;

  }

  /// @dev Allows the commissioner to cancel his auctions (which are owned
  ///   by this contract)
  function cancelCommissionerAuction(uint32 tokenId) public onlyCommissioner {
    require(saleClockAuctionContract != address(0));
    saleClockAuctionContract.cancelAuction(tokenId);
  }

  /// @dev Put a player up for auction. The message sender must own the
  ///   player token being put up for auction.
  /// @param _playerTokenId - ID of playerToken to be auctioned
  /// @param _startingPrice - Starting price in wei
  /// @param _endingPrice - Ending price in wei
  /// @param _duration - Duration in seconds
  function createSaleAuction(
      uint256 _playerTokenId,
      uint256 _startingPrice,
      uint256 _endingPrice,
      uint256 _duration
  )
      public
      whenNotPaused
  {
      // Auction contract checks input sizes
      // If player is already on any auction, this will throw
      // because it will be owned by the auction contract.
      require(_owns(msg.sender, _playerTokenId));
      _approve(_playerTokenId, saleClockAuctionContract);

      // saleClockAuctionContract.createAuction throws if inputs are invalid and clears
      // transfer after escrowing the player.
      saleClockAuctionContract.createAuction(
          _playerTokenId,
          _startingPrice,
          _endingPrice,
          _duration,
          msg.sender
      );
  }

  /// @dev Transfers the balance of the sale auction contract
  /// to the CSportsCore contract. We use two-step withdrawal to
  /// avoid two transfer calls in the auction bid function.
  /// To withdraw from this CSportsCore contract, the CFO must call
  /// the withdrawBalance(...) function defined in CSportsAuth.
  function withdrawAuctionBalances() external onlyCOO {
      saleClockAuctionContract.withdrawBalance();
  }
}

/// @title The facet of the CSportsCore contract that manages minting new PlayerTokens
/// @author CryptoSports, Inc. (http://cryptosports.team)
/// See the CSportsCore contract documentation to understand how the various contract facets are arranged.
contract CSportsMinting is CSportsAuction {

  /// @dev MarketingTokenRedeemed event is fired when a marketing token has been redeemed
  event MarketingTokenRedeemed(uint256 hash, uint128 rwpMd5, address indexed recipient);

  /// @dev MarketingTokenCreated event is fired when a marketing token has been created
  event MarketingTokenCreated(uint256 hash, uint128 rwpMd5);

  /// @dev MarketingTokenReplaced event is fired when a marketing token has been replaced
  event MarketingTokenReplaced(uint256 oldHash, uint256 newHash, uint128 rwpMd5);

  /// @dev Sanity check that identifies this contract as having minting capability
  function isMinter() public pure returns (bool) {
      return true;
  }

  /// @dev Utility function to make it easy to keccak256 a string in python or javascript using
  /// the exact algorythm used by Solidity.
  function getKeccak256(string stringToHash) public pure returns (uint256) {
      return uint256(keccak256(abi.encodePacked(stringToHash)));
  }

  /// @dev Allows the commissioner to load up our marketingTokens mapping with up to
  /// MAX_MARKETING_TOKENS marketing tokens that can be created if one knows the words
  /// to keccak256 and match the keywordHash passed here. Use web3.utils.soliditySha3(param1 [, param2, ...])
  /// to create this hash.
  ///
  /// ONLY THE COMMISSIONER CAN CREATE MARKETING TOKENS, AND ONLY UP TO MAX_MARKETING_TOKENS OF THEM
  ///
  /// @param keywordHash - keccak256 of a known set of keyWords
  /// @param md5Token - The md5 key in the leagueRosterContract that specifies the player
  /// player token that will be minted and transfered by the redeemMarketingToken(...) method.
  function addMarketingToken(uint256 keywordHash, uint128 md5Token) public onlyCommissioner {

    require(remainingMarketingTokens > 0);
    require(marketingTokens[keywordHash] == 0);

    // Make sure the md5Token exists in the league roster
    uint128 _rosterIndex = leagueRosterContract.getRealWorldPlayerRosterIndex(md5Token);
    require(_rosterIndex != 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

    // Map the keyword Hash to the RWP md5 and decrement the remainingMarketingTokens property
    remainingMarketingTokens--;
    marketingTokens[keywordHash] = md5Token;

    emit MarketingTokenCreated(keywordHash, md5Token);

  }

  /// @dev This method allows the commish to replace an existing marketing token that has
  /// not been used with a new one (new hash and mdt). Since we are replacing, we co not
  /// have to deal with remainingMarketingTokens in any way. This is to allow for replacing
  /// marketing tokens that have not been redeemed and aren&#39;t likely to be redeemed (breakage)
  ///
  /// ONLY THE COMMISSIONER CAN ACCESS THIS METHOD
  ///
  /// @param oldKeywordHash Hash to replace
  /// @param newKeywordHash Hash to replace with
  /// @param md5Token The md5 key in the leagueRosterContract that specifies the player
  function replaceMarketingToken(uint256 oldKeywordHash, uint256 newKeywordHash, uint128 md5Token) public onlyCommissioner {

    uint128 _md5Token = marketingTokens[oldKeywordHash];
    if (_md5Token != 0) {
      marketingTokens[oldKeywordHash] = 0;
      marketingTokens[newKeywordHash] = md5Token;
      emit MarketingTokenReplaced(oldKeywordHash, newKeywordHash, md5Token);
    }

  }

  /// @dev Returns the real world player&#39;s MD5 key from a keywords string. A 0x00 returned
  /// value means the keyword string parameter isn&#39;t mapped to a marketing token.
  /// @param keyWords Keywords to use to look up RWP MD5
  //
  /// ANYONE CAN VALIDATE A KEYWORD STRING (MAP IT TO AN MD5 IF IT HAS ONE)
  ///
  /// @param keyWords - A string that will keccak256 to an entry in the marketingTokens
  /// mapping (or not)
  function MD5FromMarketingKeywords(string keyWords) public view returns (uint128) {
    uint256 keyWordsHash = uint256(keccak256(abi.encodePacked(keyWords)));
    uint128 _md5Token = marketingTokens[keyWordsHash];
    return _md5Token;
  }

  /// @dev Allows anyone to try to redeem a marketing token by passing N words that will
  /// be SHA256&#39;ed to match an entry in our marketingTokens mapping. If a match is found,
  /// a CryptoSports token is created that corresponds to the md5 retrieved
  /// from the marketingTokens mapping and its owner is assigned as the msg.sender.
  ///
  /// ANYONE CAN REDEEM A MARKETING token
  ///
  /// @param keyWords - A string that will keccak256 to an entry in the marketingTokens mapping
  function redeemMarketingToken(string keyWords) public {

    uint256 keyWordsHash = uint256(keccak256(abi.encodePacked(keyWords)));
    uint128 _md5Token = marketingTokens[keyWordsHash];
    if (_md5Token != 0) {

      // Only one redemption per set of keywords
      marketingTokens[keyWordsHash] = 0;

      uint128 _rosterIndex = leagueRosterContract.getRealWorldPlayerRosterIndex(_md5Token);
      if (_rosterIndex != 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF) {

        // Grab the real world player record from the leagueRosterContract
        RealWorldPlayer memory _rwp;
        (_rwp.md5Token, _rwp.prevCommissionerSalePrice, _rwp.lastMintedTime, _rwp.mintedCount, _rwp.hasActiveCommissionerAuction, _rwp.mintingEnabled) =  leagueRosterContract.realWorldPlayerFromIndex(_rosterIndex);

        // Mint this player, sending it to the message sender
        _mintPlayer(uint32(_rosterIndex), _rwp.mintedCount, msg.sender);

        // Finally, update our realWorldPlayer record to reflect the fact that we just
        // minted a new one, and there is an active commish auction. The only portion of
        // the RWP record we change here is an update to the mingedCount.
        leagueRosterContract.updateRealWorldPlayer(uint32(_rosterIndex), _rwp.prevCommissionerSalePrice, uint64(now), _rwp.mintedCount + 1, _rwp.hasActiveCommissionerAuction, _rwp.mintingEnabled);

        emit MarketingTokenRedeemed(keyWordsHash, _rwp.md5Token, msg.sender);
      }

    }
  }

  /// @dev Returns an array of minimum auction starting prices for an array of players
  /// specified by their MD5s.
  /// @param _md5Tokens MD5s in the league roster for the players we are inquiring about.
  function minStartPriceForCommishAuctions(uint128[] _md5Tokens) public view onlyCommissioner returns (uint128[50]) {
    require (_md5Tokens.length <= 50);
    uint128[50] memory minPricesArray;
    for (uint32 i = 0; i < _md5Tokens.length; i++) {
        uint128 _md5Token = _md5Tokens[i];
        uint128 _rosterIndex = leagueRosterContract.getRealWorldPlayerRosterIndex(_md5Token);
        if (_rosterIndex == 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF) {
          // Cannot mint a non-existent real world player
          continue;
        }
        RealWorldPlayer memory _rwp;
        (_rwp.md5Token, _rwp.prevCommissionerSalePrice, _rwp.lastMintedTime, _rwp.mintedCount, _rwp.hasActiveCommissionerAuction, _rwp.mintingEnabled) =  leagueRosterContract.realWorldPlayerFromIndex(_rosterIndex);

        // Skip this if there is no player associated with the md5 specified
        if (_rwp.md5Token != _md5Token) continue;

        minPricesArray[i] = uint128(_computeNextCommissionerPrice(_rwp.prevCommissionerSalePrice));
    }
    return minPricesArray;
  }

  /// @dev Creates newly minted playerTokens and puts them up for auction. This method
  ///   can only be called by the commissioner, and checks to make sure certian minting
  ///   conditions are met (reverting if not met):
  ///     * The MD5 of the RWP specified must exist in the CSportsLeagueRoster contract
  ///     * Cannot mint a realWorldPlayer that currently has an active commissioner auction
  ///     * Cannot mint realWorldPlayer that does not have minting enabled
  ///     * Cannot mint realWorldPlayer with a start price exceeding our minimum
  ///   If any of the above conditions fails to be met, then no player tokens will be
  ///   minted.
  ///
  /// *** ONLY THE COMMISSIONER OR THE LEAGUE ROSTER CONTRACT CAN CALL THIS FUNCTION ***
  ///
  /// @param _md5Tokens - array of md5Tokens representing realWorldPlayer that we are minting.
  /// @param _startPrice - the starting price for the auction (0 will set to current minimum price)
  function mintPlayers(uint128[] _md5Tokens, uint256 _startPrice, uint256 _endPrice, uint256 _duration) public {

    require(leagueRosterContract != address(0));
    require(saleClockAuctionContract != address(0));
    require((msg.sender == commissionerAddress) || (msg.sender == address(leagueRosterContract)));

    for (uint32 i = 0; i < _md5Tokens.length; i++) {
      uint128 _md5Token = _md5Tokens[i];
      uint128 _rosterIndex = leagueRosterContract.getRealWorldPlayerRosterIndex(_md5Token);
      if (_rosterIndex == 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF) {
        // Cannot mint a non-existent real world player
        continue;
      }

      // We don&#39;t have to check _rosterIndex here because the getRealWorldPlayerRosterIndex(...)
      // method always returns a valid index.
      RealWorldPlayer memory _rwp;
      (_rwp.md5Token, _rwp.prevCommissionerSalePrice, _rwp.lastMintedTime, _rwp.mintedCount, _rwp.hasActiveCommissionerAuction, _rwp.mintingEnabled) =  leagueRosterContract.realWorldPlayerFromIndex(_rosterIndex);

      if (_rwp.md5Token != _md5Token) continue;
      if (!_rwp.mintingEnabled) continue;

      // Enforce the restrictions that there can ever only be a single outstanding commissioner
      // auction - no new minting if there is an active commissioner auction for this real world player
      if (_rwp.hasActiveCommissionerAuction) continue;

      // Ensure that our price is not less than a minimum
      uint256 _minStartPrice = _computeNextCommissionerPrice(_rwp.prevCommissionerSalePrice);

      // Make sure the start price exceeds our minimum acceptable
      if (_startPrice < _minStartPrice) {
          _startPrice = _minStartPrice;
      }

      // Mint the new player token
      uint32 _playerId = _mintPlayer(uint32(_rosterIndex), _rwp.mintedCount, address(this));

      // @dev Approve ownership transfer to the saleClockAuctionContract (which is required by
      //  the createAuction(...) which will escrow the playerToken)
      _approve(_playerId, saleClockAuctionContract);

      // Apply the default duration
      if (_duration == 0) {
        _duration = COMMISSIONER_AUCTION_DURATION;
      }

      // By setting our _endPrice to zero, we become immune to the USD <==> ether
      // conversion rate. No matter how high ether goes, our auction price will get
      // to a USD value that is acceptable to someone (assuming 0 is acceptable that is).
      // This also helps for players that aren&#39;t in very much demand.
      saleClockAuctionContract.createAuction(
          _playerId,
          _startPrice,
          _endPrice,
          _duration,
          address(this)
      );

      // Finally, update our realWorldPlayer record to reflect the fact that we just
      // minted a new one, and there is an active commish auction.
      leagueRosterContract.updateRealWorldPlayer(uint32(_rosterIndex), _rwp.prevCommissionerSalePrice, uint64(now), _rwp.mintedCount + 1, true, _rwp.mintingEnabled);
    }
  }

  /// @dev Reprices (and updates duration) of an array of tokens that are currently
  /// being auctioned by this contract. Since this function can only be called by
  /// the commissioner, we don&#39;t do a lot of checking of parameters and things.
  /// The SaleClockAuction&#39;s repriceAuctions method assures that the CSportsCore
  /// contract is the "seller" of the token (meaning it is a commissioner auction).
  /// @param _tokenIds Array of tokenIds corresponding to auctions being updated
  /// @param _startingPrices New starting prices for each token being repriced
  /// @param _endingPrices New ending price
  /// @param _duration New duration
  function repriceAuctions(
      uint256[] _tokenIds,
      uint256[] _startingPrices,
      uint256[] _endingPrices,
      uint256 _duration
  ) external onlyCommissioner {

      // We cannot reprice below our player minimum
      for (uint32 i = 0; i < _tokenIds.length; i++) {
          uint32 _tokenId = uint32(_tokenIds[i]);
          PlayerToken memory pt = playerTokens[_tokenId];
          RealWorldPlayer memory _rwp;
          (_rwp.md5Token, _rwp.prevCommissionerSalePrice, _rwp.lastMintedTime, _rwp.mintedCount, _rwp.hasActiveCommissionerAuction, _rwp.mintingEnabled) = leagueRosterContract.realWorldPlayerFromIndex(pt.realWorldPlayerId);
          uint256 _minStartPrice = _computeNextCommissionerPrice(_rwp.prevCommissionerSalePrice);

          // We require the price to be >= our _minStartPrice
          require(_startingPrices[i] >= _minStartPrice);
      }

      // Note we pass in this CSportsCore contract address as the seller, making sure the only auctions
      // that can be repriced by this method are commissioner auctions.
      saleClockAuctionContract.repriceAuctions(_tokenIds, _startingPrices, _endingPrices, _duration, address(this));
  }

  /// @dev Allows the commissioner to create a sale auction for a token
  ///   that is owned by the core contract. Can only be called when not paused
  ///   and only by the commissioner
  /// @param _playerTokenId - ID of the player token currently owned by the core contract
  /// @param _startingPrice - Starting price for the auction
  /// @param _endingPrice - Ending price for the auction
  /// @param _duration - Duration of the auction (in seconds)
  function createCommissionerAuction(uint32 _playerTokenId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration)
        public whenNotPaused onlyCommissioner {

        require(leagueRosterContract != address(0));
        require(_playerTokenId < playerTokens.length);

        // If player is already on any auction, this will throw because it will not be owned by
        // this CSportsCore contract (as all commissioner tokens are if they are not currently
        // on auction).
        // Any token owned by the CSportsCore contract by definition is a commissioner auction
        // that was canceled which makes it OK to re-list.
        require(_owns(address(this), _playerTokenId));

        // (1) Grab the real world token ID (md5)
        PlayerToken memory pt = playerTokens[_playerTokenId];

        // (2) Get the full real world player record from its roster index
        RealWorldPlayer memory _rwp;
        (_rwp.md5Token, _rwp.prevCommissionerSalePrice, _rwp.lastMintedTime, _rwp.mintedCount, _rwp.hasActiveCommissionerAuction, _rwp.mintingEnabled) = leagueRosterContract.realWorldPlayerFromIndex(pt.realWorldPlayerId);

        // Ensure that our starting price is not less than a minimum
        uint256 _minStartPrice = _computeNextCommissionerPrice(_rwp.prevCommissionerSalePrice);
        if (_startingPrice < _minStartPrice) {
            _startingPrice = _minStartPrice;
        }

        // Apply the default duration
        if (_duration == 0) {
            _duration = COMMISSIONER_AUCTION_DURATION;
        }

        // Approve the token for transfer
        _approve(_playerTokenId, saleClockAuctionContract);

        // saleClockAuctionContract.createAuction throws if inputs are invalid and clears
        // transfer after escrowing the player.
        saleClockAuctionContract.createAuction(
            _playerTokenId,
            _startingPrice,
            _endingPrice,
            _duration,
            address(this)
        );
  }

  /// @dev Computes the next commissioner auction starting price equal to
  ///  the previous real world player sale price + 25% (with a floor).
  function _computeNextCommissionerPrice(uint128 prevTwoCommissionerSalePriceAve) internal view returns (uint256) {

      uint256 nextPrice = prevTwoCommissionerSalePriceAve + (prevTwoCommissionerSalePriceAve / 4);

      // sanity check to ensure we don&#39;t overflow arithmetic (this big number is 2^128-1).
      if (nextPrice > 340282366920938463463374607431768211455) {
        nextPrice = 340282366920938463463374607431768211455;
      }

      // We never auction for less than our floor
      if (nextPrice < COMMISSIONER_AUCTION_FLOOR_PRICE) {
          nextPrice = COMMISSIONER_AUCTION_FLOOR_PRICE;
      }

      return nextPrice;
  }

}

/// @notice This is the main contract that implements the csports ERC721 token.
/// @author CryptoSports, Inc. (http://cryptosports.team)
/// @dev This contract is made up of a series of parent classes so that we could
/// break the code down into meaningful amounts of related functions in
/// single files, as opposed to having one big file. The purpose of
/// each facet is given here:
///
///   CSportsConstants - This facet holds constants used throughout.
///   CSportsAuth -
///   CSportsBase -
///   CSportsOwnership -
///   CSportsAuction -
///   CSportsMinting -
///   CSportsCore - This is the main CSports constract implementing the CSports
///         Fantash Football League. It manages contract upgrades (if / when
///         they might occur), and has generally useful helper methods.
///
/// This CSportsCore contract interacts with the CSportsLeagueRoster contract
/// to determine which PlayerTokens to mint.
///
/// This CSportsCore contract interacts with the TimeAuction contract
/// to implement and run PlayerToken auctions (sales).
contract CSportsCore is CSportsMinting {

  /// @dev Used by other contracts as a sanity check
  bool public isCoreContract = true;

  // Set if (hopefully not) the core contract needs to be upgraded. Can be
  // set by the CEO but only when paused. When successfully set, we can never
  // unpause this contract. See the unpause() method overridden by this class.
  address public newContractAddress;

  /// @notice Class constructor creates the main CSportsCore smart contract instance.
  /// @param nftName The ERC721 name for the contract
  /// @param nftSymbol The ERC721 symbol for the contract
  /// @param nftTokenURI The ERC721 token uri for the contract
  constructor(string nftName, string nftSymbol, string nftTokenURI) public {

      // New contract starts paused.
      paused = true;

      /// @notice storage for the fields that identify this 721 token
      _name = nftName;
      _symbol = nftSymbol;
      _tokenURI = nftTokenURI;

      // All C-level roles are the message sender
      ceoAddress = msg.sender;
      cfoAddress = msg.sender;
      cooAddress = msg.sender;
      commissionerAddress = msg.sender;

  }

  /// @dev Reject all Ether except if it&#39;s from one of our approved sources
  function() external payable {
    /*require(
        msg.sender == address(saleClockAuctionContract)
    );*/
  }

  /// --------------------------------------------------------------------------- ///
  /// ----------------------------- PUBLIC FUNCTIONS ---------------------------- ///
  /// --------------------------------------------------------------------------- ///

  /// @dev Used to mark the smart contract as upgraded, in case there is a serious
  ///  bug. This method does nothing but keep track of the new contract and
  ///  emit a message indicating that the new address is set. It&#39;s up to clients of this
  ///  contract to update to the new contract address in that case. (This contract will
  ///  be paused indefinitely if such an upgrade takes place.)
  /// @param _v2Address new address
  function upgradeContract(address _v2Address) public onlyCEO whenPaused {
      newContractAddress = _v2Address;
      emit ContractUpgrade(_v2Address);
  }

  /// @dev Override unpause so it requires all external contract addresses
  ///  to be set before contract can be unpaused. Also require that we have
  ///  set a valid season and the contract has not been upgraded.
  function unpause() public onlyCEO whenPaused {
      require(leagueRosterContract != address(0));
      require(saleClockAuctionContract != address(0));
      require(newContractAddress == address(0));

      // Actually unpause the contract.
      super.unpause();
  }

  /// @dev Consolidates setting of contract links into a single call for deployment expediency
  function setLeagueRosterAndSaleAndTeamContractAddress(address _leagueAddress, address _saleAddress, address _teamAddress) public onlyCEO {
      setLeagueRosterContractAddress(_leagueAddress);
      setSaleAuctionContractAddress(_saleAddress);
      setTeamContractAddress(_teamAddress);
  }

  /// @dev Returns all the relevant information about a specific playerToken.
  ///@param _playerTokenID - player token ID we are seeking the full player token info for
  function getPlayerToken(uint32 _playerTokenID) public view returns (
      uint32 realWorldPlayerId,
      uint32 serialNumber,
      uint64 mintedTime,
      uint128 mostRecentPrice) {
    require(_playerTokenID < playerTokens.length);
    PlayerToken storage pt = playerTokens[_playerTokenID];
    realWorldPlayerId = pt.realWorldPlayerId;
    serialNumber = pt.serialNumber;
    mostRecentPrice = pt.mostRecentPrice;
    mintedTime = pt.mintedTime;
  }

  /// @dev Returns the realWorldPlayer MD5 ID for a given playerTokenID
  /// @param _playerTokenID - player token ID we are seeking the associated realWorldPlayer md5 for
  function realWorldPlayerTokenForPlayerTokenId(uint32 _playerTokenID) public view returns (uint128 md5Token) {
      require(_playerTokenID < playerTokens.length);
      PlayerToken storage pt = playerTokens[_playerTokenID];
      RealWorldPlayer memory _rwp;
      (_rwp.md5Token, _rwp.prevCommissionerSalePrice, _rwp.lastMintedTime, _rwp.mintedCount, _rwp.hasActiveCommissionerAuction, _rwp.mintingEnabled) = leagueRosterContract.realWorldPlayerFromIndex(pt.realWorldPlayerId);
      md5Token = _rwp.md5Token;
  }

  /// @dev Returns the realWorldPlayer Metadata for a given playerTokenID
  /// @param _playerTokenID - player token ID we are seeking the associated realWorldPlayer md5 for
  function realWorldPlayerMetadataForPlayerTokenId(uint32 _playerTokenID) public view returns (string metadata) {
      require(_playerTokenID < playerTokens.length);
      PlayerToken storage pt = playerTokens[_playerTokenID];
      RealWorldPlayer memory _rwp;
      (_rwp.md5Token, _rwp.prevCommissionerSalePrice, _rwp.lastMintedTime, _rwp.mintedCount, _rwp.hasActiveCommissionerAuction, _rwp.mintingEnabled) = leagueRosterContract.realWorldPlayerFromIndex(pt.realWorldPlayerId);
      metadata = leagueRosterContract.getMetadata(_rwp.md5Token);
  }

  /// --------------------------------------------------------------------------- ///
  /// ------------------------- RESTRICTED FUNCTIONS ---------------------------- ///
  /// --------------------------------------------------------------------------- ///

  /// @dev Updates a particular realRealWorldPlayer. Note that the md5Token is immutable. Can only be
  ///   called by the CEO and is used in development stage only as it is only needed by our test suite.
  /// @param _rosterIndex - Index into realWorldPlayers of the entry to change.
  /// @param _prevCommissionerSalePrice - Average of the 2 most recent sale prices in commissioner auctions
  /// @param _lastMintedTime - Time this real world player was last minted
  /// @param _mintedCount - The number of playerTokens that have been minted for this player
  /// @param _hasActiveCommissionerAuction - Whether or not there is an active commissioner auction for this player
  /// @param _mintingEnabled - Denotes whether or not we should mint new playerTokens for this real world player
  function updateRealWorldPlayer(uint32 _rosterIndex, uint128 _prevCommissionerSalePrice, uint64 _lastMintedTime, uint32 _mintedCount, bool _hasActiveCommissionerAuction, bool _mintingEnabled) public onlyCEO onlyUnderDevelopment {
    require(leagueRosterContract != address(0));
    leagueRosterContract.updateRealWorldPlayer(_rosterIndex, _prevCommissionerSalePrice, _lastMintedTime, _mintedCount, _hasActiveCommissionerAuction, _mintingEnabled);
  }

}