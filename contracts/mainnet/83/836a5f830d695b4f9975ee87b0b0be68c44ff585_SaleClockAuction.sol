pragma solidity ^0.4.11;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() {
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
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
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
  function pause() onlyOwner whenNotPaused returns (bool) {
    paused = true;
    Pause();
    return true;
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused returns (bool) {
    paused = false;
    Unpause();
    return true;
  }
}


contract HeroCore{

   function ownerIndexToERC20Balance(address _address) public returns (uint256);
   function useItems(uint32 _items, uint256 tokenId, address owner,uint256 fee) public returns (bool);
   function ownerOf(uint256 _tokenId) public returns (address);
   function getHeroItems(uint256 _id) public returns ( uint32);
    
   function reduceCDFee(uint256 heroId) 
         public 
         view 
         returns (uint256);
   
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
    function promoBun(address _address) public;
}

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
        uint128  startingPriceEth;
        uint128  endingPriceEth;
        
        uint64 duration;
        // Time when auction started
        // NOTE: 0 if this auction has been concluded
        uint64 startedAt;
    }

    ERC721 public nonFungibleContract;

    uint256 public ownerCut;

    mapping (uint256 => Auction) tokenIdToAuction;

    event AuctionCreated(uint256 tokenId, uint256 startingPrice, uint256 endingPrice,uint256 startingPriceEth, uint256 endingPriceEth, uint256 duration);
    event AuctionSuccessful(uint256 tokenId, uint256 totalPrice,uint ccy, address winner);
    event AuctionCancelled(uint256 tokenId);

    function() external {}

    modifier canBeStoredWith64Bits(uint256 _value) {
        require(_value <= 18446744073709551615);
        _;
    }

    modifier canBeStoredWith128Bits(uint256 _value) {
        require(_value < 340282366920938463463374607431768211455);
        _;
    }

    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return (nonFungibleContract.ownerOf(_tokenId) == _claimant);
    }

    function _escrow(address _owner, uint256 _tokenId) internal {
        nonFungibleContract.transferFrom(_owner, this, _tokenId);
    }

    function _transfer(address _receiver, uint256 _tokenId) internal {
        nonFungibleContract.transfer(_receiver, _tokenId);
    }

    function _addAuction(uint256 _tokenId, Auction _auction) internal {
        require(_auction.duration >= 1 minutes);

        tokenIdToAuction[_tokenId] = _auction;
        
        AuctionCreated(
            uint256(_tokenId),
            uint256(_auction.startingPrice),
            uint256(_auction.endingPrice),
            uint256(_auction.startingPriceEth),
            uint256(_auction.endingPriceEth),
            uint256(_auction.duration)
        );
    }
    function _cancelAuction(uint256 _tokenId, address _seller) internal {
        _removeAuction(_tokenId);
        _transfer(_seller, _tokenId);
        AuctionCancelled(_tokenId);
    }
    
    function _order(uint256 _tokenId, uint256 _orderAmount, uint8 ccy)
        internal
        returns (uint256)
    {
        Auction storage auction = tokenIdToAuction[_tokenId];

        require(_isOnAuction(auction));

        uint256 price = _currentPrice(auction,0,ccy);
        require(_orderAmount >= price);

        address seller = auction.seller;

        _removeAuction(_tokenId);

        if (price > 0 && ccy ==0) {
            uint256 auctioneerCut = _computeCut(price);
            uint256 sellerProceeds = price - auctioneerCut;
            seller.transfer(sellerProceeds);
        }
        AuctionSuccessful(_tokenId, price,ccy, msg.sender);

        return price;
    }
    
    function _removeAuction(uint256 _tokenId) internal {
        delete tokenIdToAuction[_tokenId];
    }
    
    function _isOnAuction(Auction storage _auction) internal view returns (bool) {
        return (_auction.startedAt > 0);
    }
    
    function _currentPrice(Auction storage _auction, uint256 timeDelay, uint8 ccy)
        internal
        view
        returns (uint256)
    {
        uint256 secondsPassed = 0;
        if (now > _auction.startedAt) {
            secondsPassed = now - _auction.startedAt + timeDelay;
        }
        if(ccy == 0){
	        return _computeCurrentPrice(
	            _auction.startingPriceEth,
	            _auction.endingPriceEth,
	            _auction.duration,
	            secondsPassed
	        );
        }else{
          return _computeCurrentPrice(
            _auction.startingPrice,
            _auction.endingPrice,
            _auction.duration,
            secondsPassed
        ); 
        }
        
    }

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
            return _endingPrice;
        } else {
            int256 totalPriceChange = int256(_endingPrice) - int256(_startingPrice);
            
            int256 currentPriceChange = totalPriceChange * int256(_secondsPassed) / int256(_duration);
            
            int256 currentPrice = int256(_startingPrice) + currentPriceChange;
            
            return uint256(currentPrice);
        }
    }

    function _computeCut(uint256 _price) internal view returns (uint256) {
        return _price * ownerCut / 10000;
    }

}


