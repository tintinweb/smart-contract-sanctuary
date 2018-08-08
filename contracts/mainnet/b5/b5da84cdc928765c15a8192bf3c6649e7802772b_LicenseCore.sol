pragma solidity ^0.4.13;

interface ERC721Enumerable /* is ERC721 */ {
    /// @notice Count NFTs tracked by this contract
    /// @return A count of valid NFTs tracked by this contract, where each one of
    ///  them has an assigned and queryable owner not equal to the zero address
    function totalSupply() public view returns (uint256);

    /// @notice Enumerate valid NFTs
    /// @dev Throws if `_index` >= `totalSupply()`.
    /// @param _index A counter less than `totalSupply()`
    /// @return The token identifier for the `_index`th NFT,
    ///  (sort order not specified)
    function tokenByIndex(uint256 _index) external view returns (uint256);

    /// @notice Enumerate NFTs assigned to an owner
    /// @dev Throws if `_index` >= `balanceOf(_owner)` or if
    ///  `_owner` is the zero address, representing invalid NFTs.
    /// @param _owner An address where we are interested in NFTs owned by them
    /// @param _index A counter less than `balanceOf(_owner)`
    /// @return The token identifier for the `_index`th NFT assigned to `_owner`,
    ///   (sort order not specified)
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256 _tokenId);
}

interface ERC721Metadata /* is ERC721 */ {
    /// @notice A descriptive name for a collection of NFTs in this contract
    function name() external pure returns (string _name);

    /// @notice An abbreviated name for NFTs in this contract
    function symbol() external pure returns (string _symbol);

    /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
    /// @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
    ///  3986. The URI may point to a JSON file that conforms to the "ERC721
    ///  Metadata JSON Schema".
    function tokenURI(uint256 _tokenId) external view returns (string);
}

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
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    require(_newOwner != address(0));
    OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }

}

interface ERC721TokenReceiver {
    /// @notice Handle the receipt of an NFT
    /// @dev The ERC721 smart contract calls this function on the recipient
    ///  after a `transfer`. This function MAY throw to revert and reject the
    ///  transfer. This function MUST use 50,000 gas or less. Return of other
    ///  than the magic value MUST result in the transaction being reverted.
    ///  Note: the contract address is always the message sender.
    /// @param _from The sending address
    /// @param _tokenId The NFT identifier which is being transfered
    /// @param _data Additional data with no specified format
    /// @return `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`
    ///  unless throwing
	function onERC721Received(address _from, uint256 _tokenId, bytes _data) external returns(bytes4);
}

library Math {
  function max64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }
}

contract LicenseAccessControl {
  /**
   * @notice ContractUpgrade is the event that will be emitted if we set a new contract address
   */
  event ContractUpgrade(address newContract);
  event Paused();
  event Unpaused();

  /**
   * @notice CEO&#39;s address FOOBAR
   */
  address public ceoAddress;

  /**
   * @notice CFO&#39;s address
   */
  address public cfoAddress;

  /**
   * @notice COO&#39;s address
   */
  address public cooAddress;

  /**
   * @notice withdrawal address
   */
  address public withdrawalAddress;

  bool public paused = false;

  /**
   * @dev Modifier to make a function only callable by the CEO
   */
  modifier onlyCEO() {
    require(msg.sender == ceoAddress);
    _;
  }

  /**
   * @dev Modifier to make a function only callable by the CFO
   */
  modifier onlyCFO() {
    require(msg.sender == cfoAddress);
    _;
  }

  /**
   * @dev Modifier to make a function only callable by the COO
   */
  modifier onlyCOO() {
    require(msg.sender == cooAddress);
    _;
  }

  /**
   * @dev Modifier to make a function only callable by C-level execs
   */
  modifier onlyCLevel() {
    require(
      msg.sender == cooAddress ||
      msg.sender == ceoAddress ||
      msg.sender == cfoAddress
    );
    _;
  }

  /**
   * @dev Modifier to make a function only callable by CEO or CFO
   */
  modifier onlyCEOOrCFO() {
    require(
      msg.sender == cfoAddress ||
      msg.sender == ceoAddress
    );
    _;
  }

  /**
   * @dev Modifier to make a function only callable by CEO or COO
   */
  modifier onlyCEOOrCOO() {
    require(
      msg.sender == cooAddress ||
      msg.sender == ceoAddress
    );
    _;
  }

  /**
   * @notice Sets a new CEO
   * @param _newCEO - the address of the new CEO
   */
  function setCEO(address _newCEO) external onlyCEO {
    require(_newCEO != address(0));
    ceoAddress = _newCEO;
  }

  /**
   * @notice Sets a new CFO
   * @param _newCFO - the address of the new CFO
   */
  function setCFO(address _newCFO) external onlyCEO {
    require(_newCFO != address(0));
    cfoAddress = _newCFO;
  }

  /**
   * @notice Sets a new COO
   * @param _newCOO - the address of the new COO
   */
  function setCOO(address _newCOO) external onlyCEO {
    require(_newCOO != address(0));
    cooAddress = _newCOO;
  }

  /**
   * @notice Sets a new withdrawalAddress
   * @param _newWithdrawalAddress - the address where we&#39;ll send the funds
   */
  function setWithdrawalAddress(address _newWithdrawalAddress) external onlyCEO {
    require(_newWithdrawalAddress != address(0));
    withdrawalAddress = _newWithdrawalAddress;
  }

  /**
   * @notice Withdraw the balance to the withdrawalAddress
   * @dev We set a withdrawal address seperate from the CFO because this allows us to withdraw to a cold wallet.
   */
  function withdrawBalance() external onlyCEOOrCFO {
    require(withdrawalAddress != address(0));
    withdrawalAddress.transfer(this.balance);
  }

  /** Pausable functionality adapted from OpenZeppelin **/

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
   * @notice called by any C-level to pause, triggers stopped state
   */
  function pause() public onlyCLevel whenNotPaused {
    paused = true;
    Paused();
  }

  /**
   * @notice called by the CEO to unpause, returns to normal state
   */
  function unpause() public onlyCEO whenPaused {
    paused = false;
    Unpaused();
  }
}

