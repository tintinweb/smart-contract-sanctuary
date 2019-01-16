pragma solidity ^0.4.18;

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
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
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
/// @title Auction Core
/// @dev Contains models, variables, and internal methods for the auction.
contract ClockAuctionBase {

    // Represents an auction on an NFT
    struct Auction {
        // Current owner of NFT
        address seller;
        // Price (in wei) at beginning of auction
        uint128 startingPrice;
        // Price (in wei) at end of auction
        uint128 endingPrice;
        // Duration (in seconds) of auction
        uint64 duration;
        // Time when auction started
        // NOTE: 0 if this auction has been concluded
        uint64 startedAt;
    }

    // Reference to contract tracking NFT ownership
    ERC721 public nonFungibleContract;

    // Cut owner takes on each auction, measured in basis points (1/100 of a percent).
    // Values 0-10,000 map to 0%-100%
    uint256 public ownerCut;

    // Map from token ID to their corresponding auction.
    mapping (uint256 => Auction) tokenIdToAuction;

    event AuctionCreated(uint256 tokenId, uint256 startingPrice, uint256 endingPrice, uint256 duration);
    event AuctionSuccessful(uint256 tokenId, uint256 totalPrice, address winner);
    event AuctionCancelled(uint256 tokenId);

    /// @dev DON&#39;T give me your money.
    function() external {}

    // Modifiers to check that inputs can be safely stored with a certain
    // number of bits. We use constants and multiple modifiers to save gas.
    modifier canBeStoredWith64Bits(uint256 _value) {
        require(_value <= 18446744073709551615);
        _;
    }

    modifier canBeStoredWith128Bits(uint256 _value) {
        require(_value < 340282366920938463463374607431768211455);
        _;
    }

    /// @dev Returns true if the claimant owns the token.
    /// @param _claimant - Address claiming to own the token.
    /// @param _tokenId - ID of token whose ownership to verify.
    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return (nonFungibleContract.ownerOf(_tokenId) == _claimant);
    }

    /// @dev Escrows the NFT, assigning ownership to this contract.
    /// Throws if the escrow fails.
    /// @param _owner - Current owner address of token to escrow.
    /// @param _tokenId - ID of token whose approval to verify.
    function _escrow(address _owner, uint256 _tokenId) internal {
        // it will throw if transfer fails
        nonFungibleContract.transferFrom(_owner, this, _tokenId);
    }

    /// @dev Transfers an NFT owned by this contract to another address.
    /// Returns true if the transfer succeeds.
    /// @param _receiver - Address to transfer NFT to.
    /// @param _tokenId - ID of token to transfer.
    function _transfer(address _receiver, uint256 _tokenId) internal {
        // it will throw if transfer fails
        nonFungibleContract.transfer(_receiver, _tokenId);
    }

    /// @dev Adds an auction to the list of open auctions. Also fires the
    ///  AuctionCreated event.
    /// @param _tokenId The ID of the token to be put on auction.
    /// @param _auction Auction to add.
    function _addAuction(uint256 _tokenId, Auction _auction) internal {
        // Require that all auctions have a duration of
        // at least one minute. (Keeps our math from getting hairy!)
        require(_auction.duration >= 1 minutes);

        tokenIdToAuction[_tokenId] = _auction;

        AuctionCreated(
            uint256(_tokenId),
            uint256(_auction.startingPrice),
            uint256(_auction.endingPrice),
            uint256(_auction.duration)
        );
    }

    /// @dev Cancels an auction unconditionally.
    function _cancelAuction(uint256 _tokenId, address _seller) internal {
        _removeAuction(_tokenId);
        _transfer(_seller, _tokenId);
        AuctionCancelled(_tokenId);
    }

    /// @dev Computes the price and transfers winnings.
    /// Does NOT transfer ownership of token.
    function _bid(uint256 _tokenId, uint256 _bidAmount)
        internal
        returns (uint256)
    {
        // Get a reference to the auction struct
        Auction storage auction = tokenIdToAuction[_tokenId];

        // Explicitly check that this auction is currently live.
        // (Because of how Ethereum mappings work, we can&#39;t just count
        // on the lookup above failing. An invalid _tokenId will just
        // return an auction object that is all zeros.)
        require(_isOnAuction(auction));

        // Check that the incoming bid is higher than the current
        // price
        uint256 price = _currentPrice(auction);
        require(_bidAmount >= price);

        // Grab a reference to the seller before the auction struct
        // gets deleted.
        address seller = auction.seller;

        // The bid is good! Remove the auction before sending the fees
        // to the sender so we can&#39;t have a reentrancy attack.
        _removeAuction(_tokenId);

        // Transfer proceeds to seller (if there are any!)
        if (price > 0) {
            //  Calculate the auctioneer&#39;s cut.
            // (NOTE: _computeCut() is guaranteed to return a
            //  value <= price, so this subtraction can&#39;t go negative.)
            uint256 auctioneerCut = _computeCut(price);
            uint256 sellerProceeds = price - auctioneerCut;

            // NOTE: Doing a transfer() in the middle of a complex
            // method like this is generally discouraged because of
            // reentrancy attacks and DoS attacks if the seller is
            // a contract with an invalid fallback function. We explicitly
            // guard against reentrancy attacks by removing the auction
            // before calling transfer(), and the only thing the seller
            // can DoS is the sale of their own asset! (And if it&#39;s an
            // accident, they can call cancelAuction(). )
            seller.transfer(sellerProceeds);
        }

        // Tell the world!
        AuctionSuccessful(_tokenId, price, msg.sender);

        return price;
    }

    /// @dev Removes an auction from the list of open auctions.
    /// @param _tokenId - ID of NFT on auction.
    function _removeAuction(uint256 _tokenId) internal {
        delete tokenIdToAuction[_tokenId];
    }

    /// @dev Returns true if the NFT is on auction.
    /// @param _auction - Auction to check.
    function _isOnAuction(Auction storage _auction) internal view returns (bool) {
        return (_auction.startedAt > 0);
    }

    /// @dev Returns current price of an NFT on auction. Broken into two
    ///  functions (this one, that computes the duration from the auction
    ///  structure, and the other that does the price computation) so we
    ///  can easily test that the price computation works correctly.
    function _currentPrice(Auction storage _auction)
        internal
        view
        returns (uint256)
    {
        uint256 secondsPassed = 0;

        // A bit of insurance against negative values (or wraparound).
        // Probably not necessary (since Ethereum guarnatees that the
        // now variable doesn&#39;t ever go backwards).
        if (now > _auction.startedAt) {
            secondsPassed = now - _auction.startedAt;
        }

        return _computeCurrentPrice(
            _auction.startingPrice,
            _auction.endingPrice,
            _auction.duration,
            secondsPassed
        );
    }

    /// @dev Computes the current price of an auction. Factored out
    ///  from _currentPrice so we can run extensive unit tests.
    ///  When testing, make this function public and turn on
    ///  `Current price computation` test suite.
    function _computeCurrentPrice(
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        uint256 _secondsPassed
    )
        internal
        pure
        returns (uint256)
    {
        // NOTE: We don&#39;t use SafeMath (or similar) in this function because
        //  all of our public functions carefully cap the maximum values for
        //  time (at 64-bits) and currency (at 128-bits). _duration is
        //  also known to be non-zero (see the require() statement in
        //  _addAuction())
        if (_secondsPassed >= _duration) {
            // We&#39;ve reached the end of the dynamic pricing portion
            // of the auction, just return the end price.
            return _endingPrice;
        } else {
            // Starting price can be higher than ending price (and often is!), so
            // this delta can be negative.
            int256 totalPriceChange = int256(_endingPrice) - int256(_startingPrice);

            // This multiplication can&#39;t overflow, _secondsPassed will easily fit within
            // 64-bits, and totalPriceChange will easily fit within 128-bits, their product
            // will always fit within 256-bits.
            int256 currentPriceChange = totalPriceChange * int256(_secondsPassed) / int256(_duration);

            // currentPriceChange can be negative, but if so, will have a magnitude
            // less that _startingPrice. Thus, this result will always end up positive.
            int256 currentPrice = int256(_startingPrice) + currentPriceChange;

            return uint256(currentPrice);
        }
    }

    /// @dev Computes owner&#39;s cut of a sale.
    /// @param _price - Sale price of NFT.
    function _computeCut(uint256 _price) internal view returns (uint256) {
        // NOTE: We don&#39;t use SafeMath (or similar) in this function because
        //  all of our entry functions carefully cap the maximum values for
        //  currency (at 128-bits), and ownerCut <= 10000 (see the require()
        //  statement in the ClockAuction constructor). The result of this
        //  function is always guaranteed to be <= _price.
        return _price * ownerCut / 10000;
    }

}


