pragma solidity ^0.4.18;

// File: zeppelin-solidity/contracts/ownership/Ownable.sol

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
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

// File: zeppelin-solidity/contracts/token/ERC721/ERC721.sol

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

// File: contracts/Marketplace.sol

contract Marketplace is Ownable {
    ERC721 public nft;

    mapping (uint256 => Listing) public listings;

    uint256 public minListingSeconds;
    uint256 public maxListingSeconds;

    struct Listing {
        address seller;
        uint256 startingPrice;
        uint256 minimumPrice;
        uint256 createdAt;
        uint256 durationSeconds;
    }

    event TokenListed(uint256 indexed _tokenId, uint256 _startingPrice, uint256 _minimumPrice, uint256 _durationSeconds, address _seller);
    event TokenUnlisted(uint256 indexed _tokenId, address _unlister);
    event TokenSold(uint256 indexed _tokenId, uint256 _price, uint256 _paidAmount, address indexed _seller, address _buyer);

    modifier nftOnly() {
        require(msg.sender == address(nft));
        _;
    }

    function Marketplace(ERC721 _nft, uint256 _minListingSeconds, uint256 _maxListingSeconds) public {
        nft = _nft;
        minListingSeconds = _minListingSeconds;
        maxListingSeconds = _maxListingSeconds;
    }

    function list(address _tokenSeller, uint256 _tokenId, uint256 _startingPrice, uint256 _minimumPrice, uint256 _durationSeconds) public nftOnly {
        require(_durationSeconds >= minListingSeconds && _durationSeconds <= maxListingSeconds);
        require(_startingPrice >= _minimumPrice);
        require(! listingActive(_tokenId));
        listings[_tokenId] = Listing(_tokenSeller, _startingPrice, _minimumPrice, now, _durationSeconds);
        nft.takeOwnership(_tokenId);
        TokenListed(_tokenId, _startingPrice, _minimumPrice, _durationSeconds, _tokenSeller);
    }

    function unlist(address _caller, uint256 _tokenId) public nftOnly {
        address _seller = listings[_tokenId].seller;
        // Allow owner to unlist (via nft) for when it&#39;s time to shut this down
        require(_seller == _caller || address(owner) == _caller);
        nft.transfer(_seller, _tokenId);
        delete listings[_tokenId];
        TokenUnlisted(_tokenId, _caller);
    }

    function purchase(address _caller, uint256 _tokenId, uint256 _totalPaid) public payable nftOnly {
        Listing memory _listing = listings[_tokenId];
        address _seller = _listing.seller;

        require(_caller != _seller); // Doesn&#39;t make sense for someone to buy/sell their own token.
        require(listingActive(_tokenId));

        uint256 _price = currentPrice(_tokenId);
        require(_totalPaid >= _price);

        delete listings[_tokenId];

        nft.transfer(_caller, _tokenId);
        _seller.transfer(msg.value);
        TokenSold(_tokenId, _price, _totalPaid, _seller, _caller);
    }

    function currentPrice(uint256 _tokenId) public view returns (uint256) {
        Listing memory listing = listings[_tokenId];
        require(now >= listing.createdAt);

        uint256 _deadline = listing.createdAt + listing.durationSeconds;
        require(now <= _deadline);

        uint256 _elapsedTime = now - listing.createdAt;
        uint256 _progress = (_elapsedTime * 100) / listing.durationSeconds;
        uint256 _delta = listing.startingPrice - listing.minimumPrice;
        return listing.startingPrice - ((_delta * _progress) / 100);
    }

    function listingActive(uint256 _tokenId) internal view returns (bool) {
        Listing memory listing = listings[_tokenId];
        return listing.createdAt + listing.durationSeconds >= now && now >= listing.createdAt;
    }
}

// File: zeppelin-solidity/contracts/lifecycle/Pausable.sol

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

// File: zeppelin-solidity/contracts/math/SafeMath.sol

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

// File: zeppelin-solidity/contracts/token/ERC721/ERC721Token.sol

/**
 * @title ERC721Token
 * Generic implementation for the required functionality of the ERC721 standard
 */
