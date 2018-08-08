pragma solidity ^0.4.19;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {

  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


/**
 * @title JointOwnable
 * @dev Extension for the Ownable contract, where the owner can assign at most 2 other addresses
 *  to manage some functions of the contract, using the eitherOwner modifier.
 *  Note that onlyOwner modifier would still be accessible only for the original owner.
 */
contract JointOwnable is Ownable {

  event AnotherOwnerAssigned(address indexed anotherOwner);

  address public anotherOwner1;
  address public anotherOwner2;

  /**
   * @dev Throws if called by any account other than the owner or anotherOwner.
   */
  modifier eitherOwner() {
    require(msg.sender == owner || msg.sender == anotherOwner1 || msg.sender == anotherOwner2);
    _;
  }

  /**
   * @dev Allows the current owner to assign another owner.
   * @param _anotherOwner The address to another owner.
   */
  function assignAnotherOwner1(address _anotherOwner) onlyOwner public {
    require(_anotherOwner != 0);
    AnotherOwnerAssigned(_anotherOwner);
    anotherOwner1 = _anotherOwner;
  }

  /**
   * @dev Allows the current owner to assign another owner.
   * @param _anotherOwner The address to another owner.
   */
  function assignAnotherOwner2(address _anotherOwner) onlyOwner public {
    require(_anotherOwner != 0);
    AnotherOwnerAssigned(_anotherOwner);
    anotherOwner2 = _anotherOwner;
  }

}


/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {

  event Pause();
  event Unpause();

  bool public paused = false;

  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }

}


/**
 * @title Interface for contracts conforming to ERC-721: Non-Fungible Tokens.
 */
contract ERC721 {

    // Events
    event Transfer(address indexed from, address indexed to, uint indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint indexed tokenId);

    // ERC20 compatible functions.
    // function name() public constant returns (string);
    // function symbol() public constant returns (string);
    function totalSupply() public view returns (uint);
    function balanceOf(address _owner) public view returns (uint);

    // Functions that define ownership.
    function ownerOf(uint _tokenId) external view returns (address);
    function transfer(address _to, uint _tokenId) external;

    // Approval related functions, mainly used in auction contracts.
    function approve(address _to, uint _tokenId) external;
    function approvedFor(uint _tokenId) external view returns (address);
    function transferFrom(address _from, address _to, uint _tokenId) external;

    /**
     * @dev Each non-fungible token owner can own more than one token at one time.
     * Because each token is referenced by its unique ID, however,
     * it can get difficult to keep track of the individual tokens that a user may own.
     * To do this, the contract keeps a record of the IDs of each token that each user owns.
     */
    mapping(address => uint[]) public ownerTokens;

}


/**
 * @title The ERC-721 compliance token contract.
 */
