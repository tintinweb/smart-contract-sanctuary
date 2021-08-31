/**
 *Submitted for verification at polygonscan.com on 2021-08-31
*/

/** 
 *  SourceUnit: /home/null/Desktop/aavegotchi-gbm/contracts/facets/GBMFacet.sol
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
 *  SourceUnit: /home/null/Desktop/aavegotchi-gbm/contracts/facets/GBMFacet.sol
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
 *  SourceUnit: /home/null/Desktop/aavegotchi-gbm/contracts/facets/GBMFacet.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT


library LibSignature {

    function isValid(bytes32 messageHash, bytes memory signature, bytes memory pubKey) internal pure returns (bool) {
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, signature) == address(uint160(uint256(keccak256(pubKey))));
    }

    function getEthSignedMessageHash(bytes32 messageHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
    }

    function recoverSigner(bytes32 ethSignedMessageHash, bytes memory signature) internal pure returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(signature);

        return ecrecover(ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig) internal pure returns (bytes32 r, bytes32 s, uint8 v)
    {
        require(sig.length == 65, "Invalid signature length");

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
        // implicitly return (r, s, v)
    }
}




/** 
 *  SourceUnit: /home/null/Desktop/aavegotchi-gbm/contracts/facets/GBMFacet.sol
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
 *  SourceUnit: /home/null/Desktop/aavegotchi-gbm/contracts/facets/GBMFacet.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: CC0-1.0


interface Ownable {
    function owner() external returns(address); 
}



/** 
 *  SourceUnit: /home/null/Desktop/aavegotchi-gbm/contracts/facets/GBMFacet.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: CC0-1.0


/**
    Note: The ERC-165 identifier for this interface is 0x4e2312e0.
*/
interface IERC1155TokenReceiver {
    /**
        @notice Handle the receipt of a single ERC1155 token type.
        @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeTransferFrom` after the balance has been updated.        
        This function MUST return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` (i.e. 0xf23a6e61) if it accepts the transfer.
        This function MUST revert if it rejects the transfer.
        Return of any other value than the prescribed keccak256 generated value MUST result in the transaction being reverted by the caller.
        @param _operator  The address which initiated the transfer (i.e. msg.sender)
        @param _from      The address which previously owned the token
        @param _id        The ID of the token being transferred
        @param _value     The amount of tokens being transferred
        @param _data      Additional data with no specified format
        @return           `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
    */
    function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _value, bytes calldata _data) external returns(bytes4);

    /**
        @notice Handle the receipt of multiple ERC1155 token types.
        @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeBatchTransferFrom` after the balances have been updated.        
        This function MUST return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` (i.e. 0xbc197c81) if it accepts the transfer(s).
        This function MUST revert if it rejects the transfer(s).
        Return of any other value than the prescribed keccak256 generated value MUST result in the transaction being reverted by the caller.
        @param _operator  The address which initiated the batch transfer (i.e. msg.sender)
        @param _from      The address which previously owned the token
        @param _ids       An array containing ids of each token being transferred (order and length must match _values array)
        @param _values    An array containing amounts of each token being transferred (order and length must match _ids array)
        @param _data      Additional data with no specified format
        @return           `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
    */
    function onERC1155BatchReceived(address _operator, address _from, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external returns(bytes4);       
}



