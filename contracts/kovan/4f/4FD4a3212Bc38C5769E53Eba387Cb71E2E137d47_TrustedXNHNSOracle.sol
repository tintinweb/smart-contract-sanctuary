pragma solidity ^0.7.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../../interfaces/IXNHNSOracle.sol";

/**
 * @dev Fake oracle for testing HNSRegistrar
 */
contract TrustedXNHNSOracle is IXNHNSOracle, Ownable {
    string public NAMESPACE;

    // tld namehash -> owner adddres on HNS
    mapping(bytes32 => address) public tldOwners;
    // contracts that are allowed to initiate oracle requests
    mapping(address => bool) private allowedCallers;

    constructor(string memory _namespace) {
      NAMESPACE = _namespace;
    }

    function requestTLDUpdate(string calldata tld)
      external
      override
      returns (bytes32)
    {
      require(bytes(tld).length > 0, 'Invalid TLD');
      require(allowedCallers[msg.sender], 'Caller does not have permission to initiate oracle requests');
      bytes32 node = _getNamehash(tld);
      tldOwners[node] = tx.origin;
      emit NewOwner(_getNamehash(tld), tx.origin);
      return node;
    }

    function receiveTLDUpdate(bytes32 node, address owner_)
      external
      override
      onlyOwner returns (bool)
    {
      tldOwners[node] = owner_;
      emit NewOwner(node, owner_);
      return true;
    }

    function setOracle(address oracle, uint fee, bytes32 jobId)
      external override
      returns (bool)
    {
      return true;
    }

    function getTLDOwner(bytes32 node)
      external view
      override
      returns (address)
    {
      return tldOwners[node];
    }

    function setCallerPermission(address addr, bool permission)
      external
      override
      onlyOwner
      returns (bool)
    {
      return allowedCallers[addr] = permission;
    }
    function getCallerPermission(address addr) external view override returns (bool) {
      return allowedCallers[addr];
    }

    function _getNamehash(string memory tld) internal pure returns (bytes32) {
      return keccak256(abi.encodePacked(bytes32(0), keccak256(abi.encodePacked(tld))));
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity ^0.7.0;

interface IXNHNSOracle {
  event NewOracle(address oracle);
  // NewOwner event identical to IENS.sol
  event NewOwner(bytes32 indexed node, address owner);

  function requestTLDUpdate(string calldata tld) external returns (bytes32);
  function receiveTLDUpdate(bytes32, address) external returns (bool);
  function getTLDOwner(bytes32 node) external returns (address);
  function getCallerPermission(address addr) external returns (bool);
  function setCallerPermission(address addr, bool permission) external returns (bool);
  function setOracle(address oracle, uint fee, bytes32 jobId) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}