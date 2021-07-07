/**
 *Submitted for verification at BscScan.com on 2021-07-07
*/

// Sources flattened with hardhat v2.0.8 https://hardhat.org

// File openzeppelin-solidity/contracts/utils/[email protected]

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
      this; // silence state mutability warning without generating bytecode 
      //- see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


abstract contract BaseRelayRecipient is Context {
    address public _trustedForwarder;

    function isTrustedForwarder(address forwarder) public view virtual returns(bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            assembly { sender := shr(96, calldataload(sub(calldatasize(), 20))) }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length-20];
        } else {
            return super._msgData();
        }
    }
}


contract Registry is BaseRelayRecipient {  
  event Registered(address indexed who, string name);

  mapping(address => string) public names;
  mapping(string => address) public owners;

  constructor(address forwarder) {
    _trustedForwarder = forwarder;
  }

  function register(string memory name) external {
    require(owners[name] == address(0), "Name taken");
    address owner = _msgSender(); // Changed from msg.sender
    owners[name] = owner;
    names[owner] = name;
    emit Registered(owner, name);
  }
  
  function getOwner(string memory name) external returns(address) {
      return owners[name];
  }

  function getNames(address addr) external returns(string memory) {
    return names[addr];
  }
  
  function setTrustedForwarder(address forwarderAddress) public {
    _trustedForwarder = forwarderAddress;
  }
  
  function getTurstedForwarder() public returns(address) {
    return _trustedForwarder;
  }
 }


contract SimpleRegistry {  
  event Registered(address indexed who, string name);

  mapping(address => string) public names;
  mapping(string => address) public owners;

  function register(string memory name) external {
    require(owners[name] == address(0), "Name taken");
    address owner = msg.sender;
    owners[name] = owner;
    names[owner] = name;
    emit Registered(owner, name);
  }
}