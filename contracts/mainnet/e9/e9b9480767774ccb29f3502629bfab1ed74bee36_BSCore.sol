pragma solidity ^0.4.19;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
   @title ERC827 interface, an extension of ERC20 token standard

   Interface of a ERC827 token, following the ERC20 standard with extra
   methods to transfer value and data and execute calls in transfers and
   approvals.
 */
contract ERC827 is ERC20 {

  function approve( address _spender, uint256 _value, bytes _data ) public returns (bool);
  function transfer( address _to, uint256 _value, bytes _data ) public returns (bool);
  function transferFrom( address _from, address _to, uint256 _value, bytes _data ) public returns (bool);

}

contract AccessControl {
    address public ceoAddress;
    address public cfoAddress;
    address public cooAddress;

    // @dev Keeps track whether the contract is paused. When that is true, most actions are blocked
    bool public paused = false;

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

    modifier onlyCLevel() {
        require(
            msg.sender == cooAddress || 
            msg.sender == ceoAddress || 
            msg.sender == cfoAddress
        );
        _;
    }

    /// @dev Assigns a new address to act as the CEO. Only available to the current CEO.
    /// @param _newCEO The address of the new CEO
    function setCEO(address _newCEO) external onlyCEO {
        require(_newCEO != address(0));

        ceoAddress = _newCEO;
    }

    /// @dev Assigns a new address to act as the CFO. Only available to the current CEO.
    /// @param _newCFO The address of the new CFO
    function setCFO(address _newCFO) external onlyCEO {
        require(_newCFO != address(0));

        cfoAddress = _newCFO;
    }

    /// @dev Assigns a new address to act as the COO. Only available to the current CEO.
    /// @param _newCOO The address of the new COO
    function setCOO(address _newCOO) external onlyCEO {
        require(_newCOO != address(0));

        cooAddress = _newCOO;
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
    function pause() external onlyCLevel whenNotPaused {
        paused = true;
    }

    /// @dev Unpauses the smart contract. Can only be called by the CEO, since
    ///  one reason we may pause the contract is when CFO or COO accounts are
    ///  compromised.
    /// @notice This is public rather than external so it can be called by
    ///  derived contracts.
    function unpause() public onlyCEO whenPaused {
        paused = false;
    }
}

/// @title 
contract TournamentInterface {
    /// @dev simply a boolean to indicate this is the contract we expect to be
    function isTournament() public pure returns (bool);
    function isPlayerIdle(address _owner, uint256 _playerId) public view returns (bool);
}

/// @title Base contract for BS. Holds all common structs, events and base variables.
contract BSBase is AccessControl {
    /*** EVENTS ***/

    /// @dev The Birth event is fired whenever a new player comes into existence. 
    event Birth(address owner, uint32 playerId, uint16 typeId, uint8 attack, uint8 defense, uint8 stamina, uint8 xp, uint8 isKeeper, uint16 skillId);

    /// @dev Transfer event as defined in current draft of ERC721. Emitted every time a player
    ///  ownership is assigned, including births.
    event Transfer(address from, address to, uint256 tokenId);

    struct Player {
        uint16 typeId;
        uint8 attack;
        uint8 defense;
        uint8 stamina;
        uint8 xp;
        uint8 isKeeper;
        uint16 skillId;
        uint8 isSkillOn;
    }

    Player[] players;
    uint256 constant commonPlayerCount = 10;
    uint256 constant totalPlayerSupplyLimit = 80000000;
    mapping (uint256 => address) public playerIndexToOwner;
    mapping (address => uint256) ownershipTokenCount;
    mapping (uint256 => address) public playerIndexToApproved;
    /// SaleClockAuction public saleAuction;
    ERC827 public joyTokenContract;
    TournamentInterface public tournamentContract;

    /// @dev Assigns ownership of a specific Player to an address.
    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        // since the number of players is capped to 2^32
        // there is no way to overflow this
        ownershipTokenCount[_to]++;
        // transfer ownership
        playerIndexToOwner[_tokenId] = _to;
        // When creating new player _from is 0x0, but we can&#39;t account that address.
        if (_from != address(0)) {
            ownershipTokenCount[_from]--;
            // clear any previously approved ownership exchange
            delete playerIndexToApproved[_tokenId];
        }
        // Emit the transfer event.
        Transfer(_from, _to, _tokenId);
    }

    function _createPlayer(
        address _owner,
        uint256 _typeId,
        uint256 _attack,
        uint256 _defense,
        uint256 _stamina,
        uint256 _xp,
        uint256 _isKeeper,
        uint256 _skillId
    )
        internal
        returns (uint256)
    {
        Player memory _player = Player({
            typeId: uint16(_typeId), 
            attack: uint8(_attack), 
            defense: uint8(_defense), 
            stamina: uint8(_stamina),
            xp: uint8(_xp),
            isKeeper: uint8(_isKeeper),
            skillId: uint16(_skillId),
            isSkillOn: 0
        });
        uint256 newPlayerId = players.push(_player) - 1;

        require(newPlayerId <= totalPlayerSupplyLimit);

        // emit the birth event
        Birth(
            _owner,
            uint32(newPlayerId),
            _player.typeId,
            _player.attack,
            _player.defense,
            _player.stamina,
            _player.xp,
            _player.isKeeper,
            _player.skillId
        );

        // This will assign ownership, and also emit the Transfer event as
        // per ERC721 draft
        _transfer(0, _owner, newPlayerId);

        return newPlayerId;
    }
}

