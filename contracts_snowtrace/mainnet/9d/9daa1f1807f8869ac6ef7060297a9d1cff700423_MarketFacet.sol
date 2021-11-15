/**
 *Submitted for verification at snowtrace.io on 2021-11-10
*/

// Sources flattened with hardhat v2.6.1 https://hardhat.org

// File contracts/interfaces/IRentablePixel.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRentablePixel{
    struct RentData {
        address tenant;
        uint256 dailyPrice;
        uint256 startTimestamp;
        uint256 endTimestamp;
        uint16 minDaysToRent;
        uint16 maxDaysToRent;
        uint16 minDaysBeforeRentCancel;
        uint16 weeklyDiscount;
        uint16 monthlyDiscount;
        uint16 yearlyDiscount;
        uint16 rentCollectedDays;
    }

    struct RentTimeInput {
        uint16 year;
        uint8 month;//1-12
        uint8 day;//1-31
        uint8 hour;//0-23
        uint8 minute;//0-59
        uint8 second;//0-59
    }

    event RentListing(uint256 indexed tokenId, uint256 startTimestamp, uint256 endTimestamp);
    event CancelListing(uint256 indexed tokenId, uint256 startTimestamp, uint256 endTimestamp);
    event Rent(uint256 indexed tokenId, uint256 startTimestamp, uint256 endTimestamp, uint256 price);
    event CancelRent(uint256 indexed tokenId, uint256 startTimestamp, uint256 endTimestamp);

    function listRenting(uint256[] memory pixelIds, uint256 dailyPrice, RentTimeInput memory startTime, RentTimeInput memory endTime, uint16 minDaysToRent,
        uint16 maxDaysToRent, uint16 minDaysBeforeRentCancel, uint16 weeklyDiscount, uint16 monthlyDiscount, uint16 yearlyDiscount) external;
    function cancelRentListing(uint256[] memory pixelIds, RentTimeInput memory startTime, RentTimeInput memory endTime) external;
    function rentPixels(uint256[] memory pixelIds, RentTimeInput memory startTime, RentTimeInput memory endTime) external payable;
    function cancelRent(uint256[] memory pixelIds, RentTimeInput memory startTime, RentTimeInput memory endTime) external;
}


// File contracts/interfaces/IMarketPlace.sol


pragma solidity ^0.8.0;

interface IMarketPlace {
    struct MarketData {
        uint256 price;
        TokenState state;
    }//old struct not used
    enum TokenState {Pending, ForSale, Sold, Neutral}//old enum not used

    struct MarketDataV2 {
        uint256[] pixels;
        uint256 totalPrice;
    }

    struct MarketDataRead{
        uint256[] pixels;
        uint256 totalPrice;
        uint256 groupId;
    }

    event MarketBuy(uint256 indexed pixelId, uint256 price);
    event MarketList(uint256 indexed pixelId, uint256 price, uint256 groupId);
    event MarketCancel(uint256 indexed pixelId);

    function getFeeReceiver() external view returns(address payable);
    function getFeePercentage() external view returns(uint256);
    function setFeePercentage(uint256 _feePercentage) external;
    function setFeeReceiver(address _feeReceiver) external;
    function buyMarket(uint256 xCoordLeft, uint256 yCoordTop, uint256 width, uint256 height) external payable;
    function setPriceMarket(uint256 xCoordLeft, uint256 yCoordTop, uint256 width, uint256 height, uint256 totalPrice) external;
    function cancelMarket(uint256 xCoordLeft, uint256 yCoordTop, uint256 width, uint256 height) external;
    function getMarketData(uint256 xCoordLeft, uint256 yCoordTop, uint256 width, uint256 height) external view returns(MarketDataRead[] memory);
}


// File contracts/libraries/LibAppStorage.sol


pragma solidity ^0.8.0;
library AppConstants{
    uint256 constant publicPrice = 1000000000000000000; // 1 AVAX
    uint256 constant dayInSeconds = 86400;
    uint256 constant _NOT_ENTERED = 1;
    uint256 constant _ENTERED = 2;
}

struct AppStorage {
    //ERC721
    string _name;
    string _symbol;
    mapping(uint256 => address) _owners;
    mapping(address => uint256) _balances;
    mapping(uint256 => address) _tokenApprovals;
    mapping(address => mapping(address => bool)) _operatorApprovals;
    //ERC721Enumerable
    mapping(address => mapping(uint256 => uint256)) _ownedTokens;
    mapping(uint256 => uint256) _ownedTokensIndex;
    uint256[] _allTokens;
    mapping(uint256 => uint256) _allTokensIndex;
    //ERC721URIStorage
    mapping(uint256 => string) _tokenURIs;//not used

