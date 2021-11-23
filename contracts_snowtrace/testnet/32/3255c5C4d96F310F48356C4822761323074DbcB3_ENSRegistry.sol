// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

/**
 * @title ENS registry
 *
 * @dev Base on https://github.com/ensdomains/ens/blob/ff0f41747c05f1598973b0fe7ad0d9e09565dfcd/contracts/ENSRegistry.sol
 */
contract ENSRegistry {
  struct Record {
    address owner;
    address resolver;
    uint64 ttl;
  }

  mapping (bytes32 => Record) private records;
  mapping (address => mapping(address => bool)) private operators;

  // events

  event NewOwner(
    bytes32 indexed node,
    bytes32 indexed label,
    address owner
  );

  event Transfer(
    bytes32 indexed node,
    address owner
  );

  event NewResolver(
    bytes32 indexed node,
    address resolver
  );

  event NewTTL(
    bytes32 indexed node,
    uint64 ttl
  );

  event ApprovalForAll(
    address indexed owner,
    address indexed operator,
    bool approved
  );

  // modifiers

  modifier authorised(
    bytes32 node
  )
  {
    address owner = records[node].owner;

    require(
      owner == msg.sender || operators[owner][msg.sender],
      "ENSRegistry: reverted by authorised modifier"
    );

    _;
  }

  /**
   * @dev Public constructor
   */
  constructor()
    public
  {
    // solhint-disable-next-line avoid-tx-origin
    records[0x0].owner = tx.origin;
  }

  // external functions

  function setRecord(
    bytes32 node,
    address owner_,
    address resolver_,
    uint64 ttl_
  )
    external
  {
    setOwner(node, owner_);

    _setResolverAndTTL(node, resolver_, ttl_);
  }

  function setTTL(
    bytes32 node,
    uint64 ttl_
  )
    external
    authorised(node)
  {
    records[node].ttl = ttl_;

    emit NewTTL(node, ttl_);
  }

  function setSubnodeRecord(
    bytes32 node,
    bytes32 label,
    address owner_,
    address resolver_,
    uint64 ttl_
  )
    external
  {
    bytes32 subNode = setSubnodeOwner(node, label, owner_);

    _setResolverAndTTL(subNode, resolver_, ttl_);
  }

  function setApprovalForAll(
    address operator,
    bool approved
  )
    external
  {
    operators[msg.sender][operator] = approved;

    emit ApprovalForAll(
      msg.sender,
      operator,
      approved
    );
  }

  // external functions (views)

  function owner(
    bytes32 node
  )
    external
    view
    returns (address)
  {
    address addr = records[node].owner;

    if (addr == address(this)) {
      return address(0x0);
    }

    return addr;
  }

  function resolver(
    bytes32 node
  )
    external
    view
    returns (address)
  {
    return records[node].resolver;
  }

  function ttl(
    bytes32 node
  )
    external
    view
    returns (uint64)
  {
    return records[node].ttl;
  }

  function recordExists(
    bytes32 node
  )
    external
    view
    returns (bool)
  {
    return records[node].owner != address(0x0);
  }

  function isApprovedForAll(
    address owner_,
    address operator
  )
    external
    view
    returns (bool)
  {
    return operators[owner_][operator];
  }

  // public functions

  function setOwner(
    bytes32 node,
    address owner_
  )
    public
    authorised(node)
  {
    records[node].owner = owner_;

    emit Transfer(node, owner_);
  }

  function setResolver(
    bytes32 node,
    address resolver_
  )
    public
    authorised(node)
  {
    records[node].resolver = resolver_;

    emit NewResolver(node, resolver_);
  }

  function setSubnodeOwner(
    bytes32 node,
    bytes32 label,
    address owner_
  )
    public
    authorised(node)
    returns(bytes32)
  {
    bytes32 subNode = keccak256(abi.encodePacked(node, label));

    records[subNode].owner = owner_;

    emit NewOwner(node, label, owner_);

    return subNode;
  }

  // private functions

  function _setResolverAndTTL(
    bytes32 node,
    address resolver_,
    uint64 ttl_
  )
    private
  {
    if (resolver_ != records[node].resolver) {
      records[node].resolver = resolver_;

      emit NewResolver(node, resolver_);
    }

    if (ttl_ != records[node].ttl) {
      records[node].ttl = ttl_;

      emit NewTTL(node, ttl_);
    }
  }
}