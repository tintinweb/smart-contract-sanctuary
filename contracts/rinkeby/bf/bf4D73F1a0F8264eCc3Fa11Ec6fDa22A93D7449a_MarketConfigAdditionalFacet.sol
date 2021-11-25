// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "../../../interfaces/IMarketController.sol";
import "../../../interfaces/IMarketConfigAdditional.sol";
import "../../../interfaces/IMarketClerk.sol";
import "../../diamond/DiamondLib.sol";
import "../MarketControllerBase.sol";
import "../MarketControllerLib.sol";

/**
 * @title MarketConfigFacet
 *
 * @notice Provides centralized management of various market-related settings.
 *
 * @author Cliff Hall <[email protected]> (https://twitter.com/seaofarrows)
 */
contract MarketConfigAdditionalFacet is IMarketConfigAdditional, MarketControllerBase {

    /**
     * @dev Modifier to protect initializer function from being invoked twice.
     */
    modifier onlyUnInitialized()
    {
        MarketControllerLib.MarketControllerInitializers storage mci = MarketControllerLib.marketControllerInitializers();
        require(!mci.configAdditionalFacet, "Initializer: contract is already initialized");
        mci.configAdditionalFacet = true;
        _;
    }

    /**
     * @notice Facet Initializer
     *
     * @param _allowExternalTokensOnSecondary - whether or not external tokens are allowed to be sold via secondary market
     */
    function initialize(
      bool _allowExternalTokensOnSecondary
    )
    public
    onlyUnInitialized
    {
        // Register supported interfaces
        DiamondLib.addSupportedInterface(type(IMarketConfigAdditional).interfaceId);  // when combined with IMarketClerk ...
        DiamondLib.addSupportedInterface(type(IMarketConfigAdditional).interfaceId ^ type(IMarketClerk).interfaceId); // ... supports IMarketController

        // Initialize market config params
        MarketControllerLib.MarketControllerStorage storage mcs = MarketControllerLib.marketControllerStorage();
        mcs.allowExternalTokensOnSecondary = _allowExternalTokensOnSecondary;
    }

    /**
     * @notice Sets whether or not external tokens can be listed on secondary market
     *
     * Emits an AllowExternalTokensOnSecondaryChanged event.
     *
     * @param _status - boolean of whether or not external tokens are allowed
     */
    function setAllowExternalTokensOnSecondary(bool _status)
    external
    override
    onlyRole(ADMIN)
    {
        MarketControllerLib.MarketControllerStorage storage mcs = MarketControllerLib.marketControllerStorage();
        require(_status != mcs.allowExternalTokensOnSecondary, "Already set to requested status.");
        mcs.allowExternalTokensOnSecondary = _status;
        emit AllowExternalTokensOnSecondaryChanged(mcs.allowExternalTokensOnSecondary);
    }

    /**
     * @notice The allowExternalTokensOnSecondary getter
     */
    function getAllowExternalTokensOnSecondary()
    external
    override
    view
    returns (bool)
    {
        MarketControllerLib.MarketControllerStorage storage mcs = MarketControllerLib.marketControllerStorage();
        return mcs.allowExternalTokensOnSecondary;
    }

    /**
     * @notice The escrow agent fee getter
     *
     * Returns zero if no escrow agent fee is set
     *
     * @param _escrowAgentAddress - the address of the escrow agent
     * @return uint256 - escrow agent fee in basis points
     */
    function getEscrowAgentFeeBasisPoints(address _escrowAgentAddress)
    public
    override
    view
    returns (uint16)
    {
        MarketControllerLib.MarketControllerStorage storage mcs = MarketControllerLib.marketControllerStorage();
        return mcs.escrowAgentToFeeBasisPoints[_escrowAgentAddress];
    }

    /**
     * @notice The escrow agent fee setter
     *
     * Reverts if:
     * - _basisPoints are more than 10000
     *
     * @param _escrowAgentAddress - the address of the escrow agent
     * @param _basisPoints - the escrow agent's fee in basis points
     */
    function setEscrowAgentFeeBasisPoints(address _escrowAgentAddress, uint16 _basisPoints)
    external
    override
    onlyRole(ADMIN)
    {
        // Ensure the consignment exists, has not been released and that basis points don't exceed 10000
        // Rolled into one require due to contract size being near max
        // require(_basisPoints <= 10000, "_basisPoints over 10000");
        MarketControllerLib.MarketControllerStorage storage mcs = MarketControllerLib.marketControllerStorage();
        mcs.escrowAgentToFeeBasisPoints[_escrowAgentAddress] = _basisPoints;
        emit EscrowAgentFeeChanged(_escrowAgentAddress, _basisPoints);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./IMarketConfig.sol";
import "./IMarketConfigAdditional.sol";
import "./IMarketClerk.sol";

/**
 * @title IMarketController
 *
 * @notice Manages configuration and consignments used by the Seen.Haus contract suite.
 *
 * The ERC-165 identifier for this interface is: 0xbb8dba77
 *
 * @author Cliff Hall <[email protected]> (https://twitter.com/seaofarrows)
 */
interface IMarketController is IMarketClerk, IMarketConfig, IMarketConfigAdditional {}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "../domain/SeenTypes.sol";

/**
 * @title IMarketController
 *
 * @notice Manages configuration and consignments used by the Seen.Haus contract suite.
 * @dev Contributes its events and functions to the IMarketController interface
 *
 * The ERC-165 identifier for this interface is: 0x57f9f26d
 *
 * @author Cliff Hall <[email protected]> (https://twitter.com/seaofarrows)
 */
interface IMarketConfigAdditional {

    /// Events
    event AllowExternalTokensOnSecondaryChanged(bool indexed status);
    event EscrowAgentFeeChanged(address indexed escrowAgent, uint16 fee);
    
    /**
     * @notice Sets whether or not external tokens can be listed on secondary market
     *
     * Emits an AllowExternalTokensOnSecondaryChanged event.
     *
     * @param _status - boolean of whether or not external tokens are allowed
     */
    function setAllowExternalTokensOnSecondary(bool _status) external;

    /**
     * @notice The allowExternalTokensOnSecondary getter
     */
    function getAllowExternalTokensOnSecondary() external view returns (bool status);

        /**
     * @notice The escrow agent fee getter
     */
    function getEscrowAgentFeeBasisPoints(address _escrowAgentAddress) external view returns (uint16);

    /**
     * @notice The escrow agent fee setter
     */
    function setEscrowAgentFeeBasisPoints(address _escrowAgentAddress, uint16 _basisPoints) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "../domain/SeenTypes.sol";

/**
 * @title IMarketClerk
 *
 * @notice Manages consignments for the Seen.Haus contract suite.
 *
 * The ERC-165 identifier for this interface is: 0xec74481a
 *
 * @author Cliff Hall <[email protected]> (https://twitter.com/seaofarrows)
 */
interface IMarketClerk is IERC1155ReceiverUpgradeable, IERC721ReceiverUpgradeable {

    /// Events
    event ConsignmentTicketerChanged(uint256 indexed consignmentId, SeenTypes.Ticketer indexed ticketerType);
    event ConsignmentFeeChanged(uint256 indexed consignmentId, uint16 customConsignmentFee);
    event ConsignmentPendingPayoutSet(uint256 indexed consignmentId, uint256 amount);
    event ConsignmentRegistered(address indexed consignor, address indexed seller, SeenTypes.Consignment consignment);
    event ConsignmentMarketed(address indexed consignor, address indexed seller, uint256 indexed consignmentId);
    event ConsignmentReleased(uint256 indexed consignmentId, uint256 amount, address releasedTo);

    /**
     * @notice The nextConsignment getter
     */
    function getNextConsignment() external view returns (uint256);

    /**
     * @notice The consignment getter
     */
    function getConsignment(uint256 _consignmentId) external view returns (SeenTypes.Consignment memory);

    /**
     * @notice Get the remaining supply of the given consignment.
     *
     * @param _consignmentId - the id of the consignment
     * @return uint256 - the remaining supply held by the MarketController
     */
    function getUnreleasedSupply(uint256 _consignmentId) external view returns(uint256);

    /**
     * @notice Get the consignor of the given consignment
     *
     * @param _consignmentId - the id of the consignment
     * @return  address - consigner's address
     */
    function getConsignor(uint256 _consignmentId) external view returns(address);

    /**
     * @notice Registers a new consignment for sale or auction.
     *
     * Emits a ConsignmentRegistered event.
     *
     * @param _market - the market for the consignment. See {SeenTypes.Market}
     * @param _consignor - the address executing the consignment transaction
     * @param _seller - the seller of the consignment
     * @param _tokenAddress - the contract address issuing the NFT behind the consignment
     * @param _tokenId - the id of the token being consigned
     * @param _supply - the amount of the token being consigned
     *
     * @return Consignment - the registered consignment
     */
    function registerConsignment(
        SeenTypes.Market _market,
        address _consignor,
        address payable _seller,
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _supply
    )
    external
    returns(SeenTypes.Consignment memory);

    /**
      * @notice Update consignment to indicate it has been marketed
      *
      * Emits a ConsignmentMarketed event.
      *
      * Reverts if consignment has already been marketed.
      * A consignment is considered as marketed if it has a marketHandler other than Unhandled. See: {SeenTypes.MarketHandler}
      *
      * @param _consignmentId - the id of the consignment
      */
    function marketConsignment(uint256 _consignmentId, SeenTypes.MarketHandler _marketHandler) external;

    /**
     * @notice Release the consigned item to a given address
     *
     * Emits a ConsignmentReleased event.
     *
     * Reverts if caller is does not have MARKET_HANDLER role.
     *
     * @param _consignmentId - the id of the consignment
     * @param _amount - the amount of the consigned supply to release
     * @param _releaseTo - the address to transfer the consigned token balance to
     */
    function releaseConsignment(uint256 _consignmentId, uint256 _amount, address _releaseTo) external;

    /**
     * @notice Clears the pending payout value of a consignment
     *
     * Emits a ConsignmentPayoutSet event.
     *
     * Reverts if:
     *  - caller is does not have MARKET_HANDLER role.
     *  - consignment doesn't exist
     *
     * @param _consignmentId - the id of the consignment
     * @param _amount - the amount of that the consignment's pendingPayout must be set to
     */
    function setConsignmentPendingPayout(uint256 _consignmentId, uint256 _amount) external;

    /**
     * @notice Set the type of Escrow Ticketer to be used for a consignment
     *
     * Default escrow ticketer is Ticketer.Lots. This only needs to be called
     * if overriding to Ticketer.Items for a given consignment.
     *
     * Emits a ConsignmentTicketerSet event.
     * Reverts if consignment is not registered.
     *
     * @param _consignmentId - the id of the consignment
     * @param _ticketerType - the type of ticketer to use. See: {SeenTypes.Ticketer}
     */
    function setConsignmentTicketer(uint256 _consignmentId, SeenTypes.Ticketer _ticketerType) external;

    /**
     * @notice Set a custom fee percentage on a consignment (e.g. for "official" SEEN x Artist drops)
     *
     * Default escrow ticketer is Ticketer.Lots. This only needs to be called
     * if overriding to Ticketer.Items for a given consignment.
     *
     * Emits a ConsignmentFeeChanged event.
     *
     * Reverts if consignment doesn't exist     *
     *
     * @param _consignmentId - the id of the consignment
     * @param _customFeePercentageBasisPoints - the custom fee percentage basis points to use
     *
     * N.B. _customFeePercentageBasisPoints percentage value as an unsigned int by multiplying the percentage by 100:
     * e.g, 1.75% = 175, 100% = 10000
     */
    function setConsignmentCustomFee(uint256 _consignmentId, uint16 _customFeePercentageBasisPoints) external;

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IAccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";
import { IDiamondCut } from "../../interfaces/IDiamondCut.sol";

/**
 * @title DiamondLib
 *
 * @notice Diamond storage slot and supported interfaces
 *
 * @notice Based on Nick Mudge's gas-optimized diamond-2 reference,
 * with modifications to support role-based access and management of
 * supported interfaces.
 *
 * Reference Implementation  : https://github.com/mudgen/diamond-2-hardhat
 * EIP-2535 Diamond Standard : https://eips.ethereum.org/EIPS/eip-2535
 *
 * N.B. Facet management functions from original `DiamondLib` were refactor/extracted
 * to JewelerLib, since business facets also use this library for access control and
 * managing supported interfaces.
 *
 * @author Nick Mudge <[email protected]> (https://twitter.com/mudgen)
 * @author Cliff Hall <[email protected]> (https://twitter.com/seaofarrows)
 */
library DiamondLib {

    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct DiamondStorage {

        // maps function selectors to the facets that execute the functions.
        // and maps the selectors to their position in the selectorSlots array.
        // func selector => address facet, selector position
        mapping(bytes4 => bytes32) facets;

        // array of slots of function selectors.
        // each slot holds 8 function selectors.
        mapping(uint256 => bytes32) selectorSlots;

        // The number of function selectors in selectorSlots
        uint16 selectorCount;

        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;

        // The Seen.Haus AccessController
        IAccessControlUpgradeable accessController;

    }

    /**
     * @notice Get the Diamond storage slot
     *
     * @return ds - Diamond storage slot cast to DiamondStorage
     */
    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    /**
     * @notice Add a supported interface to the Diamond
     *
     * @param _interfaceId - the interface to add
     */
    function addSupportedInterface(bytes4 _interfaceId) internal {

        // Get the DiamondStorage struct
        DiamondStorage storage ds = diamondStorage();

        // Flag the interfaces as supported
        ds.supportedInterfaces[_interfaceId] = true;
    }

    /**
     * @notice Implementation of ERC-165 interface detection standard.
     *
     * @param _interfaceId - the sighash of the given interface
     */
    function supportsInterface(bytes4 _interfaceId) internal view returns (bool) {

        // Get the DiamondStorage struct
        DiamondStorage storage ds = diamondStorage();

        // Return the value
        return ds.supportedInterfaces[_interfaceId] || false;
    }

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./MarketControllerLib.sol";
import "../diamond/DiamondLib.sol";
import "../../domain/SeenTypes.sol";
import "../../domain/SeenConstants.sol";

/**
 * @title MarketControllerBase
 *
 * @notice Provides domain and common modifiers to MarketController facets
 *
 * @author Cliff Hall <[email protected]> (https://twitter.com/seaofarrows)
 */
abstract contract MarketControllerBase is SeenTypes, SeenConstants {

    /**
     * @dev Modifier that checks that the consignment exists
     *
     * Reverts if the consignment does not exist
     */
    modifier consignmentExists(uint256 _consignmentId) {

        MarketControllerLib.MarketControllerStorage storage mcs = MarketControllerLib.marketControllerStorage();

        // Make sure the consignment exists
        require(_consignmentId < mcs.nextConsignment, "Consignment does not exist");
        _;
    }

    /**
     * @dev Modifier that checks that the caller has a specific role.
     *
     * Reverts if caller doesn't have role.
     *
     * See: {AccessController.hasRole}
     */
    modifier onlyRole(bytes32 _role) {
        DiamondLib.DiamondStorage storage ds = DiamondLib.diamondStorage();
        require(ds.accessController.hasRole(_role, msg.sender), "Access denied, caller doesn't have role");
        _;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../domain/SeenTypes.sol";

/**
 * @title MarketControllerLib
 *
 * @dev Provides access to the the MarketController Storage and Intializer slots for MarketController facets
 *
 * @author Cliff Hall <[email protected]> (https://twitter.com/seaofarrows)
 */
library MarketControllerLib {

    bytes32 constant MARKET_CONTROLLER_STORAGE_POSITION = keccak256("seen.haus.market.controller.storage");
    bytes32 constant MARKET_CONTROLLER_INITIALIZERS_POSITION = keccak256("seen.haus.market.controller.initializers");

    struct MarketControllerStorage {

        // the address of the Seen.Haus NFT contract
        address nft;

        // the address of the xSEEN ERC-20 Seen.Haus staking contract
        address payable staking;

        // the address of the Seen.Haus multi-sig wallet
        address payable multisig;

        // address of the Seen.Haus lots-based escrow ticketing contract
        address lotsTicketer;

        // address of the Seen.Haus items-based escrow ticketing contract
        address itemsTicketer;

        // the default escrow ticketer type to use for physical consignments unless overridden with setConsignmentTicketer
        SeenTypes.Ticketer defaultTicketerType;

        // the minimum amount of xSEEN ERC-20 a caller must hold to participate in VIP events
        uint256 vipStakerAmount;

        // the percentage that will be taken as a fee from the net of a Seen.Haus sale or auction
        uint16 primaryFeePercentage;         // 1.75% = 175, 100% = 10000

        // the percentage that will be taken as a fee from the net of a Seen.Haus sale or auction (after royalties)
        uint16 secondaryFeePercentage;         // 1.75% = 175, 100% = 10000

        // the maximum percentage of a Seen.Haus sale or auction that will be paid as a royalty
        uint16 maxRoyaltyPercentage;  // 1.75% = 175, 100% = 10000

        // the minimum percentage a Seen.Haus auction bid must be above the previous bid to prevail
        uint16 outBidPercentage;      // 1.75% = 175, 100% = 10000

        // next consignment id
        uint256 nextConsignment;

        // whether or not external NFTs can be sold via secondary market
        bool allowExternalTokensOnSecondary;

        // consignment id => consignment
        mapping(uint256 => SeenTypes.Consignment) consignments;

        // consignmentId to consignor address
        mapping(uint256 => address) consignors;

        // consignment id => ticketer type
        mapping(uint256 => SeenTypes.Ticketer) consignmentTicketers;

        // escrow agent address => feeBasisPoints
        mapping(address => uint16) escrowAgentToFeeBasisPoints;

    }

    struct MarketControllerInitializers {

        // MarketConfigFacet initialization state
        bool configFacet;

        // MarketConfigFacet initialization state
        bool configAdditionalFacet;

        // MarketClerkFacet initialization state
        bool clerkFacet;

    }

    function marketControllerStorage() internal pure returns (MarketControllerStorage storage mcs) {
        bytes32 position = MARKET_CONTROLLER_STORAGE_POSITION;
        assembly {
            mcs.slot := position
        }
    }

    function marketControllerInitializers() internal pure returns (MarketControllerInitializers storage mci) {
        bytes32 position = MARKET_CONTROLLER_INITIALIZERS_POSITION;
        assembly {
            mci.slot := position
        }
    }

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "../domain/SeenTypes.sol";

/**
 * @title IMarketController
 *
 * @notice Manages configuration and consignments used by the Seen.Haus contract suite.
 * @dev Contributes its events and functions to the IMarketController interface
 *
 * The ERC-165 identifier for this interface is: 0x57f9f26d
 *
 * @author Cliff Hall <[email protected]> (https://twitter.com/seaofarrows)
 */
interface IMarketConfig {

    /// Events
    event NFTAddressChanged(address indexed nft);
    event EscrowTicketerAddressChanged(address indexed escrowTicketer, SeenTypes.Ticketer indexed ticketerType);
    event StakingAddressChanged(address indexed staking);
    event MultisigAddressChanged(address indexed multisig);
    event VipStakerAmountChanged(uint256 indexed vipStakerAmount);
    event PrimaryFeePercentageChanged(uint16 indexed feePercentage);
    event SecondaryFeePercentageChanged(uint16 indexed feePercentage);
    event MaxRoyaltyPercentageChanged(uint16 indexed maxRoyaltyPercentage);
    event OutBidPercentageChanged(uint16 indexed outBidPercentage);
    event DefaultTicketerTypeChanged(SeenTypes.Ticketer indexed ticketerType);

    /**
     * @notice Sets the address of the xSEEN ERC-20 staking contract.
     *
     * Emits a NFTAddressChanged event.
     *
     * @param _nft - the address of the nft contract
     */
    function setNft(address _nft) external;

    /**
     * @notice The nft getter
     */
    function getNft() external view returns (address);

    /**
     * @notice Sets the address of the Seen.Haus lots-based escrow ticketer contract.
     *
     * Emits a EscrowTicketerAddressChanged event.
     *
     * @param _lotsTicketer - the address of the items-based escrow ticketer contract
     */
    function setLotsTicketer(address _lotsTicketer) external;

    /**
     * @notice The lots-based escrow ticketer getter
     */
    function getLotsTicketer() external view returns (address);

    /**
     * @notice Sets the address of the Seen.Haus items-based escrow ticketer contract.
     *
     * Emits a EscrowTicketerAddressChanged event.
     *
     * @param _itemsTicketer - the address of the items-based escrow ticketer contract
     */
    function setItemsTicketer(address _itemsTicketer) external;

    /**
     * @notice The items-based escrow ticketer getter
     */
    function getItemsTicketer() external view returns (address);

    /**
     * @notice Sets the address of the xSEEN ERC-20 staking contract.
     *
     * Emits a StakingAddressChanged event.
     *
     * @param _staking - the address of the staking contract
     */
    function setStaking(address payable _staking) external;

    /**
     * @notice The staking getter
     */
    function getStaking() external view returns (address payable);

    /**
     * @notice Sets the address of the Seen.Haus multi-sig wallet.
     *
     * Emits a MultisigAddressChanged event.
     *
     * @param _multisig - the address of the multi-sig wallet
     */
    function setMultisig(address payable _multisig) external;

    /**
     * @notice The multisig getter
     */
    function getMultisig() external view returns (address payable);

    /**
     * @notice Sets the VIP staker amount.
     *
     * Emits a VipStakerAmountChanged event.
     *
     * @param _vipStakerAmount - the minimum amount of xSEEN ERC-20 a caller must hold to participate in VIP events
     */
    function setVipStakerAmount(uint256 _vipStakerAmount) external;

    /**
     * @notice The vipStakerAmount getter
     */
    function getVipStakerAmount() external view returns (uint256);

    /**
     * @notice Sets the marketplace fee percentage.
     * Emits a PrimaryFeePercentageChanged event.
     *
     * @param _primaryFeePercentage - the percentage that will be taken as a fee from the net of a Seen.Haus primary sale or auction
     *
     * N.B. Represent percentage value as an unsigned int by multiplying the percentage by 100:
     * e.g, 1.75% = 175, 100% = 10000
     */
    function setPrimaryFeePercentage(uint16 _primaryFeePercentage) external;

    /**
     * @notice Sets the marketplace fee percentage.
     * Emits a SecondaryFeePercentageChanged event.
     *
     * @param _secondaryFeePercentage - the percentage that will be taken as a fee from the net of a Seen.Haus secondary sale or auction (after royalties)
     *
     * N.B. Represent percentage value as an unsigned int by multiplying the percentage by 100:
     * e.g, 1.75% = 175, 100% = 10000
     */
    function setSecondaryFeePercentage(uint16 _secondaryFeePercentage) external;

    /**
     * @notice The primaryFeePercentage and secondaryFeePercentage getter
     */
    function getFeePercentage(SeenTypes.Market _market) external view returns (uint16);

    /**
     * @notice Sets the external marketplace maximum royalty percentage.
     *
     * Emits a MaxRoyaltyPercentageChanged event.
     *
     * @param _maxRoyaltyPercentage - the maximum percentage of a Seen.Haus sale or auction that will be paid as a royalty
     */
    function setMaxRoyaltyPercentage(uint16 _maxRoyaltyPercentage) external;

    /**
     * @notice The maxRoyaltyPercentage getter
     */
    function getMaxRoyaltyPercentage() external view returns (uint16);

    /**
     * @notice Sets the marketplace auction outbid percentage.
     *
     * Emits a OutBidPercentageChanged event.
     *
     * @param _outBidPercentage - the minimum percentage a Seen.Haus auction bid must be above the previous bid to prevail
     */
    function setOutBidPercentage(uint16 _outBidPercentage) external;

    /**
     * @notice The outBidPercentage getter
     */
    function getOutBidPercentage() external view returns (uint16);

    /**
     * @notice Sets the default escrow ticketer type.
     *
     * Emits a DefaultTicketerTypeChanged event.
     *
     * Reverts if _ticketerType is Ticketer.Default
     * Reverts if _ticketerType is already the defaultTicketerType
     *
     * @param _ticketerType - the new default escrow ticketer type.
     */
    function setDefaultTicketerType(SeenTypes.Ticketer _ticketerType) external;

    /**
     * @notice The defaultTicketerType getter
     */
    function getDefaultTicketerType() external view returns (SeenTypes.Ticketer);

    /**
     * @notice Get the Escrow Ticketer to be used for a given consignment
     *
     * If a specific ticketer has not been set for the consignment,
     * the default escrow ticketer will be returned.
     *
     * @param _consignmentId - the id of the consignment
     * @return ticketer = the address of the escrow ticketer to use
     */
    function getEscrowTicketer(uint256 _consignmentId) external view returns (address ticketer);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

/**
 * @title SeenTypes
 *
 * @notice Enums and structs used by the Seen.Haus contract ecosystem.
 *
 * @author Cliff Hall <[email protected]> (https://twitter.com/seaofarrows)
 */
contract SeenTypes {

    enum Market {
        Primary,
        Secondary
    }

    enum MarketHandler {
        Unhandled,
        Auction,
        Sale
    }

    enum Clock {
        Live,
        Trigger
    }

    enum Audience {
        Open,
        Staker,
        VipStaker
    }

    enum Outcome {
        Pending,
        Closed,
        Canceled
    }

    enum State {
        Pending,
        Running,
        Ended
    }

    enum Ticketer {
        Default,
        Lots,
        Items
    }

    struct Token {
        address payable creator;
        uint16 royaltyPercentage;
        bool isPhysical;
        uint256 id;
        uint256 supply;
        string uri;
    }

    struct Consignment {
        Market market;
        MarketHandler marketHandler;
        address payable seller;
        address tokenAddress;
        uint256 tokenId;
        uint256 supply;
        uint256 id;
        bool multiToken;
        bool released;
        uint256 releasedSupply;
        uint16 customFeePercentageBasisPoints;
        uint256 pendingPayout;
    }

    struct Auction {
        address payable buyer;
        uint256 consignmentId;
        uint256 start;
        uint256 duration;
        uint256 reserve;
        uint256 bid;
        Clock clock;
        State state;
        Outcome outcome;
    }

    struct Sale {
        uint256 consignmentId;
        uint256 start;
        uint256 price;
        uint256 perTxCap;
        State state;
        Outcome outcome;
    }

    struct EscrowTicket {
        uint256 amount;
        uint256 consignmentId;
        uint256 id;
        string itemURI;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IDiamondCut
 *
 * @notice Diamond Facet management
 *
 * Reference Implementation  : https://github.com/mudgen/diamond-2-hardhat
 * EIP-2535 Diamond Standard : https://eips.ethereum.org/EIPS/eip-2535
 *
 * The ERC-165 identifier for this interface is: 0x1f931c1c
 *
 * @author Nick Mudge <[email protected]> (https://twitter.com/mudgen)
 */
interface IDiamondCut {

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);

    enum FacetCutAction {Add, Replace, Remove}

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /**
     * @notice Add/replace/remove any number of functions and
     * optionally execute a function with delegatecall
     *
     * _calldata is executed with delegatecall on _init
     *
     * @param _diamondCut Contains the facet addresses and function selectors
     * @param _init The address of the contract or facet to execute _calldata
     * @param _calldata A function call, including function selector and arguments
     */
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

/**
 * @title SeenConstants
 *
 * @notice Constants used by the Seen.Haus contract ecosystem.
 *
 * @author Cliff Hall <[email protected]> (https://twitter.com/seaofarrows)
 */
contract SeenConstants {

    // Endpoint will serve dynamic metadata composed of ticket and ticketed item's info
    string internal constant ESCROW_TICKET_URI = "https://seen.haus/ticket/metadata/";

    // Access Control Roles
    bytes32 internal constant ADMIN = keccak256("ADMIN");                   // Deployer and any other admins as needed
    bytes32 internal constant SELLER = keccak256("SELLER");                 // Approved sellers amd Seen.Haus reps
    bytes32 internal constant MINTER = keccak256("MINTER");                 // Approved artists and Seen.Haus reps
    bytes32 internal constant ESCROW_AGENT = keccak256("ESCROW_AGENT");     // Seen.Haus Physical Item Escrow Agent
    bytes32 internal constant MARKET_HANDLER = keccak256("MARKET_HANDLER"); // Market Handler contracts
    bytes32 internal constant UPGRADER = keccak256("UPGRADER");             // Performs contract upgrades

}