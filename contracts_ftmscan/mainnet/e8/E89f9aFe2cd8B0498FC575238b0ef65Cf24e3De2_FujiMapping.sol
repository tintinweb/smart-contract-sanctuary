// SPDX-License-Identifier: MIT
//FujiMapping for two addresses
pragma solidity ^0.8.0;

import "./abstracts/claimable/Claimable.sol";
import "./interfaces/IFujiMappings.sol";

/**
 * @dev Contract that stores and returns addresses mappings
 * Required for getting contract addresses for some providers and flashloan providers
 */

contract FujiMapping is IFujiMappings, Claimable {
  // Address 1 =>  Address 2 (e.g. erc20 => cToken, contract a L1 => contract b L2, etc)
  mapping(address => address) public override addressMapping;

  // URI that contains mapping information
  string public uri;

  /**
   * @dev Adds a two address Mapping
   * @param _addr1: key address for mapping (erc20, provider)
   * @param _addr2: result address (cToken, erc20)
   */
  function setMapping(address _addr1, address _addr2) public onlyOwner {
    addressMapping[_addr1] = _addr2;
    emit MappingChanged(_addr1, _addr2);
  }

  /**
   * @dev Sets a new URI
   * Emits a {UriChanged} event.
   */
  function setURI(string memory newUri) public onlyOwner {
    uri = newUri;
    emit UriChanged(newUri);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @dev Abstract contract that implements a modified version of  Openzeppelin {Ownable.sol} contract.
 * It creates a two step process for the transfer of ownership.
 */

abstract contract Claimable is Context {
  address private _owner;

  address public pendingOwner;

  // Claimable Events

  /**
   * @dev Emits when step two in ownership transfer is completed.
   */
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  /**
   * @dev Emits when step one in ownership transfer is initiated.
   */
  event NewPendingOwner(address indexed owner);

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor() {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
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
    require(_msgSender() == owner(), "Ownable: caller is not the owner");
    _;
  }

  /**
   * @dev Throws if called by any account other than the pendingOwner.
   */
  modifier onlyPendingOwner() {
    require(_msgSender() == pendingOwner);
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
    emit OwnershipTransferred(owner(), address(0));
    _owner = address(0);
  }

  /**
   * @dev Step one of ownership transfer.
   * Initiates transfer of ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   *
   * NOTE:`newOwner` requires to claim ownership in order to be able to call
   * {onlyOwner} modified functions.
   */
  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), "Cannot pass zero address!");
    require(pendingOwner == address(0), "There is a pending owner!");
    pendingOwner = newOwner;
    emit NewPendingOwner(newOwner);
  }

  /**
   * @dev Cancels the transfer of ownership of the contract.
   * Can only be called by the current owner.
   */
  function cancelTransferOwnership() public onlyOwner {
    require(pendingOwner != address(0));
    delete pendingOwner;
    emit NewPendingOwner(address(0));
  }

  /**
   * @dev Step two of ownership transfer.
   * 'pendingOwner' claims ownership of the contract.
   * Can only be called by the pending owner.
   */
  function claimOwnership() public onlyPendingOwner {
    emit OwnershipTransferred(owner(), pendingOwner);
    _owner = pendingOwner;
    delete pendingOwner;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IFujiMappings {
  // FujiMapping Events

  /**
   * @dev Log a change in address mapping
   */
  event MappingChanged(address keyAddress, address mappedAddress);
  /**
   * @dev Log a change in URI
   */
  event UriChanged(string newUri);

  function addressMapping(address) external view returns (address);
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