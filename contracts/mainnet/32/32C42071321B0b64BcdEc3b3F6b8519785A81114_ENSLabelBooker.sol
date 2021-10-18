pragma solidity >=0.8.4;

interface ENS {

    // Logged when the owner of a node assigns a new owner to a subnode.
    event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

    // Logged when the owner of a node transfers ownership to a new account.
    event Transfer(bytes32 indexed node, address owner);

    // Logged when the resolver for a node changes.
    event NewResolver(bytes32 indexed node, address resolver);

    // Logged when the TTL of a node changes
    event NewTTL(bytes32 indexed node, uint64 ttl);

    // Logged when an operator is added or removed.
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function setRecord(bytes32 node, address owner, address resolver, uint64 ttl) external virtual;
    function setSubnodeRecord(bytes32 node, bytes32 label, address owner, address resolver, uint64 ttl) external virtual;
    function setSubnodeOwner(bytes32 node, bytes32 label, address owner) external virtual returns(bytes32);
    function setResolver(bytes32 node, address resolver) external virtual;
    function setOwner(bytes32 node, address owner) external virtual;
    function setTTL(bytes32 node, uint64 ttl) external virtual;
    function setApprovalForAll(address operator, bool approved) external virtual;
    function owner(bytes32 node) external virtual view returns (address);
    function resolver(bytes32 node) external virtual view returns (address);
    function ttl(bytes32 node) external virtual view returns (uint64);
    function recordExists(bytes32 node) external virtual view returns (bool);
    function isApprovedForAll(address owner, address operator) external virtual view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

pragma solidity >=0.8.4;

import '@ensdomains/ens-contracts/contracts/registry/ENS.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import {IENSLabelBooker} from './interfaces/IENSLabelBooker.sol';

contract ENSLabelBooker is Ownable, IENSLabelBooker {
  ENS public immutable ENS_REGISTRY;
  bytes32 public immutable ROOT_NODE;
  address public _registrar;

  mapping(bytes32 => address) private _bookings;

  modifier onlyOwnerOrRegistrar() {
    require(
      owner() == _msgSender() || _registrar == _msgSender(),
      'ENS_LABEL_BOOKER: CALL_NOT_AUTHORIZED'
    );
    _;
  }

  /**
   * @dev Constructor.
   * @param ensAddr The address of the ENS registry.
   * @param node The node that this registrar administers.
   */
  constructor(
    ENS ensAddr,
    bytes32 node,
    address owner
  ) {
    ENS_REGISTRY = ensAddr;
    ROOT_NODE = node;
    transferOwnership(owner);
  }

  /**
   * @notice Get the address of a booking.
   *         The zero address means the booking does not exist.
   * @param label The booked label.
   * @return The address associated to the booking.
   */
  function getBooking(string memory label)
    external
    view
    override
    returns (address)
  {
    bytes32 labelHash = keccak256(bytes(label));
    return _getBooking(labelHash);
  }

  /**
   * @notice Book a label with an address for a later claim.
   * @dev Can only be called by the contract owner or the registrar.
   * @param label The label to book.
   * @param bookingAddress The address which can claim the label.
   */
  function book(string memory label, address bookingAddress)
    external
    override
    onlyOwnerOrRegistrar
  {
    bytes32 labelHash = keccak256(bytes(label));
    _book(labelHash, bookingAddress);
  }

  /**
   * @notice Batch book operations given a list of labels and bookingAddresses.
   * @dev Can only be called by the contract owner or the registrar.
   *      Input lists must have the same length.
   * @param labels The list of label to book.
   * @param bookingAddresses The list of address which can claim the associated label.
   */
  function batchBook(string[] memory labels, address[] memory bookingAddresses)
    external
    override
    onlyOwnerOrRegistrar
  {
    require(
      labels.length == bookingAddresses.length,
      'ENS_LABEL_BOOKER: INVALID_PARAMS'
    );
    for (uint256 i; i < labels.length; i++) {
      bytes32 labelHash = keccak256(bytes(labels[i]));
      _book(labelHash, bookingAddresses[i]);
    }
  }

  /**
   * @notice Update the address of a book address.
   * @dev Can only be called by the contract owner or the registrar.
   * @param label The label of the book.
   * @param bookingAddress The address which can claim the label.
   */
  function updateBooking(string memory label, address bookingAddress)
    external
    override
    onlyOwnerOrRegistrar
  {
    bytes32 labelHash = keccak256(bytes(label));
    _updateBooking(labelHash, bookingAddress);
  }

  /**
   * @notice Update the addresses of books.
   * @dev Can only be called by the contract owner or the registrar.
   *      Input lists must have the same length.
   * @param labels The list of label to book.
   * @param bookingAddresses The list of address which can claim the associated label.
   */
  function batchUpdateBooking(
    string[] memory labels,
    address[] memory bookingAddresses
  ) external override onlyOwner {
    require(
      labels.length == bookingAddresses.length,
      'ENS_LABEL_BOOKER: INVALID_PARAMS'
    );
    for (uint256 i; i < labels.length; i++) {
      bytes32 labelHash = keccak256(bytes(labels[i]));
      _updateBooking(labelHash, bookingAddresses[i]);
    }
  }

  /**
   * @notice Delete a booking.
   * @dev Can only be called by the contract owner or the registrar.
   * @param label The booked label.
   */
  function deleteBooking(string memory label)
    external
    override
    onlyOwnerOrRegistrar
  {
    bytes32 labelHash = keccak256(bytes(label));
    _deleteBooking(labelHash);
  }

  /**
   * @notice Delete a list of bookings.
   * @dev Can only be called by the contract owner or the registrar.
   * @param labels The list of labels of the bookings.
   */
  function batchDeleteBooking(string[] memory labels)
    external
    override
    onlyOwnerOrRegistrar
  {
    for (uint256 i; i < labels.length; i++) {
      bytes32 labelHash = keccak256(bytes(labels[i]));
      _deleteBooking(labelHash);
    }
  }

  /**
   * @notice Delete a list of bookings.
   * @dev Can only be called by the contract owner.
   * @param registrar The new registrar that uses this contract as labelBooker Lib
   */
  function setRegistrar(address registrar) external override onlyOwner {
    _registrar = registrar;
    emit NewRegistrar(registrar);
  }

  /**
   * @dev Get the address of a booking.
   * @param labelHash The hash of the label associated to the booking.
   * @return The address associated to the booking.
   */
  function _getBooking(bytes32 labelHash) internal view returns (address) {
    return _bookings[labelHash];
  }

  /**
   * @dev Delete a booking
   * @param labelHash The hash of the label associated to the booking.
   */
  function _deleteBooking(bytes32 labelHash) internal {
    bytes32 childNode = keccak256(abi.encodePacked(ROOT_NODE, labelHash));
    _bookings[labelHash] = address(0);
    emit BookingDeleted(uint256(childNode));
  }

  /**
   * @dev Create a booking
   * @param labelHash The hash of the label associated to the booking.
   * @param bookingAddress The address associated to the booking.
   */
  function _book(bytes32 labelHash, address bookingAddress) internal {
    require(
      bookingAddress != address(0),
      'ENS_LABEL_BOOKER: INVALID_BOOKING_ADDRESS'
    );
    require(
      _bookings[labelHash] == address(0),
      'ENS_LABEL_BOOKER: LABEL_ALREADY_BOOKED'
    );
    address subdomainOwner = ENS_REGISTRY.owner(
      keccak256(abi.encodePacked(ROOT_NODE, labelHash))
    );
    require(
      subdomainOwner == address(0x0),
      'ENS_LABEL_BOOKER: SUBDOMAINS_ALREADY_REGISTERED'
    );
    bytes32 childNode = keccak256(abi.encodePacked(ROOT_NODE, labelHash));
    _bookings[labelHash] = bookingAddress;
    emit NameBooked(uint256(childNode), bookingAddress);
  }

  /**
   * @dev Update the address of a booking
   * @param labelHash The hash of the label associated to the booking.
   * @param bookingAddress The new address associated to the booking.
   */
  function _updateBooking(bytes32 labelHash, address bookingAddress) internal {
    require(bookingAddress != address(0), 'ENS_LABEL_BOOKER: INVALID_ADDRESS');
    require(
      _bookings[labelHash] != address(0),
      'ENS_LABEL_BOOKER: LABEL_NOT_BOOKED'
    );
    bytes32 childNode = keccak256(abi.encodePacked(ROOT_NODE, labelHash));
    _bookings[labelHash] = bookingAddress;
    emit BookingUpdated(uint256(childNode), bookingAddress);
  }
}

pragma solidity >=0.8.4;

interface IENSLabelBooker {
  // Logged when a booking is created.
  event NameBooked(uint256 indexed id, address indexed bookingAddress);
  // Logged when a booking is updated.
  event BookingUpdated(uint256 indexed id, address indexed bookingAddress);
  // Logged when a booking is deleted.
  event BookingDeleted(uint256 indexed id);
  event NewRegistrar(address indexed registrar);

