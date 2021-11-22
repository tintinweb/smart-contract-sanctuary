// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

/**
 * @title Controlled
 *
 * @dev Contract module which provides an access control mechanism.
 * It ensures there is only one controlling account of the smart contract
 * and grants that account exclusive access to specific functions.
 *
 * The controller account will be the one that deploys the contract.
 *
 * @author Stanisław Głogowski <[email protected]>
 */
contract Controlled {
  /**
   * @return controller account address
   */
  address public controller;

  // modifiers

  /**
   * @dev Throws if msg.sender is not the controller
   */
  modifier onlyController() {
    require(
      msg.sender == controller,
      "Controlled: msg.sender is not the controller"
    );

    _;
  }

  /**
   * @dev Internal constructor
   */
  constructor()
    internal
  {
    controller = msg.sender;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "../access/Controlled.sol";
import "./AccountBase.sol";


/**
 * @title Account
 *
 * @author Stanisław Głogowski <[email protected]>
 */
contract Account is Controlled, AccountBase {
  address public implementation;

  /**
   * @dev Public constructor
   * @param registry_ account registry address
   * @param implementation_ account implementation address
   */
  constructor(
    address registry_,
    address implementation_
  )
    public
    Controlled()
  {
    registry = registry_;
    implementation = implementation_;
  }

  // external functions

  /**
   * @notice Payable receive
   */
  receive()
    external
    payable
  {
    //
  }

  /**
   * @notice Fallback
   */
  // solhint-disable-next-line payable-fallback
  fallback()
    external
  {
    if (msg.data.length != 0) {
      address implementation_ = implementation;

      // solhint-disable-next-line no-inline-assembly
      assembly {
        let calldedatasize := calldatasize()

        calldatacopy(0, 0, calldedatasize)

        let result := delegatecall(gas(), implementation_, 0, calldedatasize, 0, 0)
        let returneddatasize := returndatasize()

        returndatacopy(0, 0, returneddatasize)

        switch result
        case 0 { revert(0, returneddatasize) }
        default { return(0, returneddatasize) }
      }
    }
  }

  /**
   * @notice Sets implementation
   * @param implementation_ implementation address
   */
  function setImplementation(
    address implementation_
  )
    external
    onlyController
  {
    implementation = implementation_;
  }

  /**
   * @notice Executes transaction
   * @param to to address
   * @param value value
   * @param data data
   * @return transaction result
   */
  function executeTransaction(
    address to,
    uint256 value,
    bytes calldata data
  )
    external
    onlyController
    returns (bytes memory)
  {
    bytes memory result;
    bool succeeded;

    // solhint-disable-next-line avoid-call-value, avoid-low-level-calls
    (succeeded, result) = payable(to).call{value: value}(data);

    require(
      succeeded,
      "Account: transaction reverted"
    );

    return result;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

/**
 * @title Account base
 *
 * @author Stanisław Głogowski <[email protected]>
 */
contract AccountBase {
  address public registry;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "../lifecycle/Initializable.sol";
import "./AccountBase.sol";
import "./AccountRegistry.sol";


/**
 * @title Account implementation (version 1)
 *
 * @author Stanisław Głogowski <[email protected]>
 */
contract AccountImplementationV1 is Initializable, AccountBase {
  bytes32 constant private ERC777_TOKENS_RECIPIENT_INTERFACE_HASH = keccak256(abi.encodePacked("ERC777TokensRecipient"));
  bytes32 constant private ERC1820_ACCEPT_MAGIC = keccak256(abi.encodePacked("ERC1820_ACCEPT_MAGIC"));

  bytes4 constant private ERC1271_VALID_MESSAGE_HASH_SIGNATURE = bytes4(keccak256(abi.encodePacked("isValidSignature(bytes32,bytes)")));
  bytes4 constant private ERC1271_VALID_MESSAGE_SIGNATURE = bytes4(keccak256(abi.encodePacked("isValidSignature(bytes,bytes)")));
  bytes4 constant private ERC1271_INVALID_SIGNATURE = 0xffffffff;

  /**
   * @dev Internal constructor
   */
  constructor() internal Initializable() {}

  // external functions

  /**
   * @notice Initializes `AccountImplementation` contract
   * @param registry_ registry address
   */
  function initialize(
    address registry_
  )
    external
    onlyInitializer
  {
    registry = registry_;
  }

  // external functions (views)

  // ERC1820

  function canImplementInterfaceForAddress(
    bytes32 interfaceHash,
    address addr
  )
    external
    view
    returns(bytes32)
  {
    bytes32 result;

    if (interfaceHash == ERC777_TOKENS_RECIPIENT_INTERFACE_HASH && addr == address(this)) {
      result =  ERC1820_ACCEPT_MAGIC;
    }

    return result;
  }

  // ERC1271

  function isValidSignature(
    bytes32 messageHash,
    bytes calldata signature
  )
    external
    view
    returns (bytes4)
  {
    return AccountRegistry(registry).isValidAccountSignature(address(this), messageHash, signature)
      ? ERC1271_VALID_MESSAGE_HASH_SIGNATURE
      : ERC1271_INVALID_SIGNATURE;
  }

  function isValidSignature(
    bytes calldata message,
    bytes calldata signature
  )
    external
    view
    returns (bytes4)
  {
    return AccountRegistry(registry).isValidAccountSignature(address(this), message, signature)
      ? ERC1271_VALID_MESSAGE_SIGNATURE
      : ERC1271_INVALID_SIGNATURE;
  }

  // external functions (pure)

  // ERC721

  function onERC721Received(
    address,
    address,
    uint256,
    bytes calldata
  )
    external
    pure
    returns (bytes4)
  {
    return this.onERC721Received.selector;
  }

  // ERC1155

  function onERC1155Received(
    address,
    address,
    uint256,
    uint256,
    bytes calldata
  )
    external
    pure
    returns (bytes4)
  {
    return this.onERC1155Received.selector;
  }

  // ERC777

  function tokensReceived(
    address,
    address,
    address,
    uint256,
    bytes calldata,
    bytes calldata
  )
    external
    pure
  {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./Account.sol";


/**
 * @title Account registry
 *
 * @author Stanisław Głogowski <[email protected]>
 */
abstract contract AccountRegistry {
  /**
   * @notice Verifies account signature
   * @param account account address
   * @param messageHash message hash
   * @param signature signature
   * @return true if valid
   */
  function isValidAccountSignature(
    address account,
    bytes32 messageHash,
    bytes calldata signature
  )
    virtual
    external
    view
    returns (bool);

  /**
   * @notice Verifies account signature
   * @param account account address
   * @param message message
   * @param signature signature
   * @return true if valid
   */
  function isValidAccountSignature(
    address account,
    bytes calldata message,
    bytes calldata signature
  )
    virtual
    external
    view
    returns (bool);
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

import "../common/account/AccountImplementationV1.sol";


/**
 * @title Personal account implementation (version 1)
 *
 * @author Stanisław Głogowski <[email protected]>
 */
contract PersonalAccountImplementationV1 is AccountImplementationV1 {

  /**
   * @dev Public constructor
   */
  constructor() public AccountImplementationV1() {}
}