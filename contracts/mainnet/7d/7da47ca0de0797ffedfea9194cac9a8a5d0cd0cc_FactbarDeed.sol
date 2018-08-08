pragma solidity ^0.4.13;

interface ERC721Metadata {

    /// @dev ERC-165 (draft) interface signature for ERC721
    // bytes4 internal constant INTERFACE_SIGNATURE_ERC721Metadata = // 0x2a786f11
    //     bytes4(keccak256(&#39;name()&#39;)) ^
    //     bytes4(keccak256(&#39;symbol()&#39;)) ^
    //     bytes4(keccak256(&#39;deedUri(uint256)&#39;));

    /// @notice A descriptive name for a collection of deeds managed by this
    ///  contract
    /// @dev Wallets and exchanges MAY display this to the end user.
    function name() external pure returns (string _name);

    /// @notice An abbreviated name for deeds managed by this contract
    /// @dev Wallets and exchanges MAY display this to the end user.
    function symbol() external pure returns (string _symbol);

    /// @notice A distinct name for a deed managed by this contract
    /// @dev Wallets and exchanges MAY display this to the end user.
    function deedName(uint256 _deedId) external pure returns (string _deedName);

    /// @notice A distinct URI (RFC 3986) for a given token.
    /// @dev If:
    ///  * The URI is a URL
    ///  * The URL is accessible
    ///  * The URL points to a valid JSON file format (ECMA-404 2nd ed.)
    ///  * The JSON base element is an object
    ///  then these names of the base element SHALL have special meaning:
    ///  * "name": A string identifying the item to which `_deedId` grants
    ///    ownership
    ///  * "description": A string detailing the item to which `_deedId` grants
    ///    ownership
    ///  * "image": A URI pointing to a file of image/* mime type representing
    ///    the item to which `_deedId` grants ownership
    ///  Wallets and exchanges MAY display this to the end user.
    ///  Consider making any images at a width between 320 and 1080 pixels and
    ///  aspect ratio between 1.91:1 and 4:5 inclusive.
    function deedUri(uint256 _deedId) external view returns (string _deedUri);
}

