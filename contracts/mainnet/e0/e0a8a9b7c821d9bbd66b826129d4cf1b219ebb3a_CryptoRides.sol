pragma solidity ^0.4.18; // solhint-disable-line

contract ERC721 {
  function approve(address _to, uint256 _tokenId) public;
  function balanceOf(address _owner) public view returns (uint256 balance);
  function implementsERC721() public pure returns (bool);
  function ownerOf(uint256 _tokenId) public view returns (address addr);
  function takeOwnership(uint256 _tokenId) public;
  function totalSupply() public view returns (uint256 total);
  function transferFrom(address _from, address _to, uint256 _tokenId) public;
  function transfer(address _to, uint256 _tokenId) public;

  event Transfer(address indexed from, address indexed to, uint256 tokenId);
  event Approval(address indexed owner, address indexed approved, uint256 tokenId);
}


contract CryptoRides is ERC721 {
  event Created(uint256 tokenId, string name, bytes7 plateNumber, address owner);
  event TokenSold(uint256 tokenId, uint256 oldPrice, uint256 newPrice, address prevOwner, address winner, string name, bytes7 plateNumber);
  event Transfer(address from, address to, uint256 tokenId);

  string public constant NAME = "CryptoRides"; // solhint-disable-line
  string public constant SYMBOL = "CryptoRidesToken"; // solhint-disable-line
  uint256 private startingPrice = 0.001 ether;
  uint256 private constant PROMO_CREATION_LIMIT = 5000;
  uint256 private firstStepLimit =  0.053613 ether;
  uint256 private secondStepLimit = 0.564957 ether;

  mapping (uint256 => address) public tokenIdToOwner;
  mapping (address => uint256) private ownershipTokenCount;
  mapping (uint256 => address) public tokenIdToApproved;
  mapping (uint256 => uint256) private tokenIdToPrice;

  address public ceoAddress;
  address public cooAddress;

  uint256 public promoCreatedCount;

  struct Ride {
    string name;
    bytes7 plateNumber;
  }
  Ride[] private rides;

  modifier onlyCEO() {
    require(msg.sender == ceoAddress);
    _;
  }

  modifier onlyCOO() {
    require(msg.sender == cooAddress);
    _;
  }

  modifier onlyCLevel() {
    require(
      msg.sender == ceoAddress ||
      msg.sender == cooAddress
    );
    _;
  }

  function CryptoRides() public {
    ceoAddress = msg.sender;
    cooAddress = msg.sender;
  }

  function approve( address _to, uint256 _tokenId) public {
    // Caller must own token.
    require(_owns(msg.sender, _tokenId));

    tokenIdToApproved[_tokenId] = _to;

    Approval(msg.sender, _to, _tokenId);
  }

  function balanceOf(address _owner) public view returns (uint256 balance) {
    return ownershipTokenCount[_owner];
  }

  function createPromoRide(address _owner, string _name, bytes7 _plateNo, uint256 _price) public onlyCOO {
    require(promoCreatedCount < PROMO_CREATION_LIMIT);

    address rideOwner = _owner;
    if (rideOwner == address(0)) {
      rideOwner = cooAddress;
    }

    if (_price <= 0) {
      _price = startingPrice;
    }

    promoCreatedCount++;
    _createRide(_name, _plateNo, rideOwner, _price);
  }

  function createContractRide(string _name, bytes7 _plateNo) public onlyCOO {
    _createRide(_name, _plateNo, address(this), startingPrice);
  }

  function getRide(uint256 _tokenId) public view returns (
    string rideName,
    bytes7 plateNumber,
    uint256 sellingPrice,
    address owner
  ) {
    Ride storage ride = rides[_tokenId];
    rideName = ride.name;
    plateNumber = ride.plateNumber;
    sellingPrice = tokenIdToPrice[_tokenId];
    owner = tokenIdToOwner[_tokenId];
  }

  function implementsERC721() public pure returns (bool) {
    return true;
  }

  function name() public pure returns (string) {
    return NAME;
  }

  function ownerOf(uint256 _tokenId)
    public
    view
    returns (address owner)
  {
    owner = tokenIdToOwner[_tokenId];
    require(owner != address(0));
  }

  function payout(address _to) public onlyCLevel {
    _payout(_to);
  }

  function purchase(uint256 _tokenId, bytes7 _plateNumber) public payable {
    address oldOwner = tokenIdToOwner[_tokenId];
    address newOwner = msg.sender;

    uint256 sellingPrice = tokenIdToPrice[_tokenId];

    require(oldOwner != newOwner);

    require(_addressNotNull(newOwner));

    require(msg.value >= sellingPrice);

    uint256 payment = uint256(SafeMath.div(SafeMath.mul(sellingPrice, 92), 100));
    uint256 purchaseExcess = SafeMath.sub(msg.value, sellingPrice);

    // Update prices
    if (sellingPrice < firstStepLimit) {
      // first stage
      tokenIdToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 200), 92);
    } else if (sellingPrice < secondStepLimit) {
      // second stage
      tokenIdToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 120), 92);
    } else {
      // third stage
      tokenIdToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 115), 92);
    }

    _transfer(oldOwner, newOwner, _tokenId);

    // Pay previous tokenOwner if owner is not contract
    if (oldOwner != address(this)) {
      oldOwner.transfer(payment); //(1-0.08)
    }

    TokenSold(_tokenId, sellingPrice, tokenIdToPrice[_tokenId], oldOwner, newOwner, rides[_tokenId].name, _plateNumber);

    msg.sender.transfer(purchaseExcess);
    rides[_tokenId].plateNumber = _plateNumber;
  }

  function priceOf(uint256 _tokenId) public view returns (uint256 price) {
    return tokenIdToPrice[_tokenId];
  }

  function setCEO(address _newCEO) public onlyCEO {
    require(_newCEO != address(0));

    ceoAddress = _newCEO;
  }

  function setCOO(address _newCOO) public onlyCEO {
    require(_newCOO != address(0));

    cooAddress = _newCOO;
  }

  function symbol() public pure returns (string) {
    return SYMBOL;
  }

  function takeOwnership(uint256 _tokenId) public {
    address newOwner = msg.sender;
    address oldOwner = tokenIdToOwner[_tokenId];

    // Safety check to prevent against an unexpected 0x0 default.
    require(_addressNotNull(newOwner));

    // Making sure transfer is approved
    require(_approved(newOwner, _tokenId));

    _transfer(oldOwner, newOwner, _tokenId);
  }

  function tokensOfOwner(address _owner) public view returns(uint256[] ownerTokens) {
    uint256 tokenCount = balanceOf(_owner);
    if (tokenCount == 0) {
        // Return an empty array
      return new uint256[](0);
    } else {
      uint256[] memory result = new uint256[](tokenCount);
      uint256 totalRides = totalSupply();
      uint256 resultIndex = 0;

      uint256 rideId;
      for (rideId = 0; rideId <= totalRides; rideId++) {
        if (tokenIdToOwner[rideId] == _owner) {
          result[resultIndex] = rideId;
          resultIndex++;
        }
      }
      return result;
    }
  }

  function totalSupply() public view returns (uint256 total) {
    return rides.length;
  }

  function transfer( address _to, uint256 _tokenId) public {
    require(_owns(msg.sender, _tokenId));
    require(_addressNotNull(_to));

    _transfer(msg.sender, _to, _tokenId);
  }

  function transferFrom(address _from, address _to, uint256 _tokenId) public {
    require(_owns(_from, _tokenId));
    require(_approved(_to, _tokenId));
    require(_addressNotNull(_to));

    _transfer(_from, _to, _tokenId);
  }

  function _addressNotNull(address _to) private pure returns (bool) {
    return _to != address(0);
  }

  function _approved(address _to, uint256 _tokenId) private view returns (bool) {
    return tokenIdToApproved[_tokenId] == _to;
  }

  function _createRide(string _name, bytes7 _plateNo, address _owner, uint256 _price) private {
    Ride memory _ride = Ride({
      name: _name, 
      plateNumber: _plateNo
    });
    uint256 newRideId = rides.push(_ride) - 1;

    require(newRideId == uint256(uint32(newRideId)));

    Created(newRideId, _name, _plateNo, _owner);

    tokenIdToPrice[newRideId] = _price;

    _transfer(address(0), _owner, newRideId);
  }

  function _owns(address claimant, uint256 _tokenId) private view returns (bool) {
    return claimant == tokenIdToOwner[_tokenId];
  }

  function _payout(address _to) private {
    if (_to == address(0)) {
      ceoAddress.transfer(this.balance);
    } else {
      _to.transfer(this.balance);
    }
  }

  function _transfer(address _from, address _to, uint256 _tokenId) private {
    // Since the number of rides is capped to 2^32 we can&#39;t overflow this
    ownershipTokenCount[_to]++;
    //transfer ownership
    tokenIdToOwner[_tokenId] = _to;

    // When creating new rides _from is 0x0, but we can&#39;t account that address.
    if (_from != address(0)) {
      ownershipTokenCount[_from]--;
      // clear any previously approved ownership exchange
      delete tokenIdToApproved[_tokenId];
    }

    // Emit the transfer event.
    Transfer(_from, _to, _tokenId);
  }
}
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}