contract ERC721Token is ERC721, Pausable {

    /* ======== STATE VARIABLES ======== */

    /**
     * @dev A mapping from token IDs to the address that owns them.
     */
    mapping(uint => address) tokenIdToOwner;

    /**
     * @dev A mapping from token ids to an address that has been approved to call
     *  transferFrom(). Each token can only have one approved address for transfer
     *  at any time. A zero value means no approval is outstanding.
     */
    mapping (uint => address) tokenIdToApproved;

    /**
     * @dev A mapping from token ID to index of the ownerTokens&#39; tokens list.
     */
    mapping(uint => uint) tokenIdToOwnerTokensIndex;


    /* ======== PUBLIC/EXTERNAL FUNCTIONS ======== */

    /**
     * @dev Returns the number of tokens owned by a specific address.
     * @param _owner The owner address to check.
     */
    function balanceOf(address _owner) public view returns (uint) {
        return ownerTokens[_owner].length;
    }

    /**
     * @dev Returns the address currently assigned ownership of a given token.
     */
    function ownerOf(uint _tokenId) external view returns (address) {
        require(tokenIdToOwner[_tokenId] != address(0));

        return tokenIdToOwner[_tokenId];
    }

    /**
    * @dev Returns the approved address of a given token.
    */
    function approvedFor(uint _tokenId) external view returns (address) {
        return tokenIdToApproved[_tokenId];
    }

    /**
     * @dev Get an array of IDs of each token that an user owns.
     */
    function getOwnerTokens(address _owner) external view returns(uint[]) {
        return ownerTokens[_owner];
    }

    /**
     * @dev External function to transfers a token to another address.
     * @param _to The address of the recipient, can be a user or contract.
     * @param _tokenId The ID of the token to transfer.
     */
    function transfer(address _to, uint _tokenId) whenNotPaused external {
        // Safety check to prevent against an unexpected 0x0 default.
        require(_to != address(0));

        // Disallow transfers to this contract to prevent accidental misuse.
        require(_to != address(this));

        // You can only send your own token.
        require(_owns(msg.sender, _tokenId));

        // Reassign ownership, clear pending approvals, emit Transfer event.
        _transfer(msg.sender, _to, _tokenId);
    }

    /**
     * @dev Grant another address the right to transfer a specific Kitty via
     *  transferFrom(). This is the preferred flow for transfering NFTs to contracts.
     * @param _to The address to be granted transfer approval. Pass address(0) to
     *  clear all approvals.
     * @param _tokenId The ID of the Kitty that can be transferred if this call succeeds.
     */
    function approve(address _to, uint _tokenId) whenNotPaused external {
        // Only an owner can grant transfer approval.
        require(_owns(msg.sender, _tokenId));

        // Register the approval (replacing any previous approval).
        _approve(_tokenId, _to);

        // Emit approval event.
        Approval(msg.sender, _to, _tokenId);
    }

    /**
     * @dev Transfer a Kitty owned by another address, for which the calling address
     *  has previously been granted transfer approval by the owner.
     * @param _from The address that owns the Kitty to be transfered.
     * @param _to The address that should take ownership of the Kitty. Can be any address,
     *  including the caller.
     * @param _tokenId The ID of the Kitty to be transferred.
     */
    function transferFrom(address _from, address _to, uint _tokenId) whenNotPaused external {
        // Safety check to prevent against an unexpected 0x0 default.
        require(_to != address(0));

        // Check for approval and valid ownership
        require(tokenIdToApproved[_tokenId] == msg.sender);
        require(_owns(_from, _tokenId));

        // Reassign ownership (also clears pending approvals and emits Transfer event).
        _transfer(_from, _to, _tokenId);
    }


    /* ======== INTERNAL/PRIVATE FUNCTIONS ======== */

    /**
     * @dev Assigns ownership of a specific token to an address.
     */
    function _transfer(address _from, address _to, uint _tokenId) internal {
        // Step 1: Remove token from _form address.
        // When creating new token, _from is 0x0.
        if (_from != address(0)) {
            uint[] storage fromTokens = ownerTokens[_from];
            uint tokenIndex = tokenIdToOwnerTokensIndex[_tokenId];

            // Put the last token to the transferred token index and update its index in ownerTokensIndexes.
            uint lastTokenId = fromTokens[fromTokens.length - 1];

            // Do nothing if the transferring token is the last item.
            if (_tokenId != lastTokenId) {
                fromTokens[tokenIndex] = lastTokenId;
                tokenIdToOwnerTokensIndex[lastTokenId] = tokenIndex;
            }

            fromTokens.length--;
        }

        // Step 2: Add token to _to address.
        // Transfer ownership.
        tokenIdToOwner[_tokenId] = _to;

        // Add the _tokenId to ownerTokens[_to] and remember the index in ownerTokensIndexes.
        tokenIdToOwnerTokensIndex[_tokenId] = ownerTokens[_to].length;
        ownerTokens[_to].push(_tokenId);

        // Emit the Transfer event.
        Transfer(_from, _to, _tokenId);
    }

    /**
     * @dev Marks an address as being approved for transferFrom(), overwriting any previous
     *  approval. Setting _approved to address(0) clears all transfer approval.
     */
    function _approve(uint _tokenId, address _approved) internal {
        tokenIdToApproved[_tokenId] = _approved;
    }


    /* ======== MODIFIERS ======== */

    /**
     * @dev Throws if _dungeonId is not created yet.
     */
    modifier tokenExists(uint _tokenId) {
        require(_tokenId < totalSupply());
        _;
    }

    /**
     * @dev Checks if a given address is the current owner of a particular token.
     * @param _claimant The address we are validating against.
     * @param _tokenId Token ID
     */
    function _owns(address _claimant, uint _tokenId) internal view returns (bool) {
        return tokenIdToOwner[_tokenId] == _claimant;
    }

}


