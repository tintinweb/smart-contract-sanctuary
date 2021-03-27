/**
 *Submitted for verification at Etherscan.io on 2021-03-26
*/

// File: localhost/VaultParameters.sol

// SPDX-License-Identifier: bsl-1.1

/*
  Copyright 2020 Unit Protocol: Artem Zakharov ([email protected]).
*/
pragma solidity ^0.7.1;


/**
 * @title Auth
 * @dev Manages USDP's system access
 **/
contract Auth {

    // address of the the contract with vault parameters
    VaultParameters public vaultParameters;

    constructor(address _parameters) {
        vaultParameters = VaultParameters(_parameters);
    }

    // ensures tx's sender is a manager
    modifier onlyManager() {
        require(vaultParameters.isManager(msg.sender), "Unit Protocol: AUTH_FAILED");
        _;
    }

    // ensures tx's sender is able to modify the Vault
    modifier hasVaultAccess() {
        require(vaultParameters.canModifyVault(msg.sender), "Unit Protocol: AUTH_FAILED");
        _;
    }

    // ensures tx's sender is the Vault
    modifier onlyVault() {
        require(msg.sender == vaultParameters.vault(), "Unit Protocol: AUTH_FAILED");
        _;
    }
}


/**
 * @title VaultParameters
 **/
contract VaultParameters {

    // permissions to modify the Vault
    mapping(address => bool) public canModifyVault;

    // managers
    mapping(address => bool) public isManager;

    // address of the Vault
    address payable public vault;
}

// File: localhost/CollateralRegistry.sol

/*
  Copyright 2020 Unit Protocol: Artem Zakharov ([email protected]).
*/
pragma solidity ^0.7.1;
pragma experimental ABIEncoderV2;



/**
 * @title CollateralRegistry
 **/
contract CollateralRegistry is Auth {

    event CollateralAdded(address indexed asset);
    event CollateralRemoved(address indexed asset);

    mapping(address => uint) public collateralId;

    address[] public collateralList;
    
    constructor(address _vaultParameters, address[] memory assets) Auth(_vaultParameters) {
        for (uint i = 0; i < assets.length; i++) {
            collateralList.push(assets[i]);
            collateralId[assets[i]] = i;
            emit CollateralAdded(assets[i]);
        }
    }

    function addCollateral(address asset) public onlyManager {
        require(asset != address(0), "Unit Protocol: ZERO_ADDRESS");

        require(!isCollateral(asset), "Unit Protocol: ALREADY_EXIST");

        collateralId[asset] = collateralList.length;
        collateralList.push(asset);

        emit CollateralAdded(asset);
    }

    function removeCollateral(address asset) public onlyManager {
        require(asset != address(0), "Unit Protocol: ZERO_ADDRESS");

        require(isCollateral(asset), "Unit Protocol: DOES_NOT_EXIST");

        uint id = collateralId[asset];

        delete collateralId[asset];

        uint lastId = collateralList.length - 1;

        if (id != lastId) {
            address lastCollateral = collateralList[lastId];
            collateralList[id] = lastCollateral;
            collateralId[lastCollateral] = id;
        }

        collateralList.pop();

        emit CollateralRemoved(asset);
    }

    function isCollateral(address asset) public view returns(bool) {
        if (collateralList.length == 0) { return false; }
        return collateralId[asset] != 0 || collateralList[0] == asset;
    }

    function collaterals() external view returns (address[] memory) {
        return collateralList;
    }

    function collateralsCount() external view returns (uint) {
        return collateralList.length;
    }
}