// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

/**
 * @title Address library
 */
library AddressLib {
  /**
   * @notice Converts address into sha3 hash
   * @param self address
   * @return sha3 hash
   */
  function toSha3Hash(
    address self
  )
    internal
    pure
    returns (bytes32)
  {
    bytes32 result;

    // solhint-disable-next-line no-inline-assembly
    assembly {
      let lookup := 0x3031323334353637383961626364656600000000000000000000000000000000

      for { let i := 40 } gt(i, 0) { } {
        i := sub(i, 1)
        mstore8(i, byte(and(self, 0xf), lookup))
        self := div(self, 0x10)
        i := sub(i, 1)
        mstore8(i, byte(and(self, 0xf), lookup))
        self := div(self, 0x10)
      }

      result := keccak256(0, 40)
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

import "../common/libs/AddressLib.sol";
import "../common/lifecycle/Initializable.sol";
import "./resolvers/ENSNameResolver.sol";
import "./ENSRegistry.sol";

/**
 * @title ENS reverse registrar
 *
 * @dev Base on https://github.com/ensdomains/ens/blob/ff0f41747c05f1598973b0fe7ad0d9e09565dfcd/contracts/ReverseRegistrar.sol
 */
contract ENSReverseRegistrar is Initializable {
  using AddressLib for address;

  // namehash('addr.reverse')
  bytes32 public constant ADDR_REVERSE_NODE = 0x91d1777781884d03a6757a803996e38de2a42967fb37eeaca72729271025a9e2;

  ENSRegistry public registry;
  ENSNameResolver public resolver;

  /**
   * @dev Public constructor
   */
  constructor() public Initializable() {}

  // external functions

  /**
   * @notice Initializes `ENSReverseRegistrar` contract
   * @param registry_ ENS registry address
   * @param resolver_ ENS name resolver address
   */
  function initialize(
    ENSRegistry registry_,
    ENSNameResolver resolver_
  )
    external
    onlyInitializer
  {
    registry = registry_;
    resolver = resolver_;
  }

  // external functions

  function claim(
    address owner
  )
    public
    returns (bytes32)
  {
    return _claimWithResolver(owner, address(0));
  }

  function claimWithResolver(
    address owner,
    address resolver_
  )
    public
    returns (bytes32)
  {
    return _claimWithResolver(owner, resolver_);
  }

  function setName(
    string memory name
  )
    public
    returns (bytes32)
  {
    bytes32 node = _claimWithResolver(address(this), address(resolver));

    resolver.setName(node, name);

    return node;
  }

  // external functions (pure)

  function node(
    address addr_
  )
    external
    pure
    returns (bytes32)
  {
    return keccak256(abi.encodePacked(ADDR_REVERSE_NODE, addr_.toSha3Hash()));
  }

  // private functions

  function _claimWithResolver(
    address owner,
    address resolver_
  )
    private
    returns (bytes32)
  {
    bytes32 label = address(msg.sender).toSha3Hash();
    bytes32 node_ = keccak256(abi.encodePacked(ADDR_REVERSE_NODE, label));
    address currentOwner = registry.owner(node_);

    if (resolver_ != address(0x0) && resolver_ != registry.resolver(node_)) {
      if (currentOwner != address(this)) {
        registry.setSubnodeOwner(ADDR_REVERSE_NODE, label, address(this));
        currentOwner = address(this);
      }

      registry.setResolver(node_, resolver_);
    }

    // Update the owner if required
    if (currentOwner != owner) {
      registry.setSubnodeOwner(ADDR_REVERSE_NODE, label, owner);
    }

    return node_;
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