/// @title Clock auction for non-fungible tokens.
contract ClockAuction is Pausable, ClockAuctionBase {

    /// @dev Constructor creates a reference to the NFT ownership contract
    ///  and verifies the owner cut is in the valid range.
    /// @param _nftAddress - address of a deployed contract implementing
    ///  the Nonfungible Interface.
    /// @param _cut - percent cut the owner takes on each auction, must be
    ///  between 0-10,000.
    function ClockAuction(address _nftAddress, uint256 _cut) public {
        require(_cut <= 10000);
        ownerCut = _cut;

        ERC721 candidateContract = ERC721(_nftAddress);
        require(candidateContract.implementsERC721());
        nonFungibleContract = candidateContract;
    }

    /// @dev Remove all Ether from the contract, which is the owner&#39;s cuts
    ///  as well as any Ether sent directly to the contract address.
    ///  Always transfers to the NFT contract, but can be called either by
    ///  the owner or the NFT contract.
    function withdrawBalance() external {
        address nftAddress = address(nonFungibleContract);

        require(
            msg.sender == owner ||
            msg.sender == nftAddress
        );
        nftAddress.transfer(this.balance);
    }

    /// @dev Creates and begins a new auction.
    /// @param _tokenId - ID of token to auction, sender must be owner.
    /// @param _startingPrice - Price of item (in wei) at beginning of auction.
    /// @param _endingPrice - Price of item (in wei) at end of auction.
    /// @param _duration - Length of time to move between starting
    ///  price and ending price (in seconds).
    /// @param _seller - Seller, if not the message sender
    function createAuction(
        uint256 _tokenId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        address _seller
    )
        public
        whenNotPaused
        canBeStoredWith128Bits(_startingPrice)
        canBeStoredWith128Bits(_endingPrice)
        canBeStoredWith64Bits(_duration)
    {
        require(_owns(msg.sender, _tokenId));
        _escrow(msg.sender, _tokenId);
        Auction memory auction = Auction(
            _seller,
            uint128(_startingPrice),
            uint128(_endingPrice),
            uint64(_duration),
            uint64(now)
        );
        _addAuction(_tokenId, auction);
    }

    /// @dev Bids on an open auction, completing the auction and transferring
    ///  ownership of the NFT if enough Ether is supplied.
    /// @param _tokenId - ID of token to bid on.
    function bid(uint256 _tokenId)
        public
        payable
        whenNotPaused
    {
        // _bid will throw if the bid or funds transfer fails
        _bid(_tokenId, msg.value);
        _transfer(msg.sender, _tokenId);
    }

    /// @dev Cancels an auction that hasn&#39;t been won yet.
    ///  Returns the NFT to original owner.
    /// @notice This is a state-modifying function that can
    ///  be called while the contract is paused.
    /// @param _tokenId - ID of token on auction
    function cancelAuction(uint256 _tokenId)
        public
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        address seller = auction.seller;
        require(msg.sender == seller);
        _cancelAuction(_tokenId, seller);
    }

    /// @dev Cancels an auction when the contract is paused.
    ///  Only the owner may do this, and NFTs are returned to
    ///  the seller. This should only be used in emergencies.
    /// @param _tokenId - ID of the NFT on auction to cancel.
    function cancelAuctionWhenPaused(uint256 _tokenId)
        whenPaused
        onlyOwner
        public
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        _cancelAuction(_tokenId, auction.seller);
    }

    /// @dev Returns auction info for an NFT on auction.
    /// @param _tokenId - ID of NFT on auction.
    function getAuction(uint256 _tokenId)
        public
        view
        returns
    (
        address seller,
        uint256 startingPrice,
        uint256 endingPrice,
        uint256 duration,
        uint256 startedAt
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

    /// @dev Returns the current price of an auction.
    /// @param _tokenId - ID of the token price we are checking.
    function getCurrentPrice(uint256 _tokenId)
        public
        view
        returns (uint256)
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        return _currentPrice(auction);
    }

}