contract ERC721Token is ERC721 {
  using SafeMath for uint256;

  // Total amount of tokens
  uint256 private totalTokens;

  // Mapping from token ID to owner
  mapping (uint256 => address) private tokenOwner;

  // Mapping from token ID to approved address
  mapping (uint256 => address) private tokenApprovals;

  // Mapping from owner to list of owned token IDs
  mapping (address => uint256[]) private ownedTokens;

  // Mapping from token ID to index of the owner tokens list
  mapping(uint256 => uint256) private ownedTokensIndex;

  /**
  * @dev Guarantees msg.sender is owner of the given token
  * @param _tokenId uint256 ID of the token to validate its ownership belongs to msg.sender
  */
  modifier onlyOwnerOf(uint256 _tokenId) {
    require(ownerOf(_tokenId) == msg.sender);
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
  * @dev Burns a specific token
  * @param _tokenId uint256 ID of the token being burned by the msg.sender
  */
  function _burn(uint256 _tokenId) onlyOwnerOf(_tokenId) internal {
    if (approvedFor(_tokenId) != 0) {
      clearApproval(msg.sender, _tokenId);
    }
    removeToken(msg.sender, _tokenId);
    Transfer(msg.sender, 0x0, _tokenId);
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
  function clearApprovalAndTransfer(address _from, address _to, uint256 _tokenId) internal {
    require(_to != address(0));
    require(_to != ownerOf(_tokenId));
    require(ownerOf(_tokenId) == _from);

    clearApproval(_from, _tokenId);
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
  * @dev Internal function to add a token ID to the list of a given address
  * @param _to address representing the new owner of the given token ID
  * @param _tokenId uint256 ID of the token to be added to the tokens list of the given address
  */
  function addToken(address _to, uint256 _tokenId) private {
    require(tokenOwner[_tokenId] == address(0));
    tokenOwner[_tokenId] = _to;
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
}

// File: contracts/PineappleArcadeTrophy.sol

contract PineappleArcadeTrophy is ERC721Token, Pausable {
    /// @notice Name and Symbol are part of the ERC721 standard
    string public constant name = "PineappleArcadeTrophy";
    string public constant symbol = "DEGEN";

    Marketplace public marketplace;
    uint256 public maxTrophies;

    /// @dev trophyId to trophyName
    mapping (uint256 => bytes32) public trophies;

    function PineappleArcadeTrophy(uint256 _maxTrophies) public {
        maxTrophies = _maxTrophies;
        pause();
    }

    function setMarketplace(Marketplace _marketplace) external onlyOwner {
        marketplace = _marketplace;
    }

    function grantTrophy(address _initialOwner, bytes32 _trophyName) external onlyOwner {
        require(totalSupply() < maxTrophies);
        require(_trophyName != 0x0);
        trophies[nextId()] = _trophyName;
        _mint(_initialOwner, nextId());
    }

    function listTrophy(uint256 _trophyId, uint256 _startingPriceWei, uint256 _minimumPriceWei, uint256 _durationSeconds) external whenNotPaused {
        address _trophySeller = ownerOf(_trophyId);
        require(_trophySeller == msg.sender);
        approve(marketplace, _trophyId);
        marketplace.list(_trophySeller, _trophyId, _startingPriceWei, _minimumPriceWei, _durationSeconds);
    }

    function unlistTrophy(uint256 _trophyId) external {
        marketplace.unlist(msg.sender, _trophyId);
    }

    function currentPrice(uint256 _trophyId) public view returns(uint256) {
        return marketplace.currentPrice(_trophyId);
    }

    function purchaseTrophy(uint256 _trophyId) external payable whenNotPaused {
        // Blockade collects 3.75% of each market transaction, paid by the seller.
        uint256 _blockadeFee = (msg.value * 375) / 10000; // Note: small values prevent Blockade from earning anything
        uint256 _sellerTake = msg.value - _blockadeFee;
        marketplace.purchase.value(_sellerTake)(msg.sender, _trophyId, msg.value);
    }

    /// @notice With each call to purchaseTrophy, fees will build up in this contract&#39;s balance.
    /// This method allows the contract owner to transfer that balance to their account.
    function withdrawBalance() external onlyOwner {
        owner.transfer(this.balance);
    }

    function nextId() internal view returns (uint256) {
        return totalSupply() + 1;
    }
}