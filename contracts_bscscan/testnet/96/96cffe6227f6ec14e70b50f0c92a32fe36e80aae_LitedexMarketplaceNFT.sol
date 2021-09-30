/**
 *Submitted for verification at BscScan.com on 2021-09-30
*/

pragma solidity ^0.4.24;

// File: zos-lib/contracts/migrations/Migratable.sol

/**
 * @title Migratable
 * Helper contract to support intialization and migration schemes between
 * different implementations of a contract in the context of upgradeability.
 * To use it, replace the constructor with a function that has the
 * `isInitializer` modifier starting with `"0"` as `migrationId`.
 * When you want to apply some migration code during an upgrade, increase
 * the `migrationId`. Or, if the migration code must be applied only after
 * another migration has been already applied, use the `isMigration` modifier.
 * This helper supports multiple inheritance.
 * WARNING: It is the developer's responsibility to ensure that migrations are
 * applied in a correct order, or that they are run at all.
 * See `Initializable` for a simpler version.
 */
contract Migratable {
  /**
   * @dev Emitted when the contract applies a migration.
   * @param contractName Name of the Contract.
   * @param migrationId Identifier of the migration applied.
   */
  event Migrated(string contractName, string migrationId);

  /**
   * @dev Mapping of the already applied migrations.
   * (contractName => (migrationId => bool))
   */
  mapping (string => mapping (string => bool)) internal migrated;

  /**
   * @dev Internal migration id used to specify that a contract has already been initialized.
   */
  string constant private INITIALIZED_ID = "initialized";


  /**
   * @dev Modifier to use in the initialization function of a contract.
   * @param contractName Name of the contract.
   * @param migrationId Identifier of the migration.
   */
  modifier isInitializer(string contractName, string migrationId) {
    validateMigrationIsPending(contractName, INITIALIZED_ID);
    validateMigrationIsPending(contractName, migrationId);
    _;
    emit Migrated(contractName, migrationId);
    migrated[contractName][migrationId] = true;
    migrated[contractName][INITIALIZED_ID] = true;
  }

  /**
   * @dev Modifier to use in the migration of a contract.
   * @param contractName Name of the contract.
   * @param requiredMigrationId Identifier of the previous migration, required
   * to apply new one.
   * @param newMigrationId Identifier of the new migration to be applied.
   */
  modifier isMigration(string contractName, string requiredMigrationId, string newMigrationId) {
    require(isMigrated(contractName, requiredMigrationId), "Prerequisite migration ID has not been run yet");
    validateMigrationIsPending(contractName, newMigrationId);
    _;
    emit Migrated(contractName, newMigrationId);
    migrated[contractName][newMigrationId] = true;
  }

  /**
   * @dev Returns true if the contract migration was applied.
   * @param contractName Name of the contract.
   * @param migrationId Identifier of the migration.
   * @return true if the contract migration was applied, false otherwise.
   */
  function isMigrated(string contractName, string migrationId) public view returns(bool) {
    return migrated[contractName][migrationId];
  }

  /**
   * @dev Initializer that marks the contract as initialized.
   * It is important to run this if you had deployed a previous version of a Migratable contract.
   * For more information see https://github.com/zeppelinos/zos-lib/issues/158.
   */
  function initialize() isInitializer("Migratable", "1.2.1") public {
  }

  /**
   * @dev Reverts if the requested migration was already executed.
   * @param contractName Name of the contract.
   * @param migrationId Identifier of the migration.
   */
  function validateMigrationIsPending(string contractName, string migrationId) private view {
    require(!isMigrated(contractName, migrationId), "Requested target migration ID has already been run");
  }
}

// File: openzeppelin-zos/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable is Migratable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function initialize(address _sender) public isInitializer("Ownable", "1.9.0") {
    owner = _sender;
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
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

// File: openzeppelin-zos/contracts/lifecycle/Pausable.sol

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Migratable, Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  function initialize(address _sender) isInitializer("Pausable", "1.9.0")  public {
    Ownable.initialize(_sender);
  }

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

// File: openzeppelin-zos/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
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
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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

// File: openzeppelin-zos/contracts/AddressUtils.sol

/**
 * Utility library of inline functions on addresses
 */
library AddressUtils {

  /**
   * Returns whether the target address is a contract
   * @dev This function will return false if invoked during the constructor of a contract,
   *  as the code is not actually created until after the constructor finishes.
   * @param addr address to check
   * @return whether the target address is a contract
   */
  function isContract(address addr) internal view returns (bool) {
    uint256 size;
    // XXX Currently there is no better way to check if there is a contract in an address
    // than to check the size of the code at that address.
    // See https://ethereum.stackexchange.com/a/14016/36603
    // for more details about how this works.
    // TODO Check this again before the Serenity release, because all addresses will be
    // contracts then.
    assembly { size := extcodesize(addr) }  // solium-disable-line security/no-inline-assembly
    return size > 0;
  }

}