    uint256 isSaleStarted;
    string baseUri;

    mapping(uint256 => IRentablePixel.RentData[]) RentStorage;
    mapping(address => uint256) totalLockedValueByAddress;
    uint256 totalLockedValue;

    mapping(uint256 => IMarketPlace.MarketData) Market;
    address payable feeReceiver;
    uint256 feePercentage;
    uint32 isRentStarted;
    uint32 isMarketStarted;

    uint32 limitMinDaysToRent;
    uint32 limitMaxDaysToRent;
    uint32 limitMinDaysBeforeRentCancel;
    uint32 limitMaxDaysForRent;
    uint256 _status;
    uint256 reflectionBalance;
    uint256 totalDividend;
    mapping(uint256 => uint256) lastDividendAt;
    uint256 reflectionPercentage;
    uint256 currentReflectionBalance;

    //pixel group id to marketdata
    mapping(uint256 => IMarketPlace.MarketDataV2) MarketV2;
    //pixel id to pixel group
    mapping(uint256 => uint256) MarketV2Pixel;
    uint256 creatorBalance;
}

library LibAppStorage {
    function diamondStorage() internal pure returns (AppStorage storage ds) {
        assembly {
            ds.slot := 0
        }
    }

    function abs(int256 x) internal pure returns (uint256) {
        return uint256(x >= 0 ? x : -x);
    }
}

interface ReentrancyGuard{
    modifier nonReentrant() {
        require(LibAppStorage.diamondStorage()._status != AppConstants._ENTERED, "ReentrancyGuard: reentrant call");

        LibAppStorage.diamondStorage()._status = AppConstants._ENTERED;

        _;

        LibAppStorage.diamondStorage()._status = AppConstants._NOT_ENTERED;
    }
}


// File contracts/libraries/LibMeta.sol


pragma solidity ^0.8.0;

library LibMeta {
    function msgSender() internal view returns (address sender_) {
        sender_ = msg.sender;
    }

    function checkContains(uint256[] memory array, uint256 value) internal pure returns(bool){
        for(uint256 i = 0; i < array.length; i++){
            if(array[i] == value){
                return true;
            }
        }
        return false;
    }
}


// File contracts/libraries/LibMarket.sol


pragma solidity ^0.8.0;
library LibMarket {
    event MarketCancel(uint256 indexed pixelId);

    function _cancelSale(uint256 tokenId, uint256 emitEvent) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        _cancelSaleGroup(s.MarketV2Pixel[tokenId], emitEvent);
    }

    function _cancelSaleGroup(uint256 groupId, uint256 emitEvent) internal {
        if(groupId != 0){
            AppStorage storage s = LibAppStorage.diamondStorage();
            uint256[] memory groupPixels = s.MarketV2[groupId].pixels;
            for(uint256 j = 0; j < groupPixels.length; j++){
                s.MarketV2Pixel[groupPixels[j]] = 0;
                if(emitEvent > 0){
                    emit MarketCancel(groupPixels[j]);
                }
            }
            delete s.MarketV2[groupId].pixels;
            s.MarketV2[groupId].totalPrice = 0;
        }
    }

    function serviceFee(uint256 amount) internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 toFeeReceiver = amount * s.feePercentage;
        return toFeeReceiver / 1000;
    }
}


// File contracts/interfaces/IDiamondCut.sol


pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

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


// File contracts/libraries/LibDiamond.sol


pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndPosition {
        address facetAddress;
        uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    struct DiamondStorage {
        // maps function selector to the facet address and
        // the position of the selector in the facetFunctionSelectors.selectors array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // maps facet addresses to function selectors
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // facet addresses
        address[] facetAddresses;
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

    // Internal function version of diamondCut
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else {
                revert("LibDiamondCut: Incorrect FacetCutAction");
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();        
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);            
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress == address(0), "LibDiamondCut: Can't add function that already exists");
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress != _facetAddress, "LibDiamondCut: Can't replace function with same function");
            removeFunction(ds, oldFacetAddress, selector);
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        // if function does not exist then do nothing and return
        require(_facetAddress == address(0), "LibDiamondCut: Remove facet address must be address(0)");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            removeFunction(ds, oldFacetAddress, selector);
        }
    }

    function addFacet(DiamondStorage storage ds, address _facetAddress) internal {
        enforceHasContractCode(_facetAddress, "LibDiamondCut: New facet has no code");
        ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = ds.facetAddresses.length;
        ds.facetAddresses.push(_facetAddress);
    }    


    function addFunction(DiamondStorage storage ds, bytes4 _selector, uint96 _selectorPosition, address _facetAddress) internal {
        ds.selectorToFacetAndPosition[_selector].functionSelectorPosition = _selectorPosition;
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(_selector);
        ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
    }

    function removeFunction(DiamondStorage storage ds, address _facetAddress, bytes4 _selector) internal {        
        require(_facetAddress != address(0), "LibDiamondCut: Can't remove function that doesn't exist");
        // an immutable function is a function defined directly in a diamond
        require(_facetAddress != address(this), "LibDiamondCut: Can't remove immutable function");
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = ds.selectorToFacetAndPosition[_selector].functionSelectorPosition;
        uint256 lastSelectorPosition = ds.facetFunctionSelectors[_facetAddress].functionSelectors.length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds.facetFunctionSelectors[_facetAddress].functionSelectors[lastSelectorPosition];
            ds.facetFunctionSelectors[_facetAddress].functionSelectors[selectorPosition] = lastSelector;
            ds.selectorToFacetAndPosition[lastSelector].functionSelectorPosition = uint96(selectorPosition);
        }
        // delete the last selector
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete ds.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
            uint256 facetAddressPosition = ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = ds.facetAddresses[lastFacetAddressPosition];
                ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                ds.facetFunctionSelectors[lastFacetAddress].facetAddressPosition = facetAddressPosition;
            }
            ds.facetAddresses.pop();
            delete ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
        }
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


// File contracts/libraries/LibERC721.sol


pragma solidity ^0.8.0;
library LibERC721 {
    function _tokenOfOwnerByIndex(address owner, uint256 index) internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(index < _balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return s._ownedTokens[owner][index];
    }

    function _balanceOf(address owner) internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(owner != address(0), "ERC721: balance query for the zero address");
        return s._balances[owner];
    }

    function _ownerOf(uint256 tokenId) internal view returns (address) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        address owner = s._owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    function _tokensOfOwner(address _owner) internal view returns(uint256[] memory ) {
        uint256 tokenCount = _balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = _tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    function isReserved(uint256 tokenId) internal pure returns(uint16){
        uint256 x = (tokenId - 1) % 100;
        uint256 y = (tokenId - 1 - x) / 100;
        if((x >= 11 && x < 21 && y >= 13 && y < 20 )
            || (x >= 10 && x < 25 && y >= 43 && y < 49 )
            || (x >= 14 && x < 19 && y >= 67 && y < 82 )
            || (x >= 3 && x < 18 && y >= 90 && y < 96 )
            || (x >= 32 && x < 38 && y >= 7 && y < 19 )
            || (x >= 89 && x < 95 && y >= 14 && y < 36 )
            || (x >= 26 && x < 39 && y >= 83 && y < 89 )
            || (x >= 46 && x < 59 && y >= 83 && y < 89 )
            || (x >= 65 && x < 73 && y >= 13 && y < 20 )
            || (x >= 63 && x < 70 && y >= 53 && y < 65 )
            || (x >= 82 && x < 92 && y >= 85 && y < 95 )
            || (x >= 92 && x < 97 && y >= 43 && y < 58 )){
            return 1;
        }
        return 0;
    }
}


// File contracts/libraries/LibReflection.sol


pragma solidity ^0.8.0;
library LibReflection {
    function _claimRewardInternal(uint256 pixelIndex, uint256 mode) internal returns(uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 balance = _getReflectionBalance(pixelIndex);
        if (balance > 0) {
            s.lastDividendAt[pixelIndex] = s.totalDividend;
            if(mode == 0){
                s.currentReflectionBalance -= balance;
                payable(LibERC721._ownerOf(pixelIndex)).transfer(balance);
            }
        }
        return balance;
    }

    function _getReflectionBalance(uint256 pixelIndex) internal view returns (uint256){
        AppStorage storage s = LibAppStorage.diamondStorage();
        if(LibERC721._ownerOf(pixelIndex) == LibDiamond.contractOwner()){
            return 0;
        }
        return s.totalDividend - s.lastDividendAt[pixelIndex];
    }

    function _reflectDividend(uint256 fee) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 reflection = fee * s.reflectionPercentage / 1000;
        s.currentReflectionBalance += reflection;
        s.reflectionBalance = s.reflectionBalance + reflection;
        s.totalDividend = s.totalDividend + (reflection / (s._allTokens.length - s._balances[LibDiamond.contractOwner()]));
        s.creatorBalance += fee - reflection;
    }
}


