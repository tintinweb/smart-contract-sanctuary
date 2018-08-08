pragma solidity ^0.4.18;

/**
 * @title ERC721 interface
 * @dev see https://github.com/ethereum/eips/issues/721
 */
contract ERC721 {
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

  function balanceOf(address _owner) public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function transfer(address _to, uint256 _tokenId) public;
  function approve(address _to, uint256 _tokenId) public;
  function takeOwnership(uint256 _tokenId) public;
}

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
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }
  
  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract CountryToken {
  function getCountryData (uint256 _tokenId) external view returns (address _owner, uint256 _startingPrice, uint256 _price, uint256 _nextPrice, uint256 _payout);
}

/**
 * @title ERC721Token
 * Generic implementation for the required functionality of the ERC721 standard
 */
contract CityToken is ERC721, Ownable {
  using SafeMath for uint256;

  address cAddress = 0x0c507D48C0cd1232B82aA950d487d01Cfc6442Db;
  
  CountryToken countryContract = CountryToken(cAddress);

  //CountryToken private countryContract;
  uint32 constant COUNTRY_IDX = 100;
  uint256 constant COUNTRY_PAYOUT = 15; // 15%

  // Total amount of tokens
  uint256 private totalTokens;
  uint256[] private listedCities;
  uint256 public devOwed;
  uint256 public poolTotal;
  uint256 public lastPurchase;

  // City Data
  mapping (uint256 => City) public cityData;

  // Mapping from token ID to owner
  mapping (uint256 => address) private tokenOwner;

  // Mapping from token ID to approved address
  mapping (uint256 => address) private tokenApprovals;

  // Mapping from owner to list of owned token IDs
  mapping (address => uint256[]) private ownedTokens;

  // Mapping from token ID to index of the owner tokens list
  mapping(uint256 => uint256) private ownedTokensIndex;

  // Balances from % payouts.
  mapping (address => uint256) private payoutBalances; 

  // The amount of Eth this country has withdrawn from the pool.
  mapping (uint256 => uint256) private countryWithdrawn;

  // Events
  event CityPurchased(uint256 indexed _tokenId, address indexed _owner, uint256 _purchasePrice);

  // Purchasing Caps for Determining Next Pool Cut
  uint256 private firstCap  = 0.12 ether;
  uint256 private secondCap = 0.5 ether;
  uint256 private thirdCap  = 1.5 ether;

  // Struct to store City Data
  struct City {
      uint256 price;         // Current price of the item.
      uint256 lastPrice;     // lastPrice this was sold for, used for adding to pool.
      uint256 payout;        // The percent of the pool rewarded.
      uint256 withdrawn;     // The amount of Eth this city has withdrawn from the pool.
      address owner;         // Current owner of the item.
  }

  /**
   * @param _tokenId uint256 ID of new token
   * @param _payoutPercentage uint256 payout percentage (divisible by 10)
   */
   function createPromoListing(uint256 _tokenId, uint256 _startingPrice, uint256 _payoutPercentage) onlyOwner() public {
     uint256 countryId = _tokenId % COUNTRY_IDX;
     address countryOwner;
     uint256 price;
     (countryOwner,,price,,) = countryContract.getCountryData(countryId);
     require (countryOwner != address(0));

     if (_startingPrice == 0) {
       if (price >= thirdCap) _startingPrice = price.div(80);
       else if (price >= secondCap) _startingPrice = price.div(75);
       else _startingPrice = 0.002 ether;
     }

     createListing(_tokenId, _startingPrice, _payoutPercentage, countryOwner);
   }

  /**
  * @dev createListing Adds new ERC721 Token
  * @param _tokenId uint256 ID of new token
  * @param _payoutPercentage uint256 payout percentage (divisible by 10)
  * @param _owner address of new owner
  */
  function createListing(uint256 _tokenId, uint256 _startingPrice, uint256 _payoutPercentage, address _owner) onlyOwner() public {

    // make sure price > 0
    require(_startingPrice > 0);
    // make sure token hasn&#39;t been used yet
    require(cityData[_tokenId].price == 0);
    
    // create new token
    City storage newCity = cityData[_tokenId];

    newCity.owner = _owner;
    newCity.price = _startingPrice;
    newCity.lastPrice = 0;
    newCity.payout = _payoutPercentage;

    // store city in storage
    listedCities.push(_tokenId);
    
    // mint new token
    _mint(_owner, _tokenId);
  }

  function createMultiple (uint256[] _itemIds, uint256[] _prices, uint256[] _payouts, address _owner) onlyOwner() external {
    for (uint256 i = 0; i < _itemIds.length; i++) {
      createListing(_itemIds[i], _prices[i], _payouts[i], _owner);
    }
  }

  /**
  * @dev Determines next price of token
  * @param _price uint256 ID of current price
  */
  function getNextPrice (uint256 _price) private view returns (uint256 _nextPrice) {
    if (_price < firstCap) {
      return _price.mul(200).div(94);
    } else if (_price < secondCap) {
      return _price.mul(135).div(95);
    } else if (_price < thirdCap) {
      return _price.mul(118).div(96);
    } else {
      return _price.mul(115).div(97);
    }
  }

  function calculatePoolCut (uint256 _price) public view returns (uint256 _poolCut) {
    if (_price < firstCap) {
      return _price.mul(10).div(100); // 10%
    } else if (_price < secondCap) {
      return _price.mul(9).div(100); // 9%
    } else if (_price < thirdCap) {
      return _price.mul(8).div(100); // 8%
    } else {
      return _price.mul(7).div(100); // 7%
    }
  }

  /**
  * @dev Purchase city from previous owner
  * @param _tokenId uint256 of token
  */
  function purchaseCity(uint256 _tokenId) public 
    payable
    isNotContract(msg.sender)
  {

    // get data from storage
    City storage city = cityData[_tokenId];
    uint256 price = city.price;
    address oldOwner = city.owner;
    address newOwner = msg.sender;

    // revert checks
    require(price > 0);
    require(msg.value >= price);
    require(oldOwner != msg.sender);

    uint256 excess = msg.value.sub(price);

    // Calculate pool cut for taxes.
    uint256 profit = price.sub(city.lastPrice);
    uint256 poolCut = calculatePoolCut(profit);
    poolTotal += poolCut;

    // 3% goes to developers
    uint256 devCut = price.mul(3).div(100);
    devOwed = devOwed.add(devCut);

    transferCity(oldOwner, newOwner, _tokenId);

    // set new prices
    city.lastPrice = price;
    city.price = getNextPrice(price);

    // raise event
    CityPurchased(_tokenId, newOwner, price);

    // Transfer payment to old owner minus the developer&#39;s and pool&#39;s cut.
    oldOwner.transfer(price.sub(devCut.add(poolCut)));

    // Transfer 10% profit to current country owner
    uint256 countryId = _tokenId % COUNTRY_IDX;
    address countryOwner;
    (countryOwner,,,,) = countryContract.getCountryData(countryId);
    require (countryOwner != address(0));
    countryOwner.transfer(poolCut.mul(COUNTRY_PAYOUT).div(100));

    // Send refund to owner if needed
    if (excess > 0) {
      newOwner.transfer(excess);
    }

    // set last purchase price to storage
    lastPurchase = now;

  }

  /**
  * @dev Transfer City from Previous Owner to New Owner
  * @param _from previous owner address
  * @param _to new owner address
  * @param _tokenId uint256 ID of token
  */
  function transferCity(address _from, address _to, uint256 _tokenId) internal {

    // check token exists
    require(tokenExists(_tokenId));

    // make sure previous owner is correct
    require(cityData[_tokenId].owner == _from);

    require(_to != address(0));
    require(_to != address(this));

    // pay any unpaid payouts to previous owner of city
    updateSinglePayout(_from, _tokenId);

    // clear approvals linked to this token
    clearApproval(_from, _tokenId);

    // remove token from previous owner
    removeToken(_from, _tokenId);

    // update owner and add token to new owner
    cityData[_tokenId].owner = _to;
    addToken(_to, _tokenId);

   //raise event
    Transfer(_from, _to, _tokenId);
  }

  /**
  * @dev Withdraw dev&#39;s cut
  */
  function withdraw() onlyOwner public {
    owner.transfer(devOwed);
    devOwed = 0;
  }

  /**
  * @dev Sets item&#39;s payout
  * @param _itemId itemId to be changed
  */
  function setPayout(uint256 _itemId, uint256 _newPayout) onlyOwner public {
    City storage city = cityData[_itemId];
    city.payout = _newPayout;
  }

  /**
  * @dev Updates the payout for the cities the owner has
  * @param _owner address of token owner
  */
  function updatePayout(address _owner) public {
    uint256[] memory cities = ownedTokens[_owner];
    uint256 owed;
    for (uint256 i = 0; i < cities.length; i++) {
        uint256 totalCityOwed = poolTotal * cityData[cities[i]].payout / 10000;
        uint256 cityOwed = totalCityOwed.sub(cityData[cities[i]].withdrawn);
        owed += cityOwed;
        
        cityData[cities[i]].withdrawn += cityOwed;
    }
    payoutBalances[_owner] += owed;
  }

  /**
   * @dev Update a single city payout for transfers.
   * @param _owner Address of the owner of the city.
   * @param _itemId Unique Id of the token.
  **/
  function updateSinglePayout(address _owner, uint256 _itemId) internal {
    uint256 totalCityOwed = poolTotal * cityData[_itemId].payout / 10000;
    uint256 cityOwed = totalCityOwed.sub(cityData[_itemId].withdrawn);
        
    cityData[_itemId].withdrawn += cityOwed;
    payoutBalances[_owner] += cityOwed;
  }

  /**
  * @dev Owner can withdraw their accumulated payouts
  * @param _owner address of token owner
  */
  function withdrawRent(address _owner) public {
      updatePayout(_owner);
      uint256 payout = payoutBalances[_owner];
      payoutBalances[_owner] = 0;
      _owner.transfer(payout);
  }

  function getRentOwed(address _owner) public view returns (uint256 owed) {
    updatePayout(_owner);
    return payoutBalances[_owner];
  }

  /**
  * @dev Return all city data
  * @param _tokenId uint256 of token
  */
  function getCityData (uint256 _tokenId) external view 
  returns (address _owner, uint256 _price, uint256 _nextPrice, uint256 _payout, address _cOwner, uint256 _cPrice, uint256 _cPayout) 
  {
    City memory city = cityData[_tokenId];
    address countryOwner;
    uint256 countryPrice;
    uint256 countryPayout;
    (countryOwner,,countryPrice,,countryPayout) = countryContract.getCountryData(_tokenId % COUNTRY_IDX);
    return (city.owner, city.price, getNextPrice(city.price), city.payout, countryOwner, countryPrice, countryPayout);
  }

  /**
  * @dev Determines if token exists by checking it&#39;s price
  * @param _tokenId uint256 ID of token
  */
  function tokenExists (uint256 _tokenId) public view returns (bool _exists) {
    return cityData[_tokenId].price > 0;
  }

  /**
  * @dev Guarantees msg.sender is owner of the given token
  * @param _tokenId uint256 ID of the token to validate its ownership belongs to msg.sender
  */
  modifier onlyOwnerOf(uint256 _tokenId) {
    require(ownerOf(_tokenId) == msg.sender);
    _;
  }

  /**
  * @dev Guarantees msg.sender is not a contract
  * @param _buyer address of person buying city
  */
  modifier isNotContract(address _buyer) {
    uint size;
    assembly { size := extcodesize(_buyer) }
    require(size == 0);
    _;
  }

  /**
  * @dev Gets the total amount of tokens stored by the contract
  * @return uint256 representing the total amount of tokens
  */
  function totalSupply() public view returns (uint256) {
    return totalTokens;
  }

  /**
  * @dev Gets the balance of the specified address
  * @param _owner address to query the balance of
  * @return uint256 representing the amount owned by the passed address
  */
  function balanceOf(address _owner) public view returns (uint256) {
    return ownedTokens[_owner].length;
  }

  /**
  * @dev Gets the list of tokens owned by a given address
  * @param _owner address to query the tokens of
  * @return uint256[] representing the list of tokens owned by the passed address
  */
  function tokensOf(address _owner) public view returns (uint256[]) {
    return ownedTokens[_owner];
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
   * @dev Gets the approved address to take ownership of a given token ID
   * @param _tokenId uint256 ID of the token to query the approval of
   * @return address currently approved to take ownership of the given token ID
   */
  function approvedFor(uint256 _tokenId) public view returns (address) {
    return tokenApprovals[_tokenId];
  }

  /**
  * @dev Transfers the ownership of a given token ID to another address
  * @param _to address to receive the ownership of the given token ID
  * @param _tokenId uint256 ID of the token to be transferred
  */
  function transfer(address _to, uint256 _tokenId) public onlyOwnerOf(_tokenId) {
    clearApprovalAndTransfer(msg.sender, _to, _tokenId);
  }

  /**
  * @dev Approves another address to claim for the ownership of the given token ID
  * @param _to address to be approved for the given token ID
  * @param _tokenId uint256 ID of the token to be approved
  */
  function approve(address _to, uint256 _tokenId) public onlyOwnerOf(_tokenId) {
    address owner = ownerOf(_tokenId);
    require(_to != owner);
    if (approvedFor(_tokenId) != 0 || _to != 0) {
      tokenApprovals[_tokenId] = _to;
      Approval(owner, _to, _tokenId);
    }
  }

  /**
  * @dev Claims the ownership of a given token ID
  * @param _tokenId uint256 ID of the token being claimed by the msg.sender
  */
  function takeOwnership(uint256 _tokenId) public {
    require(isApprovedFor(msg.sender, _tokenId));
    clearApprovalAndTransfer(ownerOf(_tokenId), msg.sender, _tokenId);
  }

  /**
   * @dev Tells whether the msg.sender is approved for the given token ID or not
   * This function is not private so it can be extended in further implementations like the operatable ERC721
   * @param _owner address of the owner to query the approval of
   * @param _tokenId uint256 ID of the token to query the approval of
   * @return bool whether the msg.sender is approved for the given token ID or not
   */
  function isApprovedFor(address _owner, uint256 _tokenId) internal view returns (bool) {
    return approvedFor(_tokenId) == _owner;
  }
  
  /**
  * @dev Internal function to clear current approval and transfer the ownership of a given token ID
  * @param _from address which you want to send tokens from
  * @param _to address which you want to transfer the token to
  * @param _tokenId uint256 ID of the token to be transferred
  */
  function clearApprovalAndTransfer(address _from, address _to, uint256 _tokenId) internal isNotContract(_to) {
    require(_to != address(0));
    require(_to != ownerOf(_tokenId));
    require(ownerOf(_tokenId) == _from);

    clearApproval(_from, _tokenId);
    updateSinglePayout(_from, _tokenId);
    removeToken(_from, _tokenId);
    addToken(_to, _tokenId);
    Transfer(_from, _to, _tokenId);
  }

  /**
  * @dev Internal function to clear current approval of a given token ID
  * @param _tokenId uint256 ID of the token to be transferred
  */
  function clearApproval(address _owner, uint256 _tokenId) private {
    require(ownerOf(_tokenId) == _owner);
    tokenApprovals[_tokenId] = 0;
    Approval(_owner, 0, _tokenId);
  }


    /**
  * @dev Mint token function
  * @param _to The address that will own the minted token
  * @param _tokenId uint256 ID of the token to be minted by the msg.sender
  */
  function _mint(address _to, uint256 _tokenId) internal {
    require(_to != address(0));
    addToken(_to, _tokenId);
    Transfer(0x0, _to, _tokenId);
  }

  /**
  * @dev Internal function to add a token ID to the list of a given address
  * @param _to address representing the new owner of the given token ID
  * @param _tokenId uint256 ID of the token to be added to the tokens list of the given address
  */
  function addToken(address _to, uint256 _tokenId) private {
    require(tokenOwner[_tokenId] == address(0));
    tokenOwner[_tokenId] = _to;
    cityData[_tokenId].owner = _to;
    uint256 length = balanceOf(_to);
    ownedTokens[_to].push(_tokenId);
    ownedTokensIndex[_tokenId] = length;
    totalTokens = totalTokens.add(1);
  }

  /**
  * @dev Internal function to remove a token ID from the list of a given address
  * @param _from address representing the previous owner of the given token ID
  * @param _tokenId uint256 ID of the token to be removed from the tokens list of the given address
  */
  function removeToken(address _from, uint256 _tokenId) private {
    require(ownerOf(_tokenId) == _from);

    uint256 tokenIndex = ownedTokensIndex[_tokenId];
    uint256 lastTokenIndex = balanceOf(_from).sub(1);
    uint256 lastToken = ownedTokens[_from][lastTokenIndex];

    tokenOwner[_tokenId] = 0;
    ownedTokens[_from][tokenIndex] = lastToken;
    ownedTokens[_from][lastTokenIndex] = 0;
    // Note that this will handle single-element arrays. In that case, both tokenIndex and lastTokenIndex are going to
    // be zero. Then we can make sure that we will remove _tokenId from the ownedTokens list since we are first swapping
    // the lastToken to the first position, and then dropping the element placed in the last position of the list

    ownedTokens[_from].length--;
    ownedTokensIndex[_tokenId] = 0;
    ownedTokensIndex[lastToken] = tokenIndex;
    totalTokens = totalTokens.sub(1);
  }

  function name() public pure returns (string _name) {
    return "EtherCities.io City";
  }

  function symbol() public pure returns (string _symbol) {
    return "EC";
  }

}