// File: contracts/marketplace/MarketplaceStorage.sol

/**
 * @title Interface for contracts conforming to ERC-20
 */
contract ERC20Interface {
  function transferFrom(address from, address to, uint tokens) public returns (bool success);
}


/**
 * @title Interface for contracts conforming to ERC-721
 */
contract ERC721Interface {
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function approve(address _to, uint256 _tokenId) public;
  function getApproved(uint256 _tokenId) public view returns (address);
  function isApprovedForAll(address _owner, address _operator) public view returns (bool);
  function safeTransferFrom(address _from, address _to, uint256 _tokenId) public;
  function supportsInterface(bytes4) public view returns (bool);
}


contract ERC721Verifiable is ERC721Interface {
  function verifyFingerprint(uint256, bytes) public view returns (bool);
}


contract MarketplaceStorage {
  ERC20Interface public acceptedToken;

  struct Order {
    // Order ID
    bytes32 id;
    // Owner of the NFT
    address seller;
    // NFT registry address
    address nftAddress;
    // Price (in wei) for the published item
    uint256 price;
    // Time when this sale ends
    uint256 expiresAt;
  }

  // From ERC721 registry assetId to Order (to avoid asset collision)
  mapping (address => mapping(uint256 => Order)) public orderByAssetId;

  uint256 public ownerCutPerMillion;
  uint256 public publicationFeeInWei;

  address public legacyNFTAddress;

  bytes4 public constant InterfaceId_ValidateFingerprint = bytes4(
    keccak256("verifyFingerprint(uint256,bytes)")
  );

  bytes4 public constant ERC721_Interface = bytes4(0x80ac58cd);

  // EVENTS
  event OrderCreated(
    bytes32 id,
    uint256 indexed assetId,
    address indexed seller,
    address nftAddress,
    uint256 priceInWei,
    uint256 expiresAt
  );
  event OrderSuccessful(
    bytes32 id,
    uint256 indexed assetId,
    address indexed seller,
    address nftAddress,
    uint256 totalPrice,
    address indexed buyer
  );
  event OrderCancelled(
    bytes32 id,
    uint256 indexed assetId,
    address indexed seller,
    address nftAddress
  );

  event ChangedPublicationFee(uint256 publicationFee);
  event ChangedOwnerCutPerMillion(uint256 ownerCutPerMillion);
  event ChangeLegacyNFTAddress(address indexed legacyNFTAddress);

  // [LEGACY] Auction events
  event AuctionCreated(
    bytes32 id,
    uint256 indexed assetId,
    address indexed seller,
    uint256 priceInWei,
    uint256 expiresAt
  );
  event AuctionSuccessful(
    bytes32 id,
    uint256 indexed assetId,
    address indexed seller,
    uint256 totalPrice,
    address indexed winner
  );
  event AuctionCancelled(
    bytes32 id,
    uint256 indexed assetId,
    address indexed seller
  );
}

// File: contracts/marketplace/Marketplace.sol