/** 
 *  SourceUnit: /home/null/Desktop/aavegotchi-gbm/contracts/facets/GBMFacet.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: CC0-1.0


/// @title ERC-1155 Multi Token Standard
/// @dev ee https://eips.ethereum.org/EIPS/eip-1155
///  The ERC-165 identifier for this interface is 0xd9b67a26.
interface IERC1155 /* is ERC165 */ {
    /**
        @dev Either `TransferSingle` or `TransferBatch` MUST emit when tokens are transferred, including zero value transfers as well as minting or burning (see "Safe Transfer Rules" section of the standard).
        The `_operator` argument MUST be the address of an account/contract that is approved to make the transfer (SHOULD be msg.sender).
        The `_from` argument MUST be the address of the holder whose balance is decreased.
        The `_to` argument MUST be the address of the recipient whose balance is increased.
        The `_id` argument MUST be the token type being transferred.
        The `_value` argument MUST be the number of tokens the holder balance is decreased by and match what the recipient balance is increased by.
        When minting/creating tokens, the `_from` argument MUST be set to `0x0` (i.e. zero address).
        When burning/destroying tokens, the `_to` argument MUST be set to `0x0` (i.e. zero address).        
    */
    event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value);

    /**
        @dev Either `TransferSingle` or `TransferBatch` MUST emit when tokens are transferred, including zero value transfers as well as minting or burning (see "Safe Transfer Rules" section of the standard).      
        The `_operator` argument MUST be the address of an account/contract that is approved to make the transfer (SHOULD be msg.sender).
        The `_from` argument MUST be the address of the holder whose balance is decreased.
        The `_to` argument MUST be the address of the recipient whose balance is increased.
        The `_ids` argument MUST be the list of tokens being transferred.
        The `_values` argument MUST be the list of number of tokens (matching the list and order of tokens specified in _ids) the holder balance is decreased by and match what the recipient balance is increased by.
        When minting/creating tokens, the `_from` argument MUST be set to `0x0` (i.e. zero address).
        When burning/destroying tokens, the `_to` argument MUST be set to `0x0` (i.e. zero address).                
    */
    event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values);

    /**
        @dev MUST emit when approval for a second party/operator address to manage all tokens for an owner address is enabled or disabled (absence of an event assumes disabled).        
    */
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /**
        @dev MUST emit when the URI is updated for a token ID.
        URIs are defined in RFC 3986.
        The URI MUST point to a JSON file that conforms to the "ERC-1155 Metadata URI JSON Schema".
    */
    event URI(string _value, uint256 indexed _id);

    /**
        @notice Transfers `_value` amount of an `_id` from the `_from` address to the `_to` address specified (with safety call).
        @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
        MUST revert if `_to` is the zero address.
        MUST revert if balance of holder for token `_id` is lower than the `_value` sent.
        MUST revert on any other error.
        MUST emit the `TransferSingle` event to reflect the balance change (see "Safe Transfer Rules" section of the standard).
        After the above conditions are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call `onERC1155Received` on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).        
        @param _from    Source address
        @param _to      Target address
        @param _id      ID of the token type
        @param _value   Transfer amount
        @param _data    Additional data with no specified format, MUST be sent unaltered in call to `onERC1155Received` on `_to`
    */
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external;

    /**
        @notice Transfers `_values` amount(s) of `_ids` from the `_from` address to the `_to` address specified (with safety call).
        @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
        MUST revert if `_to` is the zero address.
        MUST revert if length of `_ids` is not the same as length of `_values`.
        MUST revert if any of the balance(s) of the holder(s) for token(s) in `_ids` is lower than the respective amount(s) in `_values` sent to the recipient.
        MUST revert on any other error.        
        MUST emit `TransferSingle` or `TransferBatch` event(s) such that all the balance changes are reflected (see "Safe Transfer Rules" section of the standard).
        Balance changes and events MUST follow the ordering of the arrays (_ids[0]/_values[0] before _ids[1]/_values[1], etc).
        After the above conditions for the transfer(s) in the batch are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call the relevant `ERC1155TokenReceiver` hook(s) on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).                      
        @param _from    Source address
        @param _to      Target address
        @param _ids     IDs of each token type (order and length must match _values array)
        @param _values  Transfer amounts per token type (order and length must match _ids array)
        @param _data    Additional data with no specified format, MUST be sent unaltered in call to the `ERC1155TokenReceiver` hook(s) on `_to`
    */
    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external;

    /**
        @notice Get the balance of an account's tokens.
        @param _owner  The address of the token holder
        @param _id     ID of the token
        @return        The _owner's balance of the token type requested
     */
    function balanceOf(address _owner, uint256 _id) external view returns (uint256);

    /**
        @notice Get the balance of multiple account/token pairs
        @param _owners The addresses of the token holders
        @param _ids    ID of the tokens
        @return        The _owner's balance of the token types requested (i.e. balance for each (owner, id) pair)
     */
    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory);

    /**
        @notice Enable or disable approval for a third party ("operator") to manage all of the caller's tokens.
        @dev MUST emit the ApprovalForAll event on success.
        @param _operator  Address to add to the set of authorized operators
        @param _approved  True if the operator is approved, false to revoke approval
    */
    function setApprovalForAll(address _operator, bool _approved) external;

    /**
        @notice Queries the approval status of an operator for a given owner.
        @param _owner     The owner of the tokens
        @param _operator  Address of authorized operator
        @return           True if the operator is approved, false if not
    */
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}





/** 
 *  SourceUnit: /home/null/Desktop/aavegotchi-gbm/contracts/facets/GBMFacet.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: CC0-1.0


/// @title IERC721TokenReceiver
/// @dev See https://eips.ethereum.org/EIPS/eip-721. Note: the ERC-165 identifier for this interface is 0x150b7a02.
interface IERC721TokenReceiver {
    /// @notice Handle the receipt of an NFT
    /// @dev The ERC721 smart contract calls this function on the recipient
    ///  after a `transfer`. This function MAY throw to revert and reject the
    ///  transfer. Return of other than the magic value MUST result in the
    ///  transaction being reverted.
    ///  Note: the contract address is always the message sender.
    /// @param _operator The address which called `safeTransferFrom` function
    /// @param _from The address which previously owned the token
    /// @param _tokenId The NFT identifier which is being transferred
    /// @param _data Additional data with no specified format
    /// @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    ///  unless throwing
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns(bytes4);
}



/** 
 *  SourceUnit: /home/null/Desktop/aavegotchi-gbm/contracts/facets/GBMFacet.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: CC0-1.0


/// @title ERC-721 Non-Fungible Token Standard
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x80ac58cd.
interface IERC721 /* is ERC165 */ {
    /// @dev This emits when ownership of any NFT changes by any mechanism.
    ///  This event emits when NFTs are created (`from` == 0) and destroyed
    ///  (`to` == 0). Exception: during contract creation, any number of NFTs
    ///  may be created and assigned without emitting Transfer. At the time of
    ///  any transfer, the approved address for that NFT (if any) is reset to none.
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    /// @dev This emits when the approved address for an NFT is changed or
    ///  reaffirmed. The zero address indicates there is no approved address.
    ///  When a Transfer event emits, this also indicates that the approved
    ///  address for that NFT (if any) is reset to none.
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

