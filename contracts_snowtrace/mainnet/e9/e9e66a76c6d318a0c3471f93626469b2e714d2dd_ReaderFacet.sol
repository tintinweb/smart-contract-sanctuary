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


// File contracts/libraries/DateTime.sol



pragma solidity ^0.8.0;

library DateTime {
    /*
     *  Date and Time utilities for ethereum contracts
     *
     */
    struct _DateTime {
        uint16 year;
        uint8 month;
        uint8 day;
        uint8 hour;
        uint8 minute;
        uint8 second;
        uint8 weekday;
    }

    uint constant DAY_IN_SECONDS = 86400;
    uint constant YEAR_IN_SECONDS = 31536000;
    uint constant LEAP_YEAR_IN_SECONDS = 31622400;

    uint constant HOUR_IN_SECONDS = 3600;
    uint constant MINUTE_IN_SECONDS = 60;

    uint16 constant ORIGIN_YEAR = 1970;

    function isLeapYear(uint16 year) internal pure returns (bool) {
        if (year % 4 != 0) {
            return false;
        }
        if (year % 100 != 0) {
            return true;
        }
        if (year % 400 != 0) {
            return false;
        }
        return true;
    }

    function leapYearsBefore(uint year) internal pure returns (uint) {
        year -= 1;
        return year / 4 - year / 100 + year / 400;
    }

    function getDaysInMonth(uint8 month, uint16 year) internal pure returns (uint8) {
        if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
            return 31;
        }
        else if (month == 4 || month == 6 || month == 9 || month == 11) {
            return 30;
        }
        else if (isLeapYear(year)) {
            return 29;
        }
        else {
            return 28;
        }
    }

    function parseTimestamp(uint timestamp) internal pure returns (_DateTime memory dt) {
        uint secondsAccountedFor = 0;
        uint buf;
        uint8 i;

        // Year
        dt.year = getYear(timestamp);
        buf = leapYearsBefore(dt.year) - leapYearsBefore(ORIGIN_YEAR);

        secondsAccountedFor += LEAP_YEAR_IN_SECONDS * buf;
        secondsAccountedFor += YEAR_IN_SECONDS * (dt.year - ORIGIN_YEAR - buf);

        // Month
        uint secondsInMonth;
        for (i = 1; i <= 12; i++) {
            secondsInMonth = DAY_IN_SECONDS * getDaysInMonth(i, dt.year);
            if (secondsInMonth + secondsAccountedFor > timestamp) {
                dt.month = i;
                break;
            }
            secondsAccountedFor += secondsInMonth;
        }

        // Day
        for (i = 1; i <= getDaysInMonth(dt.month, dt.year); i++) {
            if (DAY_IN_SECONDS + secondsAccountedFor > timestamp) {
                dt.day = i;
                break;
            }
            secondsAccountedFor += DAY_IN_SECONDS;
        }

        // Hour
        dt.hour = getHour(timestamp);

        // Minute
        dt.minute = getMinute(timestamp);

        // Second
        dt.second = getSecond(timestamp);

        // Day of week.
        dt.weekday = getWeekday(timestamp);
        return dt;
    }

    function getYear(uint timestamp) internal pure returns (uint16) {
        uint secondsAccountedFor = 0;
        uint16 year;
        uint numLeapYears;

        // Year
        year = uint16(ORIGIN_YEAR + timestamp / YEAR_IN_SECONDS);
        numLeapYears = leapYearsBefore(year) - leapYearsBefore(ORIGIN_YEAR);

        secondsAccountedFor += LEAP_YEAR_IN_SECONDS * numLeapYears;
        secondsAccountedFor += YEAR_IN_SECONDS * (year - ORIGIN_YEAR - numLeapYears);

        while (secondsAccountedFor > timestamp) {
            if (isLeapYear(uint16(year - 1))) {
                secondsAccountedFor -= LEAP_YEAR_IN_SECONDS;
            }
            else {
                secondsAccountedFor -= YEAR_IN_SECONDS;
            }
            year -= 1;
        }
        return year;
    }

    function getMonth(uint timestamp) internal pure returns (uint8) {
        return parseTimestamp(timestamp).month;
    }

    function getDay(uint timestamp) internal pure returns (uint8) {
        return parseTimestamp(timestamp).day;
    }

    function getHour(uint timestamp) internal pure returns (uint8) {
        return uint8((timestamp / 60 / 60) % 24);
    }

    function getMinute(uint timestamp) internal pure returns (uint8) {
        return uint8((timestamp / 60) % 60);
    }

    function getSecond(uint timestamp) internal pure returns (uint8) {
        return uint8(timestamp % 60);
    }

    function getWeekday(uint timestamp) internal pure returns (uint8) {
        return uint8((timestamp / DAY_IN_SECONDS + 4) % 7);
    }

    function toTimestamp(uint16 year, uint8 month, uint8 day) internal pure returns (uint timestamp) {
        return toTimestamp(year, month, day, 0, 0, 0);
    }

    function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour) internal pure returns (uint timestamp) {
        return toTimestamp(year, month, day, hour, 0, 0);
    }

    function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour, uint8 minute) internal pure returns (uint timestamp) {
        return toTimestamp(year, month, day, hour, minute, 0);
    }

    function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour, uint8 minute, uint8 second) internal pure returns (uint timestamp) {
        uint16 i;

        // Year
        for (i = ORIGIN_YEAR; i < year; i++) {
            if (isLeapYear(i)) {
                timestamp += LEAP_YEAR_IN_SECONDS;
            }
            else {
                timestamp += YEAR_IN_SECONDS;
            }
        }

        // Month
        uint8[12] memory monthDayCounts;
        monthDayCounts[0] = 31;
        if (isLeapYear(year)) {
            monthDayCounts[1] = 29;
        }
        else {
            monthDayCounts[1] = 28;
        }
        monthDayCounts[2] = 31;
        monthDayCounts[3] = 30;
        monthDayCounts[4] = 31;
        monthDayCounts[5] = 30;
        monthDayCounts[6] = 31;
        monthDayCounts[7] = 31;
        monthDayCounts[8] = 30;
        monthDayCounts[9] = 31;
        monthDayCounts[10] = 30;
        monthDayCounts[11] = 31;

        for (i = 1; i < month; i++) {
            timestamp += DAY_IN_SECONDS * monthDayCounts[i - 1];
        }

        // Day
        timestamp += DAY_IN_SECONDS * (day - 1);

        // Hour
        timestamp += HOUR_IN_SECONDS * (hour);

        // Minute
        timestamp += MINUTE_IN_SECONDS * (minute);

        // Second
        timestamp += second;

        return timestamp;
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


// File contracts/libraries/LibRent.sol


pragma solidity ^0.8.0;
library LibRent {
    function checkTimeInputs(IRentablePixel.RentTimeInput memory startTime, IRentablePixel.RentTimeInput memory endTime) internal pure returns(uint256, uint256){
        require(startTime.hour == 0 && startTime.minute == 0 && startTime.second == 0 && endTime.hour == 0 && endTime.minute == 0 && endTime.second == 0, "Time input is wrong-1");
        require(startTime.month > 0 && startTime.month <= 12 && startTime.day > 0 && startTime.day < 32 && startTime.hour < 24 && startTime.minute < 60 && startTime.second < 60 &&
        endTime.month > 0 && endTime.month <= 12 && endTime.day > 0 && endTime.day < 32 && endTime.hour < 24 && endTime.minute < 60 && endTime.second < 60, "Time input is wrong");
        uint256 startTimestampDay = DateTime.toTimestamp(startTime.year, startTime.month, startTime.day, startTime.hour, startTime.minute, startTime.second);
        uint256 endTimestampDay = DateTime.toTimestamp(endTime.year, endTime.month, endTime.day, endTime.hour, endTime.minute, endTime.second);
        return (startTimestampDay, endTimestampDay);
    }

    function _claimableRentFor(uint256 pixelId, uint256 withFee) internal view returns(uint256){
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(s.isRentStarted == 1, "Rent has not started");
        DateTime._DateTime memory _now = DateTime.parseTimestamp(block.timestamp);
        uint256 nowTimestampDay = DateTime.toTimestamp(_now.year, _now.month, _now.day);
        uint256 rentTotal;
        IRentablePixel.RentData[] storage rentData = s.RentStorage[pixelId];
        for (uint256 j = 0; j < rentData.length ; j++) {
            if(nowTimestampDay > rentData[j].startTimestamp && rentData[j].tenant != address(0)){
                uint256 maxTimeStamp = nowTimestampDay;
                if(nowTimestampDay > rentData[j].endTimestamp){
                    maxTimeStamp = rentData[j].endTimestamp;
                }
                uint256 dayDifference = LibRent.toDayDifference(rentData[j].startTimestamp, maxTimeStamp) - rentData[j].rentCollectedDays;
                if(dayDifference > 0){
                    uint256 cost = LibRent.calculateRentCost(rentData[j], rentData[j].startTimestamp, rentData[j].endTimestamp);
                    rentTotal += cost * dayDifference / LibRent.toDayDifference(rentData[j].startTimestamp, rentData[j].endTimestamp);
                }
            }
        }
        if(withFee > 0){
            return rentTotal;
        }else{
            uint256 fee = LibMarket.serviceFee(rentTotal);
            return rentTotal - fee;
        }
    }

    function claimRentCore(uint256[] memory pixelIds, address owner) internal returns(uint256){
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(s.isRentStarted == 1, "Rent has not started");
        DateTime._DateTime memory _now = DateTime.parseTimestamp(block.timestamp);
        uint256 nowTimestampDay =DateTime.toTimestamp(_now.year, _now.month, _now.day);
        uint256 rentTotal;
        for (uint256 i = 0; i < pixelIds.length ; i++) {
            uint256 index = pixelIds[i];
            IRentablePixel.RentData[] storage rentData = s.RentStorage[index];
            for (uint256 j = 0; j < rentData.length ; j++) {
                if(nowTimestampDay > rentData[j].startTimestamp && rentData[j].tenant != address(0)){
                    uint256 maxTimeStamp = nowTimestampDay;
                    if(nowTimestampDay > rentData[j].endTimestamp){
                        maxTimeStamp = rentData[j].endTimestamp;
                    }
                    uint256 dayDifference = LibRent.toDayDifference(rentData[j].startTimestamp, maxTimeStamp) - rentData[j].rentCollectedDays;
                    if(dayDifference > 0){
                        uint256 cost = LibRent.calculateRentCost(rentData[j], rentData[j].startTimestamp, rentData[j].endTimestamp);
                        uint256 currentRent = cost * dayDifference / LibRent.toDayDifference(rentData[j].startTimestamp, rentData[j].endTimestamp);
                        rentTotal += currentRent;
                        rentData[j].rentCollectedDays += uint16(dayDifference);
                        require(s.totalLockedValueByAddress[rentData[j].tenant] >= currentRent, "Rent is not refundable");
                        s.totalLockedValueByAddress[rentData[j].tenant] -= currentRent;
                    }
                }
            }
        }
        if(rentTotal > 0){
            require(s.totalLockedValue >= rentTotal, "Locked value is low then expected");
            s.totalLockedValue -= rentTotal;
            uint256 fee = LibMarket.serviceFee(rentTotal);
            LibReflection._reflectDividend(fee);
            payable(owner).transfer(rentTotal - fee);
            return rentTotal - fee;
        }
        return 0;
    }

    function calculateRentCost(IRentablePixel.RentData memory data, uint256 startTimestamp, uint256 endTimestamp) internal pure returns(uint256){
        uint256 discount = 0;
        if(endTimestamp - startTimestamp > AppConstants.dayInSeconds * 365){
            discount = data.yearlyDiscount;
        }else if(endTimestamp - startTimestamp > AppConstants.dayInSeconds * 30){
            discount = data.monthlyDiscount;
        }else if(endTimestamp - startTimestamp > AppConstants.dayInSeconds * 7){
            discount = data.weeklyDiscount;
        }
        uint256 dayDifference = (endTimestamp - startTimestamp) / (AppConstants.dayInSeconds);

        return data.dailyPrice * dayDifference * (1000 - discount) / 1000;
    }

    function toDayDifference(uint256 startTimestamp, uint256 endTimestamp) internal pure returns(uint256){
        return (endTimestamp - startTimestamp) / AppConstants.dayInSeconds;
    }
}


// File contracts/interfaces/IERC173.sol


pragma solidity ^0.8.0;

/// @title ERC-173 Contract Ownership Standard
///  Note: the ERC-165 identifier for this interface is 0x7f5828d0
/* is ERC165 */
interface IERC173 {
    /// @dev This emits when ownership of a contract changes.
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice Get the address of the owner
    /// @return owner_ The address of the owner.
    function owner() external view returns (address owner_);

    /// @notice Set the address of the new owner of the contract
    /// @dev Set _newOwner to address(0) to renounce any ownership.
    /// @param _newOwner The address of the new owner of the contract
    function transferOwnership(address _newOwner) external;
}


// File contracts/facets/ReaderFacet.sol


pragma solidity ^0.8.0;
contract ReaderFacet is IERC173, ReentrancyGuard {
    AppStorage internal s;

    function init() external {
        LibDiamond.enforceIsContractOwner();
        s.feeReceiver = payable(LibDiamond.contractOwner());
        s.feePercentage = 50;
        s.baseUri = "ipfs://QmbHmTshtpK3c9GfZkQkBjHbCGxPk7RkS6iviyJJjTEdjH/";
        s._name = "Bitpixels for Avax";
        s._symbol = "BITPIXELS";
        s.limitMinDaysToRent = 30;
        s.limitMaxDaysToRent = 30;
        s.limitMinDaysBeforeRentCancel = 10;
        s.limitMaxDaysForRent = 90;
        s._status = AppConstants._NOT_ENTERED;
        s.reflectionPercentage = 500;
    }


    function name() public view virtual returns (string memory) {
        return s._name;
    }

    function symbol() public view virtual returns (string memory) {
        return s._symbol;
    }

    function getRentData(uint256 pixelId) public view returns(IRentablePixel.RentData[] memory){
        return s.RentStorage[pixelId];
    }

    function getTotalLockedValue() public view returns(uint256){
        return s.totalLockedValue;
    }

    function getTotalLockedValueByAddress(address _addr) public view returns(uint256){
        return s.totalLockedValueByAddress[_addr];
    }

    function getCreatorBalance() public view returns(uint256){
        return s.creatorBalance;
    }

    function getSaleStarted() public view returns(uint256){
        return s.isSaleStarted;
    }

    function getRentStarted() public view returns(uint256){
        return s.isRentStarted;
    }

    function getMarketStarted() public view returns(uint256){
        return s.isMarketStarted;
    }

    function flipSale() public {
        LibDiamond.enforceIsContractOwner();
        s.isSaleStarted = 1 - s.isSaleStarted;
    }

    function flipMarket() public {
        LibDiamond.enforceIsContractOwner();
        s.isMarketStarted = 1 - s.isMarketStarted;
    }

    function flipRent() public {
        LibDiamond.enforceIsContractOwner();
        s.isRentStarted = 1 - s.isRentStarted;
    }

    function getMinDaysToRent() public view returns(uint256){
        return s.limitMinDaysToRent;
    }

    function setMinDaysToRent(uint32 value) public {
        LibDiamond.enforceIsContractOwner();
        s.limitMinDaysToRent = value;
    }

    function getMaxDaysToRent() public view returns(uint256){
        return s.limitMaxDaysToRent;
    }

    function setMaxDaysToRent(uint32 value) public {
        LibDiamond.enforceIsContractOwner();
        s.limitMaxDaysToRent = value;
    }

    function getMinDaysBeforeRentCancel() public view returns(uint256){
        return s.limitMinDaysBeforeRentCancel;
    }

    function setMinDaysBeforeRentCancel(uint32 value) public {
        LibDiamond.enforceIsContractOwner();
        s.limitMinDaysBeforeRentCancel = value;
    }

    function getMaxDaysForRent() public view returns(uint256){
        return s.limitMaxDaysForRent;
    }

    function setMaxDaysForRent(uint32 value) public {
        LibDiamond.enforceIsContractOwner();
        s.limitMaxDaysForRent = value;
    }

    function getReflectionPercentage() public view returns(uint256){
        return s.reflectionPercentage;
    }

    function setReflectionPercentage(uint32 value) public {
        LibDiamond.enforceIsContractOwner();
        s.reflectionPercentage = value;
    }

    function claimableRent(address _address) external view returns(uint256){
        require(s.isRentStarted == 1, "Rent has not started");
        uint256[] memory pixelIds = LibERC721._tokensOfOwner(_address);
        uint256 rentTotal;
        for (uint256 i = 0; i < pixelIds.length ; i++) {
            rentTotal += LibRent._claimableRentFor(pixelIds[i], 0);
        }
        return rentTotal;
    }

    function claimableRentFor(uint256 pixelId) external view returns(uint256){
        require(s.isRentStarted == 1, "Rent has not started");
        return LibRent._claimableRentFor(pixelId, 0);
    }

    function transferOwnership(address _newOwner) external override {
        LibDiamond.enforceIsContractOwner();
        LibDiamond.setContractOwner(_newOwner);
    }

    function owner() external override view returns (address owner_) {
        owner_ = LibDiamond.contractOwner();
    }

    function getReflectionBalance() public view returns(uint256){
        return s.reflectionBalance;
    }

    function getTotalDividend() public view returns(uint256){
        return s.totalDividend;
    }

    function getLastDividendAt(uint256 tokenId) public view returns(uint256){
        return s.lastDividendAt[tokenId];
    }

    function getCurrentReflectionBalance() public view returns(uint256){
        return s.currentReflectionBalance;
    }

    function getReflectionBalances(address user) external view returns(uint256) {
        uint256 total = 0;
        uint256[] memory ownedPixels = LibERC721._tokensOfOwner(user);
        for(uint256 i = 0; i < ownedPixels.length; i++){
            uint256 pixelIndex = ownedPixels[i];
            total += LibReflection._getReflectionBalance(pixelIndex);
        }
        return total;
    }

    function claimRewards() external nonReentrant {
        uint256[] memory ownedPixels = LibERC721._tokensOfOwner(LibMeta.msgSender());
        uint256 total;
        uint256 count;
        for(uint256 i= 0; i < ownedPixels.length; i++){
            uint256 pixelIndex = ownedPixels[i];
            uint256 reward = LibReflection._claimRewardInternal(pixelIndex, 1);
            if(reward > 0){
                count += 1;
                total += reward;
            }
            if(count > 100){
                break;
            }
        }
        if(total > 0){
            s.currentReflectionBalance -= total;
            payable(LibMeta.msgSender()).transfer(total);
        }
    }

    function claimRent() external nonReentrant{
        require(s.isRentStarted == 1, "1");//Rent has not started
        LibRent.claimRentCore(LibERC721._tokensOfOwner(LibMeta.msgSender()), LibMeta.msgSender());
    }

    function withdraw() public {
        LibDiamond.enforceIsContractOwner();
        payable(LibMeta.msgSender()).transfer(address(this).balance);
    }

    function withdrawAmount(uint amount) public{
        LibDiamond.enforceIsContractOwner();
        payable(LibMeta.msgSender()).transfer(amount);
    }

    function tokensOfOwner(address _owner) public view returns(uint256[] memory ) {
        return LibERC721._tokensOfOwner(_owner);
    }
}