/// @title Interface for contracts conforming to ERC-721: Non-Fungible Tokens
/// @author Dieter Shirley <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="7b1f1e0f1e3b1a03121416011e15551814">[email&#160;protected]</a>> (https://github.com/dete)
contract ERC721 {
    // Required methods
    function totalSupply() public view returns (uint256 total);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) public view returns (address owner);
    function approve(address _to, uint256 _tokenId) public;
    function transfer(address _to, uint256 _tokenId) public;
    function transferFrom(address _from, address _to, uint256 _tokenId) public;

    // Events
    event Transfer(address from, address to, uint256 tokenId);
    event Approval(address owner, address approved, uint256 tokenId);

    // Optional
    // function name() public view returns (string name);
    // function symbol() public view returns (string symbol);
    // function tokensOfOwner(address _owner) external view returns (uint256[] tokenIds);
    // function tokenMetadata(uint256 _tokenId, string _preferredTransport) public view returns (string infoUrl);

    // ERC-165 Compatibility (https://github.com/ethereum/EIPs/issues/165)
    function supportsInterface(bytes4 _interfaceID) public view returns (bool);
}

/// @title The facet of the BS core contract that manages ownership, ERC-721 (draft) compliant.
contract BSOwnership is BSBase, ERC721 {

    /// @notice Name and symbol of the non fungible token, as defined in ERC721.
    string public constant name = "BitSoccer Player";
    string public constant symbol = "BSP";

    bytes4 constant InterfaceSignature_ERC165 =
        bytes4(keccak256("supportsInterface(bytes4)"));

    bytes4 constant InterfaceSignature_ERC721 =
        bytes4(keccak256("name()")) ^
        bytes4(keccak256("symbol()")) ^
        bytes4(keccak256("totalSupply()")) ^
        bytes4(keccak256("balanceOf(address)")) ^
        bytes4(keccak256("ownerOf(uint256)")) ^
        bytes4(keccak256("approve(address,uint256)")) ^
        bytes4(keccak256("transfer(address,uint256)")) ^
        bytes4(keccak256("transferFrom(address,address,uint256)")) ^
        bytes4(keccak256("tokensOfOwner(address)"));

    /// @notice Introspection interface as per ERC-165 (https://github.com/ethereum/EIPs/issues/165).
    ///  Returns true for any standardized interfaces implemented by this contract. We implement
    ///  ERC-165 (obviously!) and ERC-721.
    function supportsInterface(bytes4 _interfaceID) public view returns (bool)
    {
        // DEBUG ONLY
        //require((InterfaceSignature_ERC165 == 0x01ffc9a7) && (InterfaceSignature_ERC721 == 0x9f40b779));

        return ((_interfaceID == InterfaceSignature_ERC165) || (_interfaceID == InterfaceSignature_ERC721));
    }

    // Internal utility functions: These functions all assume that their input arguments
    // are valid. We leave it to public methods to sanitize their inputs and follow
    // the required logic.

    /// @dev Checks if a given address is the current owner of a particular Player.
    /// @param _claimant the address we are validating against.
    /// @param _tokenId player id, only valid when > 0
    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return playerIndexToOwner[_tokenId] == _claimant;
    }

    function _isIdle(address _owner, uint256 _tokenId) internal view returns (bool) {
        return (tournamentContract == address(0) || tournamentContract.isPlayerIdle(_owner, _tokenId));
    }

    /// @dev Checks if a given address currently has transferApproval for a particular Player.
    /// @param _claimant the address we are confirming player is approved for.
    /// @param _tokenId player id, only valid when > 0
    function _approvedFor(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return playerIndexToApproved[_tokenId] == _claimant;
    }

    /// @dev Marks an address as being approved for transferFrom(), overwriting any previous
    ///  approval. Setting _approved to address(0) clears all transfer approval.
    ///  NOTE: _approve() does NOT send the Approval event. This is intentional because
    ///  _approve() and transferFrom() are used together for putting players on auction, and
    ///  there is no value in spamming the log with Approval events in that case.
    function _approve(uint256 _tokenId, address _approved) internal {
        playerIndexToApproved[_tokenId] = _approved;
    }

    /// @notice Returns the number of players owned by a specific address.
    /// @param _owner The owner address to check.
    /// @dev Required for ERC-721 compliance
    function balanceOf(address _owner) public view returns (uint256 count) {
        return ownershipTokenCount[_owner];
    }

    /// @notice Transfers a Player to another address. If transferring to a smart
    ///  contract be VERY CAREFUL to ensure that it is aware of ERC-721 (or
    ///  BSPlayers specifically) or your Player may be lost forever. Seriously.
    /// @param _to The address of the recipient, can be a user or contract.
    /// @param _tokenId The ID of the player to transfer.
    /// @dev Required for ERC-721 compliance.
    function transfer(
        address _to,
        uint256 _tokenId
    )
        public
        whenNotPaused
    {
        // Safety check to prevent against an unexpected 0x0 default.
        require(_to != address(0));
        // Disallow transfers to this contract to prevent accidental misuse.
        require(_to != address(this));

        // Disallow transfers to the auction contracts to prevent accidental
        // misuse. Auction contracts should only take ownership of players
        // through the allow + transferFrom flow.
        // require(_to != address(saleAuction));

        // You can only send your own player.
        require(_owns(msg.sender, _tokenId));
        require(_isIdle(msg.sender, _tokenId));

        // Reassign ownership, clear pending approvals, emit Transfer event.
        _transfer(msg.sender, _to, _tokenId);
    }

    /// @notice Grant another address the right to transfer a specific Player via
    ///  transferFrom(). This is the preferred flow for transfering NFTs to contracts.
    /// @param _to The address to be granted transfer approval. Pass address(0) to
    ///  clear all approvals.
    /// @param _tokenId The ID of the Player that can be transferred if this call succeeds.
    /// @dev Required for ERC-721 compliance.
    function approve(
        address _to,
        uint256 _tokenId
    )
        public
        whenNotPaused
    {
        // Only an owner can grant transfer approval.
        require(_owns(msg.sender, _tokenId));
        require(_isIdle(msg.sender, _tokenId));

        // Register the approval (replacing any previous approval).
        _approve(_tokenId, _to);

        // Emit approval event.
        Approval(msg.sender, _to, _tokenId);
    }

    /// @notice Transfer a Player owned by another address, for which the calling address
    ///  has previously been granted transfer approval by the owner.
    /// @param _from The address that owns the Player to be transfered.
    /// @param _to The address that should take ownership of the Player. Can be any address,
    ///  including the caller.
    /// @param _tokenId The ID of the player to be transferred.
    /// @dev Required for ERC-721 compliance.
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    )
        public
        whenNotPaused
    {
        // Safety check to prevent against an unexpected 0x0 default.
        require(_to != address(0));
        // Disallow transfers to this contract to prevent accidental misuse.
        require(_to != address(this));
        // Check for approval and valid ownership
        require(_approvedFor(msg.sender, _tokenId));
        require(_owns(_from, _tokenId));
        require(_isIdle(_from, _tokenId));

        // Reassign ownership (also clears pending approvals and emits Transfer event).
        _transfer(_from, _to, _tokenId);
    }

    /// @notice Returns the total number of Players currently in existence.
    /// @dev Required for ERC-721 compliance.
    function totalSupply() public view returns (uint) {
        return players.length;
    }

    /// @notice Returns the address currently assigned ownership of a given Player.
    /// @dev Required for ERC-721 compliance.
    function ownerOf(uint256 _tokenId)
        public
        view
        returns (address owner)
    {
        owner = playerIndexToOwner[_tokenId];

        require(owner != address(0));
    }

    /// @notice Returns a list of all Player IDs assigned to an address.
    /// @param _owner The owner whose Players we are interested in.
    /// @dev This method MUST NEVER be called by smart contract code. First, it&#39;s fairly
    ///  expensive (it walks the entire Player array looking for players belonging to owner),
    ///  but it also returns a dynamic array, which is only supported for web3 calls, and
    ///  not contract-to-contract calls.
    function tokensOfOwner(address _owner) external view returns(uint256[] ownerTokens) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory result = new uint256[](tokenCount+commonPlayerCount);
        uint256 resultIndex = 0;

        uint256 playerId;
        for (playerId = 1; playerId <= commonPlayerCount; playerId++) {
            result[resultIndex] = playerId;
            resultIndex++;
        }

        if (tokenCount == 0) {
            return result;
        } else {
            uint256 totalPlayers = totalSupply();

            for (; playerId < totalPlayers; playerId++) {
                if (playerIndexToOwner[playerId] == _owner) {
                    result[resultIndex] = playerId;
                    resultIndex++;
                }
            }

            return result;
        }
    }
}