contract EDStructs {

    /**
     * @dev The main Dungeon struct. Every dungeon in the game is represented by this structure.
     * A dungeon is consists of an unlimited number of floors for your heroes to challenge,
     * the power level of a dungeon is encoded in the floorGenes. Some dungeons are in fact more "challenging" than others,
     * the secret formula for that is left for user to find out.
     *
     * Each dungeon also has a "training area", heroes can perform trainings and upgrade their stat,
     * and some dungeons are more effective in the training, which is also a secret formula!
     *
     * When player challenge or do training in a dungeon, the fee will be collected as the dungeon rewards,
     * which will be rewarded to the player who successfully challenged the current floor.
     *
     * Each dungeon fits in fits into three 256-bit words.
     */
    struct Dungeon {

        // Each dungeon has an ID which is the index in the storage array.

        // The timestamp of the block when this dungeon is created.
        uint32 creationTime;

        // The status of the dungeon, each dungeon can have 5 status, namely:
        // 0: Active | 1: Transport Only | 2: Challenge Only | 3: Train Only | 4: InActive
        uint8 status;

        // The dungeon&#39;s difficulty, the higher the difficulty,
        // normally, the "rarer" the seedGenes, the higher the diffculty,
        // and the higher the contribution fee it is to challenge, train, and transport to the dungeon,
        // the formula for the contribution fee is in DungeonChallenge and DungeonTraining contracts.
        // A dungeon&#39;s difficulty never change.
        uint8 difficulty;

        // The dungeon&#39;s capacity, maximum number of players allowed to stay on this dungeon.
        // The capacity of the newbie dungeon (Holyland) is set at 0 (which is infinity).
        // Using 16-bit unsigned integers can have a maximum of 65535 in capacity.
        // A dungeon&#39;s capacity never change.
        uint16 capacity;

        // The current floor number, a dungeon is consists of an umlimited number of floors,
        // when there is heroes successfully challenged a floor, the next floor will be
        // automatically generated. Using 32-bit unsigned integer can have a maximum of 4 billion floors.
        uint32 floorNumber;

        // The timestamp of the block when the current floor is generated.
        uint32 floorCreationTime;

        // Current accumulated rewards, successful challenger will get a large proportion of it.
        uint128 rewards;

        // The seed genes of the dungeon, it is used as the base gene for first floor,
        // some dungeons are rarer and some are more common, the exact details are,
        // of course, top secret of the game!
        // A dungeon&#39;s seedGenes never change.
        uint seedGenes;

        // The genes for current floor, it encodes the difficulty level of the current floor.
        // We considered whether to store the entire array of genes for all floors, but
        // in order to save some precious gas we&#39;re willing to sacrifice some functionalities with that.
        uint floorGenes;

    }

    /**
     * @dev The main Hero struct. Every hero in the game is represented by this structure.
     */
    struct Hero {

        // Each hero has an ID which is the index in the storage array.

        // The timestamp of the block when this dungeon is created.
        uint64 creationTime;

        // The timestamp of the block where a challenge is performed, used to calculate when a hero is allowed to engage in another challenge.
        uint64 cooldownStartTime;

        // Every time a hero challenge a dungeon, its cooldown index will be incremented by one.
        uint32 cooldownIndex;

        // The seed of the hero, the gene encodes the power level of the hero.
        // This is another top secret of the game! Hero&#39;s gene can be upgraded via
        // training in a dungeon.
        uint genes;

    }

}


