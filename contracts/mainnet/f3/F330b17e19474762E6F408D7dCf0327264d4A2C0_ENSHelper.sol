// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "../common/lifecycle/Initializable.sol";
import "./resolvers/ENSAddressResolver.sol";
import "./resolvers/ENSNameResolver.sol";
import "./ENSRegistry.sol";

/**
 * @title ENS helper
 *
 * @author Stanisław Głogowski <[email protected]>
 */
contract ENSHelper is Initializable {
  ENSRegistry public registry;

  /**
   * @dev Public constructor
   */
  constructor() public Initializable() {}

  // external functions

  /**
   * @notice Initializes `ENSLookupHelper` contract
   * @param registry_ ENS registry address
   */
  function initialize(
    ENSRegistry registry_
  )
    external
    onlyInitializer
  {
    registry = registry_;
  }

  // external functions (views)

  /**
   * @notice Gets nodes addresses
   * @param nodes array of nodes
   * @return nodes addresses
   */
  function getAddresses(
    bytes32[] memory nodes
  )
    external
    view
    returns (address[] memory)
  {
    uint nodesLen = nodes.length;
    address[] memory result = new address[](nodesLen);

    for (uint i = 0; i < nodesLen; i++) {
      result[i] = _getAddress(nodes[i]);
    }

    return result;
  }

  /**
   * @notice Gets nodes names
   * @param nodes array of nodes
   * @return nodes names
   */
  function getNames(
    bytes32[] memory nodes
  )
    external
    view
    returns (string[] memory)
  {
    uint nodesLen = nodes.length;
    string[] memory result = new string[](nodesLen);

    for (uint i = 0; i < nodesLen; i++) {
      result[i] = _getName(nodes[i]);
    }

    return result;
  }

  // private functions (views)

  function _getAddress(
    bytes32 node
  )
    private
    view
    returns (address)
  {
    address result;
    address resolver = registry.resolver(node);

    if (resolver != address(0)) {
      try ENSAddressResolver(resolver).addr(node) returns (address addr) {
        result = addr;
      } catch {
        //
      }
    }

    return result;
  }

  function _getName(
    bytes32 node
  )
    private
    view
    returns (string memory)
  {
    string memory result;
    address resolver = registry.resolver(node);

    if (resolver != address(0)) {
      try ENSNameResolver(resolver).name(node) returns (string memory name) {
        result = name;
      } catch {
        //
      }
    }

    return result;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

/**
 * @title Initializable
 *
 * @dev Contract module which provides access control mechanism, where
 * there is the initializer account that can be granted exclusive access to
 * specific functions.
 *
 * The initializer account will be tx.origin during contract deployment and will be removed on first use.
 * Use `onlyInitializer` modifier on contract initialize process.
 *
 * @author Stanisław Głogowski <[email protected]>
 */
contract Initializable {
  address private initializer;

  // events

  /**
   * @dev Emitted after `onlyInitializer`
   * @param initializer initializer address
   */
  event Initialized(
    address initializer
  );

  // modifiers

  /**
   * @dev Throws if tx.origin is not the initializer
   */
  modifier onlyInitializer() {
    require(
      // solhint-disable-next-line avoid-tx-origin
      tx.origin == initializer,
      "Initializable: tx.origin is not the initializer"
    );

    /// @dev removes initializer
    initializer = address(0);

    _;

    emit Initialized(
      // solhint-disable-next-line avoid-tx-origin
      tx.origin
    );
  }

  /**
   * @dev Internal constructor
   */
  constructor()
    internal
  {
    // solhint-disable-next-line avoid-tx-origin
    initializer = tx.origin;
  }

   // external functions (views)

  /**
   * @notice Check if contract is initialized
   * @return true when contract is initialized
   */
  function isInitialized()
    external
    view
    returns (bool)
  {
    return initializer == address(0);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./ENSAbstractResolver.sol";


/**
 * @title ENS abstract address resolver
 *
 * @dev Base on https://github.com/ensdomains/resolvers/blob/f7d62ab04bfe1692a4344f6f1d31ff81315a98c3/contracts/profiles/AddrResolver.sol
 */
abstract contract ENSAddressResolver is ENSAbstractResolver {
  bytes4 internal constant INTERFACE_ADDR_ID = bytes4(keccak256(abi.encodePacked("addr(bytes32)")));
  bytes4 internal constant INTERFACE_ADDRESS_ID = bytes4(keccak256(abi.encodePacked("addr(bytes32,uint)")));

  uint internal constant COIN_TYPE_ETH = 60;

  mapping(bytes32 => mapping(uint => bytes)) internal resolverAddresses;

  // events

  event AddrChanged(
    bytes32 indexed node,
    address addr
  );

  event AddressChanged(
    bytes32 indexed node,
    uint coinType,
    bytes newAddress
  );

  // external functions

  function setAddr(
    bytes32 node,
    address addr_
  )
    external
    onlyNodeOwner(node)
  {
    _setAddr(node, addr_);
  }

  function setAddr(
    bytes32 node,
    uint coinType,
    bytes memory addr_
  )
    external
    onlyNodeOwner(node)
  {
    _setAddr(node, coinType, addr_);
  }

  // external functions (views)

  function addr(
    bytes32 node
  )
    external
    view
    returns (address)
  {
    return _addr(node);
  }

  function addr(
    bytes32 node,
    uint coinType
  )
    external
    view
    returns (bytes memory)
  {
    return resolverAddresses[node][coinType];
  }

  // internal functions

  function _setAddr(
    bytes32 node,
    address addr_
  )
    internal
  {
    _setAddr(node, COIN_TYPE_ETH, _addressToBytes(addr_));
  }

  function _setAddr(
    bytes32 node,
    uint coinType,
    bytes memory addr_
  )
    internal
  {
    emit AddressChanged(node, coinType, addr_);

    if(coinType == COIN_TYPE_ETH) {
      emit AddrChanged(node, _bytesToAddress(addr_));
    }

    resolverAddresses[node][coinType] = addr_;
  }

  // internal functions (views)

  function _addr(
    bytes32 node
  )
    internal
    view
    returns (address)
  {
    address result;

    bytes memory addr_ = resolverAddresses[node][COIN_TYPE_ETH];

    if (addr_.length > 0) {
      result = _bytesToAddress(addr_);
    }

    return result;
  }

  // private function (pure)

  function _bytesToAddress(
    bytes memory data
  )
    private
    pure
    returns(address payable)
  {
    address payable result;

    require(data.length == 20);

    // solhint-disable-next-line no-inline-assembly
    assembly {
      result := div(mload(add(data, 32)), exp(256, 12))
    }

    return result;
  }

  function _addressToBytes(
    address addr_
  )
    private
    pure
    returns(bytes memory)
  {
    bytes memory result = new bytes(20);

    // solhint-disable-next-line no-inline-assembly
    assembly {
      mstore(add(result, 32), mul(addr_, exp(256, 12)))
    }

    return result;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./ENSAbstractResolver.sol";


/**
 * @title ENS abstract name resolver
 *
 * @dev Base on https://github.com/ensdomains/resolvers/blob/f7d62ab04bfe1692a4344f6f1d31ff81315a98c3/contracts/profiles/NameResolver.sol
 */
abstract contract ENSNameResolver is ENSAbstractResolver {
  bytes4 internal constant INTERFACE_NAME_ID = bytes4(keccak256(abi.encodePacked("name(bytes32)")));

  mapping(bytes32 => string) internal resolverNames;

  // events

  event NameChanged(
    bytes32 indexed node,
    string name
  );

  // external functions

  function setName(
    bytes32 node,
    string calldata name
  )
    external
    onlyNodeOwner(node)
  {
    resolverNames[node] = name;

    emit NameChanged(node, name);
  }

  // external functions (views)

  function name(
    bytes32 node
  )
    external
    view
    returns (string memory)
  {
    return resolverNames[node];
  }
}

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

/**
 * @title ENS abstract resolver
 *
 * @dev Base on https://github.com/ensdomains/resolvers/blob/f7d62ab04bfe1692a4344f6f1d31ff81315a98c3/contracts/ResolverBase.sol
 */
abstract contract ENSAbstractResolver {
  // modifiers

  modifier onlyNodeOwner(bytes32 node)
  {
    require(
      _isNodeOwner(node),
      "ENSAbstractResolver: reverted by onlyNodeOwner modifier"
    );

    _;
  }

  // internal functions (views)

  function _isNodeOwner(
    bytes32 node
  )
    internal
    virtual
    view
    returns (bool);
}