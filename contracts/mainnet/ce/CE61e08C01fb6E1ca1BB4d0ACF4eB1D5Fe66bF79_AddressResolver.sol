// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../GSN/Context.sol";
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
contract Ownable is Context {
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
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interface/IAddressResolver.sol";

/**
@notice Obtain different contract addresses based on different bytes32(name)
 */
contract AddressResolver is Ownable, IAddressResolver {
    mapping(bytes32 => address) public override key2address;
    mapping(address => bytes32) public override address2key;

    mapping(bytes32 =>mapping(bytes32 => address)) public override kk2addr;

    function setAddress(bytes32 key, address addr) public override onlyOwner {
        key2address[key] = addr;
        address2key[addr] = key;
    }

    function setMultiAddress(bytes32[] memory keys, address[] memory addrs) external override onlyOwner {
        require(keys.length == addrs.length, "AddressResolver::setMultiAddress:parameter number not match");
        for (uint i=0; i < keys.length; i++) {
            key2address[keys[i]] = addrs[i];
            address2key[addrs[i]] = keys[i];
        }
    }

    function requireAndKey2Address(bytes32 name, string calldata reason) external view override returns(address) {
        address addr = key2address[name];
        require(addr != address(0), reason);
        return addr;
    }

    function setKkAddr(bytes32 k1, bytes32 k2, address addr) public override onlyOwner {
        kk2addr[k1][k2] = addr;
    } 

    function setMultiKKAddr(bytes32[] memory k1s, bytes32[] memory k2s, address[] memory addrs) external override onlyOwner {
        require(k1s.length == k1s.length, "AddressResolver::setMultiKKAddr::parameter key number not match");
        require(k1s.length == addrs.length, "AddressResolver::setMultiKKAddr::parameter key addrs number not match");
        for (uint i=0; i < k1s.length; i++) {
            kk2addr[k1s[i]][k2s[i]] = addrs[i];
        }
    }

    function requireKKAddrs(bytes32 k1, bytes32 k2, string calldata reason) external view override returns(address) {
        address addr = kk2addr[k1][k2];
        require(addr != address(0), reason);
        return addr;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface IAddressResolver {
    
    function key2address(bytes32 key) external view returns(address);
    function address2key(address addr) external view returns(bytes32);
    function requireAndKey2Address(bytes32 name, string calldata reason) external view returns(address);

    function setAddress(bytes32 key, address addr) external;
    function setMultiAddress(bytes32[] memory keys, address[] memory addrs) external;
    
    function setKkAddr(bytes32 k1, bytes32 k2, address addr) external;
    function setMultiKKAddr(bytes32[] memory k1s, bytes32[] memory k2s, address[] memory addrs) external;

    function kk2addr(bytes32 k1, bytes32 k2) external view returns(address);
    function requireKKAddrs(bytes32 k1, bytes32 k2, string calldata reason) external view returns(address);
}

{
  "evmVersion": "istanbul",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "remappings": [],
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}