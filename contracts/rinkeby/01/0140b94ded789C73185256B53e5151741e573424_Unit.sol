// SPDX-License-Identifier: MIT
pragma solidity >=0.5.17 <0.9.0;
pragma experimental ABIEncoderV2;

import "./IUnit.sol";

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

    event LogNewUnit(address sender, bytes32 unitId, bytes32 providerId);
    event LogUnitDeleted(address sender, bytes32 unitId);

    Provider internal provider;

    mapping(bytes32 => UnitInternalStruct) public unitStructs;
    bytes32[] public unitList;

    constructor(address adr) public {
        provider = Provider(adr);
    }

    function setProviderAddress(address adr) external onlyOwner {
        provider = Provider(adr);
    }

    function getUnitCount() public view returns (uint256) {
        return unitList.length;
    }

    function isUnit(bytes32 unitId) public view returns (bool) {
        if (unitList.length == 0) return false;
        return unitList[unitStructs[unitId].unitListPointer] == unitId;
    }

    function getAllUnits() external view returns (UnitStruct[] memory) {
        UnitStruct[] memory array = new UnitStruct[](getUnitCount());

        for (uint256 i = 0; i < array.length; i++) {
            array[i].unitId = unitList[i];
            array[i].guestCount = unitStructs[array[i].unitId].guestCount;
            array[i].providerKey = unitStructs[array[i].unitId].providerKey;
            array[i].reservationKeys = unitStructs[array[i].unitId]
                .reservationKeys;
        }
        return array;
    }

    function createUnit(address sender, bytes32 providerId, uint16 guestCount)
        external
        returns (bool)
    {
        require(createUnit(sender, bytes32(counter++), providerId, guestCount));
        return true;
    }

    function createUnit(
        address sender,
        bytes32 unitId,
        bytes32 providerId,
        uint16 guestCount
    ) public returns (bool) {
        require(provider.isProvider(providerId), "PROVIDER_DOES_NOT_EXIST");
        require(!isUnit(unitId), "DUPLICATE_UNIT_KEY"); // duplicate key prohibited
        require(guestCount > 0, "GUEST_COUNT_IMPLAUSIBLE");
        require(provider.isProviderOwner(sender, providerId), "NOT_OWNER_CREATE_UNIT");

        unitList.push(unitId);
        unitStructs[unitId].unitListPointer = unitList.length - 1;
        unitStructs[unitId].providerKey = providerId;
        unitStructs[unitId].guestCount = guestCount;

        provider.addUnit(sender, providerId, unitId);
        emit LogNewUnit(sender, unitId, providerId);
        return true;
    }

    function deleteUnit(address sender, bytes32 unitId) external returns (bool) {
        require(isUnit(unitId), "UNIT_DOES_NOT_EXIST");
        require(
            provider.isProviderOwner(sender, unitStructs[unitId].providerKey),
            "NOT_OWNER_DELETE_UNIT"
        );

        // delete from table
        uint256 rowToDelete = unitStructs[unitId].unitListPointer;
        bytes32 keyToMove = unitList[unitList.length - 1];
        unitList[rowToDelete] = keyToMove;
        unitStructs[unitId].unitListPointer = rowToDelete;
        unitList.pop();

        bytes32 providerId = unitStructs[unitId].providerKey;
        provider.removeUnit(sender, providerId, unitId);
        emit LogUnitDeleted(sender, unitId);
        return true;
    }

    function addReservation(bytes32 unitId, bytes32 reservationId) public {
        unitStructs[unitId].reservationKeys.push(reservationId);
        unitStructs[unitId].reservationKeyPointers[reservationId] =
            unitStructs[unitId].reservationKeys.length -
            1;
    }

    function removeReservation(bytes32 unitId, bytes32 reservationId) public {
        uint256 rowToDelete =
            unitStructs[unitId].reservationKeyPointers[reservationId];
        bytes32 keyToMove =
            unitStructs[unitId].reservationKeys[
                unitStructs[unitId].reservationKeys.length - 1
            ];
        unitStructs[unitId].reservationKeys[rowToDelete] = keyToMove;
        unitStructs[unitId].reservationKeyPointers[keyToMove] = rowToDelete;
        unitStructs[unitId].reservationKeys.pop();
    }
}