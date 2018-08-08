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

  mapping (address => bool) public admins;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
    admins[owner] = true;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
  
  modifier onlyAdmin() {
    require(admins[msg.sender]);
    _;
  }

  function changeAdmin(address _newAdmin, bool _approved) onlyOwner public {
    admins[_newAdmin] = _approved;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
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

/**
 * @title ERC721Token
 * Generic implementation for the required functionality of the ERC721 standard
 */
contract Economeme is ERC721, Ownable {
  using SafeMath for uint256;

  // Total amount of tokens
  uint256 private totalTokens;
  uint256 public developerCut;
  uint256 public submissionPool; // The fund amount gained from submissions.
  uint256 public submissionPrice; // How much it costs to submit a meme.
  uint256 public endingBalance; // Balance at the end of the last purchase.

  // Meme Data
  mapping (uint256 => Meme) public memeData;

  // Mapping from token ID to owner
  mapping (uint256 => address) private tokenOwner;

  // Mapping from token ID to approved address
  mapping (uint256 => address) private tokenApprovals;

  // Mapping from owner to list of owned token IDs
  mapping (address => uint256[]) private ownedTokens;

  // Mapping from token ID to index of the owner tokens list
  mapping(uint256 => uint256) private ownedTokensIndex;

  // Balances from % payouts.
  mapping (address => uint256) public creatorBalances;

  // Events
  event Purchase(uint256 indexed _tokenId, address indexed _buyer, address indexed _seller, uint256 _purchasePrice);
  event Creation(address indexed _creator, uint256 _tokenId, uint256 _timestamp);

  // Purchasing caps for determining next price
  uint256 private firstCap  = 0.02 ether;
  uint256 private secondCap = 0.5 ether;
  uint256 private thirdCap  = 2.0 ether;
  uint256 private finalCap  = 5.0 ether;

  // Struct to store Meme data
  struct Meme {
    uint256 price;         // Current price of the item.
    address owner;         // Current owner of the item.
    address creator;       // Address that created dat boi.
  }
  
  function Economeme() public {
    submissionPrice = 1 ether / 100;
  }

/** ******************************* Buying ********************************* **/

  /**
  * @dev Purchase meme from previous owner
  * @param _tokenId uint256 of token
  */
  function buyToken(uint256 _tokenId) public 
    payable
  {
    // get data from storage
    Meme storage meme = memeData[_tokenId];
    uint256 price = meme.price;
    address oldOwner = meme.owner;
    address newOwner = msg.sender;
    uint256 excess = msg.value.sub(price);

    // revert checks
    require(price > 0);
    require(msg.value >= price);
    require(oldOwner != msg.sender);
    
    uint256 devCut = price.mul(2).div(100);
    developerCut = developerCut.add(devCut);

    uint256 creatorCut = price.mul(2).div(100);
    creatorBalances[meme.creator] = creatorBalances[meme.creator].add(creatorCut);

    uint256 transferAmount = price.sub(creatorCut + devCut);

    transferToken(oldOwner, newOwner, _tokenId);

    // raise event
    emit Purchase(_tokenId, newOwner, oldOwner, price);

    // set new price
    meme.price = getNextPrice(price);

    // Safe transfer to owner that will bypass throws on bad contracts.
    safeTransfer(oldOwner, transferAmount);
    
    // Send refund to buyer if needed
    if (excess > 0) {
      newOwner.transfer(excess);
    }
    
    // If safeTransfer did not succeed, we take lost funds into our cut and will return manually if it wasn&#39;t malicious.
    // Otherwise we&#39;re going out for some beers.
    if (address(this).balance > endingBalance + creatorCut + devCut) submissionPool += transferAmount;
    
    endingBalance = address(this).balance;
  }

  /**
   * @dev safeTransfer allows a push to an address that will not revert if the address throws.
   * @param _oldOwner The owner that funds will be transferred to.
   * @param _amount The amount of funds that will be transferred.
  */
  function safeTransfer(address _oldOwner, uint256 _amount) internal { 
    assembly { 
        let x := mload(0x40) 
        let success := call(
            5000, 
            _oldOwner, 
            _amount, 
            x, 
            0x0, 
            x, 
            0x20) 
        mstore(0x40,add(x,0x20)) 
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
    require(memeData[_tokenId].owner == _from);

    require(_to != address(0));
    require(_to != address(this));

    // clear approvals linked to this token
    clearApproval(_from, _tokenId);

    // remove token from previous owner
    removeToken(_from, _tokenId);

    // update owner and add token to new owner
    addToken(_to, _tokenId);

    // raise event
    emit Transfer(_from, _to, _tokenId);
  }
  
  /**
  * @dev Determines next price of token
  * @param _price uint256 ID of current price
  */
  function getNextPrice (uint256 _price) internal view returns (uint256 _nextPrice) {
    if (_price < firstCap) {
      return _price.mul(200).div(95);
    } else if (_price < secondCap) {
      return _price.mul(135).div(96);
    } else if (_price < thirdCap) {
      return _price.mul(125).div(97);
    } else if (_price < finalCap) {
      return _price.mul(117).div(97);
    } else {
      return _price.mul(115).div(98);
    }
  }

/** *********************** Player Administrative ************************** **/

  /**
  * @dev Used by posters to submit and create a new meme.
  */
  function createToken() external payable {
    // make sure token hasn&#39;t been used yet
    uint256 tokenId = totalTokens + 1;
    require(memeData[tokenId].price == 0);
    require(msg.value == submissionPrice);
    submissionPool += submissionPrice;
    endingBalance = address(this).balance;
    
    // create new token
    memeData[tokenId] = Meme(1 ether / 100, msg.sender, msg.sender);

    // mint new token
    _mint(msg.sender, tokenId);
    
    emit Creation(msg.sender, tokenId, block.timestamp);
  }

  /**
  * @dev Withdraw anyone&#39;s creator balance.
  * @param _beneficiary The person whose balance shall be sent to them.
  */
  function withdrawBalance(address _beneficiary) external {
    uint256 payout = creatorBalances[_beneficiary];
    creatorBalances[_beneficiary] = 0;
    _beneficiary.transfer(payout);
    endingBalance = address(this).balance;
  }

/** **************************** Frontend ********************************** **/

  /**
  * @dev Return all relevant data for a meme.
  * @param _tokenId Unique meme ID.
  */
  function getMemeData (uint256 _tokenId) external view 
  returns (address _owner, uint256 _price, uint256 _nextPrice, address _creator) 
  {
    Meme memory meme = memeData[_tokenId];
    return (meme.owner, meme.price, getNextPrice(meme.price), meme.creator);
  }

  /**
  * @dev Check the creator balance of a certain address.
  * @param _owner The address to check the balance of.
  */
  function checkBalance(address _owner) external view returns (uint256) {
    return creatorBalances[_owner];
  }

  /**
  * @dev Determines if token exists by checking it&#39;s price
  * @param _tokenId uint256 ID of token
  */
  function tokenExists (uint256 _tokenId) public view returns (bool _exists) {
    return memeData[_tokenId].price > 0;
  }
  
/** ***************************** Only Admin ******************************* **/
  
  /**
   * @dev Withdraw dev&#39;s cut
   * @param _devAmount The amount to withdraw from developer cut.
   * @param _submissionAmount The amount to withdraw from submission pool.
  */
  function withdraw(uint256 _devAmount, uint256 _submissionAmount) public onlyAdmin() {
    if (_devAmount == 0) { 
      _devAmount = developerCut; 
    }
    if (_submissionAmount == 0) {
      _submissionAmount = submissionPool;
    }
    developerCut = developerCut.sub(_devAmount);
    submissionPool = submissionPool.sub(_submissionAmount);
    owner.transfer(_devAmount + _submissionAmount);
    endingBalance = address(this).balance;
  }

  /**
   * @dev Admin may refund a submission to a user.
   * @param _refundee The address to refund.
   * @param _amount The amount of wei to refund.
  */
  function refundSubmission(address _refundee, uint256 _amount) external onlyAdmin() {
    submissionPool = submissionPool.sub(_amount);
    _refundee.transfer(_amount);
    endingBalance = address(this).balance;
  }
  
  /**
   * @dev Refund a submission by a specific tokenId.
   * @param _tokenId The unique Id of the token to be refunded at current submission price.
  */
  function refundByToken(uint256 _tokenId) external onlyAdmin() {
    submissionPool = submissionPool.sub(submissionPrice);
    memeData[_tokenId].creator.transfer(submissionPrice);
    endingBalance = address(this).balance;
  }

  /**
   * @dev Change how much it costs to submit a meme.
   * @param _newPrice The new price of submission.
  */
  function changeSubmissionPrice(uint256 _newPrice) external onlyAdmin() {
    submissionPrice = _newPrice;
  }


/** ***************************** Modifiers ******************************** **/

  /**
  * @dev Guarantees msg.sender is owner of the given token
  * @param _tokenId uint256 ID of the token to validate its ownership belongs to msg.sender
  */
  modifier onlyOwnerOf(uint256 _tokenId) {
    require(ownerOf(_tokenId) == msg.sender);
    _;
  }

/** ******************************* ERC721 ********************************* **/

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
      emit Approval(owner, _to, _tokenId);
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
  function clearApprovalAndTransfer(address _from, address _to, uint256 _tokenId) internal {
    require(_to != address(0));
    require(_to != ownerOf(_tokenId));
    require(ownerOf(_tokenId) == _from);

    clearApproval(_from, _tokenId);
    removeToken(_from, _tokenId);
    addToken(_to, _tokenId);
    emit Transfer(_from, _to, _tokenId);
  }

  /**
  * @dev Internal function to clear current approval of a given token ID
  * @param _tokenId uint256 ID of the token to be transferred
  */
  function clearApproval(address _owner, uint256 _tokenId) private {
    require(ownerOf(_tokenId) == _owner);
    tokenApprovals[_tokenId] = 0;
    emit Approval(_owner, 0, _tokenId);
  }


    /**
  * @dev Mint token function
  * @param _to The address that will own the minted token
  * @param _tokenId uint256 ID of the token to be minted by the msg.sender
  */
  function _mint(address _to, uint256 _tokenId) internal {
    addToken(_to, _tokenId);
    emit Transfer(0x0, _to, _tokenId);
  }

  /**
  * @dev Internal function to add a token ID to the list of a given address
  * @param _to address representing the new owner of the given token ID
  * @param _tokenId uint256 ID of the token to be added to the tokens list of the given address
  */
  function addToken(address _to, uint256 _tokenId) private {
    require(tokenOwner[_tokenId] == address(0));
    tokenOwner[_tokenId] = _to;
    memeData[_tokenId].owner = _to;
    
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
    return "Economeme Meme";
  }

  function symbol() public pure returns (string _symbol) {
    return "ECME";
  }

}