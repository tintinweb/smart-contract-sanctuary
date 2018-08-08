pragma solidity ^0.4.18;
/** 
*@title ERC721 interface
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

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
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
}

/**
 * @title ERC721Token
 * Generic implementation for the required functionality of the ERC721 standard
 */
contract CryptoMayorToken is ERC721, Ownable, Pausable {
  using SafeMath for uint256;

  // Total amount of tokens
  uint256 private totalTokens;
  uint256[] private listed;
  uint256 public devOwed;
  uint256 public cityPoolTotal;
  uint256 public landmarkPoolTotal;
  uint256 public otherPoolTotal;
  uint256 public lastPurchase;

  // Token Data
  mapping (uint256 => Token) private tokens;

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

  // Events
  event Purchased(uint256 indexed _tokenId, address indexed _owner, uint256 _purchasePrice);

  // Purchasing Caps for Determining Next Pool Cut
  uint256 private firstCap  = 0.5 ether;
  uint256 private secondCap = 1.0 ether;
  uint256 private thirdCap  = 3.0 ether;
  uint256 private finalCap  = 5.0 ether;

  // Percentages
  uint256 public feePercentage = 5;
  uint256 public dividendCutPercentage = 100; // 100 / 10000
  uint256 public dividendDecreaseFactor = 2;
  uint256 public powermayorCutPercentage = 1;
  uint256 public mayorCutPercentage = 1;
  uint256 public cityPoolCutPercentage = 15;

  // Mayors
  uint256 private powermayorTokenId = 10000000;

  uint256 private CITY = 1;
  uint256 private LANDMARK = 2;
  uint256 private OTHER = 3;

  // Struct to store Token Data
  struct Token {
      uint256 price;         // Current price of the item.
      uint256 lastPrice;     // lastPrice this was sold for, used for adding to pool.
      uint256 payout;        // The percent of the pool rewarded.
      uint256 withdrawn;     // The amount of Eth this token has withdrawn from the pool.
      address owner;         // Current owner of the item.
      uint256 mayorTokenId;   // Current mayor of the token - 1% mayorCut
      uint8   kind;          // 1 - city, 2 - landmark, 3 - other
      address[5] previousOwners;
  }

  /**
  * @dev createListing Adds new ERC721 Token
  * @param _tokenId uint256 ID of new token
  * @param _price uint256 starting price in wei
  * @param _payoutPercentage uint256 payout percentage (divisible by 10)
  * @param _owner address of new owner
  */
  function createToken(uint256 _tokenId, uint256 _price, uint256 _lastPrice, uint256 _payoutPercentage, uint8 _kind, uint256 _mayorTokenId, address _owner) onlyOwner() public {
    require(_price > 0);
    require(_lastPrice < _price);
    
    // make sure token hasn&#39;t been used yet
    require(tokens[_tokenId].price == 0);
    
    // check for kinds
    require(_kind > 0 && _kind <= 3);
    
    // create new token
    Token storage newToken = tokens[_tokenId];

    newToken.owner = _owner;
    newToken.price = _price;
    newToken.lastPrice = _lastPrice;
    newToken.payout = _payoutPercentage;
    newToken.kind = _kind;
    newToken.mayorTokenId = _mayorTokenId;
    newToken.previousOwners = [address(this), address(this), address(this), address(this), address(this)];

    // store token in storage
    listed.push(_tokenId);
    
    // mint new token
    _mint(_owner, _tokenId);
  }

  function createMultiple (uint256[] _itemIds, uint256[] _prices, uint256[] _lastPrices, uint256[] _payouts, uint8[] _kinds, uint256[] _mayorTokenIds, address[] _owners) onlyOwner() external {
    for (uint256 i = 0; i < _itemIds.length; i++) {
      createToken(_itemIds[i], _prices[i], _lastPrices[i], _payouts[i], _kinds[i], _mayorTokenIds[i], _owners[i]);
    }
  }

  /**
  * @dev Determines next price of token
  * @param _price uint256 ID of current price
  */
  function getNextPrice (uint256 _price) public view returns (uint256 _nextPrice) {
    if (_price < firstCap) {
      return _price.mul(200).div(100 - feePercentage);
    } else if (_price < secondCap) {
      return _price.mul(135).div(100 - feePercentage);
    } else if (_price < thirdCap) {
      return _price.mul(125).div(100 - feePercentage);
    } else if (_price < finalCap) {
      return _price.mul(117).div(100 - feePercentage);
    } else {
      return _price.mul(115).div(100 - feePercentage);
    }
  }

  function calculatePoolCut (uint256 _price) public view returns (uint256 _poolCut) {
    if (_price < firstCap) {
      return _price.mul(10).div(100);
    } else if (_price < secondCap) {
      return _price.mul(9).div(100);
    } else if (_price < thirdCap) {
      return _price.mul(8).div(100);
    } else if (_price < finalCap) {
      return _price.mul(7).div(100);
    } else {
      return _price.mul(5).div(100);
    }
  }

  /**
  * @dev Purchase toekn from previous owner
  * @param _tokenId uint256 of token
  */
  function purchase(uint256 _tokenId) public 
    payable
    isNotContract(msg.sender)
  {
    require(!paused);

    // get data from storage
    Token storage token = tokens[_tokenId];
    uint256 price = token.price;
    address oldOwner = token.owner;

    // revert checks
    require(price > 0);
    require(msg.value >= price);
    require(oldOwner != msg.sender);

    // Calculate pool cut for taxes.
    uint256 priceDelta = price.sub(token.lastPrice);
    uint256 poolCut = calculatePoolCut(priceDelta);
    
    _updatePools(token.kind, poolCut);
    
    uint256 fee = price.mul(feePercentage).div(100);
    devOwed = devOwed.add(fee);

    // Dividends
    uint256 taxesPaid = _payDividendsAndMayors(token, price);

    _shiftPreviousOwners(token, msg.sender);

    transferToken(oldOwner, msg.sender, _tokenId);

    // Transfer payment to old owner minus the developer&#39;s and pool&#39;s cut.
    // Calculate the winnings for the previous owner.
    uint256 finalPayout = price.sub(fee).sub(poolCut).sub(taxesPaid);

    // set new prices
    token.lastPrice = price;
    token.price = getNextPrice(price);

    // raise event
    Purchased(_tokenId, msg.sender, price);

    if (oldOwner != address(this)) {
      oldOwner.transfer(finalPayout);
    }

    // Calculate overspending
    uint256 excess = msg.value - price;
    
    if (excess > 0) {
        // Refund overspending
        msg.sender.transfer(excess);
    }
    
    // set last purchase price to storage
    lastPurchase = now;
  }

    /// @dev Shift the 6 most recent buyers, and add the new buyer
    /// to the front.
    /// @param _newOwner The buyer to add to the front of the recent
    /// buyers list.
  function _shiftPreviousOwners(Token storage _token, address _newOwner) private {
      _token.previousOwners[4] = _token.previousOwners[3];
      _token.previousOwners[3] = _token.previousOwners[2];
      _token.previousOwners[2] = _token.previousOwners[1];
      _token.previousOwners[1] = _token.previousOwners[0];
      _token.previousOwners[0] = _newOwner;
  }

  function _updatePools(uint8 _kind, uint256 _poolCut) internal {
    uint256 poolCutToMain = _poolCut.mul(cityPoolCutPercentage).div(100);

    if (_kind == CITY) {
      cityPoolTotal += _poolCut;
    } else if (_kind == LANDMARK) {
      cityPoolTotal += poolCutToMain;

      landmarkPoolTotal += _poolCut.sub(poolCutToMain);
    } else if (_kind == OTHER) {
      cityPoolTotal += poolCutToMain;

      otherPoolTotal += _poolCut.sub(poolCutToMain);
    }
  }

  // 1%, 0.5%, 0.25%, 0.125%, 0.0625%
  function _payDividendsAndMayors(Token _token, uint256 _price) private returns (uint256 paid) {
    uint256 dividend0 = _price.mul(dividendCutPercentage).div(10000);
    uint256 dividend1 = dividend0.div(dividendDecreaseFactor);
    uint256 dividend2 = dividend1.div(dividendDecreaseFactor);
    uint256 dividend3 = dividend2.div(dividendDecreaseFactor);
    uint256 dividend4 = dividend3.div(dividendDecreaseFactor);

    // Pay first dividend.
    if (_token.previousOwners[0] != address(this)) {_token.previousOwners[0].transfer(dividend0); paid = paid.add(dividend0);}
    if (_token.previousOwners[1] != address(this)) {_token.previousOwners[1].transfer(dividend1); paid = paid.add(dividend1);}
    if (_token.previousOwners[2] != address(this)) {_token.previousOwners[2].transfer(dividend2); paid = paid.add(dividend2);}
    if (_token.previousOwners[3] != address(this)) {_token.previousOwners[3].transfer(dividend3); paid = paid.add(dividend3);}
    if (_token.previousOwners[4] != address(this)) {_token.previousOwners[4].transfer(dividend4); paid = paid.add(dividend4);}

    uint256 tax = _price.mul(1).div(100);

    if (tokens[powermayorTokenId].owner != address(0)) {
      tokens[powermayorTokenId].owner.transfer(tax);
      paid = paid.add(tax);
    }

    if (tokens[_token.mayorTokenId].owner != address(0)) { 
      tokens[_token.mayorTokenId].owner.transfer(tax);
      paid = paid.add(tax);
    }
  }

  /**
  * @dev Transfer Token from Previous Owner to New Owner
  * @param _from previous owner address
  * @param _to new owner address
  * @param _tokenId uint256 ID of token
  */
  function transferToken(address _from, address _to, uint256 _tokenId) internal {

    // check token exists
    require(tokenExists(_tokenId));

    // make sure previous owner is correct
    require(tokens[_tokenId].owner == _from);

    require(_to != address(0));
    require(_to != address(this));

    // pay any unpaid payouts to previous owner of token
    updateSinglePayout(_from, _tokenId);

    // clear approvals linked to this token
    clearApproval(_from, _tokenId);

    // remove token from previous owner
    removeToken(_from, _tokenId);

    // update owner and add token to new owner
    tokens[_tokenId].owner = _to;
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
  * @dev Updates the payout for the token the owner has
  * @param _owner address of token owner
  */
  function updatePayout(address _owner) public {
    uint256[] memory ownerTokens = ownedTokens[_owner];
    uint256 owed;
    for (uint256 i = 0; i < ownerTokens.length; i++) {
        uint256 totalOwed;
        
        if (tokens[ownerTokens[i]].kind == CITY) {
          totalOwed = cityPoolTotal * tokens[ownerTokens[i]].payout / 10000;
        } else if (tokens[ownerTokens[i]].kind == LANDMARK) {
          totalOwed = landmarkPoolTotal * tokens[ownerTokens[i]].payout / 10000;
        } else if (tokens[ownerTokens[i]].kind == OTHER) {
          totalOwed = otherPoolTotal * tokens[ownerTokens[i]].payout / 10000;
        }

        uint256 totalTokenOwed = totalOwed.sub(tokens[ownerTokens[i]].withdrawn);
        owed += totalTokenOwed;
        
        tokens[ownerTokens[i]].withdrawn += totalTokenOwed;
    }
    payoutBalances[_owner] += owed;
  }

  function priceOf(uint256 _tokenId) public view returns (uint256) {
    return tokens[_tokenId].price;
  }

  /**
   * @dev Update a single toekn payout for transfers.
   * @param _owner Address of the owner of the token.
   * @param _tokenId Unique Id of the token.
  **/
  function updateSinglePayout(address _owner, uint256 _tokenId) internal {
    uint256 totalOwed;
        
    if (tokens[_tokenId].kind == CITY) {
      totalOwed = cityPoolTotal * tokens[_tokenId].payout / 10000;
    } else if (tokens[_tokenId].kind == LANDMARK) {
      totalOwed = landmarkPoolTotal * tokens[_tokenId].payout / 10000;
    } else if (tokens[_tokenId].kind == OTHER) {
      totalOwed = otherPoolTotal * tokens[_tokenId].payout / 10000;
    }

    uint256 totalTokenOwed = totalOwed.sub(tokens[_tokenId].withdrawn);
        
    tokens[_tokenId].withdrawn += totalTokenOwed;
    payoutBalances[_owner] += totalTokenOwed;
  }

  /**
  * @dev Owner can withdraw their accumulated payouts
  * @param _owner address of token owner
  */
  function withdrawRent(address _owner) public {
    require(_owner != address(0));
    updatePayout(_owner);
    uint256 payout = payoutBalances[_owner];
    payoutBalances[_owner] = 0;
    _owner.transfer(payout);
  }

  function getRentOwed(address _owner) public view returns (uint256 owed) {
    require(_owner != address(0));
    updatePayout(_owner);
    return payoutBalances[_owner];
  }

  /**
  * @dev Return all token data
  * @param _tokenId uint256 of token
  */
  function getToken (uint256 _tokenId) external view 
  returns (address _owner, uint256 _price, uint256 _lastPrice, uint256 _nextPrice, uint256 _payout, uint8 _kind, uint256 _mayorTokenId, address[5] _previosOwners) 
  {
    Token memory token = tokens[_tokenId];
    return (token.owner, token.price, token.lastPrice, getNextPrice(token.price), token.payout, token.kind, token.mayorTokenId, token.previousOwners);
  }

  /**
  * @dev Determines if token exists by checking it&#39;s price
  * @param _tokenId uint256 ID of token
  */
  function tokenExists (uint256 _tokenId) public view returns (bool _exists) {
    return tokens[_tokenId].price > 0;
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
  * @param _buyer address of person buying token
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
    tokens[_tokenId].owner = _to;
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
    return "CryptoMayor.io";
  }

  function symbol() public pure returns (string _symbol) {
    return "CMC";
  }

  function setFeePercentage(uint256 _newFee) onlyOwner public {
    require(_newFee <= 5);
    require(_newFee >= 3);

    feePercentage = _newFee;
  }
  
  function setMainPoolCutPercentage(uint256 _newFee) onlyOwner public {
    require(_newFee <= 30);
    require(_newFee >= 5);

    cityPoolCutPercentage = _newFee;
  }

  function setDividendCutPercentage(uint256 _newFee) onlyOwner public {
    require(_newFee <= 200);
    require(_newFee >= 50);

    dividendCutPercentage = _newFee;
  }

  // Migration
  OldContract oldContract;

  function setOldContract(address _addr) onlyOwner public {
    oldContract = OldContract(_addr);
  }

  function populateFromOldContract(uint256[] _ids) onlyOwner public {
    for (uint256 i = 0; i < _ids.length; i++) {
      // Can&#39;t rewrite tokens
      if (tokens[_ids[i]].price == 0) {
        address _owner;
        uint256 _price;
        uint256 _lastPrice;
        uint256 _nextPrice;
        uint256 _payout;
        uint8 _kind;
        uint256 _mayorTokenId;

        (_owner, _price, _lastPrice, _nextPrice, _payout, _kind, _mayorTokenId) = oldContract.getToken(_ids[i]);

        createToken(_ids[i], _price, _lastPrice, _payout, _kind, _mayorTokenId, _owner);
      }
    }
  }
}

interface OldContract {
  function getToken (uint256 _tokenId) external view 
  returns (address _owner, uint256 _price, uint256 _lastPrice, uint256 _nextPrice, uint256 _payout, uint8 _kind, uint256 _mayorTokenId);
}