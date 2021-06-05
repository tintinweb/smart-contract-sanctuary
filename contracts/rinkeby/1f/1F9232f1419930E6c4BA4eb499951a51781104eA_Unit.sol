// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

import "./Owned.sol";
import "./Provider.sol";

contract Unit is Owned {
    struct UnitStruct {
        uint256 unitListPointer; // needed to delete a "Many"
        bytes32 providerKey; // many has exactly one "One"
        bytes32[] reservationKeys;
        mapping(bytes32 => uint256) reservationKeyPointers;
        //custom data
        uint16 guestCount;
    }

    event LogNewUnit(address sender, bytes32 unitId, bytes32 providerId);
    event LogUnitDeleted(address sender, bytes32 unitId);

    Provider internal provider;

    mapping(bytes32 => UnitStruct) public unitStructs;
    bytes32[] public unitList;

    constructor() public {
        provider = Provider(address(0));
    }

    function setProviderAddress(address adr) external onlyOwner {
        provider = Provider(adr);
    }

    function getUnitCount() external view returns (uint256 unitCount) {
        return unitList.length;
    }

    function isUnit(bytes32 unitId) public view returns (bool isIndeed) {
        if (unitList.length == 0) return false;
        return unitList[unitStructs[unitId].unitListPointer] == unitId;
    }

    function createUnit(
        bytes32 unitId,
        bytes32 providerId,
        uint16 guestCount
    ) external onlyOwner returns (bool success) {
        require(provider.isProvider(providerId), "IS_NOT_PROVIDER");
        require(!isUnit(unitId), "DUPLICATE_UNIT_KEY"); // duplicate key prohibited
        require(guestCount > 0, "GUEST_COUNT_IMPLAUSIBLE");

        unitList.push(unitId);
        unitStructs[unitId].unitListPointer = unitList.length - 1;
        unitStructs[unitId].providerKey = providerId;
        unitStructs[unitId].guestCount = guestCount;

        // We also maintain a list of "Many" that refer to the "One", so ...
        provider.addUnit(providerId, unitId);
        emit LogNewUnit(msg.sender, unitId, providerId);
        return true;
    }

    function deleteUnit(bytes32 unitId)
        external
        onlyOwner
        returns (bool success)
    {
        require(isUnit(unitId), "IS_NOT_UNIT");

        // delete from the Many table
        uint256 rowToDelete = unitStructs[unitId].unitListPointer;
        bytes32 keyToMove = unitList[unitList.length - 1];
        unitList[rowToDelete] = keyToMove;
        unitStructs[unitId].unitListPointer = rowToDelete;
        unitList.pop();

        // we ALSO have to delete this key from the list in the ONE
        bytes32 providerId = unitStructs[unitId].providerKey;
        provider.removeUnit(providerId, unitId);
        emit LogUnitDeleted(msg.sender, unitId);
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