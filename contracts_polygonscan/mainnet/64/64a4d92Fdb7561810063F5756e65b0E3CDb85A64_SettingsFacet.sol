/**
 *Submitted for verification at polygonscan.com on 2021-08-31
*/

/** 
 *  SourceUnit: /home/null/Desktop/aavegotchi-gbm/contracts/facets/SettingsFacet.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT


/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
pragma solidity ^0.8.0;
interface IDiamondCut {
    enum FacetCutAction {Add, Replace, Remove}
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}




/** 
 *  SourceUnit: /home/null/Desktop/aavegotchi-gbm/contracts/facets/SettingsFacet.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT


/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
////import { IDiamondCut } from "../interfaces/IDiamondCut.sol";

library LibDiamond {
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
        // owner of the contract
        address contractOwner;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        require(msg.sender == diamondStorage().contractOwner, "LibDiamond: Must be contract owner");
    }

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    bytes32 constant CLEAR_ADDRESS_MASK = bytes32(uint256(0xffffffffffffffffffffffff));
    bytes32 constant CLEAR_SELECTOR_MASK = bytes32(uint256(0xffffffff << 224));

    // Internal function version of diamondCut
    // This code is almost the same as the external diamondCut,
    // except it is using 'Facet[] memory _diamondCut' instead of
    // 'Facet[] calldata _diamondCut'.
    // The code is duplicated to prevent copying calldata to memory which
    // causes an error for a two dimensional array.
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        DiamondStorage storage ds = diamondStorage();
        uint256 originalSelectorCount = ds.selectorCount;
        uint256 selectorCount = originalSelectorCount;
        bytes32 selectorSlot;
        // Check if last selector slot is not full
        if (selectorCount & 7 > 0) {
            // get last selectorSlot
            selectorSlot = ds.selectorSlots[selectorCount >> 3];
        }
        // loop through diamond cut
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            (selectorCount, selectorSlot) = addReplaceRemoveFacetSelectors(
                selectorCount,
                selectorSlot,
                _diamondCut[facetIndex].facetAddress,
                _diamondCut[facetIndex].action,
                _diamondCut[facetIndex].functionSelectors
            );
        }
        if (selectorCount != originalSelectorCount) {
            ds.selectorCount = uint16(selectorCount);
        }
        // If last selector slot is not full
        if (selectorCount & 7 > 0) {
            ds.selectorSlots[selectorCount >> 3] = selectorSlot;
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addReplaceRemoveFacetSelectors(
        uint256 _selectorCount,
        bytes32 _selectorSlot,
        address _newFacetAddress,
        IDiamondCut.FacetCutAction _action,
        bytes4[] memory _selectors
    ) internal returns (uint256, bytes32) {
        DiamondStorage storage ds = diamondStorage();
        require(_selectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        if (_action == IDiamondCut.FacetCutAction.Add) {
            enforceHasContractCode(_newFacetAddress, "LibDiamondCut: Add facet has no code");
            for (uint256 selectorIndex; selectorIndex < _selectors.length; selectorIndex++) {
                bytes4 selector = _selectors[selectorIndex];
                bytes32 oldFacet = ds.facets[selector];
                require(address(bytes20(oldFacet)) == address(0), "LibDiamondCut: Can't add function that already exists");
                // add facet for selector
                ds.facets[selector] = bytes20(_newFacetAddress) | bytes32(_selectorCount);
                uint256 selectorInSlotPosition = (_selectorCount & 7) << 5;
                // clear selector position in slot and add selector
                _selectorSlot = (_selectorSlot & ~(CLEAR_SELECTOR_MASK >> selectorInSlotPosition)) | (bytes32(selector) >> selectorInSlotPosition);
                // if slot is full then write it to storage
                if (selectorInSlotPosition == 224) {
                    ds.selectorSlots[_selectorCount >> 3] = _selectorSlot;
                    _selectorSlot = 0;
                }
                _selectorCount++;
            }
        } else if (_action == IDiamondCut.FacetCutAction.Replace) {
            enforceHasContractCode(_newFacetAddress, "LibDiamondCut: Replace facet has no code");
            for (uint256 selectorIndex; selectorIndex < _selectors.length; selectorIndex++) {
                bytes4 selector = _selectors[selectorIndex];
                bytes32 oldFacet = ds.facets[selector];
                address oldFacetAddress = address(bytes20(oldFacet));
                // only useful if immutable functions exist
                require(oldFacetAddress != address(this), "LibDiamondCut: Can't replace immutable function");
                require(oldFacetAddress != _newFacetAddress, "LibDiamondCut: Can't replace function with same function");
                require(oldFacetAddress != address(0), "LibDiamondCut: Can't replace function that doesn't exist");
                // replace old facet address
                ds.facets[selector] = (oldFacet & CLEAR_ADDRESS_MASK) | bytes20(_newFacetAddress);
            }
        } else if (_action == IDiamondCut.FacetCutAction.Remove) {
            require(_newFacetAddress == address(0), "LibDiamondCut: Remove facet address must be address(0)");
            uint256 selectorSlotCount = _selectorCount >> 3;
            uint256 selectorInSlotIndex = _selectorCount & 7;
            for (uint256 selectorIndex; selectorIndex < _selectors.length; selectorIndex++) {
                if (_selectorSlot == 0) {
                    // get last selectorSlot
                    selectorSlotCount--;
                    _selectorSlot = ds.selectorSlots[selectorSlotCount];
                    selectorInSlotIndex = 7;
                } else {
                    selectorInSlotIndex--;
                }
                bytes4 lastSelector;
                uint256 oldSelectorsSlotCount;
                uint256 oldSelectorInSlotPosition;
                // adding a block here prevents stack too deep error
                {
                    bytes4 selector = _selectors[selectorIndex];
                    bytes32 oldFacet = ds.facets[selector];
                    require(address(bytes20(oldFacet)) != address(0), "LibDiamondCut: Can't remove function that doesn't exist");
                    // only useful if immutable functions exist
                    require(address(bytes20(oldFacet)) != address(this), "LibDiamondCut: Can't remove immutable function");
                    // replace selector with last selector in ds.facets
                    // gets the last selector
                    lastSelector = bytes4(_selectorSlot << (selectorInSlotIndex << 5));
                    if (lastSelector != selector) {
                        // update last selector slot position info
                        ds.facets[lastSelector] = (oldFacet & CLEAR_ADDRESS_MASK) | bytes20(ds.facets[lastSelector]);
                    }
                    delete ds.facets[selector];
                    uint256 oldSelectorCount = uint16(uint256(oldFacet));
                    oldSelectorsSlotCount = oldSelectorCount >> 3;
                    oldSelectorInSlotPosition = (oldSelectorCount & 7) << 5;
                }
                if (oldSelectorsSlotCount != selectorSlotCount) {
                    bytes32 oldSelectorSlot = ds.selectorSlots[oldSelectorsSlotCount];
                    // clears the selector we are deleting and puts the last selector in its place.
                    oldSelectorSlot =
                        (oldSelectorSlot & ~(CLEAR_SELECTOR_MASK >> oldSelectorInSlotPosition)) |
                        (bytes32(lastSelector) >> oldSelectorInSlotPosition);
                    // update storage with the modified slot
                    ds.selectorSlots[oldSelectorsSlotCount] = oldSelectorSlot;
                } else {
                    // clears the selector we are deleting and puts the last selector in its place.
                    _selectorSlot =
                        (_selectorSlot & ~(CLEAR_SELECTOR_MASK >> oldSelectorInSlotPosition)) |
                        (bytes32(lastSelector) >> oldSelectorInSlotPosition);
                }
                if (selectorInSlotIndex == 0) {
                    delete ds.selectorSlots[selectorSlotCount];
                    _selectorSlot = 0;
                }
            }
            _selectorCount = selectorSlotCount * 8 + selectorInSlotIndex;
        } else {
            revert("LibDiamondCut: Incorrect FacetCutAction");
        }
        return (_selectorCount, _selectorSlot);
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            require(_calldata.length == 0, "LibDiamondCut: _init is address(0) but_calldata is not empty");
        } else {
            require(_calldata.length > 0, "LibDiamondCut: _calldata is empty but _init is not address(0)");
            if (_init != address(this)) {
                enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert("LibDiamondCut: _init function reverted");
                }
            }
        }
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}




/** 
 *  SourceUnit: /home/null/Desktop/aavegotchi-gbm/contracts/facets/SettingsFacet.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

////import {LibDiamond} from "./LibDiamond.sol";

//Struct used to store the representation of an NFT being auctionned
struct TokenRepresentation {
    address contractAddress; // The contract address
    uint256 tokenId; // The ID of the token on the contract
    bytes4 tokenKind; // The ERC name of the token implementation bytes4(keccak256("ERC721")) or bytes4(keccak256("ERC1155"))
}

struct ContractAddresses {
    address pixelcraft;
    address playerRewards;
    address daoTreasury;
    address erc20Currency;
}

struct InitiatorInfo {
    uint256 startTime;
    uint256 endTime;
    uint256 hammerTimeDuration;
    uint256 bidDecimals;
    uint256 stepMin;
    uint256 incMin;
    uint256 incMax;
    uint256 bidMultiplier;
}

struct Auction {
    address owner;
    address highestBidder;
    uint256 highestBid;
    uint256 auctionDebt;
    uint256 dueIncentives;
    address contractAddress;
    uint256 startTime;
    uint256 endTime;
    uint256 hammerTimeDuration;
    uint256 bidDecimals;
    uint256 stepMin;
    uint256 incMin;
    uint256 incMax;
    uint256 bidMultiplier;
    bool biddingAllowed;
}

struct Collection {
    uint256 startTime;
    uint256 endTime;
    uint256 hammerTimeDuration;
    uint256 bidDecimals;
    uint256 stepMin;
    uint256 incMin; // minimal earned incentives
    uint256 incMax; // maximal earned incentives
    uint256 bidMultiplier; // bid incentive growth multiplier
    bool biddingAllowed; // Allow to start/pause ongoing auctions
}

struct AppStorage {
    address pixelcraft;
    address playerRewards;
    address daoTreasury;
    InitiatorInfo initiatorInfo;
    //Contract address storing the ERC20 currency used in auctions
    address erc20Currency;
    mapping(uint256 => TokenRepresentation) tokenMapping; //_auctionId => token_primaryKey
    mapping(address => mapping(uint256 => mapping(uint256 => uint256))) auctionMapping; // contractAddress => tokenId => TokenIndex => _auctionId
    //var storing individual auction settings. if != null, they take priority over collection settings
    mapping(uint256 => Auction) auctions; //_auctionId => auctions
    mapping(uint256 => bool) auctionItemClaimed;
    //var storing contract wide settings. Those are used if no auctionId specific parameters is initialized
    mapping(address => Collection) collections; //tokencontract => collections
    mapping(address => mapping(uint256 => uint256)) erc1155TokensIndex; //Contract => TokenID => Amount being auctionned
    mapping(address => mapping(uint256 => uint256)) erc1155TokensUnderAuction; //Contract => TokenID => Amount being auctionned
    bytes backendPubKey;
}

contract Modifiers {
    AppStorage internal s;

    modifier onlyOwner() {
        LibDiamond.enforceIsContractOwner();
        _;
    }
}




/** 
 *  SourceUnit: /home/null/Desktop/aavegotchi-gbm/contracts/facets/SettingsFacet.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: UNLICENSED
// © Copyright 2021. Patent pending. All rights reserved. Perpetual Altruism Ltd.


/// @title IGBMInitiator: GBM Auction initiator interface.
/// @dev Will be called when initializing GBM auctions on the main GBM contract.
/// @author Guillaume Gonnaud
interface IGBMInitiator {
    // Auction id either = the contract token address cast as uint256 or
    // auctionId = uint256(keccak256(abi.encodePacked(_contract, _tokenId, _tokenKind)));  <= ERC721
    // auctionId = uint256(keccak256(abi.encodePacked(_contract, _tokenId, _tokenKind, _1155Index))); <= ERC1155

    function getStartTime(uint256 _auctionId) external view returns (uint256);

    function getEndTime(uint256 _auctionId) external view returns (uint256);

    function getHammerTimeDuration(uint256 _auctionId) external view returns (uint256);

    function getBidDecimals(uint256 _auctionId) external view returns (uint256);

    function getStepMin(uint256 _auctionId) external view returns (uint256);

    function getIncMin(uint256 _auctionId) external view returns (uint256);

    function getIncMax(uint256 _auctionId) external view returns (uint256);

    function getBidMultiplier(uint256 _auctionId) external view returns (uint256);
}


/** 
 *  SourceUnit: /home/null/Desktop/aavegotchi-gbm/contracts/facets/SettingsFacet.sol
*/

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: UNLICENSED
// © Copyright 2021. Patent pending. All rights reserved. Perpetual Altruism Ltd.


