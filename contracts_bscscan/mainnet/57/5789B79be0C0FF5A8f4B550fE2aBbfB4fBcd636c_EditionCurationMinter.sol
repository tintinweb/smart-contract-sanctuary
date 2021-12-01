/**
 *Submitted for verification at BscScan.com on 2021-12-01
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}





/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}






/**
 * @title Roles
 * @author Francisco Giordano (@frangio)
 * @dev Library for managing addresses assigned to a Role.
 * See RBAC.sol for example usage.
 */
library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

  /**
   * @dev give an address access to this role
   */
  function add(Role storage _role, address _addr)
    internal
  {
    _role.bearer[_addr] = true;
  }

  /**
   * @dev remove an address' access to this role
   */
  function remove(Role storage _role, address _addr)
    internal
  {
    _role.bearer[_addr] = false;
  }

  /**
   * @dev check if an address has this role
   * // reverts
   */
  function check(Role storage _role, address _addr)
    internal
    view
  {
    require(has(_role, _addr));
  }

  /**
   * @dev check if an address has this role
   * @return bool
   */
  function has(Role storage _role, address _addr)
    internal
    view
    returns (bool)
  {
    return _role.bearer[_addr];
  }
}





/**
 * @title RBAC (Role-Based Access Control)
 * @author Matt Condon (@Shrugs)
 * @dev Stores and provides setters and getters for roles and addresses.
 * Supports unlimited numbers of roles and addresses.
 * See //contracts/mocks/RBACMock.sol for an example of usage.
 * This RBAC method uses strings to key roles. It may be beneficial
 * for you to write your own implementation of this interface using Enums or similar.
 */
contract RBAC {
  using Roles for Roles.Role;

  mapping (string => Roles.Role) private roles;

  event RoleAdded(address indexed operator, string role);
  event RoleRemoved(address indexed operator, string role);

  /**
   * @dev reverts if addr does not have role
   * @param _operator address
   * @param _role the name of the role
   * // reverts
   */
  function checkRole(address _operator, string memory _role)
    public
    view
  {
    roles[_role].check(_operator);
  }

  /**
   * @dev determine if addr has role
   * @param _operator address
   * @param _role the name of the role
   * @return bool
   */
  function hasRole(address _operator, string memory _role)
    public
    view
    returns (bool)
  {
    return roles[_role].has(_operator);
  }

  /**
   * @dev add a role to an address
   * @param _operator address
   * @param _role the name of the role
   */
  function addRole(address _operator, string memory _role)
    internal
  {
    roles[_role].add(_operator);
    emit RoleAdded(_operator, _role);
  }

  /**
   * @dev remove a role from an address
   * @param _operator address
   * @param _role the name of the role
   */
  function removeRole(address _operator, string memory _role)
    internal
  {
    roles[_role].remove(_operator);
    emit RoleRemoved(_operator, _role);
  }

  /**
   * @dev modifier to scope access to a single role (uses msg.sender as addr)
   * @param _role the name of the role
   * // reverts
   */
  modifier onlyRole(string memory _role)
  {
    checkRole(msg.sender, _role);
    _;
  }

  /**
   * @dev modifier to scope access to a set of roles (uses msg.sender as addr)
   * @param _roles the names of the roles to scope access to
   * // reverts
   *
   * @TODO - when solidity supports dynamic arrays as arguments to modifiers, provide this
   *  see: https://github.com/ethereum/solidity/issues/2467
   */
  // modifier onlyRoles(string[] _roles) {
  //     bool hasAnyRole = false;
  //     for (uint8 i = 0; i < _roles.length; i++) {
  //         if (hasRole(msg.sender, _roles[i])) {
  //             hasAnyRole = true;
  //             break;
  //         }
  //     }

  //     require(hasAnyRole);

  //     _;
  // }
}






/**
 * @title Whitelist
 * @dev The Whitelist contract has a whitelist of addresses, and provides basic authorization control functions.
 * This simplifies the implementation of "user permissions".
 */
contract Whitelist is Ownable, RBAC {
  string public constant ROLE_WHITELISTED = "whitelist";


  modifier onlyIfWhitelisted(address _operator) {
    checkRole(_operator, ROLE_WHITELISTED);
    _;
  }


  function addAddressToWhitelist(address _operator)
    public
    onlyOwner
  {
    addRole(_operator, ROLE_WHITELISTED);
  }

  /**
   * @dev getter to determine if address is in whitelist
   */
  function whitelist(address _operator)
    public
    view
    returns (bool)
  {
    return hasRole(_operator, ROLE_WHITELISTED);
  }

  function addAddressesToWhitelist(address[] memory _operators)
    public
    onlyOwner
  {
    for (uint256 i = 0; i < _operators.length; i++) {
      addAddressToWhitelist(_operators[i]);
    }
  }

  function removeAddressFromWhitelist(address _operator)
    public
    onlyOwner
  {
    removeRole(_operator, ROLE_WHITELISTED);
  }

  function removeAddressesFromWhitelist(address[] memory _operators)
    public
    onlyOwner
  {
    for (uint256 i = 0; i < _operators.length; i++) {
      removeAddressFromWhitelist(_operators[i]);
    }
  }

}





/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}





interface ICAAsset {

  function ownerOf(uint256 _tokenId) external view returns (address _owner);
  function exists(uint256 _tokenId) external view returns (bool _exists);
  
  function transferFrom(address _from, address _to, uint256 _tokenId) external;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;
  function safeTransferFrom(address _from , address _to, uint256 _tokenId, bytes memory _data) external;

  function editionOfTokenId(uint256 _tokenId) external view returns (uint256 tokenId);

  function artistCommission(uint256 _tokenId) external view returns (address _artistAccount, uint256 _artistCommission);

  function editionOptionalCommission(uint256 _tokenId) external view returns (uint256 _rate, address _recipient);

  function mint(address _to, uint256 _editionNumber) external returns (uint256);

  function approve(address _to, uint256 _tokenId) external;



  function createActiveEdition(
    uint256 _editionNumber,
    bytes32 _editionData,
    uint256 _editionType,
    uint256 _startDate,
    uint256 _endDate,
    address _artistAccount,
    uint256 _artistCommission,
    uint256 _priceInWei,
    string memory _tokenUri,
    uint256 _totalAvailable
  ) external returns (bool);

  function artistsEditions(address _artistsAccount) external returns (uint256[] memory _editionNumbers);

  function totalAvailableEdition(uint256 _editionNumber) external returns (uint256);

  function highestEditionNumber() external returns (uint256);

  function updateOptionalCommission(uint256 _editionNumber, uint256 _rate, address _recipient) external;

  function updateStartDate(uint256 _editionNumber, uint256 _startDate) external;

  function updateEndDate(uint256 _editionNumber, uint256 _endDate) external;

  function updateEditionType(uint256 _editionNumber, uint256 _editionType) external;
}





interface ICA24Auction {
  function createReserveAuction(
    uint256 tokenId,
    address seller,
    uint256 reservePrice
  ) external;
}





interface ISelfServiceAccessControls {

  function isEnabledForAccount(address account) external view returns (bool);

}





interface ISelfServiceFrequencyControls {

  /*
   * Checks is the given artist can create another edition
   * @param artist - the edition artist
   * @param totalAvailable - the edition size
   * @param priceInWei - the edition price in wei
   */
  function canCreateNewEdition(address artist) external view returns (bool);

  /*
   * Records that an edition has been created
   * @param artist - the edition artist
   * @param totalAvailable - the edition size
   * @param priceInWei - the edition price in wei
   */
  function recordSuccessfulMint(address artist, uint256 totalAvailable, uint256 priceInWei) external returns (bool);
}









// One invocation per time-period
contract EditionCurationMinter is Whitelist, Pausable {

  // Calling address
  ICAAsset public caAsset;
  ICA24Auction public auction;
  ISelfServiceAccessControls public accessControls;
  ISelfServiceFrequencyControls public frequencyControls;

  // Config which enforces editions to not be over this size
  uint256 public maxEditionSize = 100;

  // Config the minimum price per edition
  uint256 public minPricePerEdition = 0; // 0.01 ether;

  /**
   * @dev Construct a new instance of the contract
   */
  constructor(
    ICAAsset _caAsset,
    ICA24Auction _auction,
    ISelfServiceAccessControls _accessControls,
    ISelfServiceFrequencyControls _frequencyControls
  ) {
    super.addAddressToWhitelist(msg.sender);

    caAsset = _caAsset;
    auction = _auction;
    accessControls = _accessControls;
    frequencyControls = _frequencyControls;
  }

  /**
   * @dev Called by artists, create new edition on the CA platform
   */
  function createEditionFor24Auction(
    address _optionalSplitAddress,
    uint256 _optionalSplitRate,
    uint256 _totalAvailable,
    uint256 _priceInWei,
    uint256 _startDate,
    uint256 _endDate,
    uint256 _artistCommission,
    uint256 _editionType,
    string memory _tokenUri
  )
  public
  whenNotPaused
  returns (uint256 _editionNumber, uint _tokenId)
  {
    address artists = msg.sender;

    require(frequencyControls.canCreateNewEdition(artists), "Sender currently frozen out of creation");
    require((_artistCommission + _optionalSplitRate) <= 100, "Total commission exceeds 100");

    _editionNumber = _createEdition(
      artists,
      [_totalAvailable, _priceInWei, _startDate, _endDate, _artistCommission, _editionType],
      _tokenUri
    );

    if (_optionalSplitRate > 0 && _optionalSplitAddress != address(0)) {
      caAsset.updateOptionalCommission(_editionNumber, _optionalSplitRate, _optionalSplitAddress);
    }

    frequencyControls.recordSuccessfulMint(artists, _totalAvailable, _priceInWei);


    _tokenId = caAsset.mint(address(this), _editionNumber);

    caAsset.approve(address(auction), _tokenId);

    auction.createReserveAuction(_tokenId, artists, _priceInWei);

  }

  /**
   * @dev Internal function for edition creation
   */
  function _createEdition(
    address _artist,
    uint256[6] memory _params,
    string memory _tokenUri
  )
  internal
  returns (uint256 _editionNumber) {

    uint256 _totalAvailable = _params[0];
    uint256 _priceInWei = _params[1];

    address owner = owner();

    // Enforce edition size
    require(msg.sender == owner || (_totalAvailable > 0 && _totalAvailable <= maxEditionSize), "Invalid edition size");

    // Enforce min price
    require(msg.sender == owner || _priceInWei >= minPricePerEdition, "Invalid price");

    // If we are the owner, skip this artists check
    require(msg.sender == owner || accessControls.isEnabledForAccount(_artist), "Not allowed to create edition");

    // Find the next edition number we can use
    uint256 editionNumber = getNextAvailableEditionNumber();

    require(
      caAsset.createActiveEdition(
        editionNumber,
        0x0, // _editionData - no edition data
        _params[5], //_editionType,
        _params[2], // _startDate,
        _params[3], //_endDate,
        _artist,
        _params[4], // _artistCommission - defaults to artistCommission if optional commission split missing
        _priceInWei,
        _tokenUri,
        _totalAvailable
      ),
      "Failed to create new edition"
    );


    return editionNumber;
  }

  /**
   * @dev Internal function for dynamically generating the next KODA edition number
   */
  function getNextAvailableEditionNumber() internal returns (uint256 editionNumber) {

    // Get current highest edition and total in the edition
    uint256 highestEditionNumber = caAsset.highestEditionNumber();
    uint256 totalAvailableEdition = caAsset.totalAvailableEdition(highestEditionNumber);

    // Add the current highest plus its total, plus 1 as tokens start at 1 not zero
    uint256 nextAvailableEditionNumber = highestEditionNumber + totalAvailableEdition + 1;

    // Round up to next 100, 1000 etc based on max allowed size
    return ((nextAvailableEditionNumber + maxEditionSize - 1) / maxEditionSize) * maxEditionSize;
  }

  /**
   * @dev Sets the KODA address
   * @dev Only callable from owner
   */
  function setCAAsset(ICAAsset _caAsset) onlyIfWhitelisted(msg.sender) public {
    caAsset = _caAsset;
  }

  /**
   * @dev Sets the KODA auction
   * @dev Only callable from owner
   */
  function setAuction(ICA24Auction _auction) onlyIfWhitelisted(msg.sender) public {
    auction = _auction;
  }

  /**
   * @dev Sets the max edition size
   * @dev Only callable from owner
   */
  function setMaxEditionSize(uint256 _maxEditionSize) onlyIfWhitelisted(msg.sender) public {
    maxEditionSize = _maxEditionSize;
  }

  /**
   * @dev Sets minimum price per edition
   * @dev Only callable from owner
   */
  function setMinPricePerEdition(uint256 _minPricePerEdition) onlyIfWhitelisted(msg.sender) public {
    minPricePerEdition = _minPricePerEdition;
  }

  /**
   * @dev Checks to see if the account is currently frozen out
   */
  function isFrozen(address account) public view returns (bool) {
    return frequencyControls.canCreateNewEdition(account);
  }

  /**
   * @dev Checks to see if the account can create editions
   */
  function isEnabledForAccount(address account) public view returns (bool) {
    return accessControls.isEnabledForAccount(account);
  }

  /**
   * @dev Checks to see if the account can create editions
   */
  function canCreateAnotherEdition(address account) public view returns (bool) {
    if (!accessControls.isEnabledForAccount(account)) {
      return false;
    }
    return frequencyControls.canCreateNewEdition(account);
  }

  /**
   * @dev Allows for the ability to extract stuck ether
   * @dev Only callable from owner
   */
  function withdrawStuckEther(address _withdrawalAccount) onlyIfWhitelisted(msg.sender) public {
    require(_withdrawalAccount != address(0), "Invalid address provided");
    payable(_withdrawalAccount).transfer(address(this).balance);
  }
}