contract LicenseBase is LicenseAccessControl {
  /**
   * @notice Issued is emitted when a new license is issued
   */
  event LicenseIssued(
    address indexed owner,
    address indexed purchaser,
    uint256 licenseId,
    uint256 productId,
    uint256 attributes,
    uint256 issuedTime,
    uint256 expirationTime,
    address affiliate
  );

  event LicenseRenewal(
    address indexed owner,
    address indexed purchaser,
    uint256 licenseId,
    uint256 productId,
    uint256 expirationTime
  );

  struct License {
    uint256 productId;
    uint256 attributes;
    uint256 issuedTime;
    uint256 expirationTime;
    address affiliate;
  }

  /**
   * @notice All licenses in existence.
   * @dev The ID of each license is an index in this array.
   */
  License[] licenses;

  /** internal **/
  function _isValidLicense(uint256 _licenseId) internal view returns (bool) {
    return licenseProductId(_licenseId) != 0;
  }

  /** anyone **/

  /**
   * @notice Get a license&#39;s productId
   * @param _licenseId the license id
   */
  function licenseProductId(uint256 _licenseId) public view returns (uint256) {
    return licenses[_licenseId].productId;
  }

  /**
   * @notice Get a license&#39;s attributes
   * @param _licenseId the license id
   */
  function licenseAttributes(uint256 _licenseId) public view returns (uint256) {
    return licenses[_licenseId].attributes;
  }

  /**
   * @notice Get a license&#39;s issueTime
   * @param _licenseId the license id
   */
  function licenseIssuedTime(uint256 _licenseId) public view returns (uint256) {
    return licenses[_licenseId].issuedTime;
  }

  /**
   * @notice Get a license&#39;s issueTime
   * @param _licenseId the license id
   */
  function licenseExpirationTime(uint256 _licenseId) public view returns (uint256) {
    return licenses[_licenseId].expirationTime;
  }

  /**
   * @notice Get a the affiliate credited for the sale of this license
   * @param _licenseId the license id
   */
  function licenseAffiliate(uint256 _licenseId) public view returns (address) {
    return licenses[_licenseId].affiliate;
  }

  /**
   * @notice Get a license&#39;s info
   * @param _licenseId the license id
   */
  function licenseInfo(uint256 _licenseId)
    public view returns (uint256, uint256, uint256, uint256, address)
  {
    return (
      licenseProductId(_licenseId),
      licenseAttributes(_licenseId),
      licenseIssuedTime(_licenseId),
      licenseExpirationTime(_licenseId),
      licenseAffiliate(_licenseId)
    );
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

contract AffiliateProgram is Pausable {
  using SafeMath for uint256;

  event AffiliateCredit(
    // The address of the affiliate
    address affiliate,
    // The store&#39;s ID of what was sold (e.g. a tokenId)
    uint256 productId,
    // The amount owed this affiliate in this sale
    uint256 amount
  );

  event Withdraw(address affiliate, address to, uint256 amount);
  event Whitelisted(address affiliate, uint256 amount);
  event RateChanged(uint256 rate, uint256 amount);

  // @notice A mapping from affiliate address to their balance
  mapping (address => uint256) public balances;

  // @notice A mapping from affiliate address to the time of last deposit
  mapping (address => uint256) public lastDepositTimes;

  // @notice The last deposit globally
  uint256 public lastDepositTime;

  // @notice The maximum rate for any affiliate
  // @dev The hard-coded maximum affiliate rate (in basis points)
  // All rates are measured in basis points (1/100 of a percent)
  // Values 0-10,000 map to 0%-100%
  uint256 private constant hardCodedMaximumRate = 5000;

  // @notice The commission exiration time
  // @dev Affiliate commissions expire if they are unclaimed after this amount of time
  uint256 private constant commissionExpiryTime = 30 days;

  // @notice The baseline affiliate rate (in basis points) for non-whitelisted referrals
  uint256 public baselineRate = 0;

  // @notice A mapping from whitelisted referrals to their individual rates
  mapping (address => uint256) public whitelistRates;

  // @notice The maximum rate for any affiliate
  // @dev overrides individual rates. This can be used to clip the rate used in bulk, if necessary
  uint256 public maximumRate = 5000;

  // @notice The address of the store selling products
  address public storeAddress;

  // @notice The contract is retired
  // @dev If we decide to retire this program, this value will be set to true
  // and then the contract cannot be unpaused
  bool public retired = false;


  /**
   * @dev Modifier to make a function only callable by the store or the owner
   */
  modifier onlyStoreOrOwner() {
    require(
      msg.sender == storeAddress ||
      msg.sender == owner);
    _;
  }

  /**
   * @dev AffiliateProgram constructor - keeps the address of it&#39;s parent store
   * and pauses the contract
   */
  function AffiliateProgram(address _storeAddress) public {
    require(_storeAddress != address(0));
    storeAddress = _storeAddress;
    paused = true;
  }

  /**
   * @notice Exposes that this contract thinks it is an AffiliateProgram
   */
  function isAffiliateProgram() public pure returns (bool) {
    return true;
  }

  /**
   * @notice returns the commission rate for a sale
   *
   * @dev rateFor returns the rate which should be used to calculate the comission
   *  for this affiliate/sale combination, in basis points (1/100th of a percent).
   *
   *  We may want to completely blacklist a particular address (e.g. a known bad actor affilite).
   *  To that end, if the whitelistRate is exactly 1bp, we use that as a signal for blacklisting
   *  and return a rate of zero. The upside is that we can completely turn off
   *  sending transactions to a particular address when this is needed. The
   *  downside is that you can&#39;t issued 1/100th of a percent commission.
   *  However, since this is such a small amount its an acceptable tradeoff.
   *
   *  This implementation does not use the _productId, _pruchaseId,
   *  _purchaseAmount, but we include them here as part of the protocol, because
   *  they could be useful in more advanced affiliate programs.
   *
   * @param _affiliate - the address of the affiliate to check for
   */
  function rateFor(
    address _affiliate,
    uint256 /*_productId*/,
    uint256 /*_purchaseId*/,
    uint256 /*_purchaseAmount*/)
    public
    view
    returns (uint256)
  {
    uint256 whitelistedRate = whitelistRates[_affiliate];
    if(whitelistedRate > 0) {
      // use 1 bp as a blacklist signal
      if(whitelistedRate == 1) {
        return 0;
      } else {
        return Math.min256(whitelistedRate, maximumRate);
      }
    } else {
      return Math.min256(baselineRate, maximumRate);
    }
  }

  /**
   * @notice cutFor returns the affiliate cut for a sale
   * @dev cutFor returns the cut (amount in wei) to give in comission to the affiliate
   *
   * @param _affiliate - the address of the affiliate to check for
   * @param _productId - the productId in the sale
   * @param _purchaseId - the purchaseId in the sale
   * @param _purchaseAmount - the purchaseAmount
   */
  function cutFor(
    address _affiliate,
    uint256 _productId,
    uint256 _purchaseId,
    uint256 _purchaseAmount)
    public
    view
    returns (uint256)
  {
    uint256 rate = rateFor(
      _affiliate,
      _productId,
      _purchaseId,
      _purchaseAmount);
    require(rate <= hardCodedMaximumRate);
    return (_purchaseAmount.mul(rate)).div(10000);
  }

  /**
   * @notice credit an affiliate for a purchase
   * @dev credit accepts eth and credits the affiliate&#39;s balance for the amount
   *
   * @param _affiliate - the address of the affiliate to credit
   * @param _purchaseId - the purchaseId of the sale
   */
  function credit(
    address _affiliate,
    uint256 _purchaseId)
    public
    onlyStoreOrOwner
    whenNotPaused
    payable
  {
    require(msg.value > 0);
    require(_affiliate != address(0));
    balances[_affiliate] += msg.value;
    lastDepositTimes[_affiliate] = now; // solium-disable-line security/no-block-members
    lastDepositTime = now; // solium-disable-line security/no-block-members
    AffiliateCredit(_affiliate, _purchaseId, msg.value);
  }

  /**
   * @dev _performWithdraw performs a withdrawal from address _from and
   * transfers it to _to. This can be different because we allow the owner
   * to withdraw unclaimed funds after a period of time.
   *
   * @param _from - the address to subtract balance from
   * @param _to - the address to transfer ETH to
   */
  function _performWithdraw(address _from, address _to) private {
    require(balances[_from] > 0);
    uint256 balanceValue = balances[_from];
    balances[_from] = 0;
    _to.transfer(balanceValue);
    Withdraw(_from, _to, balanceValue);
  }

  /**
   * @notice withdraw
   * @dev withdraw the msg.sender&#39;s balance
   */
  function withdraw() public whenNotPaused {
    _performWithdraw(msg.sender, msg.sender);
  }

  /**
   * @notice withdraw from a specific account
   * @dev withdrawFrom allows the owner to withdraw an affiliate&#39;s unclaimed
   * ETH, after the alotted time.
   *
   * This function can be called even if the contract is paused
   *
   * @param _affiliate - the address of the affiliate
   * @param _to - the address to send ETH to
   */
  function withdrawFrom(address _affiliate, address _to) onlyOwner public {
    // solium-disable-next-line security/no-block-members
    require(now > lastDepositTimes[_affiliate].add(commissionExpiryTime));
    _performWithdraw(_affiliate, _to);
  }

  /**
   * @notice retire the contract (dangerous)
   * @dev retire - withdraws the entire balance and marks the contract as retired, which
   * prevents unpausing.
   *
   * If no new comissions have been deposited for the alotted time,
   * then the owner may pause the program and retire this contract.
   * This may only be performed once as the contract cannot be unpaused.
   *
   * We do this as an alternative to selfdestruct, because certain operations
   * can still be performed after the contract has been selfdestructed, such as
   * the owner withdrawing ETH accidentally sent here.
   */
  function retire(address _to) onlyOwner whenPaused public {
    // solium-disable-next-line security/no-block-members
    require(now > lastDepositTime.add(commissionExpiryTime));
    _to.transfer(this.balance);
    retired = true;
  }

  /**
   * @notice whitelist an affiliate address
   * @dev whitelist - white listed affiliates can receive a different
   *   rate than the general public (whitelisted accounts would generally get a
   *   better rate).
   * @param _affiliate - the affiliate address to whitelist
   * @param _rate - the rate, in basis-points (1/100th of a percent) to give this affiliate in each sale. NOTE: a rate of exactly 1 is the signal to blacklist this affiliate. That is, a rate of 1 will set the commission to 0.
   */
  function whitelist(address _affiliate, uint256 _rate) onlyOwner public {
    require(_rate <= hardCodedMaximumRate);
    whitelistRates[_affiliate] = _rate;
    Whitelisted(_affiliate, _rate);
  }

  /**
   * @notice set the rate for non-whitelisted affiliates
   * @dev setBaselineRate - sets the baseline rate for any affiliate that is not whitelisted
   * @param _newRate - the rate, in bp (1/100th of a percent) to give any non-whitelisted affiliate. Set to zero to "turn off"
   */
  function setBaselineRate(uint256 _newRate) onlyOwner public {
    require(_newRate <= hardCodedMaximumRate);
    baselineRate = _newRate;
    RateChanged(0, _newRate);
  }

  /**
   * @notice set the maximum rate for any affiliate
   * @dev setMaximumRate - Set the maximum rate for any affiliate, including whitelists. That is, this overrides individual rates.
   * @param _newRate - the rate, in bp (1/100th of a percent)
   */
  function setMaximumRate(uint256 _newRate) onlyOwner public {
    require(_newRate <= hardCodedMaximumRate);
    maximumRate = _newRate;
    RateChanged(1, _newRate);
  }

  /**
   * @notice unpause the contract
   * @dev called by the owner to unpause, returns to normal state. Will not
   * unpause if the contract is retired.
   */
  function unpause() onlyOwner whenPaused public {
    require(!retired);
    paused = false;
    Unpause();
  }

}

contract ERC721 {
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

  function balanceOf(address _owner) public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) public;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;
  function transfer(address _to, uint256 _tokenId) external;
  function transferFrom(address _from, address _to, uint256 _tokenId) public;
  function approve(address _to, uint256 _tokenId) external;
  function setApprovalForAll(address _to, bool _approved) external;
  function getApproved(uint256 _tokenId) public view returns (address);
  function isApprovedForAll(address _owner, address _operator) public view returns (bool);
}

contract LicenseInventory is LicenseBase {
  using SafeMath for uint256;

  event ProductCreated(
    uint256 id,
    uint256 price,
    uint256 available,
    uint256 supply,
    uint256 interval,
    bool renewable
  );
  event ProductInventoryAdjusted(uint256 productId, uint256 available);
  event ProductPriceChanged(uint256 productId, uint256 price);
  event ProductRenewableChanged(uint256 productId, bool renewable);


  /**
   * @notice Product defines a product
   * * renewable: There may come a time when we which to disable the ability to renew a subscription. For example, a plan we no longer wish to support. Obviously care needs to be taken with how we communicate this to customers, but contract-wise, we want to support the ability to discontinue renewal of certain plans.
  */
  struct Product {
    uint256 id;
    uint256 price;
    uint256 available;
    uint256 supply;
    uint256 sold;
    uint256 interval;
    bool renewable;
  }

  // @notice All products in existence
  uint256[] public allProductIds;

  // @notice A mapping from product ids to Products
  mapping (uint256 => Product) public products;

  /*** internal ***/

  /**
   * @notice _productExists checks to see if a product exists
   */
  function _productExists(uint256 _productId) internal view returns (bool) {
    return products[_productId].id != 0;
  }

  function _productDoesNotExist(uint256 _productId) internal view returns (bool) {
    return products[_productId].id == 0;
  }

  function _createProduct(
    uint256 _productId,
    uint256 _initialPrice,
    uint256 _initialInventoryQuantity,
    uint256 _supply,
    uint256 _interval)
    internal
  {
    require(_productDoesNotExist(_productId));
    require(_initialInventoryQuantity <= _supply);

    Product memory _product = Product({
      id: _productId,
      price: _initialPrice,
      available: _initialInventoryQuantity,
      supply: _supply,
      sold: 0,
      interval: _interval,
      renewable: _interval == 0 ? false : true
    });

    products[_productId] = _product;
    allProductIds.push(_productId);

    ProductCreated(
      _product.id,
      _product.price,
      _product.available,
      _product.supply,
      _product.interval,
      _product.renewable
      );
  }

  function _incrementInventory(
    uint256 _productId,
    uint256 _inventoryAdjustment)
    internal
  {
    require(_productExists(_productId));
    uint256 newInventoryLevel = products[_productId].available.add(_inventoryAdjustment);

    // A supply of "0" means "unlimited". Otherwise we need to ensure that we&#39;re not over-creating this product
    if(products[_productId].supply > 0) {
      // you have to take already sold into account
      require(products[_productId].sold.add(newInventoryLevel) <= products[_productId].supply);
    }

    products[_productId].available = newInventoryLevel;
  }

  function _decrementInventory(
    uint256 _productId,
    uint256 _inventoryAdjustment)
    internal
  {
    require(_productExists(_productId));
    uint256 newInventoryLevel = products[_productId].available.sub(_inventoryAdjustment);
    // unnecessary because we&#39;re using SafeMath and an unsigned int
    // require(newInventoryLevel >= 0);
    products[_productId].available = newInventoryLevel;
  }

  function _clearInventory(uint256 _productId) internal
  {
    require(_productExists(_productId));
    products[_productId].available = 0;
  }

  function _setPrice(uint256 _productId, uint256 _price) internal
  {
    require(_productExists(_productId));
    products[_productId].price = _price;
  }

  function _setRenewable(uint256 _productId, bool _isRenewable) internal
  {
    require(_productExists(_productId));
    products[_productId].renewable = _isRenewable;
  }

  function _purchaseOneUnitInStock(uint256 _productId) internal {
    require(_productExists(_productId));
    require(availableInventoryOf(_productId) > 0);

    // lower inventory
    _decrementInventory(_productId, 1);

    // record that one was sold
    products[_productId].sold = products[_productId].sold.add(1);
  }

  function _requireRenewableProduct(uint256 _productId) internal view {
    // productId must exist
    require(_productId != 0);
    // You can only renew a subscription product
    require(isSubscriptionProduct(_productId));
    // The product must currently be renewable
    require(renewableOf(_productId));
  }

  /*** public ***/

  /** executives-only **/

  /**
   * @notice createProduct creates a new product in the system
   * @param _productId - the id of the product to use (cannot be changed)
   * @param _initialPrice - the starting price (price can be changed)
   * @param _initialInventoryQuantity - the initial inventory (inventory can be changed)
   * @param _supply - the total supply - use `0` for "unlimited" (cannot be changed)
   */
  function createProduct(
    uint256 _productId,
    uint256 _initialPrice,
    uint256 _initialInventoryQuantity,
    uint256 _supply,
    uint256 _interval)
    external
    onlyCEOOrCOO
  {
    _createProduct(
      _productId,
      _initialPrice,
      _initialInventoryQuantity,
      _supply,
      _interval);
  }

  /**
   * @notice incrementInventory - increments the inventory of a product
   * @param _productId - the product id
   * @param _inventoryAdjustment - the amount to increment
   */
  function incrementInventory(
    uint256 _productId,
    uint256 _inventoryAdjustment)
    external
    onlyCLevel
  {
    _incrementInventory(_productId, _inventoryAdjustment);
    ProductInventoryAdjusted(_productId, availableInventoryOf(_productId));
  }

  /**
  * @notice decrementInventory removes inventory levels for a product
  * @param _productId - the product id
  * @param _inventoryAdjustment - the amount to decrement
  */
  function decrementInventory(
    uint256 _productId,
    uint256 _inventoryAdjustment)
    external
    onlyCLevel
  {
    _decrementInventory(_productId, _inventoryAdjustment);
    ProductInventoryAdjusted(_productId, availableInventoryOf(_productId));
  }

  /**
  * @notice clearInventory clears the inventory of a product.
  * @dev decrementInventory verifies inventory levels, whereas this method
  * simply sets the inventory to zero. This is useful, for example, if an
  * executive wants to take a product off the market quickly. There could be a
  * race condition with decrementInventory where a product is sold, which could
  * cause the admins decrement to fail (because it may try to decrement more
  * than available).
  *
  * @param _productId - the product id
  */
  function clearInventory(uint256 _productId)
    external
    onlyCLevel
  {
    _clearInventory(_productId);
    ProductInventoryAdjusted(_productId, availableInventoryOf(_productId));
  }

  /**
  * @notice setPrice - sets the price of a product
  * @param _productId - the product id
  * @param _price - the product price
  */
  function setPrice(uint256 _productId, uint256 _price)
    external
    onlyCLevel
  {
    _setPrice(_productId, _price);
    ProductPriceChanged(_productId, _price);
  }

  /**
  * @notice setRenewable - sets if a product is renewable
  * @param _productId - the product id
  * @param _newRenewable - the new renewable setting
  */
  function setRenewable(uint256 _productId, bool _newRenewable)
    external
    onlyCLevel
  {
    _setRenewable(_productId, _newRenewable);
    ProductRenewableChanged(_productId, _newRenewable);
  }

  /** anyone **/

  /**
  * @notice The price of a product
  * @param _productId - the product id
  */
  function priceOf(uint256 _productId) public view returns (uint256) {
    return products[_productId].price;
  }

  /**
  * @notice The available inventory of a product
  * @param _productId - the product id
  */
  function availableInventoryOf(uint256 _productId) public view returns (uint256) {
    return products[_productId].available;
  }

  /**
  * @notice The total supply of a product
  * @param _productId - the product id
  */
  function totalSupplyOf(uint256 _productId) public view returns (uint256) {
    return products[_productId].supply;
  }

  /**
  * @notice The total sold of a product
  * @param _productId - the product id
  */
  function totalSold(uint256 _productId) public view returns (uint256) {
    return products[_productId].sold;
  }

  /**
  * @notice The renewal interval of a product in seconds
  * @param _productId - the product id
  */
  function intervalOf(uint256 _productId) public view returns (uint256) {
    return products[_productId].interval;
  }

  /**
  * @notice Is this product renewable?
  * @param _productId - the product id
  */
  function renewableOf(uint256 _productId) public view returns (bool) {
    return products[_productId].renewable;
  }


  /**
  * @notice The product info for a product
  * @param _productId - the product id
  */
  function productInfo(uint256 _productId)
    public
    view
    returns (uint256, uint256, uint256, uint256, bool)
  {
    return (
      priceOf(_productId),
      availableInventoryOf(_productId),
      totalSupplyOf(_productId),
      intervalOf(_productId),
      renewableOf(_productId));
  }

  /**
  * @notice Get all product ids
  */
  function getAllProductIds() public view returns (uint256[]) {
    return allProductIds;
  }

  /**
   * @notice returns the total cost to renew a product for a number of cycles
   * @dev If a product is a subscription, the interval defines the period of
   * time, in seconds, users can subscribe for. E.g. 1 month or 1 year.
   * _numCycles is the number of these intervals we want to use in the
   * calculation of the price.
   *
   * We require that the end user send precisely the amount required (instead
   * of dealing with excess refunds). This method is public so that clients can
   * read the exact amount our contract expects to receive.
   *
   * @param _productId - the product we&#39;re calculating for
   * @param _numCycles - the number of cycles to calculate for
   */
  function costForProductCycles(uint256 _productId, uint256 _numCycles)
    public
    view
    returns (uint256)
  {
    return priceOf(_productId).mul(_numCycles);
  }

  /**
   * @notice returns if this product is a subscription or not
   * @dev Some products are subscriptions and others are not. An interval of 0
   * means the product is not a subscription
   * @param _productId - the product we&#39;re checking
   */
  function isSubscriptionProduct(uint256 _productId) public view returns (bool) {
    return intervalOf(_productId) > 0;
  }

}

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

interface ERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

contract LicenseOwnership is LicenseInventory, ERC721, ERC165, ERC721Metadata, ERC721Enumerable {
  using SafeMath for uint256;

  // Total amount of tokens
  uint256 private totalTokens;

  // Mapping from token ID to owner
  mapping (uint256 => address) private tokenOwner;

  // Mapping from token ID to approved address
  mapping (uint256 => address) private tokenApprovals;

  // Mapping from owner address to operator address to approval
  mapping (address => mapping (address => bool)) private operatorApprovals;

  // Mapping from owner to list of owned token IDs
  mapping (address => uint256[]) private ownedTokens;

  // Mapping from token ID to index of the owner tokens list
  mapping(uint256 => uint256) private ownedTokensIndex;

  /*** Constants ***/
  // Configure these for your own deployment
  string public constant NAME = "Dottabot";
  string public constant SYMBOL = "DOTTA";
  string public tokenMetadataBaseURI = "https://api.dottabot.com/";

  /**
   * @notice token&#39;s name
   */
  function name() external pure returns (string) {
    return NAME;
  }

  /**
   * @notice symbols&#39;s name
   */
  function symbol() external pure returns (string) {
    return SYMBOL;
  }

  function implementsERC721() external pure returns (bool) {
    return true;
  }

  function tokenURI(uint256 _tokenId)
    external
    view
    returns (string infoUrl)
  {
    return Strings.strConcat(
      tokenMetadataBaseURI,
      Strings.uint2str(_tokenId));
  }

  function supportsInterface(
    bytes4 interfaceID) // solium-disable-line dotta/underscore-function-arguments
    external view returns (bool)
  {
    return
      interfaceID == this.supportsInterface.selector || // ERC165
      interfaceID == 0x5b5e139f || // ERC721Metadata
      interfaceID == 0x6466353c || // ERC-721 on 3/7/2018
      interfaceID == 0x780e9d63; // ERC721Enumerable
  }

  function setTokenMetadataBaseURI(string _newBaseURI) external onlyCEOOrCOO {
    tokenMetadataBaseURI = _newBaseURI;
  }

  /**
  * @notice Guarantees msg.sender is owner of the given token
  * @param _tokenId uint256 ID of the token to validate its ownership belongs to msg.sender
  */
  modifier onlyOwnerOf(uint256 _tokenId) {
    require(ownerOf(_tokenId) == msg.sender);
    _;
  }

  /**
  * @notice Gets the total amount of tokens stored by the contract
  * @return uint256 representing the total amount of tokens
  */
  function totalSupply() public view returns (uint256) {
    return totalTokens;
  }

  /**
  * @notice Enumerate valid NFTs
  * @dev Our Licenses are kept in an array and each new License-token is just
  * the next element in the array. This method is required for ERC721Enumerable
  * which may support more complicated storage schemes. However, in our case the
  * _index is the tokenId
  * @param _index A counter less than `totalSupply()`
  * @return The token identifier for the `_index`th NFT
  */
  function tokenByIndex(uint256 _index) external view returns (uint256) {
    require(_index < totalSupply());
    return _index;
  }

  /**
  * @notice Gets the balance of the specified address
  * @param _owner address to query the balance of
  * @return uint256 representing the amount owned by the passed address
  */
  function balanceOf(address _owner) public view returns (uint256) {
    require(_owner != address(0));
    return ownedTokens[_owner].length;
  }

  /**
  * @notice Gets the list of tokens owned by a given address
  * @param _owner address to query the tokens of
  * @return uint256[] representing the list of tokens owned by the passed address
  */
  function tokensOf(address _owner) public view returns (uint256[]) {
    return ownedTokens[_owner];
  }

  /**
  * @notice Enumerate NFTs assigned to an owner
  * @dev Throws if `_index` >= `balanceOf(_owner)` or if
  *  `_owner` is the zero address, representing invalid NFTs.
  * @param _owner An address where we are interested in NFTs owned by them
  * @param _index A counter less than `balanceOf(_owner)`
  * @return The token identifier for the `_index`th NFT assigned to `_owner`,
  */
  function tokenOfOwnerByIndex(address _owner, uint256 _index)
    external
    view
    returns (uint256 _tokenId)
  {
    require(_index < balanceOf(_owner));
    return ownedTokens[_owner][_index];
  }

  /**
  * @notice Gets the owner of the specified token ID
  * @param _tokenId uint256 ID of the token to query the owner of
  * @return owner address currently marked as the owner of the given token ID
  */
  function ownerOf(uint256 _tokenId) public view returns (address) {
    address owner = tokenOwner[_tokenId];
    require(owner != address(0));
    return owner;
  }

  /**
   * @notice Gets the approved address to take ownership of a given token ID
   * @param _tokenId uint256 ID of the token to query the approval of
   * @return address currently approved to take ownership of the given token ID
   */
  function getApproved(uint256 _tokenId) public view returns (address) {
    return tokenApprovals[_tokenId];
  }

  /**
   * @notice Tells whether the msg.sender is approved to transfer the given token ID or not
   * Checks both for specific approval and operator approval
   * @param _tokenId uint256 ID of the token to query the approval of
   * @return bool whether transfer by msg.sender is approved for the given token ID or not
   */
  function isSenderApprovedFor(uint256 _tokenId) internal view returns (bool) {
    return
      ownerOf(_tokenId) == msg.sender ||
      isSpecificallyApprovedFor(msg.sender, _tokenId) ||
      isApprovedForAll(ownerOf(_tokenId), msg.sender);
  }

  /**
   * @notice Tells whether the msg.sender is approved for the given token ID or not
   * @param _asker address of asking for approval
   * @param _tokenId uint256 ID of the token to query the approval of
   * @return bool whether the msg.sender is approved for the given token ID or not
   */
  function isSpecificallyApprovedFor(address _asker, uint256 _tokenId) internal view returns (bool) {
    return getApproved(_tokenId) == _asker;
  }

  /**
   * @notice Tells whether an operator is approved by a given owner
   * @param _owner owner address which you want to query the approval of
   * @param _operator operator address which you want to query the approval of
   * @return bool whether the given operator is approved by the given owner
   */
  function isApprovedForAll(address _owner, address _operator) public view returns (bool)
  {
    return operatorApprovals[_owner][_operator];
  }

  /**
  * @notice Transfers the ownership of a given token ID to another address
  * @param _to address to receive the ownership of the given token ID
  * @param _tokenId uint256 ID of the token to be transferred
  */
  function transfer(address _to, uint256 _tokenId)
    external
    whenNotPaused
    onlyOwnerOf(_tokenId)
  {
    _clearApprovalAndTransfer(msg.sender, _to, _tokenId);
  }

  /**
  * @notice Approves another address to claim for the ownership of the given token ID
  * @param _to address to be approved for the given token ID
  * @param _tokenId uint256 ID of the token to be approved
  */
  function approve(address _to, uint256 _tokenId)
    external
    whenNotPaused
    onlyOwnerOf(_tokenId)
  {
    address owner = ownerOf(_tokenId);
    require(_to != owner);
    if (getApproved(_tokenId) != 0 || _to != 0) {
      tokenApprovals[_tokenId] = _to;
      Approval(owner, _to, _tokenId);
    }
  }

  /**
  * @notice Enable or disable approval for a third party ("operator") to manage all your assets
  * @dev Emits the ApprovalForAll event
  * @param _to Address to add to the set of authorized operators.
  * @param _approved True if the operators is approved, false to revoke approval
  */
  function setApprovalForAll(address _to, bool _approved)
    external
    whenNotPaused
  {
    if(_approved) {
      approveAll(_to);
    } else {
      disapproveAll(_to);
    }
  }

  /**
  * @notice Approves another address to claim for the ownership of any tokens owned by this account
  * @param _to address to be approved for the given token ID
  */
  function approveAll(address _to)
    public
    whenNotPaused
  {
    require(_to != msg.sender);
    require(_to != address(0));
    operatorApprovals[msg.sender][_to] = true;
    ApprovalForAll(msg.sender, _to, true);
  }

  /**
  * @notice Removes approval for another address to claim for the ownership of any
  *  tokens owned by this account.
  * @dev Note that this only removes the operator approval and
  *  does not clear any independent, specific approvals of token transfers to this address
  * @param _to address to be disapproved for the given token ID
  */
  function disapproveAll(address _to)
    public
    whenNotPaused
  {
    require(_to != msg.sender);
    delete operatorApprovals[msg.sender][_to];
    ApprovalForAll(msg.sender, _to, false);
  }

  /**
  * @notice Claims the ownership of a given token ID
  * @param _tokenId uint256 ID of the token being claimed by the msg.sender
  */
  function takeOwnership(uint256 _tokenId)
   external
   whenNotPaused
  {
    require(isSenderApprovedFor(_tokenId));
    _clearApprovalAndTransfer(ownerOf(_tokenId), msg.sender, _tokenId);
  }

  /**
  * @notice Transfer a token owned by another address, for which the calling address has
  *  previously been granted transfer approval by the owner.
  * @param _from The address that owns the token
  * @param _to The address that will take ownership of the token. Can be any address, including the caller
  * @param _tokenId The ID of the token to be transferred
  */
  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    public
    whenNotPaused
  {
    require(isSenderApprovedFor(_tokenId));
    require(ownerOf(_tokenId) == _from);
    _clearApprovalAndTransfer(ownerOf(_tokenId), _to, _tokenId);
  }

  /**
  * @notice Transfers the ownership of an NFT from one address to another address
  * @dev Throws unless `msg.sender` is the current owner, an authorized
  * operator, or the approved address for this NFT. Throws if `_from` is
  * not the current owner. Throws if `_to` is the zero address. Throws if
  * `_tokenId` is not a valid NFT. When transfer is complete, this function
  * checks if `_to` is a smart contract (code size > 0). If so, it calls
  * `onERC721Received` on `_to` and throws if the return value is not
  * `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`.
  * @param _from The current owner of the NFT
  * @param _to The new owner
  * @param _tokenId The NFT to transfer
  * @param _data Additional data with no specified format, sent in call to `_to`
  */
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    public
    whenNotPaused
  {
    require(_to != address(0));
    require(_isValidLicense(_tokenId));
    transferFrom(_from, _to, _tokenId);
    if (_isContract(_to)) {
      bytes4 tokenReceiverResponse = ERC721TokenReceiver(_to).onERC721Received.gas(50000)(
        _from, _tokenId, _data
      );
      require(tokenReceiverResponse == bytes4(keccak256("onERC721Received(address,uint256,bytes)")));
    }
  }

  /*
   * @notice Transfers the ownership of an NFT from one address to another address
   * @dev This works identically to the other function with an extra data parameter,
   *  except this function just sets data to ""
   * @param _from The current owner of the NFT
   * @param _to The new owner
   * @param _tokenId The NFT to transfer
  */
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    external
    whenNotPaused
  {
    safeTransferFrom(_from, _to, _tokenId, "");
  }

  /**
  * @notice Mint token function
  * @param _to The address that will own the minted token
  * @param _tokenId uint256 ID of the token to be minted by the msg.sender
  */
  function _mint(address _to, uint256 _tokenId) internal {
    require(_to != address(0));
    _addToken(_to, _tokenId);
    Transfer(0x0, _to, _tokenId);
  }

  /**
  * @notice Internal function to clear current approval and transfer the ownership of a given token ID
  * @param _from address which you want to send tokens from
  * @param _to address which you want to transfer the token to
  * @param _tokenId uint256 ID of the token to be transferred
  */
  function _clearApprovalAndTransfer(address _from, address _to, uint256 _tokenId) internal {
    require(_to != address(0));
    require(_to != ownerOf(_tokenId));
    require(ownerOf(_tokenId) == _from);
    require(_isValidLicense(_tokenId));

    _clearApproval(_from, _tokenId);
    _removeToken(_from, _tokenId);
    _addToken(_to, _tokenId);
    Transfer(_from, _to, _tokenId);
  }

  /**
  * @notice Internal function to clear current approval of a given token ID
  * @param _tokenId uint256 ID of the token to be transferred
  */
  function _clearApproval(address _owner, uint256 _tokenId) private {
    require(ownerOf(_tokenId) == _owner);
    tokenApprovals[_tokenId] = 0;
    Approval(_owner, 0, _tokenId);
  }

  /**
  * @notice Internal function to add a token ID to the list of a given address
  * @param _to address representing the new owner of the given token ID
  * @param _tokenId uint256 ID of the token to be added to the tokens list of the given address
  */
  function _addToken(address _to, uint256 _tokenId) private {
    require(tokenOwner[_tokenId] == address(0));
    tokenOwner[_tokenId] = _to;
    uint256 length = balanceOf(_to);
    ownedTokens[_to].push(_tokenId);
    ownedTokensIndex[_tokenId] = length;
    totalTokens = totalTokens.add(1);
  }

  /**
  * @notice Internal function to remove a token ID from the list of a given address
  * @param _from address representing the previous owner of the given token ID
  * @param _tokenId uint256 ID of the token to be removed from the tokens list of the given address
  */
  function _removeToken(address _from, uint256 _tokenId) private {
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

  function _isContract(address addr) internal view returns (bool) {
    uint size;
    assembly { size := extcodesize(addr) }
    return size > 0;
  }
}

contract LicenseSale is LicenseOwnership {
  AffiliateProgram public affiliateProgram;

  /**
   * @notice We credit affiliates for renewals that occur within this time of
   * original purchase. E.g. If this is set to 1 year, and someone subscribes to
   * a monthly plan, the affiliate will receive credits for that whole year, as
   * the user renews their plan
   */
  uint256 public renewalsCreditAffiliatesFor = 1 years;

  /** internal **/
  function _performPurchase(
    uint256 _productId,
    uint256 _numCycles,
    address _assignee,
    uint256 _attributes,
    address _affiliate)
    internal returns (uint)
  {
    _purchaseOneUnitInStock(_productId);
    return _createLicense(
      _productId,
      _numCycles,
      _assignee,
      _attributes,
      _affiliate
      );
  }

  function _createLicense(
    uint256 _productId,
    uint256 _numCycles,
    address _assignee,
    uint256 _attributes,
    address _affiliate)
    internal
    returns (uint)
  {
    // You cannot create a subscription license with zero cycles
    if(isSubscriptionProduct(_productId)) {
      require(_numCycles != 0);
    }

    // Non-subscription products have an expiration time of 0, meaning "no-expiration"
    uint256 expirationTime = isSubscriptionProduct(_productId) ?
      now.add(intervalOf(_productId).mul(_numCycles)) : // solium-disable-line security/no-block-members
      0;

    License memory _license = License({
      productId: _productId,
      attributes: _attributes,
      issuedTime: now, // solium-disable-line security/no-block-members
      expirationTime: expirationTime,
      affiliate: _affiliate
    });

    uint256 newLicenseId = licenses.push(_license) - 1; // solium-disable-line zeppelin/no-arithmetic-operations
    LicenseIssued(
      _assignee,
      msg.sender,
      newLicenseId,
      _license.productId,
      _license.attributes,
      _license.issuedTime,
      _license.expirationTime,
      _license.affiliate);
    _mint(_assignee, newLicenseId);
    return newLicenseId;
  }

  function _handleAffiliate(
    address _affiliate,
    uint256 _productId,
    uint256 _licenseId,
    uint256 _purchaseAmount)
    internal
  {
    uint256 affiliateCut = affiliateProgram.cutFor(
      _affiliate,
      _productId,
      _licenseId,
      _purchaseAmount);
    if(affiliateCut > 0) {
      require(affiliateCut < _purchaseAmount);
      affiliateProgram.credit.value(affiliateCut)(_affiliate, _licenseId);
    }
  }

  function _performRenewal(uint256 _tokenId, uint256 _numCycles) internal {
    // You cannot renew a non-expiring license
    // ... but in what scenario can this happen?
    // require(licenses[_tokenId].expirationTime != 0);
    uint256 productId = licenseProductId(_tokenId);

    // If our expiration is in the future, renewing adds time to that future expiration
    // If our expiration has passed already, then we use `now` as the base.
    uint256 renewalBaseTime = Math.max256(now, licenses[_tokenId].expirationTime);

    // We assume that the payment has been validated outside of this function
    uint256 newExpirationTime = renewalBaseTime.add(intervalOf(productId).mul(_numCycles));

    licenses[_tokenId].expirationTime = newExpirationTime;

    LicenseRenewal(
      ownerOf(_tokenId),
      msg.sender,
      _tokenId,
      productId,
      newExpirationTime
    );
  }

  function _affiliateProgramIsActive() internal view returns (bool) {
    return
      affiliateProgram != address(0) &&
      affiliateProgram.storeAddress() == address(this) &&
      !affiliateProgram.paused();
  }

  /** executives **/
  function setAffiliateProgramAddress(address _address) external onlyCEO {
    AffiliateProgram candidateContract = AffiliateProgram(_address);
    require(candidateContract.isAffiliateProgram());
    affiliateProgram = candidateContract;
  }

  function setRenewalsCreditAffiliatesFor(uint256 _newTime) external onlyCEO {
    renewalsCreditAffiliatesFor = _newTime;
  }

  function createPromotionalPurchase(
    uint256 _productId,
    uint256 _numCycles,
    address _assignee,
    uint256 _attributes
    )
    external
    onlyCEOOrCOO
    whenNotPaused
    returns (uint256)
  {
    return _performPurchase(
      _productId,
      _numCycles,
      _assignee,
      _attributes,
      address(0));
  }

  function createPromotionalRenewal(
    uint256 _tokenId,
    uint256 _numCycles
    )
    external
    onlyCEOOrCOO
    whenNotPaused
  {
    uint256 productId = licenseProductId(_tokenId);
    _requireRenewableProduct(productId);

    return _performRenewal(_tokenId, _numCycles);
  }

  /** anyone **/

  /**
  * @notice Makes a purchase of a product.
  * @dev Requires that the value sent is exactly the price of the product
  * @param _productId - the product to purchase
  * @param _numCycles - the number of cycles being purchased. This number should be `1` for non-subscription products and the number of cycles for subscriptions.
  * @param _assignee - the address to assign the purchase to (doesn&#39;t have to be msg.sender)
  * @param _affiliate - the address to of the affiliate - use address(0) if none
  */
  function purchase(
    uint256 _productId,
    uint256 _numCycles,
    address _assignee,
    address _affiliate
    )
    external
    payable
    whenNotPaused
    returns (uint256)
  {
    require(_productId != 0);
    require(_numCycles != 0);
    require(_assignee != address(0));
    // msg.value can be zero: free products are supported

    // Don&#39;t bother dealing with excess payments. Ensure the price paid is
    // accurate. No more, no less.
    require(msg.value == costForProductCycles(_productId, _numCycles));

    // Non-subscription products should send a _numCycle of 1 -- you can&#39;t buy a
    // multiple quantity of a non-subscription product with this function
    if(!isSubscriptionProduct(_productId)) {
      require(_numCycles == 1);
    }

    // this can, of course, be gamed by malicious miners. But it&#39;s adequate for our application
    // Feel free to add your own strategies for product attributes
    // solium-disable-next-line security/no-block-members, zeppelin/no-arithmetic-operations
    uint256 attributes = uint256(keccak256(block.blockhash(block.number-1)))^_productId^(uint256(_assignee));
    uint256 licenseId = _performPurchase(
      _productId,
      _numCycles,
      _assignee,
      attributes,
      _affiliate);

    if(
      priceOf(_productId) > 0 &&
      _affiliate != address(0) &&
      _affiliateProgramIsActive()
    ) {
      _handleAffiliate(
        _affiliate,
        _productId,
        licenseId,
        msg.value);
    }

    return licenseId;
  }

  /**
   * @notice Renews a subscription
   */
  function renew(
    uint256 _tokenId,
    uint256 _numCycles
    )
    external
    payable
    whenNotPaused
  {
    require(_numCycles != 0);
    require(ownerOf(_tokenId) != address(0));

    uint256 productId = licenseProductId(_tokenId);
    _requireRenewableProduct(productId);

    // No excess payments. Ensure the price paid is exactly accurate. No more,
    // no less.
    uint256 renewalCost = costForProductCycles(productId, _numCycles);
    require(msg.value == renewalCost);

    _performRenewal(_tokenId, _numCycles);

    if(
      renewalCost > 0 &&
      licenseAffiliate(_tokenId) != address(0) &&
      _affiliateProgramIsActive() &&
      licenseIssuedTime(_tokenId).add(renewalsCreditAffiliatesFor) > now
    ) {
      _handleAffiliate(
        licenseAffiliate(_tokenId),
        productId,
        _tokenId,
        msg.value);
    }
  }

}

contract LicenseCore is LicenseSale {
  address public newContractAddress;

  function LicenseCore() public {
    paused = true;

    ceoAddress = msg.sender;
    cooAddress = msg.sender;
    cfoAddress = msg.sender;
    withdrawalAddress = msg.sender;
  }

  function setNewAddress(address _v2Address) external onlyCEO whenPaused {
    newContractAddress = _v2Address;
    ContractUpgrade(_v2Address);
  }

  function() external {
    assert(false);
  }

  function unpause() public onlyCEO whenPaused {
    require(newContractAddress == address(0));
    super.unpause();
  }
}

library Strings {
  // via https://github.com/oraclize/ethereum-api/blob/master/oraclizeAPI_0.5.sol
  function strConcat(string _a, string _b, string _c, string _d, string _e) internal pure returns (string) {
      bytes memory _ba = bytes(_a);
      bytes memory _bb = bytes(_b);
      bytes memory _bc = bytes(_c);
      bytes memory _bd = bytes(_d);
      bytes memory _be = bytes(_e);
      string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
      bytes memory babcde = bytes(abcde);
      uint k = 0;
      for (uint i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
      for (i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
      for (i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
      for (i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
      for (i = 0; i < _be.length; i++) babcde[k++] = _be[i];
      return string(babcde);
    }

    function strConcat(string _a, string _b, string _c, string _d) internal pure returns (string) {
        return strConcat(_a, _b, _c, _d, "");
    }

    function strConcat(string _a, string _b, string _c) internal pure returns (string) {
        return strConcat(_a, _b, _c, "", "");
    }

    function strConcat(string _a, string _b) internal pure returns (string) {
        return strConcat(_a, _b, "", "", "");
    }

    function uint2str(uint i) internal pure returns (string) {
        if (i == 0) return "0";
        uint j = i;
        uint len;
        while (j != 0){
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (i != 0){
            bstr[k--] = byte(48 + i % 10);
            i /= 10;
        }
        return string(bstr);
    }
}