/// @title Clock auction modified for sale of fighters
contract SaleClockAuction is ClockAuction {

    // @dev Sanity check that allows us to ensure that we are pointing to the
    //  right auction in our setSaleAuctionAddress() call.
    bool public isSaleClockAuction = true;

    // Tracks last 4 sale price of gen0 fighter sales
    uint256 public gen0SaleCount;
    uint256[4] public lastGen0SalePrices;

    // Delegate constructor
    function SaleClockAuction(address _nftAddr, uint256 _cut) public
        ClockAuction(_nftAddr, _cut) {}

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
    )
        public
        canBeStoredWith128Bits(_startingPrice)
        canBeStoredWith128Bits(_endingPrice)
        canBeStoredWith64Bits(_duration)
    {
        require(msg.sender == address(nonFungibleContract));
        _escrow(_seller, _tokenId);
        Auction memory auction = Auction(
            _seller,
            uint128(_startingPrice),
            uint128(_endingPrice),
            uint64(_duration),
            uint64(now)
        );
        _addAuction(_tokenId, auction);
    }

    /// @dev Updates lastSalePrice if seller is the nft contract
    /// Otherwise, works the same as default bid method.
    function bid(uint256 _tokenId)
        public
        payable
    {
        // _bid verifies token ID size
        address seller = tokenIdToAuction[_tokenId].seller;
        uint256 price = _bid(_tokenId, msg.value);
        _transfer(msg.sender, _tokenId);

        // If not a gen0 auction, exit
        if (seller == address(nonFungibleContract)) {
            // Track gen0 sale prices
            lastGen0SalePrices[gen0SaleCount % 4] = price;
            gen0SaleCount++;
        }
    }

    function averageGen0SalePrice() public view returns (uint256) {
        uint256 sum = 0;
        for (uint256 i = 0; i < 4; i++) {
            sum += lastGen0SalePrices[i];
        }
        return sum / 4;
    }

}


