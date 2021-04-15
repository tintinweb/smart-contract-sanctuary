/**
 *Submitted for verification at Etherscan.io on 2021-04-15
*/

// SPDX-License-Identifier: GPL-3.0-or-later
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

contract DelegatedBalanceMapping is Manageable {
    mapping(address => bool) public assetBalanceIsDelegated;

    event DelegatedBalanceMappingUpdated(
        address assetAddress,
        bool delegationEnabled
    );

    constructor(address _managementListAddress)
        Manageable(_managementListAddress)
    {}

    function updateDelegationStatusForAsset(
        address tokenAddress,
        bool delegationEnabled
    ) public onlyManagers {
        assetBalanceIsDelegated[tokenAddress] = delegationEnabled;
        emit DelegatedBalanceMappingUpdated(tokenAddress, delegationEnabled);
    }
}