    /// @dev This emits when an operator is enabled or disabled for an owner.
    ///  The operator can manage all NFTs of the owner.
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /// @notice Count all NFTs assigned to an owner
    /// @dev NFTs assigned to the zero address are considered invalid, and this
    ///  function throws for queries about the zero address.
    /// @param _owner An address for whom to query the balance
    /// @return The number of NFTs owned by `_owner`, possibly zero
    function balanceOf(address _owner) external view returns (uint256);

    /// @notice Find the owner of an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///  about them do throw.
    /// @param _tokenId The identifier for an NFT
    /// @return The address of the owner of the NFT
    function ownerOf(uint256 _tokenId) external view returns (address);

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
    ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
    ///  `onERC721Received` on `_to` and throws if the return value is not
    ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) external payable;

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to "".
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;

    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///  THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;

    /// @notice Change or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    ///  Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve
    function approve(address _approved, uint256 _tokenId) external payable;

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///  all of `msg.sender`'s assets
    /// @dev Emits the ApprovalForAll event. The contract MUST allow
    ///  multiple operators per owner.
    /// @param _operator Address to add to the set of authorized operators
    /// @param _approved True if the operator is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) external;

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT.
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId) external view returns (address);

    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}





/** 
 *  SourceUnit: /home/null/Desktop/aavegotchi-gbm/contracts/facets/GBMFacet.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: CC0-1.0


/// @title ERC20 interface
/// @dev https://github.com/ethereum/EIPs/issues/20
interface IERC20 {
	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);

	function totalSupply() external view returns (uint256);
	function balanceOf(address who) external view returns (uint256);
	function allowance(address owner, address spender) external view returns (uint256);
	function transfer(address to, uint256 value) external returns (bool);
	function approve(address spender, uint256 value) external returns (bool);
	function transferFrom(address from, address to, uint256 value) external returns (bool);
}




/** 
 *  SourceUnit: /home/null/Desktop/aavegotchi-gbm/contracts/facets/GBMFacet.sol
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
 *  SourceUnit: /home/null/Desktop/aavegotchi-gbm/contracts/facets/GBMFacet.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: UNLICENSED
// © Copyright 2021. Patent pending. All rights reserved. Perpetual Altruism Ltd.


/// @title IGBM GBM auction interface
/// @dev See GBM.auction on how to use this contract
/// @author Guillaume Gonnaud
interface IGBM {
    //Event emitted when an auction is being setup
    event Auction_Initialized(
        uint256 indexed _auctionID,
        uint256 indexed _tokenID,
        uint256 indexed _tokenIndex,
        address _contractAddress,
        bytes4 _tokenKind
    );

    //Event emitted when the start time of an auction changes (due to admin interaction )
    event Auction_StartTimeUpdated(uint256 indexed _auctionID, uint256 _startTime);

    //Event emitted when the end time of an auction changes (be it due to admin interaction or bid at the end)
    event Auction_EndTimeUpdated(uint256 indexed _auctionID, uint256 _endTime);

    //Event emitted when a Bid is placed
    event Auction_BidPlaced(uint256 indexed _auctionID, address indexed _bidder, uint256 _bidAmount);

    //Event emitted when a bid is removed (due to a new bid displacing it)
    event Auction_BidRemoved(uint256 indexed _auctionID, address indexed _bidder, uint256 _bidAmount);

    //Event emitted when incentives are paid (due to a new bid rewarding the _earner bid)
    event Auction_IncentivePaid(uint256 indexed _auctionID, address indexed _earner, uint256 _incentiveAmount);

    event Contract_BiddingAllowed(address indexed _contract, bool _biddingAllowed);

    event Auction_ItemClaimed(uint256 indexed _auctionID);

    //    function bid(
    //        uint256 _auctionID,
    //        uint256 _bidAmount,
    //        uint256 _highestBid
    //    ) external;

    function batchClaim(uint256[] memory _auctionIds) external;

    function claim(uint256 _auctionId) external;

    function erc20Currency() external view returns (address);

    function getAuctionID(address _contract, uint256 _tokenID) external view returns (uint256);

    function getAuctionID(
        address _contract,
        uint256 _tokenID,
        uint256 _tokenIndex
    ) external view returns (uint256);

    function getTokenId(uint256 _auctionId) external view returns (uint256);

    function getContractAddress(uint256 _auctionId) external view returns (address);

    function getTokenKind(uint256 _auctionId) external view returns (bytes4);

    function getAuctionHighestBidder(uint256 _auctionId) external view returns (address);

    function getAuctionHighestBid(uint256 _auctionId) external view returns (uint256);

    function getAuctionDebt(uint256 _auctionId) external view returns (uint256);

    function getAuctionDueIncentives(uint256 _auctionId) external view returns (uint256);

    function getAuctionStartTime(uint256 _auctionId) external view returns (uint256);

    function getAuctionEndTime(uint256 _auctionId) external view returns (uint256);

    function getAuctionHammerTimeDuration(uint256 _auctionId) external view returns (uint256);

    function getAuctionBidDecimals(uint256 _auctionId) external view returns (uint256);

    function getAuctionStepMin(uint256 _auctionId) external view returns (uint256);

    function getAuctionIncMin(uint256 _auctionId) external view returns (uint256);

    function getAuctionIncMax(uint256 _auctionId) external view returns (uint256);

    function getAuctionBidMultiplier(uint256 _auctionId) external view returns (uint256);
}


/** 
 *  SourceUnit: /home/null/Desktop/aavegotchi-gbm/contracts/facets/GBMFacet.sol
*/

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: UNLICENSED
// © Copyright 2021. Patent pending. All rights reserved. Perpetual Altruism Ltd.