////import "../interfaces/IGBMInitiator.sol";
////import "../libraries/AppStorage.sol";
////import "../libraries/LibDiamond.sol";

/// @title GBM auction contract Initiator
/// @dev Implementation of IGBM. Feel free to cook up your own implementation for more complex patterns.
/// @author Guillaume Gonnaud
contract SettingsFacet is IGBMInitiator, Modifiers {
    // To future developers: All the getters are called AFTER the auction ID has been generated and hence you can lookup
    // token_ID/Token contract/token kind using the main GBM contract getters(auctionId) if you want to return determinstic values

    function getInitiatorInfo() external view returns (InitiatorInfo memory) {
        return s.initiatorInfo;
    }

    function getStartTime(
        uint256 /* _auctionId */
    ) external view override returns (uint256) {
        return s.initiatorInfo.startTime;
    }

    function getEndTime(
        uint256 /* _auctionId */
    ) external view override returns (uint256) {
        return s.initiatorInfo.endTime;
    }

    function getHammerTimeDuration(
        uint256 /* _auctionId */
    ) external view override returns (uint256) {
        return s.initiatorInfo.hammerTimeDuration;
    }

    function getBidDecimals(
        uint256 /* _auctionId */
    ) external view override returns (uint256) {
        return s.initiatorInfo.bidDecimals;
    }

    function getStepMin(
        uint256 /* _auctionId */
    ) external view override returns (uint256) {
        return s.initiatorInfo.stepMin;
    }

    function getIncMin(
        uint256 /* _auctionId */
    ) external view override returns (uint256) {
        return s.initiatorInfo.incMin;
    }

    function getIncMax(
        uint256 /* _auctionId */
    ) external view override returns (uint256) {
        return s.initiatorInfo.incMax;
    }

    function getBidMultiplier(
        uint256 /* _auctionId */
    ) external view override returns (uint256) {
        return s.initiatorInfo.bidMultiplier;
    }

    /* Setter Functions */

    function setInitiatorInfo(InitiatorInfo memory _info) external onlyOwner {
        s.initiatorInfo = _info;
    }

    function setBackendPubKey(bytes memory _backendPubKey) external onlyOwner {
        s.backendPubKey = _backendPubKey;
    }
}