/// @title A facet of FighterCore that manages special access privileges.
contract FighterAccessControl {
    /// @dev Emited when contract is upgraded
    event ContractUpgrade(address newContract);

    address public ceoAddress;
    address public cfoAddress;
    address public cooAddress;

    // @dev Keeps track whether the contract is paused. When that is true, most actions are blocked
    bool public paused = false;

    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }

    modifier onlyCFO() {
        require(msg.sender == cfoAddress);
        _;
    }

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

    function setCEO(address _newCEO) public onlyCEO {
        require(_newCEO != address(0));

        ceoAddress = _newCEO;
    }

    function setCFO(address _newCFO) public onlyCEO {
        require(_newCFO != address(0));

        cfoAddress = _newCFO;
    }

    function setCOO(address _newCOO) public onlyCEO {
        require(_newCOO != address(0));

        cooAddress = _newCOO;
    }

    function withdrawBalance() external onlyCFO {
        cfoAddress.transfer(this.balance);
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

    function pause() public onlyCLevel whenNotPaused {
        paused = true;
    }

    function unpause() public onlyCEO whenPaused {
        // can&#39;t unpause if contract was upgraded
        paused = false;
    }
}


/// @title Base contract for CryptoFighters. Holds all common structs, events and base variables.
contract FighterBase is FighterAccessControl {
    /*** EVENTS ***/

    event FighterCreated(address indexed owner, uint256 fighterId, uint256 genes);

    /// @dev Transfer event as defined in current draft of ERC721. Emitted every time a fighter
    ///  ownership is assigned, including newly created fighters.
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /*** DATA TYPES ***/

    /// @dev The main Fighter struct. Every fighter in CryptoFighters is represented by a copy
    ///  of this structure.
    struct Fighter {
        // The Fighter&#39;s genetic code is packed into these 256-bits.
        // A fighter&#39;s genes never change.
        uint256 genes;

        // The minimum timestamp after which this fighter can win a prize fighter again
        uint64 prizeCooldownEndTime;

        // The minimum timestamp after which this fighter can engage in battle again
        uint64 battleCooldownEndTime;

        // battle experience
        uint32 experience;

        // Set to the index that represents the current cooldown duration for this Fighter.
        // Incremented by one for each successful prize won in battle
        uint16 prizeCooldownIndex;

        uint16 battlesFought;
        uint16 battlesWon;

        // The "generation number" of this fighter. Fighters minted by the CF contract
        // for sale are called "gen0" and have a generation number of 0.
        uint16 generation;

        uint8 dexterity;
        uint8 strength;
        uint8 vitality;
        uint8 luck;
    }

    /*** STORAGE ***/

    /// @dev An array containing the Fighter struct for all Fighters in existence. The ID
    ///  of each fighter is actually an index into this array. Note that ID 0 is a negafighter.
    ///  Fighter ID 0 is invalid.
    Fighter[] fighters;

    /// @dev A mapping from fighter IDs to the address that owns them. All fighters have
    ///  some valid owner address, even gen0 fighters are created with a non-zero owner.
    mapping (uint256 => address) public fighterIndexToOwner;

    // @dev A mapping from owner address to count of tokens that address owns.
    //  Used internally inside balanceOf() to resolve ownership count.
    mapping (address => uint256) ownershipTokenCount;

    /// @dev A mapping from FighterIDs to an address that has been approved to call
    ///  transferFrom(). A zero value means no approval is outstanding.
    mapping (uint256 => address) public fighterIndexToApproved;

    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        // since the number of fighters is capped to 2^32
        // there is no way to overflow this
        ownershipTokenCount[_to]++;
        fighterIndexToOwner[_tokenId] = _to;

        if (_from != address(0)) {
            ownershipTokenCount[_from]--;
            delete fighterIndexToApproved[_tokenId];
        }

        Transfer(_from, _to, _tokenId);
    }

    // Will generate both a FighterCreated event
    function _createFighter(
        uint16 _generation,
        uint256 _genes,
        uint8 _dexterity,
        uint8 _strength,
        uint8 _vitality,
        uint8 _luck,
        address _owner
    )
        internal
        returns (uint)
    {
        Fighter memory _fighter = Fighter({
            genes: _genes,
            prizeCooldownEndTime: 0,
            battleCooldownEndTime: 0,
            prizeCooldownIndex: 0,
            battlesFought: 0,
            battlesWon: 0,
            experience: 0,
            generation: _generation,
            dexterity: _dexterity,
            strength: _strength,
            vitality: _vitality,
            luck: _luck
        });
        uint256 newFighterId = fighters.push(_fighter) - 1;

        require(newFighterId <= 4294967295);

        FighterCreated(_owner, newFighterId, _fighter.genes);

        _transfer(0, _owner, newFighterId);

        return newFighterId;
    }
}