/// @title 
interface RandomPlayerInterface {
    /// @dev simply a boolean to indicate this is the contract we expect to be
    function isRandomPlayer() public pure returns (bool);

    /// @return a random player
    function gen() public returns (uint256 typeId, uint256 attack, uint256 defense, uint256 stamina, uint256 xp, uint256 isKeeper, uint256 skillId);
}

contract BSMinting is BSOwnership {
        /// @dev The address of the sibling contract that is used to generate player
    ///  genetic combination algorithm.
    using SafeMath for uint256;
    RandomPlayerInterface public randomPlayer;

    uint256 constant public exchangePlayerTokenCount = 100 * (10**18);

    uint256 constant promoCreationPlayerLimit = 50000;

    uint256 public promoCreationPlayerCount;

    uint256 public promoEndTime;
    mapping (address => uint256) public userToken2PlayerCount;

    event ExchangePlayer(address indexed user, uint256 count);

    function BSMinting() public {
        promoEndTime = now + 2 weeks;
    }

    function setPromoEndTime(uint256 _endTime) external onlyCOO {
        promoEndTime = _endTime;
    }

    /// @dev Update the address of the generator contract, can only be called by the CEO.
    /// @param _address An address of a contract instance to be used from this point forward.
    function setRandomPlayerAddress(address _address) external onlyCEO {
        RandomPlayerInterface candidateContract = RandomPlayerInterface(_address);

        // NOTE: verify that a contract is what we expect - https://github.com/Lunyr/crowdsale-contracts/blob/cfadd15986c30521d8ba7d5b6f57b4fefcc7ac38/contracts/LunyrToken.sol#L117
        require(candidateContract.isRandomPlayer());

        // Set the new contract address
        randomPlayer = candidateContract;
    }

    function createPromoPlayer(address _owner, uint256 _typeId, uint256 _attack, uint256 _defense,
            uint256 _stamina, uint256 _xp, uint256 _isKeeper, uint256 _skillId) external onlyCOO {
        address sender = _owner;
        if (sender == address(0)) {
             sender = cooAddress;
        }

        require(promoCreationPlayerCount < promoCreationPlayerLimit);
        promoCreationPlayerCount++;
        _createPlayer(sender, _typeId, _attack, _defense, _stamina, _xp, _isKeeper, _skillId);
    }

    function token2Player(address _sender, uint256 _count) public whenNotPaused returns (bool) {
        require(msg.sender == address(joyTokenContract) || msg.sender == _sender);
        require(_count > 0);
        uint256 totalTokenCount = _count.mul(exchangePlayerTokenCount);
        require(joyTokenContract.transferFrom(_sender, cfoAddress, totalTokenCount));

        uint256 typeId;
        uint256 attack;
        uint256 defense;
        uint256 stamina;
        uint256 xp;
        uint256 isKeeper;
        uint256 skillId;
        for (uint256 i = 0; i < _count; i++) {
            (typeId, attack, defense, stamina, xp, isKeeper, skillId) = randomPlayer.gen();
            _createPlayer(_sender, typeId, attack, defense, stamina, xp, isKeeper, skillId);
        }

        if (now < promoEndTime) {
            _onPromo(_sender, _count);
        }
        ExchangePlayer(_sender, _count);
        return true;
    }

    function _onPromo(address _sender, uint256 _count) internal {
        uint256 userCount = userToken2PlayerCount[_sender];
        uint256 userCountNow = userCount.add(_count);
        userToken2PlayerCount[_sender] = userCountNow;
        if (userCount == 0) {
            _createPlayer(_sender, 14, 88, 35, 58, 1, 0, 56);
        }
        if (userCount < 5 && userCountNow >= 5) {
            _createPlayer(_sender, 13, 42, 80, 81, 1, 0, 70);
        }
    }

    function createCommonPlayer() external onlyCOO returns (uint256)
    {
        require(players.length == 0);
        players.length++;

        uint16 commonTypeId = 1;
        address commonAdress = address(0);

        _createPlayer(commonAdress, commonTypeId++, 40, 12, 25, 1, 0, 0);
        _createPlayer(commonAdress, commonTypeId++, 16, 32, 39, 3, 0, 0);
        _createPlayer(commonAdress, commonTypeId++, 30, 35, 13, 3, 0, 0);
        _createPlayer(commonAdress, commonTypeId++, 22, 30, 24, 5, 0, 0);
        _createPlayer(commonAdress, commonTypeId++, 25, 14, 43, 3, 0, 0);
        _createPlayer(commonAdress, commonTypeId++, 15, 40, 22, 5, 0, 0);
        _createPlayer(commonAdress, commonTypeId++, 17, 39, 25, 3, 0, 0);
        _createPlayer(commonAdress, commonTypeId++, 41, 22, 13, 3, 0, 0);
        _createPlayer(commonAdress, commonTypeId++, 30, 31, 28, 1, 0, 0);
        _createPlayer(commonAdress, commonTypeId++, 13, 45, 11, 3, 1, 0);

        require(commonPlayerCount+1 == players.length);
        return commonPlayerCount;
    }
}