contract ReentrancyGuard {

  /**
   * @dev We use a single lock for the whole contract.
   */
  bool private reentrancy_lock = false;

  /**
   * @dev Prevents a contract from calling itself, directly or indirectly.
   * @notice If you mark a function `nonReentrant`, you should also
   * mark it `external`. Calling one nonReentrant function from
   * another is not supported. Instead, you can implement a
   * `private` function doing the actual work, and a `external`
   * wrapper marked as `nonReentrant`.
   */
  modifier nonReentrant() {
    require(!reentrancy_lock);
    reentrancy_lock = true;
    _;
    reentrancy_lock = false;
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
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
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
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
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

interface ERC721 {

    // COMPLIANCE WITH ERC-165 (DRAFT) /////////////////////////////////////////

    /// @dev ERC-165 (draft) interface signature for itself
    // bytes4 internal constant INTERFACE_SIGNATURE_ERC165 = // 0x01ffc9a7
    //     bytes4(keccak256(&#39;supportsInterface(bytes4)&#39;));

    /// @dev ERC-165 (draft) interface signature for ERC721
    // bytes4 internal constant INTERFACE_SIGNATURE_ERC721 = // 0xda671b9b
    //     bytes4(keccak256(&#39;ownerOf(uint256)&#39;)) ^
    //     bytes4(keccak256(&#39;countOfDeeds()&#39;)) ^
    //     bytes4(keccak256(&#39;countOfDeedsByOwner(address)&#39;)) ^
    //     bytes4(keccak256(&#39;deedOfOwnerByIndex(address,uint256)&#39;)) ^
    //     bytes4(keccak256(&#39;approve(address,uint256)&#39;)) ^
    //     bytes4(keccak256(&#39;takeOwnership(uint256)&#39;));

    /// @notice Query a contract to see if it supports a certain interface
    /// @dev Returns `true` the interface is supported and `false` otherwise,
    ///  returns `true` for INTERFACE_SIGNATURE_ERC165 and
    ///  INTERFACE_SIGNATURE_ERC721, see ERC-165 for other interface signatures.
    function supportsInterface(bytes4 _interfaceID) external pure returns (bool);

    // PUBLIC QUERY FUNCTIONS //////////////////////////////////////////////////

    /// @notice Find the owner of a deed
    /// @param _deedId The identifier for a deed we are inspecting
    /// @dev Deeds assigned to zero address are considered invalid, and
    ///  queries about them do throw.
    /// @return The non-zero address of the owner of deed `_deedId`, or `throw`
    ///  if deed `_deedId` is not tracked by this contract
    function ownerOf(uint256 _deedId) external view returns (address _owner);

    /// @notice Count deeds tracked by this contract
    /// @return A count of valid deeds tracked by this contract, where each one of
    ///  them has an assigned and queryable owner not equal to the zero address
    function countOfDeeds() external view returns (uint256 _count);

    /// @notice Count all deeds assigned to an owner
    /// @dev Throws if `_owner` is the zero address, representing invalid deeds.
    /// @param _owner An address where we are interested in deeds owned by them
    /// @return The number of deeds owned by `_owner`, possibly zero
    function countOfDeedsByOwner(address _owner) external view returns (uint256 _count);

    /// @notice Enumerate deeds assigned to an owner
    /// @dev Throws if `_index` >= `countOfDeedsByOwner(_owner)` or if
    ///  `_owner` is the zero address, representing invalid deeds.
    /// @param _owner An address where we are interested in deeds owned by them
    /// @param _index A counter less than `countOfDeedsByOwner(_owner)`
    /// @return The identifier for the `_index`th deed assigned to `_owner`,
    ///   (sort order not specified)
    function deedOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256 _deedId);

    // TRANSFER MECHANISM //////////////////////////////////////////////////////

    /// @dev This event emits when ownership of any deed changes by any
    ///  mechanism. This event emits when deeds are created (`from` == 0) and
    ///  destroyed (`to` == 0). Exception: during contract creation, any
    ///  transfers may occur without emitting `Transfer`. At the time of any transfer,
    ///  the "approved taker" is implicitly reset to the zero address.
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _deedId);

    /// @dev The Approve event emits to log the "approved taker" for a deed -- whether
    ///  set for the first time, reaffirmed by setting the same value, or setting to
    ///  a new value. The "approved taker" is the zero address if nobody can take the
    ///  deed now or it is an address if that address can call `takeOwnership` to attempt
    ///  taking the deed. Any change to the "approved taker" for a deed SHALL cause
    ///  Approve to emit. However, an exception, the Approve event will not emit when
    ///  Transfer emits, this is because Transfer implicitly denotes the "approved taker"
    ///  is reset to the zero address.
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _deedId);

    /// @notice Set the "approved taker" for your deed, or revoke approval by
    ///  setting the zero address. You may `approve` any number of times while
    ///  the deed is assigned to you, only the most recent approval matters. Emits
    ///  an Approval event.
    /// @dev Throws if `msg.sender` does not own deed `_deedId` or if `_to` ==
    ///  `msg.sender` or if `_deedId` is not a valid deed.
    /// @param _deedId The deed for which you are granting approval
    function approve(address _to, uint256 _deedId) external payable;

    /// @notice Become owner of a deed for which you are currently approved
    /// @dev Throws if `msg.sender` is not approved to become the owner of
    ///  `deedId` or if `msg.sender` currently owns `_deedId` or if `_deedId is not a
    ///  valid deed.
    /// @param _deedId The deed that is being transferred
    function takeOwnership(uint256 _deedId) external payable;
}