/// @title Interface for contracts conforming to ERC-721: Non-Fungible Tokens
contract ERC721 {
    function implementsERC721() public pure returns (bool);
    function totalSupply() public view returns (uint256 total);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) public view returns (address owner);
    function approve(address _to, uint256 _tokenId) public;
    function transferFrom(address _from, address _to, uint256 _tokenId) public;
    function transfer(address _to, uint256 _tokenId) public;
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    // Optional
    // function name() public view returns (string name);
    // function symbol() public view returns (string symbol);
    // function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256 tokenId);
    // function tokenMetadata(uint256 _tokenId) public view returns (string infoUrl);
}

/// @title The facet of the CryptoFighters core contract that manages ownership, ERC-721 (draft) compliant.
contract FighterOwnership is FighterBase, ERC721 {
    string public name = "CryptoFighters";
    string public symbol = "CF";

    function implementsERC721() public pure returns (bool)
    {
        return true;
    }

    /// @dev Checks if a given address is the current owner of a particular Fighter.
    /// @param _claimant the address we are validating against.
    /// @param _tokenId fighter id, only valid when > 0
    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return fighterIndexToOwner[_tokenId] == _claimant;
    }

    /// @dev Checks if a given address currently has transferApproval for a particular Fighter.
    /// @param _claimant the address we are confirming fighter is approved for.
    /// @param _tokenId fighter id, only valid when > 0
    function _approvedFor(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return fighterIndexToApproved[_tokenId] == _claimant;
    }

    /// @dev Marks an address as being approved for transferFrom(), overwriting any previous
    ///  approval. Setting _approved to address(0) clears all transfer approval.
    ///  NOTE: _approve() does NOT send the Approval event.
    function _approve(uint256 _tokenId, address _approved) internal {
        fighterIndexToApproved[_tokenId] = _approved;
    }

    /// @dev Transfers a fighter owned by this contract to the specified address.
    ///  Used to rescue lost fighters. (There is no "proper" flow where this contract
    ///  should be the owner of any Fighter. This function exists for us to reassign
    ///  the ownership of Fighters that users may have accidentally sent to our address.)
    /// @param _fighterId - ID of fighter
    /// @param _recipient - Address to send the fighter to
    function rescueLostFighter(uint256 _fighterId, address _recipient) public onlyCOO whenNotPaused {
        require(_owns(this, _fighterId));
        _transfer(this, _recipient, _fighterId);
    }

    /// @notice Returns the number of Fighters owned by a specific address.
    /// @param _owner The owner address to check.
    function balanceOf(address _owner) public view returns (uint256 count) {
        return ownershipTokenCount[_owner];
    }

    /// @notice Transfers a Fighter to another address. If transferring to a smart
    ///  contract be VERY CAREFUL to ensure that it is aware of ERC-721 (or
    ///  CryptoFighters specifically) or your Fighter may be lost forever. Seriously.
    /// @param _to The address of the recipient, can be a user or contract.
    /// @param _tokenId The ID of the Fighter to transfer.
    function transfer(
        address _to,
        uint256 _tokenId
    )
        public
        whenNotPaused
    {
        require(_to != address(0));
        require(_owns(msg.sender, _tokenId));

        _transfer(msg.sender, _to, _tokenId);
    }

    /// @notice Grant another address the right to transfer a specific Fighter via
    ///  transferFrom(). This is the preferred flow for transfering NFTs to contracts.
    /// @param _to The address to be granted transfer approval. Pass address(0) to
    ///  clear all approvals.
    /// @param _tokenId The ID of the Fighter that can be transferred if this call succeeds.
    function approve(
        address _to,
        uint256 _tokenId
    )
        public
        whenNotPaused
    {
        require(_owns(msg.sender, _tokenId));

        _approve(_tokenId, _to);

        Approval(msg.sender, _to, _tokenId);
    }

    /// @notice Transfer a Fighter owned by another address, for which the calling address
    ///  has previously been granted transfer approval by the owner.
    /// @param _from The address that owns the Fighter to be transfered.
    /// @param _to The address that should take ownership of the Fighter. Can be any address,
    ///  including the caller.
    /// @param _tokenId The ID of the Fighter to be transferred.
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    )
        public
        whenNotPaused
    {
        require(_approvedFor(msg.sender, _tokenId));
        require(_owns(_from, _tokenId));

        _transfer(_from, _to, _tokenId);
    }

    function totalSupply() public view returns (uint) {
        return fighters.length - 1;
    }

    function ownerOf(uint256 _tokenId)
        public
        view
        returns (address owner)
    {
        owner = fighterIndexToOwner[_tokenId];

        require(owner != address(0));
    }

    /// @notice Returns the nth Fighter assigned to an address, with n specified by the
    ///  _index argument.
    /// @param _owner The owner whose Fighters we are interested in.
    /// @param _index The zero-based index of the fighter within the owner&#39;s list of fighters.
    ///  Must be less than balanceOf(_owner).
    /// @dev This method MUST NEVER be called by smart contract code. It will almost
    ///  certainly blow past the block gas limit once there are a large number of
    ///  Fighters in existence. Exists only to allow off-chain queries of ownership.
    ///  Optional method for ERC-721.
    function tokensOfOwnerByIndex(address _owner, uint256 _index)
        external
        view
        returns (uint256 tokenId)
    {
        uint256 count = 0;
        for (uint256 i = 1; i <= totalSupply(); i++) {
            if (fighterIndexToOwner[i] == _owner) {
                if (count == _index) {
                    return i;
                } else {
                    count++;
                }
            }
        }
        revert();
    }
}


