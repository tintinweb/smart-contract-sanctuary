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
 * @title Archanova account
 *
 * @author Stanisław Głogowski <[email protected]>
 */
abstract contract ArchanovaAccount {
  struct Device {
    bool isOwner;
    bool exists;
    bool existed;
  }

  mapping(address => Device) public devices;

  // events

  event DeviceAdded(
    address device,
    bool isOwner
  );

  event DeviceRemoved(
    address device
  );

  event TransactionExecuted(
    address recipient,
    uint256 value,
    bytes data,
    bytes response
  );

  // external functions

  function addDevice(
    address device,
    bool isOwner
  )
    virtual
    external;

  function removeDevice(
    address device
  )
    virtual
    external;

  function executeTransaction(
    address payable recipient,
    uint256 value,
    bytes calldata data
  )
    virtual
    external
    returns (bytes memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "@etherspot/contracts/src/common/libs/ECDSALib.sol";
import "@etherspot/contracts/src/common/lifecycle/Initializable.sol";
import "./ArchanovaAccount.sol";


/**
 * @title Archanova migrator
 *
 * @author Stanisław Głogowski <[email protected]>
 */
contract ArchanovaMigrator is Initializable {
  using ECDSALib for bytes32;

  bytes32 constant private MIGRATION_MESSAGE_PREFIX = keccak256(abi.encodePacked("etherspot <> archanova migration"));
  bytes4 constant private TRANSFER_SELECTOR = bytes4(keccak256(abi.encodePacked("transfer(address,uint256)")));
  bytes4 constant private TRANSFER_FROM_SELECTOR = bytes4(keccak256(abi.encodePacked("transferFrom(address,address,uint256)")));
  bytes4 constant private SET_ADDR_SELECTOR = bytes4(keccak256(abi.encodePacked("setAddr(bytes32,address)")));
  bytes4 constant private SYNC_ADDR_SELECTOR = bytes4(keccak256(abi.encodePacked("syncAddr(bytes32)")));
  bytes4 constant private SET_OWNER_SELECTOR = bytes4(keccak256(abi.encodePacked("setOwner(bytes32,address)")));
  bytes4 constant private SET_RESOLVER_SELECTOR = bytes4(keccak256(abi.encodePacked("setResolver(bytes32,address)")));

  address payable public ensController;
  address payable public ensRegistry;

  uint256 private chainId;

  // events

  event BalanceTransferred(
    address archanovaAccount,
    address etherspotAccount,
    uint256 value
  );

  event ERC20TokenTransferred(
    address archanovaAccount,
    address etherspotAccount,
    address token,
    uint256 tokenAmount
  );

  event ERC721TokenTransferred(
    address archanovaAccount,
    address etherspotAccount,
    address token,
    uint256 tokenId
  );

  event ENSNodeTransferred(
    address archanovaAccount,
    address etherspotAccount,
    bytes32 ensNode
  );


  /**
   * @dev public constructor
   */
  constructor()
    public
    Initializable()
  {
    uint chainId_;

    // solhint-disable-next-line no-inline-assembly
    assembly {
      chainId_ := chainid()
    }

    chainId = chainId_;
  }

  // external functions

  /**
   * @notice Initializes `ArchanovaMigrator` contract
   * @param ensController_ ens controller address
   * @param ensRegistry_ ens registry address
   */
  function initialize(
    address payable ensController_,
    address payable ensRegistry_
  )
    external
    onlyInitializer
  {
    ensController = ensController_;
    ensRegistry = ensRegistry_;
  }

  function transferBalance(
    address payable archanovaAccount,
    address payable etherspotAccount,
    uint256 value,
    bytes calldata archanovaAccountDeviceSignature
  )
    external
  {
    _verifyArchanovaAccountOwner(
      archanovaAccount,
      etherspotAccount,
      archanovaAccountDeviceSignature
    );

    _transferBalance(
      archanovaAccount,
      etherspotAccount,
      value
    );
  }

  function transferERC20Tokens(
    address payable archanovaAccount,
    address payable etherspotAccount,
    address[] calldata erc20Tokens,
    uint256[] calldata erc20TokensAmounts,
    bytes calldata archanovaAccountDeviceSignature
  )
    external
  {
    _verifyArchanovaAccountOwner(
      archanovaAccount,
      etherspotAccount,
      archanovaAccountDeviceSignature
    );

    _transferERC20Tokens(
      archanovaAccount,
      etherspotAccount,
      erc20Tokens,
      erc20TokensAmounts
    );
  }

  function transferBalanceAndERC20Tokens(
    address payable archanovaAccount,
    address payable etherspotAccount,
    uint256 value,
    address[] calldata erc20Tokens,
    uint256[] calldata erc20TokensAmounts,
    bytes calldata archanovaAccountDeviceSignature
  )
    external
  {
    _verifyArchanovaAccountOwner(
      archanovaAccount,
      etherspotAccount,
      archanovaAccountDeviceSignature
    );

    _transferBalance(
      archanovaAccount,
      etherspotAccount,
      value
    );

    _transferERC20Tokens(
      archanovaAccount,
      etherspotAccount,
      erc20Tokens,
      erc20TokensAmounts
    );
  }

  function transferERC721Tokens(
    address payable archanovaAccount,
    address payable etherspotAccount,
    address[] calldata erc721Tokens,
    uint256[] calldata erc721TokensIds,
    bytes calldata archanovaAccountDeviceSignature
  )
    external
  {
    _verifyArchanovaAccountOwner(
      archanovaAccount,
      etherspotAccount,
      archanovaAccountDeviceSignature
    );

    _transferERC721Tokens(
      archanovaAccount,
      etherspotAccount,
      erc721Tokens,
      erc721TokensIds
    );
  }

  function transferBalanceAndERC721Tokens(
    address payable archanovaAccount,
    address payable etherspotAccount,
    uint256 value,
    address[] calldata erc721Tokens,
    uint256[] calldata erc721TokensIds,
    bytes calldata archanovaAccountDeviceSignature
  )
    external
  {
    _verifyArchanovaAccountOwner(
      archanovaAccount,
      etherspotAccount,
      archanovaAccountDeviceSignature
    );

    _transferBalance(
      archanovaAccount,
      etherspotAccount,
      value
    );

    _transferERC721Tokens(
      archanovaAccount,
      etherspotAccount,
      erc721Tokens,
      erc721TokensIds
    );
  }

  function transferERC20TokensAndERC721Tokens(
    address payable archanovaAccount,
    address payable etherspotAccount,
    address[] calldata erc20Tokens,
    uint256[] calldata erc20TokensAmounts,
    address[] calldata erc721Tokens,
    uint256[] calldata erc721TokensIds,
    bytes calldata archanovaAccountDeviceSignature
  )
    external
  {
    _verifyArchanovaAccountOwner(
      archanovaAccount,
      etherspotAccount,
      archanovaAccountDeviceSignature
    );

    _transferERC20Tokens(
      archanovaAccount,
      etherspotAccount,
      erc20Tokens,
      erc20TokensAmounts
    );

    _transferERC721Tokens(
      archanovaAccount,
      etherspotAccount,
      erc721Tokens,
      erc721TokensIds
    );
  }

  function transferBalanceAndERC20TokensAndERC721Tokens(
    address payable archanovaAccount,
    address payable etherspotAccount,
    uint256 value,
    address[] calldata erc20Tokens,
    uint256[] calldata erc20TokensAmounts,
    address[] calldata erc721Tokens,
    uint256[] calldata erc721TokensIds,
    bytes calldata archanovaAccountDeviceSignature
  )
    external
  {
    _verifyArchanovaAccountOwner(
      archanovaAccount,
      etherspotAccount,
      archanovaAccountDeviceSignature
    );

    _transferBalance(
      archanovaAccount,
      etherspotAccount,
      value
    );

    _transferERC20Tokens(
      archanovaAccount,
      etherspotAccount,
      erc20Tokens,
      erc20TokensAmounts
    );

    _transferERC721Tokens(
      archanovaAccount,
      etherspotAccount,
      erc721Tokens,
      erc721TokensIds
    );
  }

  function transferENSNode(
    address payable archanovaAccount,
    address payable etherspotAccount,
    bytes32 ensNode,
    bytes calldata archanovaAccountDeviceSignature
  )
    external
  {
    _verifyArchanovaAccountOwner(
      archanovaAccount,
      etherspotAccount,
      archanovaAccountDeviceSignature
    );

    _transferENSNode(
      archanovaAccount,
      etherspotAccount,
      ensNode
    );
  }


  function transferBalanceAndENSNode(
    address payable archanovaAccount,
    address payable etherspotAccount,
    uint256 value,
    bytes32 ensNode,
    bytes calldata archanovaAccountDeviceSignature
  )
    external
  {
    _verifyArchanovaAccountOwner(
      archanovaAccount,
      etherspotAccount,
      archanovaAccountDeviceSignature
    );

    _transferBalance(
      archanovaAccount,
      etherspotAccount,
      value
    );

    _transferENSNode(
      archanovaAccount,
      etherspotAccount,
      ensNode
    );
  }

  function transferERC20TokensAndENSNode(
    address payable archanovaAccount,
    address payable etherspotAccount,
    address[] calldata erc20Tokens,
    uint256[] calldata erc20TokensAmounts,
    bytes32 ensNode,
    bytes calldata archanovaAccountDeviceSignature
  )
    external
  {
    _verifyArchanovaAccountOwner(
      archanovaAccount,
      etherspotAccount,
      archanovaAccountDeviceSignature
    );

    _transferERC20Tokens(
      archanovaAccount,
      etherspotAccount,
      erc20Tokens,
      erc20TokensAmounts
    );

    _transferENSNode(
      archanovaAccount,
      etherspotAccount,
      ensNode
    );
  }

  function transferBalanceAndERC20TokensAndENSNode(
    address payable archanovaAccount,
    address payable etherspotAccount,
    uint256 value,
    address[] calldata erc20Tokens,
    uint256[] calldata erc20TokensAmounts,
    bytes32 ensNode,
    bytes calldata archanovaAccountDeviceSignature
  )
    external
  {
    _verifyArchanovaAccountOwner(
      archanovaAccount,
      etherspotAccount,
      archanovaAccountDeviceSignature
    );

    _transferBalance(
      archanovaAccount,
      etherspotAccount,
      value
    );

    _transferERC20Tokens(
      archanovaAccount,
      etherspotAccount,
      erc20Tokens,
      erc20TokensAmounts
    );

    _transferENSNode(
      archanovaAccount,
      etherspotAccount,
      ensNode
    );
  }

  function transferERC721TokensAndENSNode(
    address payable archanovaAccount,
    address payable etherspotAccount,
    address[] calldata erc721Tokens,
    uint256[] calldata erc721TokensIds,
    bytes32 ensNode,
    bytes calldata archanovaAccountDeviceSignature
  )
    external
  {
    _verifyArchanovaAccountOwner(
      archanovaAccount,
      etherspotAccount,
      archanovaAccountDeviceSignature
    );

    _transferERC721Tokens(
      archanovaAccount,
      etherspotAccount,
      erc721Tokens,
      erc721TokensIds
    );

    _transferENSNode(
      archanovaAccount,
      etherspotAccount,
      ensNode
    );
  }

  function transferBalanceAndERC721TokensAndENSNode(
    address payable archanovaAccount,
    address payable etherspotAccount,
    uint256 value,
    address[] calldata erc721Tokens,
    uint256[] calldata erc721TokensIds,
    bytes32 ensNode,
    bytes calldata archanovaAccountDeviceSignature
  )
    external
  {
    _verifyArchanovaAccountOwner(
      archanovaAccount,
      etherspotAccount,
      archanovaAccountDeviceSignature
    );

    _transferBalance(
      archanovaAccount,
      etherspotAccount,
      value
    );

    _transferERC721Tokens(
      archanovaAccount,
      etherspotAccount,
      erc721Tokens,
      erc721TokensIds
    );

    _transferENSNode(
      archanovaAccount,
      etherspotAccount,
      ensNode
    );
  }

  function transferERC20TokensAndERC721TokensAndENSNode(
    address payable archanovaAccount,
    address payable etherspotAccount,
    address[] calldata erc20Tokens,
    uint256[] calldata erc20TokensAmounts,
    address[] calldata erc721Tokens,
    uint256[] calldata erc721TokensIds,
    bytes32 ensNode,
    bytes calldata archanovaAccountDeviceSignature
  )
    external
  {
    _verifyArchanovaAccountOwner(
      archanovaAccount,
      etherspotAccount,
      archanovaAccountDeviceSignature
    );

    _transferERC20Tokens(
      archanovaAccount,
      etherspotAccount,
      erc20Tokens,
      erc20TokensAmounts
    );

    _transferERC721Tokens(
      archanovaAccount,
      etherspotAccount,
      erc721Tokens,
      erc721TokensIds
    );

    _transferENSNode(
      archanovaAccount,
      etherspotAccount,
      ensNode
    );
  }

  function transferBalanceAndERC20TokensAndERC721TokensAndENSNode(
    address payable archanovaAccount,
    address payable etherspotAccount,
    uint256 value,
    address[] calldata erc20Tokens,
    uint256[] calldata erc20TokensAmounts,
    address[] calldata erc721Tokens,
    uint256[] calldata erc721TokensIds,
    bytes32 ensNode,
    bytes calldata archanovaAccountDeviceSignature
  )
    external
  {
    _verifyArchanovaAccountOwner(
      archanovaAccount,
      etherspotAccount,
      archanovaAccountDeviceSignature
    );

    _transferBalance(
      archanovaAccount,
      etherspotAccount,
      value
    );

    _transferERC20Tokens(
      archanovaAccount,
      etherspotAccount,
      erc20Tokens,
      erc20TokensAmounts
    );

    _transferERC721Tokens(
      archanovaAccount,
      etherspotAccount,
      erc721Tokens,
      erc721TokensIds
    );

    _transferENSNode(
      archanovaAccount,
      etherspotAccount,
      ensNode
    );
  }

  // private functions

  function _transferBalance(
    address payable archanovaAccount,
    address payable etherspotAccount,
    uint256 value
  )
    private
  {
    ArchanovaAccount(archanovaAccount).executeTransaction(
      etherspotAccount,
      value,
      new bytes(0)
    );

    emit BalanceTransferred(
      archanovaAccount,
      etherspotAccount,
      value
    );
  }

  function _transferERC20Tokens(
    address payable archanovaAccount,
    address payable etherspotAccount,
    address[] memory tokens,
    uint256[] memory tokensAmounts
  )
    private
  {
    uint tokensLen = tokens.length;

    for (uint i = 0; i < tokensLen; i++) {
      _transferERC20Token(
        archanovaAccount,
        etherspotAccount,
        payable(tokens[i]),
        tokensAmounts[i]
      );
    }
  }

  function _transferERC20Token(
    address payable archanovaAccount,
    address payable etherspotAccount,
    address payable token,
    uint256 tokensAmount
  )
    private
  {
    bytes memory data = abi.encodeWithSelector(
      TRANSFER_SELECTOR,
      etherspotAccount,
      tokensAmount
    );

    bytes memory response = ArchanovaAccount(archanovaAccount).executeTransaction(
      token,
      0,
      data
    );

    if (response.length > 0) {
      require(
        abi.decode(response, (bool)),
        "ArchanovaMigrator: ERC20Token transfer reverted"
      );
    }
  }

  function _transferERC721Tokens(
    address payable archanovaAccount,
    address payable etherspotAccount,
    address[] memory tokens,
    uint256[] memory tokensIds
  )
    private
  {
    uint tokensLen = tokens.length;

    for (uint i = 0; i < tokensLen; i++) {
      _transferERC721Token(
        archanovaAccount,
        etherspotAccount,
        payable(tokens[i]),
        tokensIds[i]
      );
    }
  }

  function _transferERC721Token(
    address payable archanovaAccount,
    address payable etherspotAccount,
    address payable token,
    uint256 tokenId
  )
  private
  {
    bytes memory data = abi.encodeWithSelector(
      TRANSFER_FROM_SELECTOR,
      archanovaAccount,
      etherspotAccount,
      tokenId
    );

    bytes memory response = ArchanovaAccount(archanovaAccount).executeTransaction(
      token,
      0,
      data
    );

    if (response.length > 0) {
      require(
        abi.decode(response, (bool)),
        "ArchanovaMigrator: ERC721 transfer from reverted"
      );
    }
  }

  function _transferENSNode(
    address payable archanovaAccount,
    address payable etherspotAccount,
    bytes32 ensNode
  )
    private
  {
    ArchanovaAccount(archanovaAccount).executeTransaction(
      ensRegistry,
      0,
      abi.encodeWithSelector(
        SET_RESOLVER_SELECTOR,
        ensNode,
        address(ensController)
      )
    );

    ArchanovaAccount(archanovaAccount).executeTransaction(
      ensController,
      0,
      abi.encodeWithSelector(
        SYNC_ADDR_SELECTOR,
        ensNode
      )
    );

    ArchanovaAccount(archanovaAccount).executeTransaction(
      ensController,
      0,
      abi.encodeWithSelector(
        SET_ADDR_SELECTOR,
        ensNode,
        etherspotAccount
      )
    );

    ArchanovaAccount(archanovaAccount).executeTransaction(
      ensRegistry,
      0,
      abi.encodeWithSelector(
        SET_OWNER_SELECTOR,
        ensNode,
        etherspotAccount
      )
    );

    emit ENSNodeTransferred(
      archanovaAccount,
      etherspotAccount,
      ensNode
    );
  }

  // private functions (views)

  function _verifyArchanovaAccountOwner(
    address payable archanovaAccount,
    address payable etherspotAccount,
    bytes memory archanovaAccountDeviceSignature
  )
    private
    view
  {
    address recovered = keccak256(abi.encodePacked(
        "\x19Ethereum Signed Message:\n32",
        keccak256(abi.encodePacked(
          chainId,
          address(this),
          MIGRATION_MESSAGE_PREFIX,
          archanovaAccount,
          etherspotAccount
        ))
      )).recoverAddress(archanovaAccountDeviceSignature);

    (bool exists, bool isOwner, ) = ArchanovaAccount(archanovaAccount).devices(
      recovered
    );

    require(
      exists && isOwner,
      "ArchanovaMigrator: Invalid archanova account device signature"
    );
  }
}

{
  "evmVersion": "istanbul",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "none",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": false,
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