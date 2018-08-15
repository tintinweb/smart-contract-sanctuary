pragma solidity ^0.4.24;

contract ERC721Receiver {
  /**
   * @dev Magic value to be returned upon successful reception of an NFT
   *  Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`,
   *  which can be also obtained as `ERC721Receiver(0).onERC721Received.selector`
   */
  bytes4 internal constant ERC721_RECEIVED = 0x150b7a02;

  /**
   * @notice Handle the receipt of an NFT
   * @dev The ERC721 smart contract calls this function on the recipient
   * after a `safetransfer`. This function MAY throw to revert and reject the
   * transfer. Return of other than the magic value MUST result in the 
   * transaction being reverted.
   * Note: the contract address is always the message sender.
   * @param _operator The address which called `safeTransferFrom` function
   * @param _from The address which previously owned the token
   * @param _tokenId The NFT identifier which is being transfered
   * @param _data Additional data with no specified format
   * @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
   */
  function onERC721Received(
    address _operator,
    address _from,
    uint256 _tokenId,
    bytes _data
  )
    public
    returns(bytes4);
}

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

interface ERC165 {

  /**
   * @notice Query if a contract implements an interface
   * @param _interfaceId The interface identifier, as specified in ERC-165
   * @dev Interface identification is specified in ERC-165. This function
   * uses less than 30,000 gas.
   */
  function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool);
}

contract ClockAuctionBase {

  /*
  * @dev Auction data structure
  */
  struct Auction {
    address seller;
    uint128 startingPrice;
    uint128 endingPrice;
    uint64 duration;
    uint64 startedAt;
  }

  /*
  * @dev References the ERC721 contract
  */
  ERC721Basic public nfContract;

  /*
  * @dev The owner&#39;s cut on each auction, measured in 1/100 of a percent
  * 1 = 0,001%
  * 1000 = 1%
  * 10000 = 10%
  * 10&#39;000 = 100%;
  */
  uint256 public ownerCut;

  /*
  * @dev Mapping from a token ID to an auction
  */
  mapping(uint256 => Auction) tokenIdToAuction;

  /*
  * @dev Auction events
  */
  event AuctionCreated(
    uint256 tokenId,
    uint256 startingPrice,
    uint256 endingPrice,
    uint256 duration
  );

  event AuctionSuccessful(
    uint256 tokenId,
    uint256 totalPrice,
    address winner
  );

  event AuctionCancelled(
    uint256 tokenId
  );

  /*
  * @dev Checks ownership of a token (uses the ERC721&#39; ownerOf() function)
  */
  function _owns(address _address, uint256 _tokenId)
  internal view returns (bool)
  {
    return (nfContract.ownerOf(_tokenId) == _address);
  }

  /*
  * @dev Transfers ownership of a token to this contract
  * Throws if the escrow fails
  */
  function _escrow(address _owner, uint256 _tokenId) internal {
    nfContract.transferFrom(_owner, this, _tokenId);
  }

  /*
  * @dev Transfers a token from this contract to another address
  * Throws if the transfer fails
  */
  function _transfer(address _toAddress, uint256 _tokenId) internal {
    nfContract.safeTransferFrom(address(this), _toAddress, _tokenId);
  }

  /*
  * @dev Adds an auction to the list of open auctions
  * Emits the AuctionCreated event
  */
  function _addAuction(uint256 _tokenId, Auction _auction) internal {
    // Require that all auctions have a duration of
    // at least one minute. (Keeps our math logic simple)
    require(_auction.duration >= 1 minutes);

    tokenIdToAuction[_tokenId] = _auction;

    emit AuctionCreated(
      uint256(_tokenId),
      uint256(_auction.startingPrice),
      uint256(_auction.endingPrice),
      uint256(_auction.duration)
    );
  }

  /*
  * @dev Cancels an auction
  * Emits the AuctionCancelled event
  */
  function _cancelAuction(uint256 _tokenId, address _seller) internal {
    _removeAuction(_tokenId);
    _transfer(_seller, _tokenId);
    emit AuctionCancelled(_tokenId);
  }

  /*
  * @dev Computes the price and transfers the winnings
  * Does NOT transfer ownership of the token
  * Emits the AuctionSuccessful event
  */
  function _bid(uint256 _tokenId, uint256 _bidAmount)
  internal returns (uint256)
  {
    // Get a reference to the auction
    Auction storage auction = tokenIdToAuction[_tokenId];

    // Check that the auction is open
    require(_isOnAuction(auction));

    // Check that the bid is >= to the current price of the auction
    uint256 price = _currentPrice(auction);
    require(_bidAmount >= price);

    // Get a reference to the seller
    address seller = auction.seller;

    // Remove the auction before sending the fees to the ownerCut
    // This prevents a reentrancy attack
    _removeAuction(_tokenId);

    // Transfer winnings to the seller
    if (price > 0) {
      // Compute the owner&#39;s cut
      // _computeCut is guaranteed to return a value <= price
      uint256 auctioneerCut = _computeCut(price);
      uint256 sellerProceeds = price - auctioneerCut;

      seller.transfer(sellerProceeds);
    }

    uint256 bidExcess = _bidAmount - price;
    msg.sender.transfer(bidExcess);

    emit AuctionSuccessful(_tokenId, price, msg.sender);
    return price;
  }

  /*
  * @dev Removes an auction from the open auctions
  */
  function _removeAuction(uint256 _tokenId) internal {
    delete tokenIdToAuction[_tokenId];
  }

  /*
  * @dev Check if a token is on auction
  */
  function _isOnAuction(Auction storage _auction)
  internal
  view
  returns (bool)
  {
    return (_auction.startedAt > 0);
  }

  /*
  * @dev Computes the current price of a token on auction
  */
  function _currentPrice(Auction storage _auction)
  internal
  view
  returns (uint256)
  {
    // Get seconds passed since start of auction
    uint256 secondsPassed = 0;

    if (now > _auction.startedAt) {
      secondsPassed = now - _auction.startedAt;
    }

    // Compute current price
    return _computeCurrentPrice(
      _auction.startingPrice,
      _auction.endingPrice,
      _auction.duration,
      secondsPassed
    );
  }

  /*
  * @dev Computes the current price of a token on auction
  */
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
    if (_secondsPassed >= _duration) {
      // Reached end of dynamic pricing, currentPrice = _endingPrice
      return _endingPrice;

    } else {
      // Dynamic pricing

      // Starting price will usually be higher than endingPrice
      // So delta will usually be negative, thus int256
      int256 totalPriceChange = int256(_endingPrice) - int256(_startingPrice);
      int256 currentPriceChange = totalPriceChange * int256(_secondsPassed) / int256(_duration);
      int256 currentPrice = int256(_startingPrice) + currentPriceChange;
      return uint256(currentPrice);
    }
  }

  /*
  * @dev Computes the owner&#39;s cut of an auction sale
  */
  function _computeCut(uint256 _price)
  internal
  view
  returns (uint256)
  {
    return _price * ownerCut / 10000;
  }
}

contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


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
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

contract GeneScienceInterface {
  bool public isGeneScience = true;

  function mixGenes(uint256 genes1, uint256 genes2) public returns (uint256);

  function randomGenes() public returns (uint256);

}

contract YummyAccessControl {

  event Pause();
  event Unpause();

  address public ceoAddress;
  address public cfoAddress;
  address public cooAddress;

  bool public paused = false;

  constructor() public {
    ceoAddress = msg.sender;
  }

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
      msg.sender == ceoAddress || msg.sender == cfoAddress || msg.sender == cooAddress
    );
    _;
  }

  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  modifier whenPaused {
    require(paused);
    _;
  }

  function setCEO(address _newCEO) external onlyCEO {
    require(_newCEO != address(0));
    ceoAddress = _newCEO;
  }

  function setCFO(address _newCFO) external onlyCEO {
    require(_newCFO != address(0));
    cfoAddress = _newCFO;
  }

  function setCOO(address _newCOO) external onlyCEO {
    require(_newCOO != address(0));
    cooAddress = _newCOO;
  }

  function pause() external onlyCLevel whenNotPaused {
    paused = true;
    emit Pause();
  }

  function unpause() public onlyCEO whenPaused {
    paused = false;
    emit Unpause();
  }
}

contract YummyBase is YummyAccessControl {

  event Birth(
    address owner,
    uint256 tokenId,
    uint256 motherId,
    uint256 fatherId,
    uint256 genes
  );

  struct Token {
    uint256 genes;
    uint64 creationTime;
    uint64 cooldownEndBlock;
    uint32 motherId;
    uint32 fatherId;
    uint32 breedingWithId;
    uint16 cooldownIndex;
    uint16 generation;
  }

  // Lookup table for cooldowns triggered after every breeding
  uint32[14] public cooldowns = [
    uint32(1 minutes),
    uint32(2 minutes),
    uint32(5 minutes),
    uint32(10 minutes),
    uint32(30 minutes),
    uint32(1 hours),
    uint32(2 hours),
    uint32(4 hours),
    uint32(8 hours),
    uint32(16 hours),
    uint32(1 days),
    uint32(2 days),
    uint32(4 days),
    uint32(7 days)
  ];

  // Approximation of block time used for computing cooldown end blocks
  uint256 public secondsPerBlock = 15;

  // Token storage, token ID is the index of the token in this array
  Token[] tokens;

  // Mapping from tokenId to an address that has been
  // approved to use this token for fathering via breedWith()
  mapping(uint256 => address) public fatherAllowedToAddress;

  // Address of the SaleCockAuction that handles peer-to-peer sales
  SaleClockAuction public saleAuction;

  // Address of the BreedingClockAuction that handles breeding auctions
  BreedingClockAuction public breedingAuction;

  /**
  * @dev Any C-level can set how many seconds per blocks are currently observed.
  */
  function setSecondsPerBlock(uint256 secs) external onlyCLevel {
    require(secs < cooldowns[0]);
    secondsPerBlock = secs;
  }
}

library AddressUtils {

  /**
   * Returns whether the target address is a contract
   * @dev This function will return false if invoked during the constructor of a contract,
   * as the code is not actually created until after the constructor finishes.
   * @param addr address to check
   * @return whether the target address is a contract
   */
  function isContract(address addr) internal view returns (bool) {
    uint256 size;
    // XXX Currently there is no better way to check if there is a contract in an address
    // than to check the size of the code at that address.
    // See https://ethereum.stackexchange.com/a/14016/36603
    // for more details about how this works.
    // TODO Check this again before the Serenity release, because all addresses will be
    // contracts then.
    // solium-disable-next-line security/no-inline-assembly
    assembly { size := extcodesize(addr) }
    return size > 0;
  }

}

contract SupportsInterfaceWithLookup is ERC165 {
  bytes4 public constant InterfaceId_ERC165 = 0x01ffc9a7;
  /**
   * 0x01ffc9a7 ===
   *   bytes4(keccak256(&#39;supportsInterface(bytes4)&#39;))
   */

  /**
   * @dev a mapping of interface id to whether or not it&#39;s supported
   */
  mapping(bytes4 => bool) internal supportedInterfaces;

  /**
   * @dev A contract implementing SupportsInterfaceWithLookup
   * implement ERC165 itself
   */
  constructor()
    public
  {
    _registerInterface(InterfaceId_ERC165);
  }

  /**
   * @dev implement supportsInterface(bytes4) using a lookup table
   */
  function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool)
  {
    return supportedInterfaces[_interfaceId];
  }

  /**
   * @dev private method for registering an interface
   */
  function _registerInterface(bytes4 _interfaceId)
    internal
  {
    require(_interfaceId != 0xffffffff);
    supportedInterfaces[_interfaceId] = true;
  }
}

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
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

