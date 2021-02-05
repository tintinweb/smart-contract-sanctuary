/**
 *Submitted for verification at Etherscan.io on 2021-02-05
*/

// File: contracts/Ownable.sol

pragma solidity ^0.5.10;

contract Ownable {
    address public owner;


    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
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
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

}

// File: contracts/Pausable.sol

pragma solidity ^0.5.10;


contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;


    /**
     * @dev modifier to allow actions only when the contract IS paused
     */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /**
     * @dev modifier to allow actions only when the contract IS NOT paused
     */
    modifier whenPaused {
        require(paused);
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() public onlyOwner whenNotPaused returns (bool) {
        paused = true;
        emit Pause();
        return true;
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() public onlyOwner whenPaused returns (bool) {
        paused = false;
        emit Unpause();
        return true;
    }
}

// File: contracts/DragonAccessControl.sol

pragma solidity ^0.5.10;



contract DragonAccessControl {
    /// @dev Emited when contract is upgraded - See README.md for updgrade plan
    event ContractUpgrade(address newContract);

    // The addresses of the accounts (or contracts) that can execute actions within each roles.
    address payable public ceoAddress;
    address payable public cioAddress;
    address payable public cmoAddress;
    address payable public cooAddress;
    address payable public cfoAddress;

    // @dev Keeps track whether the contract is paused. When that is true, most actions are blocked
    bool public paused = false;

    /// @dev Access modifier for CEO-only functionality
    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }

    /// @dev Access modifier for CIO-only functionality
    modifier onlyCIO() {
        require(msg.sender == cioAddress);
        _;
    }

    /// @dev Access modifier for CMO-only functionality
    modifier onlyCMO() {
        require(msg.sender == cmoAddress);
        _;
    }

    /// @dev Access modifier for COO-only functionality
    modifier onlyCOO() {
        require(msg.sender == cooAddress);
        _;
    }

    /// @dev Access modifier for CFO-only functionality
    modifier onlyCFO() {
        require(msg.sender == cfoAddress);
        _;
    }

    modifier onlyCLevel() {
        require(
            msg.sender == ceoAddress ||
            msg.sender == cioAddress ||
            msg.sender == cmoAddress ||
            msg.sender == cooAddress ||
            msg.sender == cfoAddress
        );
        _;
    }

    /// @dev Assigns a new address to act as the CEO. Only available to the current CEO.
    /// @param _newCEO The address of the new CEO
    function setCEO(address payable _newCEO) external onlyCEO {
        require(_newCEO != address(0));

        ceoAddress = _newCEO;
    }

    /// @dev Assigns a new address to act as the CIO. Only available to the current CEO.
    /// @param _newCIO The address of the new CIO
    function setCIO(address payable _newCIO) external onlyCEO {
        require(_newCIO != address(0));

        cioAddress = _newCIO;
    }

    /// @dev Assigns a new address to act as the CMO. Only available to the current CEO.
    /// @param _newCMO The address of the new CMO
    function setCMO(address payable _newCMO) external onlyCEO {
        require(_newCMO != address(0));

        cmoAddress = _newCMO;
    }

    /// @dev Assigns a new address to act as the COO. Only available to the current CEO.
    /// @param _newCOO The address of the new COO
    function setCOO(address payable _newCOO) external onlyCEO {
        require(_newCOO != address(0));

        cooAddress = _newCOO;
    }

    /// @dev Assigns a new address to act as the CFO. Only available to the current CEO.
    /// @param _newCFO The address of the new CFO
    function setCFO(address payable _newCFO) external onlyCEO {
        require(_newCFO != address(0));

        cfoAddress = _newCFO;
    }

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
    ///  one reason we may pause the contract is when CIO or CMO accounts are
    ///  compromised.
    /// @notice This is public rather than external so it can be called by
    ///  derived contracts.
    function unpause() public onlyCEO whenPaused {
        // can't unpause if contract was upgraded
        paused = false;
    }
}

// File: contracts/DragonERC721.sol

pragma solidity ^0.5.10;


/// @title ERC-721 Non-Fungible Token Standard
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x80ac58cd.
interface ERC721 /* is ERC165 */ {
    /// @dev This emits when ownership of any NFT changes by any mechanism.
    ///  This event emits when NFTs are created (`from` == 0) and destroyed
    ///  (`to` == 0). Exception: during contract creation, any number of NFTs
    ///  may be created and assigned without emitting Transfer. At the time of
    ///  any transfer, the approved address for that NFT (if any) is reset to none.
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
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) external payable;

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
    ///  all of `msg.sender`'s assets
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

interface ERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

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
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns(bytes4);
}

/// @title ERC-721 Non-Fungible Token Standard, optional metadata extension
/// @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
///  Note: the ERC-165 identifier for this interface is 0x5b5e139f
interface ERC721Metadata /* is IERC721Base */ {
  /// @notice A descriptive name for a collection of NFTs in this contract
  function name() external pure returns (string memory _name);

  /// @notice An abbreviated name for NFTs in this contract
  function symbol() external pure returns (string memory _symbol);

  /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
  /// @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
  ///  3986. The URI may point to a JSON file that conforms to the "ERC721
  ///  Metadata JSON Schema".
  function tokenURI(uint256 _tokenId) external view returns (string memory);
}

/// @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
/// @dev See https://eips.ethereum.org/EIPS/eip-721
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

//contract DragonERC721 is IERC721, ERC721Metadata, ERC721TokenReceiver, ERC721Enumerable {
contract DragonERC721 is ERC165, ERC721, ERC721Metadata, ERC721TokenReceiver, ERC721Enumerable {

    mapping (bytes4 => bool) internal supportedInterfaces;

    string public tokenURIPrefix = "https://www.drakons.io/server/api/dragon/metadata/";
    string public tokenURISuffix = "";

    function name() external pure returns (string memory) {
      return "Drakons";
    }

    function symbol() external pure returns (string memory) {
      return "DRKNS";
    }

    function supportsInterface(bytes4 interfaceID) external view returns (bool) {
        return supportedInterfaces[interfaceID];
    }

    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns(bytes4){
        return bytes4(keccak256("onERC721Received(address,uint256,bytes)"));
    }

}

// File: contracts/ClockAuctionBase.sol

pragma solidity ^0.5.10;


