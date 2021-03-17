// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "../common/access/Guarded.sol";
import "../common/lifecycle/Initializable.sol";
import "../common/signature/SignatureValidator.sol";
import "../gateway/GatewayRecipient.sol";
import "./resolvers/ENSAddressResolver.sol";
import "./resolvers/ENSNameResolver.sol";
import "./resolvers/ENSPubKeyResolver.sol";
import "./resolvers/ENSTextResolver.sol";
import "./ENSRegistry.sol";


/**
 * @title ENS controller
 *
 * @notice ENS subnode registrar
 *
 * @dev The process of adding root node consists of 3 steps:
 * 1. `submitNode` - should be called from ENS node owner,
 * 2. Change ENS node owner in ENS registry to ENS controller,
 * 3. `verifyNode` - should be called from previous ENS node owner,
 *
 * To register sub node, `msg.sender` need to send valid signature from one of guardian key.
 * Once registration is complete `msg.sender` becoming both node owner and `addr` record value.
 *
 * After registration sub node cannot be replaced.
 *
 * @author Stanisław Głogowski <[email protected]>
 */
contract ENSController is Guarded, Initializable, SignatureValidator, GatewayRecipient, ENSAddressResolver, ENSNameResolver, ENSPubKeyResolver, ENSTextResolver {
  struct SubNodeRegistration {
    address account;
    bytes32 node;
    bytes32 label;
  }

  bytes4 private constant INTERFACE_META_ID = bytes4(keccak256(abi.encodePacked("supportsInterface(bytes4)")));

  bytes32 private constant HASH_PREFIX_SUB_NODE_REGISTRATION = keccak256(
    "SubNodeRegistration(address account,bytes32 node,bytes32 label)"
  );

  ENSRegistry public registry;

  mapping(bytes32 => address) public nodeOwners;

  // events

  /**
   * @dev Emitted when new node is submitted
   * @param node node name hash
   * @param owner owner address
   */
  event NodeSubmitted(
    bytes32 node,
    address owner
  );

  /**
   * @dev Emitted when the existing owner is verified
   * @param node node name hash
   */
  event NodeVerified(
    bytes32 node
  );

  /**
   * @dev Emitted when new node is released
   * @param node node name hash
   * @param owner owner address
   */
  event NodeReleased(
    bytes32 node,
    address owner
  );

  /**
   * @dev Emitted when ENS registry address is changed
   * @param registry registry address
   */
  event RegistryChanged(
    address registry
  );

  /**
   * @dev Public constructor
   */
  constructor() public Guarded() Initializable() SignatureValidator() {}

  // external functions

  /**
   * @notice Initializes `ENSController` contract
   * @param registry_ ENS registry address
   * @param gateway_ gateway address
   */
  function initialize(
    ENSRegistry registry_,
    address[] calldata guardians_,
    address gateway_
  )
    external
    onlyInitializer
  {
    require(
      address(registry_) != address(0),
      "ENSController: cannot set 0x0 registry"
    );

    registry = registry_;

    // Guarded
    _initializeGuarded(guardians_);

    // GatewayRecipient
    _initializeGatewayRecipient(gateway_);
  }

  /**
   * @notice Sets registry
   * @param registry_ registry address
   */
  function setRegistry(
    ENSRegistry registry_
  )
    external
    onlyGuardian
  {
    require(
      address(registry_) != address(0),
      "ENSController: cannot set 0x0 registry"
    );

    require(
      registry_ != registry,
      "ENSController: registry already set"
    );

    registry = registry_;

    emit RegistryChanged(
      address(registry)
    );
  }

  /**
   * @notice Submits node
   * @dev Should be called from the current ENS node owner
   * @param node node name hash
   */
  function submitNode(
    bytes32 node
  )
    external
  {
    address owner = _getContextAccount();

    require(
      _addr(node) == address(0),
      "ENSController: node already exists"
    );

    require(
      nodeOwners[node] == address(0),
      "ENSController: node already submitted"
    );

    require(
      registry.owner(node) == owner,
      "ENSController: invalid ens node owner"
    );

    nodeOwners[node] = owner;

    emit NodeSubmitted(node, owner);
  }

  /**
   * @notice Verifies node
   * @dev Should be called from the previous ENS node owner
   * @param node node name hash
   */
  function verifyNode(
    bytes32 node
  )
    external
  {
    address owner = _getContextAccount();

    require(
      _addr(node) == address(0),
      "ENSController: node already exists"
    );

    require(
      nodeOwners[node] == owner,
      "ENSController: invalid node owner"
    );

    require(
      registry.owner(node) == address(this),
      "ENSController: invalid ens node owner"
    );

    _setAddr(node, address(this));

    registry.setResolver(node, address(this));

    emit NodeVerified(node);
  }

  /**
   * @notice Releases node
   * @dev Should be called from the previous ENS node owner
   * @param node node name hash
   */
  function releaseNode(
    bytes32 node
  )
    external
  {
    address owner = _getContextAccount();

    require(
      _addr(node) == address(this),
      "ENSController: node doesn't exist"
    );

    require(
      nodeOwners[node] == owner,
      "ENSController: invalid node owner"
    );

    registry.setOwner(node, owner);

    delete nodeOwners[node];

    emit NodeReleased(node, owner);
  }

  /**
   * @notice Sync address
   * @param node node name hash
   */
  function syncAddr(
    bytes32 node
  )
    external
  {
    address account = _getContextAccount();

    require(
      account == registry.owner(node),
      "ENSController: caller is not the node owner"
    );

    require(
      registry.resolver(node) == address(this),
      "ENSController: invalid node resolver"
    );

    require(
      _addr(node) == address(0),
      "ENSController: node already in sync"
    );

    _setAddr(node, account);
  }

  /**
   * @notice Registers sub node
   * @param node node name hash
   * @param label label hash
   * @param guardianSignature guardian signature
   */
  function registerSubNode(
    bytes32 node,
    bytes32 label,
    bytes calldata guardianSignature
  )
    external
  {
    address account = _getContextAccount();

    bytes32 messageHash = _hashSubNodeRegistration(
      account,
      node,
      label
    );

    require(
      _verifyGuardianSignature(messageHash, guardianSignature),
      "ENSController: invalid guardian signature"
    );

    bytes32 subNode = keccak256(
      abi.encodePacked(
        node,
        label
      )
    );

    require(
      _addr(node) == address(this),
      "ENSController: invalid node"
    );

    require(
      _addr(subNode) == address(0),
      "ENSController: label already taken"
    );

    registry.setSubnodeRecord(node, label, address(this), address(this), 0);
    registry.setOwner(subNode, account);

    _setAddr(subNode, account);
  }

  // external functions (pure)
  function supportsInterface(
    bytes4 interfaceID
  )
    external
    pure
    returns(bool)
  {
    return interfaceID == INTERFACE_META_ID ||
    interfaceID == INTERFACE_ADDR_ID ||
    interfaceID == INTERFACE_ADDRESS_ID ||
    interfaceID == INTERFACE_NAME_ID ||
    interfaceID == INTERFACE_PUB_KEY_ID ||
    interfaceID == INTERFACE_TEXT_ID;
  }

  // public functions (views)

  /**
   * @notice Hashes `SubNodeRegistration` message payload
   * @param subNodeRegistration struct
   * @return hash
   */
  function hashSubNodeRegistration(
    SubNodeRegistration memory subNodeRegistration
  )
    public
    view
    returns (bytes32)
  {
    return _hashSubNodeRegistration(
      subNodeRegistration.account,
      subNodeRegistration.node,
      subNodeRegistration.label
    );
  }

  // internal functions (views)

  function _isNodeOwner(
    bytes32 node
  )
    internal
    override
    view
    returns (bool)
  {
    return registry.owner(node) == _getContextAccount();
  }

  // private functions (views)

  function _hashSubNodeRegistration(
    address account,
    bytes32 node,
    bytes32 label
  )
    private
    view
    returns (bytes32)
  {
    return _hashMessagePayload(HASH_PREFIX_SUB_NODE_REGISTRATION, abi.encodePacked(
      account,
      node,
      label
    ));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "../libs/ECDSALib.sol";


/**
 * @title Guarded
 *
 * @dev Contract module which provides a guardian-type control mechanism.
 * It allows key accounts to have guardians and restricts specific methods to be accessible by guardians only.
 *
 * Each guardian account can remove other guardians
 *
 * Use `_initializeGuarded` to initialize the contract
 *
 * @author Stanisław Głogowski <[email protected]>
 */
contract Guarded {
  using ECDSALib for bytes32;

  mapping(address => bool) private guardians;

  // events

  /**
   * @dev Emitted when a new guardian is added
   * @param sender sender address
   * @param guardian guardian address
   */
  event GuardianAdded(
    address sender,
    address guardian
  );

  /**
   * @dev Emitted when the existing guardian is removed
   * @param sender sender address
   * @param guardian guardian address
   */
  event GuardianRemoved(
    address sender,
    address guardian
  );

  // modifiers

  /**
   * @dev Throws if tx.origin is not a guardian account
   */
  modifier onlyGuardian() {
    require(
      // solhint-disable-next-line avoid-tx-origin
      guardians[tx.origin],
      "Guarded: tx.origin is not the guardian"
    );

    _;
  }

  /**
   * @dev Internal constructor
   */
  constructor() internal {}

  // external functions

  /**
   * @notice Adds a new guardian
   * @param guardian guardian address
   */
  function addGuardian(
    address guardian
  )
    external
    onlyGuardian
  {
    _addGuardian(guardian);
  }

  /**
   * @notice Removes the existing guardian
   * @param guardian guardian address
   */
  function removeGuardian(
    address guardian
  )
    external
    onlyGuardian
  {
    require(
      // solhint-disable-next-line avoid-tx-origin
      tx.origin != guardian,
      "Guarded: cannot remove self"
    );

    require(
      guardians[guardian],
      "Guarded: guardian doesn't exist"
    );

    guardians[guardian] = false;

    emit GuardianRemoved(
      // solhint-disable-next-line avoid-tx-origin
      tx.origin,
      guardian
    );
  }

  // external functions (views)

  /**
   * @notice Check if guardian exists
   * @param guardian guardian address
   * @return true when guardian exists
   */
  function isGuardian(
    address guardian
  )
    external
    view
    returns (bool)
  {
    return guardians[guardian];
  }

  /**
   * @notice Verifies guardian signature
   * @param messageHash message hash
   * @param signature signature
   * @return true on correct guardian signature
   */
  function verifyGuardianSignature(
    bytes32 messageHash,
    bytes calldata signature
  )
    external
    view
    returns (bool)
  {
    return _verifyGuardianSignature(
      messageHash,
      signature
    );
  }

  // internal functions

  /**
   * @notice Initializes `Guarded` contract
   * @dev If `guardians_` array is empty `tx.origin` is added as guardian account
   * @param guardians_ array of guardians addresses
   */
  function _initializeGuarded(
    address[] memory guardians_
  )
    internal
  {
    if (guardians_.length == 0) {
      // solhint-disable-next-line avoid-tx-origin
      _addGuardian(tx.origin);
    } else {
      uint guardiansLen = guardians_.length;
      for (uint i = 0; i < guardiansLen; i++) {
        _addGuardian(guardians_[i]);
      }
    }
  }


  // internal functions (views)

  function _verifyGuardianSignature(
    bytes32 messageHash,
    bytes memory signature
  )
    internal
    view
    returns (bool)
  {
    address guardian = messageHash.recoverAddress(signature);

    return guardians[guardian];
  }

  // private functions

  function _addGuardian(
    address guardian
  )
    private
  {
    require(
      guardian != address(0),
      "Guarded: cannot add 0x0 guardian"
    );

    require(
      !guardians[guardian],
      "Guarded: guardian already exists"
    );

    guardians[guardian] = true;

    emit GuardianAdded(
      // solhint-disable-next-line avoid-tx-origin
      tx.origin,
      guardian
    );
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

import "../libs/ECDSALib.sol";

/**
 * @title Signature validator
 *
 * @author Stanisław Głogowski <[email protected]>
 */
contract SignatureValidator {
  using ECDSALib for bytes32;

  uint256 public chainId;

  /**
   * @dev internal constructor
   */
  constructor() internal {
    uint256 chainId_;

    // solhint-disable-next-line no-inline-assembly
    assembly {
      chainId_ := chainid()
    }

    chainId = chainId_;
  }

  // internal functions

  function _hashMessagePayload(
    bytes32 messagePrefix,
    bytes memory messagePayload
  )
    internal
    view
    returns (bytes32)
  {
    return keccak256(abi.encodePacked(
      chainId,
      address(this),
      messagePrefix,
      messagePayload
    )).toEthereumSignedMessageHash();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "../common/libs/BytesLib.sol";


/**
 * @title Gateway recipient
 *
 * @notice Gateway target contract
 *
 * @author Stanisław Głogowski <[email protected]>
 */
contract GatewayRecipient {
  using BytesLib for bytes;

  address public gateway;

  /**
   * @dev internal constructor
   */
  constructor() internal {}

  // internal functions

  /**
   * @notice Initializes `GatewayRecipient` contract
   * @param gateway_ `Gateway` contract address
   */
  function _initializeGatewayRecipient(
    address gateway_
  )
    internal
  {
    gateway = gateway_;
  }

  // internal functions (views)

  /**
   * @notice Gets gateway context account
   * @return context account address
   */
  function _getContextAccount()
    internal
    view
    returns (address)
  {
    return _getContextAddress(40);
  }

  /**
   * @notice Gets gateway context sender
   * @return context sender address
   */
  function _getContextSender()
    internal
    view
    returns (address)
  {
    return _getContextAddress(20);
  }

  /**
   * @notice Gets gateway context data
   * @return context data
   */
  function _getContextData()
    internal
    view
    returns (bytes calldata)
  {
    bytes calldata result;

    if (_isGatewaySender()) {
      result = msg.data[:msg.data.length - 40];
    } else {
      result = msg.data;
    }

    return result;
  }

  // private functions (views)

  function _getContextAddress(
    uint256 offset
  )
    private
    view
    returns (address)
  {
    address result = address(0);

    if (_isGatewaySender()) {
      uint from = msg.data.length - offset;
      result = bytes(msg.data[from:from + 20]).toAddress();
    } else {
      result = msg.sender;
    }

    return result;
  }

  function _isGatewaySender()
    private
    view
    returns (bool)
  {
    bool result;

    if (msg.sender == gateway) {
      require(
        msg.data.length >= 44,
        "GatewayRecipient: invalid msg.data"
      );

      result = true;
    }

    return result;
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

import "./ENSAbstractResolver.sol";


/**
 * @title ENS abstract pub key resolver
 *
 * @dev Base on https://github.com/ensdomains/resolvers/blob/f7d62ab04bfe1692a4344f6f1d31ff81315a98c3/contracts/profiles/PubkeyResolver.sol
 */
abstract contract ENSPubKeyResolver is ENSAbstractResolver {
  bytes4 internal constant INTERFACE_PUB_KEY_ID = bytes4(keccak256(abi.encodePacked("pubkey(bytes32)")));

  struct PubKey {
    bytes32 x;
    bytes32 y;
  }

  mapping(bytes32 => PubKey) internal resolverPubKeys;

  // events

  event PubkeyChanged(
    bytes32 indexed node,
    bytes32 x,
    bytes32 y
  );

  // external functions (views)

  function setPubkey(
    bytes32 node,
    bytes32 x,
    bytes32 y
  )
    external
    onlyNodeOwner(node)
  {
    resolverPubKeys[node] = PubKey(x, y);

    emit PubkeyChanged(node, x, y);
  }

  // external functions (views)

  function pubkey(
    bytes32 node
  )
    external
    view
    returns (bytes32 x, bytes32 y)
  {
    return (resolverPubKeys[node].x, resolverPubKeys[node].y);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./ENSAbstractResolver.sol";


/**
 * @title ENS abstract text resolver
 *
 * @dev Base on https://github.com/ensdomains/resolvers/blob/f7d62ab04bfe1692a4344f6f1d31ff81315a98c3/contracts/profiles/TextResolver.sol
 */
abstract contract ENSTextResolver is ENSAbstractResolver {
  bytes4 internal constant INTERFACE_TEXT_ID = bytes4(keccak256(abi.encodePacked("text(bytes32,string)")));

  mapping(bytes32 => mapping(string => string)) internal resolverTexts;

  // events

  event TextChanged(
    bytes32 indexed node,
    string indexed indexedKey,
    string key
  );

  // external functions (views)

  function setText(
    bytes32 node,
    string calldata key,
    string calldata value
  )
    external
    onlyNodeOwner(node)
  {
    resolverTexts[node][key] = value;

    emit TextChanged(node, key, key);
  }

  // external functions (views)

  function text(
    bytes32 node,
    string calldata key
  )
    external
    view
    returns (string memory)
  {
    return resolverTexts[node][key];
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
 * @title ECDSA library
 *
 * @dev Based on https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.3.0/contracts/cryptography/ECDSA.sol#L26
 */
library ECDSALib {
  function recoverAddress(
    bytes32 messageHash,
    bytes memory signature
  )
    internal
    pure
    returns (address)
  {
    address result = address(0);

    if (signature.length == 65) {
      bytes32 r;
      bytes32 s;
      uint8 v;

      // solhint-disable-next-line no-inline-assembly
      assembly {
        r := mload(add(signature, 0x20))
        s := mload(add(signature, 0x40))
        v := byte(0, mload(add(signature, 0x60)))
      }

      if (v < 27) {
        v += 27;
      }

      if (v == 27 || v == 28) {
        result = ecrecover(messageHash, v, r, s);
      }
    }

    return result;
  }

  function toEthereumSignedMessageHash(
    bytes32 messageHash
  )
    internal
    pure
    returns (bytes32)
  {
    return keccak256(abi.encodePacked(
      "\x19Ethereum Signed Message:\n32",
      messageHash
    ));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

/**
 * @title Bytes library
 *
 * @author Stanisław Głogowski <[email protected]>
 */
library BytesLib {
  /**
   * @notice Converts bytes to address
   * @param data data
   * @return address
   */
  function toAddress(
    bytes memory data
  )
    internal
    pure
    returns (address)
  {
    address result;

    require(
      data.length == 20,
      "BytesLib: invalid data length"
    );

    // solhint-disable-next-line no-inline-assembly
    assembly {
      result := div(mload(add(data, 0x20)), 0x1000000000000000000000000)
    }

    return result;
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