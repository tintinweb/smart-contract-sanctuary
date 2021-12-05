// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

import {MirrorProxy} from "../../lib/MirrorProxy.sol";
import {IMirrorAllocatedEditionsFactory, IMirrorAllocatedEditionsFactoryEvents, IOwnableEvents} from "./interface/IMirrorAllocatedEditionsFactory.sol";
import {IMirrorAllocatedEditionsLogic} from "./interface/IMirrorAllocatedEditionsLogic.sol";
import {IMirrorOpenSaleV0Events} from "../../distributors/open-sale/interface/IMirrorOpenSaleV0.sol";
import {IERC2309} from "../../lib/ERC2309/interface/IERC2309.sol";
import {IERC721Events} from "../../lib/ERC721/interface/IERC721.sol";

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
    IOwnableEvents,
    IERC721Events
{
    /// @notice Address that holds the tributary registry for Mirror treasury
    address public immutable tributaryRegistry;

    /// @notice Address that holds the logic for editions
    address public logic;

    constructor(address tributaryRegistry_, address logic_) {
        tributaryRegistry = tributaryRegistry_;
        logic = logic_;
    }

    // ======== Deploy function =========

    /// @notice Deploy an editions proxy
    function deploy(
        IMirrorAllocatedEditionsLogic.NFTMetadata memory metadata,
        address operator_,
        address payable fundingRecipient_,
        address payable royaltyRecipient_,
        uint256 royaltyPercentage_,
        uint256 price,
        bool list,
        bool open,
        uint256 feePercentage
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
            open,
            feePercentage
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
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

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
pragma solidity 0.8.10;

import {IMirrorAllocatedEditionsLogic} from "./IMirrorAllocatedEditionsLogic.sol";

interface IMirrorAllocatedEditionsFactoryEvents {
    event EditionsProxyDeployed(address proxy, address operator, address logic);
}

interface IMirrorAllocatedEditionsFactory {
    function deploy(
        IMirrorAllocatedEditionsLogic.NFTMetadata memory metadata,
        address operator_,
        address payable fundingRecipient_,
        address payable royaltyRecipient_,
        uint256 royaltyPercentage_,
        uint256 price,
        bool list,
        bool open,
        uint256 feePercentage
    ) external returns (address proxy);
}

interface IOwnableEvents {
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

interface IMirrorAllocatedEditionsLogic {
    event RoyaltyChange(
        address indexed oldRoyaltyRecipient,
        uint256 oldRoyaltyPercentage,
        address indexed newRoyaltyRecipient,
        uint256 newRoyaltyPercentage
    );

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
        bool open,
        uint256 feePercentage
    ) external;

    function setRoyaltyInfo(
        address payable royaltyRecipient_,
        uint256 royaltyPercentage_
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

interface IMirrorOpenSaleV0Events {
    event RegisteredSale(
        bytes32 h,
        address indexed token,
        uint256 startTokenId,
        uint256 endTokenId,
        address indexed operator,
        address indexed recipient,
        uint256 price,
        bool open,
        uint256 feePercentage
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
        uint256 feePercentage;
    }

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
pragma solidity 0.8.10;

interface IERC2309 {
    event ConsecutiveTransfer(
        uint256 indexed fromTokenId,
        uint256 toTokenId,
        address indexed fromAddress,
        address indexed toAddress
    );
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

interface IERC721 {
    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

interface IERC721Events {
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

interface IERC721Metadata {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}

interface IERC721Burnable is IERC721 {
    function burn(uint256 tokenId) external;
}

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

interface IERC721Royalties {
    function getFeeRecipients(uint256 id)
        external
        view
        returns (address payable[] memory);

    function getFeeBps(uint256 id) external view returns (uint256[] memory);
}