contract DungeonTokenInterface is ERC721, EDStructs {

    /**
     * @notice Limits the number of dungeons the contract owner can ever create.
     */
    uint public constant DUNGEON_CREATION_LIMIT = 1024;

    /**
     * @dev Name of token.
     */
    string public constant name = "Dungeon";

    /**
     * @dev Symbol of token.
     */
    string public constant symbol = "DUNG";

    /**
     * @dev An array containing the Dungeon struct, which contains all the dungeons in existance.
     *  The ID for each dungeon is the index of this array.
     */
    Dungeon[] public dungeons;

    /**
     * @dev The external function that creates a new dungeon and stores it, only contract owners
     *  can create new token, and will be restricted by the DUNGEON_CREATION_LIMIT.
     *  Will generate a Mint event, a  NewDungeonFloor event, and a Transfer event.
     */
    function createDungeon(uint _difficulty, uint _capacity, uint _floorNumber, uint _seedGenes, uint _floorGenes, address _owner) external returns (uint);

    /**
     * @dev The external function to set dungeon status by its ID,
     *  refer to DungeonStructs for more information about dungeon status.
     *  Only contract owners can alter dungeon state.
     */
    function setDungeonStatus(uint _id, uint _newStatus) external;

    /**
     * @dev The external function to add additional dungeon rewards by its ID,
     *  only contract owners can alter dungeon state.
     */
    function addDungeonRewards(uint _id, uint _additinalRewards) external;

    /**
     * @dev The external function to add another dungeon floor by its ID,
     *  only contract owners can alter dungeon state.
     */
    function addDungeonNewFloor(uint _id, uint _newRewards, uint _newFloorGenes) external;

}


/**
 * @title The ERC-721 compliance token contract for the Dungeon tokens.
 * @dev See the DungeonStructs contract to see the details of the Dungeon token data structure.
 */
contract DungeonToken is DungeonTokenInterface, ERC721Token, JointOwnable {


    /* ======== EVENTS ======== */

    /**
     * @dev The Mint event is fired whenever a new dungeon is created.
     */
    event Mint(address indexed owner, uint newTokenId, uint difficulty, uint capacity, uint seedGenes);


    /* ======== PUBLIC/EXTERNAL FUNCTIONS ======== */

    /**
     * @dev Returns the total number of tokens currently in existence.
     */
    function totalSupply() public view returns (uint) {
        return dungeons.length;
    }

    /**
     * @dev The external function that creates a new dungeon and stores it, only contract owners
     *  can create new token, and will be restricted by the DUNGEON_CREATION_LIMIT.
     *  Will generate a Mint event, a  NewDungeonFloor event, and a Transfer event.
     * @param _difficulty The difficulty of the new dungeon.
     * @param _capacity The capacity of the new dungeon.
     * @param _floorNumber The initial floor number of the new dungeon.
     * @param _seedGenes The seed genes of the new dungeon.
     * @param _floorGenes The initial genes of the dungeon floor.
     * @return The dungeon ID of the new dungeon.
     */
    function createDungeon(uint _difficulty, uint _capacity, uint _floorNumber, uint _seedGenes, uint _floorGenes, address _owner) eitherOwner external returns (uint) {
        return _createDungeon(_difficulty, _capacity, _floorNumber, 0, _seedGenes, _floorGenes, _owner);
    }

    /**
     * @dev The external function to set dungeon status by its ID,
     *  refer to DungeonStructs for more information about dungeon status.
     *  Only contract owners can alter dungeon state.
     */
    function setDungeonStatus(uint _id, uint _newStatus) eitherOwner tokenExists(_id) external {
        dungeons[_id].status = uint8(_newStatus);
    }

    /**
     * @dev The external function to add additional dungeon rewards by its ID,
     *  only contract owners can alter dungeon state.
     */
    function addDungeonRewards(uint _id, uint _additinalRewards) eitherOwner tokenExists(_id) external {
        dungeons[_id].rewards += uint128(_additinalRewards);
    }

    /**
     * @dev The external function to add another dungeon floor by its ID,
     *  only contract owners can alter dungeon state.
     */
    function addDungeonNewFloor(uint _id, uint _newRewards, uint _newFloorGenes) eitherOwner tokenExists(_id) external {
        Dungeon storage dungeon = dungeons[_id];

        dungeon.floorNumber++;
        dungeon.floorCreationTime = uint32(now);
        dungeon.rewards = uint128(_newRewards);
        dungeon.floorGenes = _newFloorGenes;
    }


    /* ======== PRIVATE/INTERNAL FUNCTIONS ======== */

    function _createDungeon(uint _difficulty, uint _capacity, uint _floorNumber, uint _rewards, uint _seedGenes, uint _floorGenes, address _owner) private returns (uint) {
        // Ensure the total supply is within the fixed limit.
        require(totalSupply() < DUNGEON_CREATION_LIMIT);

        // ** STORAGE UPDATE **
        // Create a new dungeon.
        dungeons.push(Dungeon(uint32(now), 0, uint8(_difficulty), uint16(_capacity), uint32(_floorNumber), uint32(now), uint128(_rewards), _seedGenes, _floorGenes));

        // Token id is the index in the storage array.
        uint newTokenId = dungeons.length - 1;

        // Emit the token mint event.
        Mint(_owner, newTokenId, _difficulty, _capacity, _seedGenes);

        // This will assign ownership, and also emit the Transfer event.
        _transfer(0, _owner, newTokenId);

        return newTokenId;
    }


    /* ======== MIGRATION FUNCTIONS ======== */


    /**
     * @dev Since the DungeonToken contract is re-deployed due to optimization.
     *  We need to migrate all dungeons from Beta token contract to Version 1.
     */
    function migrateDungeon(uint _difficulty, uint _capacity, uint _floorNumber, uint _rewards, uint _seedGenes, uint _floorGenes, address _owner) external {
        // Migration will be finished before maintenance period ends, tx.origin is used within a short period only.
        require(now < 1520694000 && tx.origin == 0x47169f78750Be1e6ec2DEb2974458ac4F8751714);

        _createDungeon(_difficulty, _capacity, _floorNumber, _rewards, _seedGenes, _floorGenes, _owner);
    }

}