// File @openzeppelin/contracts/utils/[email protected]



pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}


// File @openzeppelin/contracts/utils/introspection/[email protected]



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
interface IERC165 {
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


// File @openzeppelin/contracts/token/ERC721/[email protected]



pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}


// File contracts/facets/MarketFacet.sol


pragma solidity ^0.8.0;
contract MarketFacet  is IMarketPlace, ReentrancyGuard {
    AppStorage internal s;

    function getFeeReceiver() external override view returns(address payable){
        return s.feeReceiver;
    }

    function getFeePercentage() external override view returns(uint256){
        return s.feePercentage;
    }

    function setFeePercentage(uint256 _feePercentage) external override{
        LibDiamond.enforceIsContractOwner();
        require(_feePercentage <= 150, "It will never be more than 15 percentage");
        s.feePercentage = _feePercentage;
    }

    function setFeeReceiver(address _feeReceiver) external override{
        LibDiamond.enforceIsContractOwner();
        require(_feeReceiver != address(0), "No zero address");
        s.feeReceiver = payable(_feeReceiver);
    }

    function royaltyInfo(uint256, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount){
        receiver = s.feeReceiver;
        royaltyAmount = LibMarket.serviceFee(_salePrice);
    }

    function addToCommunityRoyalties(uint256 amount) external{
        require(msg.sender == s.feeReceiver, "Must be fee receiver");
        LibReflection._reflectDividend(amount);
    }

    function setPriceMarket(uint256 xCoordLeft, uint256 yCoordTop, uint256 width, uint256 height, uint256 totalPrice) external override{
        require(s.isMarketStarted == 1, "Market has not started");
        require(totalPrice > 1000000, "Price is too low");
        require(xCoordLeft >= 0 && yCoordTop >= 0 && width >= 1 && height >= 1 && xCoordLeft < 100 && xCoordLeft + width < 101 && yCoordTop < 100 && yCoordTop + height < 101, "Check Inputs");
        uint256[] memory pixels = new uint256[](width * height);
        for (uint256 i = xCoordLeft; i < xCoordLeft + width; i++) {
            for (uint256 j = yCoordTop; j < yCoordTop + height; j++) {
                uint256 tokenId = j * 100 + i + 1;
                pixels[(i - xCoordLeft) + (j - yCoordTop) * width] = tokenId;
                require(LibMeta.msgSender() == LibERC721._ownerOf(tokenId), "Only owners can do");
                require(s.MarketV2Pixel[tokenId] == 0, "Token already listed");
            }
        }
        uint256 groupId = uint256(keccak256(abi.encodePacked(xCoordLeft, yCoordTop, width, height)));
        for(uint256 i = 0; i < pixels.length; i++){
            s.MarketV2Pixel[pixels[i]] = groupId;
            emit MarketList(pixels[i] , totalPrice / pixels.length, groupId);
        }
        s.MarketV2[groupId].pixels = pixels;
        s.MarketV2[groupId].totalPrice = totalPrice;
    }

    function cancelMarket(uint256 xCoordLeft, uint256 yCoordTop, uint256 width, uint256 height) external override{
        require(s.isMarketStarted == 1, "Market has not started");
        require(xCoordLeft >= 0 && yCoordTop >= 0 && width >= 1 && height >= 1 && xCoordLeft < 100 && xCoordLeft + width < 101 && yCoordTop < 100 && yCoordTop + height < 101, "Check Inputs");
        uint256[] memory pixels = new uint256[](width * height);
        for (uint256 i = xCoordLeft; i < xCoordLeft + width; i++) {
            for (uint256 j = yCoordTop; j < yCoordTop + height; j++) {
                uint256 tokenId = j * 100 + i + 1;
                pixels[(i - xCoordLeft) + (j - yCoordTop) * width] = tokenId;
                require(LibMeta.msgSender() == LibERC721._ownerOf(tokenId), "Only owners can do");
                require(s.MarketV2Pixel[tokenId] != 0, "Token not listed for sale");
            }
        }
        uint256[] memory groupsProcessed = new uint256[](pixels.length);
        for(uint256 i = 0; i < pixels.length; i++){
            uint256 groupId = s.MarketV2Pixel[pixels[i]];
            if(!LibMeta.checkContains(groupsProcessed, groupId)){
                LibMarket._cancelSaleGroup(groupId, 1);
                groupsProcessed[i] = groupId;
            }
        }
    }

    function getMarketData(uint256 xCoordLeft, uint256 yCoordTop, uint256 width, uint256 height) external override view returns(MarketDataRead[] memory){
        require(s.isMarketStarted == 1, "Market has not started");
        require(xCoordLeft >= 0 && yCoordTop >= 0 && width >= 1 && height >= 1 && xCoordLeft < 100 && xCoordLeft + width < 101 && yCoordTop < 100 && yCoordTop + height < 101, "Check Inputs");
        uint256 size = width * height;
        MarketDataRead[] memory data = new MarketDataRead[](size);
        for (uint256 i = xCoordLeft; i < xCoordLeft + width; i++) {
            for (uint256 j = yCoordTop; j < yCoordTop + height; j++) {
                uint256 tokenId = j * 100 + i + 1;
                uint256 groupId = s.MarketV2Pixel[tokenId];
                MarketDataV2 memory mDataV2 = s.MarketV2[groupId];
                MarketDataRead memory mData;
                mData.pixels = mDataV2.pixels;
                mData.totalPrice = mDataV2.totalPrice;
                mData.groupId = groupId;
                data[(i - xCoordLeft) + (j - yCoordTop) * width] = mData;
            }
        }
        return data;
    }
    function buyMarket(uint256 xCoordLeft, uint256 yCoordTop, uint256 width, uint256 height) external override payable nonReentrant{
        require(s.isMarketStarted == 1, "Market has not started");
        require(xCoordLeft >= 0 && yCoordTop >= 0 && width >= 1 && height >= 1 && xCoordLeft < 100 && xCoordLeft + width < 101 && yCoordTop < 100 && yCoordTop + height < 101, "Check Inputs");
        uint256[] memory pixels = new uint256[](width * height);
        for (uint256 i = xCoordLeft; i < xCoordLeft + width; i++) {
            for (uint256 j = yCoordTop; j < yCoordTop + height; j++) {
                uint256 tokenId = j * 100 + i + 1;
                pixels[(i - xCoordLeft) + (j - yCoordTop) * width] = tokenId;
                require(s.MarketV2Pixel[tokenId] != 0, "Token not listed for sale");
            }
        }
        uint256[] memory groupsProcessed = new uint256[](pixels.length);
        uint256 totalSize = 0;
        uint256 totalValue = 0;
        for(uint256 i = 0; i < pixels.length; i++){
            uint256 groupId = s.MarketV2Pixel[pixels[i]];
            if(!LibMeta.checkContains(groupsProcessed, groupId)){
                totalSize += s.MarketV2[groupId].pixels.length;
                totalValue += s.MarketV2[groupId].totalPrice;
                groupsProcessed[i] = groupId;
            }
        }
        require(totalSize == pixels.length, "All pixels in the group not chosen");
        require(msg.value >= totalValue, "AVAX value is not enough");

        for(uint256 i = 0; i < groupsProcessed.length; i++){
            uint256 groupId = groupsProcessed[i];
            if(groupId > 0){
                uint256[] memory pixelsGroup = s.MarketV2[groupId].pixels;
                address tokenOwner = LibERC721._ownerOf(pixelsGroup[0]);
                address payable seller = payable(address(tokenOwner));
                uint256 price = s.MarketV2[groupId].totalPrice;
                for(uint256 j = 0; j < pixelsGroup.length; j++){
                    IERC721(address(this)).safeTransferFrom(tokenOwner, LibMeta.msgSender(), pixelsGroup[j]);
                }
                if (price >= 0) {
                    if(s.feePercentage > 0){
                        uint256 fee = LibMarket.serviceFee(price);
                        uint256 withFee = price - fee;

                        LibReflection._reflectDividend(fee);
                        seller.transfer(withFee);
                    }else{
                        seller.transfer(price);
                    }
                }
                for(uint256 j = 0; j < pixelsGroup.length; j++){
                    emit MarketBuy(pixelsGroup[j], price / pixelsGroup.length);
                }
            }
        }
    }
}