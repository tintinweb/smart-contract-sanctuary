// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import {ITributaryRegistry} from "../../../interface/ITributaryRegistry.sol";
import {Governable} from "../../../lib/Governable.sol";
import {AllocatedEditionsProxy} from "./AllocatedEditionsProxy.sol";
import {AllocatedEditionsStorage} from "./AllocatedEditionsStorage.sol";
import {IERC2309} from "../../../external/interface/IERC2309.sol";

/**
 * @title AllocatedEditionsFactory
 * @author MirrorXYZ
 */
contract AllocatedEditionsFactory is Governable, IERC2309 {
    //======== Structs ========

    struct Parameters {
        // NFT Metadata
        bytes nftMetaData;
        // Edition Data
        uint256 allocation;
        uint256 quantity;
        uint256 price;
        // Admint Data
        bytes adminData;
    }

    //======== Events ========

    event AllocatedEditionDeployed(
        address allocatedEditionProxy,
        string name,
        string symbol,
        address operator
    );

    //======== Mutable storage =========

    /// @notice Gets set within the block, accessed from the proxy and then deleted.
    Parameters public parameters;

    /// @notice Minimum fee percentage collected by the treasury when withdrawing funds.
    uint256 public minFeePercentage = 250;

    /// @notice Contract logic for the edition deployed. 
    address public logic;

    address public tributaryRegistry;

    address public treasuryConfig;

    //======== Constructor =========
    constructor(
        address owner_,
        address logic_,
        address tributaryRegistry_,
        address treasuryConfig_
    ) Governable(owner_) {
        logic = logic_;
        tributaryRegistry = tributaryRegistry_;
        treasuryConfig = treasuryConfig_;
    }

    //======== Configuration =========

    function setMinimumFeePercentage(uint256 newMinFeePercentage)
        public
        onlyGovernance
    {
        minFeePercentage = newMinFeePercentage;
    }

    function setLogic(address newLogic) public onlyGovernance {
        logic = newLogic;
    }

    function setTreasuryConfig(address newTreasuryConfig)
        public
        onlyGovernance
    {
        treasuryConfig = newTreasuryConfig;
    }

    function setTributaryRegistry(address newTributaryRegistry)
        public
        onlyGovernance
    {
        tributaryRegistry = newTributaryRegistry;
    }

    //======== Proxy Deployments =========

    /// @notice Creates an edition by deploying a new proxy.
   function createEdition(
        AllocatedEditionsStorage.NFTMetadata memory metadata,
        AllocatedEditionsStorage.EditionData memory editionData,
        AllocatedEditionsStorage.AdminData memory adminData
    ) external returns (address allocatedEditionsProxy) {
        require(
            adminData.feePercentage >= minFeePercentage,
            "fee is too low"
        );

        parameters = Parameters({
            // NFT Metadata
            nftMetaData: abi.encode(
                metadata.name,
                metadata.symbol,
                metadata.baseURI,
                metadata.contentHash
            ),
            // Edition Data
            allocation: editionData.allocation,
            quantity: editionData.quantity,
            price: editionData.price,
            // Admin Data
            adminData: abi.encode(
                adminData.operator,
                adminData.tributary,
                adminData.fundingRecipient,
                adminData.feePercentage,
                treasuryConfig
            )
        });

        // deploys proxy
        allocatedEditionsProxy = address(
            new AllocatedEditionsProxy{
                salt: keccak256(abi.encode(metadata.symbol, adminData.operator))
            }(adminData.operator)
        );

        delete parameters;

        emit AllocatedEditionDeployed(
            allocatedEditionsProxy,
            metadata.name,
            metadata.symbol,
            adminData.operator
        );

        ITributaryRegistry(tributaryRegistry).registerTributary(
            allocatedEditionsProxy,
            adminData.tributary
        );
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

import {Ownable} from "../lib/Ownable.sol";
import {IGovernable} from "../lib/interface/IGovernable.sol";

contract Governable is Ownable, IGovernable {
    // ============ Mutable Storage ============

    // Mirror governance contract.
    address public override governor;

    // ============ Modifiers ============

    modifier onlyGovernance() {
        require(isOwner() || isGovernor(), "caller is not governance");
        _;
    }

    modifier onlyGovernor() {
        require(isGovernor(), "caller is not governor");
        _;
    }

    // ============ Constructor ============

    constructor(address owner_) Ownable(owner_) {}

    // ============ Administration ============

    function changeGovernor(address governor_) public override onlyGovernance {
        governor = governor_;
    }

    // ============ Utility Functions ============

    function isGovernor() public view override returns (bool) {
        return msg.sender == governor;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import {IERC2309} from "../../../external/interface/IERC2309.sol";
import {AllocatedEditionsStorage} from "./AllocatedEditionsStorage.sol";
import {IAllocatedEditionsFactory} from "./interface/IAllocatedEditionsFactory.sol";
import {Governable} from "../../../lib/Governable.sol";

/**
 * @title AllocatedEditionsProxy
 * @author MirrorXYZ
 */
contract AllocatedEditionsProxy is
    AllocatedEditionsStorage,
    Governable,
    IERC2309
{
    /// @notice IERC721Metadata
    string public name;
    string public symbol;

    constructor(address owner_) Governable(owner_) {
        logic = IAllocatedEditionsFactory(msg.sender).logic();

        bytes memory nftMetaData;
        bytes memory adminData;

        (
            // NFT Metadata
            nftMetaData,
            // Edition Data
            allocation,
            quantity,
            price,
            // Admin data
            adminData
        ) = IAllocatedEditionsFactory(msg.sender).parameters();

        (name, symbol, baseURI, contentHash) = abi.decode(
            nftMetaData,
            (string, string, string, bytes32)
        );

        (
            operator,
            tributary,
            fundingRecipient,
            feePercentage,
            treasuryConfig
        ) = abi.decode(
            adminData,
            (address, address, address, uint256, address)
        );

        if (allocation > 0) {
            nextTokenId = allocation;

            emit ConsecutiveTransfer(0, allocation - 1, address(0), operator);
        }
    }

    fallback() external payable {
        address _impl = logic;
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(gas(), _impl, ptr, calldatasize(), 0, 0)
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

    receive() external payable {}
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

/**
 * @title AllocatedEditionsStorage
 * @author MirrorXYZ
 */
contract AllocatedEditionsStorage {
    // ============ Structs ============

    /// @notice Contains general data about the NFT.
    struct NFTMetadata {
        string name;
        string symbol;
        string baseURI;
        bytes32 contentHash;
    }

    /// @notice Contains information pertaining to the edition spec.
    struct EditionData {
        // The number of tokens pre-allocated to the minter.
        uint256 allocation;
        // The maximum number of tokens that can be sold.
        uint256 quantity;
        // The price at which each token will be sold, in ETH.
        uint256 price;
    }

    /// @notice Contains information about funds disbursement.
    struct AdminData {
        // Operator of this contract, receives premint.
        address operator;
        // Address that receive gov tokens via treasury.
        address tributary;
        // The account that will receive sales revenue.
        address payable fundingRecipient;
        // The fee taken when withdrawing funds
        uint256 feePercentage;
    }

    // ============ Storage for Setup ============

    /// @notice NFTMetadata`
    string public baseURI;
    bytes32 contentHash;

    /// @notice EditionData
    uint256 public allocation;
    uint256 public quantity;
    uint256 public price;

    /// @notice EditionConfig
    address public operator;
    address public tributary;
    address payable fundingRecipient;
    uint256 feePercentage;

    /// @notice Treasury Config, provided at setup, for finding the treasury address.
    address treasuryConfig;

    // ============ Mutable Runtime Storage ============

    /// @notice `nextTokenId` increments with each token purchased, globally across all editions.
    uint256 internal nextTokenId;
    /// @notice The number of tokens that have moved outside of the pre-mint allocation.
    uint256 internal allocationsTransferred = 0;

    /**
     * @notice A special mapping of burned tokens, to take care of burning within
     * the tokenId range of the allocation.
     */
    mapping(uint256 => bool) internal _burned;

    // ============ Mutable Internal NFT Storage ============

    mapping(uint256 => address) internal _owners;
    mapping(address => uint256) internal _balances;
    mapping(uint256 => address) internal _tokenApprovals;
    mapping(address => mapping(address => bool)) internal _operatorApprovals;

    // ============ Delegation logic ============
    address public logic;
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

contract Ownable {
    address public owner;
    address private nextOwner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    // modifiers

    modifier onlyOwner() {
        require(isOwner(), "caller is not the owner.");
        _;
    }

    modifier onlyNextOwner() {
        require(isNextOwner(), "current owner must set caller as next owner.");
        _;
    }

    /**
     * @dev Initialize contract by setting transaction submitter as initial owner.
     */
    constructor(address owner_) {
        owner = owner_;
        emit OwnershipTransferred(address(0), owner);
    }

    /**
     * @dev Initiate ownership transfer by setting nextOwner.
     */
    function transferOwnership(address nextOwner_) external onlyOwner {
        require(nextOwner_ != address(0), "Next owner is the zero address.");

        nextOwner = nextOwner_;
    }

    /**
     * @dev Cancel ownership transfer by deleting nextOwner.
     */
    function cancelOwnershipTransfer() external onlyOwner {
        delete nextOwner;
    }

    /**
     * @dev Accepts ownership transfer by setting owner.
     */
    function acceptOwnership() external onlyNextOwner {
        delete nextOwner;

        owner = msg.sender;

        emit OwnershipTransferred(owner, msg.sender);
    }

    /**
     * @dev Renounce ownership by setting owner to zero address.
     */
    function renounceOwnership() external onlyOwner {
        owner = address(0);

        emit OwnershipTransferred(owner, address(0));
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == owner;
    }

    /**
     * @dev Returns true if the caller is the next owner.
     */
    function isNextOwner() public view returns (bool) {
        return msg.sender == nextOwner;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

interface IGovernable {
    function changeGovernor(address governor_) external;

    function isGovernor() external view returns (bool);

    function governor() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import {AllocatedEditionsStorage} from "../AllocatedEditionsStorage.sol";

interface IAllocatedEditionsFactory {
    function logic() external returns (address);

    // AllocatedEditions data
    function parameters()
        external
        returns (
            // NFT Metadata
            bytes memory nftMetaData,
            // Edition Data
            uint256 allocation,
            uint256 quantity,
            uint256 price,
            // Config
            bytes memory configData
        );
}

