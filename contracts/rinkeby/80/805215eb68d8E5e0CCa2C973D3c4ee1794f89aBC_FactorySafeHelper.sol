// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./interfaces/IFactorySafeHelper.sol";
import "./interfaces/IGnosisSafe.sol";
import "./interfaces/IGnosisSafeProxyFactory.sol";
import "./interfaces/IGnosisSafeModuleProxyFactory.sol";
import "./interfaces/IWyvernProxyRegistry.sol";

contract FactorySafeHelper is IFactorySafeHelper {
    IGnosisSafeProxyFactory public immutable GNOSIS_SAFE_PROXY_FACTORY;
    IGnosisSafeModuleProxyFactory
        public immutable GNOSIS_SAFE_MODULE_PROXY_FACTORY;

    address public immutable ORACLE;
    address public immutable GNOSIS_SAFE_TEMPLATE_ADDRESS;
    address public immutable GNOSIS_SAFE_FALLBACK_HANDLER;
    address public immutable REALITY_MODULE_TEMPLATE_ADDRESS;
    address public immutable WYVERN_PROXY_REGISTRY;
    address public immutable SZNS_DAO;
    uint256 public immutable REALITIO_TEMPLATE_ID;

    uint256 public immutable DAO_MODULE_BOND;
    uint32 public immutable DAO_MODULE_EXPIRATION;
    uint32 public immutable DAO_MODULE_TIMEOUT;

    constructor(
        address proxyFactoryAddress,
        address moduleProxyFactoryAddress,
        address realitioAddress,
        address safeTemplateAddress,
        address safeFallbackHandler,
        address realityModuleTemplateAddress,
        address wyvernProxyRegistry,
        address sznsDao,
        uint256 realitioTemplateId,
        uint256 bond,
        uint32 expiration,
        uint32 timeout
    ) {
        GNOSIS_SAFE_PROXY_FACTORY = IGnosisSafeProxyFactory(
            proxyFactoryAddress
        );
        GNOSIS_SAFE_MODULE_PROXY_FACTORY = IGnosisSafeModuleProxyFactory(
            moduleProxyFactoryAddress
        );
        ORACLE = realitioAddress;

        GNOSIS_SAFE_TEMPLATE_ADDRESS = safeTemplateAddress;
        GNOSIS_SAFE_FALLBACK_HANDLER = safeFallbackHandler;
        REALITY_MODULE_TEMPLATE_ADDRESS = realityModuleTemplateAddress;
        WYVERN_PROXY_REGISTRY = wyvernProxyRegistry;
        SZNS_DAO = sznsDao;
        REALITIO_TEMPLATE_ID = realitioTemplateId;

        DAO_MODULE_BOND = bond;
        DAO_MODULE_EXPIRATION = expiration;
        DAO_MODULE_TIMEOUT = timeout;
    }

    function createAndSetupSafe(bytes32 salt)
        external
        override
        returns (address safeAddress, address realityModule)
    {
        salt = keccak256(abi.encodePacked(salt, msg.sender, address(this)));
        // Deploy safe
        IGnosisSafe safe = GNOSIS_SAFE_PROXY_FACTORY.createProxyWithNonce(
            GNOSIS_SAFE_TEMPLATE_ADDRESS,
            "",
            uint256(salt)
        );
        safeAddress = address(safe);
        // Deploy reality module
        realityModule = GNOSIS_SAFE_MODULE_PROXY_FACTORY.deployModule(
            REALITY_MODULE_TEMPLATE_ADDRESS,
            abi.encodeWithSignature(
                "setUp(bytes)",
                abi.encode(
                    safeAddress,
                    safeAddress,
                    safeAddress,
                    ORACLE,
                    DAO_MODULE_TIMEOUT,
                    0, // cooldown, hard-coded to 0
                    DAO_MODULE_EXPIRATION,
                    DAO_MODULE_BOND,
                    REALITIO_TEMPLATE_ID,
                    SZNS_DAO
                )
            ),
            0 // salt
        );
        // Initialize safe
        address[] memory owners = new address[](1);
        owners[0] = 0x000000000000000000000000000000000000dEaD;
        safe.setup(
            owners, // owners
            1, // threshold
            address(this), // to
            abi.encodeWithSignature( // data
                "initSafe(address, address)",
                realityModule,
                WYVERN_PROXY_REGISTRY
            ),
            GNOSIS_SAFE_FALLBACK_HANDLER, // fallbackHandler
            address(0), // paymentToken
            0, // payment
            payable(0) // paymentReceiver
        );
    }

    function initSafe(
        address realityModuleAddress,
        address wyvernProxyRegistryAddress
    ) external {
        IGnosisSafe(address(this)).enableModule(realityModuleAddress);
        // IWyvernProxyRegistry(wyvernProxyRegistryAddress).registerProxy();
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IFactorySafeHelper {
    function createAndSetupSafe(bytes32 salt)
        external
        returns (address safeAddress, address);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

// Pared down version of @gnosis.pm/safe-contracts/contracts/GnosisSafe.sol

/// @title Gnosis Safe - A multisignature wallet with support for confirmations using signed messages based on ERC191.
/// @author Stefan George - <[email protected]>
/// @author Richard Meissner - <[email protected]>
interface IGnosisSafe {
    /// @dev Setup function sets initial storage of contract.
    /// @param _owners List of Safe owners.
    /// @param _threshold Number of required confirmations for a Safe transaction.
    /// @param to Contract address for optional delegate call.
    /// @param data Data payload for optional delegate call.
    /// @param fallbackHandler Handler for fallback calls to this contract
    /// @param paymentToken Token that should be used for the payment (0 is ETH)
    /// @param payment Value that should be paid
    /// @param paymentReceiver Adddress that should receive the payment (or 0 if tx.origin)
    function setup(
        address[] calldata _owners,
        uint256 _threshold,
        address to,
        bytes calldata data,
        address fallbackHandler,
        address paymentToken,
        uint256 payment,
        address payable paymentReceiver
    ) external;

    /// @dev Allows to add a module to the whitelist.
    ///      This can only be done via a Safe transaction.
    /// @notice Enables the module `module` for the Safe.
    /// @param module Module to be whitelisted.
    function enableModule(address module) external;

    /// @dev Returns if an module is enabled
    /// @return True if the module is enabled
    function isModuleEnabled(address module) external view returns (bool);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

// Pared down version of @gnosis.pm/safe-contracts/contracts/proxies/GnosisSafeProxyFactory.sol

import {IGnosisSafe} from "./IGnosisSafe.sol";

/// @title Proxy Factory - Allows to create new proxy contact and execute a message call to the new proxy within one transaction.
/// @author Stefan George - <[email protected]>
interface IGnosisSafeProxyFactory {
    /// @dev Allows to create new proxy contact and execute a message call to the new proxy within one transaction.
    /// @param _singleton Address of singleton contract.
    /// @param initializer Payload for message call sent to new proxy contract.
    /// @param saltNonce Nonce that will be used to generate the salt to calculate the address of the new proxy contract.
    function createProxyWithNonce(
        address _singleton,
        bytes memory initializer,
        uint256 saltNonce
    ) external returns (IGnosisSafe proxy);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IGnosisSafeModuleProxyFactory {
    function deployModule(
        address masterCopy,
        bytes memory initializer,
        uint256 saltNonce
    ) external returns (address proxy);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IWyvernProxyRegistry {
    function registerProxy() external returns (address proxy);
}