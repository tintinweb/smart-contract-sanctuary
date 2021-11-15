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

    function addRemote(address adr) public {
        require(owner == msg.sender, "NOT_OWNER");
        remote = adr;
    }
}

// SPDX-License-Identifier: MIT
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
            array[i].owner = providerStructs[array[i].providerId].owner;
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
        bytes32 providerId,
        string memory name
    ) internal returns (ProviderStruct memory) {
        require(!isProvider(providerId), "DUPLICATE_PROVIDER_KEY"); // duplicate key prohibited
        providerList.push(providerId);
        providerStructs[providerId].providerListPointer =
            providerList.length -
            1;
        providerStructs[providerId].name = name;
        providerStructs[providerId].owner = sender;

        return ProviderStruct(
                providerStructs[providerId].owner,
                providerId,
                providerStructs[providerId].unitKeys,
                providerStructs[providerId].name
            );
    }

    function deleteProvider(address sender, bytes32 providerId)
        external
        returns (bytes32)
    {
        require(isProvider(providerId), "PROVIDER_DOES_NOT_EXIST");
        require(
            isProviderOwner(sender, providerId),
            "NOT_OWNER_DELETE_PROVIDER"
        );
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

        return providerId;
    }

    function addUnit(
        address sender,
        bytes32 providerId,
        bytes32 unitId
    ) public {
        require(isProviderOwner(sender, providerId), "NOT_OWNER_ADD_UNIT");
        providerStructs[providerId].unitKeys.push(unitId);
        providerStructs[providerId].unitKeyPointers[unitId] =
            providerStructs[providerId].unitKeys.length -
            1;
    }

    function removeUnit(
        address sender,
        bytes32 providerId,
        bytes32 unitId
    ) public {
        require(isProviderOwner(sender, providerId), "NOT_OWNER_REMOVE_UNIT");
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

// SPDX-License-Identifier: MIT
pragma solidity 0.5.17;

interface IOwner {
    function addRemote(address adr) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

interface IProvider {
    struct ProviderStruct {
        address owner;
        bytes32 providerId;
        bytes32[] unitKeys;
        string name;
    }

    function getProviderCount() external view returns (uint256);

    function isProvider(bytes32 providerId) external view returns (bool);

    function isProviderOwner(address sender, bytes32 providerId)
        external
        view
        returns (bool);

    function getProviderUnitCount(bytes32 providerId)
        external
        view
        returns (uint256);

    function getProviderUnitAtIndex(bytes32 providerId, uint256 row)
        external
        view
        returns (bytes32);

    function getAllProviders() external view returns (ProviderStruct[] memory);

    function createProvider(address sender, string calldata name)
        external
        returns (ProviderStruct memory);

    function deleteProvider(address sender, bytes32 providerId) external returns (bytes32);
}

