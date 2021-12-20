// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

import {MirrorProxy} from "../lib/MirrorProxy.sol";
import {IMirrorERC20Logic} from "../lib/ERC20/interface/IMirrorERC20Logic.sol";
import {IMirrorCrowdfundLogic} from "./interface/IMirrorCrowdfundLogic.sol";
import {IMirrorCrowdfundEditionStructs} from "./editions/interface/IMirrorCrowdfundEditionStructs.sol";

/**
 * @title MirrorCrowdfundFactory
 * @author MirrorXYZ
 */
contract MirrorCrowdfundFactory is IMirrorCrowdfundEditionStructs {
    address public erc20Logic;
    address public crowdfundLogic;

    event CrowdfundDeployed(address proxyAddress);

    constructor(address erc20Logic_, address crowdfundLogic_) {
        erc20Logic = erc20Logic_;
        crowdfundLogic = crowdfundLogic_;
    }

    function createEditionsCrowdfundWithERC20(
        address owner,
        ERC20Attributes calldata erc20Attributes,
        CrowdfundInitConfig calldata crowdfundConfig,
        CampaignConfig calldata campaignConfig,
        string calldata baseURI,
        EditionTier[] calldata tiers
    ) public {
        // Token initialization data.
        bytes memory erc20InitData = abi.encodeWithSelector(
            IMirrorERC20Logic.initialize.selector,
            owner,
            erc20Attributes.name,
            erc20Attributes.symbol,
            erc20Attributes.totalSupply,
            erc20Attributes.decimals
        );
        // Create and initialize the token.
        address erc20Proxy = address(
            new MirrorProxy{
                salt: keccak256(
                    abi.encode(
                        owner,
                        erc20Attributes.name,
                        erc20Attributes.symbol
                    )
                )
            }(erc20Logic, erc20InitData)
        );

        // Construct the crowdfund initialization data.
        bytes memory crowdfundInitData = abi.encodeWithSelector(
            IMirrorCrowdfundLogic.initialize.selector,
            owner,
            erc20Proxy,
            crowdfundConfig.exchangeRate,
            crowdfundConfig.fundingRecipient,
            crowdfundConfig.fundingStatus,
            campaignConfig,
            baseURI,
            tiers
        );
        // Create and initialize the crowdfund.
        address crowdfundProxy = address(
            // TODO: Consider this salt closely.
            new MirrorProxy{salt: keccak256(abi.encode(owner, erc20Proxy))}(
                crowdfundLogic,
                crowdfundInitData
            )
        );
        // Emit an event that it was deployed.
        emit CrowdfundDeployed(crowdfundProxy);
    }

    function createEditionsCrowdfundWithoutERC20(
        address owner,
        address token,
        CrowdfundInitConfig calldata crowdfundConfig,
        CampaignConfig calldata campaignConfig,
        string calldata baseURI,
        EditionTier[] calldata tiers
    ) public {
        // Construct the crowdfund initialization data.
        bytes memory crowdfundInitData = abi.encodeWithSelector(
            IMirrorCrowdfundLogic.initialize.selector,
            owner,
            token,
            crowdfundConfig.exchangeRate,
            crowdfundConfig.fundingRecipient,
            crowdfundConfig.fundingStatus,
            campaignConfig,
            baseURI,
            tiers
        );
        // Create and initialize the crowdfund.
        address crowdfundProxy = address(
            // TODO: Consider this salt closely.
            new MirrorProxy{salt: keccak256(abi.encode(owner, token))}(
                crowdfundLogic,
                crowdfundInitData
            )
        );
        // Emit an event that it was deployed.
        emit CrowdfundDeployed(crowdfundProxy);
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

interface IMirrorERC20Logic {
    function DOMAIN_SEPARATOR() external view returns (bytes32);

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

import {IMirrorCrowdfundEditionStructs} from "../editions/interface/IMirrorCrowdfundEditionStructs.sol";

interface IMirrorCrowdfundLogic is IMirrorCrowdfundEditionStructs {
    /// @notice The address for treasury configuration.
    function treasuryConfig() external returns (address);

    /// @notice The address for fee configuration.
    function feeConfig() external returns (address);

    /// @notice The function for the editions factory.
    function editionsFactory() external returns (address);

    /// @notice The function of the erc20 token that can be minted.
    function token() external returns (address);

    /// @notice The exchange rate per ETH.
    function exchangeRate() external returns (uint256);

    /// @notice The account that receives the funds on withdrawals.
    function fundingRecipient() external returns (address);

    /// @notice Current funding status.
    function fundingStatus() external returns (FundingStatus);

    /// @notice The id of the next campaign.
    /// @dev Campaigns start at id = 1.
    function nextCampaignId() external returns (uint256);

    /// @notice The merkle root for redemptions.
    function redeemRoot() external returns (bytes32);

    /// @notice The merkle root for contributors.
    function contributeRoot() external returns (bytes32);

    /// @notice Set initial parameters, mint initial supply to owner and set the owner.
    /// @dev Only callable during deployment, throws if called after deployment.
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

    /// @notice Create a new campaign
    /// @dev Creating a new campaign deploys a new editions proxy if a tier is specified.
    function createCampaign(
        CampaignConfig calldata config,
        string calldata baseURI,
        EditionTier[] calldata tiers
    ) external returns (address editionsProxy);

    /// @notice Contribute to a campaign by buying an edition.
    function buyEdition(
        uint256 campaignId,
        uint256 editionId,
        address recipient
    ) external payable returns (uint256 tokenId);

    /// @notice Make a crowdfund contribution.
    /// @dev Throws if funding is closed or funding target has been met.
    /// @param contributor the account to send exchanged tokens to, used to make contributions
    ///  on behalf of someone else.
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

    /// @notice Allows the sender to get a refund of their tokens at the exchange rate.
    function refund(uint256 amountToBurn) external;

    /// @notice Redeem tokens via merkle proof verification.
    function redeemWithProof(
        uint256 amountToBurn,
        uint256 ethToReceive,
        uint256 index,
        bytes32[] calldata merkleProof
    ) external;

    /// @notice Withdraw balance to fundingRecipient.
    /// @dev if current round target has been met behave close funding
    function withdraw(uint16 feePercentage) external;

    /// @notice Allows the contract owner to update the token.
    /// @dev throws if called by non-owner
    function setToken(address token_) external;

    /// @notice Allows the contract owner to update the funding status.
    /// @dev throws if called by non-owner
    function setFundingStatus(FundingStatus status_) external;

    /// @notice Allows the contract owner to set the merkle root that specifies who can redeem.
    /// @dev throws if called by non-owner
    function setRedeemRoot(bytes32 root_) external;

    /// @notice Sets the merkle root that specifies who can contribute.
    /// @dev throws if called by non-owner
    function setContributeRoot(bytes32 root_) external;

    /// @notice Open funding with the option of setting a new exchange rate
    /// @dev throws if called by non-owner
    function openFunding() external;

    /// @notice Close funding.
    /// @dev throws if called by non-owner
    function closeFunding() external;

    /// @notice Close funding and withdraw all funds.
    /// @dev throws if called by non-owner
    function closeFundingAndWithdraw(uint16 feePercentage_) external;

    /// @notice Set recipient of funding received through contributions
    /// @dev throws if called by non-owner
    /// @param fundingRecipient_ the new recipient address
    function setFundingRecipient(address fundingRecipient_) external;

    /// @notice Adjusts the funding cap for a particular campaign.
    /// @dev throws if called by non-owner
    /// @param campaignId the campaign's ID
    /// @param fundingCap_ the new funding cap
    function setFundingCap(uint256 campaignId, uint256 fundingCap_) external;

    /// @notice Set exchange rate
    /// @dev throws if called by non-owner
    /// @param exchangeRate_ the new exchange rate
    function setExchangeRate(uint256 exchangeRate_) external;
}

interface IMirrorCrowdfundLogicEvents {
    event CrowdfundCreated(
        uint256 target,
        address token,
        uint256 exchangeRate,
        address faucet,
        address indexed recipient
    );

    event CrowdfundContribution(
        uint256 campaignId,
        address indexed contributor,
        uint256 contributionAmount,
        uint256 tokenAmount
    );

    event Redeemed(
        address indexed account,
        uint256 amountToBurn,
        uint256 ethToReceive
    );

    event RedeemedWithProof(
        address indexed account,
        uint256 amountToBurn,
        uint256 ethToReceive,
        uint256 index
    );

    event EditionPurchased(
        uint256 campaignId,
        uint256 editionId,
        address contributor,
        address recipient,
        uint256 tokenId,
        uint256 value
    );

    event Withdrawal(address indexed recipient, uint256 amount, uint256 fee);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

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

    event CampaignCreated(
        uint256 campaignId,
        string name,
        string symbol,
        uint256 fundingCap,
        address editionsProxy
    );
}