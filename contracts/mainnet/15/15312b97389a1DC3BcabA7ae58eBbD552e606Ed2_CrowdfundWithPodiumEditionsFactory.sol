// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import {CrowdfundWithPodiumEditionsProxy} from "./CrowdfundWithPodiumEditionsProxy.sol";
import {CrowdfundWithPodiumEditionsLogic} from "./CrowdfundWithPodiumEditionsLogic.sol";
import {ICrowdfundWithPodiumEditions} from "./interface/ICrowdfundWithPodiumEditions.sol";
import {ITributaryRegistry} from "../../../interface/ITributaryRegistry.sol";
import {Governable} from "../../../lib/Governable.sol";

/**
 * @title CrowdfundWithPodiumEditionsFactory
 * @author MirrorXYZ
 */
contract CrowdfundWithPodiumEditionsFactory is Governable {
    //======== Structs ========

    struct Parameters {
        address payable fundingRecipient;
        uint256 fundingCap;
        uint256 operatorPercent;
        string name;
        string symbol;
        uint256 feePercentage;
        uint256 podiumDuration;
    }

    //======== Events ========

    event CrowdfundDeployed(
        address crowdfundProxy,
        string name,
        string symbol,
        address operator
    );

    //======== Configuration storage =========

    /*
        Updatable via governance
    */

    address public logic;
    address payable public editions;
    address public tributaryRegistry;
    address public treasuryConfig;
    uint256 public minFeePercentage = 250;

    //======== Runtime mutable storage =========

    // Gets set within the block, and then deleted.
    Parameters public parameters;

    //======== Constructor =========

    constructor(
        address owner_,
        address logic_,
        address payable editions_,
        address tributaryRegistry_,
        address treasuryConfig_
    ) Governable(owner_) {
        logic = logic_;
        editions = editions_;
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

    function setEditions(address payable newEditions) public onlyGovernance {
        editions = newEditions;
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

    //======== Deploy function =========
    struct TributaryConfig {
        address tributary;
        uint256 feePercentage;
    }

    function createCrowdfund(
        ICrowdfundWithPodiumEditions.EditionTier[] calldata tiers,
        TributaryConfig calldata tributaryConfig,
        string calldata name_,
        string calldata symbol_,
        address payable operator_,
        address payable fundingRecipient_,
        uint256 fundingCap_,
        uint256 operatorPercent_,
        uint256 podiumDuration_
    ) external returns (address crowdfundProxy) {
        require(
            tributaryConfig.feePercentage >= minFeePercentage,
            "fee is too low"
        );

        parameters = Parameters({
            name: name_,
            symbol: symbol_,
            fundingRecipient: fundingRecipient_,
            fundingCap: fundingCap_,
            operatorPercent: operatorPercent_,
            feePercentage: tributaryConfig.feePercentage,
            podiumDuration: podiumDuration_
        });

        crowdfundProxy = address(
            new CrowdfundWithPodiumEditionsProxy{
                salt: keccak256(abi.encode(symbol_, operator_))
            }(treasuryConfig, operator_)
        );

        delete parameters;

        emit CrowdfundDeployed(crowdfundProxy, name_, symbol_, operator_);

        ITributaryRegistry(tributaryRegistry).registerTributary(
            crowdfundProxy,
            tributaryConfig.tributary
        );

        ICrowdfundWithPodiumEditions(editions).createEditions(
            tiers,
            payable(crowdfundProxy),
            crowdfundProxy
        );
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import {CrowdfundWithPodiumEditionsStorage} from "./CrowdfundWithPodiumEditionsStorage.sol";

interface ICrowdfundWithPodiumEditionsFactory {
    function mediaAddress() external returns (address);

    function logic() external returns (address);

    function editions() external returns (address);

    // ERC20 data.
    function parameters()
        external
        returns (
            address payable fundingRecipient,
            uint256 fundingCap,
            uint256 operatorPercent,
            string memory name,
            string memory symbol,
            uint256 feePercentage,
            uint256 podiumDuration
        );
}

/**
 * @title CrowdfundWithPodiumEditionsProxy
 * @author MirrorXYZ
 */
contract CrowdfundWithPodiumEditionsProxy is
    CrowdfundWithPodiumEditionsStorage
{
    constructor(address treasuryConfig_, address payable operator_) {
        logic = ICrowdfundWithPodiumEditionsFactory(msg.sender).logic();
        editions = ICrowdfundWithPodiumEditionsFactory(msg.sender).editions();
        // Crowdfund-specific data.
        (
            fundingRecipient,
            fundingCap,
            operatorPercent,
            name,
            symbol,
            feePercentage,
            podiumDuration
        ) = ICrowdfundWithPodiumEditionsFactory(msg.sender).parameters();

        operator = operator_;
        treasuryConfig = treasuryConfig_;
        // Initialize mutable storage.
        status = Status.FUNDING;
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

import {CrowdfundWithPodiumEditionsStorage} from "./CrowdfundWithPodiumEditionsStorage.sol";
import {ICrowdfundWithPodiumEditions} from "./interface/ICrowdfundWithPodiumEditions.sol";
import {ITreasuryConfig} from "../../../interface/ITreasuryConfig.sol";

/**
 * @title CrowdfundWithPodiumEditionsLogic
 * @author MirrorXYZ
 *
 * Crowdfund the creation of NFTs by issuing ERC20 tokens that
 * can be redeemed for the underlying value of the NFT once sold.
 */
contract CrowdfundWithPodiumEditionsLogic is
    CrowdfundWithPodiumEditionsStorage
{
    // ============ Events ============

    event ReceivedERC721(uint256 tokenId, address sender);
    event Contribution(address contributor, uint256 amount);
    event ContributionForEdition(
        address contributor,
        uint256 amount,
        uint256 editionId,
        uint256 tokenId
    );

    event FundingClosed(uint256 amountRaised, uint256 creatorAllocation);
    event BidAccepted(uint256 amount);
    event Redeemed(address contributor, uint256 amount);
    // ERC20 Events
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    // Podium Events
    event PodiumDurationExtended(uint256 editionId);

    // ============ Modifiers ============

    /**
     * @dev Modifier to check whether the `msg.sender` is the operator.
     * If it is, it will run the function. Otherwise, it will revert.
     */
    modifier onlyOperator() {
        require(msg.sender == operator);
        _;
    }

    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(reentrancy_status != REENTRANCY_ENTERED, "Reentrant call");

        // Any calls to nonReentrant after this point will fail
        reentrancy_status = REENTRANCY_ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        reentrancy_status = REENTRANCY_NOT_ENTERED;
    }

    // ============ Crowdfunding Methods ============

    function contributeForPodium(
        address payable backer,
        uint256 editionId,
        uint256 amount
    ) external payable nonReentrant {
        _contribute(backer, editionId, amount, true);
    }

    /**
     * @notice Mints tokens for the sender propotional to the
     *  amount of ETH sent in the transaction.
     * @dev Emits the Contribution event.
     */
    function contribute(
        address payable backer,
        uint256 editionId,
        uint256 amount
    ) external payable nonReentrant {
        _contribute(backer, editionId, amount, false);
    }

    /**
     * @notice Burns the sender's tokens and redeems underlying ETH.
     * @dev Emits the Redeemed event.
     */
    function redeem(uint256 tokenAmount) external nonReentrant {
        // Prevent backers from accidently redeeming when balance is 0.
        require(
            address(this).balance > 0,
            "Crowdfund: No ETH available to redeem"
        );
        // Check
        require(
            balanceOf[msg.sender] >= tokenAmount,
            "Crowdfund: Insufficient balance"
        );
        require(status == Status.TRADING, "Crowdfund: Funding must be trading");
        // Effect
        uint256 redeemable = redeemableFromTokens(tokenAmount);
        _burn(msg.sender, tokenAmount);
        // Safe version of transfer.
        sendValue(payable(msg.sender), redeemable);
        emit Redeemed(msg.sender, redeemable);
    }

    /**
     * @notice Returns the amount of ETH that is redeemable for tokenAmount.
     */
    function redeemableFromTokens(uint256 tokenAmount)
        public
        view
        returns (uint256)
    {
        return (tokenAmount * address(this).balance) / totalSupply;
    }

    function valueToTokens(uint256 value) public pure returns (uint256 tokens) {
        tokens = value * TOKEN_SCALE;
    }

    function tokensToValue(uint256 tokenAmount)
        internal
        pure
        returns (uint256 value)
    {
        value = tokenAmount / TOKEN_SCALE;
    }

    // ============ Operator Methods ============

    /**
     * @notice Transfers all funds to operator, and mints tokens for the operator.
     *  Updates status to TRADING.
     * @dev Emits the FundingClosed event.
     */
    function closeFunding() external onlyOperator nonReentrant {
        require(status == Status.FUNDING, "Crowdfund: Funding must be open");
        // Close funding status, move to tradable.
        status = Status.TRADING;
        // Mint the operator a percent of the total supply.
        uint256 operatorTokens = (operatorPercent * totalSupply) /
            (100 - operatorPercent);
        _mint(operator, operatorTokens);
        // Announce that funding has been closed.
        emit FundingClosed(address(this).balance, operatorTokens);
        // Transfer the fee to the treasury.
        sendValue(
            ITreasuryConfig(treasuryConfig).treasury(),
            computeFee(address(this).balance)
        );
        // Transfer available balance to the fundingRecipient.
        sendValue(fundingRecipient, address(this).balance);
    }

    function computeFee(uint256 amount) public view returns (uint256 fee) {
        fee = (feePercentage * amount) / (100 * 100);
    }

    // ============ Utility Methods ============

    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    // ============ ERC20 Spec ============

    function _mint(address to, uint256 value) internal {
        totalSupply = totalSupply + value;
        balanceOf[to] = balanceOf[to] + value;
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint256 value) internal {
        balanceOf[from] = balanceOf[from] - value;
        totalSupply = totalSupply - value;
        emit Transfer(from, address(0), value);
    }

    function _approve(
        address owner,
        address spender,
        uint256 value
    ) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(
        address from,
        address to,
        uint256 value
    ) private {
        balanceOf[from] = balanceOf[from] - value;
        balanceOf[to] = balanceOf[to] + value;
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint256 value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint256 value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool) {
        allowance[from][msg.sender] = allowance[from][msg.sender] - value;
        _transfer(from, to, value);
        return true;
    }

    // ============ Tiered Campaigns ============

    function buyEdition(
        uint256 amount,
        uint256 editionId,
        address recipient
    ) internal returns (uint256) {
        // Check that the sender is paying the correct amount.
        require(
            amount >=
                ICrowdfundWithPodiumEditions(editions).editionPrice(editionId),
            "Unable purchase edition with available amount"
        );
        // We don't need to transfer the value to the NFT contract here,
        // since that contract trusts this one to check before minting.
        // I.E. this contract has minting privileges.
        return
            ICrowdfundWithPodiumEditions(editions).buyEdition(
                editionId,
                recipient
            );
    }

    function buyEditionForPodium(
        uint256 amount,
        uint256 editionId,
        address recipient
    ) internal returns (uint256) {
        // Check that the sender is paying the correct amount.
        require(
            amount >=
                ICrowdfundWithPodiumEditions(editions).editionPrice(editionId),
            "Unable purchase edition with available amount"
        );

        if (podiumStartTime == 0) {
            podiumStartTime = block.timestamp;
        }

        uint256 podiumEnds = podiumStartTime + podiumDuration;

        require(podiumEnds >= block.timestamp, "podium closed");

        if (podiumEnds < block.timestamp + PODIUM_TIME_BUFFER) {
            // Extend duration.
            podiumDuration += block.timestamp + PODIUM_TIME_BUFFER - podiumEnds;
            emit PodiumDurationExtended(editionId);
        }

        // We don't need to transfer the value to the NFT contract here,
        // since that contract trusts this one to check before minting.
        // I.E. this contract has minting privileges.
        return
            ICrowdfundWithPodiumEditions(editions).buyEdition(
                editionId,
                recipient
            );
    }

    function _contribute(
        address payable backer,
        uint256 editionId,
        uint256 amount,
        bool forPodium
    ) private {
        require(status == Status.FUNDING, "Crowdfund: Funding must be open");
        require(amount == msg.value, "Crowdfund: Amount is not value sent");
        // This first case is the happy path, so we will keep it efficient.
        // The balance, which includes the current contribution, is less than or equal to cap.
        if (address(this).balance <= fundingCap) {
            // Mint equity for the contributor.
            _mint(backer, valueToTokens(amount));

            // Editions start at 1, so a "0" edition means the user wants to contribute without
            // purchasing a token.
            if (editionId > 0) {
                emit ContributionForEdition(
                    backer,
                    amount,
                    editionId,
                    forPodium
                        ? buyEditionForPodium(amount, editionId, backer)
                        : buyEdition(amount, editionId, backer)
                );
            } else {
                emit Contribution(backer, amount);
            }
        } else {
            // Compute the balance of the crowdfund before the contribution was made.
            uint256 startAmount = address(this).balance - amount;
            // If that amount was already greater than the funding cap, then we should revert immediately.
            require(
                startAmount < fundingCap,
                "Crowdfund: Funding cap already reached"
            );
            // Otherwise, the contribution helped us reach the funding cap. We should
            // take what we can until the funding cap is reached, and refund the rest.
            uint256 eligibleAmount = fundingCap - startAmount;
            // Otherwise, we process the contribution as if it were the minimal amount.
            _mint(backer, valueToTokens(eligibleAmount));

            if (editionId > 0) {
                emit ContributionForEdition(
                    backer,
                    eligibleAmount,
                    editionId,
                    // Attempt to purchase edition with eligible amount.
                    forPodium
                        ? buyEditionForPodium(eligibleAmount, editionId, backer)
                        : buyEdition(eligibleAmount, editionId, backer)
                );
            } else {
                emit Contribution(backer, eligibleAmount);
            }
            // Refund the sender with their contribution (e.g. 2.5 minus the diff - e.g. 1.5 = 1 ETH)
            sendValue(backer, amount - eligibleAmount);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

interface ICrowdfundWithPodiumEditions {
    struct Edition {
        // The maximum number of tokens that can be sold.
        uint256 quantity;
        // The price at which each token will be sold, in ETH.
        uint256 price;
        // The account that will receive sales revenue.
        address payable fundingRecipient;
        // The number of tokens sold so far.
        uint256 numSold;
        bytes32 contentHash;
    }

    struct EditionTier {
        // The maximum number of tokens that can be sold.
        uint256 quantity;
        // The price at which each token will be sold, in ETH.
        uint256 price;
        bytes32 contentHash;
    }

    function buyEdition(uint256 editionId, address recipient)
        external
        payable
        returns (uint256 tokenId);

    function editionPrice(uint256 editionId) external view returns (uint256);

    function createEditions(
        EditionTier[] memory tier,
        // The account that should receive the revenue.
        address payable fundingRecipient,
        address minter
    ) external;

    function contractURI() external view returns (string memory);
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

/**
 * @title CrowdfundWithPodiumEditionsStorage
 * @author MirrorXYZ
 */
contract CrowdfundWithPodiumEditionsStorage {
    // The two states that this contract can exist in. "FUNDING" allows
    // contributors to add funds.
    enum Status {
        FUNDING,
        TRADING
    }

    // ============ Constants ============

    // The factor by which ETH contributions will multiply into crowdfund tokens.
    uint16 internal constant TOKEN_SCALE = 1000;
    uint256 internal constant REENTRANCY_NOT_ENTERED = 1;
    uint256 internal constant REENTRANCY_ENTERED = 2;
    uint16 public constant PODIUM_TIME_BUFFER = 900;
    uint8 public constant decimals = 18;

    // ============ Immutable Storage ============

    // The operator has a special role to change contract status.
    address payable public operator;
    address payable public fundingRecipient;
    address public treasuryConfig;
    // We add a hard cap to prevent raising more funds than deemed reasonable.
    uint256 public fundingCap;
    uint256 public feePercentage;
    // The operator takes some equity in the tokens, represented by this percent.
    uint256 public operatorPercent;
    string public symbol;
    string public name;

    // ============ Mutable Storage ============

    // Represents the current state of the campaign.
    Status public status;
    uint256 internal reentrancy_status;


    // Podium storage
    uint256 public podiumStartTime;
    uint256 public podiumDuration;

    // ============ Mutable ERC20 Attributes ============

    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => uint256) public nonces;

    // ============ Delegation logic ============
    address public logic;

    // ============ Tiered Campaigns ============
    // Address of the editions contract to purchase from.
    address public editions;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

interface ITreasuryConfig {
    function treasury() external returns (address payable);

    function distributionModel() external returns (address);
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

