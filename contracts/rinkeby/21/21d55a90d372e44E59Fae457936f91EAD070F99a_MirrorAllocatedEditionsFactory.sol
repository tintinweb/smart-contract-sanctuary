// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import {MirrorProxy} from "../../lib/MirrorProxy.sol";
import {ITributaryRegistry} from "../../treasury/interface/ITributaryRegistry.sol";
import {IMirrorAllocatedEditionsFactory, IMirrorAllocatedEditionsFactoryEvents, IOwnableEvents} from "./interface/IMirrorAllocatedEditionsFactory.sol";
import {IMirrorAllocatedEditionsLogic} from "./interface/IMirrorAllocatedEditionsLogic.sol";
import {IMirrorOpenSaleV0Events} from "../../distributors/open-sale/interface/IMirrorOpenSale.sol";
import {IERC2309} from "../../lib/ERC2309/interface/IERC2309.sol";

/**
 * @title MirrorAllocatedEditionsFactory
 * @author MirrorXYZ
 * The MirrorAllocatedEditionsFactory contract is used to deploy edition proxies.
 */
contract MirrorAllocatedEditionsFactory is
    IMirrorAllocatedEditionsFactory,
    IMirrorAllocatedEditionsFactoryEvents,
    IMirrorOpenSaleV0Events,
    IERC2309,
    IOwnableEvents
{
    /// @notice Address that holds the tributary registry for Mirror treasury
    address public immutable tributaryRegistry;

    /// @notice Address that holds the relayer logic for Crowdfunds
    address public logic;

    constructor(address tributaryRegistry_, address logic_) {
        tributaryRegistry = tributaryRegistry_;
        logic = logic_;
    }

    // ======== Deploy function =========

    /**
     * @notice Deploys a crowdfund proxy, creates a crowdfund, and
     * registers the new proxies tributary.
     */
    function deploy(
        IMirrorAllocatedEditionsLogic.NFTMetadata memory metadata,
        address operator_,
        address tributary_,
        address payable fundingRecipient_,
        address payable royaltyRecipient_,
        uint256 royaltyPercentage_,
        uint256 price,
        bool list,
        bool open
    ) external override returns (address proxy) {
        bytes memory initializationData = abi.encodeWithSelector(
            IMirrorAllocatedEditionsLogic.initialize.selector,
            metadata,
            operator_,
            fundingRecipient_,
            royaltyRecipient_,
            royaltyPercentage_,
            price,
            list,
            open
        );

        proxy = address(
            new MirrorProxy{
                salt: keccak256(
                    abi.encode(
                        operator_,
                        metadata.name,
                        metadata.symbol,
                        metadata.baseURI
                    )
                )
            }(logic, initializationData)
        );

        emit EditionsProxyDeployed(proxy, operator_, logic);

        ITributaryRegistry(tributaryRegistry).registerTributary(
            proxy,
            tributary_
        );
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

/**
 * @title MirrorProxy
 * @author MirrorXYZ
 * The MirrorProxy contract is used to deploy minimal proxies.
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
     * @notice Initializes a proxy by delegating logic to the implementation,
     * and reverts if the call is not successful. Stores implementation logic.
     * @param implementation - the implementation holds the logic for all proxies
     * @param initializationData - initialization call
     */
    constructor(address implementation, bytes memory initializationData) {
        // Delegatecall into the implementation, supplying initialization calldata.
        (bool ok, ) = implementation.delegatecall(initializationData);

        // Revert and include revert data if delegatecall to implementation reverts.
        if (!ok) {
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }

        assembly {
            sstore(_IMPLEMENTATION_SLOT, implementation)
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

import {IMirrorAllocatedEditionsLogic} from "./IMirrorAllocatedEditionsLogic.sol";

interface IMirrorAllocatedEditionsFactoryEvents {
    event EditionsProxyDeployed(address proxy, address operator, address logic);
}

interface IMirrorAllocatedEditionsFactory {
    function deploy(
        IMirrorAllocatedEditionsLogic.NFTMetadata memory metadata,
        address operator_,
        address tributary_,
        address payable fundingRecipient_,
        address payable royaltyRecipient_,
        uint256 royaltyPercentage_,
        uint256 price,
        bool list,
        bool open
    ) external returns (address proxy);
}

interface IOwnableEvents {
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

interface IMirrorAllocatedEditionsLogic {
    // ============ Events ============

    event RoyaltyChange(
        address indexed oldRoyaltyRecipient,
        uint256 oldRoyaltyPercentage,
        address indexed newRoyaltyRecipient,
        uint256 newRoyaltyPercentage
    );

    // ============ Structs ============

    // Contains general data about the NFT.
    struct NFTMetadata {
        string name;
        string symbol;
        string baseURI;
        bytes32 contentHash;
        uint256 quantity;
    }

    function initialize(
        NFTMetadata memory metadata,
        address operator_,
        address payable fundingRecipient_,
        address payable royaltyRecipient_,
        uint256 royaltyPercentage_,
        uint256 price,
        bool list,
        bool open
    ) external;

    function setRoyaltyInfo(
        address payable royaltyRecipient_,
        uint256 royaltyPercentage_
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

interface IMirrorOpenSaleV0Events {
    event RegisteredSale(
        bytes32 h,
        address indexed token,
        uint256 startTokenId,
        uint256 endTokenId,
        address indexed operator,
        address indexed recipient,
        uint256 price,
        bool open
    );

    event Purchase(
        bytes32 h,
        address indexed token,
        uint256 tokenId,
        address indexed buyer,
        address indexed recipient
    );

    event Withdraw(
        bytes32 h,
        uint256 amount,
        uint256 fee,
        address indexed recipient
    );

    event OpenSale(bytes32 h);

    event CloseSale(bytes32 h);

    /// ERC721 Events

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );
}

interface IMirrorOpenSaleV0 {
    struct Sale {
        bool open;
        uint256 sold;
        address operator;
    }

    struct SaleConfig {
        address token;
        uint256 startTokenId;
        uint256 endTokenId;
        address operator;
        address recipient;
        uint256 price;
        bool open;
    }

    function count() external returns (uint256);

    function treasuryConfig() external returns (address);

    function feeRegistry() external returns (address);

    function tributaryRegistry() external returns (address);

    function sale(bytes32 h) external view returns (Sale memory);

    function register(SaleConfig calldata saleConfig_) external;

    function close(SaleConfig calldata saleConfig_) external;

    function open(SaleConfig calldata saleConfig_) external;

    function purchase(SaleConfig calldata saleConfig_, address recipient)
        external
        payable;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

interface IERC2309 {
    event ConsecutiveTransfer(
        uint256 indexed fromTokenId,
        uint256 toTokenId,
        address indexed fromAddress,
        address indexed toAddress
    );
}