contract ERC721Deed is ERC721 {
  using SafeMath for uint256;

  // Total amount of deeds
  uint256 private totalDeeds;

  // Mapping from deed ID to owner
  mapping (uint256 => address) private deedOwner;

  // Mapping from deed ID to approved address
  mapping (uint256 => address) private deedApprovedFor;

  // Mapping from owner to list of owned deed IDs
  mapping (address => uint256[]) private ownedDeeds;

  // Mapping from deed ID to index of the owner deeds list
  mapping(uint256 => uint256) private ownedDeedsIndex;

  /**
  * @dev Guarantees msg.sender is owner of the given deed
  * @param _deedId uint256 ID of the deed to validate its ownership belongs to msg.sender
  */
  modifier onlyOwnerOf(uint256 _deedId) {
    require(deedOwner[_deedId] == msg.sender);
    _;
  }

  /**
  * @dev Gets the owner of the specified deed ID
  * @param _deedId uint256 ID of the deed to query the owner of
  * @return owner address currently marked as the owner of the given deed ID
  */
  function ownerOf(uint256 _deedId)
  external view returns (address _owner) {
    require(deedOwner[_deedId] != address(0));
    _owner = deedOwner[_deedId];
  }

  /**
  * @dev Gets the total amount of deeds stored by the contract
  * @return uint256 representing the total amount of deeds
  */
  function countOfDeeds()
  external view returns (uint256) {
    return totalDeeds;
  }

  /**
  * @dev Gets the number of deeds of the specified address
  * @param _owner address to query the number of deeds
  * @return uint256 representing the number of deeds owned by the passed address
  */
  function countOfDeedsByOwner(address _owner)
  external view returns (uint256 _count) {
    require(_owner != address(0));
    _count = ownedDeeds[_owner].length;
  }

  /**
  * @dev Gets the deed ID of the specified address at the specified index
  * @param _owner address for the deed&#39;s owner
  * @param _index uint256 for the n-th deed in the list of deeds owned by this owner
  * @return uint256 representing the ID of the deed
  */
  function deedOfOwnerByIndex(address _owner, uint256 _index)
  external view returns (uint256 _deedId) {
    require(_owner != address(0));
    require(_index < ownedDeeds[_owner].length);
    _deedId = ownedDeeds[_owner][_index];
  }

  /**
  * @dev Gets all deed IDs of the specified address
  * @param _owner address for the deed&#39;s owner
  * @return uint256[] representing all deed IDs owned by the passed address
  */
  function deedsOf(address _owner)
  external view returns (uint256[] _ownedDeedIds) {
    require(_owner != address(0));
    _ownedDeedIds = ownedDeeds[_owner];
  }

  /**
  * @dev Approves another address to claim for the ownership of the given deed ID
  * @param _to address to be approved for the given deed ID
  * @param _deedId uint256 ID of the deed to be approved
  */
  function approve(address _to, uint256 _deedId)
  external onlyOwnerOf(_deedId) payable {
    require(msg.value == 0);
    require(_to != msg.sender);
    if(_to != address(0) || approvedFor(_deedId) != address(0)) {
      emit Approval(msg.sender, _to, _deedId);
    }
    deedApprovedFor[_deedId] = _to;
  }

  /**
  * @dev Claims the ownership of a given deed ID
  * @param _deedId uint256 ID of the deed being claimed by the msg.sender
  */
  function takeOwnership(uint256 _deedId)
  external payable {
    require(approvedFor(_deedId) == msg.sender);
    clearApprovalAndTransfer(deedOwner[_deedId], msg.sender, _deedId);
  }

  /**
   * @dev Gets the approved address to take ownership of a given deed ID
   * @param _deedId uint256 ID of the deed to query the approval of
   * @return address currently approved to take ownership of the given deed ID
   */
  function approvedFor(uint256 _deedId)
  public view returns (address) {
    return deedApprovedFor[_deedId];
  }

  /**
  * @dev Transfers the ownership of a given deed ID to another address
  * @param _to address to receive the ownership of the given deed ID
  * @param _deedId uint256 ID of the deed to be transferred
  */
  function transfer(address _to, uint256 _deedId)
  public onlyOwnerOf(_deedId) {
    clearApprovalAndTransfer(msg.sender, _to, _deedId);
  }

  /**
  * @dev Mint deed function
  * @param _to The address that will own the minted deed
  */
  function _mint(address _to, uint256 _deedId)
  internal {
    require(_to != address(0));
    addDeed(_to, _deedId);
    emit Transfer(0x0, _to, _deedId);
  }

  /**
  * @dev Burns a specific deed
  * @param _deedId uint256 ID of the deed being burned by the msg.sender
  * Removed because Factbars cannot be destroyed
  */
  // function _burn(uint256 _deedId) onlyOwnerOf(_deedId)
  // internal {
  //   if (approvedFor(_deedId) != 0) {
  //     clearApproval(msg.sender, _deedId);
  //   }
  //   removeDeed(msg.sender, _deedId);
  //   emit Transfer(msg.sender, 0x0, _deedId);
  // }

  /**
  * @dev Internal function to clear current approval and transfer the ownership of a given deed ID
  * @param _from address which you want to send deeds from
  * @param _to address which you want to transfer the deed to
  * @param _deedId uint256 ID of the deed to be transferred
  */
  function clearApprovalAndTransfer(address _from, address _to, uint256 _deedId)
  internal {
    require(_to != address(0));
    require(_to != _from);
    require(deedOwner[_deedId] == _from);

    clearApproval(_from, _deedId);
    removeDeed(_from, _deedId);
    addDeed(_to, _deedId);
    emit Transfer(_from, _to, _deedId);
  }

  /**
  * @dev Internal function to clear current approval of a given deed ID
  * @param _deedId uint256 ID of the deed to be transferred
  */
  function clearApproval(address _owner, uint256 _deedId)
  private {
    require(deedOwner[_deedId] == _owner);
    deedApprovedFor[_deedId] = 0;
    emit Approval(_owner, 0, _deedId);
  }

  /**
  * @dev Internal function to add a deed ID to the list of a given address
  * @param _to address representing the new owner of the given deed ID
  * @param _deedId uint256 ID of the deed to be added to the deeds list of the given address
  */
  function addDeed(address _to, uint256 _deedId)
  private {
    require(deedOwner[_deedId] == address(0));
    deedOwner[_deedId] = _to;
    uint256 length = ownedDeeds[_to].length;
    ownedDeeds[_to].push(_deedId);
    ownedDeedsIndex[_deedId] = length;
    totalDeeds = totalDeeds.add(1);
  }

  /**
  * @dev Internal function to remove a deed ID from the list of a given address
  * @param _from address representing the previous owner of the given deed ID
  * @param _deedId uint256 ID of the deed to be removed from the deeds list of the given address
  */
  function removeDeed(address _from, uint256 _deedId)
  private {
    require(deedOwner[_deedId] == _from);

    uint256 deedIndex = ownedDeedsIndex[_deedId];
    uint256 lastDeedIndex = ownedDeeds[_from].length.sub(1);
    uint256 lastDeed = ownedDeeds[_from][lastDeedIndex];

    deedOwner[_deedId] = 0;
    ownedDeeds[_from][deedIndex] = lastDeed;
    ownedDeeds[_from][lastDeedIndex] = 0;
    // Note that this will handle single-element arrays. In that case, both deedIndex and lastDeedIndex are going to
    // be zero. Then we can make sure that we will remove _deedId from the ownedDeeds list since we are first swapping
    // the lastDeed to the first position, and then dropping the element placed in the last position of the list

    ownedDeeds[_from].length--;
    ownedDeedsIndex[_deedId] = 0;
    ownedDeedsIndex[lastDeed] = deedIndex;
    totalDeeds = totalDeeds.sub(1);
  }
}

