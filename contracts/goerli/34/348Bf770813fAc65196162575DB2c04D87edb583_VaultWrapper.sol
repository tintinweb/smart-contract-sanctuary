// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;


interface IBridge {
    struct TONEvent {
        uint64 eventTransactionLt;
        uint32 eventTimestamp;
        bytes eventData;
        int8 configurationWid;
        uint256 configurationAddress;
        int8 eventContractWid;
        uint256 eventContractAddress;
        address proxy;
        uint32 round;
    }

    struct Round {
        uint32 end;
        uint32 ttl;
        uint32 requiredSignatures;
    }

    struct TONAddress {
        int8 wid;
        uint256 addr;
    }

    function updateMinimumRequiredSignatures(uint32 _minimumRequiredSignatures) external;
    function updateRoundRelaysConfiguration(TONAddress calldata _roundRelaysConfiguration) external;
    function updateRoundTTL(uint32 _roundTTL) external;

    function isRelay(
        uint32 round,
        address candidate
    ) external view returns(bool);

    function isBanned(
        address candidate
    ) external view returns(bool);

    function isRoundRotten(
        uint32 round
    ) external view returns(bool);

    function verifySignedTonEvent(
        bytes memory payload,
        bytes[] memory signatures
    ) external view returns(uint32);

    function setRoundRelays(
        bytes calldata payload,
        bytes[] calldata signatures
    ) external;

    function banRelays(
        address[] calldata _relays
    ) external;

    function unbanRelays(
        address[] calldata _relays
    ) external;

    function pause() external;
    function unpause() external;

    event EmergencyShutdown(bool active);

    event UpdateMinimumRequiredSignatures(uint32 value);
    event UpdateRoundTTL(uint32 value);
    event UpdateRoundRelaysConfiguration(TONAddress configuration);

    event NewRound(uint32 indexed round, Round meta);
    event RoundRelay(uint32 indexed round, address indexed relay);
    event BanRelay(address indexed relay, bool status);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;


contract ChainId {
    function getChainID() public view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./../interfaces/IBridge.sol";
import "../utils/ChainId.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";


interface IVault {
    struct TONAddress {
        int128 wid;
        uint256 addr;
    }

    function saveWithdraw(
        bytes32 id,
        address recipient,
        uint256 amount,
        uint256 bounty
    ) external;

    function configuration() external view returns(TONAddress memory _configuration);
    function bridge() external view returns(address);
}

contract VaultWrapper is ChainId, Initializable {
    address public vault;

    function initialize(
        address _vault
    ) initializer external {
        vault = _vault;
    }

    function decodeWithdrawEventData(
        bytes memory payload
    ) public pure returns (
        int8 sender_wid,
        uint256 sender_addr,
        uint128 amount,
        uint160 _recipient,
        uint32 chainId
    ) {
        (IBridge.TONEvent memory tonEvent) = abi.decode(payload, (IBridge.TONEvent));

        return abi.decode(
            tonEvent.eventData,
            (int8, uint256, uint128, uint160, uint32)
        );
    }

    function saveWithdraw(
        bytes calldata payload,
        bytes[] calldata signatures,
        uint256 bounty
    ) external {
        address bridge = IVault(vault).bridge();

        // Check signatures correct
        require(
            IBridge(bridge).verifySignedTonEvent(
                payload,
                signatures
            ) == 0,
            "Vault wrapper: signatures verification failed"
        );

        // Decode TON event
        (IBridge.TONEvent memory tonEvent) = abi.decode(payload, (IBridge.TONEvent));

        // Check event proxy is correct
        require(
            tonEvent.proxy == vault,
            "Vault wrapper: wrong event proxy"
        );

        // dev: fix stack too deep
        {
            // Check event configuration matches Vault's configuration
            IVault.TONAddress memory configuration = IVault(vault).configuration();

            require(
                tonEvent.configurationWid == configuration.wid &&
                tonEvent.configurationAddress == configuration.addr,
                "Vault wrapper: wrong event configuration"
            );
        }

        // Decode event data
        (
            int8 sender_wid,
            uint256 sender_addr,
            uint128 amount,
            uint160 _recipient,
            uint32 chainId
        ) = decodeWithdrawEventData(payload);

        // Check chain id
        require(chainId == getChainID(), "Vault wrapper: wrong chain id");

        address recipient = address(_recipient);

        IVault(vault).saveWithdraw(
            keccak256(payload),
            recipient,
            amount,
            recipient == msg.sender ? bounty : 0
        );
    }
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