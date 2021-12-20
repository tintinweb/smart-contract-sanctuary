// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

// Interfaces
import {IMirrorCrowdfundLogic, IMirrorCrowdfundLogicEvents} from "./interface/IMirrorCrowdfundLogic.sol";
import {IERC20Events} from "../lib/ERC20/interface/IERC20.sol";
import {IMirrorERC20Logic} from "../lib/ERC20/interface/IMirrorERC20Logic.sol";
import {IMirrorCrowdfundEditionsFactory} from "./editions/interface/IMirrorCrowdfundEditionsFactory.sol";
import {IMirrorCrowdfundEditionsLogic} from "./editions/interface/IMirrorCrowdfundEditionsLogic.sol";
// Libraries
import {Ownable} from "../lib/Ownable.sol";
import {Reentrancy} from "../lib/Reentrancy.sol";
// Treasury Config
import {ITreasuryConfig} from "../treasury/interface/ITreasuryConfig.sol";
import {IMirrorTreasury} from "../treasury/interface/IMirrorTreasury.sol";
// Fee Config
import {IMirrorFeeConfig} from "../fee-config/MirrorFeeConfig.sol";

/**
 * @title MirrorCrowdfundLogic
 * @author MirrorXYZ
 */
contract MirrorCrowdfundLogic is
    Ownable,
    IMirrorCrowdfundLogic,
    IMirrorCrowdfundLogicEvents,
    Reentrancy
{
    /// @notice The address for treasury configuration.
    address public immutable override treasuryConfig;

    /// @notice The address for fee configuration.
    address public immutable override feeConfig;

    /// @notice The address for the editions factory.
    address public immutable override editionsFactory;

    // ======== Mutable Variables ========

    /// @notice The address of the erc20 token that can be minted.
    address public override token;

    /// @notice The exchange rate per ETH.
    uint256 public override exchangeRate;

    /// @notice The account that receives the funds on withdrawals.
    address public override fundingRecipient;

    /// @notice Current funding status.
    FundingStatus public override fundingStatus;

    /// @notice A mapping of campaign id to campaign state.
    mapping(uint256 => Campaign) public campaigns;

    /// @notice The id of the next campaign.
    /// @dev Campaigns start at id = 1.
    uint256 public override nextCampaignId;

    /// @notice The merkle root for redemptions.
    bytes32 public override redeemRoot;

    /// @notice The merkle root for contributors.
    bytes32 public override contributeRoot;

    /// @notice Hash of redeemRoot, account and index to redeem status.
    mapping(bytes32 => bool) internal redeemedWithProof;

    /// @notice Hash of contributeRoot, account and index to contribution status.
    mapping(bytes32 => bool) internal contributedWithProof;

    // ======== Constructor ========

    /// @dev Ownable parameter is irrelevant since this is a logic file.
    constructor(
        address editionsFactory_,
        address treasuryConfig_,
        address feeConfig_
    ) Ownable(address(0)) {
        editionsFactory = editionsFactory_;
        treasuryConfig = treasuryConfig_;
        feeConfig = feeConfig_;
    }

    //======== Initialize crowdfund contract ========

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
    ) external override returns (address) {
        // ensure that this function is only callable during contract deployment
        if (address(this).code.length > 0) {
            revert("already initialized");
        }

        // Update the owner of this contract.
        _setOwner(address(0), owner_);

        // Allow the factory to set things if necessary.
        // Setup crowdfund.
        exchangeRate = exchangeRate_;
        fundingRecipient = fundingRecipient_;
        token = token_;

        // Open funding status if configured
        fundingStatus = fundingStatus_;

        // Create a new campaign.
        _createCampaign(config, baseURI, tiers);

        // Return the address of this contract.
        return address(this);
    }

    //======== Create a campaign ========

    /// @notice Create a new campaign
    /// @dev Creating a new campaign deploys a new editions proxy if a tier is specified.
    function createCampaign(
        CampaignConfig calldata config,
        string calldata baseURI,
        EditionTier[] calldata tiers
    ) public override onlyOwner returns (address) {
        return _createCampaign(config, baseURI, tiers);
    }

    //======== Contribution ========

    /// @notice Contribute to a campaign by buying an edition.
    function buyEdition(
        uint256 campaignId,
        uint256 editionId,
        address recipient
    ) external payable override returns (uint256 tokenId) {
        require(fundingStatus == FundingStatus.CONTRIBUTE, "not open");

        return _buyEdition(campaignId, editionId, recipient);
    }

    /// @notice Make a crowdfund contribution.
    /// @dev Throws if funding is closed or funding target has been met.
    /// @param contributor the account to send exchanged tokens to, used to make contributions
    ///  on behalf of someone else.
    function contributeToCrowdfund(uint256 campaignId, address contributor)
        external
        payable
        override
    {
        require(fundingStatus == FundingStatus.CONTRIBUTE, "not open");

        return _contribute(campaignId, contributor);
    }

    function contributeWithProof(
        uint256 campaignId,
        address contributor,
        uint256 maxAmount,
        uint256 index,
        bytes32[] calldata merkleProof
    ) external payable override {
        require(
            fundingStatus == FundingStatus.CONTRIBUTE_WITH_PROOF,
            "not open for proof-based contributions"
        );

        bytes32 root_ = contributeRoot;

        // Check that the account hasn't already contribued with proof.
        require(
            !hasContributedWithProof(root_, index, contributor),
            "already contributed"
        );

        require(msg.value <= maxAmount, "value greater than max");

        // Mark this account as having contributed with proof.
        setContributedWithProof(root_, index, contributor);

        // Check that we can verify the proof against the contribution root node.
        require(
            _verifyProof(
                merkleProof,
                root_,
                _getContributeNode(contributor, maxAmount, index)
            ),
            "invalid proof"
        );

        return _contribute(campaignId, contributor);
    }

    //======== Refund ========

    /// @notice Allows the sender to get a refund of their tokens at the exchange rate.
    function refund(uint256 amountToBurn) external override {
        require(fundingStatus == FundingStatus.REFUND, "status not refund");

        // Check that the exchange rate is valid.
        require(exchangeRate != 0, "exchange rate invalid for refund");

        // Transfer the tokens from the account's wallet to this contract.
        IMirrorERC20Logic(token).transferFrom(msg.sender, owner, amountToBurn);

        // Calculate the amount of ETH that the sender should receive.
        uint256 ethToReceive = amountToBurn / exchangeRate;

        // Send the ETH to the account.
        _sendEther(payable(msg.sender), ethToReceive);

        // Emit an event with the details of the redeem.
        emit Redeemed(msg.sender, amountToBurn, ethToReceive);
    }

    /// @notice Redeem tokens via merkle proof verification.
    function redeemWithProof(
        uint256 amountToBurn,
        uint256 ethToReceive,
        uint256 index,
        bytes32[] calldata merkleProof
    ) external override {
        // Check that the funding status is set to redeem_with_proof.
        require(
            fundingStatus == FundingStatus.REDEEM_WITH_PROOF,
            "status not redeem with proof"
        );

        // Copy the redeem root.
        bytes32 root_ = redeemRoot;

        // Check that the account hasn't already redeemed for this root.
        require(
            !_hasRedeemedWithProof(root_, index, msg.sender),
            "already redeemed"
        );

        // Mark this account as having redeemed.
        _setRedeemedWithProof(root_, index, msg.sender);

        // Check that we can verify the proof against the redemption root node.
        require(
            _verifyProof(
                merkleProof,
                root_,
                getRedeemNode(msg.sender, amountToBurn, ethToReceive, index)
            ),
            "invalid proof"
        );

        // Transfer the tokens from the account's wallet to the contract owner.
        IMirrorERC20Logic(token).transferFrom(msg.sender, owner, amountToBurn);

        // Send the ETH that the account is allocated to receive.
        _sendEther(payable(msg.sender), ethToReceive);

        // Emit an event with the details of the redeem.
        emit RedeemedWithProof(msg.sender, amountToBurn, ethToReceive, index);
    }

    //======== ETH Withdrawal ========

    /// @notice Withdraw balance to fundingRecipient.
    /// @dev if current round target has been met behave close funding
    function withdraw(uint16 feePercentage) external override nonReentrant {
        // Call internal withdraw method with the feePercentage.
        _withdraw(feePercentage);
    }

    //======== Admin configuration functions ========

    /// @notice Allows the contract owner to update the token.
    /// @dev throws if called by non-owner
    function setToken(address token_) external override onlyOwner {
        token = token_;
    }

    /// @notice Allows the contract owner to update the funding status.
    /// @dev throws if called by non-owner
    function setFundingStatus(FundingStatus status_)
        external
        override
        onlyOwner
    {
        fundingStatus = status_;
    }

    /// @notice Allows the contract owner to set the merkle root that specifies who can redeem.
    /// @dev throws if called by non-owner
    function setRedeemRoot(bytes32 root_) external override onlyOwner {
        redeemRoot = root_;
    }

    /// @notice Sets the merkle root that specifies who can contribute.
    /// @dev throws if called by non-owner
    function setContributeRoot(bytes32 root_) external override onlyOwner {
        contributeRoot = root_;
    }

    /// @notice Open funding with the option of setting a new exchange rate
    /// @dev throws if called by non-owner
    function openFunding() external override onlyOwner {
        _openFunding();
    }

    /// @notice Close funding.
    /// @dev throws if called by non-owner
    function closeFunding() external override onlyOwner {
        _closeFunding();
    }

    /// @notice Close funding and withdraw all funds.
    /// @dev throws if called by non-owner
    function closeFundingAndWithdraw(uint16 feePercentage_)
        external
        override
        onlyOwner
    {
        _closeFunding();
        _withdraw(feePercentage_);
    }

    /// @notice Set recipient of funding received through contributions
    /// @dev throws if called by non-owner
    /// @param fundingRecipient_ the new recipient address
    function setFundingRecipient(address fundingRecipient_)
        external
        override
        onlyOwner
    {
        fundingRecipient = fundingRecipient_;
    }

    /// @notice Adjusts the funding cap for a particular campaign.
    /// @dev throws if called by non-owner
    /// @param campaignId the campaign's ID
    /// @param fundingCap_ the new funding cap
    function setFundingCap(uint256 campaignId, uint256 fundingCap_)
        external
        onlyOwner
    {
        // Get the appropriate campaign.
        Campaign storage campaign = campaigns[campaignId];
        // Update the campaign's funding cap to the given cap.
        campaign.fundingCap = fundingCap_;
    }

    /// @notice Set exchange rate
    /// @dev throws if called by non-owner
    /// @param exchangeRate_ the new exchange rate
    function setExchangeRate(uint256 exchangeRate_)
        external
        override
        onlyOwner
    {
        // set exchange rate
        exchangeRate = exchangeRate_;
    }

    // ============ Internal Methods ============

    function _buyEdition(
        uint256 campaignId,
        uint256 editionId,
        address recipient
    ) internal returns (uint256 tokenId) {
        // Get the details of the relevant campaign.
        Campaign storage campaign = campaigns[campaignId];

        // Check if the edition exists
        require(
            campaign.editionsProxy != address(0),
            "no editions for campaign"
        );

        // Increase the amount that has been raised for the campaign.
        campaign.amountRaised += msg.value;

        // Ensure that this new amount does not exceed the funding cap.
        require(
            campaign.amountRaised <= campaign.fundingCap,
            "funding cap reached"
        );

        // Send tokens if exchange rate is not set to zero.
        if (exchangeRate != 0) {
            // Compute the amount of tokens and send to the backer.
            _sendToken(recipient, msg.value * exchangeRate);
        }

        // Check that the sender is paying the correct amount.
        require(
            msg.value >=
                IMirrorCrowdfundEditionsLogic(campaign.editionsProxy)
                    .editionPrice(editionId),
            "Insufficient payment for edition"
        );

        // Return the ID of the token that was minted from the purchase.
        tokenId = IMirrorCrowdfundEditionsLogic(campaign.editionsProxy)
            .purchase(editionId, recipient);

        // Broadcast that the edition was purchased.
        emit EditionPurchased(
            campaignId,
            editionId,
            msg.sender,
            recipient,
            tokenId,
            msg.value
        );
    }

    function _contribute(uint256 campaignId, address contributor) internal {
        // Assert that the contribution is not nothing.
        require(msg.value != 0, "contribution must be greater than 0");

        // Get the details of the relevant campaign.
        Campaign storage campaign = campaigns[campaignId];

        // Check if the campaign is registered.
        require(campaign.fundingCap > 0, "campaign does not exist");

        // Ensure that we have not already reached the funding cap.
        require(
            campaign.amountRaised < campaign.fundingCap,
            "funding cap reached"
        );

        // Calculate contribution and refund amounts.
        uint256 contribution = msg.value;
        uint256 refund_ = 0;
        uint256 fundsAfterContribution = msg.value + campaign.amountRaised;

        // Calculate new contirbution amount if original contribution puts
        // the funding amount above the funding target
        if (fundsAfterContribution > campaign.fundingCap) {
            contribution = campaign.fundingCap - campaign.amountRaised;
            refund_ = msg.value - contribution;
        }

        // Increment the amount raised by this contribution.
        campaign.amountRaised += contribution;

        // Send tokens if exchange rate is not set to zero.
        if (exchangeRate != 0) {
            // Compute the amount of tokens to send to the backer.
            uint256 tokenAmount = contribution * exchangeRate;
            // Mint the tokens.
            _sendToken(contributor, tokenAmount);
            // Emit an event with the number of tokens.
            emit CrowdfundContribution(
                campaignId,
                contributor,
                contribution,
                tokenAmount
            );
        } else {
            // Here we don't mint any tokens, so just emit an event with 0.
            emit CrowdfundContribution(
                campaignId,
                contributor,
                contribution,
                0
            );
        }

        // Send a refund if necessary.
        if (refund_ > 0) {
            _sendEther(payable(msg.sender), refund_);
        }
    }

    function _createCampaign(
        CampaignConfig calldata config,
        string calldata baseURI,
        EditionTier[] calldata tiers
    ) internal returns (address editionsProxy) {
        // Require a funding cap.
        require(config.fundingCap > 0, "must have funding cap");

        if (tiers.length > 0) {
            // Deploy a new editions proxy for the campaign.
            // All campaign NFTs are minted here.
            editionsProxy = IMirrorCrowdfundEditionsFactory(editionsFactory)
                .deployAndCreateEditions(
                    owner, // Same owner as this contract.
                    config.name,
                    config.symbol,
                    baseURI,
                    tiers
                );
        }

        // Initialize a new campaign.
        campaigns[++nextCampaignId] = Campaign({
            editionsProxy: editionsProxy,
            fundingCap: config.fundingCap,
            amountRaised: 0
        });

        // Broadcast an event about the new campaign.
        emit CampaignCreated(
            nextCampaignId,
            config.name,
            config.symbol,
            config.fundingCap,
            editionsProxy
        );
    }

    function _closeFunding() internal {
        // Close funding via the status.
        fundingStatus = FundingStatus.CLOSED;
    }

    function _openFunding() internal {
        // Open funding via the status.
        fundingStatus = FundingStatus.CONTRIBUTE;
    }

    function _withdraw(uint16 feePercentage_) internal {
        // Assert that the fee is valid.
        require(
            IMirrorFeeConfig(feeConfig).isFeeValid(feePercentage_),
            "invalid fee"
        );
        // Calculate the fee on the current balance, using the fee percentage.
        uint256 fee = _feeAmount(address(this).balance, feePercentage_);
        // If the fee is not zero, attempt to send it to the treasury.
        if (fee != 0) {
            IMirrorTreasury(ITreasuryConfig(treasuryConfig).treasury())
                .contribute{value: fee}(fee);
        }
        // Broadcast the withdrawal event – with balance and fee.
        emit Withdrawal(fundingRecipient, address(this).balance, fee);
        // Transfer the remaining balance to the fundingRecipient.
        _sendEther(payable(fundingRecipient), address(this).balance);
    }

    /// @notice Sends a token from the owner to a given account.
    function _sendToken(address to, uint256 amount) internal {
        IMirrorERC20Logic(token).transferFrom(owner, to, amount);
    }

    function _sendEther(address payable recipient_, uint256 amount) internal {
        // Ensure sufficient balance.
        require(address(this).balance >= amount, "insufficient balance");
        // Send the value.
        (bool success, ) = recipient_.call{value: amount}("");
        require(success, "recipient reverted");
    }

    function _feeAmount(uint256 amount, uint16 fee)
        internal
        pure
        returns (uint256)
    {
        return (amount * fee) / 10000;
    }

    function _hasRedeemedWithProof(
        bytes32 root,
        uint256 index,
        address account
    ) public view returns (bool) {
        return redeemedWithProof[_getRootAccountHash(root, index, account)];
    }

    function _setRedeemedWithProof(
        bytes32 root,
        uint256 index,
        address account
    ) private {
        redeemedWithProof[_getRootAccountHash(root, index, account)] = true;
    }

    function _getRootAccountHash(
        bytes32 root,
        uint256 index,
        address account
    ) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(root, index, account));
    }

    /// @dev Get a hash of a node
    function getRedeemNode(
        address account,
        uint256 amountToBurn,
        uint256 ethToReceive,
        uint256 index
    ) private pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(account, amountToBurn, ethToReceive, index)
            );
    }

    function hasContributedWithProof(
        bytes32 root,
        uint256 index,
        address account
    ) public view returns (bool) {
        return contributedWithProof[_getRootAccountHash(root, index, account)];
    }

    function setContributedWithProof(
        bytes32 root,
        uint256 index,
        address account
    ) private {
        contributedWithProof[_getRootAccountHash(root, index, account)] = true;
    }

    /// @dev Get a hash of a node
    function _getContributeNode(
        address account,
        uint256 maxAmount,
        uint256 index
    ) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(account, maxAmount, index));
    }

    /// @notice Verifies a Merkle proof proving the existence of a leaf in a Merkle tree.
    /// Assumes that each pair of leaves and each pair of pre-images is sorted.
    /// @param proof Merkle proof containing sibling hashes on the branch from the leaf
    /// to the root of the Merkle tree
    /// @param root Merkle root
    /// @param leaf Leaf of Merkle tree
    function _verifyProof(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) private pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(
                    abi.encodePacked(computedHash, proofElement)
                );
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(
                    abi.encodePacked(proofElement, computedHash)
                );
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
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