contract PullPayment {
  using SafeMath for uint256;

  mapping(address => uint256) public payments;
  uint256 public totalPayments;

  /**
  * @dev Withdraw accumulated balance, called by payee.
  */
  function withdrawPayments() public {
    address payee = msg.sender;
    uint256 payment = payments[payee];

    require(payment != 0);
    require(address(this).balance >= payment);

    totalPayments = totalPayments.sub(payment);
    payments[payee] = 0;

    payee.transfer(payment);
  }

  /**
  * @dev Called by the payer to store the sent amount as credit to be pulled.
  * @param dest The destination address of the funds.
  * @param amount The amount to transfer.
  */
  function asyncSend(address dest, uint256 amount) internal {
    payments[dest] = payments[dest].add(amount);
    totalPayments = totalPayments.add(amount);
  }
}

contract FactbarDeed is ERC721Deed, Pausable, PullPayment, ReentrancyGuard {

  using SafeMath for uint256;

  /* Events */
  // When a deed is created by the contract owner.
  event Creation(uint256 indexed id, bytes32 indexed name, address factTeam);

  // When a deed is appropriated, the ownership of the deed is transferred to the new owner.
  // The old owner is reimbursed, and he gets the new price minus the transfer fee.
  event Appropriation(uint256 indexed id, address indexed oldOwner, 
  address indexed newOwner, uint256 oldPrice, uint256 newPrice,
  uint256 transferFeeAmount, uint256 excess,  uint256 oldOwnerPaymentAmount );

  // Payments to the deed&#39;s fee address via PullPayment are also supported by this contract.
  event Payment(uint256 indexed id, address indexed sender, address 
  indexed factTeam, uint256 amount);

  // Factbars, like facts, cannot be destroyed. So we have removed 
  // all the deletion and desctruction features

  // The data structure of the Factbar deed
  
  struct Factbar {
    bytes32 name;
    address factTeam;
    uint256 price;
    uint256 created;
  }

  // Mapping from _deedId to Factbar
  mapping (uint256 => Factbar) private deeds;

  // Mapping from deed name to boolean indicating if the name is already taken
  mapping (bytes32 => bool) private deedNameExists;

  // Needed to make all deeds discoverable. The length of this array also serves as our deed ID.
  uint256[] private deedIds;

  // These are the admins who have the power to create deeds.
  mapping (address => bool) private admins;

  /* Variables in control of owner */

  // The contract owner can change the initial price of deeds at Creation.
  uint256 private creationPrice = 0.0005 ether; 

  // The contract owner can change the base URL, in case it becomes necessary. It is needed for Metadata.
  string public url = "https://fact-bar.org/facts/";

  // ERC-165 Metadata
  bytes4 internal constant INTERFACE_SIGNATURE_ERC165 = // 0x01ffc9a7
      bytes4(keccak256(&#39;supportsInterface(bytes4)&#39;));

  bytes4 internal constant INTERFACE_SIGNATURE_ERC721 = // 0xda671b9b
      bytes4(keccak256(&#39;ownerOf(uint256)&#39;)) ^
      bytes4(keccak256(&#39;countOfDeeds()&#39;)) ^
      bytes4(keccak256(&#39;countOfDeedsByOwner(address)&#39;)) ^
      bytes4(keccak256(&#39;deedOfOwnerByIndex(address,uint256)&#39;)) ^
      bytes4(keccak256(&#39;approve(address,uint256)&#39;)) ^
      bytes4(keccak256(&#39;takeOwnership(uint256)&#39;));

  bytes4 internal constant INTERFACE_SIGNATURE_ERC721Metadata = // 0x2a786f11
      bytes4(keccak256(&#39;name()&#39;)) ^
      bytes4(keccak256(&#39;symbol()&#39;)) ^
      bytes4(keccak256(&#39;deedUri(uint256)&#39;));


  function FactbarDeed() public {}

  // payable removed from fallback function following audit
  function() public {}

  modifier onlyExistingNames(uint256 _deedId) {
    require(deedNameExists[deeds[_deedId].name]);
    _;
  }

  modifier noExistingNames(bytes32 _name) {
    require(!deedNameExists[_name]);
    _;
  }
  
  modifier onlyAdmins() {
    require(admins[msg.sender]);
    _;
  }


   /* ERC721Metadata */

  function name()
  external pure returns (string) {
    return "Factbar";
  }

  function symbol()
  external pure returns (string) {
    return "FTBR";
  }

  function supportsInterface(bytes4 _interfaceID)
  external pure returns (bool) {
    return (
      _interfaceID == INTERFACE_SIGNATURE_ERC165
      || _interfaceID == INTERFACE_SIGNATURE_ERC721
      || _interfaceID == INTERFACE_SIGNATURE_ERC721Metadata
    );
  }

  function deedUri(uint256 _deedId)
  external view onlyExistingNames(_deedId) returns (string _uri) {
    _uri = _strConcat(url, _bytes32ToString(deeds[_deedId].name));
  }

  function deedName(uint256 _deedId)
  external view onlyExistingNames(_deedId) returns (string _name) {
    _name = _bytes32ToString(deeds[_deedId].name);
  }


  // get pending payments to address, generated from appropriations
  function getPendingPaymentAmount(address _account)
  external view returns (uint256 _balance) {
     uint256 payment = payments[_account];
    _balance = payment;
  }

  // get Ids of all deeds  
  function getDeedIds()
  external view returns (uint256[]) {
    return deedIds;
  }
 
  /// Logic for pricing of deeds
  function nextPriceOf (uint256 _deedId) public view returns (uint256 _nextPrice) {
    return calculateNextPrice(priceOf(_deedId));
  }

  uint256 private increaseLimit1 = 0.02 ether;
  uint256 private increaseLimit2 = 0.5 ether;
  uint256 private increaseLimit3 = 2.0 ether;
  uint256 private increaseLimit4 = 5.0 ether;

  function calculateNextPrice (uint256 _price) public view returns (uint256 _nextPrice) {
    if (_price < increaseLimit1) {
      return _price.mul(200).div(100);
    } else if (_price < increaseLimit2) {
      return _price.mul(135).div(100);
    } else if (_price < increaseLimit3) {
      return _price.mul(125).div(100);
    } else if (_price < increaseLimit4) {
      return _price.mul(117).div(100);
    } else {
      return _price.mul(115).div(100);
    }
  }

  function calculateTransferFee (uint256 _price) public view returns (uint256 _devCut) {
    if (_price < increaseLimit1) {
      return _price.mul(5).div(100); // 5%
    } else if (_price < increaseLimit2) {
      return _price.mul(4).div(100); // 4%
    } else if (_price < increaseLimit3) {
      return _price.mul(3).div(100); // 3%
    } else if (_price < increaseLimit4) {
      return _price.mul(3).div(100); // 3%
    } else {
      return _price.mul(3).div(100); // 3%
    }
  }


  // Forces the transfer of the deed to a new owner, 
  // if a higher price was paid. This functionality can be paused by the owner.
  function appropriate(uint256 _deedId)
  external whenNotPaused nonReentrant payable {

    // Get current price of deed
    uint256 price = priceOf(_deedId);

     // The current owner is forbidden to appropriate himself.
    address oldOwner = this.ownerOf(_deedId);
    address newOwner = msg.sender;
    require(oldOwner != newOwner);
    
    // price must be more than zero
    require(priceOf(_deedId) > 0); 
    
    // offered price must be more than or equal to the current price
    require(msg.value >= price); 

    /// Any over-payment by the buyer will be sent back to him/her
    uint256 excess = msg.value.sub(price);

    // Clear any outstanding approvals and transfer the deed.*/
    clearApprovalAndTransfer(oldOwner, newOwner, _deedId);
    uint256 nextPrice = nextPriceOf(_deedId);
    deeds[_deedId].price = nextPrice;
    
    // transfer fee is calculated
    uint256 transferFee = calculateTransferFee(price);

    /// previous owner gets entire new payment minus the transfer fee
    uint256 oldOwnerPayment = price.sub(transferFee);

    /// using Pullpayment for safety
    asyncSend(factTeamOf(_deedId), transferFee);
    asyncSend(oldOwner, oldOwnerPayment);

    if (excess > 0) {
       asyncSend(newOwner, excess);
    }

    emit Appropriation(_deedId, oldOwner, newOwner, price, nextPrice,
    transferFee, excess, oldOwnerPayment);
  }

  // these events can be turned on to make up for Solidity&#39;s horrifying logging situation
  // event logUint(address add, string text, uint256 value);
  // event simpleLogUint(string text, uint256 value);

  // Send a PullPayment.
  function pay(uint256 _deedId)
  external nonReentrant payable {
    address factTeam = factTeamOf(_deedId);
    asyncSend(factTeam, msg.value);
    emit Payment(_deedId, msg.sender, factTeam, msg.value);
  }

  // The owner can only withdraw what has not been assigned to the transfer fee address as PullPayments.
  function withdraw()
  external nonReentrant {
    withdrawPayments();
    if (msg.sender == owner) {
      // The contract&#39;s balance MUST stay backing the outstanding withdrawals.
      //  Only the surplus not needed for any backing can be withdrawn by the owner.
      uint256 surplus = address(this).balance.sub(totalPayments);
      if (surplus > 0) {
        owner.transfer(surplus);
      }
    }
  }

  /* Owner Functions */

  // The contract owner creates deeds. Newly created deeds are
  // initialised with a name and a transfer fee address
  // only Admins can create deeds
  function create(bytes32 _name, address _factTeam)
  public onlyAdmins noExistingNames(_name) {
    deedNameExists[_name] = true;
    uint256 deedId = deedIds.length;
    deedIds.push(deedId);
    super._mint(owner, deedId);
    deeds[deedId] = Factbar({
      name: _name,
      factTeam: _factTeam,
      price: creationPrice,
      created: now
      // deleted: 0
    });
    emit Creation(deedId, _name, owner);
  }

  // the owner can add and remove admins as per his/her whim

  function addAdmin(address _admin)  
  public onlyOwner{
    admins[_admin] = true;
  }

  function removeAdmin (address _admin)  
  public onlyOwner{
    delete admins[_admin];
  }

  // the owner can set the creation price 

  function setCreationPrice(uint256 _price)
  public onlyOwner {
    creationPrice = _price;
  }

  function setUrl(string _url)
  public onlyOwner {
    url = _url;
  }

  /* Other publicly available functions */

  // Returns the last paid price for this deed.
  function priceOf(uint256 _deedId)
  public view returns (uint256 _price) {
    _price = deeds[_deedId].price;
  }

  // Returns the current transfer fee address
  function factTeamOf(uint256 _deedId)
  public view returns (address _factTeam) {
    _factTeam = deeds[_deedId].factTeam;
  }


  /* Private helper functions */        

  function _bytes32ToString(bytes32 _bytes32)
  private pure returns (string) {
    bytes memory bytesString = new bytes(32);
    uint charCount = 0;
    for (uint j = 0; j < 32; j++) {
      byte char = byte(bytes32(uint(_bytes32) * 2 ** (8 * j)));
      if (char != 0) {
        bytesString[charCount] = char;
        charCount++;
      }
    }
    bytes memory bytesStringTrimmed = new bytes(charCount);
    for (j = 0; j < charCount; j++) {
      bytesStringTrimmed[j] = bytesString[j];
    }

    return string(bytesStringTrimmed);
  }

  function _strConcat(string _a, string _b)
  private pure returns (string) {
    bytes memory _ba = bytes(_a);
    bytes memory _bb = bytes(_b);
    string memory ab = new string(_ba.length + _bb.length);
    bytes memory bab = bytes(ab);
    uint k = 0;
    for (uint i = 0; i < _ba.length; i++) bab[k++] = _ba[i];
    for (i = 0; i < _bb.length; i++) bab[k++] = _bb[i];
    return string(bab);
  }

}

// The MIT License (MIT)
// Copyright (c) 2018 Factbar
// Copyright (c) 2016 Smart Contract Solutions, Inc.

// Permission is hereby granted, free of charge, 
// to any person obtaining a copy of this software and 
// associated documentation files (the "Software"), to 
// deal in the Software without restriction, including 
// without limitation the rights to use, copy, modify, 
// merge, publish, distribute, sublicense, and/or sell 
// copies of the Software, and to permit persons to whom 
// the Software is furnished to do so, 
// subject to the following conditions:

// The above copyright notice and this permission notice 
// shall be included in all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, 
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES 
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. 
// IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR 
// ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, 
// TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE 
// SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.