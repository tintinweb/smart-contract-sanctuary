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
pragma solidity ^0.8.2;
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
        uint32 relays;
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

    function forceRoundRelays(
        uint160[] calldata _relays,
        uint32 roundEnd
    ) external;

    function banRelays(
        address[] calldata _relays
    ) external;

    function unbanRelays(
        address[] calldata _relays
    ) external;

    function pause() external;
    function unpause() external;

    function setRoundSubmitter(address _roundSubmitter) external;

    event EmergencyShutdown(bool active);

    event UpdateMinimumRequiredSignatures(uint32 value);
    event UpdateRoundTTL(uint32 value);
    event UpdateRoundRelaysConfiguration(TONAddress configuration);
    event UpdateRoundSubmitter(address _roundSubmitter);

    event NewRound(uint32 indexed round, Round meta);
    event RoundRelay(uint32 indexed round, address indexed relay);
    event BanRelay(address indexed relay, bool status);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.2;


interface IVault {
    struct TONAddress {
        int128 wid;
        uint256 addr;
    }

    struct PendingWithdrawalId {
        address recipient;
        uint256 id;
    }

    function saveWithdraw(
        bytes32 payloadId,
        address recipient,
        uint256 amount,
        uint256 bounty
    ) external;

    function deposit(
        address sender,
        TONAddress calldata recipient,
        uint256 _amount,
        PendingWithdrawalId calldata pendingWithdrawalId,
        bool sendTransferToTon
    ) external;

    function configuration() external view returns(TONAddress memory _configuration);
    function bridge() external view returns(address);
    function apiVersion() external view returns(string memory api_version);

    function initialize(
        address _token,
        address _governance,
        address _bridge,
        address _wrapper,
        address guardian,
        address management,
        uint256 targetDecimals
    ) external;

    function governance() external view returns(address);
    function token() external view returns(address);
    function wrapper() external view returns(address);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.2;


interface IVaultWrapper {
    function initialize(address _vault) external;
    function apiVersion() external view returns(string memory);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.2;


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
pragma solidity ^0.8.2;

import "./../interfaces/IBridge.sol";
import "./../interfaces/IVault.sol";
import "./../interfaces/IVaultWrapper.sol";
import "./../utils/ChainId.sol";


import "@openzeppelin/contracts/proxy/utils/Initializable.sol";


contract VaultWrapper is ChainId, Initializable, IVaultWrapper {
    address constant ZERO_ADDRESS = 0x0000000000000000000000000000000000000000;
    string constant API_VERSION = "0.1.0";

    address public vault;

    function initialize(
        address _vault
    ) external override initializer {
        vault = _vault;
    }

    function apiVersion()
        external
        override
        pure
    returns (
        string memory api_version
    ) {
        return API_VERSION;
    }

    /**
        @notice
            Most common entry point for Broxus Bridge.this
            Simply transfers tokens to the FreeTON side.
        @param recipient Recipient TON address
        @param amount Amount of tokens to be deposited
    */
    function deposit(
        IVault.TONAddress memory recipient,
        uint256 amount
    ) external {
        IVault.PendingWithdrawalId memory pendingWithdrawalId = IVault.PendingWithdrawalId(ZERO_ADDRESS, 0);

        IVault(vault).deposit(
            msg.sender,
            recipient,
            amount,
            pendingWithdrawalId,
            true
        );
    }

    event FactoryDeposit(
        uint128 amount,
        int8 wid,
        uint256 user,
        uint256 creditor,
        uint256 recipient,
        uint128 tokenAmount,
        uint128 tonAmount,
        uint8 swapType,
        uint128 slippageNumerator,
        uint128 slippageDenominator,
        bytes1 separator,
        bytes level3
    );

    function depositToFactory(
        uint128 amount,
        int8 wid,
        uint256 user,
        uint256 creditor,
        uint256 recipient,
        uint128 tokenAmount,
        uint128 tonAmount,
        uint8 swapType,
        uint128 slippageNumerator,
        uint128 slippageDenominator,
        bytes memory level3
    ) external {
        require(
            tokenAmount <= amount &&
            swapType < 2 &&
            user != 0 &&
            recipient != 0 &&
            creditor != 0 &&
            slippageNumerator < slippageDenominator,
            "Wrapper: wrong args"
        );

        IVault(vault).deposit(
            msg.sender,
            IVault.TONAddress(0, 0),
            amount,
            IVault.PendingWithdrawalId(ZERO_ADDRESS, 0),
            false
        );

        emit FactoryDeposit(
            amount,
            wid,
            user,
            creditor,
            recipient,
            tokenAmount,
            tonAmount,
            swapType,
            slippageNumerator,
            slippageDenominator,
            0x07,
            level3
        );
    }

    /**
        @notice
            Special type of deposit, which allows to fill specified
            pending withdrawals. Set of fillings should be created off-chain.
            Usually allows depositor to receive additional reward (bounty) on the FreeTON side.
        @param recipient Recipient TON address
        @param amount Amount of tokens to be deposited, should be gte than sum(fillings)
        @param pendingWithdrawalsIdsToFill List of pending withdrawals ids
    */
    function depositWithFillings(
        IVault.TONAddress calldata recipient,
        uint256 amount,
        IVault.PendingWithdrawalId[] calldata pendingWithdrawalsIdsToFill
    ) external {
        require(
            pendingWithdrawalsIdsToFill.length > 0,
            'Wrapper: no pending withdrawals specified'
        );

        for (uint i = 0; i < pendingWithdrawalsIdsToFill.length; i++) {
            IVault(vault).deposit(
                msg.sender,
                recipient,
                amount,
                pendingWithdrawalsIdsToFill[i],
                true
            );
        }
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

    /**
        @notice Entry point for withdrawing tokens from the Broxus Bridge.
        Expects payload with withdraw details and list of relay's signatures.
        @param payload Bytes encoded `IBridge.TONEvent` structure
        @param signatures Set of relay's signatures
        @param bounty Pending withdraw bounty, can be set only by withdraw recipient. Ignores otherwise.
    */
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