contract ClockAuctionBase {

    // Represents an auction on an NFT
    struct Auction {
        // Current owner of NFT
        address payable seller;
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
    DragonERC721 public nonFungibleContract;

    // Cut owner takes on each auction, measured in basis points (1/100 of a percent).
    // Values 0-10,000 map to 0%-100%
    uint256 public ownerCut;

    address payable public ceoAddress;
    address payable public cfoAddress;

    modifier onlyCEOCFO() {
        require(
            msg.sender == ceoAddress ||
            msg.sender == cfoAddress
        );
        _;
    }

    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }

    // Map from token ID to their corresponding auction.
    mapping (uint256 => Auction) tokenIdToAuction;

    event AuctionCreated(uint256 tokenId, uint256 startingPrice, uint256 endingPrice, uint256 duration);
    event AuctionSuccessful(uint256 tokenId, uint256 totalPrice, address buyer, address seller);
    event AuctionCancelled(uint256 tokenId);


    function setCEO(address payable _newCEO) external onlyCEO {
        require(_newCEO != address(0));

        ceoAddress = _newCEO;
    }

    function setCFO(address payable _newCFO) external onlyCEO {
        require(_newCFO != address(0));

        cfoAddress = _newCFO;
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
        nonFungibleContract.transferFrom(_owner, address(this), _tokenId);
    }

    /// @dev Transfers an NFT owned by this contract to another address.
    /// Returns true if the transfer succeeds.
    /// @param _receiver - Address to transfer NFT to.
    /// @param _tokenId - ID of token to transfer.
    function _transfer(address _receiver, uint256 _tokenId) internal {
        // it will throw if transfer fails
        //nonFungibleContract.transfer(_receiver, _tokenId);
        nonFungibleContract.transferFrom(address(this), _receiver, _tokenId);
    }

    /// @dev Adds an auction to the list of open auctions. Also fires the
    ///  AuctionCreated event.
    /// @param _tokenId The ID of the token to be put on auction.
    /// @param _auction Auction to add.
    function _addAuction(uint256 _tokenId, Auction memory _auction) internal {
        // Require that all auctions have a duration of
        // at least one minute. (Keeps our math from getting hairy!)
        require(_auction.duration >= 1 minutes);

        tokenIdToAuction[_tokenId] = _auction;

        //cpt added emit
        emit AuctionCreated(
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
        emit AuctionCancelled(_tokenId);
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
        // (Because of how Ethereum mappings work, we can't just count
        // on the lookup above failing. An invalid _tokenId will just
        // return an auction object that is all zeros.)
        require(_isOnAuction(auction));

        // Check that the bid is greater than or equal to the current price
        uint256 price = _currentPrice(auction);
        require(_bidAmount >= price);

        // Grab a reference to the seller before the auction struct
        // gets deleted.
        address payable seller = auction.seller;

        // The bid is good! Remove the auction before sending the fees
        // to the sender so we can't have a reentrancy attack.
        _removeAuction(_tokenId);

        // Transfer proceeds to seller (if there are any!)
        if (price > 0) {
            // Calculate the auctioneer's cut.
            // (NOTE: _computeCut() is guaranteed to return a
            // value <= price, so this subtraction can't go negative.)
            uint256 auctioneerCut = _computeCut(price);
            uint256 sellerProceeds = price - auctioneerCut;

            // NOTE: Doing a transfer() in the middle of a complex
            // method like this is generally discouraged because of
            // reentrancy attacks and DoS attacks if the seller is
            // a contract with an invalid fallback function. We explicitly
            // guard against reentrancy attacks by removing the auction
            // before calling transfer(), and the only thing the seller
            // can DoS is the sale of their own asset! (And if it's an
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
        emit AuctionSuccessful(_tokenId, price, msg.sender, seller);

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
        // now variable doesn't ever go backwards).
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
        // NOTE: We don't use SafeMath (or similar) in this function because
        //  all of our public functions carefully cap the maximum values for
        //  time (at 64-bits) and currency (at 128-bits). _duration is
        //  also known to be non-zero (see the require() statement in
        //  _addAuction())
        if (_secondsPassed >= _duration) {
            // We've reached the end of the dynamic pricing portion
            // of the auction, just return the end price.
            return _endingPrice;
        } else {
            // Starting price can be higher than ending price (and often is!), so
            // this delta can be negative.
            int256 totalPriceChange = int256(_endingPrice) - int256(_startingPrice);

            // This multiplication can't overflow, _secondsPassed will easily fit within
            // 64-bits, and totalPriceChange will easily fit within 128-bits, their product
            // will always fit within 256-bits.
            int256 currentPriceChange = totalPriceChange * int256(_secondsPassed) / int256(_duration);

            // currentPriceChange can be negative, but if so, will have a magnitude
            // less that _startingPrice. Thus, this result will always end up positive.
            int256 currentPrice = int256(_startingPrice) + currentPriceChange;

            return uint256(currentPrice);
        }
    }

    /// @dev Computes owner's cut of a sale.
    /// @param _price - Sale price of NFT.
    function _computeCut(uint256 _price) internal view returns (uint256) {
        // NOTE: We don't use SafeMath (or similar) in this function because
        //  all of our entry functions carefully cap the maximum values for
        //  currency (at 128-bits), and ownerCut <= 10000 (see the require()
        //  statement in the ClockAuction constructor). The result of this
        //  function is always guaranteed to be <= _price.
        return _price * ownerCut / 10000;
    }
}

// File: contracts/ClockAuction.sol

pragma solidity ^0.5.10;



contract ClockAuction is Pausable, ClockAuctionBase {

    /// @dev The ERC-165 interface signature for ERC-721.
    ///  Ref: https://github.com/ethereum/EIPs/issues/165
    ///  Ref: https://github.com/ethereum/EIPs/issues/721
    //bytes4 constant InterfaceSignature_ERC721 = bytes4(0x5b5e139f);
    bytes4 constant InterfaceSignature_ERC721 = bytes4(0x80ac58cd);

    /// @dev Constructor creates a reference to the NFT ownership contract
    ///  and verifies the owner cut is in the valid range.
    /// @param _nftAddress - address of a deployed contract implementing
    ///  the Nonfungible Interface.
    /// @param _cut - percent cut the owner takes on each auction, must be
    ///  between 0-10,000.
    constructor (address _nftAddress, uint256 _cut) public {
        require(_cut <= 10000);
        ownerCut = _cut;

        ceoAddress = msg.sender;
        cfoAddress = msg.sender;

        DragonERC721 candidateContract = DragonERC721(_nftAddress);
        //require(candidateContract.supportsInterface(InterfaceSignature_ERC721));
        nonFungibleContract = candidateContract;
    }


    /// @dev Remove all Ether from the contract, which is the owner's cuts
    ///  as well as any Ether sent directly to the contract address.
    ///  Always transfers to the NFT contract, but can be called either by
    ///  the owner or the NFT contract.
    function withdrawBalance() external {
        address payable nftAddress = address(uint160(address(nonFungibleContract)));

        require(
            msg.sender == owner ||
            msg.sender == nftAddress
        );
        // We are using this boolean method to make sure that even if one fails it will still work
        //bool res = nftAddress.send(address(this).balance);
        nftAddress.transfer(address(this).balance);
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
        address payable _seller
    )
    external
    whenNotPaused
    {
        // Sanity check that no inputs overflow how many bits we've allocated
        // to store them in the auction struct.
        require(_startingPrice == uint256(uint128(_startingPrice)));
        require(_endingPrice == uint256(uint128(_endingPrice)));
        require(_duration == uint256(uint64(_duration)));

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
    external
    payable
    whenNotPaused
    {
        // _bid will throw if the bid or funds transfer fails
        _bid(_tokenId, msg.value);
        _transfer(msg.sender, _tokenId);
    }

    /// @dev Cancels an auction that hasn't been won yet.
    ///  Returns the NFT to original owner.
    /// @notice This is a state-modifying function that can
    ///  be called while the contract is paused.
    /// @param _tokenId - ID of token on auction
    function cancelAuction(uint256 _tokenId)
    external
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        address seller = auction.seller;
        require(msg.sender == seller || msg.sender == address(nonFungibleContract));
        _cancelAuction(_tokenId, seller);
    }

    /// @dev Cancels an auction when the contract is paused.
    ///  Only the owner may do this, and NFTs are returned to
    ///  the seller. This should only be used in emergencies.
    /// @param _tokenId - ID of the NFT on auction to cancel.
    function cancelAuctionWhenPaused(uint256 _tokenId)
    whenPaused
    onlyOwner
    external
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        _cancelAuction(_tokenId, auction.seller);
    }

    /// @dev Returns auction info for an NFT on auction.
    /// @param _tokenId - ID of NFT on auction.
    function getAuction(uint256 _tokenId)
    external
    view
    returns
    (
        address payable seller,
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
    external
    view
    returns (uint256)
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        return _currentPrice(auction);
    }
}

// File: contracts/SaleClockAuction.sol

pragma solidity ^0.5.10;


contract SaleClockAuction is ClockAuction {

    // @dev Sanity check that allows us to ensure that we are pointing to the
    //  right auction in our setSaleAuctionAddress() call.
    bool public isSaleClockAuction = true;

    // Delegate constructor
    constructor(address _nftAddr, uint256 _cut) public
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
        address payable _seller
    )
    external
    {
        // Sanity check that no inputs overflow how many bits we've allocated
        // to store them in the auction struct.
        require(_startingPrice == uint256(uint128(_startingPrice)));
        require(_endingPrice == uint256(uint128(_endingPrice)));
        require(_duration == uint256(uint64(_duration)));

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
    external
    payable
    {
        // _bid verifies token ID size
        _bid(_tokenId, msg.value);
        _transfer(msg.sender, _tokenId);
    }

    function setOwnerCut(uint256 val) external onlyCEOCFO {
        ownerCut = val;
    }
}

// File: contracts/SiringClockAuction.sol

pragma solidity ^0.5.10;


contract SiringClockAuction is ClockAuction {

    // @dev Sanity check that allows us to ensure that we are pointing to the
    //  right auction in our setSiringAuctionAddress() call.
    bool public isSiringClockAuction = true;

    // Delegate constructor
    constructor(address _nftAddr, uint256 _cut) public
    ClockAuction(_nftAddr, _cut) {}

    /// @dev Creates and begins a new auction. Since this function is wrapped,
    /// require sender to be DragonCore contract.
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
        address payable _seller
    )
    external
    {
        // Sanity check that no inputs overflow how many bits we've allocated
        // to store them in the auction struct.
        require(_startingPrice == uint256(uint128(_startingPrice)));
        require(_endingPrice == uint256(uint128(_endingPrice)));
        require(_duration == uint256(uint64(_duration)));

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

    /// @dev Places a bid for siring. Requires the sender
    /// is the DragonCore contract because all bid methods
    /// should be wrapped. Also returns the Dragon to the
    /// seller rather than the winner.
    function bid(uint256 _tokenId)
    external
    payable
    {
        require(msg.sender == address(nonFungibleContract));
        address seller = tokenIdToAuction[_tokenId].seller;
        // _bid checks that token ID is valid and will throw if bid fails
        _bid(_tokenId, msg.value);
        // We transfer the dragon back to the seller, the winner will get
        // the offspring
        _transfer(seller, _tokenId);
    }

    function setOwnerCut(uint256 val) external onlyCEOCFO {
        ownerCut = val;
    }

}

// File: contracts/DragonBase.sol

pragma solidity ^0.5.10;





contract DragonBase is DragonAccessControl, DragonERC721 {

    event Birth(address owner, uint256 dragonId, uint256 matronId, uint256 sireId, uint256 dna, uint32 generation, uint64 runeLevel);
    event DragonAssetsUpdated(uint256 _dragonId, uint64 _rune, uint64 _agility, uint64 _strength, uint64 _intelligence);
    event DragonAssetRequest(uint256 _dragonId);
    //event Transfer(address from, address to, uint256 tokenId, uint32 generation);

    struct Dragon {
        // The Dragon's genetic code is packed into these 256-bits.
        uint256 dna;
        uint64 birthTime;
        uint64 breedTime;
        uint32 matronId;
        uint32 sireId;
        uint32 siringWithId;
        uint32 generation;
    }

    struct DragonAssets {
        uint64 runeLevel;
        uint64 agility;
        uint64 strength;
        uint64 intelligence;
    }

    Dragon[] dragons;
    mapping (uint256 => address) public dragonIndexToOwner;
    mapping (address => uint256) ownershipTokenCount;
    mapping (uint256 => address) public dragonIndexToApproved;
    mapping (uint256 => address) public sireAllowedToAddress;
    mapping (uint256 => DragonAssets) public dragonAssets;

    mapping (address => mapping (address => bool)) internal authorised;

    uint256 public updateAssetFee = 8 finney;

    SaleClockAuction public saleAuction;
    SiringClockAuction public siringAuction;

    modifier isValidToken(uint256 _tokenId) {
        require(dragonIndexToOwner[_tokenId] != address(0));
        _;
    }

    /// @dev Assigns ownership of a specific Dragon to an address.
    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        // Since the number of dragons is capped to 2^32 we can't overflow this
        // Declaration: mapping (address => uint256) ownershipTokenCount;
        ownershipTokenCount[_to]++;
        // transfer ownership
        // Declaration: mapping (uint256 => address) public dragonIndexToOwner;
        dragonIndexToOwner[_tokenId] = _to;
        // When creating new dragons _from is 0x0, but we can't account that address.
        if (_from != address(0)) {
            ownershipTokenCount[_from]--;
            // once the dragon is transferred also clear sire allowances
            delete sireAllowedToAddress[_tokenId];
            // clear any previously approved ownership exchange
            delete dragonIndexToApproved[_tokenId];
        }

        //Dragon storage dragon = dragons[_tokenId];

        // Emit the transfer event.
        emit Transfer(_from, _to, _tokenId);
    }

    /// @dev An internal method that creates a new dragon and stores it. This
    ///  method doesn't do any checking and should only be called when the
    ///  input data is known to be valid. Will generate both a Birth event
    ///  and a Transfer event.
    /// @param _matronId The dragon ID of the matron of this dragon (zero for firstGen)
    /// @param _sireId The dragon ID of the sire of this dragon (zero for firstGen)
    /// @param _generation The generation number of this dragon, must be computed by caller.
    /// @param _dna The dragon's genetic code.
    /// @param _agility The dragon's agility
    /// @param _strength The dragon's strength
    /// @param _intelligence The dragon's intelligence
    /// @param _runelevel The dragon's rune level
    /// @param _owner The inital owner of this dragon, must be non-zero (except for the mythical beast, ID 0)
    function _createDragon(
        uint256 _matronId,
        uint256 _sireId,
        uint256 _generation,
        uint256 _dna,
        uint64 _agility,
        uint64 _strength,
        uint64 _intelligence,
        uint64 _runelevel,
        address _owner
    )
    internal
    returns (uint)
    {
        require(_matronId == uint256(uint32(_matronId)));
        require(_sireId == uint256(uint32(_sireId)));
        require(_generation == uint256(uint32(_generation)));

        Dragon memory _dragon = Dragon({
            dna: _dna,
            birthTime: uint64(now),
            breedTime: 0,
            matronId: uint32(_matronId),
            sireId: uint32(_sireId),
            siringWithId: 0,
            generation: uint32(_generation)
            });

        DragonAssets memory _dragonAssets = DragonAssets({
            runeLevel: _runelevel,
            agility: _agility,
            strength: _strength,
            intelligence: _intelligence
            });

        uint256 newDragonId = dragons.push(_dragon) - 1;

        dragonAssets[newDragonId] = _dragonAssets;

        // It's probably never going to happen, 4 billion dragons is A LOT, but
        // let's just be 100% sure we never let this happen.
        require(newDragonId == uint256(uint32(newDragonId)));

        // emit the birth event
        emit Birth(
            _owner,
            newDragonId,
            uint256(_dragon.matronId),
            uint256(_dragon.sireId),
            _dragon.dna,
            _dragon.generation,
            _runelevel
        );

        // This will assign ownership, and also emit the Transfer event as
        // per ERC721 draft
        _transfer(address(0), _owner, newDragonId);

        return newDragonId;
    }

    function setUpdateAssetFee(uint256 newFee) external onlyCLevel {
        updateAssetFee = newFee;
    }


    function updateDragonAsset(uint256 _dragonId, uint64 _rune, uint64 _agility, uint64 _strength, uint64 _intelligence)
    external
    whenNotPaused
    onlyCOO
    {

        DragonAssets storage currentDragonAsset = dragonAssets[_dragonId];

        require(_rune > currentDragonAsset.runeLevel);
        require(_agility >= currentDragonAsset.agility);
        require(_strength >= currentDragonAsset.strength);
        require(_intelligence >= currentDragonAsset.intelligence);

        DragonAssets memory _dragonAsset = DragonAssets({
            runeLevel: _rune,
            agility: _agility,
            strength: _strength,
            intelligence: _intelligence
            });

        dragonAssets[_dragonId] = _dragonAsset;
        msg.sender.transfer(updateAssetFee);
        emit DragonAssetsUpdated(_dragonId, _rune, _agility, _strength, _intelligence);

    }

    function requestAssetUpdate(uint256 _dragonId, uint256 _rune)
    external
    payable
    whenNotPaused
    {
        require(msg.value >= updateAssetFee);

        DragonAssets storage currentDragonAsset = dragonAssets[_dragonId];
        require(_rune > currentDragonAsset.runeLevel);

        emit DragonAssetRequest(_dragonId);

        //assetManagement.requestAssetUpdate.value(msg.value)(_dragonId);
    }

    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator) external view returns (bool)
    {
        return authorised[_owner][_operator];
    }

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///  all of `msg.sender`'s assets
    /// @dev Emits the ApprovalForAll event. The contract MUST allow
    ///  multiple operators per owner.
    /// @param _operator Address to add to the set of authorized operators
    /// @param _approved True if the operator is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) external
    {
        emit ApprovalForAll(msg.sender,_operator, _approved);
        authorised[msg.sender][_operator] = _approved;
    }

    function tokenURI(uint256 _tokenId) external view isValidToken(_tokenId) returns (string memory)
    {
        uint maxlength = 78;
        bytes memory reversed = new bytes(maxlength);
        uint i = 0;
        uint _tmpTokenId = _tokenId;
        uint _offset = 48;

        bytes memory _uriBase;
        _uriBase = bytes(tokenURIPrefix);

        while (_tmpTokenId != 0) {
            uint remainder = _tmpTokenId % 10;
            _tmpTokenId = _tmpTokenId / 10;
            reversed[i++] = byte(uint8(_offset + remainder));
        }

        bytes memory s = new bytes(_uriBase.length + i);
        uint j;

        //add the base to the final array
        for (j = 0; j < _uriBase.length; j++) {
            s[j] = _uriBase[j];
        }
        //add the tokenId to the final array
        for (j = 0; j < i; j++) {
            s[j + _uriBase.length] = reversed[i - 1 - j];
        }
        //turn it into a string and return it
        return string(s);
    }
}

