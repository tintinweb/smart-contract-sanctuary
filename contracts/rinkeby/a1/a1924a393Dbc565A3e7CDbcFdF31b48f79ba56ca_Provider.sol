// SPDX-License-Identifier: MIT
pragma solidity >=0.5.17 <0.9.0;
pragma experimental ABIEncoderV2;

import "./IProvider.sol";
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

    event LogNewProvider(address sender, bytes32 providerId);
    event LogProviderDeleted(address sender, bytes32 providerId);

    mapping(bytes32 => ProviderInternalStruct) public providerStructs;
    bytes32[] public providerList;

    constructor() public {}

    function getProviderCount() external view returns (uint256) {
        return providerList.length;
    }

    function isProvider(bytes32 providerId) public view returns (bool) {
        if (providerList.length == 0) return false;
        return
            providerList[providerStructs[providerId].providerListPointer] ==
            providerId;
    }

    function isProviderOwner(bytes32 providerId) public view returns (bool) {
        return msg.sender == providerStructs[providerId].owner;
    }

    function isProviderOwner(address sender, bytes32 providerId)
        public
        view
        returns (bool)
    {
        require(remote == sender, "NOT_REMOTE_CALL");
        return sender == providerStructs[providerId].owner;
    }

    function getProviderUnitCount(bytes32 providerId)
        external
        view
        returns (uint256)
    {
        require(isProvider(providerId), "PROVIDER_DOES_NOT_EXIST");
        return providerStructs[providerId].unitKeys.length;
    }

    function getProviderUnitAtIndex(bytes32 providerId, uint256 row)
        external
        view
        returns (bytes32)
    {
        require(isProvider(providerId), "PROVIDER_DOES_NOT_EXIST");
        return providerStructs[providerId].unitKeys[row];
    }

    function getAllProviders() external view returns (ProviderStruct[] memory) {
        ProviderStruct[] memory array =
            new ProviderStruct[](providerList.length);

        for (uint256 i = 0; i < array.length; i++) {
            array[i].providerId = providerList[i];
            array[i].name = providerStructs[array[i].providerId].name;
            array[i].unitKeys = providerStructs[array[i].providerId].unitKeys;
        }
        return array;
    }

    function createProvider(address sender, string calldata name)
        external
        returns (bool)
    {
        require(remote == msg.sender, "NOT_REMOTE_CALL");
        require(
            createProvider(sender, bytes32(counter++), name),
            "CREATE_PROVIDER_FAILED"
        );
        return true;
    }

    function createProvider(
        address sender,
        bytes32 providerId,
        string memory name
    ) internal returns (bool) {
        require(!isProvider(providerId), "DUPLICATE_PROVIDER_KEY"); // duplicate key prohibited
        providerList.push(providerId);
        providerStructs[providerId].providerListPointer =
            providerList.length -
            1;
        providerStructs[providerId].name = name;
        providerStructs[providerId].owner = sender;
        emit LogNewProvider(sender, providerId);
        return true;
    }

    function deleteProvider(bytes32 providerId) external returns (bool) {
        require(isProvider(providerId), "PROVIDER_DOES_NOT_EXIST");
        require(isProviderOwner(providerId), "NOT_OWNER");
        // the following would break referential integrity
        require(
            providerStructs[providerId].unitKeys.length <= 0,
            "LENGTH_UNIT_KEYS_GREATER_THAN_ZERO"
        );
        uint256 rowToDelete = providerStructs[providerId].providerListPointer;
        bytes32 keyToMove = providerList[providerList.length - 1];
        providerList[rowToDelete] = keyToMove;
        providerStructs[keyToMove].providerListPointer = rowToDelete;
        providerList.pop();

        emit LogProviderDeleted(msg.sender, providerId);
        return true;
    }

    function addUnit(bytes32 providerId, bytes32 unitId) public {
        require(isProviderOwner(providerId), "NOT_OWNER");
        providerStructs[providerId].unitKeys.push(unitId);
        providerStructs[providerId].unitKeyPointers[unitId] =
            providerStructs[providerId].unitKeys.length -
            1;
    }

    function removeUnit(bytes32 providerId, bytes32 unitId) public {
        require(isProviderOwner(providerId), "NOT_OWNER");
        uint256 rowToDelete =
            providerStructs[providerId].unitKeyPointers[unitId];
        bytes32 keyToMove =
            providerStructs[providerId].unitKeys[
                providerStructs[providerId].unitKeys.length - 1
            ];
        providerStructs[providerId].unitKeys[rowToDelete] = keyToMove;
        providerStructs[providerId].unitKeyPointers[keyToMove] = rowToDelete;
        providerStructs[providerId].unitKeys.pop();
    }
}