/// @title 
contract SaleClockAuctionInterface {
    /// @dev simply a boolean to indicate this is the contract we expect to be
    function isSaleClockAuction() public pure returns (bool);
    function createAuction(uint256 _tokenId, uint256 _startingPrice, uint256 _endingPrice, uint256 _duration, address _seller) external;
}

/// @title Handles creating auctions for sale and siring of players.
///  This wrapper of ReverseAuction exists only so that users can create
///  auctions with only one transaction.
contract BSAuction is BSMinting {

    /// @dev The address of the ClockAuction contract that handles sales of players. 
    SaleClockAuctionInterface public saleAuction;

    /// @dev Sets the reference to the sale auction.
    /// @param _address - Address of sale contract.
    function setSaleAuctionAddress(address _address) public onlyCEO {
        SaleClockAuctionInterface candidateContract = SaleClockAuctionInterface(_address);

        // NOTE: verify that a contract is what we expect - https://github.com/Lunyr/crowdsale-contracts/blob/cfadd15986c30521d8ba7d5b6f57b4fefcc7ac38/contracts/LunyrToken.sol#L117
        require(candidateContract.isSaleClockAuction());

        // Set the new contract address
        saleAuction = candidateContract;
    }

    /// @dev Put a player up for auction.
    ///  Does some ownership trickery to create auctions in one tx.
    function createSaleAuction(
        uint256 _playerId,
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
        require(_owns(msg.sender, _playerId));
        _approve(_playerId, saleAuction);
        // Sale auction throws if inputs are invalid and clears
        // transfer and sire approval after escrowing the player.
        saleAuction.createAuction(
            _playerId,
            _startingPrice,
            _endingPrice,
            _duration,
            msg.sender
        );
    }
}