interface IERC20Events {
    /// @notice EIP-20 Mint event
    event Mint(address indexed to, uint256 amount);

    /// @notice EIP-20 approval event
    event Approval(
        address indexed from,
        address indexed spender,
        uint256 value
    );

    /// @notice EIP-20 transfer event
    event Transfer(address indexed from, address indexed to, uint256 value);
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

import {IMirrorCrowdfundEditionsLogic} from "./IMirrorCrowdfundEditionsLogic.sol";

interface IMirrorCrowdfundEditionsFactoryEvents {
    event EditionsProxyDeployed(address proxy, address operator, address logic);
}

interface IMirrorCrowdfundEditionsFactory {
    function deployAndCreateEditions(
        address owner,
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        IMirrorCrowdfundEditionsLogic.EditionTier[] memory tiers
    ) external returns (address proxy);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

import {IMirrorCrowdfundEditionStructs} from "./IMirrorCrowdfundEditionStructs.sol";

interface IMirrorCrowdfundEditionsLogicEvents {
    /// @notice Create edition
    event EditionCreated(
        uint256 purchasableAmount,
        uint256 price,
        uint256 editionId
    );

    event EditionPurchased(
        uint256 editionId,
        uint256 indexed tokenId,
        uint256 amountPaid,
        address buyer,
        address receiver
    );

