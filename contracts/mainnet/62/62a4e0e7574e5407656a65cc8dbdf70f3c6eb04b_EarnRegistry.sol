/**
 *Submitted for verification at Etherscan.io on 2021-04-15
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

interface ManagementList {
    function isManager(address accountAddress) external returns (bool);
}

contract Manageable {
    ManagementList public managementList;

    constructor(address _managementListAddress) {
        managementList = ManagementList(_managementListAddress);
    }

    modifier onlyManagers() {
        bool isManager = managementList.isManager(msg.sender);
        require(isManager, "ManagementList: caller is not a manager");
        _;
    }
}

contract EarnRegistry is Manageable {
    mapping(uint256 => address) private _assets;
    uint256 public numAssets;
    mapping(address => uint256) private isRegistered;
    address public managementListAddress;

    constructor(
        address _managementListAddress,
        address[] memory _initialAddresses
    ) Manageable(_managementListAddress) {
        managementListAddress = _managementListAddress;
        require(
            _managementListAddress != address(0),
            "Missing management list address"
        );
        if (_initialAddresses.length > 0) {
            addAssets(_initialAddresses);
        }
    }

    function addAsset(address assetAddress) public onlyManagers {
        if (isRegistered[assetAddress] == 0) {
            numAssets += 1;
            _assets[numAssets] = assetAddress;
            isRegistered[assetAddress] = numAssets;
        }
    }

    function addAssets(address[] memory assetAddresses) public onlyManagers {
        for (uint256 i = 0; i < assetAddresses.length; i++) {
            address assetAddress = assetAddresses[i];
            addAsset(assetAddress);
        }
    }

    function removeAsset(address assetAddress) external onlyManagers {
        if (isRegistered[assetAddress] != 0) {
            uint256 registryIndex = isRegistered[assetAddress];
            delete _assets[registryIndex];
            delete isRegistered[assetAddress];
            numAssets -= 1;
        }
    }

    function assets() external view returns (address[] memory) {
        address[] memory assetList = new address[](numAssets);
        for (uint256 i = 0; i < numAssets; i++) {
            address assetAddress = _assets[i + 1];
            assetList[i] = assetAddress;
        }
        return assetList;
    }
}