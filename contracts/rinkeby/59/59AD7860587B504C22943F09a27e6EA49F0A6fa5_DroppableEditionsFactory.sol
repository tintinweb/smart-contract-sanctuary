// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import {ITributaryRegistry} from "../../../interface/ITributaryRegistry.sol";
import {InitializedGovernable} from "../../../lib/InitializedGovernable.sol";
import {DroppableEditionsProxy} from "./DroppableEditionsProxy.sol";
import {DroppableEditionsStorage} from "./DroppableEditionsStorage.sol";
import {IERC2309} from "../../../external/interface/IERC2309.sol";

/**
 * @title DroppableEditionsFactory
 * @author MirrorXYZ
 */
contract DroppableEditionsFactory is InitializedGovernable, IERC2309 {
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

    event DroppableEditionDeployed(
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

    /// @notice OpenSea Proxy Registry
    address public proxyRegistry;

    //======== Constructor =========
    constructor(
        address owner_,
        address logic_,
        address tributaryRegistry_,
        address treasuryConfig_,
        address proxyRegistry_
    ) InitializedGovernable(owner_, owner_) {
        logic = logic_;
        tributaryRegistry = tributaryRegistry_;
        treasuryConfig = treasuryConfig_;
        proxyRegistry = proxyRegistry_;
    }

    //======== Configuration =========

    /// @notice Updates minimum fee percentage
    function setMinimumFeePercentage(uint256 newMinFeePercentage)
        public
        onlyGovernance
    {
        minFeePercentage = newMinFeePercentage;
    }

    /// @notice Updates logic
    function setLogic(address newLogic) public onlyGovernance {
        logic = newLogic;
    }

    /// @notice Updates treasury config
    function setTreasuryConfig(address newTreasuryConfig)
        public
        onlyGovernance
    {
        treasuryConfig = newTreasuryConfig;
    }

    /// @notice Updates tributary registry
    function setTributaryRegistry(address newTributaryRegistry)
        public
        onlyGovernance
    {
        tributaryRegistry = newTributaryRegistry;
    }

    /// @notice Updates proxy registry
    function setProxyRegistry(address newProxyRegistry)
        public
        onlyGovernance
    {
        proxyRegistry = newProxyRegistry;
    }

    //======== Proxy Deployments =========

    /// @notice Creates an edition by deploying a new proxy.
   function createEdition(
        DroppableEditionsStorage.NFTMetadata memory metadata,
        DroppableEditionsStorage.EditionData memory editionData,
        DroppableEditionsStorage.AdminData memory adminData
    ) external returns (address allocatedEditionsProxy) {
        require(
            adminData.feePercentage >= minFeePercentage,
            "fee is too low"
        );

        require(
            editionData.allocation <= editionData.quantity,
            "allocation must be less than quantity"
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
                adminData.merkleRoot,
                adminData.tributary,
                adminData.fundingRecipient,
                adminData.feePercentage,
                treasuryConfig
            )
        });

        // deploys proxy
        allocatedEditionsProxy = address(
            new DroppableEditionsProxy{
                salt: keccak256(abi.encode(metadata.symbol, adminData.operator, adminData.merkleRoot))
            }(adminData.operator, governor, proxyRegistry)
        );

        delete parameters;

        emit DroppableEditionDeployed(
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

contract InitializedGovernable is Ownable, IGovernable {
    // ============ Events ============

    event GovernorChanged(
        address indexed previousGovernor,
        address indexed newGovernor
    );

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

    constructor(address owner_, address governor_) Ownable(owner_) {
        _setGovernor(governor_);
    }

    // ============ Administration ============

    function changeGovernor(address governor_) public override onlyGovernance {
        _setGovernor(governor_);
    }

    // ============ Utility Functions ============

    function isGovernor() public view override returns (bool) {
        return msg.sender == governor;
    }

    // ============ Internal Functions ============

    function _setGovernor(address governor_) internal {
        emit GovernorChanged(governor, governor_);

        governor = governor_;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import {IERC2309} from "../../../external/interface/IERC2309.sol";
import {DroppableEditionsStorage} from "./DroppableEditionsStorage.sol";
import {IDroppableEditionsFactory} from "./interface/IDroppableEditionsFactory.sol";
import {InitializedGovernable} from "../../../lib/InitializedGovernable.sol";
import {Pausable} from "../../../lib/Pausable.sol";
import {IDroppableEditionsLogicEvents} from "./interface/IDroppableEditionsLogic.sol";
import {IERC721Events} from "../../../external/interface/IERC721.sol";

/**
 * @title DroppableEditionsProxy
 * @author MirrorXYZ
 */
contract DroppableEditionsProxy is
    DroppableEditionsStorage,
    InitializedGovernable,
    Pausable,
    IDroppableEditionsLogicEvents,
    IERC721Events,
    IERC2309
{
    event Upgraded(address indexed implementation);

    event RenounceUpgrade(uint256 blockNumber);

    /// @notice IERC721Metadata
    string public name;
    string public symbol;

    constructor(
        address owner_,
        address governor_,
        address proxyRegistry_
    ) InitializedGovernable(owner_, governor_) Pausable(true) {
        address logic = IDroppableEditionsFactory(msg.sender).logic();

        assembly {
            sstore(_IMPLEMENTATION_SLOT, logic)
        }

        emit Upgraded(logic);

        proxyRegistry = proxyRegistry_;

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
        ) = IDroppableEditionsFactory(msg.sender).parameters();

        (name, symbol, baseURI, contentHash) = abi.decode(
            nftMetaData,
            (string, string, string, bytes32)
        );

        (
            operator,
            merkleRoot,
            tributary,
            fundingRecipient,
            feePercentage,
            treasuryConfig
        ) = abi.decode(
            adminData,
            (address, bytes32, address, address, uint256, address)
        );
    }

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

    // ============ Upgrade Methods ============

    /// @notice Get current logic
    function getLogic() external view returns (address logic) {
        assembly {
            logic := sload(_IMPLEMENTATION_SLOT)
        }
    }

    /// @notice Allows governance to change the logic.
    function changeLogic(address newLogic) external onlyGovernance {
        require(upgradesAllowed, "cannot upgrade");

        // Store the newImplementation on implementation-slot
        assembly {
            sstore(_IMPLEMENTATION_SLOT, newLogic)
        }

        emit Upgraded(newLogic);
    }

    /// @notice opt-out of upgrades
    function renounceUpgrades() external onlyGovernance {
        upgradesAllowed = false;

        emit RenounceUpgrade(block.number);
    }

    receive() external payable {}
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

/**
 * @title DroppableEditionsStorage
 * @author MirrorXYZ
 */
contract DroppableEditionsStorage {
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
        // The maximum number of tokens that can be sold.
        uint256 quantity;
        uint256 allocation;
        // The price at which each token will be sold, in ETH.
        uint256 price;
    }

    /// @notice Contains information about funds disbursement.
    struct AdminData {
        // Operator of this contract.
        address operator;
        bytes32 merkleRoot;
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
    address payable public fundingRecipient;
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

    /// @notice Only allow one purchase per account.
    mapping(address => bool) internal purchased;

    // OpenSea's Proxy Registry
    address public proxyRegistry;

    bytes32 public merkleRoot;

    uint256 currentTokenId;
    uint256 currentIndexId;
    uint256 claimedTokens;
    uint256 nonAllocatedPurchases = 0;

    mapping(uint256 => bool) public burned;

    mapping(uint256 => address) public indexToClaimer;
    mapping(address => uint256) public claimerToAllocation;

    mapping(bytes32 => bool) public claimed;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /// @notice Allows to renounce upgrades
    bool public upgradesAllowed = true;
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

interface IOwnableEvents {
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
}

contract Ownable is IOwnableEvents {
    address public owner;
    address private nextOwner;

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
        _renounceOwnership();
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

    function _setOwner(address previousOwner, address newOwner) internal {
        owner = newOwner;
        emit OwnershipTransferred(previousOwner, owner);
    }

    function _renounceOwnership() internal {
        owner = address(0);

        emit OwnershipTransferred(owner, address(0));
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

interface IDroppableEditionsFactory {
    function logic() external returns (address);

    // DroppableEditions data
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

interface IPausableEvents {
    /// @notice Emitted when the pause is triggered by `account`.
    event Paused(address account);

    /// @notice Emitted when the pause is lifted by `account`.
    event Unpaused(address account);
}

interface IPausable {
    function paused() external returns (bool);
}

contract Pausable is IPausable, IPausableEvents {
    bool public override paused;

    // Modifiers

    modifier whenNotPaused() {
        require(!paused, "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Pausable: not paused");
        _;
    }

    /// @notice Initializes the contract in unpaused state.
    constructor(bool paused_) {
        paused = paused_;
    }

    // ============ Internal Functions ============

    function _pause() internal whenNotPaused {
        paused = true;

        emit Paused(msg.sender);
    }

    function _unpause() internal whenPaused {
        paused = false;

        emit Unpaused(msg.sender);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

interface IDroppableEditionsLogicEvents {
    event EditionPurchased(
        uint256 indexed tokenId,
        uint256 amountPaid,
        address buyer,
        address receiver
    );

    event EditionCreatorChanged(
        address indexed previousCreator,
        address indexed newCreator
    );
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

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

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IERC165).interfaceId;
    }
}

interface IERC721Royalties {
    function getFeeRecipients(uint256 id)
        external
        view
        returns (address payable[] memory);

    function getFeeBps(uint256 id) external view returns (uint256[] memory);
}