// this helps with battle functionality
// it gives the ability to an external contract to do the following:
// * create fighters as rewards
// * update fighter stats
// * update cooldown data for next prize/battle
contract FighterBattle is FighterOwnership {
    event FighterUpdated(uint256 fighterId);

    /// @dev The address of the sibling contract that handles battles
    address public battleContractAddress;

    /// @dev If set to false the `battleContractAddress` can never be updated again
    bool public battleContractAddressCanBeUpdated = true;

    function setBattleAddress(address _address) public onlyCEO {
        require(battleContractAddressCanBeUpdated == true);

        battleContractAddress = _address;
    }

    function foreverBlockBattleAddressUpdate() public onlyCEO {
        battleContractAddressCanBeUpdated = false;
    }

    modifier onlyBattleContract() {
        require(msg.sender == battleContractAddress);
        _;
    }

    function createPrizeFighter(
        uint16 _generation,
        uint256 _genes,
        uint8 _dexterity,
        uint8 _strength,
        uint8 _vitality,
        uint8 _luck,
        address _owner
    ) public onlyBattleContract {
        require(_generation > 0);

        _createFighter(_generation, _genes, _dexterity, _strength, _vitality, _luck, _owner);
    }

    // Update fighter functions

    // The logic for creating so many different functions is that it will be
    // easier to optimise for gas costs having all these available to us.
    // The contract deployment will be more expensive, but future costs can be
    // cheaper.
    function updateFighter(
        uint256 _fighterId,
        uint8 _dexterity,
        uint8 _strength,
        uint8 _vitality,
        uint8 _luck,
        uint32 _experience,
        uint64 _prizeCooldownEndTime,
        uint16 _prizeCooldownIndex,
        uint64 _battleCooldownEndTime,
        uint16 _battlesFought,
        uint16 _battlesWon
    )
        public onlyBattleContract
    {
        Fighter storage fighter = fighters[_fighterId];

        fighter.dexterity = _dexterity;
        fighter.strength = _strength;
        fighter.vitality = _vitality;
        fighter.luck = _luck;
        fighter.experience = _experience;

        fighter.prizeCooldownEndTime = _prizeCooldownEndTime;
        fighter.prizeCooldownIndex = _prizeCooldownIndex;
        fighter.battleCooldownEndTime = _battleCooldownEndTime;
        fighter.battlesFought = _battlesFought;
        fighter.battlesWon = _battlesWon;

        FighterUpdated(_fighterId);
    }

    function updateFighterStats(
        uint256 _fighterId,
        uint8 _dexterity,
        uint8 _strength,
        uint8 _vitality,
        uint8 _luck,
        uint32 _experience
    )
        public onlyBattleContract
    {
        Fighter storage fighter = fighters[_fighterId];

        fighter.dexterity = _dexterity;
        fighter.strength = _strength;
        fighter.vitality = _vitality;
        fighter.luck = _luck;
        fighter.experience = _experience;

        FighterUpdated(_fighterId);
    }

    function updateFighterBattleStats(
        uint256 _fighterId,
        uint64 _prizeCooldownEndTime,
        uint16 _prizeCooldownIndex,
        uint64 _battleCooldownEndTime,
        uint16 _battlesFought,
        uint16 _battlesWon
    )
        public onlyBattleContract
    {
        Fighter storage fighter = fighters[_fighterId];

        fighter.prizeCooldownEndTime = _prizeCooldownEndTime;
        fighter.prizeCooldownIndex = _prizeCooldownIndex;
        fighter.battleCooldownEndTime = _battleCooldownEndTime;
        fighter.battlesFought = _battlesFought;
        fighter.battlesWon = _battlesWon;

        FighterUpdated(_fighterId);
    }

    function updateDexterity(uint256 _fighterId, uint8 _dexterity) public onlyBattleContract {
        fighters[_fighterId].dexterity = _dexterity;
        FighterUpdated(_fighterId);
    }

    function updateStrength(uint256 _fighterId, uint8 _strength) public onlyBattleContract {
        fighters[_fighterId].strength = _strength;
        FighterUpdated(_fighterId);
    }

    function updateVitality(uint256 _fighterId, uint8 _vitality) public onlyBattleContract {
        fighters[_fighterId].vitality = _vitality;
        FighterUpdated(_fighterId);
    }

    function updateLuck(uint256 _fighterId, uint8 _luck) public onlyBattleContract {
        fighters[_fighterId].luck = _luck;
        FighterUpdated(_fighterId);
    }

    function updateExperience(uint256 _fighterId, uint32 _experience) public onlyBattleContract {
        fighters[_fighterId].experience = _experience;
        FighterUpdated(_fighterId);
    }
}