  /**
   * @notice Get the address of a booking.
   * @param label The booked label.
   * @return The address associated to the booking
   */
  function getBooking(string memory label) external view returns (address);

  /**
   * @notice Book a name.
   * @param label The label to book.
   * @param bookingAddress The address associated to the booking.
   *
   * Emits a {NameBooked} event.
   */
  function book(string memory label, address bookingAddress) external;

  /**
   * @notice Books a list of names.
   * @param labels The list of label to book.
   * @param bookingAddresses The list of addresses associated to the bookings.
   *
   * Emits a {NameBooked} event for each booking.
   */
  function batchBook(string[] memory labels, address[] memory bookingAddresses)
    external;

  /**
   * @notice Update a booking.
   * @param label The booked label.
   * @param bookingAddress The new address associated to the booking.
   *
   * Emits a {BookingUpdated} event.
   */
  function updateBooking(string memory label, address bookingAddress) external;

  /**
   * @notice Update a list of bookings.
   * @param labels The list of labels of the bookings.
   * @param bookingAddresses The list of new addresses associated to the bookings.
   *
   * Emits a {BookingUpdated} event for each updated booking.
   */
  function batchUpdateBooking(
    string[] memory labels,
    address[] memory bookingAddresses
  ) external;

  /**
   * @notice Delete a booking.
   * @param label The booked label.
   *
   * Emits a {BookingDeleted} event.
   */
  function deleteBooking(string memory label) external;

  /**
   * @notice Delete a list of bookings.
   * @param labels The list of labels of the bookings.
   *
   * Emits a {BookingDeleted} event for each deleted booking.
   */
  function batchDeleteBooking(string[] memory labels) external;

  /**
   * @notice Set the registrar, that can use this lib.
   * @param registrar the newt registrar.
   *
   * Emits a {NewRegistrar} event
   */
  function setRegistrar(address registrar) external;
}