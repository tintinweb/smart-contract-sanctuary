// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

import {IMirrorCrowdfundFactory} from "./interface/IMirrorCrowdfundFactory.sol";
import {IERC20Factory, IERC20FactoryEvents} from "../lib/ERC20/interface/IERC20Factory.sol";
import {IMirrorCrowdfund, IMirrorCrowdfundEvents} from "./interface/IMirrorCrowdfund.sol";
import {IMirrorCrowdfundEditionsFactoryEvents} from "./editions/interface/IMirrorCrowdfundEditionsFactory.sol";
import {IMirrorCrowdfundEditionsEvents} from "./editions/interface/IMirrorCrowdfundEditions.sol";
import {Clones} from "../lib/Clones.sol";
import {IOwnableEvents} from "../lib/Ownable.sol";
import {IPausableEvents} from "../lib/Pausable.sol";
import {IERC20Events} from "../lib/ERC20/interface/IERC20.sol";
import {IOperatableEvents} from "../lib/Operatable.sol";
import {ITributaryRegistry} from "../treasury/interface/ITributaryRegistry.sol";

/**
 * @title MirrorCrowdfundFactory
 * @dev
 * The MirrorCrowdfundFactory contract is used to deploy ERC20 and MirrorCrowdfund clones using (ERC-1167).
 *
 *
 * There are two main functions, one that deploys a crowdfund clone and an ERC20 clone using the `erc20Factory`,
 * and another one that only deploys a crowdfund clone.
 * @author MirrorXYZ
 */
