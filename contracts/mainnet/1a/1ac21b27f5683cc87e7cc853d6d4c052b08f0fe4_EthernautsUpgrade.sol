pragma solidity ^0.4.19;

/// @title Interface for contracts conforming to ERC-721: Non-Fungible Tokens
/// @author Ethernauts
contract ERC721 {
    // Required methods
    function totalSupply() public view returns (uint256 total);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) external view returns (address owner);
    function approve(address _to, uint256 _tokenId) external;
    function transfer(address _to, uint256 _tokenId) external;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
    function takeOwnership(uint256 _tokenId) public;
    function implementsERC721() public pure returns (bool);

    // Events
    event Transfer(address from, address to, uint256 tokenId);
    event Approval(address owner, address approved, uint256 tokenId);

    // Optional
    // function name() public view returns (string name);
    // function symbol() public view returns (string symbol);
    // function tokensOfOwner(address _owner) external view returns (uint256[] tokenIds);
    // function tokenMetadata(uint256 _tokenId, string _preferredTransport) public view returns (string infoUrl);

    // ERC-165 Compatibility (https://github.com/ethereum/EIPs/issues/165)
    function supportsInterface(bytes4 _interfaceID) external view returns (bool);
}
// Copied from: https://etherscan.io/address/0x06012c8cf97bead5deae237070f9587f8e7a266d#code


// Copied from: https://etherscan.io/address/0x06012c8cf97bead5deae237070f9587f8e7a266d#code





// Extend this library for child contracts
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

    /**
    * @dev Compara two numbers, and return the bigger one.
    */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a > b) {
            return a;
        } else {
            return b;
        }
    }

    /**
    * @dev Compara two numbers, and return the bigger one.
    */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a < b) {
            return a;
        } else {
            return b;
        }
    }


}

/// @title Auction Core
/// @dev Contains models, variables, and internal methods for the auction.
/// @notice We omit a fallback function to prevent accidental sends to this contract.
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

    /// @dev Returns true if the claimant owns the token.
    /// @param _claimant - Address claiming to own the token.
    /// @param _tokenId - ID of token whose ownership to verify.
    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return (nonFungibleContract.ownerOf(_tokenId) == _claimant);
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

        // Check that the bid is greater than or equal to the current price
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
            // Calculate the auctioneer&#39;s cut.
            // (NOTE: _computeCut() is guaranteed to return a
            // value <= price, so this subtraction can&#39;t go negative.)
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

        // Calculate any excess funds included with the bid. If the excess
        // is anything worth worrying about, transfer it back to bidder.
        // NOTE: We checked above that the bid amount is greater than or
        // equal to the price so this cannot underflow.
        uint256 bidExcess = _bidAmount - price;

        // Return the funds. Similar to the previous transfer, this is
        // not susceptible to a re-entry attack because the auction is
        // removed before any transfers occur.
        msg.sender.transfer(bidExcess);

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
        return SafeMath.mul(_price, SafeMath.div(ownerCut,10000));
    }

}