////import "../interfaces/IGBM.sol";
////import "../interfaces/IGBMInitiator.sol";
////import "../interfaces/IERC20.sol";
////import "../interfaces/IERC721.sol";
////import "../interfaces/IERC721TokenReceiver.sol";
////import "../interfaces/IERC1155.sol";
////import "../interfaces/IERC1155TokenReceiver.sol";
////import "../interfaces/Ownable.sol";
////import "../libraries/AppStorage.sol";
////import "../libraries/LibDiamond.sol";
////import "../libraries/LibSignature.sol";

/// @title GBM auction contract
/// @dev See GBM.auction on how to use this contract
/// @author Guillaume Gonnaud
contract GBMFacet is IGBM, IERC1155TokenReceiver, IERC721TokenReceiver, Modifiers {
    function erc20Currency() external view override returns (address) {
        return s.erc20Currency;
    }

    /// @notice Place a GBM bid for a GBM auction
    /// @param _auctionId The auction you want to bid on
    /// @param _bidAmount The amount of the ERC20 token the bid is made of. They should be withdrawable by this contract.
    /// @param _highestBid The current higest bid. Throw if incorrect.
    /// @param _signature Signature
    function commitBid(
        uint256 _auctionId,
        uint256 _bidAmount,
        uint256 _highestBid,
        bytes memory _signature
    ) external {
        bytes32 messageHash = keccak256(abi.encodePacked(msg.sender, _auctionId, _bidAmount, _highestBid));
        require(LibSignature.isValid(messageHash, _signature, s.backendPubKey), "bid: Invalid signature");

        bid(_auctionId, _bidAmount, _highestBid);
    }

    /// @notice Place a GBM bid for a GBM auction
    /// @param _auctionId The auction you want to bid on
    /// @param _bidAmount The amount of the ERC20 token the bid is made of. They should be withdrawable by this contract.
    /// @param _highestBid The current higest bid. Throw if incorrect.
    function bid(
        uint256 _auctionId,
        uint256 _bidAmount,
        uint256 _highestBid
    ) internal {
        require(s.collections[s.tokenMapping[_auctionId].contractAddress].biddingAllowed, "bid: bidding is currently not allowed");

        require(_bidAmount > 1, "bid: _bidAmount cannot be 0");

        require(_highestBid == s.auctions[_auctionId].highestBid, "bid: current highest bid does not match the submitted transaction _highestBid");

        //An auction start time of 0 also indicate the auction has not been created at all

        require(getAuctionStartTime(_auctionId) <= block.timestamp && getAuctionStartTime(_auctionId) != 0, "bid: Auction has not started yet");
        require(getAuctionEndTime(_auctionId) >= block.timestamp, "bid: Auction has already ended");

        require(_bidAmount > _highestBid, "bid: _bidAmount must be higher than _highestBid");

        require(
            // (_highestBid * (getAuctionBidDecimals(_auctionId)) + (getAuctionStepMin(_auctionId) / getAuctionBidDecimals(_auctionId))) >= _highestBid,
            // "bid: _bidAmount must meet the minimum bid"

            (_highestBid * (getAuctionBidDecimals(_auctionId) + getAuctionStepMin(_auctionId))) <= (_bidAmount * getAuctionBidDecimals(_auctionId)),
            "bid: _bidAmount must meet the minimum bid"
        );

        //Transfer the money of the bidder to the GBM smart contract
        IERC20(s.erc20Currency).transferFrom(msg.sender, address(this), _bidAmount);

        //Extend the duration time of the auction if we are close to the end
        if (getAuctionEndTime(_auctionId) < block.timestamp + getAuctionHammerTimeDuration(_auctionId)) {
            s.auctions[_auctionId].endTime = block.timestamp + getAuctionHammerTimeDuration(_auctionId);
            emit Auction_EndTimeUpdated(_auctionId, s.auctions[_auctionId].endTime);
        }

        // Saving incentives for later sending
        uint256 duePay = s.auctions[_auctionId].dueIncentives;
        address previousHighestBidder = s.auctions[_auctionId].highestBidder;
        uint256 previousHighestBid = s.auctions[_auctionId].highestBid;

        // Emitting the event sequence
        if (previousHighestBidder != address(0)) {
            emit Auction_BidRemoved(_auctionId, previousHighestBidder, previousHighestBid);
        }

        if (duePay != 0) {
            s.auctions[_auctionId].auctionDebt = s.auctions[_auctionId].auctionDebt + duePay;
            emit Auction_IncentivePaid(_auctionId, previousHighestBidder, duePay);
        }

        emit Auction_BidPlaced(_auctionId, msg.sender, _bidAmount);

        // Calculating incentives for the new bidder
        s.auctions[_auctionId].dueIncentives = calculateIncentives(_auctionId, _bidAmount);

        //Setting the new bid/bidder as the highest bid/bidder
        s.auctions[_auctionId].highestBidder = msg.sender;
        s.auctions[_auctionId].highestBid = _bidAmount;

        if ((previousHighestBid + duePay) != 0) {
            //Refunding the previous bid as well as sending the incentives

            //Added to prevent revert
            IERC20(s.erc20Currency).approve(address(this), (previousHighestBid + duePay));

            IERC20(s.erc20Currency).transferFrom(address(this), previousHighestBidder, (previousHighestBid + duePay));
        }
    }

    function batchClaim(uint256[] memory _auctionIds) external override {
        for (uint256 index = 0; index < _auctionIds.length; index++) {
            claim(_auctionIds[index]);
        }
    }

    /// @notice Attribute a token to the winner of the auction and distribute the proceeds to the owner of this contract.
    /// throw if bidding is disabled or if the auction is not finished.
    /// @param _auctionId The auctionId of the auction to complete
    function claim(uint256 _auctionId) public override {
        address _ca = s.tokenMapping[_auctionId].contractAddress;
        uint256 _tid = s.tokenMapping[_auctionId].tokenId;

        require(s.collections[_ca].biddingAllowed, "claim: Claiming is currently not allowed");
        require(getAuctionEndTime(_auctionId) < block.timestamp, "claim: Auction has not yet ended");
        require(s.auctionItemClaimed[_auctionId] == false, "claim: Item has already been claimed");

        //Prevents re-entrancy
        s.auctionItemClaimed[_auctionId] = true;

        //Todo: Add in the various Aavegotchi addresses
        uint256 _proceeds = s.auctions[_auctionId].highestBid - s.auctions[_auctionId].auctionDebt;

        //Added to prevent revert
        IERC20(s.erc20Currency).approve(address(this), _proceeds);

        //Transfer the proceeds to the various recipients

        //5% to burn address
        uint256 burnShare = (_proceeds * 5) / 100;

        //40% to Pixelcraft wallet
        uint256 companyShare = (_proceeds * 40) / 100;

        //40% to player rewards
        uint256 playerRewardsShare = (_proceeds * 2) / 5;

        //15% to DAO
        uint256 daoShare = (_proceeds - burnShare - companyShare - playerRewardsShare);

        IERC20(s.erc20Currency).transferFrom(address(this), address(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF), burnShare);
        IERC20(s.erc20Currency).transferFrom(address(this), s.pixelcraft, companyShare);
        IERC20(s.erc20Currency).transferFrom(address(this), s.playerRewards, playerRewardsShare);
        IERC20(s.erc20Currency).transferFrom(address(this), s.daoTreasury, daoShare);

        //todo: test
        if (s.auctions[_auctionId].highestBid == 0) {
            s.auctions[_auctionId].highestBidder = LibDiamond.contractOwner();
        }

        if (s.tokenMapping[_auctionId].tokenKind == bytes4(keccak256("ERC721"))) {
            //0x73ad2146
            IERC721(_ca).safeTransferFrom(address(this), s.auctions[_auctionId].highestBidder, _tid);
        } else if (s.tokenMapping[_auctionId].tokenKind == bytes4(keccak256("ERC1155"))) {
            //0x973bb640
            IERC1155(_ca).safeTransferFrom(address(this), s.auctions[_auctionId].highestBidder, _tid, 1, "");
            s.erc1155TokensUnderAuction[_ca][_tid] = s.erc1155TokensUnderAuction[_ca][_tid] - 1;
        }

        emit Auction_ItemClaimed(_auctionId);
    }

    /// @notice Register an auction contract default parameters for a GBM auction. To use to save gas
    /// @param _contract The token contract the auctionned token belong to
    function registerAnAuctionContract(address _contract) public onlyOwner {
        s.collections[_contract].startTime = s.initiatorInfo.startTime;
        s.collections[_contract].endTime = s.initiatorInfo.endTime;
        s.collections[_contract].hammerTimeDuration = s.initiatorInfo.hammerTimeDuration;
        s.collections[_contract].bidDecimals = s.initiatorInfo.bidDecimals;
        s.collections[_contract].stepMin = s.initiatorInfo.stepMin;
        s.collections[_contract].incMin = s.initiatorInfo.incMin;
        s.collections[_contract].incMax = s.initiatorInfo.incMax;
        s.collections[_contract].bidMultiplier = s.initiatorInfo.bidMultiplier;
    }

    /// @notice Allow/disallow bidding and claiming for a whole token contract address.
    /// @param _contract The token contract the auctionned token belong to
    /// @param _value True if bidding/claiming should be allowed.
    function setBiddingAllowed(address _contract, bool _value) external onlyOwner {
        s.collections[_contract].biddingAllowed = _value;
        emit Contract_BiddingAllowed(_contract, _value);
    }

    /// @notice Register an auction token and emit the relevant AuctionInitialized & AuctionStartTimeUpdated events
    /// Throw if the token owner is not the GBM smart contract/supply of auctionned 1155 token is insufficient
    /// @param _tokenContract The token contract the auctionned token belong to
    /// @param _tokenId The token ID of the token being auctionned
    /// @param _tokenKind either bytes4(keccak256("ERC721")) or bytes4(keccak256("ERC1155"))
    /// @param _useInitiator Set to `false` if you want to use the default value registered for the token contract (if wanting to reset to default,
    /// use `true`)
    function registerAnAuctionToken(
        address _tokenContract,
        uint256 _tokenId,
        bytes4 _tokenKind,
        bool _useInitiator
    ) public onlyOwner {
        modifyAnAuctionToken(_tokenContract, _tokenId, _tokenKind, _useInitiator, 0, false);
    }

    /// @notice Register an auction token and emit the relevant AuctionInitialized & AuctionStartTimeUpdated events
    /// Throw if the token owner is not the GBM smart contract/supply of auctionned 1155 token is insufficient
    /// @param _tokenContract The token contract the auctionned token belong to
    /// @param _tokenId The token ID of the token being auctionned
    /// @param _tokenKind either bytes4(keccak256("ERC721")) or bytes4(keccak256("ERC1155"))
    /// @param _useInitiator Set to `false` if you want to use the default value registered for the token contract (if wanting to reset to default,
    /// use `true`)
    /// @param _1155Index Set to 0 if dealing with an ERC-721 or registering new 1155 test. otherwise, set to relevant index you want to reinitialize
    /// @param _rewrite Set to true if you want to rewrite the data of an existing auction, false otherwise
    function modifyAnAuctionToken(
        address _tokenContract,
        uint256 _tokenId,
        bytes4 _tokenKind,
        bool _useInitiator,
        uint256 _1155Index,
        bool _rewrite
    ) internal {
        if (!_rewrite) {
            _1155Index = s.erc1155TokensIndex[_tokenContract][_tokenId]; //_1155Index was 0 if creating new auctions
            require(s.auctionMapping[_tokenContract][_tokenId][_1155Index] == 0, "The auction aleady exist for the specified token");
        } else {
            require(s.auctionMapping[_tokenContract][_tokenId][_1155Index] != 0, "The auction doesn't exist yet for the specified token");
        }

        //Checking the kind of token being registered
        require(
            _tokenKind == bytes4(keccak256("ERC721")) || _tokenKind == bytes4(keccak256("ERC1155")),
            "registerAnAuctionToken: Only ERC1155 and ERC721 tokens are supported"
        );

        //Building the auction object
        TokenRepresentation memory newAuction;
        newAuction.contractAddress = _tokenContract;
        newAuction.tokenId = _tokenId;
        newAuction.tokenKind = _tokenKind;

        uint256 _auctionId;

        if (_tokenKind == bytes4(keccak256("ERC721"))) {
            require(
                msg.sender == Ownable(_tokenContract).owner() || address(this) == IERC721(_tokenContract).ownerOf(_tokenId),
                "registerAnAuctionToken: the specified ERC-721 token cannot be auctioned"
            );

            _auctionId = uint256(keccak256(abi.encodePacked(_tokenContract, _tokenId, _tokenKind)));
            s.auctionMapping[_tokenContract][_tokenId][0] = _auctionId;
        } else {
            require(
                msg.sender == Ownable(_tokenContract).owner() ||
                    s.erc1155TokensUnderAuction[_tokenContract][_tokenId] < IERC1155(_tokenContract).balanceOf(address(this), _tokenId),
                "registerAnAuctionToken:  the specified ERC-1155 token cannot be auctionned"
            );

            require(
                _1155Index <= s.erc1155TokensIndex[_tokenContract][_tokenId],
                "The specified _1155Index have not been reached yet for this token"
            );

            _auctionId = uint256(keccak256(abi.encodePacked(_tokenContract, _tokenId, _tokenKind, _1155Index)));

            if (!_rewrite) {
                s.erc1155TokensIndex[_tokenContract][_tokenId] = s.erc1155TokensIndex[_tokenContract][_tokenId] + 1;
                s.erc1155TokensUnderAuction[_tokenContract][_tokenId] = s.erc1155TokensUnderAuction[_tokenContract][_tokenId] + 1;
            }

            s.auctionMapping[_tokenContract][_tokenId][_1155Index] = _auctionId;
        }

        s.tokenMapping[_auctionId] = newAuction;

        if (_useInitiator) {
            s.auctions[_auctionId].owner = LibDiamond.contractOwner();
            s.auctions[_auctionId].startTime = s.initiatorInfo.startTime;
            s.auctions[_auctionId].endTime = s.initiatorInfo.endTime;
            s.auctions[_auctionId].hammerTimeDuration = s.initiatorInfo.hammerTimeDuration;
            s.auctions[_auctionId].bidDecimals = s.initiatorInfo.bidDecimals;
            s.auctions[_auctionId].stepMin = s.initiatorInfo.stepMin;
            s.auctions[_auctionId].incMin = s.initiatorInfo.incMin;
            s.auctions[_auctionId].incMax = s.initiatorInfo.incMax;
            s.auctions[_auctionId].bidMultiplier = s.initiatorInfo.bidMultiplier;
        }

        //Event emitted when an auction is being setup
        emit Auction_Initialized(_auctionId, _tokenId, _1155Index, _tokenContract, _tokenKind);

        //Event emitted when the start time of an auction changes (due to admin interaction )
        emit Auction_StartTimeUpdated(_auctionId, getAuctionStartTime(_auctionId));
    }

    function getAuctionInfo(uint256 _auctionId) external view returns (Auction memory auctionInfo_) {
        auctionInfo_ = s.auctions[_auctionId];
        auctionInfo_.contractAddress = s.tokenMapping[_auctionId].contractAddress;
        auctionInfo_.biddingAllowed = s.collections[s.tokenMapping[_auctionId].contractAddress].biddingAllowed;
    }

    function getAuctionHighestBidder(uint256 _auctionId) external view override returns (address) {
        return s.auctions[_auctionId].highestBidder;
    }

    function getAuctionHighestBid(uint256 _auctionId) external view override returns (uint256) {
        return s.auctions[_auctionId].highestBid;
    }

    function getAuctionDebt(uint256 _auctionId) external view override returns (uint256) {
        return s.auctions[_auctionId].auctionDebt;
    }

    function getAuctionDueIncentives(uint256 _auctionId) external view override returns (uint256) {
        return s.auctions[_auctionId].dueIncentives;
    }

    function getAuctionID(address _contract, uint256 _tokenID) external view override returns (uint256) {
        return s.auctionMapping[_contract][_tokenID][0];
    }

    function getAuctionID(
        address _contract,
        uint256 _tokenID,
        uint256 _tokenIndex
    ) external view override returns (uint256) {
        return s.auctionMapping[_contract][_tokenID][_tokenIndex];
    }

    function getTokenKind(uint256 _auctionId) external view override returns (bytes4) {
        return s.tokenMapping[_auctionId].tokenKind;
    }

    function getTokenId(uint256 _auctionId) external view override returns (uint256) {
        return s.tokenMapping[_auctionId].tokenId;
    }

    function getContractAddress(uint256 _auctionId) external view override returns (address) {
        return s.tokenMapping[_auctionId].contractAddress;
    }

    function getAuctionStartTime(uint256 _auctionId) public view override returns (uint256) {
        if (s.auctions[_auctionId].startTime != 0) {
            return s.auctions[_auctionId].startTime;
        } else {
            return s.collections[s.tokenMapping[_auctionId].contractAddress].startTime;
        }
    }

    function getAuctionEndTime(uint256 _auctionId) public view override returns (uint256) {
        if (s.auctions[_auctionId].endTime != 0) {
            return s.auctions[_auctionId].endTime;
        } else {
            return s.collections[s.tokenMapping[_auctionId].contractAddress].endTime;
        }
    }

    function getAuctionHammerTimeDuration(uint256 _auctionId) public view override returns (uint256) {
        if (s.auctions[_auctionId].hammerTimeDuration != 0) {
            return s.auctions[_auctionId].hammerTimeDuration;
        } else {
            return s.collections[s.tokenMapping[_auctionId].contractAddress].hammerTimeDuration;
        }
    }

    function getAuctionBidDecimals(uint256 _auctionId) public view override returns (uint256) {
        if (s.auctions[_auctionId].bidDecimals != 0) {
            return s.auctions[_auctionId].bidDecimals;
        } else {
            return s.collections[s.tokenMapping[_auctionId].contractAddress].bidDecimals;
        }
    }

    function getAuctionStepMin(uint256 _auctionId) public view override returns (uint256) {
        if (s.auctions[_auctionId].stepMin != 0) {
            return s.auctions[_auctionId].stepMin;
        } else {
            return s.collections[s.tokenMapping[_auctionId].contractAddress].stepMin;
        }
    }

    function getAuctionIncMin(uint256 _auctionId) public view override returns (uint256) {
        if (s.auctions[_auctionId].incMin != 0) {
            return s.auctions[_auctionId].incMin;
        } else {
            return s.collections[s.tokenMapping[_auctionId].contractAddress].incMin;
        }
    }

    function getAuctionIncMax(uint256 _auctionId) public view override returns (uint256) {
        if (s.auctions[_auctionId].incMax != 0) {
            return s.auctions[_auctionId].incMax;
        } else {
            return s.collections[s.tokenMapping[_auctionId].contractAddress].incMax;
        }
    }

    function getAuctionBidMultiplier(uint256 _auctionId) public view override returns (uint256) {
        if (s.auctions[_auctionId].bidMultiplier != 0) {
            return s.auctions[_auctionId].bidMultiplier;
        } else {
            return s.collections[s.tokenMapping[_auctionId].contractAddress].bidMultiplier;
        }
    }

    function onERC721Received(
        address, /* _operator */
        address, /*  _from */
        uint256, /*  _tokenId */
        bytes calldata /* _data */
    ) external pure override returns (bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

    function onERC1155Received(
        address, /* _operator */
        address, /* _from */
        uint256, /* _id */
        uint256, /* _value */
        bytes calldata /* _data */
    ) external pure override returns (bytes4) {
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

    function onERC1155BatchReceived(
        address, /* _operator */
        address, /* _from */
        uint256[] calldata, /* _ids */
        uint256[] calldata, /* _values */
        bytes calldata /* _data */
    ) external pure override returns (bytes4) {
        return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
    }

    /// @notice Calculating and setting how much payout a bidder will receive if outbid
    /// @dev Only callable internally
    function calculateIncentives(uint256 _auctionId, uint256 _newBidValue) internal view returns (uint256) {
        uint256 bidDecimals = getAuctionBidDecimals(_auctionId);
        uint256 bidIncMax = getAuctionIncMax(_auctionId);

        //Init the baseline bid we need to perform against
        uint256 baseBid = (s.auctions[_auctionId].highestBid * (bidDecimals + getAuctionStepMin(_auctionId))) / bidDecimals;

        //If no bids are present, set a basebid value of 1 to prevent divide by 0 errors
        if (baseBid == 0) {
            baseBid = 1;
        }

        //Ratio of newBid compared to expected minBid
        uint256 decimaledRatio = ((bidDecimals * getAuctionBidMultiplier(_auctionId) * (_newBidValue - baseBid)) / baseBid) +
            getAuctionIncMin(_auctionId) *
            bidDecimals;

        if (decimaledRatio > (bidDecimals * bidIncMax)) {
            decimaledRatio = bidDecimals * bidIncMax;
        }

        return (_newBidValue * decimaledRatio) / (bidDecimals * bidDecimals);
    }

    function registerMassERC721Each(
        address _GBM,
        bool _useInitiator,
        address _ERC721Contract,
        uint256[] memory _tokenIds
    ) external onlyOwner {
        require(_tokenIds.length > 0, "No auctions to create");
        for (uint256 index = 0; index < _tokenIds.length; index++) {
            uint256 tokenId = _tokenIds[index];
            IERC721(_ERC721Contract).safeTransferFrom(msg.sender, _GBM, tokenId, "");
            registerAnAuctionToken(_ERC721Contract, tokenId, bytes4(keccak256("ERC721")), _useInitiator);
        }

        // _tokenIDStart++;
    }

    function registerMassERC1155Each(
        address _GBM,
        bool _useInitiator,
        address _ERC1155Contract,
        uint256 _tokenID,
        uint256 _indexStart,
        uint256 _indexEnd
    ) external onlyOwner {
        registerAnAuctionContract(_ERC1155Contract);
        IERC1155(_ERC1155Contract).safeTransferFrom(msg.sender, _GBM, _tokenID, _indexEnd - _indexStart, "");
        while (_indexStart < _indexEnd) {
            registerAnAuctionToken(_ERC1155Contract, _tokenID, bytes4(keccak256("ERC1155")), _useInitiator);
            _indexStart++;
        }
    }
}