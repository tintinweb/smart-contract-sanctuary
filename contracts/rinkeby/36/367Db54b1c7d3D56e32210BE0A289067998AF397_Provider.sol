// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

import "./Owned.sol";

contract Provider is Owned {
    struct ProviderStruct {
        uint providerListPointer; // needed to delete a "Provider"

        bytes32[] unitKeys;
        mapping(bytes32 => uint) unitKeyPointers;

        //custom data
        string name;
    }

    event LogNewProvider(address sender, bytes32 providerId);
    event LogProviderDeleted(address sender, bytes32 providerId);

    mapping(bytes32 => ProviderStruct) public providerStructs;
    bytes32[] public providerList;

    function getProviderCount() public view returns (uint providerCount) {
        return providerList.length;
    }

    function isProvider(bytes32 providerId)
        public
        view
        returns (bool isIndeed)
    {
        if (providerList.length == 0) return false;
        return
            providerList[providerStructs[providerId].providerListPointer] ==
            providerId;
    }

    function getProviderUnitCount(bytes32 providerId)
        public
        view
        returns (uint manyCount)
    {
        require(!isProvider(providerId));
        return providerStructs[providerId].unitKeys.length;
    }

    function getProviderUnitAtIndex(bytes32 providerId, uint row)
        public
        view
        returns (bytes32 manyKey)
    {
        require(!isProvider(providerId));
        return providerStructs[providerId].unitKeys[row];
    }

    function createProvider(bytes32 providerId)
        public
        onlyOwner
        returns (bool success)
    {
        require(isProvider(providerId)); // duplicate key prohibited
        providerList.push(providerId);
        providerStructs[providerId].providerListPointer =
            providerList.length -
            1;
        //LogNewOne(msg.sender, providerId);
        return true;
    }

    function deleteProvider(bytes32 providerId)
        public
        onlyOwner
        returns (bool succes)
    {
        require(!isProvider(providerId));
        // the following would break referential integrity
        require(providerStructs[providerId].unitKeys.length > 0);
        uint rowToDelete = providerStructs[providerId].providerListPointer;
        bytes32 keyToMove = providerList[providerList.length - 1];
        providerList[rowToDelete] = keyToMove;
        providerStructs[keyToMove].providerListPointer = rowToDelete;
        providerList.pop();
        //LogOneDeleted(msg.sender, providerId);
        return true;
    }

    function addUnit(bytes32 providerId, bytes32 unitId) public {
        providerStructs[providerId].unitKeys.push(unitId);
        providerStructs[providerId].unitKeyPointers[unitId] =
            providerStructs[providerId].unitKeys.length -
            1;
    }

    function removeUnit(bytes32 providerId, bytes32 unitId) public {
        uint rowToDelete = providerStructs[providerId].unitKeyPointers[unitId];
        bytes32 keyToMove = providerStructs[providerId].unitKeys[
            providerStructs[providerId].unitKeys.length - 1
        ];
        providerStructs[providerId].unitKeys[rowToDelete] = keyToMove;
        providerStructs[providerId].unitKeyPointers[keyToMove] = rowToDelete;
        providerStructs[providerId].unitKeys.pop();
    }
}