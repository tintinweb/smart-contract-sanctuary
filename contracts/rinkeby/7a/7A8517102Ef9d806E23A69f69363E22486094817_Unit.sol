// SPDX-License-Identifier: MIT

pragma solidity >=0.5.17 <0.9.0;
pragma experimental ABIEncoderV2;

import "./datetime/contracts/api.sol";
import "./datetime/contracts/DateTime.sol";

contract BuissnesHourManager {
    enum WeekDayType {
        monday,
        tuesday,
        wednesday,
        thursday,
        friday,
        saturday,
        sunday
    }
    WeekDayType public types;

    struct BuissnesDay {
        WeekDayType weekday;
        uint8 startHour;
        uint8 endHour;
    }

    DateTimeAPI internal dateTime;
    mapping(bytes32 => BuissnesDay[7]) internal buissnesDays;

    constructor() public {
        dateTime = new DateTime();
    }

    function setBuissnesHours(
        bytes32 key,
        uint8 weekDayType,
        uint8 startHour,
        uint8 endHour
    ) internal {
        require(
            weekDayType <= uint8(WeekDayType.sunday),
            "WRONG_WEEKDAY_INPUT"
        );
        require(startHour < 24, "START_HOURS_OUT_OF_BOUNDS");
        require(endHour < 24, "END_HOURS_OUT_OF_BOUNDS");
        buissnesDays[key][weekDayType].startHour = startHour;
        buissnesDays[key][weekDayType].endHour = endHour;
    }

    function getBuissnesHours(bytes32 key, uint8 weekDayType)
        external
        view
        returns (uint8 start, uint8 end)
    {
        require(
            weekDayType <= uint8(WeekDayType.sunday),
            "WRONG_WEEKDAY_INPUT"
        );
        return (
            buissnesDays[key][weekDayType].startHour,
            buissnesDays[key][weekDayType].endHour
        );
    }

    function initializeBuissnesHours(bytes32 key) internal {
        for (uint8 i = 0; i <= uint8(WeekDayType.sunday); i++)
            buissnesDays[key][i] = BuissnesDay(
                WeekDayType(i),
                uint8(0),
                uint8(24)
            );
    }

    function BuissnesHoursToTimeStamp(uint8 hour, uint8 minute)
        external
        view
        returns (uint256 timestamp)
    {
        return dateTime.toTimestamp(0, 0, 0, hour, minute);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.17 <0.9.0;
pragma experimental ABIEncoderV2;

import "./interfaces/unlock/IPublicLock.sol";
import "./interfaces/unlock/IUnlock.sol";

import "./Owned.sol";

contract LockFactory is Owned {
    IUnlock internal unlock;

    mapping(bytes32 => IPublicLock) lockToKey;

    constructor() public {
        unlock = IUnlock(0xD8C88BE5e8EB88E38E6ff5cE186d764676012B0b);
    }

    function setLockAddress(address payable adr, bytes32 key)
        external
        onlyOwner
    {
        lockToKey[key] = IPublicLock(adr);
    }

    function createNewLock(bytes32 key) internal {
        unlock.createLock(
            100,
            address(0),
            100000000000000,
            20,
            "blu",
            bytes12(keccak256(abi.encodePacked(key)))
        );
        IPublicLock lock = IPublicLock(address(uint160((unlock.publicLockAddress()))));
        lockToKey[key] = lock;
    }

    function getKeyPrice(bytes32 key) external view returns (uint256) {
        return lockToKey[key].keyPrice();
    }

    function updateKeyPrice(bytes32 key, uint256 keyPrice) external {
        lockToKey[key].updateKeyPricing(keyPrice, address(0));
    }

    function getLock(bytes32 key) public view returns (IPublicLock) {
        return lockToKey[key];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.17 <0.9.0;

import "./interfaces/IOwner.sol";

contract Owned is IOwner {
    address public owner;
    address public remote;

    modifier onlyOwner() {
        require(
            owner == msg.sender ||
                address(this) == msg.sender ||
                remote == msg.sender,
            "NOT_OWNER needed"
        );
        _;
    }

    modifier checkRemote() {
        require(remote == msg.sender, "NOT_REMOTE_CALL");
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    function setRemote(address adr) public {
        require(owner == msg.sender, "NOT_OWNER");
        remote = adr;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.17 <0.9.0;
pragma experimental ABIEncoderV2;

import "./interfaces/IProvider.sol";
import "./LockFactory.sol";
import "./BuissnesHourManager.sol";
import "./datetime/contracts/DateTime.sol";

import "./Owned.sol";

contract Provider is IProvider, LockFactory, BuissnesHourManager {
    uint256 counter = 0;

    struct ProviderInternalStruct {
        address owner;
        uint256 providerListPointer; // needed to delete a "Provider"
        bytes32[] unitKeys;
        mapping(bytes32 => uint256) unitKeyPointers;
        //custom data
        string name;
        uint8 timePerReservation;
    }

    mapping(bytes32 => ProviderInternalStruct) internal providerStructs;
    bytes32[] public providerList;

    function isProvider(bytes32 providerKey) public view returns (bool) {
        if (providerList.length == 0) return false;
        return
            providerList[providerStructs[providerKey].providerListPointer] ==
            providerKey;
    }

    function isProviderOwner(address sender, bytes32 providerKey)
        public
        view
        returns (bool)
    {
        return sender == providerStructs[providerKey].owner;
    }

    function getAllProviders() external view returns (ProviderStruct[] memory) {
        ProviderStruct[] memory array =
            new ProviderStruct[](providerList.length);

        for (uint256 i = 0; i < array.length; i++) {
            array[i].providerKey = providerList[i];
            array[i].name = providerStructs[array[i].providerKey].name;
            array[i].unitKeys = providerStructs[array[i].providerKey].unitKeys;
            array[i].owner = providerStructs[array[i].providerKey].owner;
            array[i].timePerReservation = providerStructs[array[i].providerKey]
                .timePerReservation;
        }
        return array;
    }

    function getTimePerReservation(bytes32 providerKey)
        public
        view
        returns (uint8)
    {
        return providerStructs[providerKey].timePerReservation;
    }

    function renameProvider(
        address sender,
        bytes32 providerKey,
        string calldata newName
    ) external {
        require(
            isProviderOwner(sender, providerKey),
            "NOT_OWNER_OF_PROVIDER_RENAME"
        );
        providerStructs[providerKey].name = newName;
    }

    function createProvider(
        address sender,
        string calldata name,
        uint8 timePerReservation
    ) external checkRemote returns (ProviderStruct memory) {
        return
            createProvider(
                sender,
                bytes32(counter++),
                name,
                timePerReservation
            );
    }

    function createProvider(
        address sender,
        bytes32 providerKey,
        string memory name,
        uint8 timePerReservation
    ) internal returns (ProviderStruct memory) {
        require(!isProvider(providerKey), "DUPLICATE_PROVIDER_KEY"); // duplicate key prohibited
        createNewLock(providerKey);
        providerList.push(providerKey);
        providerStructs[providerKey].providerListPointer =
            providerList.length -
            1;
        providerStructs[providerKey].name = name;
        providerStructs[providerKey].owner = sender;
        providerStructs[providerKey].timePerReservation = timePerReservation;

        initializeBuissnesHours(providerKey);
        return
            ProviderStruct(
                providerStructs[providerKey].owner,
                providerKey,
                providerStructs[providerKey].unitKeys,
                providerStructs[providerKey].name,
                providerStructs[providerKey].timePerReservation
            );
    }

    function deleteProvider(address sender, bytes32 providerKey)
        external
        checkRemote
        returns (bytes32)
    {
        //TODO: delete after all refunds are done
        require(isProvider(providerKey), "PROVIDER_DOES_NOT_EXIST_DELETE");
        require(
            isProviderOwner(sender, providerKey),
            "NOT_OWNER_DELETE_PROVIDER_DELETE"
        );
        // the following would break referential integrity
        require(
            providerStructs[providerKey].unitKeys.length <= 0,
            "LENGTH_UNIT_KEYS_GREATER_THAN_ZERO_DELETE"
        );
        uint256 rowToDelete = providerStructs[providerKey].providerListPointer;
        bytes32 keyToMove = providerList[providerList.length - 1];
        providerList[rowToDelete] = keyToMove;
        providerStructs[keyToMove].providerListPointer = rowToDelete;
        providerList.pop();

        return providerKey;
    }

    function addUnit(
        address sender,
        bytes32 providerKey,
        bytes32 unitKey
    ) public 
    // checkRemote 
    {
        require(isProviderOwner(sender, providerKey), "NOT_OWNER_ADD_UNIT");
        providerStructs[providerKey].unitKeys.push(unitKey);
        providerStructs[providerKey].unitKeyPointers[unitKey] =
            providerStructs[providerKey].unitKeys.length -
            1;
    }

    function removeUnit(
        address sender,
        bytes32 providerKey,
        bytes32 unitKey
    ) public checkRemote {
        require(
            isProviderOwner(sender, providerKey),
            "NOT_OWNER_OF_PROVIDER_REMOVE_UNIT"
        );
        uint256 rowToDelete =
            providerStructs[providerKey].unitKeyPointers[unitKey];
        bytes32 keyToMove =
            providerStructs[providerKey].unitKeys[
                providerStructs[providerKey].unitKeys.length - 1
            ];
        providerStructs[providerKey].unitKeys[rowToDelete] = keyToMove;
        providerStructs[providerKey].unitKeyPointers[keyToMove] = rowToDelete;
        providerStructs[providerKey].unitKeys.pop();
    }

    function setBuissnesHours(
        address sender,
        bytes32 key,
        uint8 weekDayType,
        uint8 startHour,
        uint8 endHour
    ) external checkRemote {
        require(
            isProviderOwner(sender, key),
            "NOT_OWNER_OF_PROVIDER_SET_HOURS"
        );
        super.setBuissnesHours(key, weekDayType, startHour, endHour);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.17 <0.9.0;
pragma experimental ABIEncoderV2;

import "./interfaces/IUnit.sol";
import "./interfaces/unlock/IPublicLock.sol";

import "./Owned.sol";
import "./Provider.sol";

contract Unit is IUnit, Owned {
    uint256 counter;

    struct UnitInternalStruct {
        uint256 unitListPointer;
        bytes32 providerKey;
        bytes32[] reservationKeys;
        mapping(bytes32 => uint256) reservationKeyPointers;
        //custom data
        uint16 guestCount;
    }

    Provider internal provider;

    mapping(bytes32 => UnitInternalStruct) internal unitStructs;
    bytes32[] public unitList;

    constructor(address adr) public {
        provider = Provider(adr);
    }

    function getLock(bytes32 key) public view returns (IPublicLock) {
        return provider.getLock(unitStructs[key].providerKey);
    }

    function setProviderAddress(address adr) external onlyOwner {
        provider = Provider(adr);
    }

    function isUnit(bytes32 unitKey) public view returns (bool) {
        if (unitList.length == 0) return false;
        return unitList[unitStructs[unitKey].unitListPointer] == unitKey;
    }

    function isUnitOwner(address sender, bytes32 unitKey)
        public
        view
        returns (bool)
    {
        require(
            provider.isProviderOwner(sender, unitStructs[unitKey].providerKey),
            "SENDER_IS_NOT_OWNER"
        );

        return true;
    }

    function getAllUnits() external view returns (UnitStruct[] memory) {
        UnitStruct[] memory array = new UnitStruct[](unitList.length);

        for (uint256 i = 0; i < array.length; i++) {
            array[i].unitKey = unitList[i];
            array[i].guestCount = unitStructs[array[i].unitKey].guestCount;
            array[i].providerKey = unitStructs[array[i].unitKey].providerKey;
            array[i].reservationKeys = unitStructs[array[i].unitKey]
                .reservationKeys;
        }
        return array;
    }

    function getTimePerReservation(bytes32 unitKey)
        public
        view
        returns (uint8)
    {
        return provider.getTimePerReservation(unitStructs[unitKey].providerKey);
    }

    function createUnit(
        address sender,
        bytes32 providerKey,
        uint16 guestCount
    ) external checkRemote returns (UnitStruct memory) {
        return createUnit(sender, bytes32(counter++), providerKey, guestCount);
    }

    function createUnit(
        address sender,
        bytes32 unitKey,
        bytes32 providerKey,
        uint16 guestCount
    ) internal returns (UnitStruct memory) {
        require(provider.isProvider(providerKey), "PROVIDER_DOES_NOT_EXIST");
        require(!isUnit(unitKey), "DUPLICATE_UNIT_KEY"); // duplicate key prohibited
        require(guestCount > 0, "GUEST_COUNT_IMPLAUSIBLE");
        require(
            provider.isProviderOwner(sender, providerKey),
            "NOT_OWNER_CREATE_UNIT"
        );

        unitList.push(unitKey);
        unitStructs[unitKey].unitListPointer = unitList.length - 1;
        unitStructs[unitKey].providerKey = providerKey;
        unitStructs[unitKey].guestCount = guestCount;

        provider.addUnit(sender, providerKey, unitKey);

        return
            UnitStruct(
                unitKey,
                unitStructs[unitKey].providerKey,
                unitStructs[unitKey].reservationKeys,
                unitStructs[unitKey].guestCount
            );
    }

    function deleteUnit(address sender, bytes32 unitKey)
        external
        checkRemote
        returns (bytes32)
    {
        require(isUnit(unitKey), "UNIT_DOES_NOT_EXIST");
        require(
            provider.isProviderOwner(sender, unitStructs[unitKey].providerKey),
            "NOT_OWNER_DELETE_UNIT"
        );

        // delete from table
        uint256 rowToDelete = unitStructs[unitKey].unitListPointer;
        bytes32 keyToMove = unitList[unitList.length - 1];
        unitList[rowToDelete] = keyToMove;
        unitStructs[unitKey].unitListPointer = rowToDelete;
        unitList.pop();

        bytes32 providerKey = unitStructs[unitKey].providerKey;
        provider.removeUnit(sender, providerKey, unitKey);
        return unitKey;
    }

    function addReservation(bytes32 unitKey, bytes32 reservationKey) public {
        unitStructs[unitKey].reservationKeys.push(reservationKey);
        unitStructs[unitKey].reservationKeyPointers[reservationKey] =
            unitStructs[unitKey].reservationKeys.length -
            1;
    }

    function removeReservation(bytes32 unitKey, bytes32 reservationKey) public {
        uint256 rowToDelete =
            unitStructs[unitKey].reservationKeyPointers[reservationKey];
        bytes32 keyToMove =
            unitStructs[unitKey].reservationKeys[
                unitStructs[unitKey].reservationKeys.length - 1
            ];
        unitStructs[unitKey].reservationKeys[rowToDelete] = keyToMove;
        unitStructs[unitKey].reservationKeyPointers[keyToMove] = rowToDelete;
        unitStructs[unitKey].reservationKeys.pop();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.5.17;
import "./api.sol";

contract DateTime is DateTimeAPI{
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

        function isLeapYear(uint16 year) public pure returns (bool) {
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

        function leapYearsBefore(uint year) public pure returns (uint) {
                year -= 1;
                return year / 4 - year / 100 + year / 400;
        }

        function getDaysInMonth(uint8 month, uint16 year) public pure returns (uint8) {
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
        }

        function getYear(uint timestamp) public pure returns (uint16) {
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

        function getMonth(uint timestamp) public pure returns (uint8) {
                return parseTimestamp(timestamp).month;
        }

        function getDay(uint timestamp) public pure returns (uint8) {
                return parseTimestamp(timestamp).day;
        }

        function getHour(uint timestamp) public pure returns (uint8) {
                return uint8((timestamp / 60 / 60) % 24);
        }

        function getMinute(uint timestamp) public pure returns (uint8) {
                return uint8((timestamp / 60) % 60);
        }

        function getSecond(uint timestamp) public pure returns (uint8) {
                return uint8(timestamp % 60);
        }

        function getWeekday(uint timestamp) public pure returns (uint8) {
                return uint8((timestamp / DAY_IN_SECONDS + 4) % 7);
        }

        function toTimestamp(uint16 year, uint8 month, uint8 day) public pure returns (uint timestamp) {
                return toTimestamp(year, month, day, 0, 0, 0);
        }

        function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour) public pure returns (uint timestamp) {
                return toTimestamp(year, month, day, hour, 0, 0);
        }

        function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour, uint8 minute) public pure returns (uint timestamp) {
                return toTimestamp(year, month, day, hour, minute, 0);
        }

        function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour, uint8 minute, uint8 second) public pure returns (uint timestamp) {
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

// SPDX-License-Identifier: MIT

pragma solidity 0.5.17;

contract DateTimeAPI {
        /*
         *  Abstract contract for interfacing with the DateTime contract.
         *
         */
        function isLeapYear(uint16 year) public pure returns (bool);
        function getYear(uint timestamp) public pure returns (uint16);
        function getMonth(uint timestamp) public pure returns (uint8);
        function getDay(uint timestamp) public pure returns (uint8);
        function getHour(uint timestamp) public pure returns (uint8);
        function getMinute(uint timestamp) public pure returns (uint8);
        function getSecond(uint timestamp) public pure returns (uint8);
        function getWeekday(uint timestamp) public pure returns (uint8);
        function toTimestamp(uint16 year, uint8 month, uint8 day) public pure returns (uint timestamp);
        function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour) public pure returns (uint timestamp);
        function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour, uint8 minute) public pure returns (uint timestamp);
        function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour, uint8 minute, uint8 second) public pure returns (uint timestamp);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.5.17;

interface IOwner {
    function setRemote(address adr) external;
}

// SPDX-License-Keyentifier: MIT
pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "./unlock/IPublicLock.sol";

interface IProvider {
    struct ProviderStruct {
        address owner;
        bytes32 providerKey;
        bytes32[] unitKeys;
        string name;
        uint8 timePerReservation;
    }

    function isProviderOwner(address sender, bytes32 providerKey)
        external
        view
        returns (bool);

    function getAllProviders() external view returns (ProviderStruct[] memory);

    function renameProvider(
        address sender,
        bytes32 providerKey,
        string calldata newName
    ) external;

    function createProvider(address sender, string calldata name, uint8 timePerReservation)
        external
        returns (ProviderStruct memory);

    function deleteProvider(address sender, bytes32 providerKey)
        external
        returns (bytes32);

    function getKeyPrice(bytes32 key) external view returns (uint256);

    function updateKeyPrice(bytes32 key, uint256 keyPrice) external;

    function getLock(bytes32 key) external view returns (IPublicLock);

    function setBuissnesHours(
        address sender,
        bytes32 key,
        uint8 weekDayType,
        uint8 startHour,
        uint8 endHour
    ) external;

    function getBuissnesHours(bytes32 key, uint8 weekDayType)
        external
        view
        returns (uint8 start, uint8 end);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "./IOwner.sol";

interface IUnit {
    struct UnitStruct {
        bytes32 unitKey;
        bytes32 providerKey;
        bytes32[] reservationKeys;
        uint16 guestCount;
    }

    function setProviderAddress(address adr) external;

    function isUnitOwner(address sender, bytes32 unitKey)
        external
        view
        returns (bool);

    function getAllUnits() external view returns (UnitStruct[] memory);

    function createUnit(
        address sender,
        bytes32 providerKey,
        uint16 guestCount
    ) external returns (UnitStruct memory);

    function deleteUnit(address sender, bytes32 unitKey)
        external
        returns (bytes32);
}

pragma solidity 0.5.17;

/**
 * @title The PublicLock Interface
 * @author Nick Furfaro (unlock-protocol.com)
 */

contract IPublicLock {
    // See indentationissue description here:
    // https://github.com/duaraghav8/Ethlint/issues/268
    // solium-disable indentation

    /// Functions

    function initialize(
        address _lockCreator,
        uint256 _expirationDuration,
        address _tokenAddress,
        uint256 _keyPrice,
        uint256 _maxNumberOfKeys,
        string calldata _lockName
    ) external;

    /**
     * @notice Allow the contract to accept tips in ETH sent directly to the contract.
     * @dev This is okay to use even if the lock is priced in ERC-20 tokens
     */
    function() external payable;

    /**
     * @dev Never used directly
     */
    function initialize() external;

    /**
     * @notice The version number of the current implementation on this network.
     * @return The current version number.
     */
    function publicLockVersion() public pure returns (uint256);

    /**
     * @notice Gets the current balance of the account provided.
     * @param _tokenAddress The token type to retrieve the balance of.
     * @param _account The account to get the balance of.
     * @return The number of tokens of the given type for the given address, possibly 0.
     */
    function getBalance(address _tokenAddress, address _account)
        external
        view
        returns (uint256);

    /**
     * @notice Used to disable lock before migrating keys and/or destroying contract.
     * @dev Throws if called by other than a lock manager.
     * @dev Throws if lock contract has already been disabled.
     */
    function disableLock() external;

    /**
     * @dev Called by a lock manager or beneficiary to withdraw all funds from the lock and send them to the `beneficiary`.
     * @dev Throws if called by other than a lock manager or beneficiary
     * @param _tokenAddress specifies the token address to withdraw or 0 for ETH. This is usually
     * the same as `tokenAddress` in MixinFunds.
     * @param _amount specifies the max amount to withdraw, which may be reduced when
     * considering the available balance. Set to 0 or MAX_UINT to withdraw everything.
     *  -- however be wary of draining funds as it breaks the `cancelAndRefund` and `expireAndRefundFor`
     * use cases.
     */
    function withdraw(address _tokenAddress, uint256 _amount) external;

    /**
     * @notice An ERC-20 style approval, allowing the spender to transfer funds directly from this lock.
     */
    function approveBeneficiary(address _spender, uint256 _amount)
        external
        returns (bool);

    /**
     * A function which lets a Lock manager of the lock to change the price for future purchases.
     * @dev Throws if called by other than a Lock manager
     * @dev Throws if lock has been disabled
     * @dev Throws if _tokenAddress is not a valid token
     * @param _keyPrice The new price to set for keys
     * @param _tokenAddress The address of the erc20 token to use for pricing the keys,
     * or 0 to use ETH
     */
    function updateKeyPricing(uint256 _keyPrice, address _tokenAddress)
        external;

    /**
     * A function which lets a Lock manager update the beneficiary account,
     * which receives funds on withdrawal.
     * @dev Throws if called by other than a Lock manager or beneficiary
     * @dev Throws if _beneficiary is address(0)
     * @param _beneficiary The new address to set as the beneficiary
     */
    function updateBeneficiary(address _beneficiary) external;

    /**
     * Checks if the user has a non-expired key.
     * @param _user The address of the key owner
     */
    function getHasValidKey(address _user) external view returns (bool);

    /**
     * @notice Find the tokenId for a given user
     * @return The tokenId of the NFT, else returns 0
     * @param _account The address of the key owner
     */
    function getTokenIdFor(address _account) external view returns (uint256);

    /**
     * A function which returns a subset of the keys for this Lock as an array
     * @param _page the page of key owners requested when faceted by page size
     * @param _pageSize the number of Key Owners requested per page
     * @dev Throws if there are no key owners yet
     */
    function getOwnersByPage(uint256 _page, uint256 _pageSize)
        external
        view
        returns (address[] memory);

    /**
     * Checks if the given address owns the given tokenId.
     * @param _tokenId The tokenId of the key to check
     * @param _keyOwner The potential key owners address
     */
    function isKeyOwner(uint256 _tokenId, address _keyOwner)
        external
        view
        returns (bool);

    /**
     * @dev Returns the key's ExpirationTimestamp field for a given owner.
     * @param _keyOwner address of the user for whom we search the key
     * @dev Returns 0 if the owner has never owned a key for this lock
     */
    function keyExpirationTimestampFor(address _keyOwner)
        external
        view
        returns (uint256 timestamp);

    /**
     * Public function which returns the total number of unique owners (both expired
     * and valid).  This may be larger than totalSupply.
     */
    function numberOfOwners() external view returns (uint256);

    /**
     * Allows a Lock manager to assign a descriptive name for this Lock.
     * @param _lockName The new name for the lock
     * @dev Throws if called by other than a Lock manager
     */
    function updateLockName(string calldata _lockName) external;

    /**
     * Allows a Lock manager to assign a Symbol for this Lock.
     * @param _lockSymbol The new Symbol for the lock
     * @dev Throws if called by other than a Lock manager
     */
    function updateLockSymbol(string calldata _lockSymbol) external;

    /**
     * @dev Gets the token symbol
     * @return string representing the token symbol
     */
    function symbol() external view returns (string memory);

    /**
     * Allows a Lock manager to update the baseTokenURI for this Lock.
     * @dev Throws if called by other than a Lock manager
     * @param _baseTokenURI String representing the base of the URI for this lock.
     */
    function setBaseTokenURI(string calldata _baseTokenURI) external;

    /**  @notice A distinct Uniform Resource Identifier (URI) for a given asset.
     * @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
     *  3986. The URI may point to a JSON file that conforms to the "ERC721
     *  Metadata JSON Schema".
     * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
     * @param _tokenId The tokenID we're inquiring about
     * @return String representing the URI for the requested token
     */
    function tokenURI(uint256 _tokenId) external view returns (string memory);

    /**
     * @notice Allows a Lock manager to add or remove an event hook
     */
    function setEventHooks(address _onKeyPurchaseHook, address _onKeyCancelHook)
        external;

    /**
     * Allows a Lock manager to give a collection of users a key with no charge.
     * Each key may be assigned a different expiration date.
     * @dev Throws if called by other than a Lock manager
     * @param _recipients An array of receiving addresses
     * @param _expirationTimestamps An array of expiration Timestamps for the keys being granted
     */
    function grantKeys(
        address[] calldata _recipients,
        uint256[] calldata _expirationTimestamps,
        address[] calldata _keyManagers
    ) external;

    /**
     * @dev Purchase function
     * @param _value the number of tokens to pay for this purchase >= the current keyPrice - any applicable discount
     * (_value is ignored when using ETH)
     * @param _recipient address of the recipient of the purchased key
     * @param _referrer address of the user making the referral
     * @param _data arbitrary data populated by the front-end which initiated the sale
     * @dev Throws if lock is disabled. Throws if lock is sold-out. Throws if _recipient == address(0).
     * @dev Setting _value to keyPrice exactly doubles as a security feature. That way if a Lock manager increases the
     * price while my transaction is pending I can't be charged more than I expected (only applicable to ERC-20 when more
     * than keyPrice is approved for spending).
     */
    function purchase(
        uint256 _value,
        address _recipient,
        address _referrer,
        bytes calldata _data
    ) external payable;

    /**
     * @notice returns the minimum price paid for a purchase with these params.
     * @dev this considers any discount from Unlock or the OnKeyPurchase hook.
     */
    function purchasePriceFor(
        address _recipient,
        address _referrer,
        bytes calldata _data
    ) external view returns (uint256);

    /**
     * Allow a Lock manager to change the transfer fee.
     * @dev Throws if called by other than a Lock manager
     * @param _transferFeeBasisPoints The new transfer fee in basis-points(bps).
     * Ex: 200 bps = 2%
     */
    function updateTransferFee(uint256 _transferFeeBasisPoints) external;

    /**
     * Determines how much of a fee a key owner would need to pay in order to
     * transfer the key to another account.  This is pro-rated so the fee goes down
     * overtime.
     * @dev Throws if _keyOwner does not have a valid key
     * @param _keyOwner The owner of the key check the transfer fee for.
     * @param _time The amount of time to calculate the fee for.
     * @return The transfer fee in seconds.
     */
    function getTransferFee(address _keyOwner, uint256 _time)
        external
        view
        returns (uint256);

    /**
     * @dev Invoked by a Lock manager to expire the user's key and perform a refund and cancellation of the key
     * @param _keyOwner The key owner to whom we wish to send a refund to
     * @param amount The amount to refund the key-owner
     * @dev Throws if called by other than a Lock manager
     * @dev Throws if _keyOwner does not have a valid key
     */
    function expireAndRefundFor(address _keyOwner, uint256 amount) external;

    /**
     * @dev allows the key manager to expire a given tokenId
     * and send a refund to the keyOwner based on the amount of time remaining.
     * @param _tokenId The id of the key to cancel.
     */
    function cancelAndRefund(uint256 _tokenId) external;

    /**
     * @dev Cancels a key managed by a different user and sends the funds to the keyOwner.
     * @param _keyManager the key managed by this user will be canceled
     * @param _v _r _s getCancelAndRefundApprovalHash signed by the _keyManager
     * @param _tokenId The key to cancel
     */
    function cancelAndRefundFor(
        address _keyManager,
        uint8 _v,
        bytes32 _r,
        bytes32 _s,
        uint256 _tokenId
    ) external;

    /**
     * @notice Sets the minimum nonce for a valid off-chain approval message from the
     * senders account.
     * @dev This can be used to invalidate a previously signed message.
     */
    function invalidateOffchainApproval(uint256 _nextAvailableNonce) external;

    /**
     * Allow a Lock manager to change the refund penalty.
     * @dev Throws if called by other than a Lock manager
     * @param _freeTrialLength The new duration of free trials for this lock
     * @param _refundPenaltyBasisPoints The new refund penaly in basis-points(bps)
     */
    function updateRefundPenalty(
        uint256 _freeTrialLength,
        uint256 _refundPenaltyBasisPoints
    ) external;

    /**
     * @dev Determines how much of a refund a key owner would receive if they issued
     * @param _keyOwner The key owner to get the refund value for.
     * a cancelAndRefund block.timestamp.
     * Note that due to the time required to mine a tx, the actual refund amount will be lower
     * than what the user reads from this call.
     */
    function getCancelAndRefundValueFor(address _keyOwner)
        external
        view
        returns (uint256 refund);

    function keyManagerToNonce(address) external view returns (uint256);

    /**
     * @notice returns the hash to sign in order to allow another user to cancel on your behalf.
     * @dev this can be computed in JS instead of read from the contract.
     * @param _keyManager The key manager's address (also the message signer)
     * @param _txSender The address cancelling cancel on behalf of the keyOwner
     * @return approvalHash The hash to sign
     */
    function getCancelAndRefundApprovalHash(
        address _keyManager,
        address _txSender
    ) external view returns (bytes32 approvalHash);

    function addKeyGranter(address account) external;

    function addLockManager(address account) external;

    function isKeyGranter(address account) external view returns (bool);

    function isLockManager(address account) external view returns (bool);

    function onKeyPurchaseHook() external view returns (address);

    function onKeyCancelHook() external view returns (address);

    function revokeKeyGranter(address _granter) external;

    function renounceLockManager() external;

    ///===================================================================
    /// Auto-generated getter functions from public state variables

    function beneficiary() external view returns (address);

    function expirationDuration() external view returns (uint256);

    function freeTrialLength() external view returns (uint256);

    function isAlive() external view returns (bool);

    function keyPrice() external view returns (uint256);

    function maxNumberOfKeys() external view returns (uint256);

    function owners(uint256) external view returns (address);

    function refundPenaltyBasisPoints() external view returns (uint256);

    function tokenAddress() external view returns (address);

    function transferFeeBasisPoints() external view returns (uint256);

    function unlockProtocol() external view returns (address);

    function keyManagerOf(uint256) external view returns (address);

    ///===================================================================

    /**
     * @notice Allows the key owner to safely share their key (parent key) by
     * transferring a portion of the remaining time to a new key (child key).
     * @dev Throws if key is not valid.
     * @dev Throws if `_to` is the zero address
     * @param _to The recipient of the shared key
     * @param _tokenId the key to share
     * @param _timeShared The amount of time shared
     * checks if `_to` is a smart contract (code size > 0). If so, it calls
     * `onERC721Received` on `_to` and throws if the return value is not
     * `bytes4(keccak256('onERC721Received(address,address,uint,bytes)'))`.
     * @dev Emit Transfer event
     */
    function shareKey(
        address _to,
        uint256 _tokenId,
        uint256 _timeShared
    ) external;

    /**
     * @notice Update transfer and cancel rights for a given key
     * @param _tokenId The id of the key to assign rights for
     * @param _keyManager The address to assign the rights to for the given key
     */
    function setKeyManagerOf(uint256 _tokenId, address _keyManager) external;

    /// @notice A descriptive name for a collection of NFTs in this contract
    function name() external view returns (string memory _name);

    ///===================================================================

    /// From ERC165.sol
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    ///===================================================================

    /// From ERC-721
    /**
     * @dev Returns the number of NFTs in `owner`'s account.
     */
    function balanceOf(address _owner) public view returns (uint256 balance);

    /**
     * @dev Returns the owner of the NFT specified by `tokenId`.
     */
    function ownerOf(uint256 tokenId) public view returns (address _owner);

    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     *
     *
     * Requirements:
     * - `from`, `to` cannot be zero.
     * - `tokenId` must be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this
     * NFT by either {approve} or {setApprovalForAll}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public;

    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     * Requirements:
     * - If the caller is not `from`, it must be approved to move this NFT by
     * either {approve} or {setApprovalForAll}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public;

    function approve(address to, uint256 tokenId) public;

    /**
     * @notice Get the approved address for a single NFT
     * @dev Throws if `_tokenId` is not a valid NFT.
     * @param _tokenId The NFT to find the approved address for
     * @return The approved address for this NFT, or the zero address if there is none
     */
    function getApproved(uint256 _tokenId)
        public
        view
        returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public;

    function isApprovedForAll(address _owner, address operator)
        public
        view
        returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public;

    function totalSupply() public view returns (uint256);

    function tokenOfOwnerByIndex(address _owner, uint256 index)
        public
        view
        returns (uint256 tokenId);

    function tokenByIndex(uint256 index) public view returns (uint256);

    /**
     * @notice An ERC-20 style transfer.
     * @param _value sends a token with _value * expirationDuration (the amount of time remaining on a standard purchase).
     * @dev The typical use case would be to call this with _value 1, which is on par with calling `transferFrom`. If the user
     * has more than `expirationDuration` time remaining this may use the `shareKey` function to send some but not all of the token.
     */
    function transfer(address _to, uint256 _value)
        external
        returns (bool success);
}

pragma solidity 0.5.17;


/**
 * @title The Unlock Interface
 * @author Nick Furfaro (unlock-protocol.com)
**/

interface IUnlock
{
  // Use initialize instead of a constructor to support proxies(for upgradeability via zos).
  function initialize(address _unlockOwner) external;

  /**
  * @dev Create lock
  * This deploys a lock for a creator. It also keeps track of the deployed lock.
  * @param _tokenAddress set to the ERC20 token address, or 0 for ETH.
  * @param _salt an identifier for the Lock, which is unique for the user.
  * This may be implemented as a sequence ID or with RNG. It's used with `create2`
  * to know the lock's address before the transaction is mined.
  */
  function createLock(
    uint _expirationDuration,
    address _tokenAddress,
    uint _keyPrice,
    uint _maxNumberOfKeys,
    string calldata _lockName,
    bytes12 _salt
  ) external;

    /**
   * This function keeps track of the added GDP, as well as grants of discount tokens
   * to the referrer, if applicable.
   * The number of discount tokens granted is based on the value of the referal,
   * the current growth rate and the lock's discount token distribution rate
   * This function is invoked by a previously deployed lock only.
   */
  function recordKeyPurchase(
    uint _value,
    address _referrer // solhint-disable-line no-unused-vars
  )
    external;

    /**
   * This function will keep track of consumed discounts by a given user.
   * It will also grant discount tokens to the creator who is granting the discount based on the
   * amount of discount and compensation rate.
   * This function is invoked by a previously deployed lock only.
   */
  function recordConsumedDiscount(
    uint _discount,
    uint _tokens // solhint-disable-line no-unused-vars
  )
    external;

    /**
   * This function returns the discount available for a user, when purchasing a
   * a key from a lock.
   * This does not modify the state. It returns both the discount and the number of tokens
   * consumed to grant that discount.
   */
  function computeAvailableDiscountFor(
    address _purchaser, // solhint-disable-line no-unused-vars
    uint _keyPrice // solhint-disable-line no-unused-vars
  )
    external
    view
    returns(uint discount, uint tokens);

  // Function to read the globalTokenURI field.
  function globalBaseTokenURI()
    external
    view
    returns(string memory);

  /**
   * @dev Redundant with globalBaseTokenURI() for backwards compatibility with v3 & v4 locks.
   */
  function getGlobalBaseTokenURI()
    external
    view
    returns (string memory);

  // Function to read the globalTokenSymbol field.
  function globalTokenSymbol()
    external
    view
    returns(string memory);

  // Function to read the chainId field.
  function chainId()
    external
    view
    returns(uint);

  /**
   * @dev Redundant with globalTokenSymbol() for backwards compatibility with v3 & v4 locks.
   */
  function getGlobalTokenSymbol()
    external
    view
    returns (string memory);

  /**
   * @notice Allows the owner to update configuration variables
   */
  function configUnlock(
    address _udt,
    address _weth,
    uint _estimatedGasForPurchase,
    string calldata _symbol,
    string calldata _URI,
    uint _chainId
  )
    external;

  /**
   * @notice Upgrade the PublicLock template used for future calls to `createLock`.
   * @dev This will initialize the template and revokeOwnership.
   */
  function setLockTemplate(
    address payable _publicLockAddress
  ) external;

  // Allows the owner to change the value tracking variables as needed.
  function resetTrackedValue(
    uint _grossNetworkProduct,
    uint _totalDiscountGranted
  ) external;

  function grossNetworkProduct() external view returns(uint);

  function totalDiscountGranted() external view returns(uint);

  function locks(address) external view returns(bool deployed, uint totalSales, uint yieldedDiscountTokens);

  // The address of the public lock template, used when `createLock` is called
  function publicLockAddress() external view returns(address);

  // Map token address to exchange contract address if the token is supported
  // Used for GDP calculations
  function uniswapOracles(address) external view returns(address);

  // The WETH token address, used for value calculations
  function weth() external view returns(address);

  // The UDT token address, used to mint tokens on referral
  function udt() external view returns(address);

  // The approx amount of gas required to purchase a key
  function estimatedGasForPurchase() external view returns(uint);

  // The version number of the current Unlock implementation on this network
  function unlockVersion() external pure returns(uint16);

  /**
   * @notice allows the owner to set the oracle address to use for value conversions
   * setting the _oracleAddress to address(0) removes support for the token
   * @dev This will also call update to ensure at least one datapoint has been recorded.
   */
  function setOracle(
    address _tokenAddress,
    address _oracleAddress
  ) external;

  /**
   * @dev Returns true if the caller is the current owner.
   */
  function isOwner() external view returns(bool);

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() external view returns(address);

  /**
   * @dev Leaves the contract without owner. It will not be possible to call
   * `onlyOwner` functions anymore. Can only be called by the current owner.
   *
   * NOTE: Renouncing ownership will leave the contract without an owner,
   * thereby removing any functionality that is only available to the owner.
   */
  function renounceOwnership() external;

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) external;
}