contract GlobalDefines {
    uint8 constant TYPE_SKILL_ATTRI_ATTACK = 0;
    uint8 constant TYPE_SKILL_ATTRI_DEFENSE = 1;
    uint8 constant TYPE_SKILL_ATTRI_STAMINA = 2;
    uint8 constant TYPE_SKILL_ATTRI_GOALKEEPER = 3;
}

/// @title Interface for PlayerInterface
contract PlayerInterface {
    function checkOwner(address _owner, uint32[11] _ids) public view returns (bool);
    function queryPlayerType(uint32[11] _ids) public view returns (uint32[11] playerTypes);
    function queryPlayer(uint32 _id) public view returns (uint16[8]);
    function queryPlayerUnAwakeSkillIds(uint32[11] _playerIds) public view returns (uint16[11] playerUnAwakeSkillIds);
    function tournamentResult(uint32[3][11][32] _playerAwakeSkills) public;
}

contract BSCore is GlobalDefines, BSAuction, PlayerInterface {

    // This is the main BS contract.

    /// @notice Creates the main BS smart contract instance.
    function BSCore() public {
        // Starts paused.
        paused = true;

        // the creator of the contract is the initial CEO
        ceoAddress = msg.sender;

        // the creator of the contract is also the initial COO
        cooAddress = msg.sender;
    }

    /// @dev Sets the reference to the JOY token contract.
    /// @param _address - Address of JOY token contract.
    function setJOYTokenAddress(address _address) external onlyCOO {
        // Set the new contract address
        joyTokenContract = ERC827(_address);
    }

    /// @dev Sets the reference to the Tournament token contract.
    /// @param _address - Address of Tournament token contract.
    function setTournamentAddress(address _address) external onlyCOO {
        TournamentInterface candidateContract = TournamentInterface(_address);

        // NOTE: verify that a contract is what we expect - https://github.com/Lunyr/crowdsale-contracts/blob/cfadd15986c30521d8ba7d5b6f57b4fefcc7ac38/contracts/LunyrToken.sol#L117
        require(candidateContract.isTournament());

        // Set the new contract address
        tournamentContract = candidateContract;
    }

    function() external {
        revert();
    }

    function withdrawJOYTokens() external onlyCFO {
        uint256 value = joyTokenContract.balanceOf(address(this));
        joyTokenContract.transfer(cfoAddress, value);
    }

    /// @notice Returns all the relevant information about a specific player.
    /// @param _id The ID of the player of interest.
    function getPlayer(uint256 _id)
        external
        view
        returns (
        uint256 typeId,
        uint256 attack,
        uint256 defense,
        uint256 stamina,
        uint256 xp,
        uint256 isKeeper,
        uint256 skillId,
        uint256 isSkillOn
    ) {
        Player storage player = players[_id];

        typeId = uint256(player.typeId);
        attack = uint256(player.attack);
        defense = uint256(player.defense);
        stamina = uint256(player.stamina);
        xp = uint256(player.xp);
        isKeeper = uint256(player.isKeeper);
        skillId = uint256(player.skillId);
        isSkillOn = uint256(player.isSkillOn);
    }

    function checkOwner(address _owner, uint32[11] _ids) public view returns (bool) {
        for (uint256 i = 0; i < _ids.length; i++) {
            uint256 _id = _ids[i];
            if ((_id <= 0 || _id > commonPlayerCount) && !_owns(_owner, _id)) {
                return false;
            }
        }
        return true;
    }

    function queryPlayerType(uint32[11] _ids) public view returns (uint32[11] playerTypes) {
        for (uint256 i = 0; i < _ids.length; i++) {
            uint256 _id = _ids[i];
            Player storage player = players[_id];
            playerTypes[i] = player.typeId;
        }
    }

    function queryPlayer(uint32 _id)
        public
        view
        returns (
        uint16[8]
    ) {
        Player storage player = players[_id];
        return [player.typeId, player.attack, player.defense, player.stamina, player.xp, player.isKeeper, player.skillId, player.isSkillOn];
    }

    function queryPlayerUnAwakeSkillIds(uint32[11] _playerIds)
        public
        view
        returns (
        uint16[11] playerUnAwakeSkillIds
    ) {
        for (uint256 i = 0; i < _playerIds.length; i++) {
            Player storage player = players[_playerIds[i]];
            if (player.skillId > 0 && player.isSkillOn == 0)
            {
                playerUnAwakeSkillIds[i] = player.skillId;
            }
        }
    }

    function tournamentResult(uint32[3][11][32] _playerAwakeSkills) public {
        require(msg.sender == address(tournamentContract));

        for (uint8 i = 0; i < 32; i++) {
            for (uint8 j = 0; j < 11; j++) {
                uint32 _id = _playerAwakeSkills[i][j][0];
                Player storage player = players[_id];
                if (player.skillId > 0 && player.isSkillOn == 0) {
                    uint32 skillType = _playerAwakeSkills[i][j][1];
                    uint8 skillAddAttri = uint8(_playerAwakeSkills[i][j][2]);

                    if (skillType == TYPE_SKILL_ATTRI_ATTACK) {
                        player.attack += skillAddAttri;
                        player.isSkillOn = 1;
                    }

                    if (skillType == TYPE_SKILL_ATTRI_DEFENSE) {
                        player.defense += skillAddAttri;
                        player.isSkillOn = 1;
                    }

                    if (skillType == TYPE_SKILL_ATTRI_STAMINA) {
                        player.stamina += skillAddAttri;
                        player.isSkillOn = 1;
                    }

                    if (skillType == TYPE_SKILL_ATTRI_GOALKEEPER && player.isKeeper == 0) {
                        player.isKeeper = 1;
                        player.isSkillOn = 1;
                    }
                }
            }
        }
    }
}