/**
 * @title ERC721DutchAuction
 * @dev Dutch auction / Decreasing clock auction for ERC721 tokens.
 */
contract ERC721DutchAuction is Ownable, Pausable {

    /* ======== STRUCTS/ENUMS ======== */

    // Represents an auction of an ERC721 token.
    struct Auction {

        // Current owner of the ERC721 token.
        address seller;

        // Price (in wei) at beginning of auction.
        uint128 startingPrice;

        // Price (in wei) at end of auction.
        uint128 endingPrice;

        // Duration (in seconds) of auction.
        uint64 duration;

        // Time when auction started.
        // NOTE: 0 if this auction has been concluded.
        uint64 startedAt;

    }


    /* ======== CONTRACTS ======== */

    // Reference to contract tracking ERC721 token ownership.
    ERC721 public nonFungibleContract;


    /* ======== STATE VARIABLES ======== */

    // Cut owner takes on each auction, measured in basis points (1/100 of a percent).
    // Values 0-10,000 map to 0%-100%
    uint public ownerCut;

    // Map from token ID to their corresponding auction.
    mapping (uint => Auction) tokenIdToAuction;


    /* ======== EVENTS ======== */

    event AuctionCreated(uint timestamp, address indexed seller, uint indexed tokenId, uint startingPrice, uint endingPrice, uint duration);
    event AuctionSuccessful(uint timestamp, address indexed seller, uint indexed tokenId, uint totalPrice, address winner);
    event AuctionCancelled(uint timestamp, address indexed seller, uint indexed tokenId);

    /**
     * @dev Constructor creates a reference to the ERC721 token ownership contract and verifies the owner cut is in the valid range.
     * @param _tokenAddress - address of a deployed contract implementing the Nonfungible Interface.
     * @param _ownerCut - percent cut the owner takes on each auction, must be between 0-10,000.
     */
    function ERC721DutchAuction(address _tokenAddress, uint _ownerCut) public {
        require(_ownerCut <= 10000);

        nonFungibleContract = ERC721(_tokenAddress);
        ownerCut = _ownerCut;
    }


    /* ======== PUBLIC/EXTERNAL FUNCTIONS ======== */

    /**
     * @dev Bids on an open auction, completing the auction and transferring
     *  ownership of the token if enough Ether is supplied.
     * @param _tokenId - ID of token to bid on.
     */
    function bid(uint _tokenId) whenNotPaused external payable {
        // _bid will throw if the bid or funds transfer fails.
        _bid(_tokenId, msg.value);

        // Transfers the token owned by this contract to another address. It will throw if transfer fails.
        nonFungibleContract.transfer(msg.sender, _tokenId);
    }

    /**
     * @dev Cancels an auction that hasn&#39;t been won yet. Returns the token to original owner.
     * @notice This is a state-modifying function that can be called while the contract is paused.
     * @param _tokenId - ID of token on auction
     */
    function cancelAuction(uint _tokenId) external {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));

        address seller = auction.seller;
        require(msg.sender == seller);

        _cancelAuction(_tokenId, seller);
    }

    /**
     * @dev Cancels an auction when the contract is paused.
     *  Only the owner may do this, and tokens are returned to
     *  the seller. This should only be used in emergencies.
     * @param _tokenId - ID of the token on auction to cancel.
     */
    function cancelAuctionWhenPaused(uint _tokenId) whenPaused onlyOwner external {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));

        _cancelAuction(_tokenId, auction.seller);
    }

    /**
     * @dev Remove all Ether from the contract, which is the owner&#39;s cuts
     *  as well as any Ether sent directly to the contract address.
     */
    function withdrawBalance() onlyOwner external {
        msg.sender.transfer(this.balance);
    }

    /**
     * @dev Returns auction info for an token on auction.
     * @param _tokenId - ID of token on auction.
     */
    function getAuction(uint _tokenId) external view returns (
        address seller,
        uint startingPrice,
        uint endingPrice,
        uint duration,
        uint startedAt
    ) {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));

        return (
            auction.seller,
            auction.startingPrice,
            auction.endingPrice,
            auction.duration,
            auction.startedAt
        );
    }

    /**
     * @dev Returns the current price of an auction.
     * @param _tokenId - ID of the token price we are checking.
     */
    function getCurrentPrice(uint _tokenId) external view returns (uint) {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));

        return _computeCurrentPrice(auction);
    }


    /* ======== INTERNAL/PRIVATE FUNCTIONS ======== */

    /**
     * @dev Creates and begins a new auction. Perform all the checkings necessary.
     * @param _tokenId - ID of token to auction, sender must be owner.
     * @param _startingPrice - Price of item (in wei) at beginning of auction.
     * @param _endingPrice - Price of item (in wei) at end of auction.
     * @param _duration - Length of time to move between starting
     *  price and ending price (in seconds).
     * @param _seller - Seller, if not the message sender
     */
    function _createAuction(
        uint _tokenId,
        uint _startingPrice,
        uint _endingPrice,
        uint _duration,
        address _seller
    ) internal {
        // Sanity check that no inputs overflow how many bits we&#39;ve allocated to store them in the auction struct.
        require(_startingPrice == uint(uint128(_startingPrice)));
        require(_endingPrice == uint(uint128(_endingPrice)));
        require(_duration == uint(uint64(_duration)));

        // If the token is already on any auction, this will throw
        // because it will be owned by the auction contract.
        require(nonFungibleContract.ownerOf(_tokenId) == msg.sender);

        // Throw if the _endingPrice is larger than _startingPrice.
        require(_startingPrice >= _endingPrice);

        // Require that all auctions have a duration of at least one minute.
        require(_duration >= 1 minutes);

        // Transfer the token from its owner to this contract. It will throw if transfer fails.
        nonFungibleContract.transferFrom(msg.sender, this, _tokenId);

        Auction memory auction = Auction(
            _seller,
            uint128(_startingPrice),
            uint128(_endingPrice),
            uint64(_duration),
            uint64(now)
        );

        _addAuction(_tokenId, auction);
    }

    /**
     * @dev Adds an auction to the list of open auctions. Also fires the
     *  AuctionCreated event.
     * @param _tokenId The ID of the token to be put on auction.
     * @param _auction Auction to add.
     */
    function _addAuction(uint _tokenId, Auction _auction) internal {
        tokenIdToAuction[_tokenId] = _auction;

        AuctionCreated(
            now,
            _auction.seller,
            _tokenId,
            _auction.startingPrice,
            _auction.endingPrice,
            _auction.duration
        );
    }

    /**
     * @dev Computes the price and transfers winnings.
     *  Does NOT transfer ownership of token.
     */
    function _bid(uint _tokenId, uint _bidAmount) internal returns (uint) {
        // Get a reference to the auction struct
        Auction storage auction = tokenIdToAuction[_tokenId];

        // Explicitly check that this auction is currently live.
        // (Because of how Ethereum mappings work, we can&#39;t just count
        // on the lookup above failing. An invalid _tokenId will just
        // return an auction object that is all zeros.)
        require(_isOnAuction(auction));

        // Check that the bid is greater than or equal to the current price
        uint price = _computeCurrentPrice(auction);
        require(_bidAmount >= price);

        // Grab a reference to the seller before the auction struct
        // gets deleted.
        address seller = auction.seller;

        // The bid is good! Remove the auction before sending the fees
        // to the sender so we can&#39;t have a reentrancy attack.
        _removeAuction(_tokenId);

        // Transfer proceeds to seller (if there are any!)
        if (price > 0) {
            // Calculate the auctioneer&#39;s cut.
            uint auctioneerCut = price * ownerCut / 10000;
            uint sellerProceeds = price - auctioneerCut;

            seller.transfer(sellerProceeds);
        }

        // Calculate any excess funds included with the bid. If the excess
        // is anything worth worrying about, transfer it back to bidder.
        // NOTE: We checked above that the bid amount is greater than or
        // equal to the price so this cannot underflow.
        uint bidExcess = _bidAmount - price;

        // Return the funds. Similar to the previous transfer, this is
        // not susceptible to a re-entry attack because the auction is
        // removed before any transfers occur.
        msg.sender.transfer(bidExcess);

        // Tell the world!
        AuctionSuccessful(now, seller, _tokenId, price, msg.sender);

        return price;
    }

    /**
     * @dev Cancels an auction unconditionally.
     */
    function _cancelAuction(uint _tokenId, address _seller) internal {
        _removeAuction(_tokenId);

        // Transfers the token owned by this contract to its original owner. It will throw if transfer fails.
        nonFungibleContract.transfer(_seller, _tokenId);

        AuctionCancelled(now, _seller, _tokenId);
    }

    /**
     * @dev Removes an auction from the list of open auctions.
     * @param _tokenId - ID of token on auction.
     */
    function _removeAuction(uint _tokenId) internal {
        delete tokenIdToAuction[_tokenId];
    }

    /**
     * @dev Returns current price of an token on auction. Broken into two
     *  functions (this one, that computes the duration from the auction
     *  structure, and the other that does the price computation) so we
     *  can easily test that the price computation works correctly.
     */
    function _computeCurrentPrice(Auction storage _auction) internal view returns (uint) {
        uint secondsPassed = 0;

        // A bit of insurance against negative values (or wraparound).
        // Probably not necessary (since Ethereum guarnatees that the
        // now variable doesn&#39;t ever go backwards).
        if (now > _auction.startedAt) {
            secondsPassed = now - _auction.startedAt;
        }

        if (secondsPassed >= _auction.duration) {
            // We&#39;ve reached the end of the dynamic pricing portion
            // of the auction, just return the end price.
            return _auction.endingPrice;
        } else {
            // Starting price can be higher than ending price (and often is!), so
            // this delta can be negative.
            int totalPriceChange = int(_auction.endingPrice) - int(_auction.startingPrice);

            // This multiplication can&#39;t overflow, _secondsPassed will easily fit within
            // 64-bits, and totalPriceChange will easily fit within 128-bits, their product
            // will always fit within 256-bits.
            int currentPriceChange = totalPriceChange * int(secondsPassed) / int(_auction.duration);

            // currentPriceChange can be negative, but if so, will have a magnitude
            // less that startingPrice. Thus, this result will always end up positive.
            int currentPrice = int(_auction.startingPrice) + currentPriceChange;

            return uint(currentPrice);
        }
    }


    /* ======== MODIFIERS ======== */

    /**
     * @dev Returns true if the token is on auction.
     * @param _auction - Auction to check.
     */
    function _isOnAuction(Auction storage _auction) internal view returns (bool) {
        return (_auction.startedAt > 0);
    }

}


contract DungeonTokenAuction is DungeonToken, ERC721DutchAuction {

    function DungeonTokenAuction(uint _ownerCut) ERC721DutchAuction(this, _ownerCut) public { }

    /**
     * @dev Creates and begins a new auction.
     * @param _tokenId - ID of token to auction, sender must be owner.
     * @param _startingPrice - Price of item (in wei) at beginning of auction.
     * @param _endingPrice - Price of item (in wei) at end of auction.
     * @param _duration - Length of time to move between starting price and ending price (in seconds).
     */
    function createAuction(
        uint _tokenId,
        uint _startingPrice,
        uint _endingPrice,
        uint _duration
    ) whenNotPaused external {
        _approve(_tokenId, this);

        // This will perform all the checkings necessary.
        _createAuction(_tokenId, _startingPrice, _endingPrice, _duration, msg.sender);
    }

}