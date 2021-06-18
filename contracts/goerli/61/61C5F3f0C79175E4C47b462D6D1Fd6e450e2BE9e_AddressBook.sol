/**
 *Submitted for verification at Etherscan.io on 2021-06-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

  function setRecord(bytes32 node, address owner, address resolver, uint64 ttl) external;
  function setSubnodeRecord(bytes32 node, bytes32 label, address owner, address resolver, uint64 ttl) external;
  function setSubnodeOwner(bytes32 node, bytes32 label, address owner) external returns(bytes32);
  function setResolver(bytes32 node, address resolver) external;
  function setOwner(bytes32 node, address owner) external;
  function setTTL(bytes32 node, uint64 ttl) external;
  function setApprovalForAll(address operator, bool approved) external;
  function owner(bytes32 node) external view returns (address);
  function resolver(bytes32 node) external view returns (address);
  function ttl(bytes32 node) external view returns (uint64);
  function recordExists(bytes32 node) external view returns (bool);
  function isApprovedForAll(address owner, address operator) external view returns (bool);
}

interface ENSResolver {
  function addr(bytes32 node) external view returns (address);
  event AddrChanged(bytes32 indexed node, address a);
  function supportsInterface(bytes4 interfaceID) external pure returns (bool);
}

interface AddressVerifier {
  function isAddressValid(bytes calldata addr) external view returns (bool);
}

contract AddressBook {
  ENS constant registry = ENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);
  bytes4 constant ERC165ID = 0x01ffc9a7;
  bytes4 constant AddressVerifyID = 0xde2b83e2;

  // on chain address book
  // address -> l2 contract address -> user l2 address
  mapping(address => mapping(address => bytes)) book;

  /**
   * @dev When resolving and L2 ENS address of chain the current owner must be
   * compared to the emitted ownerAddr
   **/
  event L2AddrChanged(address indexed ownerAddr, address indexed contractAddr, bytes l2Addr);

  /**
   * @dev Register an L2 address for an Ethereum address.
   * @param contractAddr The L2 contract address
   * @param l2Addr The L2 address of the caller
   * @param onChain Whether to store the address on chain or only in calldata
   **/
  function registerAddress(address contractAddr, bytes calldata l2Addr, bool onChain) public {
    emit L2AddrChanged(msg.sender, contractAddr, l2Addr);
    if (onChain) {
      book[msg.sender][contractAddr] = l2Addr;
    } else if (book[msg.sender][contractAddr].length != 0) {
      book[msg.sender][contractAddr] = new bytes(0);
    }
  }

  /**
   * @dev Function for registering an address for a specific L2 network to an
   * ENS domain name.
   * @param name The hashed domain name (using namehash)
   * @param contractAddr The address of the L2 contract
   * @param l2Addr The L2 address of the caller (represented as a 256 bit integer)
   * @param onChain A boolean indicating whether the address should be stored on chain
   **/
  function registerName(bytes32 name, address contractAddr, bytes calldata l2Addr, bool onChain) public {
    address registeredAddr = resolveENS(name);
    require(registeredAddr != address(0), 'Name resolved to 0x0 address');
    require(registeredAddr == msg.sender, 'Name can only be bound by owner');
    emit L2AddrChanged(registeredAddr, contractAddr, l2Addr);
    (uint success, uint result) = safeSupportsInterface(contractAddr, AddressVerifyID);
    if (success == 1 && result == 1) {
      // the l2 contract supports address verification
      require(
        AddressVerifier(contractAddr).isAddressValid(l2Addr),
        'Address is invalid'
      );
    }
    if (onChain) {
      // store it in the local address book
      book[registeredAddr][contractAddr] = l2Addr;
    } else if (book[msg.sender][contractAddr].length != 0) {
      // reset if it's set to something else
      book[registeredAddr][contractAddr] = new bytes(0);
    }
    // otherwise the addressbook is up to date
  }

  /**
   * @dev Resolve the latest on-chain address for an ENS domain
   * @param name The 32 byte ENS node hash
   * @param contractAddr The L2 contract address to resolve for
   **/
  function resolveName(bytes32 name, address contractAddr) public view returns (bytes memory) {
    address resolvedAddr = resolveENS(name);
    return resolveAddress(resolvedAddr, contractAddr);
  }

  function resolveAddress(address owner, address contractAddr) public view returns (bytes memory) {
    return book[owner][contractAddr];
  }

  function resolveAddress(address contractAddr) public view returns (bytes memory) {
    return resolveAddress(msg.sender, contractAddr);
  }

  function resolveENS(bytes32 name) public view returns (address) {
    address resolverAddr = registry.resolver(name);
    require(resolverAddr != address(0), 'No resolver specified');
    ENSResolver resolver = ENSResolver(resolverAddr);
    require(resolver.supportsInterface(0x3b3b57de), 'Resolver does not support address resolution');
    return resolver.addr(name);
  }

  /**
   * @dev Check if a contract supports ERC165 and a specific interface
   * @param _contract The contract to check
   * @param interfaceID The interface ID to check for
   **/
  function safeSupportsInterface(address _contract, bytes4 interfaceID) internal view returns (uint success, uint result) {
    assembly {
      let x := mload(0x40)
      mstore(x, ERC165ID)
      mstore(add(x, 0x04), interfaceID)

      success := staticcall(
        30000,
        _contract,
        x,
        0x24,
        x,
        0x20
      )
      result := mload(x)
    }
  }
}