/// @title Handles creating auctions for sale of fighters.
///  This wrapper of ReverseAuction exists only so that users can create
///  auctions with only one transaction.
contract FighterAuction is FighterBattle {
    SaleClockAuction public saleAuction;

    function setSaleAuctionAddress(address _address) public onlyCEO {
        SaleClockAuction candidateContract = SaleClockAuction(_address);

        require(candidateContract.isSaleClockAuction());

        saleAuction = candidateContract;
    }

    function createSaleAuction(
        uint256 _fighterId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration
    )
        public
        whenNotPaused
    {
        // Auction contract checks input sizes
        // If fighter is already on any auction, this will throw
        // because it will be owned by the auction contract.
        require(_owns(msg.sender, _fighterId));
        _approve(_fighterId, saleAuction);
        // Sale auction throws if inputs are invalid and clears
        // transfer approval after escrowing the fighter.
        saleAuction.createAuction(
            _fighterId,
            _startingPrice,
            _endingPrice,
            _duration,
            msg.sender
        );
    }

    /// @dev Transfers the balance of the sale auction contract
    /// to the FighterCore contract. We use two-step withdrawal to
    /// prevent two transfer calls in the auction bid function.
    function withdrawAuctionBalances() external onlyCOO {
        saleAuction.withdrawBalance();
    }
}


/// @title all functions related to creating fighters
contract FighterMinting is FighterAuction {

    // Limits the number of fighters the contract owner can ever create.
    uint256 public promoCreationLimit = 5000;
    uint256 public gen0CreationLimit = 25000;

    // Constants for gen0 auctions.
    uint256 public gen0StartingPrice = 500 finney;
    uint256 public gen0EndingPrice = 10 finney;
    uint256 public gen0AuctionDuration = 1 days;

    // Counts the number of fighters the contract owner has created.
    uint256 public promoCreatedCount;
    uint256 public gen0CreatedCount;

    /// @dev we can create promo fighters, up to a limit
    function createPromoFighter(
        uint256 _genes,
        uint8 _dexterity,
        uint8 _strength,
        uint8 _vitality,
        uint8 _luck,
        address _owner
    ) public onlyCOO {
        if (_owner == address(0)) {
             _owner = cooAddress;
        }
        require(promoCreatedCount < promoCreationLimit);
        require(gen0CreatedCount < gen0CreationLimit);

        promoCreatedCount++;
        gen0CreatedCount++;

        _createFighter(0, _genes, _dexterity, _strength, _vitality, _luck, _owner);
    }

    /// @dev Creates a new gen0 fighter with the given genes and
    ///  creates an auction for it.
    function createGen0Auction(
        uint256 _genes,
        uint8 _dexterity,
        uint8 _strength,
        uint8 _vitality,
        uint8 _luck
    ) public onlyCOO {
        require(gen0CreatedCount < gen0CreationLimit);

        uint256 fighterId = _createFighter(0, _genes, _dexterity, _strength, _vitality, _luck, address(this));

        _approve(fighterId, saleAuction);

        saleAuction.createAuction(
            fighterId,
            _computeNextGen0Price(),
            gen0EndingPrice,
            gen0AuctionDuration,
            address(this)
        );

        gen0CreatedCount++;
    }

    /// @dev Computes the next gen0 auction starting price, given
    ///  the average of the past 4 prices + 50%.
    function _computeNextGen0Price() internal view returns (uint256) {
        uint256 avePrice = saleAuction.averageGen0SalePrice();

        // sanity check to ensure we don&#39;t overflow arithmetic (this big number is 2^128-1).
        require(avePrice < 340282366920938463463374607431768211455);

        uint256 nextPrice = avePrice + (avePrice / 2);

        // We never auction for less than starting price
        if (nextPrice < gen0StartingPrice) {
            nextPrice = gen0StartingPrice;
        }

        return nextPrice;
    }
}


