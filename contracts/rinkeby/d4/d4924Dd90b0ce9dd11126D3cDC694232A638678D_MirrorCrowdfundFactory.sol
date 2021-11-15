// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import {MirrorProxy} from "../MirrorProxy.sol";
import {ITributaryRegistry} from "../../../interface/ITributaryRegistry.sol";
import {IMirrorCrowdfundRelayer} from "./interface/IMirrorCrowdfundRelayer.sol";

/**
 * @title MirrorCrowdfundFactory
 * @author MirrorXYZ
 * The MirrorCrowdfundFactory contract is used to deploy crowdfund proxies using the
 * proxy-relayer pattern. With the proxy-relayer pattern, the storage for all proxies
 * is held in a single storage contract. The proxy delegates calls to a relayer contract
 * that calls into the storage contract. This pattern allows us to deploy small proxies that
 * do not need any storage allocation with minimal gas.
 */
contract MirrorCrowdfundFactory {
    event MirrorProxyDeployed(address proxy, address operator, address relayer);

    struct CrowdfundConfig {
        uint256 fundingCap;
        uint256 token;
        uint256 exchangeRate;
        address faucet;
        address fundingRecipient;
    }

    /// @notice Tributary registry used for rewards
    address public immutable tributaryRegistry;

    /// @notice Relayer address used for deploying a crowdfund proxy
    address public crowdfundRelayer;

    /// @notice Sets owner and relayers.
    constructor(address tributaryRegistry_, address crowdfundRelayer_) {
        tributaryRegistry = tributaryRegistry_;
        crowdfundRelayer = crowdfundRelayer_;
    }

    // ======== Deploy function =========

    /**
     * @notice Deploys a crowdfund proxy, creates a crowdfund, and
     * registers the new proxies tributary. Emits a MirrorProxyDeployed
     * event with the crowdfund-relayer address.
     */
    function deployAndCreateCrowdfund(
        address tributary,
        CrowdfundConfig memory crowdfund
    ) external returns (address proxy) {
        address operator = msg.sender;

        bytes memory initializationData = abi.encodeWithSelector(
            IMirrorCrowdfundRelayer.initializeAndCreateCrowdfund.selector,
            operator,
            crowdfund
        );

        proxy = address(
            new MirrorProxy{salt: keccak256(abi.encode(operator))}(
                crowdfundRelayer,
                initializationData
            )
        );

        emit MirrorProxyDeployed(proxy, operator, crowdfundRelayer);

        ITributaryRegistry(tributaryRegistry).registerTributary(
            proxy,
            tributary
        );
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

/**
 * @title MirrorProxy
 * @author MirrorXYZ
 * The MirrorProxy contract is used to deploy minimal contracts for multiple
 * economic producers on the Mirror ecosystem (e.g. crowdfunds, editions). The
 * proxies are used with the proxy-relayer pattern. The proxy delegates calls
 * to a relayer contract that calls into the storage contract. The proxy uses the
 * EIP-1967 standard to store the "implementation" logic, which in our case is
 * the relayer contract. The relayer logic is directly stored into the standard
 * slot using `sstore` in the constructor, and read using `sload` in the fallback
 * function.
 */
contract MirrorProxy {
    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @notice Initializes a proxy by delegating logic to the relayer,
     * and reverts if the call is not successful. Stores relayer logic.
     * @param relayer - the relayer holds the logic for all proxies
     * @param initializationData - initialization call
     */
    constructor(address relayer, bytes memory initializationData) {
        // Delegatecall into the relayer, supplying initialization calldata.
        (bool ok, ) = relayer.delegatecall(initializationData);

        // Revert and include revert data if delegatecall to implementation reverts.
        if (!ok) {
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }

        assembly {
            sstore(_IMPLEMENTATION_SLOT, relayer)
        }
    }

    /**
     * @notice When any function is called on this contract, we delegate to
     * the logic contract stored in the implementation storage slot.
     */
    fallback() external payable {
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(
                gas(),
                sload(_IMPLEMENTATION_SLOT),
                ptr,
                calldatasize(),
                0,
                0
            )
            let size := returndatasize()
            returndatacopy(ptr, 0, size)

            switch result
            case 0 {
                revert(ptr, size)
            }
            default {
                return(ptr, size)
            }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

interface ITributaryRegistry {
    function addRegistrar(address registrar) external;

    function removeRegistrar(address registrar) external;

    function addSingletonProducer(address producer) external;

    function removeSingletonProducer(address producer) external;

    function registerTributary(address producer, address tributary) external;

    function producerToTributary(address producer)
        external
        returns (address tributary);

    function singletonProducer(address producer) external returns (bool);

    function changeTributary(address producer, address newTributary) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import {IMirrorCrowdfundProxyStorage} from "./IMirrorCrowdfundProxyStorage.sol";

interface IMirrorCrowdfundRelayerEvents {
    event CrowdfundContribution(
        uint256 indexed crowdfundId,
        address indexed backer,
        uint256 contributionAmount
    );

    event Withdrawal(
        uint256 indexed crowdfundId,
        address indexed fundingRecipient,
        uint256 amount,
        uint256 fee
    );
}

interface IMirrorCrowdfundRelayer {
    function initializeAndCreateCrowdfund(
        address operator_,
        IMirrorCrowdfundProxyStorage.CrowdfundConfig memory crowdfund
    ) external returns (uint256 crowdfundId);

    function createCrowdfund(
        IMirrorCrowdfundProxyStorage.CrowdfundConfig memory crowdfund
    ) external returns (uint256 crowdfundId);

    function operator() external view returns (address);

    function closeFunding(uint256 crowdfundId, uint256 feePercentage_) external;

    function withdraw(uint256 crowdfundId, uint256 feePercentage) external;
}

interface IERC20 {
    /// @notice EIP-20 transfer _value_ to _to_ from _from_
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

interface IMirrorCrowdfundProxyStorageEvents {
    /// @notice Emitted when a new proxy is registered
    event NewCrowdfundProxy(address indexed proxy, address indexed operator);

    /// @notice Create edition
    event CrowdfundCreated(
        address indexed proxy,
        uint256 fundingCap,
        address token,
        uint256 exchangeRate,
        address faucet,
        uint256 indexed crowdfundId,
        address indexed fundingRecipient
    );
}

interface IMirrorCrowdfundProxyStorage {
    struct Crowdfund {
        uint256 fundingCap;
        address token;
        uint256 exchangeRate;
        address faucet;
        uint256 funding;
        address fundingRecipient;
        uint256 balance;
        bool closed;
    }

    struct CrowdfundConfig {
        uint256 fundingCap;
        address token;
        uint256 exchangeRate;
        address faucet;
        address fundingRecipient;
    }

    function operator(address account) external view returns (address);

    function initializeAndCreateCrowdfund(
        address operator_,
        IMirrorCrowdfundProxyStorage.CrowdfundConfig memory crowdfund
    ) external returns (uint256 crowdfundId);

    function createCrowdfund(
        address sender,
        IMirrorCrowdfundProxyStorage.CrowdfundConfig memory crowdfund
    ) external returns (uint256 crowdfundId);

    function contributeToCrowdfund(uint256 crowdfundId, uint256 amount)
        external;

    function getCrowdfund(address proxy, uint256 crowdfundId)
        external
        view
        returns (Crowdfund memory);

    function resetBalance(uint256 crowdfundId) external;

    function closeFunding(uint256 crowdfundId) external;
}

