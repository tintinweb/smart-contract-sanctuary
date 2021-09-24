// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./libraries/HellishTransfers.sol";
import "./libraries/HellishBlocks.sol";
import "./GreedStarterIndexer.sol";
import "./abstract/HellGoverned.sol";

contract GreedStarter is Initializable, UUPSUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable, HellGoverned {
    using HellishTransfers for address;
    using HellishTransfers for address payable;
    using HellishBlocks for uint;

    GreedStarterIndexer private _indexer;
    address public _indexerAddress;

    uint public _totalProjects;
    mapping(uint => Project) _projects;
    // Used to verify if the Project creator has withdrawn his rewards or leftover tokens (projectId => bool)
    mapping(uint => mapping(address => uint)) public _paidAmount;
    mapping(uint => mapping(address => uint)) public _pendingRewards;

    struct Project {
        // Unique identifier for this project
        uint id;
        // Token address being offered, this is what users will receive after investing
        address payable tokenAddress;
        // Token address used to invest, this is what users will have to pay in order to invest
        address payable paidWith;
        // Time frames in which the project will be available for investments
        uint startingBlock;
        uint endsAtBlock;
        // Defines how much 1 unit of the token costs against the paidWith asset
        uint pricePerToken;
        // Total amount of tokens available for sale on this project
        uint totalTokens;
        // Amount of tokens that were sold, from the totalTokens
        uint totalSold;
        // Rewards Collected, total amount of the paidWith currency that the project has collected.
        uint rewardsCollected;
        // Minimum amount that any address is allowed to purchase
        uint minimumPurchase;
        // Maximum amount that any address is allowed to purchase
        uint maximumPurchase;
        // Address of the creator of the project
        address createdBy;
        // Indicates if the Project creator withdrawn his corresponding funds.
        bool fundsOrRewardsWithdrawnByCreator;
        // Added on responses only
        // displays how much the msg.sender paid on this project
        uint yourPaidAmount;
        // displays the amount of pending rewards the msg.sender has.
        uint yourPendingRewards;
    }
    ////////////////////////////////////////////////////////////////////
    // External functions                                           ////
    ////////////////////////////////////////////////////////////////////
    function createProject(
        address payable tokenAddress,
        address payable paidWith,
        uint totalTokens,
        uint startingBlock,
        uint endsAtBlock,
        uint pricePerToken,
        uint minimumPurchase,
        uint maximumPurchase
    ) external nonReentrant {
        // CP1: Cannot create a project of the network currency
        require(tokenAddress != address(0), "CP1");
        // CP2: Cannot create a project and sell it for the same currency
        require(tokenAddress != paidWith, "CP2");
        // CP3: The Project Token must have 18 decimals of precision
        require(IERC20Metadata(tokenAddress).decimals() == 18, "CP3");
        // CP4: The minimum length should be of at least _minimumProjectLength blocks
        require(block.number.lowerThan(endsAtBlock) && (endsAtBlock - block.number) >= _hellGovernmentContract._minimumProjectLength(), "CP4");
        // CP5: The startingBlock should be higher or equal to the current block and lower than the ending block
        require(startingBlock.notElapsedOrEqualToCurrentBlock() && startingBlock.lowerThan(endsAtBlock), "CP5");
        // CP10: The project length should be lower or equal to the _maximumProjectLength
        require(endsAtBlock - startingBlock <= _hellGovernmentContract._maximumProjectLength(), "CP10");
        // CP6: The minimum and maximum purchase must be higher or equal to 0.01, (1e16 wei)
        // We enforce this to ensure enough precision on price calculations
        require(1e16 <= minimumPurchase  && 1e16 <= maximumPurchase, "CP6");
        // CP7: The minimumPurchase must be lower or equal to the maximumPurchase
        require(minimumPurchase <= maximumPurchase, "CP7");
        // CP8: The pricePerToken per token must be higher or equal to 1e6 wei (Like on USDT or USDC)
        require(1e6 <= pricePerToken, "CP8");
        // CP9: The Total Tokens cannot be lower than the maximum or minimumPurchase
        // Since we already tested for minimumPurchase and maximumPurchase we can assume that the totalTokens are also higher or equal than 1e16
        require(minimumPurchase <= totalTokens && maximumPurchase <= totalTokens, "CP9");
        // safeDepositAsset: Validates for enough: balance, allowance and if the GreedStarter Contract received the expected amount
        payable(address(this)).safeDepositAsset(tokenAddress, totalTokens);
        // Increase the total projects, this value will be used as our next project id
        _totalProjects += 1;
        // Create a new Project and fill it
        Project memory project;
        project.id = _totalProjects;
        project.tokenAddress = tokenAddress;
        project.paidWith = paidWith;
        project.totalTokens = totalTokens;
        project.startingBlock = startingBlock;
        project.endsAtBlock = endsAtBlock;
        project.pricePerToken = pricePerToken;
        project.createdBy = msg.sender;
        project.minimumPurchase = minimumPurchase;
        project.maximumPurchase = maximumPurchase;
        // Save the project
        _projects[_totalProjects] = project;
        // Logs a ProjectCreated event
        emit ProjectCreated(project.id, project.tokenAddress, project.paidWith, project.totalTokens, project.startingBlock, project.endsAtBlock, project.pricePerToken);
     }

     function invest(uint projectId, uint amountToBuy) external payable nonReentrant {
         Project storage project = _projects[projectId];
         // I1: This project doesn't exists
         require(project.id != 0, "I1");
         // I2: "You can't invest in your your own project"
         require(msg.sender != project.createdBy, "I2");
         // I3: This project already finished
         require(project.endsAtBlock.notElapsed(), "I3");
         // I4: This project hasn't started yet
         require(project.startingBlock.elapsedOrEqualToCurrentBlock(), "I4");
         // I5: Not enough tokens available to perform this investment;
         require((project.totalTokens - project.totalSold) >= amountToBuy, "I5");
         // I6: You can't purchase less than the minimum amount
         require(amountToBuy >= project.minimumPurchase, "I6");
         // I7: You can't purchase more than the maximum allowed
         require(_pendingRewards[projectId][msg.sender] + amountToBuy <= project.maximumPurchase, "I7");
         // Calculate the amount that the user has to pay for this investment
         uint amountToPay = (project.pricePerToken * amountToBuy) / 1 ether;
         // Transfer user funds to the Greed Starter Contract
         // safeDepositAsset: Validates for enough: balance, allowance and if the GreedStarter Contract received the expected amount
         payable(address(this)).safeDepositAsset(project.paidWith, amountToPay);
         // Register user participation
         _indexer._registerUserParticipation(projectId, msg.sender);
         // Save changes
         // If the project is being paid with the Network currency, we can safely pass msg.value to avoid negligible leftovers.
         // safeDepositAsset already verified that the amountToPay was higher or equal to msg.value.
         if(project.paidWith == address(0)) {
             // Update the amount the user has invested in this project
             _paidAmount[projectId][msg.sender] += msg.value;
             // Update the total investments the project has collected
             project.rewardsCollected += msg.value;
         // Else if we are paying with a ERC20 compliant token.
         } else {
             // Update the amount the user has invested in this project
             _paidAmount[projectId][msg.sender] += amountToPay;
             // Update the total investments the project has collected
             project.rewardsCollected += amountToPay;
         }
         // Update the total amount that this project has sold
         project.totalSold += amountToBuy;
         // Update the amount of rewards that will be available for the investor once the project ends.
         _pendingRewards[projectId][msg.sender] += amountToBuy;
         // Logs an InvestedInProject event
         emit InvestedInProject(projectId, msg.sender, amountToPay, amountToBuy, _paidAmount[projectId][msg.sender], _pendingRewards[projectId][msg.sender]);
     }

    function claimFunds(uint projectId) external nonReentrant {
        Project storage project = _projects[projectId];
        // CF1: "This project is still in progress"
        require(project.endsAtBlock.elapsed(), "CF1");
        // If the msg.sender is the project creator
        if(msg.sender == project.createdBy) {
            // CF2: You already withdrawn your rewards and leftover tokens
            require(project.fundsOrRewardsWithdrawnByCreator == false, "CF2");
            // Mark his project rewards as claimed
            _projects[projectId].fundsOrRewardsWithdrawnByCreator = true;
            uint userReceives;
            uint feePaid;
            // If the project collected more than 0 rewards, transfer the earned rewards to the project creator and pay treasury fees.
            if (project.rewardsCollected > 0) {
                (userReceives, feePaid) = payable(project.createdBy).safeTransferAssetAndPayFee(project.paidWith, project.rewardsCollected, _hellGovernmentContract._hellTreasuryAddress(), _hellGovernmentContract._greedStarterTreasuryFee());
            }
            // Calculate if there were leftover tokens
            uint unsoldAmount = project.totalTokens - project.totalSold;
            if (unsoldAmount > 0) {
                // Transfer leftover tokens back to the project creator
                payable(project.createdBy).safeTransferAsset(project.tokenAddress, unsoldAmount);
            }
            // Logs a CreatorWithdrawnFunds event.
            emit CreatorWithdrawnFunds(projectId, msg.sender, project.rewardsCollected, feePaid, userReceives, unsoldAmount);
        // If the msg.sender isn't the project creator.
        } else {
            uint rewardedAmount = _pendingRewards[projectId][msg.sender];
            // CF3: "You don't have any reward to claim"
            require(_pendingRewards[projectId][msg.sender] > 0, "CF3");
            // Set user pendingRewards back to 0
            _pendingRewards[projectId][msg.sender] = 0;
            // Send the user his earned rewards
            payable(msg.sender).safeTransferAsset(project.tokenAddress, rewardedAmount);
            // Logs a RewardsClaimed event.
            emit RewardsClaimed(projectId, msg.sender, rewardedAmount);
        }
    }
    ////////////////////////////////////////////////////////////////////
    // Views                                                        ////
    ////////////////////////////////////////////////////////////////////
    function getProjects(uint[] memory ids) external view returns(Project[] memory) {
        require(ids.length <= 30, "PAG"); // PAG: Pagination limit exceeded
        Project[] memory projects = new Project[](ids.length);
        for(uint i = 0; i < ids.length; i++) {
            projects[i] = _projects[ids[i]];
            projects[i].yourPaidAmount = _paidAmount[ids[i]][msg.sender];
            projects[i].yourPendingRewards = _pendingRewards[ids[i]][msg.sender];
        }
        return projects;
    }
    ////////////////////////////////////////////////////////////////////
    // Only Owner                                                   ////
    ////////////////////////////////////////////////////////////////////
    function _authorizeUpgrade(address) internal override onlyOwner {}
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}
    function initialize(address hellGovernmentAddress) initializer public {
        __Ownable_init();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
        _setHellGovernmentContract(hellGovernmentAddress);
    }

    function _setIndexer(address indexerAddress) external onlyOwner {
        _indexerAddress = indexerAddress;
        _indexer = GreedStarterIndexer(indexerAddress);
        emit GreedStarterIndexerUpdated(indexerAddress);
    }

    function _forceEndProject(uint projectId) external onlyOwner {
        // FE: The project doesn't exists or already ended
        require(_projects[projectId].id != 0 && block.number.lowerThan(_projects[projectId].endsAtBlock), "FE");
        _projects[projectId].endsAtBlock = block.number;
        emit ProjectClosedByAdmin(projectId);
    }
    ////////////////////////////////////////////////////////////////////
    // Events                                                       ////
    ////////////////////////////////////////////////////////////////////
    event ProjectCreated(uint indexed projectId, address payable tokenAddress, address payable paidWith, uint totalAvailable, uint startingBlock, uint endsAtBlock, uint pricePerToken);
    event InvestedInProject(uint indexed projectId, address userAddress, uint amountPaid, uint amountRewarded, uint totalPaid, uint totalRewarded);
    event CreatorWithdrawnFunds(uint indexed projectId, address creatorAddress, uint amountRewarded, uint paidFees, uint amountRewardedAfterFees, uint amountRecovered);
    event RewardsClaimed(uint indexed projectId, address userAddress, uint amountRewarded);
    event GreedStarterIndexerUpdated(address newIndexerAddress);
    event ProjectClosedByAdmin(uint projectId);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal initializer {
        __ERC1967Upgrade_init_unchained();
        __UUPSUpgradeable_init_unchained();
    }

    function __UUPSUpgradeable_init_unchained() internal initializer {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: BSD 3-Clause
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

library HellishTransfers {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using AddressUpgradeable for address;
    using AddressUpgradeable for address payable;

    function safeDepositAsset(address recipient, address tokenAddress, uint amount) internal {
        if(tokenAddress == address(0)) {
            // DA1: "You didn't send enough Ether for this operation"
            require(msg.value >= amount, "DA1");
        } else {
            IERC20Upgradeable tokenInterface = IERC20Upgradeable(tokenAddress);
            // DA2: "Not enough balance to perform this action";
            require(tokenInterface.balanceOf(msg.sender) >= amount, "DA2");
            // DA3: "Not enough allowance to perform this action";
            require(tokenInterface.allowance(msg.sender, recipient) >= amount, "DA3");
            uint recipientBalance = tokenInterface.balanceOf(recipient);
            // Transfer Sender tokens to the Recipient
            tokenInterface.safeTransferFrom(msg.sender, recipient, amount);
            // DA4: You didn't send enough tokens for this operation
            require(recipientBalance + amount == tokenInterface.balanceOf(recipient), "DA4");
        }
    }

    function safeTransferAsset(
        address payable recipient,
        address transferredTokenAddress,
        uint amount
    ) internal {
        // If the token is the zero address we know that we are using the network currency
        if(transferredTokenAddress == address(0)) {
            recipient.sendValue(amount);
        } else {
            // if it isn't the zero address, pay with their respective currency
            IERC20Upgradeable tokenInterface = IERC20Upgradeable(transferredTokenAddress);
            tokenInterface.safeTransfer(recipient, amount);
        }
    }

    function safeTransferAssetAndPayFee(
        address payable recipient,
        address transferredTokenAddress,
        uint amount,
        address payable treasuryAddress,
        uint16 treasuryFee
    ) internal returns (uint recipientReceives, uint fee) {
        require(treasuryFee > 0, "Treasury Fees cannot be zero");
        // Fee will be 0 if amount is less than the treasuryFee, causing absolution from treasuryFees
        fee = amount / uint(treasuryFee);
        recipientReceives = amount - fee;
        // If the token is the zero address we know that we are using the network currency
        if (transferredTokenAddress == address(0)) {
            // Pay Treasury Fees
            if(fee > 0) {
                treasuryAddress.sendValue(fee);
            }
            // Send funds to recipient
            recipient.sendValue(recipientReceives);
        } else {
            // Else If the token is a compliant ERC20 token as defined in the EIP
            IERC20Upgradeable tokenInterface = IERC20Upgradeable(transferredTokenAddress);
            // Pay Treasury Fees
            if(fee > 0) {
                tokenInterface.safeTransfer(treasuryAddress, fee);
            }
            // Send funds to recipient
            tokenInterface.safeTransfer(recipient, recipientReceives);
        }
        return (recipientReceives, fee);
    }
}

// SPDX-License-Identifier: BSD 3-Clause
pragma solidity ^0.8.7;

library HellishBlocks {
    function lowerThan(uint blockNumber, uint higherBlock) internal pure returns (bool) {
        return blockNumber < higherBlock;
    }
    function higherThan(uint blockNumber, uint lowerBlock) internal pure returns (bool) {
        return blockNumber > lowerBlock;
    }
    function elapsedOrEqualToCurrentBlock(uint blockNumber) internal view returns (bool) {
        return blockNumber <= block.number;
    }
    function notElapsedOrEqualToCurrentBlock(uint blockNumber) internal view returns (bool) {
        return blockNumber >= block.number;
    }
    function elapsed(uint blockNumber) internal view returns (bool) {
        return blockNumber < block.number;
    }
    function notElapsed(uint blockNumber) internal view returns (bool) {
        return blockNumber > block.number;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./abstract/HellGoverned.sol";

contract GreedStarterIndexer is Initializable, UUPSUpgradeable, OwnableUpgradeable, HellGoverned {
    address public _greedStarterAddress;
    //////////////////////////////////////////////////////////////////////////
    uint public _totalTrustedProjects;
    mapping(uint => uint) public _trustedProjects;
    mapping(uint => bool) public _projectIsTrusted;
    //////////////////////////////////////////////////////////////////////////
    // Holds the number of projects the user has created
    mapping(address => uint) public _userTotalProjects;
    // Projects created by the specified user ( User address => index => project.id)
    mapping(address => mapping(uint => uint)) public _userProjects;
    //////////////////////////////////////////////////////////////////////////
    // Holds a boolean to let know if the user has participated on a specific project
    // userAddress => projectId => bool
    mapping(address => mapping(uint => bool)) public _userParticipatedInProject;
    // Holds the amount of projects where the user has participated
    // userAddress => totalParticipatedProjects
    mapping(address => uint) public _userTotalParticipatedProjects;
    // Holds the Project ids where the user participated
    // userAddress => index => projectId
    mapping(address => mapping(uint => uint)) public _userParticipatedProjects;
    ////////////////////////////////////////////////////////////////////
    // Public Views                                                 ////
    ////////////////////////////////////////////////////////////////////
    function getTrustedProjectIds(uint[] memory indexes) external view returns(uint[] memory) {
        require(indexes.length <= _hellGovernmentContract._generalPaginationLimit(), "PAG"); // Pagination limit exceeded
        uint[] memory trustedProjectIds = new uint[](indexes.length);
        for(uint i = 0; i < indexes.length; i++) {
            trustedProjectIds[i] = _trustedProjects[indexes[i]];
        }
        return trustedProjectIds;
    }
    ////////////////////////////////////////////////////////////////////
    // Greed Starter                                                ////
    ////////////////////////////////////////////////////////////////////

    function _registerUserParticipation(uint projectId, address userAddress) external onlyGreedStarter {
        if (_userParticipatedInProject[userAddress][projectId] == false) {
            _userParticipatedInProject[userAddress][projectId] = true;
            _userTotalParticipatedProjects[userAddress] += 1;
            _userParticipatedProjects[userAddress][_userTotalParticipatedProjects[userAddress]] = projectId;
        }
    }

    ////////////////////////////////////////////////////////////////////
    // Only Owner                                                   ////
    ////////////////////////////////////////////////////////////////////
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}
    function initialize(address hellGovernmentAddress, address greedStarterAddress) initializer public {
        __Ownable_init();
        __UUPSUpgradeable_init();
        _totalTrustedProjects = 0;
        _setHellGovernmentContract(hellGovernmentAddress);
        _setGreedStarterContractAddress(greedStarterAddress);
    }

    function _registerTrustedProject(uint projectId) external onlyOwner {
        _totalTrustedProjects += 1;
        _trustedProjects[_totalTrustedProjects] = projectId;
        _projectIsTrusted[projectId] = true;
        emit ProjectRegisteredAsTrusted(projectId);
    }

    function _removeFromTrustedProjects(uint projectIndex) external onlyOwner {
        uint projectId = _trustedProjects[projectIndex];
        _trustedProjects[projectIndex] = 0;
        _projectIsTrusted[projectId] = false;
        emit ProjectRemovedFromTrustedProjects(projectId, projectIndex);
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
    function _setGreedStarterContractAddress(address contractAddress) public onlyOwner {
        _greedStarterAddress = contractAddress;
        emit GreedStarterContractAddressUpdated(contractAddress);
    }
    ////////////////////////////////////////////////////////////////////
    // Modifiers                                                    ////
    ////////////////////////////////////////////////////////////////////
    modifier onlyGreedStarter() {
        require(_greedStarterAddress == msg.sender, "Forbidden");
        _;
    }
    ////////////////////////////////////////////////////////////////////
    // Events                                                       ////
    ////////////////////////////////////////////////////////////////////
    event GreedStarterContractAddressUpdated(address newContractAddress);
    event ProjectRegisteredAsTrusted(uint indexed projectId);
    event ProjectRemovedFromTrustedProjects(uint indexed projectId, uint indexed projectIndex);

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../HellGovernment.sol";


abstract contract HellGoverned is Initializable, OwnableUpgradeable {
    HellGovernment internal _hellGovernmentContract;

    function _setHellGovernmentContract(address hellGovernmentAddress) public onlyOwner {
        _hellGovernmentContract = HellGovernment(hellGovernmentAddress);
        emit HellGovernmentContractUpdated(hellGovernmentAddress);
    }

    event HellGovernmentContractUpdated(address newHellGovernmentAddress);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal initializer {
        __ERC1967Upgrade_init_unchained();
    }

    function __ERC1967Upgrade_init_unchained() internal initializer {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallSecure(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        address oldImplementation = _getImplementation();

        // Initial upgrade and setup call
        _setImplementation(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }

        // Perform rollback test if not already in progress
        StorageSlotUpgradeable.BooleanSlot storage rollbackTesting = StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT);
        if (!rollbackTesting.value) {
            // Trigger rollback using upgradeTo from the new implementation
            rollbackTesting.value = true;
            _functionDelegateCall(
                newImplementation,
                abi.encodeWithSignature("upgradeTo(address)", oldImplementation)
            );
            rollbackTesting.value = false;
            // Check rollback was effective
            require(oldImplementation == _getImplementation(), "ERC1967Upgrade: upgrade breaks further upgrades");
            // Finally reset to the new implementation and log the upgrade
            _upgradeTo(newImplementation);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

contract HellGovernment is Initializable, UUPSUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    // General variables
    address payable public _hellTreasuryAddress;
    uint16 public _generalPaginationLimit;
    // Help us know if a specific token address was marked as trusted or not.
    mapping(address => bool) public _tokenIsTrusted;
    // Auction House variables
    uint16 public _auctionHouseTreasuryFee;
    uint public _minimumAuctionLength;
    uint public _maximumAuctionLength;
    // Greed Starter variables
    uint16 public _greedStarterTreasuryFee;
    uint public _minimumProjectLength;
    uint public _maximumProjectLength;
    ////////////////////////////////////////////////////////////////////
    // Only Owner                                                   ////
    ////////////////////////////////////////////////////////////////////
    function _authorizeUpgrade(address) internal override onlyOwner {}
    /////////////////////////////////////
    // General                      ////
    ////////////////////////////////////
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}
    function initialize(address payable treasuryAddress, uint16 auctionHouseFee, uint minimumAuctionLength, uint maximumAuctionLength, uint16 greedStarterFee, uint minimumProjectLength, uint maximumProjectLength) initializer public {
        __Ownable_init();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
        _generalPaginationLimit = 40;
        _setTreasuryAddress(treasuryAddress);
        // Initialize Auction House Variables
        _setAuctionHouseTreasuryFees(auctionHouseFee);
        _setMinimumAndMaximumAuctionLength(minimumAuctionLength, maximumAuctionLength);
        // Initialize Greed Starter Variables
        _setGreedStarterTreasuryFees(greedStarterFee);
        _setMinimumAndMaximumProjectLength(minimumProjectLength, maximumProjectLength);
        // By default the only trusted token will be the Network currency
        _tokenIsTrusted[address(0)] = true;
    }

    function _setTreasuryAddress(address payable treasuryAddress) public onlyOwner {
        _hellTreasuryAddress = treasuryAddress;
        emit TreasuryAddressUpdated(treasuryAddress);
    }

    function _setGeneralPaginationLimit(uint16 newPaginationLimit) public onlyOwner {
        _generalPaginationLimit = newPaginationLimit;
        emit GeneralPaginationLimitUpdated(newPaginationLimit);
    }

    function _setTokenTrust(address tokenAddress, bool isTrusted) external onlyOwner {
        _tokenIsTrusted[tokenAddress] = isTrusted;
        emit UpdatedTokenTrust(tokenAddress, isTrusted);
    }
    /////////////////////////////////////
    // Auction House                ////
    ////////////////////////////////////
    function _setMinimumAndMaximumAuctionLength(uint newMinimumLength, uint newMaximumLength) public onlyOwner {
        _minimumAuctionLength = newMinimumLength;
        _maximumAuctionLength = newMaximumLength;
        emit MinimumAndMaximumAuctionLengthUpdated(newMinimumLength, newMaximumLength);
    }

    function _setAuctionHouseTreasuryFees(uint16 newFee) public onlyOwner {
        _auctionHouseTreasuryFee = newFee;
        emit AuctionHouseTreasuryFeesUpdated(newFee);
    }
    /////////////////////////////////////
    // Greed Starter                ////
    ////////////////////////////////////
    function _setMinimumAndMaximumProjectLength(uint newMinimumLength, uint newMaximumLength) public onlyOwner {
        _minimumProjectLength = newMinimumLength;
        _maximumProjectLength = newMaximumLength;
        emit MinimumAndMaximumProjectLengthUpdated(newMinimumLength, newMaximumLength);
    }

    function _setGreedStarterTreasuryFees(uint16 newFee) public onlyOwner {
        _greedStarterTreasuryFee = newFee;
        emit GreedStarterTreasuryFeesUpdated(newFee);
    }
    ////////////////////////////////////////////////////////////////////
    // Events                                                       ////
    ////////////////////////////////////////////////////////////////////
    event TreasuryAddressUpdated(address indexed treasuryAddress);
    event GeneralPaginationLimitUpdated(uint16 newLimit);
    event UpdatedTokenTrust(address tokenAddress, bool isTrusted);
    // Auction House
    event AuctionHouseTreasuryFeesUpdated(uint16 newFee);
    event MinimumAndMaximumAuctionLengthUpdated(uint newMinimumLength, uint newMaximumLength);
    // Greed Starter
    event GreedStarterTreasuryFeesUpdated(uint16 newFee);
    event MinimumAndMaximumProjectLengthUpdated(uint newMinimumLength, uint newMaximumLength);
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}