    event OperatorChanged(
        address indexed proxy,
        address oldOperator,
        address newOperator
    );

    event EditionLimitSet(uint256 indexed editionId, uint256 limit);
}

interface IMirrorCrowdfundEditionsLogic is IMirrorCrowdfundEditionStructs {
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
        owner = address(0);

        emit OwnershipTransferred(owner, address(0));
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

contract Reentrancy {
    // ============ Constants ============

    uint256 internal constant REENTRANCY_NOT_ENTERED = 1;
    uint256 internal constant REENTRANCY_ENTERED = 2;

    // ============ Mutable Storage ============

    uint256 internal reentrancyStatus;

    // ============ Modifiers ============

    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(reentrancyStatus != REENTRANCY_ENTERED, "Reentrant call");
        // Any calls to nonReentrant after this point will fail
        reentrancyStatus = REENTRANCY_ENTERED;
        _;
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip2200)
        reentrancyStatus = REENTRANCY_NOT_ENTERED;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

interface ITreasuryConfig {
    function treasury() external returns (address payable);

    function distributionModel() external returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

interface IMirrorTreasury {
    function transferFunds(address payable to, uint256 value) external;

    function transferERC20(
        address token,
        address to,
        uint256 value
    ) external;

    function contributeWithTributary(address tributary) external payable;

    function contribute(uint256 amount) external payable;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

import {Ownable} from "../lib/Ownable.sol";

interface IMirrorFeeConfig {
    function maxFee() external returns (uint16);

    function minFee() external returns (uint16);

    function isFeeValid(uint16) external view returns (bool);

    function updateMaxFee(uint16 newFee) external;

    function updateMinFee(uint16 newFee) external;
}

/**
 * @title MirrorFeeConfig
 * @author MirrorXYZ
 */
contract MirrorFeeConfig is IMirrorFeeConfig, Ownable {
    uint16 public override maxFee = 500;
    uint16 public override minFee = 250;

    constructor(address owner_) Ownable(owner_) {}

    function updateMaxFee(uint16 newFee) external override onlyOwner {
        maxFee = newFee;
    }

    function updateMinFee(uint16 newFee) external override onlyOwner {
        minFee = newFee;
    }

    function isFeeValid(uint16 fee)
        external
        view
        returns (bool isBeweenMinAndMax)
    {
        isBeweenMinAndMax = (minFee <= fee) && (fee <= maxFee);
    }
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