contract ClockAuction is ClockAuctionBase, Pausable {

  bytes4 constant InterfaceSignature_ERC721 = bytes4(0x80ac58cd);

  /*
  * @dev Sets the owner cut and creates a reference to the NFT contract
  */
  constructor(address _nftAddress, uint256 _cut) public {
    require(_cut <= 10000);
    ownerCut = _cut;

    ERC721Basic candidateContract = ERC721Basic(_nftAddress);

    // Check that the candidate contract supports ERC721
    require(candidateContract.supportsInterface(InterfaceSignature_ERC721));
    nfContract = candidateContract;
  }

  /*
  * @dev Remove all Ether from the contract
  * Always transfers to the NFT contract, but can also be called by the owner
  */
  function withdrawBalance() external {
    address nftAddress = address(nfContract);

    require(
      msg.sender == owner ||
      msg.sender == nftAddress
    );

    // See KittyCore contract, line 1405
    bool res = nftAddress.send(address(this).balance);
  }

  /*
  * @dev Creates and starts a new auction
  */
  function createAuction(
    uint256 _tokenId,
    uint256 _startingPrice,
    uint256 _endingPrice,
    uint256 _duration,
    address _seller
  )
  external
  whenNotPaused
  {
    // Check that no inputs overflow allocated bits in the Auction struct
    require(_startingPrice == uint256(uint128(_startingPrice)));
    require(_endingPrice == uint256(uint128(_endingPrice)));
    require(_duration == uint256(uint64(_duration)));

    // Check that msg.sender owns the token
    require(_owns(msg.sender, _tokenId));

    // Escrow the token
    _escrow(msg.sender, _tokenId);

    // Create the auction and add it to open auctions
    Auction memory auction = Auction(
      _seller,
      uint128(_startingPrice),
      uint128(_endingPrice),
      uint64(_duration),
      uint64(now)
    );
    _addAuction(_tokenId, auction);
  }

  /*
  * @dev Bids on an open auction, completing the auction and transfering ownership
  */
  function bid(uint256 _tokenId)
  external
  payable
  whenNotPaused
  {
    _bid(_tokenId, msg.value);
    _transfer(msg.sender, _tokenId);
  }

  /*
  * @dev Bids on an open auction, completing the auction and transfering ownership
  */
  function cancelAuction(uint256 _tokenId)
  external
  {
    Auction storage auction = tokenIdToAuction[_tokenId];
    require(_isOnAuction(auction));
    address seller = auction.seller;
    require(msg.sender == seller);
    _cancelAuction(_tokenId, seller);
  }

  /*
  * @dev Cancels an auction when the contract is in paused state
  * @notice Use in emergencies only
  */
  function cancelAuctionWhenPaused(uint256 _tokenId)
  external
  whenPaused
  onlyOwner
  {
    Auction storage auction = tokenIdToAuction[_tokenId];
    require(_isOnAuction(auction));
    _cancelAuction(_tokenId, auction.seller);
  }

  /*
  * @dev Returns auction data related to a token
  */
  function getAuction(uint256 _tokenId)
  external
  view
  returns (
    address seller,
    uint256 startingPrice,
    uint256 endingPrice,
    uint256 duration,
    uint256 startedAt
  )
  {
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

  /*
  * @dev Returns auction data related to a token
  */
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

contract SaleClockAuction is ClockAuction {

  bool public isSaleClockAuction = true;

  uint gen0SalesCount;
  uint256[5] public lastGen0SalePrices;

  constructor(address _nftAddr, uint256 _cut)
  public ClockAuction(_nftAddr, _cut) {}

  function createAuction(
    uint256 _tokenId,
    uint256 _startingPrice,
    uint256 _endingPrice,
    uint256 _duration,
    address _seller
  )
  external
  {
    require(_startingPrice == uint256(uint128(_startingPrice)));
    require(_endingPrice == uint256(uint128(_endingPrice)));
    require(_duration == uint256(uint64(_duration)));

    require(msg.sender == address(nfContract));
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

  function bid(uint256 _tokenId)
  external
  payable
  {
    address seller = tokenIdToAuction[_tokenId].seller;
    uint256 price = _bid(_tokenId, msg.value);
    _transfer(msg.sender, _tokenId);

    if (seller == address(nfContract)) {
      lastGen0SalePrices[gen0SalesCount % 5] = price;
      gen0SalesCount++;
    }
  }

  function averageGen0SalePrice() external view returns (uint256) {
    uint256 sum = 0;
    for (uint256 i = 0; i < 5; i++) {
      sum += lastGen0SalePrices[i];
    }
    return sum / 5;
  }

}

contract BreedingClockAuction is ClockAuction {

  bool public isBreedingClockAuction = true;

  constructor(address _nftAddress, uint256 _cut)
  public ClockAuction(_nftAddress, _cut) {}

  function createAuction(
    uint256 _tokenId,
    uint256 _startingPrice,
    uint256 _endingPrice,
    uint256 _duration,
    address _seller
  )
  external
  {
    // Check for input overflows
    require(_startingPrice == uint256(uint128(_startingPrice)));
    require(_endingPrice == uint256(uint128(_endingPrice)));
    require(_duration == uint256(uint64(_duration)));

    require(msg.sender == address(nfContract));
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

  function bid(uint256 _tokenId)
  external
  payable
  {
    require(msg.sender == address(nfContract));
    address seller = tokenIdToAuction[_tokenId].seller;
    _bid(_tokenId, msg.value);
    _transfer(seller, _tokenId);
  }

}

contract ERC721Basic is ERC165 {
  event Transfer(
    address indexed _from,
    address indexed _to,
    uint256 indexed _tokenId
  );
  event Approval(
    address indexed _owner,
    address indexed _approved,
    uint256 indexed _tokenId
  );
  event ApprovalForAll(
    address indexed _owner,
    address indexed _operator,
    bool _approved
  );

  function balanceOf(address _owner) public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function exists(uint256 _tokenId) public view returns (bool _exists);

  function approve(address _to, uint256 _tokenId) public;
  function getApproved(uint256 _tokenId)
    public view returns (address _operator);

  function setApprovalForAll(address _operator, bool _approved) public;
  function isApprovedForAll(address _owner, address _operator)
    public view returns (bool);

  function transferFrom(address _from, address _to, uint256 _tokenId) public;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId)
    public;

  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    public;
}

contract ERC721Enumerable is ERC721Basic {
  function totalSupply() public view returns (uint256);
  function tokenOfOwnerByIndex(
    address _owner,
    uint256 _index
  )
    public
    view
    returns (uint256 _tokenId);

  function tokenByIndex(uint256 _index) public view returns (uint256);
}

contract ERC721Metadata is ERC721Basic {
  function name() external view returns (string _name);
  function symbol() external view returns (string _symbol);
  function tokenURI(uint256 _tokenId) public view returns (string);
}

contract ERC721 is ERC721Basic, ERC721Enumerable, ERC721Metadata {
}

contract ERC721BasicToken is SupportsInterfaceWithLookup, ERC721Basic {

  bytes4 private constant InterfaceId_ERC721 = 0x80ac58cd;
  /*
   * 0x80ac58cd ===
   *   bytes4(keccak256(&#39;balanceOf(address)&#39;)) ^
   *   bytes4(keccak256(&#39;ownerOf(uint256)&#39;)) ^
   *   bytes4(keccak256(&#39;approve(address,uint256)&#39;)) ^
   *   bytes4(keccak256(&#39;getApproved(uint256)&#39;)) ^
   *   bytes4(keccak256(&#39;setApprovalForAll(address,bool)&#39;)) ^
   *   bytes4(keccak256(&#39;isApprovedForAll(address,address)&#39;)) ^
   *   bytes4(keccak256(&#39;transferFrom(address,address,uint256)&#39;)) ^
   *   bytes4(keccak256(&#39;safeTransferFrom(address,address,uint256)&#39;)) ^
   *   bytes4(keccak256(&#39;safeTransferFrom(address,address,uint256,bytes)&#39;))
   */

  bytes4 private constant InterfaceId_ERC721Exists = 0x4f558e79;
  /*
   * 0x4f558e79 ===
   *   bytes4(keccak256(&#39;exists(uint256)&#39;))
   */

  using SafeMath for uint256;
  using AddressUtils for address;

  // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
  // which can be also obtained as `ERC721Receiver(0).onERC721Received.selector`
  bytes4 private constant ERC721_RECEIVED = 0x150b7a02;

  // Mapping from token ID to owner
  mapping (uint256 => address) internal tokenOwner;

  // Mapping from token ID to approved address
  mapping (uint256 => address) internal tokenApprovals;

  // Mapping from owner to number of owned token
  mapping (address => uint256) internal ownedTokensCount;

  // Mapping from owner to operator approvals
  mapping (address => mapping (address => bool)) internal operatorApprovals;

  /**
   * @dev Guarantees msg.sender is owner of the given token
   * @param _tokenId uint256 ID of the token to validate its ownership belongs to msg.sender
   */
  modifier onlyOwnerOf(uint256 _tokenId) {
    require(ownerOf(_tokenId) == msg.sender);
    _;
  }

  /**
   * @dev Checks msg.sender can transfer a token, by being owner, approved, or operator
   * @param _tokenId uint256 ID of the token to validate
   */
  modifier canTransfer(uint256 _tokenId) {
    require(isApprovedOrOwner(msg.sender, _tokenId));
    _;
  }

  constructor()
    public
  {
    // register the supported interfaces to conform to ERC721 via ERC165
    _registerInterface(InterfaceId_ERC721);
    _registerInterface(InterfaceId_ERC721Exists);
  }

  /**
   * @dev Gets the balance of the specified address
   * @param _owner address to query the balance of
   * @return uint256 representing the amount owned by the passed address
   */
  function balanceOf(address _owner) public view returns (uint256) {
    require(_owner != address(0));
    return ownedTokensCount[_owner];
  }

  /**
   * @dev Gets the owner of the specified token ID
   * @param _tokenId uint256 ID of the token to query the owner of
   * @return owner address currently marked as the owner of the given token ID
   */
  function ownerOf(uint256 _tokenId) public view returns (address) {
    address owner = tokenOwner[_tokenId];
    require(owner != address(0));
    return owner;
  }

  /**
   * @dev Returns whether the specified token exists
   * @param _tokenId uint256 ID of the token to query the existence of
   * @return whether the token exists
   */
  function exists(uint256 _tokenId) public view returns (bool) {
    address owner = tokenOwner[_tokenId];
    return owner != address(0);
  }

  /**
   * @dev Approves another address to transfer the given token ID
   * The zero address indicates there is no approved address.
   * There can only be one approved address per token at a given time.
   * Can only be called by the token owner or an approved operator.
   * @param _to address to be approved for the given token ID
   * @param _tokenId uint256 ID of the token to be approved
   */
  function approve(address _to, uint256 _tokenId) public {
    address owner = ownerOf(_tokenId);
    require(_to != owner);
    require(msg.sender == owner || isApprovedForAll(owner, msg.sender));

    tokenApprovals[_tokenId] = _to;
    emit Approval(owner, _to, _tokenId);
  }

  /**
   * @dev Gets the approved address for a token ID, or zero if no address set
   * @param _tokenId uint256 ID of the token to query the approval of
   * @return address currently approved for the given token ID
   */
  function getApproved(uint256 _tokenId) public view returns (address) {
    return tokenApprovals[_tokenId];
  }

  /**
   * @dev Sets or unsets the approval of a given operator
   * An operator is allowed to transfer all tokens of the sender on their behalf
   * @param _to operator address to set the approval
   * @param _approved representing the status of the approval to be set
   */
  function setApprovalForAll(address _to, bool _approved) public {
    require(_to != msg.sender);
    operatorApprovals[msg.sender][_to] = _approved;
    emit ApprovalForAll(msg.sender, _to, _approved);
  }

  /**
   * @dev Tells whether an operator is approved by a given owner
   * @param _owner owner address which you want to query the approval of
   * @param _operator operator address which you want to query the approval of
   * @return bool whether the given operator is approved by the given owner
   */
  function isApprovedForAll(
    address _owner,
    address _operator
  )
    public
    view
    returns (bool)
  {
    return operatorApprovals[_owner][_operator];
  }

  /**
   * @dev Transfers the ownership of a given token ID to another address
   * Usage of this method is discouraged, use `safeTransferFrom` whenever possible
   * Requires the msg sender to be the owner, approved, or operator
   * @param _from current owner of the token
   * @param _to address to receive the ownership of the given token ID
   * @param _tokenId uint256 ID of the token to be transferred
  */
  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    public
    canTransfer(_tokenId)
  {
    require(_from != address(0));
    require(_to != address(0));

    clearApproval(_from, _tokenId);
    removeTokenFrom(_from, _tokenId);
    addTokenTo(_to, _tokenId);

    emit Transfer(_from, _to, _tokenId);
  }

  /**
   * @dev Safely transfers the ownership of a given token ID to another address
   * If the target address is a contract, it must implement `onERC721Received`,
   * which is called upon a safe transfer, and return the magic value
   * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
   * the transfer is reverted.
   *
   * Requires the msg sender to be the owner, approved, or operator
   * @param _from current owner of the token
   * @param _to address to receive the ownership of the given token ID
   * @param _tokenId uint256 ID of the token to be transferred
  */
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    public
    canTransfer(_tokenId)
  {
    // solium-disable-next-line arg-overflow
    safeTransferFrom(_from, _to, _tokenId, "");
  }

  /**
   * @dev Safely transfers the ownership of a given token ID to another address
   * If the target address is a contract, it must implement `onERC721Received`,
   * which is called upon a safe transfer, and return the magic value
   * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
   * the transfer is reverted.
   * Requires the msg sender to be the owner, approved, or operator
   * @param _from current owner of the token
   * @param _to address to receive the ownership of the given token ID
   * @param _tokenId uint256 ID of the token to be transferred
   * @param _data bytes data to send along with a safe transfer check
   */
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    public
    canTransfer(_tokenId)
  {
    transferFrom(_from, _to, _tokenId);
    // solium-disable-next-line arg-overflow
    require(checkAndCallSafeTransfer(_from, _to, _tokenId, _data));
  }

  /**
   * @dev Returns whether the given spender can transfer a given token ID
   * @param _spender address of the spender to query
   * @param _tokenId uint256 ID of the token to be transferred
   * @return bool whether the msg.sender is approved for the given token ID,
   *  is an operator of the owner, or is the owner of the token
   */
  function isApprovedOrOwner(
    address _spender,
    uint256 _tokenId
  )
    internal
    view
    returns (bool)
  {
    address owner = ownerOf(_tokenId);
    // Disable solium check because of
    // https://github.com/duaraghav8/Solium/issues/175
    // solium-disable-next-line operator-whitespace
    return (
      _spender == owner ||
      getApproved(_tokenId) == _spender ||
      isApprovedForAll(owner, _spender)
    );
  }

  /**
   * @dev Internal function to mint a new token
   * Reverts if the given token ID already exists
   * @param _to The address that will own the minted token
   * @param _tokenId uint256 ID of the token to be minted by the msg.sender
   */
  function _mint(address _to, uint256 _tokenId) internal {
    require(_to != address(0));
    addTokenTo(_to, _tokenId);
    emit Transfer(address(0), _to, _tokenId);
  }

  /**
   * @dev Internal function to burn a specific token
   * Reverts if the token does not exist
   * @param _tokenId uint256 ID of the token being burned by the msg.sender
   */
  function _burn(address _owner, uint256 _tokenId) internal {
    clearApproval(_owner, _tokenId);
    removeTokenFrom(_owner, _tokenId);
    emit Transfer(_owner, address(0), _tokenId);
  }

  /**
   * @dev Internal function to clear current approval of a given token ID
   * Reverts if the given address is not indeed the owner of the token
   * @param _owner owner of the token
   * @param _tokenId uint256 ID of the token to be transferred
   */
  function clearApproval(address _owner, uint256 _tokenId) internal {
    require(ownerOf(_tokenId) == _owner);
    if (tokenApprovals[_tokenId] != address(0)) {
      tokenApprovals[_tokenId] = address(0);
    }
  }

  /**
   * @dev Internal function to add a token ID to the list of a given address
   * @param _to address representing the new owner of the given token ID
   * @param _tokenId uint256 ID of the token to be added to the tokens list of the given address
   */
  function addTokenTo(address _to, uint256 _tokenId) internal {
    require(tokenOwner[_tokenId] == address(0));
    tokenOwner[_tokenId] = _to;
    ownedTokensCount[_to] = ownedTokensCount[_to].add(1);
  }

  /**
   * @dev Internal function to remove a token ID from the list of a given address
   * @param _from address representing the previous owner of the given token ID
   * @param _tokenId uint256 ID of the token to be removed from the tokens list of the given address
   */
  function removeTokenFrom(address _from, uint256 _tokenId) internal {
    require(ownerOf(_tokenId) == _from);
    ownedTokensCount[_from] = ownedTokensCount[_from].sub(1);
    tokenOwner[_tokenId] = address(0);
  }

  /**
   * @dev Internal function to invoke `onERC721Received` on a target address
   * The call is not executed if the target address is not a contract
   * @param _from address representing the previous owner of the given token ID
   * @param _to target address that will receive the tokens
   * @param _tokenId uint256 ID of the token to be transferred
   * @param _data bytes optional data to send along with the call
   * @return whether the call correctly returned the expected magic value
   */
  function checkAndCallSafeTransfer(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    internal
    returns (bool)
  {
    if (!_to.isContract()) {
      return true;
    }
    bytes4 retval = ERC721Receiver(_to).onERC721Received(
      msg.sender, _from, _tokenId, _data);
    return (retval == ERC721_RECEIVED);
  }
}

contract ERC721Token is SupportsInterfaceWithLookup, ERC721BasicToken, ERC721 {

  bytes4 private constant InterfaceId_ERC721Enumerable = 0x780e9d63;
  /**
   * 0x780e9d63 ===
   *   bytes4(keccak256(&#39;totalSupply()&#39;)) ^
   *   bytes4(keccak256(&#39;tokenOfOwnerByIndex(address,uint256)&#39;)) ^
   *   bytes4(keccak256(&#39;tokenByIndex(uint256)&#39;))
   */

  bytes4 private constant InterfaceId_ERC721Metadata = 0x5b5e139f;
  /**
   * 0x5b5e139f ===
   *   bytes4(keccak256(&#39;name()&#39;)) ^
   *   bytes4(keccak256(&#39;symbol()&#39;)) ^
   *   bytes4(keccak256(&#39;tokenURI(uint256)&#39;))
   */

  // Token name
  string internal name_;

  // Token symbol
  string internal symbol_;

  // Mapping from owner to list of owned token IDs
  mapping(address => uint256[]) internal ownedTokens;

  // Mapping from token ID to index of the owner tokens list
  mapping(uint256 => uint256) internal ownedTokensIndex;

  // Array with all token ids, used for enumeration
  uint256[] internal allTokens;

  // Mapping from token id to position in the allTokens array
  mapping(uint256 => uint256) internal allTokensIndex;

  // Optional mapping for token URIs
  mapping(uint256 => string) internal tokenURIs;

  /**
   * @dev Constructor function
   */
  constructor(string _name, string _symbol) public {
    name_ = _name;
    symbol_ = _symbol;

    // register the supported interfaces to conform to ERC721 via ERC165
    _registerInterface(InterfaceId_ERC721Enumerable);
    _registerInterface(InterfaceId_ERC721Metadata);
  }

  /**
   * @dev Gets the token name
   * @return string representing the token name
   */
  function name() external view returns (string) {
    return name_;
  }

  /**
   * @dev Gets the token symbol
   * @return string representing the token symbol
   */
  function symbol() external view returns (string) {
    return symbol_;
  }

  /**
   * @dev Returns an URI for a given token ID
   * Throws if the token ID does not exist. May return an empty string.
   * @param _tokenId uint256 ID of the token to query
   */
  function tokenURI(uint256 _tokenId) public view returns (string) {
    require(exists(_tokenId));
    return tokenURIs[_tokenId];
  }

  /**
   * @dev Gets the token ID at a given index of the tokens list of the requested owner
   * @param _owner address owning the tokens list to be accessed
   * @param _index uint256 representing the index to be accessed of the requested tokens list
   * @return uint256 token ID at the given index of the tokens list owned by the requested address
   */
  function tokenOfOwnerByIndex(
    address _owner,
    uint256 _index
  )
    public
    view
    returns (uint256)
  {
    require(_index < balanceOf(_owner));
    return ownedTokens[_owner][_index];
  }

  /**
   * @dev Gets the total amount of tokens stored by the contract
   * @return uint256 representing the total amount of tokens
   */
  function totalSupply() public view returns (uint256) {
    return allTokens.length;
  }

  /**
   * @dev Gets the token ID at a given index of all the tokens in this contract
   * Reverts if the index is greater or equal to the total number of tokens
   * @param _index uint256 representing the index to be accessed of the tokens list
   * @return uint256 token ID at the given index of the tokens list
   */
  function tokenByIndex(uint256 _index) public view returns (uint256) {
    require(_index < totalSupply());
    return allTokens[_index];
  }

  /**
   * @dev Internal function to set the token URI for a given token
   * Reverts if the token ID does not exist
   * @param _tokenId uint256 ID of the token to set its URI
   * @param _uri string URI to assign
   */
  function _setTokenURI(uint256 _tokenId, string _uri) internal {
    require(exists(_tokenId));
    tokenURIs[_tokenId] = _uri;
  }

  /**
   * @dev Internal function to add a token ID to the list of a given address
   * @param _to address representing the new owner of the given token ID
   * @param _tokenId uint256 ID of the token to be added to the tokens list of the given address
   */
  function addTokenTo(address _to, uint256 _tokenId) internal {
    super.addTokenTo(_to, _tokenId);
    uint256 length = ownedTokens[_to].length;
    ownedTokens[_to].push(_tokenId);
    ownedTokensIndex[_tokenId] = length;
  }

  /**
   * @dev Internal function to remove a token ID from the list of a given address
   * @param _from address representing the previous owner of the given token ID
   * @param _tokenId uint256 ID of the token to be removed from the tokens list of the given address
   */
  function removeTokenFrom(address _from, uint256 _tokenId) internal {
    super.removeTokenFrom(_from, _tokenId);

    uint256 tokenIndex = ownedTokensIndex[_tokenId];
    uint256 lastTokenIndex = ownedTokens[_from].length.sub(1);
    uint256 lastToken = ownedTokens[_from][lastTokenIndex];

    ownedTokens[_from][tokenIndex] = lastToken;
    ownedTokens[_from][lastTokenIndex] = 0;
    // Note that this will handle single-element arrays. In that case, both tokenIndex and lastTokenIndex are going to
    // be zero. Then we can make sure that we will remove _tokenId from the ownedTokens list since we are first swapping
    // the lastToken to the first position, and then dropping the element placed in the last position of the list

    ownedTokens[_from].length--;
    ownedTokensIndex[_tokenId] = 0;
    ownedTokensIndex[lastToken] = tokenIndex;
  }

  /**
   * @dev Internal function to mint a new token
   * Reverts if the given token ID already exists
   * @param _to address the beneficiary that will own the minted token
   * @param _tokenId uint256 ID of the token to be minted by the msg.sender
   */
  function _mint(address _to, uint256 _tokenId) internal {
    super._mint(_to, _tokenId);

    allTokensIndex[_tokenId] = allTokens.length;
    allTokens.push(_tokenId);
  }

  /**
   * @dev Internal function to burn a specific token
   * Reverts if the token does not exist
   * @param _owner owner of the token to burn
   * @param _tokenId uint256 ID of the token being burned by the msg.sender
   */
  function _burn(address _owner, uint256 _tokenId) internal {
    super._burn(_owner, _tokenId);

    // Clear metadata (if any)
    if (bytes(tokenURIs[_tokenId]).length != 0) {
      delete tokenURIs[_tokenId];
    }

    // Reorg all tokens array
    uint256 tokenIndex = allTokensIndex[_tokenId];
    uint256 lastTokenIndex = allTokens.length.sub(1);
    uint256 lastToken = allTokens[lastTokenIndex];

    allTokens[tokenIndex] = lastToken;
    allTokens[lastTokenIndex] = 0;

    allTokens.length--;
    allTokensIndex[_tokenId] = 0;
    allTokensIndex[lastToken] = tokenIndex;
  }

}

contract YummyOwnership is YummyBase, ERC721Token {

  bytes4 constant InterfaceSignature_ERC165 = bytes4(0x01ffc9a7);

  bytes4 constant InterfaceSignature_ERC721 = bytes4(0x80ac58cd);

  function supportsInterface(bytes4 _interfaceID)
  external view returns (bool)
  {
    return (
    _interfaceID == InterfaceSignature_ERC165 ||
    _interfaceID == InterfaceSignature_ERC721
    );
  }

  function burn(uint256 tokenId) external whenNotPaused {
    // fails if msg.sender is not owner of tokenId
    super._burn(msg.sender, tokenId);
  }

  /* Override ownerOf function */
  function ownerOf(uint256 _tokenId) public view returns (address) {
    address owner = tokenOwner[_tokenId];
    //        require(owner != address(0)); // this is the change
    return owner;
  }

}

contract YummyBreeding is YummyOwnership {

  /**
  * @dev The Pregnant event is fired when two Yummies successfully combine to create a new Yummy
  * Starts the timer for the mother
  */
  event Pregnant(
    address owner,
    uint256 motherId,
    uint256 fatherId,
    uint256 cooldownEndBlock
  );

  /**
  * @dev The minimum payment required to use autoBreed
  * The fee goes towards the gas cost used to call giveBirth()
  */
  uint256 public autoBirthFee = 3 finney;

  /**
  * @dev Number of pregnant tokens
  */
  uint256 public pregnantTokens;

  /**
  * @dev Gene science contract
  */
  GeneScienceInterface public geneScience;

  function setGeneScienceAddress(address _address) external onlyCLevel {
    GeneScienceInterface candidateContract = GeneScienceInterface(_address);
    require(candidateContract.isGeneScience());
    geneScience = candidateContract;
  }

  /**
  * @dev Grant approval for breeding to another user with one of your tokens
  */
  function approveBreeding(address _addr, uint256 _fatherId)
  external onlyOwnerOf(_fatherId) whenNotPaused
  {
    fatherAllowedToAddress[_fatherId] = _addr;
  }

  /**
  * @dev Updates the minimum payment required for calling giveBirthAuto()
  * This fee is used to offset the gas cost incurred by the autobirth daemon
  */
  function setAutoBirthFee(uint256 val) external onlyCLevel {
    autoBirthFee = val;
  }

  /**
   * @dev Checks ownership and approval for breeding
   * @notice Does NOT check breeding cooldown and pregnancy
   */
  function canBreedWith(uint256 _motherId, uint256 _fatherId)
  external
  view
  returns (bool)
  {
    require(_motherId > 0);
    require(_fatherId > 0);
    Token storage mother = tokens[_motherId];
    Token storage father = tokens[_fatherId];
    return _isValidBreedingPair(
      mother,
      _motherId,
      father,
      _fatherId
    ) && _isBreedingPermitted(_fatherId, _motherId);
  }

  /**
   * @dev Breed tokens. Will either make the mother pregnant, or fail completely
   * @notice Requires a prepayment of the fee given out to the first caller of giveBirth()
   * If successful, mother becomes pregnant and father&#39;s cooldown begins
   */
  function breedWithAuto(uint256 _motherId, uint256 _fatherId)
  external
  payable
  onlyOwnerOf(_motherId)
  whenNotPaused
  {
    // Check payment
    require(msg.value >= autoBirthFee);

    // Check that mother and father are owned or breeding-approved for the caller
    require(_isBreedingPermitted(_fatherId, _motherId));

    // Check that tokens are not pregnant or under cooldown
    Token storage mother = tokens[_motherId];
    require(_isReadyToBreed(mother));
    Token storage father = tokens[_fatherId];
    require(_isReadyToBreed(father));

    // Test validity of the couple
    require(
      _isValidBreedingPair(
        mother,
        _motherId,
        father,
        _fatherId
      )
    );

    // Make a baby
    _breedWith(_motherId, _fatherId);

  }

  /**
   * @dev A pregnant token gives birth
   */
  function giveBirth(uint256 _motherId)
  external
  whenNotPaused
  returns (uint256)
  {
    // Get storage reference to mother token
    Token storage mother = tokens[_motherId];

    // Check validity and breeding readiness of mother
    require(mother.creationTime != 0);
    require(_isReadyToGiveBirth(mother));

    uint256 fatherId = mother.breedingWithId;
    Token storage father = tokens[fatherId];

    // Get higher generation number of parents
    uint16 parentGeneration = mother.generation;
    if (father.generation > mother.generation) {
      parentGeneration = father.generation;
    }

    // Compute the new token&#39;s DNA
    uint256 genes = geneScience.mixGenes(father.genes, mother.genes);

    // Create the new token
    address owner = tokenOwner[_motherId];
    uint256 tokenId = _createToken(
      _motherId,
      fatherId,
      parentGeneration + 1,
      genes,
      owner
    );

    // Clear reference to father
    delete mother.breedingWithId;

    pregnantTokens--;

    // Send the balance fee to the person who made birth happen
    msg.sender.transfer(autoBirthFee);

    // Return the new token&#39;s ID
    return tokenId;
  }

  /**
  * @dev Checks if a given token is able to breed (not pregnant and not under cooldown)
  */
  function isReadyToBreed(uint256 _tokenId) public view returns (bool) {
    require(_tokenId > 0);
    // genesis token cannot breed ?
    Token storage token = tokens[_tokenId];
    return _isReadyToBreed(token);
  }

  /**
  * @dev Check if a token is pregnant
  */
  function isPregnant(uint256 _tokenId) public view returns (bool) {
    require(_tokenId > 0);
    return tokens[_tokenId].breedingWithId != 0;
  }

  /*
  * @dev Assigns ownership of a token to an address
  */
  function _transfer(address _from, address _to, uint256 _tokenId) internal {
    ownedTokensCount[_to]++;
    tokenOwner[_tokenId] = _to;
    if (_from != address(0)) {
      ownedTokensCount[_from]--;
      delete fatherAllowedToAddress[_tokenId];
      delete tokenApprovals[_tokenId];
    }
    emit Transfer(_from, _to, _tokenId);
  }

  /*
  * @dev Internal method for creating and storing a token
  * @dev Doesn&#39;t check anything and should only be called with valid data
  */
  function _createToken(
    uint256 _motherId,
    uint256 _fatherId,
    uint256 _generation,
    uint256 _genes,
    address _owner
  )
  internal
  returns (uint)
  {
    require(_motherId == uint256(uint32(_motherId)));
    require(_fatherId == uint256(uint32(_fatherId)));
    require(_generation == uint256(uint16(_generation)));

    // New token starts with gen/2 cooldown index
    uint16 cooldownIndex = uint16(_generation / 2);
    if (cooldownIndex > 13) {
      cooldownIndex = 13;
    }

    Token memory _token = Token({
      genes : _genes,
      creationTime : uint64(now),
      cooldownEndBlock : 0,
      motherId : uint32(_motherId),
      fatherId : uint32(_fatherId),
      breedingWithId : 0,
      cooldownIndex : cooldownIndex,
      generation : uint16(_generation)
      });

    uint256 newTokenId = tokens.push(_token) - 1;

    require(newTokenId == uint256(uint32(newTokenId)));

    // Emits the creation event
    emit Birth(
      _owner,
      newTokenId,
      uint256(_token.motherId),
      uint256(_token.fatherId),
      _token.genes
    );

    _mint(_owner, newTokenId);

    return newTokenId;
  }

  /**
  * @dev Number of pregnant tokens
  */
  function _isReadyToBreed(Token _token) internal view returns (bool) {
    return (
    _token.breedingWithId == 0 &&
    _token.cooldownEndBlock <= uint64(block.number)
    );
  }

  /**
  * @dev Check if a father has authorized breeding with this mother
  * True if owner of mother and father are the same address or if father has been given breeding permission
  */
  function _isBreedingPermitted(uint256 _fatherId, uint256 _motherId)
  internal view returns (bool)
  {
    address motherOwner = tokenOwner[_motherId];
    address fatherOwner = tokenOwner[_fatherId];

    return (
      motherOwner == fatherOwner ||
      fatherAllowedToAddress[_fatherId] == motherOwner
    );
  }

  /**
  * @dev Set the cooldown end block for the token, based on it&#39;s current cooldownIndex
  * Increment cooldownIndex if it hasn&#39;t hit the cap
  */
  function _triggerCooldown(Token storage _token) internal {
    _token.cooldownEndBlock = uint64(
      (cooldowns[_token.cooldownIndex] / secondsPerBlock) + block.number
    );
    if (_token.cooldownIndex < 13) {
      _token.cooldownIndex += 1;
    }
  }

  /**
  * @dev Internal check if a given mother and father are a valid pair for auction breeding
  * @notice Skips ownership and breeding approval checks
  */
  function _canBreedViaAuction(uint256 _motherId, uint256 _fatherId)
  internal
  view
  returns (bool)
  {
    Token storage mother = tokens[_motherId];
    Token storage father = tokens[_fatherId];
    return _isValidBreedingPair(
      mother,
      _motherId,
      father,
      _fatherId
    );
  }

  /**
   * @dev Internal breeding function
   * @notice Assumes all breeding requirements are done
   */
  function _breedWith(uint256 _motherId, uint256 _fatherId) internal {
    // Get a reference to tokens from storage
    Token storage mother = tokens[_motherId];
    Token storage father = tokens[_fatherId];

    // Set the mother as pregnant and keep track of father
    mother.breedingWithId = uint32(_fatherId);

    // Trigger cooldown for both parents
    _triggerCooldown(father);
    _triggerCooldown(mother);

    // count pregnancies
    pregnantTokens++;

    // emit Pregnant event
    emit Pregnant(
      tokenOwner[_motherId],
      _motherId,
      _fatherId,
      mother.cooldownEndBlock
    );
  }

  /**
  * @dev Checks if a given token is pregnant and if the pregnancy is over
  */
  function _isReadyToGiveBirth(Token _mother) private view returns (bool) {
    return (_mother.breedingWithId != 0) &&
    (_mother.cooldownEndBlock <= uint64(block.number));
  }

  /**
  * @dev Checks if a given father-mother pair is valid
  * @notice WARNING : Does not check ownership permissions (this is up to caller)
  */
  function _isValidBreedingPair(
    Token storage _mother,
    uint256 _motherId,
    Token storage _father,
    uint256 _fatherId
  )
  private
  view
  returns (bool)
  {
    // No self-breeding
    if (_motherId == _fatherId) {return false;}

    // No breeding token&#39;s father
    if (_mother.motherId == _fatherId || _mother.fatherId == _fatherId) {
      return false;
    }

    // No breeding token&#39;s mother
    if (_father.motherId == _motherId || _mother.fatherId == _motherId) {
      return false;
    }

    // Shortcut the sibling check for gen0 tokens
    if (_father.motherId == 0 || _mother.motherId == 0) {return true;}

    // No breeding with siblings
    if (_father.motherId == _mother.motherId ||
      _father.motherId == _mother.fatherId) {
      return false;
    }
    if (_father.fatherId == _mother.motherId ||
    _father.fatherId == _mother.fatherId) {
      return false;
    }

    return true;
  }

}

contract YummyAuction is YummyBreeding {

  function setSaleAuctionAddress(address _address) external onlyCEO {
    SaleClockAuction candidateContract = SaleClockAuction(_address);
    require(candidateContract.isSaleClockAuction());
    saleAuction = candidateContract;
  }

  function setBreedingAuctionAddress(address _address) external onlyCEO {
    BreedingClockAuction candidateContract = BreedingClockAuction(_address);
    require(candidateContract.isBreedingClockAuction());
    breedingAuction = candidateContract;
  }

  function createSaleAuction(
    uint256 _tokenId,
    uint256 _startingPrice,
    uint256 _endingPrice,
    uint256 _duration
  )
  external
  whenNotPaused
  onlyOwnerOf(_tokenId)
  {
    require(!isPregnant(_tokenId));
    approve(saleAuction, _tokenId);
    saleAuction.createAuction(
      _tokenId,
      _startingPrice,
      _endingPrice,
      _duration,
      msg.sender
    );

  }

  function createBreedingAuction(
    uint256 _tokenId,
    uint256 _startingPrice,
    uint256 _endingPrice,
    uint256 _duration
  )
  external
  whenNotPaused
  onlyOwnerOf(_tokenId)
  {
    require(isReadyToBreed(_tokenId));
    approve(breedingAuction, _tokenId);
    breedingAuction.createAuction(
      _tokenId,
      _startingPrice,
      _endingPrice,
      _duration,
      msg.sender
    );
  }

  function bidOnBreedingAuction(
    uint256 _fatherId,
    uint256 _motherId
  )
  external
  payable
  whenNotPaused
  onlyOwnerOf(_motherId)
  {
    require(isReadyToBreed(_motherId));
    require(_canBreedViaAuction(_motherId, _fatherId));

    uint256 currentPrice = breedingAuction.getCurrentPrice(_fatherId);
    require(msg.value >= currentPrice + autoBirthFee);

    breedingAuction.bid.value(msg.value - autoBirthFee)(_fatherId);
    _breedWith(uint32(_motherId), uint32(_fatherId));
  }

  function withdrawAuctionBalances() external onlyCLevel {
    saleAuction.withdrawBalance();
    breedingAuction.withdrawBalance();
  }
}

contract YummyMinting is YummyAuction {

  uint256 public constant PROMO_CREATION_LIMIT = 5000;
  uint256 public constant GEN0_CREATION_LIMIT = 45000;

  uint256 public constant GEN0_STARTING_PRICE = 20 finney;
  uint256 public constant GEN0_AUCTION_DURATION = 1 days;

  uint256 public promoCreatedCount;
  uint256 gen0CreatedCount;

  function createPromoToken(
    uint256 _genes,
    address _owner
  )
  external
  onlyCOO
  {
    address tokenOwner = _owner;
    if (tokenOwner == address(0)) {
      tokenOwner = cooAddress;
    }
    require(promoCreatedCount < PROMO_CREATION_LIMIT);

    _createToken(
      0,
      0,
      0,
      _genes,
      tokenOwner
    );

    promoCreatedCount++;
  }

  function createGen0Auction(
    uint256 _genes
  )
  external
  onlyCOO
  {
    require(gen0CreatedCount < GEN0_CREATION_LIMIT);

    uint256 tokenId = _createToken(
      0,
      0,
      0,
      _genes,
      cooAddress
    );

    approve(saleAuction, tokenId);

    saleAuction.createAuction(
      tokenId,
      _computeNextGen0Price(),
      0,
      GEN0_AUCTION_DURATION,
      cooAddress
    );

    gen0CreatedCount++;
  }

  function _computeNextGen0Price() internal view returns (uint256) {
    uint256 avePrice = saleAuction.averageGen0SalePrice();

    require(avePrice == uint256(uint128(avePrice)));

    uint256 nextPrice = avePrice + (avePrice / 2);

    if (nextPrice < GEN0_STARTING_PRICE) {
      nextPrice = GEN0_STARTING_PRICE;
    }

    return nextPrice;
  }

  /**
  * @dev DEBUG
  */
  //    function createGen0Token(address _recipient)
  //    external
  //    onlyCOO
  //    returns (uint tokenId)
  //    {
  //        require(_recipient != address(0));
  //        require(gen0CreatedCount < GEN0_CREATION_LIMIT);
  //
  //        uint genes = geneScience.randomGenes();
  //        tokenId = _createToken(0, 0, 0, genes, _recipient);
  //
  //        gen0CreatedCount++;
  //    }
}

contract YummyCore is YummyMinting {

  constructor(string _name, string _symbol) public
  ERC721Token(_name, _symbol) {
    paused = true;
    emit Pause();

    ceoAddress = msg.sender;
    cooAddress = msg.sender;
    cfoAddress = msg.sender;

    _createToken(
      0,
      0,
      0,
      0,
      msg.sender
    );
  }

  function() external payable {
    require(
      msg.sender == address(breedingAuction) ||
      msg.sender == address(saleAuction)
    );
  }

  function getToken(uint256 _id)
  external view returns (
    bool isPregnant,
    bool isReady,
    uint256 cooldownIndex,
    uint256 nextActionAt,
    uint256 breedingWithId,
    uint256 creationTime,
    uint256 motherId,
    uint256 fatherId,
    uint256 generation,
    uint256 genes
  )
  {
    Token storage token = tokens[_id];

    isPregnant = (token.breedingWithId != 0);
    isReady = (token.cooldownEndBlock <= block.number);
    cooldownIndex = uint256(token.cooldownIndex);
    nextActionAt = uint256(token.cooldownEndBlock);
    breedingWithId = uint256(token.breedingWithId);
    creationTime = uint256(token.creationTime);
    motherId = uint256(token.motherId);
    fatherId = uint256(token.fatherId);
    generation = uint256(token.generation);
    genes = token.genes;
  }

  function withdrawBalance() external onlyCFO {
    uint256 balance = address(this).balance;
    uint256 subtractFees = (pregnantTokens + 1) * autoBirthFee;
    if (balance > subtractFees) {
      cfoAddress.transfer(balance - subtractFees);
    }
  }

  function unpause() public onlyCLevel whenPaused {
    require(saleAuction != address(0));
    require(breedingAuction != address(0));
    require(geneScience != address(0));

    super.unpause();
  }

}