pragma solidity ^0.4.24;

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
    ERC721Interface public nfContract;

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
    mapping (uint256 => Auction) tokenIdToAuction;

    /*
    * @dev Auction events
    */
    event AuctionCreated(uint256 tokenId, uint256 startingPrice, uint256 endingPrice, uint256 duration);
    event AuctionSuccessful(uint256 tokenId, uint256 totalPrice, address winner);
    event AuctionCancelled(uint256 tokenId);

    /*
    * @dev Checks ownership of a token (uses the ERC721&#39; ownerOf() function)
    */
    function _owns(address _address, uint256 _tokenId) internal view returns (bool) {
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
    function _bid(uint256 _tokenId, uint256 _bidAmount) internal returns (uint256) {
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

contract ERC721Interface {
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _tokenId
    );
    event Approval(
        address indexed _owner,
        address indexed _approved,
        uint256 _tokenId
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

    function supportsInterface(bytes4 _interfaceID) external view returns (bool);
}

contract ClockAuction is ClockAuctionBase, Pausable {

    bytes4 constant InterfaceSignature_ERC721 = bytes4(0x80ac58cd);

    /*
    * @dev Sets the owner cut and creates a reference to the NFT contract
    */
    constructor(address _nftAddress, uint256 _cut) public {
        require(_cut <= 10000);
        ownerCut = _cut;

        ERC721Interface candidateContract = ERC721Interface(_nftAddress);

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
    whenPaused
    onlyOwner
    external
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

    constructor(address _nftAddr, uint256 _cut) public ClockAuction(_nftAddr, _cut) {}

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