/// @title CryptoFighters: Collectible, battlable fighters on the Ethereum blockchain.
/// @dev The main CryptoFighters contract
contract FighterCore is FighterMinting {

    // This is the main CryptoFighters contract. We have several seperately-instantiated sibling contracts
    // that handle auctions, battles and the creation of new fighters. By keeping
    // them in their own contracts, we can upgrade them without disrupting the main contract that tracks
    // fighter ownership.
    //
    //      - FighterBase: This is where we define the most fundamental code shared throughout the core
    //             functionality. This includes our main data storage, constants and data types, plus
    //             internal functions for managing these items.
    //
    //      - FighterAccessControl: This contract manages the various addresses and constraints for operations
    //             that can be executed only by specific roles. Namely CEO, CFO and COO.
    //
    //      - FighterOwnership: This provides the methods required for basic non-fungible token
    //             transactions, following the draft ERC-721 spec (https://github.com/ethereum/EIPs/issues/721).
    //
    //      - FighterBattle: This file contains the methods necessary to allow a separate contract to handle battles
    //             allowing it to reward new prize fighters as well as update fighter stats.
    //
    //      - FighterAuction: Here we have the public methods for auctioning or bidding on fighters.
    //             The actual auction functionality is handled in a sibling sales contract,
    //             while auction creation and bidding is mostly mediated through this facet of the core contract.
    //
    //      - FighterMinting: This final facet contains the functionality we use for creating new gen0 fighters.
    //             We can make up to 5000 "promo" fighters that can be given away, and all others can only be created and then immediately put up
    //             for auction via an algorithmically determined starting price. Regardless of how they
    //             are created, there is a hard limit of 25,000 gen0 fighters.

    // Set in case the core contract is broken and an upgrade is required
    address public newContractAddress;

    function FighterCore() public {
        paused = true;

        ceoAddress = msg.sender;
        cooAddress = msg.sender;
        cfoAddress = msg.sender;

        // start with the mythical fighter 0
        _createFighter(0, uint256(-1), uint8(-1), uint8(-1), uint8(-1), uint8(-1),  address(0));
    }

    /// @dev Used to mark the smart contract as upgraded, in case there is a serious
    ///  breaking bug. This method does nothing but keep track of the new contract and
    ///  emit a message indicating that the new address is set. It&#39;s up to clients of this
    ///  contract to update to the new contract address in that case. (This contract will
    ///  be paused indefinitely if such an upgrade takes place.)
    /// @param _v2Address new address
    function setNewAddress(address _v2Address) public onlyCEO whenPaused {
        newContractAddress = _v2Address;
        ContractUpgrade(_v2Address);
    }

    /// @notice No tipping!
    /// @dev Reject all Ether from being sent here, unless it&#39;s from one of the
    ///  two auction contracts. (Hopefully, we can prevent user accidents.)
    function() external payable {
        require(msg.sender == address(saleAuction));
    }

    /// @param _id The ID of the fighter of interest.
    function getFighter(uint256 _id)
        public
        view
        returns (
        uint256 prizeCooldownEndTime,
        uint256 battleCooldownEndTime,
        uint256 prizeCooldownIndex,
        uint256 battlesFought,
        uint256 battlesWon,
        uint256 generation,
        uint256 genes,
        uint256 dexterity,
        uint256 strength,
        uint256 vitality,
        uint256 luck,
        uint256 experience
    ) {
        Fighter storage fighter = fighters[_id];

        prizeCooldownEndTime = fighter.prizeCooldownEndTime;
        battleCooldownEndTime = fighter.battleCooldownEndTime;
        prizeCooldownIndex = fighter.prizeCooldownIndex;
        battlesFought = fighter.battlesFought;
        battlesWon = fighter.battlesWon;
        generation = fighter.generation;
        genes = fighter.genes;
        dexterity = fighter.dexterity;
        strength = fighter.strength;
        vitality = fighter.vitality;
        luck = fighter.luck;
        experience = fighter.experience;
    }

    /// @dev Override unpause so it requires all external contract addresses
    ///  to be set before contract can be unpaused. Also, we can&#39;t have
    ///  newContractAddress set either, because then the contract was upgraded.
    function unpause() public onlyCEO whenPaused {
        require(saleAuction != address(0));
        require(newContractAddress == address(0));

        super.unpause();
    }
}