contract ClockAuction is Pausable, ClockAuctionBase {
   // bool public isClockAuction = true;
    mapping (address => mapping (uint256 => uint256)) public addressIndexToAuctionCount;
    mapping (address => mapping (uint256 => uint256)) public addressIndexToOrderCount;
   
    event DayPass(uint256 _dayPass, uint256 _startTime, uint256 _now, uint256 time );
    
    uint256 public startTime = now;
    uint256 public aDay = 86400;
    
    
    
    function _calculateDayPass() internal returns (uint256 dayPass) {
       dayPass = (now -startTime) / aDay;
       DayPass(dayPass,startTime,now,(aDay));
    }
   
   
   
    function ClockAuction(address _nftAddress, uint256 _cut) public {
        require(_cut <= 10000);
        ownerCut = _cut;
        
        ERC721 candidateContract = ERC721(_nftAddress);
        require(candidateContract.implementsERC721());
        nonFungibleContract = candidateContract;
    }

    function withdrawBalance() external {
        address nftAddress = address(nonFungibleContract);

        require(
            msg.sender == owner ||
            msg.sender == nftAddress
        );
        nftAddress.transfer(this.balance);
    }

    function createAuction(
        uint256 _tokenId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _startingPriceEth,
        uint256 _endingPriceEth,
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
            uint128(_startingPriceEth),
            uint128(_endingPriceEth),
            uint64(_duration),
            uint64(now)
        );
        _addAuction(_tokenId, auction);
    }

    function cancelAuction(uint256 _tokenId)
        public
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        address seller = auction.seller;
        require(msg.sender == seller);
        _cancelAuction(_tokenId, seller);
    }

    function cancelAuctionWhenPaused(uint256 _tokenId)
        whenPaused
        onlyOwner
        public
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        _cancelAuction(_tokenId, auction.seller);
    }

    function getAuction(uint256 _tokenId)
        public
        view
        returns
    (
        address seller,
        uint256 startingPrice,
        uint256 endingPrice,
        uint256 startingPriceEth,
        uint256 endingPriceEth,
        uint256 duration,
        uint256 startedAt
    ) {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        return (
            auction.seller,
            auction.startingPrice,
            auction.endingPrice,
            auction.startingPriceEth,
            auction.endingPriceEth,
            auction.duration,
            auction.startedAt
        );
    }
    
     function getSeller(uint256 _tokenId) public view returns(address seller) {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        return auction.seller;
    }

    function getCurrentPrice(uint256 _tokenId,uint8 ccy)
        public
        view
        returns (uint256)
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        return _currentPrice(auction, 0,ccy);
    }
    
    
    function getCurrentPrice(uint256 _tokenId, uint256 timeDelay,uint8 ccy)
        public
        view
        returns (uint256)
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        return _currentPrice(auction, timeDelay,ccy);
    }

}


contract SaleClockAuction is ClockAuction {
    bool public isSaleClockAuction = true;
    uint256 public gen0SaleCount;
    uint256[5] public lastGen0SalePrices;
    function SaleClockAuction(address _nftAddr, uint256 _cut) public
        ClockAuction(_nftAddr, _cut) {}
        
    function createAuction(
        uint256 _tokenId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _startingPriceEth,
        uint256 _endingPriceEth,
        uint256 _duration,
        address _seller
    )
        public
        canBeStoredWith128Bits(_startingPrice)
        canBeStoredWith128Bits(_endingPrice)
        canBeStoredWith128Bits(_startingPriceEth)
        canBeStoredWith128Bits(_endingPriceEth)
        canBeStoredWith64Bits(_duration)
    {
        require(msg.sender == address(nonFungibleContract));
        _escrow(_seller, _tokenId);
        Auction memory auction = Auction(
            _seller,
            uint128(_startingPrice),
            uint128(_endingPrice),
            uint128(_startingPriceEth),
            uint128(_endingPriceEth),
            uint64(_duration),
            uint64(now)
        );
        _addAuction(_tokenId, auction);
        addressIndexToAuctionCount[_seller][_calculateDayPass()] += 1;
    }
    
    function order(uint256 _tokenId, uint256 orderAmount ,address buyer)
        public returns (bool)
    {
        require(msg.sender == address(nonFungibleContract));
        address seller = tokenIdToAuction[_tokenId].seller;
        require(seller !=address(nonFungibleContract));        
        uint256 price =  _order(_tokenId,  orderAmount , 1 ) ;
        _transfer(buyer, _tokenId);
        addressIndexToOrderCount[buyer][_calculateDayPass()] +=1;
        bool flag = true;
        return flag;      
    }
    
     function orderOnSaleAuction(uint256 _tokenId)
        public
        payable
    {
        address seller = tokenIdToAuction[_tokenId].seller;
        uint256 price = _order(_tokenId, msg.value,0);
        _transfer(msg.sender, _tokenId);
        if (seller == address(nonFungibleContract)) {
            lastGen0SalePrices[gen0SaleCount % 5] = price;
            gen0SaleCount++;
            nonFungibleContract.promoBun(msg.sender);
        }
        addressIndexToOrderCount[msg.sender][_calculateDayPass()] +=1;
    }
    

    function averageGen0SalePrice() public view returns (uint256) {
        uint256 sum = 0;
        for (uint256 i = 0; i < 5; i++) {
            sum += lastGen0SalePrices[i];
        }
        return sum / 5;
    }

}