// File: contracts/DragonOwnership.sol

pragma solidity ^0.5.10;


/// @title The facet of the BlockDragons core contract that manages ownership, ERC-721 (draft) compliant.
/// @author Zynappse Corporation (https://www.zynapse.com)
/// @dev Ref: https://github.com/ethereum/EIPs/issues/721
///  @dev Refer to the Dragon contract documentation for details in contract interactions.
contract DragonOwnership is DragonBase {

    /// @notice Name and symbol of the non fungible token, as defined in ERC721.
    string public constant name = "Drakons";
    string public constant symbol = "DRKNS";

    //bytes4 constant InterfaceSignature_ERC165 = bytes4(keccak256('supportsInterface(bytes4)'));

    //bytes4 constant InterfaceSignature_ERC721 =
    //bytes4(keccak256('name()')) ^
    //bytes4(keccak256('symbol()')) ^
    //bytes4(keccak256('totalSupply()')) ^
    //bytes4(keccak256('balanceOf(address)')) ^
    //bytes4(keccak256('ownerOf(uint256)')) ^
    //bytes4(keccak256('approve(address,uint256)')) ^
    //bytes4(keccak256('transfer(address,uint256)')) ^
    //bytes4(keccak256('transferFrom(address,address,uint256)')) ^
    //bytes4(keccak256('tokensOfOwner(address)')) ^
    //bytes4(keccak256('tokenMetadata(uint256,string)'));

    /// @notice Introspection interface as per ERC-165 (https://github.com/ethereum/EIPs/issues/165).
    ///  Returns true for any standardized interfaces implemented by this contract. We implement
    ///  ERC-165 (obviously!) and ERC-721.
    //function supportsInterface(bytes4 _interfaceID) external view returns (bool)
    //{
    //    return ((_interfaceID == InterfaceSignature_ERC165) || (_interfaceID == InterfaceSignature_ERC721));
    //}

    function setTokenURIAffixes(string calldata _prefix, string calldata _suffix) external onlyCEO {
        tokenURIPrefix = _prefix;
        tokenURISuffix = _suffix;
    }

    /// @dev Checks if a given address is the current owner of a particular Dragon.
    /// @param _claimant the address we are validating against.
    /// @param _tokenId dragon id, only valid when > 0
    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return dragonIndexToOwner[_tokenId] == _claimant;
    }

    /// @dev Checks if a given address currently has transferApproval for a particular Dragon.
    /// @param _claimant the address we are confirming dragon is approved for.
    /// @param _tokenId dragon id, only valid when > 0
    function _approvedFor(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return dragonIndexToApproved[_tokenId] == _claimant;
    }

    /// @dev Marks an address as being approved for transferFrom(), overwriting any previous
    ///  approval. Setting _approved to address(0) clears all transfer approval.
    ///  NOTE: _approve() does NOT send the Approval event. This is intentional because
    ///  _approve() and transferFrom() are used together for putting Dragons on auction, and
    ///  there is no value in spamming the log with Approval events in that case.
    function _approve(uint256 _tokenId, address _approved) internal {
        dragonIndexToApproved[_tokenId] = _approved;
    }

    /// @notice Returns the number of Dragons owned by a specific address.
    /// @param _owner The owner address to check.
    /// @dev Required for ERC-721 compliance
    function balanceOf(address _owner) public view returns (uint256 count) {
        return ownershipTokenCount[_owner];
    }

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
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) public payable
    {
        require(_to != address(0));
        require(_to != address(this));
        require(_to != address(saleAuction));
        require(_to != address(siringAuction));

        // Check for approval and valid ownership
        //require(_approvedFor(msg.sender, _tokenId));
        //require(_owns(_from, _tokenId));
        address owner = ownerOf(_tokenId);
        require(owner == _from);
        require (owner == msg.sender || dragonIndexToApproved[_tokenId] == msg.sender || authorised[owner][msg.sender]);

        // Reassign ownership, clearing pending approvals and emitting Transfer event.
        _transfer(_from, _to, _tokenId);

        uint32 size;
        assembly {
            size := extcodesize(_to)
        }

        if(size > 0) {
            ERC721TokenReceiver receiver = ERC721TokenReceiver(_to);
            require(receiver.onERC721Received(msg.sender,_from,_tokenId,data) == bytes4(keccak256("onERC721Received(address,address,uint256,bytes)")));
        }
    }

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to "".
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable
    {
        safeTransferFrom(_from, _to, _tokenId, "");
    }

    /// @notice Transfers a Dragon to another address. If transferring to a smart
    ///  contract be VERY CAREFUL to ensure that it is aware of ERC-721 (or
    ///  BlockDragonz specifically) or your Dragon may be lost forever. Seriously.
    /// @param _to The address of the recipient, can be a user or contract.
    /// @param _tokenId The ID of the Dragon to transfer.
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
        // The contract should never own any dragons (except very briefly
        // after a firstGen dragon is created and before it goes on auction).
        require(_to != address(this));
        // Disallow transfers to the auction contracts to prevent accidental
        // misuse. Auction contracts should only take ownership of dragons
        // through the allow + transferFrom flow.
        require(_to != address(saleAuction));
        require(_to != address(siringAuction));

        // You can only send your own dragon.
        require(_owns(msg.sender, _tokenId));

        // Reassign ownership, clear pending approvals, emit Transfer event.
        _transfer(msg.sender, _to, _tokenId);
    }

    /// @notice Returns the address currently assigned ownership of a given Dragon.
    /// @dev Required for ERC-721 compliance.
    function ownerOf(uint256 _tokenId) public view isValidToken(_tokenId) returns (address)
    {
        return dragonIndexToOwner[_tokenId];
    }

    /// @notice Grant another address the right to transfer a specific Dragon via
    ///  transferFrom(). This is the preferred flow for transfering NFTs to contracts.
    /// @param _approved The address to be granted transfer approval. Pass address(0) to
    ///  clear all approvals.
    /// @param _tokenId The ID of the Dragon that can be transferred if this call succeeds.
    /// @dev Required for ERC-721 compliance.
    //function approve( address _to, uint256 _tokenId) external whenNotPaused {
    function approve(address _approved, uint256 _tokenId) external payable whenNotPaused {
        // Only an owner can grant transfer approval.
        //require(_owns(msg.sender, _tokenId) || authorised[owner][msg.sender]);
        address owner = dragonIndexToOwner[_tokenId];
        require(owner == msg.sender || authorised[owner][msg.sender]);

        // Register the approval (replacing any previous approval).
        _approve(_tokenId, _approved);

        // Emit approval event.
        //emit Approval(msg.sender, _approved, _tokenId);
        emit Approval(owner, _approved, _tokenId);
    }

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT.
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId) external view isValidToken(_tokenId) returns (address)
    {
        return dragonIndexToApproved[_tokenId];
    }


    /// @notice Transfer a Dragon owned by another address, for which the calling address
    ///  has previously been granted transfer approval by the owner.
    /// @param _from The address that owns the Dragon to be transfered.
    /// @param _to The address that should take ownership of the Dragon. Can be any address,
    ///  including the caller.
    /// @param _tokenId The ID of the Dragon to be transferred.
    /// @dev Required for ERC-721 compliance.
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable whenNotPaused
    {
        // Safety check to prevent against an unexpected 0x0 default.
        require(_to != address(0));
        // Disallow transfers to this contract to prevent accidental misuse.
        // The contract should never own any dragons (except very briefly
        // after a firstGen dragon is created and before it goes on auction).
        require(_to != address(this));
        // Check for approval and valid ownership
        //require(_approvedFor(msg.sender, _tokenId));
        //require(_owns(_from, _tokenId));
        address owner = ownerOf(_tokenId);
        require(owner == _from);
        require (owner == msg.sender || dragonIndexToApproved[_tokenId] == msg.sender || authorised[owner][msg.sender]);

        // Reassign ownership (also clears pending approvals and emits Transfer event).
        _transfer(_from, _to, _tokenId);
    }

    /// @notice Returns the total number of Dragons currently in existence.
    /// @dev Required for ERC-721 compliance.
    function totalSupply() public view returns (uint) {
        return dragons.length - 1;
    }

    /// @notice Returns a list of all Dragon IDs assigned to an address.
    /// @param _owner The owner whose Dragons we are interested in.
    /// @dev This method MUST NEVER be called by smart contract code. First, it's fairly
    ///  expensive (it walks the entire Dragon array looking for dragons belonging to owner),
    ///  but it also returns a dynamic array, which is only supported for web3 calls, and
    ///  not contract-to-contract calls.
    function tokensOfOwner(address _owner) external view returns(uint256[] memory ownerTokens) {
        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalDragons = totalSupply();
            uint256 resultIndex = 0;

            // We count on the fact that all dragons have IDs starting at 1 and increasing
            // sequentially up to the totalDragon count.
            uint256 dragonId;

            for (dragonId = 1; dragonId <= totalDragons; dragonId++) {
                if (dragonIndexToOwner[dragonId] == _owner) {
                    result[resultIndex] = dragonId;
                    resultIndex++;
                }
            }

            return result;
        }
    }

    /// @notice Enumerate valid NFTs
    /// @dev Throws if `_index` >= `totalSupply()`.
    /// @param _index A counter less than `totalSupply()`
    /// @return The token identifier for the `_index`th NFT,
    ///  (sort order not specified)
    function tokenByIndex(uint256 _index) external view returns (uint256)
    {
        return _index;
    }

    /// @notice Enumerate NFTs assigned to an owner
    /// @dev Throws if `_index` >= `balanceOf(_owner)` or if
    ///  `_owner` is the zero address, representing invalid NFTs.
    /// @param _owner An address where we are interested in NFTs owned by them
    /// @param _index A counter less than `balanceOf(_owner)`
    /// @return The token identifier for the `_index`th NFT assigned to `_owner`,
    ///   (sort order not specified)
    //function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256)
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256 dragonId)
    {
        uint256 count = 0;
        for (uint256 i = 1; i <= totalSupply(); ++i) {
            if (dragonIndexToOwner[i] == _owner) {
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

// File: contracts/DragonBreeding.sol

pragma solidity ^0.5.10;


/// @title DragonCore that manages Dragon siring, gestation, and birth.
/// @author Zynappse Corporation (https://www.zynapse.com)
/// @dev See the DragonCore contract documentation to understand how the various contract facets are arranged.
contract DragonBreeding is DragonOwnership {

    /// @dev The Pregnant event is fired when two dragons successfully breed and the pregnancy timer begins for the matron.
    event Pregnant(address owner, uint256 matronId, uint256 sireId);

    /// @notice The minimum payment required to use breedWithAuto(). This fee goes towards
    ///  the gas cost paid by whatever calls giveBirth(), and can be dynamically updated by
    ///  the CIO role as the gas price changes.
    uint256 public autoBirthFee = 2 finney;

    // Keeps track of number of pregnant dragons.
    uint256 public pregnantDragons;

    uint32 public BREEDING_LIMIT = 3;
    mapping(uint256 => uint64) breeding;

    /// @dev The address of the sibling contract that is used to implement the sooper-sekret genetic combination algorithm.
    //GeneScienceInterface public geneScience;

    /// @dev Update the address of the genetic contract, can only be called by the CEO.
    /// @param _address An address of a GeneScience contract instance to be used from this point forward.
    //function setGeneScienceAddress(address _address) external onlyCEO {
    //    GeneScienceInterface candidateContract = GeneScienceInterface(_address);

    // NOTE: verify that a contract is what we expect - https://github.com/Lunyr/crowdsale-contracts/blob/cfadd15986c30521d8ba7d5b6f57b4fefcc7ac38/contracts/LunyrToken.sol#L117
    //    require(candidateContract.isGeneScience());

    // Set the new contract address
    //    geneScience = candidateContract;
    //}

    /// @dev Checks that a given Dragon is able to breed. Requires that the
    ///  current cooldown is finished (for sires) and also checks that there is
    ///  no pending pregnancy.
    function _isReadyToBreed(Dragon storage _dragon) internal view returns (bool) {
        // In addition to checking the cooldownEndBlock, we also need to check to see if
        // the dragon has a pending birth; there can be some period of time between the end
        // of the pregnacy timer and the birth event.
        return (_dragon.siringWithId == 0);
    }

    /// @dev Check if a sire has authorized breeding with this matron. True if both sire
    ///  and matron have the same owner, or if the sire has given siring permission to
    ///  the matron's owner (via approveSiring()).
    function _isSiringPermitted(uint256 _sireId, uint256 _matronId) internal view returns (bool) {
        address matronOwner = dragonIndexToOwner[_matronId];
        address sireOwner = dragonIndexToOwner[_sireId];

        // Siring is okay if they have same owner, or if the matron's owner was given
        // permission to breed with this sire.
        return (matronOwner == sireOwner || sireAllowedToAddress[_sireId] == matronOwner);
    }



    /// @notice Grants approval to another user to sire with one of your Dragons.
    /// @param _addr The address that will be able to sire with your Dragon. Set to
    ///  address(0) to clear all siring approvals for this Dragon.
    /// @param _sireId A Dragon that you own that _addr will now be able to sire with.
    function approveSiring(address _addr, uint256 _sireId)
    external
    whenNotPaused
    {
        require(_owns(msg.sender, _sireId));
        sireAllowedToAddress[_sireId] = _addr;
    }

    /// @dev Updates the minimum payment required for calling giveBirthAuto(). Can only
    ///  be called by the CMO address. (This fee is used to offset the gas cost incurred
    ///  by the autobirth daemon).
    function setAutoBirthFee(uint256 val) external onlyCLevel {
        autoBirthFee = val;
    }

    /// @dev Checks to see if a given Dragon is pregnant and (if so) if the gestation period has passed.
    function _isReadyToGiveBirth(Dragon storage _matron) private view returns (bool) {
        return (_matron.siringWithId != 0);
    }

    /// @notice Checks that a given dragon is able to breed (i.e. it is not pregnant or
    ///  in the middle of a siring cooldown).
    /// @param _dragonId reference the id of the dragon, any user can inquire about it
    function isReadyToBreed(uint256 _dragonId)
    public
    view
    returns (bool)
    {
        require(_dragonId > 0);
        Dragon storage dragon = dragons[_dragonId];
        return _isReadyToBreed(dragon);
    }

    /// @dev Checks whether a dragon is currently pregnant.
    /// @param _dragonId reference the id of the dragon, any user can inquire about it
    function isPregnant(uint256 _dragonId)
    public
    view
    returns (bool)
    {
        require(_dragonId > 0);
        // A dragon is pregnant if and only if this field is set
        return dragons[_dragonId].siringWithId != 0;
    }

    /// @dev Internal check to see if a given sire and matron are a valid mating pair. DOES NOT
    /// check ownership permissions (that is up to the caller).
    /// @param _matron A reference to the Dragon struct of the potential matron.
    /// @param _matronId The matron's ID.
    /// @param _sire A reference to the Dragon struct of the potential sire.
    /// @param _sireId The sire's ID
    function _isValidMatingPair(
        Dragon storage _matron,
        uint256 _matronId,
        Dragon storage _sire,
        uint256 _sireId
    )
    private
    view
    returns(bool)
    {
        if(breeding[_matronId] >= BREEDING_LIMIT) {
            return false;
        }

        uint256 sireElement = _sire.dna / 1e34;
        uint256 matronElement = _matron.dna / 1e34;

        if (sireElement != matronElement) {
          return false;
        }

        // A Dragon can't breed with itself!
        if (_matronId == _sireId) {
            return false;
        }

        // Dragons can't breed with their parents.
        if (_matron.matronId == _sireId || _matron.sireId == _sireId) {
            return false;
        }

        if (_sire.matronId == _matronId || _sire.sireId == _matronId) {
            return false;
        }

        // We can short circuit the sibling check (below) if either dragon is first generation (has a matron ID of zero).
        if (_sire.matronId == 0 || _matron.matronId == 0) {
            return true;
        }

        // Dragons can't breed with full or half siblings.
        if (_sire.matronId == _matron.matronId || _sire.matronId == _matron.sireId) {
            return false;
        }
        if (_sire.sireId == _matron.matronId || _sire.sireId == _matron.sireId) {
            return false;
        }

        // Everything seems cool! Let's get DTF.
        return true;
    }

    /// @dev Internal check to see if a given sire and matron are a valid mating pair for
    ///  breeding via auction (i.e. skips ownership and siring approval checks).
    function _canBreedWithViaAuction(uint256 _matronId, uint256 _sireId)
    internal
    view
    returns (bool)
    {
        Dragon storage matron = dragons[_matronId];
        Dragon storage sire = dragons[_sireId];
        return _isValidMatingPair(matron, _matronId, sire, _sireId);
    }

    /// @notice Checks to see if two dragons can breed together, including checks for
    ///  ownership and siring approvals. Does NOT check that both dragons are ready for
    ///  breeding (i.e. breedWith could still fail until the cooldowns are finished).
    ///  TODO: Shouldn't this check pregnancy and cooldowns?!?
    /// @param _matronId The ID of the proposed matron.
    /// @param _sireId The ID of the proposed sire.
    function canBreedWith(uint256 _matronId, uint256 _sireId)
    external
    view
    returns(bool)
    {
        require(_matronId > 0);
        require(_sireId > 0);
        Dragon storage matron = dragons[_matronId];
        Dragon storage sire = dragons[_sireId];
        return _isValidMatingPair(matron, _matronId, sire, _sireId) &&
        _isSiringPermitted(_sireId, _matronId);
    }

    /// @dev Internal utility function to initiate breeding, assumes that all breeding
    ///  requirements have been checked.
    function _breedWith(uint256 _matronId, uint256 _sireId) internal {
        // Grab a reference to the Dragons from storage.
        // Dragon storage sire = dragons[_sireId];
        Dragon storage matron = dragons[_matronId];

        // Mark the matron as pregnant, keeping track of who the sire is.
        matron.siringWithId = uint32(_sireId);

        // Trigger the cooldown for both parents.
        // _triggerCooldown(sire);
        // _triggerCooldown(matron);

        // Clear siring permission for both parents. This may not be strictly necessary but it's likely to avoid confusion!
        delete sireAllowedToAddress[_matronId];
        delete sireAllowedToAddress[_sireId];

        // Every time a dragon gets pregnant, counter is incremented.
        pregnantDragons++;

        // Emit the pregnancy event.
        emit Pregnant(dragonIndexToOwner[_matronId], _matronId, _sireId);
    }

    /// @notice Breed a Dragon you own (as matron) with a sire that you own, or for which you
    ///  have previously been given Siring approval. Will either make your dragon pregnant, or will
    ///  fail entirely. Requires a pre-payment of the fee given out to the first caller of giveBirth()
    /// @param _matronId The ID of the Dragon acting as matron (will end up pregnant if successful)
    /// @param _sireId The ID of the Dragon acting as sire (will begin its siring cooldown if successful)
    function breedWithAuto(uint256 _matronId, uint256 _sireId)
    external
    payable
    whenNotPaused
    {
        // Checks for payment.
        require(msg.value >= autoBirthFee);

        // Caller must own the matron.
        require(_owns(msg.sender, _matronId));

        // Neither sire nor matron are allowed to be on auction during a normal
        // breeding operation, but we don't need to check that explicitly.
        // For matron: The caller of this function can't be the owner of the matron
        //   because the owner of a Dragon on auction is the auction house, and the
        //   auction house will never call breedWith().
        // For sire: Similarly, a sire on auction will be owned by the auction house
        //   and the act of transferring ownership will have cleared any oustanding
        //   siring approval.
        // Thus we don't need to spend gas explicitly checking to see if either dragon
        // is on auction.

        // Check that matron and sire are both owned by caller, or that the sire
        // has given siring permission to caller (i.e. matron's owner).
        // Will fail for _sireId = 0
        require(_isSiringPermitted(_sireId, _matronId));

        // Grab a reference to the potential matron
        Dragon storage matron = dragons[_matronId];

        // Make sure matron isn't pregnant, or in the middle of a siring cooldown
        require(_isReadyToBreed(matron));

        // Grab a reference to the potential sire
        Dragon storage sire = dragons[_sireId];

        // Make sure sire isn't pregnant, or in the middle of a siring cooldown
        require(_isReadyToBreed(sire));

        // Update the breedTime
        matron.breedTime = uint64(now);

        // Test that these dragons are a valid mating pair.
        require(_isValidMatingPair(
                matron,
                _matronId,
                sire,
                _sireId
            ));


        // All checks passed, dragon gets pregnant!
        _breedWith(_matronId, _sireId);
    }

    /// @notice Have a pregnant Dragon give birth!
    /// @param _matronId A Dragon ready to give birth.
    /// @param _dna Dragon's DNA
    /// @param _agility Dragon's agility initial value
    /// @param _strength Dragon's Strenght initial value
    /// @param _intelligence Dragon's Intelligence initial value
    /// @param _runelevel Dragon's Rune Level initial value
    /// @return The Dragon ID of the new dragon.
    /// @dev Looks at a given Dragon and, if pregnant and if the gestation period has passed,
    ///  combines the genes of the two parents to create a new dragon. The new Dragon is assigned
    ///  to the current owner of the matron. Upon successful completion, both the matron and the
    ///  new dragon will be ready to breed again. Note that anyone can call this function (if they
    ///  are willing to pay the gas!), but the new dragon always goes to the mother's owner.
    function giveBirth(uint256 _matronId, uint256 _dna, uint64 _agility, uint64 _strength, uint64 _intelligence, uint64 _runelevel)
    external
    whenNotPaused
    onlyCOO
    returns(uint256)
    {
        // Grab a reference to the matron in storage.
        Dragon storage matron = dragons[_matronId];

        // Check that the dragon is a valid dragon.
        require(matron.birthTime != 0);

        // Check that the matron is pregnant, and that its time has come!
        require(_isReadyToGiveBirth(matron));

        // Grab a reference to the sire in storage.
        uint256 sireId = matron.siringWithId;
        Dragon storage sire = dragons[sireId];

        // Determine the higher generation number of the two parents
        uint32 parentGen = matron.generation;
        if (sire.generation > matron.generation) {
            parentGen = sire.generation;
        }

        // Call the sooper-sekret gene mixing operation.
        uint256 matronId = _matronId;
        uint64 agility = _agility;
        uint64 strength = _strength;
        uint64 intelligence = _intelligence;
        uint64 runelevel = _runelevel;

        uint256 childDNA = _dna;

        // Make the new dragon!
        address owner = dragonIndexToOwner[matronId];
        //uint256 dragonId = _createDragon(_matronId, matron.siringWithId, parentGen + 1, childDNA, _agility, _strength, _intelligence, _runelevel, owner);
        uint256 dragonId = _createDragon(matronId, sireId, parentGen + 1, childDNA, agility, strength, intelligence, runelevel, owner);

        //increment the breeding for the matron
        breeding[matronId]++;

        // Clear the reference to sire from the matron (REQUIRED! Having siringWithId
        // set is what marks a matron as being pregnant.)
        delete matron.siringWithId;

        // Every time a dragon gives birth counter is decremented.
        pregnantDragons--;

        // Send the balance fee to the person who made birth happen.
        //msg.sender.send(autoBirthFee);
        msg.sender.transfer(autoBirthFee);

        // return the new dragon's ID
        return dragonId;
    }

    function getPregnantDragons() external view returns(uint256[] memory pregnantDragonsList) {

        if (pregnantDragons == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](pregnantDragons);
            uint256 totalDragons = totalSupply();
            uint256 resultIndex = 0;

             uint256 dragonId;

            for (dragonId = 1; dragonId <= totalDragons; dragonId++) {
                if (isPregnant(dragonId)) {
                    result[resultIndex] = dragonId;
                    resultIndex++;
                }
            }

            return result;
        }
    }

    function setBreedingLimit(uint32 _value) external onlyCLevel {
        BREEDING_LIMIT = _value;
    }
}

// File: contracts/DragonAuction.sol

pragma solidity ^0.5.10;


/// @title Handles creating auctions for sale and siring of dragons.
/// @author Zynappse Corporation (https://www.zynapse.com)
///  This wrapper of ReverseAuction exists only so that users can create
///  auctions with only one transaction.
contract DragonAuction is DragonBreeding {

    // @notice The auction contract variables are defined in DragonBase to allow
    //  us to refer to them in DragonOwnership to prevent accidental transfers.
    // `saleAuction` refers to the auction for gen0 and p2p sale of dragons.
    // `siringAuction` refers to the auction for siring rights of dragons.

    /// @dev Sets the reference to the sale auction.
    /// @param _address - Address of sale contract.
    function setSaleAuctionAddress(address _address) external onlyCEO {
        SaleClockAuction candidateContract = SaleClockAuction(_address);

        // NOTE: verify that a contract is what we expect - https://github.com/Lunyr/crowdsale-contracts/blob/cfadd15986c30521d8ba7d5b6f57b4fefcc7ac38/contracts/LunyrToken.sol#L117
        require(candidateContract.isSaleClockAuction());

        // Set the new contract address
        saleAuction = candidateContract;
    }

    /// @dev Sets the reference to the siring auction.
    /// @param _address - Address of siring contract.
    function setSiringAuctionAddress(address _address) external onlyCEO {
        SiringClockAuction candidateContract = SiringClockAuction(_address);

        // NOTE: verify that a contract is what we expect - https://github.com/Lunyr/crowdsale-contracts/blob/cfadd15986c30521d8ba7d5b6f57b4fefcc7ac38/contracts/LunyrToken.sol#L117
        require(candidateContract.isSiringClockAuction());

        // Set the new contract address
        siringAuction = candidateContract;
    }

    /// @dev Put a dragon up for auction.
    ///  Does some ownership trickery to create auctions in one tx.
    function createSaleAuction(
        uint256 _dragonId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration
    )
    external
    whenNotPaused
    {
        // Auction contract checks input sizes
        // If dragon is already on any auction, this will throw
        // because it will be owned by the auction contract.
        require(_owns(msg.sender, _dragonId));
        // Ensure the dragon is not pregnant to prevent the auction
        // contract accidentally receiving ownership of the child.
        // NOTE: the dragon IS allowed to be in a cooldown.
        require(!isPregnant(_dragonId));
        _approve(_dragonId, address(saleAuction));
        // Sale auction throws if inputs are invalid and clears
        // transfer and sire approval after escrowing the dragon.
        saleAuction.createAuction(
            _dragonId,
            _startingPrice,
            _endingPrice,
            _duration,
            msg.sender
        );
    }

    /// @dev Put a dragon up for auction to be sire.
    ///  Performs checks to ensure the dragon can be sired, then
    ///  delegates to reverse auction.
    function createSiringAuction(
        uint256 _dragonId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration
    )
    external
    whenNotPaused
    {
        // Auction contract checks input sizes
        // If dragon is already on any auction, this will throw
        // because it will be owned by the auction contract.
        require(_owns(msg.sender, _dragonId));
        require(isReadyToBreed(_dragonId));
        _approve(_dragonId, address(siringAuction));
        // Siring auction throws if inputs are invalid and clears
        // transfer and sire approval after escrowing the dragon.
        siringAuction.createAuction(
            _dragonId,
            _startingPrice,
            _endingPrice,
            _duration,
            msg.sender
        );
    }


    /// @dev Completes a siring auction by bidding.
    ///  Immediately breeds the winning matron with the sire on auction.
    /// @param _sireId - ID of the sire on auction.
    /// @param _matronId - ID of the matron owned by the bidder.
    function bidOnSiringAuction(
        uint256 _sireId,
        uint256 _matronId
    )
    external
    payable
    whenNotPaused
    {
        // Auction contract checks input sizes
        require(_owns(msg.sender, _matronId));
        require(isReadyToBreed(_matronId));
        require(_canBreedWithViaAuction(_matronId, _sireId));

        // Define the current price of the auction.
        uint256 currentPrice = siringAuction.getCurrentPrice(_sireId);
        require(msg.value >= currentPrice + autoBirthFee);

        // Siring auction will throw if the bid fails.
        siringAuction.bid.value(msg.value - autoBirthFee)(_sireId);
        _breedWith(uint32(_matronId), uint32(_sireId));
    }

    /// @dev Transfers the balance of the sale auction contract
    /// to the DragonCore contract. We use two-step withdrawal to
    /// prevent two transfer calls in the auction bid function.
    function withdrawAuctionBalances() external onlyCLevel {
        saleAuction.withdrawBalance();
        siringAuction.withdrawBalance();
    }

    /// @dev Shows the balance of the auction contracts.
    function getAuctionBalances() external view onlyCLevel returns (uint256, uint256) {
        return (
            address(saleAuction).balance,
            address(siringAuction).balance
        );
    }
}

// File: contracts/DragonMinting.sol

pragma solidity ^0.5.10;


/// @title all functions related to creating dragons
contract DragonMinting is DragonAuction {

    /// @dev we can create promo dragons, up to a limit. Only callable by CMO
    /// @param _dna the encoded genes of the dragons to be created, any value is accepted
    /// @param _owner the future owner of the created dragons. Default to contract CMO
    function createPromoDragon(
        uint256 _dna,
        uint64 _agility,
        uint64 _strength,
        uint64 _intelligence,
        uint64 _runelevel,
        address _owner)
        external onlyCLevel {

        address dragonOwner = _owner;
        if (dragonOwner == address(0)) {
            dragonOwner = cmoAddress;
        }

        _createDragon(0, 0, 0, _dna, _agility, _strength, _intelligence, _runelevel, dragonOwner);
    }

    /// @dev Creates a new gen0 dragon with the given dna and
    ///  creates an auction for it.
    function createGen0Auction(
        uint256 _dna,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint64 _agility,
        uint64 _strength,
        uint64 _intelligence,
        uint256 _duration )
        external onlyCLevel {

        //require(gen0CreatedCount < GEN0_CREATION_LIMIT);


        uint256 dragonId = _createDragon(0, 0, 0, _dna, _agility, _strength, _intelligence, 0, address(this));
        _approve(dragonId, address(saleAuction));

        saleAuction.createAuction(
            dragonId,
            _startingPrice,
            _endingPrice,
            _duration,
            address(uint160(address(this)))
        );

        //gen0CreatedCount++;
    }
}

// File: contracts/DragonCore.sol

pragma solidity ^0.5.10;


contract DragonCore is DragonMinting {

    // Set in case the core contract is broken and an upgrade is required
    address public newContractAddress;

    /// @notice Creates the main BlockDragonz smart contract instance.
    constructor () public {
        // Starts paused.
        paused = true;

        // the creator of the contract is the initial CEO
        ceoAddress = msg.sender;

        // the creator of the contract is also the initial CMO
        cmoAddress = msg.sender;

        // the creator of the contract is also the initial CIO
        cioAddress = msg.sender;

        // the creator of the contract is also the initial CFO
        cfoAddress = msg.sender;

        // the creator of the contract is also the initial COO
        cooAddress = msg.sender;

        // ERC-165 Base
        supportedInterfaces[0x01ffc9a7] = true;

        // ERC-721 Base
        supportedInterfaces[0x80ac58cd] = true;

        // ERC-721 Metadata
        supportedInterfaces[0x5b5e139f] = true;

        // ERC-721 Enumerable
        supportedInterfaces[0x780e9d63] = true;

        //ERC-721 Receiver
        supportedInterfaces[0x150b7a02] = true;

        // start with the mythical dragon 0 - so we don't have generation-0 parent issues
        _createDragon(0, 0, 0, uint256(-1), 0,0,0,0,  address(0));
    }

    function setNewAddress(address _newAddress) external onlyCEO whenPaused {
        newContractAddress = _newAddress;
        emit ContractUpgrade(_newAddress);
    }

    /// @notice No tipping!
    /// @dev Reject all Ether from being sent here, unless it's from one of the
    ///  two auction contracts. (Hopefully, we can prevent user accidents.)
    function() external payable {
        require(
            msg.sender == address(saleAuction) ||
            msg.sender == address(siringAuction)
        );
    }
    /// @notice Returns all the relevant information about a specific dragon.
    /// @param _id The ID of the dragon of interest.
    function getDragon(uint256 _id)
    external
    view
    returns (
        uint256 dna,
        uint256 birthTime,
        uint256 breedTime,
        uint256 matronId,
        uint256 sireId,
        uint256 siringWithId,
        uint256 generation,
        uint256 runeLevel,
        uint256 agility,
        uint256 strength,
        uint256 intelligence
    ) {
        Dragon storage dragon = dragons[_id];
        DragonAssets storage dragonAsset = dragonAssets[_id];

        dna = dragon.dna;
        birthTime = uint256(dragon.birthTime);
        breedTime = uint256(dragon.breedTime);
        matronId = uint256(dragon.matronId);
        sireId = uint256(dragon.sireId);
        siringWithId = uint256(dragon.siringWithId);
        generation = uint256(dragon.generation);
        runeLevel = dragonAsset.runeLevel;
        agility = dragonAsset.agility;
        strength = dragonAsset.strength;
        intelligence = dragonAsset.intelligence;
    }

    /// @dev Override unpause so it requires all external contract addresses
    ///  to be set before contract can be unpaused. Also, we can't have
    ///  newContractAddress set either, because then the contract was upgraded.
    /// @notice This is public rather than external so we can call super.unpause
    ///  without using an expensive CALL.
    function unpause() public onlyCEO whenPaused {
        require(address(saleAuction) != address(0));
        require(address(siringAuction) != address(0));
        require(newContractAddress == address(0));

        // Actually unpause the contract.
        super.unpause();
    }

    // @dev Allows the CIO to capture the balance available to the contract.
    function withdrawBalance() external onlyCLevel {
        uint256 balance = address(this).balance;
        // Subtract all the currently pregnant dragons we have, plus 1 of margin.
        uint256 subtractFees = (pregnantDragons + 1) * autoBirthFee;

        if (balance > subtractFees) {
            //cioAddress.send(balance - subtractFees);
            cfoAddress.transfer(balance - subtractFees);
        }
    }

    /// @dev Shows the contract's current balance.
    function getBalance() external view onlyCLevel returns (uint256) {
        return address(this).balance;
    }
}