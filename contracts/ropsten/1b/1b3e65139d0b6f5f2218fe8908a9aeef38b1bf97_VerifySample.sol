/**
 *Submitted for verification at Etherscan.io on 2021-12-21
*/

// File: @openzeppelin/contracts/utils/Context.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

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
    constructor() public {
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

contract Sample is Ownable {
  uint public id;
  bytes32 public hash;
  string public data;

  constructor(uint _id, bytes32 _hash) public {
    id = _id;
    hash = _hash;
    // emit SampleCreated(id, hash, address(this));
  }

  event EventReceived(
    uint indexed id,
    bytes32 indexed hash,
    string data
  );
  
  event SampleCreated(
    uint indexed id,
    bytes32 hash,
    address addr
  );

  event SampleUpdated(
    uint indexed id,
    bytes32 hash,
    string data
  );

  function update (
    bytes32 _hash,
    string calldata _data
  )
    external
    payable
    onlyOwner
  {
    hash = _hash;
    data = _data;

    emit EventReceived(id, hash, data);
    emit SampleUpdated(id, hash, data);
  }
}

// File: contracts/VerifySample.sol

contract VerifySample is Ownable {

  mapping (uint => address) public samples;

  // Stores a new value in the contract
  function store (
    uint id,
    bytes32 hash,
    string calldata data
  )
    external
    payable
    onlyOwner
  {
    require(hash.length == 32, "Invalid hash");

    Sample sample;
    if (samples[id] != address(0)) {
      sample = Sample(address(samples[id]));
    } else {
      sample = new Sample(id, hash);
      samples[id] = address(sample);
    }
    sample.update(hash, data);
  }
}