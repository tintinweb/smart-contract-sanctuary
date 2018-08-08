pragma solidity ^0.4.23;


/**
 * @title Interface for contracts conforming to ERC-721: Non-Fungible Tokens
 */
contract ERC721 {
  event Transfer(
    address indexed from,
    address indexed to,
    uint256 indexed tokenId
  );
  event Approval(
    address indexed owner,
    address indexed approved,
    uint256 indexed tokenId
  );

  function implementsERC721() public pure returns (bool);
  function totalSupply() public view returns (uint256 total);
  function balanceOf(address _owner) public view returns (uint256 balance);
  function ownerOf(uint256 _tokenId) external view returns (address owner);
  function approve(address _to, uint256 _tokenId) external;
  function transfer(address _to, uint256 _tokenId) external;
  function transferFrom(address _from, address _to, uint256 _tokenId) external;
}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 *      functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   *      account.
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
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
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
   * @dev Called by the owner to pause, triggers stopped state.
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

  /**
   * @dev Called by the owner to unpause, returns to normal state.
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}


/**
 * @title CurioAuction
 * @dev CurioAuction contract implements clock auction for tokens sale.
 */
contract CurioAuction is Pausable {
  event AuctionCreated(
    uint256 indexed tokenId,
    uint256 startingPrice,
    uint256 endingPrice,
    uint256 duration
  );
  event AuctionSuccessful(
    uint256 indexed tokenId,
    uint256 totalPrice,
    address indexed winner
  );
  event AuctionCancelled(uint256 indexed tokenId);

  // Represents an auction on a token
  struct Auction {
    // Current owner of token
    address seller;
    // Price (in wei) at beginning of auction
    uint128 startingPrice;
    // Price (in wei) at end of auction
    uint128 endingPrice;
    // Duration (in seconds) of auction
    uint64 duration;
    // Time when auction started (0 if this auction has been concluded)
    uint64 startedAt;
  }

  // Check that this contract is correct for Curio main contract
  bool public isCurioAuction = true;

  // Reference to token contract
  ERC721 public tokenContract;

  // Value of fee (1/100 of a percent; 0-10,000 map to 0%-100%)
  uint256 public feePercent;

  // Map from token ID to auction
  mapping (uint256 => Auction) tokenIdToAuction;

  // Count of release tokens sold by auction
  uint256 public releaseTokensSaleCount;

  // Limit of start and end prices in wei
  uint256 public auctionPriceLimit;

  /**
   * @dev Constructor function
   * @param _tokenAddress Address of ERC721 token contract (Curio core contract)
   * @param _fee Percent of fee (0-10,000)
   * @param _auctionPriceLimit Limit of start and end price in auction (in wei)
   */
  constructor(
    address _tokenAddress,
    uint256 _fee,
    uint256 _auctionPriceLimit
  )
    public
  {
    require(_fee <= 10000);
    feePercent = _fee;

    ERC721 candidateContract = ERC721(_tokenAddress);
    require(candidateContract.implementsERC721());

    tokenContract = candidateContract;

    require(_auctionPriceLimit == uint256(uint128(_auctionPriceLimit)));
    auctionPriceLimit = _auctionPriceLimit;
  }


  // -----------------------------------------
  // External interface
  // -----------------------------------------


  /**
   * @dev Creates a new auction.
   * @param _tokenId ID of token to auction, sender must be owner
   * @param _startingPrice Price of item (in wei) at beginning of auction
   * @param _endingPrice Price of item (in wei) at end of auction
   * @param _duration Length of auction (in seconds)
   * @param _seller Seller address
   */
  function createAuction(
    uint256 _tokenId,
    uint256 _startingPrice,
    uint256 _endingPrice,
    uint256 _duration,
    address _seller
  )
    whenNotPaused
    external
  {
    // Overflow and limitation input check
    require(_startingPrice == uint256(uint128(_startingPrice)));
    require(_startingPrice < auctionPriceLimit);

    require(_endingPrice == uint256(uint128(_endingPrice)));
    require(_endingPrice < auctionPriceLimit);

    require(_duration == uint256(uint64(_duration)));

    // Check call from token contract
    require(msg.sender == address(tokenContract));

    // Transfer token from seller to this contract
    _deposit(_seller, _tokenId);

    // Create an auction
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
   * @dev Returns auction info for a token on auction.
   * @param _tokenId ID of token on auction
   */
  function getAuction(uint256 _tokenId) external view
  returns
  (
    address seller,
    uint256 startingPrice,
    uint256 endingPrice,
    uint256 duration,
    uint256 startedAt
  ) {
    // Check token on auction
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
   * @param _tokenId ID of the token price we are checking
   */
  function getCurrentPrice(uint256 _tokenId) external view returns (uint256) {
    // Check token on auction
    Auction storage auction = tokenIdToAuction[_tokenId];
    require(_isOnAuction(auction));

    return _currentPrice(auction);
  }

  /**
   * @dev Bids on an open auction, completing the auction and transferring
   *      ownership of the token if enough Ether is supplied.
   * @param _tokenId ID of token to bid on
   */
  function bid(uint256 _tokenId) external payable whenNotPaused {
    address seller = tokenIdToAuction[_tokenId].seller;

    // Check auction conditions and transfer Ether to seller
    // _bid verifies token ID size
    _bid(_tokenId, msg.value);

    // Transfer token from this contract to msg.sender after successful bid
    _transfer(msg.sender, _tokenId);

    // If seller is tokenContract then increase counter of release tokens
    if (seller == address(tokenContract)) {
      releaseTokensSaleCount++;
    }
  }

  /**
   * @dev Cancels an auction. Returns the token to original owner.
   *      This is a state-modifying function that can
   *      be called while the contract is paused.
   * @param _tokenId ID of token on auction
   */
  function cancelAuction(uint256 _tokenId) external {
    // Check token on auction
    Auction storage auction = tokenIdToAuction[_tokenId];
    require(_isOnAuction(auction));

    // Check sender as seller
    address seller = auction.seller;
    require(msg.sender == seller);

    _cancelAuction(_tokenId, seller);
  }

  /**
   * @dev Cancels an auction when the contract is paused. Only owner.
   *      Returns the token to seller. This should only be used in emergencies.
   * @param _tokenId ID of the NFT on auction to cancel
   */
  function cancelAuctionWhenPaused(uint256 _tokenId) whenPaused onlyOwner external {
    // Check token on auction
    Auction storage auction = tokenIdToAuction[_tokenId];
    require(_isOnAuction(auction));

    _cancelAuction(_tokenId, auction.seller);
  }

  /**
   * @dev Withdraw all Ether (fee) from auction contract to token contract.
   *      Only auction contract owner.
   */
  function withdrawBalance() external {
    address tokenAddress = address(tokenContract);

    // Check sender as owner or token contract
    require(msg.sender == owner || msg.sender == tokenAddress);

    // Send Ether on this contract to token contract
    // Boolean method make sure that even if one fails it will still work
    bool res = tokenAddress.send(address(this).balance);
  }

  /**
   * @dev Set new auction price limit.
   * @param _newAuctionPriceLimit Start and end price limit
   */
  function setAuctionPriceLimit(uint256 _newAuctionPriceLimit) external {
    address tokenAddress = address(tokenContract);

    // Check sender as owner or token contract
    require(msg.sender == owner || msg.sender == tokenAddress);

    // Check overflow
    require(_newAuctionPriceLimit == uint256(uint128(_newAuctionPriceLimit)));

    // Set new auction price limit
    auctionPriceLimit = _newAuctionPriceLimit;
  }


  // -----------------------------------------
  // Internal interface
  // -----------------------------------------


  /**
   * @dev Returns true if the claimant owns the token.
   * @param _claimant Address claiming to own the token
   * @param _tokenId ID of token whose ownership to verify
   */
  function _owns(
    address _claimant,
    uint256 _tokenId
  )
    internal
    view
    returns (bool)
  {
    return (tokenContract.ownerOf(_tokenId) == _claimant);
  }

  /**
   * @dev Transfer token from owner to this contract.
   * @param _owner Current owner address of token to escrow
   * @param _tokenId ID of token whose approval to verify
   */
  function _deposit(
    address _owner,
    uint256 _tokenId
  )
    internal
  {
    tokenContract.transferFrom(_owner, this, _tokenId);
  }

  /**
   * @dev Transfers token owned by this contract to another address.
   *      Returns true if the transfer succeeds.
   * @param _receiver Address to transfer token to
   * @param _tokenId ID of token to transfer
   */
  function _transfer(
    address _receiver,
    uint256 _tokenId
  )
    internal
  {
    tokenContract.transfer(_receiver, _tokenId);
  }

  /**
   * @dev Adds an auction to the list of open auctions.
   * @param _tokenId The ID of the token to be put on auction
   * @param _auction Auction to add
   */
  function _addAuction(
    uint256 _tokenId,
    Auction _auction
  )
    internal
  {
    // Require that all auctions have a duration of at least one minute.
    require(_auction.duration >= 1 minutes);

    tokenIdToAuction[_tokenId] = _auction;

    emit AuctionCreated(
      uint256(_tokenId),
      uint256(_auction.startingPrice),
      uint256(_auction.endingPrice),
      uint256(_auction.duration)
    );
  }

  /**
   * @dev Removes an auction from the list of open auctions.
   * @param _tokenId ID of token on auction
   */
  function _removeAuction(uint256 _tokenId) internal {
    delete tokenIdToAuction[_tokenId];
  }

  /**
   * @dev Remove an auction and transfer token from this contract to seller address.
   * @param _tokenId The ID of the token
   * @param _seller Seller address
   */
  function _cancelAuction(
    uint256 _tokenId,
    address _seller
  )
    internal
  {
    // Remove auction from list
    _removeAuction(_tokenId);

    // Transfer token to seller
    _transfer(_seller, _tokenId);

    emit AuctionCancelled(_tokenId);
  }

  /**
   * @dev Check token is on auction.
   * @param _auction Auction to check
   */
  function _isOnAuction(Auction storage _auction) internal view returns (bool) {
    return (_auction.startedAt > 0);
  }

  /**
   * @dev Calculates fee of a sale.
   * @param _price Token price
   */
  function _calculateFee(uint256 _price) internal view returns (uint256) {
    return _price * feePercent / 10000;
  }

  /**
   * @dev Returns current price of a token on auction.
   * @param _auction Auction for calculate current price
   */
  function _currentPrice(Auction storage _auction) internal view returns (uint256) {
    uint256 secondsPassed = 0;

    // Check that auction were started
    // Variable secondsPassed is positive
    if (now > _auction.startedAt) {
      secondsPassed = now - _auction.startedAt;
    }

    return _calculateCurrentPrice(
      _auction.startingPrice,
      _auction.endingPrice,
      _auction.duration,
      secondsPassed
    );
  }

  /**
   * @dev Calculate the current price of an auction.
   * @param _startingPrice Price of item (in wei) at beginning of auction
   * @param _endingPrice Price of item (in wei) at end of auction
   * @param _duration Length of auction (in seconds)
   * @param _secondsPassed Seconds passed after auction start
   */
  function _calculateCurrentPrice(
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
      // The auction lasts longer duration
      // Return end price
      return _endingPrice;
    } else {
      // totalPriceChange can be negative
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

  /**
   * @dev Calculate auction price and transfers winnings. Does NOT transfer ownership of token.
   * @param _tokenId The ID of the token
   * @param _bidAmount Amount (in wei) offered for auction
   */
  function _bid(
    uint256 _tokenId,
    uint256 _bidAmount
  )
    internal
    returns (uint256)
  {
    Auction storage auction = tokenIdToAuction[_tokenId];

    // Check that this auction is currently live
    require(_isOnAuction(auction));

    // Check that the incoming bid is higher than the current price
    uint256 price = _currentPrice(auction);
    require(_bidAmount >= price);

    address seller = auction.seller;

    _removeAuction(_tokenId);

    // Transfer proceeds to seller
    if (price > 0) {
      uint256 fee = _calculateFee(price);

      uint256 sellerProceeds = price - fee;

      // Transfer proceeds to seller
      seller.transfer(sellerProceeds);
    }

    // Calculate excess funds and transfer it back to bidder
    uint256 bidExcess = _bidAmount - price;
    msg.sender.transfer(bidExcess);

    emit AuctionSuccessful(_tokenId, price, msg.sender);

    return price;
  }
}