/// @dev Base contract for all Ethernauts contracts holding global constants and functions.
contract EthernautsBase {

    /*** CONSTANTS USED ACROSS CONTRACTS ***/

    /// @dev Used by all contracts that interfaces with Ethernauts
    ///      The ERC-165 interface signature for ERC-721.
    ///  Ref: https://github.com/ethereum/EIPs/issues/165
    ///  Ref: https://github.com/ethereum/EIPs/issues/721
    bytes4 constant InterfaceSignature_ERC721 =
    bytes4(keccak256(&#39;name()&#39;)) ^
    bytes4(keccak256(&#39;symbol()&#39;)) ^
    bytes4(keccak256(&#39;totalSupply()&#39;)) ^
    bytes4(keccak256(&#39;balanceOf(address)&#39;)) ^
    bytes4(keccak256(&#39;ownerOf(uint256)&#39;)) ^
    bytes4(keccak256(&#39;approve(address,uint256)&#39;)) ^
    bytes4(keccak256(&#39;transfer(address,uint256)&#39;)) ^
    bytes4(keccak256(&#39;transferFrom(address,address,uint256)&#39;)) ^
    bytes4(keccak256(&#39;takeOwnership(uint256)&#39;)) ^
    bytes4(keccak256(&#39;tokensOfOwner(address)&#39;)) ^
    bytes4(keccak256(&#39;tokenMetadata(uint256,string)&#39;));

    /// @dev due solidity limitation we cannot return dynamic array from methods
    /// so it creates incompability between functions across different contracts
    uint8 public constant STATS_SIZE = 10;
    uint8 public constant SHIP_SLOTS = 5;

    // Possible state of any asset
    enum AssetState { Available, UpForLease, Used }

    // Possible state of any asset
    // NotValid is to avoid 0 in places where category must be bigger than zero
    enum AssetCategory { NotValid, Sector, Manufacturer, Ship, Object, Factory, CrewMember }

    /// @dev Sector stats
    enum ShipStats {Level, Attack, Defense, Speed, Range, Luck}
    /// @notice Possible attributes for each asset
    /// 00000001 - Seeded - Offered to the economy by us, the developers. Potentially at regular intervals.
    /// 00000010 - Producible - Product of a factory and/or factory contract.
    /// 00000100 - Explorable- Product of exploration.
    /// 00001000 - Leasable - Can be rented to other users and will return to the original owner once the action is complete.
    /// 00010000 - Permanent - Cannot be removed, always owned by a user.
    /// 00100000 - Consumable - Destroyed after N exploration expeditions.
    /// 01000000 - Tradable - Buyable and sellable on the market.
    /// 10000000 - Hot Potato - Automatically gets put up for sale after acquiring.
    bytes2 public ATTR_SEEDED     = bytes2(2**0);
    bytes2 public ATTR_PRODUCIBLE = bytes2(2**1);
    bytes2 public ATTR_EXPLORABLE = bytes2(2**2);
    bytes2 public ATTR_LEASABLE   = bytes2(2**3);
    bytes2 public ATTR_PERMANENT  = bytes2(2**4);
    bytes2 public ATTR_CONSUMABLE = bytes2(2**5);
    bytes2 public ATTR_TRADABLE   = bytes2(2**6);
    bytes2 public ATTR_GOLDENGOOSE = bytes2(2**7);
}

/// @title Inspired by https://github.com/axiomzen/cryptokitties-bounty/blob/master/contracts/KittyAccessControl.sol
/// @notice This contract manages the various addresses and constraints for operations
//          that can be executed only by specific roles. Namely CEO and CTO. it also includes pausable pattern.
contract EthernautsAccessControl is EthernautsBase {

    // This facet controls access control for Ethernauts.
    // All roles have same responsibilities and rights, but there is slight differences between them:
    //
    //     - The CEO: The CEO can reassign other roles and only role that can unpause the smart contract.
    //       It is initially set to the address that created the smart contract.
    //
    //     - The CTO: The CTO can change contract address, oracle address and plan for upgrades.
    //
    //     - The COO: The COO can change contract address and add create assets.
    //
    /// @dev Emited when contract is upgraded - See README.md for updgrade plan
    /// @param newContract address pointing to new contract
    event ContractUpgrade(address newContract);

    // The addresses of the accounts (or contracts) that can execute actions within each roles.
    address public ceoAddress;
    address public ctoAddress;
    address public cooAddress;
    address public oracleAddress;

    // @dev Keeps track whether the contract is paused. When that is true, most actions are blocked
    bool public paused = false;

    /// @dev Access modifier for CEO-only functionality
    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }

    /// @dev Access modifier for CTO-only functionality
    modifier onlyCTO() {
        require(msg.sender == ctoAddress);
        _;
    }

    /// @dev Access modifier for CTO-only functionality
    modifier onlyOracle() {
        require(msg.sender == oracleAddress);
        _;
    }

    modifier onlyCLevel() {
        require(
            msg.sender == ceoAddress ||
            msg.sender == ctoAddress ||
            msg.sender == cooAddress
        );
        _;
    }

    /// @dev Assigns a new address to act as the CEO. Only available to the current CEO.
    /// @param _newCEO The address of the new CEO
    function setCEO(address _newCEO) external onlyCEO {
        require(_newCEO != address(0));

        ceoAddress = _newCEO;
    }

    /// @dev Assigns a new address to act as the CTO. Only available to the current CTO or CEO.
    /// @param _newCTO The address of the new CTO
    function setCTO(address _newCTO) external {
        require(
            msg.sender == ceoAddress ||
            msg.sender == ctoAddress
        );
        require(_newCTO != address(0));

        ctoAddress = _newCTO;
    }

    /// @dev Assigns a new address to act as the COO. Only available to the current COO or CEO.
    /// @param _newCOO The address of the new COO
    function setCOO(address _newCOO) external {
        require(
            msg.sender == ceoAddress ||
            msg.sender == cooAddress
        );
        require(_newCOO != address(0));

        cooAddress = _newCOO;
    }

    /// @dev Assigns a new address to act as oracle.
    /// @param _newOracle The address of oracle
    function setOracle(address _newOracle) external {
        require(msg.sender == ctoAddress);
        require(_newOracle != address(0));

        oracleAddress = _newOracle;
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
    ///  one reason we may pause the contract is when CTO account is compromised.
    /// @notice This is public rather than external so it can be called by
    ///  derived contracts.
    function unpause() public onlyCEO whenPaused {
        // can&#39;t unpause if contract was upgraded
        paused = false;
    }

}









/// @title Storage contract for Ethernauts Data. Common structs and constants.
/// @notice This is our main data storage, constants and data types, plus
//          internal functions for managing the assets. It is isolated and only interface with
//          a list of granted contracts defined by CTO
/// @author Ethernauts - Fernando Pauer
contract EthernautsStorage is EthernautsAccessControl {

    function EthernautsStorage() public {
        // the creator of the contract is the initial CEO
        ceoAddress = msg.sender;

        // the creator of the contract is the initial CTO as well
        ctoAddress = msg.sender;

        // the creator of the contract is the initial CTO as well
        cooAddress = msg.sender;

        // the creator of the contract is the initial Oracle as well
        oracleAddress = msg.sender;
    }

    /// @notice No tipping!
    /// @dev Reject all Ether from being sent here. Hopefully, we can prevent user accidents.
    function() external payable {
        require(msg.sender == address(this));
    }

    /*** Mapping for Contracts with granted permission ***/
    mapping (address => bool) public contractsGrantedAccess;

    /// @dev grant access for a contract to interact with this contract.
    /// @param _v2Address The contract address to grant access
    function grantAccess(address _v2Address) public onlyCTO {
        // See README.md for updgrade plan
        contractsGrantedAccess[_v2Address] = true;
    }

    /// @dev remove access from a contract to interact with this contract.
    /// @param _v2Address The contract address to be removed
    function removeAccess(address _v2Address) public onlyCTO {
        // See README.md for updgrade plan
        delete contractsGrantedAccess[_v2Address];
    }

    /// @dev Only allow permitted contracts to interact with this contract
    modifier onlyGrantedContracts() {
        require(contractsGrantedAccess[msg.sender] == true);
        _;
    }

    modifier validAsset(uint256 _tokenId) {
        require(assets[_tokenId].ID > 0);
        _;
    }
    /*** DATA TYPES ***/

    /// @dev The main Ethernauts asset struct. Every asset in Ethernauts is represented by a copy
    ///  of this structure. Note that the order of the members in this structure
    ///  is important because of the byte-packing rules used by Ethereum.
    ///  Ref: http://solidity.readthedocs.io/en/develop/miscellaneous.html
    struct Asset {

        // Asset ID is a identifier for look and feel in frontend
        uint16 ID;

        // Category = Sectors, Manufacturers, Ships, Objects (Upgrades/Misc), Factories and CrewMembers
        uint8 category;

        // The State of an asset: Available, On sale, Up for lease, Cooldown, Exploring
        uint8 state;

        // Attributes
        // byte pos - Definition
        // 00000001 - Seeded - Offered to the economy by us, the developers. Potentially at regular intervals.
        // 00000010 - Producible - Product of a factory and/or factory contract.
        // 00000100 - Explorable- Product of exploration.
        // 00001000 - Leasable - Can be rented to other users and will return to the original owner once the action is complete.
        // 00010000 - Permanent - Cannot be removed, always owned by a user.
        // 00100000 - Consumable - Destroyed after N exploration expeditions.
        // 01000000 - Tradable - Buyable and sellable on the market.
        // 10000000 - Hot Potato - Automatically gets put up for sale after acquiring.
        bytes2 attributes;

        // The timestamp from the block when this asset was created.
        uint64 createdAt;

        // The minimum timestamp after which this asset can engage in exploring activities again.
        uint64 cooldownEndBlock;

        // The Asset&#39;s stats can be upgraded or changed based on exploration conditions.
        // It will be defined per child contract, but all stats have a range from 0 to 255
        // Examples
        // 0 = Ship Level
        // 1 = Ship Attack
        uint8[STATS_SIZE] stats;

        // Set to the cooldown time that represents exploration duration for this asset.
        // Defined by a successful exploration action, regardless of whether this asset is acting as ship or a part.
        uint256 cooldown;

        // a reference to a super asset that manufactured the asset
        uint256 builtBy;
    }

    /*** CONSTANTS ***/

    // @dev Sanity check that allows us to ensure that we are pointing to the
    //  right storage contract in our EthernautsLogic(address _CStorageAddress) call.
    bool public isEthernautsStorage = true;

    /*** STORAGE ***/

    /// @dev An array containing the Asset struct for all assets in existence. The Asset UniqueId
    ///  of each asset is actually an index into this array.
    Asset[] public assets;

    /// @dev A mapping from Asset UniqueIDs to the price of the token.
    /// stored outside Asset Struct to save gas, because price can change frequently
    mapping (uint256 => uint256) internal assetIndexToPrice;

    /// @dev A mapping from asset UniqueIDs to the address that owns them. All assets have some valid owner address.
    mapping (uint256 => address) internal assetIndexToOwner;

    // @dev A mapping from owner address to count of tokens that address owns.
    //  Used internally inside balanceOf() to resolve ownership count.
    mapping (address => uint256) internal ownershipTokenCount;

    /// @dev A mapping from AssetUniqueIDs to an address that has been approved to call
    ///  transferFrom(). Each Asset can only have one approved address for transfer
    ///  at any time. A zero value means no approval is outstanding.
    mapping (uint256 => address) internal assetIndexToApproved;


    /*** SETTERS ***/

    /// @dev set new asset price
    /// @param _tokenId  asset UniqueId
    /// @param _price    asset price
    function setPrice(uint256 _tokenId, uint256 _price) public onlyGrantedContracts {
        assetIndexToPrice[_tokenId] = _price;
    }

    /// @dev Mark transfer as approved
    /// @param _tokenId  asset UniqueId
    /// @param _approved address approved
    function approve(uint256 _tokenId, address _approved) public onlyGrantedContracts {
        assetIndexToApproved[_tokenId] = _approved;
    }

    /// @dev Assigns ownership of a specific Asset to an address.
    /// @param _from    current owner address
    /// @param _to      new owner address
    /// @param _tokenId asset UniqueId
    function transfer(address _from, address _to, uint256 _tokenId) public onlyGrantedContracts {
        // Since the number of assets is capped to 2^32 we can&#39;t overflow this
        ownershipTokenCount[_to]++;
        // transfer ownership
        assetIndexToOwner[_tokenId] = _to;
        // When creating new assets _from is 0x0, but we can&#39;t account that address.
        if (_from != address(0)) {
            ownershipTokenCount[_from]--;
            // clear any previously approved ownership exchange
            delete assetIndexToApproved[_tokenId];
        }
    }

    /// @dev A public method that creates a new asset and stores it. This
    ///  method does basic checking and should only be called from other contract when the
    ///  input data is known to be valid. Will NOT generate any event it is delegate to business logic contracts.
    /// @param _creatorTokenID The asset who is father of this asset
    /// @param _owner First owner of this asset
    /// @param _price asset price
    /// @param _ID asset ID
    /// @param _category see Asset Struct description
    /// @param _state see Asset Struct description
    /// @param _attributes see Asset Struct description
    /// @param _stats see Asset Struct description
    function createAsset(
        uint256 _creatorTokenID,
        address _owner,
        uint256 _price,
        uint16 _ID,
        uint8 _category,
        uint8 _state,
        uint8 _attributes,
        uint8[STATS_SIZE] _stats,
        uint256 _cooldown,
        uint64 _cooldownEndBlock
    )
    public onlyGrantedContracts
    returns (uint256)
    {
        // Ensure our data structures are always valid.
        require(_ID > 0);
        require(_category > 0);
        require(_attributes != 0x0);
        require(_stats.length > 0);

        Asset memory asset = Asset({
            ID: _ID,
            category: _category,
            builtBy: _creatorTokenID,
            attributes: bytes2(_attributes),
            stats: _stats,
            state: _state,
            createdAt: uint64(now),
            cooldownEndBlock: _cooldownEndBlock,
            cooldown: _cooldown
            });

        uint256 newAssetUniqueId = assets.push(asset) - 1;

        // Check it reached 4 billion assets but let&#39;s just be 100% sure.
        require(newAssetUniqueId == uint256(uint32(newAssetUniqueId)));

        // store price
        assetIndexToPrice[newAssetUniqueId] = _price;

        // This will assign ownership
        transfer(address(0), _owner, newAssetUniqueId);

        return newAssetUniqueId;
    }

    /// @dev A public method that edit asset in case of any mistake is done during process of creation by the developer. This
    /// This method doesn&#39;t do any checking and should only be called when the
    ///  input data is known to be valid.
    /// @param _tokenId The token ID
    /// @param _creatorTokenID The asset that create that token
    /// @param _price asset price
    /// @param _ID asset ID
    /// @param _category see Asset Struct description
    /// @param _state see Asset Struct description
    /// @param _attributes see Asset Struct description
    /// @param _stats see Asset Struct description
    /// @param _cooldown asset cooldown index
    function editAsset(
        uint256 _tokenId,
        uint256 _creatorTokenID,
        uint256 _price,
        uint16 _ID,
        uint8 _category,
        uint8 _state,
        uint8 _attributes,
        uint8[STATS_SIZE] _stats,
        uint16 _cooldown
    )
    external validAsset(_tokenId) onlyCLevel
    returns (uint256)
    {
        // Ensure our data structures are always valid.
        require(_ID > 0);
        require(_category > 0);
        require(_attributes != 0x0);
        require(_stats.length > 0);

        // store price
        assetIndexToPrice[_tokenId] = _price;

        Asset storage asset = assets[_tokenId];
        asset.ID = _ID;
        asset.category = _category;
        asset.builtBy = _creatorTokenID;
        asset.attributes = bytes2(_attributes);
        asset.stats = _stats;
        asset.state = _state;
        asset.cooldown = _cooldown;
    }

    /// @dev Update only stats
    /// @param _tokenId asset UniqueId
    /// @param _stats asset state, see Asset Struct description
    function updateStats(uint256 _tokenId, uint8[STATS_SIZE] _stats) public validAsset(_tokenId) onlyGrantedContracts {
        assets[_tokenId].stats = _stats;
    }

    /// @dev Update only asset state
    /// @param _tokenId asset UniqueId
    /// @param _state asset state, see Asset Struct description
    function updateState(uint256 _tokenId, uint8 _state) public validAsset(_tokenId) onlyGrantedContracts {
        assets[_tokenId].state = _state;
    }

    /// @dev Update Cooldown for a single asset
    /// @param _tokenId asset UniqueId
    /// @param _cooldown asset state, see Asset Struct description
    function setAssetCooldown(uint256 _tokenId, uint256 _cooldown, uint64 _cooldownEndBlock)
    public validAsset(_tokenId) onlyGrantedContracts {
        assets[_tokenId].cooldown = _cooldown;
        assets[_tokenId].cooldownEndBlock = _cooldownEndBlock;
    }

    /*** GETTERS ***/

    /// @notice Returns only stats data about a specific asset.
    /// @dev it is necessary due solidity compiler limitations
    ///      when we have large qty of parameters it throws StackTooDeepException
    /// @param _tokenId The UniqueId of the asset of interest.
    function getStats(uint256 _tokenId) public view returns (uint8[STATS_SIZE]) {
        return assets[_tokenId].stats;
    }

    /// @dev return current price of an asset
    /// @param _tokenId asset UniqueId
    function priceOf(uint256 _tokenId) public view returns (uint256 price) {
        return assetIndexToPrice[_tokenId];
    }

    /// @notice Check if asset has all attributes passed by parameter
    /// @param _tokenId The UniqueId of the asset of interest.
    /// @param _attributes see Asset Struct description
    function hasAllAttrs(uint256 _tokenId, bytes2 _attributes) public view returns (bool) {
        return assets[_tokenId].attributes & _attributes == _attributes;
    }

    /// @notice Check if asset has any attribute passed by parameter
    /// @param _tokenId The UniqueId of the asset of interest.
    /// @param _attributes see Asset Struct description
    function hasAnyAttrs(uint256 _tokenId, bytes2 _attributes) public view returns (bool) {
        return assets[_tokenId].attributes & _attributes != 0x0;
    }

    /// @notice Check if asset is in the state passed by parameter
    /// @param _tokenId The UniqueId of the asset of interest.
    /// @param _category see AssetCategory in EthernautsBase for possible states
    function isCategory(uint256 _tokenId, uint8 _category) public view returns (bool) {
        return assets[_tokenId].category == _category;
    }

    /// @notice Check if asset is in the state passed by parameter
    /// @param _tokenId The UniqueId of the asset of interest.
    /// @param _state see enum AssetState in EthernautsBase for possible states
    function isState(uint256 _tokenId, uint8 _state) public view returns (bool) {
        return assets[_tokenId].state == _state;
    }

    /// @notice Returns owner of a given Asset(Token).
    /// @dev Required for ERC-721 compliance.
    /// @param _tokenId asset UniqueId
    function ownerOf(uint256 _tokenId) public view returns (address owner)
    {
        return assetIndexToOwner[_tokenId];
    }

    /// @dev Required for ERC-721 compliance
    /// @notice Returns the number of Assets owned by a specific address.
    /// @param _owner The owner address to check.
    function balanceOf(address _owner) public view returns (uint256 count) {
        return ownershipTokenCount[_owner];
    }

    /// @dev Checks if a given address currently has transferApproval for a particular Asset.
    /// @param _tokenId asset UniqueId
    function approvedFor(uint256 _tokenId) public view onlyGrantedContracts returns (address) {
        return assetIndexToApproved[_tokenId];
    }

    /// @notice Returns the total number of Assets currently in existence.
    /// @dev Required for ERC-721 compliance.
    function totalSupply() public view returns (uint256) {
        return assets.length;
    }

    /// @notice List all existing tokens. It can be filtered by attributes or assets with owner
    /// @param _owner filter all assets by owner
    function getTokenList(address _owner, uint8 _withAttributes, uint256 start, uint256 count) external view returns(
        uint256[6][]
    ) {
        uint256 totalAssets = assets.length;

        if (totalAssets == 0) {
            // Return an empty array
            return new uint256[6][](0);
        } else {
            uint256[6][] memory result = new uint256[6][](totalAssets > count ? count : totalAssets);
            uint256 resultIndex = 0;
            bytes2 hasAttributes  = bytes2(_withAttributes);
            Asset memory asset;

            for (uint256 tokenId = start; tokenId < totalAssets && resultIndex < count; tokenId++) {
                asset = assets[tokenId];
                if (
                    (asset.state != uint8(AssetState.Used)) &&
                    (assetIndexToOwner[tokenId] == _owner || _owner == address(0)) &&
                    (asset.attributes & hasAttributes == hasAttributes)
                ) {
                    result[resultIndex][0] = tokenId;
                    result[resultIndex][1] = asset.ID;
                    result[resultIndex][2] = asset.category;
                    result[resultIndex][3] = uint256(asset.attributes);
                    result[resultIndex][4] = asset.cooldown;
                    result[resultIndex][5] = assetIndexToPrice[tokenId];
                    resultIndex++;
                }
            }

            return result;
        }
    }
}

/// @title The facet of the Ethernauts contract that manages ownership, ERC-721 compliant.
/// @notice This provides the methods required for basic non-fungible token
//          transactions, following the draft ERC-721 spec (https://github.com/ethereum/EIPs/issues/721).
//          It interfaces with EthernautsStorage provinding basic functions as create and list, also holds
//          reference to logic contracts as Auction, Explore and so on
/// @author Ethernatus - Fernando Pauer
/// @dev Ref: https://github.com/ethereum/EIPs/issues/721
contract EthernautsOwnership is EthernautsAccessControl, ERC721 {

    /// @dev Contract holding only data.
    EthernautsStorage public ethernautsStorage;

    /*** CONSTANTS ***/
    /// @notice Name and symbol of the non fungible token, as defined in ERC721.
    string public constant name = "Ethernauts";
    string public constant symbol = "ETNT";

    /********* ERC 721 - COMPLIANCE CONSTANTS AND FUNCTIONS ***************/
    /**********************************************************************/

    bytes4 constant InterfaceSignature_ERC165 = bytes4(keccak256(&#39;supportsInterface(bytes4)&#39;));

    /*** EVENTS ***/

    // Events as per ERC-721
    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed owner, address indexed approved, uint256 tokens);

    /// @dev When a new asset is create it emits build event
    /// @param owner The address of asset owner
    /// @param tokenId Asset UniqueID
    /// @param assetId ID that defines asset look and feel
    /// @param price asset price
    event Build(address owner, uint256 tokenId, uint16 assetId, uint256 price);

    function implementsERC721() public pure returns (bool) {
        return true;
    }

    /// @notice Introspection interface as per ERC-165 (https://github.com/ethereum/EIPs/issues/165).
    ///  Returns true for any standardized interfaces implemented by this contract. ERC-165 and ERC-721.
    /// @param _interfaceID interface signature ID
    function supportsInterface(bytes4 _interfaceID) external view returns (bool)
    {
        return ((_interfaceID == InterfaceSignature_ERC165) || (_interfaceID == InterfaceSignature_ERC721));
    }

    /// @dev Checks if a given address is the current owner of a particular Asset.
    /// @param _claimant the address we are validating against.
    /// @param _tokenId asset UniqueId, only valid when > 0
    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return ethernautsStorage.ownerOf(_tokenId) == _claimant;
    }

    /// @dev Checks if a given address currently has transferApproval for a particular Asset.
    /// @param _claimant the address we are confirming asset is approved for.
    /// @param _tokenId asset UniqueId, only valid when > 0
    function _approvedFor(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return ethernautsStorage.approvedFor(_tokenId) == _claimant;
    }

    /// @dev Marks an address as being approved for transferFrom(), overwriting any previous
    ///  approval. Setting _approved to address(0) clears all transfer approval.
    ///  NOTE: _approve() does NOT send the Approval event. This is intentional because
    ///  _approve() and transferFrom() are used together for putting Assets on auction, and
    ///  there is no value in spamming the log with Approval events in that case.
    function _approve(uint256 _tokenId, address _approved) internal {
        ethernautsStorage.approve(_tokenId, _approved);
    }

    /// @notice Returns the number of Assets owned by a specific address.
    /// @param _owner The owner address to check.
    /// @dev Required for ERC-721 compliance
    function balanceOf(address _owner) public view returns (uint256 count) {
        return ethernautsStorage.balanceOf(_owner);
    }

    /// @dev Required for ERC-721 compliance.
    /// @notice Transfers a Asset to another address. If transferring to a smart
    ///  contract be VERY CAREFUL to ensure that it is aware of ERC-721 (or
    ///  Ethernauts specifically) or your Asset may be lost forever. Seriously.
    /// @param _to The address of the recipient, can be a user or contract.
    /// @param _tokenId The ID of the Asset to transfer.
    function transfer(
        address _to,
        uint256 _tokenId
    )
    external
    whenNotPaused
    {
        // Safety check to prevent against an unexpected 0x0 default.
        require(_to != address(0));
        // Disallow transfers to this contract to prevent accidental misuse.
        // The contract should never own any assets
        // (except very briefly after it is created and before it goes on auction).
        require(_to != address(this));
        // Disallow transfers to the storage contract to prevent accidental
        // misuse. Auction or Upgrade contracts should only take ownership of assets
        // through the allow + transferFrom flow.
        require(_to != address(ethernautsStorage));

        // You can only send your own asset.
        require(_owns(msg.sender, _tokenId));

        // Reassign ownership, clear pending approvals, emit Transfer event.
        ethernautsStorage.transfer(msg.sender, _to, _tokenId);
    }

    /// @dev Required for ERC-721 compliance.
    /// @notice Grant another address the right to transfer a specific Asset via
    ///  transferFrom(). This is the preferred flow for transfering NFTs to contracts.
    /// @param _to The address to be granted transfer approval. Pass address(0) to
    ///  clear all approvals.
    /// @param _tokenId The ID of the Asset that can be transferred if this call succeeds.
    function approve(
        address _to,
        uint256 _tokenId
    )
    external
    whenNotPaused
    {
        // Only an owner can grant transfer approval.
        require(_owns(msg.sender, _tokenId));

        // Register the approval (replacing any previous approval).
        _approve(_tokenId, _to);

        // Emit approval event.
        Approval(msg.sender, _to, _tokenId);
    }


    /// @notice Transfer a Asset owned by another address, for which the calling address
    ///  has previously been granted transfer approval by the owner.
    /// @param _from The address that owns the Asset to be transferred.
    /// @param _to The address that should take ownership of the Asset. Can be any address,
    ///  including the caller.
    /// @param _tokenId The ID of the Asset to be transferred.
    function _transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    )
    internal
    {
        // Safety check to prevent against an unexpected 0x0 default.
        require(_to != address(0));
        // Disallow transfers to this contract to prevent accidental misuse.
        // The contract should never own any assets (except for used assets).
        require(_owns(_from, _tokenId));
        // Check for approval and valid ownership
        require(_approvedFor(_to, _tokenId));

        // Reassign ownership (also clears pending approvals and emits Transfer event).
        ethernautsStorage.transfer(_from, _to, _tokenId);
    }

    /// @dev Required for ERC-721 compliance.
    /// @notice Transfer a Asset owned by another address, for which the calling address
    ///  has previously been granted transfer approval by the owner.
    /// @param _from The address that owns the Asset to be transfered.
    /// @param _to The address that should take ownership of the Asset. Can be any address,
    ///  including the caller.
    /// @param _tokenId The ID of the Asset to be transferred.
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    )
    external
    whenNotPaused
    {
        _transferFrom(_from, _to, _tokenId);
    }

    /// @dev Required for ERC-721 compliance.
    /// @notice Allow pre-approved user to take ownership of a token
    /// @param _tokenId The ID of the Token that can be transferred if this call succeeds.
    function takeOwnership(uint256 _tokenId) public {
        address _from = ethernautsStorage.ownerOf(_tokenId);

        // Safety check to prevent against an unexpected 0x0 default.
        require(_from != address(0));
        _transferFrom(_from, msg.sender, _tokenId);
    }

    /// @notice Returns the total number of Assets currently in existence.
    /// @dev Required for ERC-721 compliance.
    function totalSupply() public view returns (uint256) {
        return ethernautsStorage.totalSupply();
    }

    /// @notice Returns owner of a given Asset(Token).
    /// @param _tokenId Token ID to get owner.
    /// @dev Required for ERC-721 compliance.
    function ownerOf(uint256 _tokenId)
    external
    view
    returns (address owner)
    {
        owner = ethernautsStorage.ownerOf(_tokenId);

        require(owner != address(0));
    }

    /// @dev Creates a new Asset with the given fields. ONly available for C Levels
    /// @param _creatorTokenID The asset who is father of this asset
    /// @param _price asset price
    /// @param _assetID asset ID
    /// @param _category see Asset Struct description
    /// @param _attributes see Asset Struct description
    /// @param _stats see Asset Struct description
    function createNewAsset(
        uint256 _creatorTokenID,
        uint256 _price,
        uint16 _assetID,
        uint8 _category,
        uint8 _attributes,
        uint8[STATS_SIZE] _stats
    )
    external onlyCLevel
    returns (uint256)
    {
        // owner must be sender
        require(msg.sender != address(0));

        uint256 tokenID = ethernautsStorage.createAsset(
            _creatorTokenID,
            msg.sender,
            _price,
            _assetID,
            _category,
            uint8(AssetState.Available),
            _attributes,
            _stats,
            0,
            0
        );

        // emit the build event
        Build(
            msg.sender,
            tokenID,
            _assetID,
            _price
        );

        return tokenID;
    }

    /// @notice verify if token is in exploration time
    /// @param _tokenId The Token ID that can be upgraded
    function isExploring(uint256 _tokenId) public view returns (bool) {
        uint256 cooldown;
        uint64 cooldownEndBlock;
        (,,,,,cooldownEndBlock, cooldown,) = ethernautsStorage.assets(_tokenId);
        return (cooldown > now) || (cooldownEndBlock > uint64(block.number));
    }
}


/// @title The facet of the Ethernauts Logic contract handle all common code for logic/business contracts
/// @author Ethernatus - Fernando Pauer
contract EthernautsLogic is EthernautsOwnership {

    // Set in case the logic contract is broken and an upgrade is required
    address public newContractAddress;

    /// @dev Constructor
    function EthernautsLogic() public {
        // the creator of the contract is the initial CEO, COO, CTO
        ceoAddress = msg.sender;
        ctoAddress = msg.sender;
        cooAddress = msg.sender;
        oracleAddress = msg.sender;

        // Starts paused.
        paused = true;
    }

    /// @dev Used to mark the smart contract as upgraded, in case there is a serious
    ///  breaking bug. This method does nothing but keep track of the new contract and
    ///  emit a message indicating that the new address is set. It&#39;s up to clients of this
    ///  contract to update to the new contract address in that case. (This contract will
    ///  be paused indefinitely if such an upgrade takes place.)
    /// @param _v2Address new address
    function setNewAddress(address _v2Address) external onlyCTO whenPaused {
        // See README.md for updgrade plan
        newContractAddress = _v2Address;
        ContractUpgrade(_v2Address);
    }

    /// @dev set a new reference to the NFT ownership contract
    /// @param _CStorageAddress - address of a deployed contract implementing EthernautsStorage.
    function setEthernautsStorageContract(address _CStorageAddress) public onlyCLevel whenPaused {
        EthernautsStorage candidateContract = EthernautsStorage(_CStorageAddress);
        require(candidateContract.isEthernautsStorage());
        ethernautsStorage = candidateContract;
    }

    /// @dev Override unpause so it requires all external contract addresses
    ///  to be set before contract can be unpaused. Also, we can&#39;t have
    ///  newContractAddress set either, because then the contract was upgraded.
    /// @notice This is public rather than external so we can call super.unpause
    ///  without using an expensive CALL.
    function unpause() public onlyCEO whenPaused {
        require(ethernautsStorage != address(0));
        require(newContractAddress == address(0));
        // require this contract to have access to storage contract
        require(ethernautsStorage.contractsGrantedAccess(address(this)) == true);

        // Actually unpause the contract.
        super.unpause();
    }

    // @dev Allows the COO to capture the balance available to the contract.
    function withdrawBalances(address _to) public onlyCLevel {
        _to.transfer(this.balance);
    }

    /// return current contract balance
    function getBalance() public view onlyCLevel returns (uint256) {
        return this.balance;
    }
}

/// @title Clock auction for non-fungible tokens.
/// @notice We omit a fallback function to prevent accidental sends to this contract.
///         This provides public methods for Upgrade ship.
///
///      - UpgradeShip: This provides public methods for managing how and if a ship can upgrade.
///             The user can place a number of Ship Upgrades on the ship to affect the ship’s exploration.
///             Combining the Explore and Upgrade actions together limits the amount of gas the user has to pay.
/// @author Ethernatus - Fernando Pauer
contract EthernautsUpgrade is EthernautsLogic, ClockAuctionBase {

    /// @dev Constructor creates a reference to the NFT ownership contract
    ///  and verifies the owner cut is in the valid range.
    ///  and Delegate constructor to Nonfungible contract.
    function EthernautsUpgrade() public
    EthernautsLogic() {}

    /*** EVENTS ***/
    /// @dev The Upgrade event is fired whenever a ship is upgraded.
    event Upgrade(uint256 indexed tokenId);

    /*** CONSTANTS ***/
    uint8 STATS_CAPOUT = 2**8 - 1; // all stats have a range from 0 to 255

    // ************************* UPGRADE SHIP ****************************

    /// @notice Check and define how a ship can upgrade
    /// Example:
    /// User A wants to Upgrade Ship A. Ship A has 5 available upgrade slots.
    /// Thankfully, User A has 5 Ship Upgrades in their inventory.
    /// They have 1x Plasma Cannons (+1 Attack), Hardened Plates (+2 Defense),
    ///           1x Navigation Processor (+1 Range), 1x Engine Tune (+2 Speed), and Lucky Shamrock (+1 Luck) .
    /// User A drags the 5 Ship Upgrades into the appropriate slots and hits the Upgrade button.
    /// Ship A’s stats are now improved by +1 Attack, +2 Defense, +1 Range, +2 Speed, and +1 Luck, forever.
    /// The Ship Upgrades are consumed and disappear. The Ship then increases in level +1 to a total level of 2.
    /// @param _tokenId The Token ID that can be upgraded
    /// @param _objects List of objects to be used in the upgrade
    function upgradeShip(uint256 _tokenId, uint256[SHIP_SLOTS] _objects) external whenNotPaused {
        // Checking if Asset is a ship or not
        require(ethernautsStorage.isCategory(_tokenId, uint8(AssetCategory.Ship)));

        // Ensure the Ship is in available state, otherwise it cannot be upgraded
        require(ethernautsStorage.isState(_tokenId, uint8(AssetState.Available)));

        // only owner can upgrade his/her ship
        require(msg.sender == ethernautsStorage.ownerOf(_tokenId));

        // ship could not be in exploration
        require(!isExploring(_tokenId));

        // get ship and objects current stats
        uint i = 0;
        uint8[STATS_SIZE] memory _shipStats = ethernautsStorage.getStats(_tokenId);
        uint256 level = _shipStats[uint(ShipStats.Level)];
        uint8[STATS_SIZE][SHIP_SLOTS] memory _objectsStats;

        // check if level capped out, if yes no more upgrade is available
        require(level < 5);

        // a mapping to require upgrades should have different token ids
        uint256[] memory upgradesToTokenIndex = new uint256[](ethernautsStorage.totalSupply());

        // all objects must be available to use
        for(i = 0; i < _objects.length; i++) {
            // sender should owner all assets
            require(msg.sender == ethernautsStorage.ownerOf(_objects[i]));
            require(!isExploring(_objects[i]));
            require(ethernautsStorage.isCategory(_objects[i], uint8(AssetCategory.Object)));
            // avoiding duplicate keys
            require(upgradesToTokenIndex[_objects[i]] == 0);

            // mark token id as read and avoid duplicated token ids
            upgradesToTokenIndex[_objects[i]] = _objects[i];
            _objectsStats[i] = ethernautsStorage.getStats(_objects[i]);
        }

        // upgrading stats
        uint256 attack = _shipStats[uint(ShipStats.Attack)];
        uint256 defense = _shipStats[uint(ShipStats.Defense)];
        uint256 speed = _shipStats[uint(ShipStats.Speed)];
        uint256 range = _shipStats[uint(ShipStats.Range)];
        uint256 luck = _shipStats[uint(ShipStats.Luck)];

        for(i = 0; i < SHIP_SLOTS; i++) {
            // Only objects with upgrades are allowed
            require(_objectsStats[i][1] +
                    _objectsStats[i][2] +
                    _objectsStats[i][3] +
                    _objectsStats[i][4] +
                    _objectsStats[i][5] > 0);

            attack += _objectsStats[i][uint(ShipStats.Attack)];
            defense += _objectsStats[i][uint(ShipStats.Defense)];
            speed += _objectsStats[i][uint(ShipStats.Speed)];
            range += _objectsStats[i][uint(ShipStats.Range)];
            luck += _objectsStats[i][uint(ShipStats.Luck)];
        }

        if (attack > STATS_CAPOUT) {
            attack = STATS_CAPOUT;
        }
        if (defense > STATS_CAPOUT) {
            defense = STATS_CAPOUT;
        }
        if (speed > STATS_CAPOUT) {
            speed = STATS_CAPOUT;
        }
        if (range > STATS_CAPOUT) {
            range = STATS_CAPOUT;
        }
        if (luck > STATS_CAPOUT) {
            luck = STATS_CAPOUT;
        }

        // All stats must increase, even if its provided 5 upgrades in the slots
        require(attack > _shipStats[uint(ShipStats.Attack)]);
        require(defense > _shipStats[uint(ShipStats.Defense)]);
        require(speed > _shipStats[uint(ShipStats.Speed)]);
        require(range > _shipStats[uint(ShipStats.Range)]);
        require(luck > _shipStats[uint(ShipStats.Luck)]);

        _shipStats[uint(ShipStats.Level)] = uint8(level + 1);
        _shipStats[uint(ShipStats.Attack)] = uint8(attack);
        _shipStats[uint(ShipStats.Defense)] = uint8(defense);
        _shipStats[uint(ShipStats.Speed)] = uint8(speed);
        _shipStats[uint(ShipStats.Range)] = uint8(range);
        _shipStats[uint(ShipStats.Luck)] = uint8(luck);

        // only upgrade after confirmed transaction by Upgrade Ship Contract
        ethernautsStorage.updateStats(_tokenId, _shipStats);

        // mark all objects as used and change owner
        for(i = 0; i < _objects.length; i++) {
            ethernautsStorage.updateState(_objects[i], uint8(AssetState.Used));

            // Register the approval and transfer to upgrade ship contract
            _approve(_objects[i], address(this));
            _transferFrom(msg.sender, address(this), _objects[i]);
        }

        Upgrade(_tokenId);
    }

}