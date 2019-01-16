pragma solidity ^0.4.24;

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
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

// File: contracts/v2/SimpleArtistContractV2.sol

/**
 * Interface signature for the required methods needed for calling the Interface token
 */
contract IInterfaceToken {
  function exists(uint256 _tokenId) public view returns (bool);

  function hasTokens(address _owner) public view returns (bool);

  function firstToken(address _owner) public view returns (uint256 _tokenId);

  function blockhashOf(uint256 _tokenId) public view returns (bytes32 hash);
}

/**
* @title SimpleArtistContract V2
*/
contract SimpleArtistContractV2 {

  using SafeMath for uint256;

  uint256 constant internal MAX_UINT = ~uint256(0);

  event Purchased(address indexed _funder, uint256 indexed _tokenId, uint256 _blocksPurchased, uint256 _totalValue);
  event PurchaseBlock(address indexed _funder, uint256 indexed _tokenId, bytes32 _blockhash, uint256 _block);

  modifier onlyValidAmounts() {
    require(msg.value >= 0);

    // Min price
    require(msg.value >= pricePerBlockInWei.mul(minBlockPurchaseInOneGo));

    // max price
    require(msg.value <= pricePerBlockInWei.mul(maxBlockPurchaseInOneGo));
    _;
  }

  /**
   * @dev Throws if called by any account other than the artist.
   */
  modifier onlyArtist() {
    require(msg.sender == artist, "Only callable by the artist");
    _;
  }

  /**
   * @dev Throws if the contract is fixed
   */
  modifier onlyWhenNotFixed() {
    require(!fixedContract, "Contract is locked");
    _;
  }

  address public artist;

  IInterfaceToken public token;

  uint256 public pricePerBlockInWei;
  uint256 public maxBlockPurchaseInOneGo;
  uint256 public minBlockPurchaseInOneGo;
  bool public onlyShowPurchased = false;

  // Foundation split
  address public foundationAddress = 0x2b54605eF16c4da53E32eC20b7F170389350E9F1;
  uint256 public foundationPercentage = 5; // 5% to foundation

  // Optional 3rd party split
  address public optionalSplitAddress;
  uint256 public optionalSplitPercentage;

  mapping(uint256 => uint256) internal blocknumberToTokenId;
  mapping(uint256 => uint256[]) internal tokenIdToPurchasedBlocknumbers;

  // When true - prevents the same token being used more than once
  bool public preventDoublePurchases = false;

  // Allows for a max number of invocations of this contract, equivalent to rarity i.e. 1 or 1000 in an edition
  uint256 public maxInvocations = MAX_UINT;

  // When total size of list equals the max allowed invocations - no further token interactions with this contract are allowed
  uint256[] public tokenInvocations;

  // Can hold the checksum of the corresponding generative script
  bytes32 public applicationChecksum;

  uint256 public lastPurchasedBlock = 0;

  // If set to true - some configuration options are not able to be changed
  bool public fixedContract = false;

  /**
   * @dev Constructor
   *
   * @param _token IInterfaceToken - the address of the TOKN
   * @param _pricePerBlockInWei uint256 - the purchase price per block
   * @param _minBlockPurchaseInOneGo uint256 - the minimum number of blocks allowed to purchase at once
   * @param _maxBlockPurchaseInOneGo uint256 - the maximum number of blocks allowed to purchase at once
   * @param _artist address - the artists who can control various settings on this contract
   * @param _maxInvocations bool - the maximum number of invocations allowed
   * @param _applicationChecksum bytes32 - the script sha256 checksum
   * @param _preventDoublePurchases bool - if set to true, prevents the same token from being used twice
   * @param _fixedContract bool - if set to true, application checksum and max invocations are not editable after creation
   */
  constructor(
    IInterfaceToken _token,
    uint256 _pricePerBlockInWei,
    uint256 _minBlockPurchaseInOneGo,
    uint256 _maxBlockPurchaseInOneGo,
    address _artist,
    uint256 _maxInvocations,
    bytes32 _applicationChecksum,
    bool _preventDoublePurchases,
    bool _fixedContract
  ) public {
    require(_artist != address(0));

    artist = _artist;
    token = _token;

    pricePerBlockInWei = _pricePerBlockInWei;
    minBlockPurchaseInOneGo = _minBlockPurchaseInOneGo;
    maxBlockPurchaseInOneGo = _maxBlockPurchaseInOneGo;

    // Only set max invocations if found, default to MAX_INT if not
    if (_maxInvocations != 0) {
      maxInvocations = _maxInvocations;
    }

    preventDoublePurchases = _preventDoublePurchases;
    applicationChecksum = _applicationChecksum;
    fixedContract = _fixedContract;

    // set to current block mined in
    lastPurchasedBlock = block.number;
  }

  /**
  * @dev allows payment direct to contract - if no token will store value on contract
  */
  function() public payable {
    if (token.hasTokens(msg.sender)) {
      purchase(token.firstToken(msg.sender));
    }
    else {
      splitFunds();
    }
  }

  /**
   * @dev purchase blocks with your Token ID to be displayed for a specific amount of blocks
   * @param _tokenId the InterfaceToken token ID
   */
  function purchase(uint256 _tokenId) public payable onlyValidAmounts {
    require(token.exists(_tokenId));

    // If we are preventing double purchases, then check the token has not been used before
    if (preventDoublePurchases && tokenAlreadyUsed(_tokenId)) {
      revert("Cant buy any more blocks - token already used");
    }

    // We check to see if the Node has exceeded max available invocations
    if (exceedsMaxInvocations()) {
      revert("Contract reach max invocations");
    }

    // determine how many blocks purchased
    uint256 blocksToPurchased = msg.value / pricePerBlockInWei;

    // Start purchase from next block the current block is being mined
    uint256 nextBlockToPurchase = block.number + 1;

    // If next block is behind the next block to purchase, set next block to the last block
    if (nextBlockToPurchase < lastPurchasedBlock) {
      // reducing wasted loops to find a viable block to purchase
      nextBlockToPurchase = lastPurchasedBlock;
    }

    uint8 purchased = 0;
    while (purchased < blocksToPurchased) {

      if (tokenIdOf(nextBlockToPurchase) == 0) {
        purchaseBlock(nextBlockToPurchase, _tokenId);
        purchased++;
      }

      // move next block on to find another free space
      nextBlockToPurchase = nextBlockToPurchase + 1;
    }

    // update last block once purchased
    lastPurchasedBlock = nextBlockToPurchase;

    // payments
    splitFunds();

    // Add the invocation count
    tokenInvocations.push(_tokenId);

    emit Purchased(msg.sender, _tokenId, blocksToPurchased, msg.value);
  }

  function purchaseBlock(uint256 _blocknumber, uint256 _tokenId) internal {
    // keep track of the token associated to the block
    blocknumberToTokenId[_blocknumber] = _tokenId;

    // Keep track of the blocks purchased by the token
    tokenIdToPurchasedBlocknumbers[_tokenId].push(_blocknumber);

    // Emit event for logging/tracking
    emit PurchaseBlock(msg.sender, _tokenId, getPurchasedBlockhash(_blocknumber), _blocknumber);
  }

  function splitFunds() internal {
    // 5% to foundation
    uint foundationShare = msg.value / 100 * foundationPercentage;
    foundationAddress.transfer(foundationShare);

    // Optional X% to 3rd party
    uint256 optionalShare;
    if (optionalSplitAddress != address(0) && optionalSplitPercentage > 0) {
      optionalShare = msg.value.div(100).mul(optionalSplitPercentage);
      optionalSplitAddress.transfer(optionalShare);
    }

    // artists sent the remaining value
    uint artistTotal = msg.value - foundationShare - optionalShare;
    artist.transfer(artistTotal);
  }

  /**
   * @dev Checks to see if the token has already purchased blocks
   */
  function tokenAlreadyUsed(uint256 _tokenId) public view returns (bool) {
    return tokenIdToPurchasedBlocknumbers[_tokenId].length > 0;
  }

  /**
   * @dev Checks to see if the maximum number of purchases have been made
   */
  function exceedsMaxInvocations() public view returns (bool) {
    return tokenInvocations.length >= maxInvocations;
  }

  /**
   * @dev Returns the total number invocations recorded for this contract
   */
  function totalInvocations() public view returns (uint256) {
    return tokenInvocations.length;
  }

  /**
   * @dev Returns the total number invocations recorded for this contract
   */
  function getTokenInvocations() public view returns (uint256[] _tokenIds) {
    return tokenInvocations;
  }

  /**
   * @dev Returns the allowed number of interactions left on the contract
   */
  function remainingInvocations() public view returns (uint256) {
    return maxInvocations - tokenInvocations.length;
  }

  /**
   * @dev Attempts to work out the next block which will be funded
   */
  function nextPurchasableBlocknumber() public view returns (uint256 _nextFundedBlock) {
    if (block.number < lastPurchasedBlock) {
      return lastPurchasedBlock;
    }
    return block.number + 1;
  }

  /**
   * @dev Returns the blocks which the provided token has purchased
   */
  function blocknumbersOf(uint256 _tokenId) public view returns (uint256[] _blocks) {
    return tokenIdToPurchasedBlocknumbers[_tokenId];
  }

  /**
   * @dev Return token ID for the provided block or 0 when not found
   */
  function tokenIdOf(uint256 _blockNumber) public view returns (uint256 _tokenId) {
    return blocknumberToTokenId[_blockNumber];
  }

  /**
    * @dev Get the block hash the given block number
    * @param _blocknumber the block to generate hash for
    */
  function getPurchasedBlockhash(uint256 _blocknumber) public view returns (bytes32 _tokenHash) {
    // Do not allow this to be called for hashes which aren&#39;t purchased
    require(tokenIdOf(_blocknumber) != 0);

    uint256 tokenId = tokenIdOf(_blocknumber);
    return token.blockhashOf(tokenId);
  }

  /**
   * @dev Generates default block hash behaviour - helps with tests
   */
  function nativeBlockhash(uint256 _blocknumber) public view returns (bytes32 _tokenHash) {
    return blockhash(_blocknumber);
  }

  /**
   * @dev Generates a unique token hash for the token
   * @return the hash and its associated block
   */
  function nextHash() public view returns (bytes32 _tokenHash, uint256 _nextBlocknumber) {
    uint256 nextBlocknumber = block.number - 1;

    // if current block number has been allocated then use it
    if (tokenIdOf(nextBlocknumber) != 0) {
      return (getPurchasedBlockhash(nextBlocknumber), nextBlocknumber);
    }

    if (onlyShowPurchased) {
      return (0x0, nextBlocknumber);
    }

    // if no one own the current blockhash return current
    return (nativeBlockhash(nextBlocknumber), nextBlocknumber);
  }

  /**
   * @dev Returns blocknumber - helps with tests
   */
  function blocknumber() public view returns (uint256 _blockNumber) {
    return block.number;
  }

  /**
   * @dev Toggles the contract between allowing and preventing double purchases
   */
  function togglePreventDoublePurchases() external onlyArtist onlyWhenNotFixed {
    preventDoublePurchases = !preventDoublePurchases;
  }

  /**
   * @dev Can control the max invocations allowed
   */
  function setMaxInvocations(uint256 _maxInvocations) external onlyArtist onlyWhenNotFixed {
    require(_maxInvocations > 0, "Cannot set max invocations to less then 1");
    maxInvocations = _maxInvocations;
  }

  /**
   * @dev Sets the application checksum, assume the bytes32 is a sha256 has of the application
   */
  function setApplicationChecksum(bytes32 _applicationChecksum) external onlyArtist onlyWhenNotFixed {
    applicationChecksum = _applicationChecksum;
  }

  /**
   * @dev Ability to define optional fee split and percentage
   */
  function setOptionalFeeSplit(address _optionalSplitAddress, uint256 _optionalSplitPercentage) external onlyArtist {
    require(_optionalSplitAddress != address(0), "Cannot set blank address");
    require(_optionalSplitPercentage > 0, "Cannot set a zero fee split");
    require(_optionalSplitPercentage.add(foundationPercentage) <= 100, "Optional split plus founders fee cannot be more than 100%");

    optionalSplitAddress = _optionalSplitAddress;
    optionalSplitPercentage = _optionalSplitPercentage;
  }

  /**
   * @dev Utility function for updating price per block
   * @param _priceInWei the price in wei
   */
  function setPricePerBlockInWei(uint256 _priceInWei) external onlyArtist {
    pricePerBlockInWei = _priceInWei;
  }

  /**
   * @dev Utility function for updating max blocks
   * @param _maxBlockPurchaseInOneGo max blocks per purchase
   */
  function setMaxBlockPurchaseInOneGo(uint256 _maxBlockPurchaseInOneGo) external onlyArtist {
    maxBlockPurchaseInOneGo = _maxBlockPurchaseInOneGo;
  }

  /**
   * @dev Utility function for updating min blocks
   * @param _minBlockPurchaseInOneGo min blocks per purchase
   */
  function setMinBlockPurchaseInOneGo(uint256 _minBlockPurchaseInOneGo) external onlyArtist {
    minBlockPurchaseInOneGo = _minBlockPurchaseInOneGo;
  }

  /**
 * @dev Utility function for only show purchased
 * @param _onlyShowPurchased flag for only showing purchased hashes
 */
  function setOnlyShowPurchased(bool _onlyShowPurchased) external onlyArtist {
    onlyShowPurchased = _onlyShowPurchased;
  }
}