contract LitedexMarketplaceNFT is Migratable, Ownable, Pausable, MarketplaceStorage {
  using SafeMath for uint256;
  using AddressUtils for address;

  /**
    * @dev Sets the publication fee that's charged to users to publish items
    * @param _publicationFee - Fee amount in wei this contract charges to publish an item
    */
  function setPublicationFee(uint256 _publicationFee) external onlyOwner {
    publicationFeeInWei = _publicationFee;
    emit ChangedPublicationFee(publicationFeeInWei);
  }

  /**
    * @dev Sets the share cut for the owner of the contract that's
    *  charged to the seller on a successful sale
    * @param _ownerCutPerMillion - Share amount, from 0 to 999,999
    */
  function setOwnerCutPerMillion(uint256 _ownerCutPerMillion) external onlyOwner {
    require(_ownerCutPerMillion < 1000000, "The owner cut should be between 0 and 999,999");

    ownerCutPerMillion = _ownerCutPerMillion;
    emit ChangedOwnerCutPerMillion(ownerCutPerMillion);
  }

  /**
    * @dev Sets the legacy NFT address to be used
    * @param _legacyNFTAddress - Address of the NFT address used for legacy methods that don't have nftAddress as parameter
    */
  function setLegacyNFTAddress(address _legacyNFTAddress) external onlyOwner {
    _requireERC721(_legacyNFTAddress);

    legacyNFTAddress = _legacyNFTAddress;
    emit ChangeLegacyNFTAddress(legacyNFTAddress);
  }

  /**
    * @dev Initialize this contract. Acts as a constructor
    * @param _acceptedToken - Address of the ERC20 accepted for this marketplace
    * @param _legacyNFTAddress - Address of the NFT address used for legacy methods that don't have nftAddress as parameter
    */
  function initialize(
    address _acceptedToken,
    address _legacyNFTAddress,
    address _owner
  )
    public
    isInitializer("Marketplace", "0.0.1")
  {

    // msg.sender is the App contract not the real owner. Calls ownable behind the scenes...sigh
    require(_owner != address(0), "Invalid owner");
    Pausable.initialize(_owner);

    require(_acceptedToken.isContract(), "The accepted token address must be a deployed contract");
    acceptedToken = ERC20Interface(_acceptedToken);

    _requireERC721(_legacyNFTAddress);
    legacyNFTAddress = _legacyNFTAddress;
  }

  /**
    * @dev Creates a new order
    * @param nftAddress - Non fungible registry address
    * @param assetId - ID of the published NFT
    * @param priceInWei - Price in Wei for the supported coin
    * @param expiresAt - Duration of the order (in hours)
    */
  function createOrder(
    address nftAddress,
    uint256 assetId,
    uint256 priceInWei,
    uint256 expiresAt
  )
    public
    whenNotPaused
  {
    _createOrder(
      nftAddress,
      assetId,
      priceInWei,
      expiresAt
    );
  }

  /**
    * @dev [LEGACY] Creates a new order
    * @param assetId - ID of the published NFT
    * @param priceInWei - Price in Wei for the supported coin
    * @param expiresAt - Duration of the order (in hours)
    */
  function createOrder(
    uint256 assetId,
    uint256 priceInWei,
    uint256 expiresAt
  )
    public
    whenNotPaused
  {
    _createOrder(
      legacyNFTAddress,
      assetId,
      priceInWei,
      expiresAt
    );

    Order memory order = orderByAssetId[legacyNFTAddress][assetId];
    emit AuctionCreated(
      order.id,
      assetId,
      order.seller,
      order.price,
      order.expiresAt
    );
  }

  /**
    * @dev Cancel an already published order
    *  can only be canceled by seller or the contract owner
    * @param nftAddress - Address of the NFT registry
    * @param assetId - ID of the published NFT
    */
  function cancelOrder(address nftAddress, uint256 assetId) public whenNotPaused {
    _cancelOrder(nftAddress, assetId);
  }

  /**
    * @dev [LEGACY] Cancel an already published order
    *  can only be canceled by seller or the contract owner
    * @param assetId - ID of the published NFT
    */
  function cancelOrder(uint256 assetId) public whenNotPaused {
    Order memory order = _cancelOrder(legacyNFTAddress, assetId);

    emit AuctionCancelled(
      order.id,
      assetId,
      order.seller
    );
  }

  /**
    * @dev Executes the sale for a published NFT and checks for the asset fingerprint
    * @param nftAddress - Address of the NFT registry
    * @param assetId - ID of the published NFT
    * @param price - Order price
    * @param fingerprint - Verification info for the asset
    */
  function safeExecuteOrder(
    address nftAddress,
    uint256 assetId,
    uint256 price,
    bytes fingerprint
  )
   public
   whenNotPaused
  {
    _executeOrder(
      nftAddress,
      assetId,
      price,
      fingerprint
    );
  }

  /**
    * @dev Executes the sale for a published NFT
    * @param nftAddress - Address of the NFT registry
    * @param assetId - ID of the published NFT
    * @param price - Order price
    */
  function executeOrder(
    address nftAddress,
    uint256 assetId,
    uint256 price
  )
   public
   whenNotPaused
  {
    _executeOrder(
      nftAddress,
      assetId,
      price,
      ""
    );
  }

  /**
    * @dev [LEGACY] Executes the sale for a published NFT
    * @param assetId - ID of the published NFT
    * @param price - Order price
    */
  function executeOrder(
    uint256 assetId,
    uint256 price
  )
   public
   whenNotPaused
  {
    Order memory order = _executeOrder(
      legacyNFTAddress,
      assetId,
      price,
      ""
    );

    emit AuctionSuccessful(
      order.id,
      assetId,
      order.seller,
      price,
      msg.sender
    );
  }

  /**
    * @dev [LEGACY] Gets an order using the legacy NFT address.
    * @dev It's equivalent to orderByAssetId[legacyNFTAddress][assetId] but returns same structure as the old Auction
    * @param assetId - ID of the published NFT
    */
  function auctionByAssetId(
    uint256 assetId
  )
    public
    view
    returns
    (bytes32, address, uint256, uint256)
  {
    Order memory order = orderByAssetId[legacyNFTAddress][assetId];
    return (order.id, order.seller, order.price, order.expiresAt);
  }

  /**
    * @dev Creates a new order
    * @param nftAddress - Non fungible registry address
    * @param assetId - ID of the published NFT
    * @param priceInWei - Price in Wei for the supported coin
    * @param expiresAt - Duration of the order (in hours)
    */
  function _createOrder(
    address nftAddress,
    uint256 assetId,
    uint256 priceInWei,
    uint256 expiresAt
  )
    internal
  {
    _requireERC721(nftAddress);

    ERC721Interface nftRegistry = ERC721Interface(nftAddress);
    address assetOwner = nftRegistry.ownerOf(assetId);

    require(msg.sender == assetOwner, "Only the owner can create orders");
    require(
      nftRegistry.getApproved(assetId) == address(this) || nftRegistry.isApprovedForAll(assetOwner, address(this)),
      "The contract is not authorized to manage the asset"
    );
    require(priceInWei > 0, "Price should be bigger than 0");
    require(expiresAt > block.timestamp.add(1 minutes), "Publication should be more than 1 minute in the future");

    bytes32 orderId = keccak256(
      abi.encodePacked(
        block.timestamp,
        assetOwner,
        assetId,
        nftAddress,
        priceInWei
      )
    );

    orderByAssetId[nftAddress][assetId] = Order({
      id: orderId,
      seller: assetOwner,
      nftAddress: nftAddress,
      price: priceInWei,
      expiresAt: expiresAt
    });

    // Check if there's a publication fee and
    // transfer the amount to marketplace owner
    if (publicationFeeInWei > 0) {
      require(
        acceptedToken.transferFrom(msg.sender, owner, publicationFeeInWei),
        "Transfering the publication fee to the Marketplace owner failed"
      );
    }

    emit OrderCreated(
      orderId,
      assetId,
      assetOwner,
      nftAddress,
      priceInWei,
      expiresAt
    );
  }

  /**
    * @dev Cancel an already published order
    *  can only be canceled by seller or the contract owner
    * @param nftAddress - Address of the NFT registry
    * @param assetId - ID of the published NFT
    */
  function _cancelOrder(address nftAddress, uint256 assetId) internal returns (Order) {
    Order memory order = orderByAssetId[nftAddress][assetId];

    require(order.id != 0, "Asset not published");
    require(order.seller == msg.sender || msg.sender == owner, "Unauthorized user");

    bytes32 orderId = order.id;
    address orderSeller = order.seller;
    address orderNftAddress = order.nftAddress;
    delete orderByAssetId[nftAddress][assetId];

    emit OrderCancelled(
      orderId,
      assetId,
      orderSeller,
      orderNftAddress
    );

    return order;
  }

  /**
    * @dev Executes the sale for a published NFT
    * @param nftAddress - Address of the NFT registry
    * @param assetId - ID of the published NFT
    * @param price - Order price
    * @param fingerprint - Verification info for the asset
    */
  function _executeOrder(
    address nftAddress,
    uint256 assetId,
    uint256 price,
    bytes fingerprint
  )
   internal returns (Order)
  {
    _requireERC721(nftAddress);

    ERC721Verifiable nftRegistry = ERC721Verifiable(nftAddress);

    if (nftRegistry.supportsInterface(InterfaceId_ValidateFingerprint)) {
      require(
        nftRegistry.verifyFingerprint(assetId, fingerprint),
        "The asset fingerprint is not valid"
      );
    }
    Order memory order = orderByAssetId[nftAddress][assetId];

    require(order.id != 0, "Asset not published");

    address seller = order.seller;

    require(seller != address(0), "Invalid address");
    require(seller != msg.sender, "Unauthorized user");
    require(order.price == price, "The price is not correct");
    require(block.timestamp < order.expiresAt, "The order expired");
    require(seller == nftRegistry.ownerOf(assetId), "The seller is no longer the owner");

    uint saleShareAmount = 0;

    bytes32 orderId = order.id;
    delete orderByAssetId[nftAddress][assetId];

    if (ownerCutPerMillion > 0) {
      // Calculate sale share
      saleShareAmount = price.mul(ownerCutPerMillion).div(1000000);

      // Transfer share amount for marketplace Owner
      require(
        acceptedToken.transferFrom(msg.sender, owner, saleShareAmount),
        "Transfering the cut to the Marketplace owner failed"
      );
    }

    // Transfer sale amount to seller
    require(
      acceptedToken.transferFrom(msg.sender, seller, price.sub(saleShareAmount)),
      "Transfering the sale amount to the seller failed"
    );

    // Transfer asset owner
    nftRegistry.safeTransferFrom(
      seller,
      msg.sender,
      assetId
    );

    emit OrderSuccessful(
      orderId,
      assetId,
      seller,
      nftAddress,
      price,
      msg.sender
    );

    return order;
  }

  function _requireERC721(address nftAddress) internal view {
    require(nftAddress.isContract(), "The NFT Address should be a contract");

    ERC721Interface nftRegistry = ERC721Interface(nftAddress);
    require(
      nftRegistry.supportsInterface(ERC721_Interface),
      "The NFT contract has an invalid ERC721 implementation"
    );
  }
}