contract MirrorCrowdfundFactory is
    IMirrorCrowdfundFactory,
    IOwnableEvents,
    IERC20FactoryEvents,
    IERC20Events,
    IMirrorCrowdfundEditionsFactoryEvents,
    IMirrorCrowdfundEditionsEvents,
    IMirrorCrowdfundEvents,
    IPausableEvents,
    IOperatableEvents
{
    /// @notice Mirror tributary registry
    address public tributaryRegistry;

    /// @notice ERC20 clone factory
    address public erc20Factory;

    /// @notice Crowdfund contract implementation
    address public crowdfundImplementation;

    constructor(
        address tributaryRegistry_,
        address erc20Factory_,
        address crowdfundImplementation_
    ) {
        tributaryRegistry = tributaryRegistry_;
        erc20Factory = erc20Factory_;
        crowdfundImplementation = crowdfundImplementation_;
    }

    /// @notice Deploy an ERC20 token, a crowdfund contract and start a crowdfund campaign.
    /// @param owner The crowdfund owner and token holder
    /// @param erc20Attributes The ERC20 token name, symbol and total supply
    /// @param crowdfundConfig The crowdfund configuration
    /// @param campaignConfig The campaign configuration
    /// @param baseURI The base URI for crowdfund editions (if any)
    /// @param tiers The crowdfund editions tier configuration
    /// @param nonce A random nonce used as salt for deploying clones
    /// @return The crowdfund contract address
    function createERC20AndCrowdfund(
        address owner,
        ERC20Attributes calldata erc20Attributes,
        CrowdfundInitConfig calldata crowdfundConfig,
        CampaignConfig calldata campaignConfig,
        string calldata baseURI,
        EditionTier[] calldata tiers,
        uint256 nonce,
        address tributary
    ) external override returns (address) {
        // Create and initialize the token.
        address erc20 = _deployERC20Token(owner, erc20Attributes);

        // Create crowdfund and campaign.
        return
            _deployCrowdfund(
                owner,
                erc20,
                crowdfundConfig,
                campaignConfig,
                baseURI,
                tiers,
                nonce,
                tributary
            );
    }

    /// @notice Deploy a crowdfund contract with an existing ERC20 token
    /// and start a crowdfund campaign.
    /// @param owner The crowdfund owner and token holder
    /// @param token The ERC20 token awarded for crowdfund contributions
    /// @param crowdfundConfig The crowdfund configuration
    /// @param campaignConfig The campaign configuration
    /// @param baseURI The base URI for crowdfund editions (if any)
    /// @param tiers The crowdfund editions tier configuration
    /// @param nonce A random nonce used as salt for deploying clones
    /// @return The crowdfund contract address
    function createCrowdfund(
        address owner,
        address token,
        CrowdfundInitConfig calldata crowdfundConfig,
        CampaignConfig calldata campaignConfig,
        string calldata baseURI,
        EditionTier[] calldata tiers,
        uint256 nonce,
        address tributary
    ) external override returns (address) {
        // Create crowdfund and campaign.
        return
            _deployCrowdfund(
                owner,
                token,
                crowdfundConfig,
                campaignConfig,
                baseURI,
                tiers,
                nonce,
                tributary
            );
    }

    function predictDeterministicAddress(address logic_, bytes32 salt)
        external
        view
        returns (address)
    {
        return Clones.predictDeterministicAddress(logic_, salt, address(this));
    }

    //======== Internal functions ========

    function _deployCrowdfund(
        address owner,
        address token,
        CrowdfundInitConfig calldata crowdfundConfig,
        CampaignConfig calldata campaignConfig,
        string calldata baseURI,
        EditionTier[] calldata tiers,
        uint256 nonce,
        address tributary
    ) internal returns (address) {
        address crowdfund = Clones.cloneDeterministic(
            crowdfundImplementation,
            keccak256(abi.encode(owner, token, nonce))
        );

        IMirrorCrowdfund(crowdfund).initialize(
            owner,
            token,
            crowdfundConfig.exchangeRate,
            crowdfundConfig.fundingRecipient,
            crowdfundConfig.fundingStatus,
            campaignConfig,
            baseURI,
            tiers
        );

        // Emit an event that it was deployed.
        emit CrowdfundDeployed(crowdfund);

        ITributaryRegistry(tributaryRegistry).registerTributary(
            crowdfund,
            tributary
        );

        return crowdfund;
    }

    function _deployERC20Token(
        address owner,
        ERC20Attributes calldata erc20Attributes
    ) internal returns (address) {
        return
            IERC20Factory(erc20Factory).create(
                owner,
                erc20Attributes.name,
                erc20Attributes.symbol,
                erc20Attributes.totalSupply,
                erc20Attributes.decimals,
                erc20Attributes.nonce
            );
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

import {IMirrorCrowdfundEditionStructs} from "../editions/interface/IMirrorCrowdfundEditionStructs.sol";

interface IMirrorCrowdfundFactoryEvents {
    /// @notice New ERC20 proxy deployed
    event ERC20ProxyDeployed(
        address proxy,
        string name,
        string symbol,
        address operator
    );
}

interface IMirrorCrowdfundFactory is IMirrorCrowdfundEditionStructs {
    event CrowdfundDeployed(address proxyAddress);

    function createERC20AndCrowdfund(
        address owner,
        ERC20Attributes calldata erc20Attributes,
        CrowdfundInitConfig calldata crowdfundConfig,
        CampaignConfig calldata campaignConfig,
        string calldata baseURI,
        EditionTier[] calldata tiers,
        uint256 nonce,
        address tributary
    ) external returns (address);

    function createCrowdfund(
        address owner,
        address token,
        CrowdfundInitConfig calldata crowdfundConfig,
        CampaignConfig calldata campaignConfig,
        string calldata baseURI,
        EditionTier[] calldata tiers,
        uint256 nonce,
        address tributary
    ) external returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

interface IERC20FactoryEvents {
    /// @notice New ERC20 proxy deployed
    event ERC20Deployed(
        address proxy,
        string name,
        string symbol,
        address operator
    );
}

interface IERC20Factory {
    /// @notice Deploy a new proxy
    function create(
        address operator,
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_,
        uint8 decimals_,
        uint256 nonce
    ) external returns (address erc20Proxy);

    function predictDeterministicAddress(address logic_, bytes32 salt)
        external
        view
        returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

import {IMirrorCrowdfundEditionStructs} from "../editions/interface/IMirrorCrowdfundEditionStructs.sol";

interface IMirrorCrowdfund is IMirrorCrowdfundEditionStructs {
    function treasuryConfig() external returns (address);

    function feeConfig() external returns (address);

    function editionsFactory() external returns (address);

    function crowdfundFactory() external returns (address);

    function token() external returns (address);

    function exchangeRate() external returns (uint256);

    function fundingRecipient() external returns (address);

    function fundingStatus() external returns (FundingStatus);

    function nextCampaignId() external returns (uint256);

    function redeemRoot() external returns (bytes32);

    function contributeRoot() external returns (bytes32);

    function initialize(
        address owner_,
        address token_,
        uint256 exchangeRate_,
        address fundingRecipient_,
        FundingStatus fundingStatus_,
        CampaignConfig calldata config,
        string calldata baseURI,
        EditionTier[] calldata tiers
    ) external returns (address);

    function createCampaign(
        CampaignConfig calldata config,
        string calldata baseURI,
        EditionTier[] calldata tiers
    ) external returns (address editionsProxy);

    function createCampaignAndUpdateConfiguration(
        CampaignConfig calldata config,
        string calldata baseURI,
        EditionTier[] calldata tiers,
        bytes32 contributeRoot_,
        bytes32 redeemRoot_,
        address token_,
        uint256 exchangeRate,
        FundingStatus fundingStatus_
    ) external returns (address);

    function buyEdition(
        uint256 campaignId,
        uint256 editionId,
        address recipient
    ) external payable returns (uint256);

    function contributeToCrowdfund(uint256 campaignId, address contributor)
        external
        payable;

    function contributeWithProof(
        uint256 campaignId,
        address contributor,
        uint256 maxAmount,
        uint256 index,
        bytes32[] calldata merkleProof
    ) external payable;

    function refund(uint256 amountToRedeem) external;

    function redeemWithProof(
        uint256 amountToRedeem,
        uint256 ethToReceive,
        uint256 index,
        bytes32[] calldata merkleProof
    ) external;

    function withdraw(uint16 feePercentage) external;

    function setToken(address token_) external;

    function setFundingStatus(FundingStatus status_) external;

    function setRedeemRoot(bytes32 root_) external;

    function setContributeRoot(bytes32 root_) external;

    function openFunding() external;

    function closeFunding() external;

    function closeFundingAndWithdraw(uint16 feePercentage_) external;

    function setFundingRecipient(address fundingRecipient_) external;

    function setFundingCap(uint256 campaignId, uint256 fundingCap_) external;

    function setExchangeRate(uint256 exchangeRate_) external;
}

interface IMirrorCrowdfundEvents {
    /// @notice Crowdfund campaign created
    event CampaignCreated(
        uint256 campaignId,
        string name,
        string symbol,
        uint256 fundingCap,
        address editionsProxy
    );

    /// @notice Crowdfund contribution
    event CrowdfundContribution(
        uint256 campaignId,
        address indexed contributor,
        uint256 contributionAmount,
        uint256 tokenAmount
    );

    /// @notice Crowdfund redeem
    event Redeemed(
        address indexed account,
        uint256 amountToRedeem,
        uint256 ethToReceive
    );

    /// @notice Crowdfund redeem with merkle proof
    event RedeemedWithProof(
        address indexed account,
        uint256 amountToRedeem,
        uint256 ethToReceive,
        uint256 index
    );

    /// @notice Crowdfund edition purchased
    event EditionPurchased(
        uint256 campaignId,
        uint256 editionId,
        address contributor,
        address recipient,
        uint256 tokenId,
        uint256 value
    );

    /// @notice Crowdfund withdrawal
    event Withdrawal(address indexed recipient, uint256 amount, uint256 fee);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

import {IMirrorCrowdfundEditions} from "./IMirrorCrowdfundEditions.sol";

interface IMirrorCrowdfundEditionsFactoryEvents {
    event EditionsProxyDeployed(
        address indexed proxy,
        address indexed operator,
        address indexed owner,
        address logic
    );
}

interface IMirrorCrowdfundEditionsFactory {
    function deployAndCreateEditions(
        address owner,
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        IMirrorCrowdfundEditions.EditionTier[] memory tiers
    ) external returns (address proxy);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

import {IMirrorCrowdfundEditionStructs} from "./IMirrorCrowdfundEditionStructs.sol";

interface IMirrorCrowdfundEditionsEvents {
    /// @notice Create edition
    event EditionCreated(
        uint256 purchasableAmount,
        uint256 price,
        uint256 editionId
    );

    event OperatorChanged(
        address indexed proxy,
        address oldOperator,
        address newOperator
    );

    event EditionLimitSet(uint256 indexed editionId, uint256 limit);
}

interface IMirrorCrowdfundEditions is IMirrorCrowdfundEditionStructs {
    function initialize(
        address owner_,
        address operator_,
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        EditionTier[] memory tiers
    ) external;

    function baseURI() external view returns (string memory);

    function contractURI() external view returns (string memory);

    /// @notice Create edition
    function createEditions(EditionTier[] memory tiers) external;

    function mint(uint256 editionId, address to)
        external
        returns (uint256 tokenId);

    function unpause(uint256 editionId) external;

    function pause(uint256 editionId) external;

    function purchase(uint256 editionId, address recipient)
        external
        returns (uint256 tokenId);

    function editionPrice(uint256 editionId) external returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev Copy of OpenZeppelin's Clones contract
 * https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(
                ptr,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(
                add(ptr, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt)
        internal
        returns (address instance)
    {
        assembly {
            let ptr := mload(0x40)
            mstore(
                ptr,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(
                add(ptr, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(
                ptr,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(
                add(ptr, 0x28),
                0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000
            )
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

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
        emit OwnershipTransferred(owner, address(0));

        owner = address(0);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

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
pragma solidity 0.8.10;

interface IERC20Events {
    /// @notice EIP-20 transfer event
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    /// @notice EIP-20 approval event
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    /// @notice Mint event
    event Mint(address indexed _to, uint256 _value);
}

interface IERC20 {
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external view returns (bytes32);

    function initialize(
        address operator_,
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_,
        uint8 decimals_
    ) external returns (address);

    function setBurnable(bool canBurn) external;

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function nonces(address owner) external view returns (uint256);

    function mint(address to, uint256 amount) external;

    function burn(uint256 amount) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

import {Ownable} from "../lib/Ownable.sol";

interface IOperatableEvents {
    event OperatorTransferred(
        address indexed previousOperator,
        address indexed newOperator
    );
}

// Adds an additional admin account that might be a contract, can be set by owner.
contract Operatable is Ownable, IOperatableEvents {
    address public operator;

    // modifiers

    modifier onlyOperator() {
        require(isOperator(), "caller is not the operator.");
        _;
    }

     modifier onlyOperatorOrOwner() {
        require(isOperator() || isOwner(), "caller is not the operator or owner.");
        _;
    }

    /**
     * @dev Initialize contract by setting transaction submitter as initial owner.
     */
    constructor(address owner, address operator_) Ownable(owner) {
        operator = operator_;

        emit OperatorTransferred(address(0), operator_);
    }

    /**
     * @dev Transfer operator to a new address.
     */
    function transferOperator(address newOperator_) external onlyOwner {
        _setOperator(newOperator_);
    }

    /**
     * @dev Returns true if the caller is the current operator.
     */
    function isOperator() public view returns (bool) {
        return msg.sender == operator;
    }

    function _setOperator(address newOperator_) internal {
        emit OperatorTransferred(operator, newOperator_);

        operator = newOperator_;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

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
pragma solidity ^0.8.10;

interface IMirrorCrowdfundEditionStructs {
    /// @notice Statuses for funding and redeeming.
    enum FundingStatus {
        CONTRIBUTE,
        CONTRIBUTE_WITH_PROOF,
        PAUSED,
        CLOSED,
        REFUND,
        REDEEM_WITH_PROOF
    }

    struct Edition {
        // How many tokens are available to purchase in a campaign?
        uint256 purchasableAmount;
        // What is the price per token in the campaign?
        uint256 price;
        // What is the content hash of the token's content?
        bytes32 contentHash;
        // How many have currently been minted in total?
        uint256 numMinted;
        // How many have been purchased?
        uint256 numPurchased;
        // Is this edition paused?
        bool paused;
        // Optionally limit the number of tokens that can be minted.
        uint256 limit;
    }

    struct EditionTier {
        // When setting up an EditionTier, specify the supply limit.
        uint256 quantity;
        uint256 price;
        bytes32 contentHash;
    }

    // ERC20 Attributes.
    struct ERC20Attributes {
        string name;
        string symbol;
        uint256 totalSupply;
        uint8 decimals;
        uint256 nonce;
    }

    // Initialization configuration.
    struct CrowdfundInitConfig {
        address owner;
        uint256 exchangeRate;
        address fundingRecipient;
        FundingStatus fundingStatus;
    }

    struct CampaignConfig {
        string name;
        string symbol;
        uint256 fundingCap;
    }

    struct Campaign {
        address editionsProxy;
        uint256 fundingCap;
        uint256 amountRaised;
    }
}