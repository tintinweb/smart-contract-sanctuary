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

    constructor() public {
        owner = msg.sender;
    }

    function setRemote(address adr) public {
        require(owner == msg.sender, "NOT_OWNER");
        remote = adr;
    }
}

// SPDX-License-Keyentifier: MIT
pragma solidity >=0.5.17 <0.9.0;
pragma experimental ABIEncoderV2;

import "./interfaces/IProvider.sol";
import "./Owned.sol";

contract Provider is IProvider, Owned {
    uint256 counter = 0;

    struct ProviderInternalStruct {
        address owner;
        uint256 providerListPointer; // needed to delete a "Provider"
        bytes32[] unitKeys;
        mapping(bytes32 => uint256) unitKeyPointers;
        //custom data
        string name;
    }

    mapping(bytes32 => ProviderInternalStruct) public providerStructs;
    bytes32[] public providerList;

    constructor() public {}

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
        }
        return array;
    }

    function createProvider(address sender, string calldata name)
        external
        returns (ProviderStruct memory)
    {
        require(remote == msg.sender, "NOT_REMOTE_CALL");

        return createProvider(sender, bytes32(counter++), name);
    }

    function createProvider(
        address sender,
        bytes32 providerKey,
        string memory name
    ) internal returns (ProviderStruct memory) {
        require(!isProvider(providerKey), "DUPLICATE_PROVIDER_KEY"); // duplicate key prohibited
        providerList.push(providerKey);
        providerStructs[providerKey].providerListPointer =
            providerList.length -
            1;
        providerStructs[providerKey].name = name;
        providerStructs[providerKey].owner = sender;

        return
            ProviderStruct(
                providerStructs[providerKey].owner,
                providerKey,
                providerStructs[providerKey].unitKeys,
                providerStructs[providerKey].name
            );
    }

    function deleteProvider(address sender, bytes32 providerKey)
        external
        returns (bytes32)
    {
        require(isProvider(providerKey), "PROVIDER_DOES_NOT_EXIST");
        require(
            isProviderOwner(sender, providerKey),
            "NOT_OWNER_DELETE_PROVIDER"
        );
        // the following would break referential integrity
        require(
            providerStructs[providerKey].unitKeys.length <= 0,
            "LENGTH_UNIT_KEYS_GREATER_THAN_ZERO"
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
    ) public {
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
    ) public {
        require(isProviderOwner(sender, providerKey), "NOT_OWNER_REMOVE_UNIT");
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
}

// SPDX-License-Keyentifier: MIT
pragma solidity >=0.5.17 <0.9.0;
pragma experimental ABIEncoderV2;

import "./interfaces/IUnit.sol";

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

    mapping(bytes32 => UnitInternalStruct) public unitStructs;
    bytes32[] public unitList;

    constructor(address adr) public {
        provider = Provider(adr);
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
            provider.isProviderOwner(sender, unitStructs[unitKey].providerKey), "SENDER_IS_NOT_OWNER"
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

    function createUnit(
        address sender,
        bytes32 providerKey,
        uint16 guestCount
    ) external returns (UnitStruct memory) {
        return createUnit(sender, bytes32(counter++), providerKey, guestCount);
    }

    function createUnit(
        address sender,
        bytes32 unitKey,
        bytes32 providerKey,
        uint16 guestCount
    ) public returns (UnitStruct memory) {
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
pragma solidity 0.5.17;

interface IOwner {
    function setRemote(address adr) external;
}

// SPDX-License-Keyentifier: MIT
pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

interface IProvider {
    struct ProviderStruct {
        address owner;
        bytes32 providerKey;
        bytes32[] unitKeys;
        string name;
    }

    function isProviderOwner(address sender, bytes32 providerKey)
        external
        view
        returns (bool);

    function getAllProviders() external view returns (ProviderStruct[] memory);

    function createProvider(address sender, string calldata name)
        external
        returns (ProviderStruct memory);

    function deleteProvider(address sender, bytes32 providerKey) external returns (bytes32);
}

// SPDX-License-Keyentifier: MIT
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

