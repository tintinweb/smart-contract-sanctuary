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

