pragma solidity 0.4.18;

/*

  Sketches:
  - can be created
  - can be traded: you make a bid, the other party can accept or you can withdraw the bid
  - can not be destroyed

*/

contract Ownable {
  address public owner;


  function Ownable() public {
    owner = msg.sender;
  }


  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) external onlyOwner {
    require(newOwner != address(0));
    owner = newOwner;
  }

}


contract SketchMarket is Ownable {
  // ERC-20 compatibility {
  string public standard = "CryptoSketches";
  string public name;
  string public symbol;
  uint8 public decimals;
  uint256 public totalSupply;

  mapping (address => uint256) public balanceOf;

  event Transfer(address indexed from, address indexed to, uint256 value);
  // }

  // Sketch storage {
  mapping(uint256 => string)  public sketchIndexToName;
  mapping(uint256 => string)  public sketchIndexToData;
  mapping(uint256 => address) public sketchIndexToHolder;
  mapping(uint256 => address) public sketchIndexToAuthor;
  mapping(uint256 => uint8)   public sketchIndexToOwnerFlag;

  mapping(address => uint256) public sketchAuthorCount;

  event SketchCreated(address indexed author, uint256 indexed sketchIndex);
  // }

  // Sketch trading {

  // Cut owner takes on each auction, measured in basis points (1/100 of a percent).
  // Values 0-10,000 map to 0%-100%
  uint256 public ownerCut;

  // Amount owner takes on each submission, measured in Wei.
  uint256 public listingFeeInWei;

  mapping (uint256 => Offer) public sketchIndexToOffer;
  mapping (uint256 => Bid) public sketchIndexToHighestBid;
  mapping (address => uint256) public accountToWithdrawableValue;

  event SketchTransfer(uint256 indexed sketchIndex, address indexed fromAddress, address indexed toAddress);
  event SketchOffered(uint256 indexed sketchIndex, uint256 minValue, address indexed toAddress);
  event SketchBidEntered(uint256 indexed sketchIndex, uint256 value, address indexed fromAddress);
  event SketchBidWithdrawn(uint256 indexed sketchIndex, uint256 value, address indexed fromAddress);
  event SketchBought(uint256 indexed sketchIndex, uint256 value, address indexed fromAddress, address indexed toAddress);
  event SketchNoLongerForSale(uint256 indexed sketchIndex);

  struct Offer {
    bool isForSale;
    uint256 sketchIndex;
    address seller;
    uint256 minValue;   // ETH
    address onlySellTo; // require a specific seller address
  }

  struct Bid {
    bool hasBid;
    uint256 sketchIndex;
    address bidder;
    uint256 value;
  }
  // }

  // -- Constructor (see also: Ownable)

  function SketchMarket() public payable {
    // ERC-20 token
    totalSupply = 0;
    name = "CRYPTOSKETCHES";
    symbol = "S̈";
    decimals = 0; // whole number; number of sketches owned

    // Trading parameters
    ownerCut = 375; // 3.75% cut to auctioneer
    listingFeeInWei = 5000000000000000; // 0.005 ETH, to discourage spam
  }

  function setOwnerCut(uint256 _ownerCut) external onlyOwner {
    require(_ownerCut == uint256(uint16(_ownerCut)));
    require(_ownerCut <= 10000);
    ownerCut = _ownerCut;
  }

  function setListingFeeInWei(uint256 _listingFeeInWei) external onlyOwner {
    require(_listingFeeInWei == uint256(uint128(_listingFeeInWei))); // length check
    listingFeeInWei = _listingFeeInWei;
  }

  // -- Creation and fetching methods

  function createSketch(string _name, string _data) external payable {
    require(msg.value == listingFeeInWei);
    require(bytes(_name).length < 256);     // limit name byte size to 255
    require(bytes(_data).length < 1048576); // limit drawing byte size to 1,048,576

    accountToWithdrawableValue[owner] += msg.value; // auctioneer gets paid

    sketchIndexToHolder[totalSupply] = msg.sender;
    sketchIndexToAuthor[totalSupply] = msg.sender;
    sketchAuthorCount[msg.sender]++;

    sketchIndexToName[totalSupply] = _name;
    sketchIndexToData[totalSupply] = _data;

    balanceOf[msg.sender]++;

    SketchCreated(msg.sender, totalSupply);

    totalSupply++;
  }

  function setOwnerFlag(uint256 index, uint8 _ownerFlag) external onlyOwner {
    sketchIndexToOwnerFlag[index] = _ownerFlag;
  }

  function getSketch(uint256 index) external view returns (string _name, string _data, address _holder, address _author, uint8 _ownerFlag, uint256 _highestBidValue, uint256 _offerMinValue) {
    require(totalSupply != 0);
    require(index < totalSupply);

    _name = sketchIndexToName[index];
    _data = sketchIndexToData[index];
    _holder = sketchIndexToHolder[index];
    _author = sketchIndexToAuthor[index];
    _ownerFlag = sketchIndexToOwnerFlag[index];
    _highestBidValue = sketchIndexToHighestBid[index].value;
    _offerMinValue = sketchIndexToOffer[index].minValue;
  }

  function getBidCountForSketchesWithHolder(address _holder) external view returns (uint256) {
    uint256 count = balanceOf[_holder];

    if (count == 0) {
      return 0;
    } else {
      uint256 result = 0;
      uint256 totalCount = totalSupply;
      uint256 sketchIndex;

      for (sketchIndex = 0; sketchIndex <= totalCount; sketchIndex++) {
        if ((sketchIndexToHolder[sketchIndex] == _holder) && sketchIndexToHighestBid[sketchIndex].hasBid) {
          result++;
        }
      }
      return result;
    }
  }

  function getSketchesOnOffer() external view returns (uint256[]) {
    if (totalSupply == 0) {
      return new uint256[](0);
    }

    uint256 count = 0;
    uint256 totalCount = totalSupply;
    uint256 sketchIndex;

    for (sketchIndex = 0; sketchIndex <= totalCount; sketchIndex++) {
      if (sketchIndexToOffer[sketchIndex].isForSale) {
        count++;
      }
    }

    if (count == 0) {
      return new uint256[](0);
    }

    uint256[] memory result = new uint256[](count);
    uint256 resultIndex = 0;

    for (sketchIndex = 0; sketchIndex <= totalCount; sketchIndex++) {
      if (sketchIndexToOffer[sketchIndex].isForSale) {
        result[resultIndex] = sketchIndex;
        resultIndex++;
      }
    }
    return result;
  }

  function getSketchesOnOfferWithHolder(address _holder) external view returns (uint256[]) {
    if (totalSupply == 0) {
      return new uint256[](0);
    }

    uint256 count = 0;
    uint256 totalCount = totalSupply;
    uint256 sketchIndex;

    for (sketchIndex = 0; sketchIndex <= totalCount; sketchIndex++) {
      if (sketchIndexToOffer[sketchIndex].isForSale && (sketchIndexToHolder[sketchIndex] == _holder)) {
        count++;
      }
    }

    if (count == 0) {
      return new uint256[](0);
    }

    uint256[] memory result = new uint256[](count);
    uint256 resultIndex = 0;

    for (sketchIndex = 0; sketchIndex <= totalCount; sketchIndex++) {
      if (sketchIndexToOffer[sketchIndex].isForSale && (sketchIndexToHolder[sketchIndex] == _holder)) {
        result[resultIndex] = sketchIndex;
        resultIndex++;
      }
    }
    return result;
  }

  function getSketchesWithHolder(address _holder) external view returns (uint256[]) {
    uint256 count = balanceOf[_holder];

    if (count == 0) {
      return new uint256[](0);
    } else {
      uint256[] memory result = new uint256[](count);
      uint256 totalCount = totalSupply;
      uint256 resultIndex = 0;
      uint256 sketchIndex;

      for (sketchIndex = 0; sketchIndex <= totalCount; sketchIndex++) {
        if (sketchIndexToHolder[sketchIndex] == _holder) {
          result[resultIndex] = sketchIndex;
          resultIndex++;
        }
      }
      return result;
    }
  }

  function getSketchesWithAuthor(address _author) external view returns (uint256[]) {
    uint256 count = sketchAuthorCount[_author];

    if (count == 0) {
      return new uint256[](0);      
    } else {
      uint256[] memory result = new uint256[](count);
      uint256 totalCount = totalSupply;
      uint256 resultIndex = 0;
      uint256 sketchIndex;

      for (sketchIndex = 0; sketchIndex <= totalCount; sketchIndex++) {
        if (sketchIndexToAuthor[sketchIndex] == _author) {
          result[resultIndex] = sketchIndex;
          resultIndex++;
        }
      }
      return result;
    }
  }

  // -- Trading methods

  modifier onlyHolderOf(uint256 sketchIndex) {
    require(totalSupply != 0);
    require(sketchIndex < totalSupply);
    require(sketchIndexToHolder[sketchIndex] == msg.sender);
    _;
 }

  // Transfer holdership without requiring payment
  function transferSketch(address to, uint256 sketchIndex) external onlyHolderOf(sketchIndex) {
    require(to != address(0));
    require(balanceOf[msg.sender] > 0);

    if (sketchIndexToOffer[sketchIndex].isForSale) {
      sketchNoLongerForSale(sketchIndex); // remove the offer
    }

    sketchIndexToHolder[sketchIndex] = to;
    balanceOf[msg.sender]--;
    balanceOf[to]++;

    Transfer(msg.sender, to, 1); // ERC-20
    SketchTransfer(sketchIndex, msg.sender, to);

    // If the recipient had bid for the Sketch, remove the bid and make it possible to refund its value
    Bid storage bid = sketchIndexToHighestBid[sketchIndex];
    if (bid.bidder == to) {
        accountToWithdrawableValue[to] += bid.value;
        sketchIndexToHighestBid[sketchIndex] = Bid(false, sketchIndex, 0x0, 0);
    }
  }

  // Withdraw Sketch from sale (NOTE: does not cancel bids, since bids must be withdrawn manually by bidders)
  function sketchNoLongerForSale(uint256 _sketchIndex) public onlyHolderOf(_sketchIndex) {
    sketchIndexToOffer[_sketchIndex] = Offer(false, _sketchIndex, msg.sender, 0, 0x0);
    SketchNoLongerForSale(_sketchIndex);
  }

  // Place a Sketch up for sale, to any buyer
  function offerSketchForSale(uint256 _sketchIndex, uint256 _minSalePriceInWei) public onlyHolderOf(_sketchIndex) {
    sketchIndexToOffer[_sketchIndex] = Offer(true, _sketchIndex, msg.sender, _minSalePriceInWei, 0x0);
    SketchOffered(_sketchIndex, _minSalePriceInWei, 0x0);
  }

  // Place a Sketch up for sale, but only to a specific buyer
  function offerSketchForSaleToAddress(uint256 _sketchIndex, uint256 _minSalePriceInWei, address _toAddress) public onlyHolderOf(_sketchIndex) {
    require(_toAddress != address(0));
    require(_toAddress != msg.sender);

    sketchIndexToOffer[_sketchIndex] = Offer(true, _sketchIndex, msg.sender, _minSalePriceInWei, _toAddress);
    SketchOffered(_sketchIndex, _minSalePriceInWei, _toAddress);
  }

  // Accept a bid for a Sketch that you own, receiving the amount for withdrawal at any time - note minPrice safeguard!
  function acceptBidForSketch(uint256 sketchIndex, uint256 minPrice) public onlyHolderOf(sketchIndex) {
    address seller = msg.sender;    
    require(balanceOf[seller] > 0);

    Bid storage bid = sketchIndexToHighestBid[sketchIndex];
    uint256 price = bid.value;
    address bidder = bid.bidder;

    require(price > 0);
    require(price == uint256(uint128(price))); // length check for computeCut(...)
    require(minPrice == uint256(uint128(minPrice))); // length check for computeCut(...)
    require(price >= minPrice); // you may be accepting a different bid than you think, but its value will be at least as high

    sketchIndexToHolder[sketchIndex] = bidder; // transfer actual holdership!
    balanceOf[seller]--; // update balances
    balanceOf[bidder]++;
    Transfer(seller, bidder, 1);

    sketchIndexToOffer[sketchIndex] = Offer(false, sketchIndex, bidder, 0, 0x0); // remove the offer    
    sketchIndexToHighestBid[sketchIndex] = Bid(false, sketchIndex, 0x0, 0); // remove the bid

    uint256 ownerProceeds = computeCut(price);
    uint256 holderProceeds = price - ownerProceeds;

    accountToWithdrawableValue[seller] += holderProceeds; // make profit available to seller for withdrawal
    accountToWithdrawableValue[owner] += ownerProceeds;   // make cut available to auctioneer for withdrawal

    SketchBought(sketchIndex, price, seller, bidder); // note that SketchNoLongerForSale event will not be fired
  }

  // Buy a Sketch that&#39;s up for sale now, provided you&#39;ve matched the Offer price and it&#39;s not on offer to a specific buyer
  function buySketch(uint256 sketchIndex) external payable {      
    Offer storage offer = sketchIndexToOffer[sketchIndex];
    uint256 messageValue = msg.value;

    require(totalSupply != 0);
    require(sketchIndex < totalSupply);
    require(offer.isForSale);
    require(offer.onlySellTo == 0x0 || offer.onlySellTo == msg.sender);
    require(messageValue >= offer.minValue);
    require(messageValue == uint256(uint128(messageValue))); // length check for computeCut(...)
    require(offer.seller == sketchIndexToHolder[sketchIndex]); // the holder may have changed since an Offer was last put up

    address holder = offer.seller;
    require(balanceOf[holder] > 0);

    sketchIndexToHolder[sketchIndex] = msg.sender; // transfer actual holdership!
    balanceOf[holder]--; // update balances
    balanceOf[msg.sender]++;
    Transfer(holder, msg.sender, 1);

    sketchNoLongerForSale(sketchIndex); // remove the offer

    uint256 ownerProceeds = computeCut(messageValue);
    uint256 holderProceeds = messageValue - ownerProceeds;

    accountToWithdrawableValue[owner] += ownerProceeds;
    accountToWithdrawableValue[holder] += holderProceeds;

    SketchBought(sketchIndex, messageValue, holder, msg.sender);

    // Refund any bid the new buyer had placed for this Sketch.
    // Other bids have to stay put for continued consideration or until their values have been withdrawn.
    Bid storage bid = sketchIndexToHighestBid[sketchIndex];
    if (bid.bidder == msg.sender) {
        accountToWithdrawableValue[msg.sender] += bid.value;
        sketchIndexToHighestBid[sketchIndex] = Bid(false, sketchIndex, 0x0, 0); // remove the bid
    }
  }

  // Withdraw any value owed to:
  // (a) a buyer that withdraws their bid or invalidates it by purchasing a Sketch outright for its asking price
  // (b) a seller owed funds from the sale of a Sketch
  function withdraw() external {
      uint256 amount = accountToWithdrawableValue[msg.sender];
      // Zero the pending refund before transferring to prevent re-entrancy attacks
      accountToWithdrawableValue[msg.sender] = 0;
      msg.sender.transfer(amount);
  }

  // Enter a bid, regardless of whether the Sketch holder wishes to sell or not
  function enterBidForSketch(uint256 sketchIndex) external payable {
      require(totalSupply != 0);
      require(sketchIndex < totalSupply);
      require(sketchIndexToHolder[sketchIndex] != 0x0); // can&#39;t bid on "non-owned" Sketch (theoretically impossible anyway)
      require(sketchIndexToHolder[sketchIndex] != msg.sender); // can&#39;t bid on a Sketch that you own

      uint256 price = msg.value; // in wei

      require(price > 0); // can&#39;t bid zero
      require(price == uint256(uint128(price))); // length check for computeCut(...)      

      Bid storage existing = sketchIndexToHighestBid[sketchIndex];

      require(price > existing.value); // can&#39;t bid less than highest bid

      if (existing.value > 0) {
          // Place the amount from the previous highest bid into escrow for withdrawal at any time
          accountToWithdrawableValue[existing.bidder] += existing.value;
      }
      sketchIndexToHighestBid[sketchIndex] = Bid(true, sketchIndex, msg.sender, price);

      SketchBidEntered(sketchIndex, price, msg.sender);
  }

  function withdrawBidForSketch(uint256 sketchIndex) public {
    require(totalSupply != 0);
    require(sketchIndex < totalSupply);
    require(sketchIndexToHolder[sketchIndex] != 0x0); // can&#39;t bid on "non-owned" Sketch (theoretically impossible anyway)
    require(sketchIndexToHolder[sketchIndex] != msg.sender); // can&#39;t withdraw a bid for a Sketch that you own
      
    Bid storage bid = sketchIndexToHighestBid[sketchIndex];
    require(bid.bidder == msg.sender); // it has to be your bid

    SketchBidWithdrawn(sketchIndex, bid.value, msg.sender);

    uint256 amount = bid.value;
    sketchIndexToHighestBid[sketchIndex] = Bid(false, sketchIndex, 0x0, 0);

    // Refund the bid money directly
    msg.sender.transfer(amount);
  }

  function computeCut(uint256 price) internal view returns (uint256) {
    // NOTE: We don&#39;t use SafeMath (or similar) in this function because
    //  all of our entry functions carefully cap the maximum values for
    //  currency (at 128-bits), and ownerCut <= 10000. The result of this
    //  function is always guaranteed to be <= _price.
    return price * ownerCut / 10000;
  }

}