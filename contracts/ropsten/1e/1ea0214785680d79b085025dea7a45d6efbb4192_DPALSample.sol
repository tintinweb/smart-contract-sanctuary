/**
 *Submitted for verification at Etherscan.io on 2021-11-22
*/

// File: @openzeppelin/contracts/utils/Context.sol

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

// File: @openzeppelin/contracts/access/Ownable.sol


pragma solidity ^0.8.0;


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

// File: contracts/Sample.sol

pragma solidity ^0.8.0;


contract Sample is Ownable {
  uint public id;
  bytes32 hash;
  string data;
  string dataExtended;

  constructor(uint _id) {
    id = _id;
    emit SampleCreated(id, address(this));
  }

  event SampleCreated(
    uint indexed id,
    address indexed addr
  );

  event SampleUpdated(
    uint id,
    bytes32 indexed hash,
    string data,
    string dataExtended
  );

  function update (
    bytes32 _hash,
    string calldata _data,
    string calldata _dataExtended
  )
    external
    payable
    onlyOwner
  {
    hash = _hash;
    data = _data;
    dataExtended = _dataExtended;

    emit SampleUpdated(id, hash, data, dataExtended);
  }
}

// File: contracts/DPALSample.sol

pragma solidity ^0.8.0;



contract DPALSample is Ownable {

  struct SampleInstance {
    uint id;
    address addr;
    bool verified;
  }

  mapping (uint => SampleInstance) public samples;

  event LogEntryReceived(
    uint indexed id,
    bytes32 indexed hash,
    string data,
    string dataExtended
  );

  // Stores a new value in the contract
  function store (
    uint id,
    bytes32 hash,
    string calldata data,
    string calldata dataExtended
  )
    external
    payable
    onlyOwner
  {
    require(hash.length == 32, "Invalid hash");

    emit LogEntryReceived(id, hash, data, dataExtended);

    Sample sample;
    if (samples[id].verified) {
      sample = Sample(address(samples[id].addr));
    } else {
      sample = new Sample(id);
      samples[id].addr = address(sample);
      samples[id].verified = true;
    }
    sample.update(hash, data, dataExtended);
  }
}