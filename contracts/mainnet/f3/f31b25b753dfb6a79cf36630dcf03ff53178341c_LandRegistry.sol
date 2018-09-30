/**
 * Copyright (c) 2018 blockimmo AG <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="55393c36303b26301537393a363e3c38383a7b363d">[email&#160;protected]</a>
 * Non-Profit Open Software License 3.0 (NPOSL-3.0)
 * https://opensource.org/licenses/NPOSL-3.0
 */


pragma solidity 0.4.25;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
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
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}


/**
 * @title Claimable
 * @dev Extension for the Ownable contract, where the ownership needs to be claimed.
 * This allows the new owner to accept the transfer.
 */
contract Claimable is Ownable {
  address public pendingOwner;

  /**
   * @dev Modifier throws if called by any account other than the pendingOwner.
   */
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

  /**
   * @dev Allows the current owner to set the pendingOwner address.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    pendingOwner = newOwner;
  }

  /**
   * @dev Allows the pendingOwner address to finalize the transfer.
   */
  function claimOwnership() public onlyPendingOwner {
    emit OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }
}


/**
 * @title LandRegistry
 * @dev A minimal, simple database mapping properties to their on-chain representation (`TokenizedProperty`).
 *
 * The purpose of this contract is not to be official or replace the existing (off-chain) land registry.
 * Its purpose is to map entries in the official registry to their on-chain representation.
 * This mapping / bridging process is enabled by our legal framework, which works in-sync with and relies on this database.
 *
 * `this.landRegistry` is the single source of truth for on-chain properties verified legitimate by blockimmo.
 * Any property not indexed in `this.landRegistry` is NOT verified legitimate by blockimmo.
 *
 * `TokenizedProperty` references `this` to only allow tokens of verified properties to be transferred.
 * Any (unmodified) `TokenizedProperty`&#39;s tokens will be transferable if and only if it is indexed in `this.landRegistry` (otherwise locked).
 *
 * `LandRegistryProxy` enables `this` to be easily and reliably upgraded if absolutely necessary.
 * `LandRegistryProxy` and `this` are controlled by a centralized entity.
 * This centralization provides an extra layer of control / security until our contracts are time and battle tested.
 * We intend to work towards full decentralization in small, precise, confident steps by transferring ownership
 * of these contracts when appropriate and necessary.
 */
contract LandRegistry is Claimable {
  mapping(string => address) private landRegistry;

  event Tokenized(string eGrid, address indexed property);
  event Untokenized(string eGrid, address indexed property);

  /**
   * this function&#39;s abi should never change and always maintain backwards compatibility
   */
  function getProperty(string _eGrid) public view returns (address property) {
    property = landRegistry[_eGrid];
  }

  function tokenizeProperty(string _eGrid, address _property) public onlyOwner {
    require(bytes(_eGrid).length > 0, "eGrid must be non-empty string");
    require(_property != address(0), "property address must be non-null");
    require(landRegistry[_eGrid] == address(0), "property must not already exist in land registry");

    landRegistry[_eGrid] = _property;
    emit Tokenized(_eGrid, _property);
  }

  function untokenizeProperty(string _eGrid) public onlyOwner {
    address property = getProperty(_eGrid);
    require(property != address(0), "property must exist in land registry");

    landRegistry[_eGrid] = address(0);